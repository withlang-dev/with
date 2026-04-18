module ecs.components

use math.Vec2

// --- Entity Handle ---
//
// Entity is a generational handle. The generation field detects
// use-after-remove: if the stored generation doesn't match the
// pool's current generation for that slot, the handle is stale.

type Entity { id: i32, generation: i32 }

extend Entity:
    fn new(id: i32) -> Entity:
        Entity { id, generation: 0 }

    fn with_generation(id: i32, generation: i32) -> Entity:
        Entity { id, generation }

// --- Component ID ---
//
// Unique integer identifying each component type. Used by the
// scheduler to determine which systems access which storages.

type ComponentId { value: i32 }

const TRANSFORM_ID: ComponentId   = ComponentId { value: 1 }
const VELOCITY_ID: ComponentId    = ComponentId { value: 2 }
const COLLIDER_ID: ComponentId    = ComponentId { value: 3 }
const SPRITE_ID: ComponentId      = ComponentId { value: 4 }
const INPUT_STATE_ID: ComponentId = ComponentId { value: 5 }

// --- Game Components ---

type Transform {
    position: Vec2,
    rotation: f32,
    scale: f32,
}

type Velocity {
    linear: Vec2,
    angular: f32,
}

type Collider {
    radius: f32,
    layer: u8,      // collision layer for filtering
    mask: u8,       // which layers this collides with
}

type TextureId { value: u32 }

type Sprite {
    texture: TextureId,
    width: u16,
    height: u16,
    layer: i32,
    visible: bool,
}

type InputState {
    up: bool = false,
    down: bool = false,
    left: bool = false,
    right: bool = false,
    fire: bool = false,
}

// Default field values allow InputState {} with all-false fields

// --- Texture Constants (handle-first: IDs, not strings) ---

const TEXTURE_PLAYER: TextureId = TextureId { value: 0 }
const TEXTURE_ENEMY: TextureId  = TextureId { value: 1 }
const TEXTURE_WALL: TextureId   = TextureId { value: 2 }
const TEXTURE_BULLET: TextureId = TextureId { value: 3 }

fn texture_name(id: TextureId) -> str:
    match id.value:
        0 => "player.png"
        1 => "enemy.png"
        2 => "wall.png"
        3 => "bullet.png"
        _ => "unknown.png"

// --- Event Types ---

enum InputEvent {
    KeyDown(key: Key)
    | KeyUp(key: Key)
}

enum Key { Up | Down | Left | Right | Space | Escape }

type CollisionEvent {
    entity_a: Entity,
    entity_b: Entity,
    overlap: f32,
}
