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
extern fn rt_sysinfo(out: *mut u8) -> i32
extern fn gethostname(name: *mut u8, len: u64) -> i32

// Filesystem extras (provided by platform backend)
extern fn rt_mkdir(path: *const u8, mode: i32) -> i32
extern fn rt_unlink(path: *const u8) -> i32
extern fn rt_rmdir(path: *const u8) -> i32
extern fn rt_rename(old_path: *const u8, new_path: *const u8) -> i32
extern fn rt_access(path: *const u8, mode: i32) -> i32
// stat is in the core 13 but declared with a different name to avoid confusion
extern fn rt_stat(path: *const u8, out: *mut u8) -> i32

// Random fill (from libSystem)
extern fn arc4random_buf(buf: *mut u8, len: u64)

// ── Float formatting ────────────────────────────────────────────
// Implements f64-to-decimal conversion without libc.
// Locale-independent. NaN→"nan", inf→"inf"/"-inf". Deterministic.

fn f64_is_nan(v: f64) -> bool:
    v != v

fn f64_is_neg(v: f64) -> bool:
    v < 0.0

fn f64_is_zero(v: f64) -> bool:
    v == 0.0 and not f64_is_neg(v)

// Format f64 to buffer, shortest representation. Returns length.
fn rt_f64_to_buf(val: f64, buf: *mut u8, bufsize: i64) -> i64:
    var pos: i64 = 0
    if f64_is_nan(val):
        if bufsize >= 3:
            *((buf as i64 + 0) as *mut u8) = 110  // 'n'
            *((buf as i64 + 1) as *mut u8) = 97   // 'a'
            *((buf as i64 + 2) as *mut u8) = 110  // 'n'
        return 3
    if val > 1.7e308:
        if bufsize >= 3:
            *((buf as i64 + 0) as *mut u8) = 105  // 'i'
            *((buf as i64 + 1) as *mut u8) = 110  // 'n'
            *((buf as i64 + 2) as *mut u8) = 102  // 'f'
        return 3
    if val < -1.7e308:
        if bufsize >= 4:
            *((buf as i64 + 0) as *mut u8) = 45   // '-'
            *((buf as i64 + 1) as *mut u8) = 105  // 'i'
            *((buf as i64 + 2) as *mut u8) = 110  // 'n'
            *((buf as i64 + 3) as *mut u8) = 102  // 'f'
        return 4
    var v = val
    if v < 0.0:
        if pos < bufsize:
            *((buf as i64 + pos) as *mut u8) = 45  // '-'
            pos = pos + 1
        v = 0.0 - v
    if v == 0.0:
        if pos < bufsize:
            *((buf as i64 + pos) as *mut u8) = 48  // '0'
            pos = pos + 1
        return pos
    // Integer part
    let int_part = v as u64
    let frac = v - (int_part as f64)
    var ibuf: [24]u8 = [0 as u8; 24]
    let ilen = u64_to_buf_internal(int_part, &ibuf as *mut u8)
    var ii: i64 = 0
    while ii < ilen and pos < bufsize:
        *((buf as i64 + pos) as *mut u8) = ibuf[ii]
        pos = pos + 1
        ii = ii + 1
    // Fractional part: multiply by 10^6 once to get all digits as integer,
    // avoiding repeated multiply-by-10 drift.
    if frac > 0.000000001:
        if pos < bufsize:
            *((buf as i64 + pos) as *mut u8) = 46  // '.'
            pos = pos + 1
        // Round to 6 decimal places: frac_int = round(frac * 1000000)
        let frac_int = (frac * 1000000.0 + 0.5) as u64
        let frac_start = pos
        // Write exactly 6 digits (with leading zeros)
        var fv = frac_int
        var fdigits: [6]u8 = [0 as u8; 6]
        var fdi: i32 = 5
        while fdi >= 0:
            fdigits[fdi as i64] = (48 + (fv % 10) as i32) as u8
            fv = fv / 10
            fdi = fdi - 1
        var fwi: i32 = 0
        while fwi < 6 and pos < bufsize:
            *((buf as i64 + pos) as *mut u8) = fdigits[fwi as i64]
            pos = pos + 1
            fwi = fwi + 1
        // Trim trailing zeros
        while pos > frac_start and *((buf as i64 + pos - 1) as *const u8) == 48:
            pos = pos - 1
        // If all fractional digits were zero, remove the dot
        if pos == frac_start:
            pos = pos - 1
    pos

// Format f64 with fixed precision. Returns length.
fn rt_f64_to_fixed_buf(val: f64, precision: i32, buf: *mut u8, bufsize: i64) -> i64:
    var pos: i64 = 0
    if f64_is_nan(val):
        if bufsize >= 3:
            *((buf as i64 + 0) as *mut u8) = 110
            *((buf as i64 + 1) as *mut u8) = 97
            *((buf as i64 + 2) as *mut u8) = 110
        return 3
    var v = val
    if v < 0.0:
        if pos < bufsize:
            *((buf as i64 + pos) as *mut u8) = 45
            pos = pos + 1
        v = 0.0 - v
    let int_part = v as u64
    let frac = v - (int_part as f64)
    var ibuf: [24]u8 = [0 as u8; 24]
    let ilen = u64_to_buf_internal(int_part, &ibuf as *mut u8)
    var ii: i64 = 0
    while ii < ilen and pos < bufsize:
        *((buf as i64 + pos) as *mut u8) = ibuf[ii]
        pos = pos + 1
        ii = ii + 1
    if precision > 0:
        if pos < bufsize:
            *((buf as i64 + pos) as *mut u8) = 46
            pos = pos + 1
        // Compute scale = 10^precision, then frac_int = round(frac * scale)
        var scale: f64 = 1.0
        var si: i32 = 0
        while si < precision:
            scale = scale * 10.0
            si = si + 1
        let frac_int = (frac * scale + 0.5) as u64
        // Extract digits from frac_int (right to left)
        var fdigits: [20]u8 = [0 as u8; 20]
        var fv = frac_int
        var fdi: i32 = precision - 1
        while fdi >= 0:
            fdigits[fdi as i64] = (48 + (fv % 10) as i32) as u8
            fv = fv / 10
            fdi = fdi - 1
        // Write digits left to right
        var fwi: i32 = 0
        while fwi < precision and pos < bufsize:
            *((buf as i64 + pos) as *mut u8) = fdigits[fwi as i64]
            pos = pos + 1
            fwi = fwi + 1
    pos

// Internal helper for u64-to-decimal (used by float formatting)
fn u64_to_buf_internal(n: u64, buf: *mut u8) -> i64:
    var tmp: [21]u8 = [0 as u8; 21]
    let tp = &tmp as *mut u8
    var tpos: i64 = 20
    var val = n
    if val == 0:
        *((tp as i64 + tpos) as *mut u8) = 48  // '0'
        tpos = tpos - 1
    else:
        while val > 0:
            *((tp as i64 + tpos) as *mut u8) = (48 + (val % 10) as i32) as u8
            tpos = tpos - 1
            val = val / 10
    let len = 20 - tpos
    var i: i64 = 0
    while i < len:
        *((buf as i64 + i) as *mut u8) = tp[tpos + 1 + i]
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
    *p

fn str_length(s: str) -> i64:
    s.len()

fn make_str(ptr: *const u8, len: i64) -> str:
    let raw = RawStr { ptr: ptr, len: len }
    let p = &raw as *const str
    *p

fn cstr_len(s: *const u8) -> i64:
    if s as i64 == 0:
        return 0
    var n: i64 = 0
    while s[n] != 0:
        n = n + 1
    n

// ── Memory helpers ─────────────────────────────────────────────────

fn rt_memcpy(dst: *mut u8, src: *const u8, n: i64):
    var i: i64 = 0
    while i < n:
        *((dst as i64 + i) as *mut u8) = src[i]
        i = i + 1

fn rt_memcmp(a: *const u8, b: *const u8, n: i64) -> i32:
    var i: i64 = 0
    while i < n:
        let ca = a[i]
        let cb = b[i]
        if ca != cb:
            if (ca as i32) < (cb as i32):
                return -1
            return 1
        i = i + 1
    0

fn rt_memset(dst: *mut u8, c: u8, n: i64):
    var i: i64 = 0
    while i < n:
        *((dst as i64 + i) as *mut u8) = c
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
    (size + 15) & (0 - 16)

fn size_class_block_size(idx: i32) -> i64:
    size_class_size(idx) + RT_ALLOC_HEADER_SIZE

fn alloc_header_ptr(ptr: *const u8) -> *mut u8:
    (ptr as i64 - RT_ALLOC_HEADER_SIZE) as *mut u8

