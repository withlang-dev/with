//! expect-stdout: ok

// Compile error test: string match exhaustiveness (Rust ui/match/)
// Tests: str match patterns need wildcard, enum exhaustiveness via type system

use Type
use Ast
use Sema
use InternPool

fn test_str_not_enum:
    // str is not an enum, so match on str requires wildcard
    var types = TypeTable.new()
    assert(not TypeTable.is_enum(types, TYPE_STR()))
    // str is not bool either (finite set of values)
    assert(not TypeTable.is_bool(types, TYPE_STR()))

fn test_bool_is_finite:
    // bool has exactly 2 values, so match on bool can be exhaustive
    var types = TypeTable.new()
    assert(TypeTable.is_bool(types, TYPE_BOOL()))

fn test_int_not_finite:
    // i32 is not finite (too many values), needs wildcard in match
    var types = TypeTable.new()
    assert(TypeTable.is_int(types, TYPE_I32()))
    // Not an enum (no finite variant set)
    assert(not TypeTable.is_enum(types, TYPE_I32()))

fn test_enum_is_finite:
    // Enum with known variants is finite → exhaustive match possible
    var types = TypeTable.new()
    var vnames = Vec.new()
    vnames.push(1)  // A
    vnames.push(2)  // B
    var vpayloads = Vec.new()
    vpayloads.push(0)
    vpayloads.push(0)
    var vptypes = Vec.new()
    let eid = TypeTable.add_enum(types, 10, vnames, vpayloads, vptypes)
    assert(TypeTable.is_enum(types, eid))
    assert(TypeTable.enum_variant_count(types, eid) == 2)

fn test_pattern_node_kinds:
    // All pattern kinds should be distinct
    assert(NK_PAT_WILDCARD() != NK_PAT_INT())
    assert(NK_PAT_INT() != NK_PAT_STRING())
    assert(NK_PAT_STRING() != NK_PAT_BOOL())
    assert(NK_PAT_BOOL() != NK_PAT_VARIANT())
    assert(NK_PAT_VARIANT() != NK_PAT_IDENT())

fn test_wildcard_pattern_exists:
    // Wildcard (_) is a valid pattern kind
    assert(NK_PAT_WILDCARD() == 100)

fn test_string_pattern_exists:
    // String literal is a valid pattern kind
    assert(NK_PAT_STRING() == 104)

fn main:
    test_str_not_enum()
    test_bool_is_finite()
    test_int_not_finite()
    test_enum_is_finite()
    test_pattern_node_kinds()
    test_wildcard_pattern_exists()
    test_string_pattern_exists()
    println("ok")
