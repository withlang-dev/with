module ecs.query

use components.Entity
use components.Transform
use components.Velocity
use components.Sprite
use storage.DenseStorage

// Query functions -- iteration over entities that have specific
// component combinations. These are the read-only query primitives,
// so they take their storages as `&T` (§3.8).
//
// Each function iterates the first storage and probes the others,
// counting only entities present in all storages.

// --- Count entities with both Transform and Sprite ---

pub fn count_with_transform_and_sprite(
    transforms: &DenseStorage[Transform],
    sprites: &DenseStorage[Sprite],
) -> i32:
    var n: i32 = 0
    for eid in transforms.dense_entities:
        if sprites.contains(Entity.new(eid)):
            n += 1
    n

// --- Count entities with both Transform and Velocity ---

pub fn count_with_transform_and_velocity(
    transforms: &DenseStorage[Transform],
    velocities: &DenseStorage[Velocity],
) -> i32:
    var n: i32 = 0
    for eid in transforms.dense_entities:
        if velocities.contains(Entity.new(eid)):
            n += 1
    n
