module ecs.systems

use ecs.math.{Vec2, AABB}
use ecs.storage.{DenseStorage, iter, iter_mut}
use ecs.query.{query2, query3}
use ecs.components.*
use ecs.world.{Entity, World}

// ===================================================================
// Systems are plain functions that take references to specific
// component storages. Because each storage is a separate field
// on World, the borrow checker permits disjoint simultaneous
// access — the foundation for safe parallel execution.
// ===================================================================

// --- Input System ---
//
// Reads input events, updates InputState components.
// Writes: input_states

fn run_input_events(
    input_states: &mut DenseStorage[InputState],
    events: &[InputEvent],
):
    for (_, state) in iter_mut(input_states):
        for event in events:
            match event:
                .KeyDown(.Up)    => state.up = true
                .KeyUp(.Up)      => state.up = false
                .KeyDown(.Down)  => state.down = true
                .KeyUp(.Down)    => state.down = false
                .KeyDown(.Left)  => state.left = true
                .KeyUp(.Left)    => state.left = false
                .KeyDown(.Right) => state.right = true
                .KeyUp(.Right)   => state.right = false
                .KeyDown(.Space) => state.fire = true
                .KeyUp(.Space)   => state.fire = false
                _ => ()

// --- Player Controller ---
//
// Converts InputState into Velocity for player-controlled entities.
// Reads: input_states   Writes: velocities

fn run_player_controller(
    input_states: &DenseStorage[InputState],
    velocities: &mut DenseStorage[Velocity],
    speed: f32,
):
    for i in 0..input_states.len():
        let entity = input_states.dense_entities[i]
        let input = &input_states.dense_data[i]

        if let Some(vel) = velocities.get_mut(entity):
            var dx: f32 = 0.0
            var dy: f32 = 0.0
            if input.up    then dy -= speed
            if input.down  then dy += speed
            if input.left  then dx -= speed
            if input.right then dx += speed
            vel.linear = Vec2.new(dx, dy)

// --- Movement System ---
//
// Applies velocity to transform for all entities with both.
// Data-oriented: iterates the dense transform array directly,
// probing the velocity storage for each entity. Cache-friendly —
// transforms are contiguous in memory.
//
// Reads: velocities   Writes: transforms

fn run_movement(
    transforms: &mut DenseStorage[Transform],
    velocities: &DenseStorage[Velocity],
    dt: f32,
):
    for i in 0..transforms.len():
        let entity = transforms.dense_entities[i]
        if let Some(vel) = velocities.get(entity):
            let tf = &mut transforms.dense_data[i]
            tf.position = tf.position + vel.linear.scale(dt)
            tf.rotation += vel.angular * dt

// --- Collision System ---
//
// Broad-phase AABB overlap detection. Writes collision events.
// Uses frame arena for temporary work buffers.
//
// Reads: transforms, colliders   Writes: collision_events

fn run_collision(
    transforms: &DenseStorage[Transform],
    colliders: &DenseStorage[Collider],
    events: &mut Vec[CollisionEvent],
    arena: &FrameArena,
):
    events.clear()

    // Gather entities that have both Transform and Collider.
    // Allocate the work buffer from the frame arena (freed at frame end).
    var candidates = Vec.new_in(arena)
    for i in 0..colliders.len():
        let entity = colliders.dense_entities[i]
        if transforms.contains(entity):
            candidates.push(entity)

    // O(n^2) broad phase — sufficient for small entity counts.
    // A spatial hash or BVH would replace this for large worlds.
    for i in 0..candidates.len():
        let a = candidates[i]
        let tf_a = transforms.get(a).unwrap()
        let col_a = colliders.get(a).unwrap()

        let half_a = Vec2.new(col_a.radius, col_a.radius)
        let bounds_a = AABB.from_center(tf_a.position, half_a)

        for j in (i + 1)..candidates.len():
            let b = candidates[j]
            let col_b = colliders.get(b).unwrap()

            // Layer filtering: only collide if masks overlap
            if (col_a.mask & col_b.layer) == 0 and (col_b.mask & col_a.layer) == 0 then
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

    // candidates freed when frame_arena.reset() is called

