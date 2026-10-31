# D176 — D172's marker type is `std.memo`'s `Interior[T]`, beside `Memo[K, V]` (delegated)

**Date:** 2026-10-30. **Status:** delegated (D98): only the name and home of
the marker are decided here; D172 and §19.1 rule what it is and does.

**Context.** D172 rules that read-path caches use `std`'s `Memo[K, V]`, built
on "a compiler-known marker type for interior mutability", and §19.1 states
the marker's contract without naming it. Implementing step 6 needs a name
and a module.

**Decision.** The marker is `Interior[T]`, declared in `std.memo` with
`Memo`. The compiler knows it by declaration (the type named `Interior`
declared in `lib/std/memo.w`), never by a name alone. `Interior.new` and
`Interior.ptr` are `unsafe fn`s and its one field is private, so constructing
or reaching into it is `unsafe` (§19.1).

**Alternatives.** `UnsafeCell` (Rust's name; With does not take Rust's
spelling for its own concepts, and the unsafety is already in the
signatures); `Cell` (Rust's `Cell` is safe, so the name would mislead);
a separate `std.cell` module (one type with one user does not need a module;
`Memo` is the safe abstraction and the marker lives beside it).

**Prediction.** Eric accepts `Interior` in `std.memo` (75%); the likeliest
veto is a different word, which is a rename of one type and its compiler
recognition (`sema_path_is_std_memo_module`, `type_decl_is_interior_marker`).

**Reopen if** a second safe abstraction over the marker appears outside
`std.memo` (then the marker moves to its own module).
