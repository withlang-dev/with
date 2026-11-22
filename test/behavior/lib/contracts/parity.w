// A contract a test imports with `use contracts.parity`: one modeled
// resource, and a header that also has constants, an enum, a record, a
// typedef, a global and a function the contract does not describe.
use c_import("#define PAR_LEVEL 6\n#define PAR_NAME \"par\"\ntypedef enum { PAR_A = 1, PAR_B = 2 } par_mode;\ntypedef struct par_point { int x; int y; } par_point;\ntypedef int par_id;\nstatic int par_static = 4;\ntypedef struct par_h { int mode; } par_h;\nstatic par_h par_one;\nstatic inline par_h *par_open(int mode) { par_one.mode = mode; return &par_one; }\nstatic inline void par_close(par_h *h) { h->mode = 0; }\nstatic inline int par_plain(int a) { return a + 1; }\n")

c contract parity:
    resource Handle wraps *mut par_h
        from par_open
        drop par_close
