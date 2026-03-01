//! expect-stdout: ok

// Behavior test: advanced borrow checker features
// Missing features:
// - Disjoint field borrowing (SS3.6) — field in BorrowInfo set to -1
// - Drop as implicit use for borrow-checking (SS21.1 rule 7)
// - Ephemeral return conservation (SS21.1 rule 6)

use Type
use Mir

fn test_borrow_kind_constants:
    assert(BK_SHARED() == 0)
    assert(BK_MUTABLE() == 1)

fn test_mir_drop_statement:
    // SK_DROP exists for explicit drop
    assert(SK_DROP() == 1)

fn test_mir_drop_terminator:
    // TM_DROP exists for drop-then-branch
    assert(TM_DROP() == 5)

fn test_mir_statement_kinds:
    assert(SK_ASSIGN() == 0)
    assert(SK_DROP() == 1)
    assert(SK_NOP() == 2)

fn test_mir_projection_kinds:
    // PJ_FIELD needed for disjoint field borrowing
    assert(PJ_FIELD() == 0)
    assert(PJ_INDEX() == 1)
    assert(PJ_DEREF() == 2)
    assert(PJ_DOWNCAST() == 3)

fn test_mir_operand_kinds:
    // OP_COPY vs OP_MOVE distinction needed for move checking
    assert(OP_COPY() == 0)
    assert(OP_MOVE() == 1)
    assert(OP_CONSTANT() == 2)

fn test_mir_rvalue_kinds:
    assert(RV_USE() == 0)
    assert(RV_REF() == 1)
    assert(RV_BINARY_OP() == 2)
    assert(RV_UNARY_OP() == 3)
    assert(RV_CALL() == 4)
    assert(RV_AGGREGATE() == 5)
    assert(RV_CAST() == 6)
    assert(RV_DISCRIMINANT() == 7)
    assert(RV_CONSTANT() == 8)

fn test_mir_aggregate_kinds:
    assert(AK_STRUCT() == 0)
    assert(AK_ENUM() == 1)
    assert(AK_TUPLE() == 2)
    assert(AK_ARRAY() == 3)

fn test_mir_terminator_kinds:
    assert(TM_GOTO() == 0)
    assert(TM_SWITCH_INT() == 1)
    assert(TM_RETURN() == 2)
    assert(TM_UNREACHABLE() == 3)
    assert(TM_CALL() == 4)
    assert(TM_DROP() == 5)
    assert(TM_ASSERT() == 6)

fn test_nll_region_basic:
    // NLL region infrastructure exists
    var body = MirBody.new()
    let bb0 = MirBody.add_block(body)
    let bb1 = MirBody.add_block(body)
    assert(MirBody.block_count(body) == 2)

fn test_disjoint_field_placeholder:
    // BorrowInfo has a field member, but it's always -1
    // When implemented, field >= 0 would enable disjoint field borrowing
    // Test that the projection infrastructure exists
    assert(PJ_FIELD() == 0)

fn main:
    test_borrow_kind_constants()
    test_mir_drop_statement()
    test_mir_drop_terminator()
    test_mir_statement_kinds()
    test_mir_projection_kinds()
    test_mir_operand_kinds()
    test_mir_rvalue_kinds()
    test_mir_aggregate_kinds()
    test_mir_terminator_kinds()
    test_nll_region_basic()
    test_disjoint_field_placeholder()
    println("ok")
