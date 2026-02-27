type Pool = {
    x: i32,
}

fn Pool.bump(self: *mut Pool) -> void:
    self.x = self.x + 1

type Wrap = {
    pool: Pool,
}

fn main:
    var w = Wrap { pool: Pool { x: 0 } }
    Pool.bump(w.pool)
    println(i32_to_str(w.pool.x))

extern fn i32_to_str(n: i32) -> str
