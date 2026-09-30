// rt/windows_x86_64.w -- Windows x86_64 runtime backend.

use std.builtins.c_void

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
extern fn ExitProcess(code: i32) -> Never
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
extern fn K32GetProcessMemoryInfo(process: i64, counters: *mut u8, cb: u32) -> i32
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
extern fn RtlCaptureStackBackTrace(frames_to_skip: u32, frames_to_capture: u32, back_trace: *mut i64, back_trace_hash: *mut u32) -> u16
extern fn GetCurrentProcess() -> i64
extern fn SymSetOptions(options: u32) -> u32
extern fn SymInitialize(process: i64, search_path: *const u8, invade_process: i32) -> i32
extern fn SymFromAddr(process: i64, address: u64, displacement: *mut u64, symbol: *mut u8) -> i32
extern fn SymGetLineFromAddr64(process: i64, address: u64, displacement: *mut u32, line: *mut u8) -> i32

// ── Panic backtrace ────────────────────────────────────────────────
// With codegen keeps no frame-pointer chain, but Win64 needs none: every
// function carries unwind tables (.pdata/.xdata), so RtlCaptureStackBackTrace
// walks the stack from anywhere, and dbghelp resolves each return address
// against the PDB the link wrote. with_panic_core prints this so a Windows
// panic names its call chain with no debugger attached.
fn bt_put(s: *const u8, n: i64):
    let _ = rt_write(2, s, n)

fn bt_cstr_len(p: *const u8) -> i64:
    var n: i64 = 0
    while (unsafe *((p as i64 + n) as *const u8)) != 0:
        n = n + 1
    n

fn bt_put_hex(v: i64):
    let digits = "0123456789abcdef" as *const u8
    var buf: [16]u8 = [0 as u8; 16]
    var x = v as u64
    var i: i32 = 16
    if x == 0:
        i = 15
        buf[15] = 48 as u8
    while x != 0:
        i = i - 1
        buf[i] = unsafe *((digits as i64 + ((x & 15) as i64)) as *const u8)
        x = x >> 4
    bt_put("0x" as *const u8, 2)
    bt_put((&buf as *const u8 as i64 + i as i64) as *const u8, (16 - i) as i64)

fn bt_put_dec(v: i64):
    var buf: [20]u8 = [0 as u8; 20]
    var x = v
    var i: i32 = 20
    if x == 0:
        i = 19
        buf[19] = 48 as u8
    while x > 0:
        i = i - 1
        buf[i] = ((x % 10) + 48) as u8
        x = x / 10
    bt_put((&buf as *const u8 as i64 + i as i64) as *const u8, (20 - i) as i64)

pub fn rt_backtrace_print() -> Unit:
    var frames: [64]i64 = [0 as i64; 64]
    let n = RtlCaptureStackBackTrace(0 as u32, 64 as u32, &frames as *mut i64, 0 as *mut u32) as i32
    if n == 0:
        return
    let process = GetCurrentProcess()
    // SYMOPT_UNDNAME | SYMOPT_DEFERRED_LOADS | SYMOPT_LOAD_LINES
    let _opts = SymSetOptions(22 as u32)
    let symbols = SymInitialize(process, 0 as *const u8, 1)
    bt_put("backtrace:\n" as *const u8, 11)
    // SYMBOL_INFO: SizeOfStruct at 0 (88), NameLen at 76, MaxNameLen at 80, Name at 84.
    var sym: [600]u8 = [0 as u8; 600]
    // IMAGEHLP_LINE64: SizeOfStruct at 0 (40), LineNumber at 16, FileName at 24.
    var line: [40]u8 = [0 as u8; 40]
    var i: i32 = 0
    while i < n:
        let addr = frames[i]
        bt_put("  #" as *const u8, 3)
        bt_put_dec(i as i64)
        bt_put(" " as *const u8, 1)
        bt_put_hex(addr)
        if symbols != 0:
            let sym_base = &sym as *const u8 as i64
            unsafe *(sym_base as *mut u32) = 88 as u32
            unsafe *((sym_base + 76) as *mut u32) = 0 as u32
            unsafe *((sym_base + 80) as *mut u32) = 512 as u32
            var disp: u64 = 0
            if SymFromAddr(process, addr as u64, &raw mut disp, &sym as *mut u8) != 0:
                let name = (sym_base + 84) as *const u8
                bt_put(" " as *const u8, 1)
                bt_put(name, bt_cstr_len(name))
                bt_put("+" as *const u8, 1)
                bt_put_hex(disp as i64)
            let line_base = &line as *const u8 as i64
            unsafe *(line_base as *mut u32) = 40 as u32
            var line_disp: u32 = 0
            if SymGetLineFromAddr64(process, addr as u64, &raw mut line_disp, &line as *mut u8) != 0:
                let file = unsafe *((line_base + 24) as *const *const u8)
                let number = unsafe *((line_base + 16) as *const u32)
                bt_put(" (" as *const u8, 2)
                bt_put(file, bt_cstr_len(file))
                bt_put(":" as *const u8, 1)
                bt_put_dec(number as i64)
                bt_put(")" as *const u8, 1)
        bt_put("\n" as *const u8, 1)
        i = i + 1
extern fn GetSystemInfo(info: *mut u8) -> Unit
extern fn GlobalMemoryStatusEx(info: *mut u8) -> i32
extern fn GetComputerNameW(buf: *mut u16, size: *mut u32) -> i32
extern fn SystemFunction036(buf: *mut u8, len: u32) -> i32
extern fn VirtualProtect(addr: *mut u8, size: u64, new_protect: u32, old_protect: *mut u32) -> i32
extern fn AddVectoredExceptionHandler(first: u32, handler: *mut u8) -> *mut u8
extern fn GetCurrentThreadId() -> u32
extern fn GetTempPathW(size: u32, buf: *mut u16) -> u32
extern fn GetTempFileNameW(path: *const u16, prefix: *const u16, unique: u32, buf: *mut u16) -> u32
extern fn GetFullPathNameW(path: *const u16, size: u32, buf: *mut u16, file_part: *mut *mut u16) -> u32
extern fn with_str_from_cstr(s: *const u8) -> str
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> *mut u8
// UCRT has no stdin/stdout/stderr global variables; the FILE* streams come from
// __acrt_iob_func(0/1/2) (the UCRT `#define stdin (__acrt_iob_func(0))` macros).
extern fn __acrt_iob_func(index: u32) -> *mut c_void

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
let PAGE_GUARD: u32 = 0x100 as u32
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

// std.libc's errno and rlimit seams (rt_errno_ptr, rt_getrlimit below).
// UCRT spells errno as _errno(); there is no rlimit -- the main thread's
// stack is fixed at link time -- so RLIMIT_STACK (3) reads as unlimited and
// a set is accepted as a no-op; any other resource is refused. The rlimit
// layout is std.libc's: rlim_cur then rlim_max, both u64; RLIM_INFINITY is
// Darwin's (1<<63)-1.
@[link_name("_errno")]
extern fn rt_ucrt_errno() -> *mut i32

fn win_getrlimit(resource: i32, lim: *mut u8) -> i32:
    if resource != 3:
        return -1
    unsafe *(lim as *mut i64) = 9223372036854775807
    unsafe *((lim as i64 + 8) as *mut i64) = 9223372036854775807
    0

fn win_setrlimit(resource: i32, lim: *const u8) -> i32:
    let _ = lim
    if resource != 3: -1 else: 0

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

// ── Text at the Win32 boundary ─────────────────────────────────────
// A With `str` is UTF-8 (spec §15.1) and every *W call takes UTF-16; the
// converters below are the one crossing, both ways.
// - In: UTF-8 is decoded, never widened byte by byte (which named "café"
//   "cafÃ©" on disk). Bytes that are not UTF-8 name no file, so the call
//   fails with EILSEQ rather than guess one; an interior NUL fails with
//   EINVAL; text longer than its buffer fails with ENAMETOOLONG. Nothing
//   is cut short.
// - Out: UTF-16 becomes UTF-8. An unpaired surrogate, which UTF-8 cannot
//   carry, becomes U+FFFD so the `str` stays UTF-8; text longer than its
//   buffer fails with ERANGE. A name that goes from Windows back to Windows
//   (a directory walk) never makes this trip: it stays UTF-16.
// The error numbers are the UCRT's (errno.h): std.fs prints them with strerror.
let WIN_EINVAL: i32 = 22
let WIN_ERANGE: i32 = 34
let WIN_ENAMETOOLONG: i32 = 38
let WIN_EILSEQ: i32 = 42

