// rt/compat_runtime.w -- compiler-only runtime functions.
// These supplement rt_core.w for the compiler build (lld path).
// Embedded stdlib source data is generated as compiler.EmbeddedStdlibData.
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
extern fn execvp(file: *const u8, argv: *const *const u8) -> i32
extern fn waitpid(pid: i32, status: *mut i32, options: i32) -> i32
extern fn chdir(path: *const u8) -> i32
extern fn __open(path: *const u8, flags: i32, mode: i32) -> i32
extern fn dup2(oldfd: i32, newfd: i32) -> i32
extern fn close(fd: i32) -> i32
extern fn getrlimit(resource: i32, lim: *mut u8) -> i32
extern fn setrlimit(resource: i32, lim: *const u8) -> i32
extern fn _exit(code: i32) -> void
extern fn __error() -> *mut i32
extern fn with_clock_nanos() -> i64
extern fn with_usleep(usecs: i32) -> i32

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
let WNOHANG: i32 = 1
let CAPTURE_TIMEOUT_RC: i32 = 124

var interrupt_flag: i32 = 0
var active_child_pgid: i32 = 0

fn make_str(ptr: *const u8, len: i64) -> str:
    var raw: [2]i64 = [ptr as i64, len]
    let p = &raw as *const str
    unsafe *p

fn store_i64(base: i64, offset: i64, value: i64):
    unsafe *((base + offset) as *mut i64) = value

fn load_u64(base: i64, offset: i64) -> u64:
    unsafe *((base + offset) as *const u64)

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
        let data = unsafe *sp
        with_memcpy(out, data, s.len())
    unsafe *((out as i64 + s.len()) as *mut u8) = 0
    out

fn restore_default_signal_handler(signo: i32):
    var sa: [16]u8 = [0 as u8; 16]
    let sa_base = (&raw mut sa) as *mut [16]u8 as i64
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
        let waited = waitpid(pid, &raw mut status, 0)
        if waited == pid:
            let termsig = status & 0x7f
            if termsig == 0:
                return (status >> 8) & 0xff
            if termsig != 0x7f:
                return 128 + termsig
            return status
        if waited < 0:
            let errp = __error()
            if errp as i64 != 0 and unsafe *errp == EINTR:
                continue
            return -1

fn wait_for_child_process_timeout(pid: i32, timeout_ms: i32) -> i32:
    var status: i32 = -1
    let start_ns = with_clock_nanos()
    let timeout_ns = timeout_ms as i64 * 1000000
    while true:
        let waited = waitpid(pid, &raw mut status, WNOHANG)
        if waited == pid:
            let termsig = status & 0x7f
            if termsig == 0:
                return (status >> 8) & 0xff
            if termsig != 0x7f:
                return 128 + termsig
            return status
        if waited < 0:
            let errp = __error()
            if errp as i64 != 0 and unsafe *errp == EINTR:
                continue
            return -1
        if timeout_ms > 0 and with_clock_nanos() - start_ns >= timeout_ns:
            let _ = kill(-pid, SIGTERM)
            let _sleep = with_usleep(10000)
            let waited_after_term = waitpid(pid, &raw mut status, WNOHANG)
            if waited_after_term != pid:
                let _kill = kill(-pid, 9)
                let _ = waitpid(pid, &raw mut status, 0)
            return CAPTURE_TIMEOUT_RC
        let _sleep_poll = with_usleep(10000)

fn run_binary_direct(path: *const u8) -> i32:
    var prev_mask: u32 = 0 as u32
    let mask_rc = block_interrupt_signals(&raw mut prev_mask)
    let pid = fork()
    if pid == 0:
        if mask_rc == 0:
            restore_signal_mask(&prev_mask as *const u32)
        let _ = setpgid(0, 0)
        restore_default_signal_handler(SIGINT)
        restore_default_signal_handler(SIGTERM)
        restore_default_signal_handler(SIGHUP)
        restore_default_signal_handler(SIGQUIT)
        var argv: [2]*const u8 = [0 as *const u8; 2]
        argv[0] = path
        argv[1] = 0 as *const u8
        let _ = execv(path, (&argv) as *const [2]*const u8 as *const *const u8)
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

