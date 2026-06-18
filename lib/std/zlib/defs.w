// std.zlib.defs — shared definitions for migrated PCRE2

pub fn is_alpha(c: i32) -> bool {
    (c >= 65 and c <= 90) or (c >= 97 and c <= 122)
}
pub fn is_digit(c: i32) -> bool {
    c >= 48 and c <= 57
}
pub fn is_space(c: i32) -> bool {
    c == 32 or c == 9 or c == 10 or c == 13 or c == 12 or c == 11
}
pub fn is_alnum(c: i32) -> bool {
    is_alpha(c) or is_digit(c)
}
pub fn is_upper(c: i32) -> bool {
    c >= 65 and c <= 90
}
pub fn is_lower(c: i32) -> bool {
    c >= 97 and c <= 122
}
pub fn is_xdigit(c: i32) -> bool {
    (c >= 48 and c <= 57) or (c >= 65 and c <= 70) or (c >= 97 and c <= 102)
}
pub fn is_print(c: i32) -> bool {
    c >= 32 and c <= 126
}
pub fn to_lower(c: i32) -> i32 {
    if c >= 65 and c <= 90 { c + 32 } else { c }
}
pub fn to_upper(c: i32) -> i32 {
    if c >= 97 and c <= 122 { c - 32 } else { c }
}
pub extern fn strlen(s: *const i8) -> i64
pub extern fn strcmp(a: *const i8, b: *const i8) -> i32
pub extern fn strncmp(a: *const i8, b: *const i8, n: i64) -> i32
pub extern fn strchr(s: *const i8, c: i32) -> *mut i8
pub extern fn memchr(s: *const c_void, c: i32, n: i64) -> *mut c_void
pub extern fn isalpha(c: i32) -> i32
pub extern fn isdigit(c: i32) -> i32
pub extern fn isalnum(c: i32) -> i32
pub extern fn isspace(c: i32) -> i32
pub extern fn isupper(c: i32) -> i32
pub extern fn islower(c: i32) -> i32
pub extern fn isxdigit(c: i32) -> i32
pub extern fn isprint(c: i32) -> i32
pub extern fn isgraph(c: i32) -> i32
pub extern fn ispunct(c: i32) -> i32
pub extern fn iscntrl(c: i32) -> i32
pub extern fn tolower(c: i32) -> i32
pub extern fn toupper(c: i32) -> i32
pub extern fn sqrt(x: f64) -> f64
pub extern fn pow(base: f64, exp: f64) -> f64
pub extern fn floor(x: f64) -> f64
pub extern fn ceil(x: f64) -> f64
pub extern fn round(x: f64) -> f64
pub extern fn sin(x: f64) -> f64
pub extern fn cos(x: f64) -> f64
pub extern fn tan(x: f64) -> f64
pub extern fn log(x: f64) -> f64
pub extern fn log10(x: f64) -> f64
pub extern fn exp(x: f64) -> f64
pub extern fn fabs(x: f64) -> f64
pub extern fn fmod(x: f64, y: f64) -> f64
pub extern fn asin(x: f64) -> f64
pub extern fn acos(x: f64) -> f64
pub extern fn atan(x: f64) -> f64
pub extern fn atan2(y: f64, x: f64) -> f64

pub type c_void = opaque
pub type c_char = i8
pub type c_short = i16
pub type c_ushort = u16
pub type c_int = i32
pub type c_uint = u32
pub type c_long = i64
pub type c_ulong = u64
pub type c_longlong = i64
pub type c_ulonglong = u64
pub type c_longdouble = f64
pub extern fn with_clz(x: i32) -> i32
pub extern fn with_ctz(x: i32) -> i32
pub extern fn with_popcount(x: i32) -> i32
pub extern fn with_bswap16(x: u16) -> u16
pub extern fn with_bswap32(x: u32) -> u32
pub extern fn with_bswap64(x: u64) -> u64
pub extern fn with_clzl(x: i64) -> i32
pub extern fn with_clzll(x: i64) -> i32
pub extern fn with_ctzl(x: i64) -> i32
pub extern fn with_ctzll(x: i64) -> i32
pub extern fn with_abs(x: i32) -> i32
pub extern fn with_alloc(size: i64) -> *i8
pub extern fn with_alloc_zeroed(count: i64, size: i64) -> *i8
pub extern fn with_realloc(ptr: *i8, old_size: i64, new_size: i64) -> *i8
pub extern fn with_free(ptr: *i8) -> Unit
pub extern fn with_memcpy(dst: *i8, src: *i8, n: i64) -> *i8
pub extern fn with_memmove(dst: *i8, src: *i8, n: i64) -> *i8
pub extern fn with_memset(ptr: *i8, c: i32, n: i64) -> *i8
pub extern fn with_memcmp(a: *i8, b: *i8, n: i64) -> i32
pub extern fn with_va_start(ap: *mut i8) -> Unit
pub extern fn with_va_end(ap: *mut i8) -> Unit

// PCRE2 string constants (from pcre2_internal.h macros)
pub let STRING_MARK: *const u8 = "MARK"
pub let STRING_DEFINE: *const u8 = "DEFINE"
pub let STRING_VERSION: *const u8 = "VERSION"
pub let STRING_WEIRD_STARTWORD: *const u8 = "[:<:]]"
pub let STRING_WEIRD_ENDWORD: *const u8 = "[:>:]]"

pub type max_align_t = c_longdouble

pub type z_size_t = c_ulong

pub type Byte = u8

pub type uInt = c_uint

pub type uLong = c_ulong

pub type Bytef = u8

pub type charf = c_char

pub type intf = c_int

pub type uIntf = c_uint

pub type uLongf = c_ulong

pub type voidpc = *const c_void

pub type voidpf = *mut c_void

pub type voidp = *mut c_void

pub type z_crc_t = c_uint

pub type alloc_func = unsafe extern "C" fn(*mut c_void, c_uint, c_uint) -> *mut c_void

pub type free_func = unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit

pub type internal_state { strm: *mut z_stream_s = null, status: c_int = 0, pending_buf: *mut u8 = null, pending_buf_size: c_ulong = 0, pending_out: *mut u8 = null, pending: c_ulong = 0, wrap: c_int = 0, gzhead: *mut gz_header_s = null, gzindex: c_ulong = 0, method: u8 = 0, last_flush: c_int = 0, w_size: c_uint = 0, w_bits: c_uint = 0, w_mask: c_uint = 0, window: *mut u8 = null, window_size: c_ulong = 0, prev: *mut c_ushort = null, head: *mut c_ushort = null, ins_h: c_uint = 0, hash_size: c_uint = 0, hash_bits: c_uint = 0, hash_mask: c_uint = 0, hash_shift: c_uint = 0, block_start: c_long = 0, match_length: c_uint = 0, prev_match: c_uint = 0, match_available: c_int = 0, strstart: c_uint = 0, match_start: c_uint = 0, lookahead: c_uint = 0, prev_length: c_uint = 0, max_chain_length: c_uint = 0, max_lazy_match: c_uint = 0, level: c_int = 0, strategy: c_int = 0, good_match: c_uint = 0, nice_match: c_int = 0, dyn_ltree: [573]ct_data_s, dyn_dtree: [61]ct_data_s, bl_tree: [39]ct_data_s, l_desc: tree_desc_s, d_desc: tree_desc_s, bl_desc: tree_desc_s, bl_count: [16]c_ushort = [0 as c_ushort; 16], heap: [573]c_int = [0 as c_int; 573], heap_len: c_int = 0, heap_max: c_int = 0, depth: [573]u8 = [0 as u8; 573], sym_buf: *mut u8 = null, lit_bufsize: c_uint = 0, sym_next: c_uint = 0, sym_end: c_uint = 0, opt_len: c_ulong = 0, static_len: c_ulong = 0, matches: c_uint = 0, insert: c_uint = 0, bi_buf: c_ushort = 0, bi_valid: c_int = 0, bi_used: c_int = 0, high_water: c_ulong = 0, slid: c_int = 0 }
impl Copy for internal_state

