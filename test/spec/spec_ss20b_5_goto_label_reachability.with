//! expect-stdout: finished

fn goto_label_region -> i32:
    goto 'done
    'done:
        return 7

fn conditional_goto_is_not_unconditional(flag: bool) -> i32:
    if flag:
        goto 'done
    return 1
    'done:
        return 2

fn conditional_never_is_not_unconditional(flag: bool) -> i32:
    if flag:
        todo("flagged")
    3

fn main:
    assert(goto_label_region() == 7)
    assert(conditional_goto_is_not_unconditional(false) == 1)
    assert(conditional_goto_is_not_unconditional(true) == 2)
    assert(conditional_never_is_not_unconditional(false) == 3)
    print("finished")
