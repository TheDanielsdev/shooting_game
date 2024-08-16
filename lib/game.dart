import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class ShootingArcadeGame extends FlameGame with HasCollisionDetection {
  late Shooter shooter;
  final Random _random = Random();
  late TextComponent scoreText;
  late TextComponent healthText;
  int score = 0;
  int health = 100;
  late JoystickComponent movementJoystick;
  late JoystickComponent shootJoystick;
  bool isGameOver = false;
  @override
  bool paused = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Register the PauseMenu overlay
    // overlays.addEntry(
    //     'PauseMenu',
    //     (BuildContext context, ShootingArcadeGame game) {
    //       return Center(
    //         child: ElevatedButton(
    //           onPressed: () {
    //             game.resumeGame();
    //           },
    //           child: const Text('Resume'),
    //         ),
    //       );
    //     });

    // Load the shooter character
    shooter = Shooter()
      ..position = Vector2(size.x / 2, size.y - 100)
      ..anchor = Anchor.center;
    add(shooter);

    // Display score and health
    scoreText = TextComponent(
      text: 'Score: $score',
      position: Vector2(10, 10),
      anchor: Anchor.topLeft,
      priority: 1,
    );
    add(scoreText);

    healthText = TextComponent(
      text: 'Health: $health',
      position: Vector2(size.x - 10, 10),
      anchor: Anchor.topRight,
      priority: 1,
    );
    add(healthText);

    // Add Pause/Play Button
    final pauseButton = SpriteButtonComponent(
      button: await Sprite.load('pause.png'), // Load your pause icon
      buttonDown:
          await Sprite.load('pause.png'), // Load the same icon for simplicity
      position: Vector2(size.x - 50, 10), // Position beside the health board
      size: Vector2(40, 40),
      anchor: Anchor.topRight,
      onPressed: togglePause,
    );
    add(pauseButton);

    add(TimerComponent(
      period: 2,
      repeat: true,
      onTick: spawnDangerousAnimal,
    ));

    add(TimerComponent(
      period: 5,
      repeat: true,
      onTick: spawnCoin,
    ));

    // Add movement joystick
    movementJoystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: Paint()..color = Colors.blue),
      background: CircleComponent(
          radius: 50, paint: Paint()..color = Colors.blue.withOpacity(0.5)),
      margin: const EdgeInsets.only(left: 30, bottom: 30),
      position: Vector2(70, size.y - 70),
    );
    add(movementJoystick);

    // Add shooting joystick
    shootJoystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: Paint()..color = Colors.red),
      background: CircleComponent(
          radius: 50, paint: Paint()..color = Colors.red.withOpacity(0.5)),
      margin: const EdgeInsets.only(right: 30, bottom: 30),
      position: Vector2(size.x - 70, size.y - 70),
    );
    add(shootJoystick);
  }

  void spawnDangerousAnimal() {
    final animal = DangerousAnimal()
      ..position = Vector2(_random.nextDouble() * size.x, 0)
      ..anchor = Anchor.center;
    add(animal);
  }

  void spawnCoin() {
    final coin = Coin()
      ..position = Vector2(_random.nextDouble() * size.x, 0)
      ..anchor = Anchor.center;
    add(coin);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isGameOver) return;

    if (health <= 0) {
      isGameOver = true;
      pauseEngine();
      overlays.add('GameOverMenu');
    }

    shooter.updateMovement(movementJoystick.relativeDelta * dt);
    shooter.updateShooting(shootJoystick.relativeDelta);
  }

  void increaseScore(int amount) {
    score += amount;
    scoreText.text = 'Score: $score';
  }

  void decreaseHealth(int amount) {
    health -= amount;
    healthText.text = 'Health: $health';
  }

  void togglePause() {
    if (isGameOver) return;

    if (paused) {
      resumeGame();
    } else {
      pauseGame();
    }
  }

  void pauseGame() {
    paused = true;
    pauseEngine();
    overlays.add('PauseMenu');
  }

  void resumeGame() {
    paused = false;
    resumeEngine();
    overlays.remove('PauseMenu');
  }
}

class Shooter extends SpriteAnimationComponent
    with HasGameRef<ShootingArcadeGame>, CollisionCallbacks {
  Shooter() : super(size: Vector2(64, 64), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.spriteList(
      await Future.wait(
          [for (var i = 1; i <= 4; i++) Sprite.load('shooter.png')]),
      stepTime: 0.1,
    );
    add(CircleHitbox());
  }

  void updateMovement(Vector2 delta) {
    position.add(delta * 200);
    position.clamp(
      Vector2(size.x / 2, 0),
      Vector2(gameRef.size.x - size.x / 2, gameRef.size.y),
    );
  }

  void updateShooting(Vector2 delta) {
    if (delta.length > 0.5) {
      shoot(delta.normalized());
    }
  }

  void shoot(Vector2 direction) {
    final bullet = Bullet(direction)
      ..position = position
      ..anchor = Anchor.center;
    gameRef.add(bullet);
  }
}

class Bullet extends SpriteComponent
    with HasGameRef<ShootingArcadeGame>, CollisionCallbacks {
  Vector2 direction;
  double speed = 300.0;

  Bullet(this.direction) : super(size: Vector2(16, 16));

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('bullet.png');
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction * speed * dt;

    if (position.x < 0 ||
        position.x > gameRef.size.x ||
        position.y < 0 ||
        position.y > gameRef.size.y) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is DangerousAnimal) {
      gameRef.increaseScore(
          2); // Increase score by 2 when a dangerous animal is shot
      showHitEffect();
      other.removeFromParent();
      removeFromParent();
    }
    super.onCollision(intersectionPoints, other);
  }

  void showHitEffect() {
    final effect = ParticleSystemComponent(
      particle: Particle.generate(
        count: 20,
        lifespan: 0.5,
        generator: (i) {
          return AcceleratedParticle(
            acceleration: Vector2(0, 100),
            speed: Vector2.random() * 200,
            position: position.clone(),
            child: CircleParticle(
              radius: 2,
              paint: Paint()..color = Colors.yellow,
            ),
          );
        },
      ),
    );

    gameRef.add(effect);
  }
}

class DangerousAnimal extends SpriteAnimationComponent
    with HasGameRef<ShootingArcadeGame>, CollisionCallbacks {
  DangerousAnimal() : super(size: Vector2(48, 48), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.spriteList(
      await Future.wait(
          [for (var i = 1; i <= 4; i++) Sprite.load('animal.png')]),
      stepTime: 0.1,
    );
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += 100 * dt;

    if (position.y > gameRef.size.y) {
      gameRef.decreaseHealth(10);
      removeFromParent();
    }
  }
}

class Coin extends SpriteAnimationComponent
    with HasGameRef<ShootingArcadeGame>, CollisionCallbacks {
  Coin() : super(size: Vector2(32, 32), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.spriteList(
      await Future.wait([for (var i = 1; i <= 4; i++) Sprite.load('coin.png')]),
      stepTime: 0.1,
    );
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += 150 * dt;

    if (position.y > gameRef.size.y) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Shooter) {
      gameRef.increaseScore(5); // Increase score by 5 when a coin is collected
      removeFromParent();
    }
    super.onCollision(intersectionPoints, other);
  }
}
