# Incrementality Handoff

## What's Committed

Commit `321d1d8` (WIP: incrementality infrastructure):

- **`src/BuildGraphCache.w`** — new module with all cache logic:
  - State file I/O (`out/.build-state/{target-name}.state`)
  - File fingerprinting via `with_str_hash` on file contents
  - Action signature computation (hashes target config fields)
  - Freshness detection (`build_cache_check_fresh`)
  - `build_cache_is_cacheable()` — currently includes kind 23 (actions)

- **`src/main.w`** — integration in `run_build_graph()`:
  - `skipped_targets: Vec[str]` tracking
  - Before dispatch: check cacheable, check deps rebuilt, call freshness
  - After success: call `build_cache_record` for all target paths
  - Dep-rebuilt detection: if dep is in completed but NOT in skipped, it was rebuilt

- **`docs/build-spec.md`** — expanded section 18 with detailed incrementality spec

## Current State

The caching infrastructure **works correctly**:
- State files are written to `out/.build-state/`
- Freshness checks return correct results (verified with isolated test)
- Targets ARE being skipped on incremental builds (confirmed: `[build]` target skipped)
- Build passes, fixpoint passes, tests pass

## Why Builds Aren't Faster Yet

The entire build graph uses kind 23 (action) targets. The expensive targets
are `stage1` and `stage2`, which compile the full compiler. These have an
**incomplete declared inputs** problem:

- `stage1` declares input: `out/gen/main.w` (the entrypoint)
- But the compiler transitively reads ~40 other `.w` files via `use` statements
- An edit to `src/Sema.w` doesn't appear in declared inputs
- Caching these targets would produce WRONG builds (stale compiler)

## Open Design Question: Which Actions Are Sound to Cache?

### Sound (complete declared inputs):
- All `--no-prelude` single-file compilations: `*-bridge-object`, `*-rt-*-object`,
  `*-cimport-stubs-object`, `*-compat-runtime-object`, `*-panic-runtime-object`,
  `*-fiber-*-object`, `*-channel-runtime-object`
- `compiler-sources` (text substitution only)
- `compat-runtime-source` (single file copy)

### Unsound (incomplete declared inputs):
- `stage1`, `stage2`, `build` — read transitive imports not in declared inputs
- `llvm-link-metadata` — reads external LLVM tools (version could change)

### Paths to Fix Unsound Targets

1. **`--emit-deps` compiler flag** — have the compiler output a depfile listing
   all transitively-read `.w` files. Cache logic reads the depfile to validate
   freshness. Most correct long-term solution.

2. **Hash the compiler binary as implicit input** — add compiler binary fingerprint
   to the action signature. Handles "compiler changed" but not "source file changed."

3. **Never cache stage targets** — safest near-term. Only cache `--no-prelude`
   object targets. These are ~15 targets that take real time (runtime compilation).

4. **Glob the source directory** — hash all `src/*.w` files as implicit inputs for
   stage targets. Crude but sound. O(n) file reads on every build.

## Recommended Next Steps

1. **Restrict kind 23 caching to sound targets only.** Either:
   - Add a whitelist of target names that are safe to cache, OR
   - Only cache actions with `--no-prelude` in their args (proxy for "single file, no imports")

2. **Implement `--emit-deps`** as a compiler feature (long-term soundness).

3. **Add `[skip]` messaging** gated behind `--verbose` or a cache-specific flag.

4. **Test with stable source:** after committing, run `./out/bin/with build` twice
   without editing source between runs. Verify runtime object targets are skipped
   and second build is faster.

## Files

| File | Role |
|------|------|
| `src/BuildGraphCache.w` | All cache logic |
| `src/main.w:1016-1027` | Freshness check integration |
| `src/main.w:1032,1081,1096,1111,1126` | Cache recording after success |
| `out/.build-state/*.state` | Runtime state files (not committed) |
