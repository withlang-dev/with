//! expect-stdout: as_mut_ptr 10 99
//! expect-stdout: raw_mut_elem 2 77
//! expect-stdout: mut_slice 4 6 44 88
//! expect-stdout: subfield 1 42
//! expect-stdout: generic 3 3 2 1

// D120 stage 5 (§2.3): C boundary / mutable pointer and slice uniqueness
// (as_mut_ptr, &raw mut xs[i], []mut T coercion and slice), subfield
// mutation through an index, and per-instantiation generic copy/move.

type Pair {
    x: i64,
    y: i64,
}

resource type ResHandle {
    id: i64,
}

type Holder {
    items: List[i64],
}

impl Holder:
    mut fn add(v: i64):
        self.items.push(v)

fn push_param(xs: List[i64], v: i64) -> List[i64]:
    xs.push(v)
    xs

fn fill_mut_slice(buf: []mut i64, idx: isize, val: i64):
    buf[idx] = val

fn list_count[T](xs: List[T]) -> isize:
    xs.len()

fn main:
    let a1 = [10, 20, 30]
    var b1 = a1
    let ptr = b1.as_mut_ptr()
    unsafe:
        *ptr = 99
    print(f"as_mut_ptr {a1[0]} {b1[0]}")

    let a2 = [1, 2, 3]
    var b2 = a2
    unsafe:
        let elem_ptr = &raw mut b2[1]
        *elem_ptr = 77
    print(f"raw_mut_elem {a2[1]} {b2[1]}")

    let a3 = [4, 5, 6]
    var b3 = a3
    fill_mut_slice(b3, 2, 88)
    fill_mut_slice(b3, 0, 44)
    print(f"mut_slice {a3[0]} {a3[2]} {b3[0]} {b3[2]}")

    let p1 = [Pair { x: 1, y: 2 }]
    var p2 = p1
    p2[0].x = 42
    print(f"subfield {p1[0].x} {p2[0].x}")

    let nums = [10, 20, 30]
    let n1 = list_count(nums)
    let n2 = list_count(nums)
    let words = ["hello", "world"]
    let w1 = list_count(words)
    assert(words[0] == "hello")
    var handles: List[ResHandle] = List.new()
    handles.push(ResHandle { id: 7 })
    let h1 = list_count(handles)
    var h_box = Holder { items: [5, 6] }
    let h_copy = h_box
    h_box.add(7)
    h_box.items = push_param(h_box.items, 8)
    assert(h_copy.items.len() == 2 and h_box.items.len() == 4)
    print(f"generic {n1} {n2} {w1} {h1}")
