pub type Program {
    count: i32,
}

pub fn program_empty -> Program:
    Program { count: 0 }

pub fn program_count(program: Program) -> i32:
    program.count
