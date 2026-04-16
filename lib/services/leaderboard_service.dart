import '../models/score.dart';
import 'auth_service.dart';
import 'firebase_service.dart';
import 'storage_service.dart';

class LeaderboardService {
  final StorageService storage;
  final AuthService? authService;
  final FirebaseService? firebaseService;

  LeaderboardService(this.storage, {this.authService, this.firebaseService});

  // Ranking geral por jogo
  Future<List<MapEntry<String, int>>> getGeneralLeaderboard(String gameId) async {
    // Try Firebase first if user is signed in
    if (authService?.isSignedIn == true && firebaseService != null) {
      try {
        final firebaseLeaderboard = await firebaseService!.getGeneralLeaderboard(gameId);
        return firebaseLeaderboard
            .map((entry) => MapEntry(entry['name'] as String, entry['totalScore'] as int))
            .toList();
      } catch (e) {
        print('Erro ao buscar ranking do Firebase, usando dados locais: $e');
      }
    }

    // Fallback to local storage
    final scores = storage.getScoresByGame(gameId);
    final Map<String, int> playerScores = {};

    for (final score in scores) {
      playerScores[score.playerName] = (playerScores[score.playerName] ?? 0) + score.points;
    }

    final sortedList = playerScores.entries.toList();
    sortedList.sort((a, b) => b.value.compareTo(a.value));
    return sortedList;
  }

  // Ranking da semana
  Future<List<MapEntry<String, int>>> getWeeklyLeaderboard(String gameId) async {
    // Try Firebase first if user is signed in
    if (authService?.isSignedIn == true && firebaseService != null) {
      try {
        final firebaseLeaderboard = await firebaseService!.getWeeklyLeaderboard(gameId);
        return firebaseLeaderboard
            .map((entry) => MapEntry(entry['name'] as String, entry['totalScore'] as int))
            .toList();
      } catch (e) {
        print('Erro ao buscar ranking semanal do Firebase, usando dados locais: $e');
      }
    }

    // Fallback to local storage
    final scores = storage.getScoresByGame(gameId);
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final weeklyScores = scores.where((score) => score.date.isAfter(weekAgo)).toList();

    final Map<String, int> playerScores = {};
    for (final score in weeklyScores) {
      playerScores[score.playerName] = (playerScores[score.playerName] ?? 0) + score.points;
    }

    final sortedList = playerScores.entries.toList();
    sortedList.sort((a, b) => b.value.compareTo(a.value));
    return sortedList;
  }

  // Melhor score do jogador
  Future<int?> getBestScore(String gameId, String playerId) async {
    final scores = storage.getScoresByGameAndPlayer(gameId, playerId);
    if (scores.isEmpty) return null;
    return scores.map((s) => s.points).reduce((a, b) => a > b ? a : b);
  }

  // Posição do jogador no ranking geral
  Future<int?> getPlayerRank(String gameId, String playerId) async {
    final scores = storage.getScoresByGameAndPlayer(gameId, playerId);
    if (scores.isEmpty) return null;

    final playerName = scores.first.playerName;
    final leaderboard = await getGeneralLeaderboard(gameId);

    for (int i = 0; i < leaderboard.length; i++) {
      if (leaderboard[i].key == playerName) {
        return i + 1;
      }
    }
    return null;
  }

  // Estatísticas gerais do jogador
  Map<String, dynamic> getPlayerStats(String gameid, String playerId) {
    final scores = storage.getScoresByGameAndPlayer(gameid, playerId);

    if (scores.isEmpty) {
      return {
        'totalGames': 0,
        'totalPoints': 0,
        'bestScore': 0,
        'averageScore': 0,
        'totalTime': 0,
      };
    }

    final totalPoints = scores.fold<int>(0, (sum, score) => sum + score.points);
    final bestScore = scores.map((s) => s.points).reduce((a, b) => a > b ? a : b);
    final averageScore = (totalPoints / scores.length).round();
    final totalTime = scores.fold<int>(0, (sum, score) => sum + (score.duration ?? 0));

    return {
      'totalGames': scores.length,
      'totalPoints': totalPoints,
      'bestScore': bestScore,
      'averageScore': averageScore,
      'totalTime': totalTime,
    };
  }

  // Top scores de todos os tempos
  List<Score> getTopScores(String gameId, {int limit = 10}) {
    final scores = storage.getScoresByGame(gameId);
    scores.sort((a, b) => b.points.compareTo(a.points));
    return scores.take(limit).toList();
  }

  // Scores do dia
  List<Score> getTodayScores(String gameId) {
    final scores = storage.getScoresByGame(gameId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return scores
        .where((score) => score.date.isAfter(today) && score.date.isBefore(tomorrow))
        .toList();
  }
}
