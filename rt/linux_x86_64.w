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

pub fn rt_store_args(argc_val: i32, argv_val: *const *const u8) -> void:
    rt_argc = argc_val
    rt_argv_raw = argv_val as i64

fn rt_random_fail():
    let msg = "fatal: could not read OS randomness\n" as *const u8
    let _ = write(2, msg, 36)
    _exit(1)

pub fn rt_fill_random(buf: *mut u8, len: u64) -> void:
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

pub fn rt_fiber_reset_signal_handler(sig: i32) -> void:
    linux_zero_sigaction(sig)

pub fn rt_fiber_install_signal_handlers(alt_stack: *mut u8, alt_stack_size: i64, handler: i64) -> void:
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

pub fn rt_munmap(ptr: *mut u8, size: i64) -> void:
    let _ = munmap(ptr, size as u64)

pub fn rt_exit(code: i32) -> void:
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

fn rt_copy_file(src: *const u8, dst: *const u8, mode: i32) -> i32:
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
        return rt_copy_file(src, dst, mode)

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
    with_str_from_cstr(c"Linux".ptr)

pub fn rt_sysinfo_arch() -> str:
    with_str_from_cstr(c"x86_64".ptr)

pub fn rt_getenv(name: *const u8) -> *const u8:
    getenv(name)

// ---- Compiler compatibility process/env adapter ----

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> void
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> void
extern fn with_memset(dst: *mut u8, val: i32, len: i64) -> void
extern fn setenv(name: *const u8, value: *const u8, overwrite: i32) -> i32
extern fn sigprocmask(how: i32, set: *const u32, old: *mut u32) -> i32
extern fn fork() -> i32
extern fn setpgid(pid: i32, pgid: i32) -> i32
extern fn execv(path: *const u8, argv: *const *const u8) -> i32
extern fn execvp(file: *const u8, argv: *const *const u8) -> i32
extern fn waitpid(pid: i32, status: *mut i32, options: i32) -> i32
extern fn chdir(path: *const u8) -> i32
extern fn dup2(oldfd: i32, newfd: i32) -> i32
extern fn getrlimit(resource: i32, lim: *mut u8) -> i32
extern fn setrlimit(resource: i32, lim: *const u8) -> i32
extern fn with_clock_nanos() -> i64
extern fn with_usleep(usecs: i32) -> i32

let POSIX_SIGINT: i32 = 2
let POSIX_SIGQUIT: i32 = 3
let POSIX_SIGTERM: i32 = 15
let POSIX_SIGHUP: i32 = 1
let POSIX_SIG_BLOCK: i32 = 1
let POSIX_SIG_SETMASK: i32 = 3
let POSIX_RLIMIT_STACK: i32 = 3
let POSIX_RLIM_INFINITY: u64 = 9223372036854775807 as u64
let POSIX_EINTR: i32 = 4
let POSIX_SIGACTION_SIZE: i64 = 16
let POSIX_RLIMIT_SIZE: i64 = 16
let POSIX_WNOHANG: i32 = 1
let POSIX_CAPTURE_TIMEOUT_RC: i32 = 124

var posix_interrupt_flag: i32 = 0
var posix_active_child_pgid: i32 = 0

fn posix_store_i64(base: i64, offset: i64, value: i64):
    unsafe *((base + offset) as *mut i64) = value

fn posix_load_u64(base: i64, offset: i64) -> u64:
    unsafe *((base + offset) as *const u64)

fn posix_signal_bit(signo: i32) -> u32:
    if signo <= 0:
        return 0 as u32
    (1 as u32) << ((signo - 1) as u32)

fn posix_str_to_c_buf(s: str) -> *mut u8:
    let out = with_alloc(s.len() + 1)
    if out as i64 == 0:
        return 0 as *mut u8
    if s.len() > 0:
        let sp = &s as *const *const u8
        with_memcpy(out, unsafe *sp, s.len())
    unsafe *((out as i64 + s.len()) as *mut u8) = 0
    out

fn posix_restore_default_signal_handler(signo: i32):
    var sa: [16]u8 = [0 as u8; 16]
    let sa_base = (&raw mut sa) as *mut [16]u8 as i64
    with_memset(sa_base as *mut u8, 0, POSIX_SIGACTION_SIZE)
    let _ = sigaction(signo, sa_base as *const u8, 0 as *mut u8)

