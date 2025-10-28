
import 'dart:collection';
import 'dart:math';

import '../model/cell.dart';
import '../model/grid.dart';

class Pathfinding {
  static List<Point<int>>? findPath(
    Grid grid,
    Point<int> start,
    bool Function(Cell, Point<int>) isGoal,
    [bool Function(Cell, Point<int>)? isObstacle] // Added optional obstacle predicate
  ) {
    final queue = Queue<List<Point<int>>>();
    final visited = <Point<int>>{};

    queue.add([start]);
    visited.add(start);

    while (queue.isNotEmpty) {
      final path = queue.removeFirst();
      final current = path.last;

      if (isGoal(grid.getCell(current), current)) {
        return path;
      }

      final neighbors = <Point<int>>[];
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) continue;
          final neighbor = Point(current.x + dx, current.y + dy);

          if (neighbor.x >= 0 &&
              neighbor.x < grid.width &&
              neighbor.y >= 0 &&
              neighbor.y < grid.height &&
              !visited.contains(neighbor)) {
            final neighborCell = grid.getCell(neighbor);
            final currentCell = grid.getCell(current);

            // Check for elevation difference obstacle
            if ((neighborCell.elevation - currentCell.elevation).abs() > 1) {
              continue; // Cannot move if elevation change is too steep
            }

            // Check if the neighbor is an obstacle based on the provided predicate
            if (isObstacle == null || !isObstacle(neighborCell, neighbor)) {
              neighbors.add(neighbor);
            }
          }
        }
      }

      for (var neighbor in neighbors) {
        visited.add(neighbor);
        queue.add(List.from(path)..add(neighbor));
      }
    }
    return null; // No path found
  }
}
