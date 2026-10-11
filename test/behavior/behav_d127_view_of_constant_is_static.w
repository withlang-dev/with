//! expect-stdout: -1 7 -1

// D127 (§3.1): a view of a constant is a view of an immutable static at the
// demanded type, alive for the whole program, so it may be returned; it
// never points into the frame of the function that wrote it. `clobber`
// overwrites the stack between taking the views and reading them.
fn fallback() -> &i32: &-1

fn pick(o: Option[&i32]) -> &i32: o ?? &-1

fn clobber(depth: i32) -> i32:
    var junk: [i32; 64] = [99; 64]
    for i in 0i32..64: junk[i] = depth * 1000 + i
    if depth > 0: clobber(depth - 1) + junk[3] else: junk[5]

fn main:
    let seven: i32 = 7
    let first = fallback()
    let second = pick(Some(&seven))
    let third = pick(None)
    let noise = clobber(4)
    print(f"{*first} {*second} {*third}")
    if noise == 0: print("unreachable")
