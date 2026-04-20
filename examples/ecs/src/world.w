module ecs.world

use math.Vec2
use components.Entity
use components.Transform
use components.Velocity
use components.Collider
use components.Sprite
use components.InputState
use components.CollisionEvent
use storage.TransformStorage
use storage.VelocityStorage
use storage.ColliderStorage
use storage.SpriteStorage
use storage.InputStateStorage

// The World holds all game state. Each component type has its own
// storage field. This is critical: because storages are separate
// fields, the borrow checker allows simultaneous access to disjoint
// storages -- enabling parallel system execution.

type World {
    // Entity pool: names indexed by entity id, generation tracking
    entity_names: Vec[str],
    entity_generations: Vec[i32],
    entity_alive: Vec[bool],
    next_id: i32,

    // Component storages -- one field per component type.
    // Disjoint field borrowing means:
    //   &mut world.transforms and &world.velocities
    // can coexist because they are structurally disjoint paths.
    transforms: TransformStorage,
    velocities: VelocityStorage,
    colliders: ColliderStorage,
    sprites: SpriteStorage,
    input_states: InputStateStorage,

    // Events -- produced by systems, consumed by others
    collision_events: Vec[CollisionEvent],
    despawn_queue: Vec[Entity],

    // Per-frame state
    dt: f32,
    time: f32,
    frame: i32,
}

extend World:
    fn new() -> World:
        World {
            entity_names: Vec.new(),
            entity_generations: Vec.new(),
            entity_alive: Vec.new(),
            next_id: 0,
            transforms: TransformStorage.new(),
            velocities: VelocityStorage.new(),
            colliders: ColliderStorage.new(),
            sprites: SpriteStorage.new(),
            input_states: InputStateStorage.new(),
            collision_events: Vec.new(),
            despawn_queue: Vec.new(),
            dt: 0.0,
            time: 0.0,
            frame: 0,
        }

    // --- Entity Lifecycle ---

    fn spawn(self: &mut World, name: str) -> Entity:
        let id = self.next_id
        self.next_id += 1
        self.entity_names.push(name)
        self.entity_generations.push(0)
        self.entity_alive.push(true)
        Entity.new(id)

    fn despawn(self: &mut World, entity: Entity):
        if entity.id >= 0 and entity.id < self.entity_alive.len():
            if self.entity_alive[entity.id]:
                self.entity_alive[entity.id] = false
                self.entity_generations[entity.id] += 1
                // Remove from all component storages
                self.transforms.remove(entity)
                self.velocities.remove(entity)
                self.colliders.remove(entity)
                self.sprites.remove(entity)
                self.input_states.remove(entity)

    fn queue_despawn(self: &mut World, entity: Entity):
        self.despawn_queue.push(entity)

    fn flush_despawns(self: &mut World):
        // Process deferred removals
        var i: i32 = 0
        while i < self.despawn_queue.len():
            let entity = self.despawn_queue[i]
            self.despawn(entity)
            i += 1
        self.despawn_queue.clear()

    fn is_alive(self: &World, entity: Entity) -> bool:
        if entity.id >= 0 and entity.id < self.entity_alive.len():
            self.entity_alive[entity.id] and entity.generation == self.entity_generations[entity.id]
        else:
            false

    fn entity_name(self: &World, entity: Entity) -> Option[str]:
        if self.is_alive(entity):
            Some(self.entity_names[entity.id])
        else:
            None

    fn entity_count(self: &World) -> i32:
        var count: i32 = 0
        for i in 0..self.entity_alive.len():
            if self.entity_alive[i]:
                count += 1
        count

    // --- Component Access ---

    fn add_transform(self: &mut World, entity: Entity, component: Transform):
        self.transforms.insert(entity, component)

    fn add_velocity(self: &mut World, entity: Entity, component: Velocity):
        self.velocities.insert(entity, component)

    fn add_collider(self: &mut World, entity: Entity, component: Collider):
        self.colliders.insert(entity, component)

    fn add_sprite(self: &mut World, entity: Entity, component: Sprite):
        self.sprites.insert(entity, component)

    fn add_input_state(self: &mut World, entity: Entity, component: InputState):
        self.input_states.insert(entity, component)

    // --- Debug ---

    fn print_stats(self: &World):
        print("=== World Stats ===")
        print(f"  Entities:       {self.entity_count()}")
        print(f"  Transforms:     {self.transforms.len()}")
        print(f"  Velocities:     {self.velocities.len()}")
        print(f"  Colliders:      {self.colliders.len()}")
        print(f"  Sprites:        {self.sprites.len()}")
        print(f"  Input states:   {self.input_states.len()}")
        print(f"  Frame:          {self.frame}")
        print(f"  Time:           {self.time}s")
