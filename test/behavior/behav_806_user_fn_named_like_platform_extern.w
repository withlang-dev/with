//! expect-stdout: Hello 3 4
// #806 (§18.1): a program's own function named like a platform API is the
// function the program calls. On Windows the runtime declares Winsock's
// `extern fn accept`, and the call `accept(&eng)` was judged by the
// extern's rule: "manual extern function call requires unsafe context".
trait Greet:
    fn hello(self: &Self) -> str

type English {}

impl Greet for English:
    fn hello(self: &Self) -> str: "Hello"

fn accept(g: &dyn Greet) -> str: g.hello()

fn send(n: &i32) -> i32: n + 2

fn listen(n: &i32) -> i32: n + 3

fn main:
    let eng = English {}
    let one = 1
    print(f"{accept(&eng)} {send(&one)} {listen(&one)}")
