# 8. Memory Management

### 8.1 No Garbage Collector

Memory is freed deterministically when owners go out of scope.

### 8.2 No Transparent Reference Counting

Reference counting exists only when explicitly used:
- `Rc[T]` — single-threaded
- `Arc[T]` — thread-safe

No hidden refcount operations.

### 8.3 Allocators

First-class. Standard library provides:
- `Arena` — region-based; all allocations freed at once
- `FrameArena` — resets each frame
- `PoolAllocator` — fixed-size blocks

Standard containers accept an optional allocator parameter.

**Ephemeral virality with allocators:** If a container is initialized
with a borrowed allocator (`&Arena`), the container stores the
reference internally and becomes **ephemeral** (§5.2). This means
it cannot be stored in structs, and returning it follows §5.2's
ephemerality propagation (the caller's binding inherits the borrow;
rejected if the allocator's lifetime cannot cover it):

```
fn example(arena: &FrameArena):
    // List borrows the arena → ephemeral
    var candidates = List.new_in(arena)
    candidates.push(1)           // OK: used as local
    // candidates cannot escape this scope

    // For storable containers, use an owned allocator handle:
    var stored = List.new_in(Rc.clone(&shared_arena))
    // stored is NOT ephemeral — it owns its allocator handle
```

This is a deliberate consequence of the ephemeral system: borrowed
resources create ephemeral containers, owned resources create
storable ones. The compiler enforces this automatically.

### 8.3a Temporary Arenas

`std.alloc` provides `TempArena` for short-lived scratch allocation:

```
use std.alloc

let scratch = scratch_arena()
with scratch as mut arena:
    let bytes = arena.alloc(1024)
    use_scratch(bytes)
```

`scratch_arena()` returns a fresh `TempArena`. `TempArena.alloc(size)`
and `TempArena.alloc_zeroed(count, size)` allocate raw memory and
record it in the arena. `TempArena.reset()` frees all allocations made
through that arena and clears the allocation list. `TempArena` also has
a destructor that calls `reset()`, so a scoped arena created for a
block releases its allocations when the arena value goes out of scope.

`TempArena` is distinct from the longer-lived arena types:

| Type | Reset authority | Primary use case |
|------|-----------------|------------------|
| `Arena` | User-controlled reset/drop | Long-lived region allocation |
| `FrameArena` | External reset per frame/tick | Game loops, render passes |
| `TempArena` | Lexical owner scope or explicit `reset()` | Scratch computation |

References or containers that borrow arena-backed storage follow the
normal ephemeral rules: they cannot be stored somewhere that outlives
the arena scope.

### 8.4 Convenience Type

```
type Shared[T] = Arc[RwLock[T]]
```

Usable with `with` blocks for scoped access.

---
