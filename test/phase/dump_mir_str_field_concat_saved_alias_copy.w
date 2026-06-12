//! args: --dump-mir
//! expect-check-stdout: _4 = binop(concat, copy _1.f4
//! expect-check-stdout: _1.f4 = copy _4
//! expect-check-stdout-not: _1.f4 = str_concat_n([move _1.f4

type Acc { buf: str, name: str }

fn saved_alias -> str:
    var a = Acc { buf: "", name: "n" }
    let saved = a.buf
    a.buf = a.buf ++ "x"
    saved ++ a.buf

