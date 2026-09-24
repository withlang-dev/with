//! expect-stdout: set: true
//! expect-stdout: read back: true
//! expect-stdout: ok
//! skip-on: windows issue #800: action/capability/net/process/fs OS-surface fails on native Windows

// D66 (spec §16.2b.5): a discriminated variadic contract on a free
// operation. `ulimit(int cmd, ...)` stays variadic all the way to the C
// call; the facade closes the type hole for `UL_SETFSIZE`, whose variadic
// argument is a `long`, so `ulimit(UL_SETFSIZE, n)` is a safe presented
// call that passes `n` as a C long on the variadic ABI (Apple arm64 puts
// it on the stack; a fixed-arity redeclaration would put it in a register
// and set a garbage limit). `UL_GETFSIZE` is not listed, so it is still
// the raw call under `unsafe` — the value it reads back is the proof the
// long crossed intact.

use c_import("long ulimit(int cmd, ...);\n#define UL_GETFSIZE 1\n#define UL_SETFSIZE 2\n")

c facade limits:
    fn ulimit
        variadic param 1 selected by param cmd:
            case UL_SETFSIZE: c_long

fn main:
    let current = unsafe { ulimit(UL_GETFSIZE) }
    let set = ulimit(UL_SETFSIZE, current)
    print(f"set: {set == current}")
    let again = unsafe { ulimit(UL_GETFSIZE) }
    print(f"read back: {again == current}")
    print("ok")
