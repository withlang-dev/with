//! expect-stdout: ok

// #1195: a struct of at most 16 bytes crosses a C call in registers, in the
// shape the target's C ABI gives it. Left as an LLVM aggregate, a 4-byte
// `Color` return became a hidden pointer on linux-x86_64 and shifted every
// argument (raylib's GetImageColor read a stack address as `x`). The expected
// signatures are clang's for the same C declarations; two floats sharing an
// SSE eightbyte travel as one double where clang writes `<2 x float>` — the
// same 64 bits in the same register.

use pre_d_build_runner
use std.fs

fn expect_declares(target: &str, expected: &[str]):
    let case_dir = p7_prepare_case("c_abi_small_structs_" ++ target, "cabishapes")
    p7_write(case_dir, "src/shapes.w", read_file(p7_abs("test/behavior/lib/c_abi_struct_shapes.w")).unwrap())
    let ir = p7_run(case_dir, "c_abi_ir_" ++ target, "ir\0src/shapes.w\0--target=" ++ target ++ "\0--no-prelude\0")
    p7_assert_success(ir, "C ABI IR for " ++ target)
    for i in 0..expected.len():
        let line = expected[i]
        if not ir.stdout.contains(line ++ "\n"):
            eprint(target ++ ": missing `" ++ line ++ "`")
            for have in ir.stdout.split("\n"):
                if have.starts_with("declare ") and not have.contains("@llvm."): eprint("  " ++ have)
            assert(false)

fn main:
    let sysv = [
        "declare i32 @r_color(i32)",
        "declare double @r_v2(double)",
        "declare { double, float } @r_v3({ double, float })",
        "declare { double, double } @r_v4({ double, double })",
        "declare { double, double } @r_d2({ double, double })",
        "declare i64 @r_if(i64)",
        // clang narrows the tail to i32; the padding travels in the same register.
        "declare { double, i64 } @r_di({ double, i64 })",
        "declare { i64, i64 } @r_l2({ i64, i64 })",
        "declare { i64, i32 } @r_i3({ i64, i32 })",
        "declare void @r_l3(ptr sret(%L3), ptr byval(%L3))",
        // One INTEGER register is left for a two-eightbyte struct: all of it
        // goes to the stack, none of it is split.
        "declare i32 @spill(i64, i64, i64, i64, i64, ptr byval(%L2))",
        // Packed structs classify at their packed offsets; an unaligned field
        // makes the struct MEMORY. c_import's raylib Color is packed, and as
        // an aggregate its return became a hidden pointer again.
        "declare i32 @r_pcolor(i32)",
        "declare i40 @r_pt(i40)",
        "declare void @r_pu(ptr sret(%PU), ptr byval(%PU))",
    ]
    let aapcs = [
        "declare i32 @r_color(i64)",
        "declare %V2 @r_v2([2 x float])",
        "declare %V3 @r_v3([3 x float])",
        "declare %V4 @r_v4([4 x float])",
        "declare %D2 @r_d2([2 x double])",
        "declare i64 @r_if(i64)",
        "declare [2 x i64] @r_di([2 x i64])",
        "declare [2 x i64] @r_l2([2 x i64])",
        "declare [2 x i64] @r_i3([2 x i64])",
        "declare void @r_l3(ptr sret(%L3), ptr)",
        "declare i32 @spill(i64, i64, i64, i64, i64, [2 x i64])",
    ]
    // Microsoft x64: 1, 2, 4 or 8 bytes go in one integer register whatever
    // the members are; everything else is a pointer to a copy.
    let win64 = [
        "declare i32 @r_color(i32)",
        "declare i64 @r_v2(i64)",
        "declare i64 @r_if(i64)",
        "declare void @r_v3(ptr sret(%V3), ptr)",
        "declare void @r_l2(ptr sret(%L2), ptr)",
        "declare i32 @spill(i64, i64, i64, i64, i64, ptr)",
    ]
    expect_declares("linux_x86_64", sysv[..])
    expect_declares("windows_x86_64", win64[..])
    expect_declares("linux_aarch64", aapcs[..])
    expect_declares("darwin_aarch64", aapcs[..])
    expect_declares("windows_aarch64", aapcs[..])
    print("ok")
