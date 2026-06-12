// std.alloc — first-class allocation helpers built on std.mem.

use std.mem

fn alloc_default_block_size(size: i32) -> i32:
    if size > 0: size else: 4096

fn alloc_align16(size: i32) -> i32:
    let n = if size > 0: size else: 1
    ((n + 15) / 16) * 16

fn alloc_max_i32(a: i32, b: i32) -> i32:
    if a > b: a else: b

fn alloc_mark_unit() -> i64:
    1000000000

pub type Arena {
    block_size: i32,
    blocks: Vec[i64],
    block_sizes: Vec[i32],
    current: *i8,
    offset: i32,
    capacity: i32,
    high_water_bytes: i64,
}

pub type FrameArena {
    block_size: i32,
    blocks: Vec[i64],
    block_sizes: Vec[i32],
    current: *i8,
    offset: i32,
    capacity: i32,
    high_water_bytes: i64,
}

type TempArena {
    allocations: Vec[i64],
}

@[no_await_guard]
pub type ArenaScope ephemeral {
    arena: Arena,
    mark: i64,
    allocations: i32,
}

pub type Pool {
    item_size: i32,
    slab_capacity: i32,
    slabs: Vec[i64],
    free_list: Vec[i64],
}

pub type PoolAllocator {
    pool: Pool,
}

pub type ArenaVec[T] ephemeral {
    arena: *mut Arena,
    ptr: *mut T,
    len_value: i32,
    cap_value: i32,
}

pub fn arena_new(block_size: i32) -> Arena:
    Arena {
        block_size: alloc_default_block_size(block_size),
        blocks: Vec.new(),
        block_sizes: Vec.new(),
        current: 0 as *i8,
        offset: 0,
        capacity: 0,
        high_water_bytes: 0,
    }

pub fn frame_arena_new(block_size: i32) -> FrameArena:
    FrameArena {
        block_size: alloc_default_block_size(block_size),
        blocks: Vec.new(),
        block_sizes: Vec.new(),
        current: 0 as *i8,
        offset: 0,
        capacity: 0,
        high_water_bytes: 0,
    }

fn Arena.add_block(mut self: Arena, min_size: i32):
    let base = alloc_max_i32(self.block_size, alloc_align16(min_size))
    let grown = if self.capacity > 0: self.capacity * 2 else: base
    let size = alloc_max_i32(base, grown)
    let ptr = alloc(size)
    self.blocks.push(ptr as i64)
    self.block_sizes.push(size)
    self.current = ptr
    self.offset = 0
    self.capacity = size

fn FrameArena.add_block(mut self: FrameArena, min_size: i32):
    let base = alloc_max_i32(self.block_size, alloc_align16(min_size))
    let grown = if self.capacity > 0: self.capacity * 2 else: base
    let size = alloc_max_i32(base, grown)
    let ptr = alloc(size)
    self.blocks.push(ptr as i64)
    self.block_sizes.push(size)
    self.current = ptr
    self.offset = 0
    self.capacity = size

pub fn Arena.alloc(mut self: Arena, size: i32) -> *i8:
    let n = alloc_align16(size)
    if self.current as i64 == 0 or self.offset + n > self.capacity:
        self.add_block(n)
    let out = (self.current as i64 + self.offset as i64) as *i8
    self.offset = self.offset + n
    var used = self.offset as i64
    let block_count = self.blocks.len() as i32
    if block_count > 1:
        for i in 0..block_count - 1:
            used = used + self.block_sizes.get(i as i64) as i64
    if used > self.high_water_bytes:
        self.high_water_bytes = used
    out

pub fn FrameArena.alloc(mut self: FrameArena, size: i32) -> *i8:
    let n = alloc_align16(size)
    if self.current as i64 == 0 or self.offset + n > self.capacity:
        self.add_block(n)
    let out = (self.current as i64 + self.offset as i64) as *i8
    self.offset = self.offset + n
    var used = self.offset as i64
    let block_count = self.blocks.len() as i32
    if block_count > 1:
        for i in 0..block_count - 1:
            used = used + self.block_sizes.get(i as i64) as i64
    if used > self.high_water_bytes:
        self.high_water_bytes = used
    out

pub fn Arena.alloc_zeroed(mut self: Arena, count: i32, size: i32) -> *i8:
    let total = if count > 0 and size > 0: count * size else: 1
    let ptr = self.alloc(total)
    mem_set(ptr, 0, total as i64)
    ptr

pub fn FrameArena.alloc_zeroed(mut self: FrameArena, count: i32, size: i32) -> *i8:
    let total = if count > 0 and size > 0: count * size else: 1
    let ptr = self.alloc(total)
    mem_set(ptr, 0, total as i64)
    ptr

