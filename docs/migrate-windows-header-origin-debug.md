# Windows header origin filtering (#1109)

## Mixed separators and generated include strings

The next Windows run (34425873898, commit 88eaa3f1) exposed two remaining
failures. Its synthetic header location was
`input\Windows Kits/ucrt/system.h:2:12`: neither the all-forward-slash nor
the all-backslash pattern matched. A local minimal header with this mixed
spelling reproduces the failure. LLDB observed `ci_is_system_path` return
`w0=0` to `ci_migrate_decl_is_filtered+80`, PC 0x1001889d8; its `tbz` takes
the unfiltered branch at +92. Evidence: `/tmp/with-mixed-origin-lldb.log`.
The shared classifier now normalizes separators before testing path
components, covering arbitrary mixtures without enumerating spellings.
The regression adds mixed Windows Kits, MSVC, and SDK paths and executes
the retained project code for every case.

The macro-origin fixture separately embedded its absolute Windows path in
a generated With string without escaping backslashes. The captured Clang
diagnostic names `D:awithwith/...` instead of `D:\a\with\with/...`.
The fixture now uses forward slashes in that generated include string.
The migration and import assertions remain unchanged.

The source check, development stage2 build, mixed-header regression and
macro-origin regression pass locally. Logs:
`/tmp/with-macro-ci-source-check.log`, `/tmp/with-macro-ci-stage2.log`,
`/tmp/with-macro-ci-windows-test.log`, `/tmp/with-macro-ci-origins-test.log`.
Native Windows CI is still required; the earlier local success below did
not establish Windows correctness.

## Initial shared classifier

Macro PR #1107's Windows x86_64 and AArch64 lanes fail in the two new
migration regressions before their assertions. The x86 capture from run
34415160251 attempts to translate UCRT inline formatters, then reports an
unsupported filtered `__stdio_common_vfwprintf` reference. Linux x86_64's
separate failure is the known SDK-export expectation; Linux AArch64 passed.

The reduced local repro includes a header under `Windows Kits/ucrt/mock.h`
with an uncalled inline helper referring to `extern int __sdk_private`.
Migration incorrectly enters that helper and fails on its private variable.
LLDB observed `ci_is_system_path` return `w0=0` for
`out/windows-origin/Windows Kits/ucrt/mock.h:3:19` to
`ci_migrate_decl_is_filtered+80`, PC 0x100776d24. Its `tbz` takes the
unfiltered branch at +92. Evidence: `/tmp/with-macro-windows-origin-lldb.txt`
and `/tmp/with-macro-windows-origin-repro.log`.

The declaration filter duplicated a Unix-only path classifier. The bridge's
macro classifier already recognized Windows Kits and MSVC. Declaration
locations now use that same classifier, and generic SDK paths accept both
separator spellings. No translator failure is suppressed.

`behav_migrate_windows_header_origins` covers Windows Kits, MSVC, and generic
SDK paths. It requires private SDK declarations/macros to be absent, retains
the project alias, and executes the project code. Native Windows runs also
exercise libclang's backslash locations. The private token-paste fixture
uses `1U ## LL`, retaining its unsigned bit-63 assertion with a 64-bit C
literal on both LP64 and LLP64 targets.

The source check and development stage1/stage2 build passed. All four
targeted regressions passed: Windows header origins, macro origins,
private token paste, and `c_import` macros without a C compiler. Logs:
`/tmp/with-macro-windows-stage2-build.log` and
`/tmp/with-windows-behav_*.log`. The reduced migration also succeeds with
the project function intact and the SDK helper absent.

The existing core SDK-export assertions remain unchanged pending Eric's
ruling. This follow-up is separate from the frozen failed CI commit
`23079d82`; it is not a claim of a green complete test battery.
