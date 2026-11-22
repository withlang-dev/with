//! expect-stdout: ok

// An argument is evaluated once. `strlen(name(1))` called `name` twice:
// lower_auto_deref_call_arg lowered the argument to look for a deref path
// from `str` to `*const c_char`, found none, and returned -1, and the caller
// lowered it again. The walk is now decided from the types before anything is
// lowered. The struct case is the same walk succeeding: it must still lower
// exactly once.

use c_import("unsigned long strlen(const char *s);\n")

var calls: i32 = 0

fn name(n: i32) -> str:
    calls = calls + 1
    f"abc{n}"

type Holder { text: str }

fn held(n: i32) -> Holder:
    calls = calls + 1
    Holder { text: f"wxyz{n}" }

fn length_of(text: &str) -> i64: text.len()

fn main:
    assert(strlen(name(1)) == 4usize)
    assert(calls == 1)
    assert(length_of(name(22)) == 5)
    assert(calls == 2)
    assert(length_of(held(3).text) == 5)
    assert(calls == 3)
    print("ok")
