# D119 — A C local or table array becomes a `List`; a struct or union field stays `[T; N]`; the no-heap lowering is guaranteed

**Date:** 2026-10-09. **Status:** ruled (Eric Hartford). **The compiler and
the C migrator are NON-COMPLIANT** until implemented.

**Context.** Checking D118's migrator risk found the migrator never emits a
`List`: the four corpora hold 878 fixed arrays, in the retired `[N]T`
spelling, with a cast on every element (`let crc_table: [256]c_uint =
[(0 as c_uint), …]`). Eric proposed that the migrator emit a `List` for
every C array except where layout is the contract. The brief checked three
facts: fixed arrays are already bounds-checked (`t[7]` on `[i32; 4]`
panics), so safety is not a reason; a never-grown local `List` literal
allocates on every call today (1000 calls, 1003 allocations), so D113's
"needn't touch the heap" was a permission nobody honored; and "a List with
capacity 256" for `char buf[256]` is length 0, so `buf[10]` would panic. It
proposed the line at value semantics rather than C crossing: C cannot
assign a local array or pass it by value, but a struct field is part of a
value.

**Ruling (Eric, verbatim).** "Agree with all of it, and the two corrections
land: capacity 256 is length 0, so `buf` has to be a 256-element fill, and
a local list allocating on every call today means the migrator can't switch
until the lowering is real. My plan had the order backwards. The compiler
guarantee comes first and the migrator follows it."

"1. The struct-field line. Rule it, but record a second reason beside the
agent's, because it holds regardless of how one other question goes.
Migrated C treats structs as bytes: `memcpy(&a, &b, sizeof a)`,
`memset(&s, 0, sizeof s)`, `fwrite(&rec, sizeof rec, 1, f)`. All of those
assume the array is inline in the struct. A `List` field would make each
one copy a header and share a buffer, which is a double free waiting to
happen. So struct and union fields stay `[T; N]` because the C code depends
on their bytes, not only because of value semantics. The agent's correction
to my "fixed arrays exist for C layout" is right too: a fixed array is
With's fixed-size value, and `float3`, a matrix and a hash state are fixed
arrays because they're values, not because of C."

"2. Make the no-heap lowering a guarantee. Write it into the spec with its
exact conditions (never pushed, grown, moved out, stored or retained), and
gate it on the allocation-count test. A permission nobody's required to
honor is how 1003 allocations happened."

"One question the agent's reasoning surfaces, which shouldn't block any of
this: it calls `List` a resource, with identity, so copying one needs
`.clone()`. That's how D111 left it ("keep move semantics until something
forces the question"). But it's a choice, not a fact. Swift's `Array` is a
mutable growable list that's a *value*, copied in O(1) via copy-on-write.
Whether With's `List` should be a value is the same question you answered
for strings … It doesn't change the struct-field ruling, since the byte
argument stands either way, but it deserves its own brief rather than being
settled implicitly by this one."

"Sequencing as the agent proposed: the spelling fix right after the rename,
then the guaranteed lowering, then the migrator rule with corpus
benchmarks, all ahead of the header change."

**Spec projection (drafted from the agreed design).** §4.3c: the no-heap
lowering is guaranteed, with its conditions. §4.3a: a fixed array is With's
fixed-size value; a `List` is the growable sequence. `with-migrate-spec.md`
"Arrays": locals and tables become `List` literals (fills for buffers, the
length carried, `List[[T; N]]` for 2-D locals), struct and union fields stay
`[T; N]`, an address passed to C is the data pointer and length, elements
are typed by demand and never cast one by one; the `List` rule waits for the
guaranteed lowering and a before/after benchmark of each corpus.

**Order.** After D118's rename: (1) the migrator spelling fix (`[T; N]`, no
per-element casts, `sizeof` ratio → `len()`) and re-migration (D112);
(2) the guaranteed lowering, gated on the allocation-count test; (3) the
migrator's `List` rule, with each corpus benchmarked against its C; then
the D115 header change.

**Not decided here.** Whether `List` is a value (copy-on-write, as Swift's
`Array`) or a resource (D111's current answer): its own brief.

**What would reopen it.** A C idiom over a local array that needs its
elements inline (none known: C cannot assign or pass a local array).
