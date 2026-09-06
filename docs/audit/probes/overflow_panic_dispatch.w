use std.process

fn id_i8(x: i8): x
fn id_i64(x: i64): x
fn id_u8(x: u8): x

fn main:
    let argv = args()
    assert(argv.len() >= 2)
    let op = argv.get(1)

    if op == "ok":
        assert(id_i8(1) + id_i8(2) == id_i8(3))
        print("overflow-panic-control: ok")
        return
    if op == "uadd": let _ = id_u8(255) + id_u8(1)
    if op == "usub": let _ = id_u8(0) - id_u8(1)
    if op == "umul": let _ = id_u8(128) * id_u8(2)
    if op == "saddhi": let _ = id_i8(127) + id_i8(1)
    if op == "saddlo": let _ = id_i8(-128) + id_i8(-1)
    if op == "ssubhi": let _ = id_i8(127) - id_i8(-1)
    if op == "ssublo": let _ = id_i8(-128) - id_i8(1)
    if op == "smulhi": let _ = id_i8(64) * id_i8(2)
    if op == "smullo": let _ = id_i8(-128) * id_i8(2)
    if op == "neg8": let _ = -id_i8(-128)
    if op == "div8": let _ = id_i8(-128) / id_i8(-1)
    if op == "mod8": let _ = id_i8(-128) % id_i8(-1)

    let i64_max = id_i64(9223372036854775807)
    let i64_min = id_i64(-9223372036854775807 - 1)
    if op == "sadd64": let _ = i64_max + id_i64(1)
    if op == "smul64": let _ = i64_max * id_i64(2)
    if op == "neg64": let _ = -i64_min
    if op == "div64": let _ = i64_min / id_i64(-1)
    if op == "mod64": let _ = i64_min % id_i64(-1)

    print("unexpected non-panic")
