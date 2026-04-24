import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../games/game_2048.dart';
import '../../models/score.dart';
import '../../providers/player_provider.dart';
import '../../providers/score_provider.dart';
import '../../services/ads_service.dart';
import '../../theme/app_theme.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({Key? key}) : super(key: key);

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  static const String _gameId = '2048';
  static const double _swipeThreshold = 240;

  late Game2048 game;
  bool _dialogOpen = false;
  bool _scoreSaved = false;

  @override
  void initState() {
    super.initState();
    game = Game2048();
  }

  void _restartGame() {
    setState(() {
      game = Game2048();
      _dialogOpen = false;
      _scoreSaved = false;
    });
  }

  void _handleSwipe(DragEndDetails details) {
    if (game.isGameOver) return;

    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.distance < _swipeThreshold) return;

    final direction = velocity.dx.abs() > velocity.dy.abs()
        ? (velocity.dx > 0 ? Game2048Direction.right : Game2048Direction.left)
        : (velocity.dy > 0 ? Game2048Direction.down : Game2048Direction.up);

    final moved = game.move(direction);
    if (!moved) return;

    setState(() {});

    if (game.isGameOver && !_dialogOpen) {
      _dialogOpen = true;
      _showEndDialog();
    }
  }

  Future<void> _showEndDialog() async {
    final adsService = context.read<AdsService>();
    await adsService.showInterstitialAd();
    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Resultado do 2048',
      barrierColor: Colors.black.withAlpha(180),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        final won = game.isWon;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: won
                        ? [
                            const Color(0xFF0F172A),
                            const Color(0xFF312E81),
                            const Color(0xFF4C1D95),
                          ]
                        : [
                            const Color(0xFF111827),
                            const Color(0xFF1F2937),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: won ? const Color(0xFFFACC15) : AppTheme.border,
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(120),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: won
                                ? [const Color(0xFFFDE68A), const Color(0xFFF59E0B)]
                                : [const Color(0xFF60A5FA), const Color(0xFF2563EB)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (won ? const Color(0xFFFACC15) : const Color(0xFF60A5FA))
                                  .withAlpha(90),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          won ? Icons.emoji_events : Icons.grid_off,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        won ? 'Você chegou em 2048!' : 'Sem movimentos',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        won
                            ? 'Excelente. O tabuleiro brilhou e você desbloqueou o bloco final.'
                            : 'Não há mais jogadas possíveis. Tente novamente para bater sua marca.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: Colors.white.withAlpha(220),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildVictoryMetric(
                            label: 'Score',
                            value: '${game.score}',
                            accent: const Color(0xFF7EE7FF),
                          ),
                          const SizedBox(width: 12),
                          _buildVictoryMetric(
                            label: 'Maior bloco',
                            value: '${game.maxTile}',
                            accent: const Color(0xFFFACC15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildVictoryMetric(
                            label: 'Movimentos',
                            value: '${game.moves}',
                            accent: const Color(0xFFA78BFA),
                          ),
                          const SizedBox(width: 12),
                          _buildVictoryMetric(
                            label: 'Tempo',
                            value: '${game.gameDuration.inSeconds}s',
                            accent: const Color(0xFF34D399),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _restartGame();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Jogar novamente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: won ? const Color(0xFFFACC15) : AppTheme.accentCyan,
                            foregroundColor: const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _scoreSaved
                              ? null
                              : () async {
                                  await _saveScore();
                                },
                          icon: const Icon(Icons.save_alt),
                          label: Text(_scoreSaved ? 'Score salvo' : 'Salvar score'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: won ? const Color(0xFFFACC15) : AppTheme.accentCyan,
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Voltar ao hub',
                          style: TextStyle(color: Colors.white.withAlpha(220)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    ).then((_) {
      _dialogOpen = false;
    });
  }

  Future<void> _saveScore() async {
    if (_scoreSaved) return;

    final playerProvider = context.read<PlayerProvider>();
    final scoreProvider = context.read<ScoreProvider>();
    final player = playerProvider.currentPlayer;

    if (player == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: jogador não encontrado.')),
      );
      return;
    }

    final score = Score(
      playerId: playerProvider.currentUserId,
      playerName: player.name,
      gameId: _gameId,
      points: game.score,
      duration: game.gameDuration.inSeconds,
      metadata: {
        'maxTile': game.maxTile,
        'moves': game.moves,
        'won': game.isWon,
      },
    );

    await scoreProvider.saveScore(score);
    if (mounted) {
      setState(() {
        _scoreSaved = true;
      });
    } else {
      _scoreSaved = true;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Score salvo!')),
    );
  }

  Widget _buildVictoryMetric({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withAlpha(90)),
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withAlpha(190),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _tileGradient(int value) {
    switch (value) {
      case 1:
        return const [Color(0xFF7EE7FF), Color(0xFF22D3EE)];
      case 2:
        return const [Color(0xFF86EFAC), Color(0xFF22C55E)];
      case 4:
        return const [Color(0xFFA7F3D0), Color(0xFF10B981)];
      case 8:
        return const [Color(0xFFFDE68A), Color(0xFFF59E0B)];
      case 16:
        return const [Color(0xFFFBBF24), Color(0xFFF97316)];
      case 32:
        return const [Color(0xFFF97316), Color(0xFFEA580C)];
      case 64:
        return const [Color(0xFFFB7185), Color(0xFFEF4444)];
      case 128:
        return const [Color(0xFFEC4899), Color(0xFFDB2777)];
      case 256:
        return const [Color(0xFFA855F7), Color(0xFF7C3AED)];
      case 512:
        return const [Color(0xFF8B5CF6), Color(0xFF4F46E5)];
      case 1024:
        return const [Color(0xFF6366F1), Color(0xFF2563EB)];
      case 2048:
        return const [Color(0xFFFDE047), Color(0xFFF59E0B)];
      default:
        return const [Color(0xFF111827), Color(0xFF1F2937)];
    }
  }

  Color _tileTextColor(int value) {
    if (value <= 4) return const Color(0xFF0F172A);
    if (value == 2048) return const Color(0xFF1E1B4B);
    return Colors.white;
  }

  Color _tileGlow(int value) {
    switch (value) {
      case 1:
        return const Color(0xFF22D3EE);
      case 2:
        return const Color(0xFF22C55E);
      case 4:
        return const Color(0xFF10B981);
      case 8:
        return const Color(0xFFF59E0B);
      case 16:
        return const Color(0xFFF97316);
      case 32:
        return const Color(0xFFEA580C);
      case 64:
        return const Color(0xFFEF4444);
      case 128:
        return const Color(0xFFDB2777);
      case 256:
        return const Color(0xFF7C3AED);
      case 512:
        return const Color(0xFF4F46E5);
      case 1024:
        return const Color(0xFF2563EB);
      case 2048:
        return const Color(0xFFFACC15);
      default:
        return AppTheme.accentCyan;
    }
  }

  double _tileFontSize(int value) {
    if (value >= 1024) return 24;
    if (value >= 128) return 27;
    if (value >= 16) return 31;
    return 36;
  }

  Widget _buildTile(Game2048Tile? tile) {
    if (tile == null) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2335),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withAlpha(12)),
        ),
      );
    }

    final isNewTile = tile.bornTurn == game.turnCounter;
    final isMergedTile = tile.mergedTurn == game.turnCounter;
    final beginScale = isNewTile ? 0.15 : isMergedTile ? 1.18 : 1.0;
    final curve = isNewTile ? Curves.easeOutBack : Curves.easeOutCubic;
    final gradient = _tileGradient(tile.value);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 240),
      curve: curve,
      tween: Tween<double>(begin: beginScale, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withAlpha(tile.value == 2048 ? 80 : 18),
            width: tile.value == 2048 ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _tileGlow(tile.value).withAlpha(tile.value == 2048 ? 140 : 70),
              blurRadius: tile.value == 2048 ? 22 : 14,
              spreadRadius: tile.value == 2048 ? 2 : 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: RadialGradient(
                    center: const Alignment(-0.5, -0.6),
                    radius: 1.1,
                    colors: [
                      Colors.white.withAlpha(85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: FittedBox(
                child: Text(
                  '${tile.value}',
                  style: TextStyle(
                    fontSize: _tileFontSize(tile.value),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    color: _tileTextColor(tile.value),
                    shadows: [
                      Shadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final scoreProvider = context.watch<ScoreProvider>();
    final player = playerProvider.currentPlayer;
    final bestScore = player == null ? null : scoreProvider.getBestScore(_gameId, player.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('2048'),
        actions: [
          _buildAppBarStat('Score', '${game.score}'),
          _buildAppBarStat('Bloco', '${game.maxTile}'),
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
                const Text(
                  'Deslize para unir blocos iguais',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Todos os blocos começam com 1. Quando dois iguais se encontram, eles dobram de valor. O objetivo é chegar em 2048.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildSmallInfo('Melhor', bestScore != null ? '${bestScore.points}' : '---'),
                    const SizedBox(width: 12),
                    _buildSmallInfo('Jogadas', '${game.moves}'),
                    const SizedBox(width: 12),
                    _buildSmallInfo('Tempo', '${game.gameDuration.inSeconds}s'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanEnd: _handleSwipe,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1220),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(70),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: Game2048.size * Game2048.size,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: Game2048.size,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemBuilder: (context, index) {
                            final row = index ~/ Game2048.size;
                            final col = index % Game2048.size;
                            return _buildTile(game.board[row][col]);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _restartGame,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reiniciar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentCyan,
                      foregroundColor: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: game.isGameOver && !_scoreSaved
                        ? () async {
                            await _saveScore();
                          }
                        : null,
                    icon: const Icon(Icons.save_alt),
                    label: Text(_scoreSaved ? 'Score salvo' : 'Salvar Score'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.accentCyan),
                      foregroundColor: AppTheme.accentCyan,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfo(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarStat(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
