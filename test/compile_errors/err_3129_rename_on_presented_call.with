//! expect-check-fail: 'rename' would need a second declaration, which a presented call does not get
//! expect-check-fail: = help: delete the 'rename' line: the function is called by its C name

// #3129 (§16.2b.8): a text return on a free function is presented at its
// call sites, under the C name.
use c_import("typedef struct h h;
typedef int (*h_cb)(char *p, unsigned long n, void *ud);
h *h_new(void);
void h_free(h *x);
int h_set(h *x, int opt, ...);
const char *h_name(void);
#define OPT_DATA 1
#define OPT_SIZE 2
#define OPT_CB 3
#define OPT_F 1.5
#define H_OK 0
")

c contract lib:
    resource Handle wraps *mut h
        from h_new
        drop h_free
    fn h_name
        returns static CStr
        rename name

fn main:
    print("unreachable")
