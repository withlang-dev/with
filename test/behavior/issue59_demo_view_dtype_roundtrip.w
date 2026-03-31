//! expect-stdout: ok

use demo.device
use demo.memory
use demo.program
use demo.view

fn echo(view: View) -> View:
    view

fn main:
    let mem = alloc(default_device(), 8usize).unwrap()
    let view = view_contiguous(mem, shape1(2usize), .Int32)
    let echoed = echo(view)
    assert(echoed.dtype == .Int32)

    let entry = bind("a", echoed)
    let entries: Vec[BindEntry] = Vec.new()
    entries.push(entry)
    let bindings = bindings_from(entries)
    assert(bindings.entries.len() == 1)
    assert(bindings.entries[0].view.dtype == .Int32)

    free(mem)
    print("ok")
