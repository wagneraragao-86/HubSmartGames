import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../games/hanoi_game.dart';
import '../../models/score.dart';
import '../../providers/player_provider.dart';
import '../../providers/score_provider.dart';
import '../../theme/app_theme.dart';

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
  }

  void _showGameCompletedDialog() {
    final playerProvider = context.read<PlayerProvider>();
    final scoreProvider = context.read<ScoreProvider>();

    final stats = game.getGameStats();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Parabéns!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Movimentos: ${stats['moves']}'),
            Text('Movimentos Ideais: ${stats['optimalMoves']}'),
            Text('Eficiência: ${stats['efficiency']}%'),
            Text('Tempo: ${stats['duration']}s'),
            const SizedBox(height: 8),
            Text(
              'Pontuação: ${_calculateScore(stats)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
              // Salvar score e jogar novamente
              if (playerProvider.currentPlayer != null) {
                final score = Score(
                  playerId: playerProvider.currentPlayer!.id,
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
                game = TowerOfHanoi(numberOfDisks: 3);
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
    final score = (baseScore - movePenalty).clamp(50, 10000).toInt();
    return score;
  }

  void _changeDiskCount(int disks) {
    if (selectedDisks == disks) return;
    setState(() {
      selectedDisks = disks;
      game = TowerOfHanoi(numberOfDisks: selectedDisks);
    });
  }

  Widget _buildDiskChip(int diskCount) {
    final isSelected = selectedDisks == diskCount;
    return ChoiceChip(
      label: Text('$diskCount'),
      selected: isSelected,
      onSelected: (_) => _changeDiskCount(diskCount),
      selectedColor: AppTheme.accentCyan,
      backgroundColor: AppTheme.cardBackground,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(color: isSelected ? AppTheme.accentCyan : AppTheme.border),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Torre de Hanói'),
      ),
      body: Column(
        children: [
          // Nivel de dificuldade
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Número de Discos',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(8, (index) {
                    final diskCount = index + 3;
                    return _buildDiskChip(diskCount);
                  }),
                ),
              ],
            ),
          ),
          // Info
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Movimentos: ${game.moves}/${game.minMovesNeeded}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Discos: ${game.numberOfDisks}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Game Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTower(0),
                  _buildTower(1),
                  _buildTower(2),
                ],
              ),
            ),
          ),
          // Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      game.resetGame();
                    });
                  },
                  child: const Text('Resetar'),
                ),
                ElevatedButton(
                  onPressed: game.isSolved()
                      ? null
                      : () {
                          setState(() {
                            game.undo();
                          });
                        },
                  child: const Text('Desfazer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTower(int towerIndex) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (!game.selectTower(towerIndex)) {
            // Movimento inválido - mostrar feedback
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Movimento inválido!')),
            );
          } else if (game.isSolved()) {
            _showGameCompletedDialog();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: game.selectedTowerIndex == towerIndex
              ? AppTheme.accentCyan.withAlpha(77)
              : AppTheme.surface,
          border: Border.all(
            color: game.selectedTowerIndex == towerIndex ? AppTheme.accentCyan : AppTheme.border,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Torre ${towerIndex + 1}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Base
                  Container(
                    width: 60,
                    height: 4,
                    color: AppTheme.textPrimary,
                  ),
                  // Discos
                  ...List.generate(game.towers[towerIndex].length, (index) {
                    final disk = game.towers[towerIndex][index];
                    final width = 20.0 + (disk * 15.0);
                    return Positioned(
                      bottom: 16.0 + (index * 20.0),
                      child: Container(
                        width: width,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _getDiskColor(disk),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.textPrimary, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            '$disk',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
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
      AppTheme.accentRed,
      AppTheme.accentCyan,
      AppTheme.accentGreen,
      AppTheme.accentPurple,
      AppTheme.accentCyan,
      AppTheme.accentPurple,
      AppTheme.accentRed,
    ];
    return colors[disk % colors.length];
  }
}
