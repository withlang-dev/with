//! expect-stdout: 42
//! expect-stdout: hello
//! expect-stdout: 15
//! expect-stdout: 99
//! expect-stdout: 1
//! expect-stdout: 1
//! expect-stdout: 17

// §2.4 / §6.2 / §6.3 IndexPlace behavioral tests.

type Item { value: i32, name: str }

type Counter { val: i32 }

fn Counter.increment(mut self: Self):
    self.val = self.val + 1

var f_calls = 0
var g_calls = 0

fn f() -> i32:
    f_calls = f_calls + 1
    0

fn g() -> i32:
    g_calls = g_calls + 1
    7

fn main:
    // §6.2 direct index assignment
    let xs: Vec[i32] = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    xs[1] = 42
    print(int_to_string(xs[1] as i64))

    // §6.2 nested field assignment through index
    let items: Vec[Item] = Vec.new()
    items.push(Item { value: 0, name: "world" })
    items[0].name = "hello"
    print(items[0].name)

    // §6.3 compound assignment through index
    let ys: Vec[i32] = Vec.new()
    ys.push(10)
    ys[0] += 5
    print(int_to_string(ys[0] as i64))

    // §6.2 mutating receiver call through index
    let counters: Vec[Counter] = Vec.new()
    counters.push(Counter { val: 98 })
    counters[0].increment()
    print(int_to_string(counters[0].val as i64))

    // §6.3 single-evaluation rule: xs[f()] += g()
    let zs: Vec[i32] = Vec.new()
    zs.push(10)
    zs[f()] += g()
    print(int_to_string(f_calls as i64))
    print(int_to_string(g_calls as i64))
    print(int_to_string(zs[0] as i64))
