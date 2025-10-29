
import 'grid.dart';
import 'plant.dart';
import 'animal.dart';
import 'terrain.dart';

class GameState {
  GameState({
    required this.grid,
    this.plants = const [],
    this.animals = const [],
    this.currentTick = 0,
    this.currentSeason = Season.spring,
    this.seasonTickCounter = 0,
  });

  final Grid grid;
  final List<Plant> plants;
  final List<Animal> animals;
  final int currentTick;
  final Season currentSeason;
  final int seasonTickCounter;

  GameState copyWith({
    Grid? grid,
    List<Plant>? plants,
    List<Animal>? animals,
    int? currentTick,
    Season? currentSeason,
    int? seasonTickCounter,
  }) {
    return GameState(
      grid: grid ?? this.grid,
      plants: plants ?? this.plants,
      animals: animals ?? this.animals,
      currentTick: currentTick ?? this.currentTick,
      currentSeason: currentSeason ?? this.currentSeason,
      seasonTickCounter: seasonTickCounter ?? this.seasonTickCounter,
    );
  }
}
