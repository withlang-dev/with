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
    int is_bitfield;
    CXType clang_type;
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
    // ── AST traversal (Phase 1) ────────────────────────
    CXCursor *cursors;      // general cursor array (index-based handles)
    int32_t cursor_count;
    int32_t cursor_cap;
    CXType *types;          // general type array (index-based handles)
    int32_t type_count;
    int32_t type_cap;
    // Children cache: for each cursor, store [start, count] into a flat child array
    int32_t *child_starts;  // child_starts[cursor_idx] = start index in child_indices
    int32_t *child_counts;  // child_counts[cursor_idx] = number of children
    int32_t *child_indices; // flat array of cursor indices for all children
    int32_t child_indices_count;
    int32_t child_indices_cap;
    int32_t children_cache_cap; // capacity of child_starts/child_counts arrays
} CImportSession;

typedef struct {
    char **names;
    char **values;
    int *fn_like;
    char ***params;        // params[i] = NULL-terminated array of param names
    int32_t *param_counts; // number of params for macro i
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

// ── Recursive type translation ──────────────────────────────

#define MAX_TYPE_DEPTH 16

static char* translate_fn_type(CImportSession *s, CXType fn_type, int depth);

static char* translate_type_recursive(CImportSession *s, CXType type, int depth, int is_last_struct_field) {
    if (depth > MAX_TYPE_DEPTH) {
        return session_strdup(s, "__UNSUPPORTED:type too complex");
    }

    CXType canonical = clang_getCanonicalType(type);
    enum CXTypeKind kind = canonical.kind;

    switch (kind) {
        case CXType_Void: return session_strdup(s, "void");
        case CXType_Bool: return session_strdup(s, "bool");
        case CXType_Char_S:
        case CXType_SChar: return session_strdup(s, "i8");
        case CXType_Char_U:
        case CXType_UChar: return session_strdup(s, "u8");
        case CXType_Short: return session_strdup(s, "i16");
        case CXType_UShort: return session_strdup(s, "u16");
        case CXType_Int: return session_strdup(s, "i32");
        case CXType_UInt: return session_strdup(s, "u32");
        case CXType_Long: {
            long long sz = clang_Type_getSizeOf(canonical);
            return session_strdup(s, sz <= 4 ? "i32" : "i64");
        }
        case CXType_LongLong: return session_strdup(s, "i64");
        case CXType_ULong: {
            long long sz = clang_Type_getSizeOf(canonical);
            return session_strdup(s, sz <= 4 ? "u32" : "u64");
        }
        case CXType_ULongLong: return session_strdup(s, "u64");
        case CXType_Int128: return session_strdup(s, "i128");
        case CXType_UInt128: return session_strdup(s, "u128");
        case CXType_Float: return session_strdup(s, "f32");
        case CXType_Double:
        case CXType_LongDouble: return session_strdup(s, "f64");

        case CXType_Pointer: {
            CXType pointee = clang_getPointeeType(canonical);
            CXType can_pointee = clang_getCanonicalType(pointee);
            int is_const = clang_isConstQualifiedType(pointee);
            int is_volatile = clang_isVolatileQualifiedType(pointee);

            // Function pointer -> *const fn(...) -> Ret
            if (can_pointee.kind == CXType_FunctionProto ||
                can_pointee.kind == CXType_FunctionNoProto) {
                char *fn_str = translate_fn_type(s, can_pointee, depth + 1);
                if (!fn_str) return session_strdup(s, "*const i8");
                char buf[2048];
                snprintf(buf, sizeof(buf), "*const %s", fn_str);
                return session_strdup(s, buf);
            }

            // Determine pointer qualifier: volatile > const > mut
            const char *qual = is_volatile ? "volatile" : (is_const ? "const" : "mut");

            // void pointer -> *qual c_void
            if (can_pointee.kind == CXType_Void) {
                char buf[64];
                snprintf(buf, sizeof(buf), "*%s c_void", qual);
                return session_strdup(s, buf);
            }

            // char pointer -> *qual i8
            if (can_pointee.kind == CXType_Char_S ||
                can_pointee.kind == CXType_SChar ||
                can_pointee.kind == CXType_Char_U) {
                char buf[64];
                snprintf(buf, sizeof(buf), "*%s i8", qual);
                return session_strdup(s, buf);
            }

            // General pointer
            char *inner = translate_type_recursive(s, pointee, depth + 1, 0);
            if (!inner || strncmp(inner, "__UNSUPPORTED:", 14) == 0 ||
                strcmp(inner, "opaque") == 0) {
                return session_strdup(s, "*const i8");
            }

            char buf[2048];
            snprintf(buf, sizeof(buf), "*%s %s", qual, inner);
            return session_strdup(s, buf);
        }

        case CXType_ConstantArray: {
            long long size = clang_getArraySize(canonical);
            CXType elem = clang_getArrayElementType(canonical);
            char *elem_str = translate_type_recursive(s, elem, depth + 1, 0);
            if (!elem_str || strcmp(elem_str, "opaque") == 0) return session_strdup(s, "opaque");
            if (strncmp(elem_str, "__UNSUPPORTED:", 14) == 0) {
                return elem_str;
            }
            char buf[2048];
            snprintf(buf, sizeof(buf), "[%lld]%s", size, elem_str);
            return session_strdup(s, buf);
        }

        case CXType_IncompleteArray: {
            CXType elem = clang_getArrayElementType(canonical);
            char *elem_str = translate_type_recursive(s, elem, depth + 1, 0);
            if (!elem_str || strncmp(elem_str, "__UNSUPPORTED:", 14) == 0) {
                return session_strdup(s, "*const i8");
            }
            char buf[2048];
            if (is_last_struct_field) {
                // Flexible array member
                snprintf(buf, sizeof(buf), "[0]%s", elem_str);
            } else {
                // Decay to pointer
                snprintf(buf, sizeof(buf), "*%s", elem_str);
            }
            return session_strdup(s, buf);
        }

        case CXType_FunctionProto:
        case CXType_FunctionNoProto: {
            return translate_fn_type(s, canonical, depth + 1);
        }

        case CXType_Record: {
            CXString spelling = clang_getTypeSpelling(canonical);
            const char *name_str = clang_getCString(spelling);
            // Strip qualifiers and "struct " / "union " prefix
            const char *bare = name_str;
            if (bare && strncmp(bare, "const ", 6) == 0) bare += 6;
            if (bare && strncmp(bare, "volatile ", 9) == 0) bare += 9;
            if (bare && strncmp(bare, "struct ", 7) == 0)
                bare += 7;
            else if (bare && strncmp(bare, "union ", 6) == 0)
                bare += 6;
            // Anonymous record or internal names (starting with _)
            if (!bare || bare[0] == '\0' || bare[0] == '_' ||
                strstr(name_str, "(anonymous") != NULL) {
                clang_disposeString(spelling);
                return session_strdup(s, "opaque");
            }
            char *result = session_strdup(s, bare);
            clang_disposeString(spelling);
            return result;
        }

        case CXType_Enum: {
            return session_strdup(s, "i32");
        }

        case CXType_Complex: {
            CXType elem = clang_getElementType(canonical);
            long long sz = clang_Type_getSizeOf(elem);
            if (sz <= 4) return session_strdup(s, "Complex32");
            return session_strdup(s, "Complex64");
        }
        case CXType_Vector:
            return session_strdup(s, "__UNSUPPORTED:vector type");
        case CXType_VariableArray:
            return session_strdup(s, "__UNSUPPORTED:variable-length array");

        // Block pointer (Apple extension)
        case CXType_BlockPointer:
            return session_strdup(s, "*const i8");

        // Atomic type — unwrap but mark as unsupported for struct demotion
        case CXType_Atomic: {
            return session_strdup(s, "__UNSUPPORTED:_Atomic type");
        }

        default: {
            CXString sp = clang_getTypeSpelling(canonical);
            fprintf(stderr, "c_import: unsupported type kind %d: %s\n",
                    kind, clang_getCString(sp));
            clang_disposeString(sp);
            return session_strdup(s, "opaque");
        }
    }
}

static char* translate_fn_type(CImportSession *s, CXType fn_type, int depth) {
    if (depth > MAX_TYPE_DEPTH) {
        return session_strdup(s, "__UNSUPPORTED:type too complex");
    }

    CXType ret_type = clang_getResultType(fn_type);
    char *ret_str = translate_type_recursive(s, ret_type, depth + 1, 0);
    if (!ret_str) ret_str = session_strdup(s, "void");

    int num_args = clang_getNumArgTypes(fn_type);
    int is_variadic = clang_isFunctionTypeVariadic(fn_type);

    char params[4096] = {0};
    int pos = 0;
    for (int i = 0; i < num_args; i++) {
        if (i > 0) {
            pos += snprintf(params + pos, sizeof(params) - (size_t)pos, ", ");
        }
        CXType arg_type = clang_getArgType(fn_type, (unsigned)i);
        char *arg_str = translate_type_recursive(s, arg_type, depth + 1, 0);
        if (!arg_str || strncmp(arg_str, "__UNSUPPORTED:", 14) == 0) {
            arg_str = session_strdup(s, "i32");
        }
        pos += snprintf(params + pos, sizeof(params) - (size_t)pos, "%s", arg_str);
    }
    if (is_variadic) {
        if (num_args > 0) {
            pos += snprintf(params + pos, sizeof(params) - (size_t)pos, ", ...");
        } else {
            pos += snprintf(params + pos, sizeof(params) - (size_t)pos, "...");
        }
    }

    if (strncmp(ret_str, "__UNSUPPORTED:", 14) == 0) {
        ret_str = session_strdup(s, "i32");
    }

    char buf[8192];
    snprintf(buf, sizeof(buf), "fn(%s) -> %s", params, ret_str);
    return session_strdup(s, buf);
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
    fc->fields[fc->count].clang_type = type;
    fc->fields[fc->count].is_bitfield = clang_Cursor_isBitField(cursor) ? 1 : 0;
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
        CXTranslationUnit_DetailedPreprocessingRecord);

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

    // Free AST traversal arrays
    free(s->cursors);
    free(s->types);
    free(s->child_starts);
    free(s->child_counts);
    free(s->child_indices);

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

int32_t with_cimport_param_is_restrict(int64_t session, int32_t idx, int32_t param) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    CXCursor arg = clang_Cursor_getArgument(s->decls[idx], (unsigned)param);
    CXType type = clang_getCursorType(arg);
    if (clang_isRestrictQualifiedType(type)) return 1;
    CXString spelling = clang_getTypeSpelling(type);
    const char *raw = clang_getCString(spelling);
    int is_restrict = raw && strstr(raw, "restrict") != NULL;
    clang_disposeString(spelling);
    return is_restrict ? 1 : 0;
}

