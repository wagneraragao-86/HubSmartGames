import 'dart:math';

import 'package:flutter/material.dart';

enum EnemyKind { drone, elite, boss }

enum PowerUpType { doubleShot, laser, shield, bomb }

enum SpawnStyle { line, zigzag, scatter, dive }

enum BossPattern { spread, aimedBurst, radial }

class SpaceProjectile {
  SpaceProjectile({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.fromPlayer,
    this.damage = 1,
    this.pierceHits = 1,
    this.width = 12,
    this.height = 4,
    this.color = const Color(0xFFFFFFFF),
    this.glow = false,
  });

  double x;
  double y;
  double vx;
  double vy;
  final bool fromPlayer;
  final int damage;
  int pierceHits;
  final double width;
  final double height;
  final Color color;
  final bool glow;

  Rect get rect => Rect.fromLTWH(x, y, width, height);
}

class SpaceEnemy {
  SpaceEnemy({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.hp,
    required this.maxHp,
    required this.scoreValue,
    required this.kind,
    required this.style,
  });

  double x;
  double y;
  double vx;
  double vy;
  int hp;
  final int maxHp;
  final int scoreValue;
  final EnemyKind kind;
  final SpawnStyle style;
  double fireCooldown = 0;
  double patternCooldown = 0;
  double driftSeed = 0;
  double homeY = 0;

  final double width = 44;
  final double height = 28;

  Rect get rect => Rect.fromLTWH(x, y, width, height);
}

class SpacePowerUpItem {
  SpacePowerUpItem({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.type,
  });

  double x;
  double y;
  double vx;
  double vy;
  final PowerUpType type;
  double age = 0;
  final double width = 24;
  final double height = 24;

  Rect get rect => Rect.fromLTWH(x, y, width, height);
}

class BurstParticle {
  BurstParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    required this.size,
  });

  double x;
  double y;
  double vx;
  double vy;
  double life;
  final double maxLife = 1;
  final Color color;
  final double size;

  bool update(double dt) {
    life -= dt;
    x += vx * dt;
    y += vy * dt;
    vx *= 0.98;
    vy *= 0.98;
    return life <= 0;
  }

  double get progress => (life / maxLife).clamp(0.0, 1.0);
}

class ExplosionEffect {
  ExplosionEffect({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    this.duration = 0.35,
  });

  double x;
  double y;
  double radius;
  double life = 0;
  final double duration;
  final Color color;

  bool update(double dt) {
    life += dt;
    radius += 210 * dt;
    return life >= duration;
  }

  double get progress => (life / duration).clamp(0.0, 1.0);
}

class RewardChallenge {
  const RewardChallenge({
    required this.id,
    required this.title,
    required this.bonusPoints,
    required this.isCompleted,
  });

  final String id;
  final String title;
  final int bonusPoints;
  final bool isCompleted;
}

class SpaceStar {
  SpaceStar(this.x, this.y, this.speed, this.size);

  double x;
  double y;
  final double speed;
  final double size;
}

class SpawnBatch {
  const SpawnBatch({
    required this.kind,
    required this.count,
    required this.spawnIntervalMs,
    required this.speed,
    required this.hp,
    required this.scoreValue,
    required this.style,
    this.allowsPowerUpDrop = false,
  });

  final EnemyKind kind;
  final int count;
  final int spawnIntervalMs;
  final double speed;
  final int hp;
  final int scoreValue;
  final SpawnStyle style;
  final bool allowsPowerUpDrop;
}

class WaveBlueprint {
  const WaveBlueprint({
    required this.title,
    required this.subtitle,
    required this.batches,
  });

  final String title;
  final String subtitle;
  final List<SpawnBatch> batches;
}

class SpaceImpactGame {
  final Random _random = Random();

  double _width = 0;
  double _height = 0;
  bool _viewportReady = false;

  final List<SpaceProjectile> _playerShots = [];
  final List<SpaceProjectile> _enemyShots = [];
  final List<SpaceEnemy> _enemies = [];
  final List<SpacePowerUpItem> _powerUps = [];
  final List<SpaceStar> _stars = [];
  final List<Offset> _playerTrail = [];
  final List<BurstParticle> _particles = [];
  final List<ExplosionEffect> _explosions = [];

  double playerX = 120;
  double playerY = 240;
  double _playerWidth = 42;
  double _playerHeight = 28;
  double _playerVelocityX = 0;
  double _playerVelocityY = 0;

  int score = 0;
  int level = 1;
  int lives = 3;
  int enemiesDestroyed = 0;
  int damageTaken = 0;
  int powerUpsCollected = 0;
  int bombsTriggered = 0;
  int bossesDefeated = 0;
  int wavesCleared = 0;
  bool isGameOver = false;
  bool isPaused = false;
  bool isVictory = false;
  int gameStartMs = DateTime.now().millisecondsSinceEpoch;
  int elapsedMs = 0;
  double _spawnAccumulatorMs = 0;
  int _waveTransitionAtMs = 0;
  int _waveIndex = 0;
  int _batchIndex = 0;
  int _remainingSpawnsInBatch = 0;
  int _spawnedInBatch = 0;
  int _invulnerableUntilMs = 0;
  int _shieldUntilMs = 0;
  int _doubleShotUntilMs = 0;
  int _laserUntilMs = 0;
  int _shieldCharges = 0;
  int _lastDamageFlashMs = 0;

