# D15 — One loop back-edge carried-move predicate; `break` is a separate edge

**Date:** 2026-07-20
**Status:** Accepted.
**Deciders:** Eric (BDFL)

### The decision

The move checker's "is this binding used moved on the next iteration?" test is
computed by a single pure predicate — `is_loop_carried_move(entry_state,
cur_state, needs_drop)` = `entry==LIVE && cur==MOVED && needs_drop` — that BOTH
loop back-edges call: the fall-through (`finalize_loop_move_state`) and the
`continue` (`check_loop_continue_carried_move`), including their
`WITH_TRACE_MOVE` verdict lines. Re-inlining the condition per edge is
forbidden.

`break` (`capture_loop_break_move_state`) is deliberately NOT folded into this
predicate. It is an **exit** edge: it propagates the current move-state *out* of
the loop into the post-loop state (any binding MOVED at a break is MOVED after
the loop). It has no `entry==LIVE` guard because that is correct — it is not a
carried-move error, it is a different operation. A future maintainer should not
"unify" break with the back-edge predicate; that would be wrong.

### Context / why

#696: the `continue` back-edge check had drifted from the fall-through check —
it fired on `cur==MOVED` alone, dropping the `entry==LIVE` guard, so a value
moved *before* a loop with a `continue` was wrongly flagged as moved *inside*
it. It shipped in #613 with zero tests. Root cause was per-edge re-derivation of
one predicate — the same failure mode D6 forbids for call ABI ("`FnAbi` is the
single ABI source of truth — never re-derive call ABI per-path"). The instance
fix (give continue the loop-entry snapshot) is not enough on its own: with the
condition still inlined at two sites, a third back-edge could reintroduce the
divergence. So we make the guard structural — a caller cannot invoke the
predicate without supplying the entry state.

### Alternatives weighed

- **Leave both sites inlined (instance fix only).** Rejected: that is what let
  #696 exist; nothing stops the next edge from drifting.
- **Also unify `break`.** Rejected as incorrect — break is an exit edge, not a
  back-edge; it has different (correct) semantics.

### What guards it / would reopen it

`tools/move_audit.w` (`with build :move-audit`) is the behavior matrix over
(edge × move-timing × shape); it proved this refactor neutral (15/15 cells) and
would catch a future re-divergence. See D6 (single-source-of-truth ABI) and
D14 (battery tiering).

---
