
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/game_controller.dart';
import '../model/cell.dart';
import '../model/plant.dart';
import '../model/animal.dart';
import '../model/villager.dart'; // Import the Villager class
import '../model/terrain.dart';
import 'stats_overlay.dart';
import 'map_key_overlay.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider);
    final grid = gameState.grid;

    final mediaQuery = MediaQuery.of(context);
    final appBarHeight = AppBar().preferredSize.height;
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height - appBarHeight - mediaQuery.padding.top;

    final double cellSize = min(
      screenWidth / grid.width,
      screenHeight / grid.height,
    );

    // Calculate the actual pixel dimensions of the grid
    final double gridWidthPx = cellSize * grid.width;
    final double gridHeightPx = cellSize * grid.height;

    // Calculate the offset needed to center the grid within the available space
    final double gridOffsetX = (screenWidth - gridWidthPx) / 2;
    final double gridOffsetY = (screenHeight - gridHeightPx) / 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Simulator'),
      ),
      body: Stack(
        children: [
          Center(
            child: SizedBox(
              width: gridWidthPx,
              height: gridHeightPx,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: grid.width * grid.height,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: grid.width,
                  mainAxisExtent: cellSize,
                ),
                itemBuilder: (context, index) {
                  final x = index % grid.width;
                  final y = index ~/ grid.width;
                  final cell = grid.getCell(Point(x, y));

                  Color cellColor;
                  switch (cell.terrain) {
                    case TerrainType.water:
                      cellColor = Colors.blue[200]!;
                      break;
                    case TerrainType.grassland:
                      cellColor = Colors.lightGreen[100 + cell.elevation * 100]!;
                      break;
                    case TerrainType.forest:
                      cellColor = Colors.green[100 + cell.elevation * 100]!;
                      break;
                    case TerrainType.hill:
                      cellColor = Colors.brown[300 + cell.elevation * 100]!; // New color for hills
                      break;
                  }

                  final plantAtPosition = gameState.plants.firstWhereOrNull(
                    (plant) => plant.position == Point(x, y),
                  );

                  Widget? childWidget;
                  String tooltipMessage = 'Position: ($x, $y)\nTerrain: ${cell.terrain.name}\nElevation: ${cell.elevation}';

                  if (plantAtPosition != null) {
                    Color plantColor;
                    double plantSizeFactor = 0.6;

                    switch (plantAtPosition.type) {
                      case PlantType.grass:
                        plantColor = Colors.yellow;
                        plantSizeFactor = min(1.0, plantAtPosition.size / 10.0);
                        plantSizeFactor = max(0.8, plantSizeFactor);
                        break;
                      case PlantType.berryBush:
                        plantColor = Colors.green[800]!;
                        break;
                      case PlantType.tree:
                        plantColor = Colors.brown; // Color for trees
                        plantSizeFactor = min(1.0, plantAtPosition.size / 20.0);
                        plantSizeFactor = max(0.8, plantSizeFactor);
                        break;
                    }
                    childWidget = Container(
                      width: cellSize * plantSizeFactor,
                      height: cellSize * plantSizeFactor,
                      decoration: BoxDecoration(
                        color: plantColor,
                        shape: plantAtPosition.type == PlantType.tree ? BoxShape.rectangle : BoxShape.circle,
                      ),
                      child: plantAtPosition.type == PlantType.berryBush && !plantAtPosition.isEmpty
                          ? Center(
                              child: Container(
                                width: cellSize * 0.2,
                                height: cellSize * 0.2,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    );
                    tooltipMessage += '\nPlant: ${plantAtPosition.type.name}\nSize: ${plantAtPosition.size.toStringAsFixed(1)}\nNutrition: ${plantAtPosition.nutritionalValue.toInt()}';
                    if (plantAtPosition.type == PlantType.berryBush) {
                      tooltipMessage += '\nEmpty: ${plantAtPosition.isEmpty ? 'Yes' : 'No'}';
                      if (plantAtPosition.isEmpty) {
                        tooltipMessage += ' (Regrows in ${plantAtPosition.regrowthTimer} ticks)';
                      }
                    }
                  }

                  return Tooltip(
                    message: tooltipMessage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cellColor,
                        border: Border.all(color: Colors.black12, width: 0.5),
                      ),
                      child: Center(
                        child: childWidget,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Render animals on top of the grid
          ...gameState.animals.map((animal) {
            IconData animalIcon;
            Color iconColor;
            switch (animal.type) {
              case AnimalType.rabbit:
                animalIcon = Icons.pets;
                iconColor = Colors.grey[700]!;
                break;
              case AnimalType.deer:
                animalIcon = Icons.forest;
                iconColor = Colors.brown[700]!;
                break;
              case AnimalType.wolf:
                animalIcon = Icons.coronavirus;
                iconColor = Colors.blueGrey[900]!;
                break;
            }

            // Calculate the animated position
            final startX = animal.previousPosition.x.toDouble();
            final startY = animal.previousPosition.y.toDouble();
            final endX = animal.position.x.toDouble();
            final endY = animal.position.y.toDouble();

            return TweenAnimationBuilder<Point<double>>(
              key: ValueKey(animal.hashCode), // Unique key for each animal to trigger animation
              tween: PointTween(
                begin: Point(startX, startY),
                end: Point(endX, endY),
              ),
              duration: const Duration(milliseconds: 400), // Animation duration
              builder: (context, animatedPosition, child) {
                return Positioned(
                  left: gridOffsetX + animatedPosition.x * cellSize,
                  top: gridOffsetY + animatedPosition.y * cellSize,
                  width: cellSize,
                  height: cellSize,
                  child: Center(
                    child: Tooltip(
                      message: 'Animal: ${animal.type.name}\nHunger: ${animal.hunger.toInt()}\nThirst: ${animal.thirst.toInt()}\nEnergy: ${animal.energy.toInt()}\nLifespan: ${animal.lifespan}\nAge: ${animal.age}',
                      child: Icon(
                        animalIcon,
                        color: iconColor,
                        size: cellSize * 0.8,
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
          // Render villagers on top of the grid
          ...gameState.villagers.map((villager) {
            // Calculate the animated position
            final startX = villager.previousPosition.x.toDouble();
            final startY = villager.previousPosition.y.toDouble();
            final endX = villager.position.x.toDouble();
            final endY = villager.position.y.toDouble();

            return TweenAnimationBuilder<Point<double>>(
              key: ValueKey(villager.hashCode), // Unique key for each villager to trigger animation
              tween: PointTween(
                begin: Point(startX, startY),
                end: Point(endX, endY),
              ),
              duration: const Duration(milliseconds: 400), // Animation duration
              builder: (context, animatedPosition, child) {
                return Positioned(
                  left: gridOffsetX + animatedPosition.x * cellSize,
                  top: gridOffsetY + animatedPosition.y * cellSize,
                  width: cellSize,
                  height: cellSize,
                  child: Center(
                    child: Tooltip(
                      message: 'Villager: ${villager.name ?? 'Unnamed'}\nProfession: ${villager.profession.name}\nHunger: ${villager.hunger.toInt()}\nThirst: ${villager.thirst.toInt()}\nEnergy: ${villager.energy.toInt()}\nLifespan: ${villager.lifespan}\nAge: ${villager.age}',
                      child: Icon(
                        Icons.person, // Generic icon for villagers
                        color: Colors.purple[400]!, // Distinct color for villagers
                        size: cellSize * 0.8,
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
          const StatsOverlay(),
          const MapKeyOverlay(),
        ],
      ),
    );
  }
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}

// Custom Tween for Point<double>
class PointTween extends Tween<Point<double>> {
  PointTween({required Point<double> begin, required Point<double> end}) : super(begin: begin, end: end);

  @override
  Point<double> lerp(double t) {
    return Point(
      begin!.x + (end!.x - begin!.x) * t,
      begin!.y + (end!.y - begin!.y) * t,
    );
  }
}
