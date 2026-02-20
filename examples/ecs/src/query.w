module ecs.query

use ecs.storage.DenseStorage

// Query generators — lazy iteration over entities that have
// specific component combinations. These are the read-only
// query primitives; mutable access uses direct array iteration
// in systems (see systems.w) for maximum clarity.
//
// Each generator iterates the first storage and probes the
// others, yielding only entities present in all storages.
// Generators are ephemeral (they borrow the storages), so
// they live in local scope — ideal for pipeline composition.

// --- Single-component query ---

gen fn query1[A](
    a: &DenseStorage[A],
) -> (Entity, &A) =
    for i in 0..a.len():
        yield (a.dense_entities[i], &a.dense_data[i])

// --- Two-component join ---

gen fn query2[A, B](
    a: &DenseStorage[A],
    b: &DenseStorage[B],
) -> (Entity, &A, &B) =
    for i in 0..a.len():
        let entity = a.dense_entities[i]
        if let Some(b_val) = b.get(entity):
            yield (entity, &a.dense_data[i], b_val)

// --- Three-component join ---

gen fn query3[A, B, C](
    a: &DenseStorage[A],
    b: &DenseStorage[B],
    c: &DenseStorage[C],
) -> (Entity, &A, &B, &C) =
    for i in 0..a.len():
        let entity = a.dense_entities[i]
        if let Some(b_val) = b.get(entity):
            if let Some(c_val) = c.get(entity):
                yield (entity, &a.dense_data[i], b_val, c_val)

// --- Query with exclusion (entities that have A but NOT B) ---

gen fn query_without[A, B](
    a: &DenseStorage[A],
    b: &DenseStorage[B],
) -> (Entity, &A) =
    for i in 0..a.len():
        let entity = a.dense_entities[i]
        if not b.contains(entity):
            yield (entity, &a.dense_data[i])

// --- Count matching entities ---

fn count2[A, B](a: &DenseStorage[A], b: &DenseStorage[B]) -> usize =
    var n: usize = 0
    for i in 0..a.len():
        if b.contains(a.dense_entities[i]):
            n += 1
    n
