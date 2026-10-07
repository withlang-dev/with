# D56 — CI is not a merge signal; the seed-driven battery on the maintainer machine is

**Laws:** 10, 8 (docs/mission.md).

**Date:** 2026-09-22. **Status:** ruled by Eric ("we either reduce it to 20
minutes or we ignore it as any kind of signal. You decide."); the choice
below is the agent's, from the measurements.

**Decision.** Pull requests are gated by the seed-driven battery
(`WITH=$PWD/src/main src/main build`, `:fixpoint`, `:test`, `:test-green`,
`:last-green`, plus `:move-audit`/`:drop-audit` for ownership changes) run on
the maintainer machine and posted on the PR; a PR is a draft until that
battery is green and is marked ready when it is. The GitHub lanes are not
run on pull requests or pushes at all; they run nightly and on manual
dispatch, as post-hoc evidence (Eric, 2026-09-22: CI was overzealous in
what it did on every push). The SDK is built only on release
(`sdk-release.yml`, dispatched against an existing release tag), never on
a push (Eric, 2026-09-22). No lane is a required status check.

**Why.** A lane cannot be a real-time signal: on the last green macOS run
the source-SDK build took 105 min, the compiler build 29 min, fixpoint 34
min and the battery 71 min — about four hours; even without the SDK build,
build+fixpoint+battery is ~2 h on a 4-core runner (the laptop is ~10×
faster; its battery is ~25 min). A signal that arrives two hours after the
decision is noise, and a lane that skips the battery to fit 20 minutes is
not a signal. Running lanes on every PR push therefore bought nothing and
cost runner time and false reds.

**What it costs.** A PR merged before its battery has finished puts an
unverified tree on main; the maintainer accepts that and it is cleaned up
afterwards (2026-09-22: #1301 merged early, `behav_fn_abi_async` red on
main, fixed forward). The draft/ready convention is the mitigation.

**Reopens if** runners get ~10× faster, or a lane can run the real
battery in ≤20 minutes.

---
