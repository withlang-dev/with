// Clang bridge for c_import — wraps libclang into flat i64-handle API.
// Pattern follows llvm_bridge.c: i64 handles, with_str strings, to_cstr helper.

#include <clang-c/Index.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

typedef struct { const char *ptr; int64_t len; } with_str;

// ── String helpers ──────────────────────────────────────────

static with_str make_str(const char *p) {
    with_str s;
    if (p && p[0]) {
        s.len = (int64_t)strlen(p);
        char *copy = (char *)malloc((size_t)s.len + 1);
        memcpy(copy, p, (size_t)s.len + 1);
        s.ptr = copy;
    } else {
        s.ptr = "";
        s.len = 0;
    }
    return s;
}

// ── Internal types ──────────────────────────────────────────

typedef struct {
    char *name;
    char *type_spelling;
} FieldInfo;

typedef struct {
    char *name;
    int64_t value;
} EnumConstInfo;

typedef struct {
    FieldInfo *fields;
    int32_t field_count;
    EnumConstInfo *enum_consts;
    int32_t enum_const_count;
    int fields_cached;
    int enum_consts_cached;
} DeclCache;

typedef struct {
    CXIndex index;
    CXTranslationUnit tu;
    CXCursor *decls;
    int32_t decl_count;
    int32_t decl_cap;
    DeclCache *caches;
    char *error;
    char *tmp_path;
    // Owned strings for cleanup
    char **strings;
    int32_t str_count;
    int32_t str_cap;
    // Header file for filtering transitive includes
    CXFile header_file;
} CImportSession;

typedef struct {
    char **names;
    char **values;
    int *fn_like;
    int32_t count;
    int32_t cap;
} MacroSession;

// ── String tracking ─────────────────────────────────────────

static char* session_strdup(CImportSession *s, const char *p) {
    if (!p) return NULL;
    char *copy = strdup(p);
    if (s->str_count >= s->str_cap) {
        s->str_cap = s->str_cap ? s->str_cap * 2 : 64;
        s->strings = (char **)realloc(s->strings, sizeof(char*) * (size_t)s->str_cap);
    }
    s->strings[s->str_count++] = copy;
    return copy;
}

static with_str session_make_str(CImportSession *s, const char *p) {
    with_str r;
    if (p && p[0]) {
        char *copy = session_strdup(s, p);
        r.ptr = copy;
        r.len = (int64_t)strlen(copy);
    } else {
        r.ptr = "";
        r.len = 0;
    }
    return r;
}

static with_str clang_str_to_with(CImportSession *s, CXString cxs) {
    const char *cstr = clang_getCString(cxs);
    with_str r = session_make_str(s, cstr);
    clang_disposeString(cxs);
    return r;
}

// ── SDK path detection ──────────────────────────────────────

static char sdk_path[1024] = {0};
static int sdk_path_resolved = 0;

static const char* get_sdk_path(void) {
    if (!sdk_path_resolved) {
        sdk_path_resolved = 1;
        FILE *p = popen("xcrun --show-sdk-path 2>/dev/null", "r");
        if (p) {
            if (fgets(sdk_path, sizeof(sdk_path), p)) {
                size_t len = strlen(sdk_path);
                if (len > 0 && sdk_path[len-1] == '\n')
                    sdk_path[len-1] = 0;
            }
            pclose(p);
        }
    }
    return sdk_path[0] ? sdk_path : NULL;
}

// ── Visitor: collect top-level declarations ─────────────────

static enum CXChildVisitResult collect_decl(CXCursor cursor,
                                             CXCursor parent,
                                             CXClientData data) {
    (void)parent;
    CImportSession *s = (CImportSession *)data;

    enum CXCursorKind kind = clang_getCursorKind(cursor);
    if (kind != CXCursor_FunctionDecl &&
        kind != CXCursor_StructDecl &&
        kind != CXCursor_UnionDecl &&
        kind != CXCursor_EnumDecl &&
        kind != CXCursor_TypedefDecl &&
        kind != CXCursor_VarDecl)
        return CXChildVisit_Continue;

    // Filter out declarations from transitive includes
    if (s->header_file) {
        CXSourceLocation loc = clang_getCursorLocation(cursor);
        CXFile file = NULL;
        clang_getFileLocation(loc, &file, NULL, NULL, NULL);
        if (file && !clang_File_isEqual(file, s->header_file))
            return CXChildVisit_Continue;
    }

    if (s->decl_count >= s->decl_cap) {
        s->decl_cap = s->decl_cap ? s->decl_cap * 2 : 256;
        s->decls = (CXCursor *)realloc(s->decls,
                    sizeof(CXCursor) * (size_t)s->decl_cap);
    }
    s->decls[s->decl_count++] = cursor;
    return CXChildVisit_Continue;
}

