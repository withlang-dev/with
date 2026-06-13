//! expect-stdout: ok

trait Named:
    fn label(self: &Self) -> str

type Point: Copy { x: i32, y: i32 }
enum Val { Num(i32) | Empty }

impl Named for Point:
    fn label(self: &Self) -> str:
        "Point"

const POINT_NAME: str = comptime TypeInfo.name[Point]()
const POINT_SIZE: usize = comptime TypeInfo.size[Point]()
const POINT_ALIGN: usize = comptime TypeInfo.align[Point]()
const POINT_IS_COPY: bool = comptime TypeInfo.is_copy[Point]()
const POINT_HAS_NAMED: bool = comptime TypeInfo.implements[Point](Named)
const VAL_HAS_NAMED: bool = comptime TypeInfo.implements[Val](Named)

comptime fn module_field_summary[T: type] -> str:
    var out = ""
    for field in TypeInfo.fields[T]():
        if out.len() > 0:
            out = out ++ ","
        out = out ++ field.name ++ ":" ++ field.type_name
    out

comptime fn direct_field_summary[T: type] -> str:
    var out = ""
    for field in T.fields():
        if out.len() > 0:
            out = out ++ ","
        out = out ++ field.name ++ ":" ++ field.type_name
    out

fn variant_summary() -> str:
    var out = ""
    comptime for variant in TypeInfo.variants[Val]():
        out = out ++ variant.name
        if variant.has_payload:
            out = out ++ ":" ++ variant.payload_type_name
        out = out ++ ":" ++ f"{variant.discriminant}" ++ ";"
    out

const MODULE_FIELDS: str = comptime module_field_summary[Point]()
const DIRECT_FIELDS: str = comptime direct_field_summary[Point]()

fn main:
    assert(POINT_NAME == Point.name())
    assert(POINT_SIZE == Point.size())
    assert(POINT_ALIGN == Point.align())
    assert(POINT_IS_COPY == Point.is_copy())
    assert(POINT_HAS_NAMED)
    assert(not VAL_HAS_NAMED)
    assert(MODULE_FIELDS == "x:i32,y:i32")
    assert(MODULE_FIELDS == DIRECT_FIELDS)
    assert(variant_summary() == "Num:i32:0;Empty:1;")
    print("ok")
