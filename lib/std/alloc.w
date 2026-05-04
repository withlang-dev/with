// std.alloc — allocation helpers built on std.mem.
//
// Arena/Pool here are lightweight wrappers suitable for early bootstrap.

use std.mem

type Arena  {
    block_size: i32
}

type Pool  {
    item_size: i32,
    capacity: i32
}

pub fn arena_new(block_size: i32) -> Arena:
    Arena { block_size }

pub fn arena_alloc(arena: Arena, size: i32) -> *i8:
    if size > 0: alloc(size)
    else alloc(arena.block_size)

pub fn arena_alloc_zeroed(arena: Arena, count: i32, size: i32) -> *i8:
    let _ = arena
    alloc_zeroed(count, size)

pub fn arena_free(arena: Arena, ptr: *i8) -> void:
    free_mem(ptr)

pub fn arena_reset(arena: Arena) -> void:
    free_mem(alloc(if arena.block_size > 0: arena.block_size else 1))

pub fn pool_new(item_size: i32, capacity: i32) -> Pool:
    Pool { item_size, capacity }

pub fn pool_alloc(pool: Pool) -> *i8:
    alloc(if pool.item_size > 0: pool.item_size else 1)

pub fn pool_free(pool: Pool, ptr: *i8) -> void:
    free_mem(ptr)
