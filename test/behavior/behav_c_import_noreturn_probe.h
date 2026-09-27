/* c_import's noreturn probe: each noreturn spelling makes a function `-> Never`,
   and nothing else does: not a GNU attribute of another kind, not a type named
   like noreturn_code_t, and not an unnamed record, whose spelling carries this
   file's path (which contains "noreturn"). */
typedef int noreturn_code_t;
void nr_touch(noreturn_code_t code);
void nr_touch_nothrow(int code) __attribute__ ((__nothrow__)) __attribute__ ((__const__));
void nr_touch_record(struct { int q; } *p);
void nr_stop_gnu(int code) __attribute__((noreturn));
void nr_stop_gnu_reserved(int code) __attribute__ ((__noreturn__));
_Noreturn void nr_stop_c11(void);