  static const int maxLevel = 5;

  final List<WaveBlueprint> _waves = const [
    WaveBlueprint(
      title: 'Patrulha Inicial',
      subtitle: 'Drones em formação linear.',
      batches: [
        SpawnBatch(
          kind: EnemyKind.drone,
          count: 8,
          spawnIntervalMs: 520,
          speed: 122,
          hp: 1,
          scoreValue: 12,
          style: SpawnStyle.line,
        ),
        SpawnBatch(
          kind: EnemyKind.drone,
          count: 4,
          spawnIntervalMs: 380,
          speed: 142,
          hp: 1,
          scoreValue: 14,
          style: SpawnStyle.scatter,
          allowsPowerUpDrop: true,
        ),
      ],
    ),
    WaveBlueprint(
      title: 'Cruzamento Nebular',
      subtitle: 'Zigue-zague e primeiros elites.',
      batches: [
        SpawnBatch(
          kind: EnemyKind.drone,
          count: 6,
          spawnIntervalMs: 360,
          speed: 148,
          hp: 1,
          scoreValue: 16,
          style: SpawnStyle.zigzag,
        ),
        SpawnBatch(
          kind: EnemyKind.elite,
          count: 2,
          spawnIntervalMs: 820,
          speed: 108,
          hp: 3,
          scoreValue: 55,
          style: SpawnStyle.scatter,
          allowsPowerUpDrop: true,
        ),
      ],
    ),
    WaveBlueprint(
      title: 'Assalto Baixo',
      subtitle: 'Ataques rasantes e mergulhos.',
      batches: [
        SpawnBatch(
          kind: EnemyKind.drone,
          count: 6,
          spawnIntervalMs: 340,
          speed: 154,
          hp: 1,
          scoreValue: 18,
          style: SpawnStyle.dive,
        ),
        SpawnBatch(
          kind: EnemyKind.drone,
          count: 6,
          spawnIntervalMs: 300,
          speed: 168,
          hp: 2,
          scoreValue: 22,
          style: SpawnStyle.scatter,
        ),
        SpawnBatch(
          kind: EnemyKind.elite,
          count: 2,
          spawnIntervalMs: 900,
          speed: 116,
          hp: 4,
          scoreValue: 70,
          style: SpawnStyle.line,
          allowsPowerUpDrop: true,
        ),
      ],
    ),
    WaveBlueprint(
      title: 'Guardiões',
      subtitle: 'Escudos e contra-ataques.',
      batches: [
        SpawnBatch(
          kind: EnemyKind.elite,
          count: 3,
          spawnIntervalMs: 720,
          speed: 126,
          hp: 4,
          scoreValue: 80,
          style: SpawnStyle.scatter,
          allowsPowerUpDrop: true,
        ),
        SpawnBatch(
          kind: EnemyKind.drone,
          count: 8,
          spawnIntervalMs: 260,
          speed: 176,
          hp: 2,
          scoreValue: 24,
          style: SpawnStyle.zigzag,
        ),
      ],
    ),
    WaveBlueprint(
      title: 'Núcleo de Guerra',
      subtitle: 'Escorta pesada e boss de verdade.',
      batches: [
        SpawnBatch(
          kind: EnemyKind.drone,
          count: 4,
          spawnIntervalMs: 260,
          speed: 182,
          hp: 2,
          scoreValue: 26,
          style: SpawnStyle.scatter,
        ),
        SpawnBatch(
          kind: EnemyKind.elite,
          count: 3,
          spawnIntervalMs: 760,
          speed: 136,
          hp: 5,
          scoreValue: 100,
          style: SpawnStyle.dive,
          allowsPowerUpDrop: true,
        ),
        SpawnBatch(
          kind: EnemyKind.boss,
          count: 1,
          spawnIntervalMs: 0,
          speed: 38,
          hp: 30,
          scoreValue: 700,
          style: SpawnStyle.line,
          allowsPowerUpDrop: true,
        ),
      ],
    ),
  ];

  List<SpaceProjectile> get playerShots => List.unmodifiable(_playerShots);
  List<SpaceProjectile> get enemyShots => List.unmodifiable(_enemyShots);
  List<SpaceEnemy> get enemies => List.unmodifiable(_enemies);
  List<SpacePowerUpItem> get powerUps => List.unmodifiable(_powerUps);
  List<SpaceStar> get stars => List.unmodifiable(_stars);
  List<Offset> get playerTrail => List.unmodifiable(_playerTrail);
  List<BurstParticle> get particles => List.unmodifiable(_particles);
  List<ExplosionEffect> get explosions => List.unmodifiable(_explosions);

  String get currentWaveTitle => _waveIndex < _waves.length ? _waves[_waveIndex].title : 'Concluída';
  String get currentWaveSubtitle => _waveIndex < _waves.length ? _waves[_waveIndex].subtitle : 'A missão foi concluída.';
  int get currentWaveNumber => min(_waveIndex + 1, _waves.length);
  int get totalWaves => _waves.length;
  bool get hasShield => _shieldCharges > 0 && elapsedMs < _shieldUntilMs;
  bool get hasDoubleShot => elapsedMs < _doubleShotUntilMs;
  bool get hasLaser => elapsedMs < _laserUntilMs;
  SpaceEnemy? get bossEnemy {
    for (final enemy in _enemies) {
      if (enemy.kind == EnemyKind.boss) return enemy;
    }
    return null;
  }

