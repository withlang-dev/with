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

## Amendment 1 (2026-10-09): dimensions in index order

**Context.** D119 step 1 had the migrator write C's `int a[2][3]` as
`[[c_int; 3]; 2]`, which lists the dimensions inside-out. Compared in all
ten references (`.reference/`): index order in C# (`new int[5, 10]`,
`csharp-12.0/collection-expressions.md`), Go (`[16][4]int`), Zig
(`[10][16]u8`), Vale (`[#2][#2]int`), Swift (`[3 of [3 of Int]]`), Scala
(`Array.ofDim[T](n1, n2)`) and Vx (`Tensor<f32, [128, 128]>`, row-major);
inside-out in Rust (`[[u8; 16]; 20]`), Mojo (`InlineArray[T, N]`, nested)
and Goose (`u8[4][6]`, six rows of four).

**Ruling (Eric, verbatim, from the case he gave).** "The type.
`[T; d1, d2, …, dk]`: the element type, a semicolon, then the dimensions in
the order you index them, outermost first. … It's sugar, not a new type.
`[T; 2, 3]` *is* `[[T; 3]; 2]`: the same type, the same layout. Row-major,
contiguous … Indexing. `a[i][j]`, exactly as in C. `a[i]` is a row of type
`[T; 3]` … Lengths. `a.len()` is the outer dimension (2) … `a.shape()`
returns `[2, 3]` … Migration. `int a[2][3]` becomes `[c_int; 2, 3]`: the
same numbers in the same order. Canonical spelling. The nested form stays
legal, because generics produce it … But the compiler always *prints* the
flat form, and the formatter rewrites nested to flat."

On the brief's three corrections: "All three corrections are right … 1.
Rule array-length generics in principle now, implement them as their own
stage. … ("array lengths can be generic parameters, by the mechanism
`Vector` already uses") … While it's being extended, one consistency note:
`Vector[N, f32]` puts the count before the element, and `[f32; N]` puts the
element first. The two should agree on order, or at least the
length-generics brief should decide whether they need to. 2. Keep D113 as
the one rule. … `let grid = [0; 2, 3]  // List[[isize; 3]]: a list of
fixed rows` … `let fixed: [c_int; 2, 3] = [0; 2, 3]  // a fixed array,
because the type demands one` … 3. Agreed, no ruling chose `[T; N]`. …
`shape()` in §13.3 beside `first()`/`rest()`, yes. … on a fixed array it's
a compile-time constant. On a `List[[T; 3]]` the same method … returning
`[len, 3]`, but the outer entry is a run-time value."

**Spec projection.** §4.3a "Multidimensional arrays"; §13.3 `shape()`;
`with-migrate-spec.md` Arrays: a nested field is `[T; M, N]`.

**Costs, stated with the ruling.** Two spellings name one type (the nested
form is what generics produce; only the flat form is printed or
formatted). `len()` is the outer dimension, not the element count.

**Open.** Whether `Vector[N, T]` and `[T; N]` should agree on order: the
array-length-generics brief decides. Not ruled here: `a[i, j]` as
`a[i][j]` through `MultiIndex`, and whether the retired `[N]T` becomes an
error with a fix-it.