fn argv_blob_count(blob: *const u8, len: i64) -> i32:
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

fn run_argv_direct_cwd(blob: *const u8, len: i64, cwd: *const u8) -> i32:
    let argc = argv_blob_count(blob, len)
    if argc <= 0 or argc >= 256:
        return -1
    var prev_mask: u32 = 0 as u32
    let mask_rc = block_interrupt_signals(&raw mut prev_mask)
    let pid = fork()
    if pid == 0:
        if mask_rc == 0:
            restore_signal_mask(&prev_mask as *const u32)
        let _ = setpgid(0, 0)
        restore_default_signal_handler(SIGINT)
        restore_default_signal_handler(SIGTERM)
        restore_default_signal_handler(SIGHUP)
        restore_default_signal_handler(SIGQUIT)
        if cwd as i64 != 0:
            if chdir(cwd) != 0:
                _exit(127)
            let _ = setenv("PWD" as *const u8, cwd, 1)
        var argv: [256]*const u8 = [0 as *const u8; 256]
        var argi = 0
        var offset: i64 = 0
        while offset < len and argi < 255:
            argv[argi] = (blob as i64 + offset) as *const u8
            argi += 1
            while offset < len and (unsafe *((blob as i64 + offset) as *const u8)) != 0:
                offset += 1
            offset += 1
        argv[argi] = 0 as *const u8
        let _ = execvp(argv[0], (&argv) as *const [256]*const u8 as *const *const u8)
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

fn run_argv_direct(blob: *const u8, len: i64) -> i32:
    run_argv_direct_cwd(blob, len, 0 as *const u8)

fn redirect_fd_to_path(path: *const u8, fd: i32) -> i32:
    let out_fd = __open(path, 1 | 0x200 | 0x400, 0o644)
    if out_fd < 0:
        return -1
    if dup2(out_fd, fd) < 0:
        let _ = close(out_fd)
        return -1
    let _ = close(out_fd)
    0

fn redirect_fd_from_path(path: *const u8, fd: i32) -> i32:
    let in_fd = __open(path, 0, 0)
    if in_fd < 0:
        return -1
    if dup2(in_fd, fd) < 0:
        let _ = close(in_fd)
        return -1
    let _ = close(in_fd)
    0

fn run_argv_capture(blob: *const u8, len: i64, stdout_path: *const u8, stderr_path: *const u8, timeout_ms: i32) -> i32:
    run_argv_capture_cwd(blob, len, stdout_path, stderr_path, timeout_ms, 0 as *const u8)

fn spawn_argv_capture(blob: *const u8, len: i64, stdout_path: *const u8, stderr_path: *const u8) -> i32:
    let argc = argv_blob_count(blob, len)
    if argc <= 0 or argc >= 256:
        return -1
    var prev_mask: u32 = 0 as u32
    let mask_rc = block_interrupt_signals(&raw mut prev_mask)
    let pid = fork()
    if pid == 0:
        if mask_rc == 0:
            restore_signal_mask(&prev_mask as *const u32)
        let _ = setpgid(0, 0)
        restore_default_signal_handler(SIGINT)
        restore_default_signal_handler(SIGTERM)
        restore_default_signal_handler(SIGHUP)
        restore_default_signal_handler(SIGQUIT)
        if redirect_fd_to_path(stdout_path, 1) != 0:
            _exit(127)
        if redirect_fd_to_path(stderr_path, 2) != 0:
            _exit(127)
        var argv: [256]*const u8 = [0 as *const u8; 256]
        var argi = 0
        var offset: i64 = 0
        while offset < len and argi < 255:
            argv[argi] = (blob as i64 + offset) as *const u8
            argi += 1
            while offset < len and (unsafe *((blob as i64 + offset) as *const u8)) != 0:
                offset += 1
            offset += 1
        argv[argi] = 0 as *const u8
        let _ = execvp(argv[0], (&argv) as *const [256]*const u8 as *const *const u8)
        _exit(127)
    if pid < 0:
        if mask_rc == 0:
            restore_signal_mask(&prev_mask as *const u32)
        return -1
    let _ = setpgid(pid, pid)
    if mask_rc == 0:
        restore_signal_mask(&prev_mask as *const u32)
    pid

