// rt/clang_bridge.w — libclang bridge for c_import, written in With.
//
// Wraps libclang into a flat i64-handle API for the With compiler.
// All libclang types accessed through extern fn declarations.
// No C headers needed — resolves at link time.

// ── Runtime helpers (from rt_core.w) ────────────────────────────
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> void
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> void
extern fn with_memset(dst: *mut u8, val: i32, len: i64) -> void
extern fn rt_write(fd: i32, buf: *const u8, len: u64) -> i64

// ── libSystem extern fns ────────────────────────────────────────
extern fn mkstemp(template_path: *mut u8) -> i32
extern fn rename(old: *const u8, new_path: *const u8) -> i32
extern fn unlink(path: *const u8) -> i32
extern fn close(fd: i32) -> i32
extern fn write(fd: i32, buf: *const u8, nbyte: u64) -> i64
extern fn popen(command: *const u8, mode: *const u8) -> *mut u8
extern fn pclose(stream: *mut u8) -> i32
extern fn fgets(buf: *mut u8, size: i32, stream: *mut u8) -> *mut u8
extern fn strtod(str: *const u8, endptr: *mut *mut u8) -> f64
extern fn realpath(path: *const u8, resolved_name: *mut u8) -> *mut u8

// ── libclang types ──────────────────────────────────────────────
// Struct layouts match the C ABI exactly.

type CXCursor:
    kind: i32
    xdata: i32
    data: [3]i64

type CXType:
    kind: i32
    pad0: i32
    data: [2]i64

type CXString:
    data: i64
    private_flags: u32
    pad0: u32

type CXSourceLocation:
    ptr_data: [2]i64
    int_data: u32
    pad0: u32

type CXSourceRange:
    ptr_data: [2]i64
    begin_int_data: u32
    end_int_data: u32

type CXToken:
    int_data: [4]u32
    ptr_data: i64

// ── libclang extern fn declarations ─────────────────────────────
// Index/TU
extern fn clang_createIndex(exclude: i32, display: i32) -> *mut u8
extern fn clang_disposeIndex(index: *mut u8)
extern fn clang_parseTranslationUnit(index: *mut u8, src: *const u8, args: *const *const u8, nargs: i32, unsaved: *mut u8, nunsaved: u32, opts: u32) -> *mut u8
extern fn clang_disposeTranslationUnit(tu: *mut u8)
extern fn clang_getTranslationUnitCursor(tu: *mut u8) -> CXCursor
extern fn clang_getNumDiagnostics(tu: *mut u8) -> u32
extern fn clang_getDiagnostic(tu: *mut u8, idx: u32) -> *mut u8
extern fn clang_getDiagnosticSeverity(diag: *mut u8) -> i32
extern fn clang_getDiagnosticSpelling(diag: *mut u8) -> CXString
extern fn clang_disposeDiagnostic(diag: *mut u8)
extern fn clang_getTranslationUnitTargetInfo(tu: *mut u8) -> *mut u8
extern fn clang_TargetInfo_getTriple(ti: *mut u8) -> CXString
extern fn clang_TargetInfo_dispose(ti: *mut u8)
extern fn clang_getFile(tu: *mut u8, file_name: *const u8) -> *mut u8
extern fn clang_getFileContents(tu: *mut u8, file: *mut u8, size: *mut u64) -> *const u8
extern fn clang_Cursor_getTranslationUnit(cursor: CXCursor) -> *mut u8

// Cursor queries
extern fn clang_getCursorKind(cursor: CXCursor) -> i32
extern fn clang_Cursor_isNull(cursor: CXCursor) -> i32
extern fn clang_getCursorSpelling(cursor: CXCursor) -> CXString
extern fn clang_getCursorType(cursor: CXCursor) -> CXType
extern fn clang_getCursorLocation(cursor: CXCursor) -> CXSourceLocation
extern fn clang_getCursorLinkage(cursor: CXCursor) -> i32
extern fn clang_Cursor_getStorageClass(cursor: CXCursor) -> i32
extern fn clang_Cursor_getNumArguments(cursor: CXCursor) -> i32
extern fn clang_Cursor_getArgument(cursor: CXCursor, idx: u32) -> CXCursor
extern fn clang_Cursor_isFunctionInlined(cursor: CXCursor) -> i32
extern fn clang_Cursor_isBitField(cursor: CXCursor) -> i32
extern fn clang_Cursor_isAnonymous(cursor: CXCursor) -> i32
extern fn clang_Cursor_hasAttrs(cursor: CXCursor) -> i32
extern fn clang_Cursor_getBinaryOpcode(cursor: CXCursor) -> i32
extern fn clang_getCursorUnaryOperatorKind(cursor: CXCursor) -> i32
extern fn clang_getCursorDefinition(cursor: CXCursor) -> CXCursor
extern fn clang_getCursorReferenced(cursor: CXCursor) -> CXCursor
extern fn clang_getCursorExtent(cursor: CXCursor) -> CXSourceRange
extern fn clang_isCursorDefinition(cursor: CXCursor) -> i32
extern fn clang_getCursorKindSpelling(kind: i32) -> CXString
extern fn clang_getCursorTLSKind(cursor: CXCursor) -> i32
extern fn clang_Cursor_Evaluate(cursor: CXCursor) -> *mut u8
extern fn clang_Cursor_isEqual(a: CXCursor, b: CXCursor) -> i32
extern fn clang_getCursorSemanticParent(cursor: CXCursor) -> CXCursor

// Type queries
extern fn clang_getCanonicalType(ty: CXType) -> CXType
extern fn clang_getTypeSpelling(ty: CXType) -> CXString
extern fn clang_isConstQualifiedType(ty: CXType) -> i32
extern fn clang_isVolatileQualifiedType(ty: CXType) -> i32
extern fn clang_isRestrictQualifiedType(ty: CXType) -> i32
extern fn clang_Type_getSizeOf(ty: CXType) -> i64
extern fn clang_Type_getAlignOf(ty: CXType) -> i64
extern fn clang_Type_getOffsetOf(ty: CXType, field: *const u8) -> i64
extern fn clang_getPointeeType(ty: CXType) -> CXType
extern fn clang_getArraySize(ty: CXType) -> i64
extern fn clang_getArrayElementType(ty: CXType) -> CXType
extern fn clang_getResultType(ty: CXType) -> CXType
extern fn clang_getNumArgTypes(ty: CXType) -> i32
extern fn clang_getArgType(ty: CXType, idx: u32) -> CXType
extern fn clang_isFunctionTypeVariadic(ty: CXType) -> i32
extern fn clang_getFunctionTypeCallingConv(ty: CXType) -> i32
extern fn clang_getElementType(ty: CXType) -> CXType
extern fn clang_getNumElements(ty: CXType) -> i64
extern fn clang_Type_getModifiedType(ty: CXType) -> CXType
extern fn clang_Type_getValueType(ty: CXType) -> CXType
extern fn clang_getTypedefDeclUnderlyingType(cursor: CXCursor) -> CXType
extern fn clang_Type_getNamedType(ty: CXType) -> CXType
extern fn clang_getTypeDeclaration(ty: CXType) -> CXCursor
extern fn clang_getEnumDeclIntegerType(cursor: CXCursor) -> CXType
extern fn clang_getEnumConstantDeclValue(cursor: CXCursor) -> i64

// Visitor
extern fn clang_visitChildren(parent: CXCursor, visitor: *const u8, data: *mut u8) -> u32

// libclang CX_StorageClass values.
let CX_SC_EXTERN: i32 = 2

// String
extern fn clang_getCString(s: CXString) -> *const u8
extern fn clang_disposeString(s: CXString)

// File
extern fn clang_getFileLocation(loc: CXSourceLocation, file: *mut *mut u8, line: *mut u32, col: *mut u32, offset: *mut u32)
extern fn clang_getExpansionLocation(loc: CXSourceLocation, file: *mut *mut u8, line: *mut u32, col: *mut u32, offset: *mut u32)
extern fn clang_getSpellingLocation(loc: CXSourceLocation, file: *mut *mut u8, line: *mut u32, col: *mut u32, offset: *mut u32)
extern fn clang_getLocationForOffset(tu: *mut u8, file: *mut u8, offset: u32) -> CXSourceLocation
extern fn clang_getPresumedLocation(loc: CXSourceLocation, filename: *mut CXString, line: *mut u32, col: *mut u32)
extern fn clang_File_isEqual(f1: *mut u8, f2: *mut u8) -> i32
extern fn clang_getFileName(file: *mut u8) -> CXString

// Source range
extern fn clang_getRange(begin: CXSourceLocation, end: CXSourceLocation) -> CXSourceRange
extern fn clang_getRangeStart(range: CXSourceRange) -> CXSourceLocation
extern fn clang_getRangeEnd(range: CXSourceRange) -> CXSourceLocation

// Tokens
extern fn clang_tokenize(tu: *mut u8, range: CXSourceRange, tokens: *mut *mut CXToken, count: *mut u32)
extern fn clang_getTokenSpelling(tu: *mut u8, token: CXToken) -> CXString
extern fn clang_disposeTokens(tu: *mut u8, tokens: *mut CXToken, count: u32)

// Evaluation
extern fn clang_EvalResult_getKind(result: *mut u8) -> i32
extern fn clang_EvalResult_getAsLongLong(result: *mut u8) -> i64
extern fn clang_EvalResult_isUnsignedInt(result: *mut u8) -> i32
extern fn clang_EvalResult_getAsUnsigned(result: *mut u8) -> u64
extern fn clang_EvalResult_getAsDouble(result: *mut u8) -> f64
extern fn clang_EvalResult_getAsStr(result: *mut u8) -> *const u8
extern fn clang_EvalResult_dispose(result: *mut u8)

// ── CXTypeKind constants ────────────────────────────────────────
let CXType_Invalid: i32 = 0
let CXType_Void: i32 = 2
let CXType_Bool: i32 = 3
let CXType_Char_U: i32 = 4
let CXType_UChar: i32 = 5
let CXType_UShort: i32 = 8
let CXType_UInt: i32 = 9
let CXType_ULong: i32 = 10
let CXType_ULongLong: i32 = 11
let CXType_UInt128: i32 = 12
let CXType_Char_S: i32 = 13
let CXType_SChar: i32 = 14
let CXType_Short: i32 = 16
let CXType_Int: i32 = 17
let CXType_Long: i32 = 18
let CXType_LongLong: i32 = 19
let CXType_Int128: i32 = 20
let CXType_Float: i32 = 21
let CXType_Double: i32 = 22
let CXType_LongDouble: i32 = 23
let CXType_Float128: i32 = 30
let CXType_Half: i32 = 31
let CXType_Float16: i32 = 32
let CXType_Complex: i32 = 100
let CXType_Pointer: i32 = 101
let CXType_BlockPointer: i32 = 102
let CXType_Record: i32 = 105
let CXType_Enum: i32 = 106
let CXType_FunctionNoProto: i32 = 110
let CXType_FunctionProto: i32 = 111
let CXType_ConstantArray: i32 = 112
let CXType_Vector: i32 = 113
let CXType_IncompleteArray: i32 = 114
let CXType_VariableArray: i32 = 115
let CXType_ExtVector: i32 = 176
let CXType_Atomic: i32 = 177

// ── CXCursorKind constants ──────────────────────────────────────
let CXCursor_StructDecl: i32 = 2
let CXCursor_UnionDecl: i32 = 3
let CXCursor_EnumDecl: i32 = 5
let CXCursor_FieldDecl: i32 = 6
let CXCursor_EnumConstantDecl: i32 = 7
let CXCursor_FunctionDecl: i32 = 8
let CXCursor_VarDecl: i32 = 9
let CXCursor_TypedefDecl: i32 = 20
let CXCursor_TranslationUnit: i32 = 350
let CXCursor_StaticAssert: i32 = 602

// ── CXChildVisitResult ──────────────────────────────────────────
let CXChildVisit_Break: i32 = 0
let CXChildVisit_Continue: i32 = 1
let CXChildVisit_Recurse: i32 = 2

// ── CXDiagnosticSeverity ────────────────────────────────────────
let CXDiagnostic_Error: i32 = 3

// ── CXCallingConv ───────────────────────────────────────────────
let CXCallingConv_C: i32 = 1
let CXCallingConv_X86StdCall: i32 = 2
let CXCallingConv_X86FastCall: i32 = 3
let CXCallingConv_X86ThisCall: i32 = 4
let CXCallingConv_AAPCS: i32 = 6
let CXCallingConv_AAPCS_VFP: i32 = 7
let CXCallingConv_Win64: i32 = 10

// ── CXEvalResultKind ────────────────────────────────────────────
let CXEval_Int: i32 = 1
let CXEval_Float: i32 = 2
let CXEval_StrLiteral: i32 = 4

// ── Implicit cast kind codes (returned by with_ci_implicit_cast_kind) ──
let CI_CAST_UNKNOWN: i32 = 0
let CI_CAST_LVALUE_TO_RVALUE: i32 = 1
let CI_CAST_ARRAY_TO_POINTER: i32 = 2
let CI_CAST_FUNCTION_TO_POINTER: i32 = 3
let CI_CAST_INT_TO_POINTER: i32 = 4
let CI_CAST_POINTER_TO_INT: i32 = 5
let CI_CAST_BITCAST: i32 = 6
let CI_CAST_INT_WIDEN: i32 = 7
let CI_CAST_INT_TRUNCATE: i32 = 8
let CI_CAST_FLOAT_WIDEN: i32 = 9
let CI_CAST_FLOAT_TRUNCATE: i32 = 10
let CI_CAST_FLOAT_TO_INT: i32 = 11
let CI_CAST_INT_TO_FLOAT: i32 = 12
let CI_CAST_INT_TO_BOOL: i32 = 13
let CI_CAST_POINTER_TO_BOOL: i32 = 14
let CI_CAST_NOOP: i32 = 15
let CI_CAST_NULL_TO_POINTER: i32 = 16
let CI_CAST_FLOAT_TO_BOOL: i32 = 17

// ── Binary/Unary operator codes ─────────────────────────────────
let BO_ADD: i32 = 1
let BO_SUB: i32 = 2
let BO_MUL: i32 = 3
let BO_DIV: i32 = 4
let BO_MOD: i32 = 5
let BO_AND: i32 = 6
let BO_OR: i32 = 7
let BO_XOR: i32 = 8
let BO_SHL: i32 = 9
let BO_SHR: i32 = 10
let BO_EQ: i32 = 11
let BO_NE: i32 = 12
let BO_LT: i32 = 13
let BO_GT: i32 = 14
let BO_LE: i32 = 15
let BO_GE: i32 = 16
let BO_LAND: i32 = 17
let BO_LOR: i32 = 18
let BO_ASSIGN: i32 = 19
let BO_ADD_ASSIGN: i32 = 20
let BO_SUB_ASSIGN: i32 = 21
let BO_MUL_ASSIGN: i32 = 22
let BO_DIV_ASSIGN: i32 = 23
let BO_MOD_ASSIGN: i32 = 24
let BO_AND_ASSIGN: i32 = 25
let BO_OR_ASSIGN: i32 = 26
let BO_XOR_ASSIGN: i32 = 27
let BO_SHL_ASSIGN: i32 = 28
let BO_SHR_ASSIGN: i32 = 29
let BO_COMMA: i32 = 30
let UO_MINUS: i32 = 1
let UO_BITNOT: i32 = 2
let UO_LOGNOT: i32 = 3
let UO_ADDROF: i32 = 4
let UO_DEREF: i32 = 5
let UO_PLUS: i32 = 6
let UO_PRE_INC: i32 = 7
let UO_PRE_DEC: i32 = 8
let UO_POST_INC: i32 = 9
let UO_POST_DEC: i32 = 10

// ── MAX_TYPE_DEPTH ──────────────────────────────────────────────
let MAX_TYPE_DEPTH: i32 = 16

// ── Internal struct types ───────────────────────────────────────

type FieldInfo:
    name: *mut u8
    type_spelling: *mut u8
    is_bitfield: i32
    clang_type: CXType

type EnumConstInfo:
    name: *mut u8
    value: i64

type FieldCollector:
    fields: *mut FieldInfo
    count: i32
    cap: i32

type EnumConstCollector:
    consts: *mut EnumConstInfo
    count: i32
    cap: i32

type DeclCache:
    fields: *mut FieldInfo
    field_count: i32
    enum_consts: *mut EnumConstInfo
    enum_const_count: i32
    fields_cached: i32
    enum_consts_cached: i32

type CImportSession:
    index: *mut u8
    tu: *mut u8
    decls: *mut CXCursor
    decl_count: i32
    decl_cap: i32
    caches: *mut DeclCache
    err_msg: *mut u8
    tmp_path: *mut u8
    strings: *mut *mut u8
    str_count: i32
    str_cap: i32
    header_file: *mut u8
    // Phase 1: AST traversal
    cursors: *mut CXCursor
    cursor_count: i32
    cursor_cap: i32
    types: *mut CXType
    type_count: i32
    type_cap: i32
    // Children cache
    child_starts: *mut i32
    child_counts: *mut i32
    child_indices: *mut i32
    child_indices_count: i32
    child_indices_cap: i32
    children_cache_cap: i32

type ChildCollector:
    session: *mut CImportSession
    indices: *mut i32
    count: i32
    cap: i32

type MacroSession:
    names: *mut *mut u8
    values: *mut *mut u8
    fn_like: *mut i32
    params: *mut *mut *mut u8
    param_counts: *mut i32
    count: i32
    cap: i32

// ── String helpers ──────────────────────────────────────────────

unsafe fn c_strlen(s: *const u8) -> i64:
    if s as i64 == 0: return 0
    var i: i64 = 0
    while *((s as i64 + i) as *const u8) != 0:
        i = i + 1
    i

unsafe fn c_strdup(s: *const u8) -> *mut u8:
    if s as i64 == 0: return 0 as *mut u8
    let len = c_strlen(s)
    let out = with_alloc(len + 1)
    if out as i64 == 0: return 0 as *mut u8
    if len > 0:
        with_memcpy(out, s, len)
    *((out as i64 + len) as *mut u8) = 0
    out

unsafe fn c_strcmp(a: *const u8, b: *const u8) -> i32:
    if a as i64 == 0 and b as i64 == 0: return 0
    if a as i64 == 0: return -1
    if b as i64 == 0: return 1
    var i: i64 = 0
    while true:
        let ca = *((a as i64 + i) as *const u8)
        let cb = *((b as i64 + i) as *const u8)
        if ca != cb: return (ca as i32) - (cb as i32)
        if ca == 0: return 0
        i = i + 1
    0

unsafe fn c_strncmp(a: *const u8, b: *const u8, n: i64) -> i32:
    if n <= 0: return 0
    var i: i64 = 0
    while i < n:
        let ca = *((a as i64 + i) as *const u8)
        let cb = *((b as i64 + i) as *const u8)
        if ca != cb: return (ca as i32) - (cb as i32)
        if ca == 0: return 0
        i = i + 1
    0

unsafe fn c_strstr(haystack: *const u8, needle: *const u8) -> *const u8:
    if haystack as i64 == 0 or needle as i64 == 0: return 0 as *const u8
    let nlen = c_strlen(needle)
    if nlen == 0: return haystack
    var i: i64 = 0
    let hlen = c_strlen(haystack)
    while i <= hlen - nlen:
        if c_strncmp((haystack as i64 + i) as *const u8, needle, nlen) == 0:
            return (haystack as i64 + i) as *const u8
        i = i + 1
    0 as *const u8

unsafe fn c_strchr(s: *const u8, c: u8) -> *const u8:
    if s as i64 == 0: return 0 as *const u8
    var i: i64 = 0
    while *((s as i64 + i) as *const u8) != 0:
        if *((s as i64 + i) as *const u8) == c:
            return (s as i64 + i) as *const u8
        i = i + 1
    if c == 0: return (s as i64 + i) as *const u8
    0 as *const u8

// Allocate and copy a with_str to a null-terminated C string
unsafe fn str_to_cstr(s: str) -> *mut u8:
    let out = with_alloc(s.len() + 1)
    if out as i64 == 0: return 0 as *mut u8
    if s.len() > 0:
        let sp = *(&s as *const *const u8)
        with_memcpy(out, sp, s.len())
    *((out as i64 + s.len()) as *mut u8) = 0
    out

unsafe fn make_str(p: *const u8) -> str:
    if p as i64 == 0 or *p == 0:
        return ""
    let len = c_strlen(p)
    let owned = with_alloc(len + 1)
    if owned as i64 == 0: return ""
    with_memcpy(owned, p, len)
    *((owned as i64 + len) as *mut u8) = 0
    var raw: [2]i64 = [owned as i64, len]
    let sp = &raw as *const str
    *sp