pub type z_stream_s { next_in: *mut u8 = null, avail_in: c_uint = 0, total_in: c_ulong = 0, next_out: *mut u8 = null, avail_out: c_uint = 0, total_out: c_ulong = 0, msg: *mut i8 = null, state: *mut internal_state = null, zalloc: unsafe extern "C" fn(*mut c_void, c_uint, c_uint) -> *mut c_void, zfree: unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit, opaque_: *mut c_void = null, data_type: c_int = 0, adler: c_ulong = 0, reserved: c_ulong = 0 }
impl Copy for z_stream_s

pub type z_stream = z_stream_s

pub type z_streamp = *mut z_stream_s

pub type gz_header_s { text: c_int = 0, time: c_ulong = 0, xflags: c_int = 0, os: c_int = 0, extra: *mut u8 = null, extra_len: c_uint = 0, extra_max: c_uint = 0, name: *mut u8 = null, name_max: c_uint = 0, comment: *mut u8 = null, comm_max: c_uint = 0, hcrc: c_int = 0, done: c_int = 0 }
impl Copy for gz_header_s

pub type gz_header = gz_header_s

pub type gz_headerp = *mut gz_header_s

pub type in_func = unsafe extern "C" fn(*mut c_void, *mut *mut u8) -> c_uint

pub type out_func = unsafe extern "C" fn(*mut c_void, *mut u8, c_uint) -> c_int

pub type gzFile = *mut gzFile_s

pub type gzFile_s { have: c_uint = 0, next: *mut u8 = null, pos: c_longlong = 0 }
impl Copy for gzFile_s

pub type uch = u8

pub type uchf = u8

pub type ush = c_ushort

pub type ushf = c_ushort

pub type ulg = c_ulong

