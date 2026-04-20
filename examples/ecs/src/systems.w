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
use storage.TransformStorage
use storage.VelocityStorage
use storage.ColliderStorage
use storage.SpriteStorage
use storage.InputStateStorage
use world.World

// ===================================================================
// Systems are plain functions that take references to specific
// component storages. Because each storage is a separate field
// on World, the borrow checker permits disjoint simultaneous
// access -- the foundation for safe parallel execution.
// ===================================================================

// --- Input System ---
//
// Reads input events, updates InputState components.
// Writes: input_states

fn run_input_events(
    input_states: &mut InputStateStorage,
    events: &Vec[InputEvent],
):
    for si in 0..input_states.len():
        for ei in 0..events.len():
            let event = events[ei]
            match event:
                .KeyDown(.Up)    => input_states.dense_data[si].up = true
                .KeyUp(.Up)      => input_states.dense_data[si].up = false
                .KeyDown(.Down)  => input_states.dense_data[si].down = true
                .KeyUp(.Down)    => input_states.dense_data[si].down = false
                .KeyDown(.Left)  => input_states.dense_data[si].left = true
                .KeyUp(.Left)    => input_states.dense_data[si].left = false
                .KeyDown(.Right) => input_states.dense_data[si].right = true
                .KeyUp(.Right)   => input_states.dense_data[si].right = false
                .KeyDown(.Space) => input_states.dense_data[si].fire = true
                .KeyUp(.Space)   => input_states.dense_data[si].fire = false
                _ => ()

// --- Player Controller ---
//
// Converts InputState into Velocity for player-controlled entities.
// Reads: input_states   Writes: velocities

fn run_player_controller(
    input_states: &InputStateStorage,
    velocities: &mut VelocityStorage,
    speed: f32,
):
    for i in 0..input_states.len():
        let eid = input_states.dense_entities[i]
        let entity = Entity.new(eid)
        let input = input_states.dense_data[i]

        if velocities.contains(entity):
            var dx: f32 = 0.0
            var dy: f32 = 0.0
            if input.up: dy -= speed
            if input.down: dy += speed
            if input.left: dx -= speed
            if input.right: dx += speed
            velocities.insert(entity, Velocity {
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

fn run_movement(
    transforms: &mut TransformStorage,
    velocities: &VelocityStorage,
    dt: f32,
):
    for i in 0..transforms.len():
        let eid = transforms.dense_entities[i]
        let entity = Entity.new(eid)
        if let Some(vel) = velocities.get(entity):
            let tf = transforms.dense_data[i]
            transforms.dense_data[i] = Transform {
                position: tf.position + vel.linear.scale(dt),
                rotation: tf.rotation + vel.angular * dt,
                scale: tf.scale,
            }

// --- Collision System ---
//
// Broad-phase AABB overlap detection. Writes collision events.
//
// Reads: transforms, colliders   Writes: collision_events

fn run_collision(
    transforms: &TransformStorage,
    colliders: &ColliderStorage,
    events: &mut Vec[CollisionEvent],
):
    events.clear()

    // Gather entities that have both Transform and Collider.
    var candidates = Vec.new()
    for i in 0..colliders.len():
        let eid = colliders.dense_entities[i]
        let entity = Entity.new(eid)
        if transforms.contains(entity):
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
    transforms: &TransformStorage,
    sprites: &SpriteStorage,
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
    for i in 0..entries.len():
        let entry = entries[i]
        print(f"    [{entry.layer}] {texture_name(entry.texture)} at ({entry.position.x}, {entry.position.y})")

// --- Collision Response ---
//
// Processes collision events. Demonstrates entity name lookup.

fn run_collision_response(world: &World):
    for i in 0..world.collision_events.len():
        let event = world.collision_events[i]
        let name_a = world.entity_name(event.entity_a)
        let name_b = world.entity_name(event.entity_b)
        match name_a:
            Some(a_str) =>
                match name_b:
                    Some(b_str) =>
                        print(f"  Collision: {a_str} <-> {b_str} (overlap: {event.overlap})")
                    None =>
                        print(f"  Collision: {a_str} <-> ? (overlap: {event.overlap})")
            None =>
                print(f"  Collision: ? <-> ? (overlap: {event.overlap})")

// ===================================================================
// Frame orchestration
//
// Systems declare what they read/write via their parameter types.
// Non-conflicting systems could be parallelized using scope.
// ===================================================================

fn run_frame(world: &mut World, input_events: &Vec[InputEvent]):
    // Phase 1: Input (writes input_states, velocities)
    run_input_events(&mut world.input_states, input_events)
    run_player_controller(&world.input_states, &mut world.velocities, 200.0)

    // Phase 2: Movement (reads velocities, writes transforms)
    run_movement(&mut world.transforms, &world.velocities, world.dt)

    // Phase 3: Collision detection
    run_collision(
        &world.transforms,
        &world.colliders,
        &mut world.collision_events,
    )

    // Phase 4: Render
    run_render(&world.transforms, &world.sprites)

    // Phase 5: Collision response + cleanup
    run_collision_response(world)
    world.flush_despawns()

    // End of frame
    world.time += world.dt
    world.frame += 1
