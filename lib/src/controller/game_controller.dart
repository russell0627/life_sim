
import 'dart:async';
import 'dart:math';

import 'package:life_sim/src/view/game_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/entity.dart';
import '../model/game_state.dart';
import '../model/grid.dart';
import '../model/plant.dart';
import '../model/animal.dart';
import '../model/cell.dart';
import '../model/terrain.dart';
import '../utils/pathfinding.dart';
import 'world_generator.dart';

part 'game_controller.g.dart';

@riverpod
class GameController extends _$GameController {
  Timer? _timer;
  final Random _random = Random();

  @override
  GameState build() {
    final initialState = WorldGenerator.generate(width: 20, height: 20, initialPlants: 50, initialAnimals: 5);
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => tick());
    ref.onDispose(() => _timer?.cancel());
    return initialState;
  }

  void tick() {
    var currentGrid = state.grid;
    var currentPlants = List<Plant>.from(state.plants);
    var currentAnimals = List<Animal>.from(state.animals);
    var newTick = state.currentTick + 1;

    // --- Entity Collection for Grid Update ---
    Map<Point<int>, List<Entity>> nextCellEntities = {};

    // --- Plant Growth and Spreading Logic ---
    List<Plant> plantsToAdd = [];
    List<Plant> updatedPlants = [];

    for (var plant in currentPlants) {
      // Handle berry bush regrowth
      if (plant.type == PlantType.berryBush && plant.isEmpty) {
        if (plant.regrowthTimer > 0) {
          plant.regrowthTimer--;
        } else {
          plant.isEmpty = false;
          plant.nutritionalValue = 25.0; // Reset to initial nutritious value
          plant.size = 2.0; // Reset to initial size
        }
      }

      // Plant grows (only if not empty for berry bush)
      if (!(plant.type == PlantType.berryBush && plant.isEmpty)) {
        if (plant.type == PlantType.grass) {
          plant.size += 0.2; // Grass grows faster
          plant.nutritionalValue += 0.5; // Grass becomes more nutritious faster
        } else if (plant.type == PlantType.berryBush) {
          plant.size += 0.01; // Berry bushes grow very slowly
          plant.nutritionalValue += 0.05; // Berry bushes become more nutritious very slowly
        } else {
          plant.size += 0.05;
          plant.nutritionalValue += 0.2;
        }
      }
      updatedPlants.add(plant.copyWith()); // Add copy to updated list

      // Plant spreads
      double spreadChance = 0.005; // Default spread chance
      if (plant.type == PlantType.grass) {
        spreadChance = 0.1; // Grass spreads much faster (10% chance per tick)
      } else if (plant.type == PlantType.berryBush) {
        spreadChance = 0.001; // Berry bushes spread very slowly
      }

      if (_random.nextDouble() < spreadChance) {
        final adjacentPositions = <Point<int>>[];
        for (int dx = -1; dx <= 1; dx++) {
          for (int dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue;
            final newX = plant.position.x + dx;
            final newY = plant.position.y + dy;
            final newPosition = Point(newX, newY);

            if (newX >= 0 && newX < currentGrid.width &&
                newY >= 0 && newY < currentGrid.height) {
              final targetCell = currentGrid.getCell(newPosition);
              // Plants can only spread to grassland or forest
              if ((targetCell.terrain == TerrainType.grassland || targetCell.terrain == TerrainType.forest) &&
                  !currentPlants.any((p) => p.position == newPosition)) { // No plant-on-plant overlap
                adjacentPositions.add(newPosition);
              }
            }
          }
        }

        if (adjacentPositions.isNotEmpty) {
          final spreadPosition = adjacentPositions[_random.nextInt(adjacentPositions.length)];
          final newPlant = Plant(position: spreadPosition, type: plant.type); // Spread the same type of plant
          plantsToAdd.add(newPlant);
        }
      }
    }
    currentPlants.addAll(plantsToAdd);
    currentPlants = updatedPlants.toSet().toList(); // Remove duplicates and update currentPlants

    // Add all current plants to the nextCellEntities map
    for (var plant in currentPlants) {
      nextCellEntities.update(plant.position, (value) => value..add(plant), ifAbsent: () => [plant]);
    }

    List<Animal> nextAnimals = [];
    List<Plant> nextPlants = List.from(currentPlants); // Copy for animal consumption

    for (var animal in currentAnimals) {
      animal.hunger -= 2.0;
      animal.thirst -= 1.5;
      animal.energy -= 0.5;
      animal.lifespan--;

      animal.hunger = max(0.0, animal.hunger);
      animal.thirst = max(0.0, animal.thirst);
      animal.energy = max(0.0, animal.energy);

      if (animal.hunger <= 0 || animal.thirst <= 0 || animal.lifespan <= 0) {
        continue;
      }

      if (animal.isSleeping) {
        animal.sleepDuration++;
        animal.energy = min(100.0, animal.energy + 5.0);
        if (animal.sleepDuration >= 10 || animal.energy >= 90) {
          animal.isSleeping = false;
          animal.sleepDuration = 0;
        }
        nextAnimals.add(animal.copyWith());
        continue;
      }

      Point<int> targetPosition = animal.position;
      int stepsTaken = 0;

      // Define a dynamic obstacle predicate for the current animal
      bool animalObstaclePredicate(Cell cell, Point<int> pos) {
        // Pathfinding already handles elevation difference
        if (cell.terrain == TerrainType.mountain) return true; // All animals avoid mountains
        if (animal.type == AnimalType.rabbit && cell.terrain == TerrainType.water) return true; // Rabbits avoid water
        // Add other animal-specific terrain restrictions here
        return false;
      }

      while (stepsTaken < animal.speed) {
        Point<int> currentAnimalPosition = animal.position;
        bool actionTaken = false;

        if (animal.thirst < 50) {
          final path = Pathfinding.findPath(
            currentGrid,
            currentAnimalPosition,
            (cell, pos) => cell.terrain == TerrainType.water,
            animalObstaclePredicate,
          );
          if (path != null && path.length > 1) {
            targetPosition = path[1];
          } else if (currentGrid.getCell(currentAnimalPosition).terrain == TerrainType.water) {
            animal.thirst = 100.0;
            actionTaken = true;
          }
        } else if (animal.hunger < 50) {
          if (animal.diet == Diet.herbivore) {
            final path = Pathfinding.findPath(
              currentGrid,
              currentAnimalPosition,
              (cell, pos) => nextPlants.any((p) => p.position == pos && (p.type == PlantType.grass || (p.type == PlantType.berryBush && !p.isEmpty))), // Only target non-empty berry bushes
              animalObstaclePredicate,
            );
            if (path != null && path.length > 1) {
              targetPosition = path[1];
            } else {
              // If already on a plant, eat it
              final plantToEat = nextPlants.firstWhereOrNull(
                (p) => p.position == currentAnimalPosition && (p.type == PlantType.grass || (p.type == PlantType.berryBush && !p.isEmpty)),
              );
              if (plantToEat != null) {
                animal.hunger = min(100.0, animal.hunger + plantToEat.nutritionalValue);
                actionTaken = true;

                if (plantToEat.type == PlantType.grass) {
                  plantToEat.size = max(1.0, plantToEat.size - 1.0); // Regress size
                  plantToEat.nutritionalValue = max(10.0, plantToEat.nutritionalValue - 10.0); // Regress nutrition
                } else if (plantToEat.type == PlantType.berryBush) {
                  plantToEat.isEmpty = true;
                  plantToEat.regrowthTimer = 20; // 20 ticks to regrow berries
                  plantToEat.nutritionalValue = 0.0; // No nutrition while empty
                }
              }
            }
          } else if (animal.diet == Diet.carnivore) {
            final path = Pathfinding.findPath(
              currentGrid,
              currentAnimalPosition,
              (cell, pos) => nextAnimals.any((a) => a.position == pos && a.diet == Diet.herbivore),
              animalObstaclePredicate,
            );
            if (path != null && path.length > 1) {
              targetPosition = path[1];
            } else {
              final prey = nextAnimals.firstWhereOrNull(
                (a) => a.position == currentAnimalPosition && a.diet == Diet.herbivore,
              );
              if (prey != null) {
                animal.hunger = min(100.0, animal.hunger + 50.0);
                nextAnimals.remove(prey);
                actionTaken = true;
              }
            }
          }
        } else if (animal.energy < 30) {
          animal.isSleeping = true;
          animal.sleepDuration = 0;
          actionTaken = true;
        } else {
          final possibleMoves = <Point<int>>[];
          for (int dx = -1; dx <= 1; dx++) {
            for (int dy = -1; dy <= 1; dy++) {
              if (dx == 0 && dy == 0) continue;
              final newX = currentAnimalPosition.x + dx;
              final newY = currentAnimalPosition.y + dy;
              final newPosition = Point(newX, newY);

              if (newX >= 0 && newX < currentGrid.width &&
                  newY >= 0 && newY < currentGrid.height) {
                // Use the dynamic obstacle predicate for wandering
                if (!animalObstaclePredicate(currentGrid.getCell(newPosition), newPosition)) {
                  possibleMoves.add(newPosition);
                }
              }
            }
          }
          if (possibleMoves.isNotEmpty) {
            targetPosition = possibleMoves[_random.nextInt(possibleMoves.length)];
          }
        }

        if (!actionTaken && targetPosition != currentAnimalPosition) {
          animal.position = targetPosition;
        }
        stepsTaken++;
        if (actionTaken) break;
      }
      nextAnimals.add(animal.copyWith());

      nextCellEntities.update(animal.position, (value) => value..add(animal), ifAbsent: () => [animal]);
    }

    Grid newGrid = Grid(width: currentGrid.width, height: currentGrid.height);
    for (int x = 0; x < newGrid.width; x++) {
      for (int y = 0; y < newGrid.height; y++) {
        final position = Point(x, y);
        final originalCell = currentGrid.getCell(position);
        List<Entity> entitiesInCell = nextCellEntities[position] ?? [];

        List<Entity> finalEntitiesForCell = [];
        Animal? animalInCell;
        Plant? plantInCell;

        for (var entity in entitiesInCell) {
          if (entity is Animal) {
            animalInCell = entity;
          } else if (entity is Plant) {
            plantInCell = entity;
          }
        }

        if (animalInCell != null) {
          finalEntitiesForCell.add(animalInCell);
          if (originalCell.terrain == TerrainType.grassland || originalCell.terrain == TerrainType.forest) {
            if (plantInCell != null) {
              if (animalInCell.type == AnimalType.rabbit && plantInCell.type == PlantType.berryBush) {
                finalEntitiesForCell.add(plantInCell);
              } else if (plantInCell.type == PlantType.grass) {
                finalEntitiesForCell.add(plantInCell);
              }
            }
          }
        } else if (plantInCell != null) {
          finalEntitiesForCell.add(plantInCell);
        }

        newGrid = newGrid.setCell(
          position,
          originalCell.copyWith(entities: finalEntitiesForCell),
        );
      }
    }

    state = state.copyWith(grid: newGrid, plants: nextPlants, animals: nextAnimals, currentTick: newTick);
  }
}
