//! expect-check-fail: 'text return' is stated twice
//! expect-check-fail: = help: delete one of the two 'text return' clauses

// #3129 (§16.2b.8): one function has one `text return`.
use c_import("char *make_text(void);\nvoid free_text(char *p);\n")

c contract texts:
    fn make_text
        text return, owned, freed by free_text
        text return, owned, freed by free_text

fn main:
    print("unreachable")
