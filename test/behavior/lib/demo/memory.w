use c_import("stdlib.h")

use demo.core

pub fn alloc(device: Device, size: Size) -> Result[Memory, DemoError]:
    let _ = device
    let raw = unsafe { malloc(size) }
    if raw == None:
        return Err(.OutOfMemory)
    Ok(raw.unwrap() as Memory)

pub fn free(mem: Memory) -> Unit:
    if mem == 0:
        return
    let _ = unsafe { realloc(mem as *mut c_void, 0usize) }

pub fn memory_ptr(mem: Memory) -> *mut u8:
    mem as *mut u8
