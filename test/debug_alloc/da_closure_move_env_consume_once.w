//! expect-debug-alloc: leak count=0
//! expect-stdout: abc
//! expect-stdout: done

// D63: a `move ||` closure whose body consumes its capture moves it out of
// the owned cell when called; the cell's drop fn then finds the slot blank
// and frees only the cell. Exactly one drop of the str.
fn mk(s: str) -> fn() -> str: move () => s

fn main:
    let take = mk("abc".clone())
    print(take())
    print("done")
