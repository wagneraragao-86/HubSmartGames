import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../games/snake_game.dart';
import '../../models/score.dart';
import '../../providers/player_provider.dart';
import '../../providers/score_provider.dart';
import '../../services/ads_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/game_intro_dialog.dart';

class SnakeScreen extends StatefulWidget {
  const SnakeScreen({Key? key}) : super(key: key);

  @override
  State<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends State<SnakeScreen> {
  late SnakeGame game;
  late Timer gameTimer;
  int gameDifficulty = 300;
  static const List<int> snakeSpeeds = [500, 300, 250, 200, 150];
  Offset? _swipeStart;
  bool _swipeLocked = false;

  @override
  void initState() {
    super.initState();
    game = SnakeGame();
    _startGameLoop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showGameIntroDialogIfNeeded(
        context,
        const GameIntroDialogData(
          gameId: 'snake',
          title: 'Como jogar Snake',
          subtitle: 'Controle a cobra com gestos na tela.',
          instructions: [
            'Deslize o dedo na area do jogo para mudar a direção.',
            'Coma os pontos para crescer e aumentar a pontuação.',
            'Evite bater nas bordas ou no proprio corpo.',
            'Use o botão de pausa se precisar parar a partida.',
          ],
        ),
      );
    });
  }

  void _startGameLoop() {
    gameTimer = Timer.periodic(Duration(milliseconds: gameDifficulty), (_) {
      if (!mounted) return;
      setState(() {
        game.update();
        if (game.isGameOver) {
          gameTimer.cancel();
          _showGameOverDialog();
        }
      });
    });
  }

  void _changeSpeed(int speed) {
    if (gameDifficulty == speed) return;
    gameTimer.cancel();
    setState(() {
      gameDifficulty = speed;
    });
    if (!game.isGameOver) {
      _startGameLoop();
    }
  }

  void _handleSwipeStart(DragStartDetails details) {
    _swipeStart = details.localPosition;
    _swipeLocked = false;
  }

  void _handleSwipeUpdate(DragUpdateDetails details) {
    if (_swipeLocked || _swipeStart == null || game.isPaused || game.isGameOver) {
      return;
    }

    final delta = details.localPosition - _swipeStart!;
    if (delta.distance < 24) {
      return;
    }

    _swipeLocked = true;

    if (delta.dx.abs() > delta.dy.abs()) {
      game.changeDirection(delta.dx > 0 ? Direction.right : Direction.left);
    } else {
      game.changeDirection(delta.dy > 0 ? Direction.down : Direction.up);
    }

    setState(() {});
  }

  void _handleSwipeEnd(DragEndDetails details) {
    _swipeStart = null;
    _swipeLocked = false;
  }

  String _snakeSpeedLabel(int speed) {
    switch (speed) {
      case 500:
        return 'Facil';
      case 300:
        return 'Normal';
      case 250:
        return 'Rapido';
      case 200:
        return 'Agil';
      case 150:
        return 'Maximo';
      default:
        return '$speed ms';
    }
  }

  IconData _snakeSpeedIcon(int speed) {
    switch (speed) {
      case 500:
        return Icons.slow_motion_video;
      case 300:
        return Icons.speed;
      case 250:
        return Icons.flash_on;
      case 200:
        return Icons.bolt;
      case 150:
        return Icons.rocket;
      default:
        return Icons.speed;
    }
  }

  void _showGameOverDialog() async {
    final playerProvider = context.read<PlayerProvider>();
    final scoreProvider = context.read<ScoreProvider>();
    final adsService = context.read<AdsService>();

    final stats = game.getGameStats();

    await adsService.showInterstitialAd();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: ${stats['score']}'),
            Text('Level: ${stats['level']}'),
            Text('Snake Length: ${stats['snakeLength']}'),
            Text('Duration: ${stats['duration']}s'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (playerProvider.currentPlayer != null) {
                final score = Score(
                  playerId: playerProvider.currentUserId,
                  playerName: playerProvider.currentPlayer!.name,
                  gameId: 'snake',
                  points: stats['score'],
                  duration: stats['duration'],
                  metadata: {
                    'level': stats['level'],
                    'snakeLength': stats['snakeLength'],
                  },
                );
                scoreProvider.saveScore(score);
              }

              Navigator.pushReplacementNamed(context, '/');
            },
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () {
              if (playerProvider.currentPlayer != null) {
                final score = Score(
                  playerId: playerProvider.currentUserId,
                  playerName: playerProvider.currentPlayer!.name,
                  gameId: 'snake',
                  points: stats['score'],
                  duration: stats['duration'],
                  metadata: {
                    'level': stats['level'],
                    'snakeLength': stats['snakeLength'],
                  },
                );
                scoreProvider.saveScore(score);
              }

              Navigator.pop(context);
              setState(() {
                gameTimer.cancel();
                game = SnakeGame();
                _startGameLoop();
              });
            },
            child: const Text('Jogar Novamente'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    gameTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (mounted) {
          gameTimer.cancel();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Snake'),
          leading: BackButton(
            onPressed: () {
              if (mounted) {
                gameTimer.cancel();
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                'Score: ${game.score}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                'Level: ${game.level}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                'Snake: ${game.snake.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _handleSwipeStart,
                onPanUpdate: _handleSwipeUpdate,
                onPanEnd: _handleSwipeEnd,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.textPrimary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    painter: SnakePainter(game),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.surface,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Velocidade da Cobra',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: gameDifficulty,
                            isExpanded: true,
                            icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.accentCyan),
                            dropdownColor: AppTheme.cardBackground,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            items: snakeSpeeds.map((speed) {
                              return DropdownMenuItem<int>(
                                value: speed,
                                child: Row(
                                  children: [
                                    Icon(
                                      _snakeSpeedIcon(speed),
                                      size: 18,
                                      color: AppTheme.accentCyan,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${_snakeSpeedLabel(speed)} (${speed}ms)'),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _changeSpeed(value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.pause, size: 24),
                        onPressed: () {
                          setState(() {
                            game.togglePause();
                          });
                        },
                      ),
                    ],
                  ),
                  Text(
                    game.isPaused ? 'PAUSADO' : '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentRed,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Deslize o dedo na area do jogo para controlar a cobra.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SnakePainter extends CustomPainter {
  final SnakeGame game;

  SnakePainter(this.game);

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / SnakeGame.gridSize;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppTheme.surface,
    );

    for (int i = 0; i <= SnakeGame.gridSize; i++) {
      final offset = i * cellSize;
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset, size.height),
        Paint()
          ..color = AppTheme.border
          ..strokeWidth = 0.5,
      );
      canvas.drawLine(
        Offset(0, offset),
        Offset(size.width, offset),
        Paint()
          ..color = AppTheme.border
          ..strokeWidth = 0.5,
      );
    }

    for (int i = 0; i < game.snake.length; i++) {
      final point = game.snake[i];
      final isHead = i == 0;
      final rect = Rect.fromLTWH(
        point.x * cellSize + 1,
        point.y * cellSize + 1,
        cellSize - 2,
        cellSize - 2,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = isHead ? AppTheme.accentGreen : AppTheme.accentPurple,
      );
    }

    final foodRect = Rect.fromLTWH(
      game.food.x * cellSize + 2,
      game.food.y * cellSize + 2,
      cellSize - 4,
      cellSize - 4,
    );
    canvas.drawCircle(
      foodRect.center,
      cellSize / 3,
      Paint()..color = AppTheme.accentRed,
    );
  }

  @override
  bool shouldRepaint(SnakePainter oldDelegate) => true;
}
