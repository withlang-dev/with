# D137 — The windows-aarch64 lane is non-gating: dispatch it, never wait for it, and file each failure as a new issue

**Date:** 2026-10-19. **Status:** ruled (Eric). **Extends:** D56 (CI is not a
merge signal), D131 (validation tiers).

**Ruling (Eric, 2026-10-19).** "do not gate on windows-on-arm - let it run
asynchronously, we will continue and deal with failures as they are
communicated." And: "treat windows-on-arm as non-gating, and we don't ever
wait for it to complete, we only submit jobs then treat failures as a new
issue when they appear."

**Decision.**

- No merge, reseed, seed cut, release or campaign step waits on a
  windows-aarch64 job: `selfhost-windows-aarch64`, `seed-windows-aarch64`,
  the windows-aarch64 jobs of the SDK and nightly release workflows.
- Work dispatches the job and moves on. Nobody polls it or holds a stack,
  a PR or an issue open for its verdict.
- A red windows-aarch64 run is filed as a new issue when it is seen, with the
  run ID, the failing targets and their captures, and fixed like any other
  bug (we own every bug). It does not reopen the work that dispatched it.
- A release whose windows-aarch64 job is red publishes the other platforms;
  that platform has no asset until a later run is green (runbook,
  "Publish-first").

**Why.** The only Windows-on-ARM host is a GitHub runner. One lane run takes
about an hour, and the D118 bring-up spent most of a day waiting on such runs
between fixes. Its failures are real bugs, but they are Windows-on-ARM
specific: the seed-driven battery on the Mac still proves main correct
(D56), so waiting buys no safety for anything else.

**Risk accepted.** A change can land on main that breaks windows-aarch64 and
is seen only when the next run reports. The issue it gets is the fix's
tracker.

**What would reopen it.** A Windows-on-ARM host that runs the battery in the
battery's own time, or a release where windows-aarch64 is a primary platform.
