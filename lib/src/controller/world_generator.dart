
import 'dart:math';

import '../model/animal.dart';
import '../model/cell.dart';
import '../model/game_state.dart';
import '../model/grid.dart';
import '../model/plant.dart';

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

    // Generate terrain (simple: some water patches)
    for (int i = 0; i < width * height * 0.1; i++) { // 10% water cells
      final x = random.nextInt(width);
      final y = random.nextInt(height);
      final position = Point(x, y);
      grid = grid.setCell(position, grid.getCell(position).copyWith(terrain: Terrain.water));
    }

    // Place initial plants
    for (int i = 0; i < initialPlants; i++) {
      Point<int> position;
      PlantType plantType = PlantType.values[random.nextInt(PlantType.values.length)];
      do {
        position = Point(random.nextInt(width), random.nextInt(height));
      } while (grid.getCell(position).terrain == Terrain.water ||
               plants.any((p) => p.position == position));
      plants.add(Plant(position: position, type: plantType));
    }

    // Place initial animals
    for (int i = 0; i < initialAnimals; i++) {
      Point<int> position;
      AnimalType animalType = AnimalType.values[random.nextInt(AnimalType.values.length)];
      do {
        position = Point(random.nextInt(width), random.nextInt(height));
      } while (grid.getCell(position).terrain == Terrain.water ||
               plants.any((p) => p.position == position) ||
               animals.any((a) => a.position == position));
      animals.add(Animal(position: position, type: animalType));
    }

    // Update grid with initial entities
    for (var plant in plants) {
      grid = grid.setCell(plant.position, grid.getCell(plant.position).copyWith(entities: [plant]));
    }
    for (var animal in animals) {
      grid = grid.setCell(animal.position, grid.getCell(animal.position).copyWith(entities: [animal]));
    }

    return GameState(grid: grid, plants: plants, animals: animals, currentTick: 0);
  }
}
