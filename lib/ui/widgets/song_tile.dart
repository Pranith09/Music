import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../models/song_model.dart';
import '../../services/audio_player_service.dart';
import '../theme/app_theme.dart';

class SongTile extends StatelessWidget {
  final SongItem song;
  final List<SongItem>? contextPlaylist;
  final VoidCallback? onTap;

  const SongTile({
    Key? key,
    required this.song,
    this.contextPlaylist,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context);
    final isCurrentSong = playerService.currentSong?.id == song.id;
    final isPlaying = isCurrentSong && playerService.isPlaying;
    final isFav = playerService.isFavorite(song.id);

    return InkWell(
      onTap: onTap ?? () => playerService.playSong(song, contextPlaylist: contextPlaylist),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrentSong ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Album Artwork Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  artworkBorder: BorderRadius.circular(10),
                  artworkFit: BoxFit.cover,
                  nullArtworkWidget: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isCurrentSong ? AppTheme.primary : AppTheme.surfaceElevated,
                          AppTheme.cardColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      color: isCurrentSong ? Colors.white : AppTheme.textMuted,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Song Info (Title & Artist)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrentSong ? AppTheme.primaryAccent : AppTheme.textPrimary,
                      fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isPlaying) ...[
                        const Icon(Icons.graphic_eq_rounded, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrentSong ? AppTheme.primary.withOpacity(0.8) : AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        song.formattedDuration,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Favorite Quick Toggle
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? AppTheme.favoriteRed : AppTheme.textMuted.withOpacity(0.5),
                size: 20,
              ),
              onPressed: () => playerService.toggleFavorite(song.id),
              splashRadius: 20,
            ),

            // More Options Popup
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted, size: 20),
              color: AppTheme.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (value) {
                if (value == 'play_next') {
                  // Play next logic
                  playerService.playSong(song);
                } else if (value == 'add_playlist') {
                  _showAddToPlaylistDialog(context, playerService, song.id);
                } else if (value == 'info') {
                  _showSongInfoDialog(context, song);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'add_playlist',
                  child: Row(
                    children: [
                      Icon(Icons.playlist_add_rounded, color: AppTheme.textPrimary, size: 20),
                      SizedBox(width: 12),
                      Text('Add to Playlist'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppTheme.textPrimary, size: 20),
                      SizedBox(width: 12),
                      Text('Details & Path'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, AudioPlayerService playerService, int songId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final playlists = playerService.playlists;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add to Playlist',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No playlists yet. Create one from the Playlists tab.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (c, i) {
                    final pl = playlists[i];
                    final alreadyContains = pl.songIds.contains(songId);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.queue_music_rounded, color: AppTheme.primary),
                      title: Text(pl.name),
                      trailing: alreadyContains
                          ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                          : const Icon(Icons.add_rounded, color: AppTheme.textMuted),
                      onTap: () {
                        if (!alreadyContains) {
                          playerService.addSongToPlaylist(pl.id, songId);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Added to ${pl.name}')),
                          );
                        }
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showSongInfoDialog(BuildContext context, SongItem song) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(song.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Artist', song.artist),
            _buildInfoRow('Album', song.album),
            _buildInfoRow('Duration', song.formattedDuration),
            if (song.data.isNotEmpty) _buildInfoRow('File Path', song.data),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
        ],
      ),
    );
  }
}
