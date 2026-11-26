#include <stdio.h>
typedef struct { int active; } Overlay;
typedef struct { long long id; int ok; } Stored;
typedef struct { int tag; unsigned char* data; int size; } Msg;
#define CB_OVERLAY 331
#define CB_STORED 1102
static Overlay g_overlay = { 1 };
static Stored g_stored = { 77, 1 };
static int g_n = 0;
static int g_freed = 0;
static inline _Bool msg_next(int pipe, Msg* out) { g_n++; if (g_n == 1) { out->tag = CB_OVERLAY; out->data = (unsigned char*)&g_overlay; out->size = sizeof g_overlay; return 1; } if (g_n == 2) { out->tag = CB_STORED; out->data = (unsigned char*)&g_stored; out->size = sizeof g_stored; return 1; } if (g_n == 3) { out->tag = CB_STORED; out->data = (unsigned char*)&g_stored; out->size = 2; return 1; } if (g_n == 4) { out->tag = CB_OVERLAY; out->data = 0; out->size = 0; return 1; } if (g_n == 5) { out->tag = 9; out->data = 0; out->size = 0; return 1; } return 0; }
static inline void msg_free(int pipe) { g_freed++; }
static inline int msg_freed(void) { return g_freed; }
