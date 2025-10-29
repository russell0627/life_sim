
import 'dart:math';

import '../model/animal.dart';
import '../model/cell.dart';
import '../model/game_state.dart';
import '../model/grid.dart';
import '../model/plant.dart';
import '../model/terrain.dart';

class WorldGenerator {
  static final Random _random = Random();

  static double _noise(double x, double y, int seed, int octaves, double persistence) {
    double total = 0;
    double frequency = 1;
    double amplitude = 1;
    double maxValue = 0; // Used for normalizing result to 0.0 - 1.0

    for (int i = 0; i < octaves; i++) {
      double value = _pseudoRandom(x * frequency, y * frequency, seed).toDouble();
      total += value * amplitude;

      maxValue += amplitude;
      amplitude *= persistence;
      frequency *= 2;
    }

    return total / maxValue; // Normalize to 0-1
  }

  static int _pseudoRandom(double x, double y, int seed) {
    int n = (x * 10000).toInt() + (y * 10000).toInt() * 10000 + seed;
    n = (n << 13) ^ n;
    return (n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff;
  }

  static GameState generate({
    required int width,
    required int height,
    int initialPlants = 10,
    int initialAnimals = 5,
  }) {
    Grid grid = Grid(width: width, height: height);
    List<Plant> plants = [];
    List<Animal> animals = [];

    int noiseSeed = _random.nextInt(100000);

    List<List<double>> noiseMap = List.generate(width, (_) => List.generate(height, (_) => 0.0));
    double minNoise = 1.0;
    double maxNoise = 0.0;

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        double scaledX = x / width * 6.0;
        double scaledY = y / height * 6.0;
        noiseMap[x][y] = _noise(scaledX, scaledY, noiseSeed, 4, 0.5);

        if (noiseMap[x][y] < minNoise) minNoise = noiseMap[x][y];
        if (noiseMap[x][y] > maxNoise) maxNoise = noiseMap[x][y];
      }
    }

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final position = Point(x, y);
        double normalizedNoise = (noiseMap[x][y] - minNoise) / (maxNoise - minNoise);

        int elevation = (normalizedNoise * 4).round().clamp(0, 4);
        TerrainType terrain;

        if (normalizedNoise < 0.1) {
          terrain = TerrainType.water;
          elevation = 0;
        } else if (normalizedNoise < 0.75) {
          terrain = TerrainType.grassland;
        } else if (normalizedNoise < 0.9) {
          terrain = TerrainType.forest;
        } else { 
          terrain = TerrainType.hill; // Renamed from mountain to hill
        }

        if (terrain == TerrainType.water) {
          elevation = 0;
        }

        grid = grid.setCell(position, grid.getCell(position).copyWith(terrain: terrain, elevation: elevation));
      }
    }

    // Place initial plants
    for (int i = 0; i < initialPlants; i++) {
      Point<int> position;
      PlantType plantType;
      double plantTypeRoll = _random.nextDouble();
      if (plantTypeRoll < 0.6) {
        plantType = PlantType.grass;
      } else if (plantTypeRoll < 0.9) {
        plantType = PlantType.berryBush;
      } else {
        plantType = PlantType.tree;
      }

      do {
        position = Point(_random.nextInt(width), _random.nextInt(height));
      } while (grid.getCell(position).terrain == TerrainType.water ||
               grid.getCell(position).terrain == TerrainType.hill || // Renamed from mountain to hill
               (plantType == PlantType.tree && grid.getCell(position).terrain != TerrainType.forest) ||
               plants.any((p) => p.position == position));
      plants.add(Plant(position: position, type: plantType));
    }

    // Place initial animals
    for (int i = 0; i < initialAnimals; i++) {
      Point<int> position;
      AnimalType animalType = AnimalType.values[_random.nextInt(AnimalType.values.length)];
      do {
        position = Point(_random.nextInt(width), _random.nextInt(height));
      } while (grid.getCell(position).terrain == TerrainType.water ||
               grid.getCell(position).terrain == TerrainType.hill || // Renamed from mountain to hill
               plants.any((p) => p.position == position) ||
               animals.any((a) => a.position == position));
      animals.add(Animal(position: position, type: animalType));
    }

    return GameState(
      grid: grid,
      plants: plants,
      animals: animals,
      currentTick: 0,
      currentSeason: Season.spring,
      seasonTickCounter: 0,
    );
  }
}
