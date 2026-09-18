import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../models/song_model.dart';
import '../../services/audio_player_service.dart';
import '../theme/app_theme.dart';
import 'album_detail_screen.dart';

class PlaylistsTab extends StatelessWidget {
  const PlaylistsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context);
    final favSongs = playerService.favoriteSongs;
    final recentSongs = playerService.recentlyPlayed;
    final playlists = playerService.playlists;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Top Special Cards: Favorites & Recently Played
        Row(
          children: [
            // Favorites Card
            Expanded(
              child: _buildSpecialPlaylistCard(
                context,
                title: 'Favorites',
                subtitle: '${favSongs.length} Songs',
                icon: Icons.favorite_rounded,
                gradient: const [Color(0xFFEF4444), Color(0xFF991B1B)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => AlbumDetailScreen(
                        title: 'Favorites',
                        subtitle: 'Your Liked Songs',
                        artworkType: ArtworkType.AUDIO,
                        songs: favSongs,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            // Recently Played Card
            Expanded(
              child: _buildSpecialPlaylistCard(
                context,
                title: 'Recent',
                subtitle: '${recentSongs.length} Songs',
                icon: Icons.history_rounded,
                gradient: const [Color(0xFF8B5CF6), Color(0xFF4C1D95)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => AlbumDetailScreen(
                        title: 'Recently Played',
                        subtitle: 'Last Played Tracks',
                        artworkType: ArtworkType.AUDIO,
                        songs: recentSongs,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Custom Playlists Header with Add Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Custom Playlists',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 20),
              label: const Text('New Playlist', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              onPressed: () => _showCreatePlaylistDialog(context, playerService),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (playlists.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.queue_music_rounded, size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
                const SizedBox(height: 12),
                const Text(
                  'No custom playlists yet',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap "+ New Playlist" to create one',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final pl = playlists[index];
              final playlistSongs = playerService.getSongsForPlaylist(pl);

              return Card(
                color: AppTheme.cardColor,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.queue_music_rounded, color: AppTheme.primary),
                  ),
                  title: Text(
                    pl.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    '${playlistSongs.length} Tracks',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted),
                    color: AppTheme.surfaceElevated,
                    onSelected: (value) {
                      if (value == 'delete') {
                        playerService.deletePlaylist(pl.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => AlbumDetailScreen(
                          title: pl.name,
                          subtitle: 'Custom Playlist',
                          artworkType: ArtworkType.AUDIO,
                          songs: playlistSongs,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSpecialPlaylistCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, AudioPlayerService playerService) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Playlist name...',
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.dividerColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                playerService.createPlaylist(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