pub let HAVE_UNISTD_H: c_int = 1
pub let USE_CLANG_TYPES: c_int = 0
pub let USE_CLANG_STDDEF: c_int = 0
pub let USER_ADDR_NULL: c_ulonglong = (0 as c_ulonglong)
pub let USE_CLANG_STDARG: c_int = 0
pub let RENAME_SECLUDE: c_int = 0x00000001
pub let RENAME_SWAP: c_int = 0x00000002
pub let RENAME_EXCL: c_int = 0x00000004
pub let RENAME_RESERVED1: c_int = 0x00000008
pub let RENAME_NOFOLLOW_ANY: c_int = 0x00000010
pub let RENAME_RESOLVE_BENEATH: c_int = 0x00000020
pub let SEEK_SET: c_int = 0
pub let SEEK_CUR: c_int = 1
pub let SEEK_END: c_int = 2
pub let SEEK_HOLE: c_int = 3
pub let SEEK_DATA: c_int = 4
pub let BUFSIZ: c_int = 1024
pub let EOF: c_int = -1
pub let FOPEN_MAX: c_int = 20
pub let FILENAME_MAX: c_int = 1024
pub let P_tmpdir = "/var/tmp/"
pub let L_tmpnam: c_int = 1024
pub let TMP_MAX: c_int = 308915776
pub let L_ctermid: c_int = 1024
pub let NULL: *mut c_void = null
pub let MAX_MEM_LEVEL: c_int = 9
pub let MAX_WBITS: c_int = 15
pub let USE_CLANG_LIMITS: c_int = 0
pub let MB_LEN_MAX: c_int = 6
pub let CHAR_BIT: c_int = 8
pub let SCHAR_MAX: c_int = 127
pub let SCHAR_MIN: c_int = -128
pub let UCHAR_MAX: c_int = 255
pub let CHAR_MAX: c_int = 127
pub let CHAR_MIN: c_int = -128
pub let USHRT_MAX: c_int = 65535
pub let SHRT_MAX: c_int = 32767
pub let SHRT_MIN: c_int = -32768
pub let UINT_MAX: c_int = 0xffffffff
pub let INT_MAX: c_int = 2147483647
pub let INT_MIN: c_int = (-2147483647 - 1)
pub let ULONG_MAX: c_ulong = 0xffffffffffffffff
pub let LONG_MAX: c_long = 0x7fffffffffffffff
pub let LONG_MIN: c_long = (-0x7fffffffffffffff - 1)
pub let ULLONG_MAX: c_ulonglong = 0xffffffffffffffff
pub let LLONG_MAX: c_longlong = 0x7fffffffffffffff
pub let LLONG_MIN: c_longlong = (-0x7fffffffffffffff - 1)
pub let LONG_BIT: c_int = 64
pub let SSIZE_MAX: c_long = 0x7fffffffffffffff
pub let WORD_BIT: c_int = 32
pub let SIZE_T_MAX: c_ulong = 0xffffffffffffffff
pub let UQUAD_MAX: c_ulonglong = 0xffffffffffffffff
pub let QUAD_MAX: c_longlong = 0x7fffffffffffffff
pub let QUAD_MIN: c_longlong = LLONG_MIN
pub let ARG_MAX: c_int = (1024 * 1024)
pub let CHILD_MAX: c_int = 266
pub let GID_MAX: c_uint = 2147483647
pub let LINK_MAX: c_int = 32767
pub let MAX_CANON: c_int = 1024
pub let MAX_INPUT: c_int = 1024
pub let NAME_MAX: c_int = 255
pub let NGROUPS_MAX: c_int = 16
pub let UID_MAX: c_uint = 2147483647
pub let OPEN_MAX: c_int = 10240
pub let PATH_MAX: c_int = 1024
pub let PIPE_BUF: c_int = 512
pub let BC_BASE_MAX: c_int = 99
pub let BC_DIM_MAX: c_int = 2048
pub let BC_SCALE_MAX: c_int = 99
pub let BC_STRING_MAX: c_int = 1000
pub let CHARCLASS_NAME_MAX: c_int = 14
pub let COLL_WEIGHTS_MAX: c_int = 2
pub let EQUIV_CLASS_MAX: c_int = 2
pub let EXPR_NEST_MAX: c_int = 32
pub let LINE_MAX: c_int = 2048
pub let RE_DUP_MAX: c_int = 255
pub let NZERO: c_int = 20
pub let PTHREAD_DESTRUCTOR_ITERATIONS: c_int = 4
pub let PTHREAD_KEYS_MAX: c_int = 512
pub let PTHREAD_STACK_MIN: c_int = 16384
pub let OFF_MIN: c_longlong = LLONG_MIN
pub let OFF_MAX: c_longlong = 0x7fffffffffffffff
pub let NL_ARGMAX: c_int = 9
pub let NL_LANGMAX: c_int = 14
pub let NL_MSGMAX: c_int = 32767
pub let NL_NMAX: c_int = 1
pub let NL_SETMAX: c_int = 255
pub let NL_TEXTMAX: c_int = 2048
pub let IOV_MAX: c_int = 1024
pub let LONG_LONG_MAX: c_longlong = 9223372036854775807
pub let LONG_LONG_MIN: c_longlong = -9223372036854775808
pub let ULONG_LONG_MAX: c_ulonglong = ((0 as c_ulonglong) -% 1)
pub let F_OK: c_int = 0
pub let X_OK: c_int = (1 << 0)
pub let W_OK: c_int = (1 << 1)
pub let R_OK: c_int = (1 << 2)
pub let L_SET: c_int = 0
pub let L_INCR: c_int = 1
pub let L_XTND: c_int = 2
pub let ACCESSX_MAX_DESCRIPTORS: c_int = 100
pub let ACCESSX_MAX_TABLESIZE: c_int = (16 * 1024)
pub let STDIN_FILENO: c_int = 0
pub let STDOUT_FILENO: c_int = 1
pub let STDERR_FILENO: c_int = 2
pub let F_ULOCK: c_int = 0
pub let F_LOCK: c_int = 1
pub let F_TLOCK: c_int = 2
pub let F_TEST: c_int = 3
pub let SYNC_VOLUME_FULLSYNC: c_int = 0x01
pub let SYNC_VOLUME_WAIT: c_int = 0x02
pub let ZLIB_VERSION = "1.3.2"
pub let ZLIB_VERNUM: c_int = 0x1320
pub let ZLIB_VER_MAJOR: c_int = 1
pub let ZLIB_VER_MINOR: c_int = 3
pub let ZLIB_VER_REVISION: c_int = 2
pub let ZLIB_VER_SUBREVISION: c_int = 0
pub let Z_NO_FLUSH: c_int = 0
pub let Z_PARTIAL_FLUSH: c_int = 1
pub let Z_SYNC_FLUSH: c_int = 2
pub let Z_FULL_FLUSH: c_int = 3
pub let Z_FINISH: c_int = 4
pub let Z_BLOCK: c_int = 5
pub let Z_TREES: c_int = 6
pub let Z_OK: c_int = 0
pub let Z_STREAM_END: c_int = 1
pub let Z_NEED_DICT: c_int = 2
pub let Z_ERRNO: c_int = -1
pub let Z_STREAM_ERROR: c_int = -2
pub let Z_DATA_ERROR: c_int = -3
pub let Z_MEM_ERROR: c_int = -4
pub let Z_BUF_ERROR: c_int = -5
pub let Z_VERSION_ERROR: c_int = -6
pub let Z_NO_COMPRESSION: c_int = 0
pub let Z_BEST_SPEED: c_int = 1
pub let Z_BEST_COMPRESSION: c_int = 9
pub let Z_DEFAULT_COMPRESSION: c_int = -1
pub let Z_FILTERED: c_int = 1
pub let Z_HUFFMAN_ONLY: c_int = 2
pub let Z_RLE: c_int = 3
pub let Z_FIXED: c_int = 4
pub let Z_DEFAULT_STRATEGY: c_int = 0
pub let Z_BINARY: c_int = 0
pub let Z_TEXT: c_int = 1
pub let Z_ASCII: c_int = 1
pub let Z_UNKNOWN: c_int = 2
pub let Z_DEFLATED: c_int = 8
pub let Z_NULL: c_int = 0
pub let zlib_version: *const i8 = zlibVersion()
pub let SIGHUP: c_int = 1
pub let SIGINT: c_int = 2
pub let SIGQUIT: c_int = 3
pub let SIGILL: c_int = 4
pub let SIGTRAP: c_int = 5
pub let SIGABRT: c_int = 6
pub let SIGIOT: c_int = 6
pub let SIGEMT: c_int = 7
pub let SIGFPE: c_int = 8
pub let SIGKILL: c_int = 9
pub let SIGBUS: c_int = 10
pub let SIGSEGV: c_int = 11
pub let SIGSYS: c_int = 12
pub let SIGPIPE: c_int = 13
pub let SIGALRM: c_int = 14
pub let SIGTERM: c_int = 15
pub let SIGURG: c_int = 16
pub let SIGSTOP: c_int = 17
pub let SIGTSTP: c_int = 18
pub let SIGCONT: c_int = 19
pub let SIGCHLD: c_int = 20
pub let SIGTTIN: c_int = 21
pub let SIGTTOU: c_int = 22
pub let SIGIO: c_int = 23
pub let SIGXCPU: c_int = 24
pub let SIGXFSZ: c_int = 25
pub let SIGVTALRM: c_int = 26
pub let SIGPROF: c_int = 27
pub let SIGWINCH: c_int = 28
pub let SIGINFO: c_int = 29
pub let SIGUSR1: c_int = 30
pub let SIGUSR2: c_int = 31
pub let SIGEV_NONE: c_int = 0
pub let SIGEV_SIGNAL: c_int = 1
pub let SIGEV_THREAD: c_int = 3
pub let SIGEV_KEVENT: c_int = 4
pub let ILL_NOOP: c_int = 0
pub let ILL_ILLOPC: c_int = 1
pub let ILL_ILLTRP: c_int = 2
pub let ILL_PRVOPC: c_int = 3
pub let ILL_ILLOPN: c_int = 4
pub let ILL_ILLADR: c_int = 5
pub let ILL_PRVREG: c_int = 6
pub let ILL_COPROC: c_int = 7
pub let ILL_BADSTK: c_int = 8
pub let FPE_NOOP: c_int = 0
pub let FPE_FLTDIV: c_int = 1
pub let FPE_FLTOVF: c_int = 2
pub let FPE_FLTUND: c_int = 3
pub let FPE_FLTRES: c_int = 4
pub let FPE_FLTINV: c_int = 5
pub let FPE_FLTSUB: c_int = 6
pub let FPE_INTDIV: c_int = 7
pub let FPE_INTOVF: c_int = 8
pub let SEGV_NOOP: c_int = 0
pub let SEGV_MAPERR: c_int = 1
pub let SEGV_ACCERR: c_int = 2
pub let BUS_NOOP: c_int = 0
pub let BUS_ADRALN: c_int = 1
pub let BUS_ADRERR: c_int = 2
pub let BUS_OBJERR: c_int = 3
pub let TRAP_BRKPT: c_int = 1
pub let TRAP_TRACE: c_int = 2
pub let CLD_NOOP: c_int = 0
pub let CLD_EXITED: c_int = 1
pub let CLD_KILLED: c_int = 2
pub let CLD_DUMPED: c_int = 3
pub let CLD_TRAPPED: c_int = 4
pub let CLD_STOPPED: c_int = 5
pub let CLD_CONTINUED: c_int = 6
pub let POLL_IN: c_int = 1
pub let POLL_OUT: c_int = 2
pub let POLL_MSG: c_int = 3
pub let POLL_ERR: c_int = 4
pub let POLL_PRI: c_int = 5
pub let POLL_HUP: c_int = 6
pub let SA_ONSTACK: c_int = 0x0001
pub let SA_RESTART: c_int = 0x0002
pub let SA_RESETHAND: c_int = 0x0004
pub let SA_NOCLDSTOP: c_int = 0x0008
pub let SA_NODEFER: c_int = 0x0010
pub let SA_NOCLDWAIT: c_int = 0x0020
pub let SA_SIGINFO: c_int = 0x0040
pub let SA_USERTRAMP: c_int = 0x0100
pub let SA_64REGSET: c_int = 0x0200
pub let SA_USERSPACE_MASK: c_int = 127
pub let SIG_BLOCK: c_int = 1
pub let SIG_UNBLOCK: c_int = 2
pub let SIG_SETMASK: c_int = 3
pub let SI_USER: c_int = 0x10001
pub let SI_QUEUE: c_int = 0x10002
pub let SI_TIMER: c_int = 0x10003
pub let SI_ASYNCIO: c_int = 0x10004
pub let SI_MESGQ: c_int = 0x10005
pub let SS_ONSTACK: c_int = 0x0001
pub let SS_DISABLE: c_int = 0x0004
pub let MINSIGSTKSZ: c_int = 32768
pub let SIGSTKSZ: c_int = 131072
pub let SV_ONSTACK: c_int = 0x0001
pub let SV_INTERRUPT: c_int = 0x0002
pub let SV_RESETHAND: c_int = 0x0004
pub let SV_NODEFER: c_int = 0x0010
pub let SV_NOCLDSTOP: c_int = 0x0008
pub let SV_SIGINFO: c_int = 0x0040
pub fn INT8_C[T](v: T) -> T {
    v
}
pub fn INT16_C[T](v: T) -> T {
    v
}
pub fn INT32_C[T](v: T) -> T {
    v
}
pub fn INT64_C[T](v: T) -> i64 {
    (v as i64)
}
pub fn UINT8_C[T](v: T) -> T {
    v
}
pub fn UINT16_C[T](v: T) -> T {
    v
}
pub fn UINT32_C[T](v: T) -> u32 {
    (v as u32)
}
pub fn UINT64_C[T](v: T) -> u64 {
    (v as u64)
}
pub fn INTMAX_C[T](v: T) -> i64 {
    (v as i64)
}
pub fn UINTMAX_C[T](v: T) -> u64 {
    (v as u64)
}
pub let INT8_MAX: c_int = 127
pub let INT16_MAX: c_int = 32767
pub let INT32_MAX: c_int = 2147483647
pub let INT64_MAX: c_longlong = 9223372036854775807
pub let INT8_MIN: c_int = -128
pub let INT16_MIN: c_int = -32768
pub let INT32_MIN: c_int = ((0 - 2147483647) - 1)
pub let INT64_MIN: c_longlong = ((0 - 9223372036854775807) - 1)
pub let UINT8_MAX: c_int = 255
pub let UINT16_MAX: c_int = 65535
pub let UINT32_MAX: c_uint = 4294967295
pub let UINT64_MAX: c_ulonglong = 18446744073709551615
pub let INT_LEAST8_MIN: c_int = -128
pub let INT_LEAST16_MIN: c_int = -32768
pub let INT_LEAST32_MIN: c_int = INT32_MIN
pub let INT_LEAST64_MIN: c_longlong = INT64_MIN
pub let INT_LEAST8_MAX: c_int = 127
pub let INT_LEAST16_MAX: c_int = 32767
pub let INT_LEAST32_MAX: c_int = 2147483647
pub let INT_LEAST64_MAX: c_longlong = 9223372036854775807
pub let UINT_LEAST8_MAX: c_int = 255
pub let UINT_LEAST16_MAX: c_int = 65535
pub let UINT_LEAST32_MAX: c_uint = 4294967295
pub let UINT_LEAST64_MAX: c_ulonglong = 18446744073709551615
pub let INT_FAST8_MIN: c_int = -128
pub let INT_FAST16_MIN: c_int = -32768
pub let INT_FAST32_MIN: c_int = INT32_MIN
pub let INT_FAST64_MIN: c_longlong = INT64_MIN
pub let INT_FAST8_MAX: c_int = 127
pub let INT_FAST16_MAX: c_int = 32767
pub let INT_FAST32_MAX: c_int = 2147483647
pub let INT_FAST64_MAX: c_longlong = 9223372036854775807
pub let UINT_FAST8_MAX: c_int = 255
pub let UINT_FAST16_MAX: c_int = 65535
pub let UINT_FAST32_MAX: c_uint = 4294967295
pub let UINT_FAST64_MAX: c_ulonglong = 18446744073709551615
pub let INTPTR_MAX: c_long = 9223372036854775807
pub let INTPTR_MIN: c_long = ((0 - 9223372036854775807) - 1)
pub let UINTPTR_MAX: c_ulong = 18446744073709551615
pub let INTMAX_MAX: c_long = INTMAX_C(9223372036854775807)
pub let UINTMAX_MAX: c_ulong = UINTMAX_C(18446744073709551615)
pub let INTMAX_MIN: c_long = ((0 - INTMAX_MAX) - 1)
pub let PTRDIFF_MIN: c_long = INTMAX_MIN
pub let PTRDIFF_MAX: c_long = INTMAX_MAX
pub let SIZE_MAX: c_ulong = 18446744073709551615
pub let RSIZE_MAX: c_ulong = (SIZE_MAX >> 1)
pub let WINT_MIN: c_int = INT32_MIN
pub let WINT_MAX: c_int = 2147483647
pub let SIG_ATOMIC_MIN: c_int = INT32_MIN
pub let SIG_ATOMIC_MAX: c_int = 2147483647
pub let PRIO_PROCESS: c_int = 0
pub let PRIO_PGRP: c_int = 1
pub let PRIO_USER: c_int = 2
pub let PRIO_DARWIN_THREAD: c_int = 3
pub let PRIO_DARWIN_PROCESS: c_int = 4
pub let PRIO_MIN: c_int = -20
pub let PRIO_MAX: c_int = 20
pub let PRIO_DARWIN_BG: c_int = 0x1000
pub let PRIO_DARWIN_NONUI: c_int = 0x1001
pub let RUSAGE_SELF: c_int = 0
pub let RUSAGE_CHILDREN: c_int = -1
pub let RUSAGE_INFO_V0: c_int = 0
pub let RUSAGE_INFO_V1: c_int = 1
pub let RUSAGE_INFO_V2: c_int = 2
pub let RUSAGE_INFO_V3: c_int = 3
pub let RUSAGE_INFO_V4: c_int = 4
pub let RUSAGE_INFO_V5: c_int = 5
pub let RUSAGE_INFO_V6: c_int = 6
pub let RUSAGE_INFO_CURRENT: c_int = 6
pub let RU_PROC_RUNS_RESLIDE: c_int = 0x00000001
pub let RLIMIT_CPU: c_int = 0
pub let RLIMIT_FSIZE: c_int = 1
pub let RLIMIT_DATA: c_int = 2
pub let RLIMIT_STACK: c_int = 3
pub let RLIMIT_CORE: c_int = 4
pub let RLIMIT_AS: c_int = 5
pub let RLIMIT_RSS: c_int = 5
pub let RLIMIT_MEMLOCK: c_int = 6
pub let RLIMIT_NPROC: c_int = 7
pub let RLIMIT_NOFILE: c_int = 8
pub let RLIM_NLIMITS: c_int = 9
pub let RLIMIT_WAKEUPS_MONITOR: c_int = 0x1
pub let RLIMIT_CPU_USAGE_MONITOR: c_int = 0x2
pub let RLIMIT_THREAD_CPULIMITS: c_int = 0x3
pub let RLIMIT_FOOTPRINT_INTERVAL: c_int = 0x4
pub let WAKEMON_ENABLE: c_int = 0x01
pub let WAKEMON_DISABLE: c_int = 0x02
pub let WAKEMON_GET_PARAMS: c_int = 0x04
pub let WAKEMON_SET_DEFAULTS: c_int = 0x08
pub let WAKEMON_MAKE_FATAL: c_int = 0x10
pub let CPUMON_MAKE_FATAL: c_int = 0x1000
pub let FOOTPRINT_INTERVAL_RESET: c_int = 0x1
pub let IOPOL_TYPE_DISK: c_int = 0
pub let IOPOL_TYPE_VFS_ATIME_UPDATES: c_int = 2
pub let IOPOL_TYPE_VFS_MATERIALIZE_DATALESS_FILES: c_int = 3
pub let IOPOL_TYPE_VFS_STATFS_NO_DATA_VOLUME: c_int = 4
pub let IOPOL_TYPE_VFS_TRIGGER_RESOLVE: c_int = 5
pub let IOPOL_TYPE_VFS_IGNORE_CONTENT_PROTECTION: c_int = 6
pub let IOPOL_TYPE_VFS_IGNORE_PERMISSIONS: c_int = 7
pub let IOPOL_TYPE_VFS_SKIP_MTIME_UPDATE: c_int = 8
pub let IOPOL_TYPE_VFS_ALLOW_LOW_SPACE_WRITES: c_int = 9
pub let IOPOL_TYPE_VFS_DISALLOW_RW_FOR_O_EVTONLY: c_int = 10
pub let IOPOL_TYPE_VFS_ENTITLED_RESERVE_ACCESS: c_int = 14
pub let IOPOL_SCOPE_PROCESS: c_int = 0
pub let IOPOL_SCOPE_THREAD: c_int = 1
pub let IOPOL_SCOPE_DARWIN_BG: c_int = 2
pub let IOPOL_DEFAULT: c_int = 0
pub let IOPOL_IMPORTANT: c_int = 1
pub let IOPOL_PASSIVE: c_int = 2
pub let IOPOL_THROTTLE: c_int = 3
pub let IOPOL_UTILITY: c_int = 4
pub let IOPOL_STANDARD: c_int = 5
pub let IOPOL_APPLICATION: c_int = 5
pub let IOPOL_NORMAL: c_int = 1
pub let IOPOL_ATIME_UPDATES_DEFAULT: c_int = 0
pub let IOPOL_ATIME_UPDATES_OFF: c_int = 1
pub let IOPOL_MATERIALIZE_DATALESS_FILES_DEFAULT: c_int = 0
pub let IOPOL_MATERIALIZE_DATALESS_FILES_OFF: c_int = 1
pub let IOPOL_MATERIALIZE_DATALESS_FILES_ON: c_int = 2
pub let IOPOL_MATERIALIZE_DATALESS_FILES_ORIG: c_int = 4
pub let IOPOL_MATERIALIZE_DATALESS_FILES_BASIC_MASK: c_int = 3
pub let IOPOL_VFS_STATFS_NO_DATA_VOLUME_DEFAULT: c_int = 0
pub let IOPOL_VFS_STATFS_FORCE_NO_DATA_VOLUME: c_int = 1
pub let IOPOL_VFS_TRIGGER_RESOLVE_DEFAULT: c_int = 0
pub let IOPOL_VFS_TRIGGER_RESOLVE_OFF: c_int = 1
pub let IOPOL_VFS_CONTENT_PROTECTION_DEFAULT: c_int = 0
pub let IOPOL_VFS_CONTENT_PROTECTION_IGNORE: c_int = 1
pub let IOPOL_VFS_IGNORE_PERMISSIONS_OFF: c_int = 0
pub let IOPOL_VFS_IGNORE_PERMISSIONS_ON: c_int = 1
pub let IOPOL_VFS_SKIP_MTIME_UPDATE_OFF: c_int = 0
pub let IOPOL_VFS_SKIP_MTIME_UPDATE_ON: c_int = 1
pub let IOPOL_VFS_SKIP_MTIME_UPDATE_IGNORE: c_int = 2
pub let IOPOL_VFS_ALLOW_LOW_SPACE_WRITES_OFF: c_int = 0
pub let IOPOL_VFS_ALLOW_LOW_SPACE_WRITES_ON: c_int = 1
pub let IOPOL_VFS_DISALLOW_RW_FOR_O_EVTONLY_DEFAULT: c_int = 0
pub let IOPOL_VFS_DISALLOW_RW_FOR_O_EVTONLY_ON: c_int = 1
pub let IOPOL_VFS_NOCACHE_WRITE_FS_BLKSIZE_DEFAULT: c_int = 0
pub let IOPOL_VFS_NOCACHE_WRITE_FS_BLKSIZE_ON: c_int = 1
pub let IOPOL_VFS_ENTITLED_RESERVE_ACCESS_OFF: c_int = 0
pub let IOPOL_VFS_ENTITLED_RESERVE_ACCESS_ON: c_int = 1
pub let WNOHANG: c_int = 0x00000001
pub let WUNTRACED: c_int = 0x00000002
pub let WCOREFLAG: c_int = 0200
pub fn W_EXITCODE[T](ret: T, sig: T) -> T {
    ((ret << 8) | sig)
}
pub let WEXITED: c_int = 0x00000004
pub let WSTOPPED: c_int = 0x00000008
pub let WCONTINUED: c_int = 0x00000010
pub let WNOWAIT: c_int = 0x00000020
pub let WAIT_ANY: c_int = -1
pub let WAIT_MYPGRP: c_int = 0
pub let EXIT_FAILURE: c_int = 1
pub let EXIT_SUCCESS: c_int = 0
pub let RAND_MAX: c_int = 0x7fffffff
pub let DEF_WBITS: c_int = 15
pub let DEF_MEM_LEVEL: c_int = 8
pub let STORED_BLOCK: c_int = 0
pub let STATIC_TREES: c_int = 1
pub let DYN_TREES: c_int = 2
pub let MIN_MATCH: c_int = 3
pub let MAX_MATCH: c_int = 258
pub let PRESET_DICT: c_int = 0x20
pub let OS_CODE: c_int = 19
pub let BASE: c_uint = 65521
pub let NMAX: c_int = 5552
pub type z_word_t = c_ulong

