# D120 implementation plan: collections and structs of values are values

**Ruling:** `docs/meetings/2026-10-09-D120-collections-and-structs-of-values-are-values.md`
(Eric, 2026-10-09). Spec: §2.3 (ownership.md), §4.3 (types.md). This
document is a derivative plan: it cannot amend the ruling, and where they
disagree the ruling stands. `resource type` landed 2026-10-16 (PR #2438),
stage 1 the same day (PR #2440, under Amendment 1), stage 2 (PR #2441),
stage 3 (PR #2442), stage 4 (PR #2444), stage 5 with this change; stage 6
and the final corpus measurements are open.

## What the ruling asks for

1. **Value-ness is compositional.** `List[T]`, `HashMap[K, V]`,
   `HashSet[T]` and `BTreeMap[K, V]` are values when their elements are;
   a struct is a value when every field is a value, it has no `Drop` and
   is not `resource type`. A value is passed by copy (D111): the program
   never sees "use of moved value" on one and never writes `.clone()`.
2. **Copy-on-write with an atomic count in the allocation.** A copy
   shares the buffer under a count; the first mutation of a shared buffer
   copies it. A buffer never shared is mutated in place.
3. **The uniqueness check** sits at mutations the compiler cannot prove
   unique, hoisted out of loops; a list is made unique before a mutable
   pointer into it goes to C; a generic function decides per instantiation.
4. **A report** names where CoW copies can occur.
5. **Merge gate:** self-host compile time and the pcre2 and zlib corpus
   test suites each within 5% (Amendment 1, 2026-10-16; the ruling said
   2%) by interleaved, repeated local A/B. A held
   regression goes to Eric with the numbers and a profile. Three
   microbenchmarks (a push loop through a field, an element write through
   a parameter, share-then-mutate) are tracked, never gating.

## The seams that already exist (the `str` pattern, D111)

- **The count.** A `str` buffer's holders beyond the first live in the
  allocation header's second word (`rt_core.w str_holders`,
  `alloc_store_small_header` zeroes it); `rt_payload_start_is_owned`
  tells an owned payload from a literal or a view. `with_str_retain`,
  `with_str_free_drop_origin` (the release that frees when it finds no
  other holder) and `str_is_unique` are the three operations.
- **Copy glue.** Sema's `is_copy` (Sema.w) says a `str` is Copy and
  `copy_is_bits` separates a bit copy from one with glue. MIR marks a
  consumed copy of a Copy-with-glue type `MIR_HOLD_RETAIN`
  (`MirLower.retain_consumed_copy`); codegen's `mir_emit_copy_glue_ptr`
  emits the retain per type (a `str` retains; a tuple or distinct type
  recurses).
- **Drop glue.** `mir_emit_drop_ptr_for_sema_type` emits the per-type
  release; a `List` drops its elements in a loop and frees the buffer
  (`with_vec_free_*`, `list_alloc_base` with the D115 start offset).
- **The List header** is `{ptr, len, cap, start}` (32 bytes, D115
  Amendment 1); every runtime helper takes the element size. The
  allocation base is `ptr - start × es`, so the holder count sits in that
  allocation's header exactly as a `str`'s does.
- **Mutations** reach the runtime through `MirIntrinsic.LIST_*`
  (SemaTypes.w; dispatched in SemaCheck.w by method name) and the
  `with_vec_*` helpers; `HashMap`/`HashSet` are `ptr` wrappers over the
  `with_hashmap_*` runtime (rt_core.w ~4038); `BTreeMap` is a struct over a
  `List[(K, V)]`, so it follows the struct rule.

## Stages

Each stage is its own PR with its own battery; the gate measurement runs
at the end of stage 3 and again at the end, and a stage that regresses it
holds there.

**Stage 1 — a `List` of bit-copy elements is a value.**
- Runtime: `with_vec_retain(v)`, `with_vec_release_last(v, es) -> bool`
  (decrements; true when this holder was the last, so the caller drops
  elements and frees), `with_vec_make_unique_bits(v, es)` (count > 0 →
  copy the live elements into a fresh buffer, release the old holder).
  The count lives in the allocation header's second word; an empty list
  (`ptr == null`) is trivially unique.
- Sema: `is_copy(List[T])` is `is_copy(T)` (TY_VEC); `type_needs_drop`
  stays true, so a list is Copy with glue, as a `str` is.
- Codegen: `mir_emit_copy_glue_ptr` retains a `List`; the `List` drop
  glue runs its element loop and free only when `release_last` says so.
- MIR: every mutating `LIST_*` intrinsic and every `&mut`/place-mutating
  path on a list operand (push, pop, insert, remove, clear, set, slot,
  iter_place, sort, truncate, extend, swap, retain, dedup, reverse,
  `as_mut_ptr`, a mutable range) is preceded by the make-unique call. No
  hoisting yet: correctness first, the check everywhere.
- Tests: a value list copies (`let b = a; b.push(1)` leaves `a` alone);
  a shared list's drop frees once (debug allocator); a list of resources
  still moves (`err_d116_moved_operand.w` stays); `with_vec_make_unique`
  under WITH_DEBUG_ALLOC.
- The Vec-level `.clone()` sites in `src/` and `lib/std/` keep working
  (a clone of a value is a copy); they are swept in stage 6.

**Stage 2 — elements with glue.** `List[str]`, `List[List[isize]]`,
`List[ValueStruct]`: the copy made by make-unique must run the element
copy glue (a retain per `str`, recursively). Codegen emits a per-type
`list_make_unique[T]` function beside the drop glue it already generates,
with the element copy loop inside; the bits case calls the runtime
directly. `HashMap`/`HashSet`: the runtime map gains the same count and a
`with_hashmap_make_unique` with a key/value copy callback (or codegen
emits the copy loop over `slot_occupied`/`key_ptr_at`); `BTreeMap`
follows from its `List` field.

**Stage 3 — structs of values are values.** `is_copy(TY_STRUCT)` is true
when every field is Copy, the type has no `Drop` and is not `resource
type`, with no `impl Copy` needed (an explicit `impl Copy` stays legal and
redundant; `impl Copy` on a type with a non-Copy field is still refused).
Copy glue for a struct recurses its fields (the tuple path already does).
This is the widest semantic change: every plain struct of values in the
tree stops moving. Expect: code that relied on a move for a last use is
unaffected (the drop plan's last-use facts still turn a copy into a move
with no count traffic); code that counted on "use of moved value" to catch
a mistake loses that check, which is the ruling. **Run the gate
measurement here**, before any hoisting, to see the raw cost.

**Stage 4 — the uniqueness proof and hoisting.** A local that was never
copied from since its creation, assignment or last make-unique is unique;
MIR's place-sensitive move state already tracks the copies, so the fact is
a flag per place cleared by a copy-out and set by a make-unique. A
mutation through a field or parameter keeps the check (the ruling's
"relaxed load and a predictable branch"). Loops: a check whose operand is
loop-invariant (the list place is not copied from inside the loop) is
emitted once before the loop. Measured against stage 3.

**Stage 5 — the C boundary, generics, the report.** A `List` handed to C
as a mutable pointer (`as_mut_ptr`, a facade buffer pairing, `&raw mut`
of an element) is made unique first. A generic instantiation's copy or
move follows `is_copy` of the instantiated type, so `fn f[T](xs: List[T])`
copies for values and moves for resources (an error names only resource
element types). `with analyze file.w cow` reports every mutation site that
keeps a check, with its reason (through a field, through a parameter,
copied in the loop), the analysis the ruling asked for.

**Stage 6 — the sweep.** `.clone()` on value lists and value structs in
`src/`, `lib/std/`, `tools/`, `build/` is ceremony now (the census's
`clone-call`); a `with -p` sweep removes it where the receiver is a
value, and the bar follows at the reseed. Corpora never edited (D112).

## The measurement

`tools/ab_bench.w` (to write, With): builds the candidate and the baseline
compiler (the installed seed's release and the branch's), then runs the
workload N times each, interleaved A B A B …, reporting the median and
the ratio with its spread. Workloads: `with check src/main.w` (self-host
time; `WITH_PROFILE=1` for the profile when it regresses), the pcre2 and
zlib corpus suites (`src/main build :pcre2-tests`, `:zlib-tests`, or the
corpora's own runner), and the three microbenchmarks under
`test/benchmark/` (push through a field, element write through a
parameter, share-then-mutate). A regression counts only when the ratio
exceeds 1.02 in every one of three interleaved rounds. The result table
goes on the PR; a counted regression holds the merge and the table and
profile go to Eric.
