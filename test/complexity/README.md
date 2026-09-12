# Stdlib complexity fixtures

Run `with build :stdlib-complexity`. The lane also runs in `with build :test`.
It builds `stdlib.w` at `-O1`, then measures work inside that executable so
compiler time and process startup are excluded. The build action runs serially
to avoid competing test processes during timing.

Each case checks its results on every sample. It compares the median of three
runs at N against the median of three runs at 4N. The bound is
`large <= max(small, 1 ms) * 6 + 1 ms`: enough room for noise and linear/log-linear
growth, while the checked baseline's quadratic and cubic cliffs exceed it.
This is a regression alarm, not an asymptotic proof or a microbenchmark ranking.

| Case | Expected result |
|---|---|
| Vec push/access/pop; borrowed iteration | PASS |
| SlotMap fill/remove/refill, including stale/live handles | PASS after #936 |
| HashMap and HashSet insert/lookup/remove | PASS |
| Vec consuming iteration | XFAIL #938 |
| BTreeMap/BTreeSet ascending and descending workloads | XFAIL #937 |
| HashMap removal without allocating temporary buffers | XFAIL #939 |

Only a failed cost bound is eligible for XFAIL. Wrong results, crashes,
timeouts, missing trace markers, and invalid controls fail the lane. An XPASS
also fails: update its expectation in the same change that fixes the engine.

Allocation checks use `with run --trace-alloc stdlib.w allocations`. An empty
marked span must report zero requests; a Vec allocation control must report at
least one. A marked colliding-key HashMap removal checks the no-allocation
contract without confusing temporary allocations with leaks or reserved slabs.
The result and all remaining keys are checked after removal.

Reports and captured output are written to `out/stdlib-complexity/`. Timing
samples run without allocation tracing; tracing is a separate correctness and
allocation-volume pass. No public allocation-counter API is required.