pub let N: c_int = 5
pub let W: c_int = 8
pub let POLY: c_int = 0xedb88320
pub type ct_data_s_fc = union { freq: c_ushort = 0, code: c_ushort = 0 }
impl Copy for ct_data_s_fc
pub type ct_data_s_dl = union { dad: c_ushort = 0, len: c_ushort = 0 }
impl Copy for ct_data_s_dl
pub type ct_data_s { fc: ct_data_s_fc, dl: ct_data_s_dl }
impl Copy for ct_data_s

pub type ct_data = ct_data_s

pub type static_tree_desc_s { static_tree: *const ct_data_s = null, extra_bits: *const c_int = null, extra_base: c_int = 0, elems: c_int = 0, max_length: c_int = 0 }
impl Copy for static_tree_desc_s

pub type static_tree_desc = static_tree_desc_s

pub type tree_desc_s { dyn_tree: *mut ct_data_s = null, max_code: c_int = 0, stat_desc: *const static_tree_desc_s = null }
impl Copy for tree_desc_s

pub type tree_desc = tree_desc_s

pub type Pos = c_ushort

pub type Posf = c_ushort

pub type IPos = c_uint

pub type deflate_state = internal_state

pub type block_state = c_uint

pub let need_more: c_uint = 0
pub let block_done: c_uint = 1
pub let finish_started: c_uint = 2
pub let finish_done: c_uint = 3
pub type compress_func = unsafe extern "C" fn(*mut internal_state, c_int) -> i32

