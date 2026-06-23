// rt/rt_core.w -- libc-free runtime for user programs, written in With
//
// Provides the same with_* symbols as rt_core.c,
// backed by rt_* calls instead of libc. Links only libSystem on macOS.
//
// Compiled with --no-prelude --emit-obj.
//
// The rt_* platform functions are provided by rt/darwin_aarch64.o (or similar).
// Float formatting is implemented inline below.

// ── rt_* platform interface (provided by darwin_aarch64.o) ─────────

extern fn rt_write(fd: i32, buf: *const u8, len: u64) -> i64
extern fn rt_read(fd: i32, buf: *mut u8, len: u64) -> i64
extern fn rt_open(path: *const u8, flags: i32, mode: i32) -> i32
extern fn rt_close(fd: i32) -> i32
extern fn rt_seek(fd: i32, offset: i64, whence: i32) -> i64
extern fn rt_mmap(size: u64) -> *mut u8
extern fn rt_munmap(ptr: *mut u8, size: u64)
extern fn rt_exit(code: i32)
extern fn rt_clock_ns() -> i64
extern fn rt_getenv(name: *const u8) -> *const u8
extern fn rt_store_args(argc: i32, argv: *const *const u8)

// Sleep + process + signal + sysinfo extras (provided by platform backend)
extern fn rt_nanosleep(ns: i64) -> i32
extern fn rt_getpid() -> i32
extern fn rt_raise(sig: i32) -> i32
extern fn rt_kill(pid: i32, sig: i32) -> i32
extern fn rt_sysinfo(out: *mut u8) -> i32
extern fn gethostname(name: *mut u8, len: u64) -> i32
extern fn rt_thread_spawn(start_routine: *mut u8, arg: *mut u8) -> i64
extern fn rt_thread_join(handle: i64) -> i32
extern fn rt_fill_random(buf: *mut u8, len: u64) -> Unit

// Filesystem extras (provided by platform backend)
extern fn rt_mkdir(path: *const u8, mode: i32) -> i32
extern fn rt_unlink(path: *const u8) -> i32
extern fn rt_rmdir(path: *const u8) -> i32
extern fn rt_rename(old_path: *const u8, new_path: *const u8) -> i32
extern fn rt_remove_tree(path: *const u8) -> i32
extern fn rt_copy_tree(src: *const u8, dst: *const u8) -> i32
extern fn rt_symlink(target: *const u8, link_path: *const u8) -> i32
extern fn rt_list_files(path: *const u8) -> str
extern fn rt_access(path: *const u8, mode: i32) -> i32
extern fn rt_chmod(path: *const u8, mode: i32) -> i32
extern fn rt_file_mode(path: *const u8) -> i32
extern fn rt_readlink(path: *const u8) -> str
// stat is in the core 13 but declared with a different name to avoid confusion
extern fn rt_stat(path: *const u8, out: *mut u8) -> i32

// ── Float formatting ────────────────────────────────────────────
// Implements deterministic f64-to-decimal conversion without libc.
// Locale-independent. NaN→"nan", inf→"inf"/"-inf".

fn f64_bits(v: f64) -> u64:
    unsafe *((&v as *const f64) as *const u64)

fn f64_exp_bits(bits: u64) -> u64:
    (bits >> 52) & 0x7ffu64

fn f64_frac_bits(bits: u64) -> u64:
    bits & 0x000fffffffffffffu64

fn f64_is_negative_bits(bits: u64) -> bool:
    (bits & 0x8000000000000000u64) != 0u64

fn f64_is_nan_bits(bits: u64) -> bool:
    f64_exp_bits(bits) == 0x7ffu64 and f64_frac_bits(bits) != 0u64

fn f64_is_inf_bits(bits: u64) -> bool:
    f64_exp_bits(bits) == 0x7ffu64 and f64_frac_bits(bits) == 0u64

fn rt_buf_put(buf: *mut u8, bufsize: i64, pos: i64, ch: u8) -> i64:
    if pos < bufsize:
        unsafe *((buf as i64 + pos) as *mut u8) = ch
    pos + 1

fn rt_buf_write_ascii(buf: *mut u8, bufsize: i64, pos_arg: i64, text: *const u8, len: i64) -> i64:
    var pos = pos_arg
    var i: i64 = 0
    while i < len:
        if pos < bufsize:
            unsafe *((buf as i64 + pos) as *mut u8) = unsafe text[i]
        pos = pos + 1
        i = i + 1
    pos

fn rt_pow10_u64(precision: i32) -> u64:
    var out: u64 = 1
    var i: i32 = 0
    while i < precision:
        out = out * 10u64
        i = i + 1
    out

fn rt_pow10_f64(precision: i32) -> f64:
    var out: f64 = 1.0
    var i: i32 = 0
    while i < precision:
        out = out * 10.0
        i = i + 1
    out

fn u64_decimal_digits(n_arg: u64) -> i32:
    var n = n_arg
    var digits: i32 = 1
    while n >= 10u64:
        n = n / 10u64
        digits = digits + 1
    digits

fn rt_f64_write_special(bits: u64, buf: *mut u8, bufsize: i64) -> i64:
    if f64_is_nan_bits(bits):
        return rt_buf_write_ascii(buf, bufsize, 0, "nan" as *const u8, 3)
    var pos: i64 = 0
    if f64_is_negative_bits(bits):
        pos = rt_buf_put(buf, bufsize, pos, 45)  // '-'
    rt_buf_write_ascii(buf, bufsize, pos, "inf" as *const u8, 3)

fn rt_f64_abs_value(val: f64, bits: u64) -> f64:
    if f64_is_negative_bits(bits):
        return 0.0 - val
    val

fn rt_f64_write_fixed_abs(val: f64, precision_arg: i32, trim: bool, buf: *mut u8, bufsize: i64, pos_arg: i64) -> i64:
    var precision = precision_arg
    if precision < 0:
        precision = 0
    if precision > 18:
        precision = 18
    var pos = pos_arg
    var int_part = val as u64
    var frac = val - (int_part as f64)
    if precision == 0:
        if frac >= 0.5:
            int_part = int_part + 1u64
        var ibuf: [24]u8 = [0 as u8; 24]
        let ilen = u64_to_buf_internal(int_part, &ibuf as *mut u8)
        return rt_buf_write_ascii(buf, bufsize, pos, &ibuf as *const u8, ilen)
    let scale_u = rt_pow10_u64(precision)
    let scale_f = rt_pow10_f64(precision)
    var frac_int = (frac * scale_f + 0.5) as u64
    if frac_int >= scale_u:
        int_part = int_part + 1u64
        frac_int = frac_int - scale_u
    var ibuf: [24]u8 = [0 as u8; 24]
    let ilen = u64_to_buf_internal(int_part, &ibuf as *mut u8)
    pos = rt_buf_write_ascii(buf, bufsize, pos, &ibuf as *const u8, ilen)
    pos = rt_buf_put(buf, bufsize, pos, 46)  // '.'
    let frac_start = pos
    var fdigits: [18]u8 = [0 as u8; 18]
    var fv = frac_int
    var fdi = precision - 1
    while fdi >= 0:
        fdigits[fdi as i64] = (48 + (fv % 10u64) as i32) as u8
        fv = fv / 10u64
        fdi = fdi - 1
    var fwi: i32 = 0
    while fwi < precision:
        pos = rt_buf_put(buf, bufsize, pos, fdigits[fwi as i64])
        fwi = fwi + 1
    if trim:
        while pos > frac_start and unsafe *((buf as i64 + pos - 1) as *const u8) == 48:
            pos = pos - 1
        if pos == frac_start:
            pos = pos - 1
    pos

fn rt_f64_write_exponent(exp: i32, buf: *mut u8, bufsize: i64, pos_arg: i64) -> i64:
    var pos = rt_buf_put(buf, bufsize, pos_arg, 101)  // 'e'
    var e = exp
    if e < 0:
        pos = rt_buf_put(buf, bufsize, pos, 45)
        e = 0 - e
    else:
        pos = rt_buf_put(buf, bufsize, pos, 43)
    if e < 10:
        pos = rt_buf_put(buf, bufsize, pos, 48)
        return rt_buf_put(buf, bufsize, pos, (48 + e) as u8)
    var eb: [8]u8 = [0 as u8; 8]
    let elen = u64_to_buf_internal(e as u64, &eb as *mut u8)
    rt_buf_write_ascii(buf, bufsize, pos, &eb as *const u8, elen)

fn rt_f64_write_scientific_abs(val: f64, precision: i32, trim: bool, buf: *mut u8, bufsize: i64, pos_arg: i64) -> i64:
    var scaled = val
    var exp: i32 = 0
    while scaled >= 10.0:
        scaled = scaled / 10.0
        exp = exp + 1
    while scaled < 1.0:
        scaled = scaled * 10.0
        exp = exp - 1
    var pos = rt_f64_write_fixed_abs(scaled, precision, trim, buf, bufsize, pos_arg)
    rt_f64_write_exponent(exp, buf, bufsize, pos)

// Format f64 to buffer in general display mode. Returns length.
fn rt_f64_to_buf(val: f64, buf: *mut u8, bufsize: i64) -> i64:
    let bits = f64_bits(val)
    if f64_is_nan_bits(bits) or f64_is_inf_bits(bits):
        return rt_f64_write_special(bits, buf, bufsize)
    var pos: i64 = 0
    if f64_is_negative_bits(bits):
        pos = rt_buf_put(buf, bufsize, pos, 45)
    let v = rt_f64_abs_value(val, bits)
    if v == 0.0:
        return rt_buf_put(buf, bufsize, pos, 48)
    if v >= 1000000000000000.0 or v < 0.000001:
        return rt_f64_write_scientific_abs(v, 14, true, buf, bufsize, pos)
    let int_digits = u64_decimal_digits(v as u64)
    var precision = 15 - int_digits
    if precision < 0:
        precision = 0
    if precision > 15:
        precision = 15
    rt_f64_write_fixed_abs(v, precision, true, buf, bufsize, pos)

// Format f64 with fixed precision. Returns length.
fn rt_f64_to_fixed_buf(val: f64, precision: i32, buf: *mut u8, bufsize: i64) -> i64:
    let bits = f64_bits(val)
    if f64_is_nan_bits(bits) or f64_is_inf_bits(bits):
        return rt_f64_write_special(bits, buf, bufsize)
    var pos: i64 = 0
    if f64_is_negative_bits(bits):
        pos = rt_buf_put(buf, bufsize, pos, 45)
    let v = rt_f64_abs_value(val, bits)
    rt_f64_write_fixed_abs(v, precision, false, buf, bufsize, pos)

// Format f64 with scientific notation and fixed fractional precision.
fn rt_f64_to_scientific_buf(val: f64, precision: i32, buf: *mut u8, bufsize: i64) -> i64:
    let bits = f64_bits(val)
    if f64_is_nan_bits(bits) or f64_is_inf_bits(bits):
        return rt_f64_write_special(bits, buf, bufsize)
    var pos: i64 = 0
    if f64_is_negative_bits(bits):
        pos = rt_buf_put(buf, bufsize, pos, 45)
    let v = rt_f64_abs_value(val, bits)
    if v == 0.0:
        pos = rt_f64_write_fixed_abs(0.0, precision, false, buf, bufsize, pos)
        return rt_f64_write_exponent(0, buf, bufsize, pos)
    rt_f64_write_scientific_abs(v, precision, false, buf, bufsize, pos)

// Internal helper for u64-to-decimal (used by float formatting)
fn u64_to_buf_internal(n: u64, buf: *mut u8) -> i64:
    var tmp: [21]u8 = [0 as u8; 21]
    let tp = &tmp as *mut u8
    var tpos: i64 = 20
    var val = n
    if val == 0:
        unsafe *((tp as i64 + tpos) as *mut u8) = 48  // '0'
        tpos = tpos - 1
    else:
        while val > 0:
            unsafe *((tp as i64 + tpos) as *mut u8) = (48 + (val % 10) as i32) as u8
            tpos = tpos - 1
            val = val / 10
    let len = 20 - tpos
    var i: i64 = 0
    while i < len:
        unsafe { *((buf as i64 + i) as *mut u8) = tp[tpos + 1 + i] }
        i = i + 1
    len

// ── String type helpers ────────────────────────────────────────────
//
// With's str is a value type with layout {*const u8, i64}.
// In --emit-obj / --no-prelude mode, str.ptr() is not available.
// We use pointer casts to extract/construct str values.

type RawStr:
    ptr: *const u8
    len: i64

fn str_data(s: str) -> *const u8:
    let p = &s as *const *const u8
    unsafe *p

fn str_length(s: str) -> i64:
    s.len()

fn make_str(ptr: *const u8, len: i64) -> str:
    let raw = RawStr { ptr: ptr, len: len }
    let p = &raw as *const str
    unsafe *p

fn cstr_len(s: *const u8) -> i64:
    if s as i64 == 0:
        return 0
    var n: i64 = 0
    while (unsafe s[n]) != 0:
        n = n + 1
    n

// ── Memory helpers ─────────────────────────────────────────────────

fn rt_memcpy(dst: *mut u8, src: *const u8, n: i64):
    var i: i64 = 0
    while i < n:
        unsafe { *((dst as i64 + i) as *mut u8) = src[i] }
        i = i + 1

fn rt_memcmp(a: *const u8, b: *const u8, n: i64) -> i32:
    var i: i64 = 0
    while i < n:
        let ca = unsafe a[i]
        let cb = unsafe b[i]
        if ca != cb:
            if (ca as i32) < (cb as i32):
                return -1
            return 1
        i = i + 1
    0

fn rt_memset(dst: *mut u8, c: u8, n: i64):
    var i: i64 = 0
    while i < n:
        unsafe *((dst as i64 + i) as *mut u8) = c
        i = i + 1

// ── Freelist allocator backed by rt_mmap/rt_munmap ─────────────────
//
// Small allocations (payload <= 4096): freelist with 9 size classes.
// Every allocation has a 16-byte header; the first word stores the aligned
// payload size for allocated blocks and doubles as the freelist next pointer
// while a small block is free.
// Large allocations (> 4096 payload bytes): direct rt_mmap with 16-byte header.
// All allocations are 16-byte aligned minimum.

let RT_PAGE_SIZE: i64 = 65536
let RT_LARGE_THRESHOLD: i64 = 4096
let RT_NUM_SIZE_CLASSES: i32 = 9
let RT_ALLOC_HEADER_SIZE: i64 = 16
let RT_ALLOC_RANGE_CAP: i32 = 8192

enum Order: i32:
    Relaxed = 0
    Acquire = 1
    Release = 2
    AcqRel = 3
    SeqCst = 4

type Atomic[T] {
    val: T,
}

type RtThreadClosureFn = fn(*mut u8) -> i32

type RtThreadClosureRaw {
    fn_ptr: *mut u8,
    ctx: *mut u8,
}

type RtThreadStart {
    handle: i64,
    fn_ptr: *mut u8,
    ctx: *mut u8,
    result: i32,
}

var rt_alloc_lock_word: Atomic[i32]

fn rt_allocator_lock():
    var spins = 0
    while rt_alloc_lock_word.swap(1, .Acquire) != 0:
        spins = spins + 1
        if spins >= 1024:
            let _ = rt_nanosleep(1000)
            spins = 0

fn rt_allocator_unlock():
    rt_alloc_lock_word.store(0, .Release)

// Freelist node: just a pointer to next
// We store this in the freed memory itself.
// freelists[i] is the head pointer for size class i.
var freelists_0: i64 = 0
var freelists_1: i64 = 0
var freelists_2: i64 = 0
var freelists_3: i64 = 0
var freelists_4: i64 = 0
var freelists_5: i64 = 0
var freelists_6: i64 = 0
var freelists_7: i64 = 0
var freelists_8: i64 = 0

// Current slab for carving small allocations
var slab_ptr: i64 = 0
var slab_remaining: i64 = 0

var rt_slab_range_starts: [8192]i64 = [0 as i64; 8192]
var rt_slab_range_ends: [8192]i64 = [0 as i64; 8192]
var rt_slab_range_count: i32 = 0
var rt_slab_ranges_complete: i32 = 1

var rt_large_range_starts: [8192]i64 = [0 as i64; 8192]
var rt_large_range_ends: [8192]i64 = [0 as i64; 8192]
var rt_large_range_count: i32 = 0
var rt_large_ranges_complete: i32 = 1

fn rt_record_slab_range(start: i64, size: i64):
    if rt_slab_range_count >= RT_ALLOC_RANGE_CAP:
        rt_slab_ranges_complete = 0
        return
    rt_slab_range_starts[rt_slab_range_count as i64] = start
    rt_slab_range_ends[rt_slab_range_count as i64] = start + size
    rt_slab_range_count = rt_slab_range_count + 1

fn rt_record_large_range(start: i64, size: i64):
    if rt_large_range_count >= RT_ALLOC_RANGE_CAP:
        rt_large_ranges_complete = 0
        return
    rt_large_range_starts[rt_large_range_count as i64] = start
    rt_large_range_ends[rt_large_range_count as i64] = start + size
    rt_large_range_count = rt_large_range_count + 1

