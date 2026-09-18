# Audit: src/compiler/ModuleSource.w @ 450733e5

## Verdict: COMPLETE (1 low note, no live defects)

Module: `src/compiler/ModuleSource.w` (29 lines) — D39 single lookup for a
module's text: bundle interface, embedded stdlib, embedded runtime,
filesystem. Consumers: `src/Resolve.w:215` (resolver import loop),
`src/compiler/Frontend.w:1793` (source-text registry),
`src/compiler/Frontend.w:1809` (import merge),
`src/compiler/Frontend.w:2475` (single-file import parse). All four honor
`src.interface` via `parser.enable_interface_mode()`.
Commit verified: `450733e5` (`git rev-parse --short HEAD` = 450733e5).

## Targets traced

- **T13 ownership/drop**: CONFORMING — no `Drop`/destructor/lifetime logic;
  all four arms move an owned `str` into `ModuleSource.text`
  (`bundle_interface_text` returns a `with_str_clone_ref` clone at
  `BundleInterfaces.w:67`; `embedded_std_source`/`embedded_rt_source` return
  owned data; `runtime_read_file` returns owned `with_fs_read_file` output).
  `interface: bool` is `Copy`. No aliasing, no release surface.
- **T15 migration fidelity**: NOT APPLICABLE — no migrator/C-import logic;
  single-commit history (`8c822fd6` landed it with D39 batch C1) and the arm
  order matches the `BundleInterfaces.w:10-13` documented precedence
  (registry before embedded stdlib before filesystem).
- **T22 spec conformance**: CONFORMING — arm order
  (bundle → `<embedded-std>/` → `<embedded-rt>/` → filesystem,
  lines 20-29) matches the header comment and `BundleInterfaces.w:10-13`;
  bundle hit forces `interface: true`, filesystem fallback derives it from
  the `.wi` suffix (line 29), embedded arms correctly force `false`
  (embedded trees are `.w` sources). Empty text = read failure at all
  callers (`Resolve.w:217`, `Frontend.w:1811`, `Frontend.w:2477`).

## Findings

1. (Low, T22, probe: static-trace-only) `src/compiler/Zcu.w:327-331`
   (`source_for_file_id_frontend` decl-table fallback) re-derives text from
   `embedded_std_source`/`embedded_rt_source`/`runtime_read_file` WITHOUT
   consulting `bundle_interface_text`, so the header claim ("diagnostic
   source mapping goes through here") is strictly false on that path — a
   bundle-provided `<embedded-std>/…` module rendered via the fallback would
   show embedded source instead of its `.wi` text, and without interface
   context. REFUTATION ATTEMPTED: unreachable in-repo — every parse path
   that populates the decl tables first records the file registry
   (`Frontend.w:1793-1795`, `Frontend.w:1825`, `Frontend.w:2483`), and the
   fallback is only reached when the file id is absent from that registry,
   which is checked FIRST (`Zcu.w:320-322`, #661 fix). Downgraded to latent
   note; suggests routing the fallback through `module_source_read` for
   defense in depth. No caller exhibits the failure.
2. (Note, T22, probe: static-trace-only, NOT a numbered defect)
   `bundle_interfaces_register_wi` (`BundleInterfaces.w:94-95,101-103`)
   stores even an empty trailing section (`""`), which line 21's
   `len() > 0` test then treats as "not bundle-provided", silently falling
   through to embedded/filesystem source with `interface: false`.
   REFUTED as live defect: no in-repo emitter path was found to produce an
   empty `module <path>` section (registration callers at
   `Compilation.w:475,541,576` reject section-less files loudly), and an
   empty (zero-decl) module would have no declarations to mismatch. Edge
   only; recorded so a future emitter change re-checks it.

## Probes run (`out/bootstrap/bin/with-stage1`, verified present via `ls`)

- P1 embedded-stdlib read (PASS): `/tmp/msaudit/hello.w` with
  `use std.option` resolved the import — failure surfaced at line 4
  (`unknown method 'unwrap_or'`), i.e. past import resolution/merge,
  proving the `embedded_std_source` arm end to end.
- N1 negative control (PASS): `use std.nonexistent_xyz` →
  `error: import module not found: 'std.nonexistent_xyz'`, the clean
  empty-text path (no crash, no phantom source).
- Bundle-interface arm not probed live (no `--link-bundle` fixture built);
  verified by static trace: `Compilation.w:541-543` registers `.wi`
  sections before resolution, `module_source_read` consults the registry
  first (line 20-22), and all four consumers enable interface mode.

Caller searches used REGEX mode only (`module_source_read`,
`bundle_interface_text|embedded_std_source|embedded_rt_source|runtime_read_file`,
`ModuleSource|module_source`, `bundle_interfaces_register_wi`).
No issues filed. Compiler sources untouched (read-only).

## Verdict: COMPLETE (1 low note, no live defects)
