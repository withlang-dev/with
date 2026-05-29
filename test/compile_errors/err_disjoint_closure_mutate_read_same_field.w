//! expect-check-fail: already mutably borrowed

type ClosureCaptureWorld {
    positions: i32,
    velocities: i32,
}

fn write_then_read(writer: fn() -> void, reader: fn() -> i32) -> i32:
    writer()
    reader()

fn bad:
    var world = ClosureCaptureWorld { positions: 1, velocities: 2 }
    let _ = write_then_read(
        () => world.positions = world.positions + 1,
        () => world.positions + world.velocities,
    )
