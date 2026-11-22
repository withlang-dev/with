//! expect-check-fail: a parent borrow hands out a modeled resource
//! expect-check-fail: = help: declare 'row' as a resource, or write 'returns borrow row from param N' for a view of an imported record

// #3129 (§16.2b.6): 'from parent' names the resource a child resource
// borrows; an imported record is no resource.
use c_import("typedef struct h h;
h *h_new(void);
void h_free(h *x);
typedef struct row { int a; } row;
const char *h_two(int a, int b);
row *h_row(int k);
const char *h_msg(int code);
int h_fail(int x);
int h_of(int x);
#define H_OK 0
")

c contract lib:
    resource Handle wraps *mut h
        from h_new
        drop h_free
    fn h_row
        returns borrow row from parent Handle of param k

fn main:
    print("unreachable")
