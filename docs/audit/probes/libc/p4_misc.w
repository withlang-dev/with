use std.libc

fn main:
    var dst: [16]i8 = [0 as i8; 16]
    let d = (&raw mut dst) as *mut [16]i8 as *mut i8
    assert((strcpy(d, c"abc".ptr) as i64) == (d as i64))
    assert(unsafe *d == 97)
    assert(unsafe *(d + 3) == 0)
    assert((strncpy(d, c"xy".ptr, 16 as u64) as i64) == (d as i64))
    assert(unsafe *(d + 2) == 0)
    let hay = c"hello world".ptr
    assert((strstr(hay, c"world".ptr) as i64) == ((hay as i64) + 6))
    assert((strstr(hay, c"zzz".ptr) as i64) == 0)
    assert((strrchr(hay, 111) as i64) == ((hay as i64) + 7))
    assert((strrchr(hay, 122) as i64) == 0)
    // glibc <locale.h>: LC_ALL=6; NULL query returns current locale, non-null
    assert((setlocale(6, 0 as *const i8) as i64) != 0)
    var tpl: [32]i8 = [0 as i8; 32]
    let t = (&raw mut tpl) as *mut [32]i8 as *mut i8
    strcpy(t, c"/tmp/with_audit_XXXXXX".ptr)
    let tfd = mkstemp(t)
    assert(tfd >= 0)
    assert(close(tfd) == 0)
    assert(unlink(t) == 0)
    var rp: [8]i8 = [0 as i8; 8]
    let rpp = (&raw mut rp) as *mut [8]i8 as *mut i8
    assert((realpath(c"/".ptr, rpp) as i64) == (rpp as i64))
    assert(unsafe *rpp == 47)
    assert(unsafe *(rpp + 1) == 0)
    // Linux <sys/resource.h>: RLIMIT_NOFILE=7
    var rl = rlimit { rlim_cur: 0, rlim_max: 0 }
    assert(getrlimit(7, &raw mut rl) == 0)
    assert(rl.rlim_cur > 0)
    assert(rl.rlim_cur <= rl.rlim_max)
    assert(setrlimit(7, &raw const rl) == 0)
    let t0 = time(0 as *mut i64)
    assert(t0 > 1700000000)
    var t2: i64 = 0
    assert(time(&raw mut t2) != 0)
    assert(t2 >= t0)
    let c1 = clock()
    let c2 = clock()
    assert(c2 >= c1)
    assert(isatty(0) == 0)
    print("ok")
