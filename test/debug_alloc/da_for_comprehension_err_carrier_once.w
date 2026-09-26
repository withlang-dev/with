//! expect-debug-alloc: leak count=0
//! expect-stdout: negative -1 with a tail long enough to live on the heap for sure

// #1504: the for-comprehension's failure arm (`___fail @ _ => ___fail`) hands
// the Err carrier to the result once; the wildcard under an @-binding
// discards nothing (the outer binding owns the value).
fn get_result(x: i32) -> Result[i32, str]:
    if x > 0: Ok(x) else: Err(f"negative {x} with a tail long enough to live on the heap for sure")

fn main:
    let r: Result[i32, str] = for x in get_result(5); y in get_result(-1):
        yield x + y
    match r:
        Ok(_) => assert(false)
        Err(e) => print(e)