fn alloc_payload_size(ptr: *const u8) -> i64:
    *(alloc_header_ptr(ptr) as *const i64)

fn alloc_store_small_header(block: i64, size: i64):
    *(block as *mut i64) = size

fn small_block_ptr(block: i64) -> *mut u8:
    (block + RT_ALLOC_HEADER_SIZE) as *mut u8

fn free_small_block(block: i64, idx: i32):
    let old_head = get_freelist(idx)
    *(block as *mut i64) = old_head
    set_freelist(idx, block)

fn rt_alloc(size_arg: i64) -> *mut u8:
    let size = alloc_align_size(size_arg)

    if size > RT_LARGE_THRESHOLD:
        // Large allocation: direct rt_mmap with 16-byte header storing size
        let total = size + RT_ALLOC_HEADER_SIZE
        let p = rt_mmap(total as u64)
        if p as i64 == 0:
            rt_exit(99)
        // Store allocation size in header
        *(p as *mut i64) = size
        return (p as i64 + RT_ALLOC_HEADER_SIZE) as *mut u8

    // Small allocation: check freelist keyed by payload size class.
    let idx = size_class_index(size)
    let cls_size = size_class_size(idx)
    let block_size = size_class_block_size(idx)

    let head = get_freelist(idx)
    if head != 0:
        // Pop from freelist. The first 8 bytes of the node store 'next'.
        let next = *(head as *const i64)
        set_freelist(idx, next)
        alloc_store_small_header(head, cls_size)
        return small_block_ptr(head)

    // Carve from slab
    if slab_remaining < block_size:
        let new_slab = rt_mmap(RT_PAGE_SIZE as u64)
        if new_slab as i64 == 0:
            rt_exit(99)
        slab_ptr = new_slab as i64
        slab_remaining = RT_PAGE_SIZE

    let block = slab_ptr
    slab_ptr = slab_ptr + block_size
    slab_remaining = slab_remaining - block_size
    alloc_store_small_header(block, cls_size)
    small_block_ptr(block)

fn rt_free(ptr: *mut u8):
    if ptr as i64 == 0:
        return
    let block = alloc_header_ptr(ptr as *const u8) as i64
    let size = *(block as *const i64)
    if size > RT_LARGE_THRESHOLD:
        rt_munmap(block as *mut u8, (size + RT_ALLOC_HEADER_SIZE) as u64)
        return
    let idx = size_class_index(size)
    free_small_block(block, idx)

fn rt_free_sized(ptr: *mut u8, size_arg: i64):
    let _ = size_arg
    rt_free(ptr)

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
fn str_to_cstr(s: str) -> *const u8:
    let slen = str_length(s)
    let buf = rt_alloc(slen + 1)
    rt_memcpy(buf, str_data(s), slen)
    *((buf as i64 + slen) as *mut u8) = 0
    buf as *const u8

// ── Exported allocator/memory API for std/mem.w ───────────────────

@[c_export("with_alloc")]
pub fn alloc_export(size: i64) -> *mut u8:
    rt_alloc(size)

@[c_export("with_alloc_zeroed")]
pub fn alloc_zeroed_export(count: i64, size: i64) -> *mut u8:
    let total = count * size
    let ptr = rt_alloc(total)
    if ptr as i64 != 0 and total > 0:
        rt_memset(ptr, 0, total)
    ptr

@[c_export("with_realloc")]
pub fn realloc_export(ptr: *mut u8, old_size: i64, new_size: i64) -> *mut u8:
    rt_realloc(ptr, old_size, new_size)

@[c_export("with_free")]
pub fn free_export(ptr: *mut u8):
    rt_free(ptr)

@[c_export("with_free_sized")]
pub fn free_sized_export(ptr: *mut u8, size: i64):
    rt_free_sized(ptr, size)

@[c_export("with_memcpy")]
pub fn memcpy_export(dst: *mut u8, src: *const u8, n: i64):
    rt_memcpy(dst, src, n)

@[c_export("with_memmove")]
pub fn memmove_export(dst: *mut u8, src: *const u8, n: i64):
    // Simple: copy to temp buffer then to dst (handles overlap)
    if n <= 0: return
    let tmp = rt_alloc(n)
    rt_memcpy(tmp, src, n)
    rt_memcpy(dst, tmp as *const u8, n)
    rt_free_sized(tmp, n)

@[c_export("with_memset")]
pub fn memset_export(dst: *mut u8, c: i32, n: i64):
    rt_memset(dst, c as u8, n)

@[c_export("with_memcmp")]
pub fn memcmp_export(a: *const u8, b: *const u8, n: i64) -> i32:
    rt_memcmp(a, b, n)

// Allocate a new str from a buffer
fn alloc_str(buf: *const u8, len: i64) -> str:
    let out = rt_alloc(len + 1)
    rt_memcpy(out, buf, len)
    *((out as i64 + len) as *mut u8) = 0
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

@[c_export("with_runtime_set_argv")]
pub fn runtime_set_argv(argc: i32, argv: *const *const u8):
    saved_argc = argc
    saved_argv_raw = argv as i64
    rt_store_args(argc, argv)

// with_runtime_init, with_runtime_run, with_runtime_shutdown come from the
// small runtime stub object when async is absent, or from fiber.c when the
// fiber runtime is linked. rt_core.w does not provide them directly.

// ── Print functions ────────────────────────────────────────────────

@[c_export("with_print_str")]
pub fn print_str(s: str):
    let p = str_data(s)
    let n = str_length(s)
    if p as i64 != 0 and n > 0:
        write_all(1, p, n)

@[c_export("with_println_str")]
pub fn println_str(s: str):
    let p = str_data(s)
    let n = str_length(s)
    if p as i64 != 0 and n > 0:
        write_all(1, p, n)
    let _ = rt_write(1, "\n" as *const u8, 1)

@[c_export("with_println_i32")]
pub fn println_i32(n: i32):
    var buf: [16]u8 = [0 as u8; 16]
    let len = i64_to_buf(n as i64, &buf as *mut u8)
    write_all(1, &buf as *const u8, len)
    let _ = rt_write(1, "\n" as *const u8, 1)

@[c_export("with_println_i64")]
pub fn println_i64(n: i64):
    var buf: [24]u8 = [0 as u8; 24]
    let len = i64_to_buf(n, &buf as *mut u8)
    write_all(1, &buf as *const u8, len)
    let _ = rt_write(1, "\n" as *const u8, 1)

@[c_export("with_println_bool")]
pub fn println_bool(b: i32):
    if b != 0:
        write_all(1, "true\n" as *const u8, 5)
    else:
        write_all(1, "false\n" as *const u8, 6)

@[c_export("with_write")]
pub fn write_str(s: str):
    print_str(s)

@[c_export("with_ewrite")]
pub fn ewrite(s: str):
    let p = str_data(s)
    let n = str_length(s)
    if p as i64 != 0 and n > 0:
        write_all(2, p, n)

@[c_export("with_eprintln")]
pub fn eprintln(s: str):
    let p = str_data(s)
    let n = str_length(s)
    if p as i64 != 0 and n > 0:
        write_all(2, p, n)
    let _ = rt_write(2, "\n" as *const u8, 1)

@[c_export("with_eprint")]
pub fn eprint(s: str):
    eprintln(s)

// ── Panic / assert ─────────────────────────────────────────────────

@[c_export("with_panic_core")]
pub fn panic_impl(msg: str, file: str, line: i32):
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

@[c_export("with_assert")]
pub fn assert_impl(cond: i32, msg: str):
    if cond == 0:
        let empty = make_str("" as *const u8, 0)
        panic_impl(msg, empty, 0)

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
            tmp[pos] = digits[digit_idx]
            n = n / (base as u64)
            pos = pos - 1
    let len = 65 - pos as i64
    rt_memcpy(buf, (&tmp as i64 + (pos + 1) as i64) as *const u8, len)
    len

// ── with_fmt_* functions ───────────────────────────────────────────

@[c_export("with_fmt_i32")]
pub fn fmt_i32(n: i32) -> str:
    var buf: [16]u8 = [0 as u8; 16]
    let len = i64_to_buf(n as i64, &buf as *mut u8)
    alloc_str(&buf as *const u8, len)

@[c_export("with_fmt_i64")]
pub fn fmt_i64(n: i64) -> str:
    var buf: [24]u8 = [0 as u8; 24]
    let len = i64_to_buf(n, &buf as *mut u8)
    alloc_str(&buf as *const u8, len)

