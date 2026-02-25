import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/antigravity_game.dart';
import 'screens/menu_screen.dart';
import 'economy/persistence_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize persistence before anything else
  await PersistenceManager.instance.init();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Full-screen immersive mode
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const AntiGravityApp());
}

class AntiGravityApp extends StatefulWidget {
  const AntiGravityApp({super.key});

  @override
  State<AntiGravityApp> createState() => _AntiGravityAppState();
}

class _AntiGravityAppState extends State<AntiGravityApp> {
  // Single game instance shared across screens
  late final AntiGravityGame _game;
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _game = AntiGravityGame();
    _initFuture = _game.loadPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZeroFlip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4A90D9),
                ),
              ),
            );
          }
          return MenuScreen(game: _game);
        },
      ),
    );
  }
}
