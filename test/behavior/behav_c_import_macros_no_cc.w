// §16.1: object-like and arithmetic c_import macros are collected by the
// compiler-owned libclang bridge, with no `cc -E -dM` fallback shell-out.

use c_import("#define CIM_A 7\n#define CIM_B (CIM_A * 2)\nint cim_ok(void);\n")

fn test_object_and_arithmetic_macros:
    assert(CIM_A == 7)
    assert(CIM_B == 14)
