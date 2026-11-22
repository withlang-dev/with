//! args: --dump-mir
//! expect-check-stdout: str_concat_n([

fn chain(a: str, b: str, c: str, d: str) -> str:
    a ++ b ++ c ++ d

fn main:
    assert(chain("a", "b", "c", "d") == "abcd")
