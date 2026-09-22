module ecs.storage

use std.collections.HashMap
use components.Entity

// DenseStorage[T] is a sparse-set component container. Components are
// stored in contiguous arrays (dense), with a hash map for entity
// lookup (sparse). Iteration is O(n) where n = stored components.
//
// This is the standard ECS storage pattern: cache-friendly iteration
// with O(1) random access by entity handle.
//
// Element access observes; `remove` transfers (D27): `get` returns a
// view of the stored component and `remove` returns the component.

pub type DenseStorage[T] {
    dense_entities: Vec[i32],
    dense_data: Vec[T],
    sparse: HashMap[i32, i32],
}

pub fn DenseStorage.new[T]() -> DenseStorage[T]:
    DenseStorage {
        dense_entities: Vec.new(),
        dense_data: Vec.new(),
        sparse: HashMap.new(),
    }

extend[T] DenseStorage[T]:
    // `-> Unit` is the answer D43 asks for: the tail `if`'s arms are an
    // assignment (a value of type T) and a push (Unit), so an unannotated
    // return type would have two meanings.
    pub mut fn insert(entity: Entity, component: T) -> Unit:
        if entity.id in self.sparse:
            // An independent index, not a view into the map we are about
            // to mutate (D22 contextual Copy).
            let idx: i32 = self.sparse.get(entity.id).unwrap()
            self.dense_data[idx] = component
        else:
            self.sparse.insert(entity.id, self.dense_data.len())
            self.dense_entities.push(entity.id)
            self.dense_data.push(component)

    pub fn get(entity: Entity) -> Option[&T]:
        let idx = self.sparse.get(entity.id) ?? return None
        Some(self.dense_data.get(idx))

    // Transfers the component out (`Vec.remove`, D27) and re-indexes the
    // entities that shifted down behind it.
    pub mut fn remove(entity: Entity) -> Option[T]:
        let idx: i32 = self.sparse.remove(entity.id) ?? return None
        self.dense_entities.remove(idx)
        for i in idx..self.dense_entities.len():
            let eid: i32 = self.dense_entities[i]
            self.sparse.insert(eid, i)
        Some(self.dense_data.remove(idx))

    pub fn contains(entity: Entity) -> bool: entity.id in self.sparse

    pub fn len() -> i32: self.dense_data.len()

    pub mut fn clear():
        self.dense_entities.clear()
        self.dense_data.clear()
        self.sparse.clear()
