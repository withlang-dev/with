// std.sys — System information
//
// Machine characteristics: cores, memory, page size, bandwidth.
// Lazily initialized on first call, cached for process lifetime.
// No c_import — uses with_sysinfo and with_clock_nanos from the runtime.

extern fn with_sysinfo(out: *mut u8) -> i32
extern fn with_clock_nanos() -> i64
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

type SysInfo {
    cpu_cores: i32,
    memory_total: i64,
    page_size: i64,
}

// ── Cached state ────────────────────────────────────────────────

var _cached: bool = false
var _cpu_count: i32 = 0
var _total_memory: usize = 0
var _page_size: usize = 0
var _bandwidth: f64 = 0.0
// Optimization barrier: written by _read_pass, read by _measure_bandwidth.
// Prevents LLVM from eliminating the read loop.
var _bw_sink: i64 = 0

fn _ensure_init():
    if _cached: return
    var info = SysInfo { cpu_cores: 1, memory_total: 0, page_size: 4096 }
    let _ = with_sysinfo(&info as *mut u8)
    _cpu_count = if info.cpu_cores > 0: info.cpu_cores else: 1
    _total_memory = if info.memory_total > 0: info.memory_total as usize else: 0usize
    _page_size = if info.page_size > 0: info.page_size as usize else: 4096usize
    _bandwidth = _measure_bandwidth()
    _cached = true

// ── Public API ──────────────────────────────────────────────────

/// Number of logical CPU cores (including hyperthreads).
pub fn cpu_count() -> i32:
    _ensure_init()
    _cpu_count

/// Total physical memory in bytes.
pub fn total_memory() -> usize:
    _ensure_init()
    _total_memory

/// OS page size in bytes (typically 4096 or 16384).
pub fn page_size() -> usize:
    _ensure_init()
    _page_size

/// Sustained sequential read bandwidth in GB/s, measured on this machine.
/// Returns 0.0 if no timer is available.
pub fn memory_bandwidth() -> f64:
    _ensure_init()
    _bandwidth

// ── Bandwidth measurement ───────────────────────────────────────

fn _measure_bandwidth() -> f64:
    let t0 = with_clock_nanos()
    if t0 == 0: return 0.0

    // 8MB: exceeds per-core last-level cache on all current hardware.
    let size: i64 = 8 * 1024 * 1024
    let buf = with_alloc(size)
    if buf as i64 == 0: return 0.0

    _write_pass(buf, size)
    _read_pass(buf, size)

    let start = with_clock_nanos()
    _read_pass(buf, size)
    let elapsed = with_clock_nanos() - start

    with_free(buf)

    if elapsed <= 0: return 0.0
    // bytes / nanosecond = GB/s
    (size as f64) / (elapsed as f64)

@[noinline]
fn _read_pass(buf: *mut u8, size: i64):
    var sink: i64 = 0
    var i: i64 = 0
    while i < size:
        sink = sink + unsafe *(buf + i) as i64
        i = i + 64
    // DoNotOptimize: "+r"(sink) makes sink both input and output of the
    // asm block. LLVM cannot eliminate the loop because the result feeds
    // into the asm in a way it can't see through.
    unsafe { asm volatile("" : sink("+r") :: "memory") }

@[noinline]
fn _write_pass(buf: *mut u8, size: i64):
    // Write varying values — prevents LLVM from constant-folding the
    // subsequent read pass.
    var i: i64 = 0
    while i < size:
        unsafe *(buf + i) = (i % 251) as u8
        i = i + 64
    unsafe { asm volatile("" ::: "memory") }
