comptime fn consume(xs: List[str]) -> i64:
    xs.len()

comptime fn moved_list_len() -> i64:
    let xs = List[str].new()
    consume(move xs)

const MOVED_LEN: i64 = comptime moved_list_len()

fn main:
    assert(MOVED_LEN == 0)
    print("comptime-move-arg")
