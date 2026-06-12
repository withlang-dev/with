pub fn exported_value -> i32:
    41 + 1

pub fn exported_unit -> Unit:
    print("")

fn helper:
    7

fn main:
    assert(exported_value() == 42)
    exported_unit()
    assert(helper() == 7)
