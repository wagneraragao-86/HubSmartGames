import 'dart:math';

enum Direction { up, down, left, right }

class SnakeGame {
  static const int gridSize = 20;

  List<Point<int>> snake = [const Point(10, 10)];
  late Point<int> food;
  Direction direction = Direction.right;
  Direction nextDirection = Direction.right;
  int score = 0;
  bool isGameOver = false;
  bool isPaused = false;
  int level = 1;
  DateTime gameStartTime = DateTime.now();

  SnakeGame() {
    food = Point<int>(Random().nextInt(gridSize), Random().nextInt(gridSize));
  }

  void update() {
    if (isGameOver || isPaused) return;

    direction = nextDirection;

    final head = snake.first;
    int newX = head.x;
    int newY = head.y;

    switch (direction) {
      case Direction.up:
        newY--;
        break;
      case Direction.down:
        newY++;
        break;
      case Direction.left:
        newX--;
        break;
      case Direction.right:
        newX++;
        break;
    }

    // Verificar colisão com borderasa (wrap around)
    newX = (newX + gridSize) % gridSize;
    newY = (newY + gridSize) % gridSize;

    final newHead = Point<int>(newX, newY);

    // Verificar colisão com o corpo
    if (snake.contains(newHead)) {
      isGameOver = true;
      return;
    }

    snake.insert(0, newHead);

    // Verificar se comeu a comida
    if (newHead == food) {
      score += (10 * level);
      _generateFood();

      // Aumentar nível a cada 50 pontos
      if (score > 0 && score % 50 == 0) {
        level++;
      }
    } else {
      snake.removeLast();
    }
  }

  void _generateFood() {
    do {
      food = Point<int>(Random().nextInt(gridSize), Random().nextInt(gridSize));
    } while (snake.contains(food));
  }

  void changeDirection(Direction newDirection) {
    // Evitar que a cobra vire para trás
    if (direction == Direction.up && newDirection == Direction.down) return;
    if (direction == Direction.down && newDirection == Direction.up) return;
    if (direction == Direction.left && newDirection == Direction.right) return;
    if (direction == Direction.right && newDirection == Direction.left) return;

    nextDirection = newDirection;
  }

  void togglePause() {
    isPaused = !isPaused;
  }

  Duration get gameDuration {
    return DateTime.now().difference(gameStartTime);
  }

  Map<String, dynamic> getGameStats() {
    return {
      'score': score,
      'level': level,
      'duration': gameDuration.inSeconds,
      'snakeLength': snake.length,
    };
  }
}
