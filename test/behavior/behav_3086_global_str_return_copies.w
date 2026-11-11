//! expect-stdout: [abc1] [abc1]
//! expect-stdout: [abc1] [abc1] 4

// #3086 (D52, D111): a global `str` returned by name is copied, never moved
// out: `return g` blanked the global, and a global assigned inside a block
// got a scope-dropped proxy.
var ready: i32 = 0
var g: str = ""
fn fp_ret() -> str:
    if g.len() > 100: return ""
    return g
fn fp3() -> str:
    if ready == 0:
        g = f"abc{1}"
        ready = 1
    g
fn main:
    g = f"abc{1}"
    print(f"[{fp_ret()}] [{fp_ret()}]")
    print(f"[{fp3()}] [{fp3()}] {g.len()}")
