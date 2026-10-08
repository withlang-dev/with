//! expect-stdout: ok

// D75 (§16.2b.5): a `...` definition has the C calling convention, and
// `ap.arg[T]()` is lowered for the target's va_list (TypeLayout's
// c_va_list kind) the way clang lowers va_arg: a char* walk in 8-byte slots
// on Darwin arm64 and Windows; SysV x86_64's gp/fp offsets (general
// registers while gp_offset <= 40, vector registers while fp_offset <= 160,
// then the overflow area) on Linux and Darwin x86_64; AAPCS64's negative
// gr/vr offsets on Linux arm64. The list starts in its binding
// (llvm.va_start) and ends with its scope (llvm.va_end).
use pre_d_build_runner

fn va_ir_body(ir: &str, name: &str) -> str:
    for section in ir.split("define "):
        if section.split("\n")[0].contains("@" ++ name ++ "("):
            return section.split("\n}")[0].to_owned()
    ""

fn main:
    let case_dir = p7_prepare_case("variadic_definition_target_abi", "va_def_abi")
    p7_write(case_dir, "src/defs.w", "pub type Trio { a: i64, b: i64, c: i64 }\npub unsafe fn ints(n: i32, ...) -> i64:\n    var ap = va_start()\n    var total: i64 = 0\n    for i in 0..n:\n        total = total + ap.arg[i64]()\n    total\npub unsafe fn doubles(n: i32, ...) -> f64:\n    var ap = va_start()\n    var total = 0.0\n    for i in 0..n:\n        total = total + ap.arg[f64]()\n    total\npub unsafe fn trio(t: Trio, ...) -> i64: t.a + t.c\npub fn plain_trio(t: Trio) -> i64: t.a + t.c\n")
    for target in ["darwin_aarch64", "darwin_x86_64", "linux_x86_64", "linux_aarch64", "windows_x86_64", "windows_aarch64"]:
        let flags = "\0--target=" ++ target ++ "\0--no-prelude\0"
        let ir = p7_run(case_dir, "va_def_ir_" ++ target, "ir\0src/defs.w" ++ flags)
        p7_assert_success(ir, "variadic definition IR for " ++ target)
        assert(ir.stdout.contains("@ints(i32 %0, ...)"))
        let ints = va_ir_body(ir.stdout, "ints")
        let doubles = va_ir_body(ir.stdout, "doubles")
        for body in [ints, doubles]:
            assert(body.contains("call void @llvm.va_start.p0(ptr"))
            assert(body.contains("call void @llvm.va_end.p0(ptr"))
        if target == "linux_x86_64" or target == "darwin_x86_64":
            assert(ints.contains("icmp ule i32") and ints.contains(", 40"))
            assert(doubles.contains("icmp ule i32") and doubles.contains(", 160"))
        else if target == "linux_aarch64":
            assert(ints.contains("{ ptr, ptr, ptr, i32, i32 }, ptr") and ints.contains("i32 0, i32 3"))
            assert(doubles.contains("{ ptr, ptr, ptr, i32, i32 }, ptr") and doubles.contains("i32 0, i32 4"))
            assert(ints.contains("icmp sge i32") and ints.contains("icmp sle i32"))
        else:
            assert(not ints.contains("icmp ule i32") and not ints.contains("icmp sge i32"))
            assert(ints.contains("i64 8"))
        // The C convention, not With's: an aggregate crosses the variadic
        // definition as C passes it (`byval` on SysV x86_64), while With's
        // own convention passes an aggregate over two words as a plain
        // pointer on every target (ABI v11), never `byval`.
        assert(ir.stdout.contains("@plain_trio(ptr %0)"))
        if target == "linux_x86_64":
            assert(ir.stdout.contains("@trio(ptr byval(%Trio)"))
        if target == "darwin_aarch64" or target == "linux_aarch64":
            assert(ir.stdout.contains("@trio(ptr %0, ...)"))
        let audit = p7_run(case_dir, "va_def_audit_" ++ target, "analyze\0src/defs.w\0audit:all" ++ flags)
        p7_assert_success(audit, "variadic definition audit for " ++ target)
        assert(audit.stdout.contains("violations=0"))
    print("ok")
