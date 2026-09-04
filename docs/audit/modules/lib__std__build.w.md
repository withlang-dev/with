# Audit: lib/std/build.w @ 450733e5

Scope: read-only source audit of `lib/std/build.w` (3028 lines) at commit 450733e5.
Targets traced: T13 (ownership/drop), T15 (migration fidelity), T22 (spec conformance).
Compiler: out/bootstrap/bin/with-stage1 (seed compiler).
In-repo test coverage: `test/behavior/behav_std_build_api.w` (exists, passes — see P3).

## Module summary

`std.build` is the user-facing typed build-graph construction API. Contents:

- Enums with driver-pinned integer values: `BuildKind` (23 variants, 5/6 reserved
  with a do-not-reuse comment, build.w:33-58), `BuildTarget`, `OptimizeMode`,
  `BuildOutputKind`, `PreludeMode`, `OverflowMode`, `BuildStatus`, `ArtifactKind`,
  `DeclKind`, `CompilerPhase`, `ArchiveEntryKind`.
- Plain data types: `BuildOptions`, `TestOptions`, `BuildGraphOptions`,
  `MigrateOptions`, `SourceSpan`, `DiagnosticSummary`, `Artifact`, `BuildResult`,
  `DeclSummary`, `CompilerMessage(+Envelope)`, `Package`, `ProjectInfo`,
  `Diagnostics`, `SourceEmitter`, `ToolFs`, `ProcessRunner`, `ProcessEnv/Var/Spec`,
  `ArchiveEntry`, `Target`, `Build`, `ActionCtx`, `BuildCtx`, `Download`,
  `WorkspaceCompilePlan`.
- `Workspace` is an `ephemeral` handle with `impl Copy` (build.w:291-299); most
  `Workspace` methods are comptime-evaluator stubs exiting 97 except the native
  path (`ActionCtx.create_workspace`, `add_file/string`, `options/set_options`,
  `compile` via `ws_run_compile_child`).
- Capability-gated driver surface: `tool_capability_valid` (env-token equality)
  enforced once at `BuildCtx.__driver_new` (build.w:504-516);
  `tool_capability_require` (build.w:482-485) rejects only empty tokens
  afterwards — a documented minted-capability trust model (build.w:476-481).
- Pure helpers: path normalize/dirname/relative guards, glob matcher
  (`*` single-star per segment, `**` cross-segment, sorted output), tar
  build/parse (ustar + v7-fallback magic, octal, checksum, pax records),
  stored-block gzip writer, sha256 via `std.crypto.sha256`.
- Graph builders (`Build.executable/library/test/object/archive/action/command/
  install/group/binary_compare/fixpoint_compare/compile_c_object/.../download/
  extract_tar_gz`, `Target.*` modifiers) plus `Build.emit_graph` (v2 text graph,
  build.w:2962-3028) and the native action runner (`Build.__driver_run_action`,
  workspace plan serialize/deserialize, `ws_run_compile_child`).

## Target disposition

- T13 ownership/drop: CONFORMANT. All builder methods (`ProcessSpec.*`,
  `Target.*`, `Build.*`, `ProcessEnv.set`) take `move self`, rebind to
  `var owned/out`, mutate in place and return — the D32 no-vacate idiom, with
  an explicit comment at build.w:369-370. Handle moves out of locals use
  `move` (`Workspace.name` build.w:575, `Workspace.options` build.w:592).
  Cross-boundary strings are cloned (`with_str_clone_ref`) at every
  construction site (`__driver_new` 510-515, glob sort 803-811, plan/state
  clone helpers 2881-2894, download/extract arg pushes 2291-2294/2348-2351).
  `with-stage1 check lib/std/build.w` -> `ok`; no manual memory ops outside
  the `std.crypto.sha256` digest-pointer pair, which matches that module's API.
