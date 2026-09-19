// rt/wasm.w -- WebAssembly platform backend (WASI preview1 imports).
//
// The With runtime does not use libc. On WebAssembly the "operating
// system" is whatever host serves this module's imports: the JS host the
// compiler emits next to every .wasm (src/compiler/WasmHost.w), wasmtime,
// or node:wasi. This file implements the rt_* platform contract rt_core.w
// declares (the same surface rt/linux_x86_64.w and rt/darwin_aarch64.w
// implement over libc) directly on WASI preview1 system calls, and owns
// the pieces a libc would otherwise provide: process startup and exit,
// the page allocator behind rt_mmap, the memcmp family, and malloc/free.
//
// Linear memory: wasm-ld lays out the shadow stack (--stack-first) and
// data below the initial memory size; everything from that end upward
// belongs to rt_mmap, which grows it with memory.grow.
//
// Paths: WASI opens paths relative to a preopened directory fd. Every
// path a program hands the runtime is made absolute against the cwd
// (PWD from the environment when absolute, else "/"), normalized, and
// matched against the longest preopen name; the remainder is what WASI
// sees. The emitted JS host preopens "/" and passes PWD, so a program
// under node sees the real filesystem exactly as a native one would.
//
// This backend is the wasm32 flavour: WASI sizes are 32-bit here. The
// compiler reserves a wasm64 kind, but its runtime (64-bit WASI sizes,
// 16-byte iovecs) is not written yet and the driver refuses the target.

use std.builtins.c_void

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> *mut u8
extern fn with_memset(dst: *mut u8, val: i32, len: i64) -> *mut u8
extern fn with_str_from_cstr(s: *const u8) -> str
extern fn with_str_from_bytes(s: *const u8, len: i64) -> str

// ── WASI preview1 imports ─────────────────────────────────────────────

@[import_module("wasi_snapshot_preview1")]
extern fn args_sizes_get(argc: *mut i32, argv_buf_size: *mut i32) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn args_get(argv: *mut *mut u8, argv_buf: *mut u8) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn environ_sizes_get(count: *mut i32, buf_size: *mut i32) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn environ_get(environ: *mut *mut u8, environ_buf: *mut u8) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn clock_time_get(id: i32, precision: i64, time: *mut i64) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn fd_close(fd: i32) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn fd_fdstat_get(fd: i32, stat: *mut u8) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn fd_filestat_get(fd: i32, stat: *mut u8) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn fd_prestat_get(fd: i32, prestat: *mut u8) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn fd_prestat_dir_name(fd: i32, path: *mut u8, path_len: i32) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn fd_read(fd: i32, iovs: *const u8, iovs_len: i32, nread: *mut i32) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn fd_readdir(fd: i32, buf: *mut u8, buf_len: i32, cookie: i64, bufused: *mut i32) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn fd_seek(fd: i32, offset: i64, whence: i32, newoffset: *mut i64) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn fd_write(fd: i32, iovs: *const u8, iovs_len: i32, nwritten: *mut i32) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn path_create_directory(fd: i32, path: *const u8, path_len: i32) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn path_filestat_get(fd: i32, flags: i32, path: *const u8, path_len: i32, buf: *mut u8) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn path_open(fd: i32, dirflags: i32, path: *const u8, path_len: i32, oflags: i32, fs_rights_base: i64, fs_rights_inheriting: i64, fdflags: i32, opened_fd: *mut i32) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn path_readlink(fd: i32, path: *const u8, path_len: i32, buf: *mut u8, buf_len: i32, bufused: *mut i32) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn path_remove_directory(fd: i32, path: *const u8, path_len: i32) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn path_rename(fd: i32, old_path: *const u8, old_path_len: i32, new_fd: i32, new_path: *const u8, new_path_len: i32) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn path_symlink(old_path: *const u8, old_path_len: i32, fd: i32, new_path: *const u8, new_path_len: i32) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn path_unlink_file(fd: i32, path: *const u8, path_len: i32) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn poll_oneoff(subscriptions: *const u8, events: *mut u8, nsubscriptions: i32, nevents: *mut i32) -> i32
@[import_module("wasi_snapshot_preview1")]
extern fn proc_exit(code: i32) -> Never
@[import_module("wasi_snapshot_preview1")]
extern fn random_get(buf: *mut u8, buf_len: i32) -> i32

// Linear-memory intrinsics (LLVM lowers a declaration with the intrinsic's
// name and prototype to the memory.size / memory.grow instructions).
@[link_name("llvm.wasm.memory.size.i32")]
extern fn wasm_memory_size(mem: i32) -> i32
@[link_name("llvm.wasm.memory.grow.i32")]
extern fn wasm_memory_grow(mem: i32, delta_pages: i32) -> i32

let WASM_PAGE: i64 = 65536
let WASM_MMAP_ALIGN: i64 = 4096
let WASM_PTR: i64 = 4
let WASM_PATH_MAX: i64 = 4096

let WASI_CLOCK_REALTIME: i32 = 0
let WASI_CLOCK_MONOTONIC: i32 = 1
let WASI_FILETYPE_CHARDEV: i32 = 2
let WASI_FILETYPE_DIRECTORY: i32 = 3
let WASI_FILETYPE_REGULAR: i32 = 4
let WASI_FILETYPE_SYMLINK: i32 = 7
let WASI_LOOKUP_SYMLINK_FOLLOW: i32 = 1
let WASI_O_CREAT: i32 = 1
let WASI_O_DIRECTORY: i32 = 2
let WASI_O_EXCL: i32 = 4
let WASI_O_TRUNC: i32 = 8
let WASI_FDFLAG_APPEND: i32 = 1
// Every non-socket right (bits 0..27). Hosts that still enforce rights
// (node's uvwasi) grant preopens exactly this set; wasmtime ignores them.
// The access mode of an open is carried by the FD_READ/FD_WRITE bits, so a
// read-only open must not request the write rights (a read-only file, or
// a directory, refuses them).
let WASI_RIGHTS_ALL: i64 = 268435455
let WASI_RIGHT_FD_READ: i64 = 2
let WASI_RIGHT_FD_WRITE: i64 = 64
let WASI_RIGHT_FD_ALLOCATE: i64 = 256
let WASI_RIGHT_FD_FILESTAT_SET_SIZE: i64 = 4194304
let WASI_EBADF: i32 = 8
let WASI_EEXIST: i32 = 20
let WASI_EINVAL: i32 = 28
let WASI_ENOENT: i32 = 44
let WASI_ENOSYS: i32 = 52
let WASI_ENOTDIR: i32 = 54

// Canonical rt_open flags (rt_core.w): O_RDONLY=0, O_WRONLY=1, O_RDWR=2,
// O_CREAT=0x200, O_TRUNC=0x400, O_APPEND=0x800.
let RT_O_WRONLY: i32 = 1
let RT_O_RDWR: i32 = 2
let RT_O_CREAT: i32 = 512
let RT_O_TRUNC: i32 = 1024
let RT_O_APPEND: i32 = 2048

let RT_S_IFMT: i32 = 61440
let RT_S_IFDIR: i32 = 16384
let RT_S_IFREG: i32 = 32768
let RT_S_IFLNK: i32 = 40960

type RtStatBuf:
    size: i64
    is_dir: i32
    is_file: i32
    modified_ns: i64

