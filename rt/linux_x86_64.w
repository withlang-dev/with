// rt/linux_x86_64.w -- Linux x86_64 runtime backend.
//
// Implements the rt_* platform boundary through stable libc/POSIX ABI symbols.
// Error convention: negative return = negated errno.

extern fn write(fd: i32, buf: *const u8, len: u64) -> i64
extern fn read(fd: i32, buf: *mut u8, len: u64) -> i64
extern fn open(path: *const u8, flags: i32, mode: i32) -> i32
extern fn close(fd: i32) -> i32
extern fn lseek(fd: i32, offset: i64, whence: i32) -> i64
extern fn getcwd(buf: *mut u8, size: u64) -> *mut u8
extern fn mmap(addr: *mut u8, len: u64, prot: i32, flags: i32, fd: i32, offset: i64) -> *mut u8
extern fn munmap(addr: *mut u8, len: u64) -> i32
extern fn getenv(name: *const u8) -> *const u8
extern fn stat(path: *const u8, buf: *mut u8) -> i32
extern fn chmod(path: *const u8, mode: i32) -> i32
extern fn _exit(code: i32) -> void
extern fn __errno_location() -> *mut i32
extern fn getrandom(buf: *mut u8, len: u64, flags: u32) -> i64
extern fn sysconf(name: i32) -> i64
extern fn sigaltstack(ss: *const u8, old_ss: *mut u8) -> i32
extern fn sigaction(sig: i32, act: *const u8, old_act: *mut u8) -> i32
extern var stdin: *mut u8
extern var stdout: *mut u8
extern var stderr: *mut u8

fn get_errno() -> i32:
    let p = __errno_location()
    unsafe *p

pub fn __error() -> *mut i32:
    __errno_location()

type RtStatBuf:
    size: i64
    is_dir: i32
    is_file: i32
    modified_ns: i64

var rt_argc: i32 = 0
var rt_argv_raw: i64 = 0

pub fn rt_store_args(argc_val: i32, argv_val: *const *const u8):
    rt_argc = argc_val
    rt_argv_raw = argv_val as i64

fn rt_random_fail():
    let msg = "fatal: could not read OS randomness\n" as *const u8
    let _ = write(2, msg, 36)
    _exit(1)

pub fn rt_fill_random(buf: *mut u8, len: u64):
    var off: u64 = 0
    while off < len:
        let p = (buf as i64 + off as i64) as *mut u8
        let n = getrandom(p, len - off, 0 as u32)
        if n > 0:
            off = off + n as u64
        else:
            if get_errno() == 4:
                continue
            break
    if off < len:
        let fd = open("/dev/urandom" as *const u8, 0, 0)
        if fd < 0:
            rt_random_fail()
        while off < len:
            let p = (buf as i64 + off as i64) as *mut u8
            let n = rt_read(fd, p, len - off)
            if n <= 0:
                let _close = rt_close(fd)
                rt_random_fail()
            off = off + n as u64
        let _close = rt_close(fd)

pub fn rt_libc_stdin() -> *mut u8:
    stdin

pub fn rt_libc_stdout() -> *mut u8:
    stdout

pub fn rt_libc_stderr() -> *mut u8:
    stderr

pub fn rt_fiber_page_size() -> i64:
    let page_size = sysconf(30)
    if page_size > 0:
        return page_size
    4096

pub fn rt_fiber_mmap_flags() -> i32:
    // Linux: MAP_PRIVATE | MAP_ANONYMOUS.
    0x22

pub fn rt_fiber_fault_addr(info: *const u8) -> i64:
    if info as i64 == 0:
        return 0
    unsafe:
        *((info as i64 + 16) as *const i64)

fn linux_store_i64(base: i64, offset: i64, value: i64):
    unsafe:
        *((base + offset) as *mut i64) = value

fn linux_store_i32(base: i64, offset: i64, value: i32):
    unsafe:
        *((base + offset) as *mut i32) = value