- T15 migration fidelity: NOT APPLICABLE. `git log --follow -- lib/std/build.w`
  shows continuous native-With development (`#921` native runner phases,
  D32 strict-move work, `#782`, `#750`, `#747`); no C-source migration, no
  forked/duplicated logic. The related driver-side `src/BuildGraphModel.w`
  (native graph model + parser) is a sibling native module, not a migration
  source — divergence between the two serializers is handled under T22.
- T22 spec conformance: CONFORMANT with one latent-divergence observation
  (Finding 1, refuted as non-live). Escape function is byte-identical in logic
  to the driver's `src/BuildGraphModel.w:142` (`\\`, `\t`, `\n`, `\r`;
  verified by reading both). sha256 core matches the independent oracle
  `sha256sum` on `"abc"` (P4). Graph header `WITH_BUILD_GRAPH\t2` and all
  rows pinned by `behav_std_build_api.w` verified live (P3).

## Findings

1. (low, T22, HELD — no live impact) `Build.emit_graph` (build.w:2962-3028)
   serializes only package/default/generated/target/entry/output plus
   system_lib/include_path/define/input/extra_output/dep/arg rows. It omits
   the `write_scope`, `timeout_ms`, `cwd`, `env`, `network`, `parallel` rows
   that the driver's `src/BuildGraphModel.w:187-202` emits and
   `:302-336` parses. Refutation attempt: `grep -rn emit_graph` over
   `build.w` and `src/` finds no live caller — the only in-repo consumer is
   `test/behavior/behav_std_build_api.w`, which pins the subset that exists
   and passes. The live `#921` path runs the graph natively
   (`ws_run_compile_child`, `Build.__driver_run_action`) rather than through
   this text form, so a target using `Target.write_scope/timeout/allow_network/
   allow_parallel/working_dir/with_env` would silently lose those attributes
   only if some future consumer re-adds a text-graph round trip through this
   function. Not filed (per instructions); noted for the owner.

## Probes run (all EXECUTED)

- P1 `with-stage1 check lib/std/build.w` -> `ok` (3028-line module typechecks).
- P2 `/tmp/audit-build/probe_build.w` via `with-stage1 run` -> `probe-ok`.
  Covers: `BuildKind` numeric pins (0/7/23, guarding the reserved 5,6 gap);
  `ProcessSpec` chained builder (`arg/working_dir/timeout/capture/env_var/
  stdin`); `archive_file/dir/symlink_entry` constructors incl. the `""`
  dir source_path; `emit_graph` escaping of a name containing TAB, LF and
  backslash to backslash-t / backslash-n / double-backslash sequences
  (asserted via `contains`).
  Negative control: asserts the graph does NOT contain the raw `we<TAB>ird`
  form — passed.
- P3 `with-stage1 run test/behavior/behav_std_build_api.w` -> `ok`
  (13-target graph, header + 16 row assertions; file exists).
- P4 sha256 oracle: `std.crypto.sha256` of `"abc"` ->
  `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad`,
  byte-identical to `echo -n "abc" | sha256sum` (independent oracle for the
  hash backing `ToolFs.sha256_file` and the download sha256 check,
  build.w:2304-2312).
- HELD: `ToolFs` read/write/glob/tar/gzip black-box probes — every method
  takes `&Self` rooted in a driver-minted `BuildCtx` capability, which a
  standalone probe cannot mint; tar/gzip correctness therefore rests on code
  reading (ustar magic/octal/checksum/pax paths reviewed at
  build.w:1104-1360+) not execution. Glob's fail-closed arms
  (no-wildcard-pattern error, empty-match error, build.w:958-976) reviewed
  by reading only.

## Negative controls

- Escaping negative (P2): raw-tab absence asserted and passed.
- `check` on the full 3028-line module passes with no warnings surfaced.
- Claimed test-file coverage verified: `test/behavior/behav_std_build_api.w`
  exists and passes; no other test file claims to cover this module.

Verdict: COMPLETE
