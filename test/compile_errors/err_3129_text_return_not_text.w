//! expect-check-fail: not a pointer to a C character type; 'text return' describes new text C hands back
//! expect-check-fail: = help: delete 'text return': it applies to a function returning 'char *'; a returned record or resource has its own clause ('returns borrow …', or a resource's 'from')

// #3129 (§16.2b.8): 'text return' describes text; an int pointer is none.
use c_import("int *make_ints(void);\nvoid free_text(char *p);\ntypedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nint h_use(h *x);\n")

c contract lib:
    fn make_ints
        text return, owned, freed by free_text

fn main:
    print("unreachable")