pub type config_s { good_length: c_ushort = 0, max_lazy: c_ushort = 0, nice_length: c_ushort = 0, max_chain: c_ushort = 0, func: unsafe extern "C" fn(*mut internal_state, c_int) -> i32 }
impl Copy for config_s

pub type config = config_s

pub let deflate_copyright: [68]c_char = [32, 100, 101, 102, 108, 97, 116, 101, 32, 49, 46, 51, 46, 50, 32, 67, 111, 112, 121, 114, 105, 103, 104, 116, 32, 49, 57, 57, 53, 45, 50, 48, 50, 54, 32, 74, 101, 97, 110, 45, 108, 111, 117, 112, 32, 71, 97, 105, 108, 108, 121, 32, 97, 110, 100, 32, 77, 97, 114, 107, 32, 65, 100, 108, 101, 114, 32, 0]

pub let LENGTH_CODES: c_int = 29
pub let LITERALS: c_int = 256
pub let L_CODES: c_int = 286
pub let D_CODES: c_int = 30
pub let BL_CODES: c_int = 19
pub let HEAP_SIZE: c_int = 573
pub let MAX_BITS: c_int = 15
pub let Buf_size: c_int = 16
pub let INIT_STATE: c_int = 42
pub let GZIP_STATE: c_int = 57
pub let EXTRA_STATE: c_int = 69
pub let NAME_STATE: c_int = 73
pub let COMMENT_STATE: c_int = 91
pub let HCRC_STATE: c_int = 103
pub let BUSY_STATE: c_int = 113
pub let FINISH_STATE: c_int = 666
pub let LIT_BUFS: c_int = 4
pub let MIN_LOOKAHEAD: c_int = 262
pub let WIN_INIT: c_int = 258
pub let NIL: c_int = 0
pub let TOO_FAR: c_int = 4096
pub let MAX_STORED: c_int = 65535
pub fn MIN[T](a: T, b: T) -> T {
    (if (a > b): b else: a)
}
pub type gz_state { x: gzFile_s, mode: c_int = 0, fd: c_int = 0, path: *mut i8 = null, size: c_uint = 0, want: c_uint = 0, in_: *mut u8 = null, out: *mut u8 = null, direct: c_int = 0, junk: c_int = 0, how: c_int = 0, again: c_int = 0, start: c_longlong = 0, eof: c_int = 0, past: c_int = 0, level: c_int = 0, strategy: c_int = 0, reset: c_int = 0, skip: c_longlong = 0, err: c_int = 0, msg: *mut i8 = null, strm: z_stream_s }
impl Copy for gz_state

