//! expect-check-fail: view `view` borrows from `owner`, which `touch` may have invalidated

// The same index projection applies to the original byte buffer spelling.
use c_import("#include <stdlib.h>
typedef struct Value { int n; } Value;
typedef struct Handle { Value value; } Handle;
static inline Handle *make(void) { Handle *h = malloc(sizeof(Handle)); h->value.n = 1; return h; }
static inline void close_handle(Handle *h) { free(h); }
static inline const Value *observe(Handle *h) { return &h->value; }
static inline int touch(const unsigned char *values, int count, Handle *h) { h->value.n = count; return count; }
")
c facade values:
    resource Owner wraps *mut Handle
        from make
        drop close_handle
    fn observe
        returns borrow Value from param 0
    fn touch
        buffer param values len param count
fn main:
    let owner = Owner.make().unwrap()
    let view = owner.observe().unwrap()
    let values: [u8; 1] = [1]
    touch(values, owner)
    print(f"{view.n}")
