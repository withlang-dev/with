use issue66.core
use issue66.ir

pub fn sample_text() -> str:
    "param a in [N] f32\n"

pub fn build_program() -> IRProgram:
    var prog = empty_program()
    push_inst(&prog, ir_const_i32(0, 7))
    push_inst(&prog, ir_const_f32(1, 1.25))
    prog

pub fn first_float_ip(prog: IRProgram) -> i32:
    for ip in 0..prog.insts.len():
        let inst = prog.insts[ip]
        if inst.dtype == .Float32:
            return ip
    -1
