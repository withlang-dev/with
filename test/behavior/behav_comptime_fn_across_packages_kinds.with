//! expect-stdout: 7 12 8
// The rule holds for every kind of function: an operator (`+` is
// `Add.add`), a trait method, and a generic function, each declared
// `comptime fn` in another package.
use ctlib.math

const SUM: i32 = comptime (Money { cents: 3 } + Money { cents: 4 }).cents
const SCALED: i32 = comptime Money { cents: 4 }.scaled(3)
const FIRST: i32 = comptime first_of(8, 9)

fn main:
    print(f"{SUM} {SCALED} {FIRST}")
