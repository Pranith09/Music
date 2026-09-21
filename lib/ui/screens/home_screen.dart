import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../models/song_model.dart';
import '../../services/audio_player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player.dart';
import '../widgets/sleep_timer_dialog.dart';
import '../widgets/song_tile.dart';
import 'album_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Search tracks, artists, albums...',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  border: InputBorder.none,
                ),
                onChanged: (val) => playerService.setSearchQuery(val),
              )
            : const Text(
                'Music',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  playerService.setSearchQuery('');
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (!_isSearching) ...[
            PopupMenuButton<SortOption>(
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'Sort by',
              color: AppTheme.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (option) => playerService.setSortOption(option),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: SortOption.title,
                  child: Text('Track Title (A-Z)'),
                ),
                const PopupMenuItem(
                  value: SortOption.artist,
                  child: Text('Artist Name'),
                ),
                const PopupMenuItem(
                  value: SortOption.album,
                  child: Text('Album Name'),
                ),
                const PopupMenuItem(
                  value: SortOption.dateAdded,
                  child: Text('Date Added (Newest)'),
                ),
                const PopupMenuItem(
                  value: SortOption.duration,
                  child: Text('Duration (Longest)'),
                ),
              ],
            ),
            IconButton(
              icon: Icon(
                Icons.bedtime_outlined,
                color: playerService.sleepTimerRemaining != null ? AppTheme.accentGlow : AppTheme.textPrimary,
              ),
              onPressed: () => SleepTimerSheet.show(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => playerService.refreshLibrary(),
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tracks'),
            Tab(text: 'Albums'),
            Tab(text: 'Artists'),
            Tab(text: 'Folders'),
          ],
        ),
      ),
      body: Stack(
        children: [
          if (playerService.isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          else if (!playerService.hasPermission)
            _buildPermissionDeniedState(playerService)
          else
            TabBarView(
              controller: _tabController,
              children: [
                _buildTracksTab(playerService),
                _buildAlbumsTab(playerService),
                _buildArtistsTab(playerService),
                _buildFoldersTab(playerService),
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

  Widget _buildTracksTab(AudioPlayerService playerService) {
    final songs = playerService.songs;

    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off_rounded, size: 64, color: AppTheme.textMuted.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text(
              'No downloaded songs found',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Place .mp3, .m4a, or .flac files in your phone storage',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Rescan Storage'),
              onPressed: () => playerService.refreshLibrary(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => playerService.refreshLibrary(),
      color: AppTheme.accent,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 90),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return SongTile(song: song, contextPlaylist: songs);
        },
      ),
    );
  }

  Widget _buildAlbumsTab(AudioPlayerService playerService) {
    final albums = playerService.albums;

    if (albums.isEmpty) {
      return const Center(child: Text('No albums found', style: TextStyle(color: AppTheme.textMuted)));
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.82,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return InkWell(
          onTap: () {
            final albumSongs = playerService.songs.where((s) => s.albumId == album.id).toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => AlbumDetailScreen(
                  title: album.album,
                  subtitle: album.artist ?? 'Unknown Artist',
                  artworkId: album.id,
                  artworkType: ArtworkType.ALBUM,
                  songs: albumSongs,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: QueryArtworkWidget(
                      id: album.id,
                      type: ArtworkType.ALBUM,
                      artworkFit: BoxFit.cover,
                      artworkWidth: double.infinity,
                      nullArtworkWidget: Container(
                        color: AppTheme.surfaceElevated,
                        child: const Center(
                          child: Icon(Icons.album_rounded, size: 48, color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.album,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${album.numOfSongs} Tracks',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtistsTab(AudioPlayerService playerService) {
    final artists = playerService.artists;

    if (artists.isEmpty) {
      return const Center(child: Text('No artists found', style: TextStyle(color: AppTheme.textMuted)));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return Card(
          color: AppTheme.cardColor,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.surfaceElevated,
              child: const Icon(Icons.person_rounded, color: AppTheme.accent),
            ),
            title: Text(
              artist.artist,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            subtitle: Text(
              '${artist.numberOfTracks ?? 0} Tracks',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
            onTap: () {
              final artistSongs = playerService.songs.where((s) => s.artistId == artist.id).toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => AlbumDetailScreen(
                    title: artist.artist,
                    subtitle: 'Artist',
                    artworkId: artist.id,
                    artworkType: ArtworkType.ARTIST,
                    songs: artistSongs,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFoldersTab(AudioPlayerService playerService) {
    final folders = playerService.folders;

    if (folders.isEmpty) {
      return const Center(child: Text('No folders found', style: TextStyle(color: AppTheme.textMuted)));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        return Card(
          color: AppTheme.cardColor,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder_rounded, color: AppTheme.accent),
            ),
            title: Text(
              folder.name,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            subtitle: Text(
              '${folder.songCount} Tracks • ${folder.path}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => AlbumDetailScreen(
                    title: folder.name,
                    subtitle: folder.path,
                    artworkType: ArtworkType.AUDIO,
                    songs: folder.songs,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPermissionDeniedState(AudioPlayerService playerService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off_rounded, size: 68, color: Colors.orangeAccent),
            const SizedBox(height: 18),
            const Text(
              'Audio Permission Required',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Music needs storage permission to scan your downloaded audio files on your Realme Narzo 60.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => playerService.refreshLibrary(),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }
}