// ── Get canonical type spelling ─────────────────────────────

// Strip C qualifiers that With doesn't understand (restrict, volatile, _Atomic)
static char* strip_qualifiers(const char *spelling) {
    if (!spelling) return strdup("");
    // Work on a mutable copy
    char *buf = strdup(spelling);
    // Remove "restrict" in all positions
    char *p;
    // "*restrict" → "*" (most common form from clang)
    while ((p = strstr(buf, "*restrict")) != NULL) {
        memmove(p + 1, p + 9, strlen(p + 9) + 1);
    }
    while ((p = strstr(buf, " restrict")) != NULL) {
        memmove(p, p + 9, strlen(p + 9) + 1);
    }
    while ((p = strstr(buf, "restrict ")) != NULL) {
        memmove(p, p + 9, strlen(p + 9) + 1);
    }
    // Remove "volatile"
    while ((p = strstr(buf, " volatile")) != NULL) {
        memmove(p, p + 9, strlen(p + 9) + 1);
    }
    while ((p = strstr(buf, "volatile ")) != NULL) {
        memmove(p, p + 9, strlen(p + 9) + 1);
    }
    // Remove "_Atomic"
    while ((p = strstr(buf, " _Atomic")) != NULL) {
        memmove(p, p + 8, strlen(p + 8) + 1);
    }
    while ((p = strstr(buf, "_Atomic ")) != NULL) {
        memmove(p, p + 8, strlen(p + 8) + 1);
    }
    // Trim trailing whitespace
    size_t len = strlen(buf);
    while (len > 0 && (buf[len-1] == ' ' || buf[len-1] == '\t')) {
        buf[--len] = '\0';
    }
    return buf;
}

static with_str get_type_spelling(CImportSession *s, CXType type) {
    CXType canonical = clang_getCanonicalType(type);
    CXString cxs = clang_getTypeSpelling(canonical);
    const char *raw = clang_getCString(cxs);
    char *cleaned = strip_qualifiers(raw);
    with_str result = session_make_str(s, cleaned);
    free(cleaned);
    clang_disposeString(cxs);
    return result;
}

// ── Field collection (cached per declaration) ───────────────

typedef struct {
    FieldInfo *fields;
    int32_t count;
    int32_t cap;
} FieldCollector;

static enum CXChildVisitResult collect_field(CXCursor cursor,
                                              CXCursor parent,
                                              CXClientData data) {
    (void)parent;
    FieldCollector *fc = (FieldCollector *)data;
    if (clang_getCursorKind(cursor) != CXCursor_FieldDecl)
        return CXChildVisit_Continue;

    if (fc->count >= fc->cap) {
        fc->cap = fc->cap ? fc->cap * 2 : 16;
        fc->fields = (FieldInfo *)realloc(fc->fields,
                      sizeof(FieldInfo) * (size_t)fc->cap);
    }

    CXString name = clang_getCursorSpelling(cursor);
    CXType type = clang_getCursorType(cursor);
    CXType canonical = clang_getCanonicalType(type);
    CXString type_str = clang_getTypeSpelling(canonical);

    fc->fields[fc->count].name = strdup(clang_getCString(name));
    fc->fields[fc->count].type_spelling = strdup(clang_getCString(type_str));
    fc->count++;

    clang_disposeString(name);
    clang_disposeString(type_str);
    return CXChildVisit_Continue;
}

