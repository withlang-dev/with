//! expect-stdout: 1 2 3 5 8 9 | apple fig kiwi pear | 0 | 7

// Vec.sort sorts orderable elements in place (heapsort; elements move by
// swap, never by copy, §2.3). A str element owns its buffer: a copy would
// double-free it, which the debug allocator run of this test would report.
fn main:
    var nums: Vec[i32] = [5, 3, 9, 1, 8, 2]
    nums.sort()
    var words: Vec[str] = [f"pe{"ar"}", f"ap{"ple"}", f"ki{"wi"}", f"f{"ig"}"]
    words.sort()
    var empty: Vec[i32] = []
    empty.sort()
    var one: Vec[i32] = [7]
    one.sort()
    let texts: Vec[str] = nums.iter() |> map(f"{it}") |> collect[Vec]()
    print(texts.join(" ") ++ " | " ++ words.join(" ") ++ f" | {empty.len()} | {one[0]}")
