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
use Parser

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
    // impl blocks are desugared to individual fn decls with mangled names
    let decl = AstPool.get_decl(p.pool, 0)
    assert(AstPool.kind(p.pool, decl) == NK_FN_DECL())

fn test_solver_multi_trait:
    var solver = TraitSolver.new()
    // Register traits with i32 name symbols and empty method Vecs
    var mn1 = Vec.new()
    var mp1 = Vec.new()
    var mr1 = Vec.new()
    mn1.push(100)
    mp1.push(1)
    mr1.push(TYPE_STR())
    TraitSolver.add_trait(solver, 1, mn1, mp1, mr1)  // "Display" = 1
    var mn2 = Vec.new()
    var mp2 = Vec.new()
    var mr2 = Vec.new()
    TraitSolver.add_trait(solver, 2, mn2, mp2, mr2)  // "Clone" = 2
    var mn3 = Vec.new()
    var mp3 = Vec.new()
    var mr3 = Vec.new()
    TraitSolver.add_trait(solver, 3, mn3, mp3, mr3)  // "Eq" = 3
    assert(solver.trait_names.len() == 3)
    // Add impls
    var im1 = Vec.new()
    im1.push(100)
    TraitSolver.add_impl(solver, 5, 1, im1)  // type 5 implements Display
    var im2 = Vec.new()
    TraitSolver.add_impl(solver, 5, 2, im2)  // type 5 implements Clone
    var im3 = Vec.new()
    TraitSolver.add_impl(solver, 5, 3, im3)  // type 5 implements Eq
    // Resolve all — returns impl index (>= 0) on success
    assert(TraitSolver.resolve(solver, 1, 5) >= 0)
    assert(TraitSolver.resolve(solver, 2, 5) >= 0)
    assert(TraitSolver.resolve(solver, 3, 5) >= 0)
    // Not implemented for type 10 — returns negative error code
    assert(TraitSolver.resolve(solver, 1, 10) < 0)

fn test_solver_obligation_list:
    var solver = TraitSolver.new()
    var mn = Vec.new()
    var mp = Vec.new()
    var mr = Vec.new()
    TraitSolver.add_trait(solver, 10, mn, mp, mr)  // "Add" = 10
    var im = Vec.new()
    TraitSolver.add_impl(solver, TYPE_I32(), 10, im)
    var obs = ObligationList.new()
    let ob = TraitObligation { trait_name: 10, self_type: TYPE_I32(), span_start: 0, span_end: 0 }
    ObligationList.add(obs, ob)
    assert(ObligationList.count(obs) == 1)
    let all_ok = ObligationList.resolve_all(obs, solver)
    assert(all_ok == TR_OK())

fn test_solver_obligation_fail:
    var solver = TraitSolver.new()
    var mn = Vec.new()
    var mp = Vec.new()
    var mr = Vec.new()
    TraitSolver.add_trait(solver, 10, mn, mp, mr)  // "Add" = 10
    // No impl for bool
    var obs = ObligationList.new()
    let ob = TraitObligation { trait_name: 10, self_type: TYPE_BOOL(), span_start: 0, span_end: 0 }
    ObligationList.add(obs, ob)
    let all_ok = ObligationList.resolve_all(obs, solver)
    assert(all_ok != TR_OK())

fn main:
    test_trait_keywords()
    test_parse_trait_decl()
    test_parse_impl_block()
    test_solver_multi_trait()
    test_solver_obligation_list()
    test_solver_obligation_fail()
    println("ok")
