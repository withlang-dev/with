//! expect-stdout: 1 2 3
//! expect-stdout: 7 9 2
//! expect-stdout: 5 6
//! expect-stdout: 11 12 21 22
//! expect-stdout: 4 8
//! expect-stdout: 10 20 30
//! expect-stdout: 41 42 45
//! expect-stdout: 2 3 4
//! expect-stdout: 1 2

// C11 6.2.4p3: a local declared `static` is one object for the whole
// program, initialized once. It was translated as an ordinary local, so
// every call started from the initializer again ("1 1 1"). 6.2.2p4: `extern`
// in a body declares no object, it names the file-scope one; it was a fresh
// local too.
use c_import("typedef struct { int a; int b; } Pair;
static int shared = 40;
static inline int add1(int x) { return x + 1; }
static inline int ext(void) { extern int shared; shared = shared + 1; return shared; }
static inline int ext_goto(int step) { extern int shared; if (step == 0) goto out; shared = shared + step;
out: return shared; }
static inline int call(int x) { static int (*f)(int) = add1; return f(x); }
static inline int lazy(int x) { static int (*f)(int); if (!f) f = add1; return f(x); }
static inline int per_thread(void) { static _Thread_local int t = 0; t = t + 1; return t; }
static inline int next_id(void) { static int counter = 0; counter = counter + 1; return counter; }
static inline int cell(int i, int set, int v) { static int cells[4]; if (set) cells[i] = v; return cells[i]; }
static inline int pair_bump(int which) { static Pair p = { 4, 5 }; if (which) { p.b = p.b + 1; return p.b; } p.a = p.a + 1; return p.a; }
static inline int two_blocks(int which) { if (which) { static int n = 10; n = n + 1; return n; } else { static int n = 20; n = n + 1; return n; } }
static inline int with_goto(int step) { static int total = 0; if (step == 0) goto done; total = total + step;
done: return total; }
static inline int table(int i) { static const int values[3] = { 10, 20, 30 }; return values[i]; }
")

fn main:
    print(f"{next_id()} {next_id()} {next_id()}")
    cell(0, 1, 7)
    cell(1, 1, 9)
    cell(3, 1, 2)
    print(f"{cell(0, 0, 0)} {cell(1, 0, 0)} {cell(3, 0, 0)}")
    print(f"{pair_bump(0)} {pair_bump(1)}")
    print(f"{two_blocks(1)} {two_blocks(1)} {two_blocks(0)} {two_blocks(0)}")
    with_goto(4)
    print(f"{with_goto(0)} {with_goto(4)}")
    print(f"{table(0)} {table(1)} {table(2)}")
    print(f"{ext()} {ext()} {ext_goto(3)}")
    print(f"{call(1)} {lazy(2)} {lazy(3)}")
    print(f"{per_thread()} {per_thread()}")
