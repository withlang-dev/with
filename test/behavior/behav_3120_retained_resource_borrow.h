#include <stdarg.h>
#include <stdlib.h>

typedef struct slist { int count; } slist;
typedef struct mime { int parts; } mime;
typedef struct easy { const slist *headers; const mime *body; } easy;

#define OPT_HEADERS 1
#define OPT_CLEAR_HEADERS 2
#define OPT_MIME 3
#define H_OK 0

static int g_live = 0;

static inline int live_count(void) { return g_live; }

static inline slist *slist_new(void) {
    slist *s = (slist *)calloc(1, sizeof(slist));
    s->count = 2;
    g_live++;
    return s;
}
static inline void slist_free(slist *s) { if (s) { g_live--; free(s); } }
static inline int slist_count(const slist *s) { return s ? s->count : -1; }
static inline int slist_push(slist *s) { if (s) s->count++; return s ? s->count : -1; }

static inline mime *mime_new(void) {
    mime *m = (mime *)calloc(1, sizeof(mime));
    m->parts = 3;
    g_live++;
    return m;
}
static inline void mime_free(mime *m) { if (m) { g_live--; free(m); } }
static inline int mime_parts(const mime *m) { return m ? m->parts : -1; }
static inline int mime_add(mime *m) { if (m) m->parts++; return m ? m->parts : -1; }

static inline easy *easy_new(void) {
    easy *e = (easy *)calloc(1, sizeof(easy));
    g_live++;
    return e;
}
static inline void easy_free(easy *e) { if (e) { g_live--; free(e); } }
static inline void easy_reset(easy *e) {
    if (e) {
        e->headers = NULL;
        e->body = NULL;
    }
}
static inline int easy_setopt(easy *e, int opt, ...) {
    va_list ap;
    va_start(ap, opt);
    if (opt == OPT_HEADERS) {
        e->headers = va_arg(ap, const slist *);
    } else if (opt == OPT_CLEAR_HEADERS) {
        (void)va_arg(ap, int);
        e->headers = NULL;
    } else if (opt == OPT_MIME) {
        e->body = va_arg(ap, const mime *);
    }
    va_end(ap);
    return H_OK;
}
static inline int easy_perform(const easy *e) {
    int total = 0;
    if (e->headers) total += e->headers->count * 10;
    if (e->body) total += e->body->parts;
    return total;
}
