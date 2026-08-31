//! skip-on: windows #799: opendir/readdir/closedir are POSIX <dirent.h>, absent from MSVCRT (link-undefined on Windows); the borrowed-owned-handle wrapper mechanism is already covered on Windows by behav_c_import_owning_wrapper_strdup
//! expect-stdout: ok

// [Phase8] #357 increment 2: readdir BORROWS the owned DIR — its curated
// wrapper takes &COwned_opendir and forwards .handle() internally, so user
// code iterates a directory without touching the raw handle. The DIR is
// closed exactly once by COwned_opendir's Drop. The dirent pointer return is
// borrowed and never dereferenced here (no layout dependency).

use c_import("typedef struct __dirstream DIR;\nstruct dirent;\nDIR *opendir(const char *name);\nstruct dirent *readdir(DIR *dirp);\nint closedir(DIR *dirp);\nstatic inline const char *dot357(void){return \".\";}\n")
use std.builtins.print_i32

fn main:
    unsafe:
        let d = opendir(dot357())
        if d.handle() == null:
            print("bad-open")
            return
        var n = 0
        while readdir(&d) != null:
            n = n + 1
        if n >= 2:
            print("ok")
        else:
            print_i32(n)
