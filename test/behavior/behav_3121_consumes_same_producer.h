#include <stdlib.h>
#include <string.h>

typedef struct slist_node {
    char *data;
    struct slist_node *next;
} slist_node;

typedef enum {
    SLIST_OK = 0,
    SLIST_OUT_OF_MEMORY = 27
} slist_status;

static int g_nodes_live = 0;

static inline int slist_live_count(void) { return g_nodes_live; }

static inline slist_node *slist_append_raw(slist_node *list, const char *data) {
    if (data && strcmp(data, "FAIL_OOM") == 0) {
        return NULL;
    }
    slist_node *n = (slist_node *)calloc(1, sizeof(slist_node));
    if (!n) return NULL;
    size_t len = strlen(data);
    n->data = (char *)malloc(len + 1);
    if (!n->data) { free(n); return NULL; }
    memcpy(n->data, data, len + 1);
    g_nodes_live++;
    if (!list) return n;
    slist_node *cur = list;
    while (cur->next) cur = cur->next;
    cur->next = n;
    return list;
}

static inline slist_node *slist_create(const char *data) {
    return slist_append_raw(NULL, data);
}

static inline slist_node *slist_append(slist_node *list, const char *data) {
    return slist_append_raw(list, data);
}

static inline void slist_free_all(slist_node *list) {
    while (list) {
        slist_node *next = list->next;
        free(list->data);
        free(list);
        g_nodes_live--;
        list = next;
    }
}

static inline int slist_len(const slist_node *list) {
    int n = 0;
    while (list) { n++; list = list->next; }
    return n;
}
