import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/score.dart';
import '../../providers/player_provider.dart';
import '../../providers/score_provider.dart';
import '../../theme/app_theme.dart';

enum ReactionState { idle, waiting, ready, result }

class ReactionScreen extends StatefulWidget {
  const ReactionScreen({Key? key}) : super(key: key);

  @override
  State<ReactionScreen> createState() => _ReactionScreenState();
}

class _ReactionScreenState extends State<ReactionScreen> {
  ReactionState _state = ReactionState.idle;
  Timer? _readyTimer;
  DateTime? _readyAt;
  int _reactionTime = 0;
  int _currentScore = 0;
  String _message = 'Toque em INICIAR para começar';

  final Random _random = Random();

  void _startRound() {
    _readyTimer?.cancel();
    setState(() {
      _state = ReactionState.waiting;
      _reactionTime = 0;
      _currentScore = 0;
      _message = 'Aguarde o botão ficar verde...';
    });

    final delay = Duration(milliseconds: 800 + _random.nextInt(2200));
    _readyTimer = Timer(delay, () {
      setState(() {
        _state = ReactionState.ready;
        _readyAt = DateTime.now();
        _message = 'TOQUE AGORA!';
      });
    });
  }

  void _handleTap() {
    if (_state == ReactionState.waiting) {
      _readyTimer?.cancel();
      setState(() {
        _state = ReactionState.idle;
        _message = 'Muito cedo! Toque em INICIAR e tente novamente.';
      });
      return;
    }

    if (_state == ReactionState.ready) {
      final elapsed = DateTime.now().difference(_readyAt!).inMilliseconds;
      final points = (1000 - elapsed).clamp(0, 1000);
      setState(() {
        _reactionTime = elapsed;
        _currentScore = points;
        _state = ReactionState.result;
        _message = 'Boa! Tempo: $_reactionTime ms';
      });
      return;
    }

    if (_state == ReactionState.idle || _state == ReactionState.result) {
      _startRound();
    }
  }

  Future<void> _saveScore() async {
    final playerProvider = context.read<PlayerProvider>();
    final scoreProvider = context.read<ScoreProvider>();
    final player = playerProvider.currentPlayer;

    if (player == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um jogador antes de salvar.')),
      );
      return;
    }

    final score = Score(
      playerId: player.id,
      playerName: player.name,
      gameId: 'reaction',
      points: _currentScore,
      duration: _reactionTime,
      metadata: {
        'reactionTime': _reactionTime,
      },
    );

    await scoreProvider.saveScore(score);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Score salvo!')),
    );
  }

  @override
  void dispose() {
    _readyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final scoreProvider = context.watch<ScoreProvider>();
    final player = playerProvider.currentPlayer;
    final bestScore = player == null ? null : scoreProvider.getBestScore('reaction', player.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reação'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Melhor',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  bestScore != null ? '${bestScore.points} pts' : '---',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Último',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  _currentScore > 0 ? '$_currentScore pts' : '---',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Teste seu tempo de resposta',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Toque em INICIAR e espere o botão ficar verde. Clique o mais rápido possível para marcar pontos.',
                  style: const TextStyle(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Game Area
          Expanded(
            child: Center(
              child: SizedBox(
                width: 260,
                height: 260,
                child: ElevatedButton(
                  onPressed: _handleTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _state == ReactionState.ready
                        ? AppTheme.accentGreen
                        : _state == ReactionState.waiting
                            ? AppTheme.accentCyan.withAlpha(40)
                            : AppTheme.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(200),
                      side: BorderSide(color: AppTheme.accentCyan.withAlpha(90)),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _state == ReactionState.ready ? Icons.flash_on : Icons.play_arrow,
                        size: 56,
                        color: AppTheme.textPrimary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _state == ReactionState.idle
                            ? 'INICIAR'
                            : _state == ReactionState.waiting
                                ? 'AGUARDE'
                                : _state == ReactionState.ready
                                    ? 'TOQUE!'
                                    : 'NOVO JOGO',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (_state == ReactionState.result) ...[
                        const SizedBox(height: 8),
                        Text('$_reactionTime ms', style: const TextStyle(fontSize: 18)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Status Message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              _message,
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          // Controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _state == ReactionState.result ? _saveScore : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentCyan,
                      foregroundColor: AppTheme.textPrimary,
                    ),
                    child: const Text('Salvar Score'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _startRound,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.accentCyan),
                    ),
                    child: const Text('Reiniciar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
