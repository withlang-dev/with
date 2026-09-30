//! expect-stdout: hi from C compiled and linked by `with cc`

/* #1915 (:no-host-toolchain): `with cc` compiles and links a C program with
 * the compiler's own clang, lld and sysroot, no host toolchain in reach. */
#include <stdio.h>
#include <math.h>

int main(void) {
    printf("hi from C compiled and linked by `with cc`\n");
    return (int)sqrt(0.0);
}
