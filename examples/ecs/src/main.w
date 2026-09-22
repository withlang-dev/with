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
//   - Handle-first entity design (generational handles)
//   - Dense component storage with O(1) lookup
//   - Systems that state what they read and write in their signatures
//   - Record update syntax for entity modification
//   - `with ... as mut` builders for spawning
//   - Data-oriented iteration patterns
// ===================================================================

fn main:
    var world = World.new()
    let dt = 1.0 / 60.0
    world.dt = dt

    // --- Spawn Entities ---

    let player = world.spawn_player()
    let enemies = world.spawn_enemies(5)
    let walls = world.spawn_walls()

    print(f"=== ECS Demo: {world.entity_count()} entities spawned ===\n")
    world.print_stats()
    print("")

    // --- Simulate 5 frames ---

    // Frame 0: player presses Right
    print(f"--- Frame {world.frame} (t={world.time:.2}s) ---")
    var ev0 = Vec.new()
    ev0.push(InputEvent.KeyDown(.Right))
    world.run_frame(&ev0)

    // Frame 1: key held (no new events)
    print(f"--- Frame {world.frame} (t={world.time:.2}s) ---")
    let ev1: Vec[InputEvent] = Vec.new()
    world.run_frame(&ev1)

    // Frame 2: player also presses Up (diagonal movement)
    print(f"--- Frame {world.frame} (t={world.time:.2}s) ---")
    var ev2 = Vec.new()
    ev2.push(InputEvent.KeyDown(.Up))
    world.run_frame(&ev2)

    // Frame 3: release Right, keep Up
    print(f"--- Frame {world.frame} (t={world.time:.2}s) ---")
    var ev3 = Vec.new()
    ev3.push(InputEvent.KeyUp(.Right))
    world.run_frame(&ev3)

    // Frame 4: release everything
    print(f"--- Frame {world.frame} (t={world.time:.2}s) ---")
    var ev4 = Vec.new()
    ev4.push(InputEvent.KeyUp(.Up))
    world.run_frame(&ev4)

    // --- Final State ---

    print("\n=== After 5 frames ===")
    world.print_stats()

    // Print entity positions by iterating transforms and probing sprites
    print("\nEntity positions:")
    for i in 0..world.transforms.len():
        let entity = Entity.new(world.transforms.dense_entities[i])
        if let Some(sprite) = world.sprites.get(entity):
            let tf = world.transforms.dense_data[i]
            let label = match world.entity_name(entity):
                Some(name) => f"{name}"
                None => "?"
            print(f"  {label} -> ({tf.position.x:.1}, {tf.position.y:.1}) tex={texture_name(sprite.texture)}")

    // --- Demonstrate despawning ---

    print("\nDespawning first enemy...")
    if enemies.len() > 0:
        let first_enemy: Entity = enemies[0]
        world.despawn(first_enemy)

        print(f"Entities after despawn: {world.entity_count()}")

        // Verify the handle is invalidated
        assert(not world.is_alive(first_enemy))
        assert(world.transforms.get(first_enemy).is_none())
        print("Handle correctly invalidated (generation mismatch)")

    print("\n=== Demo complete ===")

// --- Entity Spawning Helpers ---
//
// Spawning mutates the world, so the helpers are `mut fn` receivers
// (§3.1); the collections they return are `with ... as mut` builders
// (§7.2).

extend World:
    mut fn spawn_player() -> Entity:
        let player = self.spawn_entity("player")
        self.add_transform(player, Transform {
            position: Vec2.new(100.0, 300.0),
            rotation: 0.0,
            scale: 1.0,
        })
        self.add_velocity(player, Velocity {
            linear: Vec2.zero(),
            angular: 0.0,
        })
        self.add_input_state(player, InputState {})
        self.add_sprite(player, Sprite {
            texture: TEXTURE_PLAYER,
            width: 32,
            height: 32,
            layer: 10,
            visible: true,
        })
        self.add_collider(player, Collider {
            radius: 16.0,
            layer: 1,    // player layer
            mask: 0xFF,  // collides with everything
        })
        player

    mut fn spawn_enemies(count: i32) -> Vec[Entity]:
        with Vec.new() as mut enemies:
            for i in 0..count:
                let enemy = self.spawn_entity(f"enemy_{i}")
                self.add_transform(enemy, Transform {
                    position: Vec2.new(200.0 + (i as f32) * 80.0, 300.0),
                    rotation: 0.0,
                    scale: 1.0,
                })
                self.add_velocity(enemy, Velocity {
                    linear: Vec2.new(0.0, 30.0 + (i as f32) * 5.0),
                    angular: 0.5,
                })
                self.add_sprite(enemy, Sprite {
                    texture: TEXTURE_ENEMY,
                    width: 32,
                    height: 32,
                    layer: 5,
                    visible: true,
                })
                self.add_collider(enemy, Collider {
                    radius: 16.0,
                    layer: 2,    // enemy layer
                    mask: 0x01,  // collides with player layer only
                })
                enemies.push(enemy)

    mut fn spawn_walls() -> Vec[Entity]:
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
            let top = self.spawn_entity("wall_top")
            self.add_transform(top, { base_wall with position: Vec2.new(400.0, 0.0) })
            self.add_sprite(top, wall_sprite)
            self.add_collider(top, Collider { radius: 400.0, layer: 4, mask: 0xFF })
            walls.push(top)

            // Bottom wall (record update — only position changes)
            let bottom = self.spawn_entity("wall_bottom")
            self.add_transform(bottom, { base_wall with position: Vec2.new(400.0, 600.0) })
            self.add_sprite(bottom, wall_sprite)
            self.add_collider(bottom, Collider { radius: 400.0, layer: 4, mask: 0xFF })
            walls.push(bottom)

            // Left wall
            let left = self.spawn_entity("wall_left")
            self.add_transform(left, { base_wall with position: Vec2.new(0.0, 300.0) })
            self.add_sprite(left, { wall_sprite with width: 16, height: 600 })
            self.add_collider(left, Collider { radius: 300.0, layer: 4, mask: 0xFF })
            walls.push(left)

            // Right wall
            let right = self.spawn_entity("wall_right")
            self.add_transform(right, { base_wall with position: Vec2.new(800.0, 300.0) })
            self.add_sprite(right, { wall_sprite with width: 16, height: 600 })
            self.add_collider(right, Collider { radius: 300.0, layer: 4, mask: 0xFF })
            walls.push(right)
