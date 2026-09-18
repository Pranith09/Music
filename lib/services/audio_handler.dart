import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => AuraAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.pranith.aura_music.playback',
      androidNotificationChannelName: 'Aura Music Playback',
      androidNotificationChannelDescription: 'Offline Music Playback Controls',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: false,
      androidShowNotificationBadge: true,
      androidNotificationClickStartsActivity: true,
    ),
  );
}

class AuraAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  List<SongItem> _playlist = [];
  int _currentIndex = -1;

  AudioPlayer get player => _player;
  List<SongItem> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  SongItem? get currentSong => (_currentIndex >= 0 && _currentIndex < _playlist.length) ? _playlist[_currentIndex] : null;

  AuraAudioHandler() {
    _initPlayer();
  }

  void _initPlayer() {
    // Broadcast player state changes to AudioService & Notification
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });

    // Handle track completion
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  Future<void> setPlaylist(List<SongItem> songs, {int initialIndex = 0}) async {
    _playlist = List.from(songs);
    _currentIndex = initialIndex;

    // Update queue for AudioService
    queue.add(_playlist.map((song) => _songToMediaItem(song)).toList());

    if (_playlist.isNotEmpty && initialIndex >= 0 && initialIndex < _playlist.length) {
      await _playIndex(initialIndex);
    }
  }

  Future<void> _playIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    final song = _playlist[index];

    // Update current MediaItem for lock screen & notification
    mediaItem.add(_songToMediaItem(song));

    try {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(song.uri.isNotEmpty ? song.uri : Uri.file(song.data).toString()),
          tag: _songToMediaItem(song),
        ),
      );
      await _player.play();
    } catch (e) {
      // Fallback directly to file path if URI fails
      try {
        await _player.setFilePath(song.data);
        await _player.play();
      } catch (err) {
        // Try skipping to next song if this one fails to load
        skipToNext();
      }
    }
  }

  MediaItem _songToMediaItem(SongItem song) {
    return MediaItem(
      id: song.id.toString(),
      album: song.album,
      title: song.title,
      artist: song.artist,
      duration: Duration(milliseconds: song.duration),
      artUri: song.albumId != null
          ? Uri.parse("content://media/external/audio/albumart/${song.albumId}")
          : null,
      extras: {
        'data': song.data,
        'albumId': song.albumId,
      },
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_playlist.isEmpty) return;
    int nextIndex = _currentIndex + 1;
    if (nextIndex >= _playlist.length) {
      nextIndex = 0; // Loop back to start
    }
    await _playIndex(nextIndex);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;
    // If playing for more than 3 seconds, restart current track
    if (_player.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    int prevIndex = _currentIndex - 1;
    if (prevIndex < 0) {
      prevIndex = _playlist.length - 1;
    }
    await _playIndex(prevIndex);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await _playIndex(index);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    await _player.setShuffleModeEnabled(enabled);
    if (enabled) {
      await _player.shuffle();
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
      case AudioServiceRepeatMode.off:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }
}
