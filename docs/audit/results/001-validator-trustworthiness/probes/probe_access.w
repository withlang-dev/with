use Mir

fn main:
    var mir_mod = MirModule.init()
    let verdict = validate_mir_module(mir_mod)
    print(verdict)
