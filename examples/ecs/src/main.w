module ecs.main

use math.*
use storage.*
use query.*
use components.*
use world.*
use systems.*

// ===================================================================
// ECS Demo — A small game engine core
//
// Demonstrates:
//   - Handle-first entity design (SlotMap + generational handles)
//   - Dense component storage with O(1) lookup
//   - Disjoint field borrowing for parallel system execution
//   - Comptime component registration and ID generation
//   - Query generators with pipeline composition
//   - Record update syntax for entity modification
//   - Frame arena for per-frame temporary allocations
//   - scope-based parallelism (OS threads, not fibers)
//   - Data-oriented iteration patterns
// ===================================================================

fn main:
    var world = World.new()
    let dt = 1.0 / 60.0
    world.dt = dt

    // --- Spawn Entities ---

    let player = spawn_player(&mut world)
    let enemies = spawn_enemies(&mut world, 5)
    let walls = spawn_walls(&mut world)

    print(f"=== ECS Demo: {world.entity_count()} entities spawned ===\n")
    world.print_stats()
    print("")

    // --- Simulate 5 frames ---

    // Frame 0: player presses Right
    print(f"--- Frame {world.frame} (t={world.time:.2}s) ---")
    var ev0 = Vec.new()
    ev0.push(InputEvent.KeyDown(.Right))
    run_frame(&mut world, &ev0)

    // Frame 1: key held (no new events)
    print(f"--- Frame {world.frame} (t={world.time:.2}s) ---")
    let ev1 = Vec.new()
    run_frame(&mut world, &ev1)

    // Frame 2: player also presses Up (diagonal movement)
    print(f"--- Frame {world.frame} (t={world.time:.2}s) ---")
    var ev2 = Vec.new()
    ev2.push(InputEvent.KeyDown(.Up))
    run_frame(&mut world, &ev2)

    // Frame 3: release Right, keep Up
    print(f"--- Frame {world.frame} (t={world.time:.2}s) ---")
    var ev3 = Vec.new()
    ev3.push(InputEvent.KeyUp(.Right))
    run_frame(&mut world, &ev3)

    // Frame 4: release everything
    print(f"--- Frame {world.frame} (t={world.time:.2}s) ---")
    var ev4 = Vec.new()
    ev4.push(InputEvent.KeyUp(.Up))
    run_frame(&mut world, &ev4)

    // --- Final State ---

    print("\n=== After 5 frames ===")
    world.print_stats()

    // Print entity positions by iterating transforms and probing sprites
    print("\nEntity positions:")
    for i in 0..world.transforms.len():
        let eid = world.transforms.dense_entities[i]
        let entity = Entity.new(eid)
        if let Some(sprite) = world.sprites.get(entity):
            let tf = world.transforms.dense_data[i]
            let name = world.entity_name(entity)
            let label = name.unwrap_or("?")
            print(f"  {label} -> ({tf.position.x:.1}, {tf.position.y:.1}) tex={texture_name(sprite.texture)}")

    // --- Demonstrate despawning ---

    print("\nDespawning first enemy...")
    if enemies.len() > 0:
        let first_enemy = enemies[0]
        world.despawn(first_enemy)

        print(f"Entities after despawn: {world.entity_count()}")

        // Verify the handle is invalidated
        assert(not world.is_alive(first_enemy))
        assert(world.transforms.get(first_enemy).is_none())
        print("Handle correctly invalidated (generation mismatch)")

    print("\n=== Demo complete ===")

// --- Entity Spawning Helpers ---

fn spawn_player(world: &mut World) -> Entity:
    let player = world.spawn("player")
    world.add(player, Transform {
        position: Vec2.new(100.0, 300.0),
        rotation: 0.0,
        scale: 1.0,
    })
    world.add(player, Velocity {
        linear: Vec2.zero(),
        angular: 0.0,
    })
    world.add(player, InputState {})
    world.add(player, Sprite {
        texture: TEXTURE_PLAYER,
        width: 32,
        height: 32,
        layer: 10,
        visible: true,
    })
    world.add(player, Collider {
        radius: 16.0,
        layer: 1,    // player layer
        mask: 0xFF,  // collides with everything
    })
    player

fn spawn_enemies(world: &mut World, count: i32) -> Vec[Entity]:
    with Vec.new() as mut enemies:
        for i in 0..count:
            let enemy = world.spawn(f"enemy_{i}")
            world.add(enemy, Transform {
                position: Vec2.new(200.0 + (i as f32) * 80.0, 300.0),
                rotation: 0.0,
                scale: 1.0,
            })
            world.add(enemy, Velocity {
                linear: Vec2.new(0.0, 30.0 + (i as f32) * 5.0),
                angular: 0.5,
            })
            world.add(enemy, Sprite {
                texture: TEXTURE_ENEMY,
                width: 32,
                height: 32,
                layer: 5,
                visible: true,
            })
            world.add(enemy, Collider {
                radius: 16.0,
                layer: 2,    // enemy layer
                mask: 0x01,  // collides with player layer only
            })
            enemies.push(enemy)

fn spawn_walls(world: &mut World) -> Vec[Entity]:
    // Spawn border walls using record update syntax
    let base_wall = Transform {
        position: Vec2.zero(),
        rotation: 0.0,
        scale: 1.0,
    }
    let wall_sprite = Sprite {
        texture: TEXTURE_WALL,
        width: 800,
        height: 16,
        layer: 0,
        visible: true,
    }

    with Vec.new() as mut walls:
        // Top wall
        let top = world.spawn("wall_top")
        world.add(top, { base_wall with position: Vec2.new(400.0, 0.0) })
        world.add(top, wall_sprite)
        world.add(top, Collider { radius: 400.0, layer: 4, mask: 0xFF })
        walls.push(top)

        // Bottom wall (record update — only position changes)
        let bottom = world.spawn("wall_bottom")
        world.add(bottom, { base_wall with position: Vec2.new(400.0, 600.0) })
        world.add(bottom, wall_sprite)
        world.add(bottom, Collider { radius: 400.0, layer: 4, mask: 0xFF })
        walls.push(bottom)

        // Left wall
        let left = world.spawn("wall_left")
        world.add(left, { base_wall with position: Vec2.new(0.0, 300.0) })
        world.add(left, { wall_sprite with width: 16, height: 600 })
        world.add(left, Collider { radius: 300.0, layer: 4, mask: 0xFF })
        walls.push(left)

        // Right wall
        let right = world.spawn("wall_right")
        world.add(right, { base_wall with position: Vec2.new(800.0, 300.0) })
        world.add(right, { wall_sprite with width: 16, height: 600 })
        world.add(right, Collider { radius: 300.0, layer: 4, mask: 0xFF })
        walls.push(right)
