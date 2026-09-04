# Primary verification — `src/BuildGraphKinds.w`

Status: **Complete**  
Primary verifier: root agent  
Source revision: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`  
Source SHA-256: `71859a980cde2703cce16e56ffd3c404f106561a2d98440593f6a6c0de1ce271`  
Source examined: all 134 lines

## Scope examined

The complete module was read inline. It defines the live build-kind number
space, the retired historical number space, build-kind validity and dispatch
classification, diagnostic names, target-kind validity and names, host target
detection, and host/target comparison.

The codebase-memory graph was queried first. Its current `.w` extraction did
not return these symbols, so Tilth was used to enumerate imports and call sites.
Every direct production consumer was examined:

- `src/BuildGraphDispatch.w` dispatches live kinds 7–22;
- `src/BuildGraphMaterialize.w` validates removed/live/implemented build kinds
  and target kinds before materialization;
- `src/BuildGraphOps.w` selects target-dependent object-section behavior;
- `src/main.w` handles kinds 1–4 and 23, while kind 0 deliberately falls
  through to the ordinary binary-build path; and
- `tools/debug_sema_layout.w` imports the module as part of its broad compiler
  debug surface but does not use its exports.

The public producer in `lib/std/build.w`, target-option parser in
`src/compiler/DriverOptions.w`, canonical lowering descriptor in
`src/TargetSpec.w`, platform-runtime selection in `src/compiler/Frontend.w`,
and host `with_sysinfo_os`/`with_sysinfo_arch` implementations were also read.
`rt/windows_aarch64.w` exists and is selected for target kind 6.

The live build-kind table is internally complete: 0–4 and 7–23 are valid and
implemented, 5–6 are retired, 1000–1027 are recognized historical removals,
and no project-kind range is live. Dispatch coverage matches that table. The
unused `BUILD_GRAPH_PROJECT_KIND_MIN/MAX` constants describe the intentionally
empty former range and are recorded as dead compatibility surface, not a
correctness defect.

## Artifact and optimization evidence

The primary agent ran:

```text
./out/bootstrap/bin/with-stage1 build --explain stage1 :stage1
```

The build graph reported `fresh`, included `src/BuildGraphKinds.w` in the
stage1 source set, selected the seed compiler, and showed `-O1` in the stage
arguments.

## Exhaustive controls

`docs/audit/probes/build_graph_kinds_matrix.w` copies the module's pure table and
predicate definitions and exhaustively checks:

- live, removed, and implemented status for every value 0–23;
- removed/invalid status for every historical value 1000–1027;
- invalid values immediately outside all defined ranges;
- the exact diagnostic name for every value 0–23 and 1000–1027;
- target validity and exact names for 0–6 plus invalid boundaries; and
- current-host detection and `target_kind_is_host` behavior.

The matrix passed `check --validate-all` and native execution, printing
`build-graph-kinds-matrix: ok`. The current Linux x86-64 host result also agrees
with the native system-information implementation.

## BGK-001 — the public build graph cannot spell Windows ARM64

Classification: **Confirmed cross-layer completeness defect; candidate unreported**  
Severity: **Medium**  
Blast radius: `build.w` projects that need a Windows ARM64 target  
Confidence: **Very high**

The compiler uses target kind 6 consistently for Windows ARM64:

1. `BuildGraphKinds.w` accepts target kinds 0–6 and names 6
   `windows_aarch64`.
2. `DriverOptions.parse_target_kind` accepts the Windows ARM64 spellings and
   returns 6.
3. `TargetSpec.w` supplies the Windows ARM64 OS/architecture identity, LLVM
   triple, name, and cross-target classification for kind 6.
4. `compiler/Frontend.w` selects `rt/windows_aarch64.w` for kind 6.
5. `lib/std/build.w`, however, declares `BuildTarget` only through
   `windows_x86_64 = 5`; it has no value 6.

The retained probe `docs/audit/probes/build_target_windows_aarch64.w` imports
`std.build` and spells `BuildTarget.windows_aarch64`. Stage1 `check` exits 1
with `unknown field 'windows_aarch64' for type 'BuildTarget'`. This is the
typed public producer consumed by build-graph materialization, so the missing
enum member prevents a project graph from selecting a target the rest of the
compiler recognizes.

Five Whys:

1. A build project cannot select Windows ARM64 because its target enum has no
   such member.
2. The enum is incomplete because it was not extended when compiler target
   kind 6 was added.
3. Nothing mechanically verifies parity between the public enum and the
   compiler's target-kind range.
4. Target identities are declared independently in several modules.
5. A target can therefore become usable on one front door while remaining
   unrepresentable on another.

Repair boundary: add the value-6 public enum member using the repository's
established spelling, and add an exhaustive parity test covering public enum
values, CLI aliases, `BuildGraphKinds`, `TargetSpec`, runtime-file selection,
and every supported host mapping. This is a public-surface completion; it must
not renumber existing values.

## BGK-002 — target identity has multiple unsynchronized authorities

Classification: **Confirmed architectural integrity defect**  
Severity: **Medium**  
Blast radius: every new target, target alias, host mapping, build-graph target,
runtime selection, and diagnostic name  
Confidence: **Very high**

The same target identities and/or numeric values are independently encoded in:

- `BuildGraphKinds.w` (valid range, names, and host mapping);
- `TargetSpec.w` (valid range, names, triples, data layouts, and host mapping);
- `DriverOptions.w` (CLI aliases to numeric values);
- `lib/std/build.w` (public numeric enum); and
- `compiler/Frontend.w` (numeric target-to-runtime selection).

`TargetSpec.w` calls itself the single source of truth, but the compiler does
not consume it as such for these other decisions. BGK-001 is direct evidence
that the tables have already drifted; this is therefore a present integrity
defect, not a speculative maintainability concern.

Five Whys:

1. The public and internal target sets disagree because each owns a separate
   list.
2. Each list is updated manually because consumers exchange bare integers.
3. Bare integers carry no mechanically checkable target identity.
4. No exhaustive repository test compares every independent table.
5. The claimed target descriptor authority is advisory rather than enforced.

Repair boundary: make one target descriptor/table authoritative and derive or
validate the CLI mapping, public enum parity, graph validation/naming, host
mapping, runtime choice, and target lowering from it. If bootstrap layering
prevents direct sharing with `std.build`, retain the public enum but enforce
exhaustive numeric/name parity as a build/test invariant.

## Issue relationship

The primary agent searched the upstream tracker on 2026-09-02 for Windows
ARM64, `BuildTarget`, public build-target parity, and related spellings. No exact
report for BGK-001 or BGK-002 was found.

Closed #425 implemented the general `--target` and cross-compilation path. Its
test plan explicitly mentioned target values surviving through
`std.build.BuildTarget`, but it did not report or close the current missing
Windows ARM64 enum member. No issue was filed during this report-only audit.

## Required regression matrix

- Exhaust every valid build kind, retired kind, historical removed kind, and
  the immediate invalid boundaries for validity, implementation, dispatch, and
  diagnostic name.
- Exhaust every target kind for public enum value, canonical name, accepted CLI
  spellings, triple, data layout, object format, runtime file, host mapping, and
  cross-support result.
- Compile one typed `std.build` project that selects each public target and
  prove the selected numeric identity reaches materialization unchanged.
- Prove unsupported/invalid numeric target values fail loudly before codegen or
  linking, never falling back to the native target.
- Run the parity checks on every supported host architecture so host detection
  in the runtime and target descriptor cannot drift.

## Completion statement

The primary agent examined all 134 source lines, every direct production
consumer, every target producer and downstream target authority, the complete
live/retired dispatch table, platform host implementations, and related issue
history. The pure answer spaces were exhaustively executed, artifact inclusion
and `-O1` were verified, and the retained public-surface failure was reproduced
with the real typed API. Both findings identify the exact source boundary and
repair contract. No candidate in this module remains unclassified, so this
evidence supports marking `src/BuildGraphKinds.w` complete while retaining its
confirmed defects for prioritization.
