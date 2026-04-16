import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import 'auth_screen.dart';
import 'games_hub_screen.dart';
import 'player_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PlayerProvider>(
      builder: (context, authProvider, playerProvider, _) {
        if (!authProvider.isSignedIn) {
          return const AuthScreen();
        }

        if (playerProvider.currentPlayer == null) {
          return const PlayerSelectionScreen();
        }

        return const GameHubScreen();
      },
    );
  }
}
