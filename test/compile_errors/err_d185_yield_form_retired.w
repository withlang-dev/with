//! expect-error: the `for x in a; y in b: yield e` expression form is retired
// §13.6a (D185, Law 9): one comprehension family; the yield form was a second spelling.
fn a() -> Option[i32]: Some(1)
fn b() -> Option[i32]: Some(2)
fn main:
    let r = for x in a(); y in b(): yield x + y
    print(f"{r:?}")
