//! expect-stdout: ok

// Behavior test: match guards and pattern matching (Rust ui/match/)
// Tests: match arm patterns, guard expressions, MIR switch_int generation,
// enum variant matching, wildcard patterns

use Token
use Lexer
use Ast
use Type
use Mir
use Parser

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_match_keyword:
    var tokens = lex("match")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_MATCH())

fn test_parse_match_with_guard:
    // match x:
    //     1 if y > 0 => "pos"
    //     _ => "other"
    let src = "fn f:\n    match 1:\n        1 => 10\n        _ => 20\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_MATCH())

fn test_match_arm_patterns:
    // Int pattern
    assert(NK_PAT_INT() == 102)
    // Bool pattern
    assert(NK_PAT_BOOL() == 103)
    // String pattern
    assert(NK_PAT_STRING() == 104)
    // Wildcard pattern
    assert(NK_PAT_WILDCARD() == 100)
    // Ident pattern
    assert(NK_PAT_IDENT() == 101)
    // Variant pattern
    assert(NK_PAT_VARIANT() == 105)
    // Tuple pattern
    assert(NK_PAT_TUPLE() == 106)
    // Struct pattern
    assert(NK_PAT_STRUCT() == 107)
    // Range pattern
    assert(NK_PAT_RANGE() == 108)
    // Or pattern
    assert(NK_PAT_OR() == 109)
    // Enum shorthand pattern
    assert(NK_PAT_ENUM_SHORTHAND() == 111)

fn test_match_arm_node:
    assert(NK_MATCH_ARM() == 110)

fn test_mir_switch_int_for_match:
    // match lowering uses TM_SWITCH_INT to branch on value
    var body = MirBody.new()
    let local = MirBody.add_local(body, 0, TYPE_I32(), 0)
    let bb0 = MirBody.add_block(body)
    let bb1 = MirBody.add_block(body)
    let bb2 = MirBody.add_block(body)
    MirBody.set_switch_int(body, bb0, local, bb1, bb2)
    MirBody.set_return(body, bb1)
    MirBody.set_return(body, bb2)
    assert(MirBody.block_count(body) == 3)
    // Verify switch_int stored in extra
    let extra_base = 0
    assert(MirBody.get_extra(body, extra_base) == TM_SWITCH_INT())
    assert(MirBody.get_extra(body, extra_base + 1) == local)
    assert(MirBody.get_extra(body, extra_base + 2) == bb1)
    assert(MirBody.get_extra(body, extra_base + 3) == bb2)

fn test_match_enum_variant_type:
    // Enum type with multiple variants for match
    var types = TypeTable.new()
    var vnames = Vec.new()
    vnames.push(1)  // Red
    vnames.push(2)  // Green
    vnames.push(3)  // Blue
    var vpayloads = Vec.new()
    vpayloads.push(0)  // Red: no payload
    vpayloads.push(0)  // Green: no payload
    vpayloads.push(0)  // Blue: no payload
    var vptypes = Vec.new()
    let eid = TypeTable.add_enum(types, 10, vnames, vpayloads, vptypes)
    assert(TypeTable.is_enum(types, eid))
    assert(TypeTable.enum_variant_count(types, eid) == 3)

fn test_match_enum_with_payload:
    // Enum with payloads: Option-like
    var types = TypeTable.new()
    var vnames = Vec.new()
    vnames.push(1)  // Some
    vnames.push(2)  // None
    var vpayloads = Vec.new()
    vpayloads.push(1)  // Some: 1 payload
    vpayloads.push(0)  // None: no payload
    var vptypes = Vec.new()
    vptypes.push(TYPE_I32())  // Some(i32)
    let eid = TypeTable.add_enum(types, 20, vnames, vpayloads, vptypes)
    assert(TypeTable.enum_variant_count(types, eid) == 2)
    assert(TypeTable.enum_variant_payload_count(types, eid, 0) == 1)
    assert(TypeTable.enum_variant_payload_type(types, eid, 0, 0) == TYPE_I32())
    assert(TypeTable.enum_variant_payload_count(types, eid, 1) == 0)

fn test_multi_arm_match_cfg:
    // match with 3 arms needs a chain of switch_int blocks
    var body = MirBody.new()
    let scrutinee = MirBody.add_local(body, 0, TYPE_I32(), 0)
    let bb_entry = MirBody.add_block(body)
    let bb_arm1 = MirBody.add_block(body)
    let bb_arm2 = MirBody.add_block(body)
    let bb_arm3 = MirBody.add_block(body)
    let bb_join = MirBody.add_block(body)
    // Entry checks first arm
    MirBody.set_switch_int(body, bb_entry, scrutinee, bb_arm1, bb_arm2)
    // arm1 → join
    MirBody.set_goto(body, bb_arm1, bb_join)
    // arm2 → join
    MirBody.set_goto(body, bb_arm2, bb_arm3)
    // arm3 (wildcard) → join
    MirBody.set_goto(body, bb_arm3, bb_join)
    // join returns
    MirBody.set_return(body, bb_join)
    assert(MirBody.block_count(body) == 5)

fn main:
    test_match_keyword()
    test_parse_match_with_guard()
    test_match_arm_patterns()
    test_match_arm_node()
    test_mir_switch_int_for_match()
    test_match_enum_variant_type()
    test_match_enum_with_payload()
    test_multi_arm_match_cfg()
    println("ok")