type RtSysInfo:
    cpu_cores: i32
    memory_total: i64
    page_size: i64

// ── errno ─────────────────────────────────────────────────────────────

var wasm_errno: i32 = 0

// WASI numbers its errnos alphabetically; rt_core and std.fs read the
// POSIX values (ENOENT=2, EEXIST=17, ...) that every other backend returns.
fn wasm_errno_to_posix(e: i32) -> i32:
    if e == 0: return 0
    if e == 2: return 13
    if e == 6: return 11
    if e == 8: return 9
    if e == 10: return 16
    if e == 20: return 17
    if e == 27: return 4
    if e == 28: return 22
    if e == 29: return 5
    if e == 31: return 21
    if e == 32: return 40
    if e == 37: return 36
    if e == 41: return 24
    if e == 44: return 2
    if e == 51: return 28
    if e == 52: return 38
    if e == 54: return 20
    if e == 55: return 39
    if e == 58: return 95
    if e == 63: return 1
    if e == 64: return 32
    if e == 68: return 34
    if e == 69: return 30
    if e == 70: return 29
    if e == 76: return 13
    5

fn wasm_fail(wasi_errno: i32) -> i32:
    wasm_errno = wasm_errno_to_posix(wasi_errno)
    -wasm_errno

pub fn rt_errno_ptr() -> *mut i32: &raw mut wasm_errno

// ── memory helpers ────────────────────────────────────────────────────

fn wasm_load_u8(base: i64, offset: i64) -> i32:
    (unsafe *((base + offset) as *const u8)) as i32

fn wasm_load_i32(base: i64, offset: i64) -> i32:
    unsafe *((base + offset) as *const i32)

fn wasm_load_i64(base: i64, offset: i64) -> i64:
    unsafe *((base + offset) as *const i64)

fn wasm_store_u8(base: i64, offset: i64, value: i32):
    unsafe *((base + offset) as *mut u8) = value as u8

fn wasm_store_i32(base: i64, offset: i64, value: i32):
    unsafe *((base + offset) as *mut i32) = value

fn wasm_store_i64(base: i64, offset: i64, value: i64):
    unsafe *((base + offset) as *mut i64) = value

fn wasm_store_ptr(base: i64, offset: i64, ptr: *const u8):
    unsafe *((base + offset) as *mut *const u8) = ptr

fn wasm_load_ptr(base: i64, offset: i64) -> *const u8:
    unsafe *((base + offset) as *const *const u8)

fn wasm_cstr_len(s: *const u8) -> i64:
    var n: i64 = 0
    while wasm_load_u8(s as i64, n) != 0:
        n = n + 1
    n

fn wasm_align_up(x: i64, a: i64) -> i64:
    ((x + a - 1) / a) * a

fn wasm_write_cstr(fd: i32, s: *const u8):
    let _ = rt_write(fd, s, wasm_cstr_len(s))

// ── page allocator behind rt_mmap ─────────────────────────────────────
//
// A bump allocator over memory.grow with a small run recycler: rt_core's
// large allocations come back through rt_munmap and are reissued to the
// next request that fits (best fit, split on surplus). Runs are
// 4096-aligned so rt_core's slab bookkeeping sees page-shaped ranges,
// and a reissued run is re-zeroed because rt_core relies on fresh mmap
// memory being zero.

var wasm_heap_cur: i64 = 0
var wasm_heap_end: i64 = 0
let WASM_FREE_SLOTS: i32 = 256
var wasm_free_ptrs: [256]i64 = [0 as i64; 256]
var wasm_free_sizes: [256]i64 = [0 as i64; 256]
var wasm_free_count: i32 = 0

fn wasm_heap_init():
    if wasm_heap_end != 0:
        return
    let end = (wasm_memory_size(0) as i64) * WASM_PAGE
    wasm_heap_cur = end
    wasm_heap_end = end

pub fn rt_mmap(size: i64) -> *mut u8:
    wasm_heap_init()
    if size <= 0:
        return 0 as *mut u8
    let need = wasm_align_up(size, WASM_MMAP_ALIGN)
    var best = -1
    var best_size: i64 = 0
    for i in 0..wasm_free_count:
        let s: i64 = wasm_free_sizes[i]
        if s >= need and (best < 0 or s < best_size):
            best = i
            best_size = s
    if best >= 0:
        let p: i64 = wasm_free_ptrs[best]
        if best_size > need:
            wasm_free_ptrs[best] = p + need
            wasm_free_sizes[best] = best_size - need
        else:
            wasm_free_count = wasm_free_count - 1
            wasm_free_ptrs[best] = wasm_free_ptrs[wasm_free_count]
            wasm_free_sizes[best] = wasm_free_sizes[wasm_free_count]
        let _ = with_memset(p as *mut u8, 0, need)
        return p as *mut u8
    let start = wasm_align_up(wasm_heap_cur, WASM_MMAP_ALIGN)
    if start + need > wasm_heap_end:
        let grow_bytes = start + need - wasm_heap_end
        let pages = (grow_bytes + WASM_PAGE - 1) / WASM_PAGE
        if wasm_memory_grow(0, pages as i32) < 0:
            wasm_errno = 12
            return 0 as *mut u8
        wasm_heap_end = wasm_heap_end + pages * WASM_PAGE
    wasm_heap_cur = start + need
    start as *mut u8

pub fn rt_munmap(ptr: *mut u8, size: i64) -> Unit:
    if ptr as i64 == 0 or size <= 0:
        return
    let need = wasm_align_up(size, WASM_MMAP_ALIGN)
    if ptr as i64 + need == wasm_heap_cur:
        wasm_heap_cur = ptr as i64
        return
    if wasm_free_count < WASM_FREE_SLOTS:
        wasm_free_ptrs[wasm_free_count] = ptr as i64
        wasm_free_sizes[wasm_free_count] = need
        wasm_free_count = wasm_free_count + 1
    // A full recycler leaks the run: bounded, and only for pathological
    // free patterns of >256 outstanding large runs.

// rt_core's --alloc-system mode (WITH_ALLOC_SYSTEM) asks a libc malloc for
// every block; on wasm "the libc" is this page allocator with a header.
pub fn malloc(size: i64) -> *mut u8:
    let total = wasm_align_up(size + 16, 16)
    let p = rt_mmap(total)
    if p as i64 == 0:
        return 0 as *mut u8
    wasm_store_i64(p as i64, 0, total)
    (p as i64 + 16) as *mut u8

pub fn free(ptr: *mut u8) -> Unit:
    if ptr as i64 == 0:
        return
    let base = ptr as i64 - 16
    rt_munmap(base as *mut u8, wasm_load_i64(base, 0))

// ── process ───────────────────────────────────────────────────────────

pub fn _exit(code: i32) -> Never:
    proc_exit(code)

pub fn abort() -> Unit:
    wasm_write_cstr(2, c"abort()\n".ptr)
    proc_exit(134)

pub fn rt_exit(code: i32) -> Never:
    proc_exit(code)

pub fn rt_getpid() -> i32: 1

pub fn rt_kill(pid: i32, sig: i32) -> i32:
    let _ = pid
    let _ = sig
    wasm_fail(WASI_ENOSYS)

pub fn rt_raise(sig: i32) -> i32:
    if sig == 6:
        abort()
    proc_exit(128 + sig)