fn rt_forget_large_range(start: i64):
    var i: i32 = 0
    while i < rt_large_range_count:
        if rt_large_range_starts[i as i64] == start:
            rt_large_range_count = rt_large_range_count - 1
            rt_large_range_starts[i as i64] = rt_large_range_starts[rt_large_range_count as i64]
            rt_large_range_ends[i as i64] = rt_large_range_ends[rt_large_range_count as i64]
            rt_large_range_starts[rt_large_range_count as i64] = 0
            rt_large_range_ends[rt_large_range_count as i64] = 0
            return
        i = i + 1

fn get_freelist(idx: i32) -> i64:
    if idx == 0: return freelists_0
    if idx == 1: return freelists_1
    if idx == 2: return freelists_2
    if idx == 3: return freelists_3
    if idx == 4: return freelists_4
    if idx == 5: return freelists_5
    if idx == 6: return freelists_6
    if idx == 7: return freelists_7
    return freelists_8

fn set_freelist(idx: i32, val: i64):
    if idx == 0: freelists_0 = val
    else if idx == 1: freelists_1 = val
    else if idx == 2: freelists_2 = val
    else if idx == 3: freelists_3 = val
    else if idx == 4: freelists_4 = val
    else if idx == 5: freelists_5 = val
    else if idx == 6: freelists_6 = val
    else if idx == 7: freelists_7 = val
    else: freelists_8 = val

fn size_class_index(size: i64) -> i32:
    if size <= 16: return 0
    if size <= 32: return 1
    if size <= 64: return 2
    if size <= 128: return 3
    if size <= 256: return 4
    if size <= 512: return 5
    if size <= 1024: return 6
    if size <= 2048: return 7
    8

fn size_class_size(idx: i32) -> i64:
    if idx == 0: return 16
    if idx == 1: return 32
    if idx == 2: return 64
    if idx == 3: return 128
    if idx == 4: return 256
    if idx == 5: return 512
    if idx == 6: return 1024
    if idx == 7: return 2048
    4096

fn alloc_align_size(size_arg: i64) -> i64:
    var size = size_arg
    if size <= 0:
        size = 1
    (size + 15) & (-16)

fn size_class_block_size(idx: i32) -> i64:
    size_class_size(idx) + RT_ALLOC_HEADER_SIZE

fn alloc_header_ptr(ptr: *const u8) -> *mut u8:
    (ptr as i64 - RT_ALLOC_HEADER_SIZE) as *mut u8

fn alloc_payload_size(ptr: *const u8) -> i64:
    unsafe *(alloc_header_ptr(ptr) as *const i64)

fn alloc_store_small_header(block: i64, size: i64):
    unsafe *(block as *mut i64) = size

fn small_block_ptr(block: i64) -> *mut u8:
    (block + RT_ALLOC_HEADER_SIZE) as *mut u8

fn rt_payload_start_is_owned(ptr: *const u8) -> i32:
    if ptr as i64 == 0:
        return 0
    let payload = ptr as i64
    let header = payload - RT_ALLOC_HEADER_SIZE
    for i in 0..rt_slab_range_count:
        let start = rt_slab_range_starts[i as i64]
        let end = rt_slab_range_ends[i as i64]
        if header >= start and header + RT_ALLOC_HEADER_SIZE <= end:
            let size = unsafe *(header as *const i64)
            if size <= 0 or size > RT_LARGE_THRESHOLD:
                return 0
            let idx = size_class_index(size)
            let cls_size = size_class_size(idx)
            if size != cls_size:
                return 0
            let block_size = RT_ALLOC_HEADER_SIZE + size
            if header + block_size > end:
                return 0
            return 1
    for i in 0..rt_large_range_count:
        let start = rt_large_range_starts[i as i64]
        let end = rt_large_range_ends[i as i64]
        if header == start and payload < end:
            return 1
    0

fn rt_payload_start_can_be_owned(ptr: *const u8) -> i32:
    if rt_payload_start_is_owned(ptr) != 0:
        return 1
    if rt_slab_ranges_complete == 0 or rt_large_ranges_complete == 0:
        return 1
    0

fn free_small_block(block: i64, idx: i32):
    let old_head = get_freelist(idx)
    unsafe *(block as *mut i64) = old_head
    set_freelist(idx, block)

// ── Debug allocator (issue #606 instrument) ────────────────────────
// A pure-With memory-error ledger gated at runtime by --debug-alloc /
// WITH_DEBUG_ALLOC. It does DETECTION only: per-payload-address tracking that
// aborts loudly on a double-free and lists un-freed blocks at exit. Source SITES
// (which alloc/free call) are resolved out-of-process by the harness via lldb
// conditioned on the address reported here — With codegen does not maintain a
// walkable frame-pointer chain, so in-process backtraces are not used.
// All ledger ops run under the allocator lock (called from rt_alloc/rt_free).
let DBG_CAP: i64 = 65536            // hash slots (power of two)
let DBG_ENTRY_WORDS: i64 = 4        // addr, size, freed, reserved

var dbg_state: i32 = 0              // 0=unread, 1=off, 2=on (cached, read once)
var dbg_scribble_state: i32 = 0    // 0=unread, 1=off, 2=on (cached, read once)
var dbg_base: i64 = 0              // mmap'd ledger table, 0 = uninitialised
var dbg_full_warned: i32 = 0

fn dbg_on() -> i32:
    if dbg_state == 0:
        let v = rt_getenv(c"WITH_DEBUG_ALLOC".ptr)
        if v as i64 != 0 and (unsafe *v) != 0:
            dbg_state = 2
        else:
            dbg_state = 1
    if dbg_state == 2:
        return 1
    0

// Scribble-on-free (use-after-free poisoning) is opt-in via WITH_DEBUG_ALLOC_SCRIBBLE.
// It is OFF by default because, for a Vec[Drop] buffer, poisoning the freed payload
// turns a subsequent double-drop's element read into a use-after-free crash *before*
// the ledger reports the buffer's double-free — so it would mask the clean
// double-free verdict. Turn it on to hunt use-after-free specifically.
fn dbg_scribble_on() -> i32:
    if dbg_scribble_state == 0:
        let v = rt_getenv(c"WITH_DEBUG_ALLOC_SCRIBBLE".ptr)
        if v as i64 != 0 and (unsafe *v) != 0:
            dbg_scribble_state = 2
        else:
            dbg_scribble_state = 1
    if dbg_scribble_state == 2:
        return 1
    0

fn dbg_puts(s: *const u8, n: i64):
    let _ = rt_write(2, s, n as u64)

fn dbg_put_i64(v: i64):
    var buf: [24]u8 = [0 as u8; 24]
    let len = i64_to_buf(v, &buf as *mut u8)
    let _ = rt_write(2, &buf as *const u8, len as u64)

fn dbg_ledger_init():
    if dbg_base != 0:
        return
    let bytes = DBG_CAP * DBG_ENTRY_WORDS * 8
    let p = rt_mmap(bytes as u64)
    if p as i64 == 0:
        dbg_state = 1                // mmap failed: disable rather than crash
        return
    dbg_base = p as i64             // MAP_ANON is zero-filled; no memset needed

fn dbg_entry_addr(slot: i64) -> i64:
    dbg_base + slot * DBG_ENTRY_WORDS * 8

// Record (or reset, on address reuse) a live allocation.
fn dbg_record_alloc(addr: i64, size: i64):
    if dbg_base == 0:
        dbg_ledger_init()
    if dbg_base == 0:
        return
    var slot = (addr >> 4) & (DBG_CAP - 1)
    var probes: i64 = 0
    while probes < DBG_CAP:
        let e = dbg_entry_addr(slot)
        let a = unsafe *(e as *const i64)
        if a == 0 or a == addr:
            unsafe *(e as *mut i64) = addr
            unsafe *((e + 8) as *mut i64) = size
            unsafe *((e + 16) as *mut i64) = 0      // freed flag clear (reuse-safe)
            return
        slot = (slot + 1) & (DBG_CAP - 1)
        probes = probes + 1
    if dbg_full_warned == 0:
        dbg_full_warned = 1
        dbg_puts("debug-alloc: ledger full, tracking truncated\n" as *const u8, 45)

// Mark a free. Returns 1 if this is a double free (already freed, not reused).
fn dbg_mark_free(addr: i64) -> i32:
    if dbg_base == 0:
        return 0
    var slot = (addr >> 4) & (DBG_CAP - 1)
    var probes: i64 = 0
    while probes < DBG_CAP:
        let e = dbg_entry_addr(slot)
        let a = unsafe *(e as *const i64)
        if a == 0:
            return 0                 // untracked address
        if a == addr:
            let freed = unsafe *((e + 16) as *const i64)
            if freed != 0:
                return 1
            unsafe *((e + 16) as *mut i64) = 1
            return 0
        slot = (slot + 1) & (DBG_CAP - 1)
        probes = probes + 1
    0

// Authoritative payload size from the ledger (the freed header word is reused as
// the freelist link, so it can't be trusted on a double-free).
fn dbg_ledger_size(addr: i64) -> i64:
    if dbg_base == 0:
        return 0
    var slot = (addr >> 4) & (DBG_CAP - 1)
    var probes: i64 = 0
    while probes < DBG_CAP:
        let e = dbg_entry_addr(slot)
        let a = unsafe *(e as *const i64)
        if a == 0:
            return 0
        if a == addr:
            return unsafe *((e + 8) as *const i64)
        slot = (slot + 1) & (DBG_CAP - 1)
        probes = probes + 1
    0

fn dbg_report_double_free(addr: i64, size: i64):
    dbg_puts("debug-alloc: DOUBLE FREE addr=" as *const u8, 30)
    dbg_put_i64(addr)
    dbg_puts(" size=" as *const u8, 6)
    dbg_put_i64(size)
    dbg_puts("\n" as *const u8, 1)
    rt_exit(134)

// Poison a freed small-block payload so use-after-free reads corrupt loudly.
// The freelist link lives in the header word (payload-16), untouched here.
fn dbg_scribble(ptr: i64, size: i64):
    var i: i64 = 0
    while i < size:
        unsafe *((ptr + i) as *mut u8) = 0xDE as u8
        i = i + 1

// Called from with_runtime_shutdown on normal program exit.
pub fn with_debug_alloc_report_leaks() -> Unit:
    if dbg_on() == 0:
        return
    if dbg_base == 0:
        return
    var slot: i64 = 0
    var leaks: i64 = 0
    while slot < DBG_CAP:
        let e = dbg_entry_addr(slot)
        let a = unsafe *(e as *const i64)
        if a != 0:
            let freed = unsafe *((e + 16) as *const i64)
            if freed == 0:
                let size = unsafe *((e + 8) as *const i64)
                dbg_puts("debug-alloc: LEAK addr=" as *const u8, 23)
                dbg_put_i64(a)
                dbg_puts(" size=" as *const u8, 6)
                dbg_put_i64(size)
                dbg_puts("\n" as *const u8, 1)
                leaks = leaks + 1
        slot = slot + 1
    dbg_puts("debug-alloc: leak count=" as *const u8, 24)
    dbg_put_i64(leaks)
    dbg_puts("\n" as *const u8, 1)

fn rt_alloc_unlocked(size_arg: i64) -> *mut u8:
    let size = alloc_align_size(size_arg)

    if size > RT_LARGE_THRESHOLD:
        // Large allocation: direct rt_mmap with 16-byte header storing size
        let total = size + RT_ALLOC_HEADER_SIZE
        let p = rt_mmap(total as u64)
        if p as i64 == 0:
            rt_exit(99)
        // Store allocation size in header
        unsafe *(p as *mut i64) = size
        rt_record_large_range(p as i64, total)
        return (p as i64 + RT_ALLOC_HEADER_SIZE) as *mut u8

    // Small allocation: check freelist keyed by payload size class.
    let idx = size_class_index(size)
    let cls_size = size_class_size(idx)
    let block_size = size_class_block_size(idx)

    let head = get_freelist(idx)
    if head != 0:
        // Pop from freelist. Zero the payload — recycled memory is dirty.
        let next = unsafe *(head as *const i64)
        set_freelist(idx, next)
        alloc_store_small_header(head, cls_size)
        let ptr = small_block_ptr(head)
        rt_memset(ptr, 0, size)
        return ptr

    // Carve from slab
    if slab_remaining < block_size:
        let new_slab = rt_mmap(RT_PAGE_SIZE as u64)
        if new_slab as i64 == 0:
            rt_exit(99)
        slab_ptr = new_slab as i64
        slab_remaining = RT_PAGE_SIZE
        rt_record_slab_range(slab_ptr, RT_PAGE_SIZE)

    let block = slab_ptr
    slab_ptr = slab_ptr + block_size
    slab_remaining = slab_remaining - block_size
    alloc_store_small_header(block, cls_size)
    small_block_ptr(block)

fn rt_alloc(size_arg: i64) -> *mut u8:
    rt_allocator_lock()
    let ptr = rt_alloc_unlocked(size_arg)
    if dbg_on() != 0 and ptr as i64 != 0:
        dbg_record_alloc(ptr as i64, alloc_payload_size(ptr as *const u8))
    rt_allocator_unlock()
    if rt_payload_start_can_be_owned(ptr as *const u8) == 0:
        with_panic_core(make_str("allocator returned invalid payload" as *const u8, 34), make_str("" as *const u8, 0), 0)
    ptr

fn rt_free_unlocked(ptr: *mut u8):
    if ptr as i64 == 0:
        return
    // #606 debug allocator: detect double-free before the generic ownership
    // panic so the report names the address; poison freed small payloads.
    if dbg_on() != 0:
        if dbg_mark_free(ptr as i64) != 0:
            dbg_report_double_free(ptr as i64, dbg_ledger_size(ptr as i64))
        if dbg_scribble_on() != 0:
            let dbg_size = alloc_payload_size(ptr as *const u8)
            if dbg_size <= RT_LARGE_THRESHOLD:
                dbg_scribble(ptr as i64, dbg_size)
    if rt_payload_start_can_be_owned(ptr as *const u8) == 0:
        with_panic_core(make_str("invalid free: pointer is not an allocated payload start" as *const u8, 55), make_str("" as *const u8, 0), 0)
    let block = alloc_header_ptr(ptr as *const u8) as i64
    let size = unsafe *(block as *const i64)
    if size > RT_LARGE_THRESHOLD:
        rt_forget_large_range(block)
        rt_munmap(block as *mut u8, (size + RT_ALLOC_HEADER_SIZE) as u64)
        return
    let idx = size_class_index(size)
    free_small_block(block, idx)

fn rt_free(ptr: *mut u8):
    rt_allocator_lock()
    rt_free_unlocked(ptr)
    rt_allocator_unlock()

fn rt_free_sized(ptr: *mut u8, size_arg: i64):
    let _ = size_arg
    rt_free(ptr)

fn rt_thread_entry(arg: *mut u8) -> *mut u8:
    let start = arg as *mut RtThreadStart
    let raw = RtThreadClosureRaw { fn_ptr: (unsafe *start).fn_ptr, ctx: (unsafe *start).ctx }
    let worker: RtThreadClosureFn = unsafe transmute[RtThreadClosureFn](raw)
    (unsafe *start).result = worker(0 as *mut u8)
    arg

pub fn with_thread_spawn(fn_ptr: *mut u8, ctx: *mut u8) -> i64:
    if fn_ptr as i64 == 0:
        return -1
    let start = rt_alloc(sizeof[RtThreadStart]()) as *mut RtThreadStart
    (unsafe *start).handle = 0
    (unsafe *start).fn_ptr = fn_ptr
    (unsafe *start).ctx = ctx
    (unsafe *start).result = 0
    let handle = rt_thread_spawn(rt_thread_entry as *mut u8, start as *mut u8)
    if handle < 0:
        rt_free(start as *mut u8)
        return handle
    (unsafe *start).handle = handle
    start as i64

pub fn with_thread_join(handle: i64) -> i32:
    if handle == 0:
        return -1
    if handle < 0:
        return handle as i32
    let start = handle as *mut RtThreadStart
    let rc = rt_thread_join((unsafe *start).handle)
    if rc != 0:
        return rc
    let result = (unsafe *start).result
    rt_free(start as *mut u8)
    result

fn rt_realloc(ptr: *mut u8, old_size: i64, new_size: i64) -> *mut u8:
    if ptr as i64 == 0:
        return rt_alloc(new_size)
    if new_size <= 0:
        let _ = old_size
        rt_free(ptr)
        return 0 as *mut u8

    let stored_old_size = alloc_payload_size(ptr as *const u8)
    let new_aligned = alloc_align_size(new_size)

    // If both are in the same size class, no-op
    if stored_old_size <= RT_LARGE_THRESHOLD and new_aligned <= RT_LARGE_THRESHOLD:
        let old_idx = size_class_index(stored_old_size)
        let new_idx = size_class_index(new_aligned)
        if old_idx == new_idx:
            return ptr

    let new_ptr = rt_alloc(new_size)
    var copy_old_size = stored_old_size
    if old_size > 0 and old_size < copy_old_size:
        copy_old_size = old_size
    let copy_size = if copy_old_size < new_size: copy_old_size else: new_size
    rt_memcpy(new_ptr, ptr as *const u8, copy_size)
    rt_free(ptr)
    new_ptr

