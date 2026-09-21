import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../models/song_model.dart';
import '../../services/audio_player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_tile.dart';

class AlbumDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final int? artworkId;
  final ArtworkType artworkType;
  final List<SongItem> songs;

  const AlbumDetailScreen({
    Key? key,
    required this.title,
    required this.subtitle,
    this.artworkId,
    this.artworkType = ArtworkType.ALBUM,
    required this.songs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppTheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (artworkId != null)
                        QueryArtworkWidget(
                          id: artworkId!,
                          type: artworkType,
                          artworkFit: BoxFit.cover,
                          nullArtworkWidget: Container(
                            color: AppTheme.surfaceElevated,
                            child: const Center(
                              child: Icon(Icons.album_rounded, size: 80, color: AppTheme.textMuted),
                            ),
                          ),
                        )
                      else
                        Container(
                          color: AppTheme.surfaceElevated,
                          child: const Center(
                            child: Icon(Icons.folder_rounded, size: 80, color: AppTheme.accent),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppTheme.background.withOpacity(0.8),
                              AppTheme.background,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$subtitle • ${songs.length} Tracks',
                        style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, size: 24),
                              label: const Text('Play All', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => playerService.playAll(songs, shuffle: false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textPrimary,
                                side: const BorderSide(color: AppTheme.dividerColor),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.shuffle_rounded, size: 20),
                              label: const Text('Shuffle', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => playerService.playAll(songs, shuffle: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppTheme.dividerColor),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = songs[index];
                    return SongTile(song: song, contextPlaylist: songs);
                  },
                  childCount: songs.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }
}