static void ensure_fields_cached(CImportSession *s, int32_t idx) {
    if (idx < 0 || idx >= s->decl_count) return;
    if (!s->caches)
        s->caches = (DeclCache *)calloc((size_t)s->decl_count, sizeof(DeclCache));
    if (s->caches[idx].fields_cached) return;
    s->caches[idx].fields_cached = 1;

    FieldCollector fc = {NULL, 0, 0};
    clang_visitChildren(s->decls[idx], collect_field, &fc);
    s->caches[idx].fields = fc.fields;
    s->caches[idx].field_count = fc.count;
}

// ── Enum constant collection (cached per declaration) ───────

typedef struct {
    EnumConstInfo *consts;
    int32_t count;
    int32_t cap;
} EnumCollector;

static enum CXChildVisitResult collect_enum_const(CXCursor cursor,
                                                    CXCursor parent,
                                                    CXClientData data) {
    (void)parent;
    EnumCollector *ec = (EnumCollector *)data;
    if (clang_getCursorKind(cursor) != CXCursor_EnumConstantDecl)
        return CXChildVisit_Continue;

    if (ec->count >= ec->cap) {
        ec->cap = ec->cap ? ec->cap * 2 : 16;
        ec->consts = (EnumConstInfo *)realloc(ec->consts,
                      sizeof(EnumConstInfo) * (size_t)ec->cap);
    }

    CXString name = clang_getCursorSpelling(cursor);
    ec->consts[ec->count].name = strdup(clang_getCString(name));
    ec->consts[ec->count].value = clang_getEnumConstantDeclValue(cursor);
    ec->count++;

    clang_disposeString(name);
    return CXChildVisit_Continue;
}

static void ensure_enum_consts_cached(CImportSession *s, int32_t idx) {
    if (idx < 0 || idx >= s->decl_count) return;
    if (!s->caches)
        s->caches = (DeclCache *)calloc((size_t)s->decl_count, sizeof(DeclCache));
    if (s->caches[idx].enum_consts_cached) return;
    s->caches[idx].enum_consts_cached = 1;

    EnumCollector ec = {NULL, 0, 0};
    clang_visitChildren(s->decls[idx], collect_enum_const, &ec);
    s->caches[idx].enum_consts = ec.consts;
    s->caches[idx].enum_const_count = ec.count;
}

// ── Global name deduplication ────────────────────────────────

static char **g_emitted_names = NULL;
static int32_t g_emitted_count = 0;
static int32_t g_emitted_cap = 0;

static int is_name_emitted(const char *name) {
    for (int32_t i = 0; i < g_emitted_count; i++) {
        if (strcmp(g_emitted_names[i], name) == 0)
            return 1;
    }
    return 0;
}

static void mark_name_emitted(const char *name) {
    if (is_name_emitted(name)) return;
    if (g_emitted_count >= g_emitted_cap) {
        g_emitted_cap = g_emitted_cap ? g_emitted_cap * 2 : 256;
        g_emitted_names = (char **)realloc(g_emitted_names,
                           sizeof(char *) * (size_t)g_emitted_cap);
    }
    g_emitted_names[g_emitted_count++] = strdup(name);
}

// ═══════════════════════════════════════════════════════════
// Public API
// ═══════════════════════════════════════════════════════════

int32_t with_cimport_available(void) { return 1; }

int32_t with_cimport_is_name_emitted(with_str name) {
    if (name.len <= 0) return 0;
    char buf[512];
    size_t len = (size_t)name.len < sizeof(buf)-1 ? (size_t)name.len : sizeof(buf)-1;
    memcpy(buf, name.ptr, len);
    buf[len] = 0;
    return is_name_emitted(buf);
}

void with_cimport_mark_name_emitted(with_str name) {
    if (name.len <= 0) return;
    char buf[512];
    size_t len = (size_t)name.len < sizeof(buf)-1 ? (size_t)name.len : sizeof(buf)-1;
    memcpy(buf, name.ptr, len);
    buf[len] = 0;
    mark_name_emitted(buf);
}

void with_cimport_reset_names(void) {
    for (int32_t i = 0; i < g_emitted_count; i++)
        free(g_emitted_names[i]);
    free(g_emitted_names);
    g_emitted_names = NULL;
    g_emitted_count = 0;
    g_emitted_cap = 0;
}

