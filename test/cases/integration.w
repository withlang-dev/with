type Op = Add | Sub | Mul

fn apply(op: Op, a: i32, b: i32) -> i32 =
    match op
        Add -> a + b
        Sub -> a - b
        Mul -> a * b

type Pair = {
    first: i32,
    second: i32,
}

fn Pair.sum(self: Pair) -> i32 = self.first + self.second

fn Pair.apply_op(self: Pair, op: Op) -> i32 =
    apply(op, self.first, self.second)

fn main() -> i32 =
    let p = Pair { first: 20, second: 10 }
    let sum = p.sum()
    let product = p.apply_op(Mul)
    let diff = p.apply_op(Sub)
    sum - product - diff + 222