pub fn Arena.mark(self: &Arena) -> i64:
    let block_index = self.blocks.len() as i64 - 1
    if block_index < 0:
        return 0
    block_index * alloc_mark_unit() + self.offset as i64

pub fn Arena.reset_to(mut self: Arena, mark: i64) -> Unit:
    let block_index = mark / alloc_mark_unit()
    let mark_offset = (mark - block_index * alloc_mark_unit()) as i32
    let n = self.blocks.len() as i32
    var new_blocks: Vec[i64] = Vec.new()
    var new_sizes: Vec[i32] = Vec.new()
    for i in 0..n:
        let raw = self.blocks.get(i as i64)
        let size = self.block_sizes.get(i as i64)
        if i as i64 <= block_index:
            new_blocks.push(raw)
            new_sizes.push(size)
        else if raw != 0:
            free_mem(raw as *i8)
    self.blocks = new_blocks
    self.block_sizes = new_sizes
    if self.blocks.len() > 0:
        let last = self.blocks.len() as i32 - 1
        self.current = self.blocks.get(last as i64) as *i8
        self.capacity = self.block_sizes.get(last as i64)
        self.offset = if mark_offset >= 0 and mark_offset <= self.capacity: mark_offset else: 0
    else:
        self.current = 0 as *i8
        self.offset = 0
        self.capacity = 0

pub fn Arena.reset(mut self: Arena) -> Unit:
    if self.blocks.len() == 0:
        return
    let mark = 0
    self.reset_to(mark)

pub fn FrameArena.reset(mut self: FrameArena) -> Unit:
    if self.blocks.len() == 0:
        return
    let first = self.blocks.get(0)
    let first_size = self.block_sizes.get(0)
    for i in 1..self.blocks.len() as i32:
        let raw = self.blocks.get(i as i64)
        if raw != 0:
            free_mem(raw as *i8)
    let new_blocks: Vec[i64] = Vec.new()
    let new_sizes: Vec[i32] = Vec.new()
    new_blocks.push(first)
    new_sizes.push(first_size)
    self.blocks = new_blocks
    self.block_sizes = new_sizes
    self.current = first as *i8
    self.capacity = first_size
    self.offset = 0

pub fn Arena.drop(mut self: Arena) -> Unit:
    for raw in self.blocks:
        if raw != 0:
            free_mem(raw as *i8)
    self.blocks = Vec.new()
    self.block_sizes = Vec.new()
    self.current = 0 as *i8
    self.offset = 0
    self.capacity = 0

pub fn FrameArena.drop(mut self: FrameArena) -> Unit:
    for raw in self.blocks:
        if raw != 0:
            free_mem(raw as *i8)
    self.blocks = Vec.new()
    self.block_sizes = Vec.new()
    self.current = 0 as *i8
    self.offset = 0
    self.capacity = 0

pub fn FrameArena.high_water(self: &FrameArena) -> i64:
    self.high_water_bytes

pub fn Arena.scope(self: Arena) -> ArenaScope:
    let mark = self.mark()
    ArenaScope { arena: self, mark, allocations: 0 }

pub fn ArenaScope.alloc(mut self: ArenaScope, size: i32) -> *i8:
    let ptr = self.arena.alloc(size)
    self.allocations = self.allocations + 1
    ptr

pub fn ArenaScope.alloc_zeroed(mut self: ArenaScope, count: i32, size: i32) -> *i8:
    let ptr = self.arena.alloc_zeroed(count, size)
    self.allocations = self.allocations + 1
    ptr

pub fn ArenaScope.reset(mut self: ArenaScope) -> Unit:
    self.arena.reset_to(self.mark)
    self.allocations = 0

pub fn ArenaScope.drop(mut self: ArenaScope) -> Unit:
    self.arena.drop()
    self.allocations = 0

pub fn ArenaScope.allocation_count(self: &ArenaScope) -> i32:
    self.allocations

pub fn arena_alloc(mut arena: Arena, size: i32) -> *i8:
    arena.alloc(size)

pub fn arena_alloc_zeroed(mut arena: Arena, count: i32, size: i32) -> *i8:
    arena.alloc_zeroed(count, size)

pub fn arena_free(arena: Arena, ptr: *i8) -> Unit:
    let _ = arena
    let _ = ptr

pub fn arena_reset(mut arena: Arena) -> Unit:
    arena.reset()

pub fn scratch_arena() -> TempArena:
    TempArena { allocations: Vec.new() }

