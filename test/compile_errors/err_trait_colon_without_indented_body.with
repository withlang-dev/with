//! expect-check-fail: expected an indented trait body after ':'

// #1346 (§29.13 Form 2): a ':' that ends the line introduces an indented
// body; with nothing indented below it the header is a syntax error, as for
// `fn f:`. An empty trait is `trait Empty {}`.

trait Empty:

fn main:
    print("unreachable")
