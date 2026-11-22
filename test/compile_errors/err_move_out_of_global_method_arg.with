//! expect-check-fail: cannot move out of global `g`

// D52 (§9.1c) on the method path (#1588): a global passed to a method's
// consuming parameter is diagnosed at that use — "cannot move out of
// global" — never as "use of moved value" at a later read. A `const` is
// exempt (behav_const_consumed_twice_materializes). A List global, not a
// str: a str global is read by copy (D111).

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
var g: List[Tok] = [Tok { id: 1 }, Tok { id: 2 }]

type T { inputs: List[List[Tok]] }
impl T:
    move fn input(path: List[Tok]) -> T:
        var t = self
        t.inputs.push(path)
        t

fn main:
    var t = T { inputs: List.new() }
    t = t.input(g)
    print(f"{t.inputs.len()} {g.len()}")
