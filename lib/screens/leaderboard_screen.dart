import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game.dart';
import '../models/player.dart';
import '../models/score.dart';
import '../providers/player_provider.dart';
import '../providers/score_provider.dart';
import '../services/leaderboard_service.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedGameId = 'snake';
  int selectedLeaderboardType = 0; // 0: Geral, 1: Semanal, 2: Amigos

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final games = Game.getAvailableGames();

    return Column(
      children: [
        // Game Selector
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.surface,
          child: DropdownButton<String>(
            isExpanded: true,
            value: selectedGameId,
            items: games.map((game) {
              return DropdownMenuItem(
                value: game.id,
                child: Text('${game.icon} ${game.name}'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedGameId = value;
                });
              }
            },
            style: const TextStyle(color: AppTheme.textPrimary),
            dropdownColor: AppTheme.surface,
          ),
        ),
        // Tab Controller
        TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentCyan,
          labelColor: AppTheme.accentCyan,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Geral'),
            Tab(text: 'Semanal'),
            Tab(text: 'Amigos'),
          ],
          onTap: (index) {
            setState(() {
              selectedLeaderboardType = index;
            });
          },
        ),
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLeaderboardList(
                gameId: selectedGameId,
                type: 'general',
              ),
              _buildLeaderboardList(
                gameId: selectedGameId,
                type: 'weekly',
              ),
              _buildLeaderboardList(
                gameId: selectedGameId,
                type: 'friends',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList({
    required String gameId,
    required String type,
  }) {
    return Consumer3<LeaderboardService, PlayerProvider, ScoreProvider>(
      builder: (context, leaderboardService, playerProvider, scoreProvider, _) {
        final leaderboard = _buildLocalLeaderboard(
          gameId: gameId,
          type: type,
          playerProvider: playerProvider,
          scores: scoreProvider.getScoresByGame(gameId),
        );

        if (leaderboard.isEmpty) {
          return Center(
            child: Text(
              type == 'friends'
                  ? 'Nenhum score encontrado com seus amigos'
                  : 'Nenhum score encontrado ainda',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: leaderboard.length,
          itemBuilder: (context, index) {
            final entry = leaderboard[index];
            final isCurrentPlayer = entry.key == playerProvider.currentPlayer?.name;

            return Card(
              color: isCurrentPlayer ? AppTheme.accentCyan.withAlpha(51) : AppTheme.cardBackground,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRankColor(index),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  entry.key,
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
                trailing: Text(
                  '${entry.value} pts',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: isCurrentPlayer ? const Text('Você está aqui') : null,
              ),
            );
          },
        );
      },
    );
  }

  List<MapEntry<String, int>> _buildLocalLeaderboard({
    required String gameId,
    required String type,
    required PlayerProvider playerProvider,
    required List<Score> scores,
  }) {
    final Map<String, int> playerScores = {};

    if (type == 'friends') {
      final currentPlayer = playerProvider.currentPlayer;
      if (currentPlayer == null) return [];

      final friendNames = currentPlayer.friendIds
          .map((id) => playerProvider.allPlayers
              .firstWhere(
                (player) => player.id == id,
                orElse: () => Player(id: '', name: ''),
              )
              .name)
          .where((name) => name.isNotEmpty)
          .toList();
      friendNames.add(currentPlayer.name);

      for (final score in scores) {
        if (friendNames.contains(score.playerName)) {
          playerScores[score.playerName] = (playerScores[score.playerName] ?? 0) + score.points;
        }
      }
    } else {
      for (final score in scores) {
        playerScores[score.playerName] = (playerScores[score.playerName] ?? 0) + score.points;
      }
    }

    final sortedList = playerScores.entries.toList();
    sortedList.sort((a, b) => b.value.compareTo(a.value));
    return sortedList;
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return AppTheme.accentCyan;
      case 1:
        return AppTheme.accentPurple;
      case 2:
        return AppTheme.accentBronze;
      default:
        return AppTheme.textSecondary;
    }
  }
}