pub fn rt_backtrace_print() -> Unit:
    let _ = 0

pub fn rt_thread_spawn(start_routine: *mut u8, arg: *mut u8) -> i64:
    let _ = start_routine
    let _ = arg
    -1

pub fn rt_thread_join(handle: i64) -> i32:
    let _ = handle
    -1

pub fn rt_getrlimit(resource: i32, lim: *mut u8) -> i32:
    let _ = resource
    let _ = lim
    wasm_fail(WASI_ENOSYS)

pub fn rt_setrlimit(resource: i32, lim: *const u8) -> i32:
    let _ = resource
    let _ = lim
    wasm_fail(WASI_ENOSYS)

pub fn rt_set_process_memory_limit_bytes(limit: i64) -> i32:
    let _ = limit
    -1

pub fn gethostname(name: *mut u8, len: u64) -> i32:
    if len < 5:
        return wasm_fail(WASI_EINVAL)
    let _ = with_memcpy(name, c"wasm".ptr, 5)
    0

// ── stdio handles ─────────────────────────────────────────────────────
//
// std.libc's FILE* seams: a stream handle is fd + 1 so that stdin's is
// non-null; fileno undoes it.

pub fn rt_libc_stdin() -> *mut c_void: 1 as *mut c_void
pub fn rt_libc_stdout() -> *mut c_void: 2 as *mut c_void
pub fn rt_libc_stderr() -> *mut c_void: 3 as *mut c_void
pub fn rt_fileno(stream: *mut c_void) -> i32: (stream as i64 - 1) as i32

pub fn rt_isatty(fd: i32) -> i32:
    var st: [24]u8 = [0 as u8; 24]
    let base = (&raw mut st) as *mut [24]u8 as i64
    if fd_fdstat_get(fd, base as *mut u8) != 0:
        return 0
    if wasm_load_u8(base, 0) == WASI_FILETYPE_CHARDEV: 1 else: 0

// ── read / write / seek / close ───────────────────────────────────────

pub fn rt_write(fd: i32, buf: *const u8, len: i64) -> i64:
    var written: i64 = 0
    while written < len:
        var iov: [8]u8 = [0 as u8; 8]
        let iov_base = (&raw mut iov) as *mut [8]u8 as i64
        var chunk = len - written
        if chunk > 1073741824:
            chunk = 1073741824
        wasm_store_ptr(iov_base, 0, (buf as i64 + written) as *const u8)
        wasm_store_i32(iov_base, 4, chunk as i32)
        var n: i32 = 0
        let rc = fd_write(fd, iov_base as *const u8, 1, &raw mut n)
        if rc != 0:
            let e = wasm_fail(rc)
            return if written > 0: written else: e as i64
        if n <= 0:
            break
        written = written + n as i64
    written

pub fn rt_read(fd: i32, buf: *mut u8, len: i64) -> i64:
    if len <= 0:
        return 0
    var iov: [8]u8 = [0 as u8; 8]
    let iov_base = (&raw mut iov) as *mut [8]u8 as i64
    var chunk = len
    if chunk > 1073741824:
        chunk = 1073741824
    wasm_store_ptr(iov_base, 0, buf as *const u8)
    wasm_store_i32(iov_base, 4, chunk as i32)
    var n: i32 = 0
    let rc = fd_read(fd, iov_base as *const u8, 1, &raw mut n)
    if rc != 0:
        return wasm_fail(rc) as i64
    n as i64

pub fn rt_close(fd: i32) -> i32:
    let rc = fd_close(fd)
    if rc != 0:
        return wasm_fail(rc)
    0

pub fn rt_seek(fd: i32, offset: i64, whence: i32) -> i64:
    var pos: i64 = 0
    let rc = fd_seek(fd, offset, whence, &raw mut pos)
    if rc != 0:
        return wasm_fail(rc) as i64
    pos

pub fn rt_fcntl(fd: i32, cmd: i32, arg: i32) -> i32:
    let _ = fd
    let _ = cmd
    let _ = arg
    0

// ── preopens, cwd, path resolution ────────────────────────────────────

let WASM_PREOPEN_SLOTS: i32 = 64
var wasm_preopen_count: i32 = 0
var wasm_preopen_fds: [64]i32 = [0 as i32; 64]
var wasm_preopen_names: [64]i64 = [0 as i64; 64]
var wasm_preopen_lens: [64]i64 = [0 as i64; 64]
var wasm_preopens_ready: i32 = 0
var wasm_cwd: i64 = 0
var wasm_cwd_len: i64 = 0

// Normalize the absolute path in `src[0..len)` into `out` (capacity
// `cap`, NUL-terminated): collapses repeated slashes, "." and "..".
// Returns the normalized length, or -1 when it does not fit.
fn wasm_normalize_into(src: *const u8, len: i64, out: *mut u8, cap: i64) -> i64:
    var n: i64 = 0
    var i: i64 = 0
    let ob = out as i64
    let sb = src as i64
    while i < len:
        // skip slashes
        while i < len and wasm_load_u8(sb, i) == 47:
            i = i + 1
        if i >= len:
            break
        var j = i
        while j < len and wasm_load_u8(sb, j) != 47:
            j = j + 1
        let seg_len = j - i
        if seg_len == 1 and wasm_load_u8(sb, i) == 46:
            i = j
            continue
        if seg_len == 2 and wasm_load_u8(sb, i) == 46 and wasm_load_u8(sb, i + 1) == 46:
            // pop the previous segment
            while n > 0 and wasm_load_u8(ob, n - 1) != 47:
                n = n - 1
            if n > 0:
                n = n - 1
            i = j
            continue
        if n + 1 + seg_len + 1 > cap:
            return -1
        wasm_store_u8(ob, n, 47)
        n = n + 1
        let _ = with_memcpy((ob + n) as *mut u8, (sb + i) as *const u8, seg_len)
        n = n + seg_len
        i = j
    if n == 0:
        if cap < 2:
            return -1
        wasm_store_u8(ob, 0, 47)
        n = 1
    wasm_store_u8(ob, n, 0)
    n

// The absolute, normalized form of `path` (cwd-relative when it does not
// start with '/'). Returns the length or -1.
fn wasm_absolute_into(path: *const u8, out: *mut u8, cap: i64) -> i64:
    let plen = wasm_cstr_len(path)
    if plen > 0 and wasm_load_u8(path as i64, 0) == 47:
        return wasm_normalize_into(path, plen, out, cap)
    if wasm_cwd_len + 1 + plen + 1 > WASM_PATH_MAX:
        return -1
    var joined: [4096]u8 = [0 as u8; 4096]
    let jb = (&raw mut joined) as *mut [4096]u8 as i64
    let _ = with_memcpy(jb as *mut u8, wasm_cwd as *const u8, wasm_cwd_len)
    wasm_store_u8(jb, wasm_cwd_len, 47)
    let _ = with_memcpy((jb + wasm_cwd_len + 1) as *mut u8, path, plen)
    wasm_normalize_into(jb as *const u8, wasm_cwd_len + 1 + plen, out, cap)

fn wasm_dup_bytes(src: *const u8, len: i64) -> i64:
    let p = with_alloc(len + 1)
    if p as i64 == 0:
        return 0
    let _ = with_memcpy(p, src, len)
    wasm_store_u8(p as i64, len, 0)
    p as i64