int32_t with_cimport_fn_is_variadic(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    CXType fn_type = clang_getCursorType(s->decls[idx]);
    return clang_isFunctionTypeVariadic(fn_type) ? 1 : 0;
}

int32_t with_cimport_fn_storage_class(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    return (int32_t)clang_Cursor_getStorageClass(s->decls[idx]);
}

int32_t with_cimport_fn_is_inline(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    return clang_Cursor_isFunctionInlined(s->decls[idx]) ? 1 : 0;
}

with_str with_cimport_fn_calling_conv(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("c");
    CXType fn_type = clang_getCursorType(s->decls[idx]);
    enum CXCallingConv cc = clang_getFunctionTypeCallingConv(fn_type);
    switch (cc) {
        case CXCallingConv_Default:
        case CXCallingConv_C: return make_str("c");
        case CXCallingConv_X86StdCall: return make_str("stdcall");
        case CXCallingConv_X86FastCall: return make_str("fastcall");
        case CXCallingConv_X86ThisCall: return make_str("thiscall");
        case CXCallingConv_Win64: return make_str("win64");
        case CXCallingConv_X86VectorCall: return make_str("vectorcall");
        case CXCallingConv_AArch64VectorCall: return make_str("aarch64_vfabi");
        default: return make_str("c");
    }
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

int32_t with_cimport_struct_field_is_bitfield(int64_t session, int32_t idx, int32_t field) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    ensure_fields_cached(s, idx);
    if (field < 0 || field >= s->caches[idx].field_count) return 0;
    return s->caches[idx].fields[field].is_bitfield;
}

int64_t with_cimport_struct_field_offset(int64_t session, int32_t idx, int32_t field) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return -1;
    CXType struct_type = clang_getCursorType(s->decls[idx]);
    ensure_fields_cached(s, idx);
    if (field < 0 || field >= s->caches[idx].field_count) return -1;
    // Get field cursor by visiting children
    CXCursor struct_cursor = s->decls[idx];
    CXType canonical = clang_getCanonicalType(struct_type);
    return clang_Type_getOffsetOf(canonical, s->caches[idx].fields[field].name) / 8;
}

int64_t with_cimport_struct_size(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    CXType type = clang_getCursorType(s->decls[idx]);
    return clang_Type_getSizeOf(type);
}

int32_t with_cimport_struct_is_opaque(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 1;
    return !clang_isCursorDefinition(s->decls[idx]);
}

