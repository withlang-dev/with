//! expect-check-fail: fn 'zdoc_read': text param 0: *const i32 words: not a pointer to a C character type; 'text param' describes a `char *`, `unsigned char *` or `signed char *` input (§16.2b.8)

// D122 (spec §16.2b.8): `text param N` describes input text, a pointer to
// a C character type read to its NUL; any other pointer is a buffer or a
// handle, and the clause is refused rather than reinterpreted.
use c_import("#include <stdlib.h>
typedef struct zdoc { int n; } zdoc;
static inline zdoc *zdoc_read(const int *words) { zdoc *d = (zdoc *)malloc(sizeof(zdoc)); d->n = words[0]; return d; }
static inline void zdoc_free(zdoc *d) { free(d); }
")

c facade z:
    resource Document wraps *mut zdoc
        from zdoc_read
        drop zdoc_free
    fn zdoc_read
        text param 0

fn main:
    print("unreachable")
