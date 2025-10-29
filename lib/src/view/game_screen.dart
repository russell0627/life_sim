
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/game_controller.dart';
import '../model/cell.dart';
import '../model/plant.dart';
import '../model/animal.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Simulator'),
      ),
      body: Stack(
        children: [
          Center(
            child: SizedBox(
              width: cellSize * grid.width,
              height: cellSize * grid.height,
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

                  final animalAtPosition = gameState.animals.firstWhereOrNull(
                    (animal) => animal.position == Point(x, y),
                  );

                  final plantAtPosition = gameState.plants.firstWhereOrNull(
                    (plant) => plant.position == Point(x, y),
                  );

                  Widget? childWidget;
                  String tooltipMessage = 'Position: ($x, $y)\nTerrain: ${cell.terrain.name}\nElevation: ${cell.elevation}';

                  if (animalAtPosition != null) {
                    IconData animalIcon;
                    Color iconColor;
                    switch (animalAtPosition.type) {
                      case AnimalType.rabbit:
                        animalIcon = Icons.pets; // Example icon for rabbit
                        iconColor = Colors.grey[700]!;
                        break;
                      case AnimalType.deer:
                        animalIcon = Icons.forest; // Example icon for deer
                        iconColor = Colors.brown[700]!;
                        break;
                      case AnimalType.wolf:
                        animalIcon = Icons.coronavirus; // Example icon for wolf (can be changed)
                        iconColor = Colors.blueGrey[900]!;
                        break;
                    }
                    childWidget = Icon(
                      animalIcon,
                      color: iconColor,
                      size: cellSize * 0.8,
                    );
                    tooltipMessage += '\nAnimal: ${animalAtPosition.type.name}\nHunger: ${animalAtPosition.hunger.toInt()}\nThirst: ${animalAtPosition.thirst.toInt()}\nEnergy: ${animalAtPosition.energy.toInt()}\nLifespan: ${animalAtPosition.lifespan}\nAge: ${animalAtPosition.age}';
                  } else if (plantAtPosition != null) {
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
