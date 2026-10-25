//! expect-debug-alloc: leak count=0
//! expect-stdout: sum 6
//! expect-stdout: names a,b,c
//! expect-stdout: ok

// #2561: `match move self.list` vacates the field, and each arm stores it
// again (`self.list = rest`). The vacate's reset ran at the end of the match
// statement, after the arm's store, and blanked the field: the cursor
// yielded its first element only and leaked the rest of the list.

type Cursor[T] { list: List[T] }

impl[T] Cursor[T]:
    mut fn next() -> Option[T]:
        match move self.list:
            [h, ..rest] =>
                self.list = rest
                Some(h)
            [] =>
                self.list = []
                None

fn main:
    var ints = Cursor { list: [1, 2, 3] }
    var sum = 0
    while true:
        match ints.next():
            Some(n) => sum += n
            None => break
    print(f"sum {sum}")
    var names = Cursor { list: ["a", "b", "c"] }
    var seen = ""
    while true:
        match names.next():
            Some(s) => seen = if seen.len() == 0: s else: seen ++ "," ++ s
            None => break
    print(f"names {seen}")
    print("ok")
