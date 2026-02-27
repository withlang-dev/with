// Integration test: trait bounds with generics and dyn dispatch
trait Measurable =
    fn measure(self: Self) -> i32

type Length = { cm: i32 }
type Weight = { grams: i32 }

impl Measurable for Length =
    fn measure(self: Length) -> i32: self.cm

impl Measurable for Weight =
    fn measure(self: Weight) -> i32: self.grams

fn total[T: Measurable](a: T, b: T) -> i32:
    a.measure() + b.measure()

fn print_measure(m: dyn Measurable) -> void:
    println(m.measure())

fn main -> i32:
    let l1 = Length { cm: 100 }
    let l2 = Length { cm: 50 }
    println(total(l1, l2))
    let w = Weight { grams: 500 }
    print_measure(l1)
    print_measure(w)
    0