@[c_export("with_fmt_u32")]
pub fn fmt_u32(n: u32) -> str:
    var buf: [16]u8 = [0 as u8; 16]
    let len = u64_to_buf(n as u64, &buf as *mut u8)
    alloc_str(&buf as *const u8, len)

@[c_export("with_fmt_u64")]
pub fn fmt_u64(n: u64) -> str:
    var buf: [24]u8 = [0 as u8; 24]
    let len = u64_to_buf(n, &buf as *mut u8)
    alloc_str(&buf as *const u8, len)

@[c_export("with_fmt_bool")]
pub fn fmt_bool(b: i32) -> str:
    if b != 0:
        return make_str("true" as *const u8, 4)
    make_str("false" as *const u8, 5)

@[c_export("with_fmt_str")]
pub fn fmt_str(s: str) -> str:
    s

@[c_export("with_fmt_str_debug")]
pub fn fmt_str_debug(s: str) -> str:
    let slen = str_length(s)
    let out_len = slen + 2
    let out = rt_alloc(out_len + 1)
    *(out as *mut u8) = 34  // '"'
    let sp = str_data(s)
    if sp as i64 != 0 and slen > 0:
        rt_memcpy((out as i64 + 1) as *mut u8, sp, slen)
    *((out as i64 + slen + 1) as *mut u8) = 34  // '"'
    *((out as i64 + out_len) as *mut u8) = 0
    make_str(out as *const u8, out_len)

// ── Float formatting ───────────────────────────────────────────────

@[c_export("with_fmt_f64")]
pub fn fmt_f64(n: f64) -> str:
    var buf: [64]u8 = [0 as u8; 64]
    let len = rt_f64_to_buf(n, &buf as *mut u8, 64)
    alloc_str(&buf as *const u8, len)

@[c_export("with_f64_to_string")]
pub fn f64_to_string(n: f64) -> str:
    fmt_f64(n)

// ── FmtBuffer (f-string formatting via buffer) ────────────────────
//
// FmtBuffer layout: { ptr: *mut u8, len: i64, cap: i64 }
// Stored as 24 bytes allocated on the heap.

let FMT_BUF_SIZE: i64 = 24
let FMT_BUF_OFF_PTR: i64 = 0
let FMT_BUF_OFF_LEN: i64 = 8
let FMT_BUF_OFF_CAP: i64 = 16

fn fb_ptr(b: *mut u8) -> *mut u8:
    *(b as *const *mut u8)
fn fb_len(b: *mut u8) -> i64:
    *((b as i64 + FMT_BUF_OFF_LEN) as *const i64)
fn fb_cap(b: *mut u8) -> i64:
    *((b as i64 + FMT_BUF_OFF_CAP) as *const i64)
fn fb_set_ptr(b: *mut u8, v: *mut u8):
    *(b as *mut *mut u8) = v
fn fb_set_len(b: *mut u8, v: i64):
    *((b as i64 + FMT_BUF_OFF_LEN) as *mut i64) = v
fn fb_set_cap(b: *mut u8, v: i64):
    *((b as i64 + FMT_BUF_OFF_CAP) as *mut i64) = v

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

@[c_export("with_fmt_buf_new")]
pub fn fmt_buf_new() -> *mut u8:
    let b = rt_alloc(FMT_BUF_SIZE)
    fb_set_ptr(b, rt_alloc(64))
    fb_set_len(b, 0)
    fb_set_cap(b, 64)
    b

@[c_export("with_fmt_buf_write_str")]
pub fn fmt_buf_write_str(b: *mut u8, s: str):
    let slen = str_length(s)
    if slen > 0:
        fb_append(b, str_data(s), slen)

@[c_export("with_fmt_buf_write_i64")]
pub fn fmt_buf_write_i64(b: *mut u8, val: i64):
    var tmp: [24]u8 = [0 as u8; 24]
    let len = i64_to_buf(val, &tmp as *mut u8)
    fb_append(b, &tmp as *const u8, len)

@[c_export("with_fmt_buf_write_f64")]
pub fn fmt_buf_write_f64(b: *mut u8, val: f64):
    var tmp: [64]u8 = [0 as u8; 64]
    let len = rt_f64_to_buf(val, &tmp as *mut u8, 64)
    fb_append(b, &tmp as *const u8, len)

@[c_export("with_fmt_buf_write_bool")]
pub fn fmt_buf_write_bool(b: *mut u8, val: i32):
    if val != 0:
        fb_append(b, "true" as *const u8, 4)
    else:
        fb_append(b, "false" as *const u8, 5)

@[c_export("with_fmt_buf_write_char")]
pub fn fmt_buf_write_char(b: *mut u8, c: u8):
    fb_grow(b, 1)
    let p = fb_ptr(b)
    let cur = fb_len(b)
    *((p as i64 + cur) as *mut u8) = c
    fb_set_len(b, cur + 1)

@[c_export("with_fmt_buf_write_i64_spec")]
pub fn fmt_buf_write_i64_spec(b: *mut u8, val: i64, is_unsigned: i32, flags: i64, width: i32, precision: i32, mode: i32):
    let s = fmt_int_spec(val, is_unsigned, flags, width, precision, mode)
    fmt_buf_write_str(b, s)

@[c_export("with_fmt_buf_write_f64_spec")]
pub fn fmt_buf_write_f64_spec(b: *mut u8, val: f64, flags: i64, width: i32, precision: i32, mode: i32):
    let s = fmt_f64_spec(val, flags, width, precision, mode)
    fmt_buf_write_str(b, s)

@[c_export("with_fmt_buf_write_str_spec")]
pub fn fmt_buf_write_str_spec(b: *mut u8, val: str, flags: i64, width: i32, precision: i32):
    let s = fmt_str_spec(val, flags, width, precision)
    fmt_buf_write_str(b, s)

@[c_export("with_fmt_buf_write_debug")]
pub fn fmt_buf_write_debug(b: *mut u8, val: str):
    let s = fmt_str_debug(val)
    fmt_buf_write_str(b, s)

@[c_export("with_fmt_buf_finish")]
pub fn fmt_buf_finish(b: *mut u8) -> str:
    let p = fb_ptr(b)
    let len = fb_len(b)
    // Null-terminate
    fb_grow(b, 1)
    let fp = fb_ptr(b)  // may have moved after grow
    *((fp as i64 + len) as *mut u8) = 0
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
    *((out as i64 + width) as *mut u8) = 0
    make_str(out as *const u8, width)

// ── with_fmt_int_spec ──────────────────────────────────────────────

@[c_export("with_fmt_int_spec")]
pub fn fmt_int_spec(val_arg: i64, is_unsigned: i32, flags: i64, width: i32, precision: i32, mode: i32) -> str:
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
            *((out as i64 + width as i64) as *mut u8) = 0
            return make_str(out as *const u8, width as i64)
        return pad_str(&buf as *const u8, len, width as i64, fill_char, align_mode)

    alloc_str(&buf as *const u8, len)

// ── with_fmt_f64_spec ──────────────────────────────────────────────

@[c_export("with_fmt_f64_spec")]
pub fn fmt_f64_spec(val: f64, flags: i64, width: i32, precision: i32, mode: i32) -> str:
    let _ = mode
    var buf: [64]u8 = [0 as u8; 64]
    var len: i64 = 0

    if precision >= 0:
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
            *((out as i64 + width as i64) as *mut u8) = 0
            return make_str(out as *const u8, width as i64)
        return pad_str(&buf as *const u8, len, width as i64, fill_char, align_mode)

    alloc_str(&buf as *const u8, len)

// ── with_fmt_str_spec ──────────────────────────────────────────────

@[c_export("with_fmt_str_spec")]
pub fn fmt_str_spec(val: str, flags: i64, width: i32, precision: i32) -> str:
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

@[c_export("with_str_concat")]
pub fn str_concat(a: str, b: str) -> str:
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
    *((out as i64 + total) as *mut u8) = 0
    make_str(out as *const u8, total)

@[c_export("with_str_eq")]
pub fn str_eq(a: str, b: str) -> i32:
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

@[c_export("with_str_clone")]
pub fn str_clone(s: str) -> str:
    let slen = str_length(s)
    if slen == 0:
        return make_str("" as *const u8, 0)
    let out = rt_alloc(slen + 1)
    rt_memcpy(out, str_data(s), slen)
    *((out as i64 + slen) as *mut u8) = 0
    make_str(out as *const u8, slen)

@[c_export("with_str_len")]
pub fn str_len_export(s: str) -> i64:
    str_length(s)

@[c_export("with_str_byte_at")]
pub fn str_byte_at(s: str, idx: i64) -> i32:
    let slen = str_length(s)
    if idx < 0 or idx >= slen:
        return 0
    let p = str_data(s)
    (p[idx]) as i32

