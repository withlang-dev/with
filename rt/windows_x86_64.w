// rt/windows_x86_64.w -- Windows x86_64 runtime backend.

extern fn GetLastError() -> i32
extern fn GetStdHandle(kind: i32) -> i64
extern fn ReadFile(handle: i64, buf: *mut u8, len: u32, read_out: *mut u32, overlapped: *mut u8) -> i32
extern fn WriteFile(handle: i64, buf: *const u8, len: u32, written_out: *mut u32, overlapped: *mut u8) -> i32
extern fn CreateFileW(path: *const u16, access: u32, share: u32, security: *mut u8, creation: u32, flags: u32, template_file: i64) -> i64
extern fn CloseHandle(handle: i64) -> i32
extern fn SetFilePointerEx(handle: i64, distance: i64, new_pos: *mut i64, method: u32) -> i32
extern fn GetCurrentDirectoryW(size: u32, buf: *mut u16) -> u32
extern fn SetCurrentDirectoryW(path: *const u16) -> i32
extern fn VirtualAlloc(addr: *mut u8, size: u64, alloc_type: u32, protect: u32) -> *mut u8
extern fn VirtualFree(addr: *mut u8, size: u64, free_type: u32) -> i32
extern fn ExitProcess(code: i32) -> Unit
extern fn QueryPerformanceCounter(value: *mut i64) -> i32
extern fn QueryPerformanceFrequency(value: *mut i64) -> i32
extern fn GetSystemTimeAsFileTime(filetime: *mut i64) -> Unit
extern fn Sleep(ms: u32) -> Unit
extern fn GetCurrentProcessId() -> i32
extern fn OpenProcess(access: u32, inherit: i32, pid: i32) -> i64
extern fn TerminateProcess(handle: i64, code: u32) -> i32
extern fn CreateThread(attrs: *mut u8, stack_size: u64, start: *mut u8, arg: *mut u8, flags: u32, tid: *mut u32) -> i64
extern fn WaitForSingleObject(handle: i64, ms: u32) -> u32
extern fn GetExitCodeProcess(handle: i64, code: *mut u32) -> i32
extern fn CreateProcessW(app: *const u16, cmd: *mut u16, proc_attrs: *mut u8, thread_attrs: *mut u8, inherit_handles: i32, flags: u32, env: *mut u8, cwd: *const u16, startup: *mut u8, proc_info: *mut u8) -> i32
extern fn GetEnvironmentVariableW(name: *const u16, buf: *mut u16, size: u32) -> u32
extern fn SetEnvironmentVariableW(name: *const u16, value: *const u16) -> i32
extern fn GetFileAttributesW(path: *const u16) -> u32
extern fn SetFileAttributesW(path: *const u16, attrs: u32) -> i32
extern fn GetFileAttributesExW(path: *const u16, info_level: i32, out: *mut u8) -> i32
extern fn CreateDirectoryW(path: *const u16, security: *mut u8) -> i32
extern fn DeleteFileW(path: *const u16) -> i32
extern fn RemoveDirectoryW(path: *const u16) -> i32
extern fn MoveFileExW(old_path: *const u16, new_path: *const u16, flags: u32) -> i32
extern fn FindFirstFileW(pattern: *const u16, data: *mut u8) -> i64
extern fn FindNextFileW(handle: i64, data: *mut u8) -> i32
extern fn FindClose(handle: i64) -> i32
extern fn CreateSymbolicLinkW(link_path: *const u16, target: *const u16, flags: u32) -> i8
extern fn GetSystemInfo(info: *mut u8) -> Unit
extern fn GlobalMemoryStatusEx(info: *mut u8) -> i32
extern fn GetComputerNameW(buf: *mut u16, size: *mut u32) -> i32
extern fn SystemFunction036(buf: *mut u8, len: u32) -> i32
extern fn GetCurrentThreadId() -> u32
extern fn GetTempPathA(size: u32, buf: *mut u8) -> u32
extern fn GetTempFileNameA(path: *const u8, prefix: *const u8, unique: u32, buf: *mut u8) -> u32
extern fn GetFullPathNameA(path: *const u8, size: u32, buf: *mut u8, file_part: *mut *mut u8) -> u32
extern fn with_str_from_cstr(s: *const u8) -> str
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> Unit

let INVALID_HANDLE_VALUE: i64 = -1
let STD_INPUT_HANDLE: i32 = -10
let STD_OUTPUT_HANDLE: i32 = -11
let STD_ERROR_HANDLE: i32 = -12
let GENERIC_READ: u32 = 0x80000000 as u32
let GENERIC_WRITE: u32 = 0x40000000 as u32
let FILE_SHARE_ALL: u32 = 7 as u32
let CREATE_ALWAYS: u32 = 2 as u32
let OPEN_EXISTING: u32 = 3 as u32
let OPEN_ALWAYS: u32 = 4 as u32
let FILE_ATTRIBUTE_READONLY: u32 = 1 as u32
let FILE_ATTRIBUTE_DIRECTORY: u32 = 16 as u32
let FILE_ATTRIBUTE_NORMAL: u32 = 128 as u32
let FILE_FLAG_BACKUP_SEMANTICS: u32 = 0x02000000 as u32
let MEM_COMMIT_RESERVE: u32 = 0x3000 as u32
let MEM_RELEASE: u32 = 0x8000 as u32
let PAGE_READWRITE: u32 = 4 as u32
let WAIT_OBJECT_0: u32 = 0 as u32
let WAIT_TIMEOUT: u32 = 258 as u32
let INFINITE: u32 = 0xffffffff as u32
let PROCESS_TERMINATE: u32 = 1 as u32
let PROCESS_QUERY_LIMITED_INFORMATION: u32 = 0x1000 as u32
let SYNCHRONIZE: u32 = 0x00100000 as u32
let MOVEFILE_REPLACE_EXISTING: u32 = 1 as u32
let CAPTURE_TIMEOUT_RC: i32 = 124

type RtStatBuf:
    size: i64
    is_dir: i32
    is_file: i32
    modified_ns: i64

type RtSysInfo:
    cpu_cores: i32
    memory_total: i64
    page_size: i64

var rt_argc: i32 = 0
var rt_argv_raw: i64 = 0
var rt_handles: [256]i64 = [0 as i64; 256]
var qpc_freq: i64 = 0
var process_handles: [256]i64 = [0 as i64; 256]
var process_ids: [256]i32 = [0 as i32; 256]
var process_next_slot: i32 = 1

fn win_error() -> i32:
    let err = GetLastError()
    if err == 0: 1 else: err

fn win_neg_error() -> i32:
    -win_error()

fn win_strlen16(s: *const u16) -> i64:
    var len: i64 = 0
    while unsafe *((s as i64 + len * 2) as *const u16) != 0:
        len = len + 1
    len

fn win_cstr_len(s: *const u8) -> i64:
    if s as i64 == 0:
        return 0
    var len: i64 = 0
    while unsafe *((s as i64 + len) as *const u8) != 0:
        len = len + 1
    len

fn win_utf8_to_utf16_buf(src: *const u8, dst: *mut u16, cap: i64) -> i32:
    if src as i64 == 0 or cap <= 0:
        return -1
    var i: i64 = 0
    while i < cap - 1:
        let ch = unsafe *((src as i64 + i) as *const u8)
        if ch == 0:
            break
        unsafe *((dst as i64 + i * 2) as *mut u16) = ch as u16
        i = i + 1
    unsafe *((dst as i64 + i * 2) as *mut u16) = 0 as u16
    0

