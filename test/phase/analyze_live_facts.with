fn analysis_probe_read(value: &List[i32]): value.len()
fn analysis_probe_write(value: List[i32]): value.push(1)
fn analysis_probe_take(value: List[i32]): value

fn main:
    var shared = List.new()
    let _ = analysis_probe_read(shared)
    analysis_probe_write(shared)
    let owned: List[i32] = List.new()
    let _ = analysis_probe_take(move owned)