fn wasm_init_cwd():
    if wasm_cwd != 0:
        return
    let pwd = rt_getenv(c"PWD".ptr)
    if pwd as i64 != 0 and wasm_load_u8(pwd as i64, 0) == 47:
        var norm: [4096]u8 = [0 as u8; 4096]
        let nb = (&raw mut norm) as *mut [4096]u8 as *mut u8
        let n = wasm_normalize_into(pwd, wasm_cstr_len(pwd), nb, WASM_PATH_MAX)
        if n > 0:
            wasm_cwd = wasm_dup_bytes(nb as *const u8, n)
            wasm_cwd_len = n
            return
    wasm_cwd = wasm_dup_bytes(c"/".ptr, 1)
    wasm_cwd_len = 1

fn wasm_init_preopens():
    if wasm_preopens_ready != 0:
        return
    wasm_preopens_ready = 1
    var fd = 3
    while fd < 3 + WASM_PREOPEN_SLOTS:
        var prestat: [8]u8 = [0 as u8; 8]
        let pb = (&raw mut prestat) as *mut [8]u8 as i64
        let rc = fd_prestat_get(fd, pb as *mut u8)
        if rc == WASI_EBADF:
            break
        if rc != 0 or wasm_load_u8(pb, 0) != 0:
            fd = fd + 1
            continue
        let name_len = wasm_load_i32(pb, 4) as i64
        var name: [4096]u8 = [0 as u8; 4096]
        let nb = (&raw mut name) as *mut [4096]u8 as *mut u8
        if name_len >= WASM_PATH_MAX or fd_prestat_dir_name(fd, nb, name_len as i32) != 0:
            fd = fd + 1
            continue
        wasm_store_u8(nb as i64, name_len, 0)
        // "." is the host's notion of the cwd: map it to ours.
        var norm: [4096]u8 = [0 as u8; 4096]
        let normb = (&raw mut norm) as *mut [4096]u8 as *mut u8
        var n: i64 = 0
        if name_len == 1 and wasm_load_u8(nb as i64, 0) == 46:
            n = wasm_normalize_into(wasm_cwd as *const u8, wasm_cwd_len, normb, WASM_PATH_MAX)
        else:
            n = wasm_absolute_into(nb as *const u8, normb, WASM_PATH_MAX)
        if n > 0 and wasm_preopen_count < WASM_PREOPEN_SLOTS:
            let slot = wasm_preopen_count
            wasm_preopen_fds[slot] = fd
            wasm_preopen_names[slot] = wasm_dup_bytes(normb as *const u8, n)
            wasm_preopen_lens[slot] = n
            wasm_preopen_count = wasm_preopen_count + 1
        fd = fd + 1

// Resolve `path` to (preopen fd, WASI-relative path in `out`). Returns
// the relative length (>= 1; "." names the preopen itself) or a negated
// POSIX errno.
fn wasm_resolve(path: *const u8, out: *mut u8, cap: i64, fd_out: *mut i32) -> i64:
    var abs: [4096]u8 = [0 as u8; 4096]
    let ab = (&raw mut abs) as *mut [4096]u8 as *mut u8
    let n = wasm_absolute_into(path, ab, WASM_PATH_MAX)
    if n < 0:
        return wasm_fail(37) as i64
    var best = -1
    var best_len: i64 = -1
    for i in 0..wasm_preopen_count:
        let plen = wasm_preopen_lens[i]
        let pname = wasm_preopen_names[i]
        if plen > n:
            continue
        var matched = true
        var k: i64 = 0
        while k < plen:
            if wasm_load_u8(pname, k) != wasm_load_u8(ab as i64, k):
                matched = false
                break
            k = k + 1
        if not matched:
            continue
        // boundary: the preopen is "/" or the next byte is '/' or end
        if plen != 1 and n > plen and wasm_load_u8(ab as i64, plen) != 47:
            continue
        if plen > best_len:
            best = i
            best_len = plen
    if best < 0:
        return wasm_fail(WASI_ENOENT) as i64
    unsafe *fd_out = wasm_preopen_fds[best]
    var start = best_len
    while start < n and wasm_load_u8(ab as i64, start) == 47:
        start = start + 1
    let rel_len = n - start
    if rel_len <= 0:
        if cap < 2:
            return wasm_fail(37) as i64
        wasm_store_u8(out as i64, 0, 46)
        wasm_store_u8(out as i64, 1, 0)
        return 1
    if rel_len + 1 > cap:
        return wasm_fail(37) as i64
    let _ = with_memcpy(out, (ab as i64 + start) as *const u8, rel_len)
    wasm_store_u8(out as i64, rel_len, 0)
    rel_len

pub fn rt_getcwd(buf: *mut u8, size: i64) -> i32:
    wasm_init_cwd()
    if size < wasm_cwd_len + 1:
        return wasm_fail(68)
    let _ = with_memcpy(buf, wasm_cwd as *const u8, wasm_cwd_len + 1)
    0

pub fn rt_realpath(path: *const u8, resolved_path: *mut u8) -> *mut u8:
    wasm_init_cwd()
    if wasm_absolute_into(path, resolved_path, WASM_PATH_MAX) < 0:
        return 0 as *mut u8
    resolved_path

// ── files and directories ─────────────────────────────────────────────

// The rights for an open with the canonical access mode (0 read, 1 write,
// 2 read/write): everything, minus the side the mode does not ask for.
fn wasm_open_rights(accmode: i32) -> i64:
    if accmode == 0:
        return WASI_RIGHTS_ALL - WASI_RIGHT_FD_WRITE - WASI_RIGHT_FD_ALLOCATE - WASI_RIGHT_FD_FILESTAT_SET_SIZE
    if accmode == RT_O_WRONLY:
        return WASI_RIGHTS_ALL - WASI_RIGHT_FD_READ
    WASI_RIGHTS_ALL

fn wasm_open_rel(dirfd: i32, rel: *const u8, rel_len: i64, oflags: i32, fdflags: i32, rights: i64, follow: i32) -> i32:
    var fd: i32 = -1
    let rc = path_open(dirfd, if follow != 0: WASI_LOOKUP_SYMLINK_FOLLOW else: 0, rel, rel_len as i32, oflags, rights, WASI_RIGHTS_ALL, fdflags, &raw mut fd)
    if rc != 0:
        return wasm_fail(rc)
    fd

fn wasm_open_wasi(path: *const u8, oflags: i32, fdflags: i32, rights: i64) -> i32:
    var rel: [4096]u8 = [0 as u8; 4096]
    let rb = (&raw mut rel) as *mut [4096]u8 as *mut u8
    var dirfd: i32 = -1
    let n = wasm_resolve(path, rb, WASM_PATH_MAX, &raw mut dirfd)
    if n < 0:
        return n as i32
    wasm_open_rel(dirfd, rb as *const u8, n, oflags, fdflags, rights, 1)

pub fn rt_open(path: *const u8, flags: i32, mode: i32) -> i32:
    let _ = mode
    var oflags = 0
    var fdflags = 0
    if (flags & RT_O_CREAT) != 0: oflags = oflags | WASI_O_CREAT
    if (flags & RT_O_TRUNC) != 0: oflags = oflags | WASI_O_TRUNC
    if (flags & RT_O_APPEND) != 0: fdflags = fdflags | WASI_FDFLAG_APPEND
    wasm_open_wasi(path, oflags, fdflags, wasm_open_rights(flags & 3))

