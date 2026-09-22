module ecs.systems

use math.Vec2
use math.AABB
use components.Entity
use components.Transform
use components.Velocity
use components.Collider
use components.Sprite
use components.InputState
use components.InputEvent
use components.Key
use components.CollisionEvent
use components.TextureId
use components.texture_name
use storage.DenseStorage
use world.World

// ===================================================================
// Systems state what they touch in their signatures (§3.8): a system
// that writes a storage is a `mut fn` on the World that owns it; a
// system that only reads takes its storages as `&T` and returns what
// it produces.
// ===================================================================

extend World:
    // --- Input System ---
    //
    // Reads input events, updates InputState components.
    // Writes: input_states

    mut fn run_input_events(events: &Vec[InputEvent]):
        for si in 0..self.input_states.len():
            for event in events:
                match event:
                    .KeyDown(.Up)    => self.input_states.dense_data[si].up = true
                    .KeyUp(.Up)      => self.input_states.dense_data[si].up = false
                    .KeyDown(.Down)  => self.input_states.dense_data[si].down = true
                    .KeyUp(.Down)    => self.input_states.dense_data[si].down = false
                    .KeyDown(.Left)  => self.input_states.dense_data[si].left = true
                    .KeyUp(.Left)    => self.input_states.dense_data[si].left = false
                    .KeyDown(.Right) => self.input_states.dense_data[si].right = true
                    .KeyUp(.Right)   => self.input_states.dense_data[si].right = false
                    .KeyDown(.Space) => self.input_states.dense_data[si].fire = true
                    .KeyUp(.Space)   => self.input_states.dense_data[si].fire = false
                    _ => ()

    // --- Player Controller ---
    //
    // Converts InputState into Velocity for player-controlled entities.
    // Reads: input_states   Writes: velocities

    mut fn run_player_controller(speed: f32):
        for i in 0..self.input_states.len():
            let entity = Entity.new(self.input_states.dense_entities[i])
            // An independent copy: velocities is mutated below (§3.4).
            let input: InputState = self.input_states.dense_data[i]

            if self.velocities.contains(entity):
                var dx: f32 = 0.0
                var dy: f32 = 0.0
                if input.up: dy -= speed
                if input.down: dy += speed
                if input.left: dx -= speed
                if input.right: dx += speed
                self.velocities.insert(entity, Velocity {
                    linear: Vec2.new(dx, dy),
                    angular: 0.0,
                })

    // --- Movement System ---
    //
    // Applies velocity to transform for all entities with both.
    // Data-oriented: iterates the dense transform array directly,
    // probing the velocity storage for each entity. Cache-friendly --
    // transforms are contiguous in memory.
    //
    // Reads: velocities   Writes: transforms

    mut fn run_movement():
        let dt = self.dt
        for i in 0..self.transforms.len():
            let entity = Entity.new(self.transforms.dense_entities[i])
            let vel: Velocity = self.velocities.get(entity) ?? continue
            let tf: Transform = self.transforms.dense_data[i]
            self.transforms.dense_data[i] = Transform {
                position: tf.position.add(vel.linear.scale(dt)),
                rotation: tf.rotation + vel.angular * dt,
                scale: tf.scale,
            }

// --- Collision System ---
//
// Broad-phase AABB overlap detection. Returns the collision events.
//
// Reads: transforms, colliders

fn run_collision(
    transforms: &DenseStorage[Transform],
    colliders: &DenseStorage[Collider],
) -> Vec[CollisionEvent]:
    var events = Vec.new()

    // Gather entities that have both Transform and Collider.
    var candidates = Vec.new()
    for eid in colliders.dense_entities:
        if transforms.contains(Entity.new(eid)):
            candidates.push(eid)

    // O(n^2) broad phase -- sufficient for small entity counts.
    for i in 0..candidates.len():
        let a = Entity.new(candidates[i])
        let tf_a = transforms.get(a).unwrap()
        let col_a = colliders.get(a).unwrap()

        let half_a = Vec2.new(col_a.radius, col_a.radius)
        let bounds_a = AABB.from_center(tf_a.position, half_a)

        for j in (i + 1)..candidates.len():
            let b = Entity.new(candidates[j])
            let col_b = colliders.get(b).unwrap()

            // Layer filtering: only collide if masks overlap
            if (col_a.mask & col_b.layer) == 0 and (col_b.mask & col_a.layer) == 0:
                continue

            let tf_b = transforms.get(b).unwrap()
            let half_b = Vec2.new(col_b.radius, col_b.radius)
            let bounds_b = AABB.from_center(tf_b.position, half_b)

            if bounds_a.overlaps(&bounds_b):
                let dist = Vec2.distance(tf_a.position, tf_b.position)
                let min_dist = col_a.radius + col_b.radius
                if dist < min_dist:
                    events.push(CollisionEvent {
                        entity_a: a,
                        entity_b: b,
                        overlap: min_dist - dist,
                    })
    events

// --- Render System ---
//
// Builds a draw list and renders (mock). Demonstrates
// data-oriented iteration patterns.
//
// Reads: transforms, sprites

type RenderEntry {
    entity_id: i32,
    position: Vec2,
    rotation: f32,
    scale: f32,
    texture: TextureId,
    width: u16,
    height: u16,
    layer: i32,
}

fn run_render(
    transforms: &DenseStorage[Transform],
    sprites: &DenseStorage[Sprite],
):
    // Build render list by iterating sprites and probing transforms
    var entries = Vec.new()
    for i in 0..sprites.len():
        let eid = sprites.dense_entities[i]
        let entity = Entity.new(eid)
        let sprite = sprites.dense_data[i]
        if sprite.visible:
            if let Some(tf) = transforms.get(entity):
                entries.push(RenderEntry {
                    entity_id: eid,
                    position: tf.position,
                    rotation: tf.rotation,
                    scale: tf.scale,
                    texture: sprite.texture,
                    width: sprite.width,
                    height: sprite.height,
                    layer: sprite.layer,
                })

    // Draw (mock -- print to stdout for this demo)
    print(f"  Render: {entries.len()} sprites")
    for entry in entries:
        print(f"    [{entry.layer}] {texture_name(entry.texture)} at ({entry.position.x}, {entry.position.y})")

// --- Collision Response ---
//
// Processes collision events. Demonstrates entity name lookup.

fn run_collision_response(world: &World):
    for event in world.collision_events:
        let name_a = match world.entity_name(event.entity_a):
            Some(name) => f"{name}"
            None => "?"
        let name_b = match world.entity_name(event.entity_b):
            Some(name) => f"{name}"
            None => "?"
        print(f"  Collision: {name_a} <-> {name_b} (overlap: {event.overlap})")

// ===================================================================
// Frame orchestration
//
// Systems declare what they read/write via their signatures.
// Non-conflicting read-only systems could be parallelized using scope.
// ===================================================================

extend World:
    pub mut fn run_frame(input_events: &Vec[InputEvent]):
        // Phase 1: Input (writes input_states, velocities)
        self.run_input_events(input_events)
        self.run_player_controller(200.0)

        // Phase 2: Movement (reads velocities, writes transforms)
        self.run_movement()

        // Phase 3: Collision detection (reads transforms, colliders)
        self.collision_events = run_collision(&self.transforms, &self.colliders)

        // Phase 4: Render
        run_render(&self.transforms, &self.sprites)

        // Phase 5: Collision response + cleanup
        run_collision_response(self)
        self.flush_despawns()

        // End of frame
        self.time += self.dt
        self.frame += 1
