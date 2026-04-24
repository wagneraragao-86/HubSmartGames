import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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
  static const String _downloadLink =
      'https://play.google.com/store/apps/details?id=com.example.hub_smart_games';

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
        // Verificar se é ranking de amigos e usuário não está logado
        if (type == 'friends') {
          return Column(
            children: [
              _buildInviteFriendsCard(),
              if (!playerProvider.isLoggedIn)
                Expanded(child: _buildFriendsLoginPrompt())
              else
                Expanded(
                  child: _buildFriendsLeaderboard(
                    gameId: gameId,
                    playerProvider: playerProvider,
                    scoreProvider: scoreProvider,
                  ),
                ),
            ],
          );
        }

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

  Widget _buildFriendsLeaderboard({
    required String gameId,
    required PlayerProvider playerProvider,
    required ScoreProvider scoreProvider,
  }) {
    final leaderboard = _buildLocalLeaderboard(
      gameId: gameId,
      type: 'friends',
      playerProvider: playerProvider,
      scores: scoreProvider.getScoresByGame(gameId),
    );

    if (leaderboard.isEmpty) {
      return Center(
        child: Text(
          'Nenhum score encontrado com seus amigos',
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
  }

  Widget _buildInviteFriendsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.accentCyan.withAlpha(35),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accentCyan.withAlpha(90)),
            ),
            child: const Icon(Icons.person_add_alt_1, color: AppTheme.accentCyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Convide amigos para jogar',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Compartilhe o link para baixar o app em qualquer app instalado.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _shareInviteLink,
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Convidar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareInviteLink() async {
    final message = [
      'Joguei no Hub Smart Games e achei muito bom.',
      'Baixe o app aqui: $_downloadLink',
      'Dá para compartilhar por WhatsApp, email ou qualquer outro meio.',
    ].join('\n');

    await Share.share(
      message,
      subject: 'Convite para o Hub Smart Games',
    );
  }

  Widget _buildFriendsLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ranking de Amigos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Para ver o ranking entre amigos, faça login com sua conta Google.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _shareInviteLink,
              icon: const Icon(Icons.share),
              label: const Text('Convidar amigos'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: context.read<PlayerProvider>().isLoggedIn
                  ? null
                  : () async {
                      try {
                        await context.read<PlayerProvider>().loginWithGoogle();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Login realizado com sucesso!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro no login: $e')),
                        );
                      }
                    },
              icon: const Icon(Icons.login),
              label: Text(
                context.read<PlayerProvider>().isLoggedIn ? 'Já conectado' : 'Fazer Login',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
              ),
            ),
          ],
        ),
      ),
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
