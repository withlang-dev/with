//! expect-stdout: ok

comptime fn str_len_val() -> i64:
    let s = "hello"
    s.len()

comptime fn str_byte_at_val() -> i32:
    let s = "hello"
    s.byte_at(1)

comptime fn str_slice_val() -> str:
    let s = "hello world"
    s.slice(0, 5)

comptime fn str_contains_hit() -> bool:
    let s = "hello world"
    s.contains("world")

comptime fn str_contains_miss() -> bool:
    let s = "hello world"
    s.contains("xyz")

comptime fn str_starts_with_hit() -> bool:
    let s = "hello world"
    s.starts_with("hello")

comptime fn str_starts_with_miss() -> bool:
    let s = "hello world"
    s.starts_with("world")

comptime fn str_ends_with_hit() -> bool:
    let s = "hello world"
    s.ends_with("world")

comptime fn str_ends_with_miss() -> bool:
    let s = "hello world"
    s.ends_with("hello")

comptime fn str_find_hit() -> i64:
    let s = "hello world"
    s.find("world")

comptime fn str_find_miss() -> i64:
    let s = "hello world"
    s.find("xyz")

comptime fn str_replace_val() -> str:
    let s = "hello world"
    s.replace("world", "with")

const LEN_VAL: i64 = comptime str_len_val()
const BYTE_AT: i32 = comptime str_byte_at_val()
const SLICE_VAL: str = comptime str_slice_val()
const CONTAINS_HIT: bool = comptime str_contains_hit()
const CONTAINS_MISS: bool = comptime str_contains_miss()
const STARTS_HIT: bool = comptime str_starts_with_hit()
const STARTS_MISS: bool = comptime str_starts_with_miss()
const ENDS_HIT: bool = comptime str_ends_with_hit()
const ENDS_MISS: bool = comptime str_ends_with_miss()
const FIND_HIT: i64 = comptime str_find_hit()
const FIND_MISS: i64 = comptime str_find_miss()
const REPLACE_VAL: str = comptime str_replace_val()

fn main:
    assert(LEN_VAL == 5)
    assert(BYTE_AT == 101)
    assert(SLICE_VAL == "hello")
    assert(CONTAINS_HIT == true)
    assert(CONTAINS_MISS == false)
    assert(STARTS_HIT == true)
    assert(STARTS_MISS == false)
    assert(ENDS_HIT == true)
    assert(ENDS_MISS == false)
    assert(FIND_HIT == 6)
    assert(FIND_MISS == -1)
    assert(REPLACE_VAL == "hello with")
    print("ok")
