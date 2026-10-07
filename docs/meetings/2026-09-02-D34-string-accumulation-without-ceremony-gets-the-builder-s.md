# D34 — String accumulation without ceremony: `++` gets the builder's efficiency; demand-site finalization for wrapper types

**Laws:** 1, 2 (docs/mission.md).

**Date:** 2026-09-02
**Status:** Ruled by Eric on the `to_str()`-ceremony brief (the trigger:
a declared `-> str` return forced an explicit `.to_str()` on a
StringBuilder tail — "extra ceremony is a literal bug"). Two rulings,
verbatim: "ok we want both A and C. A should apply to all Builder
patterns (or maybe something grander, maybe any form of 'wrapper' like
an Option or a Promise). and C absolutely if we can make ++ as
efficient as StringBuilder we should do it and remove complexity."

**C (ruled, unconditional):** `s = s ++ x` / accumulation on `str`
itself becomes amortized-efficient when the base is uniquely owned —
the ownership model statically proves the in-place-growth condition
that forces Rust and Go into a separate builder type. Consequences:
the loop-accumulator lint is DELETED (the natural spelling becomes the
fast spelling — a lint that herds users from the ergonomic form to a
ceremonial one is the anti-pattern named in the mission), and
StringBuilder retires from the user surface. Interim engineering
(bulk-memcpy push_str, zero-copy to_str) lands first since C subsumes
it.

**A (ruled for builders; grander scope needs its own design ruling):**
a value of a finalizable wrapper type satisfies an owned demand for its
built type at demand sites (return position, typed binding, argument)
— StringBuilder satisfies a `str` demand without `.to_str()`. Eric's
"maybe something grander — any form of 'wrapper' like an Option or a
Promise" opens a general demand-driven elimination design (the D22/D27
"an annotation demands what it says" doctrine extended to eliminators);
its Option arm implies implicit unwrap-panics and its Promise/Task arm
implies implicit await — semantics heavy enough that the general trait
design goes back to Eric as a brief before any implementation beyond
the builder case. Transfer-is-explicit tension noted and accepted for
finalization: consuming a builder at a demand site is the builder's
purpose.

---
