# D95 — Five rulings: `let _` drops, `pub const` takes its value's type, `??` binds below `|>`, structural types derive, the SQLite fixture

**Date:** 2026-10-05. **Status:** BDFL rulings (Eric, all five; the reasons
below are his). Spec v7.24. Issues #2074, #2101, #2133, #2142, #2161. **The
implementation is NON-COMPLIANT until it catches up.**

## 1. `let _ = t` drops `t` (#2074)

Sema treated a wildcard `let _ = x` as moving nothing while MIR moved `x`
and dropped it, so `let _ = h` followed by `h.len()` read freed memory.

**Decision: the discard consumes.** It follows from rules already there:
naming a non-`Copy` value moves it, and `_` binds nothing, so the value is
dropped right there. Making `_` observe instead would make it special, and
Rust's version of that (`let _ = x` does nothing) is a well-known trap.
Here `let _ = h` is a visible "drop this now", which fits "leaking takes
visible effort". Sema is made to agree with MIR, and a use after it says
so: "`let _ = h` dropped `h` at line N; remove it to keep `h`".

## 2. A `pub const` takes its value's type (#2101)

**Decision: approve** the §9.1b wording of #2162, with two clarifications.
What it describes is Go's untyped constants: `ENEMY_CAP = 2000` works as an
`i32`, an `i64` or an `f32` wherever it is used, which is more stable as a
public API than a fixed type. It covers constant arithmetic as well as single
literals (`const SIZE = 64 * 1024`), and a use the value does not fit is an
error at that use (`5_000_000_000` used as an `i32`), not at the
declaration. It is consistent with a `pub fn` inferring its return type.

## 3. The SQLite fixture (#2133, PR #2136)

**Decision: approve.** It is what the flagship example should show, and
checking that `db.exec("SELEC 1")` carries SQLite's own "syntax error" text
is the right test. Follow-up, not blocking: `error QueryError from
DatabaseError, ExecError, StatementError, StepError` asks the user to know
four error types for one library, all carrying a status and
`sqlite3_errmsg`. A facade-level clause declaring one error type for every
producer in the facade would make it `-> Result[i32, SqliteError]` with no
`from` line.

## 4. `??` binds below `|>` (#2142)

**Decision: approve.** `??` gets its own level between the comparisons and
`|>`, as Swift and Kotlin place nil-coalescing below arithmetic and above
comparison; it is right-associative, `a ?? b ?? c` is `a ?? (b ?? c)`. The
same shape comes up with arithmetic: `xs |> sum() * 2` is
`xs |> (sum() * 2)`, consistent with F# and Elixir, so that precedence
stays, and the type error it produces suggests the parentheses. README's
`largest` drops its parentheses once this lands.

## 5. Structural types derive (#2161)

**Decision: approve, generalized.** One rule for structural types instead
of one ruling per trait: a tuple, a fixed array, `Option` and `Result`
implement `Clone`, `Eq`, `Ord`, `Hash` and `Debug` when every element type
does. For arrays, if an element's `clone()` panics partway through, the
elements already cloned are dropped: that is what "a leak is a defect"
requires, and it is easy to get wrong in generated code.

**Reopen if:** (1) a program needs to keep a value alive past a `let _`;
(4) a pipeline stage that is itself a default (`stage() ?? d`) turns out to
have a use.
