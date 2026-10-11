//! expect-stdout: 10 20 42 3 5 60

// D128 (§4.2.1): the demand reaches a literal-typed local through a block
// tail, a slice of a list literal's binding, a struct literal field, a
// `loop`'s break value, an assignment that a decision made typed, and a
// `push` of a literal that a typed demand overrides.
type Holder ephemeral { view: &i32 }
fn sum_slice(xs: []i32) -> i32:
    var t: i32 = 0
    for x in xs: t += x
    t
fn filled() -> List[i32]:
    var xs = List.new()
    xs.push(10)
    xs.push(20)
    xs.push(30)
    xs

fn tail() -> i32:
    var acc = 7
    acc = acc + 3
    acc % 100

fn looped() -> i32:
    loop:
        break 42

fn last_even() -> i32:
    var last = -1
    for i in 0..5:
        if i % 2 == 1: continue
        last = i
    last + 1

fn main:
    let a = [10, 20, 30, 40]
    let s: []i32 = a[1..3]
    let x = 1
    let h = Holder { view: &x }
    print(f"{tail()} {sum_slice(s) - 30} {looped()} {*h.view + 2} {last_even()} {filled()[0] + filled()[1] + filled()[2]}")