fn win_str_data(s: &str) -> *const u8:
    unsafe **(&s as *const *const *const u8)

fn win_str_to_utf16_buf(src: &str, dst: *mut u16, cap: i64) -> i32:
    if cap <= 0:
        return -1
    let data = win_str_data(src)
    var i: i64 = 0
    while i < src.len() and i < cap - 1:
        unsafe *((dst as i64 + i * 2) as *mut u16) = (unsafe *((data as i64 + i) as *const u8)) as u16
        i = i + 1
    unsafe *((dst as i64 + i * 2) as *mut u16) = 0 as u16
    0

fn win_utf16_to_utf8_buf(src: *const u16, dst: *mut u8, cap: i64) -> i32:
    var i: i64 = 0
    while i < cap - 1:
        let ch = unsafe *((src as i64 + i * 2) as *const u16)
        if ch == 0:
            break
        unsafe *((dst as i64 + i) as *mut u8) = if ch < 128: ch as u8 else: 63 as u8
        i = i + 1
    unsafe *((dst as i64 + i) as *mut u8) = 0
    i as i32

fn win_handle_for_fd(fd: i32) -> i64:
    if fd == 0:
        return GetStdHandle(STD_INPUT_HANDLE)
    if fd == 1:
        return GetStdHandle(STD_OUTPUT_HANDLE)
    if fd == 2:
        return GetStdHandle(STD_ERROR_HANDLE)
    if fd < 0 or fd >= 256:
        return 0
    rt_handles[fd]

fn win_alloc_fd(handle: i64) -> i32:
    if handle == 0 or handle == INVALID_HANDLE_VALUE:
        return win_neg_error()
    for i in 3..256:
        if rt_handles[i] == 0:
            rt_handles[i] = handle
            return i
    let _ = CloseHandle(handle)
    -24

pub fn rt_store_args(argc_val: i32, argv_val: *const *const u8) -> Unit:
    rt_argc = argc_val
    rt_argv_raw = argv_val as i64

pub fn rt_args() -> (*const *const u8, i32):
    (rt_argv_raw as *const *const u8, rt_argc)

pub fn rt_write(fd: i32, buf: *const u8, len: i64) -> i64:
    let handle = win_handle_for_fd(fd)
    if handle == 0 or handle == INVALID_HANDLE_VALUE:
        return -6
    var written: u32 = 0 as u32
    if WriteFile(handle, buf, len as u32, &raw mut written, 0 as *mut u8) == 0:
        return -(win_error() as i64)
    written as i64

pub fn rt_read(fd: i32, buf: *mut u8, len: i64) -> i64:
    let handle = win_handle_for_fd(fd)
    if handle == 0 or handle == INVALID_HANDLE_VALUE:
        return -6
    var got: u32 = 0 as u32
    if ReadFile(handle, buf, len as u32, &raw mut got, 0 as *mut u8) == 0:
        return -(win_error() as i64)
    got as i64

pub fn rt_open(path: *const u8, flags: i32, mode: i32) -> i32:
    let _ = mode
    var wpath: [4096]u16 = [0 as u16; 4096]
    if win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096) != 0:
        return -1
    let access = if (flags & 3) == 0: GENERIC_READ else if (flags & 3) == 1: GENERIC_WRITE else: GENERIC_READ | GENERIC_WRITE
    let creation = if (flags & 0x200) != 0:
        if (flags & 0x400) != 0: CREATE_ALWAYS else: OPEN_ALWAYS
    else:
        OPEN_EXISTING
    let h = CreateFileW(&wpath as *const [4096]u16 as *const u16, access, FILE_SHARE_ALL, 0 as *mut u8, creation, FILE_ATTRIBUTE_NORMAL, 0)
    win_alloc_fd(h)

pub fn rt_close(fd: i32) -> i32:
    if fd >= 0 and fd <= 2:
        return 0
    if fd < 0 or fd >= 256:
        return -6
    let h = rt_handles[fd]
    rt_handles[fd] = 0
    if h == 0:
        return -6
    if CloseHandle(h) == 0:
        return win_neg_error()
    0

pub fn rt_seek(fd: i32, offset: i64, whence: i32) -> i64:
    let h = win_handle_for_fd(fd)
    if h == 0 or h == INVALID_HANDLE_VALUE:
        return -6
    var pos: i64 = 0
    if SetFilePointerEx(h, offset, &raw mut pos, whence as u32) == 0:
        return -(win_error() as i64)
    pos

fn win_filetime_to_ns(low: u32, high: u32) -> i64:
    let ticks = ((high as u64) << 32) | low as u64
    let unix_100ns = ticks - 116444736000000000 as u64
    (unix_100ns * 100) as i64

pub fn rt_stat(path: *const u8, out_raw: *mut u8) -> i32:
    let out = out_raw as *mut RtStatBuf
    var wpath: [4096]u16 = [0 as u16; 4096]
    if win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096) != 0:
        return -1
    var info: [64]u8 = [0 as u8; 64]
    if GetFileAttributesExW(&wpath as *const [4096]u16 as *const u16, 0, &raw mut info as *mut [64]u8 as *mut u8) == 0:
        return win_neg_error()
    let base = &info as i64
    let attrs = unsafe *(base as *const u32)
    let write_low = unsafe *((base + 20) as *const u32)
    let write_high = unsafe *((base + 24) as *const u32)
    let size_high = unsafe *((base + 28) as *const u32)
    let size_low = unsafe *((base + 32) as *const u32)
    (unsafe *out).size = (((size_high as u64) << 32) | size_low as u64) as i64
    (unsafe *out).is_dir = if (attrs & FILE_ATTRIBUTE_DIRECTORY) != 0: 1 else: 0
    (unsafe *out).is_file = if (attrs & FILE_ATTRIBUTE_DIRECTORY) == 0: 1 else: 0
    (unsafe *out).modified_ns = win_filetime_to_ns(write_low, write_high)
    0

pub fn rt_file_mode(path: *const u8) -> i32:
    var wpath: [4096]u16 = [0 as u16; 4096]
    if win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096) != 0:
        return -1
    let attrs = GetFileAttributesW(&wpath as *const [4096]u16 as *const u16)
    if attrs == 0xffffffff as u32:
        return win_neg_error()
    if (attrs & FILE_ATTRIBUTE_DIRECTORY) != 0:
        return 0o040755
    0o100644

pub fn rt_chmod(path: *const u8, mode: i32) -> i32:
    var wpath: [4096]u16 = [0 as u16; 4096]
    if win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096) != 0:
        return -1
    var attrs = GetFileAttributesW(&wpath as *const [4096]u16 as *const u16)
    if attrs == 0xffffffff as u32:
        return win_neg_error()
    if (mode & 0o200) != 0:
        attrs = attrs & ~FILE_ATTRIBUTE_READONLY
    else:
        attrs = attrs | FILE_ATTRIBUTE_READONLY
    if SetFileAttributesW(&wpath as *const [4096]u16 as *const u16, attrs) == 0:
        return win_neg_error()
    0

