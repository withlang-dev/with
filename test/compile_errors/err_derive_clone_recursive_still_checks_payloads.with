//! expect-check-fail: cannot derive Clone for type 'Value': variant 'File' payload of type 'Handle' does not implement Clone
// A derive's assumption that its own type is Clone closes a recursive
// payload (`List[Value]`), and masks nothing else: a payload that is not
// Clone is still refused.
type Handle { fd: i32 }
impl Drop for Handle:
    move fn drop(): {}

@[derive(Clone)]
enum Value:
    Arr(items: List[Value])
    File(h: Handle)

fn main:
    print("x")
