//! expect-stdout: 8 2
//! expect-stdout: ok

// #1915: three shapes of mingw-w64's headers — the Windows libc c_import
// parses now — each in its smallest form, that failed a whole-header import
// of windows.h:
// - UNREFERENCED_PARAMETER(P) is `{(P) = (P);}`: an inline body assigning a
//   parameter through parentheses must bind it mutably (`cannot assign to
//   immutable variable`).
// - An inline body that only calls an inline function the import omits
//   (winbase.h's InitializeThreadpoolEnvironment calling winnt.h's
//   TpInitializeCallbackEnviron, omitted over an opaque bitfield record) is
//   omitted with it, not emitted naming a symbol the import never declares.
// - A #pragma pack(1) record whose flexible array follows a narrower field
//   (mmeapi.h, winioctl.h): its accessor takes the field's raw address, since
//   no reference to an underaligned field may exist (§16.4).

use c_import("typedef struct Env { int version; struct { unsigned a : 1; unsigned b : 1; } s; } Env;\nstatic inline void env_init(Env *e) { e->version = 3; }\nstatic inline void env_setup(Env *e) { env_init(e); }\nstatic inline int bump(int x) { (x) = (x) + 1; return x; }\n#pragma pack(push, 1)\ntypedef struct Packed { char tag; long long items[1]; } Packed;\n#pragma pack(pop)\nstatic inline int packed_size(void) { return (int)sizeof(Packed); }\n")

fn main:
    let p = Packed { tag: 1, _items: [7] }
    let first = unsafe { *p.items() }
    print(f"{bump(first as i32)} {packed_size() - 7}")
    print("ok")