  double get bossHealthRatio {
    final boss = bossEnemy;
    if (boss == null) return 0;
    return boss.hp / boss.maxHp;
  }

  List<String> get activePowerupLabels {
    final labels = <String>[];
    if (hasDoubleShot) labels.add('Tiro duplo');
    if (hasLaser) labels.add('Laser');
    if (hasShield) labels.add('Escudo');
    return labels;
  }

  double get viewportWidth => _width;
  double get viewportHeight => _height;

  double get hitFlashOpacity {
    if (_lastDamageFlashMs <= 0) return 0;
    final remain = (_lastDamageFlashMs - elapsedMs).clamp(0, 140);
    return remain / 140;
  }

  double get shieldGlowOpacity {
    if (!hasShield) return 0;
    final remain = (_shieldUntilMs - elapsedMs).clamp(0, 10000);
    return remain / 10000;
  }

  void setViewport(double width, double height) {
    final oldWidth = _width;
    final oldHeight = _height;
    _width = width;
    _height = height;

    if (!_viewportReady) {
      _createStars();
      reset();
      _viewportReady = true;
      return;
    }

    final ratioX = oldWidth == 0 ? 1.0 : width / oldWidth;
    final ratioY = oldHeight == 0 ? 1.0 : height / oldHeight;

    playerX = (playerX * ratioX).clamp(_playerWidth, _width - _playerWidth - 8);
    playerY = (playerY * ratioY).clamp(_playerHeight, _height - _playerHeight - 8);
  }

  void reset() {
    if (_width <= 0 || _height <= 0) return;

    _playerShots.clear();
    _enemyShots.clear();
    _enemies.clear();
    _powerUps.clear();
    _particles.clear();
    _explosions.clear();
    _playerTrail.clear();
    score = 0;
    level = 1;
    lives = 3;
    enemiesDestroyed = 0;
    damageTaken = 0;
    powerUpsCollected = 0;
    bombsTriggered = 0;
    bossesDefeated = 0;
    wavesCleared = 0;
    isGameOver = false;
    isPaused = false;
    isVictory = false;
    elapsedMs = 0;
    gameStartMs = DateTime.now().millisecondsSinceEpoch;
    _spawnAccumulatorMs = 0;
    _waveTransitionAtMs = 0;
    _waveIndex = 0;
    _batchIndex = 0;
    _remainingSpawnsInBatch = _waves.first.batches.first.count;
    _spawnedInBatch = 0;
    _invulnerableUntilMs = 0;
    _shieldUntilMs = 0;
    _doubleShotUntilMs = 0;
    _laserUntilMs = 0;
    _shieldCharges = 0;
    _lastDamageFlashMs = 0;
    _playerVelocityX = 0;
    _playerVelocityY = 0;
    playerX = _width * 0.16;
    playerY = _height * 0.5;
    _recordTrailPoint();
  }

  void togglePause() {
    if (isGameOver) return;
    isPaused = !isPaused;
  }

  void movePlayer(double dx, double dy) {
    if (isGameOver || isPaused) return;

    playerX = (playerX + dx).clamp(_playerWidth, _width - _playerWidth - 8);
    playerY = (playerY + dy).clamp(_playerHeight, _height - _playerHeight - 8);
    _playerVelocityX = 0;
    _playerVelocityY = 0;
    _recordTrailPoint();
  }

  void movePlayerTowards(double targetX, double targetY, double deltaSeconds) {
    if (isGameOver || isPaused || _width <= 0 || _height <= 0) return;

    final desiredX = targetX.clamp(_playerWidth, _width - _playerWidth - 8);
    final desiredY = targetY.clamp(_playerHeight, _height - _playerHeight - 8);
    const maxSpeed = 760.0;
    const acceleration = 3000.0;

    final dx = desiredX - playerX;
    final dy = desiredY - playerY;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance == 0) {
      _playerVelocityX *= 0.82;
      _playerVelocityY *= 0.82;
      return;
    }

    final desiredVelocityX = dx / distance * maxSpeed;
    final desiredVelocityY = dy / distance * maxSpeed;
    final blend = (acceleration * deltaSeconds / maxSpeed).clamp(0.0, 1.0);

    _playerVelocityX += (desiredVelocityX - _playerVelocityX) * blend;
    _playerVelocityY += (desiredVelocityY - _playerVelocityY) * blend;