// Session-tracked string allocation (freed on dispose)
unsafe fn session_strdup(s: *mut CImportSession, p: *const u8) -> *mut u8:
    if p as i64 == 0: return 0 as *mut u8
    let dup = c_strdup(p)
    if dup as i64 == 0: return 0 as *mut u8
    if (*s).str_count >= (*s).str_cap:
        (*s).str_cap = if (*s).str_cap > 0: (*s).str_cap * 2 else: 64
        let new_size = (*s).str_cap as i64 * 8
        let new_buf = with_alloc(new_size)
        if (*s).strings as i64 != 0 and (*s).str_count > 0:
            with_memcpy(new_buf, (*s).strings as *const u8, (*s).str_count as i64 * 8)
        if (*s).strings as i64 != 0:
            with_free((*s).strings as *mut u8)
        (*s).strings = new_buf as *mut *mut u8
    *(((*s).strings as i64 + (*s).str_count as i64 * 8) as *mut *mut u8) = dup
    (*s).str_count = (*s).str_count + 1
    dup

unsafe fn session_make_str(s: *mut CImportSession, p: *const u8) -> str:
    if p as i64 == 0 or *p == 0:
        return ""
    let dup = session_strdup(s, p)
    if dup as i64 == 0: return ""
    let len = c_strlen(dup)
    var raw: [2]i64 = [dup as i64, len]
    let sp = &raw as *const str
    *sp

unsafe fn clang_str_to_with(s: *mut CImportSession, cxs: CXString) -> str:
    let cstr = clang_getCString(cxs)
    let r = session_make_str(s, cstr)
    clang_disposeString(cxs)
    r

// ── Buffer builder (replaces snprintf) ──────────────────────────

unsafe fn buf_append_str(buf: *mut u8, pos: *mut i64, cap: i64, s: *const u8):
    if s as i64 == 0: return
    let len = c_strlen(s)
    var i: i64 = 0
    while i < len and *pos < cap - 1:
        *((buf as i64 + *pos) as *mut u8) = *((s as i64 + i) as *const u8)
        *pos = *pos + 1
        i = i + 1
    *((buf as i64 + *pos) as *mut u8) = 0

// Append a string to a buffer, replacing each ' with '\'' for shell safety.
unsafe fn buf_append_shell_escaped(buf: *mut u8, pos: *mut i64, cap: i64, s: *const u8):
    if s as i64 == 0: return
    let len = c_strlen(s)
    var i: i64 = 0
    while i < len and *pos < cap - 5:
        let ch = *((s as i64 + i) as *const u8)
        if ch == 39:  // single quote
            // Write '\'' (4 chars)
            *((buf as i64 + *pos) as *mut u8) = 39       // '
            *pos = *pos + 1
            *((buf as i64 + *pos) as *mut u8) = 92       // backslash
            *pos = *pos + 1
            *((buf as i64 + *pos) as *mut u8) = 39       // '
            *pos = *pos + 1
            *((buf as i64 + *pos) as *mut u8) = 39       // '
            *pos = *pos + 1
        else:
            *((buf as i64 + *pos) as *mut u8) = ch
            *pos = *pos + 1
        i = i + 1
    *((buf as i64 + *pos) as *mut u8) = 0

unsafe fn buf_append_i64(buf: *mut u8, pos: *mut i64, cap: i64, val: i64):
    var tmp: [32]u8 = [0 as u8; 32]
    var v = val
    if v < 0:
        buf_append_str(buf, pos, cap, "-" as *const u8)
        v = 0 - v
    if v == 0:
        buf_append_str(buf, pos, cap, "0" as *const u8)
        return
    var idx: i64 = 31
    while v > 0 and idx > 0:
        idx = idx - 1
        *(((&raw mut tmp) as i64 + idx) as *mut u8) = (48 + (v % 10) as i32) as u8
        v = v / 10
    buf_append_str(buf, pos, cap, ((&tmp) as i64 + idx) as *const u8)

// ── Dynamic array helpers ───────────────────────────────────────

unsafe fn grow_ptr_array(arr: *mut *mut u8, count: i32, cap: *mut i32, elem_size: i64) -> *mut u8:
    if count < *cap: return *arr
    *cap = if *cap > 0: *cap * 2 else: 64
    let new_size = (*cap) as i64 * elem_size
    let new_buf = with_alloc(new_size)
    if new_buf as i64 != 0:
        with_memset(new_buf, 0, new_size)
        if *arr as i64 != 0 and count > 0:
            with_memcpy(new_buf, *arr as *const u8, count as i64 * elem_size)
        if *arr as i64 != 0:
            with_free(*arr)
    *arr = new_buf
    new_buf

// ── Global state ────────────────────────────────────────────────

var g_emitted_names: *mut *mut u8 = 0 as *mut *mut u8
var g_emitted_count: i32 = 0
var g_emitted_cap: i32 = 0

var g_cimport_include_paths: [32]*mut u8 = [0 as *mut u8; 32]
var g_cimport_include_count: i32 = 0

var sdk_path_buf: [1024]u8 = [0 as u8; 1024]
var sdk_path_resolved: i32 = 0

var resource_dir_buf: [1024]u8 = [0 as u8; 1024]
var resource_dir_resolved: i32 = 0

// ── SDK path detection ──────────────────────────────────────────

unsafe fn get_sdk_path() -> *const u8:
    if sdk_path_resolved == 0:
        sdk_path_resolved = 1
        let p = popen("xcrun --show-sdk-path 2>/dev/null\0" as *const u8, "r\0" as *const u8)
        if p as i64 != 0:
            let r = fgets(&raw mut sdk_path_buf as *mut [1024]u8 as *mut u8, 1024, p)
            if r as i64 != 0:
                let len = c_strlen(&sdk_path_buf as *const [1024]u8 as *const u8)
                if len > 0 and sdk_path_buf[(len - 1) as i64] == 10:
                    sdk_path_buf[(len - 1) as i64] = 0
            let _ = pclose(p)
    if sdk_path_buf[0] != 0:
        return &sdk_path_buf as *const [1024]u8 as *const u8
    0 as *const u8

unsafe fn get_clang_resource_dir() -> *const u8:
    if resource_dir_resolved == 0:
        resource_dir_resolved = 1
        // Try LLVM_PREFIX/lib/clang/<version> by listing the directory
        let p = popen("ls -1d /usr/local/llvm/lib/clang/[0-9]* 2>/dev/null | head -1\0" as *const u8, "r\0" as *const u8)
        if p as i64 != 0:
            let r = fgets(&raw mut resource_dir_buf as *mut [1024]u8 as *mut u8, 1024, p)
            if r as i64 != 0:
                let len = c_strlen(&resource_dir_buf as *const [1024]u8 as *const u8)
                if len > 0 and resource_dir_buf[(len - 1) as i64] == 10:
                    resource_dir_buf[(len - 1) as i64] = 0
            let _ = pclose(p)
    if resource_dir_buf[0] != 0:
        return &resource_dir_buf as *const [1024]u8 as *const u8
    0 as *const u8

// ── Name deduplication ──────────────────────────────────────────

unsafe fn is_name_emitted(name: *const u8) -> i32:
    var i: i32 = 0
    while i < g_emitted_count:
        let entry = *((g_emitted_names as i64 + i as i64 * 8) as *const *const u8)
        if c_strcmp(entry, name) == 0: return 1
        i = i + 1
    0

unsafe fn mark_name_emitted(name: *const u8):
    if is_name_emitted(name) != 0: return
    if g_emitted_count >= g_emitted_cap:
        g_emitted_cap = if g_emitted_cap > 0: g_emitted_cap * 2 else: 256
        let new_buf = with_alloc(g_emitted_cap as i64 * 8)
        if g_emitted_names as i64 != 0 and g_emitted_count > 0:
            with_memcpy(new_buf, g_emitted_names as *const u8, g_emitted_count as i64 * 8)
        if g_emitted_names as i64 != 0:
            with_free(g_emitted_names as *mut u8)
        g_emitted_names = new_buf as *mut *mut u8
    *((g_emitted_names as i64 + g_emitted_count as i64 * 8) as *mut *mut u8) = c_strdup(name)
    g_emitted_count = g_emitted_count + 1

// ── Type translation helpers ────────────────────────────────────

unsafe fn strip_qualifiers(s: *mut CImportSession, spelling: *const u8) -> *mut u8:
    if spelling as i64 == 0: return session_strdup(s, "\0" as *const u8)
    let buf = c_strdup(spelling)
    if buf as i64 == 0: return session_strdup(s, "\0" as *const u8)
    // Remove "restrict", "volatile", "_Atomic" substrings
    // Simplified: just track through session
    let result = session_strdup(s, buf as *const u8)
    with_free(buf)
    result

unsafe fn get_type_spelling(s: *mut CImportSession, ty: CXType) -> str:
    let canonical = clang_getCanonicalType(ty)
    let cxs = clang_getTypeSpelling(canonical)
    let cstr = clang_getCString(cxs)
    let result = session_make_str(s, cstr)
    clang_disposeString(cxs)
    result

// Forward declaration pattern: translate_fn_type calls translate_type_recursive and vice versa.
// In With, both are defined at module scope so mutual recursion works.

unsafe fn translate_type_recursive_mode(s: *mut CImportSession, ty: CXType, depth: i32, is_last_struct_field: i32, preserve_incomplete_arrays: i32) -> *mut u8:
    if depth > MAX_TYPE_DEPTH:
        return session_strdup(s, "__UNSUPPORTED:type too complex\0" as *const u8)
    let canonical = clang_getCanonicalType(ty)
    let kind = canonical.kind

    if kind == CXType_Void: return session_strdup(s, "void\0" as *const u8)
    if kind == CXType_Bool: return session_strdup(s, "bool\0" as *const u8)
    if kind == CXType_Char_S or kind == CXType_SChar: return session_strdup(s, "c_char\0" as *const u8)
    if kind == CXType_Char_U or kind == CXType_UChar: return session_strdup(s, "u8\0" as *const u8)
    if kind == CXType_Short: return session_strdup(s, "c_short\0" as *const u8)
    if kind == CXType_UShort: return session_strdup(s, "c_ushort\0" as *const u8)
    if kind == CXType_Int: return session_strdup(s, "c_int\0" as *const u8)
    if kind == CXType_UInt: return session_strdup(s, "c_uint\0" as *const u8)
    if kind == CXType_Long: return session_strdup(s, "c_long\0" as *const u8)
    if kind == CXType_LongLong: return session_strdup(s, "c_longlong\0" as *const u8)
    if kind == CXType_ULong: return session_strdup(s, "c_ulong\0" as *const u8)
    if kind == CXType_ULongLong: return session_strdup(s, "c_ulonglong\0" as *const u8)
    if kind == CXType_Int128: return session_strdup(s, "i128\0" as *const u8)
    if kind == CXType_UInt128: return session_strdup(s, "u128\0" as *const u8)
    if kind == CXType_Half or kind == CXType_Float16: return session_strdup(s, "f16\0" as *const u8)
    if kind == CXType_Float: return session_strdup(s, "f32\0" as *const u8)
    if kind == CXType_Double: return session_strdup(s, "f64\0" as *const u8)
    if kind == CXType_LongDouble: return session_strdup(s, "c_longdouble\0" as *const u8)
    if kind == CXType_Float128: return session_strdup(s, "f128\0" as *const u8)

    if kind == CXType_Pointer:
        let pointee = clang_getPointeeType(canonical)
        let can_pointee = clang_getCanonicalType(pointee)
        let is_const = clang_isConstQualifiedType(pointee)
        let is_volatile = clang_isVolatileQualifiedType(pointee)
        // Function pointer
        if can_pointee.kind == CXType_FunctionProto or can_pointee.kind == CXType_FunctionNoProto:
            let fn_str = translate_fn_type(s, can_pointee, depth + 1)
            if fn_str as i64 == 0: return session_strdup(s, "*const i8\0" as *const u8)
            var buf: [2048]u8 = [0 as u8; 2048]
            var pos: i64 = 0
            buf_append_str(&raw mut buf as *mut [2048]u8 as *mut u8, &raw mut pos, 2048, "*const \0" as *const u8)
            buf_append_str(&raw mut buf as *mut [2048]u8 as *mut u8, &raw mut pos, 2048, fn_str as *const u8)
            return session_strdup(s, &buf as *const [2048]u8 as *const u8)
        let qual = if is_volatile != 0: "volatile\0" as *const u8 else: if is_const != 0: "const\0" as *const u8 else: "mut\0" as *const u8
        // void pointer
        if can_pointee.kind == CXType_Void:
            var buf: [64]u8 = [0 as u8; 64]
            var pos: i64 = 0
            buf_append_str(&raw mut buf as *mut [64]u8 as *mut u8, &raw mut pos, 64, "*\0" as *const u8)
            buf_append_str(&raw mut buf as *mut [64]u8 as *mut u8, &raw mut pos, 64, qual)
            buf_append_str(&raw mut buf as *mut [64]u8 as *mut u8, &raw mut pos, 64, " c_void\0" as *const u8)
            return session_strdup(s, &buf as *const [64]u8 as *const u8)
        // char pointer
        if can_pointee.kind == CXType_Char_S or can_pointee.kind == CXType_SChar or can_pointee.kind == CXType_Char_U:
            var buf: [64]u8 = [0 as u8; 64]
            var pos: i64 = 0
            buf_append_str(&raw mut buf as *mut [64]u8 as *mut u8, &raw mut pos, 64, "*\0" as *const u8)
            buf_append_str(&raw mut buf as *mut [64]u8 as *mut u8, &raw mut pos, 64, qual)
            buf_append_str(&raw mut buf as *mut [64]u8 as *mut u8, &raw mut pos, 64, " i8\0" as *const u8)
            return session_strdup(s, &buf as *const [64]u8 as *const u8)
        // General pointer
        let inner = translate_type_recursive_mode(s, pointee, depth + 1, 0, preserve_incomplete_arrays)
        if inner as i64 == 0 or c_strncmp(inner as *const u8, "__UNSUPPORTED:\0" as *const u8, 14) == 0:
            return session_strdup(s, "*const i8\0" as *const u8)
        var buf: [2048]u8 = [0 as u8; 2048]
        var pos: i64 = 0
        buf_append_str(&raw mut buf as *mut [2048]u8 as *mut u8, &raw mut pos, 2048, "*\0" as *const u8)
        buf_append_str(&raw mut buf as *mut [2048]u8 as *mut u8, &raw mut pos, 2048, qual)
        buf_append_str(&raw mut buf as *mut [2048]u8 as *mut u8, &raw mut pos, 2048, " \0" as *const u8)
        buf_append_str(&raw mut buf as *mut [2048]u8 as *mut u8, &raw mut pos, 2048, inner as *const u8)
        return session_strdup(s, &buf as *const [2048]u8 as *const u8)

    if kind == CXType_ConstantArray:
        let size = clang_getArraySize(canonical)
        let elem = clang_getArrayElementType(canonical)
        let elem_str = translate_type_recursive_mode(s, elem, depth + 1, 0, preserve_incomplete_arrays)
        if elem_str as i64 == 0 or c_strcmp(elem_str as *const u8, "c_void\0" as *const u8) == 0:
            return session_strdup(s, "c_void\0" as *const u8)
        if c_strncmp(elem_str as *const u8, "__UNSUPPORTED:\0" as *const u8, 14) == 0:
            return elem_str
        var buf: [2048]u8 = [0 as u8; 2048]
        var pos: i64 = 0
        buf_append_str(&raw mut buf as *mut [2048]u8 as *mut u8, &raw mut pos, 2048, "[\0" as *const u8)
        buf_append_i64(&raw mut buf as *mut [2048]u8 as *mut u8, &raw mut pos, 2048, size)
        buf_append_str(&raw mut buf as *mut [2048]u8 as *mut u8, &raw mut pos, 2048, "]\0" as *const u8)
        buf_append_str(&raw mut buf as *mut [2048]u8 as *mut u8, &raw mut pos, 2048, elem_str as *const u8)
        return session_strdup(s, &buf as *const [2048]u8 as *const u8)

    if kind == CXType_IncompleteArray:
        let elem = clang_getArrayElementType(canonical)
        let elem_str = translate_type_recursive_mode(s, elem, depth + 1, 0, preserve_incomplete_arrays)
        if elem_str as i64 == 0 or c_strncmp(elem_str as *const u8, "__UNSUPPORTED:\0" as *const u8, 14) == 0:
            return session_strdup(s, "*const i8\0" as *const u8)
        var buf: [2048]u8 = [0 as u8; 2048]
        var pos: i64 = 0
        if preserve_incomplete_arrays != 0 or is_last_struct_field != 0:
            buf_append_str(&raw mut buf as *mut [2048]u8 as *mut u8, &raw mut pos, 2048, "[0]\0" as *const u8)
            buf_append_str(&raw mut buf as *mut [2048]u8 as *mut u8, &raw mut pos, 2048, elem_str as *const u8)
        else:
            buf_append_str(&raw mut buf as *mut [2048]u8 as *mut u8, &raw mut pos, 2048, "*\0" as *const u8)
            buf_append_str(&raw mut buf as *mut [2048]u8 as *mut u8, &raw mut pos, 2048, elem_str as *const u8)
        return session_strdup(s, &buf as *const [2048]u8 as *const u8)

    if kind == CXType_FunctionProto or kind == CXType_FunctionNoProto:
        return translate_fn_type(s, canonical, depth + 1)

    if kind == CXType_Record:
        let spelling = clang_getTypeSpelling(canonical)
        let name_str = clang_getCString(spelling)
        var bare = name_str
        if bare as i64 != 0 and c_strncmp(bare, "const \0" as *const u8, 6) == 0:
            bare = (bare as i64 + 6) as *const u8
        if bare as i64 != 0 and c_strncmp(bare, "volatile \0" as *const u8, 9) == 0:
            bare = (bare as i64 + 9) as *const u8
        if bare as i64 != 0 and c_strncmp(bare, "struct \0" as *const u8, 7) == 0:
            bare = (bare as i64 + 7) as *const u8
        else if bare as i64 != 0 and c_strncmp(bare, "union \0" as *const u8, 6) == 0:
            bare = (bare as i64 + 6) as *const u8
        if bare as i64 == 0 or *bare == 0 or *bare == 95 or c_strstr(name_str, "(anonymous\0" as *const u8) as i64 != 0:
            clang_disposeString(spelling)
            return session_strdup(s, "c_void\0" as *const u8)
        let result = session_strdup(s, bare)
        clang_disposeString(spelling)
        return result

    if kind == CXType_Enum:
        return session_strdup(s, "i32\0" as *const u8)

    if kind == CXType_Complex:
        let elem = clang_getElementType(canonical)
        let sz = clang_Type_getSizeOf(elem)
        if sz <= 4: return session_strdup(s, "Complex32\0" as *const u8)
        return session_strdup(s, "Complex64\0" as *const u8)

    if kind == CXType_Vector or kind == CXType_ExtVector:
        let elem = clang_getElementType(canonical)
        let num_elements = clang_getNumElements(canonical)
        let elem_str = translate_type_recursive_mode(s, elem, depth + 1, 0, preserve_incomplete_arrays)
        if elem_str as i64 != 0 and num_elements > 0:
            var buf: [256]u8 = [0 as u8; 256]
            var pos: i64 = 0
            buf_append_str(&raw mut buf as *mut [256]u8 as *mut u8, &raw mut pos, 256, "Vector(\0" as *const u8)
            buf_append_i64(&raw mut buf as *mut [256]u8 as *mut u8, &raw mut pos, 256, num_elements)
            buf_append_str(&raw mut buf as *mut [256]u8 as *mut u8, &raw mut pos, 256, ", \0" as *const u8)
            buf_append_str(&raw mut buf as *mut [256]u8 as *mut u8, &raw mut pos, 256, elem_str as *const u8)
            buf_append_str(&raw mut buf as *mut [256]u8 as *mut u8, &raw mut pos, 256, ")\0" as *const u8)
            return session_strdup(s, &buf as *const [256]u8 as *const u8)
        return session_strdup(s, "__UNSUPPORTED:vector type\0" as *const u8)

    if kind == CXType_VariableArray:
        return session_strdup(s, "__UNSUPPORTED:variable-length array\0" as *const u8)

    if kind == CXType_BlockPointer:
        return session_strdup(s, "*const i8\0" as *const u8)

    if kind == CXType_Atomic:
        let inner = clang_Type_getModifiedType(canonical)
        if inner.kind != CXType_Invalid:
            return translate_type_recursive_mode(s, inner, depth + 1, is_last_struct_field, preserve_incomplete_arrays)
        let inner2 = clang_Type_getValueType(canonical)
        if inner2.kind != CXType_Invalid:
            return translate_type_recursive_mode(s, inner2, depth + 1, is_last_struct_field, preserve_incomplete_arrays)
        return session_strdup(s, "c_int\0" as *const u8)

    // Default: unsupported — must produce a loud compile error
    session_strdup(s, "__UNSUPPORTED:unknown_type_kind\0" as *const u8)