fn win_u16_at(s: *const u16, i: i64) -> u16: unsafe *((s as i64 + i * 2) as *const u16)

fn win_put_u16(s: *mut u16, i: i64, unit: i32):
    unsafe *((s as i64 + i * 2) as *mut u16) = unit as u16

fn win_put_u8(s: *mut u8, i: i64, byte: i32):
    unsafe *((s as i64 + i) as *mut u8) = byte as u8

// The length of the UTF-8 sequence `lead` begins (1 to 4), or 0 when `lead`
// begins none: a continuation byte (80..BF), C0, C1 or F5..FF.
fn win_utf8_seq_len(lead: i32) -> i64:
    if lead < 0x80: 1 else if lead >= 0xC2 and lead <= 0xDF: 2 else if lead >= 0xE0 and lead <= 0xEF: 3 else if lead >= 0xF0 and lead <= 0xF4: 4 else: 0

// The code point of the `n`-byte sequence at `src`, or -1 when it is not
// UTF-8: a bad continuation byte, an overlong form, a UTF-16 surrogate, or
// past U+10FFFF.
fn win_utf8_decode(src: *const u8, n: i64) -> i32:
    let lead: i32 = unsafe *src
    if n == 1:
        return lead
    var cp = lead & (if n == 2: 0x1F else if n == 3: 0x0F else: 0x07)
    for k in 1..n:
        let next: i32 = unsafe *((src as i64 + k) as *const u8)
        if (next & 0xC0) != 0x80:
            return -1
        cp = (cp << 6) | (next & 0x3F)
    if (n == 3 and cp < 0x800) or (n == 4 and (cp < 0x10000 or cp > 0x10FFFF)) or (cp >= 0xD800 and cp <= 0xDFFF):
        return -1
    cp

fn win_utf16_units(cp: i32) -> i64: if cp >= 0x10000: 2 else: 1

// `cp` as UTF-16 at unit `at`: one unit, or a surrogate pair past U+FFFF.
fn win_put_cp16(dst: *mut u16, at: i64, cp: i32):
    if cp >= 0x10000:
        win_put_u16(dst, at, 0xD800 | ((cp - 0x10000) >> 10))
        win_put_u16(dst, at + 1, 0xDC00 | ((cp - 0x10000) & 0x3FF))
    else:
        win_put_u16(dst, at, cp)

// Decodes `len` bytes of UTF-8 at `src` into `dst`, which has room for `cap`
// units counting the terminating NUL. 0, or a negative errno.
fn win_utf8_to_utf16(src: *const u8, len: i64, dst: *mut u16, cap: i64) -> i32:
    var i: i64 = 0
    var out: i64 = 0
    while i < len:
        let at = (src as i64 + i) as *const u8
        let lead: i32 = unsafe *at
        if lead == 0:
            return -WIN_EINVAL
        let n = win_utf8_seq_len(lead)
        if n == 0 or i + n > len:
            return -WIN_EILSEQ
        let cp = win_utf8_decode(at, n)
        if cp < 0:
            return -WIN_EILSEQ
        let units = win_utf16_units(cp)
        if out + units >= cap:
            return -WIN_ENAMETOOLONG
        win_put_cp16(dst, out, cp)
        out = out + units
        i = i + n
    if out >= cap:
        return -WIN_ENAMETOOLONG
    win_put_u16(dst, out, 0)
    0

fn win_utf8_to_utf16_buf(src: *const u8, dst: *mut u16, cap: i64) -> i32:
    if src as i64 == 0:
        return -WIN_EINVAL
    win_utf8_to_utf16(src, win_cstr_len(src), dst, cap)

fn win_str_data(s: &str) -> *const u8:
    unsafe *(s as *const str as *const *const u8)

fn win_str_to_utf16_buf(src: &str, dst: *mut u16, cap: i64) -> i32:
    win_utf8_to_utf16(win_str_data(src), src.len(), dst, cap)

// The code point at unit `i` of NUL-terminated UTF-16: a valid surrogate pair
// is one code point past U+FFFF, and an unpaired surrogate reads as U+FFFD.
fn win_utf16_cp_at(src: *const u16, i: i64) -> i32:
    let hi: i32 = win_u16_at(src, i)
    if hi < 0xD800 or hi > 0xDFFF:
        return hi
    if hi <= 0xDBFF:
        let lo: i32 = win_u16_at(src, i + 1)
        if lo >= 0xDC00 and lo <= 0xDFFF:
            return 0x10000 + ((hi - 0xD800) << 10) + (lo - 0xDC00)
    0xFFFD

fn win_utf8_width(cp: i32) -> i64:
    if cp < 0x80: 1 else if cp < 0x800: 2 else if cp < 0x10000: 3 else: 4

// The UTF-8 length of NUL-terminated UTF-16, the NUL not counted.
fn win_utf16_utf8_len(src: *const u16) -> i64:
    var i: i64 = 0
    var n: i64 = 0
    var cp = win_utf16_cp_at(src, 0)
    while cp != 0:
        n = n + win_utf8_width(cp)
        i = i + win_utf16_units(cp)
        cp = win_utf16_cp_at(src, i)
    n

// Encodes NUL-terminated UTF-16 at `src` into `dst`, which has room for `cap`
// bytes counting the terminating NUL. The byte length, or -ERANGE.
fn win_utf16_to_utf8_buf(src: *const u16, dst: *mut u8, cap: i64) -> i32:
    if win_utf16_utf8_len(src) >= cap:
        return -WIN_ERANGE
    var i: i64 = 0
    var out: i64 = 0
    var cp = win_utf16_cp_at(src, 0)
    while cp != 0:
        if cp < 0x80:
            win_put_u8(dst, out, cp)
        else if cp < 0x800:
            win_put_u8(dst, out, 0xC0 | (cp >> 6))
            win_put_u8(dst, out + 1, 0x80 | (cp & 0x3F))
        else if cp < 0x10000:
            win_put_u8(dst, out, 0xE0 | (cp >> 12))
            win_put_u8(dst, out + 1, 0x80 | ((cp >> 6) & 0x3F))
            win_put_u8(dst, out + 2, 0x80 | (cp & 0x3F))
        else:
            win_put_u8(dst, out, 0xF0 | (cp >> 18))
            win_put_u8(dst, out + 1, 0x80 | ((cp >> 12) & 0x3F))
            win_put_u8(dst, out + 2, 0x80 | ((cp >> 6) & 0x3F))
            win_put_u8(dst, out + 3, 0x80 | (cp & 0x3F))
        out = out + win_utf8_width(cp)
        i = i + win_utf16_units(cp)
        cp = win_utf16_cp_at(src, i)
    win_put_u8(dst, out, 0)
    out as i32

// NUL-terminated UTF-16 as a fresh `str`.
fn win_utf16_to_str(src: *const u16) -> str:
    let n = win_utf16_utf8_len(src)
    let buf = with_alloc(n + 1)
    let _ = win_utf16_to_utf8_buf(src, buf, n + 1)
    let text = with_str_from_bytes(buf as *const u8, n)
    with_free(buf)
    text

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

