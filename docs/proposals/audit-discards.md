## Proposal: `audit:discards`, an opt-in report of ignored failures

**Laws:** 4, 10, 11. **Amends:** nothing. D177 and §10.1 stand as ruled.

**What it is.** A new audit, run only when asked:

```
with analyze prog.w audit:discards
```

**What it reports**

1. **A discarded `Result`:** an expression statement whose type is `Result[T, E]`.
2. **An assignment tested as a condition:** `if rc = next():`, with a note that the stored value is tested.

**What it never reports**

- Anything bound, matched, propagated with `?`, or handled (`unwrap_or`, `let _ =`).
- A discarded `Option`. Those are routine and would bury the signal.

**What it never does**

- Run under `with build`, `with check`, `with run`, or `audit:all`.
- Refuse a program. The exit code is 0 unless the caller passes `--deny`.
- Add syntax. There is no annotation to silence a finding. Output is sorted `file:line:col kind`, so a team that wants a baseline commits the output and diffs against it.

**Why it is consistent with the laws**

- **Law 11:** nothing is restricted, and the programmer still owns the logic.
- **Law 1:** no new spelling is required of anyone.
- **Law 4:** a discarded failure is the one place the program proceeds as if a call succeeded without anyone saying so. The audit makes that visible to whoever asks.

**Fixtures (law 10)**

- `behav_audit_discards_reports.w`: one of each finding, exact output.
- `behav_audit_discards_silent.w`: every handled form, empty output.
- A check that `with build` output is byte-identical with and without the audit present.

**The test that decides whether this proposal deserves to exist.** Run it once over With's own `src/` and `lib/`. If it finds no real bugs in half a million lines, I'm wrong and the proposal should be dropped. If it finds some, you have your answer about what developers would care about, from your own code.

**Reopen if:** the audit's findings are ever promoted to a default diagnostic without a ruling.