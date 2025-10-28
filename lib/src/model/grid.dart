
import 'dart:math';

import 'cell.dart';

class Grid {
  Grid({required this.width, required this.height, List<List<Cell>>? cells}) {
    _cells = cells ??
        List.generate(
          width,
          (_) => List.generate(height, (_) => Cell(terrain: Terrain.ground)),
        );
  }

  final int width;
  final int height;
  late final List<List<Cell>> _cells;

  Cell getCell(Point<int> position) {
    if (position.x < 0 ||
        position.x >= width ||
        position.y < 0 ||
        position.y >= height) {
      throw ArgumentError('Position is out of bounds');
    }
    return _cells[position.x][position.y];
  }

  Grid copyWith({List<List<Cell>>? cells}) {
    return Grid(
      width: width,
      height: height,
      cells: cells ?? _cells.map((row) => List<Cell>.from(row)).toList(),
    );
  }

  // Helper to set a cell at a specific position
  Grid setCell(Point<int> position, Cell newCell) {
    final newCells = _cells.map((row) => List<Cell>.from(row)).toList();
    newCells[position.x][position.y] = newCell;
    return Grid(width: width, height: height, cells: newCells);
  }
}