int32_t with_cimport_struct_is_packed(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    CXType type = clang_getCursorType(s->decls[idx]);
    long long align = clang_Type_getAlignOf(type);
    return (align == 1) ? 1 : 0;
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

// ── Enum integer type query ─────────────────────────────────

with_str with_cimport_enum_int_type(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("int");
    CXType int_type = clang_getEnumDeclIntegerType(s->decls[idx]);
    CXString spelling = clang_getTypeSpelling(int_type);
    with_str result = session_make_str(s, clang_getCString(spelling));
    clang_disposeString(spelling);
    return result;
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

// ── Translated type queries (recursive translation) ─────────

with_str with_cimport_fn_param_type_translated(int64_t session, int32_t idx, int32_t param) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("i32");
    CXCursor arg = clang_Cursor_getArgument(s->decls[idx], (unsigned)param);
    CXType type = clang_getCursorType(arg);
    char *result = translate_type_recursive(s, type, 0, 0);
    return session_make_str(s, result ? result : "i32");
}

with_str with_cimport_fn_return_type_translated(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("void");
    CXType fn_type = clang_getCursorType(s->decls[idx]);
    CXType ret_type = clang_getResultType(fn_type);
    char *result = translate_type_recursive(s, ret_type, 0, 0);
    return session_make_str(s, result ? result : "void");
}

with_str with_cimport_struct_field_type_translated(int64_t session, int32_t idx, int32_t field) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("i32");
    ensure_fields_cached(s, idx);
    if (field < 0 || field >= s->caches[idx].field_count) return make_str("i32");
    int is_last = (field == s->caches[idx].field_count - 1) ? 1 : 0;
    char *result = translate_type_recursive(s, s->caches[idx].fields[field].clang_type, 0, is_last);
    return session_make_str(s, result ? result : "i32");
}

with_str with_cimport_var_type_translated(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("i32");
    CXType var_type = clang_getCursorType(s->decls[idx]);
    char *result = translate_type_recursive(s, var_type, 0, 0);
    return session_make_str(s, result ? result : "i32");
}

with_str with_cimport_typedef_underlying_translated(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("i32");
    CXType underlying = clang_getTypedefDeclUnderlyingType(s->decls[idx]);
    char *result = translate_type_recursive(s, underlying, 0, 0);
    return session_make_str(s, result ? result : "i32");
}

// ── Anonymous struct/union field queries ─────────────────────

// Returns 0 if not anonymous, 1 if anonymous struct, 2 if anonymous union
int32_t with_cimport_struct_field_is_anonymous_record(int64_t session, int32_t idx, int32_t field) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    ensure_fields_cached(s, idx);
    if (field < 0 || field >= s->caches[idx].field_count) return 0;

    CXType ftype = s->caches[idx].fields[field].clang_type;
    CXType canonical = clang_getCanonicalType(ftype);
    if (canonical.kind != CXType_Record) return 0;

    CXCursor decl = clang_getTypeDeclaration(canonical);
    if (!clang_Cursor_isAnonymous(decl)) return 0;
    return (clang_getCursorKind(decl) == CXCursor_UnionDecl) ? 2 : 1;
}

int32_t with_cimport_struct_field_anon_field_count(int64_t session, int32_t idx, int32_t field) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    ensure_fields_cached(s, idx);
    if (field < 0 || field >= s->caches[idx].field_count) return 0;

    CXType ftype = s->caches[idx].fields[field].clang_type;
    CXType canonical = clang_getCanonicalType(ftype);
    if (canonical.kind != CXType_Record) return 0;

    CXCursor decl = clang_getTypeDeclaration(canonical);
    FieldCollector fc = {NULL, 0, 0};
    clang_visitChildren(decl, collect_field, &fc);
    int count = fc.count;
    for (int i = 0; i < fc.count; i++) {
        free(fc.fields[i].name);
        free(fc.fields[i].type_spelling);
    }
    free(fc.fields);
    return count;
}

with_str with_cimport_struct_field_anon_field_name(int64_t session, int32_t idx, int32_t field, int32_t sub_field) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("");
    ensure_fields_cached(s, idx);
    if (field < 0 || field >= s->caches[idx].field_count) return make_str("");

    CXType ftype = s->caches[idx].fields[field].clang_type;
    CXType canonical = clang_getCanonicalType(ftype);
    if (canonical.kind != CXType_Record) return make_str("");

    CXCursor decl = clang_getTypeDeclaration(canonical);
    FieldCollector fc = {NULL, 0, 0};
    clang_visitChildren(decl, collect_field, &fc);

    with_str result = make_str("");
    if (sub_field >= 0 && sub_field < fc.count) {
        result = session_make_str(s, fc.fields[sub_field].name);
    }

    for (int i = 0; i < fc.count; i++) {
        free(fc.fields[i].name);
        free(fc.fields[i].type_spelling);
    }
    free(fc.fields);
    return result;
}

with_str with_cimport_struct_field_anon_field_type(int64_t session, int32_t idx, int32_t field, int32_t sub_field) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("i32");
    ensure_fields_cached(s, idx);
    if (field < 0 || field >= s->caches[idx].field_count) return make_str("i32");

    CXType ftype = s->caches[idx].fields[field].clang_type;
    CXType canonical = clang_getCanonicalType(ftype);
    if (canonical.kind != CXType_Record) return make_str("i32");

    CXCursor decl = clang_getTypeDeclaration(canonical);
    FieldCollector fc = {NULL, 0, 0};
    clang_visitChildren(decl, collect_field, &fc);

    with_str result = make_str("i32");
    if (sub_field >= 0 && sub_field < fc.count) {
        int is_last = (sub_field == fc.count - 1) ? 1 : 0;
        char *translated = translate_type_recursive(s, fc.fields[sub_field].clang_type, 0, is_last);
        result = session_make_str(s, translated ? translated : "i32");
    }

    for (int i = 0; i < fc.count; i++) {
        free(fc.fields[i].name);
        free(fc.fields[i].type_spelling);
    }
    free(fc.fields);
    return result;
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

        // Extract parameter names for function-like macros
        char **macro_params = NULL;
        int32_t macro_param_count = 0;
        char *value_start = name_end;
        if (is_fn_like) {
            char *pstart = name_end + 1; // skip '('
            char *pend = pstart;
            while (*pend && *pend != ')') pend++;
            // Parse comma-separated params between pstart and pend
            if (pend > pstart) {
                // Count commas to estimate param count
                int cap = 8;
                macro_params = (char **)malloc(sizeof(char*) * (size_t)cap);
                char *p = pstart;
                while (p < pend) {
                    while (p < pend && *p == ' ') p++;
                    char *tok = p;
                    while (p < pend && *p != ',' && *p != ' ') p++;
                    if (p > tok) {
                        if (macro_param_count >= cap) {
                            cap *= 2;
                            macro_params = (char **)realloc(macro_params, sizeof(char*) * (size_t)cap);
                        }
                        size_t tlen = (size_t)(p - tok);
                        char *pname = (char *)malloc(tlen + 1);
                        memcpy(pname, tok, tlen);
                        pname[tlen] = 0;
                        macro_params[macro_param_count++] = pname;
                    }
                    while (p < pend && (*p == ',' || *p == ' ')) p++;
                }
            }
            value_start = pend;
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
            ms->params = (char ***)realloc(ms->params, sizeof(char**) * (size_t)ms->cap);
            ms->param_counts = (int32_t *)realloc(ms->param_counts, sizeof(int32_t) * (size_t)ms->cap);
        }
        ms->names[ms->count]   = name;
        ms->values[ms->count]  = value;
        ms->fn_like[ms->count] = is_fn_like;
        ms->params[ms->count]  = macro_params;
        ms->param_counts[ms->count] = macro_param_count;
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
        if (ms->params && ms->params[i]) {
            for (int32_t j = 0; j < ms->param_counts[i]; j++)
                free(ms->params[i][j]);
            free(ms->params[i]);
        }
    }
    free(ms->names);
    free(ms->values);
    free(ms->fn_like);
    free(ms->params);
    free(ms->param_counts);
    free(ms);
}

