//! args: --dump-mir
//! expect-check-stdout: _3 = str_concat_n([copy _1.buf
//! expect-check-stdout: _1.buf = move _3
//! expect-check-stdout-not: _1.buf = str_concat_n([move _1.buf

type Acc { buf: str, name: str }

fn saved_alias -> str:
    var a = Acc { buf: "", name: "n" }
    let saved = a.buf
    a.buf = a.buf ++ "x"
    saved ++ a.buf

