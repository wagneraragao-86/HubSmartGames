import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../games/hanoi_game.dart';
import '../../models/score.dart';
import '../../providers/player_provider.dart';
import '../../providers/score_provider.dart';
import '../../services/ads_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/game_intro_dialog.dart';

class HanoiScreen extends StatefulWidget {
  const HanoiScreen({Key? key}) : super(key: key);

  @override
  State<HanoiScreen> createState() => _HanoiScreenState();
}

class _HanoiScreenState extends State<HanoiScreen> {
  late TowerOfHanoi game;
  int selectedDisks = 3;

  @override
  void initState() {
    super.initState();
    game = TowerOfHanoi(numberOfDisks: selectedDisks);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showGameIntroDialogIfNeeded(
        context,
        const GameIntroDialogData(
          gameId: 'hanoi',
          title: 'Como jogar Torre de Hanoi',
          subtitle: 'Mova os discos entre as torres seguindo a regra dos tamanhos.',
          instructions: [
            'Toque em uma torre para selecionar um disco.',
            'Toque em outra torre para mover o disco selecionado.',
            'Nunca coloque um disco maior sobre um menor.',
            'Tente resolver com o menor numero de movimentos possível.',
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _showGameCompletedDialog() async {
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
        title: const Text('Parabens!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Movimentos: ${stats['moves']}'),
            Text('Movimentos Ideais: ${stats['optimalMoves']}'),
            Text('Eficiencia: ${stats['efficiency']}%'),
            Text('Tempo: ${stats['duration']}s'),
            const SizedBox(height: 8),
            Text(
              'Pontuacao: ${_calculateScore(stats)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (playerProvider.currentPlayer != null) {
                final score = Score(
                  playerId: playerProvider.currentUserId,
                  playerName: playerProvider.currentPlayer!.name,
                  gameId: 'hanoi',
                  points: _calculateScore(stats),
                  duration: stats['duration'],
                  metadata: {
                    'moves': stats['moves'],
                    'optimalMoves': stats['optimalMoves'],
                    'disks': stats['disks'],
                  },
                );
                scoreProvider.saveScore(score);
              }

              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () {
              if (playerProvider.currentPlayer != null) {
                final score = Score(
                  playerId: playerProvider.currentUserId,
                  playerName: playerProvider.currentPlayer!.name,
                  gameId: 'hanoi',
                  points: _calculateScore(stats),
                  duration: stats['duration'],
                  metadata: {
                    'moves': stats['moves'],
                    'optimalMoves': stats['optimalMoves'],
                    'disks': stats['disks'],
                  },
                );
                scoreProvider.saveScore(score);
              }

              Navigator.pop(context);
              setState(() {
                game = TowerOfHanoi(numberOfDisks: selectedDisks);
              });
            },
            child: const Text('Jogar Novamente'),
          ),
        ],
      ),
    );
  }

  int _calculateScore(Map<String, dynamic> stats) {
    final baseScore = 500;
    final movePenalty = (stats['moves'] - stats['optimalMoves']) * 10;
    return (baseScore - movePenalty).clamp(50, 10000).toInt();
  }

  void _changeDiskCount(int disks) {
    if (selectedDisks == disks) return;
    setState(() {
      selectedDisks = disks;
      game = TowerOfHanoi(numberOfDisks: selectedDisks);
    });
  }

