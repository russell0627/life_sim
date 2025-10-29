
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/game_controller.dart';

class StatsOverlay extends ConsumerWidget {
  const StatsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider);
    final currentTick = gameState.currentTick;

    return Positioned(
      top: 16.0,
      left: 16.0,
      child: Card(
        elevation: 4.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Ensure the column only takes necessary space
            children: [
              Text(
                'Current Tick: $currentTick',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Season: ${gameState.currentSeason.name.toUpperCase()}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Animals: ${gameState.animals.length}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Plants: ${gameState.plants.length}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
