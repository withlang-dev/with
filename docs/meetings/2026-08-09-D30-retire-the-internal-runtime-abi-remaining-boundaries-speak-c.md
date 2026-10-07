# D30 — Retire the internal runtime ABI; remaining boundaries speak C; §16.3c call-site coercion is the ergonomic dual

**Laws:** 9, 8 (docs/mission.md).

**Date:** 2026-08-09
**Status:** Ruled by Eric ("approved, blessed, condoned, and ratified") on the
#761 brief. Normative from the §16.3e spec sentence landing with this entry.
The implementation is deliberately NON-COMPLIANT until the retirement lands
(sequenced after the 747-flip merge/reseed; the seed-built out/lib interim,
747-flip `ad053bea`, bridges until then). Supersedes in part D18's extern
`-> str` ownership-contract bullet (annotated there). The transitional
`with_*` guidance in CLAUDE.md remains operative until the retirement lands
and is marked accordingly. Status 2026-09-04: the regex seam
(`rt/regex_runtime.w`, `with_regex_*`) is retired — `std.regex` calls the
pcre2 bundle through its interface and the compiler's own regex-literal
validation goes through the facade (batch C4, docs/wo_bundles.md "Shim
retired"); the `with_*` runtime objects remain.

**Ruling (blessed wording):**

> The `with_*` runtime seam was a C-bootstrap fossil kept for build economy,
> not a semantic necessity; #761 showed a boundary with independently-derived
> ownership contracts corrupts silently. The runtime compiles in-unit like
> the embedded stdlib; codegen lowers to ordinary module functions;
> pre-compiled runtime objects are permitted only as a cache keyed by
> compiler version and target, where a hit is byte-identical to the in-unit
> result. Remaining boundaries face genuinely foreign code and speak C
> (§16.3e); §16.3c call-site coercion is the ergonomic dual that makes the
> prohibition free. Reopen only if a With-to-With dynamic-library ABI is
> ever designed — that surface gets its own ruling.

**Context and reasoning.** #761's root cause: the codegen-emitted str
intrinsics' ownership convention was derived twice — the emitter assumed
caller-owns, while the callee side fell out of whichever compiler built the
rt object (seed-built bodies freed nothing; flip-built bodies dropped their
consuming-`str` params — disassembly-proven on 42 functions). Nothing tied
the sides together, so which rt a binary linked decided whether it worked.
Alternatives weighed and rejected: a runtime-ABI tier default reinterpreting
plain `T` (a signature that lies by tier — against D5's authority sentence);
per-function `@[effect]` pins (ceremony restating what inference knows, and
an unmarked-wrong default for the next function); Swift-style ownership
conventions in `FnAbi` and a Rust-style raw-parts ABI (both regulate a seam
this ruling deletes — and Rust's own runtime fleeing Rust's rules is the
cautionary tale, not the pattern). The dissolving move: the seam exists for
history and build economy only; make the runtime ordinary With code and the
defect class becomes unrepresentable. Objects as cache: allowed. Objects as
boundary: retired.

**Boundary prohibition (§16.3e).** After the retirement, every surviving ABI
surface (`extern fn`, `@[c_export]`, `c_import` decls) faces a side that
cannot see With's types; With-managed types there are hard errors (Zig's
stance — `zig/src/Sema.zig:8615`; deliberately not Rust's `improper_ctypes`
lint, which makes the guardrail opt-out). The prohibition costs nothing at
call sites because §16.3c's modeled coercion (call-scoped NUL-terminated
temporaries; `retains:` refusing `str` with `to_cstring` named, #602/D4)
carries the ergonomics. Cross-links: D5 (signatures authoritative), D6
(`FnAbi` remains the single descriptor for the boundaries that remain),
D18 (leak-freedom; superseded in part here), D24 (independent builds),
D13 (version metadata post-link — the cache-key design must respect both).

---