    playerX = (playerX + _playerVelocityX * deltaSeconds).clamp(_playerWidth, _width - _playerWidth - 8);
    playerY = (playerY + _playerVelocityY * deltaSeconds).clamp(_playerHeight, _height - _playerHeight - 8);
    _recordTrailPoint();
  }

  void coastPlayer(double deltaSeconds) {
    if (isGameOver || isPaused || _width <= 0 || _height <= 0) return;

    _playerVelocityX *= 0.88;
    _playerVelocityY *= 0.88;

    if (_playerVelocityX.abs() < 0.6) _playerVelocityX = 0;
    if (_playerVelocityY.abs() < 0.6) _playerVelocityY = 0;

    playerX = (playerX + _playerVelocityX * deltaSeconds).clamp(_playerWidth, _width - _playerWidth - 8);
    playerY = (playerY + _playerVelocityY * deltaSeconds).clamp(_playerHeight, _height - _playerHeight - 8);
    _recordTrailPoint();
  }

  void shoot() {
    if (isGameOver || isPaused) return;

    if (hasLaser) {
      _playerShots.add(
        SpaceProjectile(
          x: playerX + _playerWidth * 0.72,
          y: playerY + _playerHeight / 2 - 5,
          vx: 14.0,
          vy: 0.0,
          fromPlayer: true,
          damage: 3,
          pierceHits: 4,
          width: 20,
          height: 10,
          color: const Color(0xFF7EE7FF),
          glow: true,
        ),
      );
      return;
    }

    if (hasDoubleShot) {
      _spawnPlayerShot(offsetY: -9, width: 12, damage: 1, pierceHits: 1, glow: false);
      _spawnPlayerShot(offsetY: 9, width: 12, damage: 1, pierceHits: 1, glow: false);
      return;
    }

    _spawnPlayerShot(offsetY: 0, width: 12, damage: 1, pierceHits: 1, glow: false);
  }

  void _spawnPlayerShot({
    required double offsetY,
    required double width,
    required int damage,
    required int pierceHits,
    required bool glow,
  }) {
    _playerShots.add(
      SpaceProjectile(
        x: playerX + _playerWidth * 0.72,
        y: playerY + _playerHeight / 2 - (width / 3) + offsetY,
        vx: 9.0,
        vy: 0.0,
        fromPlayer: true,
        damage: damage,
        pierceHits: pierceHits,
        width: glow ? 20 : width,
        height: glow ? 8 : 4,
        color: glow ? const Color(0xFF7EE7FF) : const Color(0xFFE0F2FE),
        glow: glow,
      ),
    );
  }

  void update(double deltaSeconds) {
    if (isGameOver || isPaused || _width <= 0 || _height <= 0) return;

    elapsedMs += (deltaSeconds * 1000).round();
    _spawnAccumulatorMs += deltaSeconds * 1000;

    _updateStars(deltaSeconds);
    _updatePowerUps(deltaSeconds);
    _updatePlayerShots(deltaSeconds);
    _updateEnemyShots(deltaSeconds);
    _updateEnemies(deltaSeconds);
    _handleCollisions();
    _updateParticles(deltaSeconds);
    _updateExplosions(deltaSeconds);
    _spawnWaveEnemies();
    _advanceWaveState();
    _checkVictoryCondition();
  }

  void _createStars() {
    _stars.clear();
    for (int i = 0; i < 90; i += 1) {
      _stars.add(
        SpaceStar(
          _random.nextDouble() * (_width == 0 ? 1 : _width),
          _random.nextDouble() * (_height == 0 ? 1 : _height),
          24 + _random.nextDouble() * 120,
          1 + _random.nextDouble() * 2.9,
        ),
      );
    }
  }

  void _spawnWaveEnemies() {
    if (_waveTransitionAtMs > 0) return;
    if (_waveIndex >= _waves.length) return;

    final wave = _waves[_waveIndex];
    if (_batchIndex >= wave.batches.length) return;

    final batch = wave.batches[_batchIndex];

    if (_remainingSpawnsInBatch <= 0) {
      _moveToNextBatch();
      return;
    }

    final intervalMs = max(90, batch.spawnIntervalMs);
    if (batch.kind == EnemyKind.boss && _spawnedInBatch == 0) {
      _spawnEnemy(batch, _spawnedInBatch);
      _spawnedInBatch += 1;
      _remainingSpawnsInBatch -= 1;
      _spawnAccumulatorMs = 0;
      _moveToNextBatch();
      return;
    }

    if (_spawnAccumulatorMs < intervalMs) return;

    _spawnAccumulatorMs = 0;
    _spawnEnemy(batch, _spawnedInBatch);
    _spawnedInBatch += 1;
    _remainingSpawnsInBatch -= 1;

    if (_remainingSpawnsInBatch <= 0) {
      _moveToNextBatch();
    }
  }

  void _moveToNextBatch() {
    _batchIndex += 1;
    _spawnedInBatch = 0;
    _spawnAccumulatorMs = 0;
    if (_waveIndex < _waves.length && _batchIndex < _waves[_waveIndex].batches.length) {
      _remainingSpawnsInBatch = _waves[_waveIndex].batches[_batchIndex].count;
    }
  }

  void _spawnEnemy(SpawnBatch batch, int spawnIndex) {
    final double y;
    switch (batch.style) {
      case SpawnStyle.line:
        y = (_height * (0.18 + ((spawnIndex % 5) * 0.12))).clamp(50.0, _height - 70);
        break;
      case SpawnStyle.zigzag:
        y = _height * 0.28 + sin((_elapsedFactor / 220) + spawnIndex * 0.8) * (_height * 0.18);
        break;
      case SpawnStyle.scatter:
        y = _random.nextDouble() * (_height * 0.76) + (_height * 0.12);
        break;
      case SpawnStyle.dive:
        y = _random.nextDouble() * (_height * 0.42) + (_height * 0.08);
        break;
    }

    final enemy = SpaceEnemy(
      x: _width + 60,
      y: y,
      vx: batch.kind == EnemyKind.boss ? batch.speed * 0.55 : -batch.speed,
      vy: batch.style == SpawnStyle.dive
          ? (_random.nextBool() ? 1 : -1) * (batch.speed * 0.22)
          : 0,
      hp: batch.hp,
      maxHp: batch.hp,
      scoreValue: batch.scoreValue,
      kind: batch.kind,
      style: batch.style,
    );

    enemy.driftSeed = _random.nextDouble() * pi * 2;
    enemy.homeY = y;

    if (enemy.kind == EnemyKind.boss) {
      enemy.x = _width + 80;
      enemy.y = _height * 0.26;
      enemy.vx = -batch.speed;
      enemy.vy = 0;
      enemy.patternCooldown = 0.6;
      enemy.fireCooldown = 0.4;
    }

    _enemies.add(enemy);
  }

  void _updateStars(double deltaSeconds) {
    for (final star in _stars) {
      star.x -= star.speed * deltaSeconds;
      if (star.x < -4) {
        star.x = _width + _random.nextDouble() * 24;
        star.y = _random.nextDouble() * _height;
      }
    }
  }

  void _updatePowerUps(double deltaSeconds) {
    for (final powerUp in _powerUps) {
      powerUp.age += deltaSeconds;
      powerUp.x += powerUp.vx * deltaSeconds;
      powerUp.y += powerUp.vy * deltaSeconds + sin((elapsedMs / 250) + powerUp.age * 8) * 0.4;
    }

    _powerUps.removeWhere((item) => item.x < -40 || item.y < -40 || item.x > _width + 40 || item.y > _height + 40 || item.age > 12);
  }

  void _updatePlayerShots(double deltaSeconds) {
    for (final shot in _playerShots) {
      shot.x += shot.vx * 60 * deltaSeconds;
      shot.y += shot.vy * 60 * deltaSeconds;
    }
    _playerShots.removeWhere((shot) => shot.x > _width + 34 || shot.y < -34 || shot.y > _height + 34 || shot.pierceHits <= 0);
  }

  void _updateEnemyShots(double deltaSeconds) {
    for (final shot in _enemyShots) {
      shot.x += shot.vx * 60 * deltaSeconds;
      shot.y += shot.vy * 60 * deltaSeconds;
    }
    _enemyShots.removeWhere((shot) => shot.x < -34 || shot.x > _width + 34 || shot.y < -34 || shot.y > _height + 34 || shot.pierceHits <= 0);
  }

  void _updateEnemies(double deltaSeconds) {
    final escapedEnemies = <SpaceEnemy>{};

    for (final enemy in _enemies) {
      if (enemy.kind == EnemyKind.boss) {
        _updateBoss(enemy, deltaSeconds);
        continue;
      }

      enemy.x += enemy.vx * deltaSeconds;

      if (enemy.style == SpawnStyle.dive) {
        final targetBias = (playerY - enemy.y) * 0.018;
        enemy.y += (enemy.vy + targetBias) * deltaSeconds * 1.6;
      } else if (enemy.style == SpawnStyle.zigzag) {
        enemy.y += sin((elapsedMs / 160) + enemy.driftSeed) * 0.9;
      } else {
        enemy.y += sin((elapsedMs / 220) + enemy.driftSeed) * 0.45;
      }

      enemy.fireCooldown -= deltaSeconds;
      if (enemy.kind == EnemyKind.elite && enemy.fireCooldown <= 0) {
        enemy.fireCooldown = 1.55 - (level * 0.08);
        _fireAimedEnemyShot(enemy, speed: 6.8, spread: 0.12);
      } else if (enemy.kind == EnemyKind.drone && level >= 3 && _random.nextDouble() < 0.007) {
        _fireAimedEnemyShot(enemy, speed: 5.8, spread: 0);
      }

      if (enemy.x < -90 || enemy.y < -90 || enemy.y > _height + 90) {
        escapedEnemies.add(enemy);
      }
    }

    _enemies.removeWhere(escapedEnemies.contains);
  }

  void _updateBoss(SpaceEnemy enemy, double deltaSeconds) {
    final targetX = _width * 0.67;
    if (enemy.x > targetX) {
      enemy.x += enemy.vx * deltaSeconds;
    } else {
      enemy.x += sin((elapsedMs / 500) + enemy.driftSeed) * 0.35;
    }

    enemy.y += sin((elapsedMs / 240) + enemy.driftSeed) * 0.8;

    if (enemy.y < _height * 0.12) enemy.y = _height * 0.12;
    if (enemy.y > _height * 0.68) enemy.y = _height * 0.68;

    enemy.patternCooldown -= deltaSeconds;
    if (enemy.patternCooldown <= 0) {
      _fireBossPattern(enemy);
      final pattern = _bossPatternFor(enemy);
      enemy.patternCooldown = switch (pattern) {
        BossPattern.spread => 1.25,
        BossPattern.aimedBurst => 1.0,
        BossPattern.radial => 1.55,
      };
    }

    if (enemy.x < _width * 0.55) {
      enemy.x = _width * 0.55;
    }
  }

  BossPattern _bossPatternFor(SpaceEnemy enemy) {
    final ratio = enemy.hp / enemy.maxHp;
    final cycle = (elapsedMs ~/ 2400) % 3;
    if (ratio <= 0.33) {
      return cycle == 0 ? BossPattern.radial : BossPattern.aimedBurst;
    }
    if (ratio <= 0.66) {
      return cycle == 0 ? BossPattern.aimedBurst : BossPattern.spread;
    }
    return cycle == 0 ? BossPattern.spread : BossPattern.aimedBurst;
  }

  void _fireBossPattern(SpaceEnemy enemy) {
    final pattern = _bossPatternFor(enemy);
    final originX = enemy.x - 4;
    final originY = enemy.y + enemy.height * 0.5;

    switch (pattern) {
      case BossPattern.spread:
        _enemyShots.addAll([
          _createEnemyBullet(originX, originY, -7.0, -1.6, 2, 10, 10, const Color(0xFFFFA36A)),
          _createEnemyBullet(originX, originY, -7.6, 0.0, 2, 10, 10, const Color(0xFFFFA36A)),
          _createEnemyBullet(originX, originY, -7.0, 1.6, 2, 10, 10, const Color(0xFFFFA36A)),
        ]);
        break;
      case BossPattern.aimedBurst:
        final dx = playerX - enemy.x;
        final dy = playerY - enemy.y;
        final distance = max(1.0, sqrt(dx * dx + dy * dy));
        final baseX = dx / distance;
        final baseY = dy / distance;
        for (final spread in [-0.18, -0.06, 0.06, 0.18]) {
          final angle = atan2(baseY, baseX) + spread;
          _enemyShots.add(
            _createEnemyBullet(
              originX,
              originY,
              cos(angle) * 7.5,
              sin(angle) * 7.5,
              2,
              10,
              10,
              const Color(0xFFFF5B7F),
            ),
          );
        }
        break;
      case BossPattern.radial:
        for (var i = 0; i < 8; i += 1) {
          final angle = (pi * 2 / 8) * i;
          _enemyShots.add(
            _createEnemyBullet(
              originX,
              originY,
              cos(angle) * 6.8,
              sin(angle) * 6.8,
              2,
              10,
              10,
              const Color(0xFFEA7CFF),
            ),
          );
        }
        break;
    }
  }

  SpaceProjectile _createEnemyBullet(
    double x,
    double y,
    double vx,
    double vy,
    int damage,
    double width,
    double height,
    Color color,
  ) {
    return SpaceProjectile(
      x: x,
      y: y,
      vx: vx,
      vy: vy,
      fromPlayer: false,
      damage: damage,
      pierceHits: 1,
      width: width,
      height: height,
      color: color,
    );
  }

  void _fireAimedEnemyShot(SpaceEnemy enemy, {required double speed, required double spread}) {
    final dx = playerX - enemy.x;
    final dy = playerY - enemy.y;
    final distance = max(1.0, sqrt(dx * dx + dy * dy));
    final baseX = dx / distance;
    final baseY = dy / distance;
    final angle = atan2(baseY, baseX) + spread;

    _enemyShots.add(
      _createEnemyBullet(
        enemy.x - 2,
        enemy.y + enemy.height * 0.5,
        cos(angle) * speed,
        sin(angle) * speed,
        1,
        9,
        9,
        const Color(0xFFFF8A5B),
      ),
    );
  }

  void _handleCollisions() {
    final deadProjectiles = <SpaceProjectile>{};
    final deadEnemies = <SpaceEnemy>{};
    final deadPowerUps = <SpacePowerUpItem>{};
    final playerRect = this.playerRect;

    for (final shot in _playerShots) {
      for (final enemy in _enemies) {
        if (!shot.rect.overlaps(enemy.rect)) continue;

        enemy.hp -= shot.damage;
        shot.pierceHits -= 1;
        _spawnHitEffects(shot.x, shot.y, shot.color, 5);
        _lastDamageFlashMs = elapsedMs + 120;

        if (enemy.hp <= 0) {
          deadEnemies.add(enemy);
          enemiesDestroyed += 1;
          score += enemy.scoreValue;
          _spawnExplosion(enemy.x + enemy.width / 2, enemy.y + enemy.height / 2, big: enemy.kind == EnemyKind.boss);
          _spawnKillBurst(enemy.x + enemy.width / 2, enemy.y + enemy.height / 2, enemy.kind);
          _maybeDropPowerUp(enemy);
          if (enemy.kind == EnemyKind.boss) {
            bossesDefeated += 1;
          }
        }

        if (shot.pierceHits <= 0) {
          deadProjectiles.add(shot);
        }
        break;
      }
    }

    for (final shot in _enemyShots) {
      if (!shot.rect.overlaps(playerRect)) continue;

      if (hasShield) {
        _shieldCharges = 0;
        _shieldUntilMs = 0;
        _spawnExplosion(playerX, playerY, big: false, color: const Color(0xFF7EE7FF));
        _spawnShieldBurst();
      } else if (elapsedMs >= _invulnerableUntilMs) {
        _applyDamage(shot.damage);
        _spawnExplosion(playerX, playerY, big: false, color: const Color(0xFFFF6B7A));
      }

      deadProjectiles.add(shot);
    }

    for (final enemy in _enemies) {
      if (!enemy.rect.overlaps(playerRect)) continue;

      if (hasShield) {
        _shieldCharges = 0;
        _shieldUntilMs = 0;
        _spawnExplosion(playerX, playerY, big: false, color: const Color(0xFF7EE7FF));
        _spawnShieldBurst();
      } else if (elapsedMs >= _invulnerableUntilMs) {
        _applyDamage(enemy.kind == EnemyKind.boss ? 2 : 1);
        _spawnExplosion(playerX, playerY, big: false, color: const Color(0xFFFF6B7A));
      }

      if (enemy.kind != EnemyKind.boss) {
        deadEnemies.add(enemy);
      }
    }

    for (final powerUp in _powerUps) {
      if (powerUp.rect.overlaps(playerRect)) {
        deadPowerUps.add(powerUp);
        _collectPowerUp(powerUp.type);
      }
    }

    _playerShots.removeWhere(deadProjectiles.contains);
    _enemyShots.removeWhere(deadProjectiles.contains);
    _enemies.removeWhere(deadEnemies.contains);
    _powerUps.removeWhere(deadPowerUps.contains);
  }

  void _collectPowerUp(PowerUpType type) {
    powerUpsCollected += 1;
    switch (type) {
      case PowerUpType.doubleShot:
        _doubleShotUntilMs = max(_doubleShotUntilMs, elapsedMs) + 9000;
        _spawnExplosion(playerX, playerY - 18, big: false, color: const Color(0xFF7EE7FF));
        break;
      case PowerUpType.laser:
        _laserUntilMs = max(_laserUntilMs, elapsedMs) + 6500;
        _spawnExplosion(playerX, playerY - 18, big: false, color: const Color(0xFFB5F7FF));
        break;
      case PowerUpType.shield:
        _shieldCharges = 1;
        _shieldUntilMs = max(_shieldUntilMs, elapsedMs) + 10000;
        _spawnShieldBurst();
        break;
      case PowerUpType.bomb:
        _triggerBomb();
        break;
    }
  }

  void _triggerBomb() {
    bombsTriggered += 1;
    _spawnExplosion(playerX, playerY, big: true, color: const Color(0xFFFFD166));
    final remainingEnemies = List<SpaceEnemy>.from(_enemies);
    for (final enemy in remainingEnemies) {
      enemy.hp = 0;
      _spawnExplosion(enemy.x + enemy.width / 2, enemy.y + enemy.height / 2, big: enemy.kind == EnemyKind.boss, color: const Color(0xFFFFD166));
      _spawnKillBurst(enemy.x + enemy.width / 2, enemy.y + enemy.height / 2, enemy.kind, intensity: 1.5);
      score += enemy.scoreValue;
      enemiesDestroyed += 1;
      _maybeDropPowerUp(enemy, forceRare: true);
      if (enemy.kind == EnemyKind.boss) {
        bossesDefeated += 1;
      }
    }

    _enemies.clear();
    _enemyShots.clear();
    _playerShots.removeWhere((shot) => shot.x > _width * 0.6);
  }

  void _maybeDropPowerUp(SpaceEnemy enemy, {bool forceRare = false}) {
    final chance = switch (enemy.kind) {
      EnemyKind.drone => 0.10,
      EnemyKind.elite => 0.28,
      EnemyKind.boss => 0.92,
    };
    if (!forceRare && _random.nextDouble() > chance) return;

    final type = _pickPowerUpType(enemy.kind);
    _powerUps.add(
      SpacePowerUpItem(
        x: enemy.x,
        y: enemy.y,
        vx: -1.6,
        vy: (_random.nextDouble() - 0.5) * 1.2,
        type: type,
      ),
    );
  }

  PowerUpType _pickPowerUpType(EnemyKind kind) {
    final roll = _random.nextInt(kind == EnemyKind.boss ? 100 : 100);
    if (kind == EnemyKind.boss) {
      if (roll < 30) return PowerUpType.laser;
      if (roll < 55) return PowerUpType.shield;
      if (roll < 80) return PowerUpType.doubleShot;
      return PowerUpType.bomb;
    }
    if (roll < 34) return PowerUpType.doubleShot;
    if (roll < 64) return PowerUpType.laser;
    if (roll < 86) return PowerUpType.shield;
    return PowerUpType.bomb;
  }

  void _spawnHitEffects(double x, double y, Color color, int count) {
    for (var i = 0; i < count; i += 1) {
      _particles.add(
        BurstParticle(
          x: x,
          y: y,
          vx: (_random.nextDouble() - 0.5) * 180,
          vy: (_random.nextDouble() - 0.5) * 180,
          life: 0.36 + _random.nextDouble() * 0.18,
          color: color,
          size: 2 + _random.nextDouble() * 2.8,
        ),
      );
    }
  }

  void _spawnKillBurst(double x, double y, EnemyKind kind, {double intensity = 1}) {
    final particleCount = switch (kind) {
      EnemyKind.drone => 10,
      EnemyKind.elite => 16,
      EnemyKind.boss => 28,
    };
    final color = switch (kind) {
      EnemyKind.drone => const Color(0xFFFF6B7A),
      EnemyKind.elite => const Color(0xFFFF9D6C),
      EnemyKind.boss => const Color(0xFFEA7CFF),
    };
    for (var i = 0; i < particleCount; i += 1) {
      final angle = (pi * 2 / particleCount) * i;
      final speed = (100 + _random.nextDouble() * 160) * intensity;
      _particles.add(
        BurstParticle(
          x: x,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          life: 0.5 + _random.nextDouble() * 0.35,
          color: color,
          size: 2 + _random.nextDouble() * 3.4,
        ),
      );
    }
  }

  void _spawnShieldBurst() {
    for (var i = 0; i < 14; i += 1) {
      final angle = (pi * 2 / 14) * i;
      _particles.add(
        BurstParticle(
          x: playerX,
          y: playerY,
          vx: cos(angle) * 120,
          vy: sin(angle) * 120,
          life: 0.42 + _random.nextDouble() * 0.18,
          color: const Color(0xFF7EE7FF),
          size: 2.5 + _random.nextDouble() * 2.2,
        ),
      );
    }
  }

  void _spawnExplosion(double x, double y, {required bool big, Color? color}) {
    _explosions.add(
      ExplosionEffect(
        x: x,
        y: y,
        radius: big ? 20 : 10,
        color: color ?? (big ? const Color(0xFFFFC857) : const Color(0xFFFF6B7A)),
      ),
    );
    _lastDamageFlashMs = elapsedMs + 130;
  }

  void _updateParticles(double deltaSeconds) {
    _particles.removeWhere((particle) => particle.update(deltaSeconds));
  }

  void _updateExplosions(double deltaSeconds) {
    _explosions.removeWhere((explosion) => explosion.update(deltaSeconds));
  }

  void _applyDamage(int amount) {
    if (isGameOver) return;

    _invulnerableUntilMs = elapsedMs + 650;
    damageTaken += amount;
    lives = max(0, lives - amount);
    _lastDamageFlashMs = elapsedMs + 140;

    if (lives <= 0) {
      lives = 0;
      isGameOver = true;
    }
  }

  void _advanceWaveState() {
    if (_waveIndex >= _waves.length) return;

    final wave = _waves[_waveIndex];
    final waveFinishedSpawning = _batchIndex >= wave.batches.length;
    if (waveFinishedSpawning && _enemies.isEmpty && _waveTransitionAtMs == 0) {
      _waveTransitionAtMs = elapsedMs + 1200;
    }

    if (_waveTransitionAtMs > 0 && elapsedMs >= _waveTransitionAtMs) {
      _waveTransitionAtMs = 0;
      wavesCleared += 1;
      _waveIndex += 1;
      level = min(maxLevel, _waveIndex + 1);

      if (_waveIndex >= _waves.length) {
        isVictory = true;
        isGameOver = true;
        return;
      }

      _batchIndex = 0;
      _spawnAccumulatorMs = 0;
      _spawnedInBatch = 0;
      _remainingSpawnsInBatch = _waves[_waveIndex].batches.first.count;
      _showWaveSplash();
    }
  }

  void _showWaveSplash() {
    if (_waveIndex < _waves.length) {
      _spawnExplosion(_width * 0.5, _height * 0.32, big: false, color: const Color(0xFF7EE7FF));
    }
  }

  void _checkVictoryCondition() {
    if (isGameOver || _waveIndex < _waves.length) return;
    isVictory = true;
    isGameOver = true;
  }

  Rect get playerRect => Rect.fromLTWH(playerX - 18, playerY - 14, _playerWidth, _playerHeight);

  void _recordTrailPoint() {
    _playerTrail.add(Offset(playerX, playerY));
    if (_playerTrail.length > 16) {
      _playerTrail.removeAt(0);
    }
  }

  double get _elapsedFactor => elapsedMs.toDouble();

  List<RewardChallenge> getChallenges() {
    return [
      RewardChallenge(
        id: 'destroy_20',
        title: 'Destrua 20 naves',
        bonusPoints: 120,
        isCompleted: enemiesDestroyed >= 20,
      ),
      RewardChallenge(
        id: 'reach_level_3',
        title: 'Alcance nível 3',
        bonusPoints: 140,
        isCompleted: level >= 3,
      ),
      RewardChallenge(
        id: 'survive_90s',
        title: 'Sobreviva 90 segundos',
        bonusPoints: 180,
        isCompleted: elapsedMs >= 90000,
      ),
      RewardChallenge(
        id: 'no_damage',
        title: 'Termine sem dano',
        bonusPoints: 220,
        isCompleted: isGameOver && damageTaken == 0,
      ),
    ];
  }

  int get bonusPoints {
    return getChallenges().where((challenge) => challenge.isCompleted).fold<int>(0, (sum, challenge) => sum + challenge.bonusPoints);
  }

  int get bonusCoins => (bonusPoints / 10).floor();

  Duration get duration => Duration(milliseconds: elapsedMs);

  Map<String, dynamic> getGameStats() {
    return {
      'score': score,
      'level': level,
      'lives': lives,
      'enemiesDestroyed': enemiesDestroyed,
      'damageTaken': damageTaken,
      'duration': duration.inSeconds,
      'bonusPoints': bonusPoints,
      'bonusCoins': bonusCoins,
      'isVictory': isVictory,
      'powerUpsCollected': powerUpsCollected,
      'bombsTriggered': bombsTriggered,
      'bossesDefeated': bossesDefeated,
      'wavesCleared': wavesCleared,
      'currentWave': currentWaveNumber,
      'challenges': getChallenges()
          .map(
            (challenge) => {
              'id': challenge.id,
              'title': challenge.title,
              'bonusPoints': challenge.bonusPoints,
              'completed': challenge.isCompleted,
            },
          )
          .toList(),
    };
  }
}