@[c_export("with_str_slice")]
pub fn str_slice(s: str, start_arg: i64, end_arg: i64) -> str:
    let slen = str_length(s)
    var start = start_arg
    var end = end_arg
    if start < 0: start = 0
    if end > slen: end = slen
    if start >= end:
        return make_str("" as *const u8, 0)
    make_str((str_data(s) as i64 + start) as *const u8, end - start)

@[c_export("with_str_substr")]
pub fn str_substr(s: str, start_arg: i64, length_arg: i64) -> str:
    let slen = str_length(s)
    var start = start_arg
    var length = length_arg
    if start < 0: start = 0
    if start >= slen:
        return make_str("" as *const u8, 0)
    if start + length > slen:
        length = slen - start
    make_str((str_data(s) as i64 + start) as *const u8, length)

@[c_export("with_str_starts_with")]
pub fn str_starts_with(s: str, prefix: str) -> i32:
    let pl = str_length(prefix)
    let sl = str_length(s)
    if pl > sl: return 0
    if rt_memcmp(str_data(s), str_data(prefix), pl) == 0: 1 else: 0

@[c_export("with_str_ends_with")]
pub fn str_ends_with(s: str, suffix: str) -> i32:
    let sufl = str_length(suffix)
    let sl = str_length(s)
    if sufl > sl: return 0
    let offset = sl - sufl
    if rt_memcmp((str_data(s) as i64 + offset) as *const u8, str_data(suffix), sufl) == 0: 1 else: 0

@[c_export("with_str_contains")]
pub fn str_contains(hay: str, needle: str) -> i32:
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

@[c_export("with_str_index_of")]
pub fn str_index_of(hay: str, needle: str) -> i64:
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

@[c_export("with_str_trim")]
pub fn str_trim(s: str) -> str:
    let slen = str_length(s)
    let sp = str_data(s)
    var start: i64 = 0
    while start < slen:
        let c = sp[start]
        if c != 32 and c != 9 and c != 10 and c != 13:  // ' ', '\t', '\n', '\r'
            break
        start = start + 1
    var end = slen
    while end > start:
        let c = sp[end - 1]
        if c != 32 and c != 9 and c != 10 and c != 13:
            break
        end = end - 1
    if start == 0 and end == slen:
        return s
    make_str((sp as i64 + start) as *const u8, end - start)

@[c_export("with_str_to_upper")]
pub fn str_to_upper(s: str) -> str:
    let slen = str_length(s)
    if slen == 0: return s
    let out = rt_alloc(slen + 1)
    let sp = str_data(s)
    var i: i64 = 0
    while i < slen:
        let c = sp[i]
        if c >= 97 and c <= 122:  // 'a' to 'z'
            *((out as i64 + i) as *mut u8) = c - 32
        else:
            *((out as i64 + i) as *mut u8) = c
        i = i + 1
    *((out as i64 + slen) as *mut u8) = 0
    make_str(out as *const u8, slen)

@[c_export("with_str_to_lower")]
pub fn str_to_lower(s: str) -> str:
    let slen = str_length(s)
    if slen == 0: return s
    let out = rt_alloc(slen + 1)
    let sp = str_data(s)
    var i: i64 = 0
    while i < slen:
        let c = sp[i]
        if c >= 65 and c <= 90:  // 'A' to 'Z'
            *((out as i64 + i) as *mut u8) = c + 32
        else:
            *((out as i64 + i) as *mut u8) = c
        i = i + 1
    *((out as i64 + slen) as *mut u8) = 0
    make_str(out as *const u8, slen)

@[c_export("with_str_repeat")]
pub fn str_repeat(s: str, count: i64) -> str:
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
    *((out as i64 + total) as *mut u8) = 0
    make_str(out as *const u8, total)

@[c_export("with_str_replace")]
pub fn str_replace(s: str, old: str, new_s: str) -> str:
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
            *((out as i64 + j) as *mut u8) = sp[i]
            j = j + 1
            i = i + 1
    *((out as i64 + new_len) as *mut u8) = 0
    make_str(out as *const u8, new_len)

@[c_export("with_str_from_cstr")]
pub fn str_from_cstr(s: *const u8) -> str:
    let len = cstr_len(s)
    make_str(s, len)

@[c_export("with_str_hash")]
pub fn str_hash(s: str) -> u64:
    fnv_hash(str_data(s), str_length(s))

// ── Conversion functions ───────────────────────────────────────────

@[c_export("with_i32_to_str")]
pub fn i32_to_str(n: i32) -> str:
    fmt_i32(n)

@[c_export("i32_to_str")]
pub fn i32_to_str_alias(n: i32) -> str:
    fmt_i32(n)

@[c_export("with_i64_to_str")]
pub fn i64_to_str(n: i64) -> str:
    fmt_i64(n)

@[c_export("i64_to_string")]
pub fn i64_to_string_alias(n: i64) -> str:
    fmt_i64(n)

@[c_export("with_bool_to_str")]
pub fn bool_to_str(b: i32) -> str:
    fmt_bool(b)

@[c_export("str_from_byte")]
pub fn str_from_byte_export(b: i32) -> str:
    let buf = rt_alloc(2)
    *buf = (b & 255) as u8
    *((buf as i64 + 1) as *mut u8) = 0
    make_str(buf as *const u8, 1)

@[c_export("with_parse_i64")]
pub fn parse_i64(s: str) -> i64:
    let slen = str_length(s)
    if slen == 0: return 0
    let sp = str_data(s)
    var result: i64 = 0
    var neg: i32 = 0
    var i: i64 = 0
    let first = *(sp as *const u8)
    if first == 45:  // '-'
        neg = 1
        i = 1
    else if first == 43:  // '+'
        i = 1
    while i < slen:
        let c = sp[i]
        if c < 48 or c > 57:
            break
        result = result * 10 + (c - 48) as i64
        i = i + 1
    if neg != 0: 0 - result else: result

@[c_export("with_parse_float")]
pub fn parse_float(s: str) -> f64:
    let slen = str_length(s)
    if slen == 0: return 0.0
    let sp = str_data(s)
    var result: f64 = 0.0
    var neg: i32 = 0
    var i: i64 = 0
    let first = *(sp as *const u8)
    if first == 45:
        neg = 1
        i = 1
    else if first == 43:
        i = 1
    // Integer part
    while i < slen:
        let c = sp[i]
        if c < 48 or c > 57:
            break
        result = result * 10.0 + (c - 48) as f64
        i = i + 1
    // Fractional part
    if i < slen and sp[i] == 46:  // '.'
        i = i + 1
        var frac: f64 = 0.1
        while i < slen:
            let c = sp[i]
            if c < 48 or c > 57:
                break
            result = result + (c - 48) as f64 * frac
            frac = frac * 0.1
            i = i + 1
    if neg != 0: 0.0 - result else: result

// ── Args and environment ───────────────────────────────────────────

@[c_export("with_arg_count")]
pub fn arg_count() -> i32:
    saved_argc

@[c_export("with_arg_at")]
pub fn arg_at(idx: i32) -> str:
    if idx < 0 or idx >= saved_argc or saved_argv_raw == 0:
        return make_str("" as *const u8, 0)
    let s = *((saved_argv_raw + idx as i64 * 8) as *const *const u8)
    make_str(s, cstr_len(s))

@[c_export("with_getenv_str")]
pub fn getenv_str(name: str) -> str:
    let cname = str_to_cstr(name)
    let val = rt_getenv(cname)
    if val as i64 == 0:
        return make_str("" as *const u8, 0)
    make_str(val, cstr_len(val))

@[c_export("with_getenv")]
pub fn getenv_impl(name: str) -> str:
    getenv_str(name)

// with_setenv_str: provided by compat_runtime.w (needs libc)

// ── Vec operations ─────────────────────────────────────────────────
//
// Vec layout: { ptr: *mut u8, len: i64, cap: i64, elem_size: i64 }
// We access it via pointer casts since we can't import the Vec type.

// Offsets into Vec struct (each field is 8 bytes):
// 0: ptr, 8: len, 16: cap, 24: elem_size

fn vec_get_ptr_field(v: *mut u8) -> *mut u8:
    *(v as *const *mut u8)

fn vec_set_ptr_field(v: *mut u8, p: *mut u8):
    *(v as *mut *mut u8) = p

fn vec_get_len(v: *mut u8) -> i64:
    *((v as i64 + 8) as *const i64)

fn vec_set_len(v: *mut u8, n: i64):
    *((v as i64 + 8) as *mut i64) = n

