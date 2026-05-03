import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/index.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class PlayerProvider extends ChangeNotifier {
  final StorageService storage;
  final AuthService? _authService;
  Player? _currentPlayer;
  List<Player> _allPlayers = [];
  String? _anonymousId;

  PlayerProvider(this.storage, {AuthService? authService})
      : _authService = authService {
    _loadCurrentPlayer();
    _loadAllPlayers();
  }

  Player? get currentPlayer => _currentPlayer;
  List<Player> get allPlayers => _allPlayers;
  bool get isLoggedIn => _authService?.isSignedIn == true;
  String get currentUserId => _currentPlayer?.id ?? _anonymousId ?? '';

  void _loadCurrentPlayer() {
    _currentPlayer = storage.getCurrentPlayer();
    if (_currentPlayer == null && !isLoggedIn) {
      _createAnonymousPlayer();
    }
    notifyListeners();
  }

  void _createAnonymousPlayer() {
    _anonymousId = const Uuid().v4();
    _currentPlayer = Player(
      id: _anonymousId!,
      name: 'Jogador Anônimo ${_anonymousId!.substring(0, 8)}',
      avatar: null,
    );
    // Não salvar no storage ainda, apenas manter em memória.
  }

  void _loadAllPlayers() {
    _allPlayers = storage.getAllPlayers();
    notifyListeners();
  }

  Future<void> createPlayer(String name, {String? avatar}) async {
    // Se está autenticado, usar dados do Google.
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
      // Criar player local normalmente.
      final player = Player(
        name: name,
        avatar: avatar,
      );
      await storage.savePlayer(player);
      _loadAllPlayers();
      await selectPlayer(player.id);
    }
  }

  Future<void> loginWithGoogle() async {
    final authService = _authService;
    if (authService == null) return;

    await authService.signInWithGoogle();
    if (authService.isSignedIn) {
      final googleUser = authService.currentUser!;
      final player = Player(
        id: googleUser.uid,
        name: googleUser.displayName ?? 'Usuário',
        avatar: googleUser.photoURL,
      );
      await storage.savePlayer(player);
      _loadAllPlayers();

      // Transferir progresso do usuário anônimo.
      if (_anonymousId != null) {
        await storage.transferScores(_anonymousId!, googleUser.uid);
        _anonymousId = null;
      }

      await selectPlayer(player.id);
    }
  }

  Future<void> logout() async {
    final authService = _authService;
    if (authService != null) {
      await authService.signOut();
    }
    await storage.clearCurrentPlayer();
    _currentPlayer = null;
    _anonymousId = null;
    _createAnonymousPlayer();
    notifyListeners();
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
      await storage.clearCurrentPlayer();
      _currentPlayer = null;
      if (!isLoggedIn) {
        _createAnonymousPlayer();
      }
    }
    _loadAllPlayers();
  }
}
