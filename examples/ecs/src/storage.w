module ecs.storage

use std.collections.HashMap
use math.Vec2
use components.Entity
use components.Transform
use components.Velocity
use components.Collider
use components.Sprite
use components.InputState

// DenseStorage is a sparse-set component container. Components are
// stored in contiguous arrays (dense), with a hash map for entity
// lookup (sparse). Iteration is O(n) where n = stored components.
//
// This is the standard ECS storage pattern: cache-friendly iteration
// with O(1) random access by entity handle.
//
// Each component type gets its own concrete storage because the
// compiler does not yet support generic extend blocks.

// ================================================================
// TransformStorage
// ================================================================

type TransformStorage {
    dense_entities: Vec[i32],
    dense_data: Vec[Transform],
    sparse: HashMap[i32, i32],
}

extend TransformStorage:
    fn new() -> TransformStorage:
        TransformStorage {
            dense_entities: Vec.new(),
            dense_data: Vec.new(),
            sparse: HashMap.new(),
        }

    fn insert(self: &mut TransformStorage, entity: Entity, component: Transform):
        if self.sparse.contains_key(entity.id):
            let idx = self.sparse.get(entity.id)
            self.dense_data[idx] = component
        else:
            self.sparse.insert(entity.id, self.dense_data.len())
            self.dense_entities.push(entity.id)
            self.dense_data.push(component)

    fn get(self: &TransformStorage, entity: Entity) -> Option[Transform]:
        if self.sparse.contains_key(entity.id):
            let idx = self.sparse.get(entity.id)
            Some(self.dense_data[idx])
        else:
            None

    fn remove(self: &mut TransformStorage, entity: Entity):
        if self.sparse.contains_key(entity.id):
            let idx = self.sparse.remove(entity.id)
            let last = self.dense_data.len() - 1
            if idx != last:
                self.dense_entities.swap(idx, last)
                self.dense_data.swap(idx, last)
                self.sparse.insert(self.dense_entities[idx], idx)
            let _ = self.dense_entities.pop()
            let _ = self.dense_data.pop()

    fn contains(self: &TransformStorage, entity: Entity) -> bool:
        self.sparse.contains_key(entity.id)

    fn len(self: &TransformStorage) -> i32: self.dense_data.len()

    fn clear(self: &mut TransformStorage):
        self.dense_entities.clear()
        self.dense_data.clear()
        self.sparse.clear()

// ================================================================
// VelocityStorage
// ================================================================

type VelocityStorage {
    dense_entities: Vec[i32],
    dense_data: Vec[Velocity],
    sparse: HashMap[i32, i32],
}

extend VelocityStorage:
    fn new() -> VelocityStorage:
        VelocityStorage {
            dense_entities: Vec.new(),
            dense_data: Vec.new(),
            sparse: HashMap.new(),
        }

    fn insert(self: &mut VelocityStorage, entity: Entity, component: Velocity):
        if self.sparse.contains_key(entity.id):
            let idx = self.sparse.get(entity.id)
            self.dense_data[idx] = component
        else:
            self.sparse.insert(entity.id, self.dense_data.len())
            self.dense_entities.push(entity.id)
            self.dense_data.push(component)

    fn get(self: &VelocityStorage, entity: Entity) -> Option[Velocity]:
        if self.sparse.contains_key(entity.id):
            let idx = self.sparse.get(entity.id)
            Some(self.dense_data[idx])
        else:
            None

    fn remove(self: &mut VelocityStorage, entity: Entity):
        if self.sparse.contains_key(entity.id):
            let idx = self.sparse.remove(entity.id)
            let last = self.dense_data.len() - 1
            if idx != last:
                self.dense_entities.swap(idx, last)
                self.dense_data.swap(idx, last)
                self.sparse.insert(self.dense_entities[idx], idx)
            let _ = self.dense_entities.pop()
            let _ = self.dense_data.pop()

    fn contains(self: &VelocityStorage, entity: Entity) -> bool:
        self.sparse.contains_key(entity.id)

    fn len(self: &VelocityStorage) -> i32: self.dense_data.len()

    fn clear(self: &mut VelocityStorage):
        self.dense_entities.clear()
        self.dense_data.clear()
        self.sparse.clear()

// ================================================================
// ColliderStorage
// ================================================================

type ColliderStorage {
    dense_entities: Vec[i32],
    dense_data: Vec[Collider],
    sparse: HashMap[i32, i32],
}

