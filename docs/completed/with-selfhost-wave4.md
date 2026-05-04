# Wave 4 Implementation Plan

## Resolve / HIR + Module Graph (Withc2)

## Goal

Implement Wave 4 resolution foundations for the self-hosted compiler:

- `ModuleId`-based module graph
- deterministic import resolution (`use`)
- minimal `c_import` support in the graph/resolution pipeline
- stable `DefId` assignment
- resolved-symbol table generation from HIR

Wave 4 exit gate:

- resolved symbol tables from self-host match Stage0 behavior on the Wave 4 corpus.

---

## Inputs and Constraints

- Canonical wave definition:
  - `docs/with-selfhost-plan.md`
  - `docs/with-selfhost-detailed-plan.md`
- Stage0 oracle behavior sources:
  - `bootstrap/src/Driver.zig`
    - `processImports`
    - `resolveModulePath`
    - `parseImportedFile`
    - `processCImports`
  - `bootstrap/src/Parser.zig`
    - `parseUseDecl`
    - `c_import` parsing branch
  - `bootstrap/src/Sema.zig`
    - scope/binding lookup behavior
    - named symbol tables (`named_types`, `fn_sigs`, `variant_lookup`, trait/impl maps)
  - `bootstrap/test/cases/*` import/c_import/module coverage cases
- Reference architecture:
  - Zig:
    - `.reference/zig/src/Zcu.zig`
    - `.reference/zig/src/Package.zig`
    - `.reference/zig/src/Package/Module.zig`
    - `.reference/zig/src/Sema.zig`
  - Rust:
    - `.reference/rust/compiler/rustc_resolve/src/lib.rs`
    - `.reference/rust/compiler/rustc_resolve/src/build_reduced_graph.rs`
    - `.reference/rust/compiler/rustc_resolve/src/imports.rs`
    - `.reference/rust/compiler/rustc_hir/src/definitions.rs`
    - `.reference/rust/compiler/rustc_span/src/def_id.rs`
    - `.reference/rust/compiler/rustc_hir_id/src/lib.rs`

Constraints:

- Stage0 remains semantic oracle; no language redesign in Wave 4.
- Deterministic IDs and ordering are mandatory.
- No type inference or trait solver redesign in this wave (Wave 5+).

---

## Scope

## In scope

- Module graph construction with stable `ModuleId`s.
- Canonicalized import path resolution behavior matching Stage0 search/fallback order.
- `use` expansion/connection in resolution state (without introducing MIR lowering concerns).
- Minimal `c_import` wiring:
  - preserve/import c_import declarations into module graph
  - track link-lib directives
  - stable synthetic defs for imported C symbols (minimal behavior parity with Stage0 surface)
- Stable `DefId` assignment for top-level defs and scoped bindings required for name resolution.
- HIR (resolved form) sufficient to attach symbol references to `DefId`s.
- Deterministic resolved-symbol table dump and parity harness.

## Out of scope

- Full type-system parity (Wave 5).
- Full semantic/type diagnostics parity (Wave 6+).
- MIR lowering/borrow/async/codegen behavior.
- New language features.

---

## Current Gaps (in this tree)

- Import handling is currently AST-pool expansion logic inside driver/frontend, not an explicit module graph with `ModuleId`.
- No first-class HIR resolved layer exists yet (AST is consumed directly by Sema/Codegen).
- No stable `DefId` table exists across modules/scopes.
- No deterministic resolved dump format/CLI path is defined.
- `c_import` handling is mixed with driver behavior and not represented as module-graph/HIR artifacts.

---

## Wave 4 Oracle Contract (Parity Target)

Wave 4 needs a deterministic resolved-symbol-table artifact that can be compared with Stage0 behavior.

Proposed contract for self-host `check --dump-resolved`:

1. Header:
   - `resolved root=<path> modules=<M> defs=<D>`
2. Module table (discovery order):
   - `module[<mid>] file=<fid> path=<canonical_path> imports=<K> decls=<N>`
3. Import edges:
   - `import[<mid>:<i>] kind=use path=<a.b.c> target=<target_mid|-1>`
   - `import[<mid>:<i>] kind=c_import header=<header_spec> target=<target_mid|-1>`
