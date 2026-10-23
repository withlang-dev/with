//! expect-stdout: 7 -1

// #2325 (D43, D22): a function with no return annotation that returns a
// Copy view from one path (`x` of `for x in xs`, an `&i32`) and a value
// from another (`-1`) returns the value: the view materializes its i32.
// The join reported "mismatched return types" between &i32 and i32.
fn find(xs: &List[i32], want: i32):
    for x in xs:
        if x == want: return x
    return -1

fn main:
    let xs: List[i32] = [3, 7]
    print(f"{find(&xs, 7)} {find(&xs, 9)}")
