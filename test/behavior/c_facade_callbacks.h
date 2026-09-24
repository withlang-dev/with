/* D51 stage 9 (ruling §44-§51, spec §16.2b.9-10): a callback-taking C API
 * for the callback fixtures. A `db` runs a callback once for `db_exec`
 * (callback scope), keeps one registered callback and its userdata for
 * `db_fire` (retention), and owns one userdata it destroys through the
 * destroy callback handed with it (consume with destroy callback). Every
 * event is appended to a shared log (the order witness):
 *   1000 + id           a With userdata value dropped (the fixture logs it)
 *   2000 + db id        db_close
 *   3000 + db id        the owned userdata's destroy callback invoked by C
 *   4000 + n            a callback ran with argument n
 */
void *malloc(unsigned long size);
void *calloc(unsigned long count, unsigned long size);
void free(void *p);

typedef struct { int *n; int *ev; } Log;
static inline Log log_new(void) { Log l; l.n = (int *)calloc(1, sizeof(int)); l.ev = (int *)calloc(64, sizeof(int)); return l; }
static inline void log_free(Log l) { free(l.n); free(l.ev); }
static inline void log_push(Log l, int e) { if (*l.n < 64) { l.ev[*l.n] = e; *l.n = *l.n + 1; } }
static inline int log_len(Log l) { return *l.n; }
static inline int log_at(Log l, int i) { return l.ev[i]; }
static inline void log_reset(Log l) { *l.n = 0; }

typedef int (*db_cb)(void *ud, int n);
typedef void (*db_dtor)(void *ud);
typedef struct db { Log log; int id; int total; void *app; db_cb cb; void *owned; db_dtor owned_dtor; } db;

static inline db *db_new(Log l, int id) { db *d = (db *)malloc(sizeof(db)); d->log = l; d->id = id; d->total = 0; d->app = 0; d->cb = 0; d->owned = 0; d->owned_dtor = 0; return d; }
static inline void db_close(db *d) { if (d->owned_dtor) { log_push(d->log, 3000 + d->id); d->owned_dtor(d->owned); } log_push(d->log, 2000 + d->id); free(d); }
static inline int db_exec(db *d, db_cb cb, void *ud, int n) { log_push(d->log, 4000 + n); int r = cb(ud, n); d->total += r; return r; }
static inline int db_register(db *d, db_cb cb, void *app) { d->cb = cb; d->app = app; return 1; }
static inline int db_fire(db *d, int n) { if (!d->cb) return -1; log_push(d->log, 4000 + n); int r = d->cb(d->app, n); d->total += r; return r; }
static inline int db_set_owned(db *d, void *owned, db_dtor dtor) { if (d->owned_dtor) { log_push(d->log, 3000 + d->id); d->owned_dtor(d->owned); } d->owned = owned; d->owned_dtor = dtor; return 2; }
static inline int db_total(db *d) { return d->total; }
static inline int db_id(db *d) { return d->id; }
