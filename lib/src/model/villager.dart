
import 'dart:math';

import 'package:life_sim/src/model/humanoid.dart';

enum VillagerProfession {
  gatherer,
  builder,
  hunter,
  // Add more professions as needed
}

class Villager extends Humanoid {
  Villager({
    required super.position,
    super.name,
    super.hunger,
    super.thirst,
    super.energy,
    super.lifespan,
    super.age,
    this.profession = VillagerProfession.gatherer, // Default profession
    Point<int>? previousPosition, // For animation
    this.isSleeping = false, // New property
    this.sleepDuration = 0,  // New property
  }) : super(previousPosition: previousPosition);

  final VillagerProfession profession;
  bool isSleeping;
  int sleepDuration;
  // Add other villager-specific properties here, e.g., inventory, skills, etc.

  Villager copyWith({
    Point<int>? position,
    String? name,
    double? hunger,
    double? thirst,
    double? energy,
    int? lifespan,
    int? age,
    VillagerProfession? profession,
    Point<int>? previousPosition,
    bool? isSleeping,
    int? sleepDuration,
  }) {
    return Villager(
      position: position ?? this.position,
      name: name ?? this.name,
      hunger: hunger ?? this.hunger,
      thirst: thirst ?? this.thirst,
      energy: energy ?? this.energy,
      lifespan: lifespan ?? this.lifespan,
      age: age ?? this.age,
      profession: profession ?? this.profession,
      previousPosition: previousPosition ?? this.previousPosition,
      isSleeping: isSleeping ?? this.isSleeping,
      sleepDuration: sleepDuration ?? this.sleepDuration,
    );
  }
}
