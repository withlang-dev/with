//! expect-stdout: ok

extern fn with_runtime_run_one_step() -> Unit

async fn value(n: i32) -> i32:
    n

fn complete_two_ready_tasks():
    unsafe { with_runtime_run_one_step() }
    unsafe { with_runtime_run_one_step() }

fn test_fair_select:
    var left_wins = 0
    var right_wins = 0
    var i = 0
    while i < 64:
        let left = value(1)
        let right = value(2)
        complete_two_ready_tasks()

        select await:
            x = left => left_wins = left_wins + x
            y = right => right_wins = right_wins + (y / 2)

        i = i + 1

    assert(left_wins > 0)
    assert(right_wins > 0)

fn test_biased_select:
    var left_wins = 0
    var right_wins = 0
    var i = 0
    while i < 16:
        let left = value(1)
        let right = value(2)
        complete_two_ready_tasks()

        select await biased:
            x = left => left_wins = left_wins + x
            y = right => right_wins = right_wins + (y / 2)

        i = i + 1

    assert(left_wins == 16)
    assert(right_wins == 0)

fn main:
    test_fair_select()
    test_biased_select()
    print("ok")
