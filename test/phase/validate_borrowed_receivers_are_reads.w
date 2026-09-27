//! args: --validate-all
//! expect-check-stdout: validate-all: ok

// #1505 (§9.9, §2.4): a receiver the callee borrows is lowered as a read of
// its place, so the ownership validator can judge call arguments (#1414's
// rule) without refusing these programs. `ch in s` calls the borrowing
// with_str_contains_char_ref, and a user IndexPlace's `get(self: &Self)`
// and `set(mut self: Self)` take the receiver in place; each lowered the
// receiver as an OK_MOVE argument, so `--dump-drop-plan` said the final
// drop of `email` and `g` was `state_before=Moved action=skip` although
// codegen ran it.

type Grid {
    data: Vec[i32],
    width: i32,
}

impl IndexPlace[i32, i32] for Grid:
    fn get(self: &Self, index: i32) -> i32:
        self.data.get(index)

    fn set(mut self: Self, index: i32, value: i32):
        with self.data.slot(index) as mut s:
            s.set(value)

fn main:
    let n = 3
    let email = f"user{n}@example.com"
    assert('@' in email)
    assert('!' not in email)
    var g = Grid { data: Vec.new(), width: 3 }
    g.data.push(1)
    g.data.push(2)
    g[0] += 100
    g[1] += 10
    g[1] = g[0] + g[1]
    print(f"{email} {g[0]} {g[1]}")
