import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song_model.dart';

class MediaScannerService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  OnAudioQuery get audioQuery => _audioQuery;

  /// Check and request storage permissions (Android 13+ and older)
  Future<bool> checkAndRequestPermissions() async {
    // Check permission status via on_audio_query and permission_handler
    bool hasPermission = await _audioQuery.permissionsStatus();

    if (!hasPermission) {
      if (await Permission.audio.request().isGranted) {
        hasPermission = true;
      } else if (await Permission.storage.request().isGranted) {
        hasPermission = true;
      } else {
        // Fallback for Android 13+
        hasPermission = await _audioQuery.permissionsRequest();
      }
    }
    return hasPermission;
  }

  /// Scan all songs on device
  Future<List<SongItem>> scanAllSongs({bool filterShortClips = true}) async {
    try {
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final List<SongItem> items = [];
      for (final song in songs) {
        // Filter out short notification sounds / ringtones (< 10 seconds)
        if (filterShortClips && (song.duration ?? 0) < 10000) {
          continue;
        }
        items.add(SongItem.fromAudioQuery(song));
      }
      return items;
    } catch (e) {
      debugPrint('Error scanning songs: $e');
      return [];
    }
  }

  /// Scan Albums
  Future<List<AlbumModel>> scanAlbums() async {
    try {
      return await _audioQuery.queryAlbums(
        sortType: AlbumSortType.ALBUM,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );
    } catch (e) {
      debugPrint('Error scanning albums: $e');
      return [];
    }
  }

  /// Scan Artists
  Future<List<ArtistModel>> scanArtists() async {
    try {
      return await _audioQuery.queryArtists(
        sortType: ArtistSortType.ARTIST,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );
    } catch (e) {
      debugPrint('Error scanning artists: $e');
      return [];
    }
  }

  /// Sort songs based on chosen option
  static List<SongItem> sortSongs(List<SongItem> songs, SortOption option) {
    final list = List<SongItem>.from(songs);
    switch (option) {
      case SortOption.title:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.artist:
        list.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
        break;
      case SortOption.album:
        list.sort((a, b) => a.album.toLowerCase().compareTo(b.album.toLowerCase()));
        break;
      case SortOption.duration:
        list.sort((a, b) => b.duration.compareTo(a.duration));
        break;
      case SortOption.dateAdded:
        list.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
        break;
    }
    return list;
  }
}
