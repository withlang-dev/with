//! expect-stdout: item-0|item-1|item-2|
//! expect-stdout: last abcd
//! expect-stdout: ab
//! expect-stdout: true false
//! expect-stdout: user

// D111 classes the stack's battery found; run under the debug allocator.
// - a comprehension stores its element: a generator's yielded view is
//   copied, not kept (the next resume overwrote `buf`);
// - a str field read through its binding copies (it moved the field out);
// - a D60 tail assignment's read moves the local out (it leaked a hold);
// - `sub in text` lowers through its D110 signature row;
// - a user global named `name` does not shadow std.os's comptime local.
type S { s: str, n: i32 }

var name: str = ""

gen fn labels(count: i32) -> &str:
    var buf = ""
    for i in 0..count:
        buf = f"item-{i}"
        yield &buf

fn last_seen() -> str:
    var x = S { s: "ab" ++ "cd", n: 0 }
    let p = x.s
    var seen = ""
    var k = 0
    while k < 5:
        seen = p
        if k == 1:
            x.s = "zz" ++ "zz"
            break
        k += 1
    f"last {seen}"

fn keep[T](x: T) -> T:
    var y = x
    y = y

fn main:
    let kept = [s for s in labels(3)]
    var out = ""
    for s in kept: out = out ++ s ++ "|"
    print(out)
    print(last_seen())
    print(keep("a" ++ "b"))
    let text = "hello"
    print(f"{"ell" in text} {"xyz" in text}")
    name = "user"
    print(name)
