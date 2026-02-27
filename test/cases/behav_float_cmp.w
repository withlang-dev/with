//! expect-stdout: ok

// Behavior test: float comparison operators (Rust ui/numbers-arithmetic/)
// Tests: all 6 float comparison codegen instructions: ==, !=, <, >, <=, >=

use Type
use Ast
use Codegen

fn test_float_eq:
    var types = TypeTable.new()
    let op = binop_to_llvm(types, OP_EQ(), TYPE_F64())
    assert(op == LI_FCMP_OEQ())

fn test_float_ne:
    var types = TypeTable.new()
    let op = binop_to_llvm(types, OP_NEQ(), TYPE_F64())
    assert(op == LI_FCMP_ONE())

fn test_float_lt:
    var types = TypeTable.new()
    let op = binop_to_llvm(types, OP_LT(), TYPE_F64())
    assert(op == LI_FCMP_OLT())

fn test_float_gt:
    var types = TypeTable.new()
    let op = binop_to_llvm(types, OP_GT(), TYPE_F64())
    assert(op == LI_FCMP_OGT())

fn test_float_le:
    var types = TypeTable.new()
    let op = binop_to_llvm(types, OP_LTE(), TYPE_F64())
    assert(op == LI_FCMP_OLE())

fn test_float_ge:
    var types = TypeTable.new()
    let op = binop_to_llvm(types, OP_GTE(), TYPE_F64())
    assert(op == LI_FCMP_OGE())

fn test_int_cmp_signed:
    // Integer comparisons for contrast
    var types = TypeTable.new()
    assert(binop_to_llvm(types, OP_EQ(), TYPE_I32()) == LI_ICMP_EQ())
    assert(binop_to_llvm(types, OP_NEQ(), TYPE_I32()) == LI_ICMP_NE())
    assert(binop_to_llvm(types, OP_LT(), TYPE_I32()) == LI_ICMP_SLT())
    assert(binop_to_llvm(types, OP_GT(), TYPE_I32()) == LI_ICMP_SGT())
    assert(binop_to_llvm(types, OP_LTE(), TYPE_I32()) == LI_ICMP_SLE())
    assert(binop_to_llvm(types, OP_GTE(), TYPE_I32()) == LI_ICMP_SGE())

fn test_f32_comparisons:
    // f32 should also use FCMP instructions
    var types = TypeTable.new()
    assert(binop_to_llvm(types, OP_EQ(), TYPE_F32()) == LI_FCMP_OEQ())
    assert(binop_to_llvm(types, OP_LT(), TYPE_F32()) == LI_FCMP_OLT())
    assert(binop_to_llvm(types, OP_GT(), TYPE_F32()) == LI_FCMP_OGT())

fn test_float_arithmetic_ops:
    var types = TypeTable.new()
    assert(binop_to_llvm(types, OP_ADD(), TYPE_F64()) == LI_FADD())
    assert(binop_to_llvm(types, OP_SUB(), TYPE_F64()) == LI_FSUB())
    assert(binop_to_llvm(types, OP_MUL(), TYPE_F64()) == LI_FMUL())
    assert(binop_to_llvm(types, OP_DIV(), TYPE_F64()) == LI_FDIV())

fn test_int_arithmetic_ops:
    var types = TypeTable.new()
    assert(binop_to_llvm(types, OP_ADD(), TYPE_I32()) == LI_ADD())
    assert(binop_to_llvm(types, OP_SUB(), TYPE_I32()) == LI_SUB())
    assert(binop_to_llvm(types, OP_MUL(), TYPE_I32()) == LI_MUL())
    assert(binop_to_llvm(types, OP_DIV(), TYPE_I32()) == LI_SDIV())

fn main:
    test_float_eq()
    test_float_ne()
    test_float_lt()
    test_float_gt()
    test_float_le()
    test_float_ge()
    test_int_cmp_signed()
    test_f32_comparisons()
    test_float_arithmetic_ops()
    test_int_arithmetic_ops()
    println("ok")
