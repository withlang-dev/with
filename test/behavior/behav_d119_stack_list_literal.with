//! expect-stdout: 10
//! expect-stdout: n0n1n2
//! expect-stdout: 3
//! expect-stdout: 6
//! expect-stdout: 4
//! expect-stdout: 7
//! expect-stdout: 9
//! expect-stdout: 0
//! expect-stdout: 6
//! expect-stdout: 5
//! expect-stdout: 2
//! expect-stdout: 8
//! expect-stdout: 3
//! expect-stdout: 9
//! expect-stdout: p0p1p2p3
//! expect-stdout: q3
//! expect-stdout: true
//! expect-stdout: 7

// §4.3c (D119): a List literal that is never pushed, grown, moved out,
// stored or retained does not touch the heap. Each shape here either keeps
// its elements in the frame or escapes and becomes an ordinary List; the
// program cannot tell which, and the debug allocator sees no leak or double
// free either way.

type Holder { xs: List[i32] }

fn total(xs: &List[i32]):
    var sum = 0
    for x in xs: sum = sum + x
    sum

fn made() -> List[i32]: [1, 2, 3]

fn kept():
    let held = [4, 5]
    Holder { xs: held }

fn main:
    // Read in place, by index, by a `&` parameter and by iteration.
    let t = [1, 2, 3, 4]
    print(f"{t[0] + t[1] + t[2] + t[3]}")
    // Owned elements made at run time: dropped with the frame's literal.
    let names = [f"n{0}", f"n{1}", f"n{2}"]
    print(f"{names[0]}{names[1]}{names[2]}")
    print(f"{t.len() - 1}")
    // Returned: the literal leaves its frame.
    print(f"{total(made())}")
    // Grown.
    var grown = [1, 2]
    grown.push(1)
    print(f"{grown.len() + 1}")
    // Stored in a struct.
    let h = kept()
    print(f"{h.xs[0] + 3}")
    // An element written in place.
    var w = [0, 0]
    w[1] = 9
    print(f"{w[1]}")
    // Cleared.
    var c = [1, 2, 3]
    c.clear()
    print(f"{c.len()}")
    // Moved into another binding.
    let u: List[i32] = [1, 2, 3]
    let v = u
    print(f"{total(&v)}")
    // A temporary handed to a `&` parameter.
    print(f"{total([2, 3]) }")
    // Chosen by a branch.
    let pick = if t.len() > 3: [2] else: [3, 4]
    print(f"{pick[0]}")
    // Iterated.
    var seen = 0
    for x in [3, 5]: seen = seen + x
    print(f"{seen}")
    print(f"{total(&t) - 7}")
    print(f"{t[2] * 3}")
    // One call site run again while the last run's value is still held:
    // read before the reassignment, and only dropped by it.
    var prev = [f"p{0}"]
    var trail = ""
    for i in 1..4:
        let cur = [f"p{i}"]
        trail = trail ++ prev[0]
        prev = cur
    print(trail ++ prev[0])
    var last = [f"q{0}"]
    for i in 1..4:
        let cur = [f"q{i}"]
        last = cur
    print(last[0])
    // Its capacity covers its elements.
    print(f"{t.capacity() >= t.len()}")
    // The buffer's address handed out (for a C call): written through, so
    // the constants stay in the frame rather than in read-only data.
    let raw = [1, 2]
    unsafe { *raw.as_mut_ptr() = 7 }
    print(f"{raw[0]}")
