//! expect-stdout: ok

use pre_d_build_runner
use std.sysinfo

fn probe(root: &str, name: &str, directives: &str, expected: i32, diagnostic: &str, runs: bool):
    let path = "tests/" ++ name ++ ".w"
    p7_write(root, path, directives ++ "\nfn main: print(\"test-body-ran\")\n")
    let result = p7_run(root, "directive-" ++ name, "test\0" ++ path ++ "\0")
    if result.rc != expected:
        print(result.stdout)
        print(result.stderr)
    assert(result.rc == expected)
    assert(result.stderr.contains(diagnostic))
    assert(result.stdout.contains("test-body-ran") == runs)

fn main:
    let root = p7_prepare_case("cli_test_directive_verdicts", "directiveverdicts")
    let host = if os() == "Windows": "windows" else if os() == "Linux": "linux" else: "darwin"
    let other = if host == "linux": "windows" else: "linux"
    let known = "//! known-issue: #916\n"
    probe(root, "skip-known", known ++ "//! skip: directive regression", 0, "", false)
    probe(root, "known-after-skip", "//! skip: directive regression\n" ++ known, 0, "", false)
    probe(root, "host-skip", "//! skip-on: " ++ host ++ " directive regression", 0, "", false)
    probe(root, "host-arch-known", known ++ "//! skip-on: " ++ host ++ "-" ++ arch() ++ " directive regression", 0, "", false)
    probe(root, "other-only-known", known ++ "//! only-on: " ++ other, 0, "", false)
    probe(root, "other-skip", "//! skip-on: " ++ other ++ " directive regression", 0, "", true)
    probe(root, "invalid-known", known ++ "//! skip-on: typo directive regression", 1, "unknown platform value", false)
    probe(root, "missing-reason-known", known ++ "//! skip", 1, "skip missing reason", false)
    probe(root, "known-pass", known, 1, "expected this test to stay red", true)
    let red_path = "tests/known-red.w"
    p7_write(root, red_path, known ++ "\nfn main: missing_name\n")
    let red = p7_run(root, "directive-known-red", "test\0" ++ red_path ++ "\0")
    assert(red.rc == 0)
    assert(red.stderr.contains("red as expected"))
    print("ok")
