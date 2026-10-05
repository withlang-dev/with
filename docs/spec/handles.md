# 6. Handles and Generational Arenas

### 6.1 Handles

A handle is a typed index with a generation counter.

```
type Handle[T] { index: u32, generation: u32 }
    with Copy, Eq
```

Handles are `Copy`, type-parameterized (`Handle[Texture]` incompatible
with `Handle[Mesh]`), not an ownership relationship, and safe against
use-after-remove (generation mismatch returns `None`).

### 6.2 SlotMap (Standard Library Requirement)

The standard library must provide:

```
type SlotMap[T]
```

| Method | Signature | Notes |
|--------|-----------|-------|
| `insert` | `(mut self: Self, T) -> Handle[T]` | |
| `get` | `(self: &Self, Handle[T]) -> Option[&T]` | Ephemeral return |
| `slot` | Scoped via `with sm.slot(h) as mut s:` | Place-based mutation |
| `remove` | `(mut self: Self, Handle[T]) -> Option[T]` | |
| `replace` | `(mut self: Self, Handle[T], T) -> Option[T]` | |
| `for_each` | `(self: &Self, fn(Handle[T], &T))` | |
| `get_disjoint` | `with sm.get_disjoint(h1, h2) as mut (a, b):` | Panics if equal |
| `contains` | `(&Self, Handle[T]) -> bool` | |
| `len` | `(&Self) -> Int` | signed (D11) |

### 6.3 Performance Characteristics

A handle dereference involves: one array index lookup, one bounds
check (branch, usually predicted), and one generation comparison
(branch, usually predicted). This is roughly 2-3ns per access versus
~0.3ns for a raw pointer dereference.

For bulk operations, use `for_each` / `iter` which amortize the
per-element overhead. In rare hot paths where handle indirection is
measurably costly, `unsafe` raw pointer access is available.

The trade-off is explicit: **safety over raw pointer speed** for
individual accesses, with batch iteration as the escape hatch for
performance-critical loops.

---
