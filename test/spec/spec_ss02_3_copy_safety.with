// Spec test: Section 2.3 — Copy Safety (formerly 25.31)

// PASS: Copy on all-Copy struct
type CopySafetyPoint { x: f64, y: f64 }
impl Copy for CopySafetyPoint

// PASS: Copy on struct with only primitives
type CopySafetyColor { r: u8, g: u8, b: u8, a: u8 }
impl Copy for CopySafetyColor

fn test_copy_safety_structs_copy_on_assignment:
    let p = CopySafetyPoint { x: 1.0, y: 2.0 }
    let p2 = p
    assert(p.x == 1.0)
    assert(p2.y == 2.0)

    let c = CopySafetyColor { r: 10, g: 20, b: 30, a: 255 }
    let c2 = c
    assert(c.r == 10)
    assert(c2.a == 255)
