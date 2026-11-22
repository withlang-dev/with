//! expect-stdout: 9 3 4 3
//! expect-stdout: 7

// D144: an unannotated binding of a view of plain bits takes the value,
// wherever the view came from: a map lookup's payload, a `&i32` parameter,
// an iterator's next item. Each is read, then the receiver is written, and
// the binding is still the value it was. A written `&x` keeps the view.
use std.collections.HashMap

type S { m: HashMap[i32, i32], xs: List[i32], n: i32 }
impl S:
    mut fn bump(): self.n += 1
    mut fn from_map() -> i32:
        let x = self.m.get(1).unwrap()
        self.bump()
        x
    mut fn from_param(p: &i32) -> i32:
        let y = p
        self.bump()
        y
    mut fn from_iter() -> i32:
        var cursor = self.xs.iter()
        let z = cursor.next().unwrap()
        self.bump()
        z

fn main:
    var s = S { m: HashMap.new(), xs: [4, 5], n: 0 }
    s.m.insert(1, 9)
    let k = 3
    print(f"{s.from_map()} {s.from_param(k)} {s.from_iter()} {s.n}")
    var a = 7
    let view = &a
    print(f"{view}")
