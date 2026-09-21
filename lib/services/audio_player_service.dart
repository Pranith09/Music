import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/song_model.dart';
import 'audio_handler.dart';
import 'media_scanner_service.dart';
import 'storage_service.dart';

class AudioPlayerService extends ChangeNotifier {
  final MusicAudioHandler _audioHandler;
  final StorageService _storageService;
  final MediaScannerService _scannerService;

  List<SongItem> _allSongs = [];
  List<SongItem> _filteredSongs = [];
  List<AlbumModel> _albums = [];
  List<ArtistModel> _artists = [];
  List<FolderItem> _folders = [];
  Set<int> _favoriteIds = {};
  List<CustomPlaylist> _playlists = [];
  List<SongItem> _recentlyPlayedSongs = [];

  bool _isLoading = true;
  bool _hasPermission = false;
  String _searchQuery = '';
  SortOption _currentSort = SortOption.title;
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.off;

  // Sleep Timer
  Timer? _sleepTimer;
  Duration? _sleepTimerRemaining;

  // Getters
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  String get searchQuery => _searchQuery;
  SortOption get currentSort => _currentSort;
  bool get isShuffle => _isShuffle;
  RepeatMode get repeatMode => _repeatMode;
  Duration? get sleepTimerRemaining => _sleepTimerRemaining;

  List<SongItem> get songs => _searchQuery.isEmpty ? _allSongs : _filteredSongs;
  List<AlbumModel> get albums => _albums;
  List<ArtistModel> get artists => _artists;
  List<FolderItem> get folders => _folders;
  List<CustomPlaylist> get playlists => _playlists;
  List<SongItem> get favoriteSongs => _allSongs.where((s) => _favoriteIds.contains(s.id)).toList();
  List<SongItem> get recentlyPlayed => _recentlyPlayedSongs;

  MusicAudioHandler get handler => _audioHandler;
  SongItem? get currentSong => _audioHandler.currentSong;
  List<SongItem> get currentQueue => _audioHandler.playlist;
  int get currentIndex => _audioHandler.currentIndex;
  bool get isPlaying => _audioHandler.player.playing;
  Stream<Duration> get positionStream => _audioHandler.player.positionStream;
  Stream<Duration?> get durationStream => _audioHandler.player.durationStream;
  Stream<PlayerState> get playerStateStream => _audioHandler.player.playerStateStream;

  AudioPlayerService({
    required MusicAudioHandler audioHandler,
    required StorageService storageService,
    required MediaScannerService scannerService,
  })  : _audioHandler = audioHandler,
        _storageService = storageService,
        _scannerService = scannerService {
    _init();
  }

  Future<void> _init() async {
    _favoriteIds = _storageService.getFavorites();
    _playlists = _storageService.getPlaylists();
    _currentSort = _storageService.getSortOption();

    _audioHandler.mediaItem.listen((item) {
      if (item != null) {
        final id = int.tryParse(item.id);
        if (id != null) {
          _storageService.addRecentlyPlayed(id);
          _refreshRecentlyPlayed();
          notifyListeners();
        }
      }
    });

    _audioHandler.player.playerStateStream.listen((_) {
      notifyListeners();
    });

    await refreshLibrary();
  }

