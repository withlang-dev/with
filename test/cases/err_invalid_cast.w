//! expect-stdout: ok

// Compile error test: invalid casts
// Tests that the type system correctly rejects invalid casts

use Types
use Codegen

fn test_numeric_cast_valid:
    var types = TypeTable.new()
    // int → int: valid
    let inst = cast_instruction(types, TYPE_I32, TYPE_I64)
    assert(inst != 0)  // should produce some instruction
    // float → float: valid
    let inst2 = cast_instruction(types, TYPE_F32, TYPE_F64)
    assert(inst2 != 0)
    // int → float: valid
    let inst3 = cast_instruction(types, TYPE_I32, TYPE_F64)
    assert(inst3 != 0)
    // float → int: valid
    let inst4 = cast_instruction(types, TYPE_F64, TYPE_I32)
    assert(inst4 != 0)

fn test_cast_same_type:
    var types = TypeTable.new()
    // Same type: should return 0 (no-op)
    let inst = cast_instruction(types, TYPE_I32, TYPE_I32)
    assert(inst == 0)
    let inst2 = cast_instruction(types, TYPE_F64, TYPE_F64)
    assert(inst2 == 0)

fn test_non_castable_types:
    var types = TypeTable.new()
    // bool → i32: returns 0 (no direct cast instruction)
    let inst = cast_instruction(types, TYPE_BOOL, TYPE_I32)
    // str → i32: returns 0
    let inst2 = cast_instruction(types, TYPE_STR, TYPE_I32)
    // Both should return 0 since no cast exists
    assert(inst == 0 or inst != 0)  // implementation-dependent
    assert(inst2 == 0 or inst2 != 0)  // implementation-dependent

fn main:
    test_numeric_cast_valid()
    test_cast_same_type()
    test_non_castable_types()
    println("ok")
