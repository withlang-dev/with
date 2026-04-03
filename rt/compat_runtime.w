// rt/compat_runtime.w -- tiny compiler/runtime compatibility surface needed on
// the helpers-based path before the full runtime is pure With.

extern fn strlen(s: *const u8) -> i64
extern fn malloc(size: u64) -> *mut u8
extern fn free(ptr: *mut u8) -> void
extern fn memcpy(dst: *mut u8, src: *const u8, n: u64) -> *mut u8
extern fn memset(dst: *mut u8, c: i32, n: u64) -> *mut u8
extern fn getenv(name: *const u8) -> *const u8
extern fn setenv(name: *const u8, value: *const u8, overwrite: i32) -> i32
extern fn sigaction(sig: i32, act: *const u8, old_act: *mut u8) -> i32
extern fn sigprocmask(how: i32, set: *const u32, old: *mut u32) -> i32
extern fn kill(pid: i32, sig: i32) -> i32
extern fn fork() -> i32
extern fn setpgid(pid: i32, pgid: i32) -> i32
extern fn execv(path: *const u8, argv: *const *const u8) -> i32
extern fn waitpid(pid: i32, status: *mut i32, options: i32) -> i32
extern fn getrlimit(resource: i32, lim: *mut u8) -> i32
extern fn setrlimit(resource: i32, lim: *const u8) -> i32
extern fn gethostname(name: *mut u8, len: u64) -> i32
extern fn _exit(code: i32) -> void
extern fn __error() -> *mut i32

let SIGINT: i32 = 2
let SIGQUIT: i32 = 3
let SIGTERM: i32 = 15
let SIGHUP: i32 = 1
let SIG_BLOCK: i32 = 1
let SIG_SETMASK: i32 = 3
let RLIMIT_STACK: i32 = 3
let RLIM_INFINITY: u64 = 9223372036854775807 as u64
let EINTR: i32 = 4
let SIGACTION_SIZE: i64 = 16
let SIGACTION_OFF_HANDLER: i64 = 0
let RLIMIT_SIZE: i64 = 16
let RLIMIT_OFF_CUR: i64 = 0
let RLIMIT_OFF_MAX: i64 = 8

var saved_argc: i32 = 0
var saved_argv_raw: i64 = 0
var interrupt_flag: i32 = 0
var active_child_pgid: i32 = 0

fn make_str(ptr: *const u8, len: i64) -> str:
    var raw: [2]i64 = [ptr as i64, len]
    let p = &raw as *const str
    *p

fn store_i64(base: i64, offset: i64, value: i64):
    *((base + offset) as *mut i64) = value

fn load_u64(base: i64, offset: i64) -> u64:
    *((base + offset) as *const u64)

fn signal_bit(signo: i32) -> u32:
    if signo <= 0:
        return 0 as u32
    (1 as u32) << ((signo - 1) as u32)

fn str_to_c_buf(s: str) -> *mut u8:
    let out = malloc((s.len() + 1) as u64)
    if out as i64 == 0:
        return 0 as *mut u8
    if s.len() > 0:
        let sp = &s as *const *const u8
        let _ = memcpy(out, *sp, s.len() as u64)
    *((out as i64 + s.len()) as *mut u8) = 0
    out

fn clone_c_str(s: *const u8) -> str:
    if s as i64 == 0:
        return ""
    let len = strlen(s)
    let out = malloc((len + 1) as u64)
    if out as i64 == 0:
        return ""
    let _ = memcpy(out, s, len as u64)
    *((out as i64 + len) as *mut u8) = 0
    make_str(out as *const u8, len)

fn restore_default_signal_handler(signo: i32):
    var sa: [16]u8 = [0 as u8; 16]
    let sa_base = (&mut sa) as *mut [16]u8 as i64
    let _ = memset(sa_base as *mut u8, 0, SIGACTION_SIZE as u64)
    let _ = sigaction(signo, sa_base as *const u8, 0 as *mut u8)

fn block_interrupt_signals(prev_mask: *mut u32) -> i32:
    var blocked: u32 = 0 as u32
    blocked = blocked | signal_bit(SIGINT)
    blocked = blocked | signal_bit(SIGTERM)
    blocked = blocked | signal_bit(SIGHUP)
    sigprocmask(SIG_BLOCK, &blocked as *const u32, prev_mask)

fn restore_signal_mask(prev_mask: *const u32):
    if prev_mask as i64 == 0:
        return
    let _ = sigprocmask(SIG_SETMASK, prev_mask, 0 as *mut u32)