pub fn rt_getcwd(buf: *mut u8, size: i64) -> i32:
    var wbuf: [4096]u16 = [0 as u16; 4096]
    let n = GetCurrentDirectoryW(4096 as u32, &raw mut wbuf as *mut [4096]u16 as *mut u16)
    if n == 0:
        return win_neg_error()
    let _ = win_utf16_to_utf8_buf(&wbuf as *const [4096]u16 as *const u16, buf, size)
    0

pub fn rt_mmap(size: i64) -> *mut u8:
    VirtualAlloc(0 as *mut u8, size as u64, MEM_COMMIT_RESERVE, PAGE_READWRITE)

pub fn rt_munmap(ptr: *mut u8, size: i64) -> Unit:
    let _ = size
    let _free = VirtualFree(ptr, 0, MEM_RELEASE)

pub fn rt_exit(code: i32) -> Unit:
    ExitProcess(code)

pub fn rt_clock_ns() -> i64:
    if qpc_freq == 0:
        let _ = QueryPerformanceFrequency(&raw mut qpc_freq)
    var now: i64 = 0
    let _ = QueryPerformanceCounter(&raw mut now)
    if qpc_freq <= 0:
        return 0
    let seconds = now / qpc_freq
    let remainder = now % qpc_freq
    seconds * 1000000000 + (remainder * 1000000000) / qpc_freq

pub fn rt_wall_clock_sec() -> i64:
    // FILETIME: 100ns intervals since 1601-01-01; rebase to the Unix epoch.
    var ft: i64 = 0
    GetSystemTimeAsFileTime(&raw mut ft)
    (ft - 116444736000000000) / 10000000

pub fn rt_nanosleep(ns: i64) -> i32:
    let ms = if ns <= 0: 0 else: ((ns + 999999) / 1000000) as u32
    Sleep(ms)
    0

pub fn rt_getpid() -> i32:
    GetCurrentProcessId()

pub fn rt_kill(pid: i32, sig: i32) -> i32:
    let access = SYNCHRONIZE | PROCESS_QUERY_LIMITED_INFORMATION | PROCESS_TERMINATE
    let h = OpenProcess(access, 0, pid)
    if h == 0:
        return win_neg_error()
    if sig != 0:
        let _ = TerminateProcess(h, (128 + sig) as u32)
    let _close = CloseHandle(h)
    0

pub fn rt_raise(sig: i32) -> i32:
    ExitProcess(128 + sig)
    0

pub fn rt_thread_spawn(start_routine: *mut u8, arg: *mut u8) -> i64:
    var tid: u32 = 0 as u32
    let h = CreateThread(0 as *mut u8, 0, start_routine, arg, 0, &raw mut tid)
    if h == 0:
        return -(win_error() as i64)
    h

pub fn rt_thread_join(handle: i64) -> i32:
    let r = WaitForSingleObject(handle, INFINITE)
    let _ = CloseHandle(handle)
    if r != WAIT_OBJECT_0:
        return win_neg_error()
    0

pub fn rt_fill_random(buf: *mut u8, len: u64) -> Unit:
    if SystemFunction036(buf, len as u32) == 0:
        ExitProcess(1)

pub fn rt_libc_stdin() -> *mut u8:
    0 as *mut u8

pub fn rt_libc_stdout() -> *mut u8:
    0 as *mut u8

pub fn rt_libc_stderr() -> *mut u8:
    0 as *mut u8

pub fn rt_fiber_page_size() -> i64:
    4096

pub fn rt_fiber_mmap_flags() -> i32:
    0

pub fn rt_fiber_fault_addr(info: *const u8) -> i64:
    let _ = info
    0

pub fn rt_fiber_reset_signal_handler(sig: i32) -> Unit:
    let _ = sig

pub fn rt_fiber_install_signal_handlers(alt_stack: *mut u8, alt_stack_size: i64, handler: i64) -> Unit:
    let _ = alt_stack
    let _ = alt_stack_size
    let _ = handler

fn win_path_join(parent: *const u8, name: *const u8, out: *mut u8, cap: i64) -> i32:
    let parent_len = win_cstr_len(parent)
    let name_len = win_cstr_len(name)
    var need_slash = true
    if parent_len > 0:
        let last = unsafe *((parent as i64 + parent_len - 1) as *const u8)
        if last == 47 or last == 92:
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

fn win_is_dot_or_dotdot(name: *const u8) -> bool:
    let first = unsafe *((name as i64) as *const u8)
    if first != 46:
        return false
    let second = unsafe *((name as i64 + 1) as *const u8)
    if second == 0:
        return true
    if second != 46:
        return false
    (unsafe *((name as i64 + 2) as *const u8)) == 0

fn win_find_name(data: *mut u8, out: *mut u8, cap: i64) -> i32:
    let name_w = (data as i64 + 44) as *const u16
    win_utf16_to_utf8_buf(name_w, out, cap)

fn win_is_dir(path: *const u8) -> bool:
    var wpath: [4096]u16 = [0 as u16; 4096]
    if win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096) != 0:
        return false
    let attrs = GetFileAttributesW(&wpath as *const [4096]u16 as *const u16)
    attrs != 0xffffffff as u32 and (attrs & FILE_ATTRIBUTE_DIRECTORY) != 0

pub fn rt_mkdir(path: *const u8, mode: i32) -> i32:
    let _ = mode
    var wpath: [4096]u16 = [0 as u16; 4096]
    if win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096) != 0:
        return -1
    if CreateDirectoryW(&wpath as *const [4096]u16 as *const u16, 0 as *mut u8) == 0:
        return win_neg_error()
    0

pub fn rt_unlink(path: *const u8) -> i32:
    var wpath: [4096]u16 = [0 as u16; 4096]
    if win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096) != 0:
        return -1
    if DeleteFileW(&wpath as *const [4096]u16 as *const u16) == 0:
        return win_neg_error()
    0

pub fn rt_rmdir(path: *const u8) -> i32:
    var wpath: [4096]u16 = [0 as u16; 4096]
    if win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096) != 0:
        return -1
    if RemoveDirectoryW(&wpath as *const [4096]u16 as *const u16) == 0:
        return win_neg_error()
    0

pub fn rt_rename(old_path: *const u8, new_path: *const u8) -> i32:
    var oldw: [4096]u16 = [0 as u16; 4096]
    var neww: [4096]u16 = [0 as u16; 4096]
    if win_utf8_to_utf16_buf(old_path, &raw mut oldw as *mut [4096]u16 as *mut u16, 4096) != 0:
        return -1
    if win_utf8_to_utf16_buf(new_path, &raw mut neww as *mut [4096]u16 as *mut u16, 4096) != 0:
        return -1
    if MoveFileExW(&oldw as *const [4096]u16 as *const u16, &neww as *const [4096]u16 as *const u16, MOVEFILE_REPLACE_EXISTING) == 0:
        return win_neg_error()
    0

