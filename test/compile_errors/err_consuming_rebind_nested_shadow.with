//! expect-check-fail: shadowing is not allowed for 'item'

type Resource { value: i32 }
impl Resource:
    fn drop(move self: Self): ()

fn consume(resource: Resource) -> i32:
    resource.value

fn main:
    let item = Resource { value: 41 }
    if true:
        let item = consume(item)
        print(f"{item}")
