//! expect-stdout: closed 1
//! expect-stdout: ok

// D51 §16.2b.13: "the producer's return matches" and "the destroyer accepts
// the representation" compare types through `type` aliases, pointees
// included. A header's `typedef struct __handle Handle` translates the
// functions over `*mut __handle` while the facade names `*mut Handle` (as
// libc's `DIR *` is `*mut __dirstream`); both are the same representation.

use c_import("void *calloc(unsigned long count, unsigned long size);
typedef struct __handle { int closed; } Handle;
static inline Handle* handle_open(void) { return (Handle*)calloc(1, sizeof(Handle)); }
static inline void handle_close(Handle* h) { h->closed++; }
static inline int handle_closed(Handle* h) { return h->closed; }
")

c facade h:
    resource Owned wraps *mut Handle
        from handle_open
        drop handle_close

fn main:
    let o = Owned.open().unwrap()
    let p = o.repr
    drop(o)
    unsafe { print(f"closed {handle_closed(p)}") }
    print("ok")
