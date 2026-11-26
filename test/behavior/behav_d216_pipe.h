#include <stdlib.h>
typedef struct { int active; } Overlay;
typedef struct { int tag; unsigned char* data; int size; } Msg;
typedef struct pipe_s { int n; int freed; int depth; } pipe_t;
#define CB_OVERLAY 331
static Overlay g_overlay = { 1 };
static inline pipe_t* pipe_open(void) { return (pipe_t*)calloc(1, sizeof(pipe_t)); }
static inline void pipe_close(pipe_t* p) { free(p); }
static inline int pipe_depth(pipe_t* p) { return p->depth; }
static inline int pipe_freed(pipe_t* p) { return p->freed; }
static inline _Bool pipe_next(pipe_t* p, Msg* out) { p->n++; if (p->n > 2) return 0; out->tag = CB_OVERLAY; out->data = (unsigned char*)&g_overlay; out->size = sizeof g_overlay; return 1; }
static inline void pipe_free(pipe_t* p) { p->freed++; }
