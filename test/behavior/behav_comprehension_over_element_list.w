//! expect-stdout: 2
//! expect-stdout: 3
//! expect-stdout: 2
//! expect-stdout: 3

// A comprehension over an element of a `List[List[T]]` — a local's element
// or a field's, read through `fn` or `mut fn` — iterates the element as a
// `for` does. The element place was lowered with a deref projection (Sema
// types the element access as a view; the place is the element itself),
// which the MIR validator refused before codegen.
type Places { refs: List[List[i32]] }

impl Places:
    fn total(source: i32): [t for t in self.refs[source]].len()

    mut fn borrow(dest: i32, source: i32):
        self.refs[dest] = [t for t in self.refs[source]]

fn main:
    let refs = [[1, 2], [3]]
    print([t for t in refs[0]].len())
    let p = Places { refs: [[1, 2, 3], [4]] }
    print(p.total(0))
    p.borrow(1, 0)
    print(p.refs[1].len() - 1)
    print([[t * 2 for t in row] for row in p.refs][0].len())
