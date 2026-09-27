//! expect-check-fail: cannot format a value of type 'Range[i32]' with :? — §15.4.7 gives it no Debug form

// D71 / §15.4.7 (#1564): a range has no Debug form; neither does a value
// composed of one (only compositions of the table's types have a form).

fn main:
    let pair = (1, 2..5)
    print(f"{pair:?}")
