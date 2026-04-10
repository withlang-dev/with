// Initialize PCRE2 default contexts.
// The With compiler doesn't emit global symbols for top-level var,
// so these definitions provide the storage that extern var references.

#include <stdlib.h>
#include <string.h>

typedef unsigned long pcre2_size_t;

typedef struct {
    void *(*malloc)(pcre2_size_t, void *);
    void (*free)(void *, void *);
    void *memory_data;
} pcre2_memctl;

// Default allocator functions
static void *default_malloc(pcre2_size_t size, void *data) {
    (void)data;
    return malloc(size);
}

static void default_free(void *block, void *data) {
    (void)data;
    free(block);
}

// PCRE2 context struct layouts (must match With-compiled struct layout)
// Each context starts with pcre2_memctl, followed by config fields.

// compile context: memctl + stack_guard + stack_guard_data + tables +
//   max_pattern_length + max_pattern_compiled_length + bsr_convention +
//   newline_convention + parens_nest_limit + extra_options +
//   max_varlookbehind + optimize
typedef struct {
    pcre2_memctl memctl;
    void *stack_guard;
    void *stack_guard_data;
    void *tables;
    pcre2_size_t max_pattern_length;
    pcre2_size_t max_pattern_compiled_length;
    unsigned int bsr_convention;
    unsigned int newline_convention;
    unsigned int parens_nest_limit;
    unsigned int extra_options;
    unsigned int max_varlookbehind;
    unsigned int optimize;
} pcre2_compile_context_8;

// match context: memctl + callout + callout_data + substitute_callout +
//   substitute_callout_data + offset_limit + heap_limit + match_limit +
//   depth_limit
typedef struct {
    pcre2_memctl memctl;
    void *callout;
    void *callout_data;
    void *substitute_callout;
    void *substitute_callout_data;
    pcre2_size_t offset_limit;
    unsigned int heap_limit;
    unsigned int match_limit;
    unsigned int depth_limit;
} pcre2_match_context_8;

// convert context: memctl + glob_escape + glob_separator
typedef struct {
    pcre2_memctl memctl;
    unsigned int glob_escape;
    unsigned int glob_separator;
} pcre2_convert_context_8;

// Provide storage and initialization for the default contexts
// These are referenced as extern var in the With-compiled modules

extern void *_pcre2_default_tables_8;

#define PCRE2_UNSET (~(pcre2_size_t)0)
#define PARENS_NEST_LIMIT 250
#define BSR_DEFAULT 0
#define NEWLINE_DEFAULT 2  // PCRE2_NEWLINE_LF
#define MAX_VARLOOKBEHIND 255
#define PCRE2_OPTIMIZATION_ALL 0xFFFFFFFF
#define MATCH_LIMIT 10000000
#define MATCH_LIMIT_DEPTH 10000000
#define HEAP_LIMIT 100000000

pcre2_compile_context_8 _pcre2_default_compile_context_8 = {
    { default_malloc, default_free, NULL },
    NULL, NULL,
    NULL,  // tables — filled at runtime or left as default
    PCRE2_UNSET, PCRE2_UNSET,
    BSR_DEFAULT, NEWLINE_DEFAULT,
    PARENS_NEST_LIMIT, 0,
    MAX_VARLOOKBEHIND, PCRE2_OPTIMIZATION_ALL
};

pcre2_match_context_8 _pcre2_default_match_context_8 = {
    { default_malloc, default_free, NULL },
    NULL, NULL, NULL, NULL,
    PCRE2_UNSET,
    HEAP_LIMIT, MATCH_LIMIT, MATCH_LIMIT_DEPTH
};

pcre2_convert_context_8 _pcre2_default_convert_context_8 = {
    { default_malloc, default_free, NULL },
    '/', '.'
};
