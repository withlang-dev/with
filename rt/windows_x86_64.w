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
extern fn with_str_concat(a: str, b: str) -> str
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
var env_result_buf: [32768]u8 = [0 as u8; 32768]
var process_handles: [256]i64 = [0 as i64; 256]
var process_ids: [256]i32 = [0 as i32; 256]
var process_next_slot: i32 = 1

unsafe fn win_error() -> i32:
    let err = GetLastError()
    if err == 0: 1 else: err

unsafe fn win_neg_error() -> i32:
    -win_error()

unsafe fn win_strlen16(s: *const u16) -> i64:
    var len: i64 = 0
    while unsafe *((s as i64 + len * 2) as *const u16) != 0:
        len = len + 1
    len

unsafe fn win_cstr_len(s: *const u8) -> i64:
    if s as i64 == 0:
        return 0
    var len: i64 = 0
    while unsafe *((s as i64 + len) as *const u8) != 0:
        len = len + 1
    len

unsafe fn win_utf8_to_utf16_buf(src: *const u8, dst: *mut u16, cap: i64) -> i32:
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

unsafe fn win_str_to_utf16_buf(src: str, dst: *mut u16, cap: i64) -> i32:
    if cap <= 0:
        return -1
    let sp = &src as *const *const u8
    let data = unsafe *sp
    var i: i64 = 0
    while i < src.len() and i < cap - 1:
        unsafe *((dst as i64 + i * 2) as *mut u16) = (unsafe *((data as i64 + i) as *const u8)) as u16
        i = i + 1
    unsafe *((dst as i64 + i * 2) as *mut u16) = 0 as u16
    0

unsafe fn win_utf16_to_utf8_buf(src: *const u16, dst: *mut u8, cap: i64) -> i32:
    var i: i64 = 0
    while i < cap - 1:
        let ch = unsafe *((src as i64 + i * 2) as *const u16)
        if ch == 0:
            break
        unsafe *((dst as i64 + i) as *mut u8) = if ch < 128: ch as u8 else: 63 as u8
        i = i + 1
    unsafe *((dst as i64 + i) as *mut u8) = 0
    i as i32

unsafe fn win_handle_for_fd(fd: i32) -> i64:
    if fd == 0:
        return GetStdHandle(STD_INPUT_HANDLE)
    if fd == 1:
        return GetStdHandle(STD_OUTPUT_HANDLE)
    if fd == 2:
        return GetStdHandle(STD_ERROR_HANDLE)
    if fd < 0 or fd >= 256:
        return 0
    rt_handles[fd]

unsafe fn win_alloc_fd(handle: i64) -> i32:
    if handle == 0 or handle == INVALID_HANDLE_VALUE:
        return win_neg_error()
    for i in 3..256:
        if rt_handles[i] == 0:
            rt_handles[i] = handle
            return i
    let _ = CloseHandle(handle)
    -24

pub unsafe fn rt_store_args(argc_val: i32, argv_val: *const *const u8) -> Unit:
    rt_argc = argc_val
    rt_argv_raw = argv_val as i64

pub unsafe fn rt_args() -> (*const *const u8, i32):
    (rt_argv_raw as *const *const u8, rt_argc)

pub unsafe fn rt_write(fd: i32, buf: *const u8, len: i64) -> i64:
    let handle = win_handle_for_fd(fd)
    if handle == 0 or handle == INVALID_HANDLE_VALUE:
        return -6
    var written: u32 = 0 as u32
    if WriteFile(handle, buf, len as u32, &raw mut written, 0 as *mut u8) == 0:
        return -(win_error() as i64)
    written as i64

pub unsafe fn rt_read(fd: i32, buf: *mut u8, len: i64) -> i64:
    let handle = win_handle_for_fd(fd)
    if handle == 0 or handle == INVALID_HANDLE_VALUE:
        return -6
    var got: u32 = 0 as u32
    if ReadFile(handle, buf, len as u32, &raw mut got, 0 as *mut u8) == 0:
        return -(win_error() as i64)
    got as i64

pub unsafe fn rt_open(path: *const u8, flags: i32, mode: i32) -> i32:
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

pub unsafe fn rt_close(fd: i32) -> i32:
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

pub unsafe fn rt_seek(fd: i32, offset: i64, whence: i32) -> i64:
    let h = win_handle_for_fd(fd)
    if h == 0 or h == INVALID_HANDLE_VALUE:
        return -6
    var pos: i64 = 0
    if SetFilePointerEx(h, offset, &raw mut pos, whence as u32) == 0:
        return -(win_error() as i64)
    pos

