//! expect-stdout: ok

use pre_d_build_runner

// A scenario that cannot run is not a pass (Eric, 2026-11-11). `with uat`
// skips a scenario whose requirement this host does not meet; under
// `--strict`, the battery's mode, that scenario is BLOCKED and the run
// fails. The battery merged work while the raylib and SDL scenarios were
// skipped behind a locked screen. A scenario that is not for this platform
// is still a skip.
fn main:
    let dir = p7_prepare_case("uat_strict_blocked_scenario", "uat_strict")
    p7_write(dir, "uat/needs.uat", "scenario: needs something this host lacks\nrequires: env WITH_UAT_TEST_NEVER_SET\n\nrun: with --version\n")
    p7_write(dir, "uat/elsewhere.uat", "scenario: for another platform\nplatforms: windows-x86_64, linux-x86_64\n\nrun: with --version\n")
    let lenient = p7_run(dir, "lenient", "uat\0")
    p7_assert_success(lenient, "without --strict an unmet requirement skips")
    assert(lenient.stdout.contains("skip  (requires env WITH_UAT_TEST_NEVER_SET: unset)"))
    let strict = p7_run(dir, "strict", "uat\0--strict\0")
    let ok = strict.rc != 0 and strict.stdout.contains("BLOCKED  (requires env WITH_UAT_TEST_NEVER_SET: unset)") and strict.stdout.contains("skip  (platforms: ")
    if not ok:
        print(f"rc={strict.rc}")
        print(strict.stdout)
    assert(ok)
    print("ok")
