# D54 — In-place foreign resources are pinned by default; `movable` is the facade's claim; a heap cell, never an immovable type

**Laws:** 4, 6 (docs/mission.md).

**Date:** 2026-09-22. **Status:** BDFL ruling (Eric); spec §16.2b.3 carries
the normative sentences. Extends D51; the D51 ruling document is not
amended (it is silent on address stability).

**Decision.** An in-place resource (a by-value C representation with
`init`) is pinned: the representation has one address from the creation of
the resource value until foreign destruction completes. The facade may
declare it `movable` only on trusted evidence that no operation retains the
representation's address — the same evidence weight as `ok`, never
inferred. The renderer implements pinning as a heap cell owned by the
resource value: the value stays an ordinary movable With value; every
`self` pointer handed to C points into the cell; on drop the destruction
operation runs first and the cell is freed after (the cell outlives the C
state, never the reverse); the zeroed/`preinit` states apply to the cell's
contents, and the cell exists from the construction of the resource value,
so an "allocated, not live" resource already has its stable address (zlib's
`inflateInit` keeps the address it is called with); raw and borrowed access
yields a pointer into the cell, valid for the borrow regardless of moves of
the value — a rule the checker enforces, not only the renderer. Pinning
covers the representation's own storage only: `z_stream.next_in`/`next_out`
point at user buffers, a dependency question (§16.2b.6), not an
address-stability one.

**Why pinned by default.** The compiler cannot infer whether `init` stores a
back-pointer, so the facade states it either way, and the costs are
asymmetric: a needlessly pinned resource costs one heap allocation; a
needlessly movable one is silent memory corruption after the first move. The
needs-pinning class is larger than zlib — `pthread_mutex_t` and
`pthread_cond_t` are UB to move after init per POSIX, `sqlite3_vfs`, libuv's
`uv_*_t` watchers keep loop and list pointers, some OpenSSL contexts — while
the movable class (hash contexts, stat buffers, `struct tm`) is mostly plain
data that is not a resource at all. "Never half-model unsafely" is met when
the unstated default is the safe one.

**Why a heap cell and not an immovable type.** "Constructed in its final
place and cannot be moved" would add an immovable type category to the
language; Rust's `Pin` took years and remains its most misunderstood API,
and With's pitch is one kind of value. One allocation per stream is what
`flate2` pays; zero-allocation placement (arena, struct field) can come
later as an optimization invisible to users, because the semantics are
already "address stable".

**Reopens if** a measured hot path needs placement without an allocation —
that is the invisible optimization above, not a change of rule.

---
