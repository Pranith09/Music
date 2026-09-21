import 'dart:convert';
import 'package:on_audio_query/on_audio_query.dart';

enum SortOption {
  title,
  artist,
  album,
  dateAdded,
  duration,
}

enum RepeatMode {
  off,
  all,
  one,
}

class SongItem {
  final int id;
  final String title;
  final String artist;
  final String album;
  final int duration;
  final String uri;
  final String data; // File Path
  final int? albumId;
  final int? artistId;
  final int? trackNumber;
  final int? dateAdded;
  final int size;

  SongItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.uri,
    required this.data,
    this.albumId,
    this.artistId,
    this.trackNumber,
    this.dateAdded,
    this.size = 0,
  });

  factory SongItem.fromAudioQuery(SongModel song) {
    return SongItem(
      id: song.id,
      title: song.title.trim().isNotEmpty ? song.title.trim() : 'Unknown Title',
      artist: (song.artist != null && song.artist!.trim() != '<unknown>' && song.artist!.trim().isNotEmpty)
          ? song.artist!.trim()
          : 'Unknown Artist',
      album: (song.album != null && song.album!.trim() != '<unknown>' && song.album!.trim().isNotEmpty)
          ? song.album!.trim()
          : 'Unknown Album',
      duration: song.duration ?? 0,
      uri: song.uri ?? '',
      data: song.data,
      albumId: song.albumId,
      artistId: song.artistId,
      trackNumber: song.track,
      dateAdded: song.dateAdded,
      size: song.size,
    );
  }

  String get formattedDuration {
    final minutes = (duration / 1000 / 60).floor();
    final seconds = ((duration / 1000) % 60).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get folderName {
    if (data.isEmpty) return 'Root';
    final parts = data.split('/');
    if (parts.length > 1) {
      return parts[parts.length - 2];
    }
    return 'Music';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'duration': duration,
        'uri': uri,
        'data': data,
        'albumId': albumId,
        'artistId': artistId,
        'trackNumber': trackNumber,
        'dateAdded': dateAdded,
        'size': size,
      };

  factory SongItem.fromJson(Map<String, dynamic> json) => SongItem(
        id: json['id'] as int,
        title: json['title'] as String? ?? 'Unknown Title',
        artist: json['artist'] as String? ?? 'Unknown Artist',
        album: json['album'] as String? ?? 'Unknown Album',
        duration: json['duration'] as int? ?? 0,
        uri: json['uri'] as String? ?? '',
        data: json['data'] as String? ?? '',
        albumId: json['albumId'] as int?,
        artistId: json['artistId'] as int?,
        trackNumber: json['trackNumber'] as int?,
        dateAdded: json['dateAdded'] as int?,
        size: json['size'] as int? ?? 0,
      );
}

class FolderItem {
  final String name;
  final String path;
  final List<SongItem> songs;

  FolderItem({
    required this.name,
    required this.path,
    required this.songs,
  });

  int get songCount => songs.length;
}

class CustomPlaylist {
  final String id;
  final String name;
  final List<int> songIds;
  final DateTime createdAt;

  CustomPlaylist({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'songIds': songIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CustomPlaylist.fromJson(Map<String, dynamic> json) => CustomPlaylist(
        id: json['id'] as String,
        name: json['name'] as String,
        songIds: List<int>.from(json['songIds'] as List? ?? []),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