unsafe fn translate_type_recursive(s: *mut CImportSession, ty: CXType, depth: i32, is_last_struct_field: i32) -> *mut u8:
    translate_type_recursive_mode(s, ty, depth, is_last_struct_field, 0)

unsafe fn translate_storage_type_recursive(s: *mut CImportSession, ty: CXType, depth: i32, is_last_struct_field: i32) -> *mut u8:
    translate_type_recursive_mode(s, ty, depth, is_last_struct_field, 1)

unsafe fn cimport_path_to_cstr(path: str) -> *mut u8:
    let buf = with_alloc(path.len() + 1)
    if buf as i64 == 0:
        return 0 as *mut u8
    var i = 0
    while i as i64 < path.len():
        *((buf as i64 + i as i64) as *mut u8) = path.byte_at(i as i64)
        i = i + 1
    *((buf as i64 + path.len() as i64) as *mut u8) = 0
    buf

unsafe fn cimport_type_is_const_storage(ty: CXType) -> i32:
    let canonical = clang_getCanonicalType(ty)
    if clang_isConstQualifiedType(canonical) != 0:
        return 1
    let kind = canonical.kind
    if kind == CXType_ConstantArray or kind == CXType_IncompleteArray or kind == CXType_VariableArray:
        return cimport_type_is_const_storage(clang_getArrayElementType(canonical))
    0

unsafe fn translate_fn_type(s: *mut CImportSession, fn_type: CXType, depth: i32) -> *mut u8:
    if depth > MAX_TYPE_DEPTH:
        return session_strdup(s, "__UNSUPPORTED:type too complex\0" as *const u8)
    let ret_type = clang_getResultType(fn_type)
    var ret_str = translate_type_recursive(s, ret_type, depth + 1, 0)
    if ret_str as i64 == 0:
        ret_str = session_strdup(s, "void\0" as *const u8)
    let num_args = clang_getNumArgTypes(fn_type)
    let is_variadic = if clang_isFunctionTypeVariadic(fn_type) != 0 and fn_type.kind != CXType_FunctionNoProto: 1 else: 0
    var params: [4096]u8 = [0 as u8; 4096]
    var pos: i64 = 0
    var i: i32 = 0
    while i < num_args:
        if i > 0:
            buf_append_str(&raw mut params as *mut [4096]u8 as *mut u8, &raw mut pos, 4096, ", \0" as *const u8)
        let arg_type = clang_getArgType(fn_type, i as u32)
        var arg_str = translate_type_recursive(s, arg_type, depth + 1, 0)
        if arg_str as i64 == 0 or c_strncmp(arg_str as *const u8, "__UNSUPPORTED:\0" as *const u8, 14) == 0:
            arg_str = session_strdup(s, "i32\0" as *const u8)
        buf_append_str(&raw mut params as *mut [4096]u8 as *mut u8, &raw mut pos, 4096, arg_str as *const u8)
        i = i + 1
    if is_variadic != 0:
        if num_args > 0:
            buf_append_str(&raw mut params as *mut [4096]u8 as *mut u8, &raw mut pos, 4096, ", ...\0" as *const u8)
        else:
            buf_append_str(&raw mut params as *mut [4096]u8 as *mut u8, &raw mut pos, 4096, "...\0" as *const u8)
    if c_strncmp(ret_str as *const u8, "__UNSUPPORTED:\0" as *const u8, 14) == 0:
        ret_str = session_strdup(s, "i32\0" as *const u8)
    var buf: [8192]u8 = [0 as u8; 8192]
    var bpos: i64 = 0
    buf_append_str(&raw mut buf as *mut [8192]u8 as *mut u8, &raw mut bpos, 8192, "fn(\0" as *const u8)
    buf_append_str(&raw mut buf as *mut [8192]u8 as *mut u8, &raw mut bpos, 8192, &params as *const [4096]u8 as *const u8)
    buf_append_str(&raw mut buf as *mut [8192]u8 as *mut u8, &raw mut bpos, 8192, ") -> \0" as *const u8)
    buf_append_str(&raw mut buf as *mut [8192]u8 as *mut u8, &raw mut bpos, 8192, ret_str as *const u8)
    session_strdup(s, &buf as *const [8192]u8 as *const u8)

// ── Visitor callbacks ───────────────────────────────────────────
// These receive CXCursor by pointer (With calling convention matches C ABI for >16B structs)

@[callconv("c")]
unsafe fn collect_decl(cursor: CXCursor, parent: CXCursor, data: *mut u8) -> i32:
    let s = data as *mut CImportSession
    let kind = clang_getCursorKind(cursor)
    if kind != CXCursor_FunctionDecl and kind != CXCursor_StructDecl and kind != CXCursor_UnionDecl and kind != CXCursor_EnumDecl and kind != CXCursor_TypedefDecl and kind != CXCursor_VarDecl and kind != CXCursor_StaticAssert:
        return CXChildVisit_Continue
    // Filter transitive includes
    if (unsafe: *s).header_file as i64 != 0:
        let loc = clang_getCursorLocation(cursor)
        var file: *mut u8 = 0 as *mut u8
        clang_getFileLocation(loc, &raw mut file, 0 as *mut u32, 0 as *mut u32, 0 as *mut u32)
        if file as i64 != 0 and clang_File_isEqual(file, (unsafe: *s).header_file) == 0:
            return CXChildVisit_Continue
    // Grow decl array
    if (unsafe: *s).decl_count >= (unsafe: *s).decl_cap:
        (unsafe: *s).decl_cap = if (unsafe: *s).decl_cap > 0: (unsafe: *s).decl_cap * 2 else: 256
        let new_buf = with_alloc((unsafe: *s).decl_cap as i64 * 32)  // sizeof(CXCursor) = 32
        if (unsafe: *s).decls as i64 != 0 and (unsafe: *s).decl_count > 0:
            with_memcpy(new_buf, (unsafe: *s).decls as *const u8, (unsafe: *s).decl_count as i64 * 32)
        if (unsafe: *s).decls as i64 != 0:
            with_free((unsafe: *s).decls as *mut u8)
        (unsafe: *s).decls = new_buf as *mut CXCursor
    let dst = (((unsafe: *s).decls as i64) + ((unsafe: *s).decl_count as i64 * 32)) as *mut CXCursor
    unsafe: *dst = cursor
    (unsafe: *s).decl_count = (unsafe: *s).decl_count + 1
    CXChildVisit_Continue

@[callconv("c")]
unsafe fn collect_field(cursor: CXCursor, parent: CXCursor, data: *mut u8) -> i32:
    let fc = data as *mut FieldCollector
    if clang_getCursorKind(cursor) != CXCursor_FieldDecl:
        return CXChildVisit_Continue
    if (*fc).count >= (*fc).cap:
        (*fc).cap = if (*fc).cap > 0: (*fc).cap * 2 else: 16
        let new_buf = with_alloc((*fc).cap as i64 * 48)  // sizeof(FieldInfo) = 8+8+4+pad+24 = 48
        if new_buf as i64 != 0:
            with_memset(new_buf, 0, (*fc).cap as i64 * 48)
            if (*fc).fields as i64 != 0 and (*fc).count > 0:
                with_memcpy(new_buf, (*fc).fields as *const u8, (*fc).count as i64 * 48)
            if (*fc).fields as i64 != 0:
                with_free((*fc).fields as *mut u8)
        (*fc).fields = new_buf as *mut FieldInfo
    let name = clang_getCursorSpelling(cursor)
    let ty = clang_getCursorType(cursor)
    let canonical = clang_getCanonicalType(ty)
    let type_str = clang_getTypeSpelling(canonical)
    let fi = ((*fc).fields as i64 + (*fc).count as i64 * 48) as *mut FieldInfo
    (*fi).name = c_strdup(clang_getCString(name))
    (*fi).type_spelling = c_strdup(clang_getCString(type_str))
    (*fi).clang_type = ty
    (*fi).is_bitfield = if clang_Cursor_isBitField(cursor) != 0: 1 else: 0
    (*fc).count = (*fc).count + 1
    clang_disposeString(name)
    clang_disposeString(type_str)
    CXChildVisit_Continue

unsafe fn ensure_fields_cached(s: *mut CImportSession, idx: i32):
    if idx < 0 or idx >= (*s).decl_count: return
    if (*s).caches as i64 == 0:
        let size = (*s).decl_count as i64 * 48  // sizeof(DeclCache) ≈ 48
        (*s).caches = with_alloc(size) as *mut DeclCache
        with_memset((*s).caches as *mut u8, 0, size)
    let cache = ((*s).caches as i64 + idx as i64 * 48) as *mut DeclCache
    if (*cache).fields_cached != 0: return
    (*cache).fields_cached = 1
    var fc = FieldCollector { fields: 0 as *mut FieldInfo, count: 0, cap: 0 }
    let decl = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let _ = clang_visitChildren(decl, collect_field as *const u8, &raw mut fc as *mut FieldCollector as *mut u8)
    (*cache).fields = fc.fields
    (*cache).field_count = fc.count

@[callconv("c")]
unsafe fn collect_enum_const(cursor: CXCursor, parent: CXCursor, data: *mut u8) -> i32:
    let ec = data as *mut EnumConstCollector
    if clang_getCursorKind(cursor) != CXCursor_EnumConstantDecl:
        return CXChildVisit_Continue
    if (*ec).count >= (*ec).cap:
        (*ec).cap = if (*ec).cap > 0: (*ec).cap * 2 else: 16
        let new_buf = with_alloc((*ec).cap as i64 * 16)  // sizeof(EnumConstInfo) = 16
        if new_buf as i64 != 0:
            with_memset(new_buf, 0, (*ec).cap as i64 * 16)
            if (*ec).consts as i64 != 0 and (*ec).count > 0:
                with_memcpy(new_buf, (*ec).consts as *const u8, (*ec).count as i64 * 16)
            if (*ec).consts as i64 != 0:
                with_free((*ec).consts as *mut u8)
        (*ec).consts = new_buf as *mut EnumConstInfo
    let name = clang_getCursorSpelling(cursor)
    let ci = ((*ec).consts as i64 + (*ec).count as i64 * 16) as *mut EnumConstInfo
    (*ci).name = c_strdup(clang_getCString(name))
    (*ci).value = clang_getEnumConstantDeclValue(cursor)
    (*ec).count = (*ec).count + 1
    clang_disposeString(name)
    CXChildVisit_Continue

unsafe fn ensure_enum_consts_cached(s: *mut CImportSession, idx: i32):
    if idx < 0 or idx >= (*s).decl_count: return
    if (*s).caches as i64 == 0:
        let size = (*s).decl_count as i64 * 48
        (*s).caches = with_alloc(size) as *mut DeclCache
        with_memset((*s).caches as *mut u8, 0, size)
    let cache = ((*s).caches as i64 + idx as i64 * 48) as *mut DeclCache
    if (*cache).enum_consts_cached != 0: return
    (*cache).enum_consts_cached = 1
    var ec = EnumConstCollector { consts: 0 as *mut EnumConstInfo, count: 0, cap: 0 }
    let decl = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let _ = clang_visitChildren(decl, collect_enum_const as *const u8, &raw mut ec as *mut EnumConstCollector as *mut u8)
    (*cache).enum_consts = ec.consts
    (*cache).enum_const_count = ec.count

// ═══════════════════════════════════════════════════════════
// Public API
// ═══════════════════════════════════════════════════════════

@[c_export("with_cimport_available")]
pub unsafe fn cimport_available() -> i32:
    1

@[c_export("with_cimport_is_name_emitted")]
pub unsafe fn cimport_is_name_emitted(name: str) -> i32:
    if name.len() <= 0: return 0
    var buf: [512]u8 = [0 as u8; 512]
    let len = if name.len() < 511: name.len() else: 511
    if len > 0:
        let sp = *(&name as *const *const u8)
        with_memcpy(&raw mut buf as *mut [512]u8 as *mut u8, sp, len)
    buf[len as i64] = 0
    is_name_emitted(&buf as *const [512]u8 as *const u8)

@[c_export("with_cimport_mark_name_emitted")]
pub unsafe fn cimport_mark_name_emitted(name: str):
    if name.len() <= 0: return
    var buf: [512]u8 = [0 as u8; 512]
    let len = if name.len() < 511: name.len() else: 511
    if len > 0:
        let sp = *(&name as *const *const u8)
        with_memcpy(&raw mut buf as *mut [512]u8 as *mut u8, sp, len)
    buf[len as i64] = 0
    mark_name_emitted(&buf as *const [512]u8 as *const u8)

@[c_export("with_cimport_reset_names")]
pub unsafe fn cimport_reset_names():
    var i: i32 = 0
    while i < g_emitted_count:
        let entry = *((g_emitted_names as i64 + i as i64 * 8) as *const *mut u8)
        with_free(entry)
        i = i + 1
    if g_emitted_names as i64 != 0:
        with_free(g_emitted_names as *mut u8)
    g_emitted_names = 0 as *mut *mut u8
    g_emitted_count = 0
    g_emitted_cap = 0

@[c_export("with_cimport_add_include_path")]
pub unsafe fn cimport_add_include_path(path: str):
    if g_cimport_include_count >= 32 or path.len() <= 0: return
    let buf = with_alloc(path.len() + 1)
    if buf as i64 == 0: return
    let sp = *(&path as *const *const u8)
    with_memcpy(buf, sp, path.len())
    *((buf as i64 + path.len()) as *mut u8) = 0
    g_cimport_include_paths[g_cimport_include_count as i64] = buf
    g_cimport_include_count = g_cimport_include_count + 1

@[c_export("with_cimport_clear_include_paths")]
pub unsafe fn cimport_clear_include_paths():
    var i: i32 = 0
    while i < g_cimport_include_count:
        with_free(g_cimport_include_paths[i as i64])
        g_cimport_include_paths[i as i64] = 0 as *mut u8
        i = i + 1
    g_cimport_include_count = 0

// ── Parse ───────────────────────────────────────────────────

@[c_export("with_cimport_parse")]
pub unsafe fn cimport_parse(header_code: str) -> i64:
    let size = 232  // sizeof(CImportSession) — all pointer fields
    let s = with_alloc(size) as *mut CImportSession
    if s as i64 == 0: return 0
    with_memset(s as *mut u8, 0, size)

    // Create temp file
    var template_path: [32]u8 = [0 as u8; 32]
    let tmpl = "/tmp/with_cimport_XXXXXX\0"
    let tp = *(&tmpl as *const *const u8)
    with_memcpy(&raw mut template_path as *mut [32]u8 as *mut u8, tp, 25)
    let fd = mkstemp(&raw mut template_path as *mut [32]u8 as *mut u8)
    if fd < 0:
        (*s).err_msg = c_strdup("failed to create temp file\0" as *const u8)
        return s as i64

    let src_ptr = *(&header_code as *const *const u8)
    let _ = write(fd, src_ptr, header_code.len() as u64)
    let _ = write(fd, "\n\0" as *const u8, 1 as u64)
    let _ = close(fd)

    // Rename to .c
    var c_path_buf: [64]u8 = [0 as u8; 64]
    with_memcpy(&raw mut c_path_buf as *mut [64]u8 as *mut u8, &template_path as *const [32]u8 as *const u8, 32)
    let tlen = c_strlen(&template_path as *const [32]u8 as *const u8)
    *(((&raw mut c_path_buf) as i64 + tlen) as *mut u8) = 46  // '.'
    *(((&raw mut c_path_buf) as i64 + tlen + 1) as *mut u8) = 99  // 'c'
    *(((&raw mut c_path_buf) as i64 + tlen + 2) as *mut u8) = 0
    let _ = rename(&template_path as *const [32]u8 as *const u8, &c_path_buf as *const [64]u8 as *const u8)
    (*s).tmp_path = c_strdup(&c_path_buf as *const [64]u8 as *const u8)

    // Build compiler args
    var args: [64]*const u8 = [0 as *const u8; 64]
    var nargs: i32 = 0
    let sysroot = get_sdk_path()
    if sysroot as i64 != 0:
        args[nargs as i64] = "-isysroot\0" as *const u8
        nargs = nargs + 1
        args[nargs as i64] = sysroot
        nargs = nargs + 1
    let resdir = get_clang_resource_dir()
    if resdir as i64 != 0:
        args[nargs as i64] = "-resource-dir\0" as *const u8
        nargs = nargs + 1
        args[nargs as i64] = resdir
        nargs = nargs + 1
    var ip: i32 = 0
    while ip < g_cimport_include_count and nargs < 62:
        args[nargs as i64] = "-I\0" as *const u8
        nargs = nargs + 1
        args[nargs as i64] = g_cimport_include_paths[ip as i64] as *const u8
        nargs = nargs + 1
        ip = ip + 1

    (*s).index = clang_createIndex(0, 0)
    (*s).tu = clang_parseTranslationUnit((*s).index, (*s).tmp_path as *const u8, &args as *const [64]*const u8 as *const *const u8, nargs, 0 as *mut u8, 0 as u32, 0 as u32)

    if (*s).tu as i64 == 0:
        (*s).err_msg = c_strdup("failed to parse translation unit\0" as *const u8)
        return s as i64

    // Check for fatal errors
    let diag_count = clang_getNumDiagnostics((*s).tu)
    var di: u32 = 0
    while di < diag_count:
        let diag = clang_getDiagnostic((*s).tu, di)
        if clang_getDiagnosticSeverity(diag) >= CXDiagnostic_Error:
            let msg = clang_getDiagnosticSpelling(diag)
            (*s).err_msg = c_strdup(clang_getCString(msg))
            clang_disposeString(msg)
            clang_disposeDiagnostic(diag)
            return s as i64
        clang_disposeDiagnostic(diag)
        di = di + 1

    // Collect top-level declarations
    let root = clang_getTranslationUnitCursor((*s).tu)
    (*s).header_file = 0 as *mut u8
    let _ = clang_visitChildren(root, collect_decl as *const u8, s as *mut u8)
    s as i64

// ── Dispose ─────────────────────────────────────────────────

@[c_export("with_cimport_dispose")]
pub unsafe fn cimport_dispose(session: i64):
    let s = session as *mut CImportSession
    if s as i64 == 0: return
    if (*s).caches as i64 != 0:
        var i: i32 = 0
        while i < (*s).decl_count:
            let cache = ((*s).caches as i64 + i as i64 * 48) as *mut DeclCache
            var j: i32 = 0
            while j < (*cache).field_count:
                let fi = ((*cache).fields as i64 + j as i64 * 48) as *mut FieldInfo
                with_free((*fi).name)
                with_free((*fi).type_spelling)
                j = j + 1
            if (*cache).fields as i64 != 0:
                with_free((*cache).fields as *mut u8)
            j = 0
            while j < (*cache).enum_const_count:
                let ci = ((*cache).enum_consts as i64 + j as i64 * 16) as *mut EnumConstInfo
                with_free((*ci).name)
                j = j + 1
            if (*cache).enum_consts as i64 != 0:
                with_free((*cache).enum_consts as *mut u8)
            i = i + 1
        with_free((*s).caches as *mut u8)
    // Free tracked strings
    var si: i32 = 0
    while si < (*s).str_count:
        let entry = *(((*s).strings as i64 + si as i64 * 8) as *const *mut u8)
        with_free(entry)
        si = si + 1
    if (*s).strings as i64 != 0:
        with_free((*s).strings as *mut u8)
    // Free AST traversal arrays
    if (*s).cursors as i64 != 0: with_free((*s).cursors as *mut u8)
    if (*s).types as i64 != 0: with_free((*s).types as *mut u8)
    if (*s).child_starts as i64 != 0: with_free((*s).child_starts as *mut u8)
    if (*s).child_counts as i64 != 0: with_free((*s).child_counts as *mut u8)
    if (*s).child_indices as i64 != 0: with_free((*s).child_indices as *mut u8)
    // Cleanup temp file
    if (*s).tmp_path as i64 != 0:
        let _ = unlink((*s).tmp_path as *const u8)
        with_free((*s).tmp_path)
    if (*s).tu as i64 != 0: clang_disposeTranslationUnit((*s).tu)
    if (*s).index as i64 != 0: clang_disposeIndex((*s).index)
    if (*s).err_msg as i64 != 0: with_free((*s).err_msg)
    if (*s).decls as i64 != 0: with_free((*s).decls as *mut u8)
    with_free(s as *mut u8)

