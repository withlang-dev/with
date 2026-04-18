module ecs.query

use math.Vec2
use components.Entity
use components.Transform
use components.Velocity
use components.Collider
use components.Sprite
use components.InputState
use storage.TransformStorage
use storage.VelocityStorage
use storage.ColliderStorage
use storage.SpriteStorage
use storage.InputStateStorage

// Query functions -- iteration over entities that have specific
// component combinations. These are the read-only query primitives.
//
// Each function iterates the first storage and probes the others,
// printing/processing only entities present in all storages.

// --- Count entities with both Transform and Sprite ---

fn count_with_transform_and_sprite(
    transforms: &TransformStorage,
    sprites: &SpriteStorage,
) -> i32:
    var n: i32 = 0
    for i in 0..transforms.len():
        let eid = transforms.dense_entities[i]
        let entity = Entity.new(eid)
        if sprites.contains(entity):
            n += 1
    n

// --- Count entities with both Transform and Velocity ---

fn count_with_transform_and_velocity(
    transforms: &TransformStorage,
    velocities: &VelocityStorage,
) -> i32:
    var n: i32 = 0
    for i in 0..transforms.len():
        let eid = transforms.dense_entities[i]
        let entity = Entity.new(eid)
        if velocities.contains(entity):
            n += 1
    n
