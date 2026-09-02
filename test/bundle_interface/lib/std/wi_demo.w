// D39 bundle-interface demo module (build/selfhost.w bs_check_bundle_interface).
// Lives under lib/std/ so its canonical path is <embedded-std>/std/wi_demo.w
// in both the bundle object and the consumer; wi_demo.wi is its interface.
pub type Pair { a: i32, b: i32 }
pub const K: i32 = 7
pub let TABLE: [4]u8 = [1, 2, 3, 4]
pub fn add(p: &Pair) -> i32: p.a + p.b
pub fn take(p: Pair) -> i32: p.a * p.b
pub fn table_at(i: i64) -> u8: TABLE[i]