4. Definition table (stable `DefId` order):
   - `def[<did>] module=<mid> parent=<did|-1> kind=<DEF_KIND> name=<symbol> span=<start>..<end>`
5. Binding table (if represented separately from defs):
   - `bind[<scope_key>:<symbol>] def=<did>`

Determinism rules:

- module order is first-discovery DFS/BFS as specified and frozen
- def order is source-order within module, then lexical-order within scopes
- no pointer addresses, no host-dependent absolute paths in deterministic mode

Note:

- Stage0 does not currently expose a dedicated resolved dump artifact. Wave 4 parity harness should normalize Stage0-observable behavior (imports + symbol visibility + resolution outcomes) into the same contract via an oracle adapter script.

---

## Target Deliverables

1. `ModuleGraph` with `ModuleId` ownership and import edges.
2. `DefTable` with stable `DefId` and parent/owner relationships.
3. `Resolver` pass that maps symbols to defs and produces a resolved HIR layer.
4. Minimal `c_import` integration into module graph + def collection path.
5. Deterministic `--dump-resolved` CLI artifact.
6. Wave 4 tests and Stage0 parity scripts.

---

## Target File Plan

Core implementation:

- `src/compiler/foundation/Ids.w` (use/extend `ModuleId`, `DefId`)
- `src/compiler/resolve/ModuleGraph.w` (new)
- `src/compiler/resolve/DefTable.w` (new)
- `src/compiler/resolve/Hir.w` (new resolved HIR schema)
- `src/compiler/resolve/Resolver.w` (new)
- `src/compiler/Frontend.w` (wire resolve stage after parse/import discovery)
- `src/compiler/Zcu.w` (persist graph/resolve state)
- `src/main.w` (add `--dump-resolved` plumbing)

Compatibility path (if needed while old driver path exists):

- `src/Driver.w` and/or `src/Compilation.w` bridge to resolved stage without forking behavior.

Wave 4 tests/scripts:

- `test/wave4/*` resolver and module-graph unit cases
- `test/wave4/resolved_corpus.txt`
- `scripts/run_wave4_resolve_unit_tests.sh`
- `scripts/run_wave4_resolved_parity.sh`

Optional documentation:

- `docs/wave4-resolved-dump-spec.md` (if split out from this plan doc)

---

## Execution Plan (Ordered)

## 0. Freeze Wave 4 Contract + Corpus

- Freeze resolved dump contract and deterministic ordering policy.
- Build Wave 4 corpus from Stage0 cases:
  - `import_local`
  - `import_std_*`
  - `c_import`
  - mixed `use` chains and nested imports
- Include targeted error cases (unresolved import, unresolved symbol, duplicate names).

## 1. Module Graph Model

- Implement `ModuleGraph` tables keyed by `ModuleId`:
  - module metadata (file, canonical path, source hash optional)
  - import list (`use`, `c_import`)
  - parse status / resolve status
- Define root module semantics (`ModuleId` 0).
- Freeze deterministic module discovery order.

## 2. Path Resolution Parity

- Port Stage0 path-resolution behavior from `Driver.resolveModulePath`:
  - source-dir relative lookup
  - `lib/` parent-walk/project-root search
  - `src/` fallback
  - item-import fallback (`foo/bar/Baz.w` -> `foo/bar.w`)
- Canonicalize module paths for graph-key stability.
- Add cycle/duplicate import suppression semantics equivalent to Stage0.

## 3. Minimal `c_import` Integration

- Represent `c_import` edges in module graph.
- Track link libs deterministically (sorted output in deterministic mode).
- Integrate minimal synthetic-def support:
  - stable naming and ownership in `DefTable`
  - no broad C semantic redesign in this wave
- Keep behavior aligned with Stage0 `processCImports` surface semantics.

## 4. Def Model + Stable `DefId`

- Implement `DefTable` with stable insertion order:
  - top-level defs: fn/type/let/extern/trait/impl/c_import synthetic entries
  - nested defs needed for resolver correctness (params/locals where applicable)
- Record per-def:
  - owner module
  - parent def
  - kind
  - name symbol
  - span
- Freeze `DefId` assignment algorithm and document it.

## 5. Scope Graph + Binding Tables