fn vec_get_cap(v: *mut u8) -> i64:
    *((v as i64 + 16) as *const i64)

fn vec_set_cap(v: *mut u8, n: i64):
    *((v as i64 + 16) as *mut i64) = n

fn vec_get_elem_size(v: *mut u8) -> i64:
    *((v as i64 + 24) as *const i64)

fn vec_set_elem_size(v: *mut u8, n: i64):
    *((v as i64 + 24) as *mut i64) = n

@[c_export("with_vec_new_out")]
pub fn vec_new_out(out: *mut u8, elem_size: i64):
    vec_set_ptr_field(out, 0 as *mut u8)
    vec_set_len(out, 0)
    vec_set_cap(out, 0)
    vec_set_elem_size(out, elem_size)

@[c_export("with_vec_new")]
pub fn vec_new(elem_size: i64) -> (*mut u8, i64, i64, i64):
    // Return a tuple that matches Vec layout
    (0 as *mut u8, 0 as i64, 0 as i64, elem_size)

@[c_export("with_vec_new_with_capacity_out")]
pub fn vec_new_with_capacity_out(out: *mut u8, elem_size: i64, cap: i64):
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

@[c_export("with_vec_push")]
pub fn vec_push(v: *mut u8, elem: *const u8):
    let vlen = vec_get_len(v)
    let vcap = vec_get_cap(v)
    if vlen >= vcap:
        vec_grow(v)
    let es = vec_get_elem_size(v)
    let dst = (vec_get_ptr_field(v) as i64 + vlen * es) as *mut u8
    rt_memcpy(dst, elem, es)
    vec_set_len(v, vlen + 1)

@[c_export("with_vec_get_ptr")]
pub fn vec_get_ptr(v: *mut u8, idx: i64) -> *mut u8:
    let vlen = vec_get_len(v)
    if idx < 0 or idx >= vlen:
        return 0 as *mut u8
    let es = vec_get_elem_size(v)
    (vec_get_ptr_field(v) as i64 + idx * es) as *mut u8

@[c_export("with_vec_len")]
pub fn vec_len(v: *mut u8) -> i64:
    vec_get_len(v)

@[c_export("with_vec_clear")]
pub fn vec_clear(v: *mut u8):
    vec_set_len(v, 0)

@[c_export("with_vec_push_i32")]
pub fn vec_push_i32(v: *mut u8, val: i32):
    vec_push(v, &val as *const u8)

@[c_export("with_vec_get_i32")]
pub fn vec_get_i32(v: *mut u8, idx: i64) -> i32:
    let p = vec_get_ptr(v, idx)
    if p as i64 != 0:
        return *(p as *const i32)
    0

@[c_export("with_vec_push_i64")]
pub fn vec_push_i64(v: *mut u8, val: i64):
    vec_push(v, &val as *const u8)

@[c_export("with_vec_get_i64")]
pub fn vec_get_i64(v: *mut u8, idx: i64) -> i64:
    let p = vec_get_ptr(v, idx)
    if p as i64 != 0:
        return *(p as *const i64)
    0

@[c_export("with_vec_push_str")]
pub fn vec_push_str(v: *mut u8, val: str):
    vec_push(v, &val as *const u8)

@[c_export("with_vec_get_str")]
pub fn vec_get_str(v: *mut u8, idx: i64) -> str:
    let p = vec_get_ptr(v, idx)
    if p as i64 != 0:
        return *(p as *const str)
    make_str("" as *const u8, 0)

@[c_export("with_vec_push_bool")]
pub fn vec_push_bool(v: *mut u8, val: i32):
    vec_push(v, &val as *const u8)

@[c_export("with_vec_get_bool")]
pub fn vec_get_bool(v: *mut u8, idx: i64) -> i32:
    vec_get_i32(v, idx)

@[c_export("with_ptr_get_i32")]
pub fn ptr_get_i32(ptr: *const u8, index: i64) -> i32:
    *((ptr as i64 + index * 4) as *const i32)

@[c_export("with_vec_set_i32")]
pub fn vec_set_i32(v: *mut u8, idx: i64, val: i32):
    let vlen = vec_get_len(v)
    if idx >= 0 and idx < vlen:
        let es = vec_get_elem_size(v)
        *((vec_get_ptr_field(v) as i64 + idx * es) as *mut i32) = val

@[c_export("with_vec_set_i64")]
pub fn vec_set_i64(v: *mut u8, idx: i64, val: i64):
    let vlen = vec_get_len(v)
    if idx >= 0 and idx < vlen:
        let es = vec_get_elem_size(v)
        *((vec_get_ptr_field(v) as i64 + idx * es) as *mut i64) = val

@[c_export("with_vec_remove")]
pub fn vec_remove(v: *mut u8, idx: i64):
    let vlen = vec_get_len(v)
    if idx < 0 or idx >= vlen: return
    let base = vec_get_ptr_field(v)
    let es = vec_get_elem_size(v)
    var i = idx
    while i < vlen - 1:
        rt_memcpy((base as i64 + i * es) as *mut u8, (base as i64 + (i + 1) * es) as *const u8, es)
        i = i + 1
    vec_set_len(v, vlen - 1)

@[c_export("with_vec_pop_i32")]
pub fn vec_pop_i32(v: *mut u8) -> i32:
    let vlen = vec_get_len(v)
    if vlen == 0: return 0
    vec_set_len(v, vlen - 1)
    let es = vec_get_elem_size(v)
    *((vec_get_ptr_field(v) as i64 + (vlen - 1) * es) as *const i32)

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
    *(m as *const *mut u8)
fn hm_vals(m: i64) -> *mut u8:
    *((m + HM_OFF_VALS) as *const *mut u8)
fn hm_occ(m: i64) -> *mut u8:
    *((m + HM_OFF_OCC) as *const *mut u8)
fn hm_cap(m: i64) -> i64:
    *((m + HM_OFF_CAP) as *const i64)
fn hm_len(m: i64) -> i64:
    *((m + HM_OFF_LEN) as *const i64)
fn hm_key_size(m: i64) -> i64:
    *((m + HM_OFF_KSZ) as *const i64)
fn hm_val_size(m: i64) -> i64:
    *((m + HM_OFF_VSZ) as *const i64)
fn hm_is_str_key(m: i64) -> i32:
    *((m + HM_OFF_ISSTR) as *const i32)

fn hm_set_keys(m: i64, v: *mut u8):
    *(m as *mut *mut u8) = v
fn hm_set_vals(m: i64, v: *mut u8):
    *((m + HM_OFF_VALS) as *mut *mut u8) = v
fn hm_set_occ(m: i64, v: *mut u8):
    *((m + HM_OFF_OCC) as *mut *mut u8) = v
fn hm_set_cap(m: i64, v: i64):
    *((m + HM_OFF_CAP) as *mut i64) = v
fn hm_set_len(m: i64, v: i64):
    *((m + HM_OFF_LEN) as *mut i64) = v
fn hm_set_key_size(m: i64, v: i64):
    *((m + HM_OFF_KSZ) as *mut i64) = v
fn hm_set_val_size(m: i64, v: i64):
    *((m + HM_OFF_VSZ) as *mut i64) = v
fn hm_set_is_str_key(m: i64, v: i32):
    *((m + HM_OFF_ISSTR) as *mut i32) = v

// FNV-1a hash
fn fnv_hash(data: *const u8, len: i64) -> u64:
    // FNV offset basis: 14695981039346656037
    var h: u64 = 14695981039346656037
    var i: i64 = 0
    while i < len:
        let byte = data[i]
        h = h ^ (byte as u64)
        // FNV prime: 1099511628211
        h = h * 1099511628211
        i = i + 1
    h

fn hm_hash_key(m: i64, key: *const u8) -> u64:
    if hm_is_str_key(m) != 0:
        // key points to a str value {ptr, len}
        let str_ptr = *(key as *const *const u8)
        let str_len = *((key as i64 + 8) as *const i64)
        return fnv_hash(str_ptr, str_len)
    fnv_hash(key, hm_key_size(m))