fn win_remove_tree_impl(path: *const u8) -> i32:
    if not win_is_dir(path):
        return rt_unlink(path)
    var pattern8: [4096]u8 = [0 as u8; 4096]
    let join_rc = win_path_join(path, "*" as *const u8, &raw mut pattern8 as *mut [4096]u8 as *mut u8, 4096)
    if join_rc != 0:
        return join_rc
    var pattern: [4096]u16 = [0 as u16; 4096]
    let _ = win_utf8_to_utf16_buf(&pattern8 as *const [4096]u8 as *const u8, &raw mut pattern as *mut [4096]u16 as *mut u16, 4096)
    var data: [600]u8 = [0 as u8; 600]
    let h = FindFirstFileW(&pattern as *const [4096]u16 as *const u16, &raw mut data as *mut [600]u8 as *mut u8)
    if h != INVALID_HANDLE_VALUE:
        while true:
            var name: [512]u8 = [0 as u8; 512]
            let _name_len = win_find_name(&raw mut data as *mut [600]u8 as *mut u8, &raw mut name as *mut [512]u8 as *mut u8, 512)
            if not win_is_dot_or_dotdot(&name as *const [512]u8 as *const u8):
                var child: [4096]u8 = [0 as u8; 4096]
                let child_join = win_path_join(path, &name as *const [512]u8 as *const u8, &raw mut child as *mut [4096]u8 as *mut u8, 4096)
                if child_join == 0:
                    let rc = win_remove_tree_impl(&child as *const [4096]u8 as *const u8)
                    if rc != 0:
                        let _close = FindClose(h)
                        return rc
            if FindNextFileW(h, &raw mut data as *mut [600]u8 as *mut u8) == 0:
                break
        let _close = FindClose(h)
    rt_rmdir(path)

pub fn rt_remove_tree(path: *const u8) -> i32:
    win_remove_tree_impl(path)

fn win_copy_file(src: *const u8, dst: *const u8) -> i32:
    let in_fd = rt_open(src, 0, 0)
    if in_fd < 0:
        return in_fd
    let out_fd = rt_open(dst, 1 | 0x200 | 0x400, 0o644)
    if out_fd < 0:
        let _ = rt_close(in_fd)
        return out_fd
    let buf = with_alloc(65536)
    if buf as i64 == 0:
        let _ = rt_close(in_fd)
        let _ = rt_close(out_fd)
        return -12
    while true:
        let n = rt_read(in_fd, buf, 65536)
        if n < 0:
            with_free(buf)
            let _ = rt_close(in_fd)
            let _ = rt_close(out_fd)
            return n as i32
        if n == 0:
            break
        var off: i64 = 0
        while off < n:
            let w = rt_write(out_fd, (buf as i64 + off) as *const u8, n - off)
            if w <= 0:
                with_free(buf)
                let _ = rt_close(in_fd)
                let _ = rt_close(out_fd)
                return if w < 0: w as i32 else: -5
            off = off + w
    with_free(buf)
    let cin = rt_close(in_fd)
    let cout = rt_close(out_fd)
    if cin != 0: cin else: cout

pub fn rt_copy_tree(src: *const u8, dst: *const u8) -> i32:
    if not win_is_dir(src):
        return win_copy_file(src, dst)
    let mkdir_rc = rt_mkdir(dst, 0o755)
    if mkdir_rc != 0 and not win_is_dir(dst):
        return mkdir_rc
    var pattern8: [4096]u8 = [0 as u8; 4096]
    if win_path_join(src, "*" as *const u8, &raw mut pattern8 as *mut [4096]u8 as *mut u8, 4096) != 0:
        return -36
    var pattern: [4096]u16 = [0 as u16; 4096]
    let _ = win_utf8_to_utf16_buf(&pattern8 as *const [4096]u8 as *const u8, &raw mut pattern as *mut [4096]u16 as *mut u16, 4096)
    var data: [600]u8 = [0 as u8; 600]
    let h = FindFirstFileW(&pattern as *const [4096]u16 as *const u16, &raw mut data as *mut [600]u8 as *mut u8)
    if h == INVALID_HANDLE_VALUE:
        return 0
    while true:
        var name: [512]u8 = [0 as u8; 512]
        let _name_len = win_find_name(&raw mut data as *mut [600]u8 as *mut u8, &raw mut name as *mut [512]u8 as *mut u8, 512)
        if not win_is_dot_or_dotdot(&name as *const [512]u8 as *const u8):
            var child_src: [4096]u8 = [0 as u8; 4096]
            var child_dst: [4096]u8 = [0 as u8; 4096]
            let sj = win_path_join(src, &name as *const [512]u8 as *const u8, &raw mut child_src as *mut [4096]u8 as *mut u8, 4096)
            let dj = win_path_join(dst, &name as *const [512]u8 as *const u8, &raw mut child_dst as *mut [4096]u8 as *mut u8, 4096)
            if sj == 0 and dj == 0:
                let rc = rt_copy_tree(&child_src as *const [4096]u8 as *const u8, &child_dst as *const [4096]u8 as *const u8)
                if rc != 0:
                    let _close = FindClose(h)
                    return rc
        if FindNextFileW(h, &raw mut data as *mut [600]u8 as *mut u8) == 0:
            break
    let _close2 = FindClose(h)
    0

pub fn rt_symlink(target: *const u8, link_path: *const u8) -> i32:
    var targetw: [4096]u16 = [0 as u16; 4096]
    var linkw: [4096]u16 = [0 as u16; 4096]
    let _ = win_utf8_to_utf16_buf(target, &raw mut targetw as *mut [4096]u16 as *mut u16, 4096)
    let _ = win_utf8_to_utf16_buf(link_path, &raw mut linkw as *mut [4096]u16 as *mut u16, 4096)
    let flags = if win_is_dir(target): 1 as u32 else: 0 as u32
    if CreateSymbolicLinkW(&linkw as *const [4096]u16 as *const u16, &targetw as *const [4096]u16 as *const u16, flags | (2 as u32)) == 0:
        return win_neg_error()
    0

pub fn rt_readlink(path: *const u8) -> str:
    let _ = path
    win_empty_str()

fn win_empty_str() -> str:
    with_str_from_cstr(c"".ptr)

fn win_list_append(out: str, path: *const u8) -> str:
    let path_text = with_str_from_cstr(path)
    out ++ path_text ++ "\n"

fn win_list_files_walk(path: *const u8, out: str) -> str:
    if not win_is_dir(path):
        return win_list_append(out, path)
    var result = out
    var pattern8: [4096]u8 = [0 as u8; 4096]
    if win_path_join(path, "*" as *const u8, &raw mut pattern8 as *mut [4096]u8 as *mut u8, 4096) != 0:
        return result
    var pattern: [4096]u16 = [0 as u16; 4096]
    let _ = win_utf8_to_utf16_buf(&pattern8 as *const [4096]u8 as *const u8, &raw mut pattern as *mut [4096]u16 as *mut u16, 4096)
    var data: [600]u8 = [0 as u8; 600]
    let h = FindFirstFileW(&pattern as *const [4096]u16 as *const u16, &raw mut data as *mut [600]u8 as *mut u8)
    if h == INVALID_HANDLE_VALUE:
        return result
    while true:
        var name: [512]u8 = [0 as u8; 512]
        let _name_len = win_find_name(&raw mut data as *mut [600]u8 as *mut u8, &raw mut name as *mut [512]u8 as *mut u8, 512)
        if not win_is_dot_or_dotdot(&name as *const [512]u8 as *const u8):
            var child: [4096]u8 = [0 as u8; 4096]
            if win_path_join(path, &name as *const [512]u8 as *const u8, &raw mut child as *mut [4096]u8 as *mut u8, 4096) == 0:
                result = win_list_files_walk(&child as *const [4096]u8 as *const u8, result)
        if FindNextFileW(h, &raw mut data as *mut [600]u8 as *mut u8) == 0:
            break
    let _close = FindClose(h)
    result