// ── Arguments ──────────────────────────────────────────────────────
// std.process.args() is UTF-8, as every `str` is. The narrow argv main
// receives is the command line in the ANSI code page: "café" arrives as
// "caf\xe9" under code page 1252, and a character the code page lacks as "?"
// or a best-fit look-alike. So the runtime takes the UCRT's wide argv:
// _configure_wide_argv runs the parser that built the narrow one (the UCRT's
// argv_parsing.cpp: one parse_command_line template for both) over the
// UTF-16 command line, in the mode the startup code used
// (rt_crt_startup_argv_mode below), so quoting and backslashes read exactly as they
// did. The UCRT keeps that argv for the life of the process.
@[link_name("_configure_wide_argv")]
extern fn rt_ucrt_configure_wide_argv(mode: i32) -> i32
@[link_name("__p___argc")]
extern fn rt_ucrt_argc_ptr() -> *mut i32
@[link_name("__p___wargv")]
extern fn rt_ucrt_wargv_ptr() -> *mut *const *const u16
// The argv mode both startups this runtime links under use: mingw-w64's
// (the SDK's, #1915), whose wildcard.c is built with globbing off, and
// Visual Studio's without setargv.obj. _get_startup_argv_mode, which
// answers the same, is Visual Studio's startup code only.
const RT_CRT_ARGV_UNEXPANDED: i32 = 1
fn rt_crt_startup_argv_mode(): RT_CRT_ARGV_UNEXPANDED

fn win_wide_arg(wargv: *const *const u16, i: i32) -> *const u16:
    unsafe *((wargv as i64 + i * 8) as *const *const u16)

// The wide argv as UTF-8 (an unpaired surrogate becomes U+FFFD) in one block
// from rt_mmap, the pointers then the text, argv[argc] NULL: it lives as long
// as the process, like the argv it replaces. Null if the UCRT refuses.
fn win_utf8_argv(argc_out: *mut i32) -> *const *const u8:
    if rt_ucrt_configure_wide_argv(rt_crt_startup_argv_mode()) != 0:
        return 0 as *const *const u8
    let argc = unsafe *rt_ucrt_argc_ptr()
    let wargv = unsafe *rt_ucrt_wargv_ptr()
    if argc < 0 or wargv as i64 == 0:
        return 0 as *const *const u8
    let table: i64 = (argc + 1) * 8
    var bytes = table
    for i in 0..argc:
        bytes = bytes + win_utf16_utf8_len(win_wide_arg(wargv, i)) + 1
    let block = rt_mmap(bytes)
    if block as i64 == 0:
        return 0 as *const *const u8
    var text = block as i64 + table
    for i in 0..argc:
        let arg = win_wide_arg(wargv, i)
        let n = win_utf16_utf8_len(arg)
        let _ = win_utf16_to_utf8_buf(arg, text as *mut u8, n + 1)
        unsafe *((block as i64 + i * 8) as *mut i64) = text
        text = text + n + 1
    // argv[argc] stays NULL: rt_mmap's pages come zero-filled.
    unsafe *argc_out = argc
    block as *const *const u8

// `argc_val` and `argv_val` are main's narrow arguments; args() gets the
// UTF-8 ones instead (above). Failing to read them is fatal, as the CRT's own
// startup treats a failed argv (exe_common.inl: __scrt_fastfail); running on
// the code-page text instead would hand the program the wrong arguments.
pub fn rt_store_args(argc_val: i32, argv_val: *const *const u8):
    let _ = argc_val
    let _ = argv_val
    var argc: i32 = 0
    let argv = win_utf8_argv(&raw mut argc)
    if argv as i64 == 0:
        let _ = rt_write(2, "fatal: could not read the command line\n" as *const u8, 39)
        ExitProcess(1)
    rt_argc = argc
    rt_argv_raw = argv as i64
    // PWD is the runtime's on Windows. The driver reads it for its working
    // directory (project root, absolutized paths, embed anchoring). No shell
    // maintains it here the way POSIX shells do: a git-bash parent exports the
    // POSIX spelling (/c/src/with, which Win32 resolves as C:\c\src\with) and
    // a child spawned into another directory inherits its parent's value. Set
    // it from the real directory at startup; win_spawn_argv sets it for
    // children given a directory (#1082).
    var cwd: [4096]u8 = [0 as u8; 4096]
    if rt_getcwd(&raw mut cwd as *mut [4096]u8 as *mut u8, 4096) == 0:
        let _pwd = win_setenv("PWD", with_str_from_cstr(&cwd as *const [4096]u8 as *const u8))

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
    var wpath: [4096]u16 = [0; 4096]
    let rc = win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096)
    if rc != 0:
        return rc
    win_open_w(&wpath as *const [4096]u16 as *const u16, flags)

fn win_open_w(wpath: *const u16, flags: i32) -> i32:
    let access = if (flags & 3) == 0: GENERIC_READ else if (flags & 3) == 1: GENERIC_WRITE else: GENERIC_READ | GENERIC_WRITE
    let creation = if (flags & 0x200) != 0:
        if (flags & 0x400) != 0: CREATE_ALWAYS else: OPEN_ALWAYS
    else:
        OPEN_EXISTING
    win_alloc_fd(CreateFileW(wpath, access, FILE_SHARE_ALL, 0 as *mut u8, creation, FILE_ATTRIBUTE_NORMAL, 0))

pub fn rt_close(fd: i32) -> i32:
    if fd >= 0 and fd <= 2:
        return 0
    if fd < 0 or fd >= 256:
        return -6
    let h: i64 = rt_handles[fd]
    rt_handles[fd] = 0
    if h == 0:
        return -6
    if CloseHandle(h) == 0:
        return win_neg_error()
    0

// No fcntl on Windows: the descriptor flags it would set (O_NONBLOCK,
// FD_CLOEXEC) have no HANDLE equivalent here, so the call is unsupported
// and reports -1 (std.libc's fcntl seam; zlib's gz layer ignores it).
pub fn rt_fcntl(fd: i32, cmd: i32, arg: i32) -> i32:
    let _ = fd
    let _ = cmd
    let _ = arg
    -1

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
    var wpath: [4096]u16 = [0; 4096]
    let rc = win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096)
    if rc != 0:
        return rc
    var info: [64]u8 = [0; 64]
    if GetFileAttributesExW(&wpath as *const [4096]u16 as *const u16, 0, &raw mut info as *mut [64]u8 as *mut u8) == 0:
        return win_neg_error()
    let base = &raw const info as i64
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
    var wpath: [4096]u16 = [0; 4096]
    let rc = win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096)
    if rc != 0:
        return rc
    let attrs = GetFileAttributesW(&wpath as *const [4096]u16 as *const u16)
    if attrs == 0xffffffff:
        return win_neg_error()
    if (attrs & FILE_ATTRIBUTE_DIRECTORY) != 0:
        return 0o040755
    0o100644

pub fn rt_chmod(path: *const u8, mode: i32) -> i32:
    var wpath: [4096]u16 = [0; 4096]
    let rc = win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096)
    if rc != 0:
        return rc
    var attrs = GetFileAttributesW(&wpath as *const [4096]u16 as *const u16)
    if attrs == 0xffffffff:
        return win_neg_error()
    if (mode & 0o200) != 0:
        attrs = attrs & ~FILE_ATTRIBUTE_READONLY
    else:
        attrs = attrs | FILE_ATTRIBUTE_READONLY
    if SetFileAttributesW(&wpath as *const [4096]u16 as *const u16, attrs) == 0:
        return win_neg_error()
    0

pub fn rt_getcwd(buf: *mut u8, size: i64) -> i32:
    var wbuf: [4096]u16 = [0; 4096]
    let n = GetCurrentDirectoryW(4096, &raw mut wbuf as *mut [4096]u16 as *mut u16)
    if n == 0:
        return win_neg_error()
    // A directory that does not fit comes back as the size it needs, unwritten.
    if n >= 4096:
        return -WIN_ERANGE
    let len = win_utf16_to_utf8_buf(&wbuf as *const [4096]u16 as *const u16, buf, size)
    if len < 0: len else: 0

pub fn rt_mmap(size: i64) -> *mut u8:
    VirtualAlloc(0 as *mut u8, size as u64, MEM_COMMIT_RESERVE, PAGE_READWRITE)

pub fn rt_munmap(ptr: *mut u8, size: i64):
    let _ = size
    let _free = VirtualFree(ptr, 0, MEM_RELEASE)

pub fn rt_exit(code: i32) -> Never:
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

