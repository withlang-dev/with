//! expect-stdout: drop 2
//! expect-stdout: drop 1
//! expect-stdout: 0
//! expect-stdout: drop 9
//! expect-stdout: drop 7
//! expect-stdout: drop 5
//! expect-stdout: drop 3
//! expect-stdout: end
//! expect-stdout: drop 4

// #1786 (§2.5.1, §9.1): a statement's value is discarded AND dropped. An
// intrinsic method's result (`v.pop()` lowers to VEC_POP) was never
// registered as a statement temp, so a discarded `Some(payload)` leaked;
// and an entry point's tail is statement position (§9.1: `main`, `@[entry]`
// and `test_*` do not infer), so a tail call's value is dropped at the
// statement's end too, not moved into the entry's return slot — and a
// discarded tail keeps its own type, so the intrinsic's result temp is
// sized for the Option, not for Unit.

type Fd:
    n: i32
impl Drop for Fd:
    move fn drop(): print(f"drop {self.n}")

fn mk(n: i32) -> Fd: Fd { n: n }

fn test_tail_call_is_a_statement:
    mk(7)

fn test_tail_pop_is_a_statement:
    var v: Vec[Fd] = Vec.new()
    v.push(Fd { n: 3 })
    v.push(Fd { n: 5 })
    v.pop()

fn main:
    var v: Vec[Fd] = Vec.new()
    v.push(Fd { n: 1 })
    v.push(Fd { n: 2 })
    v.pop()
    let _ = v.pop()
    print(v.len())
    mk(9)
    test_tail_call_is_a_statement()
    test_tail_pop_is_a_statement()
    v.push(Fd { n: 4 })
    print("end")