fn posix_block_interrupt_signals(prev_mask: *mut u32) -> i32:
    var blocked: u32 = 0 as u32
    blocked = blocked | posix_signal_bit(POSIX_SIGINT)
    blocked = blocked | posix_signal_bit(POSIX_SIGTERM)
    blocked = blocked | posix_signal_bit(POSIX_SIGHUP)
    sigprocmask(POSIX_SIG_BLOCK, &blocked as *const u32, prev_mask)

fn posix_restore_signal_mask(prev_mask: *const u32):
    if prev_mask as i64 != 0:
        let _ = sigprocmask(POSIX_SIG_SETMASK, prev_mask, 0 as *mut u32)

fn posix_wait_child(pid: i32, timeout_ms: i32) -> i32:
    var status: i32 = -1
    let start_ns = with_clock_nanos()
    let timeout_ns = timeout_ms as i64 * 1000000
    while true:
        let waited = if timeout_ms > 0: waitpid(pid, &raw mut status, POSIX_WNOHANG) else: waitpid(pid, &raw mut status, 0)
        if waited == pid:
            let termsig = status & 0x7f
            if termsig == 0:
                return (status >> 8) & 0xff
            if termsig != 0x7f:
                return 128 + termsig
            return status
        if waited < 0:
            if get_errno() == POSIX_EINTR:
                continue
            return -1
        if timeout_ms > 0 and with_clock_nanos() - start_ns >= timeout_ns:
            let _term = kill(-pid, POSIX_SIGTERM)
            let _sleep = with_usleep(10000)
            let waited_after_term = waitpid(pid, &raw mut status, POSIX_WNOHANG)
            if waited_after_term != pid:
                let _kill = kill(-pid, 9)
                let _wait = waitpid(pid, &raw mut status, 0)
            return POSIX_CAPTURE_TIMEOUT_RC
        if timeout_ms > 0:
            let _sleep_poll = with_usleep(10000)

fn posix_argv_blob_count(blob: *const u8, len: i64) -> i32:
    if len <= 0:
        return 0
    var count = 0
    var offset: i64 = 0
    while offset < len:
        count += 1
        while offset < len and (unsafe *((blob as i64 + offset) as *const u8)) != 0:
            offset += 1
        offset += 1
    count

fn posix_fill_argv(blob: *const u8, len: i64, argv: *mut *const u8) -> i32:
    var argi = 0
    var offset: i64 = 0
    while offset < len and argi < 255:
        unsafe *((argv as i64 + argi as i64 * 8) as *mut *const u8) = (blob as i64 + offset) as *const u8
        argi += 1
        while offset < len and (unsafe *((blob as i64 + offset) as *const u8)) != 0:
            offset += 1
        offset += 1
    unsafe *((argv as i64 + argi as i64 * 8) as *mut *const u8) = 0 as *const u8
    argi

fn posix_redirect_fd_to_path(path: *const u8, fd: i32) -> i32:
    let out_fd = rt_open(path, 1 | 0x200 | 0x400, 0o644)
    if out_fd < 0:
        return -1
    if dup2(out_fd, fd) < 0:
        let _ = rt_close(out_fd)
        return -1
    let _ = rt_close(out_fd)
    0

fn posix_redirect_fd_from_path(path: *const u8, fd: i32) -> i32:
    let in_fd = rt_open(path, 0, 0)
    if in_fd < 0:
        return -1
    if dup2(in_fd, fd) < 0:
        let _ = rt_close(in_fd)
        return -1
    let _ = rt_close(in_fd)
    0

fn posix_child_common(mask_rc: i32, prev_mask: *const u32):
    if mask_rc == 0:
        posix_restore_signal_mask(prev_mask)
    let _ = setpgid(0, 0)
    posix_restore_default_signal_handler(POSIX_SIGINT)
    posix_restore_default_signal_handler(POSIX_SIGTERM)
    posix_restore_default_signal_handler(POSIX_SIGHUP)
    posix_restore_default_signal_handler(POSIX_SIGQUIT)

