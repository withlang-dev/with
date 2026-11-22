//! expect-exit: 134
//! expect-stderr: lib_name: 'freed by lib_free', but lib_free is NULL

// §31.8.6: the generated code never calls a null pointer. Before each call
// through a function-pointer global it tests the pointer it read; NULL is a
// contract failure naming the clause and the global.
use c_import("void *malloc(unsigned long n);
typedef void (*free_fn)(void *p);
static free_fn lib_free = 0;
static inline char *lib_name(void) { char *s = malloc(4); s[0] = 'a'; s[1] = 'b'; s[2] = 0; return s; }
")

c contract lib:
    fn lib_name
        text return, owned, freed by lib_free

fn main:
    let n = lib_name()
    print("unreachable")
