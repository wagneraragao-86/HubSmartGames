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
  late final Animation<double> _particleAnimation;
  String _statusMessage = 'Toque em um cano para girar. Depois clique em TESTAR CAMINHO.';
  Set<Point<int>> _currentPath = {};

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addListener(_updateFlowStep);

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flowController, curve: Curves.easeInOut),
    );

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
    _flowController.repeat(reverse: true);
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

      if (position.x < 0 ||
          position.x >= _level.width ||
          position.y < 0 ||
          position.y >= _level.height) {
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
              'Fase: ${_levelIndex + 1}/${HidroFluxGame.levels.length}',
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
              'Giros: $_rotationCount',
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
              '${_level.width}x${_level.height}',
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
          // Status Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.surface,
            child: Text(
              _statusMessage,
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          // Game Area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellSize = min(50.0, constraints.maxWidth / _level.width);
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _level.width,
                    childAspectRatio: 1,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
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
                            flowing: _flowPath.contains(Point(col, row)) &&
                                _flowPath.indexOf(Point(col, row)) <= _flowStep,
                            particleProgress: _particleAnimation.value,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Controls
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
                        onPressed: _solved && _levelIndex < HidroFluxGame.levels.length - 1
                            ? _nextLevel
                            : null,
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
}

class PipePainter extends CustomPainter {
  final PipeDirection direction;
  final bool flowing;
  final double particleProgress;

  PipePainter({
    required this.direction,
    this.flowing = false,
    this.particleProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerWidth = size.width * 0.28;
    final innerWidth = outerWidth * 0.54;
    final endCapRadius = outerWidth * 0.9;
    final hubRadius = outerWidth * 0.7;

    final outerGradient = LinearGradient(
      colors: flowing
          ? [
              AppTheme.accentCyan.withAlpha(220),
              AppTheme.accentCyan.withAlpha(180),
              AppTheme.accentCyan.withAlpha(140),
            ]
          : [
              AppTheme.surface.withAlpha(235),
              AppTheme.surface.withAlpha(215),
              AppTheme.textSecondary.withAlpha(170),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final innerGradient = LinearGradient(
      colors: flowing
          ? [
              Colors.white.withAlpha(220),
              AppTheme.accentCyan.withAlpha(200),
              AppTheme.accentCyan.withAlpha(130),
            ]
          : [
              AppTheme.surface.withAlpha(205),
              AppTheme.surface.withAlpha(185),
              AppTheme.textSecondary.withAlpha(140),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final outerPaint = Paint()
      ..shader = outerGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final innerPaint = Paint()
      ..shader = innerGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = AppTheme.border.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(30)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final outerPath = _pipeSegmentPath(size, center, outerWidth);
    final innerPath = _pipeSegmentPath(size, center, innerWidth);
    final openCenter = _pipeOpenCenter(size, center);

    canvas.drawPath(outerPath.shift(const Offset(1.8, 1.8)), shadowPaint);
    canvas.drawPath(outerPath, outerPaint);
    canvas.drawPath(innerPath, innerPaint);
    canvas.drawPath(outerPath, outlinePaint);

    _drawEndCap(canvas, openCenter, endCapRadius, outlinePaint);
    _drawHub(canvas, center, hubRadius, flowing, outlinePaint);
    _drawHighlight(canvas, size, center, outerWidth, direction);

    if (flowing) {
      _drawFlowingParticles(canvas, size, center, innerWidth, openCenter);
    }
  }

  Path _pipeSegmentPath(Size size, Offset center, double width) {
    final halfWidth = width / 2;
    switch (direction) {
      case PipeDirection.up:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(center.dx - halfWidth, center.dy, center.dx + halfWidth, size.height),
            Radius.circular(halfWidth),
          ));
      case PipeDirection.right:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(0, center.dy - halfWidth, center.dx, center.dy + halfWidth),
            Radius.circular(halfWidth),
          ));
      case PipeDirection.down:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(center.dx - halfWidth, 0, center.dx + halfWidth, center.dy),
            Radius.circular(halfWidth),
          ));
      case PipeDirection.left:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(center.dx, center.dy - halfWidth, size.width, center.dy + halfWidth),
            Radius.circular(halfWidth),
          ));
    }
  }

  Offset _pipeOpenCenter(Size size, Offset center) {
    switch (direction) {
      case PipeDirection.up:
        return Offset(center.dx, size.height);
      case PipeDirection.right:
        return Offset(0, center.dy);
      case PipeDirection.down:
        return Offset(center.dx, 0);
      case PipeDirection.left:
        return Offset(size.width, center.dy);
    }
  }

  void _drawEndCap(Canvas canvas, Offset capCenter, double radius, Paint outlinePaint) {
    canvas.drawCircle(capCenter, radius, Paint()..color = AppTheme.surface.withAlpha(220));
    canvas.drawCircle(capCenter, radius * 0.7, Paint()..color = AppTheme.surface.withAlpha(245));
    canvas.drawCircle(capCenter, radius, outlinePaint);
  }

  void _drawHub(Canvas canvas, Offset center, double radius, bool flowing, Paint outlinePaint) {
    final hubGradient = RadialGradient(
      colors: flowing
          ? [
              AppTheme.accentCyan.withAlpha(240),
              AppTheme.accentCyan.withAlpha(180),
            ]
          : [
              AppTheme.surface.withAlpha(240),
              AppTheme.textSecondary.withAlpha(180),
            ],
      center: const Alignment(-0.2, -0.2),
      radius: 0.8,
    );

    final hubPaint = Paint()
      ..shader = hubGradient.createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center + const Offset(1.2, 1.2), radius, Paint()..color = Colors.black.withAlpha(35));
    canvas.drawCircle(center, radius, hubPaint);
    canvas.drawCircle(center, radius, outlinePaint);
  }

  void _drawHighlight(
      Canvas canvas, Size size, Offset center, double width, PipeDirection direction) {
    final highlightWidth = width * 0.6;
    final halfWidth = highlightWidth / 2;
    final highlightPaint = Paint()
      ..color = Colors.white.withAlpha(90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    Path highlight;
    switch (direction) {
      case PipeDirection.up:
        highlight = Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(center.dx - halfWidth, center.dy + width * 0.07, center.dx + halfWidth,
                size.height - width * 0.12),
            Radius.circular(halfWidth),
          ));
        break;
      case PipeDirection.right:
        highlight = Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(width * 0.12, center.dy - halfWidth, center.dx - width * 0.07,
                center.dy + halfWidth),
            Radius.circular(halfWidth),
          ));
        break;
      case PipeDirection.down:
        highlight = Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(center.dx - halfWidth, width * 0.12, center.dx + halfWidth,
                center.dy - width * 0.07),
            Radius.circular(halfWidth),
          ));
        break;
      case PipeDirection.left:
        highlight = Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(center.dx + width * 0.07, center.dy - halfWidth,
                size.width - width * 0.12, center.dy + halfWidth),
            Radius.circular(halfWidth),
          ));
        break;
    }

    canvas.drawPath(highlight, highlightPaint);
  }

  void _drawFlowingParticles(
    Canvas canvas,
    Size size,
    Offset center,
    double channelWidth,
    Offset endCenter,
  ) {
    final particlePaint = Paint()
      ..color = Colors.white.withAlpha(200)
      ..style = PaintingStyle.fill;

    final numParticles = 3;
    final spacing = 1.0 / (numParticles + 1);
    final start = center;
    final end = endCenter;

    for (int i = 0; i < numParticles; i++) {
      final t = (particleProgress + (i + 1) * spacing) % 1.0;
      final position = Offset.lerp(start, end, t)!;
      final particleSize = channelWidth * 0.16;

      canvas.drawCircle(position, particleSize, particlePaint);
      canvas.drawCircle(
        position,
        particleSize * 1.6,
        Paint()
          ..color = AppTheme.accentCyan.withAlpha(110)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant PipePainter oldDelegate) {
    return oldDelegate.direction != direction ||
        oldDelegate.flowing != flowing ||
        oldDelegate.particleProgress != particleProgress;
  }
}