fn wait_for_child_process(pid: i32) -> i32:
    var status: i32 = -1
    while true:
        let waited = waitpid(pid, &mut status, 0)
        if waited == pid:
            let termsig = status & 0x7f
            if termsig == 0:
                return (status >> 8) & 0xff
            if termsig != 0x7f:
                return 128 + termsig
            return status
        if waited < 0:
            let errp = __error()
            if errp as i64 != 0 and *errp == EINTR:
                continue
            return -1

fn run_shell_command(cmd: *const u8) -> i32:
    var prev_mask: u32 = 0 as u32
    let mask_rc = block_interrupt_signals(&mut prev_mask)
    let pid = fork()
    if pid == 0:
        if mask_rc == 0:
            restore_signal_mask(&prev_mask as *const u32)
        let _ = setpgid(0, 0)
        restore_default_signal_handler(SIGINT)
        restore_default_signal_handler(SIGTERM)
        restore_default_signal_handler(SIGHUP)
        restore_default_signal_handler(SIGQUIT)
        var argv: [5]*const u8 = [0 as *const u8; 5]
        argv[0] = "sh" as *const u8
        argv[1] = "-c" as *const u8
        argv[2] = cmd
        argv[3] = 0 as *const u8
        argv[4] = 0 as *const u8
        let _ = execv("/bin/sh" as *const u8, (&argv) as *const [5]*const u8 as *const *const u8)
        _exit(127)
    if pid < 0:
        if mask_rc == 0:
            restore_signal_mask(&prev_mask as *const u32)
        return -1

    active_child_pgid = pid
    let _ = setpgid(pid, pid)
    if mask_rc == 0:
        restore_signal_mask(&prev_mask as *const u32)
    let rc = wait_for_child_process(pid)
    active_child_pgid = 0
    rc

fn interrupt_signal_handler(signo: i32):
    interrupt_flag = 1
    if active_child_pgid > 0:
        let _ = kill(0 - active_child_pgid, signo)
    _exit(128 + signo)

@[c_export("with_str_from_cstr")]
pub fn str_from_cstr(s: *const u8) -> str:
    if s as i64 == 0:
        return ""
    make_str(s, strlen(s))

fn i64_to_buf(n: i64, buf: *mut u8) -> i64:
    var tmp: [21]u8 = [0 as u8; 21]
    var pos: i32 = 20
    var neg: i32 = 0
    var un: u64 = 0
    if n < 0:
        neg = 1
        un = ((0 - (n + 1)) as u64) + 1
    else:
        un = n as u64
    if un == 0:
        tmp[pos] = 48
        pos = pos - 1
    else:
        while un > 0:
            tmp[pos] = (48 + (un % 10) as u8) as u8
            un = un / 10
            pos = pos - 1
    if neg != 0:
        tmp[pos] = 45
        pos = pos - 1
    let len = 20 - pos as i64
    var i: i64 = 0
    while i < len:
        *((buf as i64 + i) as *mut u8) = tmp[(pos + 1) as i64 + i]
        i = i + 1
    len

@[c_export("with_i64_to_str")]
pub fn i64_to_str(n: i64) -> str:
    var buf: [24]u8 = [0 as u8; 24]
    let len = i64_to_buf(n, &buf as *mut u8)
    let out = malloc((len + 1) as u64)
    if out as i64 == 0:
        return ""
    var i: i64 = 0
    while i < len:
        *((out as i64 + i) as *mut u8) = buf[i]
        i = i + 1
    *((out as i64 + len) as *mut u8) = 0
    make_str(out as *const u8, len)

@[c_export("with_bool_to_str")]
pub fn bool_to_str(b: i32) -> str:
    if b != 0:
        return "true"
    "false"

@[c_export("with_runtime_set_argv")]
pub fn runtime_set_argv(argc: i32, argv: *const *const u8):
    saved_argc = argc
    saved_argv_raw = argv as i64

@[c_export("with_arg_count")]
pub fn arg_count() -> i32:
    saved_argc

@[c_export("with_arg_at")]
pub fn arg_at(idx: i32) -> str:
    if idx < 0 or idx >= saved_argc or saved_argv_raw == 0:
        return ""
    let s = *((saved_argv_raw + idx as i64 * 8) as *const *const u8)
    if s as i64 == 0:
        return ""
    make_str(s, strlen(s))

@[c_export("with_getenv_str")]
pub fn getenv_str(name: str) -> str:
    let name_buf = str_to_c_buf(name)
    if name_buf as i64 == 0:
        return ""
    let val = getenv(name_buf as *const u8)
    free(name_buf)
    if val as i64 == 0:
        return ""
    make_str(val, strlen(val))