fn run_argv_capture_input(blob: *const u8, len: i64, stdout_path: *const u8, stderr_path: *const u8, timeout_ms: i32, stdin_path: *const u8) -> i32:
    let argc = argv_blob_count(blob, len)
    if argc <= 0 or argc >= 256:
        return -1
    var prev_mask: u32 = 0 as u32
    let mask_rc = block_interrupt_signals(&raw mut prev_mask)
    let pid = fork()
    if pid == 0:
        if mask_rc == 0:
            restore_signal_mask(&prev_mask as *const u32)
        let _ = setpgid(0, 0)
        restore_default_signal_handler(SIGINT)
        restore_default_signal_handler(SIGTERM)
        restore_default_signal_handler(SIGHUP)
        restore_default_signal_handler(SIGQUIT)
        if redirect_fd_from_path(stdin_path, 0) != 0:
            _exit(127)
        if redirect_fd_to_path(stdout_path, 1) != 0:
            _exit(127)
        if redirect_fd_to_path(stderr_path, 2) != 0:
            _exit(127)
        var argv: [256]*const u8 = [0 as *const u8; 256]
        var argi = 0
        var offset: i64 = 0
        while offset < len and argi < 255:
            argv[argi] = (blob as i64 + offset) as *const u8
            argi += 1
            while offset < len and (unsafe *((blob as i64 + offset) as *const u8)) != 0:
                offset += 1
            offset += 1
        argv[argi] = 0 as *const u8
        let _ = execvp(argv[0], (&argv) as *const [256]*const u8 as *const *const u8)
        _exit(127)
    if pid < 0:
        if mask_rc == 0:
            restore_signal_mask(&prev_mask as *const u32)
        return -1

    active_child_pgid = pid
    let _ = setpgid(pid, pid)
    if mask_rc == 0:
        restore_signal_mask(&prev_mask as *const u32)
    let rc = wait_for_child_process_timeout(pid, timeout_ms)
    active_child_pgid = 0
    rc

fn run_argv_capture_cwd(blob: *const u8, len: i64, stdout_path: *const u8, stderr_path: *const u8, timeout_ms: i32, cwd: *const u8) -> i32:
    let argc = argv_blob_count(blob, len)
    if argc <= 0 or argc >= 256:
        return -1
    var prev_mask: u32 = 0 as u32
    let mask_rc = block_interrupt_signals(&raw mut prev_mask)
    let pid = fork()
    if pid == 0:
        if mask_rc == 0:
            restore_signal_mask(&prev_mask as *const u32)
        let _ = setpgid(0, 0)
        restore_default_signal_handler(SIGINT)
        restore_default_signal_handler(SIGTERM)
        restore_default_signal_handler(SIGHUP)
        restore_default_signal_handler(SIGQUIT)
        if redirect_fd_to_path(stdout_path, 1) != 0:
            _exit(127)
        if redirect_fd_to_path(stderr_path, 2) != 0:
            _exit(127)
        if cwd as i64 != 0:
            if chdir(cwd) != 0:
                _exit(127)
            let _ = setenv("PWD" as *const u8, cwd, 1)
        var argv: [256]*const u8 = [0 as *const u8; 256]
        var argi = 0
        var offset: i64 = 0
        while offset < len and argi < 255:
            argv[argi] = (blob as i64 + offset) as *const u8
            argi += 1
            while offset < len and (unsafe *((blob as i64 + offset) as *const u8)) != 0:
                offset += 1
            offset += 1
        argv[argi] = 0 as *const u8
        let _ = execvp(argv[0], (&argv) as *const [256]*const u8 as *const *const u8)
        _exit(127)
    if pid < 0:
        if mask_rc == 0:
            restore_signal_mask(&prev_mask as *const u32)
        return -1

    active_child_pgid = pid
    let _ = setpgid(pid, pid)
    if mask_rc == 0:
        restore_signal_mask(&prev_mask as *const u32)
    let rc = wait_for_child_process_timeout(pid, timeout_ms)
    active_child_pgid = 0
    rc