int32_t with_cimport_macro_param_count(int64_t session, int32_t idx) {
    MacroSession *ms = (MacroSession *)(intptr_t)session;
    if (!ms || idx < 0 || idx >= ms->count) return 0;
    return ms->param_counts ? ms->param_counts[idx] : 0;
}

with_str with_cimport_macro_param_name(int64_t session, int32_t idx, int32_t param) {
    MacroSession *ms = (MacroSession *)(intptr_t)session;
    if (!ms || idx < 0 || idx >= ms->count) return make_str("");
    if (!ms->params || !ms->params[idx]) return make_str("");
    if (param < 0 || param >= ms->param_counts[idx]) return make_str("");
    return make_str(ms->params[idx][param]);
}

// ═══════════════════════════════════════════════════════════
// Phase 1: Full AST traversal API
// ═══════════════════════════════════════════════════════════

// ── Cursor/Type storage helpers ─────────────────────────────

static int32_t store_cursor(CImportSession *s, CXCursor cursor) {
    if (!s->cursors) {
        s->cursor_cap = 256;
        s->cursors = (CXCursor *)malloc(sizeof(CXCursor) * (size_t)s->cursor_cap);
        s->cursor_count = 0;
    }
    if (s->cursor_count >= s->cursor_cap) {
        s->cursor_cap *= 2;
        s->cursors = (CXCursor *)realloc(s->cursors, sizeof(CXCursor) * (size_t)s->cursor_cap);
    }
    s->cursors[s->cursor_count] = cursor;
    return s->cursor_count++;
}

static int32_t store_type(CImportSession *s, CXType type) {
    if (!s->types) {
        s->type_cap = 256;
        s->types = (CXType *)malloc(sizeof(CXType) * (size_t)s->type_cap);
        s->type_count = 0;
    }
    if (s->type_count >= s->type_cap) {
        s->type_cap *= 2;
        s->types = (CXType *)realloc(s->types, sizeof(CXType) * (size_t)s->type_cap);
    }
    s->types[s->type_count] = type;
    return s->type_count++;
}

// ── Children collection ─────────────────────────────────────

typedef struct {
    CImportSession *session;
    int32_t *indices;
    int32_t count;
    int32_t cap;
} ChildCollector;

static enum CXChildVisitResult collect_child_cursor(CXCursor cursor,
                                                      CXCursor parent,
                                                      CXClientData data) {
    (void)parent;
    ChildCollector *cc = (ChildCollector *)data;
    int32_t idx = store_cursor(cc->session, cursor);
    if (cc->count >= cc->cap) {
        cc->cap = cc->cap ? cc->cap * 2 : 16;
        cc->indices = (int32_t *)realloc(cc->indices, sizeof(int32_t) * (size_t)cc->cap);
    }
    cc->indices[cc->count++] = idx;
    return CXChildVisit_Continue;
}

static void ensure_children_cached(CImportSession *s, int32_t cursor_idx) {
    if (!s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return;

    // Ensure cache arrays are allocated
    if (!s->child_starts) {
        s->children_cache_cap = s->cursor_cap > 0 ? s->cursor_cap : 256;
        s->child_starts = (int32_t *)calloc((size_t)s->children_cache_cap, sizeof(int32_t));
        s->child_counts = (int32_t *)calloc((size_t)s->children_cache_cap, sizeof(int32_t));
        // Initialize with -1 to indicate uncached
        for (int32_t i = 0; i < s->children_cache_cap; i++)
            s->child_starts[i] = -1;
    }

    // Grow cache arrays if needed
    if (cursor_idx >= s->children_cache_cap) {
        int32_t old_cap = s->children_cache_cap;
        s->children_cache_cap = cursor_idx + 256;
        s->child_starts = (int32_t *)realloc(s->child_starts, sizeof(int32_t) * (size_t)s->children_cache_cap);
        s->child_counts = (int32_t *)realloc(s->child_counts, sizeof(int32_t) * (size_t)s->children_cache_cap);
        for (int32_t i = old_cap; i < s->children_cache_cap; i++)
            s->child_starts[i] = -1;
    }

    // Already cached?
    if (s->child_starts[cursor_idx] != -1) return;

    // Collect children
    ChildCollector cc = { s, NULL, 0, 0 };
    clang_visitChildren(s->cursors[cursor_idx], collect_child_cursor, &cc);

    // Store in flat child_indices array
    int32_t start = s->child_indices_count;
    if (!s->child_indices) {
        s->child_indices_cap = 256;
        s->child_indices = (int32_t *)malloc(sizeof(int32_t) * (size_t)s->child_indices_cap);
    }
    while (s->child_indices_count + cc.count > s->child_indices_cap) {
        s->child_indices_cap *= 2;
        s->child_indices = (int32_t *)realloc(s->child_indices, sizeof(int32_t) * (size_t)s->child_indices_cap);
    }
    for (int32_t i = 0; i < cc.count; i++) {
        s->child_indices[s->child_indices_count++] = cc.indices[i];
    }
    free(cc.indices);

    s->child_starts[cursor_idx] = start;
    s->child_counts[cursor_idx] = cc.count;
}

// ── Root cursor ─────────────────────────────────────────────

int32_t with_ci_root_cursor(int64_t session) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->tu) return -1;
    CXCursor root = clang_getTranslationUnitCursor(s->tu);
    return store_cursor(s, root);
}

