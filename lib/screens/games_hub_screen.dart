import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/index.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'games/hidro_flux_screen.dart';
import 'games/hanoi_screen.dart';
import 'games/reaction_screen.dart';
import 'games/snake_screen.dart';
import 'leaderboard_screen.dart';
import 'player_selection_screen.dart';
import 'profile_screen.dart';

class GameHubScreen extends StatefulWidget {
  const GameHubScreen({Key? key}) : super(key: key);

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Consumer2<AuthProvider, PlayerProvider>(
            builder: (context, authProvider, playerProvider, _) {
              return Column(
                children: [
                  Text('Hub de Jogos'),
                  Text(
                    '${authProvider.userName ?? 'Usuário'} - ${playerProvider.currentPlayer?.name ?? 'Jogador'}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
                ],
              );
            },
          ),
          centerTitle: true,
          actions: [
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Perfil'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                    PopupMenuItem(
                      child: const Text('Trocar Jogador'),
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const PlayerSelectionScreen(),
                          ),
                        );
                      },
                    ),
                    PopupMenuItem(
                      child: const Text('Sair'),
                      onTap: () async {
                        await authProvider.signOut();
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const AuthScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.sports_esports), text: 'Jogos'),
              Tab(icon: Icon(Icons.leaderboard), text: 'Rankings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Aba de Jogos
            _buildGamesTab(),
            // Aba de Rankings
            const LeaderboardScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesTab() {
    final games = Game.getAvailableGames();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return _buildGameCard(context, game);
      },
    );
  }

  Widget _buildGameCard(BuildContext context, Game game) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToGame(context, game),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              game.icon,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              game.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                game.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToGame(BuildContext context, Game game) {
    Widget screen;
    switch (game.id) {
      case 'snake':
        screen = const SnakeScreen();
        break;
      case 'hanoi':
        screen = const HanoiScreen();
        break;
      case 'reaction':
        screen = const ReactionScreen();
        break;
      case 'hidro_flux':
        screen = const HidroFluxScreen();
        break;
      default:
        return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