fn interrupt_signal_handler(signo: i32):
    interrupt_flag = 1
    if active_child_pgid > 0:
        let _ = kill(-active_child_pgid, signo)
    _exit(128 + signo)

pub fn with_setenv_str(name: str, value: str) -> i32:
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

pub fn with_install_interrupt_handlers():
    var sa: [16]u8 = [0 as u8; 16]
    let sa_base = (&raw mut sa) as *mut [16]u8 as i64
    with_memset(sa_base as *mut u8, 0, SIGACTION_SIZE)
    store_i64(sa_base, SIGACTION_OFF_HANDLER, interrupt_signal_handler as i64)
    let _ = sigaction(SIGINT, sa_base as *const u8, 0 as *mut u8)
    let _ = sigaction(SIGTERM, sa_base as *const u8, 0 as *mut u8)
    let _ = sigaction(SIGHUP, sa_base as *const u8, 0 as *mut u8)

pub fn with_raise_stack_limit():
    var lim: [16]u8 = [0 as u8; 16]
    let lim_base = (&raw mut lim) as *mut [16]u8 as i64
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

pub fn with_interrupt_requested() -> i32:
    interrupt_flag

pub fn with_exec_binary(path: str) -> i32:
    let buf = str_to_c_buf(path)
    if buf as i64 == 0:
        return -1
    if interrupt_flag != 0:
        with_free(buf)
        let errp = __error()
        if errp as i64 != 0:
            unsafe *errp = EINTR
        return -1
    let rc = run_binary_direct(buf as *const u8)
    with_free(buf)
    rc

pub fn with_exec_argv(args: str) -> i32:
    let buf = str_to_c_buf(args)
    if buf as i64 == 0:
        return -1
    if interrupt_flag != 0:
        with_free(buf)
        let errp = __error()
        if errp as i64 != 0:
            unsafe *errp = EINTR
        return -1
    let rc = run_argv_direct(buf as *const u8, args.len())
    with_free(buf)
    rc

pub fn with_exec_argv_cwd(args: str, cwd: str) -> i32:
    let arg_buf = str_to_c_buf(args)
    if arg_buf as i64 == 0:
        return -1
    let cwd_buf = str_to_c_buf(cwd)
    if cwd_buf as i64 == 0:
        with_free(arg_buf)
        return -1
    if interrupt_flag != 0:
        with_free(arg_buf)
        with_free(cwd_buf)
        let errp = __error()
        if errp as i64 != 0:
            unsafe *errp = EINTR
        return -1
    let rc = run_argv_direct_cwd(arg_buf as *const u8, args.len(), cwd_buf as *const u8)
    with_free(arg_buf)
    with_free(cwd_buf)
    rc

pub fn with_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32:
    let arg_buf = str_to_c_buf(args)
    if arg_buf as i64 == 0:
        return -1
    let out_buf = str_to_c_buf(stdout_path)
    if out_buf as i64 == 0:
        with_free(arg_buf)
        return -1
    let err_buf = str_to_c_buf(stderr_path)
    if err_buf as i64 == 0:
        with_free(arg_buf)
        with_free(out_buf)
        return -1
    if interrupt_flag != 0:
        with_free(arg_buf)
        with_free(out_buf)
        with_free(err_buf)
        let errp = __error()
        if errp as i64 != 0:
            unsafe *errp = EINTR
        return -1
    let rc = run_argv_capture(arg_buf as *const u8, args.len(), out_buf as *const u8, err_buf as *const u8, timeout_ms)
    with_free(arg_buf)
    with_free(out_buf)
    with_free(err_buf)
    rc

