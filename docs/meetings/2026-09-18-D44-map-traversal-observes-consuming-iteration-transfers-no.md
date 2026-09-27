# D44 — Map traversal observes; consuming iteration transfers; no operation on a map makes a second owner

**Date:** 2026-09-18. **Status:** ruled (Eric, "make it canon"); specification
§2.3, §13.3, §13.5, §4 (the iteration example) and §22.1 rule 7 blessed
verbatim the same day. The compiler is NON-COMPLIANT until the
implementation lands (list below). **Issues:** #1158, #1187.

**Ruling.** `for (k, v) in map` is `map.iter()` and binds `k: &K`, `v: &V`.
`keys()`, `values()` and `iter()` return concrete ephemeral iterator structs
(§13.1) yielding views whose origin is the map. Transfer has its own names:
`remove`, `drain`, `into_iter`, `into_keys`, `into_values`. An independent
collection is spelled where it is wanted — `m.keys() |> map(it.clone()) |>
collect[Vec]()` — because it allocates and needs `Clone`; a typed binding
never collects (`let ks: Vec[K] = m.keys()` is a type error). `items()` is
retired: `iter()` is the one traversal, and it is what `for` already names.

Underneath it, §2.3 now says **transport is not duplication**: the compiler
may move a value's bytes wherever ownership moves, and never produces a
second live value from one unless the type is `Copy` — a rule that binds
intrinsics, runtime helpers and generated code exactly as it binds user code.

**Why.** None of the seven references creates a second owner, and every
language without a collector hands out views with a separately named
transfer. (Verified in `.reference/`: Rust `keys(&self) -> Keys<'_>`,
`IntoIterator for &HashMap` yields `(&K, &V)`, `into_keys`/`drain` transfer;
Mojo `keys()/values()/items()` yield `ref[origin]` "as immutable references",
`take_items()` drains; Zig `Entry{ key_ptr, value_ptr }` and
`ArrayHashMap.keys() []K` into the backing array; Vale `values() ->
Array<mut, &V>` and keys only for `K Ref imm`; Scala 3 `keys:
Iterable[K]^{this}` — a view whose capture set names the map; Swift `Keys`
is "a view of a dictionary's keys"; Go `range` and `maps.Keys` copy, safely
only because a collector owns the memory.) With has no collector and no
transparent reference counts (§1.5), so a copy of an owning value is a second
owner — the defect the mission names.

**Context.** The built-in `HashMap`'s `keys()`/`values()`/`items()` byte-copied
their elements through `with_hashmap_{keys,values,items}_out`. For a non-`Copy`
element the returned `Vec` and the map owned the same buffers: the compiler's
own `sema_clone_str_str_hashmap` double-freed through `.keys()` while building
the OpenSSL UAT project (#1158; allocator verdict `DOUBLE FREE size=64`, second
free `with_hashmap_free` from `Zcu.compile_source_frontend_mode`), and a plain
run stayed "ok" while `WITH_DEBUG_ALLOC_SCRIBBLE=1` corrupted the map in all
three modes. `for (k, v) in map` lowered through the same `MAP_ITEMS`
intrinsic and left the map empty — `m.len()` printed 0, `m.get` segfaulted,
`with check` said ok (#1187) — against §13.5's "the collection remains valid
after the loop".

**Alternatives rejected.**
- *Snapshots clone, iteration observes (keep `keys() -> Vec[K]`).* Correct,
  and the stdlib's Vec-backed map already does it, but `m.keys()` would hide
  an O(n) clone behind a name that reads as "look", would need `Clone` to
  look at all, and would break the signature a second time when views land.
  The caller count made the break nearly free now: five call sites in `src/`
  (four on `i32` keys, one the crash site), none in `lib/`, `tools/` or
  `build/`, 23 in `test/`. D39 makes a shipped `.wi` signature a contract, so
  it only gets more expensive.
- *Clone everywhere.* Every pass over a `HashMap[str, V]` would allocate and
  free each key and value; contradicts §13.5 and D22/D27.
- *Collect by owned demand* (`let ks: Vec[K] = m.keys()` clones). §3.8
  materializes `Copy` because a copy is free; extending it to `Clone` would
  let an annotation cause an O(n) allocation.
- *`clone_keys()`-style names.* With already spells the three meanings:
  observe (`keys()`), collect (`|> collect[Vec]()`), consume (`into_*`, D33).
- *`keys() -> Vec[&K]`.* Not writable: the compiler rejects the bare spelling
  `Vec[&T]` even as a local.

**Mission fit (mission.md ¶2).** Looking, copying and taking are three
meanings; each has its own visible spelling, and nothing allocates unless its
name says so. "Memory is the first resource… owned from the moment it is
made": a second owner made by the compiler is the defect, whatever the API.

**Non-compliance to retire** (the implementation plan):
1. The intrinsics byte-copy non-`Copy` elements (§2.3). Fix first, as a
   defect, alone in its batch with `:move-audit`/`:drop-audit`.
2. `for (k, v) in map` empties the map and binds owned values; `for … in &m`
   and iteration over a `&HashMap` parameter leave the pattern variables
   unbound; `let a: &str = k` inside the loop is invalid MIR (#1187).
3. `keys()`/`values()` return `Vec`; `iter`, `into_*` and `drain` on maps do
   not exist; `items()` exists. The stdlib Vec-backed map changes in the same
   commit as the intrinsics so the two never disagree.
4. The compiler rejects `Vec[&T]` while accepting the equivalent
   `Vec[Wrapper{&T}]`; §22.1 rules 3 and 7 make both legal as ephemeral
   values. Separate fix; the `sorted` example in §13.3 depends on it.
5. The ownership audit and `--validate-all` passed all of the above (#1159).

**Reopen if** a real corpus shows `|> map(it.clone()) |> collect[Vec]()` is
written often enough to be ceremony; the answer then is a named collecting
form, not collection by demand.
