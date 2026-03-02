// Mir — Minimal MIR scaffold for module layout validation.
//
// Provides a stable in-memory representation with invariants
// (non-empty names, non-empty bodies, unique function names).

type MirFunction = {
    name: str,
    block_count: i32,
}

type MirModule = {
    functions: Vec[MirFunction],
}

fn MirModule.init -> MirModule:
    MirModule {
        functions: Vec.new(),
    }

fn MirModule.deinit(self: MirModule):
    return

// Add a function to the module. Returns 0 on success, -1 on error.
fn MirModule.add_function(self: MirModule, name: str, block_count: i32) -> i32:
    if name.len() == 0:
        return -1
    if block_count == 0:
        return -1
    if self.has_function(name):
        return -1
    self.functions.push(MirFunction { name, block_count })
    0

fn MirModule.has_function(self: MirModule, name: str) -> bool:
    for i in 0..self.functions.len() as i32:
        if self.functions.get(i as i64).name == name:
            return true
    false