// ── Tree traversal ──────────────────────────────────────────

int32_t with_ci_num_children(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return 0;
    ensure_children_cached(s, cursor_idx);
    return s->child_counts[cursor_idx];
}

int32_t with_ci_child(int64_t session, int32_t cursor_idx, int32_t child_index) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return -1;
    ensure_children_cached(s, cursor_idx);
    if (child_index < 0 || child_index >= s->child_counts[cursor_idx]) return -1;
    int32_t start = s->child_starts[cursor_idx];
    return s->child_indices[start + child_index];
}

// ── Cursor introspection ────────────────────────────────────

int32_t with_ci_cursor_kind(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return 0;
    return (int32_t)clang_getCursorKind(s->cursors[cursor_idx]);
}

with_str with_ci_cursor_spelling(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return make_str("");
    return clang_str_to_with(s, clang_getCursorSpelling(s->cursors[cursor_idx]));
}

with_str with_ci_cursor_kind_name(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return make_str("");
    enum CXCursorKind kind = clang_getCursorKind(s->cursors[cursor_idx]);
    return clang_str_to_with(s, clang_getCursorKindSpelling(kind));
}

// ── Type queries ────────────────────────────────────────────

int32_t with_ci_cursor_type(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return -1;
    CXType ty = clang_getCursorType(s->cursors[cursor_idx]);
    return store_type(s, ty);
}

int32_t with_ci_type_kind(int64_t session, int32_t type_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return 0;
    return (int32_t)s->types[type_idx].kind;
}

with_str with_ci_type_spelling(int64_t session, int32_t type_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return make_str("");
    return clang_str_to_with(s, clang_getTypeSpelling(s->types[type_idx]));
}

int64_t with_ci_type_sizeof(int64_t session, int32_t type_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return -1;
    return clang_Type_getSizeOf(s->types[type_idx]);
}

int64_t with_ci_type_alignof(int64_t session, int32_t type_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return -1;
    return clang_Type_getAlignOf(s->types[type_idx]);
}

int32_t with_ci_type_is_const(int64_t session, int32_t type_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return 0;
    return clang_isConstQualifiedType(s->types[type_idx]) ? 1 : 0;
}

int32_t with_ci_type_is_volatile(int64_t session, int32_t type_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return 0;
    return clang_isVolatileQualifiedType(s->types[type_idx]) ? 1 : 0;
}

int32_t with_ci_type_pointee(int64_t session, int32_t type_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return -1;
    CXType pointee = clang_getPointeeType(s->types[type_idx]);
    if (pointee.kind == CXType_Invalid) return -1;
    return store_type(s, pointee);
}

int32_t with_ci_type_canonical(int64_t session, int32_t type_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return -1;
    CXType canonical = clang_getCanonicalType(s->types[type_idx]);
    return store_type(s, canonical);
}

int32_t with_ci_type_result(int64_t session, int32_t type_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return -1;
    CXType result = clang_getResultType(s->types[type_idx]);
    if (result.kind == CXType_Invalid) return -1;
    return store_type(s, result);
}

int32_t with_ci_type_arg_count(int64_t session, int32_t type_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return 0;
    return clang_getNumArgTypes(s->types[type_idx]);
}

int32_t with_ci_type_arg(int64_t session, int32_t type_idx, int32_t index) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return -1;
    CXType arg = clang_getArgType(s->types[type_idx], (unsigned)index);
    if (arg.kind == CXType_Invalid) return -1;
    return store_type(s, arg);
}

int32_t with_ci_type_is_variadic(int64_t session, int32_t type_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return 0;
    return clang_isFunctionTypeVariadic(s->types[type_idx]) ? 1 : 0;
}

int64_t with_ci_type_array_size(int64_t session, int32_t type_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return -1;
    return clang_getArraySize(s->types[type_idx]);
}

int32_t with_ci_type_array_element(int64_t session, int32_t type_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return -1;
    CXType elem = clang_getArrayElementType(s->types[type_idx]);
    if (elem.kind == CXType_Invalid) return -1;
    return store_type(s, elem);
}

int32_t with_ci_type_named(int64_t session, int32_t type_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return -1;
    CXType named = clang_Type_getNamedType(s->types[type_idx]);
    if (named.kind == CXType_Invalid) return -1;
    return store_type(s, named);
}

int32_t with_ci_type_declaration(int64_t session, int32_t type_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return -1;
    CXCursor decl = clang_getTypeDeclaration(s->types[type_idx]);
    if (clang_Cursor_isNull(decl)) return -1;
    return store_cursor(s, decl);
}

// ── Translated type (reuse existing recursive translator) ───

with_str with_ci_type_translated(int64_t session, int32_t type_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return make_str("i32");
    char *result = translate_type_recursive(s, s->types[type_idx], 0, 0);
    return session_make_str(s, result ? result : "i32");
}

// ── Linkage / storage / inline ──────────────────────────────

int32_t with_ci_cursor_linkage(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return 0;
    return (int32_t)clang_getCursorLinkage(s->cursors[cursor_idx]);
}

int32_t with_ci_cursor_storage_class(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return 0;
    return (int32_t)clang_Cursor_getStorageClass(s->cursors[cursor_idx]);
}

int32_t with_ci_cursor_is_inline(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return 0;
    return clang_Cursor_isFunctionInlined(s->cursors[cursor_idx]) ? 1 : 0;
}

// ── Source location ─────────────────────────────────────────

with_str with_ci_cursor_location(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return make_str("");
    CXSourceLocation loc = clang_getCursorLocation(s->cursors[cursor_idx]);
    CXFile file = NULL;
    unsigned line = 0, col = 0;
    clang_getFileLocation(loc, &file, &line, &col, NULL);
    if (!file) return make_str("");
    CXString fname = clang_getFileName(file);
    const char *fname_str = clang_getCString(fname);
    char buf[1024];
    snprintf(buf, sizeof(buf), "%s:%u:%u", fname_str ? fname_str : "?", line, col);
    clang_disposeString(fname);
    return session_make_str(s, buf);
}

