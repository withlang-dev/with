//! args: --dump-mir
//! expect-check-stdout: _1.f4 = str_concat_n([move _1.f4

type Acc { buf: str, name: str }

fn fast_field -> str:
    var a = Acc { buf: "", name: "n" }
    a.buf = a.buf ++ "x"
    a.buf

