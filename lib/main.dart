import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'screens/splash_screen.dart';
import 'audio/audio_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Full screen immersive
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await AudioManager().init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => GameState(),
      child: const TapAwayApp(),
    ),
  );
}

class TapAwayApp extends StatelessWidget {
  const TapAwayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap Away – Arrow Puzzle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4361EE),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