pub fn rt_fill_random(buf: *mut u8, len: u64):
    if SystemFunction036(buf, len as u32) == 0:
        ExitProcess(1)

// The UCRT streams (`#define stdin (__acrt_iob_func(0))`), as std.libc's
// libc_stdin/stdout/stderr hand them to fprintf and friends on every target.
pub fn rt_libc_stdin() -> *mut c_void:
    __acrt_iob_func(0 as u32)

pub fn rt_libc_stdout() -> *mut c_void:
    __acrt_iob_func(1 as u32)

pub fn rt_libc_stderr() -> *mut c_void:
    __acrt_iob_func(2 as u32)

// std.libc's POSIX seams (rt_core.w's with_libc_*) over the UCRT: errno is
// _errno(), fileno/isatty are the CRT's underscore spellings on CRT fds,
// rlimit has no equivalent (the main stack is fixed at link time: RLIMIT_STACK
// reads unlimited, a set is a no-op, other resources are refused), mkstemp
// and realpath are the Win32 temp-file and full-path calls.
@[link_name("_fileno")]
extern fn rt_ucrt_fileno(stream: *mut c_void) -> i32
@[link_name("_fseeki64")]
extern fn rt_ucrt_fseeki64(stream: *mut c_void, offset: i64, whence: i32) -> i32
@[link_name("_ftelli64")]
extern fn rt_ucrt_ftelli64(stream: *mut c_void) -> i64
@[link_name("_isatty")]
extern fn rt_ucrt_isatty(fd: i32) -> i32

pub fn rt_errno_ptr() -> *mut i32: rt_ucrt_errno()
pub fn rt_fileno(stream: *mut c_void) -> i32: rt_ucrt_fileno(stream)
pub fn rt_fseek(stream: *mut c_void, offset: i64, whence: i32) -> i32: rt_ucrt_fseeki64(stream, offset, whence)
pub fn rt_ftell(stream: *mut c_void) -> i64: rt_ucrt_ftelli64(stream)
pub fn rt_isatty(fd: i32) -> i32: rt_ucrt_isatty(fd)
pub fn rt_getrlimit(resource: i32, lim: *mut u8) -> i32: win_getrlimit(resource, lim)
pub fn rt_setrlimit(resource: i32, lim: *const u8) -> i32: win_setrlimit(resource, lim)
pub fn rt_mkstemp(template_path: *mut u8) -> i32: win_mkstemp(template_path)
pub fn rt_realpath(path: *const u8, resolved_path: *mut u8) -> *mut u8: win_realpath(path, resolved_path)

pub fn rt_fiber_page_size() -> i64:
    4096

pub fn rt_fiber_mmap_flags() -> i32:
    0

pub fn rt_fiber_fault_addr(info: *const u8) -> i64:
    let _ = info
    0

pub fn rt_fiber_reset_signal_handler(sig: i32):
    let _ = sig

// Arm the fiber stack's guard page. PAGE_GUARD raises STATUS_GUARD_PAGE_VIOLATION
// on first touch AND auto-commits the page, so the vectored handler has real stack
// to run its diagnostic on — the Windows analogue of POSIX sigaltstack.
pub fn rt_fiber_protect_guard(region: *mut u8, len: i64) -> Unit:
    var old: u32 = 0
    let _ = VirtualProtect(region, len as u64, PAGE_READWRITE | PAGE_GUARD, &raw mut old)

pub fn rt_fiber_install_signal_handlers(alt_stack: *mut u8, alt_stack_size: i64, handler: i64):
    let _ = alt_stack
    let _ = alt_stack_size
    let _ = AddVectoredExceptionHandler(1 as u32, handler as *mut u8)

// ── Directory walks ────────────────────────────────────────────────
// A walk converts the caller's UTF-8 path once and builds every path below
// it in UTF-16: a name FindFirstFileW returns goes back to Windows exactly as
// read, so each child is reached however it is spelled. (Round-tripping names
// through UTF-8 dropped every non-ASCII one, and would still lose a name
// holding an unpaired surrogate.) Only list_files_text's output is UTF-8.

// `parent` + "/" + `name` into `out`, which has room for `cap` units counting
// the NUL; no separator is added after one already there. 0, or -ENAMETOOLONG.
fn win_wpath_join(parent: *const u16, name: *const u16, out: *mut u16, cap: i64) -> i32:
    let parent_len = win_strlen16(parent)
    let name_len = win_strlen16(name)
    var at = parent_len
    let last: i32 = if parent_len > 0: win_u16_at(parent, parent_len - 1) else: 47
    let slash_len: i64 = if last == 47 or last == 92: 0 else: 1
    if parent_len + slash_len + name_len + 1 > cap:
        return -WIN_ENAMETOOLONG
    for i in 0..parent_len:
        win_put_u16(out, i, win_u16_at(parent, i))
    if slash_len == 1:
        win_put_u16(out, at, 47)
        at = at + 1
    for j in 0..name_len:
        win_put_u16(out, at + j, win_u16_at(name, j))
    win_put_u16(out, at + name_len, 0)
    0

fn win_is_dot_or_dotdot(name: *const u16) -> bool:
    if win_u16_at(name, 0) != 46:
        return false
    let second = win_u16_at(name, 1)
    second == 0 or (second == 46 and win_u16_at(name, 2) == 0)

// WIN32_FIND_DATAW.cFileName.
fn win_find_name(data: *const u8) -> *const u16: (data as i64 + 44) as *const u16

fn win_is_dir(wpath: *const u16) -> bool:
    let attrs = GetFileAttributesW(wpath)
    attrs != 0xffffffff and (attrs & FILE_ATTRIBUTE_DIRECTORY) != 0

fn win_mkdir_w(wpath: *const u16) -> i32:
    if CreateDirectoryW(wpath, 0 as *mut u8) == 0: win_neg_error() else: 0

fn win_unlink_w(wpath: *const u16) -> i32:
    if DeleteFileW(wpath) == 0: win_neg_error() else: 0

fn win_rmdir_w(wpath: *const u16) -> i32:
    if RemoveDirectoryW(wpath) == 0: win_neg_error() else: 0

pub fn rt_mkdir(path: *const u8, mode: i32) -> i32:
    let _ = mode
    var wpath: [4096]u16 = [0; 4096]
    let rc = win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096)
    if rc != 0: rc else: win_mkdir_w(&wpath as *const [4096]u16 as *const u16)

pub fn rt_unlink(path: *const u8) -> i32:
    var wpath: [4096]u16 = [0; 4096]
    let rc = win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096)
    if rc != 0: rc else: win_unlink_w(&wpath as *const [4096]u16 as *const u16)

pub fn rt_rmdir(path: *const u8) -> i32:
    var wpath: [4096]u16 = [0; 4096]
    let rc = win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096)
    if rc != 0: rc else: win_rmdir_w(&wpath as *const [4096]u16 as *const u16)

pub fn rt_rename(old_path: *const u8, new_path: *const u8) -> i32:
    var oldw: [4096]u16 = [0; 4096]
    var neww: [4096]u16 = [0; 4096]
    let old_rc = win_utf8_to_utf16_buf(old_path, &raw mut oldw as *mut [4096]u16 as *mut u16, 4096)
    if old_rc != 0:
        return old_rc
    let new_rc = win_utf8_to_utf16_buf(new_path, &raw mut neww as *mut [4096]u16 as *mut u16, 4096)
    if new_rc != 0:
        return new_rc
    if MoveFileExW(&oldw as *const [4096]u16 as *const u16, &neww as *const [4096]u16 as *const u16, MOVEFILE_REPLACE_EXISTING) == 0:
        return win_neg_error()
    0

