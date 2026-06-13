//! expect-stdout: ok

type Pair { x: i32, y: i32 }

fn describe_pair(value: &Pair) -> str:
    var out = ""
    comptime for field in Pair.fields():
        out = out ++ field.name ++ "=" ++ value.{field.name}.debug_str() ++ ";"
    out

fn sum_pair(value: &Pair) -> i32:
    var total = 0
    comptime for field in Pair.fields():
        total = total + value.{field.name}
    total

fn main:
    let value = Pair { x: 40, y: 2 }
    assert(describe_pair(value) == "x=40;y=2;")
    assert(sum_pair(value) == 42)
    print("ok")
