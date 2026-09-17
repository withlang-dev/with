# Floating-package release investigation

Work in progress, 2026-09-17. The release remains blocked. No package pins,
platform exclusions, or relaxed UAT verdicts are proposed.

## Failure matrix

Baseline source: `69bf4e70`; diagnostic workflow commit:
`985cc5e0478ceca38041b81117b171ee22c6eb12`.
Fresh Darwin compiler built from the pinned seed, full build exit 0.
Local fixtures use zlib 1.3.2, bzip2 1.0.8, sqlite3 3.53.4,
OpenSSL 4.0.2, libcurl 8.21.0, and raylib 6.0.

| Package | Darwin local | Darwin CI | Linux x86_64 | Windows x86_64 | Windows arm64 |
|---|---|---|---|---|---|
| zlib | check/run pass | pass | pass | pass | pass in initial run |
| bzip2 | check/run pass | pass | pass | C import check/build time out | C import check/build time out |
| sqlite3 | check/run pass | pass | pass | pass | pass in initial run |
| OpenSSL | generated undefined macro; debug allocator double free | compiler invalid free | compiler invalid free | generated undefined macro | generated undefined macro |
| libcurl | check/run pass | pass | pass | C import check/build time out | C import check/build time out |
| raylib | check/run and rendered spiral pass | NSGL pixel format unavailable | missing GL/X11 link libraries | WGL cannot load Mesa DLL (invalid Win32 application) | WGL cannot load Mesa DLL (invalid Win32 application) |

Linux arm64 stops before UAT in the native test gate. Its `skip-on` is
honored internally, then the outer `known-issue` wrapper incorrectly treats
the skip's zero status as an unexpectedly passing test.

Initial run: https://github.com/withlang-dev/with/actions/runs/35143254857.
Stage diagnostics: https://github.com/withlang-dev/with/actions/runs/35163919599.
Windows x86_64 job `105020636622`: both isolated `check` and `build`
stop after `frontend.interface`, before `frontend.c_import` completes.
Neither creates a program. The diagnostic steps use `continue-on-error`
to collect all stages; their displayed successful conclusions do **not**
mean the commands passed. Raw logs show the three-minute timeouts.
The seed-driven UAT no longer fails to rename the executing compiler.

Darwin verification follows the existing local-first release path. Eric's
Mac rendered the spiral successfully on its Apple M5 Max. The hosted NSGL
failure does not establish a limitation of his Mac; no paid runner or local
Actions runner registration is needed.

## Proven roots

### Macro names are marked emitted before translation succeeds

LLDB on the OpenSSL import stops first in
`with_cimport_mark_name_emitted("OSSL_DEPRECATED")` from
`ci_translate_macros` (`src/CImport.w:3054`), then in
`ci_record_untranslated_macro` for the same name. The direct-call guard
subsequently accepts `OSSL_DEPRECATED(4.0)` because the omitted callee is
still marked emitted. This happens on Darwin too; it is not exclusively
an MSVC expansion difference. A forced cold translation cache reproduces it.

Evidence: local `out/with-get-investigation/openssl-macro-emission.log`
and `openssl-macro-lldb.log`. Fix scope: emission registry truthfulness
across every successful/failed function-macro branch, aliases, dependent
object macros, and diagnostics when an omitted name is used.

### HashMap extraction returns shallow owners

The native allocator reports a double free during frontend teardown.
`WITH_ALLOC_NO_REUSE=1` suppresses address reuse and leaves the ordinary
macro diagnostic. With ASLR disabled, address trap `4712080096` records:

1. Allocation in `Zcu.c_import_record_omissions_frontend` for a map key.
2. Free in `sema_clone_str_str_hashmap`, when its `src.keys()` Vec drops
   (`0x1004ece58`, helper +404).
3. Reuse for a trait-selection HashMap allocation.
4. Free through the original omitted-symbol map at `Frontend.w:1780`.
5. Double free when the actual trait map is destroyed.

`MAP_KEYS`, `MAP_VALUES`, and `MAP_ITEMS` produce owning Vecs through
runtime raw-byte copies. They do not establish independent ownership of
non-Copy elements. Reduced string-map programs for all three exhibit stale
reads with `WITH_DEBUG_ALLOC_SCRIBBLE=1`; ordinary runs and `audit:all`
can pass. Map iteration also lowers through `MAP_ITEMS` and belongs in
the acceptance matrix. Do not work around this in the Sema clone helper.

