//! expect-stdout: ok

// Behavior test: traits
// Tests: trait declaration, impl, bounds, solver

use Token
use Lexer
use Ast
use Type
use Traits
use Sema
use InternPool

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_trait_keywords:
    var tokens = lex("trait impl dyn")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_TRAIT())
    assert(TokenList.tag_at(tokens, 1) == TK_KW_IMPL())
    assert(TokenList.tag_at(tokens, 2) == TK_KW_DYN())

fn test_parse_trait_decl:
    let src = "trait Display:\n    fn display(self) -> str\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    assert(AstPool.decl_count(p.pool) >= 1)
    let decl = AstPool.get_decl(p.pool, 0)
    assert(AstPool.kind(p.pool, decl) == NK_TRAIT_DECL())

fn test_parse_impl_block:
    let src = "impl Display for Point:\n    fn display(self) -> str:\n        \"point\"\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    assert(AstPool.decl_count(p.pool) >= 1)
    let decl = AstPool.get_decl(p.pool, 0)
    assert(AstPool.kind(p.pool, decl) == NK_IMPL_DECL())

fn test_solver_multi_trait:
    var solver = TraitSolver.new()
    TraitSolver.add_trait(solver, "Display", 1)
    TraitSolver.add_trait(solver, "Clone", 0)
    TraitSolver.add_trait(solver, "Eq", 0)
    assert(TraitSolver.trait_count(solver) == 3)
    // Add impls
    TraitSolver.add_impl(solver, "Display", 5)
    TraitSolver.add_impl(solver, "Clone", 5)
    TraitSolver.add_impl(solver, "Eq", 5)
    // Resolve all
    assert(TraitSolver.resolve(solver, "Display", 5) == 1)
    assert(TraitSolver.resolve(solver, "Clone", 5) == 1)
    assert(TraitSolver.resolve(solver, "Eq", 5) == 1)
    // Not implemented for type 10
    assert(TraitSolver.resolve(solver, "Display", 10) == 0)

fn test_solver_obligation_list:
    var solver = TraitSolver.new()
    TraitSolver.add_trait(solver, "Add", 0)
    TraitSolver.add_impl(solver, "Add", TYPE_I32())
    var obs = ObligationList.new()
    ObligationList.add(obs, "Add", TYPE_I32())
    assert(ObligationList.count(obs) == 1)
    let all_ok = ObligationList.resolve_all(obs, solver)
    assert(all_ok == 1)

fn test_solver_obligation_fail:
    var solver = TraitSolver.new()
    TraitSolver.add_trait(solver, "Add", 0)
    // No impl for bool
    var obs = ObligationList.new()
    ObligationList.add(obs, "Add", TYPE_BOOL())
    let all_ok = ObligationList.resolve_all(obs, solver)
    assert(all_ok == 0)

fn main:
    test_trait_keywords()
    test_parse_trait_decl()
    test_parse_impl_block()
    test_solver_multi_trait()
    test_solver_obligation_list()
    test_solver_obligation_fail()
    println("ok")
