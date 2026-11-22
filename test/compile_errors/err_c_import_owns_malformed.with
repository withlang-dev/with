//! expect-check-fail: owns: "getcwd" is not 'ctor -> dtor'

// D51 stage 4c: `owns:` is a deprecated spelling of a facade resource; an
// entry that spells no resource is an error, never silently nothing.

use c_import("char *getcwd(char *buf, unsigned long size);
void free(void *p);
", owns: ["getcwd"])

fn main:
    print("unreachable")
