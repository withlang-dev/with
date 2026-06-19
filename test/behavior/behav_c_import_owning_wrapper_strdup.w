//! expect-stdout: ok

// #357: a curated owning constructor (strdup returns an owned char* released by
// free) is generated as an owning-wrapper type COwned_strdup whose Drop calls
// free exactly once. The safe constructor returns the wrapper; `.handle()`
// borrows the raw pointer. When `owned` leaves scope, free runs automatically.

use c_import("static inline const char *clit(void) { return \"hello\"; }\nchar *strdup(const char *s);\n")

fn main:
    unsafe:
        let src = clit()
        let owned = strdup(src)
        let h = owned.handle()
        if h == null:
            print("bad")
        else:
            print("ok")
