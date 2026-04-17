import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../games/hidro_flux_game.dart';
import '../../models/score.dart';
import '../../providers/player_provider.dart';
import '../../providers/score_provider.dart';
import '../../theme/app_theme.dart';

class HidroFluxScreen extends StatefulWidget {
  const HidroFluxScreen({Key? key}) : super(key: key);

  @override
  State<HidroFluxScreen> createState() => _HidroFluxScreenState();
}

class _HidroFluxScreenState extends State<HidroFluxScreen> with SingleTickerProviderStateMixin {
  int _levelIndex = 0;
  late HidroFluxLevel _level;
  late List<List<PipeDirection>> _grid;
  bool _solved = false;
  int _rotationCount = 0;
  int _lastPathTime = 0;
  List<Point<int>> _flowPath = [];
  int _flowStep = -1;
  late final AnimationController _flowController;
  String _statusMessage = 'Toque em um cano para girar. Depois clique em TESTAR CAMINHO.';
  Set<Point<int>> _currentPath = {};

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addListener(_updateFlowStep);
    _loadLevel();
  }

  void _loadLevel() {
    _level = HidroFluxGame.levels[_levelIndex];
    _grid = _level.grid.map((row) => row.toList()).toList();
    _solved = false;
    _rotationCount = 0;
    _lastPathTime = 0;
    _flowPath = [];
    _flowStep = -1;
    _statusMessage = 'Toque em um cano para girar. Depois clique em TESTAR CAMINHO.';
    _currentPath.clear();
    _stopFlowAnimation();
  }

  void _rotateTile(int row, int col) {
    if (_solved) return;
    setState(() {
      _grid[row][col] = _grid[row][col].rotateClockwise();
      _rotationCount += 1;
    });
  }

  void _nextLevel() {
    if (_levelIndex < HidroFluxGame.levels.length - 1) {
      setState(() {
        _levelIndex += 1;
        _loadLevel();
      });
    }
  }

  void _resetLevel() {
    setState(() {
      _loadLevel();
    });
  }

  void _updateFlowStep() {
    if (_flowPath.isEmpty) return;
    final step = (_flowController.value * _flowPath.length).floor();
    setState(() {
      _flowStep = step.clamp(0, _flowPath.length - 1);
    });
  }

  void _startFlowAnimation() {
    if (_flowPath.isEmpty) return;
    _flowController.repeat();
  }

  void _stopFlowAnimation() {
    if (_flowController.isAnimating) {
      _flowController.stop();
    }
  }

  void _testPath() {
    final visited = <Point<int>>{};
    final path = <Point<int>>[];
    Point<int> position = _level.start;
    final stopwatch = Stopwatch()..start();

    while (true) {
      if (position == _level.goal) {
        stopwatch.stop();
        setState(() {
          _solved = true;
          _flowPath = path;
          _flowStep = 0;
          _currentPath = path.toSet();
          _lastPathTime = stopwatch.elapsedMilliseconds;
          _statusMessage = 'Sucesso! Caminho encontrado em ${_lastPathTime}ms.';
        });
        _startFlowAnimation();
        return;
      }

      if (position.x < 0 || position.x >= _level.width || position.y < 0 || position.y >= _level.height) {
        stopwatch.stop();
        setState(() {
          _solved = false;
          _flowPath = path;
          _flowStep = 0;
          _currentPath = path.toSet();
          _statusMessage = 'Saída do tabuleiro! Ajuste os canos e tente novamente.';
        });
        _startFlowAnimation();
        return;
      }

      if (visited.contains(position)) {
        stopwatch.stop();
        setState(() {
          _solved = false;
          _flowPath = path;
          _flowStep = 0;
          _currentPath = path.toSet();
          _statusMessage = 'Loop detectado! Gere um novo caminho.';
        });
        _startFlowAnimation();
        return;
      }

      visited.add(position);
      path.add(position);
      final direction = _grid[position.y][position.x];
      position = Point(position.x + direction.delta.x, position.y + direction.delta.y);
    }
  }

  Future<void> _saveScore() async {
    final playerProvider = context.read<PlayerProvider>();
    final scoreProvider = context.read<ScoreProvider>();
    final currentPlayer = playerProvider.currentPlayer;

    if (currentPlayer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um jogador para salvar o score.')),
      );
      return;
    }

    final points = (1000 - _rotationCount * 10).clamp(100, 1000);
    final score = Score(
      playerId: currentPlayer.id,
      playerName: currentPlayer.name,
      gameId: 'hidro_flux',
      points: points,
      duration: _lastPathTime,
      metadata: {
        'level': _level.title,
        'rotations': _rotationCount,
      },
    );

    await scoreProvider.saveScore(score);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Score salvo com sucesso!')),
      );
    }
  }

  Color _cellColor(int row, int col) {
    final position = Point(col, row);
    if (_level.start == position) {
      return AppTheme.accentGreen.withAlpha(30);
    }
    if (_level.goal == position) {
      return AppTheme.accentCyan.withAlpha(30);
    }
    final pathIndex = _flowPath.indexOf(position);
    if (pathIndex != -1) {
      if (pathIndex <= _flowStep) {
        return AppTheme.accentCyan.withAlpha(120);
      }
      return AppTheme.accentCyan.withAlpha(20);
    }
    if (_currentPath.contains(position)) {
      return AppTheme.accentCyan.withAlpha(20);
    }
    return AppTheme.surface;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hidro Flux'),
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_level.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _infoChip('Fase', '${_levelIndex + 1}/${HidroFluxGame.levels.length}'),
                    _infoChip('Giros', '$_rotationCount'),
                    _infoChip('Tamanho', '${_level.width}x${_level.height}'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_statusMessage, style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellSize = min(40.0, constraints.maxWidth / _level.width);
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _level.width,
                    childAspectRatio: 1,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _level.width * _level.height,
                  itemBuilder: (context, index) {
                    final row = index ~/ _level.width;
                    final col = index % _level.width;
                    final direction = _grid[row][col];
                    return GestureDetector(
                      onTap: () => _rotateTile(row, col),
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        decoration: BoxDecoration(
                          color: _cellColor(row, col),
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomPaint(
                          painter: PipePainter(
                            direction: direction,
                            flowing: _flowPath.contains(Point(col, row)) && _flowPath.indexOf(Point(col, row)) <= _flowStep,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _testPath,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentCyan,
                        ),
                        child: const Text('TESTAR CAMINHO'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetLevel,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.accentCyan),
                        ),
                        child: const Text('REINICIAR'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _solved ? _saveScore : null,
                        child: const Text('SALVAR SCORE'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _solved && _levelIndex < HidroFluxGame.levels.length - 1 ? _nextLevel : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _solved ? AppTheme.accentGreen : AppTheme.surface,
                        ),
                        child: const Text('PRÓXIMO NÍVEL'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }
}

class PipePainter extends CustomPainter {
  final PipeDirection direction;
  final bool flowing;

  PipePainter({required this.direction, this.flowing = false});

  @override
  void paint(Canvas canvas, Size size) {
    final pipePaint = Paint()
      ..color = flowing ? AppTheme.accentCyan : AppTheme.textSecondary
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final edge = size.width * 0.12;

    switch (direction) {
      case PipeDirection.up:
        canvas.drawLine(Offset(center.dx, size.height), center, pipePaint);
        break;
      case PipeDirection.right:
        canvas.drawLine(Offset(0, center.dy), center, pipePaint);
        break;
      case PipeDirection.down:
        canvas.drawLine(Offset(center.dx, 0), center, pipePaint);
        break;
      case PipeDirection.left:
        canvas.drawLine(Offset(size.width, center.dy), center, pipePaint);
        break;
    }

    final jointPaint = Paint()
      ..color = flowing ? AppTheme.accentCyan : AppTheme.textSecondary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, edge, jointPaint);
  }

  @override
  bool shouldRepaint(covariant PipePainter oldDelegate) {
    return oldDelegate.direction != direction || oldDelegate.flowing != flowing;
  }
}
