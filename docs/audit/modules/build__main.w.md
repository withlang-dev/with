# Primary verification — `build.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `5c57da785ae13c8865437fbe061d9b1cc164dfc575598e1aad0b47e044bd2756`
Source examined: child 1-3068 complete (five reads); primary: -O0 grep
(zero build settings — sole hit is the CLI flag list), `check build.w`
rc=0, chain/fixpoint region claims accepted as child evidence

## Scope examined

Stage chain, fixpoint logic, cross lanes, optimization invariant, failure messages.

Applicable overview targets examined: T19/T21 (chain/lanes), T23 (build failures).

## Verdict: no finding — chain verified dry, -O1 invariant holds

- Stage chain + fixpoint + cross targets verified by child via --explain
  (dry, no full build run — correctly avoided per protocol).
- `-O1` invariant (AGENTS.md): primary grep finds NO `-O0` in build settings;
  the single `-O0` hit (`build/compiler.w:966`) is the user-facing CLI flag
  inventory, not a build default. Invariant holds.
- `check build.w` rc=0: the build system typechecks under the seed.

## Notes

- Windows cross-target inline mirrors (duplication note by child) recorded
  as child evidence; structural, no behavior.
