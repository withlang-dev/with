// rt/darwin_aarch64.w — macOS aarch64 runtime backend
//
// Implements the 13 rt_* functions by calling libSystem.
// All libSystem symbols declared as extern fn (no c_import, no libc headers).
//
// Error convention: negative return = negated errno.
// EINTR rule: retry internally on EINTR.
// rt_mmap returns null on failure (not MAP_FAILED).

// ── libSystem declarations ──────────────────────────────────────
// These are stable ABI symbols from libSystem.B.dylib.
// __open is the non-variadic internal symbol (open is variadic in C,
// which has a different calling convention on aarch64).

extern fn write(fd: i32, buf: *const u8, len: u64) -> i64
extern fn read(fd: i32, buf: *mut u8, len: u64) -> i64
extern fn __open(path: *const u8, flags: i32, mode: i32) -> i32
extern fn close(fd: i32) -> i32
extern fn lseek(fd: i32, offset: i64, whence: i32) -> i64
extern fn getcwd(buf: *mut u8, size: u64) -> *mut u8
extern fn mmap(addr: *mut u8, len: u64, prot: i32, flags: i32, fd: i32, offset: i64) -> *mut u8
extern fn munmap(addr: *mut u8, len: u64) -> i32
extern fn getenv(name: *const u8) -> *const u8
extern fn sysconf(name: i32) -> i64
extern fn stat(path: *const u8, buf: *mut u8) -> i32
extern fn chmod(path: *const u8, mode: i32) -> i32
extern fn _exit(code: i32) -> void
extern fn mach_absolute_time() -> u64
extern fn __error() -> *mut i32
extern fn arc4random_buf(buf: *mut u8, len: u64)
extern fn sigaltstack(ss: *const u8, old_ss: *mut u8) -> i32
extern fn sigaction(sig: i32, act: *const u8, old_act: *mut u8) -> i32
extern var __stdinp: *mut u8
extern var __stdoutp: *mut u8
extern var __stderrp: *mut u8

type MachTimebaseInfo:
    numer: u32
    denom: u32

extern fn mach_timebase_info(info: *mut MachTimebaseInfo) -> i32

// ── Helpers ─────────────────────────────────────────────────────

fn get_errno() -> i32:
    let p = __error()
    unsafe *p

// ── StatBuf (stdlib's view of metadata) ─────────────────────────

type RtStatBuf:
    size: i64
    is_dir: i32
    is_file: i32
    modified_ns: i64

// ── Argv storage ────────────────────────────────────────────────

var rt_argc: i32 = 0
var rt_argv_raw: i64 = 0

pub fn rt_store_args(argc_val: i32, argv_val: *const *const u8):
    rt_argc = argc_val
    rt_argv_raw = argv_val as i64

pub fn rt_fill_random(buf: *mut u8, len: u64):
    arc4random_buf(buf, len)

pub fn rt_libc_stdin() -> *mut u8:
    __stdinp

pub fn rt_libc_stdout() -> *mut u8:
    __stdoutp

pub fn rt_libc_stderr() -> *mut u8:
    __stderrp

pub fn rt_fiber_page_size() -> i64:
    let page_size = sysconf(29)
    if page_size > 0:
        return page_size
    16384

pub fn rt_fiber_mmap_flags() -> i32:
    // Darwin: MAP_PRIVATE | MAP_ANON.
    0x1002

pub fn rt_fiber_fault_addr(info: *const u8) -> i64:
    if info as i64 == 0:
        return 0
    unsafe:
        *((info as i64 + 24) as *const i64)

fn darwin_store_i64(base: i64, offset: i64, value: i64):
    unsafe:
        *((base + offset) as *mut i64) = value

fn darwin_store_i32(base: i64, offset: i64, value: i32):
    unsafe:
        *((base + offset) as *mut i32) = value

fn darwin_zero_sigaction(sig: i32):
    var sa: [16]u8 = [0 as u8; 16]
    let sa_base = (&raw mut sa) as *mut [16]u8 as i64
    let _ = sigaction(sig, sa_base as *const u8, 0 as *mut u8)

pub fn rt_fiber_reset_signal_handler(sig: i32):
    darwin_zero_sigaction(sig)

