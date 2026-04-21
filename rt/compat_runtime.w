// rt/compat_runtime.w -- compiler-only runtime functions.
// These supplement rt_core.w for the compiler build (lld path).
// The embedded stdlib functions are appended by generate_embedded_stdlib.py.
//
// No libc dependency: uses with_alloc/with_free/with_memcpy/with_memset
// from rt_core.w. All other extern fns are libSystem (stable Darwin ABI).

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> void
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> void
extern fn with_memset(dst: *mut u8, val: i32, len: i64) -> void
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

var interrupt_flag: i32 = 0
var active_child_pgid: i32 = 0

fn make_str(ptr: *const u8, len: i64) -> str:
    var raw: [2]i64 = [ptr as i64, len]
    let p = &raw as *const str
    unsafe: *p

fn store_i64(base: i64, offset: i64, value: i64):
    unsafe: *((base + offset) as *mut i64) = value

fn load_u64(base: i64, offset: i64) -> u64:
    unsafe: *((base + offset) as *const u64)

fn signal_bit(signo: i32) -> u32:
    if signo <= 0:
        return 0 as u32
    (1 as u32) << ((signo - 1) as u32)

fn str_to_c_buf(s: str) -> *mut u8:
    let out = with_alloc(s.len() + 1)
    if out as i64 == 0:
        return 0 as *mut u8
    if s.len() > 0:
        let sp = &s as *const *const u8
        let data = unsafe: *sp
        with_memcpy(out, data, s.len())
    unsafe: *((out as i64 + s.len()) as *mut u8) = 0
    out

fn restore_default_signal_handler(signo: i32):
    var sa: [16]u8 = [0 as u8; 16]
    let sa_base = (&mut sa) as *mut [16]u8 as i64
    with_memset(sa_base as *mut u8, 0, SIGACTION_SIZE)
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
            if errp as i64 != 0 and unsafe: *errp == EINTR:
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

@[c_export("with_setenv_str")]
pub fn setenv_str(name: str, value: str) -> i32:
    let name_buf = str_to_c_buf(name)
    if name_buf as i64 == 0:
        return -1
    let value_buf = str_to_c_buf(value)
    if value_buf as i64 == 0:
        with_free(name_buf)
        return -1
    let rc = setenv(name_buf as *const u8, value_buf as *const u8, 1)
    with_free(name_buf)
    with_free(value_buf)
    rc

@[c_export("with_install_interrupt_handlers")]
pub fn install_interrupt_handlers():
    var sa: [16]u8 = [0 as u8; 16]
    let sa_base = (&mut sa) as *mut [16]u8 as i64
    with_memset(sa_base as *mut u8, 0, SIGACTION_SIZE)
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
        with_free(buf)
        let errp = __error()
        if errp as i64 != 0:
            unsafe: *errp = EINTR
        return -1
    let rc = run_shell_command(buf as *const u8)
    with_free(buf)
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
    let cmd = with_alloc(total + 1)
    if cmd as i64 == 0:
        return -1
    let archive_ptr = unsafe: *(&archive as *const *const u8)
    let dest_ptr = unsafe: *(&dest as *const *const u8)
    var pos: i64 = 0
    with_memcpy((cmd as i64 + pos) as *mut u8, prefix, prefix_len)
    pos = pos + prefix_len
    if archive.len() > 0:
        with_memcpy((cmd as i64 + pos) as *mut u8, archive_ptr, archive.len())
        pos = pos + archive.len()
    with_memcpy((cmd as i64 + pos) as *mut u8, middle, middle_len)
    pos = pos + middle_len
    if dest.len() > 0:
        with_memcpy((cmd as i64 + pos) as *mut u8, dest_ptr, dest.len())
        pos = pos + dest.len()
    with_memcpy((cmd as i64 + pos) as *mut u8, suffix, suffix_len)
    unsafe: *((cmd as i64 + total) as *mut u8) = 0
    if interrupt_flag != 0:
        with_free(cmd)
        return -1
    let rc = run_shell_command(cmd as *const u8)
    with_free(cmd)
    if rc == 0:
        return 0
    -1