pub type gz_statep = *mut gz_state

pub let O_RDONLY: c_int = 0x0000
pub let O_WRONLY: c_int = 0x0001
pub let O_RDWR: c_int = 0x0002
pub let O_ACCMODE: c_int = 0x0003
pub let FREAD: c_int = 0x00000001
pub let FWRITE: c_int = 0x00000002
pub let O_NONBLOCK: c_int = 0x00000004
pub let O_APPEND: c_int = 0x00000008
pub let O_SYNC: c_int = 0x0080
pub let O_SHLOCK: c_int = 0x00000010
pub let O_EXLOCK: c_int = 0x00000020
pub let O_ASYNC: c_int = 0x00000040
pub let O_FSYNC: c_int = 0x0080
pub let O_NOFOLLOW: c_int = 0x00000100
pub let O_CREAT: c_int = 0x00000200
pub let O_TRUNC: c_int = 0x00000400
pub let O_EXCL: c_int = 0x00000800
pub let O_RESOLVE_BENEATH: c_int = 0x00001000
pub let O_UNIQUE: c_int = 0x00002000
pub let O_EVTONLY: c_int = 0x00008000
pub let O_NOCTTY: c_int = 0x00020000
pub let O_DIRECTORY: c_int = 0x00100000
pub let O_SYMLINK: c_int = 0x00200000
pub let O_DSYNC: c_int = 0x400000
pub let O_CLOEXEC: c_int = 0x01000000
pub let O_NOFOLLOW_ANY: c_int = 0x20000000
pub let O_EXEC: c_int = 0x40000000
pub let O_SEARCH: c_int = (0x40000000 | 0x00100000)
pub let AT_FDCWD: c_int = -2
pub let AT_EACCESS: c_int = 0x0010
pub let AT_SYMLINK_NOFOLLOW: c_int = 0x0020
pub let AT_SYMLINK_FOLLOW: c_int = 0x0040
pub let AT_REMOVEDIR: c_int = 0x0080
pub let AT_REALDEV: c_int = 0x0200
pub let AT_FDONLY: c_int = 0x0400
pub let AT_SYMLINK_NOFOLLOW_ANY: c_int = 0x0800
pub let AT_RESOLVE_BENEATH: c_int = 0x2000
pub let AT_NODELETEBUSY: c_int = 0x4000
pub let AT_UNIQUE: c_int = 0x8000
pub let O_DP_GETRAWENCRYPTED: c_int = 0x0001
pub let O_DP_GETRAWUNENCRYPTED: c_int = 0x0002
pub let O_DP_AUTHENTICATE: c_int = 0x0004
pub let AUTH_OPEN_NOAUTHFD: c_int = -1
pub let FAPPEND: c_int = 0x00000008
pub let FASYNC: c_int = 0x00000040
pub let FFSYNC: c_int = O_FSYNC
pub let FFDSYNC: c_int = 0x400000
pub let FNONBLOCK: c_int = 0x00000004
pub let FNDELAY: c_int = 0x00000004
pub let O_NDELAY: c_int = 0x00000004
pub let CPF_OVERWRITE: c_int = 0x0001
pub let CPF_IGNORE_MODE: c_int = 0x0002
pub let CPF_MASK: c_int = (0x0001 | 0x0002)
pub let F_DUPFD: c_int = 0
pub let F_GETFD: c_int = 1
pub let F_SETFD: c_int = 2
pub let F_GETFL: c_int = 3
pub let F_SETFL: c_int = 4
pub let F_GETOWN: c_int = 5
pub let F_SETOWN: c_int = 6
pub let F_GETLK: c_int = 7
pub let F_SETLK: c_int = 8
pub let F_SETLKW: c_int = 9
pub let F_SETLKWTIMEOUT: c_int = 10
pub let F_FLUSH_DATA: c_int = 40
pub let F_CHKCLEAN: c_int = 41
pub let F_PREALLOCATE: c_int = 42
pub let F_SETSIZE: c_int = 43
pub let F_RDADVISE: c_int = 44
pub let F_RDAHEAD: c_int = 45
pub let F_NOCACHE: c_int = 48
pub let F_LOG2PHYS: c_int = 49
pub let F_GETPATH: c_int = 50
pub let F_FULLFSYNC: c_int = 51
pub let F_PATHPKG_CHECK: c_int = 52
pub let F_FREEZE_FS: c_int = 53
pub let F_THAW_FS: c_int = 54
pub let F_GLOBAL_NOCACHE: c_int = 55
pub let F_ADDSIGS: c_int = 59
pub let F_ADDFILESIGS: c_int = 61
pub let F_NODIRECT: c_int = 62
pub let F_GETPROTECTIONCLASS: c_int = 63
pub let F_SETPROTECTIONCLASS: c_int = 64
pub let F_LOG2PHYS_EXT: c_int = 65
pub let F_SETBACKINGSTORE: c_int = 70
pub let F_GETPATH_MTMINFO: c_int = 71
pub let F_GETCODEDIR: c_int = 72
pub let F_SETNOSIGPIPE: c_int = 73
pub let F_GETNOSIGPIPE: c_int = 74
pub let F_TRANSCODEKEY: c_int = 75
pub let F_SINGLE_WRITER: c_int = 76
pub let F_GETPROTECTIONLEVEL: c_int = 77
pub let F_FINDSIGS: c_int = 78
pub let F_ADDFILESIGS_FOR_DYLD_SIM: c_int = 83
pub let F_BARRIERFSYNC: c_int = 85
pub let F_OFD_SETLK: c_int = 90
pub let F_OFD_SETLKW: c_int = 91
pub let F_OFD_GETLK: c_int = 92
pub let F_OFD_SETLKWTIMEOUT: c_int = 93
pub let F_ADDFILESIGS_RETURN: c_int = 97
pub let F_CHECK_LV: c_int = 98
pub let F_PUNCHHOLE: c_int = 99
pub let F_TRIM_ACTIVE_FILE: c_int = 100
pub let F_SPECULATIVE_READ: c_int = 101
pub let F_GETPATH_NOFIRMLINK: c_int = 102
pub let F_ADDFILESIGS_INFO: c_int = 103
pub let F_ADDFILESUPPL: c_int = 104
pub let F_GETSIGSINFO: c_int = 105
pub let F_SETLEASE: c_int = 106
pub let F_GETLEASE: c_int = 107
pub let F_TRANSFEREXTENTS: c_int = 110
pub let F_ATTRIBUTION_TAG: c_int = 111
pub let F_NOCACHE_EXT: c_int = 112
pub let F_ADDSIGS_MAIN_BINARY: c_int = 113
pub let FCNTL_FS_SPECIFIC_BASE: c_int = 0x00010000
pub let F_DUPFD_CLOEXEC: c_int = 67
pub let FD_CLOEXEC: c_int = 1
pub let F_RDLCK: c_int = 1
pub let F_UNLCK: c_int = 2
pub let F_WRLCK: c_int = 3
pub let S_IFMT: c_int = 0170000
pub let S_IFIFO: c_int = 0010000
pub let S_IFCHR: c_int = 0020000
pub let S_IFDIR: c_int = 0040000
pub let S_IFBLK: c_int = 0060000
pub let S_IFREG: c_int = 0100000
pub let S_IFLNK: c_int = 0120000
pub let S_IFSOCK: c_int = 0140000
pub let S_IFWHT: c_int = 0160000
pub let S_IRWXU: c_int = 0000700
pub let S_IRUSR: c_int = 0000400
pub let S_IWUSR: c_int = 0000200
pub let S_IXUSR: c_int = 0000100
pub let S_IRWXG: c_int = 0000070
pub let S_IRGRP: c_int = 0000040
pub let S_IWGRP: c_int = 0000020
pub let S_IXGRP: c_int = 0000010
pub let S_IRWXO: c_int = 0000007
pub let S_IROTH: c_int = 0000004
pub let S_IWOTH: c_int = 0000002
pub let S_IXOTH: c_int = 0000001
pub let S_ISUID: c_int = 0004000
pub let S_ISGID: c_int = 0002000
pub let S_ISVTX: c_int = 0001000
pub let S_ISTXT: c_int = 0001000
pub let S_IREAD: c_int = 0000400
pub let S_IWRITE: c_int = 0000200
pub let S_IEXEC: c_int = 0000100
pub let F_ALLOCATECONTIG: c_int = 0x00000002
pub let F_ALLOCATEALL: c_int = 0x00000004
pub let F_ALLOCATEPERSIST: c_int = 0x00000008
pub let F_PEOFPOSMODE: c_int = 3
pub let F_VOLPOSMODE: c_int = 4
pub let USER_FSIGNATURES_CDHASH_LEN: c_int = 20
pub let GETSIGSINFO_PLATFORM_BINARY: c_int = 1
pub let LOCK_SH: c_int = 0x01
pub let LOCK_EX: c_int = 0x02
pub let LOCK_NB: c_int = 0x04
pub let LOCK_UN: c_int = 0x08
pub let ATTRIBUTION_NAME_MAX: c_int = 255
pub let F_CREATE_TAG: c_int = 0x00000001
pub let F_DELETE_TAG: c_int = 0x00000002
pub let F_QUERY_TAG: c_int = 0x00000004
pub let O_POPUP: c_int = 0x80000000
pub let O_ALERT: c_int = 0x20000000
pub let EPERM: c_int = 1
pub let ENOENT: c_int = 2
pub let ESRCH: c_int = 3
pub let EINTR: c_int = 4
pub let EIO: c_int = 5
pub let ENXIO: c_int = 6
pub let E2BIG: c_int = 7
pub let ENOEXEC: c_int = 8
pub let EBADF: c_int = 9
pub let ECHILD: c_int = 10
pub let EDEADLK: c_int = 11
pub let ENOMEM: c_int = 12
pub let EACCES: c_int = 13
pub let EFAULT: c_int = 14
pub let ENOTBLK: c_int = 15
pub let EBUSY: c_int = 16
pub let EEXIST: c_int = 17
pub let EXDEV: c_int = 18
pub let ENODEV: c_int = 19
pub let ENOTDIR: c_int = 20
pub let EISDIR: c_int = 21
pub let EINVAL: c_int = 22
pub let ENFILE: c_int = 23
pub let EMFILE: c_int = 24
pub let ENOTTY: c_int = 25
pub let ETXTBSY: c_int = 26
pub let EFBIG: c_int = 27
pub let ENOSPC: c_int = 28
pub let ESPIPE: c_int = 29
pub let EROFS: c_int = 30
pub let EMLINK: c_int = 31
pub let EPIPE: c_int = 32
pub let EDOM: c_int = 33
pub let ERANGE: c_int = 34
pub let EAGAIN: c_int = 35
pub let EWOULDBLOCK: c_int = 35
pub let EINPROGRESS: c_int = 36
pub let EALREADY: c_int = 37
pub let ENOTSOCK: c_int = 38
pub let EDESTADDRREQ: c_int = 39
pub let EMSGSIZE: c_int = 40
pub let EPROTOTYPE: c_int = 41
pub let ENOPROTOOPT: c_int = 42
pub let EPROTONOSUPPORT: c_int = 43
pub let ESOCKTNOSUPPORT: c_int = 44
pub let ENOTSUP: c_int = 45
pub let EPFNOSUPPORT: c_int = 46
pub let EAFNOSUPPORT: c_int = 47
pub let EADDRINUSE: c_int = 48
pub let EADDRNOTAVAIL: c_int = 49
pub let ENETDOWN: c_int = 50
pub let ENETUNREACH: c_int = 51
pub let ENETRESET: c_int = 52
pub let ECONNABORTED: c_int = 53
pub let ECONNRESET: c_int = 54
pub let ENOBUFS: c_int = 55
pub let EISCONN: c_int = 56
pub let ENOTCONN: c_int = 57
pub let ESHUTDOWN: c_int = 58
pub let ETOOMANYREFS: c_int = 59
pub let ETIMEDOUT: c_int = 60
pub let ECONNREFUSED: c_int = 61
pub let ELOOP: c_int = 62
pub let ENAMETOOLONG: c_int = 63
pub let EHOSTDOWN: c_int = 64
pub let EHOSTUNREACH: c_int = 65
pub let ENOTEMPTY: c_int = 66
pub let EPROCLIM: c_int = 67
pub let EUSERS: c_int = 68
pub let EDQUOT: c_int = 69
pub let ESTALE: c_int = 70
pub let EREMOTE: c_int = 71
pub let EBADRPC: c_int = 72
pub let ERPCMISMATCH: c_int = 73
pub let EPROGUNAVAIL: c_int = 74
pub let EPROGMISMATCH: c_int = 75
pub let EPROCUNAVAIL: c_int = 76
pub let ENOLCK: c_int = 77
pub let ENOSYS: c_int = 78
pub let EFTYPE: c_int = 79
pub let EAUTH: c_int = 80
pub let ENEEDAUTH: c_int = 81
pub let EPWROFF: c_int = 82
pub let EDEVERR: c_int = 83
pub let EOVERFLOW: c_int = 84
pub let EBADEXEC: c_int = 85
pub let EBADARCH: c_int = 86
pub let ESHLIBVERS: c_int = 87
pub let EBADMACHO: c_int = 88
pub let ECANCELED: c_int = 89
pub let EIDRM: c_int = 90
pub let ENOMSG: c_int = 91
pub let EILSEQ: c_int = 92
pub let ENOATTR: c_int = 93
pub let EBADMSG: c_int = 94
pub let EMULTIHOP: c_int = 95
pub let ENODATA: c_int = 96
pub let ENOLINK: c_int = 97
pub let ENOSR: c_int = 98
pub let ENOSTR: c_int = 99
pub let EPROTO: c_int = 100
pub let ETIME: c_int = 101
pub let EOPNOTSUPP: c_int = 102
pub let ENOPOLICY: c_int = 103
pub let ENOTRECOVERABLE: c_int = 104
pub let EOWNERDEAD: c_int = 105
pub let EQFULL: c_int = 106
pub let ENOTCAPABLE: c_int = 107
pub let ELAST: c_int = 107
pub let GZBUFSIZE: c_int = 8192
pub let GZ_NONE: c_int = 0
pub let GZ_READ: c_int = 7247
pub let GZ_WRITE: c_int = 31153
pub let GZ_APPEND: c_int = 1
pub let LOOK: c_int = 0
pub let COPY: c_int = 1
pub let GZIP: c_int = 2
pub fn GT_OFF[T](x: T) -> T {
    sizeof[c_int]()
}
pub type code { op: u8 = 0, bits: u8 = 0, val: c_ushort = 0 }
impl Copy for code

