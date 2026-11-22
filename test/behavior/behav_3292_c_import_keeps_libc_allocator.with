//! expect-stdout: 3
// #3292: code translated from an imported header calls the functions the
// header names. The translator rewrote calls of malloc, calloc, realloc and
// free to the runtime's allocator and left `free` named as a value libc's, so
// an allocation in a header's inline function went to one allocator and its
// release through a function value to the other.
use c_import("void *malloc(unsigned long n);
void *calloc(unsigned long n, unsigned long size);
void *realloc(void *p, unsigned long n);
void free(void *p);
typedef void (*free_fn)(void *p);
static free_fn lib_free = free;
static inline int lib_grown(void) {
    char *s = malloc(2);
    int *z = calloc(4, sizeof(int));
    s[0] = 'a'; s[1] = 0;
    s = realloc(s, 64);
    s[1] = 'b'; s[2] = 'c'; s[3] = 0;
    int n = z[3];
    while (s[n]) n++;
    lib_free(s);
    lib_free(z);
    return n;
}
")

fn main:
    print(unsafe { lib_grown() })
