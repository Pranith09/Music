import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song_model.dart';

class MediaScannerService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  OnAudioQuery get audioQuery => _audioQuery;

  Future<bool> checkAndRequestPermissions() async {
    bool hasPermission = await _audioQuery.permissionsStatus();

    if (!hasPermission) {
      if (await Permission.audio.request().isGranted) {
        hasPermission = true;
      } else if (await Permission.storage.request().isGranted) {
        hasPermission = true;
      } else {
        hasPermission = await _audioQuery.permissionsRequest();
      }
    }
    return hasPermission;
  }

  Future<List<SongItem>> scanAllSongs({bool filterShortClips = true}) async {
    try {
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final List<SongItem> items = [];
      for (final song in songs) {
        if (filterShortClips && (song.duration ?? 0) < 10000) {
          continue; // Skip clips under 10 seconds
        }
        items.add(SongItem.fromAudioQuery(song));
      }
      return items;
    } catch (e) {
      debugPrint('Error scanning songs: $e');
      return [];
    }
  }

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

  /// Organizes songs into folders based on file directory path
  static List<FolderItem> groupSongsIntoFolders(List<SongItem> songs) {
    final Map<String, List<SongItem>> folderMap = {};

    for (final song in songs) {
      if (song.data.isEmpty) continue;
      final parts = song.data.split('/');
      if (parts.length > 1) {
        final folderPath = parts.sublist(0, parts.length - 1).join('/');
        final folderName = parts[parts.length - 2];
        if (!folderMap.containsKey(folderPath)) {
          folderMap[folderPath] = [];
        }
        folderMap[folderPath]!.add(song);
      }
    }

    final List<FolderItem> folders = [];
    folderMap.forEach((path, songsInFolder) {
      final parts = path.split('/');
      final name = parts.isNotEmpty ? parts.last : 'Music';
      folders.add(FolderItem(name: name, path: path, songs: songsInFolder));
    });

    folders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return folders;
  }

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
