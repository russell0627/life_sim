
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_sim/src/model/grid.dart';
import 'package:life_sim/src/utils/pathfinding.dart';
import 'package:life_sim/src/model/terrain.dart'; // Import TerrainType

void main() {
  group('Pathfinding', () {
    test('should find a path on a simple grid', () {
      final grid = Grid(width: 3, height: 3);
      final start = Point(0, 0);
      final end = Point(2, 2);

      final path = Pathfinding.findPath(
        grid,
        start,
        (cell, pos) => pos == end,
      );

      expect(path, isNotNull);
      expect(path!.first, start);
      expect(path.last, end);
      // A simple path could be [(0,0), (1,0), (2,0), (2,1), (2,2)] or similar
      // We just check if it's a valid path length and contains start/end
      expect(path.length, greaterThanOrEqualTo(3)); // Min path length for 3x3 diagonal
    });

    test('should return null if no path is found due to obstacles', () {
      // Create a grid with an obstacle blocking the path
      Grid grid = Grid(width: 3, height: 3);
      grid = grid.setCell(Point(1, 0), grid.getCell(Point(1, 0)).copyWith(terrain: TerrainType.water)); // Use TerrainType
      grid = grid.setCell(Point(1, 1), grid.getCell(Point(1, 1)).copyWith(terrain: TerrainType.water)); // Use TerrainType
      grid = grid.setCell(Point(1, 2), grid.getCell(Point(1, 2)).copyWith(terrain: TerrainType.water)); // Use TerrainType

      final start = Point(0, 1);
      final end = Point(2, 1);

      final path = Pathfinding.findPath(
        grid,
        start,
        (cell, pos) => pos == end,
      );

      expect(path, isNull);
    });

    test('should find a path around an obstacle', () {
      Grid grid = Grid(width: 3, height: 3);
      grid = grid.setCell(Point(1, 1), grid.getCell(Point(1, 1)).copyWith(terrain: TerrainType.water)); // Use TerrainType

      final start = Point(0, 0);
      final end = Point(2, 2);

      final path = Pathfinding.findPath(
        grid,
        start,
        (cell, pos) => pos == end,
      );

      expect(path, isNotNull);
      expect(path!.first, start);
      expect(path.last, end);
      expect(path.length, greaterThanOrEqualTo(4)); // Path should be longer due to obstacle
      expect(path, isNot(contains(Point(1, 1)))); // Should not go through the obstacle
    });

    test('should find path to water terrain', () {
      Grid grid = Grid(width: 3, height: 3);
      grid = grid.setCell(Point(2, 2), grid.getCell(Point(2, 2)).copyWith(terrain: TerrainType.water)); // Use TerrainType

      final start = Point(0, 0);

      final path = Pathfinding.findPath(
        grid,
        start,
        (cell, pos) => cell.terrain == TerrainType.water, // Use TerrainType
      );

      expect(path, isNotNull);
      expect(path!.first, start);
      expect(grid.getCell(path.last).terrain, TerrainType.water);
    });
  });
}
