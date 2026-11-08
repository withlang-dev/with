//! expect-debug-alloc: leak count=0
//! expect-stdout: p1.w p2.w p3.w

// #3080 (D111): a str field read as a function's tail from an owned local
// is a copy the temp holds, so it retains; the owner's scope-exit drop then
// releases one holder and the caller receives the other. Before, the tail
// read `_5 = copy _2.text` carried no hold, `drop(_2)` freed the buffer and
// the function returned it (a double free at the caller's drop). The
// `return` spelling and the `.clone()` spelling were already correct.
type V { kind: i32, text: str }
fn make(n: i32) -> V: V { kind: n, text: f"p{n}.w" }

fn text_of(n: i32) -> str:
    let value = make(n)
    if value.kind < 0: return ""
    value.text

fn text_of_ret(n: i32) -> str:
    let value = make(n)
    if value.kind >= 0:
        return value.text
    ""

fn text_of_nested(n: i32) -> str:
    let value = make(n)
    if value.kind > 0:
        let inner = make(n)
        inner.text
    else:
        value.text

fn main:
    print(f"{text_of(1)} {text_of_ret(2)} {text_of_nested(3)}")
