//! expect-debug-alloc: leak count=0
//! expect-stdout: holders 3
//! expect-stdout: holders 1
//! expect-stdout: alpha beta
//! expect-stdout: ok

// #2449: InternPool and AstPool are counted handles. A clone is another
// holder; a dropped handle releases; the last release frees the symbol
// tables, the maps, the string arena's pages and the node tables. Before
// this, both were Copy handles over raw allocations with no Drop: every
// InternPool.init() leaked a 1 MB arena page by construction (the LSP made
// one per reparse, the test runner one per discovered file).

use InternPool
use Ast

type Keeper { intern: InternPool, ast: AstPool }

fn keep(intern: &InternPool, ast: &AstPool) -> Keeper:
    Keeper { intern: intern.clone(), ast: ast.clone() }

fn main:
    var intern = InternPool.init()
    var ast = AstPool.new()
    let a = intern.intern_str("alpha")
    let b = intern.intern_str("beta")
    let node = ast.add_node(1, 0, 5, a, b, 0)
    let first = keep(intern, ast)
    let second = keep(intern, ast)
    print(f"holders {intern.holders()}")
    // A holder interns through its own handle; the others see it.
    let c = second.intern.intern_str("gamma")
    assert(intern.resolve(c) == "gamma")
    assert(first.ast.get_data0(node) == a)
    drop(first)
    drop(second)
    print(f"holders {intern.holders()}")
    print(intern.resolve(a) ++ " " ++ intern.resolve(b))
    // A string longer than a page gets its own page; it is freed too.
    var big = ""
    for i in 0..70000: big = big ++ "0123456789abcdef"
    let huge = intern.intern_str(big)
    assert(intern.resolve(huge).len() == big.len())
    print("ok")
