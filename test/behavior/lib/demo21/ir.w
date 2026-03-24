pub type IRProgram {
    insts: Vec[i32],
    num_params: i32,
}

pub fn empty_ir -> IRProgram:
    IRProgram { insts: Vec.new(), num_params: 0 }
