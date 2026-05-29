use c_import("stdlib.h")

use demo.core
use demo.view

type Pair {
    device: Device,
}

type ProgramRec {
    kind: i32,
}

pub type ProgramSource {
    entry: str,
    ir_text: str,
}

pub type BindEntry: Copy {
    name: str,
    view: View,
}

pub type Bindings {
    entries: Vec[BindEntry],
}

fn program_rec(prog: Program) -> *mut ProgramRec:
    prog as *mut ProgramRec

fn alloc_program(kind: i32) -> Result[Program, DemoError]:
    let raw = malloc(size_of[ProgramRec]())
    if raw == None:
        return Err(.OutOfMemory)
    let rec = raw.unwrap() as *mut ProgramRec
    unsafe:
        (*rec).kind = kind
    Ok(rec as Program)

pub fn program_source(entry: str) -> ProgramSource:
    ProgramSource { entry, ir_text: "" }

pub fn bind(name: str, view: View) -> BindEntry:
    BindEntry { name, view }

pub fn bindings_from(entries: Vec[BindEntry]) -> Bindings:
    Bindings { entries }

pub fn compile(device: Device, source: ProgramSource) -> Result[Program, DemoError]:
    let _ = device
    let _ = source.entry
    if source.ir_text.contains("select") and source.ir_text.contains("store out [@0] %7"):
        return alloc_program(2)
    if source.ir_text.contains("add") and source.ir_text.contains("store out [] %6"):
        return alloc_program(1)
    Err(.InvalidProgram("unsupported demo IR"))

pub fn program_kind(prog: Program) -> i32:
    if prog == 0:
        return 0
    unsafe (*program_rec(prog)).kind

pub fn program_destroy(prog: Program):
    if prog == 0:
        return
    let _ = realloc(prog as *mut c_void, 0usize)

pub fn ok(device: Device) -> bool:
    let pair = Pair { device }
    pair.device == device
