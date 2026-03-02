# Wave 0 Implementation Plan

## Determinism + Golden Baseline (Stage0 as Oracle)

## Goal

Establish a reproducible Stage0 baseline so Withc2 can be validated by diffing stable compiler outputs.

Wave 0 deliverables:

1. Deterministic Stage0 behavior for dump paths.
2. Stable dump flags for:
   - tokens
   - AST
   - typed
   - LLVM IR
3. Golden snapshot capture + diff workflow in `bootstrap/test`.

---

## Current State (from this tree)

- Stage0 already has debug commands in `bootstrap/src/main.zig`:
  - `tokens <file.w>`
  - `ast <file.w>`
  - `ir <file.w>`
- There is no typed dump path yet.
- Existing behavior includes nondeterministic inputs in test tooling:
  - filesystem iteration order (`iterate`, `walk`)
  - `nanoTimestamp()` seeds/stems in package-test flow
  - potential unstable map iteration outputs in some paths
  - absolute source path leakage in IR text (`source_file`, `source_filename`)

Wave 0 should fix determinism in dump/baseline workflows without changing language semantics.

---

## Design Principles (borrowed from references)

- `.reference/zig`: sort before printing and keep dump pathways explicit.
- `.reference/rust`: dedicated dump flags + blessed/golden workflows for text IRs.
- Stage0 policy for Wave 0: fail loud on unsupported dump mode; do not silently degrade dump fidelity.

---

## Scope

### In scope

- `bootstrap/` CLI + driver + sema dump plumbing.
- Deterministic ordering/path normalization needed for stable dump output.
- Golden capture and verification scripts under `bootstrap/test`.

### Out of scope

- Semantic/compiler-architecture rewrites in Stage0.
- New language features.
- MIR-level parity work (Wave 1+).

---

## Output Contract (must be stable)

## `--dump-tokens`

- One token per line, deterministic order (source order).
- Include token tag, byte span, escaped lexeme.
- No pointer addresses, no absolute paths.

## `--dump-ast`

- Canonical AST dump format (not pretty-render formatting output).
- Deterministic field ordering and child ordering.
- Include spans in stable format.

## `--dump-typed`

- Canonical typed dump after Sema.
- Includes declarations, signatures, and expression/binding types in source order.
- Uses stable type names/TypeIds (no addresses).

## `--dump-llvm-ir`

- Deterministic LLVM IR text mode used for golden diffs.
- Normalize/remap unstable headers (module id/source filename/path-dependent lines).
- Keep a raw mode available for debugging when needed.

---

## Execution Plan (ordered)

## 0. Baseline Inventory + Acceptance Spec

- [ ] Create `docs/wave0-dump-spec.md` (or section here) defining exact line format for all 4 dumps.
- [ ] Freeze a deterministic sample corpus list file (for golden generation).
- [ ] Add explicit acceptance checks:
  - same input, same commit, two runs => byte-identical dumps
  - golden diff command returns non-zero on mismatch

## 1. Determinism Audit and Hardening (Stage0)

Targets: `bootstrap/src/main.zig`, `bootstrap/src/Driver.zig`, related helpers.

- [ ] Audit all dump-adjacent code paths for:
  - directory iteration without sort
  - hash-map iteration without sort before output
  - time/random seeds in output-affecting workflows
  - absolute path emission in dump output
- [ ] Add deterministic utilities:
  - stable sort helpers for string/path lists
  - path canonicalization/remap helper (repo-relative in dumps)
- [ ] Remove or gate nondeterministic defaults where dumps/goldens depend on them.
- [ ] Add a deterministic test mode switch (`--deterministic` or equivalent) and enable it for dump/golden commands by default.

## 2. Unified Stable Dump Flags

Targets: `bootstrap/src/main.zig`, `bootstrap/src/Driver.zig`, `bootstrap/src/Sema.zig`, `bootstrap/src/render.zig`, optional new dump modules.

- [ ] Add CLI flags:
  - `--dump-tokens`
  - `--dump-ast`
  - `--dump-typed`
  - `--dump-llvm-ir`
- [ ] Support `check` pathway with dump flags so one entrypoint can produce all oracle artifacts.
- [ ] Keep existing subcommands (`tokens`, `ast`, `ir`) as compatibility wrappers.
- [ ] Implement canonical token dump formatter.
- [ ] Implement canonical AST dump formatter (stable, span-aware; separate from doc/fmt pretty output).
- [ ] Implement typed dump:
  - record/check type information in Sema dump structures
  - print in deterministic AST/source traversal order
- [ ] Implement LLVM IR normalized dump mode:
  - deterministic pass selection (`-O0` for dump path unless explicitly requested)
  - strip/remap unstable headers/path-only variance
- [ ] Add `--dump-out <path|->` and/or `--dump-dir <dir>` for machine workflows.

## 3. Golden Baseline Capture

Targets: `bootstrap/test`, new `bootstrap/test/golden/wave0/...` layout.

- [ ] Define corpus file list (curated, representative, stable size).
- [ ] Add capture script:
  - emits all four dumps per corpus file
  - writes to deterministic path layout
  - supports `--update` (bless) and verify mode
- [ ] Add compare script:
  - diff current dumps vs golden
  - clear failure report grouped by dump kind/file
- [ ] Ensure script ordering is deterministic (sorted corpus processing).

Suggested layout:

```text
bootstrap/test/golden/wave0/
  corpus.txt
  <case>.tokens.golden
  <case>.ast.golden
  <case>.typed.golden
  <case>.llvm.golden
```

## 4. CI + Developer Workflow

Targets: `bootstrap/test/run_phase0_*.sh` + any CI runner scripts.

- [ ] Add `run_phase0_golden_dumps_tests.sh`.
- [ ] Wire into Phase 0 suite.
- [ ] Document local flow:
  - generate/update goldens
  - verify goldens
  - inspect mismatch quickly
- [ ] Enforce no implicit golden updates in CI (verify-only in CI).

## 5. Wave 0 Exit Criteria

- [ ] Stable dump flags produce byte-identical output across repeated local runs.
- [ ] Golden suite passes on clean tree.
- [ ] Golden suite fails on intentional dump drift.
- [ ] Stage0 dump outputs are documented as oracle inputs for Withc2 Wave 1+.

---

## Risk Register + Mitigations

- [ ] LLVM IR nondeterminism across LLVM versions/platforms.
  - Mitigation: normalize known unstable lines; pin toolchain in CI; compare normalized IR only.
- [ ] Typed dump churn due current Sema gaps.
  - Mitigation: stable typed dump schema now; allow additive fields with explicit version bump.
- [ ] Snapshot size/maintenance burden.
  - Mitigation: curated corpus + deterministic selection + fast diff reporting.

---

## Implementation Checklist (copy/paste tracker)

- [ ] Finalize dump format spec.
- [ ] Add deterministic-mode plumbing in Stage0 CLI/driver.
- [ ] Land stable token dump output.
- [ ] Land stable AST dump output.
- [ ] Land stable typed dump output.
- [ ] Land normalized LLVM IR dump output.
- [ ] Add wave0 golden capture script + corpus.
- [ ] Add wave0 golden verify script.
- [ ] Integrate into phase0 test runner/CI.
- [ ] Document developer usage in `docs/`.
- [ ] Mark Wave 0 complete in self-host plan docs.
