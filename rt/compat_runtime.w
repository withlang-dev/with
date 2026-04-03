// rt/compat_runtime.w -- tiny compiler/runtime compatibility surface needed on
// the helpers-based path before the full runtime is pure With.

extern fn strlen(s: *const u8) -> i64
extern fn malloc(size: u64) -> *mut u8

fn make_str(ptr: *const u8, len: i64) -> str:
    var raw: [2]i64 = [ptr as i64, len]
    let p = &raw as *const str
    *p

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
