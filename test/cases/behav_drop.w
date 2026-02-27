//! expect-stdout: ok

// Behavior test: drop semantics
// Tests: MIR drop statements, scope cleanup

use Ast
use Type
use Mir
use MirBuild
use Borrow

fn test_mir_drop_stmt:
    var body = MirBody.new()
    MirBody.add_local(body, TYPE_I32(), 0)  // local 0 = return
    MirBody.add_local(body, TYPE_I32(), 1)  // local 1 = some var
    let bb = MirBody.add_block(body)
    // Add an assign stmt
    MirBody.add_stmt(body, bb, SK_ASSIGN(), 1, 0, 0)
    // Add a drop stmt
    MirBody.add_stmt(body, bb, SK_DROP(), 1, 0, 0)
    MirBody.set_terminator(body, bb, TM_RETURN(), 0, 0, 0)
    // Verify
    assert(MirBody.stmt_count(body, bb) == 2)

fn test_borrow_check_with_drops:
    var types = TypeTable.new()
    var body = MirBody.new()
    MirBody.add_local(body, TYPE_I32(), 0)  // return
    MirBody.add_local(body, TYPE_I32(), 1)  // x
    let bb = MirBody.add_block(body)
    MirBody.add_stmt(body, bb, SK_ASSIGN(), 1, 42, 0)
    MirBody.add_stmt(body, bb, SK_DROP(), 1, 0, 0)
    MirBody.set_terminator(body, bb, TM_RETURN(), 0, 0, 0)
    var bc = BorrowChecker.new(body, types)
    BorrowChecker.check(bc)
    assert(BorrowChecker.error_count(bc) == 0)

fn test_mir_nop_stmt:
    var body = MirBody.new()
    MirBody.add_local(body, TYPE_I32(), 0)
    let bb = MirBody.add_block(body)
    MirBody.add_stmt(body, bb, SK_NOP(), 0, 0, 0)
    MirBody.set_terminator(body, bb, TM_RETURN(), 0, 0, 0)
    assert(MirBody.stmt_count(body, bb) == 1)

fn test_mir_multiple_locals:
    var body = MirBody.new()
    MirBody.add_local(body, TYPE_I32(), 0)
    MirBody.add_local(body, TYPE_I32(), 1)
    MirBody.add_local(body, TYPE_BOOL(), 0)
    MirBody.add_local(body, TYPE_STR(), 0)
    assert(MirBody.local_count(body) == 4)

fn main:
    test_mir_drop_stmt()
    test_borrow_check_with_drops()
    test_mir_nop_stmt()
    test_mir_multiple_locals()
    println("ok")
