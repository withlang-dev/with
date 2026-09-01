//! args: --dump-mir
//! expect-check-stdout: _3 = str_concat_n([copy _1.buf, copy _1.name])
//! expect-check-stdout: _1.buf = move _3
//! expect-check-stdout-not: _1.buf = str_concat_n([move _1.buf

type Acc { buf: str, name: str }

fn later_base_operand -> str:
    var a = Acc { buf: "", name: "n" }
    a.buf = a.buf ++ a.name
    move a.buf

