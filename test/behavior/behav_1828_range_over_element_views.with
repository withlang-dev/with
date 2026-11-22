//! expect-stdout: 1 2
//! expect-stdout: 5000000000 5000000001
//! expect-stdout: 5000000000 5000000001 true

// #1828: a range whose bounds are element views (`xs[a]..xs[b]`, D27)
// ranges over the pointee type. Sema never recorded the range's type, MIR
// rebuilt it from the `&i32` bounds, found no such range and answered void:
// a bound range was invalid MIR, and a loop's counter was typed only by the
// `i32` for-element fallback #1828 removed — `i32` for an i64 range too.

type Keys:
    starts: List[i32]
    wide: List[i64]

fn walk(keys: &Keys, base: i32):
    var out = ""
    for i in keys.starts[base]..keys.starts[base + 1]:
        out = out ++ f"{i} "
    print(out.trim())
    var wide = ""
    for w in keys.wide[0]..keys.wide[1]:
        wide = wide ++ f"{w} "
    print(wide.trim())
    let r = keys.wide[0]..keys.wide[1]
    var bound = ""
    for w in r:
        bound = bound ++ f"{w} "
    print(f"{bound}{5000000001 in keys.wide[0]..keys.wide[1]}")

fn main:
    var starts: List[i32] = List.new()
    starts.push(1)
    starts.push(3)
    var wide: List[i64] = List.new()
    wide.push(5000000000)
    wide.push(5000000002)
    walk(&Keys { starts, wide }, 0)
