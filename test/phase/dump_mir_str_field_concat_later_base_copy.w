//! args: --dump-mir
//! expect-check-stdout: _3 = binop(concat, copy _1.f4, copy _1.f6)
//! expect-check-stdout: _1.f4 = copy _3
//! expect-check-stdout-not: _1.f4 = str_concat_n([move _1.f4

type Acc { buf: str, name: str }

fn later_base_operand -> str:
    var a = Acc { buf: "", name: "n" }
    a.buf = a.buf ++ a.name
    a.buf

