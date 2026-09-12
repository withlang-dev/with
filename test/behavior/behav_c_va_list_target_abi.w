//! expect-stdout: ok

use pre_d_build_runner

fn va_ir_body(ir: &str, name: &str) -> str:
    for section in ir.split("define "):
        if section.split("\n").get(0).contains("@" ++ name ++ "("):
            return section.split("\n}").get(0).to_owned()
    ""

fn main:
    let case_dir = p7_prepare_case("c_va_list_target_abi", "va_list_abi")
    p7_write(case_dir, "src/probe.w", "extern fn va_probe(args: c_va_list) -> i32\npub unsafe fn forward(args: c_va_list) -> i32: va_probe(args)\n@[c_export(\"exported\")]\npub unsafe fn exported(args: c_va_list) -> i32: va_probe(args)\npub type VaBox { byte: u8, args: c_va_list }\npub fn storage_size() -> i64: sizeof[c_va_list]()\npub fn box_size() -> i64: sizeof[VaBox]()\npub fn box_align() -> i64: alignof[VaBox]()\n")
    p7_write(case_dir, "src/return.w", "@[c_export(\"return_args\")]\npub fn return_args(args: c_va_list) -> c_va_list: args\n")
    p7_write(case_dir, "src/from_pointer.w", "extern fn va_probe(args: c_va_list) -> i32\npub unsafe fn from_pointer(args: *mut c_va_list) -> i32: va_probe(*args)\n")
    p7_write(case_dir, "src/indirect.w", "pub unsafe fn indirect(cb: extern \"C\" fn(c_va_list) -> i32, args: c_va_list) -> i32: cb(args)\n")
    p7_write(case_dir, "src/indirect_return.w", "pub unsafe fn indirect_return(cb: extern \"C\" fn(c_va_list) -> c_va_list, args: c_va_list) -> c_va_list: cb(args)\n")
    p7_write(case_dir, "src/indirect_from_pointer.w", "pub unsafe fn indirect_from_pointer(cb: extern \"C\" fn(c_va_list) -> i32, args: *mut c_va_list) -> i32: cb(*args)\n")
    p7_write(case_dir, "src/explicit_pointer.w", "pub fn explicit_pointer(cb: extern \"C\" fn(*mut c_va_list) -> i32, args: *mut c_va_list) -> i32: cb(args)\n")
    p7_write(case_dir, "src/with_callback.w", "pub fn probe(args: c_va_list) -> i32: 7\npub unsafe fn indirect(cb: fn(c_va_list) -> i32, args: c_va_list) -> i32: cb(args)\npub unsafe fn caller(args: c_va_list) -> i32: indirect(probe, args)\n")
    for target in ["darwin_aarch64", "linux_x86_64", "linux_aarch64", "windows_x86_64", "windows_aarch64"]:
        let flags = "\0--target=" ++ target ++ "\0--no-prelude\0"
        let ir = p7_run(case_dir, "va_list_ir_" ++ target, "ir\0src/probe.w" ++ flags)
        p7_assert_success(ir, "va_list IR for " ++ target)
        let size = if target == "linux_x86_64": 24 else: if target == "linux_aarch64": 32 else: 8
        assert(va_ir_body(ir.stdout, "storage_size").contains(f"ret i64 {size}"))
        assert(va_ir_body(ir.stdout, "box_size").contains(f"ret i64 {size + 8}"))
        assert(va_ir_body(ir.stdout, "box_align").contains("ret i64 8"))
        let exported = va_ir_body(ir.stdout, "exported")
        assert(exported.contains("@va_probe(ptr "))
        if target == "linux_aarch64":
            assert(exported.contains("alloca { i64, i64, i64, i64 }, align 8"))
            assert(not exported.contains("@va_probe(ptr %0)"))
        else:
            assert(exported.contains("@va_probe(ptr %0)"))
        let matrix = p7_run(case_dir, "va_list_matrix_" ++ target, "analyze\0src/probe.w\0matrix:name~va_probe" ++ flags)
        p7_assert_success(matrix, "target-specific ABI matrix for " ++ target)
        if target == "linux_x86_64":
            assert(matrix.stdout.contains("value-ref=1"))
            assert(matrix.stdout.contains("place-address"))
        else:
            assert(matrix.stdout.contains("value-ref=0"))
            assert(not matrix.stdout.contains("place-address"))
        if target == "linux_aarch64":
            assert(matrix.stdout.contains("needs-copy=true"))
            assert(matrix.stdout.contains("temporary-address"))
        let audit = p7_run(case_dir, "va_list_audit_" ++ target, "analyze\0src/probe.w\0audit:all" ++ flags)
        p7_assert_success(audit, "target-specific ABI audit for " ++ target)
        assert(audit.stdout.contains("violations=0"))
        let returned = p7_run(case_dir, "va_list_return_" ++ target, "ir\0src/return.w" ++ flags)
        if target == "linux_x86_64":
            assert(returned.rc != 0)
            assert(returned.stderr.contains("return type 'c_va_list' is not C-ABI-expressible"))
        else:
            p7_assert_success(returned, "C-expressible va_list return for " ++ target)
        let from_pointer = p7_run(case_dir, "va_list_from_pointer_" ++ target, "ir\0src/from_pointer.w" ++ flags)
        p7_assert_success(from_pointer, "C va_list call from an existing place for " ++ target)
        let forwarded = va_ir_body(from_pointer.stdout, "from_pointer")
        if target == "linux_aarch64":
            assert(forwarded.contains("alloca { i64, i64, i64, i64 }, align 8"))
            assert(not forwarded.contains("@va_probe(ptr %0)"))
        if target == "linux_x86_64":
            assert(forwarded.contains("@va_probe(ptr %0)"))
        let indirect = p7_run(case_dir, "va_list_indirect_" ++ target, "ir\0src/indirect.w" ++ flags)
        p7_assert_success(indirect, "C va_list callback for " ++ target)
        let indirect_body = va_ir_body(indirect.stdout, "indirect")
        if target == "linux_aarch64":
            assert(indirect_body.contains("alloca { i64, i64, i64, i64 }, align 8"))
        if target == "linux_x86_64":
            assert(not indirect_body.contains("alloca { i64, i64, i64 }, align 8"))
        let with_callback = p7_run(case_dir, "va_list_with_callback_" ++ target, "ir\0src/with_callback.w" ++ flags)
        p7_assert_success(with_callback, "With va_list callback for " ++ target)
        for source in ["indirect", "with_callback", "indirect_from_pointer", "explicit_pointer"]:
            let callback_audit = p7_run(case_dir, source ++ "_audit_" ++ target, "analyze\0src/" ++ source ++ ".w\0audit:all" ++ flags)
            p7_assert_success(callback_audit, source ++ " ABI audit for " ++ target)
            assert(callback_audit.stdout.contains("violations=0"))
        let indirect_return = p7_run(case_dir, "va_list_indirect_return_" ++ target, "analyze\0src/indirect_return.w\0audit:all" ++ flags)
        if target == "linux_x86_64":
            assert(indirect_return.rc != 0)
            assert(indirect_return.stderr.contains("not C-ABI-expressible"))
        else:
            p7_assert_success(indirect_return, "C va_list callback return for " ++ target)
    let header = p7_run(case_dir, "va_list_header", "emit-c-header\0src/probe.w\0")
    p7_assert_success(header, "C header for va_list parameter")
    assert(header.stdout.contains("#include <stdarg.h>"))
    assert(header.stdout.contains("exported(va_list "))
    p7_write(case_dir, "src/native.w", "type VaBox { byte: u8, args: c_va_list }\nfn main:\n    var value: VaBox\n    let offset = (&raw const value.args as i64) - (&raw const value.byte as i64)\n    assert(offset == 8)\n    print(\"offset ok\")\n")
    let native = p7_run(case_dir, "va_list_native_offset", "run\0src/native.w\0")
    p7_assert_success(native, "physical va_list field offset")
    assert(native.stdout.contains("offset ok"))
    let invalid = p7_run(case_dir, "va_list_invalid_target", "analyze\0src/probe.w\0audit:all\0--target=invalid_target\0--no-prelude\0")
    assert(invalid.rc != 0)
    print("ok")
