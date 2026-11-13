//! expect-stdout: first 1 0
//! expect-stdout: 97 98
//! expect-stdout: second 1 1
//! expect-stdout: 97 98

// §31.8.6: the pointer is read at each call, never cached, so a pointer a
// raw call replaced is the one called. `lib_use_other` assigns the global
// (so it stays raw); the second release runs the replacement. The text is
// a static buffer, so each release only counts.
use c_import("typedef void (*free_fn)(void *p);
static char lib_text[4];
static int lib_first = 0;
static int lib_second = 0;
static inline void lib_release_first(void *p) { lib_first = lib_first + 1; }
static inline void lib_release_second(void *p) { lib_second = lib_second + 1; }
static free_fn lib_free = lib_release_first;
static inline void lib_use_other(void) { lib_free = lib_release_second; }
static inline int lib_first_count(void) { return lib_first; }
static inline int lib_second_count(void) { return lib_second; }
static inline char *lib_name(void) { lib_text[0] = 'a'; lib_text[1] = 'b'; lib_text[2] = 0; return lib_text; }
")

c contract lib:
    fn lib_name
        text return, owned, freed by lib_free

fn show(n: Option[List[u8]]):
    let bytes = n.unwrap()
    print(f"{bytes[0]} {bytes[1]}")

fn main:
    let one = lib_name()
    print(f"first {lib_first_count()} {lib_second_count()}")
    show(one)
    unsafe { lib_use_other() }
    let two = lib_name()
    print(f"second {lib_first_count()} {lib_second_count()}")
    show(two)
