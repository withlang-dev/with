//! skip
// Spec test: Section 3.6 — Disjoint Closure Captures (formerly 25.55)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

type World { positions: Vec[Vec2], velocities: Vec[Vec2], sprites: Vec[Sprite] }

// PASS: closures capture disjoint fields
fn test:
    var world = World { ... }
    scope s =>
        s.spawn(() => update_physics(&mut world.velocities, &world.positions))
        s.spawn(() => render(&world.positions, &world.sprites))
    // OK: first captures velocities (mut) + positions (shared)
    //     second captures positions (shared) + sprites (shared)
    //     no conflict — disjoint mutable access

// FAIL: overlapping mutable capture
fn test_fail:
    var world = World { ... }
    scope s =>
        s.spawn(() => modify(&mut world.positions))
        s.spawn(() => modify(&mut world.positions))  // ERROR: conflicting borrows
