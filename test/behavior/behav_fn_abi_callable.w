//! expect-stdout: ok

use pre_d_build_runner
use std.fs

fn body(ir: &str, name: &str):
    for section in ir.split("define "):
        if section.split("\n")[0].contains("@" ++ name ++ "("):
            return section.split("\n}")[0].to_owned()
    ""

fn wide_functions:
    var source = ""
    for shape in ["Large", "Pair"]:
        var parameters = ""
        var types = ""
        var arguments = ""
        for i in 0..65:
            if i != 0:
                parameters = parameters ++ ", "
                types = types ++ ", "
                arguments = arguments ++ ", "
            parameters = parameters ++ f"p{i}: {shape}"
            types = types ++ shape
            arguments = arguments ++ "value"
        source = source ++ "\n@[c_export(\"wide_" ++ shape ++ "\")]\nfn wide_" ++ shape ++
            "(" ++ parameters ++ "): p64\nfn indirect_" ++ shape ++
            "(cb: extern \"C\" fn(" ++ types ++ ") -> " ++ shape ++ ", value: " ++ shape ++
            "): cb(" ++ arguments ++ ")\n"
    source

fn main:
    let case_dir = p7_prepare_case("fn_abi_callable", "fn_abi_callable")
    let source = read_file(p7_join(p7_repo_root(), "test/behavior/lib/fn_abi_callable_fixture.w")).unwrap() ++ wide_functions()
    p7_write(case_dir, "src/callable.w", source)
    for target in ["darwin_aarch64", "linux_x86_64", "linux_aarch64", "windows_x86_64", "windows_aarch64"]:
        let flags = "\0--target=" ++ target ++ "\0--no-prelude\0"
        let ir = p7_run(case_dir, "callable_ir_" ++ target, "ir\0src/callable.w" ++ flags)
        p7_assert_success(ir, "callable IR for " ++ target)
        let large_call = body(ir.stdout, "call_large")
        assert(large_call.contains("call void %"))
        assert(large_call.contains("sret(%Large)"))
        let pointer_call = body(ir.stdout, "call_pointer")
        assert(pointer_call.contains("call i64 %"))
        assert(not pointer_call.contains("alloca %Large"))
        let owned_method = body(ir.stdout, "Pair.bounce")
        if target != "windows_x86_64":
            assert(owned_method.contains("@Pair.bounce(%Pair "))
        if target == "linux_x86_64":
            assert(body(ir.stdout, "wide_Large").split("\n")[0].contains("ptr byval(%Large) %65)"))
        let audited = p7_run(case_dir, "callable_audit_" ++ target, "analyze\0src/callable.w\0audit:all" ++ flags)
        p7_assert_success(audited, "callable audit for " ++ target)
        assert(audited.stdout.contains("violations=0"))
    let native_source = source ++ "\nfn main:\n" ++
        "    let p = Pair { a: 13, b: 29 }\n" ++
        "    let l = Large { a: 2, b: 3, c: 5, d: 7 }\n" ++
        "    assert(call_pair(pair, p).a == 29)\n" ++
        "    assert(call_large(large, l).a == 7)\n" ++
        "    assert(closure_pair(p).b == 13)\n" ++
        "    assert(closure_large(l).d == 2)\n" ++
        "    assert(with_pair(pair, p).a == 29)\n" ++
        "    assert(with_large(named_with_large, l).a == 7)\n" ++
        "    assert(captured_large(l).a == 13)\n" ++
        "    assert(p.bounce(Pair { a: 17, b: 19 }).a == 17)\n" ++
        "    assert(p.echo(l).d == 7)\n" ++
        "    assert(indirect_Large(wide_Large, l).d == 7)\n" ++
        "    assert(indirect_Pair(wide_Pair, p).b == 29)\n" ++
        "    print(\"native ok\")\n"
    p7_write(case_dir, "src/main.w", native_source)
    let native = p7_run(case_dir, "callable_native", "run\0src/main.w\0--debug-alloc\0")
    p7_assert_success(native, "native callback values and ownership")
    assert(native.stdout.contains("native ok"))
    assert(not native.stderr.contains("LEAK"))
    print("ok")