// The cimport_stubs spelling of open(2): its flag bits are
// O_APPEND=0x0008, O_CREAT=0x0200, O_TRUNC=0x0400, O_EXCL=0x0800.
pub fn __open(path: *const u8, flags: i32, mode: i32) -> i32:
    let _ = mode
    var oflags = 0
    var fdflags = 0
    if (flags & 0x0200) != 0: oflags = oflags | WASI_O_CREAT
    if (flags & 0x0400) != 0: oflags = oflags | WASI_O_TRUNC
    if (flags & 0x0800) != 0: oflags = oflags | WASI_O_EXCL
    if (flags & 0x0008) != 0: fdflags = fdflags | WASI_FDFLAG_APPEND
    wasm_open_wasi(path, oflags, fdflags, wasm_open_rights(flags & 3))

// filestat: filetype u8 @16, size u64 @32, mtim u64 @48 (64 bytes).
fn wasm_path_stat(path: *const u8, follow: i32, out_base: i64) -> i32:
    var rel: [4096]u8 = [0 as u8; 4096]
    let rb = (&raw mut rel) as *mut [4096]u8 as *mut u8
    var dirfd: i32 = -1
    let n = wasm_resolve(path, rb, WASM_PATH_MAX, &raw mut dirfd)
    if n < 0:
        return n as i32
    let rc = path_filestat_get(dirfd, if follow != 0: WASI_LOOKUP_SYMLINK_FOLLOW else: 0, rb as *const u8, n as i32, out_base as *mut u8)
    if rc != 0:
        return wasm_fail(rc)
    0

pub fn rt_stat(path: *const u8, out_raw: *mut u8) -> i32:
    let out = out_raw as *mut RtStatBuf
    var st: [64]u8 = [0 as u8; 64]
    let base = (&raw mut st) as *mut [64]u8 as i64
    let rc = wasm_path_stat(path, 1, base)
    if rc != 0:
        return rc
    let ft = wasm_load_u8(base, 16)
    (unsafe *out).size = wasm_load_i64(base, 32)
    (unsafe *out).is_dir = if ft == WASI_FILETYPE_DIRECTORY: 1 else: 0
    (unsafe *out).is_file = if ft == WASI_FILETYPE_REGULAR: 1 else: 0
    (unsafe *out).modified_ns = wasm_load_i64(base, 48)
    0

// lstat-style mode word: WASI has no permission bits, so a plausible
// default accompanies the file type.
pub fn rt_file_mode(path: *const u8) -> i32:
    var st: [64]u8 = [0 as u8; 64]
    let base = (&raw mut st) as *mut [64]u8 as i64
    if wasm_path_stat(path, 0, base) != 0:
        return -1
    let ft = wasm_load_u8(base, 16)
    if ft == WASI_FILETYPE_DIRECTORY:
        return RT_S_IFDIR | 0o755
    if ft == WASI_FILETYPE_SYMLINK:
        return RT_S_IFLNK | 0o777
    RT_S_IFREG | 0o644

fn wasm_lstat_is_dir(path: *const u8) -> bool:
    let mode = rt_file_mode(path)
    mode >= 0 and (mode & RT_S_IFMT) == RT_S_IFDIR

pub fn rt_access(path: *const u8, mode: i32) -> i32:
    let _ = mode
    var st: [64]u8 = [0 as u8; 64]
    let base = (&raw mut st) as *mut [64]u8 as i64
    wasm_path_stat(path, 1, base)

pub fn rt_chmod(path: *const u8, mode: i32) -> i32:
    // WASI preview1 has no permission bits to set; the file keeps the
    // host's defaults.
    let _ = path
    let _ = mode
    0

// A resolved path plus the WASI directory it lives in, for the
// path_* calls that take one.
fn wasm_path_call(path: *const u8, op: i32) -> i32:
    var rel: [4096]u8 = [0 as u8; 4096]
    let rb = (&raw mut rel) as *mut [4096]u8 as *mut u8
    var dirfd: i32 = -1
    let n = wasm_resolve(path, rb, WASM_PATH_MAX, &raw mut dirfd)
    if n < 0:
        return n as i32
    var rc = 0
    if op == 0:
        rc = path_create_directory(dirfd, rb as *const u8, n as i32)
    else if op == 1:
        rc = path_unlink_file(dirfd, rb as *const u8, n as i32)
    else:
        rc = path_remove_directory(dirfd, rb as *const u8, n as i32)
    if rc != 0:
        return wasm_fail(rc)
    0

pub fn rt_mkdir(path: *const u8, mode: i32) -> i32:
    let _ = mode
    wasm_path_call(path, 0)

pub fn rt_unlink(path: *const u8) -> i32:
    wasm_path_call(path, 1)

pub fn rt_rmdir(path: *const u8) -> i32:
    wasm_path_call(path, 2)

pub fn rt_rename(old_path: *const u8, new_path: *const u8) -> i32:
    var old_rel: [4096]u8 = [0 as u8; 4096]
    var new_rel: [4096]u8 = [0 as u8; 4096]
    let ob = (&raw mut old_rel) as *mut [4096]u8 as *mut u8
    let nb = (&raw mut new_rel) as *mut [4096]u8 as *mut u8
    var old_fd: i32 = -1
    var new_fd: i32 = -1
    let on = wasm_resolve(old_path, ob, WASM_PATH_MAX, &raw mut old_fd)
    if on < 0:
        return on as i32
    let nn = wasm_resolve(new_path, nb, WASM_PATH_MAX, &raw mut new_fd)
    if nn < 0:
        return nn as i32
    let rc = path_rename(old_fd, ob as *const u8, on as i32, new_fd, nb as *const u8, nn as i32)
    if rc != 0:
        return wasm_fail(rc)
    0

pub fn rt_symlink(target: *const u8, link_path: *const u8) -> i32:
    var rel: [4096]u8 = [0 as u8; 4096]
    let rb = (&raw mut rel) as *mut [4096]u8 as *mut u8
    var dirfd: i32 = -1
    let n = wasm_resolve(link_path, rb, WASM_PATH_MAX, &raw mut dirfd)
    if n < 0:
        return n as i32
    let rc = path_symlink(target, wasm_cstr_len(target) as i32, dirfd, rb as *const u8, n as i32)
    if rc != 0:
        return wasm_fail(rc)
    0

fn rt_empty_str() -> str:
    with_str_from_bytes(c" ".ptr, 0)

pub fn rt_readlink(path: *const u8) -> str:
    var rel: [4096]u8 = [0 as u8; 4096]
    let rb = (&raw mut rel) as *mut [4096]u8 as *mut u8
    var dirfd: i32 = -1
    let n = wasm_resolve(path, rb, WASM_PATH_MAX, &raw mut dirfd)
    if n < 0:
        return rt_empty_str()
    var buf: [4096]u8 = [0 as u8; 4096]
    let bb = (&raw mut buf) as *mut [4096]u8 as *mut u8
    var used: i32 = 0
    let rc = path_readlink(dirfd, rb as *const u8, n as i32, bb, 4095, &raw mut used)
    if rc != 0:
        let _ = wasm_fail(rc)
        return rt_empty_str()
    with_str_from_bytes(bb as *const u8, used as i64)

