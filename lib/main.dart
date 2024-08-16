import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game.dart';
import 'game_over_menu.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shooting Arcade Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyGameWidget(),
    );
  }
}

class MyGameWidget extends StatelessWidget {
  final ShootingArcadeGame _game = ShootingArcadeGame();

  MyGameWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWidget(
      game: _game,
      overlayBuilderMap: {
        'GameOverMenu': (BuildContext context, ShootingArcadeGame game) {
          return GameOverMenu(game: game);
        },
      },
    );
  }
}
