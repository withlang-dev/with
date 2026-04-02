use issue66.ir_text

fn main:
    let prog = build_program()
    assert(sample_text() == "param a in [N] f32\n")
    assert(first_float_ip(prog) == 1)
    print("ok")