// ── Parse ───────────────────────────────────────────────────

int64_t with_cimport_parse(with_str header_code) {
    CImportSession *s = (CImportSession *)calloc(1, sizeof(CImportSession));
    if (!s) return 0;

    // Create temp file with header code
    char tmp_template[] = "/tmp/with_cimport_XXXXXX";
    int fd = mkstemp(tmp_template);
    if (fd < 0) {
        s->error = strdup("failed to create temp file");
        return (int64_t)(intptr_t)s;
    }

    write(fd, header_code.ptr, (size_t)header_code.len);
    write(fd, "\n", 1);
    close(fd);

    // Rename to .c so clang treats it as C
    char *c_path = (char *)malloc(strlen(tmp_template) + 3);
    sprintf(c_path, "%s.c", tmp_template);
    rename(tmp_template, c_path);
    s->tmp_path = c_path;

    // Build compiler arguments
    const char *args[4];
    int nargs = 0;
    const char *sysroot = get_sdk_path();
    if (sysroot) {
        args[nargs++] = "-isysroot";
        args[nargs++] = sysroot;
    }

    s->index = clang_createIndex(0, 0);
    s->tu = clang_parseTranslationUnit(
        s->index, c_path,
        args, nargs,
        NULL, 0,
        CXTranslationUnit_SkipFunctionBodies);

    if (!s->tu) {
        s->error = strdup("failed to parse translation unit");
        return (int64_t)(intptr_t)s;
    }

    // Check for fatal errors
    unsigned diag_count = clang_getNumDiagnostics(s->tu);
    for (unsigned i = 0; i < diag_count; i++) {
        CXDiagnostic diag = clang_getDiagnostic(s->tu, i);
        if (clang_getDiagnosticSeverity(diag) >= CXDiagnostic_Error) {
            CXString msg = clang_getDiagnosticSpelling(diag);
            s->error = strdup(clang_getCString(msg));
            clang_disposeString(msg);
            clang_disposeDiagnostic(diag);
            return (int64_t)(intptr_t)s;
        }
        clang_disposeDiagnostic(diag);
    }

    // Collect top-level declarations
    CXCursor root = clang_getTranslationUnitCursor(s->tu);
    s->header_file = NULL;  // No filtering for now (transitive includes allowed)
    clang_visitChildren(root, collect_decl, s);

    return (int64_t)(intptr_t)s;
}

// ── Dispose ─────────────────────────────────────────────────

void with_cimport_dispose(int64_t session) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s) return;

    if (s->caches) {
        for (int32_t i = 0; i < s->decl_count; i++) {
            for (int32_t j = 0; j < s->caches[i].field_count; j++) {
                free(s->caches[i].fields[j].name);
                free(s->caches[i].fields[j].type_spelling);
            }
            free(s->caches[i].fields);
            for (int32_t j = 0; j < s->caches[i].enum_const_count; j++) {
                free(s->caches[i].enum_consts[j].name);
            }
            free(s->caches[i].enum_consts);
        }
        free(s->caches);
    }

    for (int32_t i = 0; i < s->str_count; i++)
        free(s->strings[i]);
    free(s->strings);

    if (s->tmp_path) {
        unlink(s->tmp_path);
        free(s->tmp_path);
    }
    if (s->tu) clang_disposeTranslationUnit(s->tu);
    if (s->index) clang_disposeIndex(s->index);
    free(s->error);
    free(s->decls);
    free(s);
}

// ── Error ───────────────────────────────────────────────────

with_str with_cimport_error(int64_t session) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    return make_str(s && s->error ? s->error : "");
}

// ── Declaration queries ─────────────────────────────────────

int32_t with_cimport_decl_count(int64_t session) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    return s ? s->decl_count : 0;
}

int32_t with_cimport_decl_kind(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    return (int32_t)clang_getCursorKind(s->decls[idx]);
}

with_str with_cimport_decl_name(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("");
    return clang_str_to_with(s, clang_getCursorSpelling(s->decls[idx]));
}

// ── Function queries ────────────────────────────────────────

