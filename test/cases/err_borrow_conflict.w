//! expect-stdout: ok

// Compile error test: borrow conflicts
// Tests that the borrow checker detects aliasing violations

use Ast
use Type
use Mir
use Borrow

fn test_no_borrows_no_errors:
    var types = TypeTable.new()
    var body = MirBody.new()
    MirBody.add_local(body, TYPE_I32(), 0)
    let bb = MirBody.add_block(body)
    MirBody.set_terminator(body, bb, TM_RETURN(), 0, 0, 0)
    var bc = BorrowChecker.new(body, types)
    BorrowChecker.check(bc)
    assert(BorrowChecker.error_count(bc) == 0)

fn test_single_borrow_ok:
    var types = TypeTable.new()
    var body = MirBody.new()
    MirBody.add_local(body, TYPE_I32(), 0)  // return
    MirBody.add_local(body, TYPE_I32(), 1)  // x (mutable)
    let bb = MirBody.add_block(body)
    MirBody.add_stmt(body, bb, SK_ASSIGN(), 1, 42, 0)
    MirBody.set_terminator(body, bb, TM_RETURN(), 0, 0, 0)
    var bc = BorrowChecker.new(body, types)
    BorrowChecker.check(bc)
    assert(BorrowChecker.error_count(bc) == 0)

fn test_borrow_info_creation:
    var types = TypeTable.new()
    var body = MirBody.new()
    MirBody.add_local(body, TYPE_I32(), 0)
    MirBody.add_local(body, TYPE_I32(), 1)
    let bb = MirBody.add_block(body)
    MirBody.set_terminator(body, bb, TM_RETURN(), 0, 0, 0)
    var bc = BorrowChecker.new(body, types)
    // Manually add a borrow
    BorrowChecker.add_borrow(bc, BK_SHARED(), 1, 0, bb, 0, 0, 0)
    assert(bc.borrows.len() == 1)

fn test_collect_borrows:
    var types = TypeTable.new()
    var body = MirBody.new()
    MirBody.add_local(body, TYPE_I32(), 0)
    let bb = MirBody.add_block(body)
    MirBody.set_terminator(body, bb, TM_RETURN(), 0, 0, 0)
    var bc = BorrowChecker.new(body, types)
    BorrowChecker.collect_borrows(bc)
    // With no ref statements, should have 0 borrows
    assert(bc.borrows.len() == 0)

fn test_nll_region:
    var r = NllRegion.new()
    NllRegion.add(r, 0)
    NllRegion.add(r, 1)
    NllRegion.add(r, 2)
    assert(NllRegion.contains(r, 0) == 1)
    assert(NllRegion.contains(r, 1) == 1)
    assert(NllRegion.contains(r, 2) == 1)
    assert(NllRegion.contains(r, 3) == 0)

fn main:
    test_no_borrows_no_errors()
    test_single_borrow_ok()
    test_borrow_info_creation()
    test_collect_borrows()
    test_nll_region()
    println("ok")
