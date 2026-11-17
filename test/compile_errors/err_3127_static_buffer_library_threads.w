//! expect-check-fail: E0921: call of `lib_version` may race: it returns a view of `lib`, state the call itself rewrites
//! expect-check-fail: its library's contract does not say `runs no threads`

// #3127 (§16.2b.7, §31.6.2): no default grant. A library is not taken to
// run no threads; without the statement the call stays raw.
use c_import("static inline const char *lib_version(void) { static char out[32]; out[0] = 0x76; out[1] = 0x31; out[2] = 0; return out; }\nstatic inline const char *lib_name(void) { return \"lib\"; }\n")

c contract lib:
    domain lib process
    fn lib_version
        returns borrow CStr from domain lib

fn main:
    let v = lib_version()
    print(v.is_some())
