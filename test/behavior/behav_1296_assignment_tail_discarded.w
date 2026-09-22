//! expect-stdout: ok

// #1296 (§9.1): an assignment in tail position is discarded — the body is
// Unit, so §4.9 supplies `Ok(())` for `Result[Unit, E]` and §4.10 supplies
// `T.default()` for a `-> T` with `T: Default`. Both body spellings (block,
// single statement) and both assignment spellings (`=`, `+=`) get one answer.

error E = Bad

type P { cur: Option[i32] = None, n: i32 = 0 }

fn next(n: i32) -> Result[Option[i32], E]:
    if n > 3: return Err(.Bad)
    Some(n)

extend P:
    mut fn bump() -> Result[Unit, E]:
        self.cur = next(self.n)?
    mut fn bump2() -> Result[Unit, E]:
        let c = next(self.n)?
        self.cur = c
    mut fn bump3() -> Result[Unit, E]:
        self.n += 1

var g: i32 = 0
var s: str = "a"

// §4.10: the tail is discarded, the function returns i32.default() — not 1.
fn inc -> i32: g += 1
fn inc_block -> i32:
    g += 1
    g += 1
fn set_str -> str: s = "zz"
fn set_str_grouped -> str: (s = "yy")

// Unannotated: the tail is Unit (D43), so the function is Unit.
fn set5(): g = 5
fn set6():
    g = 6

// A closure body that is an assignment is discarded the same way.
fn via_closure() -> i32:
    var n = 0
    let f: fn() -> i32 = () => n += 10
    f()

fn main:
    var p = P { }
    p.bump().unwrap()
    assert(p.cur == Some(0))
    p.bump2().unwrap()
    p.bump3().unwrap()
    assert(p.n == 1)
    p.n = 9
    assert(p.bump().is_err())
    assert(inc() == 0)
    assert(g == 1)
    assert(inc_block() == 0)
    assert(g == 3)
    assert(set_str() == "")
    assert(s == "zz")
    assert(set_str_grouped() == "")
    assert(s == "yy")
    set5()
    assert(g == 5)
    set6()
    assert(g == 6)
    assert(via_closure() == 0)
    print("ok")
