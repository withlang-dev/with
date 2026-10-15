/* D134 (§16.2b.6): a tree whose nodes are borrowed from a document and
 * from an owned node — libxml2's shape. A `dc` owns a root `nd`; an `nd`
 * may be free-standing (nd_new) and owns its children either way. */
void *malloc(unsigned long size);
void *calloc(unsigned long count, unsigned long size);
void free(void *p);

typedef struct nd { struct nd *first; struct nd *next; int id; } nd;
typedef struct dc { nd *root; int id; } dc;

static inline nd *nd_new(int id) { nd *n = (nd *)calloc(1, sizeof(nd)); n->id = id; return n; }
static inline void nd_free(nd *n) { nd *c = n->first; while (c) { nd *x = c->next; nd_free(c); c = x; } free(n); }
static inline nd *nd_first(nd *n) { return n->first; }
static inline nd *nd_next(nd *n) { return n->next; }
static inline int nd_id(nd *n) { return n->id; }
/* Attaches a fresh child with the given id and returns the parent. */
static inline int nd_grow(nd *n, int id) { nd *c = nd_new(id); c->next = n->first; n->first = c; return id; }

static inline dc *dc_new(int id) { dc *d = (dc *)calloc(1, sizeof(dc)); d->id = id; d->root = nd_new(id * 10); return d; }
static inline void dc_free(dc *d) { nd_free(d->root); free(d); }
static inline nd *dc_root(dc *d) { return d->root; }
static inline int dc_id(dc *d) { return d->id; }