  Future<void> refreshLibrary() async {
    _isLoading = true;
    notifyListeners();

    _hasPermission = await _scannerService.checkAndRequestPermissions();
    if (_hasPermission) {
      final songs = await _scannerService.scanAllSongs();
      _allSongs = MediaScannerService.sortSongs(songs, _currentSort);
      _albums = await _scannerService.scanAlbums();
      _artists = await _scannerService.scanArtists();
      _folders = MediaScannerService.groupSongsIntoFolders(_allSongs);
      _refreshRecentlyPlayed();
      _applySearch();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _refreshRecentlyPlayed() {
    final recentIds = _storageService.getRecentlyPlayed();
    _recentlyPlayedSongs = [];
    for (final id in recentIds) {
      final song = _allSongs.firstWhere(
        (s) => s.id == id,
        orElse: () => SongItem(id: -1, title: '', artist: '', album: '', duration: 0, uri: '', data: ''),
      );
      if (song.id != -1) {
        _recentlyPlayedSongs.add(song);
      }
    }
  }

  Future<void> playSong(SongItem song, {List<SongItem>? contextPlaylist}) async {
    final list = contextPlaylist ?? songs;
    final index = list.indexWhere((s) => s.id == song.id);
    if (index >= 0) {
      await _audioHandler.setPlaylist(list, initialIndex: index);
      _storageService.setLastSongId(song.id);
      notifyListeners();
    }
  }

  Future<void> playAll(List<SongItem> list, {bool shuffle = false}) async {
    if (list.isEmpty) return;
    List<SongItem> playList = List.from(list);
    if (shuffle) {
      playList.shuffle();
    }
    await _audioHandler.setPlaylist(playList, initialIndex: 0);
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_audioHandler.player.playing) {
      await _audioHandler.pause();
    } else {
      if (currentSong == null && _allSongs.isNotEmpty) {
        await playSong(_allSongs.first);
      } else {
        await _audioHandler.play();
      }
    }
    notifyListeners();
  }

  Future<void> playNext() async {
    await _audioHandler.skipToNext();
    notifyListeners();
  }

  Future<void> playPrevious() async {
    await _audioHandler.skipToPrevious();
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioHandler.seek(position);
  }

  Future<void> toggleShuffle() async {
    _isShuffle = !_isShuffle;
    await _audioHandler.setShuffleMode(
      _isShuffle ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
    notifyListeners();
  }

  Future<void> toggleRepeat() async {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        await _audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        await _audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        await _audioHandler.setRepeatMode(AudioServiceRepeatMode.none);
        break;
    }
    notifyListeners();
  }

  bool isFavorite(int songId) => _favoriteIds.contains(songId);

  Future<void> toggleFavorite(int songId) async {
    await _storageService.toggleFavorite(songId);
    _favoriteIds = _storageService.getFavorites();
    notifyListeners();
  }

  Future<void> createPlaylist(String name) async {
    final playlist = CustomPlaylist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim().isNotEmpty ? name.trim() : 'New Playlist',
      songIds: [],
      createdAt: DateTime.now(),
    );
    await _storageService.savePlaylist(playlist);
    _playlists = _storageService.getPlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _storageService.deletePlaylist(playlistId);
    _playlists = _storageService.getPlaylists();
    notifyListeners();
  }

  Future<void> addSongToPlaylist(String playlistId, int songId) async {
    await _storageService.addSongToPlaylist(playlistId, songId);
    _playlists = _storageService.getPlaylists();
    notifyListeners();
  }

  List<SongItem> getSongsForPlaylist(CustomPlaylist playlist) {
    return _allSongs.where((s) => playlist.songIds.contains(s.id)).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.trim().isEmpty) {
      _filteredSongs = [];
    } else {
      final q = _searchQuery.toLowerCase().trim();
      _filteredSongs = _allSongs.where((song) {
        return song.title.toLowerCase().contains(q) ||
            song.artist.toLowerCase().contains(q) ||
            song.album.toLowerCase().contains(q);
      }).toList();
    }
  }

  Future<void> setSortOption(SortOption option) async {
    _currentSort = option;
    await _storageService.setSortOption(option);
    _allSongs = MediaScannerService.sortSongs(_allSongs, option);
    _applySearch();
    notifyListeners();
  }

  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerRemaining = duration;

    if (duration != null && duration.inSeconds > 0) {
      _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_sleepTimerRemaining == null || _sleepTimerRemaining!.inSeconds <= 1) {
          timer.cancel();
          _sleepTimer = null;
          _sleepTimerRemaining = null;
          _audioHandler.pause();
          notifyListeners();
        } else {
          _sleepTimerRemaining = _sleepTimerRemaining! - const Duration(seconds: 1);
          notifyListeners();
        }
      });
    }
    notifyListeners();
  }

  void cancelSleepTimer() => setSleepTimer(null);

  @override
  void dispose() {
    _sleepTimer?.cancel();
    super.dispose();
  }
}
