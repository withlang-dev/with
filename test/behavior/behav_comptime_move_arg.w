comptime fn consume(xs: Vec[str]) -> i64:
    xs.len()

comptime fn moved_vec_len() -> i64:
    let xs = Vec[str].new()
    consume(move xs)

const MOVED_LEN: i64 = comptime moved_vec_len()

fn main:
    assert(MOVED_LEN == 0)
    print("comptime-move-arg")