// Null-terminate a str for syscalls
fn str_has_interior_nul(s: str) -> bool:
    let p = str_data(s)
    let n = str_length(s)
    if p as i64 == 0:
        return false
    var i: i64 = 0
    while i < n:
        if (unsafe p[i]) == 0:
            return true
        i = i + 1
    false

// Safe call-scoped str -> C-string conversion. A `str` may carry interior NUL
// bytes (§16.3c), which C would silently truncate at; that is forbidden, so the
// conversion fails loudly instead of producing a poisoned C string. Raw interop
// (`str_data(s) as *const c_char`) is unaffected and stays explicit/unsafe.
fn str_to_cstr(s: str) -> *const u8:
    if str_has_interior_nul(s):
        let empty = make_str("" as *const u8, 0)
        with_panic_core("str to C string conversion: interior NUL byte", empty, 0)
    let slen = str_length(s)
    let buf = rt_alloc(slen + 1)
    rt_memcpy(buf, str_data(s), slen)
    unsafe *((buf as i64 + slen) as *mut u8) = 0
    buf as *const u8

pub fn with_str_to_cstr(s: str) -> *mut u8:
    str_to_cstr(s) as *mut u8

// ── Exported allocator/memory API for std/mem.w ───────────────────

pub fn with_alloc(size: i64) -> *mut u8:
    rt_alloc(size)

pub fn with_alloc_zeroed(count: i64, size: i64) -> *mut u8:
    let total = count * size
    let ptr = rt_alloc(total)
    if ptr as i64 != 0 and total > 0:
        rt_memset(ptr, 0, total)
    ptr

pub fn with_realloc(ptr: *mut u8, old_size: i64, new_size: i64) -> *mut u8:
    rt_realloc(ptr, old_size, new_size)

pub fn with_free(ptr: *mut u8) -> Unit:
    rt_free(ptr)

pub fn with_free_sized(ptr: *mut u8, size: i64) -> Unit:
    rt_free_sized(ptr, size)

pub fn with_memcpy(dst: *mut u8, src: *const u8, n: i64) -> *mut u8:
    rt_memcpy(dst, src, n)
    return dst

pub fn with_memmove(dst: *mut u8, src: *const u8, n: i64) -> *mut u8:
    // Simple: copy to temp buffer then to dst (handles overlap)
    if n <= 0: return dst
    let tmp = rt_alloc(n)
    rt_memcpy(tmp, src, n)
    rt_memcpy(dst, tmp as *const u8, n)
    rt_free_sized(tmp, n)
    return dst

pub fn with_memset(dst: *mut u8, c: i32, n: i64) -> *mut u8:
    rt_memset(dst, c as u8, n)
    return dst

pub fn with_memcmp(a: *const u8, b: *const u8, n: i64) -> i32:
    rt_memcmp(a, b, n)

// Allocate a new str from a buffer
fn alloc_str(buf: *const u8, len: i64) -> str:
    let out = rt_alloc(len + 1)
    rt_memcpy(out, buf, len)
    unsafe *((out as i64 + len) as *mut u8) = 0
    make_str(out as *const u8, len)

// ── I/O helpers ────────────────────────────────────────────────────

fn write_all(fd: i32, buf: *const u8, len: i64):
    var written: i64 = 0
    while written < len:
        let r = rt_write(fd, (buf as i64 + written) as *const u8, (len - written) as u64)
        if r <= 0:
            break
        written = written + r

// ── Lifecycle ──────────────────────────────────────────────────────

var saved_argc: i32 = 0
var saved_argv_raw: i64 = 0

pub fn with_runtime_set_argv(argc: i32, argv: *const *const u8) -> Unit:
    saved_argc = argc
    saved_argv_raw = argv as i64
    rt_store_args(argc, argv)

// with_runtime_init, with_runtime_run, with_runtime_shutdown come from the
// small runtime stub object when async is absent, or from fiber.c when the
// fiber runtime is linked. rt_core.w does not provide them directly.

// ── Print functions ────────────────────────────────────────────────

pub fn with_print_str(s: str) -> Unit:
    let p = str_data(s)
    let n = str_length(s)
    if p as i64 != 0 and n > 0:
        write_all(1, p, n)

pub fn with_println_str(s: str) -> Unit:
    let p = str_data(s)
    let n = str_length(s)
    if p as i64 != 0 and n > 0:
        write_all(1, p, n)
    let _ = rt_write(1, "\n" as *const u8, 1)

pub fn with_println_i32(n: i32) -> Unit:
    var buf: [16]u8 = [0 as u8; 16]
    let len = i64_to_buf(n as i64, &buf as *mut u8)
    write_all(1, &buf as *const u8, len)
    let _ = rt_write(1, "\n" as *const u8, 1)

pub fn with_println_i64(n: i64) -> Unit:
    var buf: [24]u8 = [0 as u8; 24]
    let len = i64_to_buf(n, &buf as *mut u8)
    write_all(1, &buf as *const u8, len)
    let _ = rt_write(1, "\n" as *const u8, 1)

pub fn with_println_bool(b: i32) -> Unit:
    if b != 0:
        write_all(1, "true\n" as *const u8, 5)
    else:
        write_all(1, "false\n" as *const u8, 6)

pub fn with_write(s: str) -> Unit:
    with_print_str(s)

pub fn with_ewrite(s: str) -> Unit:
    let p = str_data(s)
    let n = str_length(s)
    if p as i64 != 0 and n > 0:
        write_all(2, p, n)

pub fn with_eprintln(s: str) -> Unit:
    let p = str_data(s)
    let n = str_length(s)
    if p as i64 != 0 and n > 0:
        write_all(2, p, n)
    let _ = rt_write(2, "\n" as *const u8, 1)

pub fn with_eprint(s: str) -> Unit:
    with_eprintln(s)

// ── Panic / assert ─────────────────────────────────────────────────

pub fn with_panic_core(msg: str, file: str, line: i32) -> Unit:
    write_all(2, "panic: " as *const u8, 7)
    let mp = str_data(msg)
    let ml = str_length(msg)
    if mp as i64 != 0 and ml > 0:
        write_all(2, mp, ml)
    let fp = str_data(file)
    let fl = str_length(file)
    if fp as i64 != 0 and fl > 0:
        write_all(2, " at " as *const u8, 4)
        write_all(2, fp, fl)
        if line > 0:
            write_all(2, ":" as *const u8, 1)
            var buf: [16]u8 = [0 as u8; 16]
            let len = i64_to_buf(line as i64, &buf as *mut u8)
            write_all(2, &buf as *const u8, len)
    let _ = rt_write(2, "\n" as *const u8, 1)
    rt_exit(1)

pub fn with_assert(cond: i32, msg: str) -> Unit:
    if cond == 0:
        let empty = make_str("" as *const u8, 0)
        with_panic_core(msg, empty, 0)

// ── Integer formatting ─────────────────────────────────────────────

// Write signed i64 to buf, return length. buf must be >= 21 bytes.
fn i64_to_buf(n: i64, buf: *mut u8) -> i64:
    var tmp: [21]u8 = [0 as u8; 21]
    var pos: i32 = 20
    var neg: i32 = 0
    var un: u64 = 0
    if n < 0:
        neg = 1
        // un = (uint64_t)(-(n + 1)) + 1
        un = ((0 - (n + 1)) as u64) + 1
    else:
        un = n as u64
    if un == 0:
        tmp[pos] = 48  // '0'
        pos = pos - 1
    else:
        while un > 0:
            tmp[pos] = (48 + (un % 10) as u8) as u8
            un = un / 10
            pos = pos - 1
    if neg != 0:
        tmp[pos] = 45  // '-'
        pos = pos - 1
    let len = 20 - pos as i64
    rt_memcpy(buf, (&tmp as i64 + (pos + 1) as i64) as *const u8, len)
    len

// Write unsigned u64 to buf, return length.
fn u64_to_buf(n_arg: u64, buf: *mut u8) -> i64:
    var tmp: [21]u8 = [0 as u8; 21]
    var pos: i32 = 20
    var n = n_arg
    if n == 0:
        tmp[pos] = 48
        pos = pos - 1
    else:
        while n > 0:
            tmp[pos] = (48 + (n % 10) as u8) as u8
            n = n / 10
            pos = pos - 1
    let len = 20 - pos as i64
    rt_memcpy(buf, (&tmp as i64 + (pos + 1) as i64) as *const u8, len)
    len

// Write u64 in given base to buf.
fn u64_base_to_buf(n_arg: u64, base: i32, uppercase: i32, buf: *mut u8) -> i64:
    let lower = "0123456789abcdef" as *const u8
    let upper = "0123456789ABCDEF" as *const u8
    let digits = if uppercase != 0: upper else: lower
    var tmp: [66]u8 = [0 as u8; 66]
    var pos: i32 = 65
    var n = n_arg
    if n == 0:
        tmp[pos] = 48
        pos = pos - 1
    else:
        while n > 0:
            let digit_idx = (n % (base as u64)) as i64
            tmp[pos] = unsafe digits[digit_idx]
            n = n / (base as u64)
            pos = pos - 1
    let len = 65 - pos as i64
    rt_memcpy(buf, (&tmp as i64 + (pos + 1) as i64) as *const u8, len)
    len

// ── with_fmt_* functions ───────────────────────────────────────────

pub fn with_fmt_i32(n: i32) -> str:
    var buf: [16]u8 = [0 as u8; 16]
    let len = i64_to_buf(n as i64, &buf as *mut u8)
    alloc_str(&buf as *const u8, len)

pub fn with_fmt_i64(n: i64) -> str:
    var buf: [24]u8 = [0 as u8; 24]
    let len = i64_to_buf(n, &buf as *mut u8)
    alloc_str(&buf as *const u8, len)

pub fn with_fmt_u32(n: u32) -> str:
    var buf: [16]u8 = [0 as u8; 16]
    let len = u64_to_buf(n as u64, &buf as *mut u8)
    alloc_str(&buf as *const u8, len)

pub fn with_fmt_u64(n: u64) -> str:
    var buf: [24]u8 = [0 as u8; 24]
    let len = u64_to_buf(n, &buf as *mut u8)
    alloc_str(&buf as *const u8, len)

pub fn with_fmt_bool(b: i32) -> str:
    if b != 0:
        return make_str("true" as *const u8, 4)
    make_str("false" as *const u8, 5)

pub fn with_fmt_str(s: str) -> str:
    s

pub fn with_fmt_str_debug(s: str) -> str:
    let slen = str_length(s)
    let out_len = slen + 2
    let out = rt_alloc(out_len + 1)
    unsafe *(out as *mut u8) = 34  // '"'
    let sp = str_data(s)
    if sp as i64 != 0 and slen > 0:
        rt_memcpy((out as i64 + 1) as *mut u8, sp, slen)
    unsafe *((out as i64 + slen + 1) as *mut u8) = 34  // '"'
    unsafe *((out as i64 + out_len) as *mut u8) = 0
    make_str(out as *const u8, out_len)

// ── Float formatting ───────────────────────────────────────────────

pub fn with_fmt_f64(n: f64) -> str:
    var buf: [64]u8 = [0 as u8; 64]
    let len = rt_f64_to_buf(n, &buf as *mut u8, 64)
    alloc_str(&buf as *const u8, len)

pub fn with_f64_to_string(n: f64) -> str:
    with_fmt_f64(n)

// ── FmtBuffer (f-string formatting via buffer) ────────────────────
//
// FmtBuffer layout: { ptr: *mut u8, len: i64, cap: i64 }
// Stored as 24 bytes allocated on the heap.

let FMT_BUF_SIZE: i64 = 24
let FMT_BUF_OFF_PTR: i64 = 0
let FMT_BUF_OFF_LEN: i64 = 8
let FMT_BUF_OFF_CAP: i64 = 16

fn fb_ptr(b: *mut u8) -> *mut u8:
    unsafe *(b as *const *mut u8)
fn fb_len(b: *mut u8) -> i64:
    unsafe *((b as i64 + FMT_BUF_OFF_LEN) as *const i64)
fn fb_cap(b: *mut u8) -> i64:
    unsafe *((b as i64 + FMT_BUF_OFF_CAP) as *const i64)
fn fb_set_ptr(b: *mut u8, v: *mut u8):
    unsafe *(b as *mut *mut u8) = v
fn fb_set_len(b: *mut u8, v: i64):
    unsafe *((b as i64 + FMT_BUF_OFF_LEN) as *mut i64) = v
fn fb_set_cap(b: *mut u8, v: i64):
    unsafe *((b as i64 + FMT_BUF_OFF_CAP) as *mut i64) = v

fn fb_grow(b: *mut u8, needed: i64):
    let cur_len = fb_len(b)
    let cur_cap = fb_cap(b)
    if cur_len + needed <= cur_cap: return
    var new_cap = cur_cap * 2
    if new_cap < cur_len + needed:
        new_cap = cur_len + needed
    let new_ptr = rt_alloc(new_cap)
    let old_ptr = fb_ptr(b)
    if old_ptr as i64 != 0 and cur_len > 0:
        rt_memcpy(new_ptr, old_ptr as *const u8, cur_len)
    if old_ptr as i64 != 0 and cur_cap > 0:
        rt_free_sized(old_ptr, cur_cap)
    fb_set_ptr(b, new_ptr)
    fb_set_cap(b, new_cap)

fn fb_append(b: *mut u8, data: *const u8, len: i64):
    fb_grow(b, len)
    let p = fb_ptr(b)
    let cur = fb_len(b)
    rt_memcpy((p as i64 + cur) as *mut u8, data, len)
    fb_set_len(b, cur + len)

pub fn with_fmt_buf_new() -> *mut u8:
    let b = rt_alloc(FMT_BUF_SIZE)
    fb_set_ptr(b, rt_alloc(64))
    fb_set_len(b, 0)
    fb_set_cap(b, 64)
    b

pub fn with_fmt_buf_write_str(b: *mut u8, s: str) -> Unit:
    let slen = str_length(s)
    if slen > 0:
        fb_append(b, str_data(s), slen)

pub fn with_fmt_buf_write_i64(b: *mut u8, val: i64) -> Unit:
    var tmp: [24]u8 = [0 as u8; 24]
    let len = i64_to_buf(val, &tmp as *mut u8)
    fb_append(b, &tmp as *const u8, len)

pub fn with_fmt_buf_write_f64(b: *mut u8, val: f64) -> Unit:
    var tmp: [64]u8 = [0 as u8; 64]
    let len = rt_f64_to_buf(val, &tmp as *mut u8, 64)
    fb_append(b, &tmp as *const u8, len)

pub fn with_fmt_buf_write_bool(b: *mut u8, val: i32) -> Unit:
    if val != 0:
        fb_append(b, "true" as *const u8, 4)
    else:
        fb_append(b, "false" as *const u8, 5)

pub fn with_fmt_buf_write_char(b: *mut u8, c: u8) -> Unit:
    fb_grow(b, 1)
    let p = fb_ptr(b)
    let cur = fb_len(b)
    unsafe *((p as i64 + cur) as *mut u8) = c
    fb_set_len(b, cur + 1)

pub fn with_fmt_buf_write_i64_spec(b: *mut u8, val: i64, is_unsigned: i32, flags: i64, width: i32, precision: i32, mode: i32) -> Unit:
    let s = with_fmt_int_spec(val, is_unsigned, flags, width, precision, mode)
    with_fmt_buf_write_str(b, s)

pub fn with_fmt_buf_write_f64_spec(b: *mut u8, val: f64, flags: i64, width: i32, precision: i32, mode: i32) -> Unit:
    let s = with_fmt_f64_spec(val, flags, width, precision, mode)
    with_fmt_buf_write_str(b, s)

pub fn with_fmt_buf_write_str_spec(b: *mut u8, val: str, flags: i64, width: i32, precision: i32) -> Unit:
    let s = with_fmt_str_spec(val, flags, width, precision)
    with_fmt_buf_write_str(b, s)

pub fn with_fmt_buf_write_debug(b: *mut u8, val: str) -> Unit:
    let s = with_fmt_str_debug(val)
    with_fmt_buf_write_str(b, s)

pub fn with_fmt_buf_finish(b: *mut u8) -> str:
    let p = fb_ptr(b)
    let len = fb_len(b)
    // Null-terminate
    fb_grow(b, 1)
    let fp = fb_ptr(b)  // may have moved after grow
    unsafe *((fp as i64 + len) as *mut u8) = 0
    // Return as str (takes ownership of buffer memory)
    let result = make_str(fp as *const u8, len)
    // Free the FmtBuffer header (but not the data — it's now owned by the str)
    rt_free_sized(b, FMT_BUF_SIZE)
    result

// ── Pad string helper ──────────────────────────────────────────────

