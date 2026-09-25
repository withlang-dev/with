//! expect-stdout: ok
use pre_d_build_runner
use std.process

// §9.1 / D43 / D60: visibility must not change inference or runtime behavior.
// Generate both spellings from ONE body, so neither half can acquire a
// convenient annotation while the other keeps testing inference.
fn main:
    let override = env("WITH_RETURN_INFERENCE_TEST_COMPILER")
    let compiler = if override.len() > 0: override else: p7_compiler_path()
    let source = "var counter: i32 = 0\n$VISfn unit: assert(true)\n$VISfn bump: counter = counter + 1\n$VISfn incomplete(b: bool):\n    if b: assert(true)\n$VISfn value: later()\n$VISfn later: 42\n$VISfn choose(b: bool):\n    if b: 7\n    else: 9\n$VISfn identity[T](x: T): x\npub type Counter { n: i32 }\nimpl Counter:\n    $VISmut fn bump(): self.n = self.n + 1\n    $VISfn read(): self.n\nfn main:\n    unit()\n    bump()\n    incomplete(false)\n    assert(counter == 1)\n    assert(value() == 42)\n    assert(choose(true) == 7 and choose(false) == 9)\n    assert(identity(13) == 13)\n    var c = Counter { n: 0 }\n    c.bump()\n    assert(c.read() == 1)\n    print(\"same\")\n"
    let mixed = "$VISfn mixed(b: bool):\n    if b: 1\n    else: \"one\"\nfn main:\n    mixed(true)\n"
    for mode in 0..2:
        let visibility = if mode == 0: "" else: "pub "
        let label = if mode == 0: "private-return-inference" else: "public-return-inference"
        let dir = p7_prepare_case(label, "return_inference")
        p7_write(dir, "src/main.w", source.replace("$VIS", visibility))
        let result = p7_run_with_compiler(compiler, p7_repo_root(), label, "run\0" ++ p7_join(dir, "src/main.w") ++ "\0")
        p7_assert_success(result, label)
        assert(result.stdout.trim() == "same")
        p7_write(dir, "src/main.w", mixed.replace("$VIS", visibility))
        let rejected = p7_run_with_compiler(compiler, p7_repo_root(), label ++ "-mixed", "check\0" ++ p7_join(dir, "src/main.w") ++ "\0")
        p7_assert_failure_contains(rejected, "cannot infer return type: if arms have types i32 and str", label)
    print("ok")