pub fn rt_fiber_install_signal_handlers(alt_stack: *mut u8, alt_stack_size: i64, handler: i64):
    var ss: [24]u8 = [0 as u8; 24]
    let ss_base = (&raw mut ss) as *mut [24]u8 as i64
    darwin_store_i64(ss_base, 0, alt_stack as i64)
    darwin_store_i64(ss_base, 8, alt_stack_size)
    darwin_store_i32(ss_base, 16, 0)
    let _ = sigaltstack(ss_base as *const u8, 0 as *mut u8)

    var sa: [16]u8 = [0 as u8; 16]
    let sa_base = (&raw mut sa) as *mut [16]u8 as i64
    darwin_store_i64(sa_base, 0, handler)
    darwin_store_i32(sa_base, 12, 0x0040 | 0x0001)
    let _ = sigaction(11, sa_base as *const u8, 0 as *mut u8)
    let _ = sigaction(10, sa_base as *const u8, 0 as *mut u8)

// ── I/O ─────────────────────────────────────────────────────────

pub fn rt_write(fd: i32, buf: *const u8, len: i64) -> i64:
    var r: i64 = 0
    loop:
        r = write(fd, buf, len as u64)
        if r >= 0 or get_errno() != 4:
            break
    if r < 0:
        return -(get_errno() as i64)
    r

pub fn rt_read(fd: i32, buf: *mut u8, len: i64) -> i64:
    var r: i64 = 0
    loop:
        r = read(fd, buf, len as u64)
        if r >= 0 or get_errno() != 4:
            break
    if r < 0:
        return -(get_errno() as i64)
    r

pub fn rt_open(path: *const u8, flags: i32, mode: i32) -> i32:
    // Map canonical flags to native darwin flags
    // Canonical: O_RDONLY=0, O_WRONLY=1, O_RDWR=2, O_CREAT=0x200, O_TRUNC=0x400, O_APPEND=0x800
    // Darwin:    O_RDONLY=0, O_WRONLY=1, O_RDWR=2, O_CREAT=0x200, O_TRUNC=0x400, O_APPEND=0x008
    var native = flags & 3
    if (flags & 0x200) != 0: native = native | 0x200
    if (flags & 0x400) != 0: native = native | 0x400
    if (flags & 0x800) != 0: native = native | 0x008
    var r: i32 = 0
    loop:
        r = __open(path, native, mode)
        if r >= 0 or get_errno() != 4:
            break
    if r < 0:
        return -get_errno()
    r

pub fn rt_close(fd: i32) -> i32:
    var r: i32 = 0
    loop:
        r = close(fd)
        if r >= 0 or get_errno() != 4:
            break
    if r < 0:
        return -get_errno()
    0

pub fn rt_seek(fd: i32, offset: i64, whence: i32) -> i64:
    let r = lseek(fd, offset, whence)
    if r < 0:
        return -(get_errno() as i64)
    r

pub fn rt_stat(path: *const u8, out: *mut RtStatBuf) -> i32:
    var native_buf: [144]u8 = [0 as u8; 144]
    let r = stat(path, &native_buf as *mut u8)
    if r < 0:
        return -get_errno()
    // Extract fields from native stat struct (darwin aarch64 layout):
    // offset 4: st_mode (u16), offset 48: st_mtimespec.tv_sec (i64),
    // offset 56: st_mtimespec.tv_nsec (i64), offset 96: st_size (i64)
    let base = &native_buf as i64
    let size = unsafe *((base + 96) as *const i64)
    let mode = unsafe *((base + 4) as *const u16)
    let mtime_sec = unsafe *((base + 48) as *const i64)
    let mtime_nsec = unsafe *((base + 56) as *const i64)
    (unsafe *out).size = size
    (unsafe *out).is_dir = if (mode as i32 & 0o170000) == 0o040000: 1 else: 0
    (unsafe *out).is_file = if (mode as i32 & 0o170000) == 0o100000: 1 else: 0
    (unsafe *out).modified_ns = mtime_sec * 1000000000 + mtime_nsec
    0

pub fn rt_chmod(path: *const u8, mode: i32) -> i32:
    let r = chmod(path, mode)
    if r < 0:
        return -get_errno()
    0

