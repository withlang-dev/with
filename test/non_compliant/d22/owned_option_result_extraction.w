//! D22-NON-COMPLIANT
//! owner-stage: 5
//! required-verdict: compile-and-run under `--debug-alloc`
//! exact-type: owned Option/Result eliminators each produce `Vec[i64]`
//! expected-diagnostic: none
//! origin-set: owned payloads have `{}`
//! drop-behavior: consuming elimination resets each wrapper; each Vec buffer drops exactly once; leak count=0
//! expect-debug-alloc: leak count=0

fn one(value: i64) -> Vec[i64]:
    let out: Vec[i64] = Vec.new()
    out.push(value)
    out

fn main:
    let option: Option[Vec[i64]] = Some(one(125))
    let from_option = option.unwrap()
    assert(from_option[0] == 125)

    let result: Result[Vec[i64], str] = Ok(one(126))
    let from_result = result.unwrap()
    assert(from_result[0] == 126)
