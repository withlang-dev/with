// Test: record update with multiple fields
type Config = {
    width: i32,
    height: i32,
    depth: i32,
    visible: bool
}

type Point3D = {
    x: i32,
    y: i32,
    z: i32
}

fn main() -> i32 =
    // single field update
    let cfg1 = Config { width: 800, height: 600, depth: 32, visible: true }
    let cfg2 = { cfg1 with width: 1920 }
    assert(cfg2.width == 1920)
    assert(cfg2.height == 600)
    assert(cfg2.depth == 32)

    // update two fields
    let cfg3 = { cfg1 with width: 1024, height: 768 }
    assert(cfg3.width == 1024)
    assert(cfg3.height == 768)
    assert(cfg3.depth == 32)

    // update three fields
    let cfg4 = { cfg1 with width: 320, height: 240, depth: 16 }
    assert(cfg4.width == 320)
    assert(cfg4.height == 240)
    assert(cfg4.depth == 16)

    // chain record updates
    let p = Point3D { x: 1, y: 2, z: 3 }
    let q = { p with x: 10 }
    let r = { q with y: 20 }
    assert(r.x == 10)
    assert(r.y == 20)
    assert(r.z == 3)

    // original is unchanged
    assert(p.x == 1)
    assert(p.y == 2)
    assert(p.z == 3)

    println("all record update multi tests passed")
    0
