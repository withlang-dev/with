# Audit: src/BuildGraphSupport.w @ 450733e5

- Commit: 450733e5 (verified `git rev-parse --short HEAD`)
- Module: 341 lines, path/argv helpers shared by build-graph execution
- Uses: Resolve, BuildGraphModel, BuildGraphRuntime, compiler.Runtime; extern `with_str_clone_ref`

## Verdict: INCOMPLETE (1 low-severity finding)

### Finding 1 (Low, T22 spec conformance / edge behavior, probe HELD)
- Location: [src/BuildGraphSupport.w](/home/shawn/workspace2/with/src/BuildGraphSupport.w:54) (`build_graph_dirname`), affects [basename](/home/shawn/workspace2/with/src/BuildGraphSupport.w:63)
- Detail: `build_graph_dirname("/")` returns `""` (last_slash=0, `slice(0,0)`), whereas POSIX dirname gives `"/"`. Consequently `build_graph_path_basename("/")` returns `""` instead of `"/"`. Same class: trailing-slash inputs (e.g. `"a/"` yields dirname `"a"` rather than POSIX `"."`).
- Impact: low — call sites deal with project-relative build paths where bare-`"/"` is unlikely; no caller observed passing root. Flagged as edge-case conformance note, may be intentional simplification.
- Probe: HELD — no `run` probe executed (child batch budget spent on `check`); traced by code reading only.

## Target traces
- T13 ownership/drop: no custom Drop/free in module; all returned strings built via owned ops (`slice`, `++`, `with_str_clone_ref`, `runtime_str_clone`, f-strings). Clone discipline looks consistent (`resolve_paths`, `clone_strings`, `sorted_strings` clone on insert). No finding.
- T15 migration fidelity: validators mirror conservative containment policy (`..` substring reject, absolute-path reject, `$`-prefix reject, control-byte/NUL reject). `single_star_pattern_matches` treats multi-`*` as no-match (conservative). `sorted_strings` is a stable insertion sort (strict `< 0` insert) — O(n^2) but correct for small listings. `times_report` explicitly keeps durations/sizes out of hashed inputs (comment, lines 306-313). No finding.
- T22 spec conformance: except Finding 1, validators/containment checks cover output/entry/extra_outputs with install/promote/clean exemptions at lines 166-199; NUL validation covers entry/output/inputs/args at lines 211-226 (defines only newline-checked at 133-140 — noted, NUL in defines not checked here, but defines path unknown; not filed).

## Probes run
1. `out/bootstrap/bin/with-stage1 check src/BuildGraphSupport.w` → `ok` (EXECUTED, pass).
2. `wc -l` → 341 lines (EXECUTED).
3. Behavioral `run` probes (dirname/basename/glob/validators) — HELD: reason = two-batch tool budget exhausted after source read + check probe.

## Negative controls
- None executed (HELD — same budget reason).
