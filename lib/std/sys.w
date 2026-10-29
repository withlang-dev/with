// std.sys — System information
//
// Machine characteristics: cores, memory, page size, bandwidth.
// Measured by the first call and cached for the process lifetime.
// No c_import — uses with_system_info and with_clock_nanos from the runtime.

use rt.rt_core
use std.sync

// ── Cached state ────────────────────────────────────────────────

type SysFacts:
    cpu_count: i32
    total_memory: usize
    page_size: usize
    bandwidth: f64

// The first caller measures under the lock, so first calls from several
// threads measure once and every caller reads the same facts (#985).
global _facts: Mutex[Option[SysFacts]] = Mutex.new(None)

fn facts() -> SysFacts:
    with _facts.enter_mut() as mut cached:
        if cached.is_none(): cached = Some(measure_facts())
        cached.unwrap()

fn measure_facts() -> SysFacts:
    let info = with_system_info()
    SysFacts {
        cpu_count: if info.cpu_cores > 0: info.cpu_cores else: 1,
        total_memory: if info.memory_total > 0: info.memory_total as usize else: 0usize,
        page_size: if info.page_size > 0: info.page_size as usize else: 4096usize,
        bandwidth: _measure_bandwidth(),
    }

// ── Public API ──────────────────────────────────────────────────

/// Number of logical CPU cores (including hyperthreads).
pub fn cpu_count() -> i32: facts().cpu_count

/// Total physical memory in bytes.
pub fn total_memory() -> usize: facts().total_memory

/// OS page size in bytes (typically 4096 or 16384).
pub fn page_size() -> usize: facts().page_size

/// Sustained sequential read bandwidth in GB/s, measured on this machine.
/// Returns 0.0 if no timer is available.
pub fn memory_bandwidth() -> f64: facts().bandwidth

// ── Bandwidth measurement ───────────────────────────────────────

fn _measure_bandwidth() -> f64:
    let t0 = with_clock_nanos()
    if t0 == 0: return 0.0

    // 8MB: exceeds per-core last-level cache on all current hardware.
    let size: i64 = 8 * 1024 * 1024
    let buf = with_alloc(size)
    if buf as i64 == 0: return 0.0

    unsafe { _write_pass(buf, size) }
    unsafe { _read_pass(buf, size) }

    let start = with_clock_nanos()
    unsafe { _read_pass(buf, size) }
    let elapsed = with_clock_nanos() - start

    with_free(buf)

    if elapsed <= 0: return 0.0
    // bytes / nanosecond = GB/s
    (size as f64) / (elapsed as f64)

@[noinline]
unsafe fn _read_pass(buf: *mut u8, size: i64):
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
unsafe fn _write_pass(buf: *mut u8, size: i64):
    // Write varying values — prevents LLVM from constant-folding the
    // subsequent read pass.
    var i: i64 = 0
    while i < size:
        unsafe *(buf + i) = (i % 251) as u8
        i = i + 64
    unsafe { asm volatile("" ::: "memory") }
