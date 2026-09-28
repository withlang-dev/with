fn analysis_probe_read(value: &Vec[i32]): value.len()
fn analysis_probe_write(value: Vec[i32]): value.push(1)
fn analysis_probe_take(value: Vec[i32]): value

fn main:
    var shared = Vec.new()
    let _ = analysis_probe_read(shared)
    analysis_probe_write(shared)
    let owned: Vec[i32] = Vec.new()
    let _ = analysis_probe_take(move owned)
