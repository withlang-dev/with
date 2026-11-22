//! expect-check-fail: already mutably borrowed

type ClosureCaptureWorld {
    positions: i32,
    velocities: i32,
}

fn apply_two(a: fn() -> Unit, b: fn() -> Unit):
    a()
    b()

fn bad:
    var world = ClosureCaptureWorld { positions: 1, velocities: 2 }
    apply_two(
        () => world.positions = world.positions + 1,
        () => world.positions = world.positions + 2,
    )