with_str with_ci_cursor_source_text(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return make_str("");
    CXSourceRange range = clang_getCursorExtent(s->cursors[cursor_idx]);
    CXSourceLocation start_loc = clang_getRangeStart(range);
    CXSourceLocation end_loc = clang_getRangeEnd(range);
    CXFile file = NULL;
    unsigned start_off = 0, end_off = 0;
    clang_getFileLocation(start_loc, &file, NULL, NULL, &start_off);
    clang_getFileLocation(end_loc, NULL, NULL, NULL, &end_off);
    if (!file || end_off <= start_off) return make_str("");

    // Get file contents via the TU's source buffer
    size_t buf_size = 0;
    const char *buf = clang_getFileContents(s->tu, file, &buf_size);
    if (!buf || end_off > buf_size) return make_str("");

    size_t len = end_off - start_off;
    char *text = (char *)malloc(len + 1);
    memcpy(text, buf + start_off, len);
    text[len] = 0;

    with_str result = session_make_str(s, text);
    free(text);
    return result;
}

// ── Struct/Union/Enum specifics ─────────────────────────────

int32_t with_ci_cursor_is_anonymous(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return 0;
    return clang_Cursor_isAnonymous(s->cursors[cursor_idx]) ? 1 : 0;
}

int32_t with_ci_cursor_is_bitfield(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return 0;
    return clang_Cursor_isBitField(s->cursors[cursor_idx]) ? 1 : 0;
}

int64_t with_ci_field_offset_bits(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return -1;
    CXType parent_type = clang_getCursorType(clang_getCursorSemanticParent(s->cursors[cursor_idx]));
    CXString name = clang_getCursorSpelling(s->cursors[cursor_idx]);
    long long offset = clang_Type_getOffsetOf(parent_type, clang_getCString(name));
    clang_disposeString(name);
    return offset;
}

int64_t with_ci_enum_const_value_new(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return 0;
    return clang_getEnumConstantDeclValue(s->cursors[cursor_idx]);
}

int32_t with_ci_cursor_is_definition(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return 0;
    return clang_isCursorDefinition(s->cursors[cursor_idx]) ? 1 : 0;
}

// ── Target info ─────────────────────────────────────────────

int32_t with_ci_pointer_width(int64_t session) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->tu) return 8;
    CXType void_ptr = clang_getCanonicalType(
        clang_getResultType(clang_getCursorType(clang_getTranslationUnitCursor(s->tu))));
    // Fallback: just return platform pointer size
    return (int32_t)sizeof(void *);
}

with_str with_ci_target_triple(int64_t session) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->tu) return make_str("");
    CXTargetInfo ti = clang_getTranslationUnitTargetInfo(s->tu);
    if (!ti) return make_str("");
    CXString triple = clang_TargetInfo_getTriple(ti);
    with_str result = session_make_str(s, clang_getCString(triple));
    clang_disposeString(triple);
    clang_TargetInfo_dispose(ti);
    return result;
}

int32_t with_ci_sizeof_long(int64_t session) {
    // On arm64 macOS, long is 8 bytes. On 32-bit, it's 4.
    return (int32_t)sizeof(long);
}

int32_t with_ci_char_is_signed(int64_t session) {
    // On arm64 macOS/Linux, char is signed. On ARM, char may be unsigned.
    (void)session;
    #ifdef __CHAR_UNSIGNED__
    return 0;
    #else
    return 1;
    #endif
}

// ── Operator introspection (Session 2) ──────────────────────

int32_t with_ci_binary_op(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return -1;
    // Try source text extraction approach
    // Get the source text between first and second child
    ensure_children_cached(s, cursor_idx);
    if (s->child_counts[cursor_idx] < 2) return -1;

    int32_t start = s->child_starts[cursor_idx];
    int32_t lhs_idx = s->child_indices[start];
    int32_t rhs_idx = s->child_indices[start + 1];

    CXSourceRange lhs_range = clang_getCursorExtent(s->cursors[lhs_idx]);
    CXSourceRange rhs_range = clang_getCursorExtent(s->cursors[rhs_idx]);
    CXSourceLocation lhs_end = clang_getRangeEnd(lhs_range);
    CXSourceLocation rhs_start = clang_getRangeStart(rhs_range);

    unsigned lhs_end_off = 0, rhs_start_off = 0;
    CXFile file = NULL;
    clang_getFileLocation(lhs_end, &file, NULL, NULL, &lhs_end_off);
    clang_getFileLocation(rhs_start, NULL, NULL, NULL, &rhs_start_off);
    if (!file || rhs_start_off <= lhs_end_off) return -1;

    size_t buf_size = 0;
    const char *buf = clang_getFileContents(s->tu, file, &buf_size);
    if (!buf || rhs_start_off > buf_size) return -1;

    // Extract and trim whitespace to find the operator
    const char *op_start = buf + lhs_end_off;
    const char *op_end = buf + rhs_start_off;
    while (op_start < op_end && (*op_start == ' ' || *op_start == '\t' || *op_start == '\n'))
        op_start++;
    while (op_end > op_start && (*(op_end-1) == ' ' || *(op_end-1) == '\t' || *(op_end-1) == '\n'))
        op_end--;

    size_t op_len = (size_t)(op_end - op_start);
    // Map to operator constants
    // BO_* constants matching C's BinaryOperatorKind
    if (op_len == 1) {
        switch (op_start[0]) {
            case '+': return 0;   // BO_Add
            case '-': return 1;   // BO_Sub
            case '*': return 2;   // BO_Mul
            case '/': return 3;   // BO_Div
            case '%': return 4;   // BO_Rem
            case '&': return 5;   // BO_And
            case '|': return 6;   // BO_Or
            case '^': return 7;   // BO_Xor
            case '<': return 12;  // BO_LT
            case '>': return 13;  // BO_GT
            case '=': return 18;  // BO_Assign
            case ',': return 19;  // BO_Comma
        }
    } else if (op_len == 2) {
        if (op_start[0] == '<' && op_start[1] == '<') return 8;   // BO_Shl
        if (op_start[0] == '>' && op_start[1] == '>') return 9;   // BO_Shr
        if (op_start[0] == '&' && op_start[1] == '&') return 10;  // BO_LAnd
        if (op_start[0] == '|' && op_start[1] == '|') return 11;  // BO_LOr
        if (op_start[0] == '<' && op_start[1] == '=') return 14;  // BO_LE
        if (op_start[0] == '>' && op_start[1] == '=') return 15;  // BO_GE
        if (op_start[0] == '=' && op_start[1] == '=') return 16;  // BO_EQ
        if (op_start[0] == '!' && op_start[1] == '=') return 17;  // BO_NE
        if (op_start[0] == '+' && op_start[1] == '=') return 20;  // BO_AddAssign
        if (op_start[0] == '-' && op_start[1] == '=') return 21;  // BO_SubAssign
        if (op_start[0] == '*' && op_start[1] == '=') return 22;  // BO_MulAssign
        if (op_start[0] == '/' && op_start[1] == '=') return 23;  // BO_DivAssign
        if (op_start[0] == '%' && op_start[1] == '=') return 24;  // BO_RemAssign
        if (op_start[0] == '&' && op_start[1] == '=') return 25;  // BO_AndAssign
        if (op_start[0] == '|' && op_start[1] == '=') return 26;  // BO_OrAssign
        if (op_start[0] == '^' && op_start[1] == '=') return 27;  // BO_XorAssign
    } else if (op_len == 3) {
        if (op_start[0] == '<' && op_start[1] == '<' && op_start[2] == '=') return 28; // BO_ShlAssign
        if (op_start[0] == '>' && op_start[1] == '>' && op_start[2] == '=') return 29; // BO_ShrAssign
    }
    return -1;
}

