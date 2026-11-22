//! expect-stdout: 5 2 3 14
//! expect-stdout: 9 1

// §4.3d (D78, #1874): the components .x .y .z .w are lanes, and a lane is
// written as it is read — `v.x = 5` writes lane 0 as `v[0] = 5` does.
type Particle { pos: i32x4, id: i32 }

fn main:
    var v = i32x4(1, 2, 3, 4)
    v.x = 5
    v.w += 10
    print(f"{v[0]} {v.y} {v.z} {v.w}")
    var p = Particle { pos: i32x4.splat(0), id: 1 }
    p.pos.x = 9
    print(f"{p.pos.x} {p.id}")
