# 20. Performance Guarantees

1. **Allocation is attributable.** Allocation need not be spelled as
   `malloc`, but every allocation must be attributable to a visible
   construct, owning type, explicit allocation API, or compiler-owned
   adapter whose cost model is documented and diagnosable.
2. **Allocation-producing constructs are enumerated.** Examples include
   allocator calls, `Vec.new()`, `.to_owned()`, owned buffer
   constructors, comprehensions, f-strings, owned string literals when
   not elided, `async fn` calls and `async:` blocks that allocate
   fibers/tasks, and modeled FFI temporaries such as call-scoped
   C-string adapters. The construct or owning result type is the signal;
   the language does not force users to spell allocation machinery when
   the intent is already clear.
3. **Allocation cost models are documented.** Each allocation-producing
   construct specifies what may allocate, which allocator or allocation
   policy is used, whether allocation may be elided, what happens on
   allocation failure, and what owns the result. String-literal
   allocation guarantees live in §15.3: `&str` context is guaranteed
   zero-allocation; owned-context elision is an optimization. Fiber
   allocation is legible through `Task` and compiler-visible allocation
   analysis, not call-site coloring.
4. **No invisible allocation obligations.** An allocation must never
   create an invisible ownership, lifetime, cleanup, or caller-must-free
   responsibility. Compiler-generated allocations must be
   compiler-owned with a non-escaping lifetime, or represented by a
   visible owning type whose `Drop` handles cleanup. Hidden caller
   obligations are forbidden. A call-scoped FFI temporary is valid only
   when it cannot escape and the compiler frees it; retained pointers,
   mutable buffers, copy-back, and ownership transfer require modeled
   contracts or visible owning types.
5. **Allocation is checkable.** Allocation-producing constructs are
   visible to compiler diagnostics and no-allocation checking.
   No-allocation contexts, co-designed with the tier and allocator
   model, reject allocating constructs unless the allocation is proven
   elided or routed through an explicit arena, allocator, or capability.
   Conservative false rejection is a compiler-precision bug, not a
   reason to require user ceremony.
6. **No hidden copies.** Values move unless `Copy`.
7. **No hidden reference counting.** Only via explicit `Rc`/`Arc`.
8. **No hidden synchronization.** Locks, atomics always explicit.
9. **No hidden runtime in `no_runtime` builds.** The fiber scheduler
   is the one blessed runtime; it is opt-in via `async` and absent
   when disabled. Suspension is always known to the compiler; ordinary
   call sites are not colored merely because the callee may suspend.
10. **Deterministic destruction.** Reverse declaration order.
11. **Disjoint borrow analysis guaranteed.**

---
