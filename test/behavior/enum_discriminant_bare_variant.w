//! expect-stdout: ok
extern fn print(s: str) -> void

enum SegKind: i32:
    Literal = 0
    Expr = 1

fn tag_name(seg_kind: i32) -> str:
    if seg_kind == Literal:
        return "lit"
    if seg_kind == Expr:
        return "expr"
    "other"

fn passthrough(seg_kind: i32) -> i32:
    seg_kind

fn main:
    assert(tag_name(Literal) == "lit")
    assert(tag_name(Expr) == "expr")
    assert(passthrough(Literal) == 0)
    assert(passthrough(Expr) == 1)
    print("ok")
