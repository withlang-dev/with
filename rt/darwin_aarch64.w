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
extern fn lstat(path: *const u8, buf: *mut u8) -> i32
extern fn _exit(code: i32) -> void
extern fn mach_absolute_time() -> u64
extern fn __error() -> *mut i32

type MachTimebaseInfo:
    numer: u32
    denom: u32

extern fn mach_timebase_info(info: &mut MachTimebaseInfo) -> i32

// ── Helpers ─────────────────────────────────────────────────────

fn get_errno() -> i32:
    let p = __error()
    *p

// ── StatBuf (stdlib's view of metadata) ─────────────────────────

type RtStatBuf:
    size: i64
    is_dir: i32
    is_file: i32
    modified_ns: i64

// ── Argv storage ────────────────────────────────────────────────

var rt_argc: i32 = 0
var rt_argv_raw: i64 = 0

@[c_export("rt_store_args")]
pub fn store_args(argc_val: i32, argv_val: *const *const u8):
    rt_argc = argc_val
    rt_argv_raw = argv_val as i64

// ── I/O ─────────────────────────────────────────────────────────

@[c_export("rt_write")]
pub fn rt_write_impl(fd: i32, buf: *const u8, len: i64) -> i64:
    var r: i64 = 0
    loop:
        r = write(fd, buf, len as u64)
        if r >= 0 or get_errno() != 4:
            break
    if r < 0:
        return -(get_errno() as i64)
    r

@[c_export("rt_read")]
pub fn rt_read_impl(fd: i32, buf: *mut u8, len: i64) -> i64:
    var r: i64 = 0
    loop:
        r = read(fd, buf, len as u64)
        if r >= 0 or get_errno() != 4:
            break
    if r < 0:
        return -(get_errno() as i64)
    r

@[c_export("rt_open")]
pub fn rt_open_impl(path: *const u8, flags: i32, mode: i32) -> i32:
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

@[c_export("rt_close")]
pub fn rt_close_impl(fd: i32) -> i32:
    var r: i32 = 0
    loop:
        r = close(fd)
        if r >= 0 or get_errno() != 4:
            break
    if r < 0:
        return -get_errno()
    0

@[c_export("rt_seek")]
pub fn rt_seek_impl(fd: i32, offset: i64, whence: i32) -> i64:
    let r = lseek(fd, offset, whence)
    if r < 0:
        return -(get_errno() as i64)
    r

@[c_export("rt_stat")]
pub fn rt_stat_impl(path: *const u8, out: *mut RtStatBuf) -> i32:
    var native_buf: [144]u8 = [0 as u8; 144]
    let r = lstat(path, &native_buf as *mut u8)
    if r < 0:
        return -get_errno()
    // Extract fields from native stat struct (darwin aarch64 layout):
    // offset 4: st_mode (u16), offset 48: st_mtimespec.tv_sec (i64),
    // offset 56: st_mtimespec.tv_nsec (i64), offset 96: st_size (i64)
    let base = &native_buf as i64
    let size = *((base + 96) as *const i64)
    let mode = *((base + 4) as *const u16)
    let mtime_sec = *((base + 48) as *const i64)
    let mtime_nsec = *((base + 56) as *const i64)
    (*out).size = size
    (*out).is_dir = if (mode as i32 & 0o170000) == 0o040000: 1 else: 0
    (*out).is_file = if (mode as i32 & 0o170000) == 0o100000: 1 else: 0
    (*out).modified_ns = mtime_sec * 1000000000 + mtime_nsec
    0

@[c_export("rt_getcwd")]
pub fn rt_getcwd_impl(buf: *mut u8, size: i64) -> i32:
    let r = getcwd(buf, size as u64)
    if r as i64 == 0:
        return -get_errno()
    0

// ── Memory ──────────────────────────────────────────────────────

@[c_export("rt_mmap")]
pub fn rt_mmap_impl(size: i64) -> *mut u8:
    // PROT_READ|PROT_WRITE = 3, MAP_PRIVATE|MAP_ANON = 0x1002
    let p = mmap(0 as *mut u8, size as u64, 3, 0x1002, -1, 0)
    if p as i64 == -1:  // MAP_FAILED
        return 0 as *mut u8
    p

@[c_export("rt_munmap")]
pub fn rt_munmap_impl(ptr: *mut u8, size: i64):
    let _ = munmap(ptr, size as u64)

