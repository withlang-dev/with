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

### Windows library filenames lost a significant prefix (#1171)

Conan's current OpenSSL Windows package contains `lib/libcrypto.lib` and
`lib/libssl.lib`. `conan_library_name_from_path` applied the Unix `lib`
prefix convention before removing any extension, producing `crypto` and
`ssl`; the Windows linker therefore searched for different filenames.

LLDB stops on the exact `name.slice(3, name.len())` branch with input
`libcrypto`, start 3, and end 9, then observes the returned `crypto`.
Evidence: `out/with-get-investigation/windows-openssl-manifest.txt` and
`conan-library-name-strip-lldb.log`. The manifest is from recipe revision
`b700c658ab174d6ef1bbd719ca441236`, x86_64 package
`2962650defb331e6d5396b541575d7735fb220d7`.

The fix handles `.lib` first and preserves its basename, including a `lib`
prefix. Unix `.a`, `.so`, and `.dylib` retain their existing convention.
The twelve-case internal fixture passes (`conan-library-names-after.log`),
covering OpenSSL, import libraries, unprefixed names, versioned Unix shared
objects, and non-library input. Native Windows UAT is still required.

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

Run `35205173022` proves that collection was only the first scaling cost.
The Windows bzip2/libcurl dumps at 1, 17, and 33 seconds progress into
`ci_lookup_simple_literal_macro_value -> ci_find_str -> ci_str_matches_at`.
The table header contains length `0x1117f0` (1,120,240 bytes); every constant
initializer lookup scans that table. Native evidence is retained in
`ci-35205173022-bzip2-lldb.log`,
`ci-35205173022-macro-lookup-disassembly.log`, and
`ci-35205173022-lookup-memory.log` under `out/with-get-investigation/`.

Macro values and misses now use keyed maps, retaining the old first-value
selection. A separate per-session name/index map replaces backward scans
for aliases and private dependency expansion, retaining their last-definition
selection. Raw values can contain `|` without colliding with a table delimiter.

The expanded regression also exposed a private-expression omission:
`#define _WITH_PIPE (1 | 2)` used by `PIPE(x)` was found in the table but
rejected by the literal-only lookup. LLDB observes the lookup return length
zero at `ci_lookup_simple_literal_macro_value+248`; the caller had skipped
private expansion outside migration mode. Evidence:
`macro-private-expression-return-lldb.log`. Import now expands private
dependencies before expression parsing through the same indexed expander.

