//! expect-stdout: issue353 inferred const passed

const MODULE_CONST = 41
const MODULE_TYPED: i32 = 1

fn local_const_value -> i32:
    const LOCAL_CONST = MODULE_CONST + MODULE_TYPED
    LOCAL_CONST

fn main:
    assert(local_const_value() == 42)
    print("issue353 inferred const passed")