pub fn rt_getcwd(buf: *mut u8, size: i64) -> i32:
    let r = getcwd(buf, size as u64)
    if r as i64 == 0:
        return -get_errno()
    0

// ── Memory ──────────────────────────────────────────────────────

pub fn rt_mmap(size: i64) -> *mut u8:
    // PROT_READ|PROT_WRITE = 3, MAP_PRIVATE|MAP_ANON = 0x1002
    let p = mmap(0 as *mut u8, size as u64, 3, 0x1002, -1, 0)
    if p as i64 == -1:  // MAP_FAILED
        return 0 as *mut u8
    p

pub fn rt_munmap(ptr: *mut u8, size: i64):
    let _ = munmap(ptr, size as u64)

// ── Process ─────────────────────────────────────────────────────

pub fn rt_exit(code: i32):
    _exit(code)

pub fn rt_args() -> (*const *const u8, i32):
    (rt_argv_raw as *const *const u8, rt_argc)

// ── Time ────────────────────────────────────────────────────────

var timebase_numer: i64 = 0
var timebase_denom: i64 = 0

pub fn rt_clock_ns() -> i64:
    if timebase_denom == 0:
        var info = MachTimebaseInfo { numer: 0, denom: 0 }
        let _ = mach_timebase_info(&raw mut info)
        timebase_numer = info.numer as i64
        timebase_denom = info.denom as i64
    let ticks = mach_absolute_time() as i64
    ticks * timebase_numer / timebase_denom

// ── Sleep ───────────────────────────────────────────────────────

type Timespec:
    tv_sec: i64
    tv_nsec: i64

extern fn nanosleep(req: *const Timespec, rem: *mut Timespec) -> i32

pub fn rt_nanosleep(ns: i64) -> i32:
    var req = Timespec { tv_sec: ns / 1000000000, tv_nsec: ns % 1000000000 }
    var rem = Timespec { tv_sec: 0, tv_nsec: 0 }
    var r: i32 = 0
    loop:
        r = nanosleep(&req, &raw mut rem)
        if r >= 0 or get_errno() != 4:
            break
        // EINTR: use remaining time for next attempt
        req = rem
    if r < 0:
        return -get_errno()
    0

// ── Process extras ──────────────────────────────────────────────

extern fn getpid() -> i32
extern fn raise(sig: i32) -> i32
extern fn kill(pid: i32, sig: i32) -> i32
extern fn pthread_attr_init(attr: *mut u8) -> i32
extern fn pthread_attr_setstacksize(attr: *mut u8, stacksize: u64) -> i32
extern fn pthread_attr_destroy(attr: *mut u8) -> i32
extern fn pthread_create(thread: *mut i64, attr: *const u8, start_routine: *mut u8, arg: *mut u8) -> i32
extern fn pthread_join(thread: i64, retval: *mut *mut u8) -> i32

pub fn rt_getpid() -> i32:
    getpid()

pub fn rt_kill(pid: i32, sig: i32) -> i32:
    let r = kill(pid, sig)
    if r < 0:
        return -get_errno()
    0

pub fn rt_raise(sig: i32) -> i32:
    let r = raise(sig)
    if r < 0:
        return -get_errno()
    0

pub fn rt_thread_spawn(start_routine: *mut u8, arg: *mut u8) -> i64:
    var handle: i64 = 0
    var attr: [64]u8 = [0 as u8; 64]
    var rc = pthread_attr_init(&raw mut attr[0])
    if rc != 0:
        return -(rc as i64)
    rc = pthread_attr_setstacksize(&raw mut attr[0], 16 * 1024 * 1024)
    if rc != 0:
        let _ = pthread_attr_destroy(&raw mut attr[0])
        return -(rc as i64)
    rc = pthread_create(&raw mut handle, &raw const attr[0], start_routine, arg)
    let destroy_rc = pthread_attr_destroy(&raw mut attr[0])
    if rc == 0 and destroy_rc != 0:
        return -(destroy_rc as i64)
    if rc != 0:
        return -(rc as i64)
    handle

pub fn rt_thread_join(handle: i64) -> i32:
    var retval: *mut u8 = 0 as *mut u8
    let rc = pthread_join(handle, &raw mut retval)
    if rc != 0:
        return -rc
    0

