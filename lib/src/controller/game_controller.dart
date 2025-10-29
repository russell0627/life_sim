
import 'dart:async';
import 'dart:math';

import 'package:life_sim/src/view/game_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/entity.dart';
import '../model/game_state.dart';
import '../model/grid.dart';
import '../model/plant.dart';
import '../model/animal.dart';
import '../model/villager.dart'; // Import the Villager class
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
    final initialState = WorldGenerator.generate(width: 50, height: 50, initialPlants: 150, initialAnimals: 30, initialVillagers: 5); // Add initial villagers
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => tick());
    ref.onDispose(() => _timer?.cancel());
    return initialState;
  }

  void tick() {
    var currentGrid = state.grid;
    var currentPlants = List<Plant>.from(state.plants);
    var currentAnimals = List<Animal>.from(state.animals);
    var currentVillagers = List<Villager>.from(state.villagers); // Get current villagers
    var newTick = state.currentTick + 1;
    var currentSeason = state.currentSeason;
    var seasonTickCounter = state.seasonTickCounter + 1;

    // --- Season Progression ---
    const int ticksPerSeason = 100; // Example: 100 ticks per season
    if (seasonTickCounter >= ticksPerSeason) {
      seasonTickCounter = 0;
      currentSeason = Season.values[(currentSeason.index + 1) % Season.values.length];
      // Apply season-specific effects here (e.g., plant die-off in winter)
    }

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

      // Plant grows (only if not empty for berry bush and not winter)
      if (currentSeason != Season.winter && !(plant.type == PlantType.berryBush && plant.isEmpty)) {
        if (plant.type == PlantType.grass) {
          plant.size += 0.2; // Grass grows faster
          plant.nutritionalValue += 0.5; // Grass becomes more nutritious faster
        } else if (plant.type == PlantType.berryBush) {
          plant.size += 0.01; // Berry bushes grow very slowly
          plant.nutritionalValue += 0.05; // Berry bushes become more nutritious very slowly
        } else if (plant.type == PlantType.tree) {
          plant.size += 0.005; // Trees grow very slowly
        }
      }
      updatedPlants.add(plant.copyWith()); // Add copy to updated list

      // Plant spreads (only if not winter)
      if (currentSeason != Season.winter) {
        double spreadChance = 0.005; // Default spread chance
        if (plant.type == PlantType.grass) {
          spreadChance = 0.4; // Grass spreads much faster (40% chance per tick)
        } else if (plant.type == PlantType.berryBush) {
          spreadChance = 0.001; // Berry bushes spread very slowly
        } else if (plant.type == PlantType.tree) {
          spreadChance = 0.0005; // Trees spread very, very slowly
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
    }
    currentPlants.addAll(plantsToAdd);
    currentPlants = updatedPlants.toSet().toList(); // Remove duplicates and update currentPlants

    // Add all current plants to the nextCellEntities map
    for (var plant in currentPlants) {
      nextCellEntities.update(plant.position, (value) => value..add(plant), ifAbsent: () => [plant]);
    }

    List<Animal> nextAnimals = [];
    List<Animal> animalsToReproduce = [];
    List<Plant> nextPlants = List.from(currentPlants); // Corrected: Moved declaration here

    for (var animal in currentAnimals) {
      // Create a mutable copy for this tick's processing
      Animal processedAnimal = animal.copyWith();

      // --- Animal Aging ---
      processedAnimal.age++;

      // --- Animal Reproduction ---
      if (currentSeason == Season.spring && // Animals reproduce in spring
          processedAnimal.age >= processedAnimal.maturityAge &&
          processedAnimal.reproductionCooldown <= 0 &&
          processedAnimal.energy > 70 && // Needs to be healthy to reproduce
          _random.nextDouble() < processedAnimal.reproductionChance) {
        animalsToReproduce.add(processedAnimal); // Add the current state for reproduction
        processedAnimal.reproductionCooldown = 50; // Cooldown before reproducing again
      }

      // Decrement reproduction cooldown
      if (processedAnimal.reproductionCooldown > 0) {
        processedAnimal.reproductionCooldown--;
      }

      // Deplete needs
      processedAnimal.hunger -= 3.0;
      processedAnimal.thirst -= 1.5;
      processedAnimal.energy -= 0.5;
      processedAnimal.lifespan--;

      processedAnimal.hunger = max(0.0, processedAnimal.hunger);
      processedAnimal.thirst = max(0.0, processedAnimal.thirst);
      processedAnimal.energy = max(0.0, processedAnimal.energy);

      if (processedAnimal.hunger <= 0 || processedAnimal.thirst <= 0 || processedAnimal.lifespan <= 0) {
        continue; // Animal dies, not added to nextAnimals
      }

      if (processedAnimal.isSleeping) {
        processedAnimal.sleepDuration++;
        processedAnimal.energy = min(100.0, processedAnimal.energy + 5.0);
        if (processedAnimal.sleepDuration >= 10 || processedAnimal.energy >= 90) {
          processedAnimal.isSleeping = false;
          processedAnimal.sleepDuration = 0;
        }
        nextAnimals.add(processedAnimal.copyWith(previousPosition: processedAnimal.position)); // No movement, so previous is current
        continue;
      }

      // Capture the position *before* any movement calculations for this tick
      Point<int> positionBeforeMovement = processedAnimal.position;

      Point<int> targetPositionForStep = processedAnimal.position; // This is the target for a single step
      int stepsTaken = 0;

      bool Function(Cell, Point<int>) animalObstaclePredicate = (cell, pos) {
        if (cell.terrain == TerrainType.hill) return true; // All animals avoid hills
        if (processedAnimal.type == AnimalType.rabbit && cell.terrain == TerrainType.water) return true; // Rabbits avoid water
        return false;
      };

      while (stepsTaken < processedAnimal.speed) {
        Point<int> currentAnimalPositionInStep = processedAnimal.position;
        bool actionTaken = false;

        if (processedAnimal.thirst < 50) {
          final path = Pathfinding.findPath(
            currentGrid,
            currentAnimalPositionInStep,
            (cell, pos) => cell.terrain == TerrainType.water,
            animalObstaclePredicate,
          );
          if (path != null && path.length > 1) {
            targetPositionForStep = path[1];
          } else if (currentGrid.getCell(currentAnimalPositionInStep).terrain == TerrainType.water) {
            processedAnimal.thirst = 100.0;
            actionTaken = true;
          }
        } else if (processedAnimal.hunger < 50) {
          if (processedAnimal.diet == Diet.herbivore) {
            final path = Pathfinding.findPath(
              currentGrid,
              currentAnimalPositionInStep,
              (cell, pos) => nextPlants.any((p) => p.position == pos && (p.type == PlantType.grass || (p.type == PlantType.berryBush && !p.isEmpty))), // Only target non-empty berry bushes
              animalObstaclePredicate,
            );
            if (path != null && path.length > 1) {
              targetPositionForStep = path[1];
            } else {
              final plantToEat = nextPlants.firstWhereOrNull(
                (p) => p.position == currentAnimalPositionInStep && (p.type == PlantType.grass || (p.type == PlantType.berryBush && !p.isEmpty)),
              );
              if (plantToEat != null) {
                processedAnimal.hunger = min(100.0, processedAnimal.hunger + plantToEat.nutritionalValue);
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
          } else if (processedAnimal.diet == Diet.carnivore) {
            final path = Pathfinding.findPath(
              currentGrid,
              currentAnimalPositionInStep,
              (cell, pos) => nextAnimals.any((a) => a.position == pos && a.diet == Diet.herbivore),
              animalObstaclePredicate,
            );
            if (path != null && path.length > 1) {
              targetPositionForStep = path[1];
            } else {
              final prey = nextAnimals.firstWhereOrNull(
                (a) => a.position == currentAnimalPositionInStep && a.diet == Diet.herbivore,
              );
              if (prey != null) {
                processedAnimal.hunger = min(100.0, processedAnimal.hunger + 50.0);
                nextAnimals.remove(prey); // Prey is removed from the list of animals for the next tick
                actionTaken = true;
              }
            }
          }
        } else if (processedAnimal.energy < 30) {
          processedAnimal.isSleeping = true;
          processedAnimal.sleepDuration = 0;
          actionTaken = true;
        } else {
          final possibleMoves = <Point<int>>[];
          for (int dx = -1; dx <= 1; dx++) {
            for (int dy = -1; dy <= 1; dy++) {
              if (dx == 0 && dy == 0) continue;
              final newX = currentAnimalPositionInStep.x + dx;
              final newY = currentAnimalPositionInStep.y + dy;
              final newPosition = Point(newX, newY);

              if (newX >= 0 && newX < currentGrid.width &&
                  newY >= 0 && newY < currentGrid.height) {
                if (!animalObstaclePredicate(currentGrid.getCell(newPosition), newPosition)) {
                  possibleMoves.add(newPosition);
                }
              }
            }
          }
          if (possibleMoves.isNotEmpty) {
            targetPositionForStep = possibleMoves[_random.nextInt(possibleMoves.length)];
          }
        }

        if (!actionTaken && targetPositionForStep != currentAnimalPositionInStep) {
          processedAnimal.position = targetPositionForStep; // Update position for the next step in this tick
        }
        stepsTaken++;
        if (actionTaken) break;
      }

      // After all movement steps for this tick are calculated, add the final state to nextAnimals.
      nextAnimals.add(processedAnimal.copyWith(previousPosition: positionBeforeMovement));

      // Update nextCellEntities with the animal's *final* position for this tick.
      nextCellEntities.update(processedAnimal.position, (value) => value..add(processedAnimal), ifAbsent: () => [processedAnimal]);
    }

    // --- Animal Reproduction ---
    for (var parentAnimal in animalsToReproduce) {
      // Find a suitable empty adjacent cell for the offspring
      final adjacentEmptyCells = <Point<int>>[];
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) continue;
          final newX = parentAnimal.position.x + dx;
          final newY = parentAnimal.position.y + dy;
          final newPosition = Point(newX, newY);

          if (newX >= 0 && newX < currentGrid.width &&
              newY >= 0 && newY < currentGrid.height) {
            // Check if cell is not water/hill and not occupied by another animal
            final targetCell = currentGrid.getCell(newPosition);
            if (targetCell.terrain != TerrainType.water &&
                targetCell.terrain != TerrainType.hill &&
                !nextAnimals.any((a) => a.position == newPosition)) {
              adjacentEmptyCells.add(newPosition);
            }
          }
        }
      }

      if (adjacentEmptyCells.isNotEmpty) {
        final offspringPosition = adjacentEmptyCells[_random.nextInt(adjacentEmptyCells.length)];
        final offspring = Animal(
          position: offspringPosition,
          type: parentAnimal.type,
          age: 0, // Newborn
          hunger: 80.0, // Start a bit hungry
          thirst: 80.0,
          energy: 80.0,
          lifespan: parentAnimal.lifespan, // Inherit lifespan potential
          speed: parentAnimal.speed, // Inherit speed
          diet: parentAnimal.diet, // Inherit diet
          maturityAge: parentAnimal.maturityAge,
          reproductionChance: parentAnimal.reproductionChance,
          previousPosition: offspringPosition, // Offspring starts at its position
        );
        nextAnimals.add(offspring);
        // Add offspring to nextCellEntities so it's rendered immediately
        nextCellEntities.update(offspringPosition, (value) => value..add(offspring), ifAbsent: () => [offspring]);
      }
    }

    List<Villager> nextVillagers = [];
    for (var villager in currentVillagers) {
      Villager processedVillager = villager.copyWith();

      // --- Villager Aging ---
      processedVillager.age++;

      // --- Deplete Needs ---
      processedVillager.hunger -= 1.0; // Slower hunger depletion than animals
      processedVillager.thirst -= 1.0;
      processedVillager.energy -= 0.2;
      processedVillager.lifespan--;

      processedVillager.hunger = max(0.0, processedVillager.hunger);
      processedVillager.thirst = max(0.0, processedVillager.thirst);
      processedVillager.energy = max(0.0, processedVillager.energy);

      // --- Death Condition ---
      if (processedVillager.hunger <= 0 || processedVillager.thirst <= 0 || processedVillager.lifespan <= 0) {
        continue; // Villager dies
      }

      // Capture the position *before* any movement calculations for this tick
      Point<int> positionBeforeMovement = processedVillager.position;
      Point<int> targetPosition = processedVillager.position;
      bool actionTaken = false;

      // --- Villager Obstacle Predicate ---
      bool Function(Cell, Point<int>) villagerObstaclePredicate = (cell, pos) {
        if (cell.terrain == TerrainType.water || cell.terrain == TerrainType.hill) return true;
        return false;
      };

      // --- Priority-Based Actions ---
      if (processedVillager.isSleeping) {
        processedVillager.sleepDuration++;
        processedVillager.energy = min(100.0, processedVillager.energy + 5.0);
        if (processedVillager.sleepDuration >= 10 || processedVillager.energy >= 90) {
          processedVillager.isSleeping = false;
          processedVillager.sleepDuration = 0;
        }
        actionTaken = true;
      } else if (processedVillager.thirst < 50) {
        final path = Pathfinding.findPath(
          currentGrid,
          processedVillager.position,
          (cell, pos) => cell.terrain == TerrainType.water, // Target water
          villagerObstaclePredicate,
        );
        if (path != null && path.length > 1) {
          targetPosition = path[1];
        } else if (currentGrid.getCell(processedVillager.position).terrain == TerrainType.water) {
          processedVillager.thirst = 100.0; // Drink water
          actionTaken = true;
        }
      } else if (processedVillager.hunger < 50) {
        final path = Pathfinding.findPath(
          currentGrid,
          processedVillager.position,
          (cell, pos) => nextPlants.any((p) => p.position == pos && (p.type == PlantType.berryBush && !p.isEmpty)), // Target non-empty berry bushes
          villagerObstaclePredicate,
        );
        if (path != null && path.length > 1) {
          targetPosition = path[1];
        } else {
          final plantToEat = nextPlants.firstWhereOrNull(
            (p) => p.position == processedVillager.position && (p.type == PlantType.berryBush && !p.isEmpty),
          );
          if (plantToEat != null) {
            processedVillager.hunger = min(100.0, processedVillager.hunger + plantToEat.nutritionalValue);
            plantToEat.isEmpty = true;
            plantToEat.regrowthTimer = 20; // 20 ticks to regrow berries
            plantToEat.nutritionalValue = 0.0; // No nutrition while empty
            actionTaken = true;
          }
        }
      } else if (processedVillager.energy < 30) {
        processedVillager.isSleeping = true;
        processedVillager.sleepDuration = 0;
        actionTaken = true;
      } else {
        // Random movement if no critical needs
        final possibleMoves = <Point<int>>[];
        for (int dx = -1; dx <= 1; dx++) {
          for (int dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue;
            final newX = processedVillager.position.x + dx;
            final newY = processedVillager.position.y + dy;
            final newPosition = Point(newX, newY);

            if (newX >= 0 && newX < currentGrid.width &&
                newY >= 0 && newY < currentGrid.height) {
              final targetCell = currentGrid.getCell(newPosition);
              if (!villagerObstaclePredicate(targetCell, newPosition)) {
                possibleMoves.add(newPosition);
              }
            }
          }
        }
        if (possibleMoves.isNotEmpty) {
          targetPosition = possibleMoves[_random.nextInt(possibleMoves.length)];
        }
      }

      if (!actionTaken && targetPosition != processedVillager.position) {
        processedVillager.position = targetPosition;
      }

      nextVillagers.add(processedVillager.copyWith(previousPosition: positionBeforeMovement));

      // Update nextCellEntities with the villager's *final* position for this tick.
      nextCellEntities.update(processedVillager.position, (value) => value..add(processedVillager), ifAbsent: () => [processedVillager]);
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
        Villager? villagerInCell; // New: Check for villager in cell

        for (var entity in entitiesInCell) {
          if (entity is Animal) {
            animalInCell = entity;
          } else if (entity is Plant) {
            plantInCell = entity;
          } else if (entity is Villager) { // New: Assign villager if found
            villagerInCell = entity;
          }
        }

        // Prioritize rendering order: Villager > Animal > Plant
        if (villagerInCell != null) {
          finalEntitiesForCell.add(villagerInCell);
        } else if (animalInCell != null) {
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

    state = state.copyWith(grid: newGrid, plants: nextPlants, animals: nextAnimals, villagers: nextVillagers, currentTick: newTick, currentSeason: currentSeason, seasonTickCounter: seasonTickCounter);
  }
}
