import 'dart:math' as math;

class TowerOfHanoi {
  final int numberOfDisks;
  late List<List<int>> towers; // 3 torres (0, 1, 2)
  int moves = 0;
  bool isGameOver = false;
  DateTime gameStartTime = DateTime.now();
  int selectedTowerIndex = -1;
  List<int> movementHistory = [];

  TowerOfHanoi({this.numberOfDisks = 3}) {
    _initializeTowers();
  }

  void _initializeTowers() {
    towers = [
      List.generate(numberOfDisks, (i) => numberOfDisks - i),
      [],
      [],
    ];
  }

  int get minMovesNeeded => math.pow(2, numberOfDisks).toInt() - 1;

  bool selectTower(int towerIndex) {
    if (towerIndex < 0 || towerIndex > 2) return false;

    if (selectedTowerIndex == -1) {
      // Selecionar primeira torre
      if (towers[towerIndex].isNotEmpty) {
        selectedTowerIndex = towerIndex;
        return true;
      }
      return false;
    } else if (selectedTowerIndex == towerIndex) {
      // Deselecionar
      selectedTowerIndex = -1;
      return false;
    } else {
      // Tentar mover
      return _moveDisk(selectedTowerIndex, towerIndex);
    }
  }

  bool _moveDisk(int from, int to) {
    if (towers[from].isEmpty) return false;

    final disk = towers[from].last;

    // Validar movimento
    if (towers[to].isNotEmpty && towers[to].last < disk) {
      return false; // Disco maior não pode ficar sobre disco menor
    }

    towers[from].removeLast();
    towers[to].add(disk);
    moves++;
    movementHistory.add(disk);

    selectedTowerIndex = -1;

    // Verificar se ganhou
    if (towers[2].length == numberOfDisks) {
      isGameOver = true;
    }

    return true;
  }

  bool canWin() => towers[2].length == numberOfDisks;

  Duration get gameDuration {
    return DateTime.now().difference(gameStartTime);
  }

  bool isSolved() => towers[2].length == numberOfDisks;

  Map<String, dynamic> getGameStats() {
    return {
      'moves': moves,
      'optimalMoves': minMovesNeeded,
      'efficiency': ((minMovesNeeded / moves) * 100).toStringAsFixed(1),
      'duration': gameDuration.inSeconds,
      'disks': numberOfDisks,
    };
  }

  void resetGame() {
    _initializeTowers();
    moves = 0;
    selectedTowerIndex = -1;
    isGameOver = false;
    movementHistory.clear();
    gameStartTime = DateTime.now();
  }

  void undo() {
    if (movementHistory.isEmpty) return;

    // Implementar desfazer
    // Seria necessário manter histórico completo de estados
  }
}
