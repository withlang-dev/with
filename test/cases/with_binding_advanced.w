// Test: with binding pattern (Form 3)
type Config = { debug: bool, level: i32 }

fn make_config() -> Config =
    Config { debug: true, level: 5 }

fn main() -> i32 =
    let result = with make_config() as cfg:
        if cfg.debug then cfg.level * 2 else cfg.level
    assert(result == 10)

    // with mutable binding
    let result2 = with make_config() as mut cfg:
        cfg.level = cfg.level + 37
        cfg.level
    assert(result2 == 42)

    0