// ── Error ───────────────────────────────────────────────────

@[c_export("with_cimport_error")]
pub unsafe fn cimport_error(session: i64) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0: return ""
    if (*s).err_msg as i64 != 0:
        return make_str((*s).err_msg as *const u8)
    ""

// ── Declaration queries ─────────────────────────────────────

@[c_export("with_cimport_decl_count")]
pub unsafe fn cimport_decl_count(session: i64) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0: return 0
    (*s).decl_count

@[c_export("with_cimport_decl_kind")]
pub unsafe fn cimport_decl_kind(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return 0
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    clang_getCursorKind(cursor)

@[c_export("with_cimport_decl_name")]
pub unsafe fn cimport_decl_name(session: i64, idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return ""
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    clang_str_to_with(s, clang_getCursorSpelling(cursor))

@[c_export("with_cimport_decl_cursor")]
pub unsafe fn cimport_decl_cursor(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return -1
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    store_cursor(s, cursor)

// ── Function queries ────────────────────────────────────────

@[c_export("with_cimport_fn_return_type")]
pub unsafe fn cimport_fn_return_type(session: i64, idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return ""
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    let ret = clang_getResultType(ty)
    get_type_spelling(s, ret)

@[c_export("with_cimport_fn_param_count")]
pub unsafe fn cimport_fn_param_count(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return 0
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    clang_Cursor_getNumArguments(cursor)

@[c_export("with_cimport_fn_param_name")]
pub unsafe fn cimport_fn_param_name(session: i64, idx: i32, param: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return ""
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let arg = clang_Cursor_getArgument(cursor, param as u32)
    clang_str_to_with(s, clang_getCursorSpelling(arg))

@[c_export("with_cimport_fn_param_type")]
pub unsafe fn cimport_fn_param_type(session: i64, idx: i32, param: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return ""
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let arg = clang_Cursor_getArgument(cursor, param as u32)
    let ty = clang_getCursorType(arg)
    get_type_spelling(s, ty)

@[c_export("with_cimport_param_is_restrict")]
pub unsafe fn cimport_param_is_restrict(session: i64, idx: i32, param: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return 0
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let arg = clang_Cursor_getArgument(cursor, param as u32)
    let ty = clang_getCursorType(arg)
    clang_isRestrictQualifiedType(ty)

@[c_export("with_cimport_fn_is_variadic")]
pub unsafe fn cimport_fn_is_variadic(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return 0
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    clang_isFunctionTypeVariadic(ty)

@[c_export("with_cimport_fn_storage_class")]
pub unsafe fn cimport_fn_storage_class(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return 0
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    clang_Cursor_getStorageClass(cursor)

@[c_export("with_cimport_fn_is_inline")]
pub unsafe fn cimport_fn_is_inline(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return 0
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    clang_Cursor_isFunctionInlined(cursor)

@[c_export("with_cimport_fn_calling_conv")]
pub unsafe fn cimport_fn_calling_conv(session: i64, idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return ""
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    let cc = clang_getFunctionTypeCallingConv(ty)
    if cc == CXCallingConv_C: return "c"
    if cc == CXCallingConv_X86StdCall: return "stdcall"
    if cc == CXCallingConv_X86FastCall: return "fastcall"
    if cc == CXCallingConv_X86ThisCall: return "thiscall"
    if cc == CXCallingConv_AAPCS: return "aapcs"
    if cc == CXCallingConv_AAPCS_VFP: return "aapcs_vfp"
    if cc == CXCallingConv_Win64: return "win64"
    "c"

@[c_export("with_cimport_fn_is_noreturn")]
pub unsafe fn cimport_fn_is_noreturn(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return 0
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    // Check for __attribute__((noreturn)) via tokenization
    if clang_Cursor_hasAttrs(cursor) == 0: return 0
    let extent = clang_getCursorExtent(cursor)
    let tu = clang_Cursor_getTranslationUnit(cursor)
    var tokens: *mut CXToken = 0 as *mut CXToken
    var token_count: u32 = 0
    clang_tokenize(tu, extent, &raw mut tokens, &raw mut token_count)
    var found: i32 = 0
    var ti: u32 = 0
    while ti < token_count:
        let tok = *((tokens as i64 + ti as i64 * 24) as *const CXToken)  // sizeof(CXToken)=24
        let sp = clang_getTokenSpelling(tu, tok)
        let cstr = clang_getCString(sp)
        if c_strcmp(cstr, "noreturn\0" as *const u8) == 0 or c_strcmp(cstr, "_Noreturn\0" as *const u8) == 0 or c_strcmp(cstr, "__attribute__\0" as *const u8) == 0:
            found = 1
        clang_disposeString(sp)
        if found != 0: break
        ti = ti + 1
    if tokens as i64 != 0:
        clang_disposeTokens(tu, tokens, token_count)
    found

// ── Translated type functions ───────────────────────────────

@[c_export("with_cimport_fn_param_type_translated")]
pub unsafe fn cimport_fn_param_type_translated(session: i64, idx: i32, param: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return ""
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let arg = clang_Cursor_getArgument(cursor, param as u32)
    let ty = clang_getCursorType(arg)
    let result = translate_type_recursive(s, ty, 0, 0)
    if result as i64 == 0: return ""
    session_make_str(s, result as *const u8)

@[c_export("with_cimport_fn_return_type_translated")]
pub unsafe fn cimport_fn_return_type_translated(session: i64, idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return ""
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    let ret = clang_getResultType(ty)
    let result = translate_type_recursive(s, ret, 0, 0)
    if result as i64 == 0: return ""
    session_make_str(s, result as *const u8)

// ── Struct queries ──────────────────────────────────────────

@[c_export("with_cimport_struct_has_definition")]
pub unsafe fn cimport_struct_has_definition(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return 0
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let def = clang_getCursorDefinition(cursor)
    if def.kind == 0: return 0
    1

@[c_export("with_cimport_struct_field_count")]
pub unsafe fn cimport_struct_field_count(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0: return 0
    ensure_fields_cached(s, idx)
    if (*s).caches as i64 == 0: return 0
    let cache = ((*s).caches as i64 + idx as i64 * 48) as *const DeclCache
    (*cache).field_count

@[c_export("with_cimport_struct_field_name")]
pub unsafe fn cimport_struct_field_name(session: i64, idx: i32, field: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0: return ""
    ensure_fields_cached(s, idx)
    if (*s).caches as i64 == 0: return ""
    let cache = ((*s).caches as i64 + idx as i64 * 48) as *const DeclCache
    if field < 0 or field >= (*cache).field_count: return ""
    let fi = ((*cache).fields as i64 + field as i64 * 48) as *const FieldInfo
    make_str((*fi).name as *const u8)

@[c_export("with_cimport_struct_field_type")]
pub unsafe fn cimport_struct_field_type(session: i64, idx: i32, field: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0: return ""
    ensure_fields_cached(s, idx)
    if (*s).caches as i64 == 0: return ""
    let cache = ((*s).caches as i64 + idx as i64 * 48) as *const DeclCache
    if field < 0 or field >= (*cache).field_count: return ""
    let fi = ((*cache).fields as i64 + field as i64 * 48) as *const FieldInfo
    make_str((*fi).type_spelling as *const u8)

@[c_export("with_cimport_struct_field_is_bitfield")]
pub unsafe fn cimport_struct_field_is_bitfield(session: i64, idx: i32, field: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0: return 0
    ensure_fields_cached(s, idx)
    if (*s).caches as i64 == 0: return 0
    let cache = ((*s).caches as i64 + idx as i64 * 48) as *const DeclCache
    if field < 0 or field >= (*cache).field_count: return 0
    let fi = ((*cache).fields as i64 + field as i64 * 48) as *const FieldInfo
    (*fi).is_bitfield

@[c_export("with_cimport_struct_field_offset")]
pub unsafe fn cimport_struct_field_offset(session: i64, idx: i32, field: i32) -> i64:
    let s = session as *mut CImportSession
    if s as i64 == 0: return -1
    ensure_fields_cached(s, idx)
    if (*s).caches as i64 == 0: return -1
    let cache = ((*s).caches as i64 + idx as i64 * 48) as *const DeclCache
    if field < 0 or field >= (*cache).field_count: return -1
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    let fi = ((*cache).fields as i64 + field as i64 * 48) as *const FieldInfo
    let offset_bits = clang_Type_getOffsetOf(ty, (*fi).name as *const u8)
    if offset_bits < 0: return -1
    offset_bits / 8

@[c_export("with_cimport_record_field_offset_by_name")]
pub unsafe fn cimport_record_field_offset_by_name(session: i64, type_name: str, field_name: str) -> i64:
    let s = session as *mut CImportSession
    if s as i64 == 0: return -1
    let type_cstr = str_to_cstr(type_name)
    let field_cstr = str_to_cstr(field_name)
    if type_cstr as i64 == 0 or field_cstr as i64 == 0:
        if type_cstr as i64 != 0: with_free(type_cstr)
        if field_cstr as i64 != 0: with_free(field_cstr)
        return -1
    var i = 0
    while i < (*s).decl_count:
        let cursor = *(((*s).decls as i64 + i as i64 * 32) as *const CXCursor)
        if clang_Cursor_isNull(cursor) != 0:
            i = i + 1
            continue
        let kind = clang_getCursorKind(cursor)
        if kind != CXCursor_StructDecl and kind != CXCursor_UnionDecl and kind != CXCursor_TypedefDecl:
            i = i + 1
            continue
        let spelling = clang_getCursorSpelling(cursor)
        let spelling_cstr = clang_getCString(spelling)
        var matches = false
        if spelling_cstr as i64 != 0:
            if c_strcmp(spelling_cstr, type_cstr as *const u8) == 0:
                matches = true
        if matches:
            var ty = clang_getCursorType(cursor)
            if kind == CXCursor_TypedefDecl:
                ty = clang_getTypedefDeclUnderlyingType(cursor)
            let offset_bits = clang_Type_getOffsetOf(ty, field_cstr as *const u8)
            clang_disposeString(spelling)
            if offset_bits >= 0:
                with_free(type_cstr)
                with_free(field_cstr)
                return offset_bits / 8
        else:
            clang_disposeString(spelling)
        i = i + 1
    with_free(type_cstr)
    with_free(field_cstr)
    -1

@[c_export("with_cimport_struct_size")]
pub unsafe fn cimport_struct_size(session: i64, idx: i32) -> i64:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return -1
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    clang_Type_getSizeOf(ty)

@[c_export("with_cimport_struct_field_size")]
pub unsafe fn cimport_struct_field_size(session: i64, idx: i32, field: i32) -> i64:
    let s = session as *mut CImportSession
    if s as i64 == 0: return -1
    ensure_fields_cached(s, idx)
    if (*s).caches as i64 == 0: return -1
    let cache = ((*s).caches as i64 + idx as i64 * 48) as *const DeclCache
    if field < 0 or field >= (*cache).field_count: return -1
    let fi = ((*cache).fields as i64 + field as i64 * 48) as *const FieldInfo
    clang_Type_getSizeOf((*fi).clang_type)

@[c_export("with_cimport_struct_is_opaque")]
pub unsafe fn cimport_struct_is_opaque(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return 1
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    if clang_isCursorDefinition(cursor) != 0: return 0
    1

@[c_export("with_cimport_struct_is_packed")]
pub unsafe fn cimport_struct_is_packed(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return 0
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    let align = clang_Type_getAlignOf(ty)
    if align == 1: return 1
    0

@[c_export("with_cimport_struct_align")]
pub unsafe fn cimport_struct_align(session: i64, idx: i32) -> i64:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return -1
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    clang_Type_getAlignOf(ty)

@[c_export("with_cimport_struct_field_type_translated")]
pub unsafe fn cimport_struct_field_type_translated(session: i64, idx: i32, field: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0: return ""
    ensure_fields_cached(s, idx)
    if (*s).caches as i64 == 0: return ""
    let cache = ((*s).caches as i64 + idx as i64 * 48) as *const DeclCache
    if field < 0 or field >= (*cache).field_count: return ""
    let fi = ((*cache).fields as i64 + field as i64 * 48) as *const FieldInfo
    let is_last = if field == (*cache).field_count - 1: 1 else: 0
    let result = translate_type_recursive(s, (*fi).clang_type, 0, is_last)
    if result as i64 == 0: return ""
    session_make_str(s, result as *const u8)

@[c_export("with_cimport_struct_field_align")]
pub unsafe fn cimport_struct_field_align(session: i64, idx: i32, field: i32) -> i64:
    let s = session as *mut CImportSession
    if s as i64 == 0: return -1
    ensure_fields_cached(s, idx)
    if (*s).caches as i64 == 0: return -1
    let cache = ((*s).caches as i64 + idx as i64 * 48) as *const DeclCache
    if field < 0 or field >= (*cache).field_count: return -1
    let fi = ((*cache).fields as i64 + field as i64 * 48) as *const FieldInfo
    clang_Type_getAlignOf((*fi).clang_type)

// ── Enum queries ────────────────────────────────────────────

@[c_export("with_cimport_enum_const_count")]
pub unsafe fn cimport_enum_const_count(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0: return 0
    ensure_enum_consts_cached(s, idx)
    if (*s).caches as i64 == 0: return 0
    let cache = ((*s).caches as i64 + idx as i64 * 48) as *const DeclCache
    (*cache).enum_const_count

@[c_export("with_cimport_enum_const_name")]
pub unsafe fn cimport_enum_const_name(session: i64, idx: i32, ci: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0: return ""
    ensure_enum_consts_cached(s, idx)
    if (*s).caches as i64 == 0: return ""
    let cache = ((*s).caches as i64 + idx as i64 * 48) as *const DeclCache
    if ci < 0 or ci >= (*cache).enum_const_count: return ""
    let eci = ((*cache).enum_consts as i64 + ci as i64 * 16) as *const EnumConstInfo
    make_str((*eci).name as *const u8)

@[c_export("with_cimport_enum_const_value")]
pub unsafe fn cimport_enum_const_value(session: i64, idx: i32, ci: i32) -> i64:
    let s = session as *mut CImportSession
    if s as i64 == 0: return 0
    ensure_enum_consts_cached(s, idx)
    if (*s).caches as i64 == 0: return 0
    let cache = ((*s).caches as i64 + idx as i64 * 48) as *const DeclCache
    if ci < 0 or ci >= (*cache).enum_const_count: return 0
    let eci = ((*cache).enum_consts as i64 + ci as i64 * 16) as *const EnumConstInfo
    (*eci).value

@[c_export("with_cimport_enum_int_type")]
pub unsafe fn cimport_enum_int_type(session: i64, idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return ""
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getEnumDeclIntegerType(cursor)
    get_type_spelling(s, ty)

// ── Variable queries ────────────────────────────────────────

@[c_export("with_cimport_var_type")]
pub unsafe fn cimport_var_type(session: i64, idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return ""
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    get_type_spelling(s, ty)

@[c_export("with_cimport_var_is_const")]
pub unsafe fn cimport_var_is_const(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return 0
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    cimport_type_is_const_storage(ty)

@[c_export("with_cimport_var_storage_class")]
pub unsafe fn cimport_var_storage_class(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return 0
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    clang_Cursor_getStorageClass(cursor)

unsafe fn cimport_var_decl_has_initializer_text(s: str) -> i32:
    let slen = s.len() as i32
    var paren_depth = 0
    var bracket_depth = 0
    var brace_depth = 0
    var i = 0
    while i < slen:
        let c = s.byte_at(i as i64)
        if c == 47 and i + 1 < slen:
            let next = s.byte_at((i + 1) as i64)
            if next == 47:
                i = i + 2
                while i < slen and s.byte_at(i as i64) != 10:
                    i = i + 1
                continue
            if next == 42:
                i = i + 2
                while i + 1 < slen:
                    if s.byte_at(i as i64) == 42 and s.byte_at((i + 1) as i64) == 47:
                        i = i + 2
                        break
                    i = i + 1
                continue
        if c == 34 or c == 39:
            let quote = c
            i = i + 1
            while i < slen:
                let inner = s.byte_at(i as i64)
                if inner == 92:
                    i = i + 2
                    continue
                if inner == quote:
                    break
                i = i + 1
            i = i + 1
            continue
        if c == 40: paren_depth = paren_depth + 1
        if c == 41 and paren_depth > 0: paren_depth = paren_depth - 1
        if c == 91: bracket_depth = bracket_depth + 1
        if c == 93 and bracket_depth > 0: bracket_depth = bracket_depth - 1
        if c == 123: brace_depth = brace_depth + 1
        if c == 125 and brace_depth > 0: brace_depth = brace_depth - 1
        if c == 61 and paren_depth == 0 and bracket_depth == 0 and brace_depth == 0:
            let prev = if i > 0: s.byte_at((i - 1) as i64) else: 0
            let next = if i + 1 < slen: s.byte_at((i + 1) as i64) else: 0
            if prev != 61 and prev != 33 and prev != 60 and prev != 62 and next != 61:
                return 1
        i = i + 1
    0

@[c_export("with_cimport_var_definition_kind")]
pub unsafe fn cimport_var_definition_kind(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return 0
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    if cimport_var_decl_has_initializer_text(cursor_source_text_from_cursor(s, cursor)) != 0:
        return 2
    if clang_Cursor_getStorageClass(cursor) == CX_SC_EXTERN:
        return 0
    1

@[c_export("with_cimport_var_type_translated")]
pub unsafe fn cimport_var_type_translated(session: i64, idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return ""
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    let result = translate_type_recursive(s, ty, 0, 0)
    if result as i64 == 0: return ""
    session_make_str(s, result as *const u8)

@[c_export("with_cimport_var_storage_type_translated")]
pub unsafe fn cimport_var_storage_type_translated(session: i64, idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return ""
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    let result = translate_storage_type_recursive(s, ty, 0, 0)
    if result as i64 == 0: return ""
    session_make_str(s, result as *const u8)

@[c_export("with_ci_cursor_in_file")]
pub unsafe fn ci_cursor_in_file(session: i64, cursor_idx: i32, path: str) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count or path.len() == 0:
        return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let loc = clang_getCursorLocation(cursor)
    var presumed_bits: [2]i64 = [0 as i64; 2]
    var presumed_line: u32 = 0
    var presumed_col: u32 = 0
    clang_getPresumedLocation(loc, &raw mut presumed_bits as *mut [2]i64 as *mut CXString, &raw mut presumed_line, &raw mut presumed_col)
    let presumed_file = *(&raw mut presumed_bits as *mut [2]i64 as *mut CXString)
    let presumed_name = clang_getCString(presumed_file)
    let c_path = cimport_path_to_cstr(path)
    if c_path as i64 == 0:
        clang_disposeString(presumed_file)
        return 0
    if presumed_name as i64 != 0 and *presumed_name != 0:
        let actual_buf = with_alloc(4096)
        let target_buf = with_alloc(4096)
        var presumed_matches = 0
        if actual_buf as i64 != 0 and target_buf as i64 != 0:
            let actual_real = realpath(presumed_name, actual_buf)
            let target_real = realpath(c_path as *const u8, target_buf)
            if actual_real as i64 != 0 and target_real as i64 != 0:
                presumed_matches = if c_strcmp(actual_real as *const u8, target_real as *const u8) == 0: 1 else: 0
            else:
                presumed_matches = if c_strcmp(presumed_name, c_path as *const u8) == 0: 1 else: 0
        if actual_buf as i64 != 0:
            with_free(actual_buf)
        if target_buf as i64 != 0:
            with_free(target_buf)
        with_free(c_path)
        clang_disposeString(presumed_file)
        if presumed_matches != 0:
            return 1
        return 0
    var file: *mut u8 = 0 as *mut u8
    clang_getFileLocation(loc, &raw mut file, 0 as *mut u32, 0 as *mut u32, 0 as *mut u32)
    if file as i64 == 0:
        with_free(c_path)
        clang_disposeString(presumed_file)
        return 0
    let target = clang_getFile((*s).tu, c_path as *const u8)
    if target as i64 != 0 and clang_File_isEqual(file, target) != 0:
        with_free(c_path)
        clang_disposeString(presumed_file)
        return 1
    let fname = clang_getFileName(file)
    let fname_str = clang_getCString(fname)
    let actual_buf = with_alloc(4096)
    let target_buf = with_alloc(4096)
    var matches = 0
    if fname_str as i64 != 0 and actual_buf as i64 != 0 and target_buf as i64 != 0:
        let actual_real = realpath(fname_str, actual_buf)
        let target_real = realpath(c_path as *const u8, target_buf)
        if actual_real as i64 != 0 and target_real as i64 != 0:
            matches = if c_strcmp(actual_real as *const u8, target_real as *const u8) == 0: 1 else: 0
        else:
            matches = if c_strcmp(fname_str, c_path as *const u8) == 0: 1 else: 0
    clang_disposeString(fname)
    if actual_buf as i64 != 0:
        with_free(actual_buf)
    if target_buf as i64 != 0:
        with_free(target_buf)
    with_free(c_path)
    clang_disposeString(presumed_file)
    matches

// ── Typedef queries ─────────────────────────────────────────

@[c_export("with_cimport_typedef_underlying")]
pub unsafe fn cimport_typedef_underlying(session: i64, idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return ""
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getTypedefDeclUnderlyingType(cursor)
    get_type_spelling(s, ty)

@[c_export("with_cimport_typedef_underlying_translated")]
pub unsafe fn cimport_typedef_underlying_translated(session: i64, idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return ""
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getTypedefDeclUnderlyingType(cursor)
    let result = translate_type_recursive(s, ty, 0, 0)
    if result as i64 == 0: return ""
    session_make_str(s, result as *const u8)

// ── Hex float conversion ────────────────────────────────────

@[c_export("with_cimport_hex_float_to_decimal")]
pub unsafe fn cimport_hex_float_to_decimal(hex_str: str) -> str:
    let cstr = str_to_cstr(hex_str)
    if cstr as i64 == 0: return ""
    var endptr: *mut u8 = 0 as *mut u8
    let val = strtod(cstr as *const u8, &raw mut endptr)
    with_free(cstr)
    // Format as decimal — simple approach: use a fixed buffer
    var buf: [64]u8 = [0 as u8; 64]
    var pos: i64 = 0
    // Convert to integer part + fraction
    let int_part = val as i64
    buf_append_i64(&raw mut buf as *mut [64]u8 as *mut u8, &raw mut pos, 64, int_part)
    buf_append_str(&raw mut buf as *mut [64]u8 as *mut u8, &raw mut pos, 64, ".0\0" as *const u8)
    make_str(&buf as *const [64]u8 as *const u8)

// ── Path utilities ──────────────────────────────────────────

@[c_export("with_cimport_realpath")]
pub unsafe fn cimport_realpath(path: str) -> str:
    let cpath = str_to_cstr(path)
    if cpath as i64 == 0: return ""
    var buf: [1024]u8 = [0 as u8; 1024]
    let r = realpath(cpath, &raw mut buf as *mut [1024]u8 as *mut u8)
    with_free(cpath)
    if r as i64 == 0: return ""
    make_str(r)

// ── Macro extraction ────────────────────────────────────────

@[c_export("with_cimport_parse_macros")]
pub unsafe fn cimport_parse_macros(header_code: str) -> i64:
    let ms_size = 56  // sizeof(MacroSession)
    let ms = with_alloc(ms_size) as *mut MacroSession
    if ms as i64 == 0: return 0
    with_memset(ms as *mut u8, 0, ms_size)

    // Write header to temp file
    var template_path: [40]u8 = [0 as u8; 40]
    let tmpl = "/tmp/with_cimport_macro_XXXXXX\0"
    let tp = *(&tmpl as *const *const u8)
    with_memcpy(&raw mut template_path as *mut [40]u8 as *mut u8, tp, 31)
    let fd = mkstemp(&raw mut template_path as *mut [40]u8 as *mut u8)
    if fd < 0: return ms as i64
    let src_ptr = *(&header_code as *const *const u8)
    let _ = write(fd, src_ptr, header_code.len() as u64)
    let _ = write(fd, "\n\0" as *const u8, 1 as u64)
    let _ = close(fd)

    var c_path: [64]u8 = [0 as u8; 64]
    with_memcpy(&raw mut c_path as *mut [64]u8 as *mut u8, &template_path as *const [40]u8 as *const u8, 40)
    let tlen = c_strlen(&template_path as *const [40]u8 as *const u8)
    *(((&raw mut c_path) as i64 + tlen) as *mut u8) = 46
    *(((&raw mut c_path) as i64 + tlen + 1) as *mut u8) = 99
    *(((&raw mut c_path) as i64 + tlen + 2) as *mut u8) = 0
    let _ = rename(&template_path as *const [40]u8 as *const u8, &c_path as *const [64]u8 as *const u8)

    // Build command: cc [-isysroot ...] [-I ...]* -E -dM file.c
    var cmd: [1024]u8 = [0 as u8; 1024]
    var cpos: i64 = 0
    let sysroot = get_sdk_path()
    if sysroot as i64 != 0:
        buf_append_str(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, "cc -isysroot '\0" as *const u8)
        buf_append_shell_escaped(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, sysroot)
        buf_append_str(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, "'\0" as *const u8)
    else:
        buf_append_str(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, "cc\0" as *const u8)
    var ip: i32 = 0
    while ip < g_cimport_include_count:
        buf_append_str(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, " -I '\0" as *const u8)
        buf_append_shell_escaped(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, g_cimport_include_paths[ip as i64] as *const u8)
        buf_append_str(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, "'\0" as *const u8)
        ip = ip + 1
    buf_append_str(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, " -E -dM '\0" as *const u8)
    buf_append_str(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, &c_path as *const [64]u8 as *const u8)
    buf_append_str(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, "'\0" as *const u8)

    let p = popen(&cmd as *const [1024]u8 as *const u8, "r\0" as *const u8)
    if p as i64 == 0:
        let _ = unlink(&c_path as *const [64]u8 as *const u8)
        return ms as i64

    var line: [4096]u8 = [0 as u8; 4096]
    while true:
        let line_ptr = fgets(&raw mut line as *mut [4096]u8 as *mut u8, 4096, p)
        if line_ptr as i64 == 0:
            break
        if c_strncmp(line_ptr as *const u8, "#define \0" as *const u8, 8) != 0:
            continue
        let name_start = (line_ptr as i64 + 8) as *const u8
        // Skip builtins
        if *name_start == 95 and *((name_start as i64 + 1) as *const u8) == 95:
            continue
        // Find end of name
        var name_end = name_start
        while *(name_end) != 0 and *(name_end) != 32 and *(name_end) != 40 and *(name_end) != 10:
            name_end = (name_end as i64 + 1) as *const u8
        let is_fn_like = if *(name_end) == 40: 1 else: 0
        let name_len = name_end as i64 - name_start as i64
        let name = with_alloc(name_len + 1)
        with_memcpy(name, name_start, name_len)
        *((name as i64 + name_len) as *mut u8) = 0

        // Skip past params for function-like macros
        var value_start = name_end
        var macro_params: *mut *mut u8 = 0 as *mut *mut u8
        var macro_param_count: i32 = 0
        if is_fn_like != 0:
            let pstart = (name_end as i64 + 1) as *const u8  // skip '('
            var pend = pstart
            while *(pend) != 0 and *(pend) != 41:  // ')'
                pend = (pend as i64 + 1) as *const u8
            // Parse comma-separated params
            if pend as i64 > pstart as i64:
                var pcap: i32 = 8
                macro_params = with_alloc(pcap as i64 * 8) as *mut *mut u8
                var pp = pstart
                while pp as i64 < pend as i64:
                    while pp as i64 < pend as i64 and *(pp) == 32: pp = (pp as i64 + 1) as *const u8
                    let tok = pp
                    while pp as i64 < pend as i64 and *(pp) != 44 and *(pp) != 32: pp = (pp as i64 + 1) as *const u8
                    if pp as i64 > tok as i64:
                        if macro_param_count >= pcap:
                            pcap = pcap * 2
                            let new_p = with_alloc(pcap as i64 * 8)
                            with_memcpy(new_p, macro_params as *const u8, macro_param_count as i64 * 8)
                            with_free(macro_params as *mut u8)
                            macro_params = new_p as *mut *mut u8
                        let tlen2 = pp as i64 - tok as i64
                        let pname = with_alloc(tlen2 + 1)
                        with_memcpy(pname, tok, tlen2)
                        *((pname as i64 + tlen2) as *mut u8) = 0
                        *((macro_params as i64 + macro_param_count as i64 * 8) as *mut *mut u8) = pname
                        macro_param_count = macro_param_count + 1
                    while pp as i64 < pend as i64 and (*(pp) == 44 or *(pp) == 32): pp = (pp as i64 + 1) as *const u8
            value_start = pend
            if *(value_start) == 41: value_start = (value_start as i64 + 1) as *const u8
        while *(value_start) == 32: value_start = (value_start as i64 + 1) as *const u8

        // Strip trailing newline
        var value_len = c_strlen(value_start)
        while value_len > 0 and (*((value_start as i64 + value_len - 1) as *const u8) == 10 or *((value_start as i64 + value_len - 1) as *const u8) == 13):
            value_len = value_len - 1
        let value = with_alloc(value_len + 1)
        if value_len > 0: with_memcpy(value, value_start, value_len)
        *((value as i64 + value_len) as *mut u8) = 0

        // Grow arrays
        if (*ms).count >= (*ms).cap:
            (*ms).cap = if (*ms).cap > 0: (*ms).cap * 2 else: 64
            let nc = (*ms).cap as i64
            let nn = with_alloc(nc * 8)
            let nv = with_alloc(nc * 8)
            let nf = with_alloc(nc * 4)
            let np = with_alloc(nc * 8)
            let npc = with_alloc(nc * 4)
            if (*ms).count > 0:
                let oc = (*ms).count as i64
                if (*ms).names as i64 != 0: with_memcpy(nn, (*ms).names as *const u8, oc * 8)
                if (*ms).values as i64 != 0: with_memcpy(nv, (*ms).values as *const u8, oc * 8)
                if (*ms).fn_like as i64 != 0: with_memcpy(nf, (*ms).fn_like as *const u8, oc * 4)
                if (*ms).params as i64 != 0: with_memcpy(np, (*ms).params as *const u8, oc * 8)
                if (*ms).param_counts as i64 != 0: with_memcpy(npc, (*ms).param_counts as *const u8, oc * 4)
            if (*ms).names as i64 != 0: with_free((*ms).names as *mut u8)
            if (*ms).values as i64 != 0: with_free((*ms).values as *mut u8)
            if (*ms).fn_like as i64 != 0: with_free((*ms).fn_like as *mut u8)
            if (*ms).params as i64 != 0: with_free((*ms).params as *mut u8)
            if (*ms).param_counts as i64 != 0: with_free((*ms).param_counts as *mut u8)
            (*ms).names = nn as *mut *mut u8
            (*ms).values = nv as *mut *mut u8
            (*ms).fn_like = nf as *mut i32
            (*ms).params = np as *mut *mut *mut u8
            (*ms).param_counts = npc as *mut i32

        let ci = (*ms).count as i64
        *(((*ms).names as i64 + ci * 8) as *mut *mut u8) = name
        *(((*ms).values as i64 + ci * 8) as *mut *mut u8) = value
        *(((*ms).fn_like as i64 + ci * 4) as *mut i32) = is_fn_like
        *(((*ms).params as i64 + ci * 8) as *mut *mut *mut u8) = macro_params
        *(((*ms).param_counts as i64 + ci * 4) as *mut i32) = macro_param_count
        (*ms).count = (*ms).count + 1

    let _ = pclose(p)
    let _ = unlink(&c_path as *const [64]u8 as *const u8)
    ms as i64

@[c_export("with_cimport_preprocess_text")]
pub unsafe fn cimport_preprocess_text(source_code: str) -> str:
    var template_path: [40]u8 = [0 as u8; 40]
    let tmpl = "/tmp/with_cimport_pp_XXXXXX\0"
    let tp = *(&tmpl as *const *const u8)
    with_memcpy(&raw mut template_path as *mut [40]u8 as *mut u8, tp, 28)
    let fd = mkstemp(&raw mut template_path as *mut [40]u8 as *mut u8)
    if fd < 0:
        return ""

    let src_ptr = *(&source_code as *const *const u8)
    let _ = write(fd, src_ptr, source_code.len() as u64)
    let _ = write(fd, "\n\0" as *const u8, 1 as u64)
    let _ = close(fd)

    var c_path: [64]u8 = [0 as u8; 64]
    with_memcpy(&raw mut c_path as *mut [64]u8 as *mut u8, &template_path as *const [40]u8 as *const u8, 40)
    let tlen = c_strlen(&template_path as *const [40]u8 as *const u8)
    *(((&raw mut c_path) as i64 + tlen) as *mut u8) = 46
    *(((&raw mut c_path) as i64 + tlen + 1) as *mut u8) = 99
    *(((&raw mut c_path) as i64 + tlen + 2) as *mut u8) = 0
    let _ = rename(&template_path as *const [40]u8 as *const u8, &c_path as *const [64]u8 as *const u8)

    var cmd: [1024]u8 = [0 as u8; 1024]
    var cpos: i64 = 0
    let sysroot = get_sdk_path()
    if sysroot as i64 != 0:
        buf_append_str(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, "cc -isysroot '\0" as *const u8)
        buf_append_shell_escaped(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, sysroot)
        buf_append_str(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, "'\0" as *const u8)
    else:
        buf_append_str(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, "cc\0" as *const u8)
    var ip: i32 = 0
    while ip < g_cimport_include_count:
        buf_append_str(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, " -I '\0" as *const u8)
        buf_append_shell_escaped(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, g_cimport_include_paths[ip as i64] as *const u8)
        buf_append_str(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, "'\0" as *const u8)
        ip = ip + 1
    buf_append_str(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, " -E '\0" as *const u8)
    buf_append_str(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, &c_path as *const [64]u8 as *const u8)
    buf_append_str(&raw mut cmd as *mut [1024]u8 as *mut u8, &raw mut cpos, 1024, "' 2>/dev/null\0" as *const u8)

    let p = popen(&cmd as *const [1024]u8 as *const u8, "r\0" as *const u8)
    if p as i64 == 0:
        let _ = unlink(&c_path as *const [64]u8 as *const u8)
        return ""

    var output: *mut u8 = 0 as *mut u8
    var out_len: i64 = 0
    var out_cap: i64 = 0
    var line: [4096]u8 = [0 as u8; 4096]
    while true:
        let line_ptr = fgets(&raw mut line as *mut [4096]u8 as *mut u8, 4096, p)
        if line_ptr as i64 == 0:
            break
        let line_len = c_strlen(line_ptr as *const u8)
        if out_len + line_len + 1 > out_cap:
            var new_cap = if out_cap > 0: out_cap * 2 else: 8192
            while new_cap < out_len + line_len + 1:
                new_cap = new_cap * 2
            let new_buf = with_alloc(new_cap)
            if new_buf as i64 == 0:
                if output as i64 != 0:
                    with_free(output)
                let _ = pclose(p)
                let _ = unlink(&c_path as *const [64]u8 as *const u8)
                return ""
            if output as i64 != 0 and out_len > 0:
                with_memcpy(new_buf, output as *const u8, out_len)
                with_free(output)
            output = new_buf
            out_cap = new_cap
        with_memcpy((output as i64 + out_len) as *mut u8, line_ptr as *const u8, line_len)
        out_len = out_len + line_len
    let _ = pclose(p)
    let _ = unlink(&c_path as *const [64]u8 as *const u8)

    if output as i64 == 0 or out_len == 0:
        if output as i64 != 0:
            with_free(output)
        return ""
    *((output as i64 + out_len) as *mut u8) = 0
    let result = make_str(output as *const u8)
    with_free(output)
    result

@[c_export("with_cimport_collect_object_macro_types")]
pub unsafe fn cimport_collect_object_macro_types(header_code: str, macro_names: str) -> str:
    if macro_names.len() == 0:
        return ""

    let size = 232  // sizeof(CImportSession)
    let s = with_alloc(size) as *mut CImportSession
    if s as i64 == 0:
        return ""
    with_memset(s as *mut u8, 0, size)

    var template_path: [32]u8 = [0 as u8; 32]
    let tmpl = "/tmp/with_cimport_XXXXXX\0"
    let tp = *(&tmpl as *const *const u8)
    with_memcpy(&raw mut template_path as *mut [32]u8 as *mut u8, tp, 25)
    let fd = mkstemp(&raw mut template_path as *mut [32]u8 as *mut u8)
    if fd < 0:
        cimport_dispose(s as i64)
        return ""

    let src_ptr = *(&header_code as *const *const u8)
    let _ = write(fd, src_ptr, header_code.len() as u64)
    let _ = write(fd, "\n\0" as *const u8, 1 as u64)

    var pos: i32 = 0
    while pos < macro_names.len() as i32:
        while pos < macro_names.len() as i32 and macro_names.byte_at(pos as i64) == 124:
            pos = pos + 1
        let start = pos
        while pos < macro_names.len() as i32 and macro_names.byte_at(pos as i64) != 124:
            pos = pos + 1
        if pos > start:
            let name = macro_names.slice(start as i64, pos as i64)
            let probe_line = "__typeof__(" ++ name ++ ") __with_macro_probe_" ++ name ++ ";\n"
            let probe_ptr = *(&probe_line as *const *const u8)
            let _ = write(fd, probe_ptr, probe_line.len() as u64)
    let _ = close(fd)

    var c_path_buf: [64]u8 = [0 as u8; 64]
    with_memcpy(&raw mut c_path_buf as *mut [64]u8 as *mut u8, &template_path as *const [32]u8 as *const u8, 32)
    let tlen = c_strlen(&template_path as *const [32]u8 as *const u8)
    *(((&raw mut c_path_buf) as i64 + tlen) as *mut u8) = 46
    *(((&raw mut c_path_buf) as i64 + tlen + 1) as *mut u8) = 99
    *(((&raw mut c_path_buf) as i64 + tlen + 2) as *mut u8) = 0
    let _ = rename(&template_path as *const [32]u8 as *const u8, &c_path_buf as *const [64]u8 as *const u8)
    (*s).tmp_path = c_strdup(&c_path_buf as *const [64]u8 as *const u8)

    var args: [64]*const u8 = [0 as *const u8; 64]
    var nargs: i32 = 0
    let sysroot = get_sdk_path()
    if sysroot as i64 != 0:
        args[nargs as i64] = "-isysroot\0" as *const u8
        nargs = nargs + 1
        args[nargs as i64] = sysroot
        nargs = nargs + 1
    let resdir = get_clang_resource_dir()
    if resdir as i64 != 0:
        args[nargs as i64] = "-resource-dir\0" as *const u8
        nargs = nargs + 1
        args[nargs as i64] = resdir
        nargs = nargs + 1
    var ip: i32 = 0
    while ip < g_cimport_include_count and nargs < 62:
        args[nargs as i64] = "-I\0" as *const u8
        nargs = nargs + 1
        args[nargs as i64] = g_cimport_include_paths[ip as i64] as *const u8
        nargs = nargs + 1
        ip = ip + 1

    (*s).index = clang_createIndex(0, 0)
    (*s).tu = clang_parseTranslationUnit((*s).index, (*s).tmp_path as *const u8, &args as *const [64]*const u8 as *const *const u8, nargs, 0 as *mut u8, 0 as u32, 0 as u32)
    if (*s).tu as i64 == 0:
        cimport_dispose(s as i64)
        return ""

    (*s).header_file = clang_getFile((*s).tu, (*s).tmp_path as *const u8)
    let root = clang_getTranslationUnitCursor((*s).tu)
    let _ = clang_visitChildren(root, collect_decl as *const u8, s as *mut u8)

    let prefix = "__with_macro_probe_"
    var result = ""
    var i: i32 = 0
    while i < (*s).decl_count:
        let cursor = *(((*s).decls as i64 + i as i64 * 32) as *const CXCursor)
        if clang_getCursorKind(cursor) == CXCursor_VarDecl:
            let spelling = clang_str_to_with(s, clang_getCursorSpelling(cursor))
            if spelling.len() > prefix.len() and spelling.slice(0, prefix.len()) == prefix:
                let macro_name = spelling.slice(prefix.len(), spelling.len())
                let translated = translate_type_recursive(s, clang_getCursorType(cursor), 0, 0)
                if translated as i64 != 0 and c_strncmp(translated as *const u8, "__UNSUPPORTED:\0" as *const u8, 14) != 0:
                    let macro_ty = session_make_str(s, translated as *const u8)
                    if macro_ty.len() > 0:
                        result = result ++ "|" ++ macro_name ++ "=" ++ macro_ty ++ "|"
        i = i + 1

    cimport_dispose(s as i64)
    result

@[c_export("with_cimport_macro_count")]
pub unsafe fn cimport_macro_count(session: i64) -> i32:
    let ms = session as *mut MacroSession
    if ms as i64 == 0: return 0
    (*ms).count

@[c_export("with_cimport_macro_name")]
pub unsafe fn cimport_macro_name(session: i64, idx: i32) -> str:
    let ms = session as *mut MacroSession
    if ms as i64 == 0 or idx < 0 or idx >= (*ms).count: return ""
    make_str(*(((*ms).names as i64 + idx as i64 * 8) as *const *const u8))

@[c_export("with_cimport_macro_value")]
pub unsafe fn cimport_macro_value(session: i64, idx: i32) -> str:
    let ms = session as *mut MacroSession
    if ms as i64 == 0 or idx < 0 or idx >= (*ms).count: return ""
    make_str(*(((*ms).values as i64 + idx as i64 * 8) as *const *const u8))

@[c_export("with_cimport_macro_is_fn_like")]
pub unsafe fn cimport_macro_is_fn_like(session: i64, idx: i32) -> i32:
    let ms = session as *mut MacroSession
    if ms as i64 == 0 or idx < 0 or idx >= (*ms).count: return 0
    *(((*ms).fn_like as i64 + idx as i64 * 4) as *const i32)

@[c_export("with_cimport_dispose_macros")]
pub unsafe fn cimport_dispose_macros(session: i64):
    let ms = session as *mut MacroSession
    if ms as i64 == 0: return
    var i: i32 = 0
    while i < (*ms).count:
        let ci = i as i64
        with_free(*(((*ms).names as i64 + ci * 8) as *const *mut u8))
        with_free(*(((*ms).values as i64 + ci * 8) as *const *mut u8))
        let params = *(((*ms).params as i64 + ci * 8) as *const *mut *mut u8)
        if params as i64 != 0:
            let pc = *(((*ms).param_counts as i64 + ci * 4) as *const i32)
            var j: i32 = 0
            while j < pc:
                with_free(*((params as i64 + j as i64 * 8) as *const *mut u8))
                j = j + 1
            with_free(params as *mut u8)
        i = i + 1
    if (*ms).names as i64 != 0: with_free((*ms).names as *mut u8)
    if (*ms).values as i64 != 0: with_free((*ms).values as *mut u8)
    if (*ms).fn_like as i64 != 0: with_free((*ms).fn_like as *mut u8)
    if (*ms).params as i64 != 0: with_free((*ms).params as *mut u8)
    if (*ms).param_counts as i64 != 0: with_free((*ms).param_counts as *mut u8)
    with_free(ms as *mut u8)

@[c_export("with_cimport_macro_param_count")]
pub unsafe fn cimport_macro_param_count(session: i64, idx: i32) -> i32:
    let ms = session as *mut MacroSession
    if ms as i64 == 0 or idx < 0 or idx >= (*ms).count: return 0
    *(((*ms).param_counts as i64 + idx as i64 * 4) as *const i32)

@[c_export("with_cimport_macro_param_name")]
pub unsafe fn cimport_macro_param_name(session: i64, idx: i32, param: i32) -> str:
    let ms = session as *mut MacroSession
    if ms as i64 == 0 or idx < 0 or idx >= (*ms).count: return ""
    let pc = *(((*ms).param_counts as i64 + idx as i64 * 4) as *const i32)
    if param < 0 or param >= pc: return ""
    let params = *(((*ms).params as i64 + idx as i64 * 8) as *const *mut *const u8)
    if params as i64 == 0: return ""
    make_str(*((params as i64 + param as i64 * 8) as *const *const u8))

// ── Variable extras ─────────────────────────────────────────

@[c_export("with_cimport_var_alignment")]
pub unsafe fn cimport_var_alignment(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return 0
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    let align = clang_Type_getAlignOf(ty)
    if align <= 0: return 0
    align as i32

@[c_export("with_cimport_var_is_threadlocal")]
pub unsafe fn cimport_var_is_threadlocal(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return 0
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    clang_getCursorTLSKind(cursor)

// ── Anonymous struct/union in struct fields ──────────────────

@[c_export("with_cimport_struct_field_is_anonymous_record")]
pub unsafe fn cimport_struct_field_is_anonymous_record(session: i64, idx: i32, field: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0: return 0
    ensure_fields_cached(s, idx)
    if (*s).caches as i64 == 0: return 0
    let cache = ((*s).caches as i64 + idx as i64 * 48) as *const DeclCache
    if field < 0 or field >= (*cache).field_count: return 0
    let fi = ((*cache).fields as i64 + field as i64 * 48) as *const FieldInfo
    let canonical = clang_getCanonicalType((*fi).clang_type)
    if canonical.kind != CXType_Record: return 0
    let decl = clang_getTypeDeclaration(canonical)
    if clang_Cursor_isAnonymous(decl) != 0:
        if decl.kind == CXCursor_UnionDecl: return 2
        return 1
    0

// ── Typedef anonymous record ────────────────────────────────

@[c_export("with_cimport_typedef_anon_record_field_count")]
pub unsafe fn cimport_typedef_anon_record_field_count(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return -1
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getTypedefDeclUnderlyingType(cursor)
    let canonical = clang_getCanonicalType(ty)
    if canonical.kind != CXType_Record: return -1
    let decl = clang_getTypeDeclaration(canonical)
    if clang_Cursor_isAnonymous(decl) == 0: return -1
    // Count fields by ensuring cache for the declaration
    // For now, return field count via type size / field enumeration approach
    // This is a simplified version - the full C version traverses children
    -1  // TODO: implement full anonymous record field enumeration

@[c_export("with_cimport_typedef_anon_is_union")]
pub unsafe fn cimport_typedef_anon_is_union(session: i64, idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or idx < 0 or idx >= (*s).decl_count: return 0
    let cursor = *(((*s).decls as i64 + idx as i64 * 32) as *const CXCursor)
    let ty = clang_getTypedefDeclUnderlyingType(cursor)
    let canonical = clang_getCanonicalType(ty)
    if canonical.kind != CXType_Record: return 0
    let decl = clang_getTypeDeclaration(canonical)
    if decl.kind == CXCursor_UnionDecl: return 1
    0

// ── Phase 1: AST traversal ─────────────────────────────────

unsafe fn store_cursor(s: *mut CImportSession, cursor: CXCursor) -> i32:
    if (*s).cursor_count >= (*s).cursor_cap:
        (*s).cursor_cap = if (*s).cursor_cap > 0: (*s).cursor_cap * 2 else: 256
        let new_buf = with_alloc((*s).cursor_cap as i64 * 32)
        if (*s).cursors as i64 != 0 and (*s).cursor_count > 0:
            with_memcpy(new_buf, (*s).cursors as *const u8, (*s).cursor_count as i64 * 32)
        if (*s).cursors as i64 != 0: with_free((*s).cursors as *mut u8)
        (*s).cursors = new_buf as *mut CXCursor
    let dst = ((*s).cursors as i64 + (*s).cursor_count as i64 * 32) as *mut CXCursor
    *dst = cursor
    let idx = (*s).cursor_count
    (*s).cursor_count = (*s).cursor_count + 1
    idx

unsafe fn store_type(s: *mut CImportSession, ty: CXType) -> i32:
    if (*s).type_count >= (*s).type_cap:
        (*s).type_cap = if (*s).type_cap > 0: (*s).type_cap * 2 else: 256
        let new_buf = with_alloc((*s).type_cap as i64 * 24)
        if (*s).types as i64 != 0 and (*s).type_count > 0:
            with_memcpy(new_buf, (*s).types as *const u8, (*s).type_count as i64 * 24)
        if (*s).types as i64 != 0: with_free((*s).types as *mut u8)
        (*s).types = new_buf as *mut CXType
    let dst = ((*s).types as i64 + (*s).type_count as i64 * 24) as *mut CXType
    *dst = ty
    let idx = (*s).type_count
    (*s).type_count = (*s).type_count + 1
    idx

@[callconv("c")]
unsafe fn collect_child_cursor(cursor: CXCursor, parent: CXCursor, data: *mut u8) -> i32:
    let cc = data as *mut ChildCollector
    if (unsafe: *cc).count >= (unsafe: *cc).cap:
        (unsafe: *cc).cap = if (unsafe: *cc).cap > 0: (unsafe: *cc).cap * 2 else: 64
        let new_buf = with_alloc((unsafe: *cc).cap as i64 * 4)
        if (unsafe: *cc).indices as i64 != 0 and (unsafe: *cc).count > 0:
            with_memcpy(new_buf, (unsafe: *cc).indices as *const u8, (unsafe: *cc).count as i64 * 4)
        if (unsafe: *cc).indices as i64 != 0: with_free((unsafe: *cc).indices as *mut u8)
        (unsafe: *cc).indices = new_buf as *mut i32
    let stored_idx = store_cursor((unsafe: *cc).session, cursor)
    unsafe: *((((unsafe: *cc).indices as i64) + ((unsafe: *cc).count as i64 * 4)) as *mut i32) = stored_idx
    (unsafe: *cc).count = (unsafe: *cc).count + 1
    CXChildVisit_Continue

unsafe fn ensure_children_cached(s: *mut CImportSession, cursor_idx: i32):
    if cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return
    // Grow cache arrays if needed
    if cursor_idx >= (*s).children_cache_cap:
        let new_cap = if (*s).children_cache_cap > 0: (*s).children_cache_cap * 2 else: 256
        let new_cap2 = if new_cap > cursor_idx + 1: new_cap else: cursor_idx + 256
        let ns = with_alloc(new_cap2 as i64 * 4)
        let nc = with_alloc(new_cap2 as i64 * 4)
        with_memset(ns, -1, new_cap2 as i64 * 4)  // -1 = uncached
        with_memset(nc, 0, new_cap2 as i64 * 4)
        if (*s).child_starts as i64 != 0 and (*s).children_cache_cap > 0:
            with_memcpy(ns, (*s).child_starts as *const u8, (*s).children_cache_cap as i64 * 4)
            with_memcpy(nc, (*s).child_counts as *const u8, (*s).children_cache_cap as i64 * 4)
        if (*s).child_starts as i64 != 0: with_free((*s).child_starts as *mut u8)
        if (*s).child_counts as i64 != 0: with_free((*s).child_counts as *mut u8)
        (*s).child_starts = ns as *mut i32
        (*s).child_counts = nc as *mut i32
        (*s).children_cache_cap = new_cap2
    // Check if already cached
    let start_val = *(((*s).child_starts as i64 + cursor_idx as i64 * 4) as *const i32)
    if start_val != -1: return  // already cached
    // Collect children
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    var cc = ChildCollector { session: s, indices: 0 as *mut i32, count: 0, cap: 0 }
    let _ = clang_visitChildren(cursor, collect_child_cursor as *const u8, &raw mut cc as *mut ChildCollector as *mut u8)
    // Store results
    let flat_start = (*s).child_indices_count
    if cc.count > 0:
        // Grow child_indices only when needed. Reallocating on every
        // cursor cache fill makes large translation units quadratic.
        if (*s).child_indices_count + cc.count > (*s).child_indices_cap:
            while (*s).child_indices_count + cc.count > (*s).child_indices_cap:
                (*s).child_indices_cap = if (*s).child_indices_cap > 0: (*s).child_indices_cap * 2 else: 256
            let new_ci = with_alloc((*s).child_indices_cap as i64 * 4)
            if (*s).child_indices as i64 != 0 and (*s).child_indices_count > 0:
                with_memcpy(new_ci, (*s).child_indices as *const u8, (*s).child_indices_count as i64 * 4)
            if (*s).child_indices as i64 != 0: with_free((*s).child_indices as *mut u8)
            (*s).child_indices = new_ci as *mut i32
        // Copy indices
        with_memcpy(((*s).child_indices as i64 + flat_start as i64 * 4) as *mut u8, cc.indices as *const u8, cc.count as i64 * 4)
        (*s).child_indices_count = (*s).child_indices_count + cc.count
    if cc.indices as i64 != 0: with_free(cc.indices as *mut u8)
    *(((*s).child_starts as i64 + cursor_idx as i64 * 4) as *mut i32) = flat_start
    *(((*s).child_counts as i64 + cursor_idx as i64 * 4) as *mut i32) = cc.count

@[c_export("with_ci_root_cursor")]
pub unsafe fn ci_root_cursor(session: i64) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or (*s).tu as i64 == 0: return -1
    let root = clang_getTranslationUnitCursor((*s).tu)
    store_cursor(s, root)

@[c_export("with_ci_num_children")]
pub unsafe fn ci_num_children(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    ensure_children_cached(s, cursor_idx)
    if cursor_idx >= (*s).children_cache_cap: return 0
    *(((*s).child_counts as i64 + cursor_idx as i64 * 4) as *const i32)

@[c_export("with_ci_child")]
pub unsafe fn ci_child(session: i64, cursor_idx: i32, child_index: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return -1
    ensure_children_cached(s, cursor_idx)
    if cursor_idx >= (*s).children_cache_cap: return -1
    let count = *(((*s).child_counts as i64 + cursor_idx as i64 * 4) as *const i32)
    if child_index < 0 or child_index >= count: return -1
    let start = *(((*s).child_starts as i64 + cursor_idx as i64 * 4) as *const i32)
    *(((*s).child_indices as i64 + (start + child_index) as i64 * 4) as *const i32)

@[c_export("with_ci_cursor_kind")]
pub unsafe fn ci_cursor_kind(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    clang_getCursorKind(cursor)

@[c_export("with_ci_cursor_spelling")]
pub unsafe fn ci_cursor_spelling(session: i64, cursor_idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return ""
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    clang_str_to_with(s, clang_getCursorSpelling(cursor))

@[c_export("with_ci_cursor_kind_name")]
pub unsafe fn ci_cursor_kind_name(session: i64, cursor_idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return ""
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let kind = clang_getCursorKind(cursor)
    clang_str_to_with(s, clang_getCursorKindSpelling(kind))

@[c_export("with_ci_cursor_type")]
pub unsafe fn ci_cursor_type(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return -1
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    store_type(s, ty)

@[c_export("with_ci_type_kind")]
pub unsafe fn ci_type_kind(session: i64, type_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return 0
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    ty.kind

@[c_export("with_ci_type_spelling")]
pub unsafe fn ci_type_spelling(session: i64, type_idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return ""
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    clang_str_to_with(s, clang_getTypeSpelling(ty))

@[c_export("with_ci_type_sizeof")]
pub unsafe fn ci_type_sizeof(session: i64, type_idx: i32) -> i64:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return -1
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    clang_Type_getSizeOf(ty)

@[c_export("with_ci_type_alignof")]
pub unsafe fn ci_type_alignof(session: i64, type_idx: i32) -> i64:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return -1
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    clang_Type_getAlignOf(ty)

@[c_export("with_ci_type_is_const")]
pub unsafe fn ci_type_is_const(session: i64, type_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return 0
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    clang_isConstQualifiedType(ty)

@[c_export("with_ci_type_is_volatile")]
pub unsafe fn ci_type_is_volatile(session: i64, type_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return 0
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    clang_isVolatileQualifiedType(ty)

@[c_export("with_ci_type_pointee")]
pub unsafe fn ci_type_pointee(session: i64, type_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return -1
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    let pt = clang_getPointeeType(ty)
    if pt.kind == CXType_Invalid: return -1
    store_type(s, pt)

@[c_export("with_ci_type_canonical")]
pub unsafe fn ci_type_canonical(session: i64, type_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return -1
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    let ct = clang_getCanonicalType(ty)
    store_type(s, ct)

@[c_export("with_ci_type_result")]
pub unsafe fn ci_type_result(session: i64, type_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return -1
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    let rt = clang_getResultType(ty)
    if rt.kind == CXType_Invalid: return -1
    store_type(s, rt)

@[c_export("with_ci_type_arg_count")]
pub unsafe fn ci_type_arg_count(session: i64, type_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return 0
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    clang_getNumArgTypes(ty)

@[c_export("with_ci_type_arg")]
pub unsafe fn ci_type_arg(session: i64, type_idx: i32, index: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return -1
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    let at = clang_getArgType(ty, index as u32)
    if at.kind == CXType_Invalid: return -1
    store_type(s, at)

@[c_export("with_ci_type_is_variadic")]
pub unsafe fn ci_type_is_variadic(session: i64, type_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return 0
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    clang_isFunctionTypeVariadic(ty)

@[c_export("with_ci_type_array_size")]
pub unsafe fn ci_type_array_size(session: i64, type_idx: i32) -> i64:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return -1
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    clang_getArraySize(ty)

@[c_export("with_ci_type_array_element")]
pub unsafe fn ci_type_array_element(session: i64, type_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return -1
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    let et = clang_getArrayElementType(ty)
    if et.kind == CXType_Invalid: return -1
    store_type(s, et)

@[c_export("with_ci_type_named")]
pub unsafe fn ci_type_named(session: i64, type_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return -1
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    let nt = clang_Type_getNamedType(ty)
    if nt.kind == CXType_Invalid: return -1
    store_type(s, nt)

@[c_export("with_ci_type_declaration")]
pub unsafe fn ci_type_declaration(session: i64, type_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return -1
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    let decl = clang_getTypeDeclaration(ty)
    if decl.kind == 0: return -1
    store_cursor(s, decl)

@[c_export("with_ci_type_translated")]
pub unsafe fn ci_type_translated(session: i64, type_idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return ""
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    let result = translate_type_recursive(s, ty, 0, 0)
    if result as i64 == 0: return ""
    session_make_str(s, result as *const u8)

// ── Cursor extras ───────────────────────────────────────────

@[c_export("with_ci_cursor_linkage")]
pub unsafe fn ci_cursor_linkage(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    clang_getCursorLinkage(cursor)

@[c_export("with_ci_cursor_storage_class")]
pub unsafe fn ci_cursor_storage_class(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    clang_Cursor_getStorageClass(cursor)

@[c_export("with_ci_cursor_is_inline")]
pub unsafe fn ci_cursor_is_inline(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    clang_Cursor_isFunctionInlined(cursor)

@[c_export("with_ci_cursor_is_anonymous")]
pub unsafe fn ci_cursor_is_anonymous(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    clang_Cursor_isAnonymous(cursor)

@[c_export("with_ci_cursor_is_bitfield")]
pub unsafe fn ci_cursor_is_bitfield(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    clang_Cursor_isBitField(cursor)

@[c_export("with_ci_field_offset_bits")]
pub unsafe fn ci_field_offset_bits(session: i64, cursor_idx: i32) -> i64:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return -1
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let parent = clang_getCursorSemanticParent(cursor)
    let parent_type = clang_getCursorType(parent)
    let name_cxs = clang_getCursorSpelling(cursor)
    let name_cstr = clang_getCString(name_cxs)
    let offset = clang_Type_getOffsetOf(parent_type, name_cstr)
    clang_disposeString(name_cxs)
    offset

@[c_export("with_ci_enum_const_value_new")]
pub unsafe fn ci_enum_const_value_new(session: i64, cursor_idx: i32) -> i64:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    clang_getEnumConstantDeclValue(cursor)

@[c_export("with_ci_cursor_is_definition")]
pub unsafe fn ci_cursor_is_definition(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    clang_isCursorDefinition(cursor)

// ── Target info ─────────────────────────────────────────────

@[c_export("with_ci_pointer_width")]
pub unsafe fn ci_pointer_width(session: i64) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or (*s).tu as i64 == 0: return 8
    // On 64-bit platforms, pointer width is 8
    8

@[c_export("with_ci_sizeof_long")]
pub unsafe fn ci_sizeof_long(session: i64) -> i32:
    // On aarch64 Darwin, sizeof(long) = 8
    8

@[c_export("with_ci_char_is_signed")]
pub unsafe fn ci_char_is_signed(session: i64) -> i32:
    // On aarch64 Darwin, char is signed
    1

@[c_export("with_ci_target_triple")]
pub unsafe fn ci_target_triple(session: i64) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or (*s).tu as i64 == 0: return ""
    let ti = clang_getTranslationUnitTargetInfo((*s).tu)
    if ti as i64 == 0: return ""
    let triple = clang_TargetInfo_getTriple(ti)
    let result = clang_str_to_with(s, triple)
    clang_TargetInfo_dispose(ti)
    result

// ── Evaluation ──────────────────────────────────────────────

@[c_export("with_ci_eval_int_valid")]
pub unsafe fn ci_eval_int_valid(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let result = clang_Cursor_Evaluate(cursor)
    if result as i64 == 0: return 0
    let kind = clang_EvalResult_getKind(result)
    clang_EvalResult_dispose(result)
    if kind == CXEval_Int: return 1
    0

@[c_export("with_ci_eval_int_value")]
pub unsafe fn ci_eval_int_value(session: i64, cursor_idx: i32) -> i64:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let result = clang_Cursor_Evaluate(cursor)
    if result as i64 == 0: return 0
    let val = clang_EvalResult_getAsLongLong(result)
    clang_EvalResult_dispose(result)
    val

@[c_export("with_ci_eval_int_is_unsigned")]
pub unsafe fn ci_eval_int_is_unsigned(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let result = clang_Cursor_Evaluate(cursor)
    if result as i64 == 0: return 0
    let is_unsigned = clang_EvalResult_isUnsignedInt(result)
    clang_EvalResult_dispose(result)
    is_unsigned

@[c_export("with_ci_eval_as_int")]
pub unsafe fn ci_eval_as_int(session: i64, cursor_idx: i32, out: *mut i64) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let result = clang_Cursor_Evaluate(cursor)
    if result as i64 == 0: return 0
    let kind = clang_EvalResult_getKind(result)
    if kind == CXEval_Int:
        *out = clang_EvalResult_getAsLongLong(result)
        clang_EvalResult_dispose(result)
        return 1
    clang_EvalResult_dispose(result)
    0

@[c_export("with_ci_eval_as_float")]
pub unsafe fn ci_eval_as_float(session: i64, cursor_idx: i32, out: *mut f64) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let result = clang_Cursor_Evaluate(cursor)
    if result as i64 == 0: return 0
    let kind = clang_EvalResult_getKind(result)
    if kind == CXEval_Float:
        *out = clang_EvalResult_getAsDouble(result)
        clang_EvalResult_dispose(result)
        return 1
    clang_EvalResult_dispose(result)
    0

@[c_export("with_ci_eval_as_str")]
pub unsafe fn ci_eval_as_str(session: i64, cursor_idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return ""
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let result = clang_Cursor_Evaluate(cursor)
    if result as i64 == 0: return ""
    let kind = clang_EvalResult_getKind(result)
    if kind == CXEval_StrLiteral:
        let cstr = clang_EvalResult_getAsStr(result)
        let r = session_make_str(s, cstr)
        clang_EvalResult_dispose(result)
        return r
    clang_EvalResult_dispose(result)
    ""

// ── Calling convention ──────────────────────────────────────

@[c_export("with_ci_calling_conv")]
pub unsafe fn ci_calling_conv(session: i64, type_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or type_idx < 0 or type_idx >= (*s).type_count: return 0
    let ty = *(((*s).types as i64 + type_idx as i64 * 24) as *const CXType)
    clang_getFunctionTypeCallingConv(ty)

@[c_export("with_ci_typedef_underlying_type")]
pub unsafe fn ci_typedef_underlying_type(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return -1
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let ty = clang_getTypedefDeclUnderlyingType(cursor)
    if ty.kind == CXType_Invalid: return -1
    store_type(s, ty)

@[c_export("with_ci_enum_int_type")]
pub unsafe fn ci_enum_int_type(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return -1
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let ty = clang_getEnumDeclIntegerType(cursor)
    if ty.kind == CXType_Invalid: return -1
    store_type(s, ty)

// ── Type predicates ─────────────────────────────────────────

@[c_export("with_ci_type_is_unsigned")]
pub unsafe fn ci_type_is_unsigned(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    let canonical = clang_getCanonicalType(ty)
    let k = canonical.kind
    if k == CXType_UChar or k == CXType_Char_U or k == CXType_UShort or k == CXType_UInt or k == CXType_ULong or k == CXType_ULongLong or k == CXType_UInt128:
        return 1
    0

@[c_export("with_ci_type_is_pointer")]
pub unsafe fn ci_type_is_pointer(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    let canonical = clang_getCanonicalType(ty)
    if canonical.kind == CXType_Pointer: return 1
    0

@[c_export("with_ci_type_is_float")]
pub unsafe fn ci_type_is_float(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    let canonical = clang_getCanonicalType(ty)
    let k = canonical.kind
    if k == CXType_Float or k == CXType_Double or k == CXType_LongDouble or k == CXType_Float128:
        return 1
    0

@[c_export("with_ci_type_is_bool")]
pub unsafe fn ci_type_is_bool(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    let canonical = clang_getCanonicalType(ty)
    if canonical.kind == CXType_Bool: return 1
    0

// ── Cursor location and source text ─────────────────────────

@[c_export("with_ci_cursor_location")]
pub unsafe fn ci_cursor_location(session: i64, cursor_idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return ""
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let loc = clang_getCursorLocation(cursor)
    var presumed_bits: [2]i64 = [0 as i64; 2]
    var line_val: u32 = 0
    var col_val: u32 = 0
    clang_getPresumedLocation(loc, &raw mut presumed_bits as *mut [2]i64 as *mut CXString, &raw mut line_val, &raw mut col_val)
    let presumed_file = *(&raw mut presumed_bits as *mut [2]i64 as *mut CXString)
    var fname_str = clang_getCString(presumed_file)
    var fallback_bits: [2]i64 = [0 as i64; 2]
    var fallback_active = false
    if fname_str as i64 == 0 or *fname_str == 0:
        var file: *mut u8 = 0 as *mut u8
        clang_getFileLocation(loc, &raw mut file, &raw mut line_val, &raw mut col_val, 0 as *mut u32)
        if file as i64 == 0:
            clang_disposeString(presumed_file)
            return ""
        let fname = clang_getFileName(file)
        fname_str = clang_getCString(fname)
        fallback_bits[0] = fname.data
        fallback_bits[1] = ((fname.private_flags as u64) | ((fname.pad0 as u64) << 32)) as i64
        fallback_active = true
    var buf: [1024]u8 = [0 as u8; 1024]
    var pos: i64 = 0
    buf_append_str(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, if fname_str as i64 != 0: fname_str else: "?\0" as *const u8)
    buf_append_str(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, ":\0" as *const u8)
    buf_append_i64(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, line_val as i64)
    buf_append_str(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, ":\0" as *const u8)
    buf_append_i64(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, col_val as i64)
    if fallback_active:
        let fallback_file = *(&raw mut fallback_bits as *mut [2]i64 as *mut CXString)
        clang_disposeString(fallback_file)
    clang_disposeString(presumed_file)
    session_make_str(s, &buf as *const [1024]u8 as *const u8)

@[c_export("with_ci_cursor_referenced_location")]
pub unsafe fn ci_cursor_referenced_location(session: i64, cursor_idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return ""
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let referenced = clang_getCursorReferenced(cursor)
    if clang_Cursor_isNull(referenced) != 0:
        return ""
    let loc = clang_getCursorLocation(referenced)
    var presumed_bits: [2]i64 = [0 as i64; 2]
    var line_val: u32 = 0
    var col_val: u32 = 0
    clang_getPresumedLocation(loc, &raw mut presumed_bits as *mut [2]i64 as *mut CXString, &raw mut line_val, &raw mut col_val)
    let presumed_file = *(&raw mut presumed_bits as *mut [2]i64 as *mut CXString)
    let fname_str = clang_getCString(presumed_file)
    if fname_str as i64 == 0 or *fname_str == 0:
        clang_disposeString(presumed_file)
        return ""
    var buf: [1024]u8 = [0 as u8; 1024]
    var pos: i64 = 0
    buf_append_str(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, fname_str)
    buf_append_str(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, ":\0" as *const u8)
    buf_append_i64(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, line_val as i64)
    buf_append_str(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, ":\0" as *const u8)
    buf_append_i64(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, col_val as i64)
    clang_disposeString(presumed_file)
    session_make_str(s, &buf as *const [1024]u8 as *const u8)

@[c_export("with_ci_cursor_expansion_location")]
pub unsafe fn ci_cursor_expansion_location(session: i64, cursor_idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return ""
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let loc = clang_getCursorLocation(cursor)
    var file: *mut u8 = 0 as *mut u8
    var line_val: u32 = 0
    var col_val: u32 = 0
    clang_getExpansionLocation(loc, &raw mut file, &raw mut line_val, &raw mut col_val, 0 as *mut u32)
    if file as i64 == 0:
        return ""
    let fname = clang_getFileName(file)
    let fname_str = clang_getCString(fname)
    if fname_str as i64 == 0 or *fname_str == 0:
        clang_disposeString(fname)
        return ""
    var buf: [1024]u8 = [0 as u8; 1024]
    var pos: i64 = 0
    buf_append_str(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, fname_str)
    buf_append_str(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, ":\0" as *const u8)
    buf_append_i64(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, line_val as i64)
    buf_append_str(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, ":\0" as *const u8)
    buf_append_i64(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, col_val as i64)
    clang_disposeString(fname)
    session_make_str(s, &buf as *const [1024]u8 as *const u8)

@[c_export("with_ci_cursor_spelling_location")]
pub unsafe fn ci_cursor_spelling_location(session: i64, cursor_idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return ""
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let loc = clang_getCursorLocation(cursor)
    var file: *mut u8 = 0 as *mut u8
    var line_val: u32 = 0
    var col_val: u32 = 0
    clang_getSpellingLocation(loc, &raw mut file, &raw mut line_val, &raw mut col_val, 0 as *mut u32)
    if file as i64 == 0:
        var expansion_file: *mut u8 = 0 as *mut u8
        clang_getExpansionLocation(loc, &raw mut expansion_file, 0 as *mut u32, 0 as *mut u32, 0 as *mut u32)
        file = expansion_file
    if file as i64 == 0:
        return ""
    let fname = clang_getFileName(file)
    let fname_str = clang_getCString(fname)
    if fname_str as i64 == 0 or *fname_str == 0:
        clang_disposeString(fname)
        return ""
    var buf: [1024]u8 = [0 as u8; 1024]
    var pos: i64 = 0
    buf_append_str(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, fname_str)
    buf_append_str(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, ":\0" as *const u8)
    buf_append_i64(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, line_val as i64)
    buf_append_str(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, ":\0" as *const u8)
    buf_append_i64(&raw mut buf as *mut [1024]u8 as *mut u8, &raw mut pos, 1024, col_val as i64)
    clang_disposeString(fname)
    session_make_str(s, &buf as *const [1024]u8 as *const u8)

unsafe fn source_location_expansion_offset(loc: CXSourceLocation, file: *mut *mut u8, offset: *mut u32):
    clang_getExpansionLocation(loc, file, 0 as *mut u32, 0 as *mut u32, offset)
    if (*file as i64) == 0:
        clang_getFileLocation(loc, file, 0 as *mut u32, 0 as *mut u32, offset)

unsafe fn source_location_spelling_offset(loc: CXSourceLocation, file: *mut *mut u8, offset: *mut u32):
    clang_getSpellingLocation(loc, file, 0 as *mut u32, 0 as *mut u32, offset)
    if (*file as i64) == 0:
        clang_getFileLocation(loc, file, 0 as *mut u32, 0 as *mut u32, offset)

unsafe fn source_range_expansion_offsets(range: CXSourceRange, file: *mut *mut u8, start_off: *mut u32, end_off: *mut u32) -> i32:
    var start_file: *mut u8 = 0 as *mut u8
    var end_file: *mut u8 = 0 as *mut u8
    source_location_expansion_offset(clang_getRangeStart(range), &raw mut start_file, start_off)
    source_location_expansion_offset(clang_getRangeEnd(range), &raw mut end_file, end_off)
    if start_file as i64 == 0 or end_file as i64 == 0:
        return 0
    if clang_File_isEqual(start_file, end_file) == 0:
        return 0
    *file = start_file
    1

unsafe fn source_range_spelling_offsets(range: CXSourceRange, file: *mut *mut u8, start_off: *mut u32, end_off: *mut u32) -> i32:
    var start_file: *mut u8 = 0 as *mut u8
    var end_file: *mut u8 = 0 as *mut u8
    source_location_spelling_offset(clang_getRangeStart(range), &raw mut start_file, start_off)
    source_location_spelling_offset(clang_getRangeEnd(range), &raw mut end_file, end_off)
    if start_file as i64 == 0 or end_file as i64 == 0:
        return 0
    if clang_File_isEqual(start_file, end_file) == 0:
        return 0
    *file = start_file
    1

unsafe fn source_range_preferred_text_offsets(range: CXSourceRange, file: *mut *mut u8, start_off: *mut u32, end_off: *mut u32) -> i32:
    var expansion_file: *mut u8 = 0 as *mut u8
    var expansion_start: u32 = 0
    var expansion_end: u32 = 0
    let has_expansion = source_range_expansion_offsets(range, &raw mut expansion_file, &raw mut expansion_start, &raw mut expansion_end)

    var spelling_file: *mut u8 = 0 as *mut u8
    var spelling_start: u32 = 0
    var spelling_end: u32 = 0
    let has_spelling = source_range_spelling_offsets(range, &raw mut spelling_file, &raw mut spelling_start, &raw mut spelling_end)

    if has_spelling != 0 and spelling_end > spelling_start:
        // Macro cursors often expand to the invocation token. Prefer spelling
        // when the cursor is wholly in the macro body or wholly in an argument;
        // avoid mixed body+argument ranges because those span unrelated text.
        if has_expansion == 0 or clang_File_isEqual(spelling_file, expansion_file) == 0 or spelling_start >= expansion_start or spelling_end <= expansion_start:
            *file = spelling_file
            *start_off = spelling_start
            *end_off = spelling_end
            return 1

    if has_expansion != 0:
        *file = expansion_file
        *start_off = expansion_start
        *end_off = expansion_end
        return 1

    0

// Returns the start byte offset of a cursor's source range, or -1 if unavailable.
// Used by the for-loop handler to classify children as init/cond/inc by position.
@[c_export("with_ci_cursor_start_offset")]
pub unsafe fn ci_cursor_start_offset(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return -1
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let range = clang_getCursorExtent(cursor)
    let start_loc = clang_getRangeStart(range)
    var file: *mut u8 = 0 as *mut u8
    var start_off: u32 = 0
    source_location_expansion_offset(start_loc, &raw mut file, &raw mut start_off)
    if file as i64 == 0: return -1
    start_off as i32

unsafe fn cursor_source_text_from_cursor(s: *mut CImportSession, cursor: CXCursor) -> str:
    let range = clang_getCursorExtent(cursor)
    var file: *mut u8 = 0 as *mut u8
    var start_off: u32 = 0
    var end_off: u32 = 0
    if source_range_preferred_text_offsets(range, &raw mut file, &raw mut start_off, &raw mut end_off) == 0:
        return ""
    if end_off <= start_off: return ""
    var buf_size: u64 = 0
    let contents = clang_getFileContents((*s).tu, file, &raw mut buf_size)
    if contents as i64 == 0 or end_off as u64 > buf_size: return ""
    let len = (end_off - start_off) as i64
    let text = with_alloc(len + 1)
    with_memcpy(text, (contents as i64 + start_off as i64) as *const u8, len)
    *((text as i64 + len) as *mut u8) = 0
    let result = session_make_str(s, text as *const u8)
    with_free(text)
    result

unsafe fn cursor_expansion_text_from_cursor(s: *mut CImportSession, cursor: CXCursor) -> str:
    let range = clang_getCursorExtent(cursor)
    var file: *mut u8 = 0 as *mut u8
    var start_off: u32 = 0
    var end_off: u32 = 0
    if source_range_expansion_offsets(range, &raw mut file, &raw mut start_off, &raw mut end_off) == 0:
        return ""
    if end_off <= start_off: return ""
    var buf_size: u64 = 0
    let contents = clang_getFileContents((*s).tu, file, &raw mut buf_size)
    if contents as i64 == 0 or end_off as u64 > buf_size: return ""
    let len = (end_off - start_off) as i64
    let text = with_alloc(len + 1)
    with_memcpy(text, (contents as i64 + start_off as i64) as *const u8, len)
    *((text as i64 + len) as *mut u8) = 0
    let result = session_make_str(s, text as *const u8)
    with_free(text)
    result

unsafe fn cursor_spelling_text_from_cursor(s: *mut CImportSession, cursor: CXCursor) -> str:
    let range = clang_getCursorExtent(cursor)
    var file: *mut u8 = 0 as *mut u8
    var start_off: u32 = 0
    var end_off: u32 = 0
    if source_range_spelling_offsets(range, &raw mut file, &raw mut start_off, &raw mut end_off) == 0:
        return ""
    if end_off <= start_off: return ""
    var buf_size: u64 = 0
    let contents = clang_getFileContents((*s).tu, file, &raw mut buf_size)
    if contents as i64 == 0 or end_off as u64 > buf_size: return ""
    let len = (end_off - start_off) as i64
    let text = with_alloc(len + 1)
    with_memcpy(text, (contents as i64 + start_off as i64) as *const u8, len)
    *((text as i64 + len) as *mut u8) = 0
    let result = session_make_str(s, text as *const u8)
    with_free(text)
    result

unsafe fn cursor_token_text_from_cursor(s: *mut CImportSession, cursor: CXCursor) -> str:
    let tu = clang_Cursor_getTranslationUnit(cursor)
    if tu as i64 == 0:
        return ""
    let cursor_range = clang_getCursorExtent(cursor)
    var file: *mut u8 = 0 as *mut u8
    var start_off: u32 = 0
    var end_off: u32 = 0
    if source_range_preferred_text_offsets(cursor_range, &raw mut file, &raw mut start_off, &raw mut end_off) == 0:
        return ""
    let begin_loc = clang_getLocationForOffset(tu, file, start_off)
    let end_loc = clang_getLocationForOffset(tu, file, end_off)
    let range = clang_getRange(begin_loc, end_loc)
    var tokens: *mut CXToken = 0 as *mut CXToken
    var token_count: u32 = 0
    clang_tokenize(tu, range, &raw mut tokens, &raw mut token_count)
    if tokens as i64 == 0 or token_count == 0:
        return ""

    var total_len: i64 = 0
    var ti: u32 = 0
    while ti < token_count:
        let tok = *((tokens as i64 + ti as i64 * 24) as *const CXToken)
        let spelling = clang_getTokenSpelling(tu, tok)
        let cstr = clang_getCString(spelling)
        if cstr as i64 != 0:
            total_len = total_len + c_strlen(cstr)
            if ti + 1 < token_count:
                total_len = total_len + 1
        clang_disposeString(spelling)
        ti = ti + 1

    let text = with_alloc(total_len + 1)
    if text as i64 == 0:
        clang_disposeTokens(tu, tokens, token_count)
        return ""

    var pos: i64 = 0
    ti = 0
    while ti < token_count:
        let tok = *((tokens as i64 + ti as i64 * 24) as *const CXToken)
        let spelling = clang_getTokenSpelling(tu, tok)
        let cstr = clang_getCString(spelling)
        if cstr as i64 != 0:
            let slen = c_strlen(cstr)
            if slen > 0:
                with_memcpy((text as i64 + pos) as *mut u8, cstr, slen)
                pos = pos + slen
            if ti + 1 < token_count:
                *((text as i64 + pos) as *mut u8) = 32
                pos = pos + 1
        clang_disposeString(spelling)
        ti = ti + 1
    *((text as i64 + pos) as *mut u8) = 0
    clang_disposeTokens(tu, tokens, token_count)
    let result = session_make_str(s, text as *const u8)
    with_free(text)
    result

@[c_export("with_ci_cursor_source_text")]
pub unsafe fn ci_cursor_source_text(session: i64, cursor_idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return ""
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    cursor_source_text_from_cursor(s, cursor)

@[c_export("with_ci_cursor_expansion_text")]
pub unsafe fn ci_cursor_expansion_text(session: i64, cursor_idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return ""
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    cursor_expansion_text_from_cursor(s, cursor)

@[c_export("with_ci_cursor_spelling_text")]
pub unsafe fn ci_cursor_spelling_text(session: i64, cursor_idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return ""
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    cursor_spelling_text_from_cursor(s, cursor)

@[c_export("with_ci_cursor_token_text")]
pub unsafe fn ci_cursor_token_text(session: i64, cursor_idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return ""
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    cursor_token_text_from_cursor(s, cursor)

@[c_export("with_ci_cursor_pointee_type")]
pub unsafe fn ci_cursor_pointee_type(session: i64, cursor_idx: i32) -> str:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return ""
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let ty = clang_getCursorType(cursor)
    let canonical = clang_getCanonicalType(ty)
    if canonical.kind != CXType_Pointer: return ""
    let pointee = clang_getPointeeType(canonical)
    let result = translate_type_recursive(s, pointee, 0, 0)
    if result as i64 == 0: return ""
    session_make_str(s, result as *const u8)

// ── Member expression ───────────────────────────────────────

@[c_export("with_ci_member_is_arrow")]
pub unsafe fn ci_member_is_arrow(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return 0
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let range = clang_getCursorExtent(cursor)
    var start_off: u32 = 0
    var end_off: u32 = 0
    var file: *mut u8 = 0 as *mut u8
    if source_range_expansion_offsets(range, &raw mut file, &raw mut start_off, &raw mut end_off) == 0:
        return 0
    if end_off <= start_off: return 0
    var buf_size: u64 = 0
    let contents = clang_getFileContents((*s).tu, file, &raw mut buf_size)
    if contents as i64 == 0: return 0
    var i: u32 = start_off
    while i + 1 < end_off and i as u64 < buf_size - 1:
        if *((contents as i64 + i as i64) as *const u8) == 45 and *((contents as i64 + i as i64 + 1) as *const u8) == 62:
            return 1
        i = i + 1
    0

@[c_export("with_ci_member_field_name")]
pub unsafe fn ci_member_field_name(session: i64, cursor_idx: i32) -> str:
    ci_cursor_spelling(session, cursor_idx)

// ── Binary/unary operators ──────────────────────────────────

@[c_export("with_ci_binary_op")]
pub unsafe fn ci_binary_op(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return -1
    ensure_children_cached(s, cursor_idx)
    if cursor_idx >= (*s).children_cache_cap: return -1
    let count = *(((*s).child_counts as i64 + cursor_idx as i64 * 4) as *const i32)
    if count < 2: return -1
    let start = *(((*s).child_starts as i64 + cursor_idx as i64 * 4) as *const i32)
    let lhs_idx = *(((*s).child_indices as i64 + start as i64 * 4) as *const i32)
    let rhs_idx = *(((*s).child_indices as i64 + (start + 1) as i64 * 4) as *const i32)
    let lhs_cursor = *(((*s).cursors as i64 + lhs_idx as i64 * 32) as *const CXCursor)
    let rhs_cursor = *(((*s).cursors as i64 + rhs_idx as i64 * 32) as *const CXCursor)
    let lhs_range = clang_getCursorExtent(lhs_cursor)
    let rhs_range = clang_getCursorExtent(rhs_cursor)
    let lhs_end = clang_getRangeEnd(lhs_range)
    let rhs_start = clang_getRangeStart(rhs_range)
    var lhs_end_off: u32 = 0
    var rhs_start_off: u32 = 0
    var lhs_file: *mut u8 = 0 as *mut u8
    var rhs_file: *mut u8 = 0 as *mut u8
    source_location_expansion_offset(lhs_end, &raw mut lhs_file, &raw mut lhs_end_off)
    source_location_expansion_offset(rhs_start, &raw mut rhs_file, &raw mut rhs_start_off)
    if lhs_file as i64 != 0 and rhs_file as i64 != 0 and clang_File_isEqual(lhs_file, rhs_file) != 0 and rhs_start_off > lhs_end_off:
        var buf_size: u64 = 0
        let contents = clang_getFileContents((*s).tu, lhs_file, &raw mut buf_size)
        if contents as i64 != 0 and rhs_start_off as u64 <= buf_size:
            // Extract operator text between lhs end and rhs start, trimmed
            var op_s = lhs_end_off
            var op_e = rhs_start_off
            while op_s < op_e and (*((contents as i64 + op_s as i64) as *const u8) == 32 or *((contents as i64 + op_s as i64) as *const u8) == 9 or *((contents as i64 + op_s as i64) as *const u8) == 10):
                op_s = op_s + 1
            while op_e > op_s and (*((contents as i64 + (op_e - 1) as i64) as *const u8) == 32 or *((contents as i64 + (op_e - 1) as i64) as *const u8) == 9 or *((contents as i64 + (op_e - 1) as i64) as *const u8) == 10):
                op_e = op_e - 1
            let op_len = op_e - op_s
            let c0 = *((contents as i64 + op_s as i64) as *const u8)
            // Return values must match the BO_* constants in CImport.w (1-indexed)
            if op_len == 1:
                if c0 == 43: return 1   // + = BO_ADD
                if c0 == 45: return 2   // - = BO_SUB
                if c0 == 42: return 3   // * = BO_MUL
                if c0 == 47: return 4   // / = BO_DIV
                if c0 == 37: return 5   // % = BO_REM
                if c0 == 38: return 6   // & = BO_AND
                if c0 == 124: return 7  // | = BO_OR
                if c0 == 94: return 8   // ^ = BO_XOR
                if c0 == 60: return 13  // < = BO_LT
                if c0 == 62: return 14  // > = BO_GT
                if c0 == 61: return 19  // = = BO_ASSIGN
                if c0 == 44: return 30  // , = BO_COMMA
            let c1 = *((contents as i64 + op_s as i64 + 1) as *const u8)
            if op_len == 2:
                if c0 == 60 and c1 == 60: return 9    // << = BO_SHL
                if c0 == 62 and c1 == 62: return 10   // >> = BO_SHR
                if c0 == 61 and c1 == 61: return 11   // == = BO_EQ
                if c0 == 33 and c1 == 61: return 12   // != = BO_NE
                if c0 == 60 and c1 == 61: return 15   // <= = BO_LE
                if c0 == 62 and c1 == 61: return 16   // >= = BO_GE
                if c0 == 38 and c1 == 38: return 17   // && = BO_LAND
                if c0 == 124 and c1 == 124: return 18 // || = BO_LOR
                if c0 == 43 and c1 == 61: return 20   // += = BO_ADD_ASSIGN
                if c0 == 45 and c1 == 61: return 21   // -= = BO_SUB_ASSIGN
                if c0 == 42 and c1 == 61: return 22   // *= = BO_MUL_ASSIGN
                if c0 == 47 and c1 == 61: return 23   // /= = BO_DIV_ASSIGN
                if c0 == 37 and c1 == 61: return 24   // %= = BO_REM_ASSIGN
                if c0 == 38 and c1 == 61: return 25   // &= = BO_AND_ASSIGN
                if c0 == 124 and c1 == 61: return 26  // |= = BO_OR_ASSIGN
                if c0 == 94 and c1 == 61: return 27   // ^= = BO_XOR_ASSIGN
            if op_len == 3:
                let c2 = *((contents as i64 + op_s as i64 + 2) as *const u8)
                if c0 == 60 and c1 == 60 and c2 == 61: return 28 // <<= = BO_SHL_ASSIGN
                if c0 == 62 and c1 == 62 and c2 == 61: return 29 // >>=
    // Fallback: use clang_Cursor_getBinaryOpcode API for macro expansions
    // where source locations span across files (LHS at call site, RHS in macro def)
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let cx_op = clang_Cursor_getBinaryOpcode(cursor)
    if cx_op == 3: return 3    // CX_BO_Mul → BO_MUL
    if cx_op == 4: return 4    // CX_BO_Div → BO_DIV
    if cx_op == 5: return 5    // CX_BO_Rem → BO_REM
    if cx_op == 6: return 1    // CX_BO_Add → BO_ADD
    if cx_op == 7: return 2    // CX_BO_Sub → BO_SUB
    if cx_op == 8: return 9    // CX_BO_Shl → BO_SHL
    if cx_op == 9: return 10   // CX_BO_Shr → BO_SHR
    if cx_op == 11: return 13  // CX_BO_LT → BO_LT
    if cx_op == 12: return 14  // CX_BO_GT → BO_GT
    if cx_op == 13: return 15  // CX_BO_LE → BO_LE
    if cx_op == 14: return 16  // CX_BO_GE → BO_GE
    if cx_op == 15: return 11  // CX_BO_EQ → BO_EQ
    if cx_op == 16: return 12  // CX_BO_NE → BO_NE
    if cx_op == 17: return 6   // CX_BO_And → BO_AND
    if cx_op == 18: return 8   // CX_BO_Xor → BO_XOR
    if cx_op == 19: return 7   // CX_BO_Or → BO_OR
    if cx_op == 20: return 17  // CX_BO_LAnd → BO_LAND
    if cx_op == 21: return 18  // CX_BO_LOr → BO_LOR
    if cx_op == 22: return 19  // CX_BO_Assign → BO_ASSIGN
    if cx_op == 23: return 22  // CX_BO_MulAssign → BO_MUL_ASSIGN
    if cx_op == 24: return 23  // CX_BO_DivAssign → BO_DIV_ASSIGN
    if cx_op == 25: return 24  // CX_BO_RemAssign → BO_REM_ASSIGN
    if cx_op == 26: return 20  // CX_BO_AddAssign → BO_ADD_ASSIGN
    if cx_op == 27: return 21  // CX_BO_SubAssign → BO_SUB_ASSIGN
    if cx_op == 28: return 28  // CX_BO_ShlAssign → BO_SHL_ASSIGN
    if cx_op == 29: return 29  // CX_BO_ShrAssign → BO_SHR_ASSIGN
    if cx_op == 30: return 25  // CX_BO_AndAssign → BO_AND_ASSIGN
    if cx_op == 31: return 27  // CX_BO_XorAssign → BO_XOR_ASSIGN
    if cx_op == 32: return 26  // CX_BO_OrAssign → BO_OR_ASSIGN
    if cx_op == 33: return 30  // CX_BO_Comma → BO_COMMA
    -1

@[c_export("with_ci_unary_op")]
pub unsafe fn ci_unary_op(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return -1
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let range = clang_getCursorExtent(cursor)
    ensure_children_cached(s, cursor_idx)
    if cursor_idx >= (*s).children_cache_cap: return -1
    let child_count = *(((*s).child_counts as i64 + cursor_idx as i64 * 4) as *const i32)
    if child_count < 1: return -1
    let child_idx = *(((*s).child_indices as i64 + (*(((*s).child_starts as i64 + cursor_idx as i64 * 4) as *const i32)) as i64 * 4) as *const i32)
    let child_cursor = *(((*s).cursors as i64 + child_idx as i64 * 32) as *const CXCursor)
    let child_range = clang_getCursorExtent(child_cursor)
    let op_loc = clang_getRangeStart(range)
    let child_start = clang_getRangeStart(child_range)
    let child_end = clang_getRangeEnd(child_range)
    var op_off: u32 = 0
    var child_start_off: u32 = 0
    var child_end_off: u32 = 0
    var op_file: *mut u8 = 0 as *mut u8
    var child_start_file: *mut u8 = 0 as *mut u8
    var child_end_file: *mut u8 = 0 as *mut u8
    source_location_expansion_offset(op_loc, &raw mut op_file, &raw mut op_off)
    source_location_expansion_offset(child_start, &raw mut child_start_file, &raw mut child_start_off)
    source_location_expansion_offset(child_end, &raw mut child_end_file, &raw mut child_end_off)
    if op_file as i64 == 0:
        return -1
    if child_start_file as i64 == 0 or child_end_file as i64 == 0:
        return -1
    if clang_File_isEqual(op_file, child_start_file) == 0 or clang_File_isEqual(op_file, child_end_file) == 0:
        return -1
    var buf_size: u64 = 0
    let contents = clang_getFileContents((*s).tu, op_file, &raw mut buf_size)
    if contents as i64 == 0: return -1
    // Prefix operator
    if op_off < child_start_off:
        var len = child_start_off - op_off
        let op = (contents as i64 + op_off as i64) as *const u8
        while len > 0 and (*((op as i64 + len as i64 - 1) as *const u8) == 32 or *((op as i64 + len as i64 - 1) as *const u8) == 9): len = len - 1
        // Return values must match UO_* constants in CImport.w (1-indexed)
        if len == 1 and *op == 45: return 1  // - = UO_MINUS
        if len == 1 and *op == 126: return 2 // ~ = UO_NOT
        if len == 1 and *op == 33: return 3  // ! = UO_LNOT
        if len == 1 and *op == 38: return 4  // & = UO_ADDR
        if len == 1 and *op == 42: return 5  // * = UO_DEREF
        if len == 1 and *op == 43: return 6  // + = UO_PLUS
        if len == 2 and *op == 43 and *((op as i64 + 1) as *const u8) == 43: return 7 // ++ = UO_PRE_INC
        if len == 2 and *op == 45 and *((op as i64 + 1) as *const u8) == 45: return 8 // -- = UO_PRE_DEC
    // Postfix operator
    var range_end_off: u32 = 0
    var range_end_file: *mut u8 = 0 as *mut u8
    source_location_expansion_offset(clang_getRangeEnd(range), &raw mut range_end_file, &raw mut range_end_off)
    if range_end_file as i64 == 0 or clang_File_isEqual(op_file, range_end_file) == 0:
        return -1
    if range_end_off > child_end_off:
        var op2 = (contents as i64 + child_end_off as i64) as *const u8
        var len2 = range_end_off - child_end_off
        while len2 > 0 and (*op2 == 32 or *op2 == 9):
            op2 = (op2 as i64 + 1) as *const u8
            len2 = len2 - 1
        if len2 >= 2 and *op2 == 43 and *((op2 as i64 + 1) as *const u8) == 43: return 9  // x++ = UO_POST_INC
        if len2 >= 2 and *op2 == 45 and *((op2 as i64 + 1) as *const u8) == 45: return 10 // x-- = UO_POST_DEC
    // Fallback: use clang_getCursorUnaryOperatorKind for macro expansions
    let cx_uop = clang_getCursorUnaryOperatorKind(cursor)
    if cx_uop == 1: return 9   // CXUnaryOperator_PostInc → UO_POST_INC
    if cx_uop == 2: return 10  // CXUnaryOperator_PostDec → UO_POST_DEC
    if cx_uop == 3: return 7   // CXUnaryOperator_PreInc → UO_PRE_INC
    if cx_uop == 4: return 8   // CXUnaryOperator_PreDec → UO_PRE_DEC
    if cx_uop == 5: return 4   // CXUnaryOperator_AddrOf → UO_ADDR
    if cx_uop == 6: return 5   // CXUnaryOperator_Deref → UO_DEREF
    if cx_uop == 7: return 6   // CXUnaryOperator_Plus → UO_PLUS
    if cx_uop == 8: return 1   // CXUnaryOperator_Minus → UO_MINUS
    if cx_uop == 9: return 2   // CXUnaryOperator_Not → UO_NOT (bitwise ~)
    if cx_uop == 10: return 3  // CXUnaryOperator_LNot → UO_LNOT (logical !)
    -1

// ── Implicit cast kind ──────────────────────────────────────

// Cast kind constants matching the C version
let CIC_NOOP: i32 = 0
let CIC_NULL_TO_PTR: i32 = 2
let CIC_BOOL_TO_INT: i32 = 3
let CIC_INT_TO_BOOL: i32 = 5
let CIC_PTR_TO_BOOL: i32 = 7
let CIC_INT_TO_FLOAT: i32 = 9
let CIC_FLOAT_TO_INT: i32 = 10
let CIC_TO_VOID: i32 = 15
let CIC_INT_TRUNC: i32 = 16
let CIC_INT_WIDEN: i32 = 17
let CIC_ARRAY_TO_PTR: i32 = 20
let CIC_INT_TO_PTR: i32 = 21
let CIC_PTR_TO_INT: i32 = 22
let CIC_PTR_CAST: i32 = 23
let CIC_FLOAT_CAST: i32 = 24
let CIC_FLOAT_TO_BOOL: i32 = 25
let CIC_BOOL_TO_FLOAT: i32 = 26
let CIC_BITCAST: i32 = 28
let CIC_INT_WIDEN_SIGN: i32 = 29

unsafe fn is_int_kind(k: i32) -> i32:
    if k >= CXType_Char_U and k <= CXType_UInt128: return 1
    if k >= CXType_Char_S and k <= CXType_Int128: return 1
    0

unsafe fn is_float_kind(k: i32) -> i32:
    if k == CXType_Float or k == CXType_Double or k == CXType_LongDouble: return 1
    0

unsafe fn is_unsigned_kind(k: i32) -> i32:
    if k >= CXType_Char_U and k <= CXType_UInt128: return 1
    0

@[c_export("with_ci_implicit_cast_kind")]
pub unsafe fn ci_implicit_cast_kind(session: i64, cursor_idx: i32) -> i32:
    let s = session as *mut CImportSession
    if s as i64 == 0 or cursor_idx < 0 or cursor_idx >= (*s).cursor_count: return CIC_NOOP
    let cursor = *(((*s).cursors as i64 + cursor_idx as i64 * 32) as *const CXCursor)
    let dest_type = clang_getCursorType(cursor)
    let dest_canon = clang_getCanonicalType(dest_type)
    ensure_children_cached(s, cursor_idx)
    if cursor_idx >= (*s).children_cache_cap: return CIC_NOOP
    let child_count = *(((*s).child_counts as i64 + cursor_idx as i64 * 4) as *const i32)
    if child_count < 1: return CIC_NOOP
    let child_idx = *(((*s).child_indices as i64 + (*(((*s).child_starts as i64 + cursor_idx as i64 * 4) as *const i32)) as i64 * 4) as *const i32)
    let child_cursor = *(((*s).cursors as i64 + child_idx as i64 * 32) as *const CXCursor)
    let src_type = clang_getCursorType(child_cursor)
    let src_canon = clang_getCanonicalType(src_type)
    let dk = dest_canon.kind
    let sk = src_canon.kind
    if dk == CXType_Void: return CIC_TO_VOID
    if dk == CXType_Pointer and sk == CXType_Int:
        if clang_getCursorKind(child_cursor) == 106:  // CXCursor_IntegerLiteral
            return CIC_NULL_TO_PTR
    if sk == CXType_Bool:
        if is_int_kind(dk) != 0: return CIC_BOOL_TO_INT
    if dk == CXType_Bool:
        if is_int_kind(sk) != 0: return CIC_INT_TO_BOOL
        if sk == CXType_Enum: return CIC_INT_TO_BOOL
        if sk == CXType_Pointer: return CIC_PTR_TO_BOOL
    if dk == CXType_Bool and sk == CXType_Pointer: return CIC_PTR_TO_BOOL
    let src_int = is_int_kind(sk)
    let dest_float = is_float_kind(dk)
    if src_int != 0 and dest_float != 0: return CIC_INT_TO_FLOAT
    let src_float = is_float_kind(sk)
    let dest_int = is_int_kind(dk)
    if src_float != 0 and dest_int != 0: return CIC_FLOAT_TO_INT
    if dk == CXType_Bool and src_float != 0: return CIC_FLOAT_TO_BOOL
    if sk == CXType_Bool and dest_float != 0: return CIC_BOOL_TO_FLOAT
    if src_float != 0 and dest_float != 0 and sk != dk: return CIC_FLOAT_CAST
    if dk == CXType_Pointer and (sk == CXType_ConstantArray or sk == CXType_IncompleteArray): return CIC_ARRAY_TO_PTR
    if dk == CXType_Pointer and src_int != 0: return CIC_INT_TO_PTR
    if sk == CXType_Pointer and dest_int != 0: return CIC_PTR_TO_INT
    if sk == CXType_Pointer and dk == CXType_Pointer: return CIC_PTR_CAST
    if src_int != 0 and dest_int != 0:
        let src_sz = clang_Type_getSizeOf(src_canon)
        let dest_sz = clang_Type_getSizeOf(dest_canon)
        if dest_sz < src_sz: return CIC_INT_TRUNC
        if dest_sz > src_sz:
            if is_unsigned_kind(sk) != is_unsigned_kind(dk): return CIC_INT_WIDEN_SIGN
            return CIC_INT_WIDEN
    if sk != dk:
        let src_sz = clang_Type_getSizeOf(src_canon)
        let dest_sz = clang_Type_getSizeOf(dest_canon)
        if src_sz > 0 and src_sz == dest_sz: return CIC_BITCAST
    CIC_NOOP

// ── Anonymous struct field enumeration (simplified stubs) ────

@[c_export("with_cimport_struct_field_anon_field_count")]
pub unsafe fn cimport_struct_field_anon_field_count(session: i64, idx: i32, field: i32) -> i32:
    // TODO: implement full anonymous record field enumeration
    0

@[c_export("with_cimport_struct_field_anon_field_name")]
pub unsafe fn cimport_struct_field_anon_field_name(session: i64, idx: i32, field: i32, sub_field: i32) -> str:
    ""

@[c_export("with_cimport_struct_field_anon_field_type")]
pub unsafe fn cimport_struct_field_anon_field_type(session: i64, idx: i32, field: i32, sub_field: i32) -> str:
    ""

@[c_export("with_cimport_typedef_anon_field_name")]
pub unsafe fn cimport_typedef_anon_field_name(session: i64, idx: i32, field: i32) -> str:
    ""

@[c_export("with_cimport_typedef_anon_field_type")]
pub unsafe fn cimport_typedef_anon_field_type(session: i64, idx: i32, field: i32) -> str:
    ""

@[c_export("with_cimport_typedef_anon_field_is_bitfield")]
pub unsafe fn cimport_typedef_anon_field_is_bitfield(session: i64, idx: i32, field: i32) -> i32:
    0
