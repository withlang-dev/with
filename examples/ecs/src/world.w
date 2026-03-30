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
    // Disjoint field borrowing (spec S3.6) means:
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

extend World:
    fn new:
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

    fn spawn(self: &mut World, name: str) -> Entity:
        self.entities.insert(EntityRow { name })

    fn despawn(self: &mut World, entity: Entity):
        // Remove from all component storages
        let _ = self.transforms.remove(entity)
        let _ = self.velocities.remove(entity)
        let _ = self.colliders.remove(entity)
        let _ = self.sprites.remove(entity)
        let _ = self.input_states.remove(entity)
        // Remove the entity itself
        let _ = self.entities.remove(entity)

    fn queue_despawn(self: &mut World, entity: Entity):
        self.despawn_queue.push(entity)

    fn flush_despawns(self: &mut World):
        // Drain the queue — process deferred removals
        let queue = with Vec.new() as mut swap:
            std.mem.swap(&mut self.despawn_queue, &mut swap)
        for entity in queue:
            self.despawn(*entity)

    fn is_alive(self: &World, entity: Entity) -> bool:
        self.entities.contains(entity)

    fn entity_name(self: &World, entity: Entity) -> Option[&str]:
        self.entities.get(entity).map(row => row.name.as_view())

    fn entity_count(self: &World) -> usize: self.entities.len()

    // --- Component Access ---

    fn add[T](self: &mut World, entity: Entity, component: T):
        comptime for field in World.fields():
            comptime if field.type_name == "DenseStorage[{T.name()}]":
                self.{field.name}.insert(entity, component)
                return
        comptime_error("Component storage not registered for {T.name()}")

    // --- Debug ---

    fn print_stats(self: &World):
        print("=== World Stats ===")
        print("  Entities:       {self.entities.len()}")
        print("  Transforms:     {self.transforms.len()}")
        print("  Velocities:     {self.velocities.len()}")
        print("  Colliders:      {self.colliders.len()}")
        print("  Sprites:        {self.sprites.len()}")
        print("  Input states:   {self.input_states.len()}")
        print("  Frame:          {self.frame}")
        print("  Time:           {self.time:.2}s")
