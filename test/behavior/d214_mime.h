// D214 fixture: a producer whose parent may be absent.
#include <stdlib.h>
typedef struct easy { int n; } easy;
typedef struct mime { easy *parent; int parts; } mime;
static inline easy *easy_init(void) { easy *e = malloc(sizeof(easy)); if (e) e->n = 7; return e; }
static inline void easy_cleanup(easy *e) { free(e); }
static inline int easy_count(easy *e) { return e->n; }
static inline mime *mime_init(easy *e) { mime *m = malloc(sizeof(mime)); if (m) { m->parent = e; m->parts = e ? e->n : 1; } return m; }
static inline void mime_free(mime *m) { free(m); }
static inline int mime_parts(mime *m) { return m->parts; }
