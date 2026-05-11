//! expect-stdout: ok

type Pair {
    x: i32,
    y: i32,
}

type Container {
    items: [Pair; 4],
}

type PairView {
    tokens: *const Pair,
    index: i32,
}

type ForwardView {
    tokens: *const ForwardToken,
    index: i32,
}

type ForwardToken {
    kind: i32,
    value: i32,
}

type PairDocument {
    tokens: [Pair; 4],
}

fn read_field(ptr: *const Pair) -> i32:
    unsafe: (*ptr).x

fn read_offset(ptr: *const Pair, idx: i64) -> i32:
    unsafe: (*(ptr + idx as u64)).y

fn PairView.read_x(self: PairView) -> i32:
    unsafe: (*(self.tokens + self.index as u64)).x

fn ForwardView.read_kind(self: ForwardView) -> i32:
    unsafe: (*(self.tokens + self.index as u64)).kind

fn get_element_field(arr: *const Pair, idx: i64) -> i32:
    unsafe: (*(arr + idx as u64)).x

fn get_from_container(c: &Container) -> i32:
    let ptr = &raw const c.items[0] as *const Pair
    unsafe: (*(ptr + 1 as u64)).y

fn PairDocument.first_ptr(self: &PairDocument) -> *const Pair:
    &raw const self.tokens[0] as *const Pair

fn main:
    var p = Pair { x: 10, y: 20 }
    let ptr = &raw const p as *const Pair
    assert(read_field(ptr) == 10)
    assert(read_offset(ptr, 0) == 20)

    var container = Container {
        items: [
            Pair { x: 1, y: 2 },
            Pair { x: 3, y: 4 },
            Pair { x: 5, y: 6 },
            Pair { x: 7, y: 8 },
        ],
    }
    assert(get_element_field(&raw const container.items[0] as *const Pair, 2) == 5)
    assert(get_from_container(&container) == 4)
    let view = PairView { tokens: &raw const container.items[0] as *const Pair, index: 2 }
    assert(view.read_x() == 5)
    let doc = PairDocument {
        tokens: [
            Pair { x: 11, y: 12 },
            Pair { x: 13, y: 14 },
            Pair { x: 15, y: 16 },
            Pair { x: 17, y: 18 },
        ],
    }
    let doc_ptr = doc.first_ptr()
    assert(unsafe: (*(doc_ptr + 1 as u64)).y == 14)
    let tokens = [
        ForwardToken { kind: 21, value: 1 },
        ForwardToken { kind: 22, value: 2 },
    ]
    let fwd = ForwardView { tokens: &raw const tokens[0] as *const ForwardToken, index: 1 }
    assert(fwd.read_kind() == 22)
    print("ok")
