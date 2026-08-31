//! skip-on: windows #799: uses tmpfile() (MSVCRT creates it in the drive root — privilege-dependent) and fopen() on a hardcoded Unix "/tmp/" path absent on Windows; the COwned-fclose owning-wrapper mechanism it exercises is already covered on Windows by behav_c_import_owning_wrapper_strdup
//! expect-stdout: ok

// [Phase8] #357: stdio owning constructors. fopen and tmpfile each return an owned
// FILE* that must be released with fclose. They are generated as COwned_<fn> wrapper
// types whose Drop calls fclose exactly once, reusing the same curated owning-wrapper
// machinery as strdup→free — so the handle auto-closes when the wrapper leaves scope.
// `.handle()` borrows the raw FILE* without taking ownership.

use c_import("typedef struct _IO_FILE FILE;\nFILE *fopen(const char *path, const char *mode);\nFILE *tmpfile(void);\nstatic inline const char *fp357(void){return \"/tmp/with_phase8_357.tmp\";}\nstatic inline const char *fm357(void){return \"w\";}\n")

fn main:
    unsafe:
        let t = tmpfile()
        let th = t.handle()
        let f = fopen(fp357(), fm357())
        let fh = f.handle()
        if th != null and fh != null:
            print("ok")
        else:
            print("bad")
        // t and f leave scope here → COwned Drop runs fclose on each exactly once
