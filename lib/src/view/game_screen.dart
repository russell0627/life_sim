
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/game_controller.dart';
import '../model/plant.dart';
import '../model/animal.dart';
import '../model/terrain.dart';
import 'stats_overlay.dart';
import 'map_key_overlay.dart'; // Import the new map key overlay

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider);
    final grid = gameState.grid;

    // Calculate available screen size
    final mediaQuery = MediaQuery.of(context);
    final appBarHeight = AppBar().preferredSize.height;
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height - appBarHeight - mediaQuery.padding.top; // Account for app bar and status bar

    // Calculate the size for each grid cell to fit the entire grid
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
                physics: const NeverScrollableScrollPhysics(), // Prevent scrolling
                itemCount: grid.width * grid.height,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: grid.width,
                  mainAxisExtent: cellSize, // Ensure square cells that fit
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
                      // Vary shade based on elevation
                      cellColor = Colors.lightGreen[100 + cell.elevation * 100]!;
                      break;
                    case TerrainType.forest:
                      cellColor = Colors.green[100 + cell.elevation * 100]!;
                      break;
                    case TerrainType.mountain:
                      cellColor = Colors.grey[400 + cell.elevation * 100]!;
                      break;
                  }

                  // Check if there's an animal at this position
                  final animalAtPosition = gameState.animals.firstWhereOrNull(
                    (animal) => animal.position == Point(x, y),
                  );

                  // Check if there's a plant at this position
                  final plantAtPosition = gameState.plants.firstWhereOrNull(
                    (plant) => plant.position == Point(x, y),
                  );

                  Widget? childWidget;
                  if (animalAtPosition != null) {
                    Color animalColor;
                    switch (animalAtPosition.type) {
                      case AnimalType.rabbit:
                        animalColor = Colors.orange[700]!;
                        break;
                      case AnimalType.deer:
                        animalColor = Colors.red[900]!;
                        break;
                      case AnimalType.wolf:
                        animalColor = Colors.grey[800]!;
                        break;
                    }
                    childWidget = Container(
                      width: cellSize * 0.6, // Scale animal size with cell size
                      height: cellSize * 0.6, // Scale animal size with cell size
                      decoration: BoxDecoration(
                        color: animalColor,
                        shape: BoxShape.rectangle,
                      ),
                    );
                  } else if (plantAtPosition != null) {
                    Color plantColor;
                    double plantSizeFactor = 0.6; // Default size factor

                    switch (plantAtPosition.type) {
                      case PlantType.grass:
                        plantColor = Colors.lightGreen;
                        // Scale grass size based on its 'size' attribute (e.g., max size 10.0)
                        plantSizeFactor = min(1.0, plantAtPosition.size / 10.0); 
                        break;
                      case PlantType.berryBush:
                        plantColor = Colors.green[800]!;
                        break;
                    }
                    childWidget = Container(
                      width: cellSize * plantSizeFactor, // Use scaled plant size
                      height: cellSize * plantSizeFactor, // Use scaled plant size
                      decoration: BoxDecoration(
                        color: plantColor,
                        shape: BoxShape.circle,
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
                          : null, // Don't show berries if empty
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: cellColor,
                      border: Border.all(color: Colors.black12, width: 0.5),
                    ),
                    child: Center(
                      child: childWidget,
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
