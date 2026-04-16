import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import 'games_hub_screen.dart';

class PlayerSelectionScreen extends StatefulWidget {
  const PlayerSelectionScreen({Key? key}) : super(key: key);

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createNewPlayer() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um nome para o jogador')),
      );
      return;
    }

    context.read<PlayerProvider>().createPlayer(_nameController.text).then((_) {
      if (mounted) {
        final players = context.read<PlayerProvider>().allPlayers;
        if (players.isNotEmpty) {
          context.read<PlayerProvider>().selectPlayer(players.last.id).then((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const GameHubScreen()),
            );
          });
        }
      }
    });
  }

  void _selectExistingPlayer(String playerId) {
    context.read<PlayerProvider>().selectPlayer(playerId).then((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GameHubScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecione um Jogador'),
        centerTitle: true,
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, playerProvider, _) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Criar novo jogador
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Novo Jogador',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Nome do jogador',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _createNewPlayer,
                            child: const Text('Criar Jogador'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Jogadores existentes
                if (playerProvider.allPlayers.isNotEmpty) ...[
                  const Text(
                    'Jogadores Existentes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: playerProvider.allPlayers.length,
                      itemBuilder: (context, index) {
                        final player = playerProvider.allPlayers[index];
                        return Card(
                          child: ListTile(
                            title: Text(player.name),
                            onTap: () => _selectExistingPlayer(player.id),
                            trailing: const Icon(Icons.arrow_forward),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
