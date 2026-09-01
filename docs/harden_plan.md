# Hardening the whole project: wire the guardrails to where they bite

Status: PLAN (2026-09-01, whole-project assessment). Nothing here is
implemented yet. Owner: Eric. Companion: `docs/harden_migrate.md` (the
migrator-specific plan; item 7 below points at it).

## The diagnosis

172k lines of With; a 987-file behavior corpus, 746 compile-error
fixtures, 211 spec tests, a drop-audit matrix, deep-debugging tooling
(`analyze`/`audit:all`/`reduce`/MIR dumps), a byte-identical fixpoint
invariant, CI with Linux and Windows self-host lanes. The skeleton is
strong. The weak points are one species: **guardrails that exist but
are not wired to the places that would make them fire.**

Evidence from a single day (2026-09-01):
- `1c50ae46` — a ten-line borrow-return shape produced wrong code in the
  seed, at -O0 and -O1, for months; found only when std.build first ran
  natively.
- #925 — `Vec[str].iter()` element views pass garbage to `&str` params,
  silently.
- #926 — compiler-source `into_iter()` links fail while `with check`
  says ok.
- #929 — unknown string escapes silently drop the backslash.
- `analyze lib/std/build.w audit:all` → 11 violations nobody knew about,
  because nothing runs audits over our own code.

Ranked by how much silent wrongness each item can hide.

## 1. A differential oracle: comptime evaluator vs native

The comptime evaluator is a second, independent implementation of With
semantics in the same binary. `test/comptime_diff` (6 files) is the
idea in embryo. Scale it:

- A battery lane runs the ENTIRE `test/behavior` corpus through the
  evaluator and natively, and diffs stdout/exit per file. Any divergence
  is a real bug in one implementation.
- Exclusions must be explicit per file (`//! no-comptime: <reason>` for
  programs that genuinely can't run interpreted — fibers, raw syscalls),
  never silent.
- Expected first harvest: #925-class marshalling bugs, promotion/
  conversion divergences, evaluator gaps (each of which is a real
  finding: the evaluator runs every build.w).

Gate: lane green; exclusion list reviewed as a number that only goes
down.

## 2. Audit and validator ratchets over our own code

`audit:all` / `--validate-all` / `--validate-ownership` run only on
ad-hoc repros today.

- Battery + CI lane: `analyze <file> audit:all` over every `lib/std/*.w`
  and a maintained list of `src/*.w` modules (start with MirLower,
  SemaCheck, CodegenDispatch, ComptimeEval).
- Baseline the current violation count PER FILE
  (`out/.build-state/audit-baseline.tsv`, checked in); the lane fails on
  any increase; the number is worked to zero and the baseline deleted.
- #927 (std.build's 11 findings) is the first ratchet target.

## 3. Determinism beyond self-compile

Fixpoint proves stage2 == stage3 for the compiler compiling itself;
nondeterminism that only manifests on other inputs escapes.

- Battery lane: compile a sampled behavior subset twice (fresh
  Compilation each), hash objects, fail on mismatch. Cheap; makes the
  "no unordered-map iteration" discipline (2 sites in src today)
  mechanical.

## 4. Loud-not-silent in the language surface

- #929: unknown escape → compile error (five-line lexer fix, outsized
  payoff); optionally support `\u{...}`.
- #926: `with check` is structurally blind to missing symbols. The
  iterate-tier gate for compiler-source changes is `:dev` (already the
  doctrine); make the seed constraint (below, item 5) diagnosable so the
  failure reads "not in seed stdlib" instead of "unknown type".
- #925: fix + fixtures that pass a view of every fat element type to a
  `&T` parameter (the exhaust-the-matrix discipline).

## 5. Seed resilience: a ring and a drill

The seed is one binary from one release asset; recovery is a memory
file; "every PR bootstrappable from a tagged seed" is prose.

- Keep a local seed ring (`src/main` plus the last N release seeds
  under `out/seeds/`); `:seed` can fall back along the ring.
- CI lane: build main from seed N-1. Turns the bootstrap rule into a
  check, and catches the seed-API constraint (compiler sources resolve
  `use std.*` against the seed's EMBEDDED stdlib; new stdlib API is
  compiler-usable only post-reseed) as a class, with a diagnostic that
  names it.

## 6. Ownership bookkeeping → validator invariants

977 `unsafe` sites in src; reset-on-move queues, moved-field marks,
three flush variants, statement frames, drop kinds. The bug class is
"bookkeeping not undone when a later decision reverses an earlier one"
(`1c50ae46`: adjust-after-lower; #695/#696: per-edge move transfer
drift).

- For each bug class, a MIR validator invariant so the next instance is
  a loud validator failure: e.g. "no reset queued for a place borrowed
  at return", "no StorageDead before the local's last read in the same
  block", "moved-field marks cleared when the moving operand is
  abandoned".
- Extend the drop-audit matrix with the dimensions the bugs came from:
  borrow-returned-after-statement, view-to-param per fat element type,
  accessor-then-method chains.

## 7. Corpus asymmetry

| area | files | note |
|---|---|---|
| behavior | 987 | strong |
| compile_errors | 746 | strong |
| spec | 211 | vs 31 spec sections — audit which sections have none |
| d_acceptance | 181 | good |
| debug_alloc | 73 | good |
| codegen | 16 | thin for a native compiler |
| internals | 14 | thin |
| migrate | 5 | vs a 16.5k-line engine — see harden_migrate.md |
| non_compliant | 2 | the D22/D27 NON-COMPLIANT matrices should be here as xfail pins |
| lsp | 0 | only exercised via selfhost intercept lanes |

- Every spec sentence the implementation doesn't meet gets an xfail
  fixture (16 exist — extend the pattern), so the compliance gap is a
  number that only goes down.
- LSP gets direct fixtures (request/response pairs), not only the
  intercept suites.

## 8. Finish D30 (in-unit runtime)

Ruled, not done. 698 `extern fn` declarations in src over the
deprecated `with_*` seam; five per-platform rt files edited by hand for
one probe today; #901's user-segfault class; #761's mixed-generation
link corruption. In-unit compilation deletes the corruption class rather
than fencing it, and collapses the per-platform duplication to one
source with platform arms.

## 9. Windows: alive or labeled

CI self-host lanes exist (good). RSS accounting stubs to 0, 18 tests
carry `skip-on: windows`, build.w treats cross-target as unimplemented.
Either the skip list ratchets down with an owner and a lane that counts
it, or Windows is labeled best-effort in docs/mission.md. Half-maintained
targets rot silently.

## 10. Process into targets

The battery/reseed checklist lives in CLAUDE.md prose and agent memory;
the traps (commit before battery, never edit mid-battery, wake holds,
never pipe `with build` through `tail`) are human discipline.

- One `:release-gate` target runs the whole sequence — build →
  fixpoint → move-audit → drop-audit → audits (item 2) → determinism
  (item 3) → oracle (item 1) → test → test-green → last-green — and
  emits one verdict line. No partial batteries.
- CI runs `:release-gate` (today it runs build + fixpoint + test only —
  no audits).

## If only three

1. Item 1 — the differential oracle (finds bugs we don't know exist).
2. Item 2 — audit/validator ratchets (stops known classes regrowing).
3. Items 5 + 10 — seed-N-1 lane and `:release-gate` (turn the two most
   fragile processes into checks).

## Order of work

Items 4 and 2 first (small, loud, immediately protective), then 1
(largest finder), then 10, 5, 6, 3, 7, 9, 8. Each item is its own
batch; ownership/codegen-touching items (4, 6) stay alone in their
batteries per the isolation rule.