pub fn TempArena.alloc(mut self: TempArena, size: i32) -> *i8:
    let ptr = alloc(if size > 0: size else: 1)
    self.allocations.push(ptr as i64)
    ptr

pub fn TempArena.alloc_zeroed(mut self: TempArena, count: i32, size: i32) -> *i8:
    let ptr = alloc_zeroed(count, size)
    self.allocations.push(ptr as i64)
    ptr

pub fn TempArena.reset(mut self: TempArena) -> Unit:
    for raw in self.allocations:
        if raw != 0:
            free_mem(raw as *i8)
    self.allocations = Vec.new()

pub fn TempArena.drop(mut self: TempArena) -> Unit:
    self.reset()

fn pool_effective_item_size(size: i32) -> i32:
    let base = if size > 0: size else: 1
    alloc_align16(alloc_max_i32(base, 8))

fn Pool.add_slab(mut self: Pool):
    let count = if self.slab_capacity > 0: self.slab_capacity else: 1
    let total = self.item_size * count
    let slab = alloc(total)
    self.slabs.push(slab as i64)
    for i in 0..count:
        self.free_list.push((slab as i64 + (i * self.item_size) as i64))

pub fn pool_new(item_size: i32, capacity: i32) -> Pool:
    var pool = Pool {
        item_size: pool_effective_item_size(item_size),
        slab_capacity: if capacity > 0: capacity else: 1,
        slabs: Vec.new(),
        free_list: Vec.new(),
    }
    pool.add_slab()
    pool

pub fn PoolAllocator.new(item_size: i32, capacity: i32) -> PoolAllocator:
    PoolAllocator { pool: pool_new(item_size, capacity) }

pub fn Pool.alloc(mut self: Pool) -> *i8:
    if self.free_list.len() == 0:
        self.add_slab()
    let last = self.free_list.len() as i32 - 1
    let raw = self.free_list.get(last as i64)
    self.free_list.remove(last as i64)
    raw as *i8

pub fn Pool.free(mut self: Pool, ptr: *i8) -> Unit:
    if ptr as i64 != 0:
        self.free_list.push(ptr as i64)

pub fn Pool.drop(mut self: Pool) -> Unit:
    for raw in self.slabs:
        if raw != 0:
            free_mem(raw as *i8)
    self.slabs = Vec.new()
    self.free_list = Vec.new()

pub fn PoolAllocator.alloc(mut self: PoolAllocator) -> *i8:
    self.pool.alloc()

pub fn PoolAllocator.free(mut self: PoolAllocator, ptr: *i8) -> Unit:
    self.pool.free(ptr)

pub fn PoolAllocator.drop(mut self: PoolAllocator) -> Unit:
    self.pool.drop()

pub fn pool_alloc(mut pool: Pool) -> *i8:
    pool.alloc()

pub fn pool_free(mut pool: Pool, ptr: *i8) -> Unit:
    pool.free(ptr)

pub fn arena_vec_new_in[T](arena: *mut Arena) -> ArenaVec[T]:
    ArenaVec { arena: arena, ptr: 0 as *mut T, len_value: 0, cap_value: 0 }

pub unsafe fn arena_vec_len[T](xs: *const ArenaVec[T]) -> i32:
    (*xs).len_value

unsafe fn arena_vec_grow[T](xs: *mut ArenaVec[T]):
    let cap = (*xs).cap_value
    let new_cap = if cap < 8: 8 else: cap * 2
    let bytes = new_cap * (sizeof[T]() as i32)
    let arena = (*xs).arena
    let next = unsafe { (*arena).alloc(bytes) } as *mut T
    let ptr = (*xs).ptr
    let len = (*xs).len_value
    if ptr as i64 != 0 and len > 0:
        mem_copy(next as *i8, ptr as *i8, (len * (sizeof[T]() as i32)) as i64)
    ((*xs).ptr = next)
    ((*xs).cap_value = new_cap)

pub unsafe fn arena_vec_push[T](xs: *mut ArenaVec[T], value: T) -> Unit:
    if (*xs).len_value >= (*xs).cap_value:
        arena_vec_grow(xs)
    let len = (*xs).len_value
    let dst = (*xs).ptr + (len as usize)
    mem_copy(dst as *i8, &value as *const T as *i8, sizeof[T]() as i64)
    ((*xs).len_value = len + 1)

pub unsafe fn arena_vec_get[T](xs: *const ArenaVec[T], index: i32) -> T:
    if index < 0 or index >= (*xs).len_value:
        panic("ArenaVec index out of bounds")
    unsafe *((*xs).ptr + (index as usize))
