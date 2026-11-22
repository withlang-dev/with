//! expect-check-fail: a retained byte case sets its length option and then its pointer as one operation, so 'h_set' states 'ok CONST'
//! expect-check-fail: = help: add 'ok <CONST>' under 'fn h_set', naming the status the library returns on success

// #3129 (§16.2b.5): the pointer is set only when the length took, so the
// operation needs the status that says it did.
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
    fn h_set
        rename set
        lend
        variadic param 2 selected by param opt:
            case OPT_DATA: &str retains by param 0 length param OPT_SIZE as c_long

fn main:
    print("unreachable")
