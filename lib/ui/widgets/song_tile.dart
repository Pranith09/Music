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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrentSong ? AppTheme.accent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  artworkBorder: BorderRadius.circular(8),
                  artworkFit: BoxFit.cover,
                  nullArtworkWidget: Container(
                    color: isCurrentSong ? AppTheme.accent.withOpacity(0.3) : AppTheme.surfaceElevated,
                    child: Icon(
                      Icons.music_note_rounded,
                      color: isCurrentSong ? AppTheme.accentGlow : AppTheme.textMuted,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
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
                      color: isCurrentSong ? AppTheme.accentGlow : AppTheme.textPrimary,
                      fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isPlaying) ...[
                        const Icon(Icons.graphic_eq_rounded, size: 14, color: AppTheme.accent),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrentSong ? AppTheme.accent.withOpacity(0.8) : AppTheme.textMuted,
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
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? AppTheme.favoriteRed : AppTheme.textMuted.withOpacity(0.4),
                size: 20,
              ),
              onPressed: () => playerService.toggleFavorite(song.id),
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}
