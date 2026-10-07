# D31 — `&place as <integer-type>` is a compile error; fix-it offers both intents

**Laws:** 7 (docs/mission.md).

**Date:** 2026-08-30
**Status:** Ruled by Eric ("I bless the decision") on the #888 brief.
Normative from the §16.11 spec sentence landing with this entry. Carves out
of D22 §6.2's cast-target owned-value demand for exactly one case; D22 §6.2
stays intact for every other cast target.

**Ruling (blessed wording):**

> Error on `&place as <integer-type>`, fix-it offering both intents
> (`&raw const place as u64` for the address, `place as u64` for the
> value), D22 §6.2 untouched everywhere else.

**Context.** #888 was filed as an "-O1 miscompile: raw store dropped." The
IR disproved it: the repro's `&target[0] as u64` materialized the Copy
pointee per D22 §6.2 (cast target = owned-value demand) and stored the byte
value 65 as a pointer — conforming behavior, catastrophic intent mismatch.
The same trap crashed std.http's recv loop (str punned over a stack buffer).

**Alternatives weighed.** (a) Keep the D22 value reading and document —
rejected: under the value reading the `&` is an unnecessary character
("every unnecessary character is a compiler failure"), and the spelling's
only plausible intent is address-taking, which it silently is not. (b) Make
`&place as <int>` mean the address (C's reading) — rejected: it would fork
D22's transparency doctrine and make one cast target semantically special.
(c) Error with fix-its — accepted: catches a real mistake the compiler
cannot otherwise resolve, costs zero legitimate programs (the value intent
is shorter without the `&`; the address intent has two blessed spellings).

**References.** Rust rejects `&T as u64` (E0606; must go through
`as *const T as usize`). Zig requires `@intFromPtr`. Mojo (verified
in-tree) has no borrow-to-integer path at all: address-of is a named
construction (`Pointer(to=x)`), pointer-to-int is an explicit conversion
(`Int(ptr)`). C is the lone divergent and reads the ADDRESS — so a C
migrant is exactly who the silent value reading burns. The migrator is
unaffected: it already emits `&raw const … as …` spellings.

**Reopen if** a target model ever defines a safe borrow-to-integer
observation, which would get its own ruling.

---
