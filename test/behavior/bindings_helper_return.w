//! expect-stdout: ok

type BindEntry {
    x: i32,
}

type Bindings {
    entries: Vec[BindEntry],
}

fn bindings_from(entries: Vec[BindEntry]) -> Bindings:
    Bindings { entries }

fn main:
    let bindings = bindings_from(Vec.new())
    if bindings.entries.len() == 0:
        println("ok")
