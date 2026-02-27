// Phase 2 gap: Result[Unit, E] codegen path still fails even though Ok() parses
fn noop -> Result[Unit, i32]:
    Ok()

fn main -> i32:
    let _ = noop()
