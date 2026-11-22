//! expect-stdout: true 3 3
//! expect-stdout: ok

// #3041 (§17.6): `str.bytes()` (`ByteIter` implementing `Iter[u8]`) and
// `str.as_bytes()` (`(*self) as []u8`) evaluate at compile time in `for` loops
// and comprehensions.

comptime fn hash_str(s: str) -> u64:
    var h: u64 = 5381
    for c in s.bytes():
        h = h *% 33 +% c as u64
    h

comptime fn sum_as_bytes(s: str) -> i32:
    var acc = 0
    for b in s.as_bytes():
        acc += b as i32
    acc

const SHADER_PARAM_ID = comptime hash_str("world_matrix")
const ABC_SUM = comptime sum_as_bytes("abc")
const ABC_LIST: List[u8] = comptime [b for b in "abc".as_bytes()]

fn main:
    let expected_sum = 97 + 98 + 99
    print(f"{SHADER_PARAM_ID > 0 and ABC_SUM == expected_sum} {ABC_LIST.len()} {("xyz".as_bytes()).len()}")
    print("ok")
