//! expect-stdout: ok

type Point { x: i32, y: i32 }

comptime fn count_fields[T: type] -> usize:
    var n = 0usize
    for field in T.fields():
        let _ = field
        n = n + 1usize
    n

comptime fn type_name[T: type] -> str:
    T.name()

comptime fn field_summary[T: type] -> str:
    var out = ""
    for field in T.fields():
        if out.len() > 0:
            out = out ++ ","
        out = out ++ field.name ++ ":" ++ field.type_name
    out

const POINT_FIELD_COUNT: usize = comptime count_fields[Point]()
const I32_TYPE_NAME: str = comptime type_name[i32]()
const POINT_FIELD_SUMMARY: str = comptime field_summary[Point]()

fn main:
    assert(POINT_FIELD_COUNT == 2usize)
    assert(I32_TYPE_NAME == "i32")
    assert(POINT_FIELD_SUMMARY == "x:i32,y:i32")
    print("ok")