fn pad_str(content: *const u8, clen: i64, width: i64, fill_char: i32, align_mode: i32) -> str:
    if clen >= width:
        return alloc_str(content, clen)
    let pad = width - clen
    let out = rt_alloc(width + 1)
    let fc: u8 = if fill_char != 0: fill_char as u8 else: 32  // ' '
    if align_mode == 1:
        // left align
        rt_memcpy(out, content, clen)
        rt_memset((out as i64 + clen) as *mut u8, fc, pad)
    else if align_mode == 3:
        // center
        let left = pad / 2
        let right = pad - left
        rt_memset(out, fc, left)
        rt_memcpy((out as i64 + left) as *mut u8, content, clen)
        rt_memset((out as i64 + left + clen) as *mut u8, fc, right)
    else:
        // right align (default)
        rt_memset(out, fc, pad)
        rt_memcpy((out as i64 + pad) as *mut u8, content, clen)
    unsafe *((out as i64 + width) as *mut u8) = 0
    make_str(out as *const u8, width)

// ── with_fmt_int_spec ──────────────────────────────────────────────

pub fn with_fmt_int_spec(val_arg: i64, is_unsigned: i32, flags: i64, width: i32, precision: i32, mode: i32) -> str:
    let _ = precision
    let fill_char = ((flags >> 8) & 255) as i32
    let align_mode = ((flags >> 16) & 3) as i32
    let sign_plus = ((flags >> 18) & 1) as i32
    let alternate_form = ((flags >> 19) & 1) as i32
    let zero_pad = ((flags >> 20) & 1) as i32

    var buf: [80]u8 = [0 as u8; 80]
    var len: i64 = 0
    var val = val_arg

    // Mode is ASCII char: 'd'=100, 'x'=120, 'X'=88, 'b'=98, 'o'=111
    var base: i32 = 10
    if mode == 120 or mode == 88:  // 'x' or 'X'
        base = 16
    else if mode == 98:  // 'b'
        base = 2
    else if mode == 111:  // 'o'
        base = 8

    // Sign handling
    if base == 10 and is_unsigned == 0:
        if val < 0:
            buf[len] = 45  // '-'
            len = len + 1
            val = 0 - val
        else if sign_plus != 0:
            buf[len] = 43  // '+'
            len = len + 1

    // Alternate form prefix
    if alternate_form != 0:
        if base == 16:
            buf[len] = 48  // '0'
            len = len + 1
            buf[len] = if mode == 88: 88 as u8 else: 120 as u8  // 'X' or 'x'
            len = len + 1
        else if base == 2:
            buf[len] = 48
            len = len + 1
            buf[len] = 98  // 'b'
            len = len + 1
        else if base == 8:
            buf[len] = 48
            len = len + 1
            buf[len] = 111  // 'o'
            len = len + 1

    // Digits
    var dbuf: [66]u8 = [0 as u8; 66]
    let dlen = u64_base_to_buf(val as u64, base, if mode == 88: 1 else: 0, &dbuf as *mut u8)
    rt_memcpy((&buf as i64 + len) as *mut u8, &dbuf as *const u8, dlen)
    len = len + dlen

    // Width / padding
    if width > 0 and len < width as i64:
        if zero_pad != 0 and align_mode == 0:
            // Zero-pad: insert zeros after sign/prefix
            let prefix_len = len - dlen
            let pad_count = width as i64 - len
            let out = rt_alloc(width as i64 + 1)
            rt_memcpy(out, &buf as *const u8, prefix_len)
            rt_memset((out as i64 + prefix_len) as *mut u8, 48, pad_count)
            rt_memcpy((out as i64 + prefix_len + pad_count) as *mut u8, (&buf as i64 + prefix_len) as *const u8, dlen)
            unsafe *((out as i64 + width as i64) as *mut u8) = 0
            return make_str(out as *const u8, width as i64)
        return pad_str(&buf as *const u8, len, width as i64, fill_char, align_mode)

    alloc_str(&buf as *const u8, len)

// ── with_fmt_f64_spec ──────────────────────────────────────────────

pub fn with_fmt_f64_spec(val: f64, flags: i64, width: i32, precision: i32, mode: i32) -> str:
    var buf: [64]u8 = [0 as u8; 64]
    var len: i64 = 0

    if mode == 102:  // 'f'
        let fixed_precision = if precision >= 0: precision else: 6
        len = rt_f64_to_fixed_buf(val, fixed_precision, &buf as *mut u8, 64)
    else if mode == 101:  // 'e'
        let scientific_precision = if precision >= 0: precision else: 6
        len = rt_f64_to_scientific_buf(val, scientific_precision, &buf as *mut u8, 64)
    else if mode == 103:  // 'g'
        len = rt_f64_to_buf(val, &buf as *mut u8, 64)
    else if precision >= 0:
        len = rt_f64_to_fixed_buf(val, precision, &buf as *mut u8, 64)
    else:
        len = rt_f64_to_buf(val, &buf as *mut u8, 64)

    // sign_plus flag: insert '+' for non-negative values
    let sign_plus = ((flags >> 18) & 1) as i32
    if sign_plus != 0 and len > 0 and buf[0] != 45:  // not already '-'
        // Shift buffer right by 1 and prepend '+'
        var si = len
        while si > 0:
            buf[si as i64] = buf[(si - 1) as i64]
            si = si - 1
        buf[0] = 43  // '+'
        len = len + 1

    if width > 0 and len < width as i64:
        let fill_char = ((flags >> 8) & 255) as i32
        let align_mode = ((flags >> 16) & 3) as i32
        let zero_pad = ((flags >> 20) & 1) as i32
        if zero_pad != 0 and align_mode == 0:
            // Zero-pad after sign
            let pad_count = width as i64 - len
            let out = rt_alloc(width as i64 + 1)
            var sign_len: i64 = 0
            if len > 0 and buf[0] == 45:  // '-'
                sign_len = 1
            rt_memcpy(out, &buf as *const u8, sign_len)
            rt_memset((out as i64 + sign_len) as *mut u8, 48, pad_count)
            rt_memcpy((out as i64 + sign_len + pad_count) as *mut u8, (&buf as i64 + sign_len) as *const u8, len - sign_len)
            unsafe *((out as i64 + width as i64) as *mut u8) = 0
            return make_str(out as *const u8, width as i64)
        return pad_str(&buf as *const u8, len, width as i64, fill_char, align_mode)

    alloc_str(&buf as *const u8, len)

// ── with_fmt_str_spec ──────────────────────────────────────────────

pub fn with_fmt_str_spec(val: str, flags: i64, width: i32, precision: i32) -> str:
    var sp = str_data(val)
    var slen = str_length(val)
    if precision >= 0 and precision as i64 < slen:
        slen = precision as i64
    if width > 0 and slen < width as i64:
        let fill_char = ((flags >> 8) & 255) as i32
        let align_mode = ((flags >> 16) & 3) as i32
        return pad_str(sp, slen, width as i64, fill_char, align_mode)
    if slen != str_length(val):
        // Truncated by precision
        return alloc_str(sp, slen)
    val

// ── String operations ──────────────────────────────────────────────

pub fn with_str_concat(a: str, b: str) -> str:
    let al = str_length(a)
    let bl = str_length(b)
    let total = al + bl
    if total == 0:
        return make_str("" as *const u8, 0)
    let out = rt_alloc(total + 1)
    let ap = str_data(a)
    let bp = str_data(b)
    if ap as i64 != 0 and al > 0:
        rt_memcpy(out, ap, al)
    if bp as i64 != 0 and bl > 0:
        rt_memcpy((out as i64 + al) as *mut u8, bp, bl)
    unsafe *((out as i64 + total) as *mut u8) = 0
    make_str(out as *const u8, total)

fn str_owned_capacity_from_ptr(ptr: *const u8) -> i64:
    if ptr as i64 == 0:
        return 0
    if rt_payload_start_is_owned(ptr) == 0:
        return 0
    let payload_size = alloc_payload_size(ptr)
    if payload_size <= 0:
        return 0
    payload_size - 1

fn str_concat_n_copy(parts: *const str, count: i64, total: i64) -> str:
    let out = rt_alloc(total + 1)
    var offset: i64 = 0
    for i in 0..count:
        let part = unsafe parts[i]
        let part_len = str_length(part)
        let part_data = str_data(part)
        if part_data as i64 != 0 and part_len > 0:
            rt_memcpy((out as i64 + offset) as *mut u8, part_data, part_len)
        offset = offset + part_len
    unsafe *((out as i64 + total) as *mut u8) = 0
    make_str(out as *const u8, total)

pub fn with_str_concat_n(parts: *const str, count: i64) -> str:
    var total: i64 = 0
    for i in 0..count:
        let part = unsafe parts[i]
        total = total + str_length(part)
    if total == 0:
        return make_str("" as *const u8, 0)
    str_concat_n_copy(parts, count, total)

pub fn with_str_concat_n_move_first(parts: *const str, count: i64) -> str:
    var total: i64 = 0
    for i in 0..count:
        let part = unsafe parts[i]
        total = total + str_length(part)
    if total == 0:
        return make_str("" as *const u8, 0)
    if count <= 0:
        return make_str("" as *const u8, 0)

    let first = unsafe parts[0]
    let first_len = str_length(first)
    let first_ptr = str_data(first)
    let first_owned = rt_payload_start_is_owned(first_ptr)
    let first_cap = str_owned_capacity_from_ptr(first_ptr)
    if first_owned != 0 and first_ptr as i64 != 0 and first_cap >= total:
        var offset = first_len
        for i in 1..count:
            let part = unsafe parts[i]
            let part_len = str_length(part)
            let part_data = str_data(part)
            if part_data as i64 != 0 and part_len > 0:
                rt_memcpy((first_ptr as i64 + offset) as *mut u8, part_data, part_len)
            offset = offset + part_len
        unsafe *((first_ptr as i64 + total) as *mut u8) = 0
        return make_str(first_ptr, total)

    // Reallocate with geometric headroom: below RT_LARGE_THRESHOLD the size
    // classes already double, but large allocations are exact-size, so an
    // exact reallocation here would copy the whole string on every append.
    // Only this loop-shaped self-append path over-allocates; one-shot concats
    // (with_str_concat_n) stay exact.
    var new_size = total + 1
    if first_owned != 0:
        let doubled = (first_cap + 1) * 2
        if doubled > new_size:
            new_size = doubled
    let out = rt_alloc(new_size)
    var offset: i64 = 0
    for i in 0..count:
        let part = unsafe parts[i]
        let part_len = str_length(part)
        let part_data = str_data(part)
        if part_data as i64 != 0 and part_len > 0:
            rt_memcpy((out as i64 + offset) as *mut u8, part_data, part_len)
        offset = offset + part_len
    unsafe *((out as i64 + total) as *mut u8) = 0
    let result = make_str(out as *const u8, total)
    if first_owned != 0 and first_ptr as i64 != 0:
        rt_free(first_ptr as *mut u8)
    result

pub fn with_str_eq(a: str, b: str) -> i32:
    let al = str_length(a)
    let bl = str_length(b)
    if al != bl:
        return 0
    if al == 0:
        return 1
    let ap = str_data(a)
    let bp = str_data(b)
    if ap as i64 == bp as i64:
        return 1
    if rt_memcmp(ap, bp, al) == 0: 1 else: 0

pub fn with_str_cmp(a: str, b: str) -> i32:
    let al = str_length(a)
    let bl = str_length(b)
    let n = if al < bl: al else: bl
    let cmp = rt_memcmp(str_data(a), str_data(b), n)
    if cmp != 0:
        return cmp
    if al < bl:
        return -1
    if al > bl:
        return 1
    0

pub fn with_str_clone(s: str) -> str:
    let slen = str_length(s)
    if slen == 0:
        return make_str("" as *const u8, 0)
    let out = rt_alloc(slen + 1)
    rt_memcpy(out, str_data(s), slen)
    unsafe *((out as i64 + slen) as *mut u8) = 0
    make_str(out as *const u8, slen)

pub fn with_str_len(s: str) -> i64:
    str_length(s)

pub fn with_str_byte_at(s: str, idx: i64) -> i32:
    let slen = str_length(s)
    if idx < 0 or idx >= slen:
        return 0
    let p = str_data(s)
    (unsafe p[idx]) as i32

pub fn with_str_slice(s: str, start_arg: i64, end_arg: i64) -> str:
    let slen = str_length(s)
    var start = start_arg
    var end = end_arg
    if start < 0: start = 0
    if end > slen: end = slen
    if start >= end:
        return make_str("" as *const u8, 0)
    make_str((str_data(s) as i64 + start) as *const u8, end - start)

pub fn with_str_substr(s: str, start_arg: i64, length_arg: i64) -> str:
    let slen = str_length(s)
    var start = start_arg
    var length = length_arg
    if start < 0: start = 0
    if start >= slen:
        return make_str("" as *const u8, 0)
    if start + length > slen:
        length = slen - start
    make_str((str_data(s) as i64 + start) as *const u8, length)

pub fn with_str_starts_with(s: str, prefix: str) -> i32:
    let pl = str_length(prefix)
    let sl = str_length(s)
    if pl > sl: return 0
    if rt_memcmp(str_data(s), str_data(prefix), pl) == 0: 1 else: 0

pub fn with_str_ends_with(s: str, suffix: str) -> i32:
    let sufl = str_length(suffix)
    let sl = str_length(s)
    if sufl > sl: return 0
    let offset = sl - sufl
    if rt_memcmp((str_data(s) as i64 + offset) as *const u8, str_data(suffix), sufl) == 0: 1 else: 0

pub fn with_str_contains(hay: str, needle: str) -> i32:
    let nl = str_length(needle)
    let hl = str_length(hay)
    if nl == 0: return 1
    if nl > hl: return 0
    let hp = str_data(hay)
    let np = str_data(needle)
    var i: i64 = 0
    while i <= hl - nl:
        if rt_memcmp((hp as i64 + i) as *const u8, np, nl) == 0:
            return 1
        i = i + 1
    0

// Byte/codepoint membership: `ch in some_str`. Chars lower to ints, so the
// needle arrives as an i32 byte value (#234, §9.9).
pub fn with_str_contains_char(hay: str, ch: i32) -> i32:
    let hl = str_length(hay)
    let hp = str_data(hay)
    let target = (ch & 0xff) as u8
    var i: i64 = 0
    while i < hl:
        if (unsafe *((hp as i64 + i) as *const u8)) == target:
            return 1
        i = i + 1
    0

pub fn with_str_index_of(hay: str, needle: str) -> i64:
    let nl = str_length(needle)
    let hl = str_length(hay)
    if nl == 0: return 0
    if nl > hl: return -1
    let hp = str_data(hay)
    let np = str_data(needle)
    var i: i64 = 0
    while i <= hl - nl:
        if rt_memcmp((hp as i64 + i) as *const u8, np, nl) == 0:
            return i
        i = i + 1
    -1

pub fn with_str_trim(s: str) -> str:
    let slen = str_length(s)
    let sp = str_data(s)
    var start: i64 = 0
    while start < slen:
        let c = unsafe sp[start]
        if c != 32 and c != 9 and c != 10 and c != 13:  // ' ', '\t', '\n', '\r'
            break
        start = start + 1
    var end = slen
    while end > start:
        let c = unsafe sp[end - 1]
        if c != 32 and c != 9 and c != 10 and c != 13:
            break
        end = end - 1
    if start == 0 and end == slen:
        return s
    make_str((sp as i64 + start) as *const u8, end - start)

pub fn with_str_to_upper(s: str) -> str:
    let slen = str_length(s)
    if slen == 0: return s
    let out = rt_alloc(slen + 1)
    let sp = str_data(s)
    var i: i64 = 0
    while i < slen:
        let c = unsafe sp[i]
        if c >= 97 and c <= 122:  // 'a' to 'z'
            unsafe *((out as i64 + i) as *mut u8) = c - 32
        else:
            unsafe *((out as i64 + i) as *mut u8) = c
        i = i + 1
    unsafe *((out as i64 + slen) as *mut u8) = 0
    make_str(out as *const u8, slen)

pub fn with_str_to_lower(s: str) -> str:
    let slen = str_length(s)
    if slen == 0: return s
    let out = rt_alloc(slen + 1)
    let sp = str_data(s)
    var i: i64 = 0
    while i < slen:
        let c = unsafe sp[i]
        if c >= 65 and c <= 90:  // 'A' to 'Z'
            unsafe *((out as i64 + i) as *mut u8) = c + 32
        else:
            unsafe *((out as i64 + i) as *mut u8) = c
        i = i + 1
    unsafe *((out as i64 + slen) as *mut u8) = 0
    make_str(out as *const u8, slen)

pub fn with_str_repeat(s: str, count: i64) -> str:
    let slen = str_length(s)
    if count <= 0 or slen == 0:
        return make_str("" as *const u8, 0)
    let total = slen * count
    let out = rt_alloc(total + 1)
    let sp = str_data(s)
    var i: i64 = 0
    while i < count:
        rt_memcpy((out as i64 + i * slen) as *mut u8, sp, slen)
        i = i + 1
    unsafe *((out as i64 + total) as *mut u8) = 0
    make_str(out as *const u8, total)

