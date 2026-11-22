//! expect-stdout: trace: drop1 let drop2 var drop3 pattern drop4 let-else deferred defer drop6 inline seven7 end

// #1851 (§2.4): a `{ ... }` block is a scope even when it holds one
// statement. Its `let`, `var`, pattern `let`, `let ... else` binding drops at
// the `}`, and its `defer` runs there. The parser returned the lone statement
// in place of the block, so the binding joined the enclosing scope: no
// `dropN` / `deferred` reached the trace before `end`, and the name stayed
// visible after the `}` (err_1851_brace_block_binding_escapes). A block of
// one expression is still that expression's value. One trace line: each
// expect-stdout line is matched as a substring, so order and count are
// pinned only inside a line.

global var TRACE = ""

fn note(s: &str): TRACE = TRACE ++ " " ++ s

type Tok:
    n: i32

impl Drop for Tok:
    move fn drop(): note(f"drop{self.n}")

fn pair() -> (Tok, i32): (Tok { n: 3 }, 30)
fn maybe() -> Option[Tok]: Some(Tok { n: 4 })

fn main:
    {
        let t = Tok { n: 1 }
    }
    note("let")
    {
        var u = Tok { n: 2 }
    }
    note("var")
    {
        let (p, k) = pair()
    }
    note("pattern")
    {
        let Some(m) = maybe() else: return
    }
    note("let-else")
    {
        defer: note("deferred")
    }
    note("defer")
    { let w = Tok { n: 6 } }
    note("inline")
    let seven = { 3 + 4 }
    note(f"seven{seven}")
    note("end")
    print("trace:" ++ TRACE)
