module ecs.storage

use std.collections.HashMap

// DenseStorage is a sparse-set component container. Components are
// stored in contiguous arrays (dense), with a hash map for entity
// lookup (sparse). Iteration is O(n) where n = stored components.
//
// This is the standard ECS storage pattern: cache-friendly iteration
// with O(1) random access by entity handle.

type DenseStorage[T] = {
    dense_entities: Vec[Entity],
    dense_data: Vec[T],
    sparse: HashMap[Entity, usize],
}

extend DenseStorage[T]:
    fn new:
        DenseStorage {
            dense_entities: Vec.new(),
            dense_data: Vec.new(),
            sparse: HashMap.new(),
        }

    fn insert(self: &mut DenseStorage[T], entity: Entity, component: T):
        match self.sparse.get(&entity)
            Some(&idx) ->
                self.dense_data[idx] = component
            None ->
                self.sparse.insert(entity, self.dense_data.len())
                self.dense_entities.push(entity)
                self.dense_data.push(component)

    fn get(self: &DenseStorage[T], entity: Entity) -> Option[&T]:
        self.sparse.get(&entity).map(|&idx| &self.dense_data[idx])

    fn get_mut(self: &mut DenseStorage[T], entity: Entity) -> Option[&mut T]:
        self.sparse.get(&entity).map(|&idx| &mut self.dense_data[idx])

    fn remove(self: &mut DenseStorage[T], entity: Entity) -> Option[T]:
        match self.sparse.remove(&entity)
            Some(idx) ->
                let last = self.dense_data.len() - 1
                if idx != last:
                    self.dense_entities.swap(idx, last)
                    self.dense_data.swap(idx, last)
                    self.sparse.insert(self.dense_entities[idx], idx)
                let _ = self.dense_entities.pop()
                self.dense_data.pop()
            None -> None

    fn contains(self: &DenseStorage[T], entity: Entity) -> bool:
        self.sparse.contains_key(&entity)

    fn len(self: &DenseStorage[T]) -> usize: self.dense_data.len()
    fn is_empty(self: &DenseStorage[T]) -> bool: self.dense_data.is_empty()

    fn clear(self: &mut DenseStorage[T]):
        self.dense_entities.clear()
        self.dense_data.clear()
        self.sparse.clear()

// --- Generators for iteration ---
//
// These produce ephemeral iterators over (Entity, &T) pairs.
// Ephemeral = usable in local pipelines, cannot be stored.
// This is fine — iteration is always a local operation.

gen fn iter[T](storage: &DenseStorage[T]) -> (Entity, &T):
    for i in 0..storage.dense_data.len():
        yield (storage.dense_entities[i], &storage.dense_data[i])

gen fn iter_mut[T](storage: &mut DenseStorage[T]) -> (Entity, &mut T):
    for i in 0..storage.dense_data.len():
        yield (storage.dense_entities[i], &mut storage.dense_data[i])
