//! expect-stdout: 3 6
//! expect-stdout: ab|cd|
//! expect-stdout: 3
//! expect-stdout: 1
// §13 (D27): `for d in deps[k]` iterates the inner list the element place
// denotes. The loop dereferenced the element's place because its type is a
// view (`&List[i32]`), reading the header's buffer pointer as a List: the
// inner lists iterated as empty (`0` printed for `3`), or the program
// crashed. A view-typed binding still reads through its one deref.
use std.collections.HashMap

fn main:
    var deps: List[List[i32]] = List.new()
    for k in 0..3:
        var mine: List[i32] = List.new()
        for j in 0..k + 1: mine.push(j as i32)
        deps.push(mine)
    var total = 0
    for k in 0..deps.len():
        for d in deps[k]:
            total = total + d
    var count = 0
    for k in 0..deps.len():
        for _ in deps[k]: count = count + 1
    print(f"{total - 1} {count}")
    var words: List[List[str]] = List.new()
    var w: List[str] = List.new()
    w.push("ab")
    w.push("cd")
    words.push(w)
    var line = ""
    for s in words[0]: line = line ++ s ++ "|"
    print(line)
    for row in deps:
        if row.len() == 3:
            var n = 0
            for _ in row: n = n + 1
            print(f"{n}")
    var maps: List[HashMap[str, i32]] = List.new()
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("one", 1)
    maps.push(m)
    for (k, v) in maps[0]: print(f"{v}")
