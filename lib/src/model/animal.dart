
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
    this.speed = 1,
    this.age = 0,
    this.maturityAge = 100, // Default maturity age
    this.reproductionCooldown = 0,
    this.reproductionChance = 0.01, // Default reproduction chance
    Point<int>? previousPosition, // New parameter
  }) : this.previousPosition = previousPosition ?? position; // Initialize previousPosition

  final AnimalType type;
  double hunger;
  double thirst;
  double energy;
  int lifespan;
  bool isSleeping;
  int sleepDuration;
  Diet diet;
  int speed;
  int age;
  int maturityAge;
  int reproductionCooldown;
  double reproductionChance;
  Point<int> previousPosition; // New field

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
    int? age,
    int? maturityAge,
    int? reproductionCooldown,
    double? reproductionChance,
    Point<int>? previousPosition, // New parameter
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
      age: age ?? this.age,
      maturityAge: maturityAge ?? this.maturityAge,
      reproductionCooldown: reproductionCooldown ?? this.reproductionCooldown,
      reproductionChance: reproductionChance ?? this.reproductionChance,
      previousPosition: previousPosition ?? this.previousPosition, // Update previousPosition
    );
  }
}
