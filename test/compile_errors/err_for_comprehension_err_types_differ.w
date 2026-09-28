//! expect-error: for-comprehension clauses must share one Err type

// §13.6a: a failure at any clause is the comprehension's failure, so every
// Result clause fails with the same Err type.
fn a() -> Result[i32, str]: Ok(1)
fn b() -> Result[i32, i64]: Ok(2)

fn main:
    let r = for x in a(); y in b(): yield x + y
    print(f"{r:?}")
