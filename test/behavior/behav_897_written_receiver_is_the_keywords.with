//! expect-stdout: 1 5 9
// #897 (D7): a receiver written untyped beside the method keyword
// (`mut fn take_it(mut self)`) is the keyword's receiver. Parsed as an
// untyped parameter it reached MIR untyped: "invalid MIR before codegen ...
// use rvalue type is incompatible with assign destination".
type P { v: List[i32], n: i32 }

impl P:
    mut fn take_it(mut self) -> isize:
        var x: List[i32] = move self.v
        x.len()
    fn read_n(self): self.n
    move fn into_sum(move self, extra: i32): self.n + extra

fn main:
    var xs: List[i32] = List.new()
    xs.push(7)
    var p = P { v: xs, n: 5 }
    let taken = p.take_it()
    let q = P { v: List.new(), n: 4 }
    print(f"{taken} {p.read_n()} {q.into_sum(5)}")
