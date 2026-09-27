# 14.18 The Fiber Runtime

The fiber scheduler is part of the standard library. It is:

- Initialized automatically on program start for hosted targets
- Work-stealing across OS threads
- Not a trait, not pluggable, not replaceable
- Absent in `no_runtime` builds (and `async` is then a compile error)

The runtime is the one component with hidden scheduling cost. This is
acceptable because: (a) it is opt-in via `async`, (b) current-fiber
suspension is known to the compiler and enforced by `may_suspend`
checks, and (c) `no_runtime` builds can disable it entirely.
