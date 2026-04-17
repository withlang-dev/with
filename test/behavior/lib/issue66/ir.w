use issue66.core
use issue66.errors

pub fn ir_const_i32(dest: i32, value: i32) -> IRInst:
    let _ = value
    IRInst { op: dest, d0: dest, dtype: .Int32 }

pub fn ir_const_f32(dest: i32, value: f32) -> IRInst:
    let _ = value
    IRInst { op: dest, d0: dest, dtype: .Float32 }

pub fn count_float_values(prog: IRProgram) -> i32:
    var count: i32 = 0
    for ip in 0..prog.insts.len():
        let inst = prog.insts[ip]
        match inst.dtype:
            .Float32 => count = count + 1
            .Int32 => continue
    count

pub fn validate_program(prog: IRProgram) -> Result[i32, DemoError]:
    if prog.insts.len() == 0:
        return Err(.ParseError("empty program"))
    Ok(count_float_values(prog))