unsafe fn win_filetime_to_ns(low: u32, high: u32) -> i64:
    let ticks = ((high as u64) << 32) | low as u64
    let unix_100ns = ticks - 116444736000000000 as u64
    (unix_100ns * 100) as i64

pub unsafe fn rt_stat(path: *const u8, out: *mut RtStatBuf) -> i32:
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

pub unsafe fn rt_chmod(path: *const u8, mode: i32) -> i32:
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

pub unsafe fn rt_getcwd(buf: *mut u8, size: i64) -> i32:
    var wbuf: [4096]u16 = [0 as u16; 4096]
    let n = GetCurrentDirectoryW(4096 as u32, &raw mut wbuf as *mut [4096]u16 as *mut u16)
    if n == 0:
        return win_neg_error()
    let _ = win_utf16_to_utf8_buf(&wbuf as *const [4096]u16 as *const u16, buf, size)
    0

pub unsafe fn rt_mmap(size: i64) -> *mut u8:
    VirtualAlloc(0 as *mut u8, size as u64, MEM_COMMIT_RESERVE, PAGE_READWRITE)

pub unsafe fn rt_munmap(ptr: *mut u8, size: i64) -> Unit:
    let _ = size
    let _free = VirtualFree(ptr, 0, MEM_RELEASE)

pub unsafe fn rt_exit(code: i32) -> Unit:
    ExitProcess(code)

pub unsafe fn rt_clock_ns() -> i64:
    if qpc_freq == 0:
        let _ = QueryPerformanceFrequency(&raw mut qpc_freq)
    var now: i64 = 0
    let _ = QueryPerformanceCounter(&raw mut now)
    if qpc_freq <= 0:
        return 0
    let seconds = now / qpc_freq
    let remainder = now % qpc_freq
    seconds * 1000000000 + (remainder * 1000000000) / qpc_freq

pub unsafe fn rt_nanosleep(ns: i64) -> i32:
    let ms = if ns <= 0: 0 else: ((ns + 999999) / 1000000) as u32
    Sleep(ms)
    0

pub unsafe fn rt_getpid() -> i32:
    GetCurrentProcessId()

pub unsafe fn rt_kill(pid: i32, sig: i32) -> i32:
    let access = SYNCHRONIZE | PROCESS_QUERY_LIMITED_INFORMATION | PROCESS_TERMINATE
    let h = OpenProcess(access, 0, pid)
    if h == 0:
        return win_neg_error()
    if sig != 0:
        let _ = TerminateProcess(h, (128 + sig) as u32)
    let _close = CloseHandle(h)
    0

pub unsafe fn rt_raise(sig: i32) -> i32:
    ExitProcess(128 + sig)
    0

pub unsafe fn rt_thread_spawn(start_routine: *mut u8, arg: *mut u8) -> i64:
    var tid: u32 = 0 as u32
    let h = CreateThread(0 as *mut u8, 0, start_routine, arg, 0, &raw mut tid)
    if h == 0:
        return -(win_error() as i64)
    h

pub unsafe fn rt_thread_join(handle: i64) -> i32:
    let r = WaitForSingleObject(handle, INFINITE)
    let _ = CloseHandle(handle)
    if r != WAIT_OBJECT_0:
        return win_neg_error()
    0

pub unsafe fn rt_fill_random(buf: *mut u8, len: u64) -> Unit:
    if SystemFunction036(buf, len as u32) == 0:
        ExitProcess(1)

pub unsafe fn rt_libc_stdin() -> *mut u8:
    0 as *mut u8

pub unsafe fn rt_libc_stdout() -> *mut u8:
    0 as *mut u8

pub unsafe fn rt_libc_stderr() -> *mut u8:
    0 as *mut u8

pub unsafe fn rt_fiber_page_size() -> i64:
    4096

pub unsafe fn rt_fiber_mmap_flags() -> i32:
    0

pub unsafe fn rt_fiber_fault_addr(info: *const u8) -> i64:
    let _ = info
    0

pub unsafe fn rt_fiber_reset_signal_handler(sig: i32) -> Unit:
    let _ = sig

pub unsafe fn rt_fiber_install_signal_handlers(alt_stack: *mut u8, alt_stack_size: i64, handler: i64) -> Unit:
    let _ = alt_stack
    let _ = alt_stack_size
    let _ = handler

unsafe fn win_path_join(parent: *const u8, name: *const u8, out: *mut u8, cap: i64) -> i32:
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

