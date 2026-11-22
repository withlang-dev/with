//! expect-stdout: cba|12|0LLL

// §2.4.1.6/7/8: reverse-order drop, drop-before-overwrite on reassignment, and
// per-iteration drop of a reassigned loop variable (no leak, no double free).

var T = ""
type R { id: str }
impl Drop for R:
    fn drop(move self: Self):
        T = T ++ self.id

fn make(s: str) -> R:
    R { id: s }

fn order:
    let a = make("a")
    let b = make("b")
    let c = make("c")

fn reassign:
    var h = make("1")
    h = make("2")

fn loop_reinit:
    var h = make("0")
    var i = 0
    while i < 3:
        h = make("L")
        i = i + 1

fn main:
    order()
    T = T ++ "|"
    reassign()
    T = T ++ "|"
    loop_reinit()
    print(T)
