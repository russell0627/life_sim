
import 'dart:math';

import 'package:life_sim/src/model/entity.dart';

enum PlantType {
  grass,
  berryBush,
  // Add more plant types here
}

class Plant extends Entity {
  Plant({
    required super.position,
    required this.type,
    this.size = 1.0,
    this.nutritionalValue = 10.0,
  }) {
    // Set initial stats based on plant type
    switch (type) {
      case PlantType.grass:
        size = 1.0;
        nutritionalValue = 10.0;
        break;
      case PlantType.berryBush:
        size = 2.0; // Berry bushes start larger
        nutritionalValue = 25.0; // More nutritious
        break;
    }
  }

  final PlantType type;
  double size;
  double nutritionalValue;

  Plant copyWith({
    Point<int>? position,
    double? size,
    double? nutritionalValue,
    PlantType? type,
  }) {
    return Plant(
      position: position ?? this.position,
      type: type ?? this.type,
      size: size ?? this.size,
      nutritionalValue: nutritionalValue ?? this.nutritionalValue,
    );
  }
}
