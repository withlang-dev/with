//! expect-check-fail: type mismatch

trait BoxDynMissingLogger:
    fn message(self: &Self) -> str

type BoxDynMissingConsole {
    level: i32,
}

fn main:
    let _logger: Box[dyn BoxDynMissingLogger] = Box.new(BoxDynMissingConsole { level: 7 })
