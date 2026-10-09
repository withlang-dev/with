# D120 — Collections and structs of values are values: copy-on-write with an atomic count; `resource type` declares a resource

**Date:** 2026-10-09. **Status:** ruled (Eric Hartford). **Extends** D111 (identity decides copy or move)
from `str` to collections and structs. **The compiler is NON-COMPLIANT**
until implemented; the implementation merges only within the measured
margins below.

**Context.** D119 called `List` a resource, as D111 had left it ("keep move
semantics until something forces the question"). Eric raised Swift's
`Array`, a mutable growable value copied in O(1) via copy-on-write. The
brief (#2302) found: the "Python behavior" for `let b = a` is aliasing,
which With cannot offer, so the choice is Swift's value or Rust's move;
Mojo's `List` is `Copyable where T: Copyable`, never implicitly; Rust's
`Vec: Clone` needs `T: Clone`; Go and Zig alias the buffer. It predicted
move (60%). Eric predicted copy-on-write (65%). Three facts then corrected
the cost: D111 ruled the `str` count atomic, for a soundness reason that
applies to lists word for word; static proof of uniqueness covers locals,
not fields or parameters (the compiler mutates lists through `self.`
fields at 1,299 `push` sites); and §2.3's resource example "buffers being
filled" had to be amended, which raised whether structs and maps follow.

**Ruling (Eric, verbatim).** "That changes the cost from "free where nobody
shares" to "a relaxed load and a predictable branch at every mutation
through a field or parameter, plus atomic count traffic only when a list is
actually shared." I'd still rule yes, but make it contingent on measurement
rather than on my argument."

"1. Copy-on-write for collections of values, atomic: yes, gated on that
benchmark. Amend §2.3's example rather than contradict it. "Buffers being
filled" was right about buffers lent to the OS or to C while being filled
(an io_uring submission, a DMA target, a pointer C retains). Those have
identity, because someone outside the program is writing into that exact
memory. A list the program fills itself doesn't."

"2. A struct whose fields are all values is a value: yes, with two
exceptions. Identity is compositional, so a struct has identity if any
field does. But a struct can also have identity that its fields don't
show: It implements Drop. Custom cleanup means each instance is a distinct
thing to clean up, so it's a resource regardless of its fields. Its meaning
forbids duplication. A capability, a permit, an ID allocator, a one-shot
token: all value fields, but copying one is a bug. Those need a way to
declare themselves resources explicitly. With mints capabilities, so this
case is real today. So: a struct is a value if every field is a value, it
has no Drop, and it isn't declared a resource. That also makes migrated C
structs values, which matches what C does with them (memcpy)."

"3. Maps and sets follow: yes. Otherwise "identity decides" stops being the
rule, and users have to memorize which collections copy. HashMap[str,
isize] is a value for the same reason List[isize] is."

On the measurement: "Self-host compile time at 2%. It's the largest real
With program, it's the 1,299 field pushes the agent counted, and it's
already tracked. This is the honest representative workload. The corpora's
own test suites at 2%. pcre2 and zlib are real programs derived from C,
with tight loops over buffers, which is the code most likely to feel the
check. Targeted microbenchmarks, tracked, not gated: a push loop through a
field, an element-write loop through a parameter, and a share-then-mutate
case that forces the copy. These isolate the check, so they're expected to
show more than 2%. Their job is to show where the cost lands, not to
block."

Costs stated with the ruling (Eric): C interop makes a list unique before a
mutable pointer into it goes to C (one check at the boundary); generic code
copies or moves per instantiation, so an error can appear only for resource
element types; a CoW copy appears at a mutation that does not look like it
allocates, and the answer is an analysis that reports where CoW copies can
occur.

**Spec projection.** §2.3 (ownership.md): the resource example becomes "a
buffer lent to the OS or to C while being filled"; a new paragraph states
the compositional rule, copy-on-write with an atomic count, the uniqueness
check, the C boundary and per-instantiation generics. §4.3 (types.md):
`resource type`, a contextual keyword before `type`: a modifier keyword for
meaning, as `distinct type`, not an attribute, which With keeps for
representation. Eric (verbatim): "resource type is approved, as drafted: a
contextual keyword, implied by Drop, allowed but redundant on a Drop type."

**Merge conditions.** The implementation merges only if self-host compile
time and the pcre2 and zlib corpora's own test suites are each within 2% of
the compiler before it, by interleaved local A/B ratio. The three
microbenchmarks are tracked and reported, never blocking. Eric (verbatim):
"Block, but blocking means escalating to you, not killing the design. If
self-host time regresses more than 2%, the merge holds and the agent brings
you the numbers and a profile showing where the cost lands. You then
decide: optimize first, accept the cost, or revisit the ruling. Reporting
alone doesn't work, for the reason we've seen all week: once something
merges, nothing forces anyone back to it, and a regression nobody's
required to look at becomes permanent. Since 2% is close to measurement
noise, the gate should require the regression to hold across repeated
interleaved runs before it counts."

So: a regression counts only when it holds across repeated interleaved
runs; a counted regression holds the merge, and the numbers and a profile
of where the cost lands go to Eric, who decides to optimize, accept or
revisit.

**Order.** After D118's rename and D119, alongside the `List` header change
(D115 Amendment 1): the count lives in the allocation, so the header stays
32 bytes.

**What would reopen it.** Self-host time or a corpus suite more than 2%
slower with the cost not removable; or a program where the deferred copy
misleads more than the move error would have.
