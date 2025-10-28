
# Development Plan: Grid-Based Life Simulator (Code-Focused)

This plan outlines the development steps with a focus on the code structure, incorporating Riverpod for state management.

## Phase 1: Core Engine & State Management

- [x] **Project Setup:**
    - [x] Add `flutter_riverpod` and `riverpod_annotation` to `pubspec.yaml`.
    - [x] Set up the basic folder structure: `lib/src`, `lib/src/model`, `lib/src/view`, `lib/src/controller`.

- [x] **State Management (Riverpod):**
    - [x] **`GameState`:** Create a plain `GameState` class in `lib/src/model/game_state.dart`. This class will be immutable and hold the simulation's state (e.g., the grid, list of animals, list of plants).
    - [x] **`GameController`:** Create the `GameController` in `lib/src/controller/game_controller.dart`. 
        - [x] It will be a Riverpod `Notifier` or `AsyncNotifier` annotated with `@riverpod`.
        - [x] It will manage the `GameState`.
        - [x] The generated file `game_controller.g.dart` will be created and used by the controller.

- [x] **Core Models:**
    - [x] **`Grid`:** Implement a `Grid` class in `lib/src/model/grid.dart`. This will likely be a 2D list or a map to hold `Cell` objects.
    - [x] **`Cell`:** Define a `Cell` class in `lib/src/model/cell.dart` to represent a single point on the grid, containing terrain type (e.g., `enum Terrain { ground, water }`) and a list of entities present.
    - [x] **`Entity`:** Create an abstract `Entity` base class in `lib/src/model/entity.dart` with properties like position (`Point` or `Vector2`).

- [x] **Simulation Loop:**
    - [x] Implement a `tick()` method inside the `GameController`.
    - [x] Use a `Timer.periodic` in the `GameController`'s `build` method to call `tick()` at a regular interval (e.g., every 500ms).

## Phase 2: Entity Implementation

- [x] **`Plant` Model:**
    - [x] Create a `Plant` class in `lib/src/model/plant.dart` that extends `Entity`.
    - [x] Add properties for `size` or `growthStage` and `nutritionalValue`.
    - [x] Implement support for multiple plant types (`PlantType` enum).
    - [x] In the `GameController`'s `tick()` method, add logic for plant growth and spreading to adjacent empty `Cell`s.

- [x] **`Animal` Model:**
    - [x] Create an `Animal` class in `lib/src/model/animal.dart` that extends `Entity`.
    - [x] Add properties for needs: `hunger`, `thirst`, `energy` (all doubles from 0.0 to 100.0).
    - [x] Add a `lifespan` property.
    - [x] Implement support for multiple animal types (`AnimalType` enum and `diet` property, including `wolf` carnivore).
    - [x] Add `speed` attribute to animals.
    - [x] In the `GameController`'s `tick()` method, add logic to deplete these needs over time.

## Phase 3: AI and Behavior in `GameController`

- [x] **Pathfinding:**
    - [x] Implement a pathfinding algorithm (e.g., A* or simple breadth-first search) as a utility function that animals can use to navigate the grid.

- [x] **Behavior Tree/State Machine:**
    - [x] In the `GameController`'s `tick()` method, iterate through each animal and decide its next action based on its needs:
        - [x] If `thirst` is critical, find the nearest `water` cell and move towards it.
        - [x] If `hunger` is critical, find the nearest `Plant` (for herbivores) or `Animal` (for carnivores) and move towards it.
        - [x] If `energy` is critical, enter a `sleeping` state.
        - [x] Otherwise, wander randomly.

- [x] **Actions:**
    - [x] Implement "drink", "eat" (plants for herbivores, animals for carnivores), and "sleep" logic. When an animal reaches its target, perform the action and replenish the corresponding need.
    - [x] Eating a plant or animal should remove it from the grid.

- [x] **Life and Death:**
    - [x] In the `tick()` method, check for animals whose `hunger` or `thirst` has reached 0, or who have exceeded their `lifespan`. 
    - [x] Remove dead animals from the `GameState`.

## Phase 4: World Generation & UI

- [x] **`WorldGenerator`:**
    - [x] Create a `WorldGenerator` service in `lib/src/controller/world_generator.dart`.
    - [x] This service will have a method that creates and returns an initial `GameState` with procedurally placed terrain, plants, and animals (including different types).
    - [x] The `GameController` will call this service to get its initial state.

- [x] **UI (View):**
    - [x] Create a `GameScreen` widget in `lib/src/view/game_screen.dart`.
    - [x] Make it a `ConsumerWidget` to watch the `gameControllerProvider`.
    - [x] Use a `GridView.builder` or a `CustomPainter` to render the grid and entities from the `GameState` (including different animal types with distinct colors).
    - [x] Create a `StatsOverlay` widget that also consumes the `gameControllerProvider` to display population counts, the current tick, etc.

## Phase 5: Finalization

- [x] **Testing:** Write unit and widget tests for the core logic and UI components.
- [ ] **Balancing:** Adjust simulation parameters (need depletion, growth rates, etc.) for an interesting and sustainable ecosystem.
- [ ] **Refinement:** Add simple animations or visual effects for entity actions (e.g., movement, eating). Code cleanup and documentation.