unsafe fn win_is_dot_or_dotdot(name: *const u8) -> bool:
    let first = unsafe *name
    if first != 46:
        return false
    let second = unsafe *((name as i64 + 1) as *const u8)
    if second == 0:
        return true
    if second != 46:
        return false
    (unsafe *((name as i64 + 2) as *const u8)) == 0

unsafe fn win_find_name(data: *mut u8, out: *mut u8, cap: i64) -> i32:
    let name_w = (data as i64 + 44) as *const u16
    win_utf16_to_utf8_buf(name_w, out, cap)

unsafe fn win_is_dir(path: *const u8) -> bool:
    var wpath: [4096]u16 = [0 as u16; 4096]
    if win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096) != 0:
        return false
    let attrs = GetFileAttributesW(&wpath as *const [4096]u16 as *const u16)
    attrs != 0xffffffff as u32 and (attrs & FILE_ATTRIBUTE_DIRECTORY) != 0

pub unsafe fn rt_mkdir(path: *const u8, mode: i32) -> i32:
    let _ = mode
    var wpath: [4096]u16 = [0 as u16; 4096]
    if win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096) != 0:
        return -1
    if CreateDirectoryW(&wpath as *const [4096]u16 as *const u16, 0 as *mut u8) == 0:
        return win_neg_error()
    0

pub unsafe fn rt_unlink(path: *const u8) -> i32:
    var wpath: [4096]u16 = [0 as u16; 4096]
    if win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096) != 0:
        return -1
    if DeleteFileW(&wpath as *const [4096]u16 as *const u16) == 0:
        return win_neg_error()
    0

pub unsafe fn rt_rmdir(path: *const u8) -> i32:
    var wpath: [4096]u16 = [0 as u16; 4096]
    if win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096) != 0:
        return -1
    if RemoveDirectoryW(&wpath as *const [4096]u16 as *const u16) == 0:
        return win_neg_error()
    0

pub unsafe fn rt_rename(old_path: *const u8, new_path: *const u8) -> i32:
    var oldw: [4096]u16 = [0 as u16; 4096]
    var neww: [4096]u16 = [0 as u16; 4096]
    if win_utf8_to_utf16_buf(old_path, &raw mut oldw as *mut [4096]u16 as *mut u16, 4096) != 0:
        return -1
    if win_utf8_to_utf16_buf(new_path, &raw mut neww as *mut [4096]u16 as *mut u16, 4096) != 0:
        return -1
    if MoveFileExW(&oldw as *const [4096]u16 as *const u16, &neww as *const [4096]u16 as *const u16, MOVEFILE_REPLACE_EXISTING) == 0:
        return win_neg_error()
    0

unsafe fn win_remove_tree_impl(path: *const u8) -> i32:
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

pub unsafe fn rt_remove_tree(path: *const u8) -> i32:
    win_remove_tree_impl(path)

unsafe fn win_copy_file(src: *const u8, dst: *const u8) -> i32:
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

pub unsafe fn rt_copy_tree(src: *const u8, dst: *const u8) -> i32:
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

pub unsafe fn rt_symlink(target: *const u8, link_path: *const u8) -> i32:
    var targetw: [4096]u16 = [0 as u16; 4096]
    var linkw: [4096]u16 = [0 as u16; 4096]
    let _ = win_utf8_to_utf16_buf(target, &raw mut targetw as *mut [4096]u16 as *mut u16, 4096)
    let _ = win_utf8_to_utf16_buf(link_path, &raw mut linkw as *mut [4096]u16 as *mut u16, 4096)
    let flags = if win_is_dir(target): 1 as u32 else: 0 as u32
    if CreateSymbolicLinkW(&linkw as *const [4096]u16 as *const u16, &targetw as *const [4096]u16 as *const u16, flags | (2 as u32)) == 0:
        return win_neg_error()
    0

unsafe fn win_empty_str() -> str:
    with_str_from_cstr(c"".ptr)

unsafe fn win_newline_str() -> str:
    with_str_from_cstr(c"\n".ptr)

unsafe fn win_list_append(out: str, path: *const u8) -> str:
    with_str_concat(with_str_concat(out, with_str_from_cstr(path)), win_newline_str())

unsafe fn win_list_files_walk(path: *const u8, out: str) -> str:
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

pub unsafe fn rt_list_files(path: *const u8) -> str:
    win_list_files_walk(path, win_empty_str())

