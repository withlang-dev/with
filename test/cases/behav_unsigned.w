//! expect-stdout: ok

// Behavior test: unsigned integer types (Rust ui/numbers-arithmetic/)
// Tests: u8/u16/u32/u64 type properties, signedness predicates,
// codegen cast instructions for unsigned types

use Type
use Codegen

fn test_unsigned_types_exist:
    var types = TypeTable.new()
    assert(TypeTable.kind(types, TYPE_U8()) == TK_INT())
    assert(TypeTable.kind(types, TYPE_U16()) == TK_INT())
    assert(TypeTable.kind(types, TYPE_U32()) == TK_INT())
    assert(TypeTable.kind(types, TYPE_U64()) == TK_INT())

fn test_unsigned_not_signed:
    var types = TypeTable.new()
    assert(TypeTable.is_unsigned_int(types, TYPE_U8()))
    assert(TypeTable.is_unsigned_int(types, TYPE_U16()))
    assert(TypeTable.is_unsigned_int(types, TYPE_U32()))
    assert(TypeTable.is_unsigned_int(types, TYPE_U64()))
    assert(not TypeTable.is_signed_int(types, TYPE_U8()))
    assert(not TypeTable.is_signed_int(types, TYPE_U32()))

fn test_signed_int_correct:
    var types = TypeTable.new()
    assert(TypeTable.is_signed_int(types, TYPE_I8()))
    assert(TypeTable.is_signed_int(types, TYPE_I16()))
    assert(TypeTable.is_signed_int(types, TYPE_I32()))
    assert(TypeTable.is_signed_int(types, TYPE_I64()))
    assert(not TypeTable.is_unsigned_int(types, TYPE_I32()))

fn test_unsigned_bit_widths:
    var types = TypeTable.new()
    assert(TypeTable.int_bits(types, TYPE_U8()) == 8)
    assert(TypeTable.int_bits(types, TYPE_U16()) == 16)
    assert(TypeTable.int_bits(types, TYPE_U32()) == 32)
    assert(TypeTable.int_bits(types, TYPE_U64()) == 64)

fn test_unsigned_is_numeric:
    var types = TypeTable.new()
    assert(TypeTable.is_numeric(types, TYPE_U8()))
    assert(TypeTable.is_numeric(types, TYPE_U32()))
    assert(TypeTable.is_numeric(types, TYPE_U64()))

fn test_unsigned_is_copy:
    var types = TypeTable.new()
    assert(TypeTable.is_copy(types, TYPE_U8()))
    assert(TypeTable.is_copy(types, TYPE_U16()))
    assert(TypeTable.is_copy(types, TYPE_U32()))
    assert(TypeTable.is_copy(types, TYPE_U64()))

fn test_unsigned_cast_widening:
    // u8 → u32 should use ZEXT (zero extend, not sign extend)
    var types = TypeTable.new()
    let inst = cast_instruction(types, TYPE_U8(), TYPE_U32())
    assert(inst == LI_ZEXT())

fn test_signed_cast_widening:
    // i8 → i32 should use SEXT (sign extend)
    var types = TypeTable.new()
    let inst = cast_instruction(types, TYPE_I8(), TYPE_I32())
    assert(inst == LI_SEXT())

fn test_cast_narrowing:
    // i32 → i8 should use TRUNC regardless of signedness
    var types = TypeTable.new()
    let inst1 = cast_instruction(types, TYPE_I32(), TYPE_I8())
    assert(inst1 == LI_TRUNC())
    let inst2 = cast_instruction(types, TYPE_U32(), TYPE_U8())
    assert(inst2 == LI_TRUNC())

fn test_unsigned_to_float:
    // u32 → f64 should use UITOFP
    var types = TypeTable.new()
    let inst = cast_instruction(types, TYPE_U32(), TYPE_F64())
    assert(inst == LI_UITOFP())

fn test_signed_to_float:
    // i32 → f64 should use SITOFP
    var types = TypeTable.new()
    let inst = cast_instruction(types, TYPE_I32(), TYPE_F64())
    assert(inst == LI_SITOFP())

fn test_float_to_unsigned:
    // f64 → u32 should use FPTOUI
    var types = TypeTable.new()
    let inst = cast_instruction(types, TYPE_F64(), TYPE_U32())
    assert(inst == LI_FPTOUI())

fn test_float_to_signed:
    // f64 → i32 should use FPTOSI
    var types = TypeTable.new()
    let inst = cast_instruction(types, TYPE_F64(), TYPE_I32())
    assert(inst == LI_FPTOSI())

fn test_unsigned_named_lookup:
    var types = TypeTable.new()
    assert(TypeTable.lookup(types, "u8") == TYPE_U8())
    assert(TypeTable.lookup(types, "u16") == TYPE_U16())
    assert(TypeTable.lookup(types, "u32") == TYPE_U32())
    assert(TypeTable.lookup(types, "u64") == TYPE_U64())

fn main:
    test_unsigned_types_exist()
    test_unsigned_not_signed()
    test_signed_int_correct()
    test_unsigned_bit_widths()
    test_unsigned_is_numeric()
    test_unsigned_is_copy()
    test_unsigned_cast_widening()
    test_signed_cast_widening()
    test_cast_narrowing()
    test_unsigned_to_float()
    test_signed_to_float()
    test_float_to_unsigned()
    test_float_to_signed()
    test_unsigned_named_lookup()
    println("ok")