- Build lexical scope representation for resolver:
  - module scope
  - function scope
  - nested block scopes
  - pattern-binding scopes (`match`, `if let`, `while let`, destructure)
- Build deterministic binding maps (`symbol -> DefId`) per scope.
- Encode shadowing/lookup behavior to match Stage0 name-resolution semantics.

## 6. Resolve Pass (AST -> Resolved HIR)

- Introduce resolved HIR node references:
  - identifier uses map to `DefId`
  - module path uses map to target `ModuleId`
- Keep sugar intact (Wave 7 handles lowering) but ensure names are resolved.
- Emit unresolved-name diagnostics equivalent in class/placement to Stage0.

## 7. Frontend Pipeline Wiring

- Insert resolve stage after parse/import discovery and before typed/sema-heavy stages.
- Store resolve artifacts in `Zcu` (`module_graph`, `def_table`, `hir_resolved`).
- Provide compatibility bridge for existing consumers still expecting AST pools.

## 8. Resolved Dump + CLI

- Add `--dump-resolved` handling in `check`.
- Emit deterministic resolved-symbol-table dump using the Wave 4 contract.
- Ensure repeated runs are byte-identical.

## 9. Unit Tests

- Add focused resolver tests:
  - module graph creation
  - import resolution ordering
  - duplicate/cycle suppression
  - path fallback semantics
  - lexical scope + shadowing
  - pattern binding resolution
  - minimal c_import edge/def handling
- Add deterministic ordering tests for `ModuleId` and `DefId`.

## 10. Stage0 Parity Harness

- Add `run_wave4_resolved_parity.sh`:
  - build Stage0 + self-host
  - run corpus through both
  - compare normalized resolved artifacts
  - enforce deterministic self-host rerun check
- Parity checks:
  - module graph shape
  - import edge targets
  - top-level def/binding sets
  - unresolved-name/error outcome classes

## 11. Integration + Documentation

- Document Wave 4 commands and gate.
- Mark progress in top-level self-host plan docs once gate is green.

---

## Validation Strategy

Wave 4 uses two gates:

1. Resolver/module-graph unit correctness:
   - `scripts/run_wave4_resolve_unit_tests.sh`
2. Stage0 behavior parity:
   - `scripts/run_wave4_resolved_parity.sh`
   - strict diff over normalized resolved-symbol artifacts

Corpus policy:

- explicit file list in `test/wave4/resolved_corpus.txt`
- sorted iteration in scripts
- include both success and selected failure cases

---

## Acceptance Criteria (Wave 4 Exit)

1. Module graph with stable `ModuleId` exists and is wired into frontend.
2. Resolver emits stable `DefId` tables and resolved symbol references.
3. `use` and minimal `c_import` behavior matches Stage0 semantics on Wave 4 corpus.
4. Deterministic `--dump-resolved` output exists and is stable across reruns.
5. Wave 4 unit + parity scripts pass locally.

---

## Risks and Mitigations

- Risk: import-path search semantics drift from Stage0.
  - Mitigation: copy search/fallback ordering from `bootstrap/src/Driver.zig` and test each strategy explicitly.
- Risk: `DefId` churn from non-deterministic traversal.
  - Mitigation: freeze traversal order and add deterministic rerun tests.
- Risk: cycle/duplicate import handling differences.
  - Mitigation: centralize visited-module state in `ModuleGraph` and parity-test cycle cases.
- Risk: c_import nondeterminism from environment/toolchain.
  - Mitigation: scope Wave 4 to minimal c_import graph behavior + deterministic synthetic-def ordering.
- Risk: over-coupling resolve to existing Sema path.
  - Mitigation: keep resolve outputs as standalone HIR/def tables with a clear bridge layer.

---

## Known Quirks and Gaps (post-review)

### Quirk: "Parity" script does not diff against Stage0 dump

Stage0 has no `--dump-resolved` flag, so `run_wave4_resolved_parity.sh` cannot do a byte-exact diff. What it actually checks is: (1) exit-code concordance between Stage0 `check` and self-host `check`, (2) self-host `--dump-resolved` is deterministic across two runs, (3) the dump header format matches `^resolved root=.* modules=N defs=M$`. The dump *content* is only verified by the unit-test pattern checks in `run_wave4_resolve_unit_tests.sh`. The script name implies stronger parity than it delivers.

