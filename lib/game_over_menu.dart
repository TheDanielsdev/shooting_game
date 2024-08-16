import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shooting_arcade/main.dart';

class GameOverMenu extends StatelessWidget {
  final Game game;

  const GameOverMenu({required this.game, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Game Over',
              style: TextStyle(
                fontSize: 48,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => MyGameWidget()));
              },
              child: const Text('Restart'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigator.of(context).pop();
              },
              child: const Text('Exit'),
            ),
          ],
        ),
      ),
    );
  }
}
