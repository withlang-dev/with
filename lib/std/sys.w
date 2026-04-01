// std.sys — System information
//
// Provides CPU, memory, and page size queries via the runtime interface.
// No c_import.

extern fn with_sysinfo(out: *mut u8) -> i32

type SysInfo:
    cpu_cores: i32
    memory_total: i64
    page_size: i64

/// Query system information (cores, memory, page size).
pub fn info() -> SysInfo:
    var out = SysInfo { cpu_cores: 1, memory_total: 0, page_size: 4096 }
    let _ = with_sysinfo(&out as *mut u8)
    out

/// Number of logical CPU cores (including hyperthreads).
pub fn cpu_count() -> i32:
    info().cpu_cores

/// Total physical memory in bytes.
pub fn total_memory() -> i64:
    info().memory_total

/// OS page size in bytes (typically 4096 or 16384).
pub fn page_size() -> i64:
    info().page_size
