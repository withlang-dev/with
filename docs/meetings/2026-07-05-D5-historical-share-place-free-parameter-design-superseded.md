# D5 — Historical SHARE-PLACE free-parameter design — SUPERSEDED

**Date:** 2026-07-05
**Status:** Superseded. The current BDFL ruling is specification §3.8:
`&T` borrows and plain `T` consumes; the signature states the mode.
**Historical design:** `docs/completed/mutability.md` · **Deciders:** Eric (BDFL)

### Supersession

Free-function SHARE-PLACE is retired. A read-only or view-producing parameter
is declared `&T`; a plain `T` is owned by the callee and is consumed without a
redundant call-site `move` annotation. Body-inferred effects remain analysis
facts, but they do not reinterpret a declared ownership mode or silently move
destructor timing between scopes. Auto-ref preserves the ergonomic call surface:
callers write `peek(x)` for `peek(x: &T)` and `take(x)` for `take(x: T)`.

This supersession does **not** change receiver modes. `mut fn` still mutates its
receiver place in place, `move fn` consumes it, and D21 pipeline place-threading
remains current. `PassMode::IndirectPlace` remains an ABI mechanism for
compiler-modeled borrowed places such as in-place receivers, never a
source-level default for plain `T`; explicit `&T` has the ABI of its reference
value.

### Historical record — not current doctrine

D5 previously made a plain non-`Copy` free parameter an inferred shared-place
alias. The caller retained ownership, body effects selected borrowing versus
transfer, and the design sought Python-shaped mutation without call-site
reference syntax. That was an accepted design at the time and explains legacy
effect summaries, `SHARE-PLACE` diagnostics, tests, and ABI comments.

That design is now void for free parameters. No instruction, protection,
restoration task, or “canonical” claim from the former D5 text remains active.
Do not restore it from history. The only retained lesson is provenance: source
ownership must follow the current declared signature, while receiver modes and
view-origin analysis continue under their own current rulings.

---