with_str with_cimport_fn_return_type(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("void");
    CXType fn_type = clang_getCursorType(s->decls[idx]);
    CXType ret_type = clang_getResultType(fn_type);
    return get_type_spelling(s, ret_type);
}

int32_t with_cimport_fn_param_count(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    return (int32_t)clang_Cursor_getNumArguments(s->decls[idx]);
}

with_str with_cimport_fn_param_name(int64_t session, int32_t idx, int32_t param) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("");
    CXCursor arg = clang_Cursor_getArgument(s->decls[idx], (unsigned)param);
    return clang_str_to_with(s, clang_getCursorSpelling(arg));
}

with_str with_cimport_fn_param_type(int64_t session, int32_t idx, int32_t param) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("i32");
    CXCursor arg = clang_Cursor_getArgument(s->decls[idx], (unsigned)param);
    CXType type = clang_getCursorType(arg);
    return get_type_spelling(s, type);
}

int32_t with_cimport_fn_is_variadic(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    CXType fn_type = clang_getCursorType(s->decls[idx]);
    return clang_isFunctionTypeVariadic(fn_type) ? 1 : 0;
}

// ── Struct queries ──────────────────────────────────────────

int32_t with_cimport_struct_field_count(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    ensure_fields_cached(s, idx);
    return s->caches[idx].field_count;
}

with_str with_cimport_struct_field_name(int64_t session, int32_t idx, int32_t field) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("");
    ensure_fields_cached(s, idx);
    if (field < 0 || field >= s->caches[idx].field_count) return make_str("");
    return session_make_str(s, s->caches[idx].fields[field].name);
}

with_str with_cimport_struct_field_type(int64_t session, int32_t idx, int32_t field) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("i32");
    ensure_fields_cached(s, idx);
    if (field < 0 || field >= s->caches[idx].field_count) return make_str("i32");
    return session_make_str(s, s->caches[idx].fields[field].type_spelling);
}

int32_t with_cimport_struct_is_opaque(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 1;
    return !clang_isCursorDefinition(s->decls[idx]);
}

// ── Enum queries ────────────────────────────────────────────

int32_t with_cimport_enum_const_count(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    ensure_enum_consts_cached(s, idx);
    return s->caches[idx].enum_const_count;
}

with_str with_cimport_enum_const_name(int64_t session, int32_t idx, int32_t ci) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("");
    ensure_enum_consts_cached(s, idx);
    if (ci < 0 || ci >= s->caches[idx].enum_const_count) return make_str("");
    return session_make_str(s, s->caches[idx].enum_consts[ci].name);
}

int64_t with_cimport_enum_const_value(int64_t session, int32_t idx, int32_t ci) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    ensure_enum_consts_cached(s, idx);
    if (ci < 0 || ci >= s->caches[idx].enum_const_count) return 0;
    return s->caches[idx].enum_consts[ci].value;
}

// ── Variable queries ────────────────────────────────────────

with_str with_cimport_var_type(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("i32");
    CXType var_type = clang_getCursorType(s->decls[idx]);
    return get_type_spelling(s, var_type);
}

int32_t with_cimport_var_is_const(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    CXType var_type = clang_getCursorType(s->decls[idx]);
    return clang_isConstQualifiedType(var_type) ? 1 : 0;
}

// ── Typedef queries ─────────────────────────────────────────

with_str with_cimport_typedef_underlying(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("i32");
    CXType underlying = clang_getTypedefDeclUnderlyingType(s->decls[idx]);
    CXType canonical = clang_getCanonicalType(underlying);
    return clang_str_to_with(s, clang_getTypeSpelling(canonical));
}

// ═══════════════════════════════════════════════════════════
// Macro extraction (via cc -E -dM)
// ═══════════════════════════════════════════════════════════

