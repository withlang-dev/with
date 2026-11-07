//! expect-check-fail: `HashMap`'s third argument names its hasher: `Minted`, for keys that are IDs this program minted (§11.7, D196); `i32` is not a hasher

// D196: the third argument of HashMap is the hasher and nothing else.
use std.collections.HashMap

fn main:
    var m: HashMap[i32, i32, i32] = HashMap.new()
    m.insert(1, 2)
    print(f"{m.len()}")