int32_t with_ci_unary_op(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return -1;
    // Get source text of the unary operator cursor
    CXSourceRange range = clang_getCursorExtent(s->cursors[cursor_idx]);
    ensure_children_cached(s, cursor_idx);
    if (s->child_counts[cursor_idx] < 1) return -1;

    int32_t child_idx = s->child_indices[s->child_starts[cursor_idx]];
    CXSourceRange child_range = clang_getCursorExtent(s->cursors[child_idx]);

    CXSourceLocation op_loc = clang_getRangeStart(range);
    CXSourceLocation child_start = clang_getRangeStart(child_range);
    CXSourceLocation child_end = clang_getRangeEnd(child_range);

    unsigned op_off = 0, child_start_off = 0, child_end_off = 0;
    CXFile file = NULL;
    clang_getFileLocation(op_loc, &file, NULL, NULL, &op_off);
    clang_getFileLocation(child_start, NULL, NULL, NULL, &child_start_off);
    clang_getFileLocation(child_end, NULL, NULL, NULL, &child_end_off);

    if (!file) return -1;

    size_t buf_size = 0;
    const char *buf = clang_getFileContents(s->tu, file, &buf_size);
    if (!buf) return -1;

    // Prefix operator: op appears before child
    if (op_off < child_start_off) {
        size_t len = child_start_off - op_off;
        const char *op = buf + op_off;
        while (len > 0 && (op[len-1] == ' ' || op[len-1] == '\t')) len--;
        if (len == 1 && op[0] == '-') return 0;  // UO_Minus
        if (len == 1 && op[0] == '~') return 1;  // UO_Not (bitwise)
        if (len == 1 && op[0] == '!') return 2;  // UO_LNot (logical)
        if (len == 1 && op[0] == '&') return 3;  // UO_AddrOf
        if (len == 1 && op[0] == '*') return 4;  // UO_Deref
        if (len == 1 && op[0] == '+') return 5;  // UO_Plus
        if (len == 2 && op[0] == '+' && op[1] == '+') return 6; // UO_PreInc
        if (len == 2 && op[0] == '-' && op[1] == '-') return 7; // UO_PreDec
    }
    // Postfix operator: op appears after child
    if (op_off >= child_end_off || child_end_off > op_off) {
        unsigned range_end_off = 0;
        clang_getFileLocation(clang_getRangeEnd(range), NULL, NULL, NULL, &range_end_off);
        if (range_end_off > child_end_off) {
            const char *op = buf + child_end_off;
            size_t len = range_end_off - child_end_off;
            while (len > 0 && (op[0] == ' ' || op[0] == '\t')) { op++; len--; }
            if (len >= 2 && op[0] == '+' && op[1] == '+') return 8; // UO_PostInc
            if (len >= 2 && op[0] == '-' && op[1] == '-') return 9; // UO_PostDec
        }
    }
    return -1;
}

// ── Constant evaluation ─────────────────────────────────────

// Simplified eval: returns 1 if the cursor evaluates to an integer
int32_t with_ci_eval_int_valid(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return 0;
    CXEvalResult eval = clang_Cursor_Evaluate(s->cursors[cursor_idx]);
    if (!eval) return 0;
    int valid = (clang_EvalResult_getKind(eval) == CXEval_Int) ? 1 : 0;
    clang_EvalResult_dispose(eval);
    return valid;
}

// Simplified eval: returns the integer value (0 if not evaluatable)
int64_t with_ci_eval_int_value(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return 0;
    CXEvalResult eval = clang_Cursor_Evaluate(s->cursors[cursor_idx]);
    if (!eval) return 0;
    int64_t val = 0;
    if (clang_EvalResult_getKind(eval) == CXEval_Int) {
        val = clang_EvalResult_getAsLongLong(eval);
    }
    clang_EvalResult_dispose(eval);
    return val;
}

int32_t with_ci_eval_as_int(int64_t session, int32_t cursor_idx, int64_t *out) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count || !out) return 0;
    CXEvalResult eval = clang_Cursor_Evaluate(s->cursors[cursor_idx]);
    if (!eval) return 0;
    CXEvalResultKind kind = clang_EvalResult_getKind(eval);
    if (kind == CXEval_Int) {
        *out = clang_EvalResult_getAsLongLong(eval);
        clang_EvalResult_dispose(eval);
        return 1;
    }
    clang_EvalResult_dispose(eval);
    return 0;
}

int32_t with_ci_eval_as_float(int64_t session, int32_t cursor_idx, double *out) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count || !out) return 0;
    CXEvalResult eval = clang_Cursor_Evaluate(s->cursors[cursor_idx]);
    if (!eval) return 0;
    CXEvalResultKind kind = clang_EvalResult_getKind(eval);
    if (kind == CXEval_Float) {
        *out = clang_EvalResult_getAsDouble(eval);
        clang_EvalResult_dispose(eval);
        return 1;
    }
    clang_EvalResult_dispose(eval);
    return 0;
}

with_str with_ci_eval_as_str(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return make_str("");
    CXEvalResult eval = clang_Cursor_Evaluate(s->cursors[cursor_idx]);
    if (!eval) return make_str("");
    CXEvalResultKind kind = clang_EvalResult_getKind(eval);
    if (kind == CXEval_StrLiteral || kind == CXEval_CFStr || kind == CXEval_ObjCStrLiteral) {
        const char *str = clang_EvalResult_getAsStr(eval);
        with_str result = session_make_str(s, str ? str : "");
        clang_EvalResult_dispose(eval);
        return result;
    }
    clang_EvalResult_dispose(eval);
    return make_str("");
}

// ── Calling convention ──────────────────────────────────────

int32_t with_ci_calling_conv(int64_t session, int32_t type_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->types || type_idx < 0 || type_idx >= s->type_count) return 0;
    return (int32_t)clang_getFunctionTypeCallingConv(s->types[type_idx]);
}

// ── Typedef ─────────────────────────────────────────────────

