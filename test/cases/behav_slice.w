//! expect-stdout: ok

// Behavior test: slices
// Tests: slice type construction

use Ast
use Type

fn test_type_slice:
    var types = TypeTable.new()
    let st = TypeTable.add_slice(types, TYPE_I32())
    assert(TypeTable.kind(types, st) == TK_SLICE())
    assert(TypeTable.get_data0(types, st) == TYPE_I32())

fn test_type_slice_f64:
    var types = TypeTable.new()
    let st = TypeTable.add_slice(types, TYPE_F64())
    assert(TypeTable.kind(types, st) == TK_SLICE())
    assert(TypeTable.get_data0(types, st) == TYPE_F64())

fn test_type_slice_vs_array:
    var types = TypeTable.new()
    let arr = TypeTable.add_array(types, TYPE_I32(), 10)
    let slc = TypeTable.add_slice(types, TYPE_I32())
    assert(TypeTable.kind(types, arr) == TK_ARRAY())
    assert(TypeTable.kind(types, slc) == TK_SLICE())
    assert(arr != slc)

fn main:
    test_type_slice()
    test_type_slice_f64()
    test_type_slice_vs_array()
    println("ok")
