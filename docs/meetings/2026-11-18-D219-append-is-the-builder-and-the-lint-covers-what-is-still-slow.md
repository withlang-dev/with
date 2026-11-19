# D219 — `++` append is the builder; the lint covers what is still slow

**Laws:** 1 (the natural spelling is the fast spelling), 4.

**Date:** 2026-11-18. **Status:** ruled by Eric. Settles D34-C against D111.

**Context.** #919: D34-C ruled that `s = s ++ x` becomes amortized, the
accumulator lint is deleted and `StringBuilder` retires from the user
surface; D111 later said text that is built goes through a builder that
produces a `str`. Measured 2026-11-18: 400,000 one-character appends take
9 ms (amortized already); the lint no longer fires for the append form;
40,000 prepends take 91 ms (still quadratic); `StringBuilder` is public and
used in about 30 places in the standard library.

**Ruling.**

- D34-C stands. D111's sentence describes the implementation: a uniquely
  held `str` at its last use is the builder.
- `StringBuilder` leaves the prelude and the recommended idioms, and stays
  in `std.string` for byte-level building.
- The lint stays for non-append accumulation, with advice that works
  (collect the pieces and join them, or build in reverse); it does not name
  `StringBuilder`.
- The fast append depends on the string being uniquely held. If another
  binding shares it, every append copies and the loop is quadratic again
  with no warning. The lint covers that case where it is provable.

**Reopen if** unique ownership at the append turns out not to be provable
in the common shapes, so the lint would fire on idiomatic loops.
