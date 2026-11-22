//! expect-check-stdout: ok

// #1417: a C comparison or logical operator yields an int. A predicate macro
// whose operands are not constants (here an extern variable, as
// winapifamily.h's WINAPI_PARTITION_* are when its family is not folded)
// imported as `let IS_ON: c_int = (g_mode == 1)` — a bool value in a c_int
// binding, "type mismatch in binding". The value follows the C type:
// `((g_mode == 1) as c_int)`. (A constant one folds to 0 or 1.)

use c_import("extern int g_mode;\n#define IS_ON (g_mode == 1)\n#define IS_OFF (!(g_mode == 1))\n")

fn main:
    let on: c_int = IS_ON
    let off: c_int = IS_OFF
    print(f"{on + off}")