pub fn with_exec_argv_capture_input(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, stdin_path: str) -> i32:
    let arg_buf = str_to_c_buf(args)
    if arg_buf as i64 == 0:
        return -1
    let out_buf = str_to_c_buf(stdout_path)
    if out_buf as i64 == 0:
        with_free(arg_buf)
        return -1
    let err_buf = str_to_c_buf(stderr_path)
    if err_buf as i64 == 0:
        with_free(arg_buf)
        with_free(out_buf)
        return -1
    let in_buf = str_to_c_buf(stdin_path)
    if in_buf as i64 == 0:
        with_free(arg_buf)
        with_free(out_buf)
        with_free(err_buf)
        return -1
    if interrupt_flag != 0:
        with_free(arg_buf)
        with_free(out_buf)
        with_free(err_buf)
        with_free(in_buf)
        let errp = __error()
        if errp as i64 != 0:
            unsafe *errp = EINTR
        return -1
    let rc = run_argv_capture_input(arg_buf as *const u8, args.len(), out_buf as *const u8, err_buf as *const u8, timeout_ms, in_buf as *const u8)
    with_free(arg_buf)
    with_free(out_buf)
    with_free(err_buf)
    with_free(in_buf)
    rc

pub fn with_exec_argv_capture_cwd(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> i32:
    let arg_buf = str_to_c_buf(args)
    if arg_buf as i64 == 0:
        return -1
    let out_buf = str_to_c_buf(stdout_path)
    if out_buf as i64 == 0:
        with_free(arg_buf)
        return -1
    let err_buf = str_to_c_buf(stderr_path)
    if err_buf as i64 == 0:
        with_free(arg_buf)
        with_free(out_buf)
        return -1
    let cwd_buf = str_to_c_buf(cwd)
    if cwd_buf as i64 == 0:
        with_free(arg_buf)
        with_free(out_buf)
        with_free(err_buf)
        return -1
    if interrupt_flag != 0:
        with_free(arg_buf)
        with_free(out_buf)
        with_free(err_buf)
        with_free(cwd_buf)
        let errp = __error()
        if errp as i64 != 0:
            unsafe *errp = EINTR
        return -1
    let rc = run_argv_capture_cwd(arg_buf as *const u8, args.len(), out_buf as *const u8, err_buf as *const u8, timeout_ms, cwd_buf as *const u8)
    with_free(arg_buf)
    with_free(out_buf)
    with_free(err_buf)
    with_free(cwd_buf)
    rc

pub fn with_exec_argv_capture_spawn(args: str, stdout_path: str, stderr_path: str) -> i32:
    let arg_buf = str_to_c_buf(args)
    if arg_buf as i64 == 0:
        return -1
    let out_buf = str_to_c_buf(stdout_path)
    if out_buf as i64 == 0:
        with_free(arg_buf)
        return -1
    let err_buf = str_to_c_buf(stderr_path)
    if err_buf as i64 == 0:
        with_free(arg_buf)
        with_free(out_buf)
        return -1
    if interrupt_flag != 0:
        with_free(arg_buf)
        with_free(out_buf)
        with_free(err_buf)
        let errp = __error()
        if errp as i64 != 0:
            unsafe *errp = EINTR
        return -1
    let pid = spawn_argv_capture(arg_buf as *const u8, args.len(), out_buf as *const u8, err_buf as *const u8)
    with_free(arg_buf)
    with_free(out_buf)
    with_free(err_buf)
    pid

pub fn with_exec_wait(pid: i32, timeout_ms: i32) -> i32:
    if pid <= 0:
        return -1
    active_child_pgid = pid
    let rc = wait_for_child_process_timeout(pid, timeout_ms)
    active_child_pgid = 0
    rc