pub fn with_str_replace(s: str, old: str, new_s: str) -> str:
    let sl = str_length(s)
    let ol = str_length(old)
    let nl = str_length(new_s)
    if ol == 0 or sl == 0: return s
    let sp = str_data(s)
    let op = str_data(old)
    let np = str_data(new_s)
    // Count occurrences
    var count: i64 = 0
    var i: i64 = 0
    while i <= sl - ol:
        if rt_memcmp((sp as i64 + i) as *const u8, op, ol) == 0:
            count = count + 1
            i = i + ol
        else:
            i = i + 1
    if count == 0: return s
    let new_len = sl + count * (nl - ol)
    let out = rt_alloc(new_len + 1)
    var j: i64 = 0
    i = 0
    while i < sl:
        if i <= sl - ol and rt_memcmp((sp as i64 + i) as *const u8, op, ol) == 0:
            if nl > 0:
                rt_memcpy((out as i64 + j) as *mut u8, np, nl)
            j = j + nl
            i = i + ol
        else:
            unsafe { *((out as i64 + j) as *mut u8) = sp[i] }
            j = j + 1
            i = i + 1
    unsafe *((out as i64 + new_len) as *mut u8) = 0
    make_str(out as *const u8, new_len)

pub fn with_str_from_cstr(s: *const u8) -> str:
    let len = cstr_len(s)
    make_str(s, len)

pub fn with_str_from_bytes(s: *const u8, len: i64) -> str:
    alloc_str(s, len)

pub fn with_str_from_vec_u8(v: *const u8) -> str:
    let vp = v as *mut u8
    let len = vec_get_len(vp)
    if len <= 0:
        return make_str("" as *const u8, 0)
    alloc_str(vec_get_ptr_field(vp), len)

pub fn with_str_hash(s: str) -> u64:
    fnv_hash(str_data(s), str_length(s))

// ── Conversion functions ───────────────────────────────────────────

pub fn with_i32_to_str(n: i32) -> str:
    with_fmt_i32(n)

pub fn i32_to_str(n: i32) -> str:
    with_fmt_i32(n)

pub fn with_i64_to_str(n: i64) -> str:
    with_fmt_i64(n)

pub fn i64_to_string(n: i64) -> str:
    with_fmt_i64(n)

pub fn with_bool_to_str(b: i32) -> str:
    with_fmt_bool(b)

pub fn str_from_byte(b: i32) -> str:
    let buf = rt_alloc(2)
    unsafe *buf = (b & 255) as u8
    unsafe *((buf as i64 + 1) as *mut u8) = 0
    make_str(buf as *const u8, 1)

pub fn with_parse_i64(s: str) -> i64:
    let slen = str_length(s)
    if slen == 0: return 0
    let sp = str_data(s)
    var result: i64 = 0
    var neg: i32 = 0
    var i: i64 = 0
    let first = unsafe *(sp as *const u8)
    if first == 45:  // '-'
        neg = 1
        i = 1
    else if first == 43:  // '+'
        i = 1
    while i < slen:
        let c = unsafe sp[i]
        if c < 48 or c > 57:
            break
        result = result * 10 + (c - 48) as i64
        i = i + 1
    if neg != 0: 0 - result else: result

pub fn with_parse_float(s: str) -> f64:
    let slen = str_length(s)
    if slen == 0: return 0.0
    let sp = str_data(s)
    var result: f64 = 0.0
    var neg: i32 = 0
    var i: i64 = 0
    let first = unsafe *(sp as *const u8)
    if first == 45:
        neg = 1
        i = 1
    else if first == 43:
        i = 1
    // Integer part
    while i < slen:
        let c = unsafe sp[i]
        if c < 48 or c > 57:
            break
        result = result * 10.0 + (c - 48) as f64
        i = i + 1
    // Fractional part
    if i < slen and (unsafe sp[i]) == 46:  // '.'
        i = i + 1
        var frac: f64 = 0.1
        while i < slen:
            let c = unsafe sp[i]
            if c < 48 or c > 57:
                break
            result = result + (c - 48) as f64 * frac
            frac = frac * 0.1
            i = i + 1
    // Exponent part
    if i < slen:
        let exp_head = unsafe sp[i]
        if exp_head == 101 or exp_head == 69:  // e/E
            i = i + 1
            var exp_neg: i32 = 0
            if i < slen:
                let sign = unsafe sp[i]
                if sign == 45:
                    exp_neg = 1
                    i = i + 1
                else if sign == 43:
                    i = i + 1
            var exp: i32 = 0
            while i < slen:
                let c = unsafe sp[i]
                if c < 48 or c > 57:
                    break
                exp = exp * 10 + (c - 48) as i32
                i = i + 1
            var scale: f64 = 1.0
            var ei: i32 = 0
            while ei < exp:
                scale = scale * 10.0
                ei = ei + 1
            if exp_neg != 0:
                result = result / scale
            else:
                result = result * scale
    if neg != 0: 0.0 - result else: result

// ── Args and environment ───────────────────────────────────────────

pub fn with_arg_count() -> i32:
    saved_argc

pub fn with_arg_at(idx: i32) -> str:
    if idx < 0 or idx >= saved_argc or saved_argv_raw == 0:
        return make_str("" as *const u8, 0)
    let s = unsafe *((saved_argv_raw + idx as i64 * 8) as *const *const u8)
    make_str(s, cstr_len(s))

pub fn with_getenv_str(name: str) -> str:
    let cname = str_to_cstr(name)
    let val = rt_getenv(cname)
    if val as i64 == 0:
        return make_str("" as *const u8, 0)
    make_str(val, cstr_len(val))

pub fn with_getenv(name: str) -> str:
    with_getenv_str(name)

// with_setenv_str: provided by compat_runtime.w (needs libc)

// ── Vec operations ─────────────────────────────────────────────────
//
// Vec layout: { ptr: *mut u8, len: i64, cap: i64, elem_size: i64 }
// We access it via pointer casts since we can't import the Vec type.

// Offsets into Vec struct (each field is 8 bytes):
// 0: ptr, 8: len, 16: cap, 24: elem_size

fn vec_get_ptr_field(v: *mut u8) -> *mut u8:
    unsafe *(v as *const *mut u8)

fn vec_set_ptr_field(v: *mut u8, p: *mut u8):
    unsafe *(v as *mut *mut u8) = p

fn vec_get_len(v: *mut u8) -> i64:
    unsafe *((v as i64 + 8) as *const i64)

fn vec_set_len(v: *mut u8, n: i64):
    unsafe *((v as i64 + 8) as *mut i64) = n

fn vec_get_cap(v: *mut u8) -> i64:
    unsafe *((v as i64 + 16) as *const i64)

fn vec_set_cap(v: *mut u8, n: i64):
    unsafe *((v as i64 + 16) as *mut i64) = n

fn vec_get_elem_size(v: *mut u8) -> i64:
    unsafe *((v as i64 + 24) as *const i64)

fn vec_set_elem_size(v: *mut u8, n: i64):
    unsafe *((v as i64 + 24) as *mut i64) = n

pub fn with_vec_new_out(out: *mut u8, elem_size: i64) -> Unit:
    vec_set_ptr_field(out, 0 as *mut u8)
    vec_set_len(out, 0)
    vec_set_cap(out, 0)
    vec_set_elem_size(out, elem_size)

pub fn with_vec_new(elem_size: i64) -> (*mut u8, i64, i64, i64):
    // Return a tuple that matches Vec layout
    (0 as *mut u8, 0 as i64, 0 as i64, elem_size)

pub fn with_vec_new_with_capacity_out(out: *mut u8, elem_size: i64, cap: i64) -> Unit:
    vec_set_elem_size(out, elem_size)
    vec_set_len(out, 0)
    vec_set_cap(out, cap)
    if cap > 0:
        vec_set_ptr_field(out, rt_alloc(cap * elem_size))
    else:
        vec_set_ptr_field(out, 0 as *mut u8)

fn vec_grow(v: *mut u8):
    let old_cap = vec_get_cap(v)
    let new_cap = if old_cap < 8: 8 as i64 else: old_cap * 2
    let es = vec_get_elem_size(v)
    let new_ptr = rt_alloc(new_cap * es)
    let old_ptr = vec_get_ptr_field(v)
    let vlen = vec_get_len(v)
    if old_ptr as i64 != 0 and vlen > 0:
        rt_memcpy(new_ptr, old_ptr as *const u8, vlen * es)
    if old_ptr as i64 != 0 and old_cap > 0:
        rt_free_sized(old_ptr, old_cap * es)
    vec_set_ptr_field(v, new_ptr)
    vec_set_cap(v, new_cap)

pub fn with_vec_push(v: *mut u8, elem: *const u8) -> Unit:
    let vlen = vec_get_len(v)
    let vcap = vec_get_cap(v)
    if vlen >= vcap:
        vec_grow(v)
    let es = vec_get_elem_size(v)
    let dst = (vec_get_ptr_field(v) as i64 + vlen * es) as *mut u8
    rt_memcpy(dst, elem, es)
    vec_set_len(v, vlen + 1)

pub fn with_vec_get_ptr(v: *mut u8, idx: i64) -> *mut u8:
    let vlen = vec_get_len(v)
    if idx < 0 or idx >= vlen:
        return 0 as *mut u8
    let es = vec_get_elem_size(v)
    (vec_get_ptr_field(v) as i64 + idx * es) as *mut u8

pub fn with_vec_len(v: *mut u8) -> i64:
    vec_get_len(v)

pub fn with_vec_clear(v: *mut u8) -> Unit:
    vec_set_len(v, 0)

// #606: free a Vec's heap buffer and zero its header. Called by the codegen
// scope-exit drop path for Drop-element Vecs (after element dtors have run).
pub fn with_vec_free(v: *mut u8) -> Unit:
    let p = vec_get_ptr_field(v)
    let cap = vec_get_cap(v)
    let es = vec_get_elem_size(v)
    if p as i64 != 0 and cap > 0 and es > 0:
        rt_free_sized(p, cap * es)
    vec_set_ptr_field(v, 0 as *mut u8)
    vec_set_len(v, 0)
    vec_set_cap(v, 0)

pub fn with_vec_push_i32(v: *mut u8, val: i32) -> Unit:
    with_vec_push(v, &val as *const u8)

pub fn with_vec_get_i32(v: *mut u8, idx: i64) -> i32:
    let p = with_vec_get_ptr(v, idx)
    if p as i64 != 0:
        return unsafe *(p as *const i32)
    0

pub fn with_vec_push_i64(v: *mut u8, val: i64) -> Unit:
    with_vec_push(v, &val as *const u8)

pub fn with_vec_get_i64(v: *mut u8, idx: i64) -> i64:
    let p = with_vec_get_ptr(v, idx)
    if p as i64 != 0:
        return unsafe *(p as *const i64)
    0

pub fn with_vec_push_str(v: *mut u8, val: str) -> Unit:
    with_vec_push(v, &val as *const u8)

pub fn with_vec_get_str(v: *mut u8, idx: i64) -> str:
    let p = with_vec_get_ptr(v, idx)
    if p as i64 != 0:
        return unsafe *(p as *const str)
    make_str("" as *const u8, 0)

pub fn with_vec_push_bool(v: *mut u8, val: i32) -> Unit:
    with_vec_push(v, &val as *const u8)

pub fn with_vec_get_bool(v: *mut u8, idx: i64) -> i32:
    with_vec_get_i32(v, idx)

pub fn with_ptr_get_i32(ptr: *const u8, index: i64) -> i32:
    unsafe *((ptr as i64 + index * 4) as *const i32)

pub fn with_vec_set_i32(v: *mut u8, idx: i64, val: i32) -> Unit:
    let vlen = vec_get_len(v)
    if idx >= 0 and idx < vlen:
        let es = vec_get_elem_size(v)
        unsafe *((vec_get_ptr_field(v) as i64 + idx * es) as *mut i32) = val

pub fn with_vec_set_i64(v: *mut u8, idx: i64, val: i64) -> Unit:
    let vlen = vec_get_len(v)
    if idx >= 0 and idx < vlen:
        let es = vec_get_elem_size(v)
        unsafe *((vec_get_ptr_field(v) as i64 + idx * es) as *mut i64) = val

pub fn with_vec_remove(v: *mut u8, idx: i64) -> Unit:
    let vlen = vec_get_len(v)
    if idx < 0 or idx >= vlen: return
    let base = vec_get_ptr_field(v)
    let es = vec_get_elem_size(v)
    var i = idx
    while i < vlen - 1:
        rt_memcpy((base as i64 + i * es) as *mut u8, (base as i64 + (i + 1) * es) as *const u8, es)
        i = i + 1
    vec_set_len(v, vlen - 1)

pub fn with_vec_pop_i32(v: *mut u8) -> i32:
    let vlen = vec_get_len(v)
    if vlen == 0: return 0
    vec_set_len(v, vlen - 1)
    let es = vec_get_elem_size(v)
    unsafe *((vec_get_ptr_field(v) as i64 + (vlen - 1) * es) as *const i32)

// ── SlotMap operations ────────────────────────────────────────────
//
// SlotMap struct layout:
//   0: values (*mut u8)      8: occupied (*mut u8)
//  16: generations (*mut u8) 24: len (i64)
//  32: cap (i64)            40: elem_size (i64)
// Total: 48 bytes

let SM_OFF_VALUES: i64 = 0
let SM_OFF_OCC: i64 = 8
let SM_OFF_GENS: i64 = 16
let SM_OFF_LEN: i64 = 24
let SM_OFF_CAP: i64 = 32
let SM_OFF_ESZ: i64 = 40
let SM_SIZE: i64 = 48

fn sm_values(m: i64) -> *mut u8:
    unsafe *(m as *const *mut u8)
fn sm_occ(m: i64) -> *mut u8:
    unsafe *((m + SM_OFF_OCC) as *const *mut u8)
fn sm_gens(m: i64) -> *mut u8:
    unsafe *((m + SM_OFF_GENS) as *const *mut u8)
fn sm_len(m: i64) -> i64:
    unsafe *((m + SM_OFF_LEN) as *const i64)
fn sm_cap(m: i64) -> i64:
    unsafe *((m + SM_OFF_CAP) as *const i64)
fn sm_elem_size(m: i64) -> i64:
    unsafe *((m + SM_OFF_ESZ) as *const i64)

fn sm_set_values(m: i64, v: *mut u8):
    unsafe *(m as *mut *mut u8) = v
fn sm_set_occ(m: i64, v: *mut u8):
    unsafe *((m + SM_OFF_OCC) as *mut *mut u8) = v
fn sm_set_gens(m: i64, v: *mut u8):
    unsafe *((m + SM_OFF_GENS) as *mut *mut u8) = v
fn sm_set_len(m: i64, v: i64):
    unsafe *((m + SM_OFF_LEN) as *mut i64) = v
fn sm_set_cap(m: i64, v: i64):
    unsafe *((m + SM_OFF_CAP) as *mut i64) = v
fn sm_set_elem_size(m: i64, v: i64):
    unsafe *((m + SM_OFF_ESZ) as *mut i64) = v

fn sm_occ_at(m: i64, idx: i64) -> i32:
    unsafe *((sm_occ(m) as i64 + idx) as *const u8) as i32
fn sm_set_occ_at(m: i64, idx: i64, val: i32):
    unsafe *((sm_occ(m) as i64 + idx) as *mut u8) = val as u8
fn sm_generation_at(m: i64, idx: i64) -> u32:
    unsafe *((sm_gens(m) as i64 + idx * 4) as *const u32)
fn sm_set_generation_at(m: i64, idx: i64, val: u32):
    unsafe *((sm_gens(m) as i64 + idx * 4) as *mut u32) = val
fn sm_value_ptr_at(m: i64, idx: i64) -> *mut u8:
    (sm_values(m) as i64 + idx * sm_elem_size(m)) as *mut u8

fn sm_normalize_generation(g: u32) -> u32:
    if g == 0 as u32: 1 as u32 else: g

fn sm_grow(m: i64):
    let old_cap = sm_cap(m)
    let new_cap = if old_cap < 8: 8 as i64 else: old_cap * 2
    let es = sm_elem_size(m)
    let old_values = sm_values(m)
    let old_occ = sm_occ(m)
    let old_gens = sm_gens(m)
    let new_values = rt_alloc(new_cap * es)
    let new_occ = rt_alloc(new_cap)
    let new_gens = rt_alloc(new_cap * 4)
    rt_memset(new_occ, 0, new_cap)
    var i: i64 = 0
    while i < new_cap:
        unsafe *((new_gens as i64 + i * 4) as *mut u32) = 1 as u32
        i = i + 1
    if old_cap > 0:
        rt_memcpy(new_values, old_values as *const u8, old_cap * es)
        rt_memcpy(new_occ, old_occ as *const u8, old_cap)
        rt_memcpy(new_gens, old_gens as *const u8, old_cap * 4)
        rt_free_sized(old_values, old_cap * es)
        rt_free_sized(old_occ, old_cap)
        rt_free_sized(old_gens, old_cap * 4)
    sm_set_values(m, new_values)
    sm_set_occ(m, new_occ)
    sm_set_gens(m, new_gens)
    sm_set_cap(m, new_cap)

