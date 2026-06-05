#ifndef WITH_BOOTSTRAP_SYS_RESOURCE_H
#define WITH_BOOTSTRAP_SYS_RESOURCE_H

struct rlimit {
    unsigned long long rlim_cur;
    unsigned long long rlim_max;
};

#define RLIMIT_STACK 0

static inline int getrlimit(int resource, struct rlimit *rlp) {
    (void)resource;
    if (rlp) {
        rlp->rlim_cur = 0;
        rlp->rlim_max = 0;
    }
    return 0;
}

static inline int setrlimit(int resource, const struct rlimit *rlp) {
    (void)resource;
    (void)rlp;
    return 0;
}

#endif
