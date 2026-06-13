//! expect-stdout: ok

type Number { value: i32 }
type Matrix1 { value: i32 }

impl Add[Number, Number] for Number:
    fn add(self: &Self, rhs: &Number) -> Number:
        Number { value: self.value + rhs.value }

impl Sub[Number, Number] for Number:
    fn sub(self: &Self, rhs: &Number) -> Number:
        Number { value: self.value - rhs.value }

impl Mul[Number, Number] for Number:
    fn mul(self: &Self, rhs: &Number) -> Number:
        Number { value: self.value * rhs.value }

impl Div[Number, Number] for Number:
    fn div(self: &Self, rhs: &Number) -> Number:
        Number { value: self.value / rhs.value }

impl Neg[Number] for Number:
    fn neg(self: &Self) -> Number:
        Number { value: 0 - self.value }

impl MatMul[Matrix1, Matrix1] for Matrix1:
    fn matmul(self: &Self, rhs: &Matrix1) -> Matrix1:
        Matrix1 { value: self.value * rhs.value }

fn add_value[T: Add[T, T]](left: T, right: T) -> T:
    left.add(right)

fn sub_value[T: Sub[T, T]](left: T, right: T) -> T:
    left.sub(right)

fn mul_value[T: Mul[T, T]](left: T, right: T) -> T:
    left.mul(right)

fn div_value[T: Div[T, T]](left: T, right: T) -> T:
    left.div(right)

fn neg_value[T: Neg[T]](value: T) -> T:
    value.neg()

fn matmul_value[T: MatMul[T, T]](left: T, right: T) -> T:
    left.matmul(right)

fn n(value: i32) -> Number:
    Number { value }

fn m(value: i32) -> Matrix1:
    Matrix1 { value }

fn main:
    assert(add_value(n(20), n(5)).value == 25)
    assert(sub_value(n(20), n(5)).value == 15)
    assert(mul_value(n(20), n(5)).value == 100)
    assert(div_value(n(20), n(5)).value == 4)
    assert(neg_value(n(5)).value == -5)

    let op_sum = n(20) + n(5)
    assert(op_sum.value == 25)
    let op_diff = n(20) - n(5)
    assert(op_diff.value == 15)
    let op_product = n(20) * n(5)
    assert(op_product.value == 100)
    let op_quotient = n(20) / n(5)
    assert(op_quotient.value == 4)

    assert(matmul_value(m(6), m(7)).value == 42)
    let op_matmul = m(6) @ m(7)
    assert(op_matmul.value == 42)

    print("ok")
