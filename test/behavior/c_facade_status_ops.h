/* D92 (ruling Amendment 3; spec §16.2b.4, §16.2b.11): a status-returning C
 * API for behav_c_facade_status_operations. A `db` remembers the status of
 * its last operation, and db_errmsg describes it, as sqlite3_errmsg
 * describes a connection's. */
void *malloc(unsigned long size);
void free(void *p);

#define DB_OK 0
#define DB_BUSY 5
#define DB_ROW 100
#define DB_DONE 101

typedef struct db { int rows; int last; int ran; } db;
static inline db *db_new(int rows) { db *d = (db *)malloc(sizeof(db)); d->rows = rows; d->last = 0; d->ran = 0; return d; }
static inline void db_close(db *d) { free(d); }
/* Runs `code` `times` times: 0 succeeds, anything else is the failure. */
static inline int db_run(db *d, int code, int times) { d->last = code; if (code == 0) { d->ran = d->ran + times; } return code; }
static inline int db_ran(db *d) { return d->ran; }
/* A row while rows remain, then done; a db made with negative rows is busy. */
static inline int db_step(db *d) {
    if (d->rows < 0) { d->last = DB_BUSY; return DB_BUSY; }
    d->last = 0;
    if (d->rows == 0) { return DB_DONE; }
    d->rows = d->rows - 1;
    return DB_ROW;
}
static inline const char *db_errmsg(db *d) { return d->last == 0 ? "not an error" : d->last == DB_BUSY ? "database is busy" : "no such code"; }

/* A resource that describes no failure. */
typedef struct plain { int pokes; } plain;
static inline plain *plain_new(void) { plain *p = (plain *)malloc(sizeof(plain)); p->pokes = 0; return p; }
static inline void plain_free(plain *p) { free(p); }
static inline int plain_poke(plain *p, int code) { p->pokes = p->pokes + 1; return code; }