pub fn rt_list_files(path: *const u8) -> str:
    win_list_files_walk(path, win_empty_str())

pub fn rt_access(path: *const u8, mode: i32) -> i32:
    let _ = mode
    var wpath: [4096]u16 = [0 as u16; 4096]
    if win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096) != 0:
        return -1
    let attrs = GetFileAttributesW(&wpath as *const [4096]u16 as *const u16)
    if attrs == 0xffffffff as u32:
        return win_neg_error()
    0

pub fn rt_sysinfo(out_raw: *mut u8) -> i32:
    let out = out_raw as *mut RtSysInfo
    var info: [64]u8 = [0 as u8; 64]
    GetSystemInfo(&raw mut info as *mut [64]u8 as *mut u8)
    // SYSTEM_INFO (x64): dwPageSize @4, dwNumberOfProcessors @32.
    // (@8 is lpMinimumApplicationAddress, @36 is the obsolete dwProcessorType
    // which reads ~8664 on x64 — reading it as the core count oversubscribed
    // the build worker pool 16-wide on small runners.)
    let page_size = unsafe *((&info as i64 + 4) as *const u32)
    let processors = unsafe *((&info as i64 + 32) as *const u32)
    var mem: [64]u8 = [0 as u8; 64]
    unsafe *((&raw mut mem) as *mut [64]u8 as *mut u32) = 64 as u32
    var total: i64 = 0
    if GlobalMemoryStatusEx(&raw mut mem as *mut [64]u8 as *mut u8) != 0:
        total = unsafe *((&mem as i64 + 8) as *const u64) as i64
    (unsafe *out).cpu_cores = if processors > 0: processors as i32 else: 1
    (unsafe *out).page_size = if page_size > 0: page_size as i64 else: 4096
    (unsafe *out).memory_total = total
    0

pub fn rt_sysinfo_os() -> str:
    with_str_from_cstr(c"Windows".ptr)

pub fn rt_sysinfo_arch() -> str:
    with_str_from_cstr(c"x86_64".ptr)

pub fn rt_getenv(name: *const u8) -> *const u8:
    var wname: [1024]u16 = [0 as u16; 1024]
    var wvalue: [16384]u16 = [0 as u16; 16384]
    if win_utf8_to_utf16_buf(name, &raw mut wname as *mut [1024]u16 as *mut u16, 1024) != 0:
        return 0 as *const u8
    let n = GetEnvironmentVariableW(&wname as *const [1024]u16 as *const u16, &raw mut wvalue as *mut [16384]u16 as *mut u16, 16384 as u32)
    if n == 0:
        return 0 as *const u8
    // Each returned value gets its own allocation so retained `env()`/
    // `with_getenv_str` results never alias. Linux/darwin satisfy this for
    // free because libc `getenv` hands out stable per-variable `environ`
    // pointers; Windows `GetEnvironmentVariableW` copies into a caller buffer,
    // so a single shared static buffer would make every retained result alias
    // the last read. The converter writes one byte per UTF-16 code unit, so the
    // returned unit count `n` is the exact UTF-8 length; the buffer covers
    // value + NUL (rt_mmap pages are zero-filled, so byte `n` is already NUL).
    //
    // The buffer MUST come from rt_mmap, not with_alloc: rt_getenv is called
    // from inside the allocator lock. The allocator's own config checks
    // (dbg_on/alloc_system_on/rt_alloc_effective_limit_unlocked reading
    // WITH_MEMORY_LIMIT_BYTES) run in rt_alloc_unlocked while rt_alloc_lock_word
    // is held; a with_alloc here would re-enter rt_allocator_lock() on the same
    // thread and deadlock on the non-recursive spinlock. Linux/darwin never hit
    // this because their rt_getenv returns environ pointers and allocates
    // nothing. rt_mmap (VirtualAlloc) is thread-safe and takes no allocator
    // lock, mirroring dbg_ledger_init's raw-page pattern. This is an owned,
    // non-aliasing, process-lifetime region — the same lifetime model as
    // `environ` — so "non-allocating rt_getenv" (rt_core.w) holds on Windows too.
    let buf = rt_mmap(n as i64 + 1)
    if buf as i64 == 0:
        return 0 as *const u8
    let _ = win_utf16_to_utf8_buf(&wvalue as *const [16384]u16 as *const u16, buf, n as i64 + 1)
    buf as *const u8

pub fn gethostname(name: *mut u8, len: u64) -> i32:
    var wname: [256]u16 = [0 as u16; 256]
    var n: u32 = 256 as u32
    if GetComputerNameW(&raw mut wname as *mut [256]u16 as *mut u16, &raw mut n) == 0:
        return -1
    let _ = win_utf16_to_utf8_buf(&wname as *const [256]u16 as *const u16, name, len as i64)
    0

pub fn pthread_self() -> i64:
    GetCurrentThreadId() as i64

pub fn mkstemp(template_path: *mut u8) -> i32:
    if template_path as i64 == 0:
        return -1
    var dir: [1024]u8 = [0 as u8; 1024]
    var name: [1024]u8 = [0 as u8; 1024]
    let prefix: [5]u8 = [119 as u8, 105 as u8, 116 as u8, 104 as u8, 0 as u8]
    let n = GetTempPathA(1024 as u32, &raw mut dir as *mut [1024]u8 as *mut u8)
    if n == 0 or n >= 1024:
        return -1
    if GetTempFileNameA(&dir as *const [1024]u8 as *const u8, &prefix as *const [5]u8 as *const u8, 0 as u32, &raw mut name as *mut [1024]u8 as *mut u8) == 0:
        return -1
    var i: i64 = 0
    while i < 1023:
        let ch = name[i]
        unsafe *((template_path as i64 + i) as *mut u8) = ch
        if ch == 0:
            break
        i = i + 1
    unsafe *((template_path as i64 + i) as *mut u8) = 0
    rt_open(&name as *const [1024]u8 as *const u8, 2, 384)

pub fn realpath(path: *const u8, resolved_path: *mut u8) -> *mut u8:
    if path as i64 == 0 or resolved_path as i64 == 0:
        return 0 as *mut u8
    let n = GetFullPathNameA(path, 4096 as u32, resolved_path, 0 as *mut *mut u8)
    if n == 0 or n >= 4096:
        return 0 as *mut u8
    resolved_path

fn win_setenv(name: &str, value: &str) -> i32:
    var wname: [1024]u16 = [0 as u16; 1024]
    var wvalue: [8192]u16 = [0 as u16; 8192]
    let value_len = value.len()
    if win_str_to_utf16_buf(name, &raw mut wname as *mut [1024]u16 as *mut u16, 1024) != 0:
        return -1
    if win_str_to_utf16_buf(value, &raw mut wvalue as *mut [8192]u16 as *mut u16, 8192) != 0:
        return -1
    let value_ptr = if value_len == 0: 0 as *const u16 else: &wvalue as *const [8192]u16 as *const u16
    if SetEnvironmentVariableW(&wname as *const [1024]u16 as *const u16, value_ptr) == 0:
        return win_neg_error()
    0

fn win_process_alloc(handle: i64, pid: i32) -> i32:
    for tries in 0..255:
        let slot = process_next_slot
        process_next_slot = process_next_slot + 1
        if process_next_slot >= 256:
            process_next_slot = 1
        if process_handles[slot] == 0:
            process_handles[slot] = handle
            process_ids[slot] = pid
            return slot
    -1

