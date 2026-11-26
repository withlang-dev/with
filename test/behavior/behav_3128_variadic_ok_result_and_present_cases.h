#include <stdarg.h>
#include <stdlib.h>

typedef int (*req_cb)(int n, void *ud);

typedef struct req {
    int count;
    req_cb cb;
    void *ud;
    const char *body;
    long body_len;
} req;

static req the_req;

static inline req *req_new(void) {
    the_req.count = 0;
    the_req.cb = 0;
    the_req.ud = 0;
    the_req.body = 0;
    the_req.body_len = 0;
    return &the_req;
}

static inline void req_free(req *r) { (void)r; }

static inline void req_reset(req *r) {
    r->cb = 0;
    r->ud = 0;
    r->body = 0;
    r->body_len = 0;
}

#define ROPT_COUNT 1
#define ROPT_CB 2
#define ROPT_UD 3
#define ROPT_BODY 4
#define ROPT_BODY_LEN 5
#define ROPT_CLEAR 6
#define ROPT_GET_COUNT 7
#define R_OK 0
#define R_ERR 1

static inline int req_set(req *r, int opt, ...) {
    va_list ap;
    va_start(ap, opt);
    int rc = R_OK;
    if (opt == ROPT_COUNT) {
        int v = va_arg(ap, int);
        if (v < 0) rc = R_ERR; else r->count = v;
    } else if (opt == ROPT_CB) {
        r->cb = (req_cb)va_arg(ap, void *);
    } else if (opt == ROPT_UD) {
        r->ud = va_arg(ap, void *);
    } else if (opt == ROPT_BODY) {
        r->body = (const char *)va_arg(ap, const void *);
    } else if (opt == ROPT_BODY_LEN) {
        r->body_len = va_arg(ap, long);
    } else if (opt == ROPT_CLEAR) {
        (void)va_arg(ap, int);
        r->body = 0;
        r->body_len = 0;
    } else if (opt == ROPT_GET_COUNT) {
        int *out = va_arg(ap, int *);
        *out = r->count;
    } else {
        rc = R_ERR;
    }
    va_end(ap);
    return rc;
}

static inline int req_run(req *r) {
    int sum = r->count + (int)r->body_len;
    if (r->cb) sum += r->cb(r->count, r->ud);
    return sum;
}