  Widget _buildSidebarButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: label,
      child: SizedBox(
        width: 60,
        height: 60,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: onPressed != null ? AppTheme.cardBackground : AppTheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: onPressed != null ? AppTheme.accentCyan : AppTheme.border,
              width: 1.5,
            ),
            boxShadow: onPressed != null
                ? [
                    BoxShadow(
                      color: AppTheme.accentCyan.withAlpha(30),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              onPressed: onPressed,
              icon: Icon(icon, size: 24, color: AppTheme.textPrimary),
              splashRadius: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiskSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedDisks,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.accentCyan),
          dropdownColor: AppTheme.cardBackground,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          items: List.generate(8, (index) {
            final disks = index + 3;
            return DropdownMenuItem<int>(
              value: disks,
              child: Text('$disks discos'),
            );
          }),
          onChanged: (value) {
            if (value != null) {
              _changeDiskCount(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSidePanel({required double width}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(left: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: SafeArea(
        left: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DISCOS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDiskSelector(),
                  ],
                ),
              ),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildSidebarButton(
                      icon: Icons.refresh,
                      label: 'Reset',
                      onPressed: () {
                        setState(() {
                          game.resetGame();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSidebarButton(
                      icon: Icons.undo,
                      label: 'Desfazer',
                      onPressed: game.isSolved()
                          ? null
                          : () {
                              setState(() {
                                game.undo();
                              });
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Toque nas torres para mover os discos. A lateral fica compacta e rolável.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withAlpha(50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final towerWidth = (((constraints.maxWidth - 48) / 3).clamp(90.0, 240.0)).toDouble();
          final stackHeight = ((constraints.maxHeight - 48).clamp(220.0, 420.0)).toDouble();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTower(0, towerWidth, stackHeight),
                _buildTower(1, towerWidth, stackHeight),
                _buildTower(2, towerWidth, stackHeight),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Torre de Hanoi'),
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
              'Mov: ${game.moves}/${game.minMovesNeeded}',
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
              'Discos: ${game.numberOfDisks}',
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sidePanelWidth = constraints.maxWidth >= 980
              ? 220.0
              : constraints.maxWidth >= 820
                  ? 190.0
                  : 160.0;

          return Row(
            children: [
              Expanded(child: _buildGameArea()),
              _buildSidePanel(width: sidePanelWidth),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTower(int towerIndex, double towerWidth, double stackHeight) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (!game.selectTower(towerIndex)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Movimento invalido!')),
            );
          } else if (game.isSolved()) {
            _showGameCompletedDialog();
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: towerWidth,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: game.selectedTowerIndex == towerIndex
              ? AppTheme.accentCyan.withAlpha(77)
              : AppTheme.surface,
          border: Border.all(
            color: game.selectedTowerIndex == towerIndex ? AppTheme.accentCyan : AppTheme.border,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: game.selectedTowerIndex == towerIndex
              ? [
                  BoxShadow(
                    color: AppTheme.accentCyan.withAlpha(50),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FittedBox(
              child: Text(
                'Torre ${towerIndex + 1}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: towerWidth * 0.92,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.textPrimary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.textPrimary.withAlpha(100),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    child: Container(
                      width: 10,
                      height: stackHeight,
                      decoration: BoxDecoration(
                        color: AppTheme.textPrimary,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.textPrimary.withAlpha(150),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...List.generate(game.towers[towerIndex].length, (index) {
                    final disk = game.towers[towerIndex][index];
                    final minDiskWidth = towerWidth * 0.38;
                    final maxDiskWidth = towerWidth * 0.84;
                    final width = (minDiskWidth + (disk - 1) * (towerWidth * 0.1))
                        .clamp(minDiskWidth, maxDiskWidth);
                    final diskHeight =
                        ((stackHeight / (game.numberOfDisks + 2)).clamp(14.0, 20.0)).toDouble();
                    final diskSpacing = ((diskHeight + 4).clamp(16.0, 24.0)).toDouble();

                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      bottom: 20.0 + (index * diskSpacing),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: game.selectedTowerIndex == towerIndex ? 0.9 : 1.0,
                        child: Container(
                          width: width,
                          height: diskHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getDiskColor(disk),
                                _getDiskColor(disk).withAlpha(200),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: AppTheme.textPrimary, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: _getDiskColor(disk).withAlpha(100),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                              if (game.selectedTowerIndex == towerIndex)
                                BoxShadow(
                                  color: AppTheme.accentCyan.withAlpha(150),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$disk',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: diskHeight > 16 ? 11 : 10,
                                shadows: [
                                  Shadow(
                                    color: AppTheme.background,
                                    offset: const Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDiskColor(int disk) {
    const colors = [
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFF45B7D1),
      Color(0xFFF9CA24),
      Color(0xFFF0932B),
      Color(0xFFE84393),
      Color(0xFF6C5CE7),
      Color(0xFF00B894),
    ];
    return colors[disk % colors.length];
  }
}
// fim
