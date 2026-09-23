/* D51 stage 6 (ruling §26-§30, spec §16.2b.6): a counting parent/child C
 * API for the dependency fixtures. A `db` is the parent; an `st` (statement)
 * is produced from it and touches it when finalized, as sqlite3_finalize
 * touches its connection — so a child finalized after its parent is closed
 * reads freed memory (logged as 9999 below). Every close and
 * finalize is appended to a shared event log (the destroy-order witness):
 *   1000 + st id        st_finalize
 *   2000 + db id * 10 + statements still open when it closed   db_close
 *   3000 + db id * 10 + statements still open                  db_close_v2
 *   4000 + snap id      snap_free
 *   5000 + link id      link_free
 *   6000 + backup id    backup_finish
 *   7000 + cursor id    cur_close
 *   8000 + iter id      it_end
 *   9999                a finalize that found its database already closed
 *                       (a closed db is marked before it is freed; with
 *                       the debug allocator's scribble the read is freed memory)
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

typedef struct db { Log log; int id; int open; } db;
typedef struct st { db *owner; int id; } st;

static inline db *db_new(Log l, int id) { db *d = (db *)malloc(sizeof(db)); d->log = l; d->id = id; d->open = 0; return d; }
static inline void db_close(db *d) { log_push(d->log, 2000 + d->id * 10 + d->open); d->open = -1000; free(d); }
static inline int db_close_v2(db *d, int how) { log_push(d->log, 3000 + d->id * 10 + d->open); d->open = -1000; free(d); return how; }
static inline int db_id(db *d) { return d->id; }

static inline st *st_make(db *d, int id) { st *s = (st *)malloc(sizeof(st)); s->owner = d; s->id = id; d->open = d->open + 1; return s; }
/* Out-parameter production: a negative id fails and produces nothing. */
static inline int db_prepare(db *d, int id, st **out) { if (id < 0) { return 1; } *out = st_make(d, id); return 0; }
/* Direct return: NULL for a negative id. */
static inline st *st_new(db *d, int id) { if (id < 0) { return 0; } return st_make(d, id); }
static inline void st_finalize(st *s) { if (s->owner->open < 0) { log_push(s->owner->log, 9999); } s->owner->open = s->owner->open - 1; log_push(s->owner->log, 1000 + s->id); free(s); }
static inline int st_step(st *s) { return s->owner->id * 100 + s->id; }

/* Independent: a snapshot copies what it needs from its db and never reads
 * it again, so it may outlive it (the facade states `independent`). */
typedef struct snap { Log log; int id; } snap;
static inline snap *snap_take(db *d, int id) { snap *s = (snap *)malloc(sizeof(snap)); s->log = d->log; s->id = id * 10 + d->id; return s; }
static inline void snap_free(snap *s) { log_push(s->log, 4000 + s->id); free(s); }
static inline int snap_id(snap *s) { return s->id; }

/* A link reads the db it was made on when freed, never the second one it
 * was given (the facade states `borrows param 0`). */
typedef struct lk { db *a; int id; } lk;
static inline lk *link_new(db *a, db *b, int id) { lk *k = (lk *)malloc(sizeof(lk)); k->a = a; k->id = id * 10 + b->id; a->open = a->open + 1; return k; }
static inline void link_free(lk *k) { k->a->open = k->a->open - 1; log_push(k->a->log, 5000 + k->id); free(k); }

/* A backup reads both of its dbs when finished: two parents, by default. */
typedef struct bk { db *dest; db *src; int id; } bk;
static inline bk *backup_init(db *dest, db *src, int id) { bk *b = (bk *)malloc(sizeof(bk)); b->dest = dest; b->src = src; b->id = id; dest->open = dest->open + 1; src->open = src->open + 1; return b; }
static inline void backup_finish(bk *b) { b->dest->open = b->dest->open - 1; b->src->open = b->src->open - 1; log_push(b->dest->log, 6000 + b->id * 10 + b->src->id); free(b); }

/* A cursor opens over a db, or blank over none: one resource, one
 * producer with a parent and one without. */
typedef struct cur { db *owner; Log log; int id; } cur;
static inline cur *cur_open(db *d, int id) { cur *c = (cur *)malloc(sizeof(cur)); c->owner = d; c->log = d->log; c->id = id; d->open = d->open + 1; return c; }
static inline cur *cur_blank(Log l, int id) { cur *c = (cur *)malloc(sizeof(cur)); c->owner = 0; c->log = l; c->id = id; return c; }
static inline void cur_close(cur *c) { if (c->owner != 0) { c->owner->open = c->owner->open - 1; } log_push(c->log, 7000 + c->id); free(c); }

/* In-place iteration state initialized over a db (a dependent in-place
 * resource: its `init` receives the parent). */
typedef struct { db *owner; int id; int pos; } iter_state;
static inline void it_init(iter_state *it, db *d, int id) { it->owner = d; it->id = id; it->pos = 0; d->open = d->open + 1; }
static inline void it_end(iter_state *it) { it->owner->open = it->owner->open - 1; log_push(it->owner->log, 8000 + it->id); }
