//! expect-stdout: cba|ba|ba

// §20/§21: locals with Drop are dropped in REVERSE declaration order at every
// scope exit — normal fallthrough, early return, and break.

var T = ""
type R { id: str }
impl Drop for R:
    fn drop(move self: Self):
        T = T ++ self.id

fn three:
    let a = R { id: "a" }
    let b = R { id: "b" }
    let c = R { id: "c" }

fn early(n: i32):
    let a = R { id: "a" }
    let b = R { id: "b" }
    if n > 0:
        return
    T = T ++ "x"

fn brk:
    var i = 0
    while i < 1:
        let a = R { id: "a" }
        let b = R { id: "b" }
        break

fn main:
    three()
    T = T ++ "|"
    early(1)
    T = T ++ "|"
    brk()
    print(T)
