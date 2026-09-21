import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../models/song_model.dart';
import '../../services/audio_player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sleep_timer_dialog.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context);
    final song = playerService.currentSong;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: Text('No song selected')),
      );
    }

    final isPlaying = playerService.isPlaying;
    final isFav = playerService.isFavorite(song.id);
    final isShuffle = playerService.isShuffle;
    final repeatMode = playerService.repeatMode;
    final queue = playerService.currentQueue;
    final currentIndex = playerService.currentIndex;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'NOW PLAYING',
              style: TextStyle(fontSize: 11, letterSpacing: 2.0, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              song.album,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.bedtime_outlined,
              color: playerService.sleepTimerRemaining != null ? AppTheme.accentGlow : AppTheme.textPrimary,
            ),
            onPressed: () => SleepTimerSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.queue_music_rounded),
            onPressed: () => _showQueueSheet(context, playerService),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Large Album Cover Art
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.76,
                  height: MediaQuery.of(context).size.width * 0.76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.25),
                        blurRadius: 30,
                        spreadRadius: -4,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      artworkFit: BoxFit.cover,
                      nullArtworkWidget: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.album_rounded, size: 88, color: AppTheme.accentGlow),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Title, Artist, Track Number & Favorite Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${song.artist}${queue.isNotEmpty ? ' • ${currentIndex + 1} of ${queue.length}' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? AppTheme.favoriteRed : AppTheme.textMuted,
                      size: 26,
                    ),
                    onPressed: () => playerService.toggleFavorite(song.id),
                  ),
                ],
              ),

              // Audio Seek Bar
              StreamBuilder<Duration>(
                stream: playerService.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final total = Duration(milliseconds: song.duration);

                  return ProgressBar(
                    progress: position,
                    total: total,
                    progressBarColor: AppTheme.accent,
                    baseBarColor: AppTheme.dividerColor,
                    thumbColor: AppTheme.accentGlow,
                    thumbGlowColor: AppTheme.accent.withOpacity(0.3),
                    thumbRadius: 6.5,
                    timeLabelTextStyle: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    onSeek: (duration) {
                      playerService.seek(duration);
                    },
                  );
                },
              ),

              // Action Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: isShuffle ? AppTheme.accentGlow : AppTheme.textMuted,
                      size: 24,
                    ),
                    onPressed: () => playerService.toggleShuffle(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, size: 36, color: AppTheme.textPrimary),
                    onPressed: () => playerService.playPrevious(),
                  ),
                  GestureDetector(
                    onTap: () => playerService.togglePlayPause(),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accent,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withOpacity(0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 36, color: AppTheme.textPrimary),
                    onPressed: () => playerService.playNext(),
                  ),
                  IconButton(
                    icon: Icon(
                      repeatMode == RepeatMode.one
                          ? Icons.repeat_one_rounded
                          : repeatMode == RepeatMode.all
                              ? Icons.repeat_rounded
                              : Icons.repeat_rounded,
                      color: repeatMode != RepeatMode.off ? AppTheme.accentGlow : AppTheme.textMuted,
                      size: 24,
                    ),
                    onPressed: () => playerService.toggleRepeat(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  void _showQueueSheet(BuildContext context, AudioPlayerService playerService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final queue = playerService.currentQueue;
        final currentIndex = playerService.currentIndex;

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (c, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Up Next Queue',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${queue.length} Tracks',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppTheme.dividerColor),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: queue.length,
                    itemBuilder: (context, index) {
                      final item = queue[index];
                      final isCurrent = index == currentIndex;

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: QueryArtworkWidget(
                              id: item.id,
                              type: ArtworkType.AUDIO,
                              artworkFit: BoxFit.cover,
                              nullArtworkWidget: Container(
                                color: AppTheme.cardColor,
                                child: const Icon(Icons.music_note_rounded, size: 20, color: AppTheme.textMuted),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrent ? AppTheme.accentGlow : AppTheme.textPrimary,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          item.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                        trailing: isCurrent ? const Icon(Icons.graphic_eq_rounded, color: AppTheme.accent) : null,
                        onTap: () {
                          playerService.playSong(item);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
