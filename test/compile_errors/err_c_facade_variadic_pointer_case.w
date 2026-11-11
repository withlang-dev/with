//! expect-check-fail: fn 'ulimit': 'case UL_SETFSIZE: *mut c_long' — a case states an integer C type ('c_long', 'curl_off_t', an enum) or 'str' (a copied input string, §16.3c); a pointer the callee keeps states its retention ('&CString retains by param N', D194), and a callback its userdata pairing

// D66 (spec §16.2b.5): a case states the presented type AND contract of
// the variadic argument; a bare pointer states no contract, and the two
// pointer contracts (retention, a callback with its userdata) are #1652.
use c_import("long ulimit(int cmd, ...);\n#define UL_GETFSIZE 1\n#define UL_SETFSIZE 2\n")

c contract limits:
    fn ulimit
        variadic param 1 selected by param cmd:
            case UL_SETFSIZE: *mut c_long

fn main:
    print("unreached")