// The directory `wpath` names, then each child's path built in `child` (the
// pattern first): one buffer per level, as FindFirstFileW is done with its
// pattern once it returns.
fn win_remove_tree_w(wpath: *const u16) -> i32:
    if not win_is_dir(wpath):
        return win_unlink_w(wpath)
    var star: [2]u16 = [42, 0]
    var child: [4096]u16 = [0; 4096]
    let child_ptr = &raw mut child as *mut [4096]u16 as *mut u16
    let join_rc = win_wpath_join(wpath, &star as *const [2]u16 as *const u16, child_ptr, 4096)
    if join_rc != 0:
        return join_rc
    var data: [600]u8 = [0; 600]
    let data_ptr = &raw mut data as *mut [600]u8 as *mut u8
    let h = FindFirstFileW(child_ptr as *const u16, data_ptr)
    if h != INVALID_HANDLE_VALUE:
        while true:
            let name = win_find_name(data_ptr as *const u8)
            if not win_is_dot_or_dotdot(name):
                let child_join = win_wpath_join(wpath, name, child_ptr, 4096)
                let rc = if child_join != 0: child_join else: win_remove_tree_w(child_ptr as *const u16)
                if rc != 0:
                    let _close = FindClose(h)
                    return rc
            if FindNextFileW(h, data_ptr) == 0:
                break
        let _close = FindClose(h)
    win_rmdir_w(wpath)

pub fn rt_remove_tree(path: *const u8) -> i32:
    var wpath: [4096]u16 = [0; 4096]
    let rc = win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096)
    if rc != 0: rc else: win_remove_tree_w(&wpath as *const [4096]u16 as *const u16)

fn win_copy_file(src: *const u16, dst: *const u16) -> i32:
    let in_fd = win_open_w(src, 0)
    if in_fd < 0:
        return in_fd
    let out_fd = win_open_w(dst, 1 | 0x200 | 0x400)
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

// As win_remove_tree_w: `child_src` holds the pattern first, then each child.
// A child whose path does not fit fails the copy (it was skipped silently).
fn win_copy_tree_w(src: *const u16, dst: *const u16) -> i32:
    if not win_is_dir(src):
        return win_copy_file(src, dst)
    let mkdir_rc = win_mkdir_w(dst)
    if mkdir_rc != 0 and not win_is_dir(dst):
        return mkdir_rc
    var star: [2]u16 = [42, 0]
    var child_src: [4096]u16 = [0; 4096]
    var child_dst: [4096]u16 = [0; 4096]
    let src_ptr = &raw mut child_src as *mut [4096]u16 as *mut u16
    let dst_ptr = &raw mut child_dst as *mut [4096]u16 as *mut u16
    let join_rc = win_wpath_join(src, &star as *const [2]u16 as *const u16, src_ptr, 4096)
    if join_rc != 0:
        return join_rc
    var data: [600]u8 = [0; 600]
    let data_ptr = &raw mut data as *mut [600]u8 as *mut u8
    let h = FindFirstFileW(src_ptr as *const u16, data_ptr)
    if h == INVALID_HANDLE_VALUE:
        return 0
    while true:
        let name = win_find_name(data_ptr as *const u8)
        if not win_is_dot_or_dotdot(name):
            var rc = win_wpath_join(src, name, src_ptr, 4096)
            if rc == 0:
                rc = win_wpath_join(dst, name, dst_ptr, 4096)
            if rc == 0:
                rc = win_copy_tree_w(src_ptr as *const u16, dst_ptr as *const u16)
            if rc != 0:
                let _close = FindClose(h)
                return rc
        if FindNextFileW(h, data_ptr) == 0:
            break
    let _close2 = FindClose(h)
    0

pub fn rt_copy_tree(src: *const u8, dst: *const u8) -> i32:
    var srcw: [4096]u16 = [0; 4096]
    var dstw: [4096]u16 = [0; 4096]
    let src_rc = win_utf8_to_utf16_buf(src, &raw mut srcw as *mut [4096]u16 as *mut u16, 4096)
    if src_rc != 0:
        return src_rc
    let dst_rc = win_utf8_to_utf16_buf(dst, &raw mut dstw as *mut [4096]u16 as *mut u16, 4096)
    if dst_rc != 0:
        return dst_rc
    win_copy_tree_w(&srcw as *const [4096]u16 as *const u16, &dstw as *const [4096]u16 as *const u16)

pub fn rt_symlink(target: *const u8, link_path: *const u8) -> i32:
    var targetw: [4096]u16 = [0; 4096]
    var linkw: [4096]u16 = [0; 4096]
    let target_rc = win_utf8_to_utf16_buf(target, &raw mut targetw as *mut [4096]u16 as *mut u16, 4096)
    if target_rc != 0:
        return target_rc
    let link_rc = win_utf8_to_utf16_buf(link_path, &raw mut linkw as *mut [4096]u16 as *mut u16, 4096)
    if link_rc != 0:
        return link_rc
    // SYMBOLIC_LINK_FLAG_DIRECTORY (1) for a directory target, plus
    // SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE (2).
    let flags: u32 = if win_is_dir(&targetw as *const [4096]u16 as *const u16): 3 else: 2
    if CreateSymbolicLinkW(&linkw as *const [4096]u16 as *const u16, &targetw as *const [4096]u16 as *const u16, flags) == 0:
        return win_neg_error()
    0

pub fn rt_readlink(path: *const u8) -> str:
    let _ = path
    win_empty_str()

fn win_empty_str() -> str:
    with_str_from_cstr(c"".ptr)

// The listed spelling of a child: `parent`, a "/" unless it already ends in
// a separator, and the name as UTF-8.
fn win_list_child_text(parent: &str, name: *const u16) -> str:
    let n = parent.len()
    let name_text = win_utf16_to_str(name)
    if n > 0 and (parent[n - 1] == 47 or parent[n - 1] == 92):
        return parent ++ name_text
    parent ++ "/" ++ name_text

// `wpath` is where the walk is; `path` is how the listing spells it.
fn win_list_files_walk(wpath: *const u16, path: &str, out: str) -> str:
    // Parity with the unix walk (a failed lstat returns `out`): a path that
    // does not exist lists nothing, a file lists itself, a directory lists
    // its tree. Before this, "not a directory" covered both cases, so a
    // missing directory listed its own name (#1081: the compiler's cleanup
    // listing an absent out/lib went down the append branch).
    let attrs = GetFileAttributesW(wpath)
    if attrs == 0xffffffff:
        return out
    if (attrs & FILE_ATTRIBUTE_DIRECTORY) == 0:
        return out ++ path ++ "\n"
    var result = out
    var star: [2]u16 = [42, 0]
    var child: [4096]u16 = [0; 4096]
    let child_ptr = &raw mut child as *mut [4096]u16 as *mut u16
    if win_wpath_join(wpath, &star as *const [2]u16 as *const u16, child_ptr, 4096) != 0:
        return result
    var data: [600]u8 = [0; 600]
    let data_ptr = &raw mut data as *mut [600]u8 as *mut u8
    let h = FindFirstFileW(child_ptr as *const u16, data_ptr)
    if h == INVALID_HANDLE_VALUE:
        return result
    while true:
        let name = win_find_name(data_ptr as *const u8)
        if not win_is_dot_or_dotdot(name):
            // Unreachable while Windows caps a path at MAX_PATH (260 units)
            // without the \\?\ prefix: a child past 4095 units could not
            // have been listed by FindFirstFileW.
            if win_wpath_join(wpath, name, child_ptr, 4096) == 0:
                let child_text = win_list_child_text(path, name)
                result = win_list_files_walk(child_ptr as *const u16, child_text, result)
        if FindNextFileW(h, data_ptr) == 0:
            break
    let _close = FindClose(h)
    result

// A path that is not UTF-8 names nothing, so it lists nothing, like a missing one.
pub fn rt_list_files(path: *const u8) -> str:
    var wpath: [4096]u16 = [0; 4096]
    if win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096) != 0:
        return win_empty_str()
    let path_text = with_str_from_cstr(path)
    win_list_files_walk(&wpath as *const [4096]u16 as *const u16, path_text, win_empty_str())

