//! expect-stdout: ok

// Behavior test: drop semantics
// Tests: MIR drop statements, scope cleanup

use Ast
use Types
use Mir
use BorrowCfg

fn test_mir_drop_stmt:
    var body = MirBody.new()
    // local 0 = return (auto-created by MirBody.new)
    MirBody.add_local(body, 1, TYPE_I32, 1)  // local 1 = some var
    let bb = MirBody.add_block(body)
    // Add an assign stmt
    MirBody.add_stmt(body, bb, SK_ASSIGN, 1, 0, 0)
    // Add a drop stmt
    MirBody.add_stmt(body, bb, SK_DROP, 1, 0, 0)
    MirBody.set_return(body, bb)
    // Verify: 2 stmts total
    assert(MirBody.stmt_count(body) == 2)

fn test_borrow_check_with_drops:
    var types = TypeTable.new()
    var body = MirBody.new()
    // local 0 = return (auto-created)
    MirBody.add_local(body, 1, TYPE_I32, 1)  // x
    let bb = MirBody.add_block(body)
    MirBody.add_stmt(body, bb, SK_ASSIGN, 1, 42, 0)
    MirBody.add_stmt(body, bb, SK_DROP, 1, 0, 0)
    MirBody.set_return(body, bb)
    var bc = BorrowChecker.new(body, types)
    BorrowChecker.check(bc)
    assert(BorrowChecker.error_count(bc) == 0)

fn test_mir_nop_stmt:
    var body = MirBody.new()
    // local 0 = return (auto-created)
    let bb = MirBody.add_block(body)
    MirBody.add_stmt(body, bb, SK_NOP, 0, 0, 0)
    MirBody.set_return(body, bb)
    assert(MirBody.stmt_count(body) == 1)

fn test_mir_multiple_locals:
    var body = MirBody.new()
    // local 0 = return (auto-created)
    MirBody.add_local(body, 1, TYPE_I32, 1)
    MirBody.add_local(body, 2, TYPE_BOOL, 0)
    MirBody.add_local(body, 3, TYPE_STR, 0)
    // 4 total: return + 3 added
    assert(MirBody.local_count(body) == 4)

fn main:
    test_mir_drop_stmt()
    test_borrow_check_with_drops()
    test_mir_nop_stmt()
    test_mir_multiple_locals()
    println("ok")
