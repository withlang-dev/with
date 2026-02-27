//! expect-stdout: ok

// Behavior test: operator overloading
// Tests: operator tokens used in overloading, type system support

use Token
use Lexer
use Ast
use Type
use Traits

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_operator_tokens:
    var tokens = lex("+ - * == !=")
    assert(TokenList.tag_at(tokens, 0) == TK_PLUS())
    assert(TokenList.tag_at(tokens, 1) == TK_MINUS())
    assert(TokenList.tag_at(tokens, 2) == TK_STAR())
    assert(TokenList.tag_at(tokens, 3) == TK_EQ_EQ())
    assert(TokenList.tag_at(tokens, 4) == TK_BANG_EQ())

fn test_solver_add_trait:
    // Operator overloading works through traits: Add, Sub, Mul, Eq
    var solver = TraitSolver.new()
    TraitSolver.add_trait(solver, "Add", 1)
    TraitSolver.add_trait(solver, "Sub", 1)
    TraitSolver.add_trait(solver, "Mul", 1)
    TraitSolver.add_trait(solver, "Eq", 1)
    assert(TraitSolver.trait_count(solver) == 4)
    // Implement Add for a custom type (id=20)
    TraitSolver.add_impl(solver, "Add", 20)
    assert(TraitSolver.resolve(solver, "Add", 20) == 1)
    assert(TraitSolver.resolve(solver, "Sub", 20) == 0)

fn test_binop_constants:
    // Verify binary op constants are distinct
    assert(OP_ADD() == 0)
    assert(OP_SUB() == 1)
    assert(OP_MUL() == 2)
    assert(OP_DIV() == 3)
    assert(OP_MOD() == 4)
    assert(OP_EQ() == 5)
    assert(OP_NEQ() == 6)
    assert(OP_LT() == 7)
    assert(OP_GT() == 8)
    assert(OP_LTE() == 9)
    assert(OP_GTE() == 10)

fn main:
    test_operator_tokens()
    test_solver_add_trait()
    test_binop_constants()
    println("ok")