fn posix_run_argv(blob: *const u8, len: i64, stdout_path: *const u8, stderr_path: *const u8, stdin_path: *const u8, cwd: *const u8, timeout_ms: i32, wait: bool) -> i32:
    let argc = posix_argv_blob_count(blob, len)
    if argc <= 0 or argc >= 256:
        return -1
    var prev_mask: u32 = 0 as u32
    let mask_rc = posix_block_interrupt_signals(&raw mut prev_mask)
    let pid = fork()
    if pid == 0:
        posix_child_common(mask_rc, &prev_mask as *const u32)
        if stdin_path as i64 != 0 and posix_redirect_fd_from_path(stdin_path, 0) != 0:
            _exit(127)
        if stdout_path as i64 != 0 and posix_redirect_fd_to_path(stdout_path, 1) != 0:
            _exit(127)
        if stderr_path as i64 != 0 and posix_redirect_fd_to_path(stderr_path, 2) != 0:
            _exit(127)
        if cwd as i64 != 0:
            if chdir(cwd) != 0:
                _exit(127)
            let _ = setenv(c"PWD".ptr, cwd, 1)
        var argv: [256]*const u8 = [0 as *const u8; 256]
        let _argc2 = posix_fill_argv(blob, len, (&raw mut argv) as *mut [256]*const u8 as *mut *const u8)
        let _ = execvp(argv[0], (&argv) as *const [256]*const u8 as *const *const u8)
        _exit(127)
    if pid < 0:
        if mask_rc == 0:
            posix_restore_signal_mask(&prev_mask as *const u32)
        return -1
    let _ = setpgid(pid, pid)
    if mask_rc == 0:
        posix_restore_signal_mask(&prev_mask as *const u32)
    if not wait:
        return pid
    posix_active_child_pgid = pid
    let rc = posix_wait_child(pid, timeout_ms)
    posix_active_child_pgid = 0
    rc

fn posix_interrupt_signal_handler(signo: i32):
    posix_interrupt_flag = 1
    if posix_active_child_pgid > 0:
        let _ = kill(-posix_active_child_pgid, signo)
    _exit(128 + signo)

fn posix_interrupted() -> bool:
    posix_interrupt_flag != 0

pub fn rt_compat_setenv_str(name: str, value: str) -> i32:
    let name_buf = posix_str_to_c_buf(name)
    if name_buf as i64 == 0:
        return -1
    let value_buf = posix_str_to_c_buf(value)
    if value_buf as i64 == 0:
        with_free(name_buf)
        return -1
    let rc = setenv(name_buf as *const u8, value_buf as *const u8, 1)
    with_free(name_buf)
    with_free(value_buf)
    rc

pub fn rt_compat_install_interrupt_handlers() -> void:
    var sa: [16]u8 = [0 as u8; 16]
    let sa_base = (&raw mut sa) as *mut [16]u8 as i64
    with_memset(sa_base as *mut u8, 0, POSIX_SIGACTION_SIZE)
    posix_store_i64(sa_base, 0, posix_interrupt_signal_handler as i64)
    let _ = sigaction(POSIX_SIGINT, sa_base as *const u8, 0 as *mut u8)
    let _ = sigaction(POSIX_SIGTERM, sa_base as *const u8, 0 as *mut u8)
    let _ = sigaction(POSIX_SIGHUP, sa_base as *const u8, 0 as *mut u8)

pub fn rt_compat_raise_stack_limit() -> void:
    var lim: [16]u8 = [0 as u8; 16]
    let lim_base = (&raw mut lim) as *mut [16]u8 as i64
    if getrlimit(POSIX_RLIMIT_STACK, lim_base as *mut u8) != 0:
        return
    var want: u64 = (8 * 1024 * 1024) as u64
    let lim_max = posix_load_u64(lim_base, 8)
    if lim_max != POSIX_RLIM_INFINITY and want > lim_max:
        want = lim_max
    let lim_cur = posix_load_u64(lim_base, 0)
    if want > lim_cur:
        posix_store_i64(lim_base, 0, want as i64)
        let _ = setrlimit(POSIX_RLIMIT_STACK, lim_base as *const u8)

pub fn rt_compat_interrupt_requested() -> i32:
    posix_interrupt_flag

