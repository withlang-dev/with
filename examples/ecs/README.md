# Example: Entity Component System

A data-oriented game engine core. Demonstrates generational handles,
dense component storage, type-safe queries, parallel system execution
via disjoint field borrowing, and comptime component registration.

## Files

```
src/
├── main.with          Demo: spawn entities, simulate 5 frames
├── math.with          Vec2 and AABB types with operator overloading
├── components.with    Game components: Transform, Velocity, Collider, Sprite, InputState
├── storage.with       DenseStorage[T] — sparse-dense array with generational handles
├── query.with         Query generators: query1, query2, query3, query_without
├── world.with         World struct: entity pool + component storages + spawn/despawn
└── systems.with       Game systems: input, movement, collision, rendering, frame orchestration
```

## What It Demonstrates

**Generational handles** — `Entity = Handle[EntityRow]` combines an index and a
generation counter. After despawn, the handle is invalidated — stale references
return `None` instead of accessing a recycled slot.

**Dense component storage** — `DenseStorage[T]` uses a sparse array for O(1) lookup
and a dense array for cache-friendly iteration. Components are stored contiguously
in memory regardless of entity creation order.

**Parallel systems via disjoint borrowing** — `run_frame()` uses `scope` to run
`run_collision` (reads `transforms`, `colliders`, writes `collision_events`) in
parallel with `run_render` (reads `transforms`, `sprites`). The borrow checker
guarantees no data races at compile time because mutable/shared accesses are
disjoint or shared-compatible.

**Comptime component registration** — `@[component]` annotations and `comptime`
blocks generate component IDs at compile time, avoiding runtime reflection or
registration boilerplate.

**Query generators** — `query2(&world.transforms, &world.sprites)` yields
`(Entity, &Transform, &Sprite)` tuples by intersecting two storages. Queries
compose with pipeline operators for filtering and transformation.

## Language Features

| Feature | Location |
|---------|----------|
| Generational handles (`Handle[T]`) | world.with — entity identity |
| `SlotMap` | world.with — entity pool |
| Generics | storage.with — `DenseStorage[T]` |
| Generators (`gen fn`) | storage.with — `iter()`; query.with — `query1`, `query2`, `query3` |
| `@[component]` comptime annotation | components.with — component registration |
| `comptime` blocks | components.with — ID generation |
| Disjoint field borrowing | systems.with — parallel system execution |
| `scope` (OS threads) | systems.with — `run_frame()` |
| Record update `{ x with field: val }` | main.with — wall spawning from base template |
| `with` blocks (mutation) | main.with — `spawn_enemies`, `spawn_walls` |
| `with` blocks (binding) | main.with — `entity_name` |
| Operator overloading (`Add`, `Sub`, `Neg`) | math.with — `Vec2` arithmetic |
| Copy types | math.with, components.with — all components are `Copy` |
| Default field values | components.with — `InputState` fields default to `false` |
| `.Variant` shorthand | main.with — `.KeyDown(.Right)`, `.KeyUp(.Up)` |
| Pipeline operators `\|>` | main.with — query + `for_each` |
| Implicit `for` iteration | systems.with, world.with — iterating component storages, queues |
