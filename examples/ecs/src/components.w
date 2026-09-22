module ecs.components

use math.Vec2

// --- Entity Handle ---
//
// Entity is a generational handle. The generation field detects
// use-after-remove: if the stored generation doesn't match the
// pool's current generation for that slot, the handle is stale.

pub type Entity { id: i32, generation: i32 }
impl Copy for Entity

pub fn Entity.new(id: i32) -> Entity:
    Entity { id, generation: 0 }

pub fn Entity.with_generation(id: i32, generation: i32) -> Entity:
    Entity { id, generation }

// --- Component ID ---
//
// Unique integer identifying each component type. Used by the
// scheduler to determine which systems access which storages.

pub type ComponentId { value: i32 }
impl Copy for ComponentId

pub const TRANSFORM_ID: ComponentId   = ComponentId { value: 1 }
pub const VELOCITY_ID: ComponentId    = ComponentId { value: 2 }
pub const COLLIDER_ID: ComponentId    = ComponentId { value: 3 }
pub const SPRITE_ID: ComponentId      = ComponentId { value: 4 }
pub const INPUT_STATE_ID: ComponentId = ComponentId { value: 5 }

// --- Game Components ---
//
// Components are plain data and opt into Copy (§11.8): storages hand
// out views, and a system that needs an independent value takes a
// typed copy.

pub type Transform {
    position: Vec2,
    rotation: f32,
    scale: f32,
}
impl Copy for Transform

pub type Velocity {
    linear: Vec2,
    angular: f32,
}
impl Copy for Velocity

pub type Collider {
    radius: f32,
    layer: u8,      // collision layer for filtering
    mask: u8,       // which layers this collides with
}
impl Copy for Collider

pub type TextureId { value: u32 }
impl Copy for TextureId

pub type Sprite {
    texture: TextureId,
    width: u16,
    height: u16,
    layer: i32,
    visible: bool,
}
impl Copy for Sprite

pub type InputState {
    up: bool = false,
    down: bool = false,
    left: bool = false,
    right: bool = false,
    fire: bool = false,
}
impl Copy for InputState

// Default field values allow InputState {} with all-false fields

// --- Texture Constants (handle-first: IDs, not strings) ---

pub const TEXTURE_PLAYER: TextureId = TextureId { value: 0 }
pub const TEXTURE_ENEMY: TextureId  = TextureId { value: 1 }
pub const TEXTURE_WALL: TextureId   = TextureId { value: 2 }
pub const TEXTURE_BULLET: TextureId = TextureId { value: 3 }

pub fn texture_name(id: TextureId) -> str:
    match id.value:
        0 => "player.png"
        1 => "enemy.png"
        2 => "wall.png"
        3 => "bullet.png"
        _ => "unknown.png"

// --- Event Types ---

pub enum Key { Up | Down | Left | Right | Space | Escape }
impl Copy for Key

pub enum InputEvent {
    KeyDown(key: Key)
    | KeyUp(key: Key)
}
impl Copy for InputEvent

pub type CollisionEvent {
    entity_a: Entity,
    entity_b: Entity,
    overlap: f32,
}
impl Copy for CollisionEvent
