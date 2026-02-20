module ecs.world

use ecs.math.Vec2
use ecs.storage.DenseStorage
use ecs.components.*

// Entity is a generational handle into the world's entity pool.
// Handles are the core abstraction: typed, Copy, safe against
// use-after-remove (generation mismatch returns None).
type Entity = Handle[EntityRow]

type EntityRow = {
    name: str,
}

// The World holds all game state. Each component type has its own
// DenseStorage field. This is critical: because storages are separate
// fields, the borrow checker allows simultaneous access to disjoint
// storages — enabling parallel system execution.

type World = {
    entities: SlotMap[EntityRow],

    // Component storages — one field per component type.
    // Disjoint field borrowing (spec §3.6) means:
    //   &mut world.transforms and &world.velocities
    // can coexist because they are structurally disjoint paths.
    transforms: DenseStorage[Transform],
    velocities: DenseStorage[Velocity],
    colliders: DenseStorage[Collider],
    sprites: DenseStorage[Sprite],
    input_states: DenseStorage[InputState],

    // Events — produced by systems, consumed by others
    collision_events: Vec[CollisionEvent],
    despawn_queue: Vec[Entity],

    // Per-frame state
    dt: f32,
    time: f32,
    frame: u64,
    frame_arena: FrameArena,
}

extend World
    fn new() -> World =
        World {
            entities: SlotMap.new(),
            transforms: DenseStorage.new(),
            velocities: DenseStorage.new(),
            colliders: DenseStorage.new(),
            sprites: DenseStorage.new(),
            input_states: DenseStorage.new(),
            collision_events: Vec.new(),
            despawn_queue: Vec.new(),
            dt: 0.0,
            time: 0.0,
            frame: 0,
            frame_arena: FrameArena.new(64 * 1024),  // 64 KB per frame
        }

    // --- Entity Lifecycle ---

    fn spawn(self: &mut World, name: str) -> Entity =
        self.entities.insert(EntityRow { name })

    fn despawn(self: &mut World, entity: Entity) =
        // Remove from all component storages
        comptime for field in TypeInfo.fields[World]():
            comptime if field.type_name.starts_with("DenseStorage["):
                let _ = self.{field.name}.remove(entity)
        // Remove the entity itself
        let _ = self.entities.remove(entity)

    fn queue_despawn(self: &mut World, entity: Entity) =
        self.despawn_queue.push(entity)

    fn flush_despawns(self: &mut World) =
        // Drain the queue — process deferred removals
        let queue = with Vec.new() as mut swap:
            std.mem.swap(&mut self.despawn_queue, &mut swap)
        for entity in queue:
            self.despawn(*entity)

    fn is_alive(self: &World, entity: Entity) -> bool =
        self.entities.contains(entity)

    fn entity_name(self: &World, entity: Entity) -> Option[&str] =
        self.entities.get(entity).map(|row| row.name.as_view())

    fn entity_count(self: &World) -> usize = self.entities.len()

    // --- Component Access ---
    //
    // A single generic method dispatches to the correct storage
    // at compile time using TypeInfo field reflection (§17.2).
    // Dead branches are eliminated — zero runtime overhead.

    fn add[T](self: &mut World, entity: Entity, component: T) =
        comptime for field in TypeInfo.fields[World]():
            comptime if field.type_name == "DenseStorage[{TypeInfo.name[T]()}]":
                self.{field.name}.insert(entity, component)
                return
        comptime_error("Component storage not registered for {TypeInfo.name[T]()}")

    // --- Debug ---

    fn print_stats(self: &World) =
        println("=== World Stats ===")
        println("  Entities:     {self.entities.len()}")
        comptime for field in TypeInfo.fields[World]():
            comptime if field.type_name.starts_with("DenseStorage["):
                println("  {field.name}:  {self.{field.name}.len()}")
        println("  Frame:        {self.frame}")
        println("  Time:         {self.time:.2}s")
