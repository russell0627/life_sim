
import 'dart:math';

import 'package:life_sim/src/model/entity.dart';

enum AnimalType {
  rabbit,
  deer,
  wolf,
  // Add more animal types here
}

enum Diet {
  herbivore,
  carnivore,
  omnivore,
}

class Animal extends Entity {
  Animal({
    required super.position,
    required this.type,
    this.hunger = 100.0,
    this.thirst = 100.0,
    this.energy = 100.0,
    this.lifespan = 1000,
    this.isSleeping = false,
    this.sleepDuration = 0,
    this.diet = Diet.herbivore, // Default to herbivore for now
    this.speed = 1, // Default speed
  }) {
    // Set initial stats based on animal type
    switch (type) {
      case AnimalType.rabbit:
        lifespan = 500; // Shorter lifespan
        hunger = 80.0; // Starts a bit hungrier
        thirst = 90.0;
        energy = 70.0;
        speed = 2; // Rabbits are faster
        diet = Diet.herbivore;
        break;
      case AnimalType.deer:
        lifespan = 1500; // Longer lifespan
        hunger = 100.0;
        thirst = 100.0;
        energy = 100.0;
        speed = 1; // Deer are slower
        diet = Diet.herbivore;
        break;
      case AnimalType.wolf:
        lifespan = 1200; // Medium lifespan
        hunger = 100.0;
        thirst = 100.0;
        energy = 100.0;
        speed = 2; // Wolves are fast
        diet = Diet.carnivore;
        break;
    }
  }

  final AnimalType type;
  double hunger;
  double thirst;
  double energy;
  int lifespan;
  bool isSleeping;
  int sleepDuration;
  Diet diet;
  int speed;

  Animal copyWith({
    Point<int>? position,
    double? hunger,
    double? thirst,
    double? energy,
    int? lifespan,
    bool? isSleeping,
    int? sleepDuration,
    Diet? diet,
    int? speed,
  }) {
    return Animal(
      position: position ?? this.position,
      type: type, // Type is final, so it's always this.type
      hunger: hunger ?? this.hunger,
      thirst: thirst ?? this.thirst,
      energy: energy ?? this.energy,
      lifespan: lifespan ?? this.lifespan,
      isSleeping: isSleeping ?? this.isSleeping,
      sleepDuration: sleepDuration ?? this.sleepDuration,
      diet: diet ?? this.diet,
      speed: speed ?? this.speed,
    );
  }
}