The full build and 33,000-definition/256-initializer regression pass, including
bitwise private values, nested function macros, aliases, parameter shadowing,
and unparenthesized C precedence. Six related macro fixtures also pass.
Logs: `macro-private-expansion-full-build.log`,
`macro-private-expansion-matrix.log`, and `macro-index-behav*.log`.
The byte-identical fixpoint, compiler analysis (2,528,011 facts, zero
violations), and full seed-driven suite (1,051 behavior files plus all
other gates) pass. Logs: `macro-index-fixpoint.log`,
`macro-index-audit-all.log`, and `macro-index-full-test.log`.
The pinned seed's final evidence check also passes
(`macro-index-last-green.log`).
Cold-cache checks and actual Darwin bzip2/libcurl UAT programs also pass
(`macro-index-darwin-{bzip2,libcurl}-{check,run}.log`). Actual Windows
package UAT remains required; Darwin OpenSSL still reaches the independently
tracked map ownership failure (#1158).

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

The macro-scaling, install-cache and Conan-transport batch passes the full
seed-driven build, byte-identical fixpoint, `audit:all` with zero violations,
the full test battery (929.8 seconds), and `:last-green`. Targeted stage2
tests include the 33,000-macro fixture and offline transport matrix. Logs:
`scaling-transport-{full-build,fixpoint,audit-all,test,last-green}.log`.

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

Both Windows relative-copy probes passed. Repeating the exact external
absolute source in run `35202995832` produced a **zero-byte** copied DLL
on both architectures while the pinned driver reported success. This explains
the later WGL invalid-Win32-application error. Logs:
`windows-x64-dll-external.log` and `windows-arm-dll-external.log`.

LLDB on the pinned Darwin driver confirms the legacy resolver joins
`D:/a/_temp/mesa/opengl32.dll` onto the project root
(`dll-copy-drive-resolver-lldb.log`). The current compiler correctly rejects
out-of-project absolute paths, but its copy operation still discards read
errors: LLDB returns a zero-length str for `missing.dll` to
`ComptimeEvaluator.eval_toolfs_capability_method`, which then writes it and
returns success (`dll-copy-missing-read-correct-lldb.log`). The native
ToolFs copy and binary-read implementations use the same unchecked reader.
Filed as [#1164](https://github.com/withlang-dev/with/issues/1164).

The UAT now declares a project-relative Mesa input. Native and interpreted
ToolFs operations check the read status before writing or creating output
directories. The stage2 regression passes all sixteen cases: both execution
modes, copy and binary read, with missing, directory, empty, and binary
sources. Read failures preserve an existing destination; empty and binary
files retain their exact contents. The pinned seed accepts the revised build
graph and its workflow pins pass `:seed-driver`. Logs:
`toolfs-{read-status-dev,stage2,binary-matrix,raylib-graph,seed-driver}.log`.
The complete Windows raylib UAT still needs to run with these changes.
The actual 58,609,152-byte Mesa DLL also copies with an identical SHA-256
under both rebuilt execution modes (`toolfs-large-dll-{native,interpreted}.log`).

### Linux system libraries and the arm64 source-build gap

Native GDB on the Linux compiler reaches
`conan_write_known_system_package+1092` with the metadata writer's status
zero, then returns success. `libGL.so` is absent on that host. A successful
metadata write is the only condition behind "using system package";
evidence is `linux-system-package-success-gdb.log`. The existing x86_64
release failure supplies the actual missing GL/X11 linker verdict.

The isolated #1165 change reads the linker's diagnostic rather than
duplicating its library search. It retains failure status and original
errors, names missing development libraries and known Debian/Ubuntu
packages, and provisions GL/X11 plus Xvfb in CI and the local Linux host.
GNU/LLVM diagnostic fixtures, the compiler source check, the local release
tool source check, and an actual ELF lld missing-library invocation pass.
Logs: `linux-link-{diagnostics-test,main-check,real-lld}.log` and
`linux-release-local-check.log`. Darwin bootstrap and the resulting stage1's
diagnostic fixture pass (`linux-link-dev.log`, `linux-link-stage1-test.log`).
Native Linux arm64 bootstrap and the resulting stage1's fixture check also
pass (`linux-link-diagnostics-dev.log`, `linux-link-stage1-native-check.log`).
End-to-end native program linking remains blocked by #1167 below.
Issue: https://github.com/withlang-dev/with/issues/1165.

There is a second Linux arm64 blocker. Conan's current raylib 6.0 revision
`4e39a8be96a10eb27035f97e83620a2d` contains Linux x86_64 binaries but no
Linux armv8 binary. Native GDB observes `conan_source_unsupported_recipe`
returning 1 to `conan_install_source_fallback+512`, which enters the
unsupported-source diagnostic. The recipe needs CMake configuration and
dependency generation for GLFW/OpenGL. Merely deleting the guard would
incorrectly compile every discovered C source without those semantics.
Evidence: `linux-raylib-packages.json`, `linux-raylib-source-rejection-gdb.log`,
and the captured recipe/config/conandata files. Source-build support for
this recipe class is required before the floating arm64 UAT can pass;
tracked in https://github.com/withlang-dev/with/issues/1166.

The fresh Linux compiler at `196f0a00` confirms this gap affects all six
floating packages: zlib 1.3.2, bzip2 1.0.8, sqlite3 3.53.4, OpenSSL 4.0.2,
libcurl 8.21.0, and raylib 6.0. Each fresh project initializes, then `get`
rejects unsupported source fallback. The current package API responses
contain no Linux armv8 binaries. Evidence: `linux-arm-current-get-*.log`
and `linux-*-packages.json`. This needs complete source configuration,
dependencies, patches, and installation semantics for the recipe classes;
raw compilation of every C file cannot meet that contract.

A clean-host probe with that compiler also fails before running even a
one-line program: `collect2: fatal error: cannot find 'ld'`. Native GDB
at `with_exec_argv` observes `cc` plus `-fuse-ld=lld`, from
`LinkStageCommand.run`. `link_stage_make_link_command` unconditionally
adds that flag on Linux; collect2 searches PATH for the absent `ld.lld`.
The build SDK on PATH masks the runtime dependency, violating the
self-contained release invariant. Evidence:
`linux-current-no-sdk-path-run.log`, `linux-current-linker-exec-gdb.log`;
tracked in https://github.com/withlang-dev/with/issues/1167.

The native-cc fix removes `-fuse-ld=lld` and the lld-only `--icf=all`
from ordinary Linux user-program links. Compiler and cross links retain
their explicit LLVM linker plan. A seed-driven native Linux full build
passes (880.9 s), its release compiler runs with no SDK on PATH, and
`behav_linux_platform_linker.w` restricts the child PATH to system cc,
as, ld, and nm: the baseline fails with missing ld; the fixed stage2
prints `ok`. Evidence: `linux-platform-linker-before.log`,
`linux-platform-linker-after.log`, `linux-platform-linker-full-build.log`.

The same release compiler's real build of a project linking GL and X11
first fails with GNU ld's missing-library errors plus the exact
`libgl-dev libx11-dev` installation suggestion. After installing those
development packages, the unchanged project links successfully.
Evidence: `linux-native-missing-libraries.log` (rc=1) and
`linux-native-provisioned-libraries.log` (rc=0).

- Verify the macro scaling fixes against real Windows package imports; a
  faster synthetic probe is not enough to close the timeout.
- Verify Windows raylib rendering with the declared project-relative Mesa
  input; the empty-DLL root is proven and the copy regression passes.
- Verify Linux system-library diagnostics/provisioning and rerun Darwin UAT
  locally with the final compiler; retain the rendered spiral assertion.
- Implement complete source-build fallback for the six current Linux arm64
  recipes, and remove the clean-host external linker dependency.
- Keep ownership/codegen changes in an isolated batch with full move/drop
  audits, then run floating UAT on all five platforms before publishing.

### Implicit Result tails freed their transferred payload (#1169)

The source-metadata parser exposed a separate ownership failure. A function
returning `Result[str, str]` with an `if` or `match` tail copied its branch
join temporary into `Ok`, then freed the same temporary on body-frame exit.
The reduced program retains `scalar("sources").unwrap()`, allocates the
same-sized `scalar("changed").unwrap()`, and observes the first value change.

The native allocator with reuse disabled and the address trap proves the
first free occurs in `source_yaml_scalar`; LLDB then stops at
`lower_fn_with_sig+6224` while lowering the reduced function. The implicit
`Ok` aggregate assignment at `src/MirLower.w` replaced `result` without
calling `consume_moved_operand`. Other aggregate transfer paths already
consume their operands. The fix consumes this payload before leaving its
temporary frame. Evidence: `result-tail-wrap-live-lldb.log` and the reduced
`result_branch_reduced.w` under `out/with-get-investigation/`.

The regression retains returned strings, vectors, and structs across a
second allocation, covering direct, both `if` arms, and both `match` arms.
The fresh stage2 passes with zero allocator leaks. Full build, byte-identical
fixpoint, compiler audit (2,528,140 facts, zero violations), move audit
(15 PASS, zero differences), and drop audit (136 PASS, zero regressions)
pass. Logs: `result-tail-full-build.log`, `result-tail-fixpoint.log`,
`result-tail-audit-all.log`, `result-tail-after-move-audit.log`,
`result-tail-stage2-drop-audit.log`, and `result-tail-stage2-matrix.log`.
The full seed-driven suite also passes, including all 1,052 behavior files,
and `last-green` archives verified evidence. Logs:
`result-tail-full-test.log` and `result-tail-last-green.log`.

The MIR validator accepted this invalid moved-payload cleanup; its missing
check is filed separately as #1170. The parser also exposed an independent
early-return leak from an enclosing statement temporary frame (#1172),
which this change does not claim to fix.