int32_t with_ci_typedef_underlying_type(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return -1;
    CXType underlying = clang_getTypedefDeclUnderlyingType(s->cursors[cursor_idx]);
    if (underlying.kind == CXType_Invalid) return -1;
    return store_type(s, underlying);
}

// ── Member expression ───────────────────────────────────────

int32_t with_ci_member_is_arrow(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return 0;
    // Check if the operator between base and member is "->"
    // MemberRefExpr children: [base]. The member name comes from cursor spelling.
    // Arrow vs dot is determined by source text.
    CXSourceRange range = clang_getCursorExtent(s->cursors[cursor_idx]);
    CXSourceLocation start = clang_getRangeStart(range);
    CXSourceLocation end = clang_getRangeEnd(range);
    unsigned start_off = 0, end_off = 0;
    CXFile file = NULL;
    clang_getFileLocation(start, &file, NULL, NULL, &start_off);
    clang_getFileLocation(end, NULL, NULL, NULL, &end_off);
    if (!file || end_off <= start_off) return 0;
    size_t buf_size = 0;
    const char *buf = clang_getFileContents(s->tu, file, &buf_size);
    if (!buf) return 0;
    // Search for "->" in the source text
    for (unsigned i = start_off; i + 1 < end_off && i < buf_size - 1; i++) {
        if (buf[i] == '-' && buf[i+1] == '>') return 1;
    }
    return 0;
}

with_str with_ci_member_field_name(int64_t session, int32_t cursor_idx) {
    // For MemberRefExpr, the cursor spelling IS the field name
    return with_ci_cursor_spelling(session, cursor_idx);
}

// ── Enum integer type ───────────────────────────────────────

// ── Typedef → anonymous record detection ────────────────────

// For typedef idx, check if underlying type is an anonymous record with fields.
// Returns field count if yes (> 0), 0 if not an anonymous record.
int32_t with_cimport_typedef_anon_record_field_count(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    CXType underlying = clang_getTypedefDeclUnderlyingType(s->decls[idx]);
    CXType canonical = clang_getCanonicalType(underlying);
    if (canonical.kind != CXType_Record) return 0;
    CXCursor decl = clang_getTypeDeclaration(canonical);
    if (clang_Cursor_isNull(decl)) return 0;
    // Check if the record is anonymous/unnamed
    CXString name = clang_getCursorSpelling(decl);
    const char *n = clang_getCString(name);
    int is_anon = (!n || !n[0] || strstr(n, "(unnamed") || strstr(n, "(anonymous"));
    clang_disposeString(name);
    if (!is_anon) return 0;
    // Check if it has a definition
    if (!clang_isCursorDefinition(decl)) return 0;
    // Count fields
    FieldCollector fc = {NULL, 0, 0};
    clang_visitChildren(decl, collect_field, &fc);
    int count = fc.count;
    for (int i = 0; i < fc.count; i++) {
        free(fc.fields[i].name);
        free(fc.fields[i].type_spelling);
    }
    free(fc.fields);
    return count;
}

// Get field name/type for a typedef's anonymous record underlying type
with_str with_cimport_typedef_anon_field_name(int64_t session, int32_t idx, int32_t field) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("");
    CXType underlying = clang_getTypedefDeclUnderlyingType(s->decls[idx]);
    CXType canonical = clang_getCanonicalType(underlying);
    if (canonical.kind != CXType_Record) return make_str("");
    CXCursor decl = clang_getTypeDeclaration(canonical);
    FieldCollector fc = {NULL, 0, 0};
    clang_visitChildren(decl, collect_field, &fc);
    with_str result = make_str("");
    if (field >= 0 && field < fc.count) {
        result = session_make_str(s, fc.fields[field].name);
    }
    for (int i = 0; i < fc.count; i++) {
        free(fc.fields[i].name);
        free(fc.fields[i].type_spelling);
    }
    free(fc.fields);
    return result;
}

with_str with_cimport_typedef_anon_field_type(int64_t session, int32_t idx, int32_t field) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return make_str("i32");
    CXType underlying = clang_getTypedefDeclUnderlyingType(s->decls[idx]);
    CXType canonical = clang_getCanonicalType(underlying);
    if (canonical.kind != CXType_Record) return make_str("i32");
    CXCursor decl = clang_getTypeDeclaration(canonical);
    FieldCollector fc = {NULL, 0, 0};
    clang_visitChildren(decl, collect_field, &fc);
    with_str result = make_str("i32");
    if (field >= 0 && field < fc.count) {
        int is_last = (field == fc.count - 1) ? 1 : 0;
        char *translated = translate_type_recursive(s, fc.fields[field].clang_type, 0, is_last);
        result = session_make_str(s, translated ? translated : "i32");
    }
    for (int i = 0; i < fc.count; i++) {
        free(fc.fields[i].name);
        free(fc.fields[i].type_spelling);
    }
    free(fc.fields);
    return result;
}

int32_t with_cimport_typedef_anon_field_is_bitfield(int64_t session, int32_t idx, int32_t field) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    CXType underlying = clang_getTypedefDeclUnderlyingType(s->decls[idx]);
    CXType canonical = clang_getCanonicalType(underlying);
    if (canonical.kind != CXType_Record) return 0;
    CXCursor decl = clang_getTypeDeclaration(canonical);
    FieldCollector fc = {NULL, 0, 0};
    clang_visitChildren(decl, collect_field, &fc);
    int result = 0;
    if (field >= 0 && field < fc.count) result = fc.fields[field].is_bitfield;
    for (int i = 0; i < fc.count; i++) {
        free(fc.fields[i].name);
        free(fc.fields[i].type_spelling);
    }
    free(fc.fields);
    return result;
}

// Check if typedef's underlying type is a union (not struct)
int32_t with_cimport_typedef_anon_is_union(int64_t session, int32_t idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || idx < 0 || idx >= s->decl_count) return 0;
    CXType underlying = clang_getTypedefDeclUnderlyingType(s->decls[idx]);
    CXType canonical = clang_getCanonicalType(underlying);
    if (canonical.kind != CXType_Record) return 0;
    CXCursor decl = clang_getTypeDeclaration(canonical);
    return (clang_getCursorKind(decl) == CXCursor_UnionDecl) ? 1 : 0;
}

int32_t with_ci_enum_int_type(int64_t session, int32_t cursor_idx) {
    CImportSession *s = (CImportSession *)(intptr_t)session;
    if (!s || !s->cursors || cursor_idx < 0 || cursor_idx >= s->cursor_count) return -1;
    CXType int_type = clang_getEnumDeclIntegerType(s->cursors[cursor_idx]);
    if (int_type.kind == CXType_Invalid) return -1;
    return store_type(s, int_type);
}
