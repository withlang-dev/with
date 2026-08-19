//! expect-stdout: ok

use pre_d_build_runner

fn argv(blob: str, value: str) -> str:
    blob ++ value ++ "\0"

fn main:
    let case_dir = p7_prepare_case("cli_test_command_args", "p7clitestargs")
    p7_write(case_dir, "tests/one.w", "//! expect-stdout: one\n\nfn main:\n    print(\"one\")\n")
    p7_write(case_dir, "tests/two.w", "//! expect-stdout: two\n\nfn main:\n    print(\"two\")\n")

    let help = p7_run(case_dir, "test-help", argv(argv("", "test"), "--help"))
    p7_assert_success(help, "test help")
    assert(help.stdout.contains("Usage: with test"))
    assert(help.stdout.contains("with test test/behavior/a.w test/behavior/b.w"))

    let multi = p7_run(case_dir, "test-multi-files", argv(argv(argv("", "test"), "tests/one.w"), "tests/two.w"))
    p7_assert_success(multi, "test multi files")
    assert(multi.stdout.contains("one"))
    assert(multi.stdout.contains("two"))

    let filtered = p7_run(case_dir, "test-filter-multi-files", argv(argv(argv(argv(argv("", "test"), "--filter"), "main"), "tests/one.w"), "tests/two.w"))
    p7_assert_success(filtered, "test filter multi files")
    assert(filtered.stdout.contains("one"))
    assert(filtered.stdout.contains("two"))

    print("ok")