fn hm_keys_eq(m: i64, a: *const u8, b: *const u8) -> i32:
    if hm_is_str_key(m) != 0:
        let a_ptr = *(a as *const *const u8)
        let a_len = *((a as i64 + 8) as *const i64)
        let b_ptr = *(b as *const *const u8)
        let b_len = *((b as i64 + 8) as *const i64)
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
        if old_occ[i] != 0:
            let k = (old_keys as i64 + i * ksz) as *const u8
            let v = (old_vals as i64 + i * vsz) as *const u8
            // Re-insert
            var h = (hm_hash_key(m, k) % (new_cap as u64)) as i64
            while hm_occ(m)[h] != 0:
                h = ((h + 1) as u64 % (new_cap as u64)) as i64
            rt_memcpy((hm_keys(m) as i64 + h * ksz) as *mut u8, k, ksz)
            rt_memcpy((hm_vals(m) as i64 + h * vsz) as *mut u8, v, vsz)
            *((hm_occ(m) as i64 + h) as *mut u8) = 1
            hm_set_len(m, hm_len(m) + 1)
        i = i + 1

    rt_free_sized(old_keys, old_cap * ksz)
    rt_free_sized(old_vals, old_cap * vsz)
    rt_free_sized(old_occ, old_cap)

@[c_export("with_hashmap_new")]
pub fn hashmap_new(key_size: i64, val_size: i64) -> *mut u8:
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

@[c_export("with_hashmap_new_out")]
pub fn hashmap_new_out(out: *mut *mut u8, key_size: i64, val_size: i64):
    *out = hashmap_new(key_size, val_size)

@[c_export("with_hashmap_new_at")]
pub fn hashmap_new_at(base: *mut u8, offset: i64, key_size: i64, val_size: i64):
    let slot = (base as i64 + offset) as *mut *mut u8
    *slot = hashmap_new(key_size, val_size)

@[c_export("with_hashmap_insert")]
pub fn hashmap_insert(map: *mut u8, key: *const u8, val: *const u8, is_str_key: i64):
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
        if hm_occ(m)[h] == 0:
            break
        if hm_keys_eq(m, (hm_keys(m) as i64 + h * ksz) as *const u8, key) != 0:
            // Update existing
            rt_memcpy((hm_vals(m) as i64 + h * vsz) as *mut u8, val, vsz)
            return
        h = ((h + 1) as u64 % (cap as u64)) as i64
    rt_memcpy((hm_keys(m) as i64 + h * ksz) as *mut u8, key, ksz)
    rt_memcpy((hm_vals(m) as i64 + h * vsz) as *mut u8, val, vsz)
    *((hm_occ(m) as i64 + h) as *mut u8) = 1
    hm_set_len(m, hm_len(m) + 1)

@[c_export("with_hashmap_get")]
pub fn hashmap_get(map: *mut u8, key: *const u8, val_out: *mut u8, is_str_key: i64) -> i32:
    let _ = is_str_key  // key type already stored in struct
    let m = map as i64
    if hm_len(m) == 0: return 0
    let cap = hm_cap(m)
    let ksz = hm_key_size(m)
    let vsz = hm_val_size(m)

    var h = (hm_hash_key(m, key) % (cap as u64)) as i64
    var probes: i64 = 0
    while probes < cap:
        if hm_occ(m)[h] == 0:
            return 0
        if hm_keys_eq(m, (hm_keys(m) as i64 + h * ksz) as *const u8, key) != 0:
            if val_out as i64 != 0:
                rt_memcpy(val_out, (hm_vals(m) as i64 + h * vsz) as *const u8, vsz)
            return 1
        h = ((h + 1) as u64 % (cap as u64)) as i64
        probes = probes + 1
    0

@[c_export("with_hashmap_contains")]
pub fn hashmap_contains(map: *mut u8, key: *const u8, is_str_key: i64) -> i32:
    hashmap_get(map, key, 0 as *mut u8, is_str_key)

@[c_export("with_hashmap_remove")]
pub fn hashmap_remove(map: *mut u8, key: *const u8, is_str_key: i64) -> i32:
    let m = map as i64
    if hm_len(m) == 0: return 0
    let cap = hm_cap(m)
    let ksz = hm_key_size(m)

    var h = (hm_hash_key(m, key) % (cap as u64)) as i64
    var probes: i64 = 0
    while probes < cap:
        if hm_occ(m)[h] == 0:
            return 0
        if hm_keys_eq(m, (hm_keys(m) as i64 + h * ksz) as *const u8, key) != 0:
            *((hm_occ(m) as i64 + h) as *mut u8) = 0
            hm_set_len(m, hm_len(m) - 1)
            // Rehash following entries
            var next = ((h + 1) as u64 % (cap as u64)) as i64
            while hm_occ(m)[next] != 0:
                // Save key+val, clear slot, re-insert
                let tmpk = rt_alloc(ksz)
                let vsz = hm_val_size(m)
                let tmpv = rt_alloc(vsz)
                rt_memcpy(tmpk, (hm_keys(m) as i64 + next * ksz) as *const u8, ksz)
                rt_memcpy(tmpv, (hm_vals(m) as i64 + next * vsz) as *const u8, vsz)
                *((hm_occ(m) as i64 + next) as *mut u8) = 0
                hm_set_len(m, hm_len(m) - 1)
                hashmap_insert(map, tmpk as *const u8, tmpv as *const u8, is_str_key)
                rt_free_sized(tmpk, ksz)
                rt_free_sized(tmpv, vsz)
                next = ((next + 1) as u64 % (cap as u64)) as i64
            return 1
        h = ((h + 1) as u64 % (cap as u64)) as i64
        probes = probes + 1
    0

@[c_export("with_hashmap_len")]
pub fn hashmap_len(map: *mut u8) -> i64:
    hm_len(map as i64)

@[c_export("with_hashmap_clear")]
pub fn hashmap_clear(map: *mut u8):
    let m = map as i64
    rt_memset(hm_occ(m), 0, hm_cap(m))
    hm_set_len(m, 0)

@[c_export("with_hashmap_keys_out")]
pub fn hashmap_keys_out(out: *mut u8, map: *mut u8, key_size: i64):
    let m = map as i64
    if m == 0:
        vec_new_out(out, key_size)
        return
    let cap = hm_cap(m)
    let ksz = hm_key_size(m)
    let effective_ksz = if ksz > 0: ksz else: key_size
    vec_new_out(out, effective_ksz)
    var i: i64 = 0
    while i < cap:
        if hm_occ(m)[i] != 0:
            vec_push(out, (hm_keys(m) as i64 + i * ksz) as *const u8)
        i = i + 1

@[c_export("with_hashmap_free")]
pub fn hashmap_free(map: *mut u8):
    if map as i64 == 0: return
    let m = map as i64
    let cap = hm_cap(m)
    rt_free_sized(hm_keys(m), cap * hm_key_size(m))
    rt_free_sized(hm_vals(m), cap * hm_val_size(m))
    rt_free_sized(hm_occ(m), cap)
    rt_free_sized(map, HM_SIZE)

@[c_export("with_hashmap_increment")]
pub fn hashmap_increment(map: *mut u8, key: *const u8, is_str_key: i64):
    var val: i64 = 0
    let _ = hashmap_get(map, key, &val as *mut u8, is_str_key)
    val = val + 1
    hashmap_insert(map, key, &val as *const u8, is_str_key)

@[c_export("with_hashmap_decrement")]
pub fn hashmap_decrement(map: *mut u8, key: *const u8, is_str_key: i64):
    var val: i64 = 0
    let _ = hashmap_get(map, key, &val as *mut u8, is_str_key)
    val = val - 1
    hashmap_insert(map, key, &val as *const u8, is_str_key)

// ── StringBuilder ──────────────────────────────────────────────────
//
// Layout: { buf: *mut u8, len: i64, cap: i64 } — 24 bytes

let SB_OFF_BUF: i64 = 0
let SB_OFF_LEN: i64 = 8
let SB_OFF_CAP: i64 = 16
let SB_SIZE: i64 = 24

@[c_export("with_sb_new")]
pub fn sb_new() -> (*mut u8, i64, i64):
    let buf = rt_alloc(64)
    (buf, 0 as i64, 64 as i64)

@[c_export("with_sb_append")]
pub fn sb_append(sb: *mut u8, s: str):
    let slen = str_length(s)
    if slen == 0: return
    let sp = str_data(s)
    var sb_buf = *(sb as *const *mut u8)
    var sb_len = *((sb as i64 + SB_OFF_LEN) as *const i64)
    var sb_cap = *((sb as i64 + SB_OFF_CAP) as *const i64)
    while sb_len + slen > sb_cap:
        let old_cap = sb_cap
        let new_cap = old_cap * 2
        let new_buf = rt_alloc(new_cap)
        rt_memcpy(new_buf, sb_buf as *const u8, sb_len)
        rt_free_sized(sb_buf, old_cap)
        sb_buf = new_buf
        sb_cap = new_cap
    rt_memcpy((sb_buf as i64 + sb_len) as *mut u8, sp, slen)
    sb_len = sb_len + slen
    *(sb as *mut *mut u8) = sb_buf
    *((sb as i64 + SB_OFF_LEN) as *mut i64) = sb_len
    *((sb as i64 + SB_OFF_CAP) as *mut i64) = sb_cap

