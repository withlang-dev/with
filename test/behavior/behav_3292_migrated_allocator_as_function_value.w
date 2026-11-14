//! expect-stdout: ok
// #3292: under `with migrate` a call of malloc, calloc, realloc or free is
// rewritten to the runtime's allocator; one of them named as a function
// value was left as libc's name, which the migrated file does not declare,
// so the output did not check. The value now names a function with C's
// signature over the runtime's allocator: memory from a rewritten `malloc`
// released through a `free` handed to a callee goes back to the allocator
// that made it.
use std.fs
use pre_d_build_runner

fn main:
    let root = p7_prepare_case("migrated_allocator_as_function_value", "allocvalue")
    p7_write(root, "values.c",
        "#include <stdlib.h>\n#include <stdio.h>\n" ++
        "typedef void *(*alloc_fn)(size_t);\ntypedef void *(*zero_fn)(size_t, size_t);\ntypedef void *(*grow_fn)(void *, size_t);\ntypedef void (*free_fn)(void *);\n" ++
        "static char *make(alloc_fn a) { char *s = a(4); s[0] = 'a'; s[1] = 0; return s; }\n" ++
        "static int *zeros(zero_fn z) { return z(8, sizeof(int)); }\n" ++
        "static char *grow(grow_fn g, char *s) { s = g(s, 4096); s[1] = 'b'; s[2] = 0; return s; }\n" ++
        "static void release(free_fn f, void *p) { f(p); }\n" ++
        "int main(void) {\n    char *s = make(malloc);\n    int *z = zeros(calloc);\n    s = grow(realloc, s);\n    printf(\"%s %d\\n\", s, z[7]);\n    release(free, s);\n    release(free, z);\n    char *t = malloc(16);\n    release(free, t);\n    return 0;\n}\n")
    let migrated = p7_run(root, "migrate", p7_argv_append(p7_argv_append(p7_argv_append(p7_argv_append("", "migrate"), "values.c"), "-o"), "values.w"))
    p7_assert_success(migrated, "with migrate values.c")
    let ran = p7_run(root, "run", p7_argv_append(p7_argv_append("", "run"), "values.w"))
    p7_assert_success(ran, "the migrated program")
    assert(ran.stdout.contains("ab 0"))
    print("ok")
