/* D66 fixtures (spec §16.2b.6): borrowed record views. A `hold` owns a
 * record of its own, so `hold_rec` lends a view of the record backed by the
 * resource; `hold_bump` rewrites it and `hold_age` only reads; `rec_of`
 * returns a record no resource owns. The domain example is libc's:
 * `localeconv` returns a pointer to a process-wide record that any later
 * localeconv or setlocale call may overwrite. No inline body takes a
 * `const char *` (#1589). */
#include <locale.h>
void *malloc(unsigned long size);
void free(void *p);

typedef struct rec { int age; unsigned int version_num; const char *version; } rec;
typedef struct hold { rec r; } hold;

static inline hold *hold_new(int age) { hold *h = (hold *)malloc(sizeof(hold)); h->r.age = age; h->r.version_num = 5; h->r.version = "8.11.0"; return h; }
static inline void hold_free(hold *h) { free(h); }
static inline rec *hold_rec(hold *h) { if (h->r.age < 0) return 0; return &h->r; }
static inline void hold_bump(hold *h) { h->r.version_num += 1; }
static inline int hold_age(hold *h) { return h->r.age; }
static inline rec *rec_of(int age) { rec *r = (rec *)malloc(sizeof(rec)); r->age = age; r->version_num = 1; r->version = "x"; return r; }
