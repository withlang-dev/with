# Windows header origin filtering (#1109)

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