### Quirk: Body traversal only for the root module

`walk_bodies = module_id == 0` in `process_module_with_pool` (Resolve.w line ~342). For imported modules (module ID > 0), only parameter types and return types are walked; function bodies are skipped. `use[*]` entries for calls inside imported module bodies are therefore absent from the dump. This is documented as a performance guard and is intentional for Wave 4.

### Quirk: Param defs carry the parent function's span, not the param's own span

`add_def(..., pool.get_start(fn_node), pool.get_end(fn_node))` for params uses the enclosing function's span for every parameter. In the dump, params show the same span as their owning function.

### Gap: Cross-module symbol resolution is incomplete

Calls to imported functions in the root module body show `def=-1` in the use table (e.g. `use[2] sym=alpha def=-1`). The resolver only resolves locally-defined or locally-bound symbols; it does not yet look up defs across module boundaries. Top-level imports are tracked as module edges, but individual call sites through those imports are not resolved to defs.

### Gap: No error-case tests

The plan listed "include targeted error cases" in the corpus. No `unresolved_import_error.w` or similar error-triggering test exists. All 4 corpus files and all 4 unit-test cases are passing cases only.

### Gap: `run_case` PASS message suppressed if any earlier test failed

The `run_case` function checks `if [[ "$failures" -eq 0 ]]; then echo "PASS..." fi` at the end, but `$failures` is global. If an early test increments it, later passing tests will not print PASS. Exit code is still correct; this is a cosmetic/diagnostic issue in the harness.

### Gap: `resolve_normalize_path` does not handle `..` segments

The path normalizer converts `\` → `/` and collapses `//` and `./`, but does not resolve `..` parent-directory traversal. Paths with `..` are passed through verbatim and could fail to canonicalize to the same key as their equivalent without `..`.

### Gap: `resolve_file_exists` reads the full file to check existence

`resolve_file_exists(path) = with_fs_read_file(path).len() > 0`. This reads the entire file content just to check if it exists. For large files this wastes memory. Not correctness-blocking but worth noting for the multi-file resolution hot path.

---

## Implementation Checklist

- [x] Define Wave 4 resolved dump contract and deterministic ordering rules.
- [x] Create `test/wave4/resolved_corpus.txt`.
- [x] Implement `ModuleGraph` tables keyed by `ModuleId`.
- [x] Port Stage0 module-path search/fallback behavior to self-host resolver path.
- [x] Implement duplicate/cycle import suppression semantics matching Stage0.
- [x] Model `use` edges explicitly in module graph.
- [x] Model minimal `c_import` edges and link-lib tracking in module graph.
- [x] Implement `DefTable` with stable `DefId` assignment.
- [x] Define `DefKind` coverage for Wave 4 (top-level + required scoped bindings).
- [x] Implement lexical scope graph and deterministic binding maps.
- [x] Implement AST -> resolved HIR mapping for identifier/path uses.
- [x] Wire resolve stage into frontend pipeline (`Zcu`/frontend orchestration).
- [x] Add compatibility bridge for existing AST consumers where required.
- [x] Add CLI support for `check --dump-resolved`.
- [x] Implement deterministic resolved dump emitter.
- [x] Add resolver/module-graph unit tests in `test/wave4/`.
- [x] Add deterministic rerun checks for resolved dumps.
- [x] Add `scripts/run_wave4_resolve_unit_tests.sh`.
- [x] Add `scripts/run_wave4_resolved_parity.sh`.
- [x] Verify Wave 4 gates pass locally.
- [x] Mark Wave 4 progress in `docs/with-selfhost-plan.md` and `docs/with-selfhost-detailed-plan.md`.

Current scope note:
- `--dump-resolved` now includes identifier-use mapping from root-module function bodies and signatures; imported modules keep deterministic module/import/def/scope/binding coverage without deep body-use traversal (performance guard for Wave 4).
- Cycle handling is covered in both unit tests and parity corpus (`test/wave4/cases/cycle_*`).
- Bootstrap import resolution now supports both nested relative imports (`use b`) and nested package-qualified imports (`use cycle.b`) via root-source-dir fallback.
