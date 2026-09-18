use std.libc

fn expect_bytes(p: *mut i8, s: *const i8, n: i64):
    var i: i64 = 0
    while i < n:
        assert(unsafe *(p + i) == unsafe *(s + i))
        i = i + 1

fn main:
    let path = c"/tmp/with_audit_libc_stdio.txt".ptr
    let f = fopen(path, c"w".ptr)
    assert((f as i64) != 0)
    assert(fputs(c"hello ".ptr, f) >= 0)
    assert(fputc(119, f) == 119)
    assert(fprintf(f, c"%s %d\n".ptr, c"n=".ptr, 7) == 5)
    assert(fflush(f) == 0)
    assert(fileno(f) >= 0)
    assert(ferror(f) == 0)
    assert(fclose(f) == 0)
    let g = fopen(path, c"r".ptr)
    assert((g as i64) != 0)
    var buf: [32]i8 = [0 as i8; 32]
    let bp = (&raw mut buf) as *mut [32]i8 as *mut i8
    assert((fgets(bp, 32, g) as i64) == (bp as i64))
    expect_bytes(bp, c"hello wn= 7\n".ptr, 13)
    assert(fgetc(g) == -1)
    assert(feof(g) != 0)
    assert(fclose(g) == 0)
    expect_bytes(strerror(2), c"No such file or directory".ptr, 25)
    perror(c"audit".ptr)
    assert(unlink(path) == 0)
    assert((fopen(path, c"r".ptr) as i64) == 0)
    print("ok")
