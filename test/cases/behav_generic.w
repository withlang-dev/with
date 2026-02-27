//! expect-stdout: ok

// Behavior test: generics
// Tests: generic type parameters, bounds

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
    // Register a trait
    TraitSolver.add_trait(solver, "Display", 1)
    assert(TraitSolver.trait_count(solver) == 1)
    // Register an impl
    let type_id = 5  // some type id
    TraitSolver.add_impl(solver, "Display", type_id)
    assert(TraitSolver.impl_count(solver) == 1)
    // Resolve
    let result = TraitSolver.resolve(solver, "Display", type_id)
    assert(result == 1)  // found
    // Not implemented
    let result2 = TraitSolver.resolve(solver, "Display", 99)
    assert(result2 == 0)  // not found

fn test_trait_cache:
    var solver = TraitSolver.new()
    TraitSolver.add_trait(solver, "Clone", 0)
    TraitSolver.add_impl(solver, "Clone", 5)
    // First resolve (caches)
    let r1 = TraitSolver.resolve(solver, "Clone", 5)
    assert(r1 == 1)
    // Second resolve (hits cache)
    let r2 = TraitSolver.resolve(solver, "Clone", 5)
    assert(r2 == 1)

fn test_trait_coherence:
    var solver = TraitSolver.new()
    TraitSolver.add_trait(solver, "Eq", 0)
    TraitSolver.add_impl(solver, "Eq", 5)
    TraitSolver.add_impl(solver, "Eq", 6)
    // No overlap - different types
    let ok = TraitSolver.check_coherence(solver)
    assert(ok == 1)

fn main:
    test_type_generic_param()
    test_type_trait_obj()
    test_trait_solver()
    test_trait_cache()
    test_trait_coherence()
    println("ok")
