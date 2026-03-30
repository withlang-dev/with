//! expect-stdout: ok

trait Named =
    fn label(self: Self) -> str

type Point { x: i32, y: i32 }
enum Val { Num(i32) | Empty }

impl Named for Point =
    fn label(self: Point) -> str:
        let _ = self
        "Point"

const POINT_NAME: str = comptime Point.name()
const POINT_SIZE: usize = comptime Point.size()
const POINT_ALIGN: usize = comptime Point.align()
const POINT_IS_COPY: bool = comptime Point.is_copy()
const POINT_HAS_NAMED: bool = comptime Point.implements(Named)
const VAL_HAS_NAMED: bool = comptime Val.implements(Named)

fn point_fields_summary() -> str:
    var out = ""
    comptime for field in Point.fields():
        out = out ++ field.name ++ ":" ++ f"{field.offset}" ++ ":" ++ f"{field.size}" ++ ":" ++ field.type_name ++ ";"
    out

fn variant_summary() -> str:
    var out = ""
    comptime for variant in Val.variants():
        out = out ++ variant.name
        if variant.has_payload:
            out = out ++ ":" ++ variant.payload_type_name
        out = out ++ ":" ++ f"{variant.discriminant}" ++ ";"
    out

fn main:
    assert(POINT_NAME == "Point")
    assert(POINT_SIZE == 8)
    assert(POINT_ALIGN == 4)
    assert(POINT_IS_COPY)
    assert(POINT_HAS_NAMED)
    assert(not VAL_HAS_NAMED)
    assert(point_fields_summary() == "x:0:4:i32;y:4:4:i32;")
    assert(variant_summary() == "Num:i32:0;Empty:1;")
    print("ok")
