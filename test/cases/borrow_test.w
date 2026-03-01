//! expect-stdout: ok

use Type
use Mir
use Borrow

fn test_borrow_info:
    let bi = BorrowInfo.new(BK_SHARED(), 5, 10, 0, 3)
    assert(bi.kind == BK_SHARED())
    assert(bi.local == 5)
    assert(bi.ref_local == 10)
    assert(bi.created_bb == 0)
    assert(bi.created_stmt == 3)
    assert(bi.field == -1)

fn test_nll_region:
    var r = NllRegion.new()
    assert(not NllRegion.contains(r, 0))
    NllRegion.add(r, 0)
    NllRegion.add(r, 1)
    NllRegion.add(r, 2)
    assert(NllRegion.contains(r, 0))
    assert(NllRegion.contains(r, 1))
    assert(NllRegion.contains(r, 2))
    assert(not NllRegion.contains(r, 3))
    // Adding duplicate should not increase size
    NllRegion.add(r, 1)
    assert(r.blocks.len() == 3)

fn test_empty_body:
    var body = MirBody.new()
    MirBody.add_block(body)
    var types = TypeTable.new()
    var bc = BorrowChecker.new(body, types)
    BorrowChecker.check(bc)
    assert(BorrowChecker.error_count(bc) == 0)

fn test_single_borrow_ok:
    var body = MirBody.new()
    let local = MirBody.add_local(body, 10, TYPE_I32(), 1)
    let ref_local = MirBody.add_local(body, 11, TYPE_I32(), 0)
    let bb = MirBody.add_block(body)
    // ref_local = &local (shared borrow)
    MirBody.add_assign(body, bb, ref_local, RV_REF(), local, 0)
    MirBody.set_return(body, bb)
    var types = TypeTable.new()
    var bc = BorrowChecker.new(body, types)
    BorrowChecker.collect_borrows(bc)
    assert(bc.borrows.len() == 1)
    let bi = bc.borrows.get(0)
    assert(bi.local == local)
    assert(bi.ref_local == ref_local)

fn test_no_escape:
    var body = MirBody.new()
    // Make return local (0) a reference type
    let ref_type = TypeTable.add_ref(TypeTable.new(), TYPE_I32(), 0)
    // The return local was created as void; add a ref-typed local
    let ref_local = MirBody.add_local(body, -1, ref_type, 0)
    var types = TypeTable.new()
    let rt = TypeTable.add_ref(types, TYPE_I32(), 0)
    // Manually track that local 0 has ref type (via types table)
    var bc = BorrowChecker.new(body, types)
    BorrowChecker.check_no_escape(bc)
    // No error because local 0 is void type, not ref
    assert(BorrowChecker.error_count(bc) == 0)

fn test_active_borrows_at:
    var body = MirBody.new()
    let local = MirBody.add_local(body, 10, TYPE_I32(), 1)
    let ref1 = MirBody.add_local(body, 11, TYPE_I32(), 0)
    let bb0 = MirBody.add_block(body)
    MirBody.add_assign(body, bb0, ref1, RV_REF(), local, 0)
    var types = TypeTable.new()
    var bc = BorrowChecker.new(body, types)
    BorrowChecker.collect_borrows(bc)
    BorrowChecker.compute_regions(bc)
    let active = BorrowChecker.active_borrows_at(bc, 0)
    assert(active >= 1)

fn main:
    test_borrow_info()
    test_nll_region()
    test_empty_body()
    test_single_borrow_ok()
    test_no_escape()
    test_active_borrows_at()
    println("ok")
