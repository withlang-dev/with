// Test: comptime for loop (unrolling)
fn sum_1_to_5() -> i32 =
    var total = 0
    comptime for i in [1, 2, 3, 4, 5]:
        total = total + i
    total

fn main() -> i32 =
    if sum_1_to_5() == 15 then 0 else 1
