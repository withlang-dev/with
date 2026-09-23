//! expect-error: let ... else requires a diverging else branch

// A multi-statement else block is the branch (#1382); its tail must diverge.
fn h(o: Option[i32]) -> i32:
    let Some(v) = o else:
        print("miss")
        0
    v

fn main:
    print(f"{h(Some(1))}")
