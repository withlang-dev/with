//! expect-stdout: 2 1
// #2520 (§18.2): a program's own trait outranks a prelude trait with a
// method of the same name. `f64.one()` with the program's `Unit1.one` beside
// std's `One.one` was "ambiguous trait method"; the remedy it named (a
// bound) has no spelling at a direct call. Std's `One` still answers
// through a bound that names it.
trait Unit1:
    fn one() -> Self
impl Unit1 for f64:
    fn one(): 2.0

fn std_one[T: One]() -> T: T.one()

fn main:
    let unit: f64 = std_one()
    print(f"{f64.one()} {unit}")
