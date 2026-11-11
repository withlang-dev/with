//! expect-check-fail: 'returns borrow Part' borrows a resource that states no producer and no 'drop'
// #3114: a resource with neither a producer nor a `drop` renders nothing;
// an item that hands out a borrow of it generated code naming an undefined
// `BorrowedPart`. The facade is refused at the item, by name.
use c_import("typedef struct mime mime; typedef struct part part;
mime *mime_new(void);
void mime_free(mime *m);
part *mime_addpart(mime *m);
")

c contract mimes:
    resource Mime wraps *mut mime
        from mime_new
        drop mime_free
    resource Part wraps *mut part
    fn mime_addpart
        rename add_part
        returns borrow Part from param 0

fn main:
    print("ok")
