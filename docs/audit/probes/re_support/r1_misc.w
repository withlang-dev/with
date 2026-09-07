use std.libc
use std.builtins.print_i32
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_config
use std.re.pcre2_error
use std.re.pcre2_jit_compile
use std.re.pcre2_maketables
use std.re.pcre2_chkdint
use std.re.pcre2_string_utils
use std.re.pcre2_ord2utf

// r1: defs constants, chkdint, string utils, ord2utf, error strings,
// config values, JIT-stub surface, maketables-vs-default.
unsafe fn main:
    // --- defs constants (oracle: /usr/include/pcre2.h) ---
    printf(c"nomatch=%d utf=%u infocap=%d cfgver=%d subglob=%u convglob=%u\n".ptr, PCRE2_ERROR_NOMATCH, PCRE2_UTF, PCRE2_INFO_CAPTURECOUNT, PCRE2_CONFIG_VERSION, PCRE2_SUBSTITUTE_GLOBAL, PCRE2_CONVERT_GLOB)
    printf(c"tableslen=%d ucpLu=%u ucpNd=%u maxtables=%d\n".ptr, TABLES_LENGTH, ucp_Lu, ucp_Nd, MAX_UTF_CODE_POINT)
    printf(c"op_end=%u op_xclass=%u op_tablelen=%u\n".ptr, OP_END, OP_XCLASS, OP_TABLE_LENGTH)
    // --- chkdint: exact products, no overflow possible on LP64 ---
    var r: c_ulong = 0
    var rc: c_int = _pcre2_ckd_smul_8(&raw mut r, 2000000000, 3)
    printf(c"ckd1 rc=%d r=%lu\n".ptr, rc, r)
    rc = _pcre2_ckd_smul_8(&raw mut r, 2147483647, 2147483647)
    printf(c"ckd2 rc=%d r=%lu\n".ptr, rc, r)
    rc = _pcre2_ckd_smul_8(&raw mut r, 0, 12345)
    printf(c"ckd3 rc=%d r=%lu\n".ptr, rc, r)
    rc = _pcre2_ckd_smul_8(&raw mut r, -5, 7)
    printf(c"ckd4 rc=%d r=%lu\n".ptr, rc, r)
    // --- string utils vs libc expectations ---
    let a = with_alloc(8)
    let b = with_alloc(8)
    unsafe { a[0] = 104 }  // h
    unsafe { a[1] = 105 }  // i
    unsafe { a[2] = 0 }
    unsafe { b[0] = 104 }
    unsafe { b[1] = 106 }  // j
    unsafe { b[2] = 0 }
    printf(c"strlen=%lu strcmp_hi_hj=%d strcmp_hi_hi=%d strncmp1=%d strncmp0=%d\n".ptr, _pcre2_strlen_8(a), _pcre2_strcmp_8(a, b), _pcre2_strcmp_8(a, a), _pcre2_strncmp_8(a, b, 1), _pcre2_strncmp_8(a, b, 0))
    let dst = with_alloc(8)
    printf(c"strcpy=%lu s2=%d\n".ptr, _pcre2_strcpy_c8_8(dst, c"abc".ptr), _pcre2_strcmp_c8_8(dst, c"abc".ptr))
    // --- ord2utf boundaries (oracle: python bytes([..]) / .encode) ---
    let ob = with_alloc(8)
    var n: c_uint = 0
    n = _pcre2_ord2utf_8(0x41, ob)
    printf(c"ord41 n=%u b=%u\n".ptr, n, unsafe { ob[0] })
    n = _pcre2_ord2utf_8(0x7FF, ob)
    printf(c"ord7ff n=%u b=%u %u\n".ptr, n, unsafe { ob[0] }, unsafe { ob[1] })
    n = _pcre2_ord2utf_8(0x20AC, ob)
    printf(c"ord20ac n=%u b=%u %u %u\n".ptr, n, unsafe { ob[0] }, unsafe { ob[1] }, unsafe { ob[2] })
    n = _pcre2_ord2utf_8(0x1F600, ob)
    printf(c"ord1f600 n=%u b=%u %u %u %u\n".ptr, n, unsafe { ob[0] }, unsafe { ob[1] }, unsafe { ob[2] }, unsafe { ob[3] })
    // --- error strings (oracle: pcre2test -error) ---
    let ebuf = with_alloc(256)
    var codes: [6]c_int = [101, -1, -48, -45, -68, -34]
    var i: i32 = 0
    while i < 6:
        let erc = pcre2_get_error_message_8(codes[i], ebuf, 256)
        printf(c"err %d rc=%d msg=%s\n".ptr, codes[i], erc, ebuf as *const i8)
        i = i + 1
    let trunc = pcre2_get_error_message_8(-1, ebuf, 4)
    printf(c"trunc rc=%d msg=%s\n".ptr, trunc, ebuf as *const i8)
    printf(c"zerosize rc=%d\n".ptr, pcre2_get_error_message_8(-1, ebuf, 0))
    // --- config (oracle: pcre2test -C values for 10.x) ---
    var w: c_uint = 0
    var cc2: [8]c_int = [0, 1, 3, 4, 5, 6, 9, 12]
    i = 0
    while i < 8:
        w = 0xdeadbeef as c_uint
        let crc = pcre2_config_8(cc2[i] as c_uint, &raw mut w as *mut c_void)
        printf(c"cfg %d rc=%d val=%u\n".ptr, cc2[i], crc, w)
        i = i + 1
    printf(c"cfg16 tableslen rc=%d val=%u\n".ptr, pcre2_config_8(15, &raw mut w as *mut c_void), w)
    printf(c"cfgbad rc=%d\n".ptr, pcre2_config_8(99, &raw mut w as *mut c_void))
    let vbuf = with_alloc(64)
    printf(c"cfgver rc=%d str=%s\n".ptr, pcre2_config_8(11, vbuf as *mut c_void), vbuf as *const i8)
    printf(c"cfguni rc=%d str=%s\n".ptr, pcre2_config_8(10, vbuf as *mut c_void), vbuf as *const i8)
    // --- JIT stub surface ---
    printf(c"jittarget=%s jitsize=%lu stacknull=%d\n".ptr, _pcre2_jit_get_target_8(), _pcre2_jit_get_size_8(null), (pcre2_jit_stack_create_8(1, 100, null) as i64) == 0)
    // --- maketables(null) vs default tables ---
    let t = pcre2_maketables_8(null)
    var bad: i32 = 0
    var k: i32 = 0
    while k < 1088:
        if unsafe { t[k] } != _pcre2_default_tables_8[k]: bad = bad + 1
        k = k + 1
    printf(c"maketables_bad=%d lccA=%u fcct=%u\n".ptr, bad, unsafe { t[65] }, unsafe { t[256 + 116] })
