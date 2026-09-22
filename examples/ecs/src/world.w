module ecs.world

use math.Vec2
use components.Entity
use components.Transform
use components.Velocity
use components.Collider
use components.Sprite
use components.InputState
use components.CollisionEvent
use storage.DenseStorage

// The World holds all game state. Each component type has its own
// storage field. This is critical: because storages are separate
// fields, systems can read one storage while writing another.

pub type World {
    // Entity pool: names indexed by entity id, generation tracking
    entity_names: Vec[str],
    entity_generations: Vec[i32],
    entity_alive: Vec[bool],
    next_id: i32,

    // Component storages -- one field per component type.
    transforms: DenseStorage[Transform],
    velocities: DenseStorage[Velocity],
    colliders: DenseStorage[Collider],
    sprites: DenseStorage[Sprite],
    input_states: DenseStorage[InputState],

    // Events -- produced by systems, consumed by others
    collision_events: Vec[CollisionEvent],
    despawn_queue: Vec[Entity],

    // Per-frame state
    dt: f32,
    time: f32,
    frame: i32,
}

pub fn World.new() -> World:
    World {
        entity_names: Vec.new(),
        entity_generations: Vec.new(),
        entity_alive: Vec.new(),
        next_id: 0,
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
    }

extend World:
    // --- Entity Lifecycle ---

    pub mut fn spawn_entity(name: str) -> Entity:
        let id = self.next_id
        self.next_id += 1
        self.entity_names.push(name)
        self.entity_generations.push(0)
        self.entity_alive.push(true)
        Entity.new(id)

    pub mut fn despawn(entity: Entity):
        if entity.id >= 0 and entity.id < self.entity_alive.len():
            let alive: bool = self.entity_alive[entity.id]
            if alive:
                self.entity_alive[entity.id] = false
                self.entity_generations[entity.id] += 1
                // Remove from all component storages
                self.transforms.remove(entity)
                self.velocities.remove(entity)
                self.colliders.remove(entity)
                self.sprites.remove(entity)
                self.input_states.remove(entity)

    pub mut fn queue_despawn(entity: Entity):
        self.despawn_queue.push(entity)

    pub mut fn flush_despawns():
        // Process deferred removals
        var i: i32 = 0
        while i < self.despawn_queue.len():
            let entity: Entity = self.despawn_queue[i]
            self.despawn(entity)
            i += 1
        self.despawn_queue.clear()

    pub fn is_alive(entity: Entity) -> bool:
        if entity.id >= 0 and entity.id < self.entity_alive.len():
            let alive: bool = self.entity_alive[entity.id]
            let generation: i32 = self.entity_generations[entity.id]
            alive and entity.generation == generation
        else:
            false

    // A view of the stored name (§3.8): the caller reads it, the world
    // keeps it.
    pub fn entity_name(entity: Entity) -> Option[&str]:
        if self.is_alive(entity):
            Some(self.entity_names.get(entity.id))
        else:
            None

    pub fn entity_count() -> i32:
        var count: i32 = 0
        for i in 0..self.entity_alive.len():
            let alive: bool = self.entity_alive[i]
            if alive:
                count += 1
        count

    // --- Component Access ---

    pub mut fn add_transform(entity: Entity, component: Transform):
        self.transforms.insert(entity, component)

    pub mut fn add_velocity(entity: Entity, component: Velocity):
        self.velocities.insert(entity, component)

    pub mut fn add_collider(entity: Entity, component: Collider):
        self.colliders.insert(entity, component)

    pub mut fn add_sprite(entity: Entity, component: Sprite):
        self.sprites.insert(entity, component)

    pub mut fn add_input_state(entity: Entity, component: InputState):
        self.input_states.insert(entity, component)

    // --- Debug ---

    pub fn print_stats():
        print("=== World Stats ===")
        print(f"  Entities:       {self.entity_count()}")
        print(f"  Transforms:     {self.transforms.len()}")
        print(f"  Velocities:     {self.velocities.len()}")
        print(f"  Colliders:      {self.colliders.len()}")
        print(f"  Sprites:        {self.sprites.len()}")
        print(f"  Input states:   {self.input_states.len()}")
        print(f"  Frame:          {self.frame}")
        print(f"  Time:           {self.time}s")