// ── Process ─────────────────────────────────────────────────────

@[c_export("rt_exit")]
pub fn rt_exit_impl(code: i32):
    _exit(code)

@[c_export("rt_args")]
pub fn rt_args_impl() -> (*const *const u8, i32):
    (rt_argv_raw as *const *const u8, rt_argc)

// ── Time ────────────────────────────────────────────────────────

var timebase_numer: i64 = 0
var timebase_denom: i64 = 0

@[c_export("rt_clock_ns")]
pub fn rt_clock_ns_impl() -> i64:
    if timebase_denom == 0:
        var info = MachTimebaseInfo { numer: 0, denom: 0 }
        let _ = mach_timebase_info(&mut info)
        timebase_numer = info.numer as i64
        timebase_denom = info.denom as i64
    let ticks = mach_absolute_time() as i64
    ticks * timebase_numer / timebase_denom

// ── Sleep ───────────────────────────────────────────────────────

type Timespec:
    tv_sec: i64
    tv_nsec: i64

extern fn nanosleep(req: *const Timespec, rem: *mut Timespec) -> i32

@[c_export("rt_nanosleep")]
pub fn rt_nanosleep_impl(ns: i64) -> i32:
    var req = Timespec { tv_sec: ns / 1000000000, tv_nsec: ns % 1000000000 }
    var rem = Timespec { tv_sec: 0, tv_nsec: 0 }
    var r: i32 = 0
    loop:
        r = nanosleep(&req, &mut rem)
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

@[c_export("rt_getpid")]
pub fn rt_getpid_impl() -> i32:
    getpid()

@[c_export("rt_raise")]
pub fn rt_raise_impl(sig: i32) -> i32:
    let r = raise(sig)
    if r < 0:
        return -get_errno()
    0

// ── Filesystem extras ───────────────────────────────────────────
// Beyond the core 13 rt_* functions — needed by std/fs.w

extern fn mkdir(path: *const u8, mode: u16) -> i32
extern fn unlink(path: *const u8) -> i32
extern fn rmdir(path: *const u8) -> i32
extern fn rename(old_path: *const u8, new_path: *const u8) -> i32
extern fn access(path: *const u8, mode: i32) -> i32

@[c_export("rt_mkdir")]
pub fn rt_mkdir_impl(path: *const u8, mode: i32) -> i32:
    var r: i32 = 0
    loop:
        r = mkdir(path, mode as u16)
        if r >= 0 or get_errno() != 4:
            break
    if r < 0:
        return -get_errno()
    0

@[c_export("rt_unlink")]
pub fn rt_unlink_impl(path: *const u8) -> i32:
    let r = unlink(path)
    if r < 0:
        return -get_errno()
    0

@[c_export("rt_rmdir")]
pub fn rt_rmdir_impl(path: *const u8) -> i32:
    let r = rmdir(path)
    if r < 0:
        return -get_errno()
    0

@[c_export("rt_rename")]
pub fn rt_rename_impl(old_path: *const u8, new_path: *const u8) -> i32:
    let r = rename(old_path, new_path)
    if r < 0:
        return -get_errno()
    0

@[c_export("rt_access")]
pub fn rt_access_impl(path: *const u8, mode: i32) -> i32:
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

@[c_export("rt_sysinfo")]
pub fn rt_sysinfo_impl(out: *mut RtSysInfo) -> i32:
    // CPU cores: sysctl hw.logicalcpu
    var cores: i32 = 0
    var cores_len: i64 = 4
    let _ = sysctlbyname("hw.logicalcpu" as *const u8, &cores as *mut u8, &mut cores_len, 0 as *const u8, 0)
    (*out).cpu_cores = if cores > 0: cores else: 1

    // Total memory: sysctl hw.memsize
    var memsize: i64 = 0
    var memsize_len: i64 = 8
    let _ = sysctlbyname("hw.memsize" as *const u8, &memsize as *mut u8, &mut memsize_len, 0 as *const u8, 0)
    (*out).memory_total = memsize

    // Page size: sysconf(_SC_PAGESIZE)
    let ps = sysconf(29)  // _SC_PAGESIZE = 29 on darwin
    (*out).page_size = ps
    0

// ── Environment ─────────────────────────────────────────────────

@[c_export("rt_getenv")]
pub fn rt_getenv_impl(name: *const u8) -> *const u8:
    getenv(name)
