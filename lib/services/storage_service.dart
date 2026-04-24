import 'package:hive/hive.dart';

import '../models/index.dart';
import 'auth_service.dart';
import 'firebase_service.dart';

class StorageService {
  static const String _playersBox = 'players';
  static const String _scoresBox = 'scores';
  static const String _currentPlayerBox = 'current_player';

  late Box<Map> _playersBox_;
  late Box<Map> _scoresBox_;
  late Box<String> _currentPlayerBox_;

  final AuthService? _authService;
  final FirebaseService? _firebaseService;

  StorageService({AuthService? authService, FirebaseService? firebaseService})
      : _authService = authService,
        _firebaseService = firebaseService;

  Future<void> initialize() async {
    _playersBox_ = await Hive.openBox<Map>(_playersBox);
    _scoresBox_ = await Hive.openBox<Map>(_scoresBox);
    _currentPlayerBox_ = await Hive.openBox<String>(_currentPlayerBox);
  }

  // Player operations
  Future<void> savePlayer(Player player) async {
    await _playersBox_.put(player.id, Map<String, dynamic>.from(player.toMap()));
  }

  Player? getPlayer(String playerId) {
    final map = _playersBox_.get(playerId);
    return map != null ? Player.fromMap(Map<String, dynamic>.from(map)) : null;
  }

  List<Player> getAllPlayers() {
    return _playersBox_.values
        .map((map) => Player.fromMap(Map<String, dynamic>.from(map)))
        .toList();
  }

  Future<void> deletePlayer(String playerId) async {
    await _playersBox_.delete(playerId);
  }

  // Current player operations
  Future<void> setCurrentPlayer(String playerId) async {
    await _currentPlayerBox_.put('current', playerId);
  }

  String? getCurrentPlayerId() {
    return _currentPlayerBox_.get('current');
  }

  Player? getCurrentPlayer() {
    final playerId = getCurrentPlayerId();
    return playerId != null ? getPlayer(playerId) : null;
  }

  // Score operations
  Future<void> saveScore(Score score) async {
    final key = '${score.gameId}_${score.id}';
    await _scoresBox_.put(key, Map<String, dynamic>.from(score.toMap()));
  }

  List<Score> getScoresByGame(String gameId) {
    return _scoresBox_.values
        .where((map) => map['gameId'] == gameId)
        .map((map) => Score.fromMap(Map<String, dynamic>.from(map)))
        .toList();
  }

  List<Score> getScoresByPlayer(String playerId) {
    return _scoresBox_.values
        .where((map) => map['playerId'] == playerId)
        .map((map) => Score.fromMap(Map<String, dynamic>.from(map)))
        .toList();
  }

  List<Score> getScoresByGameAndPlayer(String gameId, String playerId) {
    return _scoresBox_.values
        .where((map) => map['gameId'] == gameId && map['playerId'] == playerId)
        .map((map) => Score.fromMap(Map<String, dynamic>.from(map)))
        .toList();
  }

  List<Score> getAllScores() {
    return _scoresBox_.values.map((map) => Score.fromMap(Map<String, dynamic>.from(map))).toList();
  }

  Future<void> transferScores(String fromPlayerId, String toPlayerId) async {
    final scoresToTransfer = getScoresByPlayer(fromPlayerId);
    for (final score in scoresToTransfer) {
      final updatedScore = Score(
        id: score.id,
        playerId: toPlayerId,
        playerName: score.playerName, // Pode ser atualizado depois se necessário
        gameId: score.gameId,
        points: score.points,
        duration: score.duration,
        metadata: score.metadata,
        date: score.date,
      );
      await saveScore(updatedScore);
    }
    // Opcional: remover scores antigos do player anônimo
    // for (final score in scoresToTransfer) {
    //   await _scoresBox_.delete('${score.gameId}_${score.id}');
    // }
  }

  // Firebase synchronization methods
  Future<void> syncWithFirebase() async {
    if (_authService?.isSignedIn == true && _firebaseService != null) {
      final userId = _authService!.userId!;
      final userName = _authService!.userName ?? 'Unknown User';

      // Sync player data
      final localPlayer = getCurrentPlayer();
      if (localPlayer != null) {
        final firebasePlayer = Player(
          id: userId,
          name: userName,
          avatar: _authService!.userPhotoUrl,
          createdAt: localPlayer.createdAt,
          friendIds: localPlayer.friendIds,
        );
        await _firebaseService!.savePlayer(userId, firebasePlayer);
      }

      // Sync scores
      final localScores = getAllScores();
      for (final score in localScores) {
        await _firebaseService!.saveScore(userId, score);
      }
    }
  }

  Future<void> loadFromFirebase() async {
    if (_authService?.isSignedIn == true && _firebaseService != null) {
      final userId = _authService!.userId!;

      // Load player data from Firebase
      final firebasePlayer = await _firebaseService!.getPlayer(userId);
      if (firebasePlayer != null) {
        await savePlayer(firebasePlayer);
        await setCurrentPlayer(firebasePlayer.id);
      }

      // Load scores from Firebase
      final firebaseScores = await _firebaseService!.getUserScores(userId);
      for (final score in firebaseScores) {
        await saveScore(score);
      }
    }
  }

  Future<void> close() async {
    await _playersBox_.close();
    await _scoresBox_.close();
    await _currentPlayerBox_.close();
  }
}