// --- Render System ---
//
// Builds a sorted draw list and renders (mock). Demonstrates
// query generators, pipeline operators, and frame arena.
//
// Reads: transforms, sprites   Uses: frame_arena

type RenderEntry = {
    entity: Entity,
    position: Vec2,
    rotation: f32,
    scale: f32,
    texture: TextureId,
    width: u16,
    height: u16,
    layer: i32,
} with Copy

fn run_render(
    transforms: &DenseStorage[Transform],
    sprites: &DenseStorage[Sprite],
    arena: &FrameArena,
):
    // Build render list using query generator + pipeline
    var entries = Vec.new_in(arena)
    query2(sprites, transforms)
        |> filter(|(_, sprite, _)| sprite.visible)
        |> for_each(|(entity, sprite, tf)|
            entries.push(RenderEntry {
                entity,
                position: tf.position,
                rotation: tf.rotation,
                scale: tf.scale,
                texture: sprite.texture,
                width: sprite.width,
                height: sprite.height,
                layer: sprite.layer,
            })
        )

    // Sort by layer for correct draw order (painter's algorithm)
    entries.sort_by((a, b) => a.layer.cmp(&b.layer))

    // Draw (mock — print to stdout for this demo)
    print("  Render: {entries.len()} sprites")
    for entry in entries:
        print("    [{entry.layer}] {texture_name(entry.texture)} at ({entry.position.x:.1}, {entry.position.y:.1})")

// --- Collision Response ---
//
// Processes collision events. Demonstrates with-binding and
// entity name lookup.

fn run_collision_response(world: &mut World):
    for event in world.collision_events:
        with world.entity_name(event.entity_a) as name_a:
            with world.entity_name(event.entity_b) as name_b:
                let a_str = name_a.unwrap_or("?")
                let b_str = name_b.unwrap_or("?")
                print("  Collision: {a_str} <-> {b_str} (overlap: {event.overlap:.1})")

// ===================================================================
// Frame orchestration — this is where parallel execution happens.
//
// Systems declare what they read/write via their parameter types.
// The schedule groups non-conflicting systems into parallel phases
// using scope (OS thread parallelism, spec S14.12).
// ===================================================================

fn run_frame(world: &mut World, input_events: &[InputEvent]):
    // Phase 1: Input (writes input_states, velocities)
    run_input_events(&mut world.input_states, input_events)
    run_player_controller(&world.input_states, &mut world.velocities, 200.0)

    // Phase 2: Movement (reads velocities, writes transforms)
    run_movement(&mut world.transforms, &world.velocities, world.dt)

    // Phase 3: Collision + Render (PARALLEL)
    //
    // These access disjoint fields of World:
    //   run_collision: reads transforms, colliders -> writes collision_events
    //   run_render:    reads transforms, sprites   -> uses frame_arena
    //
    // The borrow checker permits this because:
    //   - world.transforms: shared borrow (&) in both — OK
    //   - world.colliders: shared borrow in collision only
    //   - world.collision_events: exclusive borrow (&mut) in collision only
    //   - world.sprites: shared borrow in render only
    //   - world.frame_arena: shared borrow in render only
    //
    // All paths are disjoint or shared-compatible. Safe parallelism
    // with zero runtime checks, enforced at compile time.
    scope s =>
        s.spawn(() => run_collision(
            &world.transforms,
            &world.colliders,
            &mut world.collision_events,
            &world.frame_arena,
        ))
        s.spawn(() => run_render(
            &world.transforms,
            &world.sprites,
            &world.frame_arena,
        ))

    // Phase 4: Collision response + cleanup (sequential)
    run_collision_response(world)
    world.flush_despawns()

    // End of frame
    world.frame_arena.reset()
    world.time += world.dt
    world.frame += 1