int64_t with_cimport_parse_macros(with_str header_code) {
    MacroSession *ms = (MacroSession *)calloc(1, sizeof(MacroSession));
    if (!ms) return 0;

    // Write header code to temp file
    char tmp_template[] = "/tmp/with_cimport_macro_XXXXXX";
    int fd = mkstemp(tmp_template);
    if (fd < 0) return (int64_t)(intptr_t)ms;

    write(fd, header_code.ptr, (size_t)header_code.len);
    write(fd, "\n", 1);
    close(fd);

    char c_path[256];
    snprintf(c_path, sizeof(c_path), "%s.c", tmp_template);
    rename(tmp_template, c_path);

    // Run preprocessor to extract macro definitions
    char cmd[1024];
    const char *sysroot = get_sdk_path();
    if (sysroot) {
        snprintf(cmd, sizeof(cmd),
                 "cc -isysroot '%s' -E -dM '%s' 2>/dev/null", sysroot, c_path);
    } else {
        snprintf(cmd, sizeof(cmd), "cc -E -dM '%s' 2>/dev/null", c_path);
    }

    FILE *p = popen(cmd, "r");
    if (!p) {
        unlink(c_path);
        return (int64_t)(intptr_t)ms;
    }

    char line[4096];
    while (fgets(line, sizeof(line), p)) {
        if (strncmp(line, "#define ", 8) != 0) continue;

        char *name_start = line + 8;
        // Skip builtins (starting with __)
        if (name_start[0] == '_' && name_start[1] == '_') continue;

        // Find end of name
        char *name_end = name_start;
        while (*name_end && *name_end != ' ' && *name_end != '(' && *name_end != '\n')
            name_end++;

        int is_fn_like = (*name_end == '(') ? 1 : 0;

        size_t name_len = (size_t)(name_end - name_start);
        char *name = (char *)malloc(name_len + 1);
        memcpy(name, name_start, name_len);
        name[name_len] = 0;

        // Skip past args for function-like macros
        char *value_start = name_end;
        if (is_fn_like) {
            while (*value_start && *value_start != ')') value_start++;
            if (*value_start == ')') value_start++;
        }
        while (*value_start == ' ') value_start++;

        // Strip trailing newline
        size_t value_len = strlen(value_start);
        while (value_len > 0 &&
               (value_start[value_len-1] == '\n' || value_start[value_len-1] == '\r'))
            value_len--;

        char *value = (char *)malloc(value_len + 1);
        memcpy(value, value_start, value_len);
        value[value_len] = 0;

        if (ms->count >= ms->cap) {
            ms->cap = ms->cap ? ms->cap * 2 : 64;
            ms->names  = (char **)realloc(ms->names,  sizeof(char*) * (size_t)ms->cap);
            ms->values = (char **)realloc(ms->values, sizeof(char*) * (size_t)ms->cap);
            ms->fn_like = (int *)realloc(ms->fn_like, sizeof(int) * (size_t)ms->cap);
        }
        ms->names[ms->count]   = name;
        ms->values[ms->count]  = value;
        ms->fn_like[ms->count] = is_fn_like;
        ms->count++;
    }

    pclose(p);
    unlink(c_path);
    return (int64_t)(intptr_t)ms;
}

int32_t with_cimport_macro_count(int64_t session) {
    MacroSession *ms = (MacroSession *)(intptr_t)session;
    return ms ? ms->count : 0;
}

with_str with_cimport_macro_name(int64_t session, int32_t idx) {
    MacroSession *ms = (MacroSession *)(intptr_t)session;
    if (!ms || idx < 0 || idx >= ms->count) return make_str("");
    return make_str(ms->names[idx]);
}

with_str with_cimport_macro_value(int64_t session, int32_t idx) {
    MacroSession *ms = (MacroSession *)(intptr_t)session;
    if (!ms || idx < 0 || idx >= ms->count) return make_str("");
    return make_str(ms->values[idx]);
}

int32_t with_cimport_macro_is_fn_like(int64_t session, int32_t idx) {
    MacroSession *ms = (MacroSession *)(intptr_t)session;
    if (!ms || idx < 0 || idx >= ms->count) return 0;
    return ms->fn_like[idx];
}

void with_cimport_dispose_macros(int64_t session) {
    MacroSession *ms = (MacroSession *)(intptr_t)session;
    if (!ms) return;
    for (int32_t i = 0; i < ms->count; i++) {
        free(ms->names[i]);
        free(ms->values[i]);
    }
    free(ms->names);
    free(ms->values);
    free(ms->fn_like);
    free(ms);
}