pub fn rt_access(path: *const u8, mode: i32) -> i32:
    let _ = mode
    var wpath: [4096]u16 = [0; 4096]
    let rc = win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096)
    if rc != 0:
        return rc
    if GetFileAttributesW(&wpath as *const [4096]u16 as *const u16) == 0xffffffff:
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
    let page_size = unsafe *((&raw const info as i64 + 4) as *const u32)
    let processors = unsafe *((&raw const info as i64 + 32) as *const u32)
    var mem: [64]u8 = [0 as u8; 64]
    unsafe *((&raw mut mem) as *mut [64]u8 as *mut u32) = 64 as u32
    var total: i64 = 0
    if GlobalMemoryStatusEx(&raw mut mem as *mut [64]u8 as *mut u8) != 0:
        total = unsafe *((&raw const mem as i64 + 8) as *const u64) as i64
    (unsafe *out).cpu_cores = if processors > 0: processors as i32 else: 1
    (unsafe *out).page_size = if page_size > 0: page_size as i64 else: 4096
    (unsafe *out).memory_total = total
    0

pub fn rt_sysinfo_os() -> str:
    with_str_from_cstr(c"Windows".ptr)

pub fn rt_sysinfo_arch() -> str:
    with_str_from_cstr(c"x86_64".ptr)

pub fn rt_getenv(name: *const u8) -> *const u8:
    var wname: [1024]u16 = [0; 1024]
    var wvalue: [16384]u16 = [0; 16384]
    if win_utf8_to_utf16_buf(name, &raw mut wname as *mut [1024]u16 as *mut u16, 1024) != 0:
        return 0 as *const u8
    let wname_ptr = &wname as *const [1024]u16 as *const u16
    var value = &raw mut wvalue as *mut [16384]u16 as *mut u16
    var value_cap: u32 = 16384
    var n = GetEnvironmentVariableW(wname_ptr, value, value_cap)
    // A value that does not fit comes back as the units it needs (its NUL
    // counted), unwritten: read it again into pages that size. One variable
    // holds up to 32767 units; the loop covers a value that grew in between.
    var big: *mut u8 = 0 as *mut u8
    var big_bytes: i64 = 0
    while n >= value_cap:
        if big as i64 != 0:
            rt_munmap(big, big_bytes)
        value_cap = n
        big_bytes = n * 2
        big = rt_mmap(big_bytes)
        if big as i64 == 0:
            return 0 as *const u8
        value = big as *mut u16
        n = GetEnvironmentVariableW(wname_ptr, value, value_cap)
    if n == 0:
        if big as i64 != 0:
            rt_munmap(big, big_bytes)
        return 0 as *const u8
    // Each returned value gets its own allocation so retained `env()`/
    // `with_getenv_str` results never alias. Linux/darwin satisfy this for
    // free because libc `getenv` hands out stable per-variable `environ`
    // pointers; Windows `GetEnvironmentVariableW` copies into a caller buffer,
    // so a single shared static buffer would make every retained result alias
    // the last read. The buffer holds the value's UTF-8 and its NUL.
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
    let len = win_utf16_utf8_len(value as *const u16)
    let buf = rt_mmap(len + 1)
    if buf as i64 != 0:
        let _ = win_utf16_to_utf8_buf(value as *const u16, buf, len + 1)
    if big as i64 != 0:
        rt_munmap(big, big_bytes)
    buf as *const u8

pub fn rt_gethostname(name: *mut u8, len: u64) -> i32:
    var wname: [256]u16 = [0; 256]
    var n: u32 = 256
    if GetComputerNameW(&raw mut wname as *mut [256]u16 as *mut u16, &raw mut n) == 0:
        return -1
    if win_utf16_to_utf8_buf(&wname as *const [256]u16 as *const u16, name, len as i64) < 0: -1 else: 0

pub fn pthread_self() -> i64:
    GetCurrentThreadId() as i64

// The template's text is not used: the name comes from GetTempFileNameW in
// the user's temp directory (a "/tmp/..." template names no directory here),
// written back as UTF-8 into a buffer this assumes holds 1024 bytes, as the
// ANSI version did (the compiler's hold 4096). A name that does not fit fails
// and leaves no file behind.
fn win_mkstemp(template_path: *mut u8) -> i32:
    if template_path as i64 == 0:
        return -1
    var dir: [1024]u16 = [0; 1024]
    var name: [1024]u16 = [0; 1024]
    let prefix: [5]u16 = [119, 105, 116, 104, 0]
    let n = GetTempPathW(1024, &raw mut dir as *mut [1024]u16 as *mut u16)
    if n == 0 or n >= 1024:
        return -1
    let name_ptr = &name as *const [1024]u16 as *const u16
    if GetTempFileNameW(&dir as *const [1024]u16 as *const u16, &prefix as *const [5]u16 as *const u16, 0, &raw mut name as *mut [1024]u16 as *mut u16) == 0:
        return -1
    if win_utf16_to_utf8_buf(name_ptr, template_path, 1024) < 0:
        let _ = DeleteFileW(name_ptr)
        return -1
    win_open_w(name_ptr, 2)

// POSIX gives `resolved_path` PATH_MAX bytes. The smallest among With's
// targets is Darwin's 1024, which is also what the compiler passes
// (ClangBridge's with_cimport_realpath); the ANSI version assumed 4096.
fn win_realpath(path: *const u8, resolved_path: *mut u8) -> *mut u8:
    if path as i64 == 0 or resolved_path as i64 == 0:
        return 0 as *mut u8
    var wpath: [4096]u16 = [0; 4096]
    var wfull: [4096]u16 = [0; 4096]
    if win_utf8_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096) != 0:
        return 0 as *mut u8
    let n = GetFullPathNameW(&wpath as *const [4096]u16 as *const u16, 4096, &raw mut wfull as *mut [4096]u16 as *mut u16, 0 as *mut *mut u16)
    if n == 0 or n >= 4096:
        return 0 as *mut u8
    if win_utf16_to_utf8_buf(&wfull as *const [4096]u16 as *const u16, resolved_path, 1024) < 0:
        return 0 as *mut u8
    resolved_path

// UTF-16 never takes more units than its UTF-8 takes bytes, so buffers sized
// from the text always fit: no value is cut short (Windows allows 32767
// units in one variable; the fixed buffer here stopped at 8191).
fn win_setenv(name: &str, value: &str) -> i32:
    let wname = with_alloc((name.len() + 1) * 2)
    let wvalue = with_alloc((value.len() + 1) * 2)
    var rc = win_str_to_utf16_buf(name, wname as *mut u16, name.len() + 1)
    if rc == 0:
        rc = win_str_to_utf16_buf(value, wvalue as *mut u16, value.len() + 1)
    if rc == 0:
        let value_ptr = if value.len() == 0: 0 as *const u16 else: wvalue as *const u16
        if SetEnvironmentVariableW(wname as *const u16, value_ptr) == 0:
            rc = win_neg_error()
    with_free(wname)
    with_free(wvalue)
    rc

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

// #679/#702 on Windows: a process's peak working set, the counterpart of
// ru_maxrss (bytes). PROCESS_MEMORY_COUNTERS is cb and PageFaultCount (u32
// each), then PeakWorkingSetSize at offset 8; 72 bytes on 64-bit Windows.
var win_last_child_maxrss: i64 = 0

fn win_process_peak_rss(process: i64) -> i64:
    var counters: [72]u8 = [0 as u8; 72]
    let base = (&raw mut counters) as *mut [72]u8 as *mut u8
    unsafe *(base as *mut u32) = 72 as u32
    if K32GetProcessMemoryInfo(process, base, 72 as u32) == 0:
        return 0
    unsafe *((base as i64 + 8) as *const i64)

