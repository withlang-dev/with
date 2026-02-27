//! expect-stdout: ok

// Behavior test: @[tailrec] with accumulator pattern (With-specific)
// Tests: tailrec flag on fn decls, parsing, MIR lowering for TCO

use Token
use Lexer
use Ast
use Type
use Mir

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_tailrec_flag_constant:
    assert(FN_FLAG_TAILREC() == 16)

fn test_must_use_flag_constant:
    assert(FN_FLAG_MUST_USE() == 32)

fn test_comptime_flag_constant:
    assert(FN_FLAG_COMPTIME() == 8)

fn test_parse_tailrec_fn:
    let src = "@[tailrec]\nfn fact(n: i32, acc: i32) -> i32:\n    if n <= 1 then acc\n    else fact(n - 1, acc * n)\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    assert(AstPool.decl_count(p.pool) == 1)
    let decl = AstPool.get_decl(p.pool, 0)
    assert(AstPool.kind(p.pool, decl) == NK_FN_DECL())
    // Flags should include tailrec
    let extra_start = AstPool.get_data2(p.pool, decl)
    let flags = AstPool.get_extra(p.pool, extra_start + 1)
    assert((flags / 16) % 2 == 1)  // bit 4 = tailrec

fn test_parse_must_use_fn:
    let src = "@[must_use]\nfn compute() -> i32:\n    42\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let extra_start = AstPool.get_data2(p.pool, decl)
    let flags = AstPool.get_extra(p.pool, extra_start + 1)
    assert((flags / 32) % 2 == 1)  // bit 5 = must_use

fn test_tailrec_mir_structure:
    // A tail-recursive function should lower to a loop in MIR:
    // entry block → body block → back-edge to entry (via goto)
    var body = MirBody.new()
    let n = MirBody.add_local(body, 1, TYPE_I32(), 0)
    let acc = MirBody.add_local(body, 2, TYPE_I32(), 0)
    let bb_entry = MirBody.add_block(body)
    let bb_body = MirBody.add_block(body)
    let bb_done = MirBody.add_block(body)
    // entry: switch on condition (n <= 1)
    MirBody.set_switch_int(body, bb_entry, n, bb_done, bb_body)
    // body: update args, goto entry (the loop back-edge for TCO)
    MirBody.set_goto(body, bb_body, bb_entry)
    // done: return acc
    MirBody.set_return(body, bb_done)
    assert(MirBody.block_count(body) == 3)
    // Verify the back-edge: bb_body → bb_entry
    // The goto stores TM_GOTO in extra
    // bb_entry's switch stores at extra[0..3]
    // bb_body's goto stores at extra[4..7]
    // bb_done's return stores at extra[8..11]
    assert(MirBody.get_extra(body, 0) == TM_SWITCH_INT())
    assert(MirBody.get_extra(body, 4) == TM_GOTO())
    assert(MirBody.get_extra(body, 5) == bb_entry)  // back-edge target
    assert(MirBody.get_extra(body, 8) == TM_RETURN())

fn test_mir_loop_structure:
    // Standard loop: while(cond) { body }
    // bb_header: switch_int(cond, bb_body, bb_exit)
    // bb_body: ...; goto bb_header
    // bb_exit: return
    var body = MirBody.new()
    MirBody.add_local(body, 0, TYPE_I32(), 0)
    let bb_header = MirBody.add_block(body)
    let bb_body = MirBody.add_block(body)
    let bb_exit = MirBody.add_block(body)
    MirBody.set_switch_int(body, bb_header, 0, bb_body, bb_exit)
    MirBody.set_goto(body, bb_body, bb_header)
    MirBody.set_return(body, bb_exit)
    assert(MirBody.block_count(body) == 3)

fn test_fn_flag_bitfield:
    // Flags are a bitfield: pub=1, async=2, gen=4, comptime=8, tailrec=16, must_use=32, variadic=64
    assert(FN_FLAG_PUB() == 1)
    assert(FN_FLAG_ASYNC() == 2)
    assert(FN_FLAG_GEN() == 4)
    assert(FN_FLAG_COMPTIME() == 8)
    assert(FN_FLAG_TAILREC() == 16)
    assert(FN_FLAG_MUST_USE() == 32)
    assert(FN_FLAG_VARIADIC() == 64)
    // Combined flags: tailrec + pub = 17
    let combined = FN_FLAG_TAILREC() + FN_FLAG_PUB()
    assert(combined == 17)
    assert((combined / 1) % 2 == 1)   // pub bit set
    assert((combined / 16) % 2 == 1)  // tailrec bit set
    assert((combined / 32) % 2 == 0)  // must_use bit not set

fn main:
    test_tailrec_flag_constant()
    test_must_use_flag_constant()
    test_comptime_flag_constant()
    test_parse_tailrec_fn()
    test_parse_must_use_fn()
    test_tailrec_mir_structure()
    test_mir_loop_structure()
    test_fn_flag_bitfield()
    println("ok")
