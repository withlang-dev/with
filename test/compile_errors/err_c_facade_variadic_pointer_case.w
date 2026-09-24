//! expect-check-fail: fn 'ulimit': 'case UL_SETFSIZE: *mut i64' — a case states an integer C type ('c_long', 'curl_off_t', an enum) or 'str' (a copied input string, §16.3c); a pointer the callee keeps needs its retention stated, and a callback its userdata pairing — neither is modeled yet (#1652) (§16.2b.5)

// D66 (spec §16.2b.5): a case states the presented type AND contract of
// the variadic argument; a bare pointer states no contract, and the two
// pointer contracts (retention, a callback with its userdata) are #1652.
use c_import("long ulimit(int cmd, ...);\n#define UL_GETFSIZE 1\n#define UL_SETFSIZE 2\n")

c facade limits:
    fn ulimit
        variadic param 1 selected by param cmd:
            case UL_SETFSIZE: *mut c_long

fn main:
    print("unreached")
