#pragma once
/* #2403: a C type whose prototype c_import presents as a method (xdoc.root). */
typedef struct b2403_node { int v; } b2403_node;
typedef struct b2403_doc { b2403_node *root; } b2403_doc;
static b2403_node b2403_the_node = { 3 };
static b2403_doc b2403_the_doc = { &b2403_the_node };
static inline b2403_doc *b2403_doc_parse(const char *s) { (void)s; return &b2403_the_doc; }
static inline b2403_node *b2403_doc_root(b2403_doc *d) { return d->root; }
