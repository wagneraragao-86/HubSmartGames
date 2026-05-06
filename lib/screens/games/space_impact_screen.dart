import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../games/space_impact_game.dart';
import '../../models/score.dart';
import '../../providers/player_provider.dart';
import '../../providers/score_provider.dart';
import '../../services/ads_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/game_intro_dialog.dart';

class SpaceImpactScreen extends StatefulWidget {
  const SpaceImpactScreen({Key? key}) : super(key: key);

  @override
  State<SpaceImpactScreen> createState() => _SpaceImpactScreenState();
}

class _SpaceImpactScreenState extends State<SpaceImpactScreen> {
  static const String _gameId = 'space_impact';
  static const Duration _tick = Duration(milliseconds: 50);
  static const Duration _shootInterval = Duration(milliseconds: 110);

  late SpaceImpactGame game;
  Timer? _timer;
  bool _dialogOpen = false;
  bool _touchActive = false;
  Offset _touchTarget = Offset.zero;
  int _lastTouchShotMs = 0;

  @override
  void initState() {
    super.initState();
    game = SpaceImpactGame();
    _startLoop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showGameIntroDialogIfNeeded(
        context,
        const GameIntroDialogData(
          gameId: 'space_impact',
          title: 'Como jogar Space Impact',
          subtitle: 'A nave fica embaixo e os inimigos descem do topo.',
          instructions: [
            'Arraste o dedo para mover a nave na area do jogo.',
            'Segure a tela para disparo continuo.',
            'Deslize para desviar dos inimigos e projeteis.',
            'Toque duas vezes para pausar a partida.',
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted) return;

      setState(() {
        _advanceGame();
      });

      if (game.isGameOver && !_dialogOpen) {
        _dialogOpen = true;
        _timer?.cancel();
        _showGameOverDialog();
      }
    });
  }

  void _advanceGame() {
    final deltaSeconds = _tick.inMilliseconds / 1000;

    if (_touchActive) {
      game.movePlayerTowards(_touchTarget.dx, _touchTarget.dy, deltaSeconds);

      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastTouchShotMs >= _shootInterval.inMilliseconds) {
        game.shoot();
        _lastTouchShotMs = now;
      }
    } else {
      game.coastPlayer(deltaSeconds);
    }

