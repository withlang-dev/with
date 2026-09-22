//! only-on: darwin
//! expect-stdout: strdup live 1 freed 1
//! expect-stdout: strndup live 1 freed 1
//! expect-stdout: ok

// D51 §16.2b / ruling §5: the toolchain libc facade's `CHeapStr` Drop frees
// what strdup/strndup allocated, exactly once. libc memory is outside the
// With debug allocator, so the witness is the system allocator itself:
// Darwin's `malloc_size` is non-zero for a live block and zero once it is
// freed (and a second free aborts the process).

use c_import("char *strdup(const char *s);
char *strndup(const char *s, unsigned long n);
void free(void *p);
unsigned long malloc_size(const void *ptr);
")

fn size(p: *const c_void) -> u64: unsafe { malloc_size(p) }

fn main:
    let a = CHeapStr.strdup("hello").unwrap()
    let pa = a.repr as *const c_void
    let la = if size(pa) > 0: 1 else: 0
    drop(a)
    print(f"strdup live {la} freed {if size(pa) == 0: 1 else: 0}")
    let b = CHeapStr.strndup("hello", 2).unwrap()
    let pb = b.repr as *const c_void
    let lb = if size(pb) > 0: 1 else: 0
    drop(b)
    print(f"strndup live {lb} freed {if size(pb) == 0: 1 else: 0}")
    print("ok")
