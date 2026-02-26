// Test enum state transitions via function chaining
type State = Idle | Running(i32) | Done(i32)

fn step(s: State) -> State =
    match s
        Idle -> Running(0)
        Running(n) if n >= 3 -> Done(n)
        Running(n) -> Running(n + 1)
        Done(n) -> Done(n)

fn extract(s: State) -> i32 =
    match s
        Done(n) -> n
        Running(n) -> n
        Idle -> -1

fn main() -> i32 =
    let s0 = Idle
    let s1 = step(s0)
    let s2 = step(s1)
    let s3 = step(s2)
    let s4 = step(s3)
    let s5 = step(s4)
    println(extract(s5))
    0