    game.update(deltaSeconds);
  }

  void _syncViewport(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    if (width <= 0 || height <= 0) return;
    if (game.viewportWidth == width && game.viewportHeight == height) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        game.setViewport(width, height);
      });
    });
  }

  Future<void> _showGameOverDialog() async {
    final playerProvider = context.read<PlayerProvider>();
    final scoreProvider = context.read<ScoreProvider>();
    final adsService = context.read<AdsService>();
    final stats = game.getGameStats();
    final challenges = List<Map<String, dynamic>>.from(stats['challenges'] as List);

    await adsService.showInterstitialAd();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(game.isVictory ? 'Missão concluída' : 'Game Over'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pontuação base: ${stats['score']}'),
              Text('Nível: ${stats['level']}'),
              Text('Ondas concluídas: ${stats['wavesCleared']}'),
              Text('Power-ups coletados: ${stats['powerUpsCollected']}'),
              Text('Boss derrotado: ${stats['bossesDefeated']}'),
              Text('Dano sofrido: ${stats['damageTaken']}'),
              Text('Tempo: ${stats['duration']}s'),
              const SizedBox(height: 12),
              const Text(
                'Recompensas por desafios',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ...challenges.map((challenge) {
                final completed = challenge['completed'] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${completed ? '✓' : '•'} ${challenge['title']}'
                    '${completed ? ' (+${challenge['bonusPoints']} pts)' : ''}',
                  ),
                );
              }),
              const SizedBox(height: 12),
              Text(
                'Bônus total: ${stats['bonusPoints']} pts | ${stats['bonusCoins']} moedas',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () async {
              final currentPlayer = playerProvider.currentPlayer;
              if (currentPlayer != null) {
                final score = Score(
                  playerId: playerProvider.currentUserId,
                  playerName: currentPlayer.name,
                  gameId: _gameId,
                  points: (stats['score'] as int) + (stats['bonusPoints'] as int),
                  duration: stats['duration'] as int,
                  metadata: {
                    'level': stats['level'],
                    'wavesCleared': stats['wavesCleared'],
                    'powerUpsCollected': stats['powerUpsCollected'],
                    'bombsTriggered': stats['bombsTriggered'],
                    'bossesDefeated': stats['bossesDefeated'],
                    'damageTaken': stats['damageTaken'],
                    'bonusPoints': stats['bonusPoints'],
                    'bonusCoins': stats['bonusCoins'],
                    'isVictory': stats['isVictory'],
                  },
                );
                await scoreProvider.saveScore(score);
              }

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Score salvo!')),
              );
            },
            child: const Text('Salvar Score'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restartGame();
            },
            child: const Text('Jogar Novamente'),
          ),
        ],
      ),
    ).then((_) {
      _dialogOpen = false;
    });
  }

  void _restartGame() {
    setState(() {
      game = SpaceImpactGame();
      _dialogOpen = false;
      _touchActive = false;
      _touchTarget = Offset.zero;
      _lastTouchShotMs = 0;
    });
    _startLoop();
  }

  void _onTouchStart(Offset position) {
    if (game.isGameOver || game.isPaused) return;
    _touchActive = true;
    _touchTarget = position;
    _lastTouchShotMs = DateTime.now().millisecondsSinceEpoch;
    game.shoot();
  }

  void _onTouchUpdate(DragUpdateDetails details) {
    if (game.isGameOver || game.isPaused) return;
    _touchTarget = details.localPosition;
  }

  void _onTouchEnd([dynamic _]) {
    _touchActive = false;
  }

  List<Widget> _buildPowerupChips() {
    final labels = game.activePowerupLabels;
    if (labels.isEmpty) {
      return [
        Chip(
          label: const Text('Sem power-ups ativos'),
          backgroundColor: AppTheme.cardBackground,
          side: const BorderSide(color: AppTheme.border),
        ),
      ];
    }

    return labels
        .map(
          (label) => Chip(
            label: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            avatar: const Icon(Icons.bolt, size: 18, color: AppTheme.accentCyan),
            backgroundColor: AppTheme.cardBackground,
            side: const BorderSide(color: AppTheme.accentCyan),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Space Impact'),
        actions: [
          _buildStatBadge('Score', game.score + game.bonusPoints),
          _buildStatBadge('Coins', game.bonusCoins),
          _buildStatBadge('Lives', game.lives),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${game.currentWaveNumber}/${game.totalWaves} - ${game.currentWaveTitle}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  game.currentWaveSubtitle,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildPowerupChips(),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _syncViewport(constraints);
                return Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF060B16), Color(0xFF0B1528)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (details) => _onTouchStart(details.localPosition),
                      onPanUpdate: _onTouchUpdate,
                      onPanEnd: _onTouchEnd,
                      onPanCancel: _onTouchEnd,
                      onDoubleTap: () => setState(game.togglePause),
                      child: Stack(
                        children: [
                          CustomPaint(
                            painter: SpaceImpactPainter(game),
                            child: const SizedBox.expand(),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(90),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Text(
                                  'Toque e arraste para mover. Segure para disparo contínuo. Toque duas vezes para pausar.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textPrimary.withAlpha(220),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, int value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class SpaceImpactPainter extends CustomPainter {
  SpaceImpactPainter(this.game);

  final SpaceImpactGame game;

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackgroundFlow(canvas, size);
    _drawStars(canvas);
    _drawExplosions(canvas);
    _drawParticles(canvas);
    _drawPowerUps(canvas);
    _drawEnemies(canvas);
    _drawShots(canvas);
    _drawPlayer(canvas);
    _drawBossBar(canvas, size);
    _drawOverlay(canvas, size);
  }

  void _drawBackgroundFlow(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF040812).withAlpha(255),
          const Color(0xFF081121).withAlpha(255),
          const Color(0xFF0C1830).withAlpha(255),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, basePaint);

    final flowOffset = (game.elapsedMilliseconds * 0.06) % 42;
    final linePaint = Paint()
      ..color = const Color(0xFF7EE7FF).withAlpha(12)
      ..strokeWidth = 1;
    for (double y = -42 + flowOffset; y < size.height + 42; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final lanePaint = Paint()
      ..color = const Color(0xFF7EE7FF).withAlpha(18)
      ..strokeWidth = 1.2;
    for (double x = 0; x <= size.width; x += size.width / 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), lanePaint);
    }

    final centerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7EE7FF).withAlpha(26),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.78), width: size.width * 0.8, height: size.height * 0.7));
    canvas.drawRect(Offset.zero & size, centerGlow);
  }

  void _drawStars(Canvas canvas) {
    for (final star in game.stars) {
      final paint = Paint()..color = Colors.white.withAlpha((180 + star.size * 20).round());
      canvas.drawCircle(Offset(star.x, star.y), star.size, paint);
    }
  }

  void _drawExplosions(Canvas canvas) {
    for (final explosion in game.explosions) {
      final t = explosion.progress;
      final alpha = ((1 - t) * 220).round();
      final paint = Paint()
        ..color = explosion.color.withAlpha(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 * (1 - t) + 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(explosion.x, explosion.y), explosion.radius, paint);
    }
  }

  void _drawParticles(Canvas canvas) {
    for (final particle in game.particles) {
      final alpha = (255 * particle.progress).round();
      final paint = Paint()
        ..color = particle.color.withAlpha(alpha)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(particle.x, particle.y), particle.size * (0.6 + particle.progress * 0.8), paint);
    }
  }

  void _drawPowerUps(Canvas canvas) {
    for (final item in game.powerUps) {
      final rect = item.rect;
      final color = switch (item.type) {
        PowerUpType.doubleShot => const Color(0xFF7EE7FF),
        PowerUpType.laser => const Color(0xFFB0FF8F),
        PowerUpType.shield => const Color(0xFFEA7CFF),
        PowerUpType.bomb => const Color(0xFFFFD166),
      };

      final glowPaint = Paint()
        ..color = color.withAlpha(90)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      final mainPaint = Paint()..color = color;
      final innerPaint = Paint()..color = Colors.white.withAlpha(220);

      canvas.drawCircle(rect.center, rect.width * 0.78, glowPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(1), const Radius.circular(8)),
        mainPaint,
      );
      canvas.drawCircle(rect.center, rect.width * 0.22, innerPaint);
    }
  }

  void _drawEnemies(Canvas canvas) {
    for (final enemy in game.enemies) {
      final rect = enemy.rect;
      final entryProgress = (enemy.spawnAge / 0.45).clamp(0.0, 1.0);
      final scale = 1.12 - (entryProgress * 0.12);
      final glowAlpha = (110 * (1 - entryProgress)).round();
      final scaledRect = Rect.fromCenter(
        center: rect.center,
        width: rect.width * scale,
        height: rect.height * scale,
      );
      final colors = switch (enemy.kind) {
        EnemyKind.drone => [const Color(0xFFFB7185), const Color(0xFFBE123C)],
        EnemyKind.elite => [const Color(0xFFFFB35B), const Color(0xFFEA580C)],
        EnemyKind.boss => [const Color(0xFFA855F7), const Color(0xFF6D28D9)],
      };

      final glowPaint = Paint()
        ..color = colors.first.withAlpha(glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(scaledRect.inflate(8), const Radius.circular(14)),
        glowPaint,
      );

      final paint = Paint()
        ..shader = LinearGradient(colors: colors).createShader(scaledRect);

      canvas.drawRRect(
        RRect.fromRectAndRadius(scaledRect, const Radius.circular(10)),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(scaledRect.deflate(6), const Radius.circular(7)),
        Paint()..color = Colors.white.withAlpha(150),
      );
      canvas.drawCircle(Offset(scaledRect.left + 14, scaledRect.center.dy), 3, Paint()..color = Colors.black);
      canvas.drawCircle(Offset(scaledRect.left + 30, scaledRect.center.dy), 3, Paint()..color = Colors.black);
    }
  }

  void _drawShots(Canvas canvas) {
    for (final shot in game.playerShots) {
      final rect = shot.rect;
      final paint = Paint()
        ..color = shot.color
        ..maskFilter = shot.glow ? const MaskFilter.blur(BlurStyle.normal, 7) : null;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
      if (shot.glow) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(6)),
          Paint()..color = shot.color.withAlpha(90),
        );
      }
    }

    for (final shot in game.enemyShots) {
      final rect = shot.rect;
      final paint = Paint()
        ..color = shot.color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(5)),
        Paint()..color = shot.color.withAlpha(90),
      );
    }
  }

  void _drawPlayer(Canvas canvas) {
    final rect = game.playerRect;
    for (var i = 0; i < game.playerTrail.length; i++) {
      final point = game.playerTrail[i];
      final fade = (i + 1) / game.playerTrail.length;
      final glowPaint = Paint()
        ..color = const Color(0xFF7EE7FF).withAlpha((60 * fade).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(point.dx, point.dy), 8 * fade, glowPaint);
    }

    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF7DD3FC), Color(0xFF1D4ED8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final wingPaint = Paint()..color = const Color(0xFF9AE6FF).withAlpha(230);
    final cockpitPaint = Paint()..color = const Color(0xFFE0F2FE);

    final ship = Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.left, rect.bottom - 2)
      ..lineTo(rect.center.dx, rect.bottom - 6)
      ..lineTo(rect.right, rect.bottom - 2)
      ..close();
    canvas.drawShadow(ship, Colors.black, 4, false);
    canvas.drawPath(ship, bodyPaint);
    canvas.drawPath(
      Path()
        ..moveTo(rect.center.dx, rect.top + 4)
        ..lineTo(rect.center.dx - 8, rect.bottom - 2)
        ..lineTo(rect.center.dx + 8, rect.bottom - 2)
        ..close(),
      Paint()..color = const Color(0xFFBFDBFE).withAlpha(220),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: rect.center, width: 12, height: 10),
        const Radius.circular(6),
      ),
      cockpitPaint,
    );
    canvas.drawCircle(Offset(rect.center.dx - 10, rect.bottom - 8), 3, wingPaint);
    canvas.drawCircle(Offset(rect.center.dx + 10, rect.bottom - 8), 3, wingPaint);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(rect.center.dx, rect.bottom + 4), width: 8, height: 10),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF7EE7FF), Color(0x00000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromCenter(center: Offset(rect.center.dx, rect.bottom + 4), width: 8, height: 12))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    if (game.hasShield) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xFF7EE7FF).withAlpha((100 + 80 * game.shieldGlowOpacity).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(rect.center, 24 + 4 * game.shieldGlowOpacity, ringPaint);
    }
  }

  void _drawBossBar(Canvas canvas, Size size) {
    final ratio = game.bossHealthRatio;
    if (ratio <= 0 || game.isVictory) return;

    final barWidth = size.width * 0.42;
    final barHeight = 10.0;
    final left = (size.width - barWidth) / 2;
    const top = 18.0;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, barWidth, barHeight),
      const Radius.circular(999),
    );
    final fgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, barWidth * ratio, barHeight),
      const Radius.circular(999),
    );

    canvas.drawRRect(bgRect, Paint()..color = Colors.black.withAlpha(120));
    canvas.drawRRect(
      fgRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFEA7CFF), Color(0xFF7EE7FF)],
        ).createShader(Rect.fromLTWH(left, top, barWidth, barHeight)),
    );
    canvas.drawRRect(
      bgRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withAlpha(150),
    );
  }

  void _drawOverlay(Canvas canvas, Size size) {
    if (game.hitFlashOpacity > 0) {
      final paint = Paint()..color = const Color(0xFFFF5B7F).withAlpha((80 * game.hitFlashOpacity).round());
      canvas.drawRect(Offset.zero & size, paint);
    }

    if (game.isPaused) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'PAUSADO',
          style: TextStyle(
            color: Colors.white.withAlpha(220),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, size.height * 0.10));
    }
  }

  @override
  bool shouldRepaint(covariant SpaceImpactPainter oldDelegate) => true;
}