pub type codetype = c_uint

pub let CODES: c_uint = 0
pub let LENS: c_uint = 1
pub let DISTS: c_uint = 2
pub type inflate_mode = c_uint

pub let HEAD: c_uint = 16180
pub let FLAGS: c_uint = 16181
pub let TIME: c_uint = 16182
pub let OS: c_uint = 16183
pub let EXLEN: c_uint = 16184
pub let EXTRA: c_uint = 16185
pub let NAME: c_uint = 16186
pub let COMMENT: c_uint = 16187
pub let HCRC: c_uint = 16188
pub let DICTID: c_uint = 16189
pub let DICT: c_uint = 16190
pub let TYPE: c_uint = 16191
pub let TYPEDO: c_uint = 16192
pub let STORED: c_uint = 16193
pub let COPY_: c_uint = 16194
pub let TABLE: c_uint = 16196
pub let LENLENS: c_uint = 16197
pub let CODELENS: c_uint = 16198
pub let LEN_: c_uint = 16199
pub let LEN: c_uint = 16200
pub let LENEXT: c_uint = 16201
pub let DIST: c_uint = 16202
pub let DISTEXT: c_uint = 16203
pub let MATCH: c_uint = 16204
pub let LIT: c_uint = 16205
pub let CHECK: c_uint = 16206
pub let LENGTH: c_uint = 16207
pub let DONE: c_uint = 16208
pub let BAD: c_uint = 16209
pub let MEM: c_uint = 16210
pub let SYNC: c_uint = 16211
pub type inflate_state { strm: *mut z_stream_s = null, mode: i32 = 0, last: c_int = 0, wrap: c_int = 0, havedict: c_int = 0, flags: c_int = 0, dmax: c_uint = 0, check: c_ulong = 0, total: c_ulong = 0, head: *mut gz_header_s = null, wbits: c_uint = 0, wsize: c_uint = 0, whave: c_uint = 0, wnext: c_uint = 0, window: *mut u8 = null, hold: c_ulong = 0, bits: c_uint = 0, length: c_uint = 0, offset: c_uint = 0, extra: c_uint = 0, lencode: *const code = null, distcode: *const code = null, lenbits: c_uint = 0, distbits: c_uint = 0, ncode: c_uint = 0, nlen: c_uint = 0, ndist: c_uint = 0, have: c_uint = 0, next: *mut code = null, lens: [320]c_ushort = [0 as c_ushort; 320], work: [288]c_ushort = [0 as c_ushort; 288], codes: [1444]code, sane: c_int = 0, back: c_int = 0, was: c_uint = 0 }
impl Copy for inflate_state

