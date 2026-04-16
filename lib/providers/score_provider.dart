import 'package:flutter/foundation.dart';

import '../models/index.dart';
import '../services/storage_service.dart';

class ScoreProvider extends ChangeNotifier {
  final StorageService storage;
  List<Score> _scores = [];
  Map<String, List<Score>> _scoresByGame = {};

  ScoreProvider(this.storage) {
    _loadScores();
  }

  List<Score> get scores => _scores;
  Map<String, List<Score>> get scoresByGame => _scoresByGame;

  void _loadScores() {
    _scores = storage.getAllScores();
    _scoresByGame = {};
    for (final score in _scores) {
      if (!_scoresByGame.containsKey(score.gameId)) {
        _scoresByGame[score.gameId] = [];
      }
      _scoresByGame[score.gameId]!.add(score);
    }
    notifyListeners();
  }

  Future<void> saveScore(Score score) async {
    await storage.saveScore(score);
    _loadScores();

    // Sincronizar com Firebase se estiver logado
    await storage.syncWithFirebase();
  }

  List<Score> getScoresByGame(String gameId) {
    return _scoresByGame[gameId] ?? [];
  }

  List<Score> getScoresByPlayer(String playerId) {
    return _scores.where((score) => score.playerId == playerId).toList();
  }

  List<Score> getScoresByGameAndPlayer(String gameId, String playerId) {
    return _scores.where((score) => score.gameId == gameId && score.playerId == playerId).toList();
  }

  Score? getBestScore(String gameId, String playerId) {
    final scores = getScoresByGameAndPlayer(gameId, playerId);
    if (scores.isEmpty) return null;
    scores.sort((a, b) => b.points.compareTo(a.points));
    return scores.first;
  }

  int getTotalScoreByPlayer(String gameId, String playerId) {
    final scores = getScoresByGameAndPlayer(gameId, playerId);
    return scores.fold<int>(0, (sum, score) => sum + score.points);
  }
}
