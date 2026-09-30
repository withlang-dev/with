//! skip-on: windows issue #802: core-language behavior fails on native Windows (needs root-cause)
//! expect-stdout: ok

use pre_d_build_runner

// #1816 (§18.5b): a one-liner's code is statements by construction, so
// `with -e 'let x = 1'` runs as an implicit main even with nothing but a
// `let`; before, its `let` was read as a module global and the link failed
// with the linker's raw "undefined symbol: _main". An entry FILE of only
// `let`s stays a module of globals (a comptime fn or an importer reads them),
// and building it says why it has no main instead of failing in the linker.
fn main:
    let case_dir = p7_prepare_case("let_only_entry", "letonlyentry")

    let one = p7_run(case_dir, "e-let-only", "-e\0let x = 1\0")
    p7_assert_success(one, "-e let only")

    let two = p7_run(case_dir, "e-let-print", "-e\0let x = 1\0-e\0print(x + 1)\0")
    p7_assert_success(two, "-e let then print")
    assert(two.stdout.contains("2"))

    p7_write(case_dir, "src/lets.w", "let a = 1\nlet b = a + 1\n")
    let file = p7_run(case_dir, "file-lets-only", "run\0src/lets.w\0")
    p7_assert_failure_contains(file, "has no `fn main` and no top-level statement to run", "file of only lets")
    assert(not file.stderr.contains("undefined symbol"))

    print("ok")
