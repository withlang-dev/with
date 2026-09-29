//! expect-stdout: 8 9 12

// §21.1 rule 1 (Eric 2026-09-29): `writes` is reserved only as a
// declaration's last clause; a parameter, a local and a function may be
// named `writes` (behav_writes_clause_contextual_keyword.w: a global and a
// field). `writes(3)` and `double(writes: 4)` are ordinary calls.
fn writes(n: i32) -> i32: n * 3
fn double(writes: i32) -> i32: writes * 2

fn main:
    let writes_now = double(4)
    let result = writes(3)
    let total = {
        let writes = 12
        writes
    }
    print(f"{writes_now} {result} {total}")