// Directory listing: the names of `path`'s entries (excluding "." and
// ".."), NUL-separated in a with_alloc'd buffer. Returns the byte count
// through `len_out` and the buffer, or null on error.
fn wasm_read_dir_names(path: *const u8, len_out: *mut i64) -> *mut u8:
    let fd = wasm_open_wasi(path, WASI_O_DIRECTORY, 0, wasm_open_rights(0))
    if fd < 0:
        return 0 as *mut u8
    var cap: i64 = 4096
    var out = with_alloc(cap)
    var used_out: i64 = 0
    var cookie: i64 = 0
    var buf: [4096]u8 = [0 as u8; 4096]
    let bb = (&raw mut buf) as *mut [4096]u8 as i64
    var done = false
    while not done:
        var used: i32 = 0
        let rc = fd_readdir(fd, bb as *mut u8, 4096, cookie, &raw mut used)
        if rc != 0:
            let _ = wasm_fail(rc)
            let _ = fd_close(fd)
            with_free(out)
            return 0 as *mut u8
        var pos: i64 = 0
        var progressed = false
        while pos + 24 <= used as i64:
            let next = wasm_load_i64(bb, pos)
            let name_len = wasm_load_i32(bb, pos + 16) as i64
            if pos + 24 + name_len > used as i64:
                break
            let name_ptr = bb + pos + 24
            let is_dot = name_len == 1 and wasm_load_u8(name_ptr, 0) == 46
            let is_dotdot = name_len == 2 and wasm_load_u8(name_ptr, 0) == 46 and wasm_load_u8(name_ptr, 1) == 46
            if not is_dot and not is_dotdot:
                if used_out + name_len + 1 > cap:
                    var new_cap = cap * 2
                    while used_out + name_len + 1 > new_cap:
                        new_cap = new_cap * 2
                    let grown = with_alloc(new_cap)
                    let _ = with_memcpy(grown, out as *const u8, used_out)
                    with_free(out)
                    out = grown
                    cap = new_cap
                let _ = with_memcpy((out as i64 + used_out) as *mut u8, name_ptr as *const u8, name_len)
                used_out = used_out + name_len
                wasm_store_u8(out as i64, used_out, 0)
                used_out = used_out + 1
            cookie = next
            pos = pos + 24 + name_len
            progressed = true
        if (used as i64) < 4096 or not progressed:
            done = true
    let _ = fd_close(fd)
    unsafe *len_out = used_out
    out

fn wasm_path_join(parent: *const u8, name: *const u8, out: *mut u8, cap: i64) -> i32:
    let plen = wasm_cstr_len(parent)
    let nlen = wasm_cstr_len(name)
    if plen + 1 + nlen + 1 > cap:
        return -1
    let ob = out as i64
    let _ = with_memcpy(out, parent, plen)
    var at = plen
    if plen > 0 and wasm_load_u8(parent as i64, plen - 1) != 47:
        wasm_store_u8(ob, at, 47)
        at = at + 1
    let _ = with_memcpy((ob + at) as *mut u8, name, nlen)
    wasm_store_u8(ob, at + nlen, 0)
    0

fn rt_list_files_walk(path: *const u8, out: str) -> str:
    if not wasm_lstat_is_dir(path):
        if rt_file_mode(path) < 0:
            return out
        return out ++ with_str_from_cstr(path) ++ "\n"
    var names_len: i64 = 0
    let names = wasm_read_dir_names(path, &raw mut names_len)
    if names as i64 == 0:
        return out
    var result = out
    var at: i64 = 0
    while at < names_len:
        let name = (names as i64 + at) as *const u8
        let nlen = wasm_cstr_len(name)
        var child: [4096]u8 = [0 as u8; 4096]
        let cb = (&raw mut child) as *mut [4096]u8 as *mut u8
        if wasm_path_join(path, name, cb, WASM_PATH_MAX) == 0:
            result = rt_list_files_walk(cb as *const u8, result)
        at = at + nlen + 1
    with_free(names)
    result

pub fn rt_list_files(path: *const u8) -> str:
    rt_list_files_walk(path, rt_empty_str())

pub fn rt_remove_tree(path: *const u8) -> i32:
    if not wasm_lstat_is_dir(path):
        return rt_unlink(path)
    var names_len: i64 = 0
    let names = wasm_read_dir_names(path, &raw mut names_len)
    if names as i64 == 0:
        return -wasm_errno
    var at: i64 = 0
    var rc = 0
    while at < names_len:
        let name = (names as i64 + at) as *const u8
        let nlen = wasm_cstr_len(name)
        var child: [4096]u8 = [0 as u8; 4096]
        let cb = (&raw mut child) as *mut [4096]u8 as *mut u8
        if wasm_path_join(path, name, cb, WASM_PATH_MAX) == 0:
            let child_rc = rt_remove_tree(cb as *const u8)
            if child_rc != 0 and rc == 0:
                rc = child_rc
        at = at + nlen + 1
    with_free(names)
    if rc != 0:
        return rc
    rt_rmdir(path)

fn rt_copy_file(src: *const u8, dst: *const u8) -> i32:
    let in_fd = wasm_open_wasi(src, 0, 0, wasm_open_rights(0))
    if in_fd < 0:
        return in_fd
    let out_fd = wasm_open_wasi(dst, WASI_O_CREAT | WASI_O_TRUNC, 0, wasm_open_rights(RT_O_WRONLY))
    if out_fd < 0:
        let _ = fd_close(in_fd)
        return out_fd
    let cap: i64 = 65536
    let buf = with_alloc(cap)
    var rc = 0
    while true:
        let n = rt_read(in_fd, buf, cap)
        if n < 0:
            rc = n as i32
            break
        if n == 0:
            break
        let w = rt_write(out_fd, buf as *const u8, n)
        if w < n:
            rc = if w < 0: w as i32 else: -5
            break
    with_free(buf)
    let _ = fd_close(in_fd)
    let _ = fd_close(out_fd)
    rc

pub fn rt_copy_tree(src: *const u8, dst: *const u8) -> i32:
    if not wasm_lstat_is_dir(src):
        return rt_copy_file(src, dst)
    let mk = rt_mkdir(dst, 0o755)
    if mk != 0 and mk != -17:
        return mk
    var names_len: i64 = 0
    let names = wasm_read_dir_names(src, &raw mut names_len)
    if names as i64 == 0:
        return -wasm_errno
    var at: i64 = 0
    var rc = 0
    while at < names_len:
        let name = (names as i64 + at) as *const u8
        let nlen = wasm_cstr_len(name)
        var child_src: [4096]u8 = [0 as u8; 4096]
        var child_dst: [4096]u8 = [0 as u8; 4096]
        let sb = (&raw mut child_src) as *mut [4096]u8 as *mut u8
        let db = (&raw mut child_dst) as *mut [4096]u8 as *mut u8
        if wasm_path_join(src, name, sb, WASM_PATH_MAX) == 0 and wasm_path_join(dst, name, db, WASM_PATH_MAX) == 0:
            let child_rc = rt_copy_tree(sb as *const u8, db as *const u8)
            if child_rc != 0 and rc == 0:
                rc = child_rc
        at = at + nlen + 1
    with_free(names)
    rc

