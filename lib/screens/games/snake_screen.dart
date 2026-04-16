import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../games/snake_game.dart';
import '../../models/score.dart';
import '../../providers/player_provider.dart';
import '../../providers/score_provider.dart';
import '../../theme/app_theme.dart';

class SnakeScreen extends StatefulWidget {
  const SnakeScreen({Key? key}) : super(key: key);

  @override
  State<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends State<SnakeScreen> {
  late SnakeGame game;
  late Timer gameTimer;
  int gameDifficulty = 300; // milliseconds entre updates
  static const List<int> snakeSpeeds = [500, 300, 250, 200, 150];

  @override
  void initState() {
    super.initState();
    game = SnakeGame();
    _startGameLoop();
  }

  void _startGameLoop() {
    gameTimer = Timer.periodic(Duration(milliseconds: gameDifficulty), (_) {
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

  String _snakeSpeedLabel(int speed) {
    switch (speed) {
      case 500:
        return 'Fácil';
      case 300:
        return 'Normal';
      case 250:
        return 'Rápido';
      case 200:
        return 'Ágil';
      case 150:
        return 'Máximo';
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

  void _showGameOverDialog() {
    final playerProvider = context.read<PlayerProvider>();
    final scoreProvider = context.read<ScoreProvider>();

    final stats = game.getGameStats();

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
              // Salvar score
              if (playerProvider.currentPlayer != null) {
                final score = Score(
                  playerId: playerProvider.currentPlayer!.id,
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
              // Salvar score e jogar novamente
              if (playerProvider.currentPlayer != null) {
                final score = Score(
                  playerId: playerProvider.currentPlayer!.id,
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
        ),
        body: Column(
          children: [
            // Difficulty selector
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Velocidade da Cobra',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: snakeSpeeds.map((speed) {
                      final isSelected = gameDifficulty == speed;
                      return ChoiceChip(
                        avatar: Icon(
                          _snakeSpeedIcon(speed),
                          size: 18,
                          color: isSelected ? AppTheme.textPrimary : AppTheme.accentCyan,
                        ),
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_snakeSpeedLabel(speed)}'),
                            Text('$speed ms',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary)),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (_) => _changeSpeed(speed),
                        selectedColor: AppTheme.accentCyan,
                        backgroundColor: AppTheme.cardBackground,
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppTheme.accentCyan : AppTheme.border,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            // Score e Info
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Score: ${game.score}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Level: ${game.level}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Snake: ${game.snake.length}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Game Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
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
            // Controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_upward),
                        onPressed: () => game.changeDirection(Direction.up),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => game.changeDirection(Direction.left),
                      ),
                      IconButton(
                        icon: const Icon(Icons.pause),
                        onPressed: () {
                          setState(() {
                            game.togglePause();
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => game.changeDirection(Direction.right),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_downward),
                        onPressed: () => game.changeDirection(Direction.down),
                      ),
                    ],
                  ),
                  Text(
                    game.isPaused ? 'PAUSADO' : '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentRed,
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

    // Background
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

    // Snake
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
        RRect.fromRectAndRadius(rect, Radius.circular(4)),
        Paint()..color = isHead ? AppTheme.accentGreen : AppTheme.accentPurple,
      );
    }

    // Food
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
