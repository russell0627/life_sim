
import 'dart:math';

import 'package:life_sim/src/model/entity.dart';

/// An abstract class representing a humanoid entity in the game world.
///
/// Humanoids are complex beings with names, needs, and lifecycles. This class
/// provides the basic attributes that all humanoid types will share.
abstract class Humanoid extends Entity {
  Humanoid({
    required super.position,
    this.name,
    this.hunger = 100.0,
    this.thirst = 100.0,
    this.energy = 100.0,
    this.lifespan = 32000, // Roughly 80 years, with 400 ticks per year
    this.age = 0,
  });

  /// The name of the humanoid. Can be null.
  String? name;

  /// The current hunger level of the humanoid (0-100).
  double hunger;

  /// The current thirst level of the humanoid (0-100).
  double thirst;

  /// The current energy level of the humanoid (0-100).
  double energy;

  /// The total lifespan of the humanoid in game ticks.
  int lifespan;

  /// The current age of the humanoid in game ticks.
  int age;
}
