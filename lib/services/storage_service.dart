import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

class StorageService {
  static const String _keyFavorites = 'user_favorites';
  static const String _keyPlaylists = 'user_playlists';
  static const String _keyRecentlyPlayed = 'user_recently_played';
  static const String _keySortOption = 'user_sort_option';
  static const String _keyLastSongId = 'user_last_song_id';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Favorites
  Set<int> getFavorites() {
    final list = _prefs.getStringList(_keyFavorites) ?? [];
    return list.map((id) => int.tryParse(id) ?? 0).where((id) => id > 0).toSet();
  }

  Future<void> toggleFavorite(int songId) async {
    final current = getFavorites();
    if (current.contains(songId)) {
      current.remove(songId);
    } else {
      current.add(songId);
    }
    await _prefs.setStringList(_keyFavorites, current.map((e) => e.toString()).toList());
  }

  bool isFavorite(int songId) {
    return getFavorites().contains(songId);
  }

  // Playlists
  List<CustomPlaylist> getPlaylists() {
    final list = _prefs.getStringList(_keyPlaylists) ?? [];
    return list.map((item) {
      try {
        return CustomPlaylist.fromJson(jsonDecode(item));
      } catch (_) {
        return null;
      }
    }).whereType<CustomPlaylist>().toList();
  }

  Future<void> savePlaylist(CustomPlaylist playlist) async {
    final playlists = getPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlist.id);
    if (index >= 0) {
      playlists[index] = playlist;
    } else {
      playlists.add(playlist);
    }
    await _savePlaylistsList(playlists);
  }

  Future<void> deletePlaylist(String playlistId) async {
    final playlists = getPlaylists();
    playlists.removeWhere((p) => p.id == playlistId);
    await _savePlaylistsList(playlists);
  }

  Future<void> addSongToPlaylist(String playlistId, int songId) async {
    final playlists = getPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index >= 0) {
      final p = playlists[index];
      if (!p.songIds.contains(songId)) {
        p.songIds.add(songId);
        await _savePlaylistsList(playlists);
      }
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, int songId) async {
    final playlists = getPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index >= 0) {
      playlists[index].songIds.remove(songId);
      await _savePlaylistsList(playlists);
    }
  }

  Future<void> _savePlaylistsList(List<CustomPlaylist> playlists) async {
    final jsonList = playlists.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList(_keyPlaylists, jsonList);
  }

  // Recently Played
  List<int> getRecentlyPlayed() {
    final list = _prefs.getStringList(_keyRecentlyPlayed) ?? [];
    return list.map((id) => int.tryParse(id) ?? 0).where((id) => id > 0).toList();
  }

  Future<void> addRecentlyPlayed(int songId) async {
    final list = getRecentlyPlayed();
    list.remove(songId);
    list.insert(0, songId);
    if (list.length > 50) {
      list.removeRange(50, list.length);
    }
    await _prefs.setStringList(_keyRecentlyPlayed, list.map((e) => e.toString()).toList());
  }

  // Sort Option
  SortOption getSortOption() {
    final index = _prefs.getInt(_keySortOption);
    if (index != null && index >= 0 && index < SortOption.values.length) {
      return SortOption.values[index];
    }
    return SortOption.title;
  }

  Future<void> setSortOption(SortOption option) async {
    await _prefs.setInt(_keySortOption, option.index);
  }

  // Last Played Song
  int? getLastSongId() {
    return _prefs.getInt(_keyLastSongId);
  }

  Future<void> setLastSongId(int songId) async {
    await _prefs.setInt(_keyLastSongId, songId);
  }
}
