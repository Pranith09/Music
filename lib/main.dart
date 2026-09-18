import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/audio_handler.dart';
import 'services/audio_player_service.dart';
import 'services/media_scanner_service.dart';
import 'services/storage_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system navigation bar & status bar transparent for AMOLED immersion
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Core Services
  final audioHandler = await initAudioService();
  final storageService = await StorageService.init();
  final scannerService = MediaScannerService();

  runApp(
    MusicApp(
      audioHandler: audioHandler as MusicAudioHandler,
      storageService: storageService,
      scannerService: scannerService,
    ),
  );
}

class MusicApp extends StatelessWidget {
  final MusicAudioHandler audioHandler;
  final StorageService storageService;
  final MediaScannerService scannerService;

  const MusicApp({
    Key? key,
    required this.audioHandler,
    required this.storageService,
    required this.scannerService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AudioPlayerService(
        audioHandler: audioHandler,
        storageService: storageService,
        scannerService: scannerService,
      ),
      child: MaterialApp(
        title: 'Music',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
