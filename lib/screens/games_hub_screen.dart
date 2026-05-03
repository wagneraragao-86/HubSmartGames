import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/index.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import 'auth_screen.dart';
import 'games/hanoi_screen.dart';
import 'games/game_2048_screen.dart';
import 'games/hidro_flux_screen.dart';
import 'games/reaction_screen.dart';
import 'games/space_impact_screen.dart';
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
                    ' - ',
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1100
            ? 4
            : width >= 720
                ? 3
                : 2;

        return Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.cardBackground,
                    AppTheme.cardBackground.withAlpha(220),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.accentCyan.withAlpha(80)),
                    ),
                    child: Image.asset('assets/logo.png'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hub Smart Games',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Escolha um jogo e mergulhe direto na ação.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: width >= 720 ? 1.08 : 0.95,
                ),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  return _buildGameCard(context, game);
                },
              ),
            ),
            const BannerAdWidget(),
          ],
        );
      },
    );
  }

  Widget _buildGameCard(BuildContext context, Game game) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 220 || constraints.maxWidth < 180;
        final iconSize = compact ? 48.0 : 64.0;
        final titleSize = compact ? 15.0 : 18.0;
        final descSize = compact ? 11.0 : 12.0;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _navigateToGame(context, game),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.cardBackground,
                    AppTheme.cardBackground.withAlpha(235),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: compact ? 64 : 76,
                    height: compact ? 64 : 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.background,
                      border: Border.all(color: AppTheme.accentCyan.withAlpha(50)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentCyan.withAlpha(25),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      game.icon,
                      style: TextStyle(fontSize: iconSize),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    game.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      game.description,
                      textAlign: TextAlign.center,
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: descSize,
                        color: AppTheme.textSecondary,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
      case 'space_impact':
        screen = const SpaceImpactScreen();
        break;
      case '2048':
        screen = const Game2048Screen();
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
