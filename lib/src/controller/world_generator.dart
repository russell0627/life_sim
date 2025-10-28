
import 'dart:math';

import '../model/animal.dart';
import '../model/game_state.dart';
import '../model/grid.dart';
import '../model/plant.dart';
import '../model/terrain.dart';

class WorldGenerator {
  static GameState generate({
    required int width,
    required int height,
    int initialPlants = 10,
    int initialAnimals = 5,
  }) {
    final Random random = Random();
    Grid grid = Grid(width: width, height: height);
    List<Plant> plants = [];
    List<Animal> animals = [];

    // Step 1: Generate initial random elevations
    List<List<int>> elevations = List.generate(width, (_) => List.generate(height, (_) => random.nextInt(5))); // Elevation from 0 to 4

    // Step 2: Apply a smoothing pass to create hills
    // This is a simple average with neighbors, repeated a few times
    for (int s = 0; s < 3; s++) { // 3 smoothing passes
      List<List<int>> newElevations = List.generate(width, (_) => List.generate(height, (_) => 0));
      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          int sumElevation = elevations[x][y];
          int count = 1;
          for (int dx = -1; dx <= 1; dx++) {
            for (int dy = -1; dy <= 1; dy++) {
              if (dx == 0 && dy == 0) continue;
              int nx = x + dx;
              int ny = y + dy;
              if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
                sumElevation += elevations[nx][ny];
                count++;
              }
            }
          }
          newElevations[x][y] = (sumElevation / count).round().clamp(0, 4); // Keep elevation within bounds
        }
      }
      elevations = newElevations;
    }

    // Step 3: Assign TerrainType based on smoothed elevation
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final position = Point(x, y);
        int elevation = elevations[x][y];
        TerrainType terrain;

        if (elevation == 0 && random.nextDouble() < 0.4) { // Higher chance for water at lowest elevation
          terrain = TerrainType.water;
        } else if (elevation >= 3) { // Mountains at higher elevations
          terrain = TerrainType.mountain;
        } else if (elevation >= 1 && random.nextDouble() < 0.4) { // Forests at mid-elevations
          terrain = TerrainType.forest;
        } else {
          terrain = TerrainType.grassland;
        }

        // Ensure water is always elevation 0
        if (terrain == TerrainType.water) {
          elevation = 0;
        }

        grid = grid.setCell(position, grid.getCell(position).copyWith(terrain: terrain, elevation: elevation));
      }
    }

    // Place initial plants
    for (int i = 0; i < initialPlants; i++) {
      Point<int> position;
      PlantType plantType = PlantType.values[random.nextInt(PlantType.values.length)];
      do {
        position = Point(random.nextInt(width), random.nextInt(height));
      } while (grid.getCell(position).terrain == TerrainType.water ||
               grid.getCell(position).terrain == TerrainType.mountain ||
               plants.any((p) => p.position == position));
      plants.add(Plant(position: position, type: plantType));
    }

    // Place initial animals
    for (int i = 0; i < initialAnimals; i++) {
      Point<int> position;
      AnimalType animalType = AnimalType.values[random.nextInt(AnimalType.values.length)];
      do {
        position = Point(random.nextInt(width), random.nextInt(height));
      } while (grid.getCell(position).terrain == TerrainType.water ||
               grid.getCell(position).terrain == TerrainType.mountain ||
               plants.any((p) => p.position == position) ||
               animals.any((a) => a.position == position));
      animals.add(Animal(position: position, type: animalType));
    }

    return GameState(grid: grid, plants: plants, animals: animals, currentTick: 0);
  }
}
