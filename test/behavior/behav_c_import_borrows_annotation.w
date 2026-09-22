//! skip-on: windows #799: opendir/telldir/closedir are POSIX <dirent.h>, absent from MSVCRT (link-undefined on Windows); the facade lend-method rendering is covered on Windows by behav_c_facade_resource_drop_once
//! expect-stdout: ok

// D51 §16.2b.5: what the retired `borrows: ["telldir(0) -> opendir"]`
// annotation said is the facade clause `fn telldir` / `lend` — telldir
// borrows the directory opendir produced. The program's own facade lends
// the toolchain libc facade's `CDir`, and the lend is rendered as the method
// `d.telldir()`; the raw C name stays raw.

use c_import("typedef struct __dirstream DIR;
DIR *opendir(const char *name);
long telldir(DIR *dirp);
int closedir(DIR *dirp);
")

c facade dirpos:
    fn telldir
        lend

fn main:
    let d = CDir.opendir(".").unwrap()
    if d.telldir() >= 0:
        print("ok")
    else:
        print("bad-tell")