fn sm_write_handle(out: *mut u8, idx: u32, generation_value: u32):
    unsafe *(out as *mut u32) = idx
    unsafe *((out as i64 + 4) as *mut u32) = generation_value

fn sm_valid(m: i64, index: u32, generation: u32) -> i32:
    if m == 0:
        return 0
    let idx = index as i64
    if idx < 0 or idx >= sm_cap(m):
        return 0
    if sm_occ_at(m, idx) == 0:
        return 0
    if sm_generation_at(m, idx) != generation:
        return 0
    1

pub fn with_slotmap_new(elem_size: i64) -> *mut u8:
    let m = rt_alloc(SM_SIZE)
    sm_set_values(m as i64, 0 as *mut u8)
    sm_set_occ(m as i64, 0 as *mut u8)
    sm_set_gens(m as i64, 0 as *mut u8)
    sm_set_len(m as i64, 0)
    sm_set_cap(m as i64, 0)
    sm_set_elem_size(m as i64, elem_size)
    m

pub fn with_slotmap_insert_out(map: *mut u8, val: *const u8, out: *mut u8) -> Unit:
    let m = map as i64
    if sm_len(m) >= sm_cap(m):
        sm_grow(m)
    var idx: i64 = 0
    while idx < sm_cap(m):
        if sm_occ_at(m, idx) == 0:
            let generation_value = sm_normalize_generation(sm_generation_at(m, idx))
            sm_set_generation_at(m, idx, generation_value)
            rt_memcpy(sm_value_ptr_at(m, idx), val, sm_elem_size(m))
            sm_set_occ_at(m, idx, 1)
            sm_set_len(m, sm_len(m) + 1)
            sm_write_handle(out, idx as u32, generation_value)
            return
        idx = idx + 1
    with_panic_core(make_str("SlotMap insert failed to find a free slot" as *const u8, 41), make_str("" as *const u8, 0), 0)

pub fn with_slotmap_get_ptr(map: *mut u8, index: u32, generation: u32) -> *mut u8:
    let m = map as i64
    if sm_valid(m, index, generation) == 0:
        return 0 as *mut u8
    sm_value_ptr_at(m, index as i64)

pub fn with_slotmap_contains(map: *mut u8, index: u32, generation: u32) -> i32:
    sm_valid(map as i64, index, generation)

pub fn with_slotmap_len(map: *mut u8) -> i64:
    if map as i64 == 0:
        return 0
    sm_len(map as i64)

pub fn with_slotmap_remove(map: *mut u8, index: u32, generation: u32, out: *mut u8) -> i32:
    let m = map as i64
    if sm_valid(m, index, generation) == 0:
        return 0
    let idx = index as i64
    if out as i64 != 0:
        rt_memcpy(out, sm_value_ptr_at(m, idx) as *const u8, sm_elem_size(m))
    sm_set_occ_at(m, idx, 0)
    var next_gen = generation + 1 as u32
    if next_gen == 0 as u32:
        next_gen = 1 as u32
    sm_set_generation_at(m, idx, next_gen)
    sm_set_len(m, sm_len(m) - 1)
    1

pub fn with_slotmap_replace(map: *mut u8, index: u32, generation: u32, val: *const u8, out: *mut u8) -> i32:
    let m = map as i64
    if sm_valid(m, index, generation) == 0:
        return 0
    let dst = sm_value_ptr_at(m, index as i64)
    if out as i64 != 0:
        rt_memcpy(out, dst as *const u8, sm_elem_size(m))
    rt_memcpy(dst, val, sm_elem_size(m))
    1

pub fn with_slotmap_set(map: *mut u8, index: u32, generation: u32, val: *const u8) -> i32:
    let m = map as i64
    if sm_valid(m, index, generation) == 0:
        return 0
    rt_memcpy(sm_value_ptr_at(m, index as i64), val, sm_elem_size(m))
    1

// ── HashMap operations ─────────────────────────────────────────────
//
// FNV-1a hash. Open-addressing with linear probing.
//
// HashMap struct layout:
//   0: keys (*mut u8)       8: vals (*mut u8)      16: occupied (*mut u8)
//  24: cap (i64)           32: len (i64)           40: key_size (i64)
//  48: val_size (i64)      56: is_str_key (i32)
// Total: 64 bytes

let HM_OFF_KEYS: i64 = 0
let HM_OFF_VALS: i64 = 8
let HM_OFF_OCC: i64 = 16
let HM_OFF_CAP: i64 = 24
let HM_OFF_LEN: i64 = 32
let HM_OFF_KSZ: i64 = 40
let HM_OFF_VSZ: i64 = 48
let HM_OFF_ISSTR: i64 = 56
let HM_SIZE: i64 = 64

fn hm_keys(m: i64) -> *mut u8:
    unsafe *(m as *const *mut u8)
fn hm_vals(m: i64) -> *mut u8:
    unsafe *((m + HM_OFF_VALS) as *const *mut u8)
fn hm_occ(m: i64) -> *mut u8:
    unsafe *((m + HM_OFF_OCC) as *const *mut u8)
fn hm_cap(m: i64) -> i64:
    unsafe *((m + HM_OFF_CAP) as *const i64)
fn hm_len(m: i64) -> i64:
    unsafe *((m + HM_OFF_LEN) as *const i64)
fn hm_key_size(m: i64) -> i64:
    unsafe *((m + HM_OFF_KSZ) as *const i64)
fn hm_val_size(m: i64) -> i64:
    unsafe *((m + HM_OFF_VSZ) as *const i64)
fn hm_is_str_key(m: i64) -> i32:
    unsafe *((m + HM_OFF_ISSTR) as *const i32)

fn hm_set_keys(m: i64, v: *mut u8):
    unsafe *(m as *mut *mut u8) = v
fn hm_set_vals(m: i64, v: *mut u8):
    unsafe *((m + HM_OFF_VALS) as *mut *mut u8) = v
fn hm_set_occ(m: i64, v: *mut u8):
    unsafe *((m + HM_OFF_OCC) as *mut *mut u8) = v
fn hm_set_cap(m: i64, v: i64):
    unsafe *((m + HM_OFF_CAP) as *mut i64) = v
fn hm_set_len(m: i64, v: i64):
    unsafe *((m + HM_OFF_LEN) as *mut i64) = v
fn hm_set_key_size(m: i64, v: i64):
    unsafe *((m + HM_OFF_KSZ) as *mut i64) = v
fn hm_set_val_size(m: i64, v: i64):
    unsafe *((m + HM_OFF_VSZ) as *mut i64) = v
fn hm_set_is_str_key(m: i64, v: i32):
    unsafe *((m + HM_OFF_ISSTR) as *mut i32) = v

// FNV-1a hash
fn fnv_hash(data: *const u8, len: i64) -> u64:
    // FNV offset basis: 14695981039346656037
    var h: u64 = 14695981039346656037
    var i: i64 = 0
    while i < len:
        let byte = unsafe data[i]
        h = h ^ (byte as u64)
        // FNV prime: 1099511628211
        h = h *% 1099511628211
        i = i + 1
    h

fn hm_hash_key(m: i64, key: *const u8) -> u64:
    if hm_is_str_key(m) != 0:
        // key points to a str value {ptr, len}
        let str_ptr = unsafe *(key as *const *const u8)
        let str_len = unsafe *((key as i64 + 8) as *const i64)
        return fnv_hash(str_ptr, str_len)
    fnv_hash(key, hm_key_size(m))

fn hm_keys_eq(m: i64, a: *const u8, b: *const u8) -> i32:
    if hm_is_str_key(m) != 0:
        let a_ptr = unsafe *(a as *const *const u8)
        let a_len = unsafe *((a as i64 + 8) as *const i64)
        let b_ptr = unsafe *(b as *const *const u8)
        let b_len = unsafe *((b as i64 + 8) as *const i64)
        if a_len != b_len: return 0
        if a_len == 0: return 1
        return if rt_memcmp(a_ptr, b_ptr, a_len) == 0: 1 else: 0
    if rt_memcmp(a, b, hm_key_size(m)) == 0: 1 else: 0

fn hm_grow(m: i64):
    let old_cap = hm_cap(m)
    let old_keys = hm_keys(m)
    let old_vals = hm_vals(m)
    let old_occ = hm_occ(m)
    let ksz = hm_key_size(m)
    let vsz = hm_val_size(m)

    let new_cap = old_cap * 2
    hm_set_cap(m, new_cap)
    hm_set_keys(m, rt_alloc(new_cap * ksz))
    hm_set_vals(m, rt_alloc(new_cap * vsz))
    hm_set_occ(m, rt_alloc(new_cap))
    rt_memset(hm_occ(m), 0, new_cap)
    hm_set_len(m, 0)

    var i: i64 = 0
    while i < old_cap:
        if (unsafe old_occ[i]) != 0:
            let k = (old_keys as i64 + i * ksz) as *const u8
            let v = (old_vals as i64 + i * vsz) as *const u8
            // Re-insert
            var h = (hm_hash_key(m, k) % (new_cap as u64)) as i64
            while (unsafe hm_occ(m)[h]) != 0:
                h = ((h + 1) as u64 % (new_cap as u64)) as i64
            rt_memcpy((hm_keys(m) as i64 + h * ksz) as *mut u8, k, ksz)
            rt_memcpy((hm_vals(m) as i64 + h * vsz) as *mut u8, v, vsz)
            unsafe *((hm_occ(m) as i64 + h) as *mut u8) = 1
            hm_set_len(m, hm_len(m) + 1)
        i = i + 1

    rt_free_sized(old_keys, old_cap * ksz)
    rt_free_sized(old_vals, old_cap * vsz)
    rt_free_sized(old_occ, old_cap)

pub fn with_hashmap_new(key_size: i64, val_size: i64) -> *mut u8:
    let m = rt_alloc(HM_SIZE)
    let mi = m as i64
    hm_set_cap(mi, 16)
    hm_set_len(mi, 0)
    hm_set_key_size(mi, key_size)
    hm_set_val_size(mi, val_size)
    // str is 16 bytes (ptr + len)
    hm_set_is_str_key(mi, if key_size == 16: 1 else: 0)
    hm_set_keys(mi, rt_alloc(16 * key_size))
    hm_set_vals(mi, rt_alloc(16 * val_size))
    hm_set_occ(mi, rt_alloc(16))
    rt_memset(hm_occ(mi), 0, 16)
    m

pub fn with_hashmap_new_out(out: *mut *mut u8, key_size: i64, val_size: i64) -> Unit:
    unsafe *out = with_hashmap_new(key_size, val_size)

pub fn with_hashmap_new_at(base: *mut u8, offset: i64, key_size: i64, val_size: i64) -> Unit:
    let slot = (base as i64 + offset) as *mut *mut u8
    unsafe *slot = with_hashmap_new(key_size, val_size)

pub fn with_hashmap_insert(map: *mut u8, key: *const u8, val: *const u8, is_str_key: i64) -> Unit:
    let m = map as i64
    // Store is_str_key if first insert
    if is_str_key != 0:
        hm_set_is_str_key(m, 1)
    // Grow at 70% load
    if hm_len(m) * 10 >= hm_cap(m) * 7:
        hm_grow(m)

    let cap = hm_cap(m)
    let ksz = hm_key_size(m)
    let vsz = hm_val_size(m)

    var h = (hm_hash_key(m, key) % (cap as u64)) as i64
    loop:
        if (unsafe hm_occ(m)[h]) == 0:
            break
        if hm_keys_eq(m, (hm_keys(m) as i64 + h * ksz) as *const u8, key) != 0:
            // Update existing
            rt_memcpy((hm_vals(m) as i64 + h * vsz) as *mut u8, val, vsz)
            return
        h = ((h + 1) as u64 % (cap as u64)) as i64
    rt_memcpy((hm_keys(m) as i64 + h * ksz) as *mut u8, key, ksz)
    rt_memcpy((hm_vals(m) as i64 + h * vsz) as *mut u8, val, vsz)
    unsafe *((hm_occ(m) as i64 + h) as *mut u8) = 1
    hm_set_len(m, hm_len(m) + 1)

pub fn with_hashmap_get(map: *mut u8, key: *const u8, val_out: *mut u8, is_str_key: i64) -> i32:
    let _ = is_str_key  // key type already stored in struct
    let m = map as i64
    if hm_len(m) == 0: return 0
    let cap = hm_cap(m)
    let ksz = hm_key_size(m)
    let vsz = hm_val_size(m)

    var h = (hm_hash_key(m, key) % (cap as u64)) as i64
    var probes: i64 = 0
    while probes < cap:
        if (unsafe hm_occ(m)[h]) == 0:
            return 0
        if hm_keys_eq(m, (hm_keys(m) as i64 + h * ksz) as *const u8, key) != 0:
            if val_out as i64 != 0:
                rt_memcpy(val_out, (hm_vals(m) as i64 + h * vsz) as *const u8, vsz)
            return 1
        h = ((h + 1) as u64 % (cap as u64)) as i64
        probes = probes + 1
    0

pub fn with_hashmap_contains(map: *mut u8, key: *const u8, is_str_key: i64) -> i32:
    with_hashmap_get(map, key, 0 as *mut u8, is_str_key)

pub fn with_hashmap_remove(map: *mut u8, key: *const u8, val_out: *mut u8, is_str_key: i64) -> i32:
    let _ = is_str_key  // key type already stored in struct
    let m = map as i64
    if hm_len(m) == 0: return 0
    let cap = hm_cap(m)
    let ksz = hm_key_size(m)
    let vsz = hm_val_size(m)

    var h = (hm_hash_key(m, key) % (cap as u64)) as i64
    var probes: i64 = 0
    while probes < cap:
        if (unsafe hm_occ(m)[h]) == 0:
            return 0
        if hm_keys_eq(m, (hm_keys(m) as i64 + h * ksz) as *const u8, key) != 0:
            if val_out as i64 != 0:
                rt_memcpy(val_out, (hm_vals(m) as i64 + h * vsz) as *const u8, vsz)
            unsafe *((hm_occ(m) as i64 + h) as *mut u8) = 0
            hm_set_len(m, hm_len(m) - 1)
            // Rehash following entries
            var next = ((h + 1) as u64 % (cap as u64)) as i64
            while (unsafe hm_occ(m)[next]) != 0:
                // Save key+val, clear slot, re-insert
                let tmpk = rt_alloc(ksz)
                let tmpv = rt_alloc(vsz)
                rt_memcpy(tmpk, (hm_keys(m) as i64 + next * ksz) as *const u8, ksz)
                rt_memcpy(tmpv, (hm_vals(m) as i64 + next * vsz) as *const u8, vsz)
                unsafe *((hm_occ(m) as i64 + next) as *mut u8) = 0
                hm_set_len(m, hm_len(m) - 1)
                with_hashmap_insert(map, tmpk as *const u8, tmpv as *const u8, hm_is_str_key(m) as i64)
                rt_free_sized(tmpk, ksz)
                rt_free_sized(tmpv, vsz)
                next = ((next + 1) as u64 % (cap as u64)) as i64
            return 1
        h = ((h + 1) as u64 % (cap as u64)) as i64
        probes = probes + 1
    0

pub fn with_hashmap_len(map: *mut u8) -> i64:
    hm_len(map as i64)

pub fn with_hashmap_clear(map: *mut u8) -> Unit:
    let m = map as i64
    rt_memset(hm_occ(m), 0, hm_cap(m))
    hm_set_len(m, 0)

pub fn with_hashmap_keys_out(out: *mut u8, map: *mut u8, key_size: i64) -> Unit:
    let m = map as i64
    if m == 0:
        with_vec_new_out(out, key_size)
        return
    let cap = hm_cap(m)
    let ksz = hm_key_size(m)
    let effective_ksz = if ksz > 0: ksz else: key_size
    with_vec_new_out(out, effective_ksz)
    var i: i64 = 0
    while i < cap:
        if (unsafe hm_occ(m)[i]) != 0:
            with_vec_push(out, (hm_keys(m) as i64 + i * ksz) as *const u8)
        i = i + 1

pub fn with_hashmap_values_out(out: *mut u8, map: *mut u8, val_size: i64) -> Unit:
    let m = map as i64
    if m == 0:
        with_vec_new_out(out, val_size)
        return
    let cap = hm_cap(m)
    let vsz = hm_val_size(m)
    let effective_vsz = if vsz > 0: vsz else: val_size
    with_vec_new_out(out, effective_vsz)
    var i: i64 = 0
    while i < cap:
        if (unsafe hm_occ(m)[i]) != 0:
            with_vec_push(out, (hm_vals(m) as i64 + i * vsz) as *const u8)
        i = i + 1

