//! expect-stdout: 3 6 1 3

// #2533: a generic function that calls itself. The instance is being
// checked when its body meets the recursive call, so the call takes the
// declared return type and binds to the instance's signature instead of
// checking the body again (the re-check overflowed the compiler's stack).
fn depth[T](xs: List[T], i: isize) -> isize:
    if i >= xs.len(): 0 else: 1 + depth(xs, i + 1)

fn total[T](xs: List[T], i: isize, acc: T) -> T:
    if i >= xs.len(): return acc
    total(xs, i + 1, acc + xs[i])

// Two instances in flight at once: each recursion is its own key.
fn depth_pair[T, U](xs: List[T], ys: List[U], i: isize) -> isize:
    if i >= xs.len() or i >= ys.len(): 0 else: 1 + depth_pair(xs, ys, i + 1)

fn main:
    let xs: List[i32] = [1, 2, 3]
    let names: List[str] = ["a", "b", "c", "d"]
    print(f"{depth(xs, 0)} {total(xs, 0, 0)} {depth_pair(names, [true], 0)} {depth_pair(xs, names, 0)}")