fn win_wait_process_slot(slot: i32, timeout_ms: i32, consume: bool) -> i32:
    if slot <= 0 or slot >= 256:
        return -1
    let h: i64 = process_handles[slot]
    if h == 0:
        return -1
    let wait_ms = if timeout_ms > 0: timeout_ms as u32 else: INFINITE
    let wr = WaitForSingleObject(h, wait_ms)
    if wr == WAIT_TIMEOUT:
        let _term = TerminateProcess(h, CAPTURE_TIMEOUT_RC as u32)
        let _wait = WaitForSingleObject(h, INFINITE)
        win_last_child_maxrss = win_process_peak_rss(h)
        if consume:
            let _close = CloseHandle(h)
            process_handles[slot] = 0
            process_ids[slot] = 0
        return CAPTURE_TIMEOUT_RC
    if wr != WAIT_OBJECT_0:
        return win_neg_error()
    var code: u32 = 1 as u32
    let _ = GetExitCodeProcess(h, &raw mut code)
    win_last_child_maxrss = win_process_peak_rss(h)
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
    // argv[0] is spelled with backslashes. CreateProcessW resolves the
    // program from the command line, and a RELATIVE path with forward
    // slashes ("out/tmp/x.exe") fails there with ERROR_FILE_NOT_FOUND while
    // "out\tmp\x.exe" and any absolute spelling succeed (probe: rc=-2 / 0 /
    // 0). Every compiler-built binary is launched by such a relative path
    // (`with run`, `with test`, `with -e`), which is why all three died on
    // native Windows (#1081). Programs that parse their own argv[0] --
    // cmd.exe reads a forward-slash one as switches -- get the same relief.
    var program = true
    while offset < len and pos < cap - 4:
        if pos > 0:
            unsafe *((out as i64 + pos * 2) as *mut u16) = 32 as u16
            pos = pos + 1
        unsafe *((out as i64 + pos * 2) as *mut u16) = 34 as u16
        pos = pos + 1
        var slash_count: i64 = 0
        while offset < len:
            var ch = unsafe *((blob as i64 + offset) as *const u8)
            if ch == 0:
                break
            if program and ch == 47:
                ch = 92 as u8
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
            // The argument's UTF-8 is decoded, not widened byte by byte; no
            // byte of a multibyte sequence is a quote or a backslash.
            let n = win_utf8_seq_len(ch)
            if n == 0 or offset + n > len:
                return -WIN_EILSEQ
            let cp = win_utf8_decode((blob as i64 + offset) as *const u8, n)
            if cp < 0:
                return -WIN_EILSEQ
            win_put_cp16(out, pos, cp)
            pos = pos + win_utf16_units(cp)
            offset = offset + n
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
        program = false
    unsafe *((out as i64 + pos * 2) as *mut u16) = 0 as u16
    0

fn win_make_security_attrs(out: *mut u8):
    unsafe *(out as *mut u32) = 24 as u32
    unsafe *((out as i64 + 8) as *mut i64) = 0
    unsafe *((out as i64 + 16) as *mut i32) = 1

// Opens a redirect target into `handle`: INVALID_HANDLE_VALUE when
// CreateFileW fails, as the child has always been given. A path that cannot
// be converted is an error instead, returned as a negative errno: it names no
// file, and opening a different one would redirect the child somewhere else.
fn win_open_redirect(path: &str, write_mode: bool, handle: *mut i64) -> i32:
    var wpath: [4096]u16 = [0; 4096]
    let rc = win_str_to_utf16_buf(path, &raw mut wpath as *mut [4096]u16 as *mut u16, 4096)
    if rc != 0:
        return rc
    var sec: [24]u8 = [0; 24]
    win_make_security_attrs(&raw mut sec as *mut [24]u8 as *mut u8)
    let access = if write_mode: GENERIC_WRITE else: GENERIC_READ
    let creation = if write_mode: CREATE_ALWAYS else: OPEN_EXISTING
    unsafe *handle = CreateFileW(&wpath as *const [4096]u16 as *const u16, access, FILE_SHARE_ALL, &raw mut sec as *mut [24]u8 as *mut u8, creation, FILE_ATTRIBUTE_NORMAL, 0)
    0

fn win_close_redirect(opened: bool, handle: i64):
    if opened and handle != 0 and handle != INVALID_HANDLE_VALUE:
        let _ = CloseHandle(handle)

fn win_spawn_argv(args: &str, stdout_path: &str, stderr_path: &str, stdin_path: &str, cwd: &str, wait: bool, timeout_ms: i32) -> i32:
    let data = win_str_data(args)
    let cmd = with_alloc(32768 * 2)
    if cmd as i64 == 0:
        return -12
    let cmd_rc = win_build_command_line(data, args.len(), cmd as *mut u16, 32768)
    // Windows' own limit on a command line; past it the spawn fails, and
    // says why (#1916) instead of returning -1 alone.
    if cmd_rc == -1:
        let _ = rt_write(2, c"error: a command line longer than Windows allows (32767 UTF-16 units)\n".ptr, 70)
    if cmd_rc != 0:
        with_free(cmd)
        return cmd_rc
    var startup: [104]u8 = [0; 104]
    var proc_info: [24]u8 = [0; 24]
    unsafe *((&raw mut startup) as *mut [104]u8 as *mut u32) = 104
    var inherit = 0
    var stdin_h = GetStdHandle(STD_INPUT_HANDLE)
    var stdout_h = GetStdHandle(STD_OUTPUT_HANDLE)
    var stderr_h = GetStdHandle(STD_ERROR_HANDLE)
    let has_stdin = stdin_path.len() > 0
    let has_stdout = stdout_path.len() > 0
    let has_stderr = stderr_path.len() > 0
    var rc = 0
    var opened_in = false
    var opened_out = false
    var opened_err = false
    if has_stdin:
        rc = win_open_redirect(stdin_path, false, &raw mut stdin_h)
        opened_in = rc == 0
        inherit = 1
    if rc == 0 and has_stdout:
        rc = win_open_redirect(stdout_path, true, &raw mut stdout_h)
        opened_out = rc == 0
        inherit = 1
    if rc == 0 and has_stderr:
        rc = win_open_redirect(stderr_path, true, &raw mut stderr_h)
        opened_err = rc == 0
        inherit = 1
    var cwdw: [4096]u16 = [0; 4096]
    var cwdp = 0 as *const u16
    if rc == 0 and cwd.len() > 0:
        rc = win_str_to_utf16_buf(cwd, &raw mut cwdw as *mut [4096]u16 as *mut u16, 4096)
        cwdp = &cwdw as *const [4096]u16 as *const u16
    if rc != 0:
        with_free(cmd)
        win_close_redirect(opened_in, stdin_h)
        win_close_redirect(opened_out, stdout_h)
        win_close_redirect(opened_err, stderr_h)
        return rc
    if inherit != 0:
        let startup_base = (&raw mut startup) as *mut [104]u8 as i64
        unsafe *((startup_base + 60) as *mut u32) = 0x00000100
        unsafe *((startup_base + 80) as *mut i64) = stdin_h
        unsafe *((startup_base + 88) as *mut i64) = stdout_h
        unsafe *((startup_base + 96) as *mut i64) = stderr_h
    // PWD follows the child's directory, as the unix spawners arrange by
    // setenv("PWD", cwd) after chdir in the forked child: the driver reads PWD
    // for its working directory (project root, absolutized paths, embed
    // anchoring), and a child given lpCurrentDirectory otherwise inherits the
    // parent's stale PWD and roots at the parent's project -- a test's nested
    // `with build` in its case directory built the repo's graph (#1082). Set
    // in the parent for the inherited block, restored after the spawn.
    var old_pwd = ""
    var pwd_set = false
    if cwd.len() > 0:
        let prev = rt_getenv(c"PWD".ptr)
        if prev as i64 != 0:
            old_pwd = with_str_from_cstr(prev)
        let _pwd = win_setenv("PWD", cwd)
        pwd_set = true
    let ok = CreateProcessW(0 as *const u16, cmd as *mut u16, 0 as *mut u8, 0 as *mut u8, inherit, 0, 0 as *mut u8, cwdp, &raw mut startup as *mut [104]u8 as *mut u8, &raw mut proc_info as *mut [24]u8 as *mut u8)
    if pwd_set:
        let _restore = win_setenv("PWD", old_pwd)
    with_free(cmd)
    win_close_redirect(opened_in, stdin_h)
    win_close_redirect(opened_out, stdout_h)
    win_close_redirect(opened_err, stderr_h)
    if ok == 0:
        return win_neg_error()
    let process_h = unsafe *((&raw const proc_info as i64 + 0) as *const i64)
    let thread_h = unsafe *((&raw const proc_info as i64 + 8) as *const i64)
    let pid = unsafe *((&raw const proc_info as i64 + 16) as *const i32)
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

