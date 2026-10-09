//! expect-check-fail: call to `grow` mutates global `HIDDEN` while `r` is a live view into it

// #1903 (§21.1 rule 6): the global may be private to its module; the view
// a public function returns of it still has it as origin.

use issue1903.hidden

fn main:
    seed(41)
    let x: List[i32] = List.new()
    let r = first(&x)
    grow()
    print(*r)
