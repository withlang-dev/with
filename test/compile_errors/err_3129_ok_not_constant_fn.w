//! expect-check-fail: 'ok NOT_A_STATUS' names no imported integer constant; a status is compared with a compile-time constant
//! expect-check-fail: = help: after 'ok' write the status constant as the header names it: 'ok CURLE_OK'

// #3129 (§16.2b.4): `ok` on an fn item names an imported constant.
use c_import("static inline int step(int a) { return 0; }\n")

c contract steps:
    fn step
        ok NOT_A_STATUS

fn main:
    print("unreachable")
