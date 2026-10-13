use common

const DEPTH: i64 = 16 // BENCH_N
const M: i64 = 1000003
enum Expr:
    Num(i32)
    Add(i32, i32)
    Mul(i32, i32)
    Neg(i32)
type Interpreter { nodes: Vec[Expr] }

impl Interpreter:
    mut fn build(depth: i64, seed: u64) -> i32:
        let s = xs_next(seed)
        var node: Expr = .Num(xs_mod(s, 1000) as i32)
        if depth > 0:
            let k = xs_mod(s, 8)
            let a = self.build(depth - 1, s)
            if k < 1: node = .Neg(a)
            else:
                let b = self.build(depth - 1, xs_next(s))
                node = if k < 5: .Add(a, b) else: .Mul(a, b)
        let index = self.nodes.len() as i32
        self.nodes.push(node)
        index

    fn eval(index: i32, pass: i64) -> i64:
        match self.nodes[index]:
            .Num(v) => (v + pass) % M
            .Add(a, b) => (self.eval(a, pass) + self.eval(b, pass)) % M
            .Mul(a, b) => (self.eval(a, pass) * self.eval(b, pass)) % M
            .Neg(a) => (M - self.eval(a, pass)) % M

fn main:
    var interpreter = Interpreter { nodes: Vec.new() }
    let root = interpreter.build(DEPTH, 12345)
    var total: i64 = 0
    for p in 0..8: total = (total + interpreter.eval(root, p)) % M
    print(interpreter.nodes.len())
    print(total)
