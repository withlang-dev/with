//! expect-error: `first` declares its returned view `from p`, but its body never returns a view derived from `p`: a declared origin the body does not derive the view from is an error, never a silent widening (§21.1 rule 6)

// #1903 (§21.1 rule 6): a declared origin the body does not derive the view
// from is an error.

var HIDDEN: List[i32] = List.new()

fn first(p: &List[i32]) -> &i32 from p: &HIDDEN[0]

fn main:
    HIDDEN.push(41)
    let x: List[i32] = List.new()
    print(*first(&x))
