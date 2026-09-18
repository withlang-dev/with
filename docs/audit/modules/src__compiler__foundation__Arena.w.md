# Audit: src/compiler/foundation/Arena.w @ 450733e5

- Commit: 450733e58a1a7cce14f9cb2084943fc178815111 (verified via `git rev-parse HEAD`)
- Module: src/compiler/foundation/Arena.w (78 lines, full read)
- Imports: compiler.foundation.Ids only (ArenaId, from_raw/raw/is_valid)
- Re-exported by: src/compiler/foundation/Mod.w:4
- stage1 binary: out/bootstrap/bin/with-stage1 exists (verified via `ls -la`, 114690576 bytes)
- Verdict: COMPLETE

## Scope / targets traced

- T13 ownership/drop: Arena owns `Vec[ArenaSlot]`; each slot owns `str_value: str`.
  `alloc_str` clones in (`value.clone()`, Arena.w:55), `get_str` clones out
  (Arena.w:78), `reset` pops to sentinel (Arena.w:36-37) following the same
  discard-pop idiom used across std (`let _ = stack.pop()`, lib/std/cfg/stackify.w).
  `--dump-drop-plan` on a driver shows `<no drop sites>` inside `Arena.reset`
  itself, consistent with drop glue living in `Vec.pop` (bulk-free semantics
  match the header contract "Deallocation is bulk-only via reset", Arena.w:4).
- T15 migration fidelity: module uses only Vec/i32/str/bool, while-loop,
  impl block, no extern/unsafe/FFI. `check` and `run` both pass under stage1.
  `value.clone()` matches the post-#747 owned-str idiom (cf. Values.w:18,75).
- T22 spec conformance: header contract (two lanes i32/str keyed by ArenaId,
  slot 0 reserved, bulk reset) is fully implemented; every public fn matches.

## Probes run (all via out/bootstrap/bin/with-stage1)

- P1 `check src/compiler/foundation/Arena.w` -> `ok` (PASS)
- P2 `run test/internals/arena_test.w` (in-repo golden) -> `ok`, exit 0 (PASS)
- P3 edge probe /tmp/arena_edge3.w -> `ok`, exit 0 (PASS). Covers: cross-kind
  defaults (`get_i32(str_id)==0`, `get_str(i32_id)==""`), sentinel raw 0
  (`contains==false`, `kind==EMPTY`, getters default), negative id, OOB
  id 99999, reset invalidation, realloc raw reuse, `len()` accounting.
- P4 stale-id resurrection probe (in P3): after `reset`, refilling to the same
  raw makes the old id resolve to the NEW slot (`kind(old)==I32`,
  `get_i32(old)==2`). Observed, exit 0 (PASS, documents bump-arena aliasing).
- N1 negative control /tmp/arena_neg.w (`assert get==43` on a 42 slot) ->
  `panic at /tmp/arena_neg.w:7:5: assertion failed`, no further output (PASS:
  harness executes asserts, positives are not vacuous).
- Initial probe draft taught: `contains(arena_id_from_raw(0))` is FALSE
  (guard `raw > 0`, Arena.w:63) — corrected and re-run in P3.

## Callers (REGEX-mode searches only)

- `Arena` in src: only Arena.w itself, Mod.w:4 re-export, std-alloc
  `Arena/FrameArena` (unrelated type in InitTemplates.w docs + SemaCheck.w
  alloc rules), InternPool's separate `InternStringArena`/`FndInternStringArena`.
- `alloc_i32|alloc_str|get_str|get_i32|Arena\.init|\.reset\(\)` in
  src/compiler: hits only inside Arena.w. Zero in-repo callers of this module
  outside Mod.w re-export and test/internals/arena_test.w.
- Hence every finding below is refuted against callers by vacuity + golden-test
  conformance; no caller breakage is possible at this commit.

## Findings

1. src/compiler/foundation/Arena.w:59-63 — INFO / T22 / probe P3 PASS /
   refuted (no callers; golden test P2 passes): `contains` excludes sentinel
   raw 0 (`raw > 0`) while `kind(0)` still safely returns `ARENA_SLOT_EMPTY`.
   Self-consistent; not a defect.
2. src/compiler/foundation/Arena.w:35-37 — INFO / T13 / probes P2,P3 PASS /
   refuted (discard-pop idiom matches lib/std/cfg/stackify.w; zero callers):
   `reset` pops to the sentinel; `<no drop sites>` inside `reset` per
   `--dump-drop-plan`, i.e. element teardown (if any) lives in `Vec.pop`
   glue. No leak observable from any probe; bulk-free matches header contract.
3. src/compiler/foundation/Arena.w:41-57 — OBSERVATION / T22 / probe P4 PASS /
   refuted (by design; golden test asserts pre-realloc invalidation only):
   raw ids are recycled after `reset`, so a retained stale id whose raw falls
   back in range aliases the new slot (even across lanes). Callers must drop
   ids at `reset`, per "bulk-only via reset" (Arena.w:4). No doc change filed.
4. src/compiler/foundation/Arena.w:70-78 — OK / T22 / probes P2,P3 PASS:
   wrong-lane getters return safe defaults (0/"") and invalid/OOB ids never
   index out of bounds (all paths go through `contains`). No defect.

## Negative controls

- N1 (above) panics as expected; positives not vacuous.
- First-draft edge probe asserting `contains(0)==true` failed, confirming
  probes exercise real semantics rather than mirroring assumptions.

Verdict: COMPLETE
