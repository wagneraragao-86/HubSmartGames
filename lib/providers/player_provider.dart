import 'package:flutter/foundation.dart';

import '../models/index.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class PlayerProvider extends ChangeNotifier {
  final StorageService storage;
  final AuthService? _authService;
  Player? _currentPlayer;
  List<Player> _allPlayers = [];

  PlayerProvider(this.storage, {AuthService? authService}) : _authService = authService {
    _loadCurrentPlayer();
    _loadAllPlayers();
  }

  Player? get currentPlayer => _currentPlayer;
  List<Player> get allPlayers => _allPlayers;

  void _loadCurrentPlayer() {
    _currentPlayer = storage.getCurrentPlayer();
    notifyListeners();
  }

  void _loadAllPlayers() {
    _allPlayers = storage.getAllPlayers();
    notifyListeners();
  }

  Future<void> createPlayer(String name, {String? avatar}) async {
    // Se está autenticado, usar dados do Google
    if (_authService?.isSignedIn == true) {
      final googleUser = _authService!.currentUser!;
      final player = Player(
        id: googleUser.uid,
        name: googleUser.displayName ?? name,
        avatar: googleUser.photoURL ?? avatar,
      );
      await storage.savePlayer(player);
      _loadAllPlayers();
      await selectPlayer(player.id);
    } else {
      // Criar player local normalmente
      final player = Player(
        name: name,
        avatar: avatar,
      );
      await storage.savePlayer(player);
      _loadAllPlayers();
    }
  }

  Future<void> selectPlayer(String playerId) async {
    await storage.setCurrentPlayer(playerId);
    _loadCurrentPlayer();
  }

  Future<void> updatePlayer(Player player) async {
    await storage.savePlayer(player);
    if (player.id == _currentPlayer?.id) {
      _currentPlayer = player;
    }
    _loadAllPlayers();
  }

  Future<void> deletePlayer(String playerId) async {
    await storage.deletePlayer(playerId);
    if (_currentPlayer?.id == playerId) {
      _currentPlayer = null;
    }
    _loadAllPlayers();
  }
}
