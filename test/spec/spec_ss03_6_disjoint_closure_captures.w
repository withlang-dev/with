// Spec test: Section 3.6 - Disjoint Closure Captures.

type ClosureCaptureWorld {
    positions: i32,
    velocities: i32,
    sprites: i32,
}

fn apply_two(a: fn() -> void, b: fn() -> void):
    a()
    b()

fn write_then_read(writer: fn() -> void, reader: fn() -> i32) -> i32:
    writer()
    reader()

fn test_disjoint_mutating_field_captures:
    var world = ClosureCaptureWorld { positions: 1, velocities: 2, sprites: 3 }
    apply_two(
        () => world.velocities = world.velocities + 10,
        () => world.sprites = world.sprites + 20,
    )
    assert(world.positions == 1)
    assert(world.velocities == 12)
    assert(world.sprites == 23)

fn test_shared_overlap_with_disjoint_mutating_capture:
    var world = ClosureCaptureWorld { positions: 5, velocities: 10, sprites: 20 }
    let observed = write_then_read(
        () => world.velocities = world.positions + world.velocities,
        () => world.positions + world.sprites,
    )
    assert(world.positions == 5)
    assert(world.velocities == 15)
    assert(observed == 25)
