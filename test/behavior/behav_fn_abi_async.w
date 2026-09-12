//! expect-stdout: ok

use pre_d_build_runner

fn main:
    let case_dir = p7_prepare_case("fn_abi_async", "fn_abi_async")
    let source = "use std.task\n" ++
        "type Payload { a: i64, b: i64, c: i64 }\nimpl Copy for Payload\n" ++
        "async fn empty: ()\n" ++
        "async fn number(n: i64): n + 1\n" ++
        "async fn aggregate(value: Payload): value\n" ++
        "async fn main:\n" ++
        "    empty().await\n" ++
        "    assert(number(41).await == 42)\n" ++
        "    let payload = aggregate(Payload { a: 2, b: 3, c: 5 }).await\n" ++
        "    assert(payload.c == 5)\n" ++
        "    print(\"async ok\")\n"
    p7_write(case_dir, "src/main.w", source)
    for target in ["darwin_aarch64", "linux_x86_64", "linux_aarch64", "windows_x86_64", "windows_aarch64"]:
        let audited = p7_run(case_dir, "async_audit_" ++ target,
            "analyze\0src/main.w\0audit:all\0--prelude=core\0--target=" ++ target ++ "\0")
        p7_assert_success(audited, "async FnAbi audit for " ++ target)
        assert(audited.stdout.contains("violations=0"))
    let native = p7_run(case_dir, "async_native", "run\0src/main.w\0--prelude=core\0")
    p7_assert_success(native, "native inferred async returns")
    assert(native.stdout.contains("async ok"))
    print("ok")
