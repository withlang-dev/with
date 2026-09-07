# Primary verification — `lib/std/signal.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 21 lines (single complete read)

## Scope examined

`sigint`/`sigterm`/`sigkill` constants + `raise_signal` over
`with_raise`. No in-repo callers. No test files.

## Behavioral matrix (all EXECUTED)

- `docs/audit/probes/signal/main.w`: sigint()=2, sigterm()=15,
  sigkill()=9 — match the python `signal` oracle (Linux;
  identical on macOS for these three). `raise_signal(0)`
  (null signal, delivery-free) returns 0 — the `with_raise`
  binding works. 4/4 PASS. Live-signal delivery deliberately
  not probed (would kill the test process).

## Findings

None.

Verdict: COMPLETE
