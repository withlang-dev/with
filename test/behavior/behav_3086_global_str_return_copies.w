//! expect-stdout: [abc1] [abc1] [abc1] [abc1] 4
//! expect-stdout: [xyz2] [xyz2] 4

// #3086 (D52, §9.1c): a global is never moved out. Returning a global str by
// name — as a block tail or in a `return` — copies it (a str retains), and a
// global first touched inside a block keeps one proxy that no block drops.
// `return g` moved the proxy and blanked the global; a global assigned inside
// an `if` was dropped at the if's exit and re-proxied after it.
var g: str = ""
var ready: i32 = 0
var h: str = ""

fn tail() -> str: g

fn ret() -> str:
    if g.len() > 100: return ""
    return g

fn lazily() -> str:
    if ready == 0:
        h = f"xyz{2}"
        ready = 1
    h

fn main:
    g = f"abc{1}"
    print(f"[{tail()}] [{tail()}] [{ret()}] [{ret()}] {g.len()}")
    print(f"[{lazily()}] [{lazily()}] {h.len()}")