fn linux_zero_sigaction(sig: i32):
    var sa: [152]u8 = [0 as u8; 152]
    let sa_base = (&raw mut sa) as *mut [152]u8 as i64
    let _ = sigaction(sig, sa_base as *const u8, 0 as *mut u8)

pub fn rt_fiber_reset_signal_handler(sig: i32):
    linux_zero_sigaction(sig)

pub fn rt_fiber_install_signal_handlers(alt_stack: *mut u8, alt_stack_size: i64, handler: i64):
    var ss: [24]u8 = [0 as u8; 24]
    let ss_base = (&raw mut ss) as *mut [24]u8 as i64
    linux_store_i64(ss_base, 0, alt_stack as i64)
    linux_store_i32(ss_base, 8, 0)
    linux_store_i64(ss_base, 16, alt_stack_size)
    let _ = sigaltstack(ss_base as *const u8, 0 as *mut u8)

    var sa: [152]u8 = [0 as u8; 152]
    let sa_base = (&raw mut sa) as *mut [152]u8 as i64
    linux_store_i64(sa_base, 0, handler)
    linux_store_i32(sa_base, 136, 134217728 | 4)
    let _ = sigaction(11, sa_base as *const u8, 0 as *mut u8)
    let _ = sigaction(7, sa_base as *const u8, 0 as *mut u8)

pub fn __open(path: *const u8, flags: i32, mode: i32) -> i32:
    var native = flags & 3
    if (flags & 0x0008) != 0: native = native | 0x400
    if (flags & 0x0200) != 0: native = native | 0x40
    if (flags & 0x0400) != 0: native = native | 0x200
    if (flags & 0x0800) != 0: native = native | 0x80
    var r: i32 = 0
    loop:
        r = open(path, native, mode)
        if r >= 0 or get_errno() != 4:
            break
    r

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
    // Canonical: O_RDONLY=0, O_WRONLY=1, O_RDWR=2, O_CREAT=0x200,
    // O_TRUNC=0x400, O_APPEND=0x800.
    // Linux: O_CREAT=0x40, O_EXCL=0x80, O_TRUNC=0x200, O_APPEND=0x400.
    var native = flags & 3
    if (flags & 0x200) != 0: native = native | 0x40
    if (flags & 0x400) != 0: native = native | 0x200
    if (flags & 0x800) != 0: native = native | 0x400
    var r: i32 = 0
    loop:
        r = open(path, native, mode)
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

let S_IFMT: i32 = 61440
let S_IFDIR: i32 = 16384
let S_IFREG: i32 = 32768
let LINUX_STAT_SIZE: i64 = 144
let LINUX_STAT_MODE_OFFSET: i64 = 24
let LINUX_STAT_SIZE_OFFSET: i64 = 48
let LINUX_STAT_MTIME_SEC_OFFSET: i64 = 88
let LINUX_STAT_MTIME_NSEC_OFFSET: i64 = 96

pub fn rt_stat(path: *const u8, out: *mut RtStatBuf) -> i32:
    var native_buf: [144]u8 = [0 as u8; 144]
    let r = stat(path, &native_buf as *mut [144]u8 as *mut u8)
    if r < 0:
        return -get_errno()
    let base = &native_buf as i64
    let size = unsafe *((base + LINUX_STAT_SIZE_OFFSET) as *const i64)
    let mode = unsafe *((base + LINUX_STAT_MODE_OFFSET) as *const i32)
    let mtime_sec = unsafe *((base + LINUX_STAT_MTIME_SEC_OFFSET) as *const i64)
    let mtime_nsec = unsafe *((base + LINUX_STAT_MTIME_NSEC_OFFSET) as *const i64)
    (unsafe *out).size = size
    (unsafe *out).is_dir = if (mode & S_IFMT) == S_IFDIR: 1 else: 0
    (unsafe *out).is_file = if (mode & S_IFMT) == S_IFREG: 1 else: 0
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

pub fn rt_mmap(size: i64) -> *mut u8:
    let p = mmap(0 as *mut u8, size as u64, 3, 0x22, -1, 0)
    if p as i64 == -1:
        return 0 as *mut u8
    p

