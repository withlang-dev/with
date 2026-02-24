# Example: Entity Component System

A data-oriented game engine core. Demonstrates generational handles,
dense component storage, type-safe queries, parallel system execution
via disjoint field borrowing, and comptime component registration.

## Files

```
src/
├── main.w          Demo: spawn entities, simulate 5 frames
├── math.w          Vec2 and AABB types with operator overloading
├── components.w    Game components: Transform, Velocity, Collider, Sprite, InputState
├── storage.w       DenseStorage[T] — sparse-dense array with generational handles
├── query.w         Query generators: query1, query2, query3, query_without
├── world.w         World struct: entity pool + component storages + spawn/despawn
└── systems.w       Game systems: input, movement, collision, rendering, frame orchestration
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
| Generational handles (`Handle[T]`) | world.w — entity identity |
| `SlotMap` | world.w — entity pool |
| Generics | storage.w — `DenseStorage[T]` |
| Generators (`gen fn`) | storage.w — `iter()`; query.w — `query1`, `query2`, `query3` |
| `@[component]` comptime annotation | components.w — component registration |
| `comptime` blocks | components.w — ID generation |
| Disjoint field borrowing | systems.w — parallel system execution |
| `scope` (OS threads) | systems.w — `run_frame()` |
| Record update `{ x with field: val }` | main.w — wall spawning from base template |
| `with` blocks (mutation) | main.w — `spawn_enemies`, `spawn_walls` |
| `with` blocks (binding) | main.w — `entity_name` |
| Operator overloading (`Add`, `Sub`, `Neg`) | math.w — `Vec2` arithmetic |
| Copy types | math.w, components.w — all components are `Copy` |
| Default field values | components.w — `InputState` fields default to `false` |
| `.Variant` shorthand | main.w — `.KeyDown(.Right)`, `.KeyUp(.Up)` |
| Pipeline operators `\|>` | main.w — query + `for_each` |
| Implicit `for` iteration | systems.w, world.w — iterating component storages, queues |
