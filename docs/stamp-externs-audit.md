# Stamp Externs Audit

Status: current as of `009ad33`.

Cleanup 2 checked whether `with_clock_nanos` and `with_getpid` are orphaned in
`src/main.w`.

Result: both externs are still live and should remain.

Current `src/main.w` call sites use them for:

- one-liner temporary source paths
- test binary output paths
- build action dispatch stamps
- selfhost capture stamps still owned by generic driver paths
- native test output paths

`BuildGraphSelfhost.w`, `BuildGraphSelfhostHarness.w`, and compiler submodules
also still use the same runtime functions. No source changes are required until
those remaining generic paths are extracted or refactored.
