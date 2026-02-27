//! expect-stdout: ok

// Safety test: runtime safety checks
// Tests: MIR terminators for assert, unreachable, drop

use Ast
use Type
use Mir
use Borrow

fn test_assert_terminator:
    // TM_ASSERT exists as a terminator kind
    assert(TM_ASSERT() == 6)

fn test_unreachable_terminator:
    assert(TM_UNREACHABLE() == 3)

fn test_return_terminator:
    assert(TM_RETURN() == 2)

fn test_goto_terminator:
    assert(TM_GOTO() == 0)

fn test_switch_int_terminator:
    assert(TM_SWITCH_INT() == 1)

fn test_call_terminator:
    assert(TM_CALL() == 4)

fn test_drop_terminator:
    assert(TM_DROP() == 5)

fn test_mir_terminator_set:
    var body = MirBody.new()
    MirBody.add_local(body, TYPE_I32(), 0)
    let bb = MirBody.add_block(body)
    MirBody.set_terminator(body, bb, TM_RETURN(), 0, 0, 0)
    assert(MirBody.block_count(body) == 1)

fn test_mir_goto_chain:
    var body = MirBody.new()
    MirBody.add_local(body, TYPE_I32(), 0)
    let bb0 = MirBody.add_block(body)
    let bb1 = MirBody.add_block(body)
    MirBody.set_terminator(body, bb0, TM_GOTO(), bb1, 0, 0)
    MirBody.set_terminator(body, bb1, TM_RETURN(), 0, 0, 0)
    assert(MirBody.block_count(body) == 2)

fn test_mir_switch_int:
    var body = MirBody.new()
    MirBody.add_local(body, TYPE_I32(), 0)
    let bb0 = MirBody.add_block(body)
    let bb1 = MirBody.add_block(body)
    let bb2 = MirBody.add_block(body)
    MirBody.set_terminator(body, bb0, TM_SWITCH_INT(), 0, bb1, bb2)
    MirBody.set_terminator(body, bb1, TM_RETURN(), 0, 0, 0)
    MirBody.set_terminator(body, bb2, TM_RETURN(), 0, 0, 0)
    assert(MirBody.block_count(body) == 3)

fn main:
    test_assert_terminator()
    test_unreachable_terminator()
    test_return_terminator()
    test_goto_terminator()
    test_switch_int_terminator()
    test_call_terminator()
    test_drop_terminator()
    test_mir_terminator_set()
    test_mir_goto_chain()
    test_mir_switch_int()
    println("ok")
