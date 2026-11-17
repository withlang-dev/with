//! expect-check-fail: not a pointer to a C character type; 'text return' describes new text C hands back
//! expect-check-fail: = help: delete 'text return': it applies to a function returning 'char *'

// #3129 (§16.2b.8): `text return` describes a returned character pointer.
use c_import("int make_number(void);\nvoid free_text(char *p);\n")

c contract texts:
    fn make_number
        text return, owned, freed by free_text

fn main:
    print("unreachable")
