//! expect-debug-alloc: leak count=0
//! expect-stdout: 2
//! expect-stdout: true
//! expect-stdout: b
//! expect-stdout: 1
//! expect-stdout: 2

// #2180 (§11.7, D96): a key that is not its bytes — a tuple, a struct
// holding a str, an Option — is hashed and compared by its parts, so two
// equal keys are one entry. The C backend refused every such key.
use std.collections.HashMap
use std.collections.HashSet

@[derive(Eq)]
type Named:
    id: i32
    name: str

fn main:
    var grid: HashMap[(i32, i32), str] = HashMap.new()
    grid.insert((1, 2), "a")
    grid.insert((3, 4), "b")
    grid.insert((1, 2), "c")
    print(grid.len())
    print(grid.contains((3, 4)))
    print(grid.get((3, 4)).unwrap())
    var names: HashSet[Named] = HashSet.new()
    names.insert(Named { id: 1, name: "x".to_lower() })
    names.insert(Named { id: 1, name: "X".to_lower() })
    print(names.len())
    var opt: HashSet[Option[str]] = HashSet.new()
    opt.insert(Some("q" ++ ""))
    opt.insert(Some("q" ++ ""))
    opt.insert(None)
    print(opt.len())
