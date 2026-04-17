import 'dart:math';

enum PipeDirection { up, right, down, left }

extension PipeDirectionExt on PipeDirection {
  PipeDirection rotateClockwise() {
    switch (this) {
      case PipeDirection.up:
        return PipeDirection.right;
      case PipeDirection.right:
        return PipeDirection.down;
      case PipeDirection.down:
        return PipeDirection.left;
      case PipeDirection.left:
        return PipeDirection.up;
    }
  }

  Point<int> get delta {
    switch (this) {
      case PipeDirection.up:
        return const Point(0, -1);
      case PipeDirection.right:
        return const Point(1, 0);
      case PipeDirection.down:
        return const Point(0, 1);
      case PipeDirection.left:
        return const Point(-1, 0);
    }
  }

  String get label {
    switch (this) {
      case PipeDirection.up:
        return '│';
      case PipeDirection.right:
        return '─';
      case PipeDirection.down:
        return '│';
      case PipeDirection.left:
        return '─';
    }
  }
}

class HidroFluxLevel {
  final String title;
  final int width;
  final int height;
  final Point<int> start;
  final Point<int> goal;
  final List<List<PipeDirection>> grid;

  HidroFluxLevel({
    required this.title,
    required this.width,
    required this.height,
    required this.start,
    required this.goal,
    required this.grid,
  });

  static List<List<PipeDirection>> parse(List<List<int>> raw) {
    return raw
        .map((row) => row.map((value) => PipeDirection.values[value % PipeDirection.values.length]).toList())
        .toList();
  }
}

class HidroFluxGame {
  static final List<HidroFluxLevel> levels = [
    HidroFluxLevel(
      title: 'Fase 1',
      width: 5,
      height: 5,
      start: const Point(0, 2),
      goal: const Point(4, 2),
      grid: HidroFluxLevel.parse([
        [1, 1, 1, 2, 2],
        [0, 2, 1, 2, 2],
        [1, 1, 1, 1, 2],
        [0, 3, 0, 1, 2],
        [0, 0, 0, 1, 3],
      ]),
    ),
    HidroFluxLevel(
      title: 'Fase 2',
      width: 6,
      height: 6,
      start: const Point(0, 3),
      goal: const Point(5, 2),
      grid: HidroFluxLevel.parse([
        [1, 1, 1, 1, 2, 2],
        [0, 2, 2, 3, 2, 2],
        [1, 1, 1, 1, 1, 2],
        [1, 0, 0, 0, 1, 2],
        [1, 1, 1, 0, 1, 2],
        [0, 0, 1, 1, 1, 3],
      ]),
    ),
    HidroFluxLevel(
      title: 'Fase 3',
      width: 8,
      height: 8,
      start: const Point(0, 4),
      goal: const Point(7, 3),
      grid: HidroFluxLevel.parse([
        [1, 1, 1, 1, 2, 2, 2, 2],
        [0, 3, 0, 1, 2, 2, 2, 2],
        [1, 1, 1, 1, 1, 1, 1, 2],
        [1, 0, 3, 0, 1, 1, 0, 2],
        [1, 1, 1, 1, 1, 1, 0, 2],
        [1, 0, 0, 1, 0, 1, 0, 2],
        [1, 1, 1, 1, 1, 1, 0, 2],
        [0, 0, 0, 0, 0, 0, 0, 3],
      ]),
    ),
    HidroFluxLevel(
      title: 'Fase 4',
      width: 10,
      height: 10,
      start: const Point(0, 5),
      goal: const Point(9, 5),
      grid: HidroFluxLevel.parse([
        [1, 1, 1, 1, 1, 2, 2, 2, 2, 2],
        [0, 0, 0, 1, 0, 1, 0, 1, 0, 2],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 2],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 2],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 2],
        [1, 0, 0, 0, 0, 1, 0, 0, 0, 2],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 2],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 2],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 2],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 3],
      ]),
    ),
    HidroFluxLevel(
      title: 'Fase 5',
      width: 12,
      height: 12,
      start: const Point(0, 6),
      goal: const Point(11, 6),
      grid: HidroFluxLevel.parse([
        [1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2],
        [0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 2],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 2],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 2],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2],
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 2],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3],
      ]),
    ),
  ];
}
