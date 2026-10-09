//! expect-stdout: ok

type BindEntry {
    x: i32,
}

type Bindings {
    entries: List[BindEntry],
}

fn bindings_from(entries: List[BindEntry]) -> Bindings:
    Bindings { entries }

fn main:
    let bindings = bindings_from(List.new())
    if bindings.entries.len() == 0:
        print("ok")
