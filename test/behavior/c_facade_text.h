/* D51 stage 7 fixtures (ruling §31-§43, spec §16.2b.7-§16.2b.8): foreign
 * strings, owned foreign text and foreign-state domains, over a tiny
 * in-header library so the fixtures need no link. A `note` owns a text
 * buffer ("note-<id>"); `note_text` lends a view into it that `note_fill`
 * rewrites and `note_len` only reads; `strdup` hands back text the caller
 * process-wide diagnostic buffer that `note_fail` rewrites and `note_pure`
 * leaves alone — the domain example; `note_version` is static storage.
 *
 * No inline body takes a `const char *`: a With `str` lent to one is not
 * marshalled yet (#1589), so the string-taking operations are libc
 * prototypes.
 */
void *malloc(unsigned long size);
void free(void *p);
unsigned long strlen(const char *s);
char *strdup(const char *s);
char *strchr(const char *s, int c);

typedef struct note { char buf[16]; int id; } note;

static inline note *note_new(int id) {
    note *n = (note *)malloc(sizeof(note));
    n->buf[0] = 'n'; n->buf[1] = 'o'; n->buf[2] = 't'; n->buf[3] = 'e'; n->buf[4] = '-';
    n->buf[5] = (char)('0' + id % 10); n->buf[6] = 0;
    if (id < 0) { n->buf[0] = 0; }
    n->id = id;
    return n;
}
static inline void note_free(note *n) { free(n); }
static inline int note_id(note *n) { return n->id; }

/* A second note made from the first: a dependent child of it. */
typedef struct twin { note *parent; } twin;
static inline twin *twin_new(note *parent) { twin *t = (twin *)malloc(sizeof(twin)); t->parent = parent; return t; }
static inline void twin_free(twin *t) { free(t); }
static inline int twin_id(twin *t) { return t->parent->id; }

/* A view into the note's own buffer; NULL when the note holds no text. */
static inline const char *note_text(note *n) { if (n->buf[0] == 0) { return 0; } return n->buf; }

/* Rewrites the buffer with `count` copies of `c`: every earlier note_text
 * view is stale. */
static inline int note_fill(note *n, int c, int count) {
    int i = 0;
    while (i < count && i < 15) { n->buf[i] = (char)c; i = i + 1; }
    n->buf[i] = 0;
    return i;
}

/* Reads the buffer without touching it. */
static inline int note_len(note *n) { return (int)strlen(n->buf); }

/* The domain example uses libc's strerror, whose text lives in a
 * process-wide buffer; note_fail and note_pure are operations of the same
 * library, one preserving that domain and one stating nothing. */
char *strerror(int code);
static inline int note_fail(int code) { return code; }
static inline int note_pure(int x) { return x + 1; }

/* Static storage: valid for the whole program. */
static inline const char *note_version(void) { return "note 1.0"; }
