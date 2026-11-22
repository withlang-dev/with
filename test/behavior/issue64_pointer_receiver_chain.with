//! expect-stdout: ok

type Inner {
    tags: List[i32],
}

unsafe fn push_via_list_ptr(items: *mut List[Inner]):
    (*items)[0].tags.push(9)

unsafe fn push_via_inner_ptr(item: *mut Inner):
    (*item).tags.push(10)

fn main:
    var items: List[Inner] = List.new()
    items.push(Inner { tags: List.new() })
    unsafe { push_via_list_ptr((&raw mut items) as *mut List[Inner]) }

    var inner = Inner { tags: List.new() }
    unsafe { push_via_inner_ptr((&raw mut inner) as *mut Inner) }

    print("ok")