fn win_wait_process_slot(slot: i32, timeout_ms: i32, consume: bool) -> i32:
    if slot <= 0 or slot >= 256:
        return -1
    let h = process_handles[slot]
    if h == 0:
        return -1
    let wait_ms = if timeout_ms > 0: timeout_ms as u32 else: INFINITE
    let wr = WaitForSingleObject(h, wait_ms)
    if wr == WAIT_TIMEOUT:
        let _term = TerminateProcess(h, CAPTURE_TIMEOUT_RC as u32)
        let _wait = WaitForSingleObject(h, INFINITE)
        if consume:
            let _close = CloseHandle(h)
            process_handles[slot] = 0
            process_ids[slot] = 0
        return CAPTURE_TIMEOUT_RC
    if wr != WAIT_OBJECT_0:
        return win_neg_error()
    var code: u32 = 1 as u32
    let _ = GetExitCodeProcess(h, &raw mut code)
    if consume:
        let _close = CloseHandle(h)
        process_handles[slot] = 0
        process_ids[slot] = 0
    code as i32

fn win_append_utf16(dst: *mut u16, pos: i64, cap: i64, src: *const u16) -> i64:
    var out_pos = pos
    var i: i64 = 0
    while out_pos < cap - 1:
        let ch = unsafe *((src as i64 + i * 2) as *const u16)
        if ch == 0:
            break
        unsafe *((dst as i64 + out_pos * 2) as *mut u16) = ch
        out_pos = out_pos + 1
        i = i + 1
    out_pos

fn win_build_command_line(blob: *const u8, len: i64, out: *mut u16, cap: i64) -> i32:
    var pos: i64 = 0
    var offset: i64 = 0
    while offset < len and pos < cap - 4:
        if pos > 0:
            unsafe *((out as i64 + pos * 2) as *mut u16) = 32 as u16
            pos = pos + 1
        unsafe *((out as i64 + pos * 2) as *mut u16) = 34 as u16
        pos = pos + 1
        var slash_count: i64 = 0
        while offset < len:
            let ch = unsafe *((blob as i64 + offset) as *const u8)
            if ch == 0:
                break
            if ch == 92:
                slash_count = slash_count + 1
                offset = offset + 1
                continue
            if ch == 34:
                while slash_count > 0:
                    if pos >= cap - 5:
                        return -1
                    unsafe *((out as i64 + pos * 2) as *mut u16) = 92 as u16
                    pos = pos + 1
                    unsafe *((out as i64 + pos * 2) as *mut u16) = 92 as u16
                    pos = pos + 1
                    slash_count = slash_count - 1
                if pos >= cap - 5:
                    return -1
                unsafe *((out as i64 + pos * 2) as *mut u16) = 92 as u16
                pos = pos + 1
                unsafe *((out as i64 + pos * 2) as *mut u16) = 34 as u16
                pos = pos + 1
                offset = offset + 1
                continue
            while slash_count > 0:
                if pos >= cap - 4:
                    return -1
                unsafe *((out as i64 + pos * 2) as *mut u16) = 92 as u16
                pos = pos + 1
                slash_count = slash_count - 1
            unsafe *((out as i64 + pos * 2) as *mut u16) = ch as u16
            pos = pos + 1
            offset = offset + 1
            if pos >= cap - 4:
                return -1
        while slash_count > 0:
            if pos >= cap - 5:
                return -1
            unsafe *((out as i64 + pos * 2) as *mut u16) = 92 as u16
            pos = pos + 1
            unsafe *((out as i64 + pos * 2) as *mut u16) = 92 as u16
            pos = pos + 1
            slash_count = slash_count - 1
        unsafe *((out as i64 + pos * 2) as *mut u16) = 34 as u16
        pos = pos + 1
        offset = offset + 1
    unsafe *((out as i64 + pos * 2) as *mut u16) = 0 as u16
    0

fn win_make_security_attrs(out: *mut u8):
    unsafe *(out as *mut u32) = 24 as u32
    unsafe *((out as i64 + 8) as *mut i64) = 0
    unsafe *((out as i64 + 16) as *mut i32) = 1

fn win_open_redirect(path: &str, write_mode: bool) -> i64:
    var wpath: [4096]u16 = [0 as u16; 4096]
    let _ = win_str_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096)
    var sec: [24]u8 = [0 as u8; 24]
    win_make_security_attrs(&raw mut sec as *mut [24]u8 as *mut u8)
    let access = if write_mode: GENERIC_WRITE else: GENERIC_READ
    let creation = if write_mode: CREATE_ALWAYS else: OPEN_EXISTING
    CreateFileW(&wpath as *const [4096]u16 as *const u16, access, FILE_SHARE_ALL, &raw mut sec as *mut [24]u8 as *mut u8, creation, FILE_ATTRIBUTE_NORMAL, 0)

fn win_spawn_argv(args: &str, stdout_path: &str, stderr_path: &str, stdin_path: &str, cwd: &str, wait: bool, timeout_ms: i32) -> i32:
    let data = win_str_data(args)
    let cmd = with_alloc(32768 * 2)
    if cmd as i64 == 0:
        return -12
    if win_build_command_line(data, args.len(), cmd as *mut u16, 32768) != 0:
        with_free(cmd)
        return -1
    var startup: [104]u8 = [0 as u8; 104]
    var proc_info: [24]u8 = [0 as u8; 24]
    unsafe *((&raw mut startup) as *mut [104]u8 as *mut u32) = 104 as u32
    var inherit = 0
    var stdin_h = GetStdHandle(STD_INPUT_HANDLE)
    var stdout_h = GetStdHandle(STD_OUTPUT_HANDLE)
    var stderr_h = GetStdHandle(STD_ERROR_HANDLE)
    let has_stdin = stdin_path.len() > 0
    let has_stdout = stdout_path.len() > 0
    let has_stderr = stderr_path.len() > 0
    if has_stdin:
        stdin_h = win_open_redirect(stdin_path, false)
        inherit = 1
    if has_stdout:
        stdout_h = win_open_redirect(stdout_path, true)
        inherit = 1
    if has_stderr:
        stderr_h = win_open_redirect(stderr_path, true)
        inherit = 1
    if inherit != 0:
        let startup_base = (&raw mut startup) as *mut [104]u8 as i64
        unsafe *((startup_base + 60) as *mut u32) = 0x00000100 as u32
        unsafe *((startup_base + 80) as *mut i64) = stdin_h
        unsafe *((startup_base + 88) as *mut i64) = stdout_h
        unsafe *((startup_base + 96) as *mut i64) = stderr_h
    var cwdw: [4096]u16 = [0 as u16; 4096]
    var cwdp = 0 as *const u16
    if cwd.len() > 0:
        let _ = win_str_to_utf16_buf(cwd, &raw mut cwdw as *mut [4096]u16 as *mut u16, 4096)
        cwdp = &cwdw as *const [4096]u16 as *const u16
    let ok = CreateProcessW(0 as *const u16, cmd as *mut u16, 0 as *mut u8, 0 as *mut u8, inherit, 0 as u32, 0 as *mut u8, cwdp, &raw mut startup as *mut [104]u8 as *mut u8, &raw mut proc_info as *mut [24]u8 as *mut u8)
    with_free(cmd)
    if has_stdin and stdin_h != 0 and stdin_h != INVALID_HANDLE_VALUE:
        let _ = CloseHandle(stdin_h)
    if has_stdout and stdout_h != 0 and stdout_h != INVALID_HANDLE_VALUE:
        let _ = CloseHandle(stdout_h)
    if has_stderr and stderr_h != 0 and stderr_h != INVALID_HANDLE_VALUE:
        let _ = CloseHandle(stderr_h)
    if ok == 0:
        return win_neg_error()
    let process_h = unsafe *((&proc_info as i64 + 0) as *const i64)
    let thread_h = unsafe *((&proc_info as i64 + 8) as *const i64)
    let pid = unsafe *((&proc_info as i64 + 16) as *const i32)
    let _thread_close = CloseHandle(thread_h)
    let slot = win_process_alloc(process_h, pid)
    if slot < 0:
        let _close = CloseHandle(process_h)
        return -1
    if wait:
        return win_wait_process_slot(slot, timeout_ms, true)
    slot