// ── Filesystem extras ───────────────────────────────────────────
// Beyond the core 13 rt_* functions — needed by std/fs.w

extern fn mkdir(path: *const u8, mode: u16) -> i32
extern fn unlink(path: *const u8) -> i32
extern fn rmdir(path: *const u8) -> i32
extern fn rename(old_path: *const u8, new_path: *const u8) -> i32
extern fn symlink(target: *const u8, link_path: *const u8) -> i32
extern fn access(path: *const u8, mode: i32) -> i32
extern fn lstat(path: *const u8, st: *mut u8) -> i32
extern fn opendir(path: *const u8) -> *mut u8
extern fn readdir(dirp: *mut u8) -> *mut u8
extern fn closedir(dirp: *mut u8) -> i32
extern fn with_str_from_cstr(s: *const u8) -> str
extern fn with_str_concat(a: str, b: str) -> str

let S_IFMT: i32 = 61440
let S_IFDIR: i32 = 16384
let DARWIN_STAT_SIZE: i64 = 144
let DARWIN_STAT_MODE_OFFSET: i64 = 4
let DARWIN_DIRENT_NAME_OFFSET: i64 = 21
let RT_PATH_MAX: i64 = 4096

fn rt_cstr_len(s: *const u8) -> i64:
    if s as i64 == 0:
        return 0
    var len: i64 = 0
    while unsafe *((s as i64 + len) as *const u8) != 0:
        len = len + 1
    len

fn rt_dirent_name(ent: *mut u8) -> *const u8:
    (ent as i64 + DARWIN_DIRENT_NAME_OFFSET) as *const u8

fn rt_dirent_is_dot_or_dotdot(name: *const u8) -> bool:
    let first = unsafe *name
    if first != 46:
        return false
    let second = unsafe *((name as i64 + 1) as *const u8)
    if second == 0:
        return true
    if second != 46:
        return false
    (unsafe *((name as i64 + 2) as *const u8)) == 0

fn rt_path_join(parent: *const u8, name: *const u8, out: *mut u8, cap: i64) -> i32:
    let parent_len = rt_cstr_len(parent)
    let name_len = rt_cstr_len(name)
    var need_slash = true
    if parent_len > 0 and unsafe *((parent as i64 + parent_len - 1) as *const u8) == 47:
        need_slash = false
    let slash_len: i64 = if need_slash: 1 else: 0
    if parent_len + slash_len + name_len + 1 > cap:
        return -36
    var i: i64 = 0
    while i < parent_len:
        unsafe *((out as i64 + i) as *mut u8) = unsafe *((parent as i64 + i) as *const u8)
        i = i + 1
    if need_slash:
        unsafe *((out as i64 + i) as *mut u8) = 47
        i = i + 1
    var j: i64 = 0
    while j < name_len:
        unsafe *((out as i64 + i + j) as *mut u8) = unsafe *((name as i64 + j) as *const u8)
        j = j + 1
    unsafe *((out as i64 + i + j) as *mut u8) = 0
    0

fn rt_lstat_mode(path: *const u8, mode_out: *mut i32) -> i32:
    var st: [144]u8 = [0 as u8; 144]
    let r = lstat(path, &st as *mut [144]u8 as *mut u8)
    if r < 0:
        return -get_errno()
    unsafe *mode_out = (unsafe *((&st as i64 + DARWIN_STAT_MODE_OFFSET) as *const u16)) as i32
    0

fn rt_lstat_is_dir(path: *const u8) -> bool:
    var mode: i32 = 0
    if rt_lstat_mode(path, &mode as *mut i32) != 0:
        return false
    (mode & S_IFMT) == S_IFDIR

pub fn rt_mkdir(path: *const u8, mode: i32) -> i32:
    var r: i32 = 0
    loop:
        r = mkdir(path, mode as u16)
        if r >= 0 or get_errno() != 4:
            break
    if r < 0:
        return -get_errno()
    0

pub fn rt_unlink(path: *const u8) -> i32:
    let r = unlink(path)
    if r < 0:
        return -get_errno()
    0

pub fn rt_rmdir(path: *const u8) -> i32:
    let r = rmdir(path)
    if r < 0:
        return -get_errno()
    0

