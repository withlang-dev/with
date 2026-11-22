//! expect-error: live view

// #1810 over #1819: a `&str` view of a global str is live across a callee
// that reassigns the global. §9.1c makes globals places under §21.1, so the
// call is a mutation of `G` under a live view and is refused. The view is
// `{ptr, len}`, so the program, if accepted, would read the buffer that
// `G = …` frees (under the old pointer-to-header `&str` it read the new
// value by accident) — #1810 lands only on top of this refusal.
var G: str = "ab" ++ "cd"

fn change(): G = "wx" ++ "yz"

fn show(r: &str):
    change()
    print(r)

fn main:
    show(G)
