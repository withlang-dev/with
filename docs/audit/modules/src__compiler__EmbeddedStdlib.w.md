# Audit: src/compiler/EmbeddedStdlib.w @ 450733e5

- Commit: 450733e58a1a7cce14f9cb2084943fc178815111 (HEAD matches; `git rev-parse --short HEAD` = 450733e5)
- Module size: 37 lines, 7 fns (1 const-fn prefix, 6 helpers), 1 extern decl
- Targets traced: T13 ownership/drop, T15 migration fidelity, T22 spec conformance (D39)

## What the module does

Thin facade over generated `compiler.EmbeddedStdlibData` plus the D39
bundle-interface registry (`compiler.BundleInterfaces`). Key function
`embedded_std_resolve_path` (lines 22-31) implements the documented
lookup order: `std/`-guard -> bundle interface text -> embedded source,
returning the canonical `<embedded-std>/<rel>` display path or `""`.
`embedded_std_rel_path` (lines 33-37) is its inverse; `""` is the
miss sentinel throughout, and every in-repo caller checks `.len() > 0`.

## Probes run (seed: out/bootstrap/bin/with-stage1)

- P0 seed exists: `ls -l out/bootstrap/bin/with-stage1` -> 114 MB,
  executable, dated Sep 3. (`seed/`, `bootstrap/` do not exist; the
  task's `seed out/bootstrap/bin/with-stage1` resolves to
  `out/bootstrap/bin/with-stage1`.)
- P1 version: `with-stage1 --version` -> `with v0.15.1.7-g450733e58`
  (matches HEAD).
- P2 positive end-to-end: `use std.fmt` + `print(fmt_int(42))` prints
  `42`. PASS, both from repo root and from `/tmp/embempty/` (no
  `lib/std` nearby, so resolution came from the embedded tree).
  (First attempts with `fmt.println` / `fmt.fmt_int` failed: that API
  does not exist; unqualified `fmt_int` is correct per `lib/std/fmt.w`.)
- N1 negative control: `use std.nonexistent_xyz` -> clean
  `error: import module not found: 'std.nonexistent_xyz'`, graceful
  `error: run failed`, no panic. PASS.

## Findings

None. No defect survived refutation; the module is COMPLETE.

Refuted observations (not findings, recorded so they are not re-filed):

1. (T13, info, refuted as defect) Line 3 declares
   `extern fn with_str_clone_ref` but never uses it (whole file is 37
   lines; zero call sites). Sibling `EmbeddedRuntime.w` has no such
   extern; `BundleInterfaces.w` declares and uses it. Benign dead
   declaration: the build succeeds and no ownership is transferred, so
   there is no leak/double-free path. At most a cleanup nit.
   `src/compiler/EmbeddedStdlib.w:3`.
2. (T22, info, refuted as defect) All wrappers are plain `fn` while
   sibling `EmbeddedRuntime.w` uses `pub fn`, yet six modules
   (`CCodegen.w:967`, `Resolve.w:1055`, `ModuleSource.w:23`,
   `Zcu.w:327`, `Frontend.w:2446`, `Lsp.w:1439`) call them
   cross-module and the shipped stage1 plus live probes P2/N1 pass, so
   visibility works as built. No action.
3. (Out of scope for this module) `Zcu.w:327-331` and
   `CCodegen.w:964-973` read embedded source without consulting
   `bundle_interface_text` first, unlike the canonical reader
   (`ModuleSource.w:19-25`) and this module's own `resolve_path`
   (lines 26-27), which both check the bundle registry first per D39.
   If a diagnostic/source view ever targets a bundle-provided module,
   those two call sites could show non-interface text. Belongs to the
   owners of `Zcu.w` / `CCodegen.w`, not to this module.

## Target verdicts

- T13 ownership/drop: PASS. No manual memory management; all returns
  are owned `str` by value from generated data fns (string literals).
- T15 migration fidelity: PASS. Generator
  (`src/tools/generate_embedded_stdlib.w:154,172`) emits exactly
  `pub fn embedded_std_source_data` /
  `pub fn embedded_std_list_modules_data`, matching the calls at
  `EmbeddedStdlib.w:11,14`.
- T22 spec conformance (D39): PASS. `resolve_path` consults the bundle
  registry before embedded source, matching `BundleInterfaces.w:10-13`
  and the `ModuleSource.w` order; display/rel round-trip is consistent
  and the `""` miss sentinel is honored by all callers.

## Verdict: COMPLETE — src/compiler/EmbeddedStdlib.w conforms on T13, T15, T22; no findings.