pub fn rt_mkstemp(template_path: *mut u8) -> i32:
    let len = wasm_cstr_len(template_path as *const u8)
    if len < 6:
        return wasm_fail(WASI_EINVAL)
    let tb = template_path as i64
    var k: i64 = 0
    while k < 6:
        if wasm_load_u8(tb, len - 1 - k) != 88:
            return wasm_fail(WASI_EINVAL)
        k = k + 1
    var attempt = 0
    while attempt < 100:
        var rnd: [6]u8 = [0 as u8; 6]
        let rb = (&raw mut rnd) as *mut [6]u8 as i64
        rt_fill_random(rb as *mut u8, 6 as u64)
        var j: i64 = 0
        while j < 6:
            let v = wasm_load_u8(rb, j) % 36
            wasm_store_u8(tb, len - 6 + j, if v < 26: 97 + v else: 48 + v - 26)
            j = j + 1
        let fd = wasm_open_wasi(template_path as *const u8, WASI_O_CREAT | WASI_O_EXCL, 0, wasm_open_rights(RT_O_RDWR))
        if fd >= 0:
            return fd
        if fd != -17:
            return fd
        attempt = attempt + 1
    wasm_fail(WASI_EEXIST)

// ── args and environment ──────────────────────────────────────────────

var rt_argc: i32 = 0
var rt_argv_raw: i64 = 0

pub fn rt_store_args(argc_val: i32, argv_val: *const *const u8) -> Unit:
    rt_argc = argc_val
    rt_argv_raw = argv_val as i64

pub fn rt_args() -> (*const *const u8, i32):
    (rt_argv_raw as *const *const u8, rt_argc)

var wasm_env: i64 = 0
var wasm_env_count: i64 = 0
var wasm_env_cap: i64 = 0
var wasm_env_ready: i32 = 0

fn wasm_init_env():
    if wasm_env_ready != 0:
        return
    wasm_env_ready = 1
    var count: i32 = 0
    var size: i32 = 0
    if environ_sizes_get(&raw mut count, &raw mut size) != 0:
        count = 0
        size = 0
    wasm_env_cap = count as i64 + 64
    wasm_env = with_alloc(wasm_env_cap * WASM_PTR) as i64
    if count > 0:
        let blob = with_alloc(size as i64 + 1)
        if environ_get(wasm_env as *mut *mut u8, blob) == 0:
            wasm_env_count = count as i64

pub fn rt_getenv(name: *const u8) -> *const u8:
    wasm_init_env()
    let nlen = wasm_cstr_len(name)
    var i: i64 = 0
    while i < wasm_env_count:
        let entry = wasm_load_ptr(wasm_env, i * WASM_PTR) as i64
        var k: i64 = 0
        while k < nlen and wasm_load_u8(entry, k) == wasm_load_u8(name as i64, k):
            k = k + 1
        if k == nlen and wasm_load_u8(entry, nlen) == 61:
            return (entry + nlen + 1) as *const u8
        i = i + 1
    0 as *const u8

fn wasm_str_data(s: &str) -> *const u8:
    unsafe **(&s as *const *const *const u8)

pub fn rt_compat_setenv_str(name: &str, value: &str) -> i32:
    wasm_init_env()
    let nlen = name.len()
    let vlen = value.len()
    let entry = with_alloc(nlen + 1 + vlen + 1)
    if entry as i64 == 0:
        return -1
    let eb = entry as i64
    let _ = with_memcpy(entry, wasm_str_data(name), nlen)
    wasm_store_u8(eb, nlen, 61)
    let _ = with_memcpy((eb + nlen + 1) as *mut u8, wasm_str_data(value), vlen)
    wasm_store_u8(eb, nlen + 1 + vlen, 0)
    var i: i64 = 0
    while i < wasm_env_count:
        let existing = wasm_load_ptr(wasm_env, i * WASM_PTR) as i64
        var k: i64 = 0
        while k < nlen and wasm_load_u8(existing, k) == wasm_load_u8(eb, k):
            k = k + 1
        if k == nlen and wasm_load_u8(existing, nlen) == 61:
            wasm_store_ptr(wasm_env, i * WASM_PTR, entry as *const u8)
            return 0
        i = i + 1
    if wasm_env_count + 1 >= wasm_env_cap:
        let new_cap = wasm_env_cap * 2
        let grown = with_alloc(new_cap * WASM_PTR)
        let _ = with_memcpy(grown, wasm_env as *const u8, wasm_env_count * WASM_PTR)
        wasm_env = grown as i64
        wasm_env_cap = new_cap
    wasm_store_ptr(wasm_env, wasm_env_count * WASM_PTR, entry as *const u8)
    wasm_env_count = wasm_env_count + 1
    wasm_store_ptr(wasm_env, wasm_env_count * WASM_PTR, 0 as *const u8)
    0

var wasm_argc: i32 = 0
var wasm_argv: i64 = 0

fn wasm_init_args():
    var count: i32 = 0
    var size: i32 = 0
    if args_sizes_get(&raw mut count, &raw mut size) != 0:
        count = 0
        size = 0
    let argv = with_alloc((count as i64 + 1) * WASM_PTR)
    if count > 0:
        let blob = with_alloc(size as i64 + 1)
        if args_get(argv as *mut *mut u8, blob) != 0:
            count = 0
    wasm_store_ptr(argv as i64, count as i64 * WASM_PTR, 0 as *const u8)
    wasm_argc = count
    wasm_argv = argv as i64

// ── program entry ─────────────────────────────────────────────────────
//
// Codegen emits `_start` (wasm-ld's entry) for a wasm target: it calls
// with_wasm_startup for argc/argv, runs the usual runtime init + main +
// shutdown sequence, and leaves through with_wasm_exit — a plain return
// from _start would report success whatever main returned.

pub fn with_wasm_startup(argc_out: *mut i32, argv_out: *mut *const *const u8) -> Unit:
    wasm_heap_init()
    wasm_init_env()
    wasm_init_cwd()
    wasm_init_preopens()
    wasm_init_args()
    unsafe *argc_out = wasm_argc
    unsafe *argv_out = wasm_argv as *const *const u8

pub fn with_wasm_exit(code: i32) -> Never:
    proc_exit(code)

// ── clocks, sleep, randomness ─────────────────────────────────────────

pub fn rt_clock_ns() -> i64:
    var t: i64 = 0
    if clock_time_get(WASI_CLOCK_MONOTONIC, 1, &raw mut t) != 0:
        return 0
    t

pub fn rt_wall_clock_sec() -> i64:
    var t: i64 = 0
    if clock_time_get(WASI_CLOCK_REALTIME, 1000000000, &raw mut t) != 0:
        return 0
    t / 1000000000

// subscription (48 bytes): userdata u64 @0, tag u8 @8 (0 = clock),
// clock.id u32 @16, timeout u64 @24, precision u64 @32, flags u16 @40.
pub fn rt_nanosleep(ns: i64) -> i32:
    if ns <= 0:
        return 0
    var sub: [48]u8 = [0 as u8; 48]
    var ev: [32]u8 = [0 as u8; 32]
    let sb = (&raw mut sub) as *mut [48]u8 as i64
    let eb = (&raw mut ev) as *mut [32]u8 as i64
    wasm_store_i32(sb, 16, WASI_CLOCK_MONOTONIC)
    wasm_store_i64(sb, 24, ns)
    var nevents: i32 = 0
    let rc = poll_oneoff(sb as *const u8, eb as *mut u8, 1, &raw mut nevents)
    if rc != 0:
        return wasm_fail(rc)
    0

