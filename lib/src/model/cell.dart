
import 'entity.dart';
import 'terrain.dart'; // Import from new terrain.dart

class Cell {
  Cell({required this.terrain, this.entities = const [], this.elevation = 0});

  final TerrainType terrain;
  final List<Entity> entities;
  final int elevation;

  Cell copyWith({
    TerrainType? terrain,
    List<Entity>? entities,
    int? elevation,
  }) {
    return Cell(
      terrain: terrain ?? this.terrain,
      entities: entities ?? this.entities,
      elevation: elevation ?? this.elevation,
    );
  }
}
