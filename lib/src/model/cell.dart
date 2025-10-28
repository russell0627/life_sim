
import 'entity.dart';

enum Terrain { ground, water }

class Cell {
  Cell({required this.terrain, this.entities = const []});

  final Terrain terrain;
  final List<Entity> entities;

  Cell copyWith({
    Terrain? terrain,
    List<Entity>? entities,
  }) {
    return Cell(
      terrain: terrain ?? this.terrain,
      entities: entities ?? this.entities,
    );
  }
}
