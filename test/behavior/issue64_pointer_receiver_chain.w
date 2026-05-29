//! expect-stdout: ok

type Inner {
    tags: Vec[i32],
}

unsafe fn push_via_vec_ptr(items: *mut Vec[Inner]):
    (*items).get(0).tags.push(9)

unsafe fn push_via_inner_ptr(item: *mut Inner):
    (*item).tags.push(10)

fn main:
    var items: Vec[Inner] = Vec.new()
    items.push(Inner { tags: Vec.new() })
    unsafe { push_via_vec_ptr((&raw mut items) as *mut Vec[Inner]) }

    var inner = Inner { tags: Vec.new() }
    unsafe { push_via_inner_ptr((&raw mut inner) as *mut Inner) }

    print("ok")
