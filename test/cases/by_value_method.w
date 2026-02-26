// Test by-value self method chaining

type Config = {
    width: i32,
    height: i32,
    depth: i32,
}

impl Config =
    fn set_width(self: Config, w: i32) -> Config:
        { self with width: w }

    fn set_height(self: Config, h: i32) -> Config:
        { self with height: h }

    fn set_depth(self: Config, d: i32) -> Config:
        { self with depth: d }

fn main -> i32:
    let cfg = Config { width: 0, height: 0, depth: 0 }
    let final = cfg.set_width(10).set_height(20).set_depth(30)
    assert(final.width == 10)
    assert(final.height == 20)
    assert(final.depth == 30)