pub let ENOUGH_LENS: c_int = 852
pub let ENOUGH_DISTS: c_int = 592
pub let ENOUGH: c_int = 1444
pub let inflate_copyright: [47]c_char = [32, 105, 110, 102, 108, 97, 116, 101, 32, 49, 46, 51, 46, 50, 32, 67, 111, 112, 121, 114, 105, 103, 104, 116, 32, 49, 57, 57, 53, 45, 50, 48, 50, 54, 32, 77, 97, 114, 107, 32, 65, 100, 108, 101, 114, 32, 0]

pub let MAXBITS: c_int = 15
pub let _dist_code: [512]u8 = [0, 1, 2, 3, 4, 4, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 0, 0, 16, 17, 18, 18, 19, 19, 20, 20, 20, 20, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22, 22, 22, 23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29]

pub let _length_code: [256]u8 = [0, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 12, 12, 13, 13, 13, 13, 14, 14, 14, 14, 15, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 17, 17, 17, 17, 17, 17, 17, 17, 18, 18, 18, 18, 18, 18, 18, 18, 19, 19, 19, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 28]

pub let MAX_BL_BITS: c_int = 7
pub let END_BLOCK: c_int = 256
pub let REP_3_6: c_int = 16
pub let REPZ_3_10: c_int = 17
pub let REPZ_11_138: c_int = 18
pub let DIST_CODE_LEN: c_int = 512
pub let SMALLEST: c_int = 1
pub let z_errmsg: [10]*mut i8 = [("need dictionary" as *mut c_char), ("stream end" as *mut c_char), ("" as *mut c_char), ("file error" as *mut c_char), ("stream error" as *mut c_char), ("data error" as *mut c_char), ("insufficient memory" as *mut c_char), ("buffer error" as *mut c_char), ("incompatible version" as *mut c_char), ("" as *mut c_char)]
