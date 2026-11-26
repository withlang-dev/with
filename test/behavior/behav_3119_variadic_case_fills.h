#include <stdarg.h>
#include <stdlib.h>
typedef struct probe { long code; double seconds; int asked; } probe;
typedef struct span_t { int lo; int hi; } span_t;
typedef enum { INFO_CODE = 1, INFO_SECONDS = 2, INFO_SPAN = 3, INFO_MISSING = 4 } info_t;
#define PROBE_OK 0
#define PROBE_UNKNOWN 7
static inline probe *probe_open(void) { probe *p = (probe *)calloc(1, sizeof(probe)); p->code = 404; p->seconds = 1.5; return p; }
static inline void probe_close(probe *p) { free(p); }
static inline int probe_asked(probe *p) { return p->asked; }
static inline int probe_getinfo(probe *p, info_t info, ...) {
    va_list ap; va_start(ap, info); int rc = PROBE_OK; p->asked++;
    if (info == INFO_CODE) { long *out = va_arg(ap, long *); *out = p->code; }
    else if (info == INFO_SECONDS) { double *out = va_arg(ap, double *); *out = p->seconds; }
    else if (info == INFO_SPAN) { span_t *out = va_arg(ap, span_t *); out->lo = 3; out->hi = 9; }
    else rc = PROBE_UNKNOWN;
    va_end(ap); return rc;
}
static inline int limit_get(info_t info, ...) {
    va_list ap; va_start(ap, info); int rc = PROBE_OK;
    if (info == INFO_CODE) { long *out = va_arg(ap, long *); *out = 64; } else rc = PROBE_UNKNOWN;
    va_end(ap); return rc;
}