pub fn rt_munmap(ptr: *mut u8, size: i64):
    let _ = munmap(ptr, size as u64)

pub fn rt_exit(code: i32):
    _exit(code)

pub fn rt_args() -> (*const *const u8, i32):
    (rt_argv_raw as *const *const u8, rt_argc)

type Timespec:
    tv_sec: i64
    tv_nsec: i64

extern fn clock_gettime(clk_id: i32, tp: *mut Timespec) -> i32
extern fn nanosleep(req: *const Timespec, rem: *mut Timespec) -> i32

pub fn rt_clock_ns() -> i64:
    var ts = Timespec { tv_sec: 0, tv_nsec: 0 }
    if clock_gettime(1, &raw mut ts) != 0:
        return 0
    ts.tv_sec * 1000000000 + ts.tv_nsec

pub fn rt_nanosleep(ns: i64) -> i32:
    var req = Timespec { tv_sec: ns / 1000000000, tv_nsec: ns % 1000000000 }
    var rem = Timespec { tv_sec: 0, tv_nsec: 0 }
    var r: i32 = 0
    loop:
        r = nanosleep(&req, &raw mut rem)
        if r >= 0 or get_errno() != 4:
            break
        req = rem
    if r < 0:
        return -get_errno()
    0

extern fn getpid() -> i32
extern fn raise(sig: i32) -> i32
extern fn kill(pid: i32, sig: i32) -> i32
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
    let rc = pthread_create(&raw mut handle, 0 as *const u8, start_routine, arg)
    if rc != 0:
        return -(rc as i64)
    handle

pub fn rt_thread_join(handle: i64) -> i32:
    var retval: *mut u8 = 0 as *mut u8
    let rc = pthread_join(handle, &raw mut retval)
    if rc != 0:
        return -rc
    0

extern fn mkdir(path: *const u8, mode: i32) -> i32
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

let LINUX_DIRENT_NAME_OFFSET: i64 = 19
let RT_PATH_MAX: i64 = 4096

fn rt_cstr_len(s: *const u8) -> i64:
    if s as i64 == 0:
        return 0
    var len: i64 = 0
    while unsafe *((s as i64 + len) as *const u8) != 0:
        len = len + 1
    len

fn rt_dirent_name(ent: *mut u8) -> *const u8:
    (ent as i64 + LINUX_DIRENT_NAME_OFFSET) as *const u8

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
    unsafe *mode_out = unsafe *((&st as i64 + LINUX_STAT_MODE_OFFSET) as *const i32)
    0

fn rt_lstat_is_dir(path: *const u8) -> bool:
    var mode: i32 = 0
    if rt_lstat_mode(path, &mode as *mut i32) != 0:
        return false
    (mode & S_IFMT) == S_IFDIR

pub fn rt_mkdir(path: *const u8, mode: i32) -> i32:
    var r: i32 = 0
    loop:
        r = mkdir(path, mode)
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
    with_str_concat(with_str_concat(out, with_str_from_cstr(path)), rt_newline_str())

fn rt_list_files_walk(path: *const u8, out: str) -> str:
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

type RtSysInfo:
    cpu_cores: i32
    memory_total: i64
    page_size: i64

pub fn rt_sysinfo(out: *mut RtSysInfo) -> i32:
    let page_size = sysconf(30)
    let pages = sysconf(85)
    let cores = sysconf(84)
    (unsafe *out).cpu_cores = if cores > 0: cores as i32 else: 1
    (unsafe *out).page_size = if page_size > 0: page_size else: 4096
    (unsafe *out).memory_total = if pages > 0 and page_size > 0: pages * page_size else: 0
    0

pub fn rt_sysinfo_os() -> str:
    with_str_from_cstr("Linux" as *const u8)

pub fn rt_sysinfo_arch() -> str:
    with_str_from_cstr("x86_64" as *const u8)

pub fn rt_getenv(name: *const u8) -> *const u8:
    getenv(name)