pub unsafe fn rt_access(path: *const u8, mode: i32) -> i32:
    let _ = mode
    var wpath: [4096]u16 = [0 as u16; 4096]
    if win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096) != 0:
        return -1
    let attrs = GetFileAttributesW(&wpath as *const [4096]u16 as *const u16)
    if attrs == 0xffffffff as u32:
        return win_neg_error()
    0

pub unsafe fn rt_sysinfo(out: *mut RtSysInfo) -> i32:
    var info: [64]u8 = [0 as u8; 64]
    GetSystemInfo(&raw mut info as *mut [64]u8 as *mut u8)
    let page_size = unsafe *((&info as i64 + 8) as *const u32)
    let processors = unsafe *((&info as i64 + 36) as *const u32)
    var mem: [64]u8 = [0 as u8; 64]
    unsafe *((&raw mut mem) as *mut [64]u8 as *mut u32) = 64 as u32
    var total: i64 = 0
    if GlobalMemoryStatusEx(&raw mut mem as *mut [64]u8 as *mut u8) != 0:
        total = unsafe *((&mem as i64 + 8) as *const u64) as i64
    (unsafe *out).cpu_cores = if processors > 0: processors as i32 else: 1
    (unsafe *out).page_size = if page_size > 0: page_size as i64 else: 4096
    (unsafe *out).memory_total = total
    0

pub unsafe fn rt_sysinfo_os() -> str:
    with_str_from_cstr(c"Windows".ptr)

pub unsafe fn rt_sysinfo_arch() -> str:
    with_str_from_cstr(c"x86_64".ptr)

pub unsafe fn rt_getenv(name: *const u8) -> *const u8:
    var wname: [1024]u16 = [0 as u16; 1024]
    var wvalue: [16384]u16 = [0 as u16; 16384]
    if win_utf8_to_utf16_buf(name, &raw mut wname as *mut [1024]u16 as *mut u16, 1024) != 0:
        return 0 as *const u8
    let n = GetEnvironmentVariableW(&wname as *const [1024]u16 as *const u16, &raw mut wvalue as *mut [16384]u16 as *mut u16, 16384 as u32)
    if n == 0:
        return 0 as *const u8
    let _ = win_utf16_to_utf8_buf(&wvalue as *const [16384]u16 as *const u16, &raw mut env_result_buf as *mut [32768]u8 as *mut u8, 32768)
    &env_result_buf as *const [32768]u8 as *const u8

pub unsafe fn gethostname(name: *mut u8, len: u64) -> i32:
    var wname: [256]u16 = [0 as u16; 256]
    var n: u32 = 256 as u32
    if GetComputerNameW(&raw mut wname as *mut [256]u16 as *mut u16, &raw mut n) == 0:
        return -1
    let _ = win_utf16_to_utf8_buf(&wname as *const [256]u16 as *const u16, name, len as i64)
    0

pub unsafe fn pthread_self() -> i64:
    GetCurrentThreadId() as i64

pub unsafe fn mkstemp(template_path: *mut u8) -> i32:
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

pub unsafe fn realpath(path: *const u8, resolved_path: *mut u8) -> *mut u8:
    if path as i64 == 0 or resolved_path as i64 == 0:
        return 0 as *mut u8
    let n = GetFullPathNameA(path, 4096 as u32, resolved_path, 0 as *mut *mut u8)
    if n == 0 or n >= 4096:
        return 0 as *mut u8
    resolved_path

unsafe fn win_setenv(name: str, value: str) -> i32:
    var wname: [1024]u16 = [0 as u16; 1024]
    var wvalue: [8192]u16 = [0 as u16; 8192]
    if win_str_to_utf16_buf(name, &raw mut wname as *mut [1024]u16 as *mut u16, 1024) != 0:
        return -1
    if win_str_to_utf16_buf(value, &raw mut wvalue as *mut [8192]u16 as *mut u16, 8192) != 0:
        return -1
    let value_ptr = if value.len() == 0: 0 as *const u16 else: &wvalue as *const [8192]u16 as *const u16
    if SetEnvironmentVariableW(&wname as *const [1024]u16 as *const u16, value_ptr) == 0:
        return win_neg_error()
    0

unsafe fn win_process_alloc(handle: i64, pid: i32) -> i32:
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

unsafe fn win_wait_process_slot(slot: i32, timeout_ms: i32, consume: bool) -> i32:
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

unsafe fn win_append_utf16(dst: *mut u16, pos: i64, cap: i64, src: *const u16) -> i64:
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

unsafe fn win_build_command_line(blob: *const u8, len: i64, out: *mut u16, cap: i64) -> i32:
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

