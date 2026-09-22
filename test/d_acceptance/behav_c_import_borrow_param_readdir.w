//! skip-on: windows #799: opendir/readdir/rewinddir/closedir are POSIX <dirent.h>, absent from MSVCRT (link-undefined on Windows); the libc facade's destroy-once rendering is covered on Windows by behav_c_import_owning_wrapper_strdup
//! expect-stdout: entries ok
//! expect-stdout: rewound ok
//! expect-stdout: closed 1
//! expect-stdout: missing none
//! expect-stdout: ok

// D51 §16.2b / ruling §5: libc's DIR is modeled by the toolchain libc facade
// (compiler/LibcFacade.w): opendir produces a `CDir` whose Drop calls
// closedir exactly once, and readdir/rewinddir lend it — rendered as the
// methods `d.readdir()` / `d.rewinddir()`, so user code iterates a directory
// without touching the raw handle and without `unsafe`. The dirent pointer
// return is a raw pointer, never dereferenced here. The witness for
// closedir is the directory's descriptor (`dirfd`), closed after the CDir
// drops. A failed opendir is `None`: no Drop over NULL.

use c_import("typedef struct __dirstream DIR;
struct dirent;
DIR *opendir(const char *name);
struct dirent *readdir(DIR *dirp);
void rewinddir(DIR *dirp);
int closedir(DIR *dirp);
int dirfd(DIR *dirp);
int dup(int fd);
int close(int fd);
")

c facade dir_probe:
    fn dirfd
        lend

fn count(d: &CDir) -> i32:
    var n = 0
    while d.readdir() != null:
        n = n + 1
    n

fn main:
    let d = CDir.opendir(".").unwrap()
    let n = count(&d)
    print(f"entries {if n >= 2: \"ok\" else: \"bad\"}")
    d.rewinddir()
    print(f"rewound {if count(&d) == n: \"ok\" else: \"bad\"}")
    let fd = d.dirfd()
    drop(d)
    let probe = dup(fd)
    print(f"closed {if probe < 0: 1 else: 0}")
    match CDir.opendir("/nonexistent-with-357"):
        Some(_) => print("missing bad")
        None => print("missing none")
    print("ok")
