pub enum DType { Int32 | Float32 }

pub type IRInst {
    op: i32,
    d0: i32,
    dtype: DType,
}

pub type IRProgram {
    insts: Vec[IRInst],
}

pub fn empty_program() -> IRProgram:
    IRProgram { insts: Vec.new() }

pub fn push_inst(prog: &IRProgram, inst: IRInst):
    prog.insts.push(inst)
