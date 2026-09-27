# Resume After Mutability Is Fixed — Historical Queue (Superseded)

> **SUPERSEDED (2026-07-23).** The D5 restoration directive below is no longer
> active. Specification §3.8 now governs free parameters: `&T` borrows and plain
> `T` consumes. Every imperative, “active work,” and “canonical” claim below is
> void; do not execute it. Consult the current handoff and decision log before
> recovering any unrelated backlog item. For D22,
> `docs/d22-Eric-Ruling.md` is canonical and complete.

**Historical status (2026-07-05; no longer active): PARKED.** At that time Eric
directed that the entire focus become restoring and fully implementing the
**share-place calling convention** from
`docs/completed/mutability.md` — his original, explicit design, unique to With
("a calling card, a statement of what With means"), which subsequent agents
trampled by implementing move+callee-drop instead. Everything below is
preserved only to explain that former queue.

There is no active restoration work in this file. Recover an unrelated backlog
item only after validating it against the current roadmap and doctrine.

---

## Historical mutability restoration directive — void

The 2026-07-05 ruling was: **Call 1 = restore share-place.** It then treated
`mutability.md` as canonical and a non-`Copy` value passed `f(x)` as an
*ephemeral shared-place alias*
(callee mutates the caller's place, caller keeps ownership, destructor runs in
the caller's scope); `move`/`copy` are required only when the body's effect
summary is `consume`/`escape_value` (`escape_view` via view-origin tracking).
That former directive is retained as history and must not be implemented.

---

## Calls Eric still needs to make (after mutability)

Bring these back as a short decision round once the mutability work lands. My
predicted rulings are recorded so they can be confirmed fast.

- **Call 2 — `mut` on non-self parameters (#645, part ii).** The parser silently
  discards `mut` in `fn f(mut x: T)`. `mutability.md` (L43, L737) says there is
  **no** `mut x: T` modifier — params are implicitly rebindable. *Predicted
  ruling: reject it loudly* ("parameters are already rebindable; no `mut`
  modifier — use a local `var`"), fixing the silent discard.

- **Call 3 — unflagged `self: ConcreteType` receivers (#646).** `mutability.md`
  (L276, L284): every method must declare a receiver mode; plain `self: Self` is
  a compile error. Today `self: ConcreteType` slips the check and gets legacy
  *consuming* lowering. Enforcing it requires migrating the compiler's own
  pervasive unflagged `self: T` methods. *Predicted ruling: affirm the design
  (require a mode), schedule the enforcement + compiler-source migration as its
  own cycle with the self-host flip discipline.* (This overlaps the mutability
  work — the receiver side already matches the doc from Cycle 1; this is the
  enforcement + migration of the concrete-type escape.)

- **Call 4 — `mut self` on primitive/str owners (#644).** A straight bug under
  either model: `mut self` is documented to mutate the receiver's place, but a
  primitive/str receiver is passed by value (mutation lost). *Predicted ruling:
  fix — lower the flagged receiver by pointer, uniformly with struct `mut self`.
  Low priority (extension-methods-on-primitives is a rare surface).*

- **Call 5 — demote `Unit`/`Never` (#647).** *Predicted ruling: won't-fix. Close
  it. `Unit`/`Never` stay reserved* (every reference language reserves the
  equivalents; core types with a 331-ref self-host risk and no upside).

---

## Queued bug fixes (memory-safety / correctness — do first after mutability)

Recommended order once the mutability work lands and the calls above are ruled:

1. **#648 — `Result[DropType]::unwrap()` double-frees.** Highest severity
   (double-free / UAF-class). `str.to_cstring().unwrap()` double-frees the
   `CString` (moved-out payload not marked consumed → both the value and the
   Result's copy drop). Pure fix. Surfaced during #602.
2. **#643 — global-read drops the implicit tail-expression value.** Silent wrong
   value: `fn f() -> i32: let mid = G; mid + 5` returns 0, not 12. `#640` family
   (tail-value machinery is fresh). Pure fix.
3. **The receiver/param-mode follow-ons** (#644 / #645-ii / #646 per the rulings
   above) — a single focused cycle, shared `FN_PARAM_FLAG` machinery, likely
   folded into the mutability work.
4. **#647** — close as won't-fix.

Also relevant, filed during the soundness campaign but lower priority /
already-tracked: #644–#647 (above). #643 and #648 are the standalone high-value
ones.

---

## Snapshot at park time (2026-07-05)

- Soundness tier complete: 9/9 cycles landed, pushed, bootstrapped into the seed
  (HEAD `92ceea13`). All fixpoint + suite green (behavior 814, compile-errors
  698). Seed + installed toolchain updated.
- `docs/decisions.md` records D2 (#625 viral-escape), D3 (#627 alias split), D4
  (#602 retains). impl-notes ch. 55–62.
- The mutability restoration supersedes/absorbs the receiver-param cluster; keep
  the two consistent.