pub fn rt_rename(old_path: *const u8, new_path: *const u8) -> i32:
    let r = rename(old_path, new_path)
    if r < 0:
        return -get_errno()
    0

pub fn rt_remove_tree(path: *const u8) -> i32:
    var mode: i32 = 0
    let stat_rc = rt_lstat_mode(path, &mode as *mut i32)
    if stat_rc != 0:
        return stat_rc
    if (mode & S_IFMT) != S_IFDIR:
        return rt_unlink(path)

    let dir = opendir(path)
    if dir as i64 == 0:
        return -get_errno()
    while true:
        let ent = readdir(dir)
        if ent as i64 == 0:
            break
        let name = rt_dirent_name(ent)
        if rt_dirent_is_dot_or_dotdot(name):
            continue
        var child: [4096]u8 = [0 as u8; 4096]
        let join_rc = rt_path_join(path, name, &child as *mut [4096]u8 as *mut u8, RT_PATH_MAX)
        if join_rc != 0:
            let _close_on_join = closedir(dir)
            return join_rc
        let child_rc = rt_remove_tree(&child as *const [4096]u8 as *const u8)
        if child_rc != 0:
            let _close_on_child = closedir(dir)
            return child_rc
    let close_rc = closedir(dir)
    if close_rc < 0:
        return -get_errno()
    rt_rmdir(path)

fn rt_copy_file_impl(src: *const u8, dst: *const u8, mode: i32) -> i32:
    let in_fd = rt_open(src, 0, 0)
    if in_fd < 0:
        return in_fd
    let out_fd = rt_open(dst, 1 | 0x200 | 0x400, mode & 0o777)
    if out_fd < 0:
        let _close_in_on_open = rt_close(in_fd)
        return out_fd
    var buf: [65536]u8 = [0 as u8; 65536]
    while true:
        let read_count = rt_read(in_fd, &buf as *mut [65536]u8 as *mut u8, 65536)
        if read_count < 0:
            let _close_in_on_read = rt_close(in_fd)
            let _close_out_on_read = rt_close(out_fd)
            return read_count as i32
        if read_count == 0:
            break
        var written: i64 = 0
        while written < read_count:
            let write_count = rt_write(out_fd, (&buf as i64 + written) as *const u8, read_count - written)
            if write_count < 0:
                let _close_in_on_write = rt_close(in_fd)
                let _close_out_on_write = rt_close(out_fd)
                return write_count as i32
            if write_count == 0:
                let _close_in_on_zero = rt_close(in_fd)
                let _close_out_on_zero = rt_close(out_fd)
                return -5
            written = written + write_count
    let close_in = rt_close(in_fd)
    let close_out = rt_close(out_fd)
    if close_in != 0:
        return close_in
    if close_out != 0:
        return close_out
    rt_chmod(dst, mode & 0o777)

pub fn rt_copy_tree(src: *const u8, dst: *const u8) -> i32:
    var mode: i32 = 0
    let stat_rc = rt_lstat_mode(src, &mode as *mut i32)
    if stat_rc != 0:
        return stat_rc
    if (mode & S_IFMT) != S_IFDIR:
        return rt_copy_file_impl(src, dst, mode)

    let mkdir_rc = rt_mkdir(dst, mode & 0o777)
    if mkdir_rc != 0 and not rt_lstat_is_dir(dst):
        return mkdir_rc

    let dir = opendir(src)
    if dir as i64 == 0:
        return -get_errno()
    while true:
        let ent = readdir(dir)
        if ent as i64 == 0:
            break
        let name = rt_dirent_name(ent)
        if rt_dirent_is_dot_or_dotdot(name):
            continue
        var child_src: [4096]u8 = [0 as u8; 4096]
        let src_join_rc = rt_path_join(src, name, &child_src as *mut [4096]u8 as *mut u8, RT_PATH_MAX)
        if src_join_rc != 0:
            let _close_on_src_join = closedir(dir)
            return src_join_rc
        var child_dst: [4096]u8 = [0 as u8; 4096]
        let dst_join_rc = rt_path_join(dst, name, &child_dst as *mut [4096]u8 as *mut u8, RT_PATH_MAX)
        if dst_join_rc != 0:
            let _close_on_dst_join = closedir(dir)
            return dst_join_rc
        let child_rc = rt_copy_tree(&child_src as *const [4096]u8 as *const u8, &child_dst as *const [4096]u8 as *const u8)
        if child_rc != 0:
            let _close_on_child = closedir(dir)
            return child_rc
    let close_rc = closedir(dir)
    if close_rc < 0:
        return -get_errno()
    rt_chmod(dst, mode & 0o777)