pub fn rt_compat_setenv_str(name: &str, value: &str) -> i32:
    win_setenv(name, value)

pub fn rt_compat_install_interrupt_handlers() -> Unit:
    let _ = 0

pub fn rt_compat_raise_stack_limit() -> Unit:
    let _ = 0

pub fn rt_set_process_memory_limit_bytes(limit: i64) -> i32:
    let _ = limit
    0

pub fn rt_compat_interrupt_requested() -> i32:
    0

pub fn rt_compat_exec_binary(path: &str) -> i32:
    var blob: [4096]u8 = [0 as u8; 4096]
    let data = win_str_data(path)
    var i: i64 = 0
    while i < path.len() and i < 4095:
        unsafe *((((&raw mut blob) as *mut [4096]u8 as i64) + i) as *mut u8) = unsafe *((data as i64 + i) as *const u8)
        i = i + 1
    unsafe *((((&raw mut blob) as *mut [4096]u8 as i64) + i) as *mut u8) = 0
    let argv = make_windows_blob_str(&raw mut blob as *mut [4096]u8 as *const u8, i + 1)
    win_spawn_argv(argv, "", "", "", "", true, 0)

fn make_windows_blob_str(ptr: *const u8, len: i64) -> str:
    var raw: [2]i64 = [ptr as i64, len]
    let p = &raw as *const str
    unsafe *p

pub fn rt_compat_exec_argv(args: &str) -> i32:
    win_spawn_argv(args, "", "", "", "", true, 0)

pub fn rt_compat_exec_argv_cwd(args: &str, cwd: &str) -> i32:
    win_spawn_argv(args, "", "", "", cwd, true, 0)

pub fn rt_compat_exec_argv_capture(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32) -> i32:
    win_spawn_argv(args, stdout_path, stderr_path, "", "", true, timeout_ms)

pub fn rt_compat_exec_argv_capture_input(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32, stdin_path: &str) -> i32:
    win_spawn_argv(args, stdout_path, stderr_path, stdin_path, "", true, timeout_ms)

pub fn rt_compat_exec_argv_capture_cwd(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32, cwd: &str) -> i32:
    win_spawn_argv(args, stdout_path, stderr_path, "", cwd, true, timeout_ms)

pub fn rt_compat_exec_argv_capture_spawn(args: &str, stdout_path: &str, stderr_path: &str) -> i32:
    win_spawn_argv(args, stdout_path, stderr_path, "", "", false, 0)

pub fn rt_compat_exec_wait(pid: i32, timeout_ms: i32) -> i32:
    win_wait_process_slot(pid, timeout_ms, true)

// ---------------------------------------------------------------------------
// Networking (Winsock2 / ws2_32). Mirrors the POSIX backend in
// rt/linux_x86_64.w:with_net_*, translated to Winsock semantics: SOCKET
// handles are returned as i64 (INVALID_SOCKET reads as -1), closesocket
// replaces close, send/recv take int-width lengths, and socket creation is
// gated behind a one-time WSAStartup. ws2_32.lib is already on the Windows
// link line (src/compiler/Link.w). Loopback handles fit in i32, so the public
// with_net_* i32-fd ABI declared by std.net is preserved on both platforms.
// ---------------------------------------------------------------------------

extern fn WSAStartup(version: u16, data: *mut u8) -> i32
extern fn socket(af: i32, ty: i32, protocol: i32) -> i64
extern fn connect(s: i64, addr: *const u8, namelen: i32) -> i32
extern fn bind(s: i64, addr: *const u8, namelen: i32) -> i32
extern fn listen(s: i64, backlog: i32) -> i32
extern fn accept(s: i64, addr: *mut u8, addrlen: *mut i32) -> i64
extern fn getsockname(s: i64, addr: *mut u8, addrlen: *mut i32) -> i32
extern fn send(s: i64, buf: *const u8, len: i32, flags: i32) -> i32
extern fn recv(s: i64, buf: *mut u8, len: i32, flags: i32) -> i32
extern fn closesocket(s: i64) -> i32
extern fn getaddrinfo(node: *const u8, service: *const u8, hints: *const WindowsAddrInfo, res: *mut *mut WindowsAddrInfo) -> i32
extern fn freeaddrinfo(res: *mut WindowsAddrInfo) -> Unit
extern fn with_str_from_bytes(s: *const u8, len: i64) -> str

// Win64 ADDRINFOA (ws2def.h): ai_addrlen is size_t (u64) and ai_canonname
// precedes ai_addr — both differ from the Linux struct addrinfo layout.
type WindowsAddrInfo:
    ai_flags: i32
    ai_family: i32
    ai_socktype: i32
    ai_protocol: i32
    ai_addrlen: u64
    ai_canonname: *mut u8
    ai_addr: *mut u8
    ai_next: *mut WindowsAddrInfo

fn rt_net_str_data(s: &str) -> *const u8:
    unsafe **(&s as *const *const *const u8)

fn rt_net_wsa_ensure() -> i32:
    // 0x0202 == Winsock 2.2. WSAStartup is refcounted; we never WSACleanup
    // (a process-lifetime refcount leak, matching how the runtime treats other
    // one-shot OS init).
    var wsadata: [512]u8 = [0 as u8; 512]
    WSAStartup(514 as u16, &raw mut wsadata as *mut [512]u8 as *mut u8)

fn rt_net_empty_str() -> str:
    with_str_from_bytes("" as *const u8, 0)

fn rt_net_copy_str_to_c_buf(s: &str, out: *mut u8, cap: i64) -> i32:
    if s.len() + 1 > cap:
        return -1
    var i: i64 = 0
    while i < s.len():
        unsafe *((out as i64 + i) as *mut u8) = s.byte_at(i) as u8
        i = i + 1
    unsafe *((out as i64 + i) as *mut u8) = 0
    0

fn rt_net_write_port_to_c_buf(port: i32, out: *mut u8, cap: i64) -> i32:
    if port < 0 or port > 65535 or cap < 2:
        return -1
    var rev: [6]u8 = [0 as u8; 6]
    var n = port
    var len: i64 = 0
    if n == 0:
        rev[0] = 48 as u8
        len = 1
    else:
        while n > 0:
            rev[len] = (48 + (n % 10)) as u8
            len = len + 1
            n = n / 10
    if len + 1 > cap:
        return -1
    var i: i64 = 0
    while i < len:
        unsafe *((out as i64 + i) as *mut u8) = rev[len - i - 1]
        i = i + 1
    unsafe *((out as i64 + len) as *mut u8) = 0
    0

