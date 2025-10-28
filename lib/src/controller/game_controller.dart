
import 'dart:async';
import 'dart:math';

import 'package:life_sim/src/view/game_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/game_state.dart';
import '../model/grid.dart';
import '../model/plant.dart';
import '../model/animal.dart';
import '../model/cell.dart';
import '../utils/pathfinding.dart';
import 'world_generator.dart';

part 'game_controller.g.dart';

@riverpod
class GameController extends _$GameController {
  Timer? _timer;
  final Random _random = Random();

  @override
  GameState build() {
    final initialState = WorldGenerator.generate(width: 20, height: 20, initialPlants: 15, initialAnimals: 5);
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => tick());
    ref.onDispose(() => _timer?.cancel());
    return initialState;
  }

  void tick() {
    var currentGrid = state.grid;
    var currentPlants = List<Plant>.from(state.plants);
    var currentAnimals = List<Animal>.from(state.animals);
    var newTick = state.currentTick + 1;

    // Clear entities from grid for fresh update
    currentGrid = Grid(width: currentGrid.width, height: currentGrid.height);

    // --- Plant Growth and Spreading Logic ---
    List<Plant> plantsToAdd = [];
    Set<Point<int>> occupiedPositions = {};

    for (var plant in currentPlants) {
      occupiedPositions.add(plant.position);
      currentGrid = currentGrid.setCell(
        plant.position,
        currentGrid.getCell(plant.position).copyWith(entities: [plant]),
      );
    }

    for (var plant in currentPlants) {
      plant.size += 0.05;
      plant.nutritionalValue += 0.2;

      if (_random.nextDouble() < 0.005) {
        final adjacentPositions = <Point<int>>[];
        for (int dx = -1; dx <= 1; dx++) {
          for (int dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue;
            final newX = plant.position.x + dx;
            final newY = plant.position.y + dy;
            final newPosition = Point(newX, newY);

            if (newX >= 0 && newX < currentGrid.width &&
                newY >= 0 && newY < currentGrid.height &&
                currentGrid.getCell(newPosition).terrain == Terrain.ground &&
                !occupiedPositions.contains(newPosition)) {
              adjacentPositions.add(newPosition);
            }
          }
        }

        if (adjacentPositions.isNotEmpty) {
          final spreadPosition = adjacentPositions[_random.nextInt(adjacentPositions.length)];
          // FIX: Ensure 'type' is provided when creating a new Plant
          final newPlant = Plant(position: spreadPosition, type: PlantType.values[_random.nextInt(PlantType.values.length)]);
          plantsToAdd.add(newPlant);
          occupiedPositions.add(spreadPosition);
          currentGrid = currentGrid.setCell(
            spreadPosition,
            currentGrid.getCell(spreadPosition).copyWith(entities: [newPlant]),
          );
        }
      }
    }
    currentPlants.addAll(plantsToAdd);
    currentPlants = currentPlants.toSet().toList();

    // --- Animal Spawning Logic ---
    // This logic is now handled by WorldGenerator, but we can add dynamic spawning later if needed.

    // --- Animal Behavior and Need Depletion Logic ---
    List<Animal> nextAnimals = [];
    List<Plant> nextPlants = List.from(currentPlants);

    for (var animal in currentAnimals) {
      // Deplete needs
      animal.hunger -= 2.0;
      animal.thirst -= 1.5;
      animal.energy -= 0.5;
      animal.lifespan--;

      animal.hunger = max(0.0, animal.hunger);
      animal.thirst = max(0.0, animal.thirst);
      animal.energy = max(0.0, animal.energy);

      // Check for death
      if (animal.hunger <= 0 || animal.thirst <= 0 || animal.lifespan <= 0) {
        continue;
      }

      // Handle sleeping behavior
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

      // Determine action based on needs
      Point<int> targetPosition = animal.position;
      int stepsTaken = 0;

      while (stepsTaken < animal.speed) {
        Point<int> currentAnimalPosition = animal.position;
        bool actionTaken = false;

        if (animal.thirst < 50) {
          final path = Pathfinding.findPath(
            currentGrid,
            currentAnimalPosition,
            (cell, pos) => cell.terrain == Terrain.water,
          );
          if (path != null && path.length > 1) {
            targetPosition = path[1];
          } else if (currentGrid.getCell(currentAnimalPosition).terrain == Terrain.water) {
            animal.thirst = 100.0;
            actionTaken = true;
          }
        } else if (animal.hunger < 50) {
          if (animal.diet == Diet.herbivore) {
            final path = Pathfinding.findPath(
              currentGrid,
              currentAnimalPosition,
              (cell, pos) => nextPlants.any((p) => p.position == pos),
            );
            if (path != null && path.length > 1) {
              targetPosition = path[1];
            } else if (nextPlants.any((p) => p.position == currentAnimalPosition)) {
              final plantToEat = nextPlants.firstWhere((p) => p.position == currentAnimalPosition);
              animal.hunger = min(100.0, animal.hunger + plantToEat.nutritionalValue);
              nextPlants.remove(plantToEat);
              actionTaken = true;
            }
          } else if (animal.diet == Diet.carnivore) {
            final path = Pathfinding.findPath(
              currentGrid,
              currentAnimalPosition,
              (cell, pos) => nextAnimals.any((a) => a.position == pos && a.diet == Diet.herbivore),
            );
            if (path != null && path.length > 1) {
              targetPosition = path[1];
            } else {
              // If on the same cell as a herbivore, eat it
              final prey = nextAnimals.firstWhereOrNull(
                (a) => a.position == currentAnimalPosition && a.diet == Diet.herbivore,
              );
              if (prey != null) {
                animal.hunger = min(100.0, animal.hunger + 50.0); // Replenish hunger significantly
                nextAnimals.remove(prey); // Remove eaten prey
                actionTaken = true;
              }
            }
          }
        } else if (animal.energy < 30) {
          animal.isSleeping = true;
          animal.sleepDuration = 0;
          actionTaken = true;
        } else {
          // Wander randomly
          final possibleMoves = <Point<int>>[];
          for (int dx = -1; dx <= 1; dx++) {
            for (int dy = -1; dy <= 1; dy++) {
              if (dx == 0 && dy == 0) continue;
              final newX = currentAnimalPosition.x + dx;
              final newY = currentAnimalPosition.y + dy;
              final newPosition = Point(newX, newY);

              if (newX >= 0 && newX < currentGrid.width &&
                  newY >= 0 && newY < currentGrid.height) {
                possibleMoves.add(newPosition);
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
        if (actionTaken) break; // If an action was taken (eat/drink/sleep), stop moving for this tick
      }
      nextAnimals.add(animal.copyWith());

      // Update the cell with the animal entity (after all movement for this animal)
      currentGrid = currentGrid.setCell(
        animal.position,
        currentGrid.getCell(animal.position).copyWith(entities: [animal]),
      );
    }

    state = state.copyWith(grid: currentGrid, plants: nextPlants, animals: nextAnimals, currentTick: newTick);
  }
}
