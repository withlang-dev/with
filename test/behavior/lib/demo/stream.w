use c_import("stdlib.h")

use demo.core
use demo.program
use demo.view

type EventRec {
    done: bool,
}

fn event_rec(event: Event) -> *mut EventRec:
    event as *mut EventRec

fn alloc_event(done: bool) -> Result[Event, DemoError]:
    let raw = unsafe { malloc(size_of[EventRec]()) }
    if raw == None:
        return Err(.OutOfMemory)
    let rec = raw.unwrap() as *mut EventRec
    unsafe:
        (*rec).done = done
    Ok(rec as Event)

fn binding_view(bindings: &Bindings, name: str) -> Result[View, DemoError]:
    var i = 0
    while i < bindings.entries.len():
        let entry = bindings.entries[i]
        if entry.name == name:
            return Ok(entry.view)
        i = i + 1
    Err(.MissingBinding(name))

fn run_reduce(bindings: &Bindings):
    let a_view = binding_view(bindings, "a").unwrap()
    let out_view = binding_view(bindings, "out").unwrap()
    let a_ptr = a_view.memory as *mut i32
    let out_ptr = out_view.memory as *mut i32
    var sum = 0
    var i: Size = 0usize
    let count = view_elem_count(a_view)
    while i < count:
        sum = sum + unsafe *(a_ptr + i as i64)
        i = i + 1usize
    let base = unsafe *out_ptr
    unsafe:
        *out_ptr = base + sum

fn run_relu(bindings: &Bindings):
    let a_view = binding_view(bindings, "a").unwrap()
    let out_view = binding_view(bindings, "out").unwrap()
    let a_ptr = a_view.memory as *mut i32
    let out_ptr = out_view.memory as *mut i32
    var i: Size = 0usize
    let count = view_elem_count(a_view)
    while i < count:
        let value = unsafe *(a_ptr + i as i64)
        let relu = if value < 0: 0 else: value
        unsafe:
            *(out_ptr + i as i64) = relu
        i = i + 1usize

pub fn stream_create(device: Device) -> Stream:
    device + 1

pub fn stream_destroy(stream: Stream) -> Unit:
    let _ = stream

pub fn dispatch(stream: Stream, prog: Program, bindings: &Bindings) -> Result[Event, DemoError]:
    let _ = stream
    let kind = program_kind(prog)
    if kind == 1:
        run_reduce(bindings)
        return alloc_event(true)
    if kind == 2:
        run_relu(bindings)
        return alloc_event(true)
    Err(.InvalidProgram("unknown program kind"))

pub fn event_is_done(event: Event) -> bool:
    if event == 0:
        return false
    unsafe (*event_rec(event)).done

pub fn event_destroy(event: Event) -> Unit:
    if event == 0:
        return
    let _ = unsafe { realloc(event as *mut c_void, 0usize) }
