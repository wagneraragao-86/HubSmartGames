import 'dart:math' as math;

enum Game2048Direction { up, down, left, right }

class Game2048Tile {
  Game2048Tile({
    required this.value,
    required this.bornTurn,
    this.mergedTurn,
  });

  int value;
  int bornTurn;
  int? mergedTurn;

  Game2048Tile copy() {
    return Game2048Tile(
      value: value,
      bornTurn: bornTurn,
      mergedTurn: mergedTurn,
    );
  }
}

class Game2048 {
  static const int size = 4;
  static const int targetTile = 2048;

  final math.Random _random = math.Random();

  late List<List<Game2048Tile?>> board;
  int score = 0;
  int moves = 0;
  int maxTile = 1;
  bool isGameOver = false;
  bool isWon = false;
  int turnCounter = 0;
  DateTime gameStartTime = DateTime.now();

  Game2048() {
    resetGame();
  }

  void resetGame() {
    board = List.generate(size, (_) => List<Game2048Tile?>.filled(size, null));
    score = 0;
    moves = 0;
    maxTile = 1;
    isGameOver = false;
    isWon = false;
    turnCounter = 0;
    gameStartTime = DateTime.now();
    _spawnRandomTile(turnCounter);
    _spawnRandomTile(turnCounter);
  }

  bool move(Game2048Direction direction) {
    if (isGameOver) return false;

    final previousBoard = _cloneBoard(board);
    final currentTurn = turnCounter + 1;
    var gainedPoints = 0;

    switch (direction) {
      case Game2048Direction.left:
        for (var row = 0; row < size; row++) {
          final result = _collapseLine(board[row], currentTurn);
          board[row] = result.line;
          gainedPoints += result.points;
          maxTile = math.max(maxTile, result.maxTile);
          if (result.reachedTarget) {
            isWon = true;
          }
        }
        break;
      case Game2048Direction.right:
        for (var row = 0; row < size; row++) {
          final result = _collapseLine(board[row].reversed.toList(), currentTurn);
          board[row] = result.line.reversed.toList();
          gainedPoints += result.points;
          maxTile = math.max(maxTile, result.maxTile);
          if (result.reachedTarget) {
            isWon = true;
          }
        }
        break;
      case Game2048Direction.up:
        for (var col = 0; col < size; col++) {
          final result = _collapseLine(_getColumn(col), currentTurn);
          _setColumn(col, result.line);
          gainedPoints += result.points;
          maxTile = math.max(maxTile, result.maxTile);
          if (result.reachedTarget) {
            isWon = true;
          }
        }
        break;
      case Game2048Direction.down:
        for (var col = 0; col < size; col++) {
          final result = _collapseLine(_getColumn(col).reversed.toList(), currentTurn);
          _setColumn(col, result.line.reversed.toList());
          gainedPoints += result.points;
          maxTile = math.max(maxTile, result.maxTile);
          if (result.reachedTarget) {
            isWon = true;
          }
        }
        break;
    }

    final moved = !_boardsEqual(previousBoard, board);
    if (!moved) {
      if (!canMove()) {
        isGameOver = true;
      }
      return false;
    }

    turnCounter = currentTurn;
    score += gainedPoints;
    moves++;

    if (isWon) {
      isGameOver = true;
      return true;
    }

    _spawnRandomTile(currentTurn);
    if (!canMove()) {
      isGameOver = true;
    }

    return true;
  }

  Duration get gameDuration => DateTime.now().difference(gameStartTime);

  Map<String, dynamic> getGameStats() {
    return {
      'score': score,
      'moves': moves,
      'maxTile': maxTile,
      'won': isWon,
      'duration': gameDuration.inSeconds,
    };
  }

  bool canMove() {
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        final value = board[row][col]?.value;
        if (value == null) return true;

        if (row + 1 < size && board[row + 1][col]?.value == value) return true;
        if (col + 1 < size && board[row][col + 1]?.value == value) return true;
      }
    }
    return false;
  }

  List<Game2048Tile?> _getColumn(int col) {
    return List<Game2048Tile?>.generate(size, (row) => board[row][col]);
  }

  void _setColumn(int col, List<Game2048Tile?> values) {
    for (var row = 0; row < size; row++) {
      board[row][col] = values[row];
    }
  }

  void _spawnRandomTile(int turn) {
    final emptyCells = <math.Point<int>>[];
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (board[row][col] == null) {
          emptyCells.add(math.Point<int>(row, col));
        }
      }
    }

    if (emptyCells.isEmpty) return;

    final cell = emptyCells[_random.nextInt(emptyCells.length)];
    board[cell.x][cell.y] = Game2048Tile(
      value: 1,
      bornTurn: turn,
    );
  }

  _CollapseResult _collapseLine(List<Game2048Tile?> line, int turn) {
    final values = line.whereType<Game2048Tile>().toList();
    final result = <Game2048Tile?>[];
    var gainedPoints = 0;
    var lineMax = maxTile;
    var reachedTarget = false;

    for (var i = 0; i < values.length; i++) {
      final current = values[i];
      if (i + 1 < values.length && values[i + 1].value == current.value) {
        final mergedValue = current.value * 2;
        final mergedTile = Game2048Tile(
          value: mergedValue,
          bornTurn: turn,
          mergedTurn: turn,
        );
        result.add(mergedTile);
        gainedPoints += mergedValue;
        lineMax = math.max(lineMax, mergedValue);
        if (mergedValue >= targetTile) {
          reachedTarget = true;
        }
        i++;
      } else {
        result.add(current.copy());
      }
    }

    while (result.length < size) {
      result.add(null);
    }

    return _CollapseResult(
      line: result,
      points: gainedPoints,
      maxTile: lineMax,
      reachedTarget: reachedTarget,
    );
  }

  List<List<Game2048Tile?>> _cloneBoard(List<List<Game2048Tile?>> source) {
    return source
        .map(
          (row) => row.map((tile) => tile?.copy()).toList(),
        )
        .toList();
  }

  bool _boardsEqual(List<List<Game2048Tile?>> a, List<List<Game2048Tile?>> b) {
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        final left = a[row][col];
        final right = b[row][col];
        if (left == null && right == null) continue;
        if (left == null || right == null) return false;
        if (left.value != right.value) return false;
      }
    }
    return true;
  }
}

class _CollapseResult {
  const _CollapseResult({
    required this.line,
    required this.points,
    required this.maxTile,
    required this.reachedTarget,
  });

  final List<Game2048Tile?> line;
  final int points;
  final int maxTile;
  final bool reachedTarget;
}
