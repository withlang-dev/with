//! expect-stdout: 14

// §9.1c, §18.1: a local may take the name of a global its module cannot see
// (race_shadowed_global's private `counter`). That local is the local:
// writing it writes no global, so the global stays never-mutated and every
// read of it is race-free in a concurrent program. The race proof's access
// fact counted the local as the global and refused this program with E0921
// at the local's own lines and at the global's read.
use race_shadowed_global

async fn work() -> i32: 1

fn bump() -> i32:
    var counter = 5
    counter += 1
    counter

fn main:
    let t = work()
    print(f"{bump() + peek_counter() + t.await}")
