//! skip-on: windows #799: uses tmpfile() (MSVCRT creates it in the drive root — privilege-dependent), POSIX fdopen/dup and a hardcoded Unix "/tmp/" path absent on Windows; the libc facade's destroy-once rendering is covered on Windows by behav_c_import_owning_wrapper_strdup
//! expect-stdout: fopen closed 1
//! expect-stdout: tmpfile closed 1
//! expect-stdout: fdopen closed 1
//! expect-stdout: missing none
//! expect-stdout: ok

// D51 §16.2b / ruling §5: libc's FILE is modeled by the toolchain libc facade
// (compiler/LibcFacade.w): fopen, fdopen and tmpfile each produce a `CFile`
// whose Drop calls fclose exactly once. A failed fopen is `None` — no Drop
// is armed over NULL (fclose(NULL) is undefined). The witness is the file's
// descriptor: open while the CFile lives, closed after it drops (`dup` of a
// closed descriptor fails). `fileno` is this program's own facade lend of
// the toolchain's CFile, rendered as the method `f.fileno()`.

use c_import("typedef struct _IO_FILE FILE;
FILE *fopen(const char *path, const char *mode);
FILE *fdopen(int fd, const char *mode);
FILE *tmpfile(void);
int fclose(FILE *f);
int fileno(FILE *f);
int dup(int fd);
int close(int fd);
")

c facade stdio_probe:
    fn fileno
        lend

// 1 when `fd` no longer names an open descriptor.
fn closed(fd: c_int) -> i32:
    let probe = dup(fd)
    if probe < 0: return 1
    close(probe)
    0

fn fd_of(f: CFile) -> c_int: f.fileno()

fn main:
    let a = CFile.fopen("/tmp/with_phase8_357.tmp", "w").unwrap()
    let fa = a.fileno()
    drop(a)
    print(f"fopen closed {closed(fa)}")
    let t = CFile.tmpfile().unwrap()
    let ft = fd_of(t)
    print(f"tmpfile closed {closed(ft)}")
    let g = CFile.fdopen(dup(1), "w").unwrap()
    let fg = g.fileno()
    drop(g)
    print(f"fdopen closed {closed(fg)}")
    match CFile.fopen("/nonexistent-with-357/x", "r"):
        Some(_) => print("missing bad")
        None => print("missing none")
    print("ok")
