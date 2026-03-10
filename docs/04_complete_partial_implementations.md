Complete Partial Implementations
Goal: Finish features that are partially implemented — parser
and/or sema done, but codegen or full wiring is missing.
Scope: These are features where most of the work is done and
the remaining piece is small and well-defined.
Checklist

 Match guards (§3.3). AST stores guard in NK_MATCH_ARM d2.
Sema type-checks it. Codegen needs to evaluate guard and branch
to next arm on false. Test: behav_match_guards.w
 loop: statement (§5.6). Token and AST node exist. Wire
parser to create NK_LOOP node. Codegen: unconditional branch to
loop header. Test: behav_loop_stmt.w
 Inclusive range ..= (§5.7). Token already lexed. Parser
needs to distinguish from ... Codegen: i <= bound instead
of i < bound. Test: behav_inclusive_range.w
 Unsigned integers (§5.11). Add u8, u16, u32, u64
to type system. Codegen: udiv/zext instead of sdiv/sext.
Test: behav_unsigned.w
 For-loop destructuring (§5.12). Parse pattern instead of
just ident as for-loop binding. Codegen: destructure after
element extraction. Test: behav_for_destructure.w
 Self keyword in traits/impls (§3.1). Self in type
resolution refers to implementing type. Self.Name looks up
associated type. Tests: assoc_type_bound.w,
assoc_type_in_bound.w, where_assoc.w
 Sealed trait exhaustive match (§3.2). Track all impls of
sealed traits. Match on dyn SealedTrait checks against known
implementors. Test: sealed_trait_match.w
 it arity validation (§3.7). Sema propagates expected
function type into check_closure. If arity != 1 and it used,
emit E0902. Tests: it_chained_pipeline.w, it_method_syntax.w
 Closure capture inference (§3.6). Current: all captures
are copies. Needed: borrow by default, mutable borrow when
mutated, move when outlives scope. Tests: capture_move.w,
capture_error.w
 Operator overloading (§5.10). Sema looks up Add/Sub
etc. trait impl for user types in binary ops. Codegen dispatches
to trait method. Test: behav_op_overload.w

Exit gate
Each feature passes its associated test(s). Fixpoint holds after
each feature lands. Unimplemented feature test count drops
significantly.