pub fn with_hashmap_items_out(out: *mut u8, map: *mut u8, key_size: i64, val_size: i64, pair_size: i64, val_offset: i64) -> Unit:
    let m = map as i64
    let effective_pair_size = if pair_size > 0: pair_size else: key_size + val_size
    with_vec_new_out(out, effective_pair_size)
    if m == 0:
        return
    let cap = hm_cap(m)
    let ksz = hm_key_size(m)
    let vsz = hm_val_size(m)
    let effective_ksz = if ksz > 0: ksz else: key_size
    let effective_vsz = if vsz > 0: vsz else: val_size
    let tmp = rt_alloc(effective_pair_size)
    var i: i64 = 0
    while i < cap:
        if (unsafe hm_occ(m)[i]) != 0:
            rt_memset(tmp, 0, effective_pair_size)
            rt_memcpy(tmp, (hm_keys(m) as i64 + i * ksz) as *const u8, effective_ksz)
            rt_memcpy((tmp as i64 + val_offset) as *mut u8, (hm_vals(m) as i64 + i * vsz) as *const u8, effective_vsz)
            with_vec_push(out, tmp as *const u8)
        i = i + 1
    rt_free_sized(tmp, effective_pair_size)

pub fn with_hashmap_free(map: *mut u8) -> Unit:
    if map as i64 == 0: return
    let m = map as i64
    let cap = hm_cap(m)
    rt_free_sized(hm_keys(m), cap * hm_key_size(m))
    rt_free_sized(hm_vals(m), cap * hm_val_size(m))
    rt_free_sized(hm_occ(m), cap)
    rt_free_sized(map, HM_SIZE)

pub fn with_hashmap_increment(map: *mut u8, key: *const u8, is_str_key: i64) -> Unit:
    var val: i64 = 0
    let _ = with_hashmap_get(map, key, &val as *mut u8, is_str_key)
    val = val + 1
    with_hashmap_insert(map, key, &val as *const u8, is_str_key)

pub fn with_hashmap_decrement(map: *mut u8, key: *const u8, is_str_key: i64) -> Unit:
    var val: i64 = 0
    let _ = with_hashmap_get(map, key, &val as *mut u8, is_str_key)
    val = val - 1
    with_hashmap_insert(map, key, &val as *const u8, is_str_key)

// ── StringBuilder ──────────────────────────────────────────────────
//
// Layout: { buf: *mut u8, len: i64, cap: i64 } — 24 bytes

let SB_OFF_BUF: i64 = 0
let SB_OFF_LEN: i64 = 8
let SB_OFF_CAP: i64 = 16
let SB_SIZE: i64 = 24

pub fn with_sb_new() -> (*mut u8, i64, i64):
    let buf = rt_alloc(64)
    (buf, 0 as i64, 64 as i64)

pub fn with_sb_append(sb: *mut u8, s: str) -> Unit:
    let slen = str_length(s)
    if slen == 0: return
    let sp = str_data(s)
    // sb_grow is declared before sb_buf so assigning it into sb_buf is a
    // view of an earlier (longer-lived) binding under §21.1.
    var sb_grow: *mut u8 = 0 as *mut u8
    var sb_buf = unsafe *(sb as *const *mut u8)
    var sb_len = unsafe *((sb as i64 + SB_OFF_LEN) as *const i64)
    var sb_cap = unsafe *((sb as i64 + SB_OFF_CAP) as *const i64)
    while sb_len + slen > sb_cap:
        let old_cap = sb_cap
        let new_cap = old_cap * 2
        sb_grow = rt_alloc(new_cap)
        rt_memcpy(sb_grow, sb_buf as *const u8, sb_len)
        rt_free_sized(sb_buf, old_cap)
        sb_buf = sb_grow
        sb_cap = new_cap
    rt_memcpy((sb_buf as i64 + sb_len) as *mut u8, sp, slen)
    sb_len = sb_len + slen
    unsafe *(sb as *mut *mut u8) = sb_buf
    unsafe *((sb as i64 + SB_OFF_LEN) as *mut i64) = sb_len
    unsafe *((sb as i64 + SB_OFF_CAP) as *mut i64) = sb_cap

pub fn with_sb_build(sb: *mut u8) -> str:
    let sb_buf = unsafe *(sb as *const *mut u8)
    let sb_len = unsafe *((sb as i64 + SB_OFF_LEN) as *const i64)
    let out = rt_alloc(sb_len + 1)
    rt_memcpy(out, sb_buf as *const u8, sb_len)
    unsafe *((out as i64 + sb_len) as *mut u8) = 0
    make_str(out as *const u8, sb_len)

// ── File I/O ───────────────────────────────────────────────────────

fn fs_path_is_dir_c(path: *const u8) -> bool:
    var st: [24]u8 = [0 as u8; 24]
    if rt_stat(path, &st as *mut u8) != 0:
        return false
    let base = &st as i64
    unsafe *((base + 8) as *const i32) != 0

fn fs_mkdir_component(path: *const u8, mode: i32) -> i32:
    let rc = rt_mkdir(path, mode)
    if rc != 0 and fs_path_is_dir_c(path):
        return 0
    rc

pub fn with_fs_read_file(path: str) -> str:
    let cpath = str_to_cstr(path)
    if fs_path_is_dir_c(cpath):
        return make_str("" as *const u8, 0)
    let fd = rt_open(cpath, 0, 0)  // O_RDONLY
    if fd < 0:
        return make_str("" as *const u8, 0)

    // Get file size via seek
    let size = rt_seek(fd, 0, 2)  // SEEK_END
    if size <= 0:
        let _ = rt_close(fd)
        return make_str("" as *const u8, 0)
    let _ = rt_seek(fd, 0, 0)  // SEEK_SET

    let buf = rt_alloc(size + 1)
    var total: i64 = 0
    while total < size:
        let r = rt_read(fd, (buf as i64 + total) as *mut u8, (size - total) as u64)
        if r <= 0: break
        total = total + r
    let _ = rt_close(fd)
    unsafe *((buf as i64 + total) as *mut u8) = 0
    make_str(buf as *const u8, total)

pub fn with_fs_write_file(path: str, data: str) -> i32:
    let cpath = str_to_cstr(path)
    // O_WRONLY=1, O_CREAT=0x200, O_TRUNC=0x400
    let fd = rt_open(cpath, 1 | 0x200 | 0x400, 0o644)
    if fd < 0: return fd
    let dp = str_data(data)
    let dl = str_length(data)
    var written: i64 = 0
    while written < dl:
        let r = rt_write(fd, (dp as i64 + written) as *const u8, (dl - written) as u64)
        if r <= 0: break
        written = written + r
    let _ = rt_close(fd)
    0

pub fn with_fs_file_exists(path: str) -> i32:
    let cpath = str_to_cstr(path)
    if rt_access(cpath, 0) != 0:
        return 0
    1

pub fn with_fs_is_dir(path: str) -> i32:
    let cpath = str_to_cstr(path)
    if fs_path_is_dir_c(cpath):
        return 1
    0

pub fn with_fs_mkdir_p(path: str) -> i32:
    let cpath = str_to_cstr(path)
    // Create each directory component
    let slen = str_length(path)
    var i: i64 = 1
    while i < slen:
        if unsafe *((cpath as i64 + i) as *const u8) == 47:  // '/'
            unsafe *((cpath as i64 + i) as *mut u8) = 0
            let rc = fs_mkdir_component(cpath, 493)  // 0755
            unsafe *((cpath as i64 + i) as *mut u8) = 47
            if rc != 0:
                return rc
        i = i + 1
    fs_mkdir_component(cpath, 493)

pub fn with_fs_remove_file(path: str) -> i32:
    let cpath = str_to_cstr(path)
    rt_unlink(cpath)

pub fn with_libc_open(path: *const i8, flags: i32, mode: i32) -> i32:
    let r = rt_open(path, flags, mode)
    if r < 0: -1 else: r

pub fn with_libc_read(fd: i32, buf: *mut u8, count: u64) -> i64:
    let r = rt_read(fd, buf, count)
    if r < 0: -1 else: r

pub fn with_libc_write(fd: i32, buf: *const u8, count: u64) -> i64:
    let r = rt_write(fd, buf, count)
    if r < 0: -1 else: r

pub fn with_libc_close(fd: i32) -> i32:
    let r = rt_close(fd)
    if r < 0: -1 else: r

pub fn with_libc_lseek(fd: i32, offset: i64, whence: i32) -> i64:
    let r = rt_seek(fd, offset, whence)
    if r < 0: -1 else: r

pub fn with_libc_unlink(path: *const i8) -> i32:
    let r = rt_unlink(path)
    if r < 0: -1 else: r

pub fn with_fs_chmod(path: str, mode: i32) -> i32:
    let cpath = str_to_cstr(path)
    rt_chmod(cpath, mode)

pub fn with_fs_file_mode(path: str) -> i32:
    let cpath = str_to_cstr(path)
    rt_file_mode(cpath)

pub fn with_fs_readlink(path: str) -> str:
    let cpath = str_to_cstr(path)
    rt_readlink(cpath)

pub fn with_fs_rename_file(old_path: str, new_path: str) -> i32:
    let cold = str_to_cstr(old_path)
    let cnew = str_to_cstr(new_path)
    rt_rename(cold, cnew)

pub fn with_fs_create_dir(path: str) -> i32:
    let cpath = str_to_cstr(path)
    rt_mkdir(cpath, 493)  // 0755

pub fn with_fs_remove_dir(path: str) -> i32:
    let cpath = str_to_cstr(path)
    rt_rmdir(cpath)

pub fn with_fs_remove_tree(path: str) -> i32:
    let cpath = str_to_cstr(path)
    rt_remove_tree(cpath)

pub fn with_fs_copy_tree(src: str, dst: str) -> i32:
    let csrc = str_to_cstr(src)
    let cdst = str_to_cstr(dst)
    rt_copy_tree(csrc, cdst)

pub fn with_fs_symlink(target: str, link_path: str) -> i32:
    let ctarget = str_to_cstr(target)
    let clink = str_to_cstr(link_path)
    rt_symlink(ctarget, clink)

pub fn with_fs_list_files(path: str) -> str:
    let cpath = str_to_cstr(path)
    rt_list_files(cpath)

// ── stdin I/O ──────────────────────────────────────────────────────

pub fn with_read_line_stdin() -> str:
    var buf: [4096]u8 = [0 as u8; 4096]
    var len: i64 = 0
    while len < 4095:
        let r = rt_read(0, (&buf as i64 + len) as *mut u8, 1)
        if r <= 0: break
        if buf[len] == 10: break  // '\n'
        len = len + 1
    if len == 0:
        return make_str("" as *const u8, 0)
    alloc_str(&buf as *const u8, len)

pub fn with_read_bytes_stdin(count: i32) -> str:
    if count <= 0:
        return make_str("" as *const u8, 0)
    let buf = rt_alloc(count as i64 + 1)
    var total: i64 = 0
    while total < count as i64:
        let r = rt_read(0, (buf as i64 + total) as *mut u8, (count as i64 - total) as u64)
        if r <= 0: break
        total = total + r
    unsafe *((buf as i64 + total) as *mut u8) = 0
    make_str(buf as *const u8, total)

pub fn with_write_stdout(s: str) -> Unit:
    with_print_str(s)

pub fn with_flush_stdout() -> Unit:
    // No buffering in rt_write
    let _ = 0

// ── String split/lines ─────────────────────────────────────────────

pub fn with_str_split(s: str, delim: str, out: *mut u8, count: *mut i64) -> Unit:
    let sl = str_length(s)
    let dl = str_length(delim)
    if sl == 0 or dl == 0:
        if out as i64 != 0:
            // Store s at out[0] (str is 16 bytes)
            unsafe *(out as *mut str) = s
        if sl > 0:
            unsafe *count = 1
        else:
            unsafe *count = 0
        return
    let sp = str_data(s)
    let dp = str_data(delim)
    var n: i64 = 0
    var start: i64 = 0
    var i: i64 = 0
    while i <= sl - dl:
        if rt_memcmp((sp as i64 + i) as *const u8, dp, dl) == 0:
            if out as i64 != 0:
                let part = make_str((sp as i64 + start) as *const u8, i - start)
                unsafe *((out as i64 + n * 16) as *mut str) = part
            n = n + 1
            start = i + dl
            i = start
        else:
            i = i + 1
    if out as i64 != 0:
        let last = make_str((sp as i64 + start) as *const u8, sl - start)
        unsafe *((out as i64 + n * 16) as *mut str) = last
    n = n + 1
    unsafe *count = n

pub fn with_lines_out(out: *mut u8, s: str) -> Unit:
    with_vec_new_out(out, 16)  // sizeof(str) = 16
    let sp = str_data(s)
    let sl = str_length(s)
    var start: i64 = 0
    var i: i64 = 0
    while i < sl:
        if (unsafe sp[i]) == 10:  // '\n'
            let line = make_str((sp as i64 + start) as *const u8, i - start)
            with_vec_push(out, &line as *const u8)
            start = i + 1
        i = i + 1
    if start < sl:
        let line = make_str((sp as i64 + start) as *const u8, sl - start)
        with_vec_push(out, &line as *const u8)

pub fn with_lines(s: str) -> (*mut u8, i64, i64, i64):
    // Allocate a Vec on the stack-return area
    var v: (i64, i64, i64, i64) = (0, 0, 0, 0)
    with_lines_out(&v as *mut u8, s)
    let vp = &v as *const *mut u8
    let vl = unsafe *((&v as i64 + 8) as *const i64)
    let vc = unsafe *((&v as i64 + 16) as *const i64)
    let ve = unsafe *((&v as i64 + 24) as *const i64)
    (unsafe *vp, vl, vc, ve)

pub fn with_str_join(parts: *mut u8, sep: str) -> str:
    let plen = vec_get_len(parts)
    if plen == 0:
        return make_str("" as *const u8, 0)
    let sep_p = str_data(sep)
    let sep_l = str_length(sep)
    // Calculate total length
    var total: i64 = 0
    var i: i64 = 0
    while i < plen:
        let p = with_vec_get_ptr(parts, i)
        let part_len = unsafe *((p as i64 + 8) as *const i64)
        total = total + part_len
        if i > 0:
            total = total + sep_l
        i = i + 1
    let out = rt_alloc(total + 1)
    var pos: i64 = 0
    i = 0
    while i < plen:
        if i > 0 and sep_l > 0:
            rt_memcpy((out as i64 + pos) as *mut u8, sep_p, sep_l)
            pos = pos + sep_l
        let p = with_vec_get_ptr(parts, i)
        let part_ptr = unsafe *(p as *const *const u8)
        let part_len = unsafe *((p as i64 + 8) as *const i64)
        if part_len > 0:
            rt_memcpy((out as i64 + pos) as *mut u8, part_ptr, part_len)
            pos = pos + part_len
        i = i + 1
    unsafe *((out as i64 + total) as *mut u8) = 0
    make_str(out as *const u8, total)

pub fn with_vec_str_join(parts: *mut u8, sep: str) -> str:
    with_str_join(parts, sep)

pub fn with_str_split_vec(out: *mut u8, s: str, delim: str) -> Unit:
    with_vec_new_out(out, 16)  // sizeof(str) = 16
    let sl = str_length(s)
    if sl == 0: return
    let dl = str_length(delim)
    if dl == 0:
        with_vec_push(out, &s as *const u8)
        return
    let sp = str_data(s)
    let dp = str_data(delim)
    var start: i64 = 0
    var i: i64 = 0
    while i <= sl - dl:
        if rt_memcmp((sp as i64 + i) as *const u8, dp, dl) == 0:
            let part = make_str((sp as i64 + start) as *const u8, i - start)
            with_vec_push(out, &part as *const u8)
            start = i + dl
            i = start
        else:
            i = i + 1
    let last = make_str((sp as i64 + start) as *const u8, sl - start)
    with_vec_push(out, &last as *const u8)

// ── Time ───────────────────────────────────────────────────────────

pub fn with_time_now() -> i64:
    rt_clock_ns()

pub fn with_clock_nanos() -> i64:
    rt_clock_ns()

pub fn with_nanosleep(ns: i64) -> i32:
    rt_nanosleep(ns)

pub fn with_usleep(usecs: i32) -> i32:
    rt_nanosleep(usecs as i64 * 1000)

pub fn with_getpid() -> i32:
    rt_getpid()

pub fn with_raise(sig: i32) -> i32:
    rt_raise(sig)

pub fn with_process_alive(pid: i32) -> i32:
    if pid <= 0:
        return 0
    let rc = rt_kill(pid, 0)
    if rc == 0: 1 else: 0

pub fn with_fs_mkdir(path: str) -> i32:
    let cpath = str_to_cstr(path)
    rt_mkdir(cpath, 493)

pub fn with_str_from_byte(byte: i32) -> str:
    let buf = rt_alloc(2) as *mut u8
    unsafe *buf = byte as u8
    unsafe *((buf as i64 + 1) as *mut u8) = 0
    make_str(buf as *const u8, 1)

// ── Bitwise builtins ───────────────────────────────────────────────

pub fn with_clz(n: i32) -> i32:
    if n == 0: return 32
    var x = n as u32
    var count: i32 = 0
    // Binary search for leading zeros
    if (x & 0xFFFF0000) == 0:
        count = count + 16
        x = x << 16
    if (x & 0xFF000000) == 0:
        count = count + 8
        x = x << 8
    if (x & 0xF0000000) == 0:
        count = count + 4
        x = x << 4
    if (x & 0xC0000000) == 0:
        count = count + 2
        x = x << 2
    if (x & 0x80000000) == 0:
        count = count + 1
    count

