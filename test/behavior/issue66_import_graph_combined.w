use issue66.ir
use issue66.ir_text

fn main:
    let prog = build_program()
    assert(sample_text() == "param a in [N] f32\n")
    assert(first_float_ip(prog) == 1)
    assert(count_float_values(prog) == 1)
    let checked = match validate_program(prog)
        .Ok(value) => value
        .Err(_) => 0
    assert(checked == 1)
    print("ok")