@[c_export("with_sb_build")]
pub fn sb_build(sb: *mut u8) -> str:
    let sb_buf = *(sb as *const *mut u8)
    let sb_len = *((sb as i64 + SB_OFF_LEN) as *const i64)
    let out = rt_alloc(sb_len + 1)
    rt_memcpy(out, sb_buf as *const u8, sb_len)
    *((out as i64 + sb_len) as *mut u8) = 0
    make_str(out as *const u8, sb_len)

// ── File I/O ───────────────────────────────────────────────────────

@[c_export("with_fs_read_file")]
pub fn fs_read_file(path: str) -> str:
    let cpath = str_to_cstr(path)
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
    *((buf as i64 + total) as *mut u8) = 0
    make_str(buf as *const u8, total)

@[c_export("with_fs_write_file")]
pub fn fs_write_file(path: str, data: str) -> i32:
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

@[c_export("with_fs_file_exists")]
pub fn fs_file_exists(path: str) -> i32:
    let cpath = str_to_cstr(path)
    let fd = rt_open(cpath, 0, 0)
    if fd < 0: return 0
    let _ = rt_close(fd)
    1

@[c_export("with_fs_mkdir_p")]
pub fn fs_mkdir_p(path: str) -> i32:
    let cpath = str_to_cstr(path)
    // Create each directory component
    let slen = str_length(path)
    var i: i64 = 1
    while i < slen:
        if *((cpath as i64 + i) as *const u8) == 47:  // '/'
            *((cpath as i64 + i) as *mut u8) = 0
            let _ = rt_mkdir(cpath, 493)  // 0755
            *((cpath as i64 + i) as *mut u8) = 47
        i = i + 1
    rt_mkdir(cpath, 493)

@[c_export("with_fs_remove_file")]
pub fn fs_remove_file(path: str) -> i32:
    let cpath = str_to_cstr(path)
    rt_unlink(cpath)

@[c_export("with_fs_rename_file")]
pub fn fs_rename_file(old_path: str, new_path: str) -> i32:
    let cold = str_to_cstr(old_path)
    let cnew = str_to_cstr(new_path)
    rt_rename(cold, cnew)

@[c_export("with_fs_create_dir")]
pub fn fs_create_dir(path: str) -> i32:
    let cpath = str_to_cstr(path)
    rt_mkdir(cpath, 493)  // 0755

@[c_export("with_fs_remove_dir")]
pub fn fs_remove_dir(path: str) -> i32:
    let cpath = str_to_cstr(path)
    rt_rmdir(cpath)

// ── stdin I/O ──────────────────────────────────────────────────────

@[c_export("with_read_line_stdin")]
pub fn read_line_stdin() -> str:
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

@[c_export("with_read_bytes_stdin")]
pub fn read_bytes_stdin(count: i32) -> str:
    if count <= 0:
        return make_str("" as *const u8, 0)
    let buf = rt_alloc(count as i64 + 1)
    var total: i64 = 0
    while total < count as i64:
        let r = rt_read(0, (buf as i64 + total) as *mut u8, (count as i64 - total) as u64)
        if r <= 0: break
        total = total + r
    *((buf as i64 + total) as *mut u8) = 0
    make_str(buf as *const u8, total)

@[c_export("with_write_stdout")]
pub fn write_stdout(s: str):
    print_str(s)

@[c_export("with_flush_stdout")]
pub fn flush_stdout():
    // No buffering in rt_write
    let _ = 0

// ── String split/lines ─────────────────────────────────────────────

@[c_export("with_str_split")]
pub fn str_split(s: str, delim: str, out: *mut u8, count: *mut i64):
    let sl = str_length(s)
    let dl = str_length(delim)
    if sl == 0 or dl == 0:
        if out as i64 != 0:
            // Store s at out[0] (str is 16 bytes)
            *(out as *mut str) = s
        if sl > 0:
            *count = 1
        else:
            *count = 0
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
                *((out as i64 + n * 16) as *mut str) = part
            n = n + 1
            start = i + dl
            i = start
        else:
            i = i + 1
    if out as i64 != 0:
        let last = make_str((sp as i64 + start) as *const u8, sl - start)
        *((out as i64 + n * 16) as *mut str) = last
    n = n + 1
    *count = n

@[c_export("with_lines_out")]
pub fn lines_out(out: *mut u8, s: str):
    vec_new_out(out, 16)  // sizeof(str) = 16
    let sp = str_data(s)
    let sl = str_length(s)
    var start: i64 = 0
    var i: i64 = 0
    while i < sl:
        if sp[i] == 10:  // '\n'
            let line = make_str((sp as i64 + start) as *const u8, i - start)
            vec_push(out, &line as *const u8)
            start = i + 1
        i = i + 1
    if start < sl:
        let line = make_str((sp as i64 + start) as *const u8, sl - start)
        vec_push(out, &line as *const u8)

@[c_export("with_lines")]
pub fn lines_fn(s: str) -> (*mut u8, i64, i64, i64):
    // Allocate a Vec on the stack-return area
    var v: (i64, i64, i64, i64) = (0, 0, 0, 0)
    lines_out(&v as *mut u8, s)
    let vp = &v as *const *mut u8
    let vl = *((&v as i64 + 8) as *const i64)
    let vc = *((&v as i64 + 16) as *const i64)
    let ve = *((&v as i64 + 24) as *const i64)
    (*vp, vl, vc, ve)

@[c_export("with_str_join")]
pub fn str_join(parts: *mut u8, sep: str) -> str:
    let plen = vec_get_len(parts)
    if plen == 0:
        return make_str("" as *const u8, 0)
    let sep_p = str_data(sep)
    let sep_l = str_length(sep)
    // Calculate total length
    var total: i64 = 0
    var i: i64 = 0
    while i < plen:
        let p = vec_get_ptr(parts, i)
        let part_len = *((p as i64 + 8) as *const i64)
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
        let p = vec_get_ptr(parts, i)
        let part_ptr = *(p as *const *const u8)
        let part_len = *((p as i64 + 8) as *const i64)
        if part_len > 0:
            rt_memcpy((out as i64 + pos) as *mut u8, part_ptr, part_len)
            pos = pos + part_len
        i = i + 1
    *((out as i64 + total) as *mut u8) = 0
    make_str(out as *const u8, total)

@[c_export("with_vec_str_join")]
pub fn vec_str_join(parts: *mut u8, sep: str) -> str:
    str_join(parts, sep)

@[c_export("with_str_split_vec")]
pub fn str_split_vec(out: *mut u8, s: str, delim: str):
    vec_new_out(out, 16)  // sizeof(str) = 16
    let sl = str_length(s)
    if sl == 0: return
    let dl = str_length(delim)
    if dl == 0:
        vec_push(out, &s as *const u8)
        return
    let sp = str_data(s)
    let dp = str_data(delim)
    var start: i64 = 0
    var i: i64 = 0
    while i <= sl - dl:
        if rt_memcmp((sp as i64 + i) as *const u8, dp, dl) == 0:
            let part = make_str((sp as i64 + start) as *const u8, i - start)
            vec_push(out, &part as *const u8)
            start = i + dl
            i = start
        else:
            i = i + 1
    let last = make_str((sp as i64 + start) as *const u8, sl - start)
    vec_push(out, &last as *const u8)

// ── Time ───────────────────────────────────────────────────────────

@[c_export("with_time_now")]
pub fn time_now() -> i64:
    rt_clock_ns()

@[c_export("with_clock_nanos")]
pub fn clock_nanos() -> i64:
    rt_clock_ns()

@[c_export("with_nanosleep")]
pub fn nanosleep_impl(ns: i64) -> i32:
    rt_nanosleep(ns)

@[c_export("with_usleep")]
pub fn usleep_impl(usecs: i32) -> i32:
    rt_nanosleep(usecs as i64 * 1000)

@[c_export("with_getpid")]
pub fn getpid_impl() -> i32:
    rt_getpid()

@[c_export("with_raise")]
pub fn raise_impl(sig: i32) -> i32:
    rt_raise(sig)

// ── Bitwise builtins ───────────────────────────────────────────────

@[c_export("with_clz")]
pub fn clz_i32(n: i32) -> i32:
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

@[c_export("with_ctz")]
pub fn ctz_i32(n: i32) -> i32:
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

