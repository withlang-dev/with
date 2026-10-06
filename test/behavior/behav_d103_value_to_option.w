//! expect-stdout: 3 4 5 6
//! expect-stdout: 7 none
//! expect-stdout: hi 2
//! expect-stdout: true
//! expect-stdout: 8 0
//! expect-stdout: -5 -7

// §4.9a (D103): where an `Option[T]` is demanded and the expression has
// type `T`, it is `Some(expression)` — once, at the demand: a call
// argument, a binding annotation, a struct field, a return, an
// assignment, and the arms of an `if` under an Option demand (`7` and
// `None` mix). `None` and an existing Option pass unchanged. Nothing is
// demanded of an operator's operands, so `opt == 3` stays an error
// (err_d103_operator_not_demand). The demand propagates into the payload:
// a named fn offered to `Option[extern "C" fn]` takes the C type, and an
// `i32` or a negated literal offered to `Option[i64]` widens.
type Holder { slot: Option[i32], name: Option[str] }

fn q(x: Option[i32]) -> i32: x.unwrap_or(0)
fn mk(flag: bool) -> Option[i32]: if flag: 5 else: None
fn p(x: Option[*const i32]) -> bool: x.is_some()
fn twice(x: i32) -> i32: x * 2
fn g(f: Option[extern "C" fn(i32) -> i32]) -> i32: match f:
    Some(h) => h(4)
    None => 0

fn main:
    let bound: Option[i32] = 4
    var assigned: Option[i32] = None
    assigned = 6
    print(f"{q(3)} {bound.unwrap()} {mk(true).unwrap()} {assigned.unwrap()}")
    let arms: Option[i32] = if q(1) == 1: 7 else: None
    let absent: Option[i32] = if q(1) == 2: 7 else: None
    print(f"{arms.unwrap()} {if absent.is_none(): \"none\" else: \"some\"}")
    var h = Holder { slot: 2, name: "hi" }
    let name = (move h.name).unwrap()
    print(f"{name} {h.slot.unwrap()}")
    let v = 9
    print(p(&raw const v))
    print(f"{g(twice)} {g(None)}")
    let narrow: i32 = -5
    let wide: Option[i64] = narrow
    let lit: Option[i64] = -7
    print(f"{wide.unwrap()} {lit.unwrap()}")
