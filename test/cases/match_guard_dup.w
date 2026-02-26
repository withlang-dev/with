// Test match with guards: duplicate variant tags (non-adjacent)
type Cmd = Get(str) | Put(str, i32) | Del(str)

fn handle(cmd: Cmd) -> i32 =
    match cmd
        Get(k) if k == "special" -> 99
        Put(k, v) if v > 100 -> 200
        Get(_) -> 1
        Put(_, v) -> v
        Del(_) -> 0

fn main() -> i32 =
    println(handle(Get("special")))
    println(handle(Get("normal")))
    println(handle(Put("x", 150)))
    println(handle(Put("y", 42)))
    println(handle(Del("z")))
    0
