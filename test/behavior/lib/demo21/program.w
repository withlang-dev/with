use demo21.ir

pub type ConstantDesc = {
    name: str,
}

pub type ProgramSource = {
    ir: IRProgram,
    ir_text: str,
    entry: str,
    spec_constants: Vec[ConstantDesc],
}
