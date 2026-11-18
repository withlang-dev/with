//! expect-stdout: read 5
//! expect-stdout: close status 0
//! expect-stdout: closed 2

// #3177, D209 (§31, §16.2b.11): bzip2's shape. The closing function takes
// an error out-pointer first and the stream second, so the contract names
// the parameter that receives the resource: 'drop f(param 1)' with the
// error discarded for 'Drop', and 'destroys g(param 1)' as the explicit
// close for a caller who wants the status. An out-pointer of an ordinary
// function is discarded the same way.
use c_import("typedef struct bz { int open; } bz;
static bz the_bz;
static int closes;
static inline bz *bzOpen(void) { the_bz.open = 1; return &the_bz; }
static inline void bzReadClose(int *bzerror, bz *b) { *bzerror = 0; b->open = 0; closes++; }
static inline int bzReadCloseStatus(int *bzerror, bz *b) { *bzerror = 0; b->open = 0; closes++; return 0; }
static inline int bzProbe(int *bzerror, int n) { *bzerror = 7; return n + 1; }
static inline int bzCloses(void) { return closes; }
")

c contract bzip:
    resource Reader wraps *mut bz
        from bzOpen
        drop bzReadClose(param 1)
        destroys bzReadCloseStatus(param 1)
    fn bzReadClose
        param 0 discarded
    fn bzProbe
        param 0 discarded
    fn bzReadCloseStatus
        rename close
        param 0 discarded

fn main:
    if true:
        let _r = Reader.open().unwrap()
        print(f"read {bzProbe(4)}")
    let s = Reader.open().unwrap()
    print(f"close status {s.close()}")
    print(f"closed {bzCloses()}")
