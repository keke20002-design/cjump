import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/antigravity_game.dart';
import 'screens/menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Full-screen immersive mode
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const AntiGravityApp());
}

class AntiGravityApp extends StatelessWidget {
  const AntiGravityApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Single game instance shared across screens
    final game = AntiGravityGame();

    return MaterialApp(
      title: 'ZeroFlip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: FutureBuilder(
        // Initialize score manager before showing menu
        future: game.scoreManager.init(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return MenuScreen(game: game);
        },
      ),
    );
  }
}