pub fn rt_symlink(target: *const u8, link_path: *const u8) -> i32:
    let r = symlink(target, link_path)
    if r < 0:
        return -get_errno()
    0

fn rt_empty_str() -> str:
    var empty: [1]u8 = [0 as u8; 1]
    with_str_from_cstr(&empty as *const [1]u8 as *const u8)

fn rt_newline_str() -> str:
    var newline: [2]u8 = [10 as u8, 0 as u8]
    with_str_from_cstr(&newline as *const [2]u8 as *const u8)

fn rt_list_files_append_line(out: str, path: *const u8) -> str:
    // TODO: O(n^2) string accumulation; replace with a builder when listed trees grow.
    with_str_concat(with_str_concat(out, with_str_from_cstr(path)), rt_newline_str())

fn rt_list_files_walk(path: *const u8, out: str) -> str:
    // TODO: partial-result on directory enumeration errors; propagate failures when callers need completeness guarantees.
    var mode: i32 = 0
    let stat_rc = rt_lstat_mode(path, &mode as *mut i32)
    if stat_rc != 0:
        return out
    if (mode & S_IFMT) != S_IFDIR:
        return rt_list_files_append_line(out, path)

    let dir = opendir(path)
    if dir as i64 == 0:
        return out
    var result = out
    while true:
        let ent = readdir(dir)
        if ent as i64 == 0:
            break
        let name = rt_dirent_name(ent)
        if rt_dirent_is_dot_or_dotdot(name):
            continue
        var child: [4096]u8 = [0 as u8; 4096]
        let join_rc = rt_path_join(path, name, &child as *mut [4096]u8 as *mut u8, RT_PATH_MAX)
        if join_rc != 0:
            continue
        result = rt_list_files_walk(&child as *const [4096]u8 as *const u8, result)
    let _close = closedir(dir)
    result

pub fn rt_list_files(path: *const u8) -> str:
    rt_list_files_walk(path, rt_empty_str())

pub fn rt_access(path: *const u8, mode: i32) -> i32:
    let r = access(path, mode)
    if r < 0:
        return -get_errno()
    0

// ── System info ─────────────────────────────────────────────────

type RtSysInfo:
    cpu_cores: i32
    memory_total: i64
    page_size: i64

extern fn sysctlbyname(name: *const u8, oldp: *mut u8, oldlenp: *mut i64, newp: *const u8, newlen: i64) -> i32

pub fn rt_sysinfo(out: *mut RtSysInfo) -> i32:
    // CPU cores: sysctl hw.logicalcpu
    var cores: i32 = 0
    var cores_len: i64 = 4
    let _ = sysctlbyname("hw.logicalcpu" as *const u8, &cores as *mut u8, &raw mut cores_len, 0 as *const u8, 0)
    (unsafe *out).cpu_cores = if cores > 0: cores else: 1

    // Total memory: sysctl hw.memsize
    var memsize: i64 = 0
    var memsize_len: i64 = 8
    let _ = sysctlbyname("hw.memsize" as *const u8, &memsize as *mut u8, &raw mut memsize_len, 0 as *const u8, 0)
    (unsafe *out).memory_total = memsize

    // Page size: sysconf(_SC_PAGESIZE)
    let ps = sysconf(29)  // _SC_PAGESIZE = 29 on darwin
    (unsafe *out).page_size = ps
    0

pub fn rt_sysinfo_os() -> str:
    with_str_from_cstr("Macos" as *const u8)

pub fn rt_sysinfo_arch() -> str:
    with_str_from_cstr("armv8" as *const u8)

// ── Environment ─────────────────────────────────────────────────

pub fn rt_getenv(name: *const u8) -> *const u8:
    getenv(name)