pub fn with_ctz(n: i32) -> i32:
    if n == 0: return 32
    var x = n as u32
    var count: i32 = 0
    if (x & 0x0000FFFF) == 0:
        count = count + 16
        x = x >> 16
    if (x & 0x000000FF) == 0:
        count = count + 8
        x = x >> 8
    if (x & 0x0000000F) == 0:
        count = count + 4
        x = x >> 4
    if (x & 0x00000003) == 0:
        count = count + 2
        x = x >> 2
    if (x & 0x00000001) == 0:
        count = count + 1
    count

pub fn with_popcount(n: i32) -> i32:
    var x = n as u32
    // Standard bit-parallel popcount
    x = x - ((x >> 1) & 0x55555555)
    x = (x & 0x33333333) + ((x >> 2) & 0x33333333)
    x = (x + (x >> 4)) & 0x0F0F0F0F
    ((x * 0x01010101) >> 24) as i32

pub fn with_bswap16(n: i16) -> i16:
    let x = n as u16
    (((x >> 8) & 0xFF) | ((x & 0xFF) << 8)) as i16

pub fn with_bswap32(n: i32) -> i32:
    let x = n as u32
    (((x >> 24) & 0xFF) | ((x >> 8) & 0xFF00) | ((x & 0xFF00) << 8) | ((x & 0xFF) << 24)) as i32

pub fn with_bswap64(n: i64) -> i64:
    let x = n as u64
    // Extract each byte
    let b0 = x & 0xFF                // byte 0 (least significant)
    let b1 = (x >> 8) & 0xFF         // byte 1
    let b2 = (x >> 16) & 0xFF        // byte 2
    let b3 = (x >> 24) & 0xFF        // byte 3
    let b4 = (x >> 32) & 0xFF        // byte 4
    let b5 = (x >> 40) & 0xFF        // byte 5
    let b6 = (x >> 48) & 0xFF        // byte 6
    let b7 = (x >> 56) & 0xFF        // byte 7 (most significant)
    // Reassemble in reverse order
    let r = (b0 << 56) | (b1 << 48) | (b2 << 40) | (b3 << 32) | (b4 << 24) | (b5 << 16) | (b6 << 8) | b7
    r as i64

pub fn with_clzl(n: i64) -> i32:
    if n == 0: return 64
    var x = n as u64
    var count: i32 = 0
    if (x & (0xFFFFFFFF as u64 << 32)) == 0:
        count = count + 32
        x = x << 32
    if (x & (0xFFFF as u64 << 48)) == 0:
        count = count + 16
        x = x << 16
    if (x & (0xFF as u64 << 56)) == 0:
        count = count + 8
        x = x << 8
    if (x & (0xF as u64 << 60)) == 0:
        count = count + 4
        x = x << 4
    if (x & (3 as u64 << 62)) == 0:
        count = count + 2
        x = x << 2
    if (x & (1 as u64 << 63)) == 0:
        count = count + 1
    count

pub fn with_clzll(n: i64) -> i32:
    with_clzl(n)

pub fn with_ctzl(n: i64) -> i32:
    if n == 0: return 64
    var x = n as u64
    var count: i32 = 0
    if (x & 0x00000000FFFFFFFF) == 0:
        count = count + 32
        x = x >> 32
    if (x & 0x000000000000FFFF) == 0:
        count = count + 16
        x = x >> 16
    if (x & 0x00000000000000FF) == 0:
        count = count + 8
        x = x >> 8
    if (x & 0x000000000000000F) == 0:
        count = count + 4
        x = x >> 4
    if (x & 0x0000000000000003) == 0:
        count = count + 2
        x = x >> 2
    if (x & 0x0000000000000001) == 0:
        count = count + 1
    count

pub fn with_ctzll(n: i64) -> i32:
    with_ctzl(n)

pub fn with_abs(n: i32) -> i32:
    if n < 0: 0 - n else: n

// ── Misc ───────────────────────────────────────────────────────────

pub fn with_fill_random(buf: *mut u8, len: i64) -> Unit:
    rt_fill_random(buf, len as u64)

// ── Codegen loop state ─────────────────────────────────────────────
// Used by LLVM codegen for break/continue within loops.

var loop_break_bbs: [256]i64 = [0 as i64; 256]
var loop_continue_bbs: [256]i64 = [0 as i64; 256]
var loop_result_bbs: [256]i64 = [0 as i64; 256]

pub fn with_codegen_loop_set_break(idx: i32, bb: i64) -> Unit:
    if idx >= 0 and idx < 256:
        loop_break_bbs[idx] = bb

pub fn with_codegen_loop_set_continue(idx: i32, bb: i64) -> Unit:
    if idx >= 0 and idx < 256:
        loop_continue_bbs[idx] = bb

pub fn with_codegen_loop_set_result(idx: i32, val: i64) -> Unit:
    if idx >= 0 and idx < 256:
        loop_result_bbs[idx] = val

pub fn with_codegen_loop_get_break(idx: i32) -> i64:
    if idx >= 0 and idx < 256:
        return loop_break_bbs[idx]
    0

pub fn with_codegen_loop_get_continue(idx: i32) -> i64:
    if idx >= 0 and idx < 256:
        return loop_continue_bbs[idx]
    0

pub fn with_codegen_loop_get_result(idx: i32) -> i64:
    if idx >= 0 and idx < 256:
        return loop_result_bbs[idx]
    0

// with_install_interrupt_handlers, with_raise_stack_limit,
// with_interrupt_requested: provided by compat_runtime.w (need libc sigaction)

// ── Network stubs ──────────────────────────────────────────────────

pub fn with_net_tcp_listen(port: i32, backlog: i32) -> i32:
    let _ = port
    let _ = backlog
    -1

pub fn with_net_tcp_accept(sock: i32) -> i32:
    let _ = sock
    -1

pub fn with_net_udp_bind(port: i32) -> i32:
    let _ = port
    -1

// Fiber stubs come from the small runtime stub object when async is absent.
// Strong definitions come from fiber.c when the fiber runtime is linked.

// ── cimport stubs ──────────────────────────────────────────────────

// with_cimport_available: provided by helpers.o (weak) / clang_bridge.o (strong)

pub fn with_extract_runtime_obj(name: str, path: str) -> i32:
    let _ = name
    let _ = path
    // The real extractor is compiler-owned and linked into the self-contained
    // compiler binary. User programs keep a stub here.
    1

// ── Sysinfo ────────────────────────────────────────────────────────

extern fn rt_sysinfo_os() -> str
extern fn rt_sysinfo_arch() -> str

pub fn with_sysinfo_os() -> str:
    rt_sysinfo_os()

pub fn with_sysinfo_arch() -> str:
    rt_sysinfo_arch()

pub fn with_sysinfo_hostname() -> str:
    var buf: [256]u8 = [0 as u8; 256]
    let buf_ptr = (&raw mut buf) as *mut [256]u8 as *mut u8
    if gethostname(buf_ptr, 256 as u64) != 0:
        return make_str("unknown" as *const u8, 7)
    buf[255] = 0
    alloc_str(buf_ptr as *const u8, cstr_len(buf_ptr as *const u8))

// rt_sysinfo wrapper — fills {cpu_cores: i32, memory_total: i64, page_size: i64}
pub fn with_sysinfo(out: *mut u8) -> i32:
    rt_sysinfo(out)

// ── Async Scopes (structured concurrency) ──────────────────────────
// Stable scope handle layout: [count: i32, capacity: i32, entries: *mut u8]
// Async entry layout: [fiber_id: i32, pad: i32, result_buf: *mut u8]

extern fn with_fiber_await(fiber_id: i32) -> Unit
extern fn with_fiber_cleanup_await(fiber_id: i32) -> Unit
extern fn with_fiber_cancel(fiber_id: i32) -> Unit
extern fn with_fiber_in_fiber() -> i32
extern fn with_fiber_yield() -> Unit
extern fn with_runtime_run_one_step() -> Unit
extern fn with_runtime_fiber_is_live(fiber_id: i32) -> i32
extern fn with_runtime_take_completed_fiber(fiber_id: i32, panic_msg_out: *mut *const u8, panic_msg_len_out: *mut i32, cancelled_return_out: *mut i32) -> i32

fn scope_count_ptr(handle: i64) -> *mut i32:
    handle as *mut i32

fn scope_capacity_ptr(handle: i64) -> *mut i32:
    (handle + 4) as *mut i32

fn scope_entries_ptr(handle: i64) -> *mut *mut u8:
    (handle + 8) as *mut *mut u8

pub fn with_scope_create() -> i64:
    let cap = 16
    let entry_size = 16
    let ptr = rt_alloc(16)
    if ptr as i64 == 0:
        return 0
    let entries = rt_alloc((cap * entry_size) as i64)
    if entries as i64 == 0:
        rt_free(ptr)
        return 0
    let count_ptr = ptr as *mut i32
    unsafe:
        *count_ptr = 0
    let cap_ptr = (ptr as i64 + 4) as *mut i32
    unsafe:
        *cap_ptr = cap
    let entries_ptr = (ptr as i64 + 8) as *mut *mut u8
    unsafe:
        *entries_ptr = entries
    ptr as i64

pub fn with_scope_track(handle: i64, fiber_id: i32, result_buf: *mut u8) -> Unit:
    if handle == 0:
        return
    let count_ptr = scope_count_ptr(handle)
    let cap_ptr = scope_capacity_ptr(handle)
    let entries_ptr = scope_entries_ptr(handle)
    let count = unsafe *count_ptr
    let cap = unsafe *cap_ptr
    // pending_grow is declared before entries so assigning it into
    // entries is a view of an earlier (longer-lived) binding (§21.1).
    var pending_grow: *mut u8 = 0 as *mut u8
    var entries = unsafe *entries_ptr
    let entry_size = 16
    if count >= cap:
        let new_cap = cap * 2
        let new_size = new_cap * entry_size
        pending_grow = rt_alloc(new_size as i64)
        if pending_grow as i64 == 0:
            return
        let old_size = count * entry_size
        rt_memcpy(pending_grow, entries as *const u8, old_size as i64)
        rt_free(entries)
        entries = pending_grow
        unsafe:
            *entries_ptr = entries
        unsafe:
            *cap_ptr = new_cap
    let entry = entries as i64 + count as i64 * entry_size
    let slot = entry as *mut i32
    unsafe:
        *slot = fiber_id
    let rbuf_slot = (entry + 8) as *mut *mut u8
    unsafe:
        *rbuf_slot = result_buf
    unsafe:
        *count_ptr = count + 1

fn scope_cleanup_await_capture_panic(fiber_id: i32, first_panic_msg: *mut *const u8, first_panic_len: *mut i32) -> Unit:
    while true:
        var panic_msg: *const u8 = 0 as *const u8
        var panic_msg_len: i32 = 0
        var cancelled_return: i32 = 0
        if with_runtime_take_completed_fiber(
            fiber_id,
            &raw mut panic_msg as *mut *const u8,
            &raw mut panic_msg_len as *mut i32,
            &raw mut cancelled_return as *mut i32
        ) != 0:
            let _ = cancelled_return
            let existing_panic_msg = unsafe *first_panic_msg
            if panic_msg as i64 != 0 and panic_msg_len > 0 and existing_panic_msg as i64 == 0:
                unsafe:
                    *first_panic_msg = panic_msg
                    *first_panic_len = panic_msg_len
            return
        if with_runtime_fiber_is_live(fiber_id) == 0:
            return
        if with_fiber_in_fiber() != 0:
            with_fiber_yield()
        else:
            with_runtime_run_one_step()

pub fn with_scope_await_all(handle: i64) -> Unit:
    if handle == 0:
        return
    let count_ptr = scope_count_ptr(handle)
    let count = unsafe *count_ptr
    let entries = unsafe *scope_entries_ptr(handle)
    if entries as i64 == 0:
        return
    let entry_size = 16

    for i in 0..count:
        let entry = entries as i64 + i as i64 * entry_size
        let slot = entry as *const i32
        let fid = unsafe *slot
        with_fiber_cancel(fid)

    var first_panic_msg: *const u8 = 0 as *const u8
    var first_panic_len: i32 = 0
    for i in 0..count:
        let entry = entries as i64 + i as i64 * entry_size
        let slot = entry as *const i32
        let fid = unsafe *slot
        scope_cleanup_await_capture_panic(fid, &raw mut first_panic_msg as *mut *const u8, &raw mut first_panic_len as *mut i32)
        let rbuf_slot = (entry + 8) as *const *mut u8
        let rbuf = unsafe *rbuf_slot
        if rbuf as i64 != 0:
            rt_free(rbuf)
    if first_panic_msg as i64 != 0 and first_panic_len > 0:
        with_ewrite(make_str(first_panic_msg, first_panic_len as i64))
        with_ewrite("\n")
        rt_exit(134)

pub fn with_scope_destroy(handle: i64) -> Unit:
    if handle == 0:
        return
    let entries = unsafe *scope_entries_ptr(handle)
    if entries as i64 != 0:
        rt_free(entries)
    rt_free(handle as *mut u8)

// ── OS-thread Scopes ──────────────────────────────────────────────
// Stable thread scope handle layout is the same as async scope.
// Thread entry layout: [handle: i64, joined: i32, result: i32]

pub fn with_thread_scope_create() -> i64:
    let cap = 16
    let entry_size = 16
    let ptr = rt_alloc(16)
    if ptr as i64 == 0:
        return 0
    let entries = rt_alloc((cap * entry_size) as i64)
    if entries as i64 == 0:
        rt_free(ptr)
        return 0
    unsafe:
        *(ptr as *mut i32) = 0
    unsafe:
        *((ptr as i64 + 4) as *mut i32) = cap
    unsafe:
        *((ptr as i64 + 8) as *mut *mut u8) = entries
    ptr as i64

pub fn with_thread_scope_track(scope: i64, handle: i64) -> i32:
    if scope == 0:
        return -1
    let count_ptr = scope_count_ptr(scope)
    let cap_ptr = scope_capacity_ptr(scope)
    let entries_ptr = scope_entries_ptr(scope)
    let count = unsafe *count_ptr
    let cap = unsafe *cap_ptr
    // pending_grow precedes entries so the assignment below is a view of
    // an earlier (longer-lived) binding (§21.1).
    var pending_grow: *mut u8 = 0 as *mut u8
    var entries = unsafe *entries_ptr
    let entry_size = 16
    if count >= cap:
        let new_cap = cap * 2
        pending_grow = rt_alloc((new_cap * entry_size) as i64)
        if pending_grow as i64 == 0:
            return -1
        rt_memcpy(pending_grow, entries as *const u8, (count * entry_size) as i64)
        rt_free(entries)
        entries = pending_grow
        unsafe:
            *entries_ptr = entries
        unsafe:
            *cap_ptr = new_cap
    let entry = entries as i64 + count as i64 * entry_size
    unsafe:
        *(entry as *mut i64) = handle
    unsafe:
        *((entry + 8) as *mut i32) = 0
    unsafe:
        *((entry + 12) as *mut i32) = 0
    unsafe:
        *count_ptr = count + 1
    count

pub fn with_thread_scope_join(scope: i64, index: i32, handle: i64) -> i32:
    if scope == 0:
        return with_thread_join(handle)
    let count = unsafe *scope_count_ptr(scope)
    if index < 0 or index >= count:
        return with_thread_join(handle)
    let entries = unsafe *scope_entries_ptr(scope)
    if entries as i64 == 0:
        return with_thread_join(handle)
    let entry = entries as i64 + index as i64 * 16
    let joined_ptr = (entry + 8) as *mut i32
    if unsafe *joined_ptr != 0:
        return unsafe *((entry + 12) as *mut i32)
    let stored_handle = unsafe *(entry as *mut i64)
    let join_handle = if stored_handle != 0: stored_handle else: handle
    let result = with_thread_join(join_handle)
    unsafe:
        *joined_ptr = 1
    unsafe:
        *((entry + 12) as *mut i32) = result
    unsafe:
        *(entry as *mut i64) = 0
    result

pub fn with_thread_scope_join_all(scope: i64) -> Unit:
    if scope == 0:
        return
    let count = unsafe *scope_count_ptr(scope)
    let entries = unsafe *scope_entries_ptr(scope)
    if entries as i64 == 0:
        return
    for i in 0..count:
        let entry = entries as i64 + i as i64 * 16
        let joined_ptr = (entry + 8) as *mut i32
        if unsafe *joined_ptr == 0:
            let handle = unsafe *(entry as *mut i64)
            let result = with_thread_join(handle)
            unsafe:
                *joined_ptr = 1
            unsafe:
                *((entry + 12) as *mut i32) = result
            unsafe:
                *(entry as *mut i64) = 0

pub fn with_thread_scope_destroy(scope: i64) -> Unit:
    if scope == 0:
        return
    let entries = unsafe *scope_entries_ptr(scope)
    if entries as i64 != 0:
        rt_free(entries)
    rt_free(scope as *mut u8)
