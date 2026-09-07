# Primary verification — `src/TargetSpec.w`

Status: **Complete**  
Primary verifier: root agent  
Source revision: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`  
Source SHA-256: `8cac4a283ab48542c9a3a5aa45bad0985593c4466e7837388680af84f0969a4e`  
Source examined: all 114 lines

## Scope examined

The complete module was read inline. It owns the process-global active target
kind and exposes target selection, native/host equivalence, host detection,
resolved OS and architecture, LLVM triple, display name, and cross-support
policy.

The codebase-memory graph was queried first. Its `.w` extraction did not return
the module's symbols, so Tilth was used to enumerate every production importer
and call site:

- `src/compiler/Compilation.w` installs the selected kind and sends the
  resulting triple to the LLVM bridge;
- `src/Parser.w` uses the selected architecture for `@[target]` filtering;
- `src/ComptimeEval.w` substitutes selected-target OS/architecture for allowed
  comptime sysinfo calls;
- `src/Codegen.w` selects target-specific C and internal ABI lowering;
- `src/compiler/Frontend.w` selects the in-unit platform runtime source;
- `src/compiler/Link.w` selects the native/cross linker, sysroot architecture,
  runtime variant and platform object; and
- `src/main.w` validates supported cross targets before compilation.

The independent target declarations in `BuildGraphKinds.w`,
`compiler/DriverOptions.w`, `lib/std/build.w`, and the platform runtime modules
were also traced. The build graph's compilation loop and cache boundary were
read because they can replace or retain the active target after initial CLI
validation.

Applicable overview targets examined: 2–3, 8, 12–14, 17–19, and 21–24. The
module does not allocate or own resources and has no suspension, borrow, drop,
or synchronization behavior.

## Normative boundary

Specification §18.5 declares cross-compilation a normal mode and exposes
`with build --target <triple>`. Section 18.5a requires unsupported non-native
selections to fail loudly rather than fall back to native output. It also says
`BuildTarget` can represent non-native targets. Closed #425's acceptance
criteria repeat that target values must be represented and must never silently
produce native artifacts.

## Artifact and optimization evidence

The primary agent ran:

```text
./out/bootstrap/bin/with-stage1 build --explain stage1 :stage1
```

The stage was `fresh`; its source list included `src/TargetSpec.w`, selected the
seed compiler, and carried `-O1`.

## Working controls

The following retained controls passed:

- `docs/audit/probes/target_spec_direct_matrix.w` imports the real module with
  `-I src` and checks all kinds 0–6 against active-kind round trips, OS,
  architecture, LLVM triple, display name, host/native equivalence, and
  cross-support policy. Its explicit `-O1` build succeeded and execution
  printed `target-spec-direct-matrix: ok`.
- `docs/audit/probes/target_spec_surface.w` was emitted as minimal no-std/no-runtime
  LLVM IR for native and every explicit kind. All seven invocations succeeded.
  The emitted triples were the exact x86-64/aarch64 Linux, Darwin, and Windows
  triples declared by `TargetSpec`; LLVM supplied a matching per-target data
  layout; and `@[target]` retained the x86 body (`ret i32 86`) for x86 targets
  and the ARM body (`ret i32 64`) for aarch64 targets.
- Unknown and unrecognized target spellings exited nonzero. A truly missing
  value at the end of the command produced the required
  `--target requires a target triple argument` diagnostic.
- A build-graph target with an explicit non-host `.target(...)` was rejected
  before compilation with the required loud `not implemented yet` diagnostic.
  Thus the test helper's current lack of a target parameter is unreachable for
  cross targets, not a present silent fallback.
- Direct-source `--target aarch64-unknown-linux-gnu --emit-obj -O1` produced an
  `ELF 64-bit ... ARM aarch64` object. This is the negative control for the
  project-build failure below: the target descriptor and LLVM bridge can emit
  the requested architecture when the selection reaches them.

## TGT-001 — custom `build.w` silently erases CLI and manifest target selection

Classification: **Confirmed silent artifact-mislabeling defect; candidate unreported**  
Severity: **Critical**  
Blast radius: every custom `build.w` executable/library/object/archive target
whose target remains at the API's default `BuildTarget.native`; both explicit
CLI `--target` and `[target].default` project configuration  
Confidence: **Very high**

`docs/audit/probes/target_spec_cli_project` declares an ordinary executable through
`ctx.new_build().executable(...)`; its source has mutually exclusive
`@[target("x86_64")]` and `@[target("aarch64")]` bodies.

On this Linux x86-64 host:

1. `with-stage1 build :target-probe --target aarch64-unknown-linux-gnu -O1`
   exited 0.
2. `file` identified the result as an x86-64 ELF, not ARM64.
3. The binary executed successfully and printed `86`, proving the parser also
   selected the host-only source branch.
4. Repeating through `[target] default = "aarch64-unknown-linux-gnu"` with no
   CLI target likewise exited 0, produced x86-64, and printed `86`.
5. The direct-source control above produced a genuine ARM64 object from the
   same compiler, source, requested target, and optimization level.

Exact source chain:

1. `DriverOptions.parse_build_command_options` stores the parsed target in
   `BuildCommandOptions.target_kind` and records whether it was explicit
   (`DriverOptions.w:413-422`).
2. `build_command_apply_project_target_default` supplies `[target].default`
   when no explicit CLI value exists (`main.w:2188-2194`), and
   `build_command_validate_target` validates this base option.
3. `load_build_graph_from_build_w` configures graph evaluation with those base
   options (`main.w:1513-1534`), so build-time target-dependent behavior sees
   the requested foreign target.
4. Every `target_new` initializes `Target.target_kind` to
   `BuildTarget.native`/0 (`lib/std/build.w:1807-1823`), and materialization
   preserves that value.
5. `build_options_for_graph_target` clones the validated base options and then
   unconditionally executes `options.target_kind = target.target_kind`
   (`main.w:1657-1662`). Zero is therefore treated as an explicit per-target
   override rather than the absence of one.
6. The graph validator accepts zero as host (`main.w:1731-1736`), and each
   `Compilation.configure_options` calls `set_target_kind(0)`, resetting both
   `TargetSpec` and the LLVM bridge to native before parsing and codegen.

The result is internally hybrid: `build.w` evaluation may observe the requested
cross target while the source compilation, target guards, ABI, object format,
and linker see native.

Five Whys:

1. The produced artifact is native because per-target compilation resets the
   active kind to zero.
2. It resets because the graph target's default value overwrites the base
   selection unconditionally.
3. The same enum value means both “inherit the command/project target” and
   “explicitly force native.”
4. The build graph has no optional/inherit representation or override bit.
5. Tests cover direct-source and no-`build.w` cross selection, but not a custom
   default target under a non-native CLI/manifest selection.

Repair boundary: resolve the effective target exactly once with explicit
precedence—an explicit per-target choice, otherwise the already validated
CLI/manifest project choice—and carry that effective value through graph
validation, cache identity, parser/comptime, ABI/codegen, runtime selection, and
linking. The public graph representation needs an unambiguous inherit state (or
an explicit-target bit); do not overload `native` as both a value and absence.
Any unsupported effective target must exit nonzero before writing an artifact.

## TGT-002 — the claimed target authority is process-global and duplicated

Classification: **Confirmed architectural integrity defect; shared with BGK-002**  
Severity: **Medium**  
Blast radius: all target-aware parsing, comptime, ABI, codegen, build graph,
runtime selection, and linking  
Confidence: **Very high**

`TargetSpec.w` describes itself as the single source of truth, but target
identity remains independently encoded in `BuildGraphKinds.w`, CLI aliases in
`DriverOptions.w`, numeric public values in `std.build`, platform branches in
`Frontend.w` and `Link.w`, and a second process-global triple buffer in
`LlvmBridge.w`. BGK-001 already demonstrates drift: internal kind 6 is Windows
ARM64, while the public enum stops at kind 5.

The descriptor is also a mutable process global rather than state owned by a
`Compilation`. Current ordinary compilation is serialized or process-isolated,
so no concurrent corruption was reproduced; however, TGT-001 demonstrates that
constructing/configuring another compilation changes the semantic target for
all consumers. That coupling is a present integrity boundary, not a thread-race
claim.

Repair boundary: give each `Compilation` one validated immutable target
descriptor and pass/read it through parser, comptime, ABI, codegen, and link
state. Derive or exhaustively validate all public names/numbers, CLI aliases,
runtime mappings, and LLVM configuration against that descriptor. Until the
global is removed, every compilation entry must set it exactly once and no two
compilations may be semantically interleaved.

## TGT-003 — host-kind comment excludes an implemented target value

Classification: **Documentation defect**  
Severity: **Super low**  
Blast radius: maintainers reading `target_spec_host_kind`  
Confidence: **Certain**

The comment says “shared 0-5 numbering,” while the immediately following
function returns 6 for Windows ARM64 and the module header correctly documents
0–6. The code is correct; the local comment is stale. Repair by changing only
the comment to 0–6 when production fixes are authorized.

## Collateral confirmed finding queued for `BuildGraphCache.w`

While changing only the requested `-o` path on the retained project probe, the
second build exited 0 from cache but did not create the new requested output.
The exact omission is visible in source: cache signature/output collection use
only `BuildGraphTarget.output` (`BuildGraphCache.w:503-553`), while the actual
path is resolved later from CLI `options.output_path` or a default
(`BuildGraphSupport.w:10-17`, `main.w:1785-1790`, `1987-1998`). An empty target
output therefore records no primary artifact at all, and changing `-o` is not
part of freshness. This is confirmed and candidate unreported, but
`BuildGraphCache.w` remains unchecked until its full primary audit classifies
the complete cache matrix.

## Issue relationship

The primary agent searched the upstream tracker on 2026-09-02 for custom
`build.w` target loss, target-option native fallback, `TargetSpec`, target-kind
parity, and output-path cache terms. No exact report for TGT-001, TGT-002,
TGT-003, or the collateral cache defect was found.

- Closed #425 established `--target` and explicitly forbids native fallback;
  it does not report the custom-graph overwrite.
- Closed #450 established manifest target defaults and likewise does not cover
  their loss in custom `build.w` execution.
- Open #761 concerns the D30 runtime ABI migration, not target-option
  precedence or cache output identity.

No issue was filed during this report-only audit.

## Required regression matrix

- All accepted aliases for native and kinds 1–6; missing, unknown, and malformed
  values; space and equals CLI forms.
- Direct-source, synthesized project, and custom-`build.w` builds under both CLI
  `--target` and manifest default, with and without an explicit per-target
  selection.
- Explicit precedence cases: CLI versus manifest, per-target versus CLI, true
  explicit native versus inherited target, and multiple targets with different
  effective selections.
- For every effective target: parser guard, comptime OS/arch, LLVM triple/data
  layout, C/internal ABI, object architecture, runtime source/object, linker
  flavor, and artifact path must agree.
- Every unsupported combination must fail loudly before producing or caching an
  artifact; no target-dependent build graph may be paired with a differently
  targeted compile.
- Interleaved and parallel compilation controls must prove target state cannot
  bleed between `Compilation` instances.
- Cache tests must include explicit/default output paths, changed `-o`, deleted
  artifacts, target changes, and graph-target inheritance.

## Completion statement

The primary agent examined all 114 source lines, every production consumer, all
independent target authorities, target installation into LLVM, build-graph
precedence, and the applicable specification and issue history. The finite
descriptor table and target-selected IR surface were exhausted inline. The
critical native-fallback defect was reproduced through both public selection
front doors and isolated with a working direct-source ARM64 control. Every
retained finding names the exact branch and repair boundary; the unrelated
cache discovery is captured without prematurely checking its module. This
evidence supports marking `src/TargetSpec.w` complete while retaining all
confirmed defects for prioritization.

## Catch-up addendum (`450733e5`, read-only source review)

The delta splits `target_spec_name()` and adds `target_spec_resolved_name()`
(`src/TargetSpec.w`, ~line 93): kind 0 ("native") resolves through
`target_spec_host_kind()` for bundle/manifest spelling, while the bare name
keeps the old spelling. Review assessment (source only): the split is
coherent with the `.wo` keying design, but every caller of the old spelling
must be re-checked for which semantic it needed — a caller wanting the
resolved name and getting the bare one (or vice versa) mis-keys a bundle
slot or mis-names an artifact. Review note R-2 is now resolved read-only: bare-name callers are
diagnostics (`CImport.w:594`, `Link.w:670`, `:1160`, `Frontend.w:1421`) plus
cross-link paths gated on `target_spec_is_native()` (`Link.w:1087-1091`
returns early for kind 0, so `cross/native/` is unreachable); resolved-name
callers are exactly the bundle/ABI surfaces (`Compilation.w:1293` manifest
line, `Link.w:1017-1018` bundle agreement, `BundleFingerprint.w:56`
header). No mis-keying found. Retained findings are unaffected
(this hunk touches neither the descriptor table nor the IR surface).
