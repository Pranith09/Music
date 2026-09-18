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
import 'playlists_screen.dart';

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
                  hintText: 'Search songs, artists, albums...',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  border: InputBorder.none,
                ),
                onChanged: (val) => playerService.setSearchQuery(val),
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.headphones_rounded, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Aura Music',
                    style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                ],
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
                  value: SortOption.dateAdded,
                  child: Text('Date Added (Newest)'),
                ),
                const PopupMenuItem(
                  value: SortOption.title,
                  child: Text('Song Title (A-Z)'),
                ),
                const PopupMenuItem(
                  value: SortOption.artist,
                  child: Text('Artist Name'),
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
                color: playerService.sleepTimerRemaining != null ? AppTheme.primary : AppTheme.textPrimary,
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
            Tab(text: 'Playlists'),
            Tab(text: 'Albums'),
            Tab(text: 'Artists'),
          ],
        ),
      ),
      body: Stack(
        children: [
          if (playerService.isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          else if (!playerService.hasPermission)
            _buildPermissionDeniedState(playerService)
          else
            TabBarView(
              controller: _tabController,
              children: [
                // Tracks Tab
                _buildTracksTab(playerService),

                // Playlists Tab
                const PlaylistsTab(),

                // Albums Tab
                _buildAlbumsTab(playerService),

                // Artists Tab
                _buildArtistsTab(playerService),
              ],
            ),

          // Floating Mini Player
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
      return RefreshIndicator(
        onRefresh: () => playerService.refreshLibrary(),
        color: AppTheme.primary,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_off_rounded, size: 64, color: AppTheme.textMuted.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    'No downloaded songs found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add music files (.mp3, .m4a, .flac) to your phone storage',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Rescan Storage'),
                    onPressed: () => playerService.refreshLibrary(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => playerService.refreshLibrary(),
      color: AppTheme.primary,
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
      return const Center(
        child: Text('No albums found', style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
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
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.album,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${album.numOfSongs} Songs',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
      return const Center(
        child: Text('No artists found', style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return Card(
          color: AppTheme.cardColor,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.surfaceElevated,
              child: const Icon(Icons.person_rounded, color: AppTheme.primary),
            ),
            title: Text(
              artist.artist,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            subtitle: Text(
              '${artist.numberOfTracks ?? 0} Tracks • ${artist.numberOfAlbums ?? 0} Albums',
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

  Widget _buildPermissionDeniedState(AudioPlayerService playerService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off_rounded, size: 72, color: Colors.orangeAccent),
            const SizedBox(height: 20),
            const Text(
              'Audio Permission Needed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aura Music needs permission to read audio files from your Realme Narzo 60 storage to play your music offline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
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