@[c_export("with_popcount")]
pub fn popcount_i32(n: i32) -> i32:
    var x = n as u32
    // Standard bit-parallel popcount
    x = x - ((x >> 1) & 0x55555555)
    x = (x & 0x33333333) + ((x >> 2) & 0x33333333)
    x = (x + (x >> 4)) & 0x0F0F0F0F
    ((x * 0x01010101) >> 24) as i32

@[c_export("with_bswap16")]
pub fn bswap16(n: i16) -> i16:
    let x = n as u16
    (((x >> 8) & 0xFF) | ((x & 0xFF) << 8)) as i16

@[c_export("with_bswap32")]
pub fn bswap32(n: i32) -> i32:
    let x = n as u32
    (((x >> 24) & 0xFF) | ((x >> 8) & 0xFF00) | ((x & 0xFF00) << 8) | ((x & 0xFF) << 24)) as i32

@[c_export("with_bswap64")]
pub fn bswap64(n: i64) -> i64:
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

@[c_export("with_clzl")]
pub fn clzl(n: i64) -> i32:
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

@[c_export("with_clzll")]
pub fn clzll(n: i64) -> i32:
    clzl(n)

@[c_export("with_ctzl")]
pub fn ctzl(n: i64) -> i32:
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

@[c_export("with_ctzll")]
pub fn ctzll(n: i64) -> i32:
    ctzl(n)

@[c_export("with_abs")]
pub fn abs_i32(n: i32) -> i32:
    if n < 0: 0 - n else: n

// ── Misc ───────────────────────────────────────────────────────────

@[c_export("with_fill_random")]
pub fn fill_random(buf: *mut u8, len: i64):
    arc4random_buf(buf, len as u64)

// with_system: provided by compat_runtime.w (needs libc fork/exec)

// ── Codegen loop state ─────────────────────────────────────────────
// Used by LLVM codegen for break/continue within loops.

var loop_break_bbs: [256]i64 = [0 as i64; 256]
var loop_continue_bbs: [256]i64 = [0 as i64; 256]
var loop_result_bbs: [256]i64 = [0 as i64; 256]

@[c_export("with_codegen_loop_set_break")]
pub fn codegen_loop_set_break(idx: i32, bb: i64):
    if idx >= 0 and idx < 256:
        loop_break_bbs[idx] = bb

@[c_export("with_codegen_loop_set_continue")]
pub fn codegen_loop_set_continue(idx: i32, bb: i64):
    if idx >= 0 and idx < 256:
        loop_continue_bbs[idx] = bb

@[c_export("with_codegen_loop_set_result")]
pub fn codegen_loop_set_result(idx: i32, val: i64):
    if idx >= 0 and idx < 256:
        loop_result_bbs[idx] = val

@[c_export("with_codegen_loop_get_break")]
pub fn codegen_loop_get_break(idx: i32) -> i64:
    if idx >= 0 and idx < 256:
        return loop_break_bbs[idx]
    0

@[c_export("with_codegen_loop_get_continue")]
pub fn codegen_loop_get_continue(idx: i32) -> i64:
    if idx >= 0 and idx < 256:
        return loop_continue_bbs[idx]
    0

@[c_export("with_codegen_loop_get_result")]
pub fn codegen_loop_get_result(idx: i32) -> i64:
    if idx >= 0 and idx < 256:
        return loop_result_bbs[idx]
    0

// with_install_interrupt_handlers, with_raise_stack_limit,
// with_interrupt_requested: provided by compat_runtime.w (need libc sigaction)

// ── Network stubs ──────────────────────────────────────────────────

@[c_export("with_net_tcp_listen")]
pub fn net_tcp_listen(port: i32) -> i32:
    let _ = port
    -1

@[c_export("with_net_tcp_accept")]
pub fn net_tcp_accept(sock: i32) -> i32:
    let _ = sock
    -1

@[c_export("with_net_tcp_connect")]
pub fn net_tcp_connect(host: str, port: i32) -> i32:
    let _ = host
    let _ = port
    -1

@[c_export("with_net_send")]
pub fn net_send(sock: i32, data: str) -> i64:
    let _ = sock
    let _ = data
    -1

@[c_export("with_net_recv")]
pub fn net_recv(sock: i32, max: i32) -> str:
    let _ = sock
    let _ = max
    make_str("" as *const u8, 0)

@[c_export("with_net_close")]
pub fn net_close(sock: i32):
    let _ = sock

@[c_export("with_net_udp_bind")]
pub fn net_udp_bind(port: i32) -> i32:
    let _ = port
    -1

// Fiber stubs come from the small runtime stub object when async is absent.
// Strong definitions come from fiber.c when the fiber runtime is linked.

// ── cimport stubs ──────────────────────────────────────────────────

// with_cimport_available: provided by helpers.o (weak) / clang_bridge.o (strong)

@[c_export("with_extract_runtime_obj")]
pub fn extract_runtime_obj(name: str, path: str) -> i32:
    let _ = name
    let _ = path
    // The real extractor is compiler-owned and linked into the self-contained
    // compiler binary. User programs keep a stub here.
    1

// ── Sysinfo ────────────────────────────────────────────────────────

@[c_export("with_sysinfo_os")]
pub fn sysinfo_os() -> str:
    make_str("Macos" as *const u8, 5)

@[c_export("with_sysinfo_arch")]
pub fn sysinfo_arch() -> str:
    make_str("armv8" as *const u8, 5)

@[c_export("with_sysinfo_hostname")]
pub fn sysinfo_hostname() -> str:
    var buf: [256]u8 = [0 as u8; 256]
    let buf_ptr = (&mut buf) as *mut [256]u8 as *mut u8
    if gethostname(buf_ptr, 256 as u64) != 0:
        return make_str("unknown" as *const u8, 7)
    buf[255] = 0
    alloc_str(buf_ptr as *const u8, cstr_len(buf_ptr as *const u8))

// rt_sysinfo wrapper — fills {cpu_cores: i32, memory_total: i64, page_size: i64}
@[c_export("with_sysinfo")]
pub fn sysinfo_impl(out: *mut u8) -> i32:
    rt_sysinfo(out)

// ── Async Scopes (structured concurrency) ──────────────────────────
// Scope holds a heap-allocated array of fiber IDs.
// Layout: [count: i32, capacity: i32, ids: *mut i32]
// Packed into a single heap allocation: 8 bytes header + ids array.

extern fn with_fiber_await(fiber_id: i32) -> void

@[c_export("with_scope_create")]
pub fn scope_create() -> i64:
    // Allocate: 8 bytes header (count + capacity) + 16 * 4 bytes for IDs
    let cap = 16
    let size = 8 + cap * 4
    let ptr = rt_alloc(size as i64)
    if ptr as i64 == 0:
        return 0
    // count = 0
    let count_ptr = ptr as *mut i32
    unsafe:
        *count_ptr = 0
    // capacity = 16
    let cap_ptr = (ptr as i64 + 4) as *mut i32
    unsafe:
        *cap_ptr = cap
    ptr as i64

@[c_export("with_scope_track")]
pub fn scope_track(handle: i64, fiber_id: i32):
    if handle == 0:
        return
    let count_ptr = handle as *mut i32
    let cap_ptr = (handle + 4) as *mut i32
    let count = unsafe: *count_ptr
    let cap = unsafe: *cap_ptr
    if count >= cap:
        // Grow: allocate new buffer, copy, free old
        let new_cap = cap * 2
        let new_size = 8 + new_cap * 4
        let new_ptr = rt_alloc(new_size as i64)
        if new_ptr as i64 == 0:
            return
        // Copy header + existing IDs
        let old_size = 8 + count * 4
        rt_memcpy(new_ptr, handle as *const u8, old_size as i64)
        rt_free(handle as *mut u8)
        // Update capacity in new buffer
        let new_cap_ptr = (new_ptr as i64 + 4) as *mut i32
        unsafe:
            *new_cap_ptr = new_cap
        // Recurse with new handle (now has room)
        scope_track(new_ptr as i64, fiber_id)
        return
    // Store fiber_id at offset 8 + count * 4
    let slot = (handle + 8 + count as i64 * 4) as *mut i32
    unsafe:
        *slot = fiber_id
    unsafe:
        *count_ptr = count + 1

@[c_export("with_scope_await_all")]
pub fn scope_await_all(handle: i64):
    if handle == 0:
        return
    let count_ptr = handle as *mut i32
    let count = unsafe: *count_ptr
    for i in 0..count:
        let slot = (handle + 8 + i as i64 * 4) as *const i32
        let fid = unsafe: *slot
        with_fiber_await(fid)

@[c_export("with_scope_destroy")]
pub fn scope_destroy(handle: i64):
    if handle == 0:
        return
    rt_free(handle as *mut u8)
