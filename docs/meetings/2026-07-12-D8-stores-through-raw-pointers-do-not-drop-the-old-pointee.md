# D8 — Stores through raw pointers do not drop the old pointee

**Date:** 2026-07-12
**Status:** Accepted

### The decision

Assignment through a raw-pointer deref or index (`*p = v`, `p[i] = v` with
`p: *const T` / `*mut T`) is a **raw store**: the compiler does not emit
drop-before-overwrite for the old pointee. Replacing a live pointee is the
programmer's job in unsafe code: `let old = *p; drop(old)` then store.
Safe places — `var` bindings (§2.2), `&mut` derefs, fields — keep
drop-before-overwrite. A **field** store through a raw deref
(`(*p).f = v`) also keeps it: projecting a field asserts a live pointee,
so the old field value is provably live.

### Context / why

`Box.new`, `Rc.new`, `Mutex.new/set`, `RwLock.new/write`, and the
ScopedMut write-backs all store through raw pointers into memory that is
either freshly allocated (uninitialized) or already moved out. The niche
model's justification for drop-on-reassign (§2.5.1: every source is a live
value or a blanked one) does not hold there — fresh heap bytes are neither.
The emitted guarded drop then runs `Drop` on garbage whenever the allocator
returns non-zero recycled memory: observed as `State.drop` firing at
`box_ctx` time (spec_ss16_7) and `Mutex.set`/`RwLock.write` dropping the
replaced payload twice (spec_ss14_17_*, "oldold" traces). Every raw-store
site in the stdlib/runtime was audited: none relies on the old drop
semantics; `sync.w` already drops the old value explicitly before storing.

Alternative weighed: keep Rust's rule (`*p = v` drops; add a
`ptr::write`-style no-drop primitive). Rejected: it silently invokes drop
glue on memory the compiler cannot prove initialized (UB-by-default in the
common fresh-allocation case), contradicts every existing stdlib site, and
adds a primitive the mission says the programmer shouldn't need. "Raw C
stays explicit": a raw store stores.

Reopen if: With grows an initializedness proof for raw pointees, or a
`ptr::write`/`ptr::replace` surface makes the explicit-drop idiom obsolete.

---
