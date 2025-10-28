
import 'grid.dart';
import 'plant.dart';
import 'animal.dart';

class GameState {
  GameState({
    required this.grid,
    this.plants = const [],
    this.animals = const [],
    this.currentTick = 0,
  });

  final Grid grid;
  final List<Plant> plants;
  final List<Animal> animals;
  final int currentTick;

  GameState copyWith({
    Grid? grid,
    List<Plant>? plants,
    List<Animal>? animals,
    int? currentTick,
  }) {
    return GameState(
      grid: grid ?? this.grid,
      plants: plants ?? this.plants,
      animals: animals ?? this.animals,
      currentTick: currentTick ?? this.currentTick,
    );
  }
}
