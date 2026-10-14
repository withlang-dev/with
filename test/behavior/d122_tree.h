// D122 fixtures: a document owning a tree of nodes, libxml2's shape.
#include <stdlib.h>
typedef struct xnode { struct xnode *first; struct xnode *next; int tag; } xnode;
typedef struct xdoc { xnode *root; } xdoc;
static inline xnode *xnode_new(int tag) { xnode *n = (xnode *)malloc(sizeof(xnode)); n->first = 0; n->next = 0; n->tag = tag; return n; }
static inline xdoc *xdoc_parse(const char *text) { xdoc *d = (xdoc *)malloc(sizeof(xdoc)); xnode *r = xnode_new(1); xnode *c = xnode_new(2); xnode *s = xnode_new(3); xnode *g = xnode_new(4); r->first = c; c->next = s; c->first = g; d->root = r; return d; }
static inline void xnode_free_tree(xnode *n) { if (!n) return; xnode_free_tree(n->first); xnode_free_tree(n->next); free(n); }
static inline void xdoc_free(xdoc *d) { xnode_free_tree(d->root); free(d); }
static inline xnode *xdoc_root(xdoc *d) { return d->root; }
static inline xnode *xnode_first_child(xnode *n) { return n->first; }
static inline xnode *xnode_next(xnode *n) { return n->next; }
static inline int xnode_tag(const xnode *n) { return n->tag; }