pub fn rt_fill_random(buf: *mut u8, len: u64) -> Unit:
    if random_get(buf, len as i32) != 0:
        wasm_write_cstr(2, c"fatal: could not read host randomness\n".ptr)
        proc_exit(1)

// ── system information ────────────────────────────────────────────────

pub fn rt_sysinfo(out_raw: *mut u8) -> i32:
    let out = out_raw as *mut RtSysInfo
    (unsafe *out).cpu_cores = 1
    (unsafe *out).page_size = WASM_PAGE
    (unsafe *out).memory_total = (wasm_memory_size(0) as i64) * WASM_PAGE
    0

pub fn rt_sysinfo_os() -> str:
    with_str_from_cstr(c"Wasi".ptr)

pub fn rt_sysinfo_arch() -> str:
    with_str_from_cstr(c"wasm32".ptr)

// ── networking (no sockets in WASI preview1) ──────────────────────────

fn rt_net_empty_str() -> str: rt_empty_str()

pub fn with_net_tcp_connect(host: &str, port: i32) -> i32:
    let _ = host
    let _ = port
    wasm_fail(WASI_ENOSYS)

pub fn with_net_udp_connect(host: &str, port: i32) -> i32:
    let _ = host
    let _ = port
    wasm_fail(WASI_ENOSYS)

pub fn with_net_tcp_listen(port: i32, backlog: i32) -> i32:
    let _ = port
    let _ = backlog
    wasm_fail(WASI_ENOSYS)

pub fn with_net_tcp_accept(sock: i32) -> i32:
    let _ = sock
    wasm_fail(WASI_ENOSYS)

pub fn with_net_udp_bind(port: i32) -> i32:
    let _ = port
    wasm_fail(WASI_ENOSYS)

pub fn with_net_sock_port(sock: i32) -> i32:
    let _ = sock
    wasm_fail(WASI_ENOSYS)

pub fn with_net_send(sock: i32, data: &str) -> i64:
    let _ = sock
    let _ = data
    wasm_fail(WASI_ENOSYS) as i64

pub fn with_net_recv(sock: i32, max_len: i64) -> str:
    let _ = sock
    let _ = max_len
    rt_net_empty_str()

pub fn with_net_close(sock: i32) -> i32:
    rt_close(sock)

// ── compiler compatibility process adapter ────────────────────────────
//
// No processes, signals, or resource limits exist under WASI preview1.
// Every exec reports failure (-1) the way a failed fork does natively;
// the interrupt/limit hooks are no-ops.

pub fn rt_compat_install_interrupt_handlers() -> Unit:
    let _ = 0

pub fn rt_compat_raise_stack_limit() -> Unit:
    let _ = 0

pub fn rt_compat_interrupt_requested() -> i32: 0

pub fn rt_compat_exec_binary(path: &str) -> i32:
    let _ = path
    -1

pub fn rt_compat_exec_argv(args: &str) -> i32:
    let _ = args
    -1

pub fn rt_compat_exec_argv_cwd(args: &str, cwd: &str) -> i32:
    let _ = args
    let _ = cwd
    -1

pub fn rt_compat_exec_argv_capture(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32) -> i32:
    let _ = args
    let _ = stdout_path
    let _ = stderr_path
    let _ = timeout_ms
    -1

pub fn rt_compat_exec_argv_capture_input(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32, stdin_path: &str) -> i32:
    let _ = args
    let _ = stdout_path
    let _ = stderr_path
    let _ = timeout_ms
    let _ = stdin_path
    -1

pub fn rt_compat_exec_argv_capture_cwd(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32, cwd: &str) -> i32:
    let _ = args
    let _ = stdout_path
    let _ = stderr_path
    let _ = timeout_ms
    let _ = cwd
    -1

pub fn rt_compat_exec_argv_capture_spawn(args: &str, stdout_path: &str, stderr_path: &str) -> i32:
    let _ = args
    let _ = stdout_path
    let _ = stderr_path
    -1

pub fn rt_compat_exec_wait(pid: i32, timeout_ms: i32) -> i32:
    let _ = pid
    let _ = timeout_ms
    -1

pub fn rt_compat_exec_try_wait(pid: i32) -> i32:
    let _ = pid
    -1

pub fn rt_compat_exec_child_maxrss() -> i64: 0

pub fn rt_compat_self_maxrss() -> i64: 0

// ── the memcmp family ─────────────────────────────────────────────────
//
// LLVM may call these by name from comparison merging; with bulk-memory
// (the default feature set) memcpy/memset lower to memory.copy/fill, so
// no With loop here can be turned back into a call to itself.

// ── compiler-rt: 128-bit multiply ─────────────────────────────────────
//
// wasm has no 64x64->128 multiply-high instruction, so LLVM lowers every
// overflow-checked 64-bit multiply (With's default `*`) and every i128
// multiply to the __multi3 libcall. compiler-rt is not linked here; this
// is its wasm definition. Only wrapping `*%` may appear inside — a checked
// multiply would call __multi3 again.

fn wasm_mul_u64_wide(a: u64, b: u64, hi_out: *mut u64) -> u64:
    let a0 = a & 4294967295
    let a1 = a >> 32
    let b0 = b & 4294967295
    let b1 = b >> 32
    let p00 = a0 *% b0
    let p01 = a0 *% b1
    let p10 = a1 *% b0
    let p11 = a1 *% b1
    let mid = (p00 >> 32) +% (p01 & 4294967295) +% (p10 & 4294967295)
    unsafe *hi_out = p11 +% (p01 >> 32) +% (p10 >> 32) +% (mid >> 32)
    (mid << 32) | (p00 & 4294967295)

pub fn __multi3(a: i128, b: i128) -> i128:
    let alo = a as u64
    let ahi = (a >> 64) as u64
    let blo = b as u64
    let bhi = (b >> 64) as u64
    var hi: u64 = 0
    let lo = wasm_mul_u64_wide(alo, blo, &raw mut hi)
    hi = hi +% (alo *% bhi) +% (ahi *% blo)
    ((hi as i128) << 64) | (lo as i128)

pub fn memcmp(a: *const u8, b: *const u8, n: i32) -> i32:
    var i: i64 = 0
    while i < n as i64:
        let ca = wasm_load_u8(a as i64, i)
        let cb = wasm_load_u8(b as i64, i)
        if ca != cb:
            return if ca < cb: -1 else: 1
        i = i + 1
    0

pub fn bcmp(a: *const u8, b: *const u8, n: i32) -> i32:
    memcmp(a, b, n)

pub fn memcpy(dst: *mut u8, src: *const u8, n: i32) -> *mut u8:
    with_memcpy(dst, src, n as i64)

pub fn memmove(dst: *mut u8, src: *const u8, n: i32) -> *mut u8:
    let d = dst as i64
    let s = src as i64
    let len = n as i64
    if d == s or len <= 0:
        return dst
    if d < s or d >= s + len:
        return with_memcpy(dst, src, len)
    var i = len
    while i > 0:
        i = i - 1
        wasm_store_u8(d, i, wasm_load_u8(s, i))
    dst

pub fn memset(dst: *mut u8, c: i32, n: i32) -> *mut u8:
    with_memset(dst, c, n as i64)
