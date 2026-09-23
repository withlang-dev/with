#ifndef BEHAV_C_IMPORT_ANON_FILE_SCOPE_RECORD_H
#define BEHAV_C_IMPORT_ANON_FILE_SCOPE_RECORD_H

/* #1396: file-scope records with no tag and no typedef name. libclang spells
   each `struct (unnamed at file:line:col)`; c_import emitted that spelling as
   a type name and the bindings failed to parse. A record some declaration
   uses is named after the first declarator that uses it; one nothing uses
   (winnt.h's C_ASSERT(TYPE_ALIGNMENT(T)) builds it inside an expression) is
   not emitted. */

typedef struct { int a; } anon_named_t;                 /* the typedef names it */
struct { int b; } anon_g1;                              /* anon_g1_anon */
static struct { int c; } anon_g2;                       /* anon_g2_anon */
extern struct { int d; long long e; } anon_g3[4];       /* anon_g3_anon */
struct { int f; } anon_a, anon_b;                       /* anon_a_anon, shared */
union { int u; float v; } anon_gu;                      /* anon_gu_anon */
enum { ANON_EA = 1, ANON_EB = 2 } anon_ge;              /* constants, c_uint var */
struct {
    struct { int x; } inner;                            /* anon_gn_anon_inner */
    union { int y; char z; };                           /* anon_gn_anon_anon_1 */
    int w;
} anon_gn;                                              /* anon_gn_anon */
struct { int r; short s; } anon_mk(void);               /* anon_mk_return_anon */
void anon_take(struct { int q; } *p);                   /* anon_take_p_anon */
typedef struct { int pa; } *anon_px_t;                  /* anon_px_t_anon */
struct { int s; } *anon_gp;                             /* anon_gp_anon */
typedef int anon_gz_anon;                               /* taken: anon_gz_anon_2 */
struct { char k; } anon_gz;
static const struct { int lo; int hi; } anon_k = { 3, 4 };  /* anon_k_anon */

/* winnt.h's shape: a record inside an expression that nothing can name. */
#define ANON_FIELD_OFFSET(type, field) ((long)(long long)&(((type *)0)->field))
#define ANON_TYPE_ALIGNMENT(t) ANON_FIELD_OFFSET(struct { char x; t test; }, test)
#define ANON_C_ASSERT(e) typedef char __ANON_C_ASSERT__[(e)?1:-1]
ANON_C_ASSERT(ANON_TYPE_ALIGNMENT(long long) == 8);

#endif
