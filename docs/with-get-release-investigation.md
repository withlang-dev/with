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
skip/directive-error verdicts bypass known-issue inversion. The complete
ten-case CLI verdict matrix passes on rebuilt stage2.

The macro/verdict batch passes the full seed-driven build, byte-identical
fixpoint, `audit:all` (zero violations), all 82 `:test` targets, and
`:last-green`. The test battery took 1001.9 seconds and included 1047 behavior
files. Logs: `macro-batch-{full-build,fixpoint,audit-all,test,last-green}.log`.
This is compiler-battery evidence, not floating-package release approval.

OpenSSL still reports an invalid free with the rebuilt stage2. Its check
passes with `WITH_ALLOC_NO_REUSE=1`, confirming that the ownership bug is
still live after macro translation succeeds; no-reuse is diagnostic only.

### Windows macro collection scaling

Run `35197408709` captured native Windows minidumps using the exact compiler
from failed run `35169665692`. Both architectures stop in
`ci_collect_object_macro_values` via `with_str_concat_n`, `str_concat_n_copy`,
and `rt_memcpy`. The x86_64 libcurl frame is at macro 15517 of 33367,
copying an accumulated prefix of 580692 bytes to append the next value.
The source is `values = values ++ "|" ++ name ++ "=" ++ value`.
Evidence: `windows-libcurl-stack-lldb.log`,
`windows-macro-collector-{disassembly,state}.log`, and
`windows-arm-bzip2-lldb.log`. Tracked in
[#1163](https://github.com/withlang-dev/with/issues/1163).

An isolated development patch replaces append-only table strings with
builders. A 33,000-macro inline-header probe also exposed two other costs:
`c_import_decode_escapes +472` recopies the accumulated header on each escaped
newline, and `macro_source_line_from_cursor +216` calls `with_fs_read_file`
for every definition before scanning from line one. The latter native stack
and disassembly are in `macro-source-read-symbol-lldb.log`.
Clang already owns a source buffer and supplies the definition's byte offset;
the patch reads that buffer directly. The standalone bridge and stage1 build
pass. Cold-cache C-import time for 8,000 macros falls from 3389.432 ms to
174.928 ms; 33,000 falls from 45990.103 ms to 326.392 ms. These are local
synthetic measurements; the actual Windows bzip2/libcurl UAT remains required.

The source-line regression also found that a continued identity macro is
omitted while its single-line form works. LLDB shows the unspliced
backslash-newline entering `macro_session_add_from_define_line`
(`macro-continuation-cold-source-lldb.log`). The same source reader now
splices logical definitions, including CRLF. It must remain buildable as a
standalone bootstrap object, before the stdlib is available.

The source-line regression passes on the rebuilt development compiler,
covering first/last lines, no final newline, CRLF, continued bodies, split
macro names and split directives (`macro-source-lines-fixed.log`).

### Install cache destination mismatch

The pinned driver's `build_cache_collect_output_paths` returns the literal
`/Users/eric/with/$HOME/.local/...`, observed on return to
`build_cache_freshness_reason +4520`. Installation expands `$HOME`, so each
gate incorrectly considers the install stale and rebuilds dependents.
Evidence: `wo-install-cache-output-lldb.log`.

The cache now uses the install operation's destination resolver. Its direct
regression passes for project paths, HOME, INSTALL_BINDIR and INSTALL_LIBDIR,
and detects changed destinations, changed contents and deleted outputs.
The frozen pinned seed retains its old implementation until a later reseed.
Tracked in [#1157](https://github.com/withlang-dev/with/issues/1157).

## Remaining root-cause work

Isolated Windows stack jobs reuse the exact failed compiler and PDB.
Run `35196602998` additionally exposed clean-machine floating-get failures:
native `/tmp` does not exist, while ConanClient hardcodes that output path
and suppresses download errors. Filed as
[#1162](https://github.com/withlang-dev/with/issues/1162). The diagnostic
workflow preserves the fresh-get failure before reconstructing the old
binary's scratch environment to investigate the separate header hang.
This setup is not release evidence.

The client patch now uses Windows TMP/TEMP or POSIX TMPDIR and captures tool
output in per-request temporary directories. It reports actual failures and
cleans up after success or failure. Source check and the offline transport
regression pass, including spaces in paths and an unusable temporary directory.
Native evidence: `conan-http-temp-lldb.log`; test evidence:
`conan-internals-tests.log`. Windows validation remains outstanding.

The pinned Darwin seed copies the actual 56 MB x64 Mesa DLL byte-for-byte
through both native and interpreted (`--strict-effects`) ToolFs actions.
Both source and output SHA-256 are
`184b6f374d06a195c07ac458638697b42209ebf31d5a6f08cd269a7165f90d45`.
Windows diagnostic run `35202112398` adds the same copy test under each
architecture's pinned seed, preserving the original and copied DLLs.

- Verify the macro scaling fixes against real Windows package imports; a
  faster synthetic probe is not enough to close the timeout.
- Determine why the copied Windows Mesa DLL is rejected, including file
  integrity and architecture. The earlier sandbox failure is not the
  newest x86_64 failure.
- Verify Linux system-library diagnostics/provisioning and rerun Darwin UAT
  locally with the final compiler; retain the rendered spiral assertion.
- Keep ownership/codegen changes in an isolated batch with full move/drop
  audits, then run floating UAT on all five platforms before publishing.