extend ColliderStorage:
    fn new() -> ColliderStorage:
        ColliderStorage {
            dense_entities: Vec.new(),
            dense_data: Vec.new(),
            sparse: HashMap.new(),
        }

    fn insert(self: &mut ColliderStorage, entity: Entity, component: Collider):
        if self.sparse.contains_key(entity.id):
            let idx = self.sparse.get(entity.id)
            self.dense_data[idx] = component
        else:
            self.sparse.insert(entity.id, self.dense_data.len())
            self.dense_entities.push(entity.id)
            self.dense_data.push(component)

    fn get(self: &ColliderStorage, entity: Entity) -> Option[Collider]:
        if self.sparse.contains_key(entity.id):
            let idx = self.sparse.get(entity.id)
            Some(self.dense_data[idx])
        else:
            None

    fn remove(self: &mut ColliderStorage, entity: Entity):
        if self.sparse.contains_key(entity.id):
            let idx = self.sparse.remove(entity.id)
            let last = self.dense_data.len() - 1
            if idx != last:
                self.dense_entities.swap(idx, last)
                self.dense_data.swap(idx, last)
                self.sparse.insert(self.dense_entities[idx], idx)
            let _ = self.dense_entities.pop()
            let _ = self.dense_data.pop()

    fn contains(self: &ColliderStorage, entity: Entity) -> bool:
        self.sparse.contains_key(entity.id)

    fn len(self: &ColliderStorage) -> i32: self.dense_data.len()

    fn clear(self: &mut ColliderStorage):
        self.dense_entities.clear()
        self.dense_data.clear()
        self.sparse.clear()

// ================================================================
// SpriteStorage
// ================================================================

type SpriteStorage {
    dense_entities: Vec[i32],
    dense_data: Vec[Sprite],
    sparse: HashMap[i32, i32],
}

extend SpriteStorage:
    fn new() -> SpriteStorage:
        SpriteStorage {
            dense_entities: Vec.new(),
            dense_data: Vec.new(),
            sparse: HashMap.new(),
        }

    fn insert(self: &mut SpriteStorage, entity: Entity, component: Sprite):
        if self.sparse.contains_key(entity.id):
            let idx = self.sparse.get(entity.id)
            self.dense_data[idx] = component
        else:
            self.sparse.insert(entity.id, self.dense_data.len())
            self.dense_entities.push(entity.id)
            self.dense_data.push(component)

    fn get(self: &SpriteStorage, entity: Entity) -> Option[Sprite]:
        if self.sparse.contains_key(entity.id):
            let idx = self.sparse.get(entity.id)
            Some(self.dense_data[idx])
        else:
            None

    fn remove(self: &mut SpriteStorage, entity: Entity):
        if self.sparse.contains_key(entity.id):
            let idx = self.sparse.remove(entity.id)
            let last = self.dense_data.len() - 1
            if idx != last:
                self.dense_entities.swap(idx, last)
                self.dense_data.swap(idx, last)
                self.sparse.insert(self.dense_entities[idx], idx)
            let _ = self.dense_entities.pop()
            let _ = self.dense_data.pop()

    fn contains(self: &SpriteStorage, entity: Entity) -> bool:
        self.sparse.contains_key(entity.id)

    fn len(self: &SpriteStorage) -> i32: self.dense_data.len()

    fn clear(self: &mut SpriteStorage):
        self.dense_entities.clear()
        self.dense_data.clear()
        self.sparse.clear()

// ================================================================
// InputStateStorage
// ================================================================

type InputStateStorage {
    dense_entities: Vec[i32],
    dense_data: Vec[InputState],
    sparse: HashMap[i32, i32],
}

extend InputStateStorage:
    fn new() -> InputStateStorage:
        InputStateStorage {
            dense_entities: Vec.new(),
            dense_data: Vec.new(),
            sparse: HashMap.new(),
        }

    fn insert(self: &mut InputStateStorage, entity: Entity, component: InputState):
        if self.sparse.contains_key(entity.id):
            let idx = self.sparse.get(entity.id)
            self.dense_data[idx] = component
        else:
            self.sparse.insert(entity.id, self.dense_data.len())
            self.dense_entities.push(entity.id)
            self.dense_data.push(component)

    fn get(self: &InputStateStorage, entity: Entity) -> Option[InputState]:
        if self.sparse.contains_key(entity.id):
            let idx = self.sparse.get(entity.id)
            Some(self.dense_data[idx])
        else:
            None

    fn remove(self: &mut InputStateStorage, entity: Entity):
        if self.sparse.contains_key(entity.id):
            let idx = self.sparse.remove(entity.id)
            let last = self.dense_data.len() - 1
            if idx != last:
                self.dense_entities.swap(idx, last)
                self.dense_data.swap(idx, last)
                self.sparse.insert(self.dense_entities[idx], idx)
            let _ = self.dense_entities.pop()
            let _ = self.dense_data.pop()

    fn contains(self: &InputStateStorage, entity: Entity) -> bool:
        self.sparse.contains_key(entity.id)

    fn len(self: &InputStateStorage) -> i32: self.dense_data.len()

    fn clear(self: &mut InputStateStorage):
        self.dense_entities.clear()
        self.dense_data.clear()
        self.sparse.clear()