pub fn rt_compat_exec_binary(path: str) -> i32:
    let buf = posix_str_to_c_buf(path)
    if buf as i64 == 0:
        return -1
    if posix_interrupted():
        with_free(buf)
        return -1
    var argv_blob = path
    let rc = posix_run_argv(buf as *const u8, argv_blob.len(), 0 as *const u8, 0 as *const u8, 0 as *const u8, 0 as *const u8, 0, true)
    with_free(buf)
    rc

pub fn rt_compat_exec_argv(args: str) -> i32:
    let buf = posix_str_to_c_buf(args)
    if buf as i64 == 0:
        return -1
    let rc = if posix_interrupted(): -1 else: posix_run_argv(buf as *const u8, args.len(), 0 as *const u8, 0 as *const u8, 0 as *const u8, 0 as *const u8, 0, true)
    with_free(buf)
    rc

pub fn rt_compat_exec_argv_cwd(args: str, cwd: str) -> i32:
    let arg_buf = posix_str_to_c_buf(args)
    let cwd_buf = posix_str_to_c_buf(cwd)
    if arg_buf as i64 == 0 or cwd_buf as i64 == 0:
        return -1
    let rc = if posix_interrupted(): -1 else: posix_run_argv(arg_buf as *const u8, args.len(), 0 as *const u8, 0 as *const u8, 0 as *const u8, cwd_buf as *const u8, 0, true)
    with_free(arg_buf)
    with_free(cwd_buf)
    rc

pub fn rt_compat_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32:
    rt_compat_exec_argv_capture_cwd(args, stdout_path, stderr_path, timeout_ms, "")

pub fn rt_compat_exec_argv_capture_input(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, stdin_path: str) -> i32:
    let arg_buf = posix_str_to_c_buf(args)
    let out_buf = posix_str_to_c_buf(stdout_path)
    let err_buf = posix_str_to_c_buf(stderr_path)
    let in_buf = posix_str_to_c_buf(stdin_path)
    if arg_buf as i64 == 0 or out_buf as i64 == 0 or err_buf as i64 == 0 or in_buf as i64 == 0:
        return -1
    let rc = if posix_interrupted(): -1 else: posix_run_argv(arg_buf as *const u8, args.len(), out_buf as *const u8, err_buf as *const u8, in_buf as *const u8, 0 as *const u8, timeout_ms, true)
    with_free(arg_buf)
    with_free(out_buf)
    with_free(err_buf)
    with_free(in_buf)
    rc

pub fn rt_compat_exec_argv_capture_cwd(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> i32:
    let arg_buf = posix_str_to_c_buf(args)
    let out_buf = posix_str_to_c_buf(stdout_path)
    let err_buf = posix_str_to_c_buf(stderr_path)
    let cwd_buf = if cwd.len() > 0: posix_str_to_c_buf(cwd) else: 0 as *mut u8
    if arg_buf as i64 == 0 or out_buf as i64 == 0 or err_buf as i64 == 0:
        return -1
    let rc = if posix_interrupted(): -1 else: posix_run_argv(arg_buf as *const u8, args.len(), out_buf as *const u8, err_buf as *const u8, 0 as *const u8, cwd_buf as *const u8, timeout_ms, true)
    with_free(arg_buf)
    with_free(out_buf)
    with_free(err_buf)
    if cwd_buf as i64 != 0:
        with_free(cwd_buf)
    rc

pub fn rt_compat_exec_argv_capture_spawn(args: str, stdout_path: str, stderr_path: str) -> i32:
    let arg_buf = posix_str_to_c_buf(args)
    let out_buf = posix_str_to_c_buf(stdout_path)
    let err_buf = posix_str_to_c_buf(stderr_path)
    if arg_buf as i64 == 0 or out_buf as i64 == 0 or err_buf as i64 == 0:
        return -1
    let rc = if posix_interrupted(): -1 else: posix_run_argv(arg_buf as *const u8, args.len(), out_buf as *const u8, err_buf as *const u8, 0 as *const u8, 0 as *const u8, 0, false)
    with_free(arg_buf)
    with_free(out_buf)
    with_free(err_buf)
    rc

pub fn rt_compat_exec_wait(pid: i32, timeout_ms: i32) -> i32:
    if pid <= 0:
        return -1
    posix_active_child_pgid = pid
    let rc = posix_wait_child(pid, timeout_ms)
    posix_active_child_pgid = 0
    rc
