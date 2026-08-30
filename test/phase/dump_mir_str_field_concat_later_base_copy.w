//! args: --dump-mir
//! expect-check-stdout: _3 = str_concat_n([copy _1.f86, copy _1.f349])
//! expect-check-stdout: _1.f86 = move _3
//! expect-check-stdout-not: _1.f86 = str_concat_n([move _1.f86

type Acc { buf: str, name: str }

fn later_base_operand -> str:
    var a = Acc { buf: "", name: "n" }
    a.buf = a.buf ++ a.name
    move a.buf

