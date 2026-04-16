import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/index.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Referências das coleções
  CollectionReference get _players => _firestore.collection('players');
  CollectionReference get _scores => _firestore.collection('scores');

  // Salvar jogador no Firestore
  Future<void> savePlayer(String userId, Player player) async {
    try {
      await _players.doc(userId).set(player.toMap());
    } catch (e) {
      print('Erro ao salvar jogador: $e');
      rethrow;
    }
  }

  // Buscar jogador do Firestore
  Future<Player?> getPlayer(String userId) async {
    try {
      final doc = await _players.doc(userId).get();
      if (doc.exists) {
        return Player.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar jogador: $e');
      return null;
    }
  }

  // Salvar pontuação no Firestore
  Future<void> saveScore(String userId, Score score) async {
    try {
      await _scores.doc().set({
        ...score.toMap(),
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erro ao salvar pontuação: $e');
      rethrow;
    }
  }

  // Buscar pontuações do usuário
  Future<List<Score>> getUserScores(String userId) async {
    try {
      final querySnapshot = await _scores.where('userId', isEqualTo: userId).get();

      final scores = querySnapshot.docs
          .map((doc) => Score.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      scores.sort((a, b) => b.date.compareTo(a.date));
      return scores;
    } catch (e) {
      print('Erro ao buscar pontuações: $e');
      return [];
    }
  }

  // Buscar pontuações por jogo
  Future<List<Score>> getScoresByGame(String gameId) async {
    try {
      final querySnapshot = await _scores
          .where('gameId', isEqualTo: gameId)
          .orderBy('points', descending: true)
          .limit(100)
          .get();

      return querySnapshot.docs
          .map((doc) => Score.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar pontuações por jogo: $e');
      return [];
    }
  }

  // Buscar ranking geral por jogo
  Future<List<Map<String, dynamic>>> getGeneralLeaderboard(String gameId) async {
    try {
      final scores = await getScoresByGame(gameId);
      final Map<String, Map<String, dynamic>> playerStats = {};

      for (final score in scores) {
        final playerName = score.playerName;
        if (!playerStats.containsKey(playerName)) {
          playerStats[playerName] = {
            'name': playerName,
            'totalScore': 0,
            'gamesPlayed': 0,
            'bestScore': 0,
          };
        }

        playerStats[playerName]!['totalScore'] += score.points;
        playerStats[playerName]!['gamesPlayed'] += 1;
        if (score.points > playerStats[playerName]!['bestScore']) {
          playerStats[playerName]!['bestScore'] = score.points;
        }
      }

      final leaderboard = playerStats.values.toList();
      leaderboard.sort((a, b) => (b['totalScore'] as int).compareTo(a['totalScore'] as int));

      return leaderboard;
    } catch (e) {
      print('Erro ao buscar ranking geral: $e');
      return [];
    }
  }

  // Buscar ranking semanal
  Future<List<Map<String, dynamic>>> getWeeklyLeaderboard(String gameId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final querySnapshot = await _scores
          .where('gameId', isEqualTo: gameId)
          .where('date', isGreaterThan: weekAgo.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      final scores = querySnapshot.docs
          .map((doc) => Score.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      final Map<String, Map<String, dynamic>> playerStats = {};

      for (final score in scores) {
        final playerName = score.playerName;
        if (!playerStats.containsKey(playerName)) {
          playerStats[playerName] = {
            'name': playerName,
            'totalScore': 0,
            'gamesPlayed': 0,
          };
        }

        playerStats[playerName]!['totalScore'] += score.points;
        playerStats[playerName]!['gamesPlayed'] += 1;
      }

      final leaderboard = playerStats.values.toList();
      leaderboard.sort((a, b) => (b['totalScore'] as int).compareTo(a['totalScore'] as int));

      return leaderboard;
    } catch (e) {
      print('Erro ao buscar ranking semanal: $e');
      return [];
    }
  }

  // Sincronizar dados locais com Firebase
  Future<void> syncLocalDataToFirebase(
    String userId,
    List<Player> localPlayers,
    List<Score> localScores,
  ) async {
    try {
      // Sincronizar jogadores
      for (final player in localPlayers) {
        if (player.id == userId) {
          await savePlayer(userId, player);
          break;
        }
      }

      // Sincronizar pontuações
      for (final score in localScores) {
        await saveScore(userId, score);
      }
    } catch (e) {
      print('Erro ao sincronizar dados: $e');
    }
  }
}