// Fill a 16-byte sockaddr_in for `port` from a dotted-quad IPv4 literal.
// Returns 0 on success, -1 when `host` is not a numeric IPv4 address (the
// caller then resolves it through getaddrinfo).
fn rt_net_fill_sockaddr_ipv4(host: &str, port: i32, sa: *mut u8) -> i32:
    var parts: [4]i32 = [0 as i32; 4]
    var idx: i64 = 0
    var cur: i32 = 0
    var have_digit = false
    var i: i64 = 0
    while i < host.len():
        let c = host.byte_at(i) as i32
        if c >= 48 and c <= 57:
            cur = cur * 10 + (c - 48)
            if cur > 255:
                return -1
            have_digit = true
        else if c == 46:
            if not have_digit or idx >= 3:
                return -1
            parts[idx] = cur
            idx = idx + 1
            cur = 0
            have_digit = false
        else:
            return -1
        i = i + 1
    if not have_digit or idx != 3:
        return -1
    parts[3] = cur
    // sin_family=AF_INET(2) LE, sin_port big-endian, sin_addr network order.
    unsafe *((sa as i64 + 0) as *mut u8) = 2 as u8
    unsafe *((sa as i64 + 1) as *mut u8) = 0 as u8
    unsafe *((sa as i64 + 2) as *mut u8) = ((port >> 8) & 255) as u8
    unsafe *((sa as i64 + 3) as *mut u8) = (port & 255) as u8
    unsafe *((sa as i64 + 4) as *mut u8) = parts[0] as u8
    unsafe *((sa as i64 + 5) as *mut u8) = parts[1] as u8
    unsafe *((sa as i64 + 6) as *mut u8) = parts[2] as u8
    unsafe *((sa as i64 + 7) as *mut u8) = parts[3] as u8
    var j: i64 = 8
    while j < 16:
        unsafe *((sa as i64 + j) as *mut u8) = 0 as u8
        j = j + 1
    0

fn rt_net_connect_any(host: &str, port: i32, socktype: i32, protocol: i32) -> i32:
    if rt_net_wsa_ensure() != 0:
        return -1
    var sa: [16]u8 = [0 as u8; 16]
    if rt_net_fill_sockaddr_ipv4(host, port, &raw mut sa as *mut [16]u8 as *mut u8) == 0:
        let fd = socket(2, socktype, protocol)
        if fd < 0:
            return -1
        if connect(fd, &sa as *const [16]u8 as *const u8, 16) != 0:
            let _ = closesocket(fd)
            return -1
        return fd as i32
    // Non-numeric host: resolve through getaddrinfo.
    var host_buf: [256]u8 = [0 as u8; 256]
    var port_buf: [16]u8 = [0 as u8; 16]
    if rt_net_copy_str_to_c_buf(host, &raw mut host_buf as *mut [256]u8 as *mut u8, 256) != 0:
        return -1
    if rt_net_write_port_to_c_buf(port, &raw mut port_buf as *mut [16]u8 as *mut u8, 16) != 0:
        return -1
    var hints = WindowsAddrInfo {
        ai_flags: 0,
        ai_family: 0,
        ai_socktype: socktype,
        ai_protocol: protocol,
        ai_addrlen: 0 as u64,
        ai_canonname: 0 as *mut u8,
        ai_addr: 0 as *mut u8,
        ai_next: 0 as *mut WindowsAddrInfo,
    }
    var res: *mut WindowsAddrInfo = 0 as *mut WindowsAddrInfo
    let gai = getaddrinfo(&host_buf as *const [256]u8 as *const u8, &port_buf as *const [16]u8 as *const u8, &hints as *const WindowsAddrInfo, &raw mut res as *mut *mut WindowsAddrInfo)
    if gai != 0 or res as i64 == 0:
        return -1
    var p = res
    while p as i64 != 0:
        let fd = socket((unsafe *p).ai_family, (unsafe *p).ai_socktype, (unsafe *p).ai_protocol)
        if fd >= 0:
            let rc = connect(fd, (unsafe *p).ai_addr as *const u8, (unsafe *p).ai_addrlen as i32)
            if rc == 0:
                freeaddrinfo(res)
                return fd as i32
            let _ = closesocket(fd)
        p = (unsafe *p).ai_next
    freeaddrinfo(res)
    -1

pub fn with_net_tcp_connect(host: str, port: i32) -> i32:
    rt_net_connect_any(&host, port, 1, 6)

pub fn with_net_udp_connect(host: str, port: i32) -> i32:
    rt_net_connect_any(&host, port, 2, 17)

fn rt_net_bind_inaddr_any(fd: i64, port: i32) -> i32:
    var sa: [16]u8 = [0 as u8; 16]
    sa[0] = 2 as u8
    sa[2] = ((port >> 8) & 255) as u8
    sa[3] = (port & 255) as u8
    bind(fd, &sa as *const [16]u8 as *const u8, 16)

pub fn with_net_tcp_listen(port: i32, backlog: i32) -> i32:
    if port < 0 or port > 65535:
        return -1
    if rt_net_wsa_ensure() != 0:
        return -1
    let fd = socket(2, 1, 6)
    if fd < 0:
        return -1
    if rt_net_bind_inaddr_any(fd, port) != 0:
        let _ = closesocket(fd)
        return -1
    if listen(fd, backlog) != 0:
        let _ = closesocket(fd)
        return -1
    fd as i32

pub fn with_net_tcp_accept(sock: i32) -> i32:
    let fd = accept(sock as i64, 0 as *mut u8, 0 as *mut i32)
    if fd < 0:
        return -1
    fd as i32

pub fn with_net_udp_bind(port: i32) -> i32:
    if port < 0 or port > 65535:
        return -1
    if rt_net_wsa_ensure() != 0:
        return -1
    let fd = socket(2, 2, 17)
    if fd < 0:
        return -1
    if rt_net_bind_inaddr_any(fd, port) != 0:
        let _ = closesocket(fd)
        return -1
    fd as i32

pub fn with_net_sock_port(sock: i32) -> i32:
    var sa: [16]u8 = [0 as u8; 16]
    var sl: i32 = 16
    if getsockname(sock as i64, &raw mut sa as *mut [16]u8 as *mut u8, &raw mut sl) != 0:
        return -1
    ((sa[2] as i32) << 8) | (sa[3] as i32)

pub fn with_net_send(sock: i32, data: str) -> i64:
    let ptr = rt_net_str_data(&data)
    let total = data.len()
    var written: i64 = 0
    while written < total:
        let chunk = total - written
        let r = send(sock as i64, (ptr as i64 + written) as *const u8, chunk as i32, 0)
        if r <= 0:
            return if written > 0: written else: -1
        written = written + (r as i64)
    written

pub fn with_net_recv(sock: i32, max_len: i64) -> str:
    if max_len <= 0:
        return rt_net_empty_str()
    let buf = with_alloc(max_len)
    if buf as i64 == 0:
        return rt_net_empty_str()
    let r = recv(sock as i64, buf, max_len as i32, 0)
    if r <= 0:
        with_free(buf)
        return rt_net_empty_str()
    let out = with_str_from_bytes(buf as *const u8, r as i64)
    with_free(buf)
    out

pub fn with_net_close(sock: i32) -> i32:
    closesocket(sock as i64)