pub fn rt_compat_install_interrupt_handlers():
    let _ = 0

pub fn rt_compat_raise_stack_limit():
    let _ = 0

pub fn rt_set_process_memory_limit_bytes(limit: i64) -> i32:
    let _ = limit
    0

pub fn rt_compat_interrupt_requested() -> i32:
    0

pub fn rt_compat_exec_binary(path: &str) -> i32:
    // A path too long for the blob is refused, not cut short.
    if path.len() > 4095:
        return -WIN_ENAMETOOLONG
    var blob: [4096]u8 = [0; 4096]
    let data = win_str_data(path)
    var i: i64 = 0
    while i < path.len():
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

// #921: nonblocking reap probe — -2 while the child still runs; on death
// consumes the slot and returns the exit code (no termination on probe).
pub fn rt_compat_exec_try_wait(pid: i32) -> i32:
    if pid <= 0 or pid >= 256:
        return -1
    let h: i64 = process_handles[pid]
    if h == 0:
        return -1
    let wr = WaitForSingleObject(h, 0 as u32)
    if wr == WAIT_TIMEOUT:
        return -2
    if wr != WAIT_OBJECT_0:
        return win_neg_error()
    var code: u32 = 1 as u32
    let _ = GetExitCodeProcess(h, &raw mut code)
    win_last_child_maxrss = win_process_peak_rss(h)
    let _close = CloseHandle(h)
    process_handles[pid] = 0
    process_ids[pid] = 0
    code as i32

// #679/#702 stubs: RSS accounting is POSIX-only for now (#807-adjacent).
pub fn rt_compat_exec_child_maxrss() -> i64: win_last_child_maxrss

pub fn rt_compat_self_maxrss() -> i64: win_process_peak_rss(GetCurrentProcess())

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
@[link_name("bind")]
extern fn rt_libc_bind(s: i64, addr: *const u8, namelen: i32) -> i32
extern fn listen(s: i64, backlog: i32) -> i32
extern fn accept(s: i64, addr: *mut u8, addrlen: *mut i32) -> i64
extern fn getsockname(s: i64, addr: *mut u8, addrlen: *mut i32) -> i32
@[link_name("send")]
extern fn rt_libc_send(s: i64, buf: *const u8, len: i32, flags: i32) -> i32
@[link_name("recv")]
extern fn rt_libc_recv(s: i64, buf: *mut u8, len: i32, flags: i32) -> i32
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
    unsafe *(s as *const str as *const *const u8)

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
        unsafe *((out as i64 + i) as *mut u8) = s[i] as u8
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
        let c = host[i] as i32
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

pub fn with_net_tcp_connect(host: &str, port: i32) -> i32:
    rt_net_connect_any(host, port, 1, 6)

pub fn with_net_udp_connect(host: &str, port: i32) -> i32:
    rt_net_connect_any(host, port, 2, 17)

fn rt_net_bind_inaddr_any(fd: i64, port: i32) -> i32:
    var sa: [16]u8 = [0 as u8; 16]
    sa[0] = 2 as u8
    sa[2] = ((port >> 8) & 255) as u8
    sa[3] = (port & 255) as u8
    rt_libc_bind(fd, &sa as *const [16]u8 as *const u8, 16)

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

pub fn with_net_send(sock: i32, data: &str) -> i64:
    let ptr = rt_net_str_data(data)
    let total = data.len()
    var written: i64 = 0
    while written < total:
        let chunk = total - written
        let r = rt_libc_send(sock as i64, (ptr as i64 + written) as *const u8, chunk as i32, 0)
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
    let r = rt_libc_recv(sock as i64, buf, max_len as i32, 0)
    if r <= 0:
        with_free(buf)
        return rt_net_empty_str()
    let out = with_str_from_bytes(buf as *const u8, r as i64)
    with_free(buf)
    out

pub fn with_net_close(sock: i32) -> i32:
    closesocket(sock as i64)

// ── Foreign-state domain rows (ruling §52, spec §16.2b.14) ────────────────
// Every foreign call above is described here; the `runtime-domain-audit`
// lane (build/compiler.w) refuses a foreign extern without a row. "Unknown
// effect means invalidate" (§38): a Win32 or Winsock row says nothing, so
// it invalidates every declared domain, the three libc domains: the C
// standard does not describe those calls, and a row it cannot justify is
// never `preserves`. The UCRT rows follow the C standard as the POSIX
// backends do: C11 7.5p3 (errno: any library function may set it; the
// `_errno` accessor is the macro's lvalue, 7.5p2), C11 7.22.4.6 (environ:
// altered by _putenv/SetEnvironmentVariable only), C11 7.11.1.1 (locale:
// setlocale only, never called here). The process-global state a Win32
// call alters — the handle table, the working directory, the vectored
// handlers, child processes — is no domain: no safe view is presented over
// it, so the runtime-domain-audit lane records each call's effect by its C
// symbol instead (build/compiler.w comp_process_state_alterers; spec
// §16.2b.14, D76).
c facade win32:
    domain errno thread
    domain environ process
    domain locale process
    fn GetLastError
    fn GetStdHandle
    fn ReadFile
    fn WriteFile
    fn CreateFileW
    fn CloseHandle
    fn SetFilePointerEx
    fn GetCurrentDirectoryW
    fn SetCurrentDirectoryW
    fn VirtualAlloc
    fn VirtualFree
    fn ExitProcess
    fn QueryPerformanceCounter
    fn QueryPerformanceFrequency
    fn GetSystemTimeAsFileTime
    fn Sleep
    fn GetCurrentProcessId
    fn OpenProcess
    fn TerminateProcess
    fn CreateThread
    fn WaitForSingleObject
    fn GetExitCodeProcess
    fn K32GetProcessMemoryInfo
    fn CreateProcessW
    fn GetEnvironmentVariableW
    fn SetEnvironmentVariableW
    fn GetFileAttributesW
    fn SetFileAttributesW
    fn GetFileAttributesExW
    fn CreateDirectoryW
    fn DeleteFileW
    fn RemoveDirectoryW
    fn MoveFileExW
    fn FindFirstFileW
    fn FindNextFileW
    fn FindClose
    fn CreateSymbolicLinkW
    fn RtlCaptureStackBackTrace
    fn GetCurrentProcess
    fn SymSetOptions
    fn SymInitialize
    fn SymFromAddr
    fn SymGetLineFromAddr64
    fn GetSystemInfo
    fn GlobalMemoryStatusEx
    fn GetComputerNameW
    fn SystemFunction036
    fn VirtualProtect
    fn AddVectoredExceptionHandler
    fn GetCurrentThreadId
    fn GetTempPathW
    fn GetTempFileNameW
    fn GetFullPathNameW
    fn __acrt_iob_func
        preserves domain environ
        preserves domain locale
    fn rt_ucrt_errno
        preserves domain errno
        preserves domain environ
        preserves domain locale
    fn rt_ucrt_fileno
        preserves domain environ
        preserves domain locale
    fn rt_ucrt_fseeki64
        preserves domain environ
        preserves domain locale
    fn rt_ucrt_ftelli64
        preserves domain environ
        preserves domain locale
    fn rt_ucrt_isatty
        preserves domain environ
        preserves domain locale
    // The argv setup calls are the CRT's startup interface, not the C
    // standard's, so their rows say nothing.
    fn rt_ucrt_configure_wide_argv
    fn rt_ucrt_argc_ptr
    fn rt_ucrt_wargv_ptr
    fn WSAStartup
    fn socket
    fn connect
    fn rt_libc_bind
        preserves domain environ
        preserves domain locale
    fn listen
    fn accept
    fn getsockname
    fn rt_libc_send
        preserves domain environ
        preserves domain locale
    fn rt_libc_recv
        preserves domain environ
        preserves domain locale
    fn closesocket
    fn getaddrinfo
    fn freeaddrinfo