Evidence: `out/with-get-investigation/openssl-trap-all.log`,
`map_snapshots.w`, and `map_keys_reduced.w`. The reducer predicate requires
an ordinary successful run and a scribble-mode failure, preventing reduction
to an unrelated empty-map unwrap panic.

The debugger helper `tools/debug_drop_sites.lldb` currently breaks at trap
function entry, before its address filter. Repeated `--one-liner` options
also discard the intended backtrace command. This tooling defect and the
audit blind spot are filed as [#1160](https://github.com/withlang-dev/with/issues/1160)
and [#1159](https://github.com/withlang-dev/with/issues/1159), respectively.
The allocator root is also recorded on
[#1158](https://github.com/withlang-dev/with/issues/1158#issuecomment-5706888853).

### Test verdict composition

The reduced `known-issue` + unconditional `skip` fixture reaches
`run_test_file_with_build_settings +348` with `w0 = 0` and a nonempty issue
string. The `cbz w0` at `0x10006f1e0` enters the unexpected-pass diagnostic
even though the test body never ran. Evidence:
`out/with-get-investigation/skip-known-branch-lldb.log`.

The first Darwin-specific gate probe additionally ran its body because the
runtime host is `Macos` while `test_gate_os_matches` compares with `Darwin`.
Keep host matching and verdict composition covered separately.

## Implementation verification so far

Function macros now enter the emitted-name registry only on a successful
translation branch. The development build passes, as do the positive macro
dependency fixture and the precise used-omission diagnostic fixture. Spaced,
grouped, nested-expression and alias forms pass a separate check. The new
positive fixture fails on the baseline with a generated reference to the
omitted `ATTRIBUTE` macro.

Clang macro probes also accepted recovery ASTs after parse errors. On the
reduced `#define END { 0, (void *)0 }`, LLDB found a severity-3 diagnostic
in the probe TU while `ci_try_eval_var_init_for_type` returned
`void { 0, null }`. Both ordinary imports and macro probes now use the
same parse-error check; batched type collection excludes invalid recovered
declarations. Evidence: `macro-brace-error-lldb.log` and
`macro-brace-recovery-lldb.log` in the investigation output directory.

The registry fix exposed an ordering regression in CI run `35169665692`:
the existing `behav_c_import_offsetof.w` failed on all five platforms,
before the jobs reached UAT. LLDB in `ci_object_macro_is_function_call`
returned `w0 = 1` for `offsetof(with_offset_point_t, x)`, preventing its
constant translator from running (`offsetof-guard-lldb.log`). The call
guard now runs after the validated constant probe and offsetof translator;
an emitted function macro alone does not prove that its invocation is a
constant. Stage1 build exit 0; eight targeted fixtures pass, covering
packed/nested/flexible layout offsets, constant and runtime macro calls,
invalid probe ASTs, and precise used-omission diagnostics.

Test gates now compare Darwin with the runtime's `Macos` spelling, and
skip/directive-error verdicts bypass known-issue inversion. Direct skip
probes pass; the full CLI verdict matrix awaits rebuilt stage2.

OpenSSL verification remains open: the development stage lacks embedded
generated modules when run outside the compiler tree, and from the compiler
tree its C import reports opaque-by-value types. A full stage chain is needed
to distinguish the known stage1 limitation from a remaining translator defect.

## Remaining root-cause work

Isolated Windows stack jobs reuse the exact failed compiler and PDB.
Run `35196602998` additionally exposed clean-machine floating-get failures:
native `/tmp` does not exist, while ConanClient hardcodes that output path
and suppresses download errors. Filed as
[#1162](https://github.com/withlang-dev/with/issues/1162). The diagnostic
workflow preserves the fresh-get failure before reconstructing the old
binary's scratch environment to investigate the separate header hang.
This setup is not release evidence.

- Capture the Windows C import hang's native stack; stage timing is only
  localization, not instruction-level proof.
- Determine why the copied Windows Mesa DLL is rejected, including file
  integrity and architecture. The earlier sandbox failure is not the
  newest x86_64 failure.
- Verify Linux system-library diagnostics/provisioning and rerun Darwin UAT
  locally with the final compiler; retain the rendered spiral assertion.
- Prove and cover skip/known-issue/directive-error verdict composition.
- Keep ownership/codegen changes in an isolated batch with full move/drop
  audits, then run floating UAT on all five platforms before publishing.
