//! expect-stdout: ok

// Behavior test: generics
// Tests: generic type parameters, bounds, trait solver

use Token
use Lexer
use Ast
use Type
use Traits
use InternPool

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_type_generic_param:
    var types = TypeTable.new()
    var pool = AstPool.new()
    let name = AstPool.add_string(pool, "T")
    let gp = TypeTable.add_generic_param(types, name)
    assert(TypeTable.kind(types, gp) == TK_GENERIC_PARAM())
    assert(TypeTable.get_data0(types, gp) == name)

fn test_type_trait_obj:
    var types = TypeTable.new()
    var pool = AstPool.new()
    let name = AstPool.add_string(pool, "Display")
    let to = TypeTable.add_trait_obj(types, name)
    assert(TypeTable.kind(types, to) == TK_TRAIT_OBJ())

fn test_trait_solver:
    var solver = TraitSolver.new()
    // Register a trait with one method
    var method_names = Vec.new()
    method_names.push(1)  // method name symbol
    var method_params = Vec.new()
    method_params.push(0)  // 0 params
    var method_rets = Vec.new()
    method_rets.push(0)  // void return
    TraitSolver.add_trait(solver, 100, method_names, method_params, method_rets)
    // Register an impl: type 5 implements trait 100
    var impl_methods = Vec.new()
    impl_methods.push(1)
    TraitSolver.add_impl(solver, 5, 100, impl_methods)
    // Resolve
    let result = TraitSolver.resolve(solver, 100, 5)
    assert(result >= 0)  // found
    // Not implemented
    let result2 = TraitSolver.resolve(solver, 100, 99)
    assert(result2 < 0)  // not found

fn test_trait_cache:
    var solver = TraitSolver.new()
    var mn = Vec.new()
    mn.push(1)
    var mp = Vec.new()
    mp.push(0)
    var mr = Vec.new()
    mr.push(0)
    TraitSolver.add_trait(solver, 200, mn, mp, mr)
    var im = Vec.new()
    im.push(1)
    TraitSolver.add_impl(solver, 5, 200, im)
    // First resolve (caches)
    let r1 = TraitSolver.resolve(solver, 200, 5)
    assert(r1 >= 0)
    // Second resolve (hits cache)
    let r2 = TraitSolver.resolve(solver, 200, 5)
    assert(r2 >= 0)

fn test_trait_coherence:
    var solver = TraitSolver.new()
    var mn = Vec.new()
    mn.push(1)
    var mp = Vec.new()
    mp.push(0)
    var mr = Vec.new()
    mr.push(0)
    TraitSolver.add_trait(solver, 300, mn, mp, mr)
    var im1 = Vec.new()
    im1.push(1)
    TraitSolver.add_impl(solver, 5, 300, im1)
    var im2 = Vec.new()
    im2.push(1)
    TraitSolver.add_impl(solver, 6, 300, im2)
    // No overlap - different types
    let ok = TraitSolver.check_coherence(solver)
    assert(ok)

fn main:
    test_type_generic_param()
    test_type_trait_obj()
    test_trait_solver()
    test_trait_cache()
    test_trait_coherence()
    println("ok")