unsafe fn win_make_security_attrs(out: *mut u8):
    unsafe *(out as *mut u32) = 24 as u32
    unsafe *((out as i64 + 8) as *mut i64) = 0
    unsafe *((out as i64 + 16) as *mut i32) = 1

unsafe fn win_open_redirect(path: str, write_mode: bool) -> i64:
    var wpath: [4096]u16 = [0 as u16; 4096]
    let _ = win_str_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096)
    var sec: [24]u8 = [0 as u8; 24]
    win_make_security_attrs(&raw mut sec as *mut [24]u8 as *mut u8)
    let access = if write_mode: GENERIC_WRITE else: GENERIC_READ
    let creation = if write_mode: CREATE_ALWAYS else: OPEN_EXISTING
    CreateFileW(&wpath as *const [4096]u16 as *const u16, access, FILE_SHARE_ALL, &raw mut sec as *mut [24]u8 as *mut u8, creation, FILE_ATTRIBUTE_NORMAL, 0)

unsafe fn win_spawn_argv(args: str, stdout_path: str, stderr_path: str, stdin_path: str, cwd: str, wait: bool, timeout_ms: i32) -> i32:
    let sp = &args as *const *const u8
    let data = unsafe *sp
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
    if stdin_path.len() > 0:
        stdin_h = win_open_redirect(stdin_path, false)
        inherit = 1
    if stdout_path.len() > 0:
        stdout_h = win_open_redirect(stdout_path, true)
        inherit = 1
    if stderr_path.len() > 0:
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
    if stdin_path.len() > 0 and stdin_h != 0 and stdin_h != INVALID_HANDLE_VALUE:
        let _ = CloseHandle(stdin_h)
    if stdout_path.len() > 0 and stdout_h != 0 and stdout_h != INVALID_HANDLE_VALUE:
        let _ = CloseHandle(stdout_h)
    if stderr_path.len() > 0 and stderr_h != 0 and stderr_h != INVALID_HANDLE_VALUE:
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

pub unsafe fn rt_compat_setenv_str(name: str, value: str) -> i32:
    win_setenv(name, value)

pub unsafe fn rt_compat_install_interrupt_handlers() -> Unit:
    let _ = 0

pub unsafe fn rt_compat_raise_stack_limit() -> Unit:
    let _ = 0

pub unsafe fn rt_compat_interrupt_requested() -> i32:
    0

pub unsafe fn rt_compat_exec_binary(path: str) -> i32:
    var blob: [4096]u8 = [0 as u8; 4096]
    let sp = &path as *const *const u8
    let data = unsafe *sp
    var i: i64 = 0
    while i < path.len() and i < 4095:
        unsafe *((((&raw mut blob) as *mut [4096]u8 as i64) + i) as *mut u8) = unsafe *((data as i64 + i) as *const u8)
        i = i + 1
    unsafe *((((&raw mut blob) as *mut [4096]u8 as i64) + i) as *mut u8) = 0
    let argv = make_windows_blob_str(&raw mut blob as *mut [4096]u8 as *const u8, i + 1)
    win_spawn_argv(argv, "", "", "", "", true, 0)

unsafe fn make_windows_blob_str(ptr: *const u8, len: i64) -> str:
    var raw: [2]i64 = [ptr as i64, len]
    let p = &raw as *const str
    unsafe *p

pub unsafe fn rt_compat_exec_argv(args: str) -> i32:
    win_spawn_argv(args, "", "", "", "", true, 0)

pub unsafe fn rt_compat_exec_argv_cwd(args: str, cwd: str) -> i32:
    win_spawn_argv(args, "", "", "", cwd, true, 0)

pub unsafe fn rt_compat_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32:
    win_spawn_argv(args, stdout_path, stderr_path, "", "", true, timeout_ms)

pub unsafe fn rt_compat_exec_argv_capture_input(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, stdin_path: str) -> i32:
    win_spawn_argv(args, stdout_path, stderr_path, stdin_path, "", true, timeout_ms)

pub unsafe fn rt_compat_exec_argv_capture_cwd(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> i32:
    win_spawn_argv(args, stdout_path, stderr_path, "", cwd, true, timeout_ms)

pub unsafe fn rt_compat_exec_argv_capture_spawn(args: str, stdout_path: str, stderr_path: str) -> i32:
    win_spawn_argv(args, stdout_path, stderr_path, "", "", false, 0)

pub unsafe fn rt_compat_exec_wait(pid: i32, timeout_ms: i32) -> i32:
    win_wait_process_slot(pid, timeout_ms, true)
