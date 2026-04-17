use issue66.ir
use issue66.core

fn main:
    var prog = empty_program()
    push_inst(&prog, ir_const_f32(0, 3.5))
    assert(count_float_values(prog) == 1)
    let checked = match validate_program(prog):
        .Ok(value) => value
        .Err(_) => 0
    assert(checked == 1)
    print("ok")