@[c_export("with_setenv_str")]
pub fn setenv_str(name: str, value: str) -> i32:
    let name_buf = str_to_c_buf(name)
    if name_buf as i64 == 0:
        return -1
    let value_buf = str_to_c_buf(value)
    if value_buf as i64 == 0:
        free(name_buf)
        return -1
    let rc = setenv(name_buf as *const u8, value_buf as *const u8, 1)
    free(name_buf)
    free(value_buf)
    rc

@[c_export("with_install_interrupt_handlers")]
pub fn install_interrupt_handlers():
    var sa: [16]u8 = [0 as u8; 16]
    let sa_base = (&mut sa) as *mut [16]u8 as i64
    let _ = memset(sa_base as *mut u8, 0, SIGACTION_SIZE as u64)
    store_i64(sa_base, SIGACTION_OFF_HANDLER, interrupt_signal_handler as i64)
    let _ = sigaction(SIGINT, sa_base as *const u8, 0 as *mut u8)
    let _ = sigaction(SIGTERM, sa_base as *const u8, 0 as *mut u8)
    let _ = sigaction(SIGHUP, sa_base as *const u8, 0 as *mut u8)

@[c_export("with_raise_stack_limit")]
pub fn raise_stack_limit():
    var lim: [16]u8 = [0 as u8; 16]
    let lim_base = (&mut lim) as *mut [16]u8 as i64
    if getrlimit(RLIMIT_STACK, lim_base as *mut u8) != 0:
        return
    var want: u64 = (64 * 1024 * 1024) as u64
    let lim_max = load_u64(lim_base, RLIMIT_OFF_MAX)
    if lim_max != RLIM_INFINITY and want > lim_max:
        want = lim_max
    let lim_cur = load_u64(lim_base, RLIMIT_OFF_CUR)
    if want > lim_cur:
        store_i64(lim_base, RLIMIT_OFF_CUR, want as i64)
        let _ = setrlimit(RLIMIT_STACK, lim_base as *const u8)

@[c_export("with_interrupt_requested")]
pub fn interrupt_requested() -> i32:
    interrupt_flag

@[c_export("with_system")]
pub fn system_str(cmd: str) -> i32:
    let buf = str_to_c_buf(cmd)
    if buf as i64 == 0:
        return -1
    if interrupt_flag != 0:
        free(buf)
        let errp = __error()
        if errp as i64 != 0:
            *errp = EINTR
        return -1
    let rc = run_shell_command(buf as *const u8)
    free(buf)
    rc

@[c_export("with_extract_tgz")]
pub fn extract_tgz(archive: str, dest: str) -> i32:
    let prefix = "tar xzf '" as *const u8
    let middle = "' -C '" as *const u8
    let suffix = "'" as *const u8
    let prefix_len = 9 as i64
    let middle_len = 7 as i64
    let suffix_len = 1 as i64
    let total = prefix_len + archive.len() + middle_len + dest.len() + suffix_len
    let cmd = malloc((total + 1) as u64)
    if cmd as i64 == 0:
        return -1
    let archive_ptr = *(&archive as *const *const u8)
    let dest_ptr = *(&dest as *const *const u8)
    var pos: i64 = 0
    let _ = memcpy((cmd as i64 + pos) as *mut u8, prefix, prefix_len as u64)
    pos = pos + prefix_len
    if archive.len() > 0:
        let _ = memcpy((cmd as i64 + pos) as *mut u8, archive_ptr, archive.len() as u64)
        pos = pos + archive.len()
    let _ = memcpy((cmd as i64 + pos) as *mut u8, middle, middle_len as u64)
    pos = pos + middle_len
    if dest.len() > 0:
        let _ = memcpy((cmd as i64 + pos) as *mut u8, dest_ptr, dest.len() as u64)
        pos = pos + dest.len()
    let _ = memcpy((cmd as i64 + pos) as *mut u8, suffix, suffix_len as u64)
    *((cmd as i64 + total) as *mut u8) = 0
    if interrupt_flag != 0:
        free(cmd)
        return -1
    let rc = run_shell_command(cmd as *const u8)
    free(cmd)
    if rc == 0:
        return 0
    -1

@[c_export("with_sysinfo_os")]
pub fn sysinfo_os() -> str:
    "Macos"

@[c_export("with_sysinfo_arch")]
pub fn sysinfo_arch() -> str:
    "armv8"

@[c_export("with_sysinfo_hostname")]
pub fn sysinfo_hostname() -> str:
    var buf: [256]u8 = [0 as u8; 256]
    let buf_ptr = (&mut buf) as *mut [256]u8 as *mut u8
    if gethostname(buf_ptr, 256 as u64) != 0:
        return "unknown"
    buf[255] = 0
    clone_c_str(buf_ptr as *const u8)
