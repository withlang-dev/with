// LLVM-C API bridge for the With self-hosted compiler.
// Provides wl_* prefix functions that accept With-compatible types
// (i64 for opaque handles, with_str for strings).
//
// All LLVM opaque references (LLVMValueRef, LLVMTypeRef, etc.) are
// passed as int64_t and cast via intptr_t macros below.

#include <llvm-c/Core.h>
#include <llvm-c/Target.h>
#include <llvm-c/TargetMachine.h>
#include <llvm-c/Analysis.h>
#include <llvm-c/Transforms/PassBuilder.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>

typedef struct { const char *ptr; int64_t len; } with_str;
typedef struct { void *ptr; int64_t len; int64_t cap; int64_t elem_size; } with_vec;

// ── Cast macros ────────────────────────────────────────────
#define P2I(p)  ((int64_t)(intptr_t)(p))
#define V(i)    ((LLVMValueRef)(intptr_t)(i))
#define T(i)    ((LLVMTypeRef)(intptr_t)(i))
#define M(i)    ((LLVMModuleRef)(intptr_t)(i))
#define C(i)    ((LLVMContextRef)(intptr_t)(i))
#define B(i)    ((LLVMBuilderRef)(intptr_t)(i))
#define TM(i)   ((LLVMTargetMachineRef)(intptr_t)(i))
#define BB(i)   ((LLVMBasicBlockRef)(intptr_t)(i))

// Rotating null-terminated string buffers (4 slots for nested calls).
static char _cstr_bufs[4][4096];
static int _cstr_idx = 0;
static const char* to_cstr(with_str s) {
    _cstr_idx = (_cstr_idx + 1) & 3;
    int64_t n = s.len < 4095 ? s.len : 4095;
    memcpy(_cstr_bufs[_cstr_idx], s.ptr, (size_t)n);
    _cstr_bufs[_cstr_idx][n] = 0;
    return _cstr_bufs[_cstr_idx];
}

// ── Lifecycle ──────────────────────────────────────────────
int64_t wl_context_create(void) { return P2I(LLVMContextCreate()); }
void    wl_context_dispose(int64_t c) { LLVMContextDispose(C(c)); }
int64_t wl_module_create(with_str name, int64_t ctx) {
    return P2I(LLVMModuleCreateWithNameInContext(to_cstr(name), C(ctx)));
}
void    wl_module_dispose(int64_t m) { LLVMDisposeModule(M(m)); }
int64_t wl_builder_create(int64_t ctx) { return P2I(LLVMCreateBuilderInContext(C(ctx))); }
void    wl_builder_dispose(int64_t b) { LLVMDisposeBuilder(B(b)); }

// ── Target initialization ──────────────────────────────────
int32_t wl_init_native_target(void) { return LLVMInitializeNativeTarget(); }
int32_t wl_init_native_asm_printer(void) { return LLVMInitializeNativeAsmPrinter(); }

// Combined: init target machine + set module triple/layout. Returns TM or 0.
static LLVMCodeGenOptLevel with_codegen_level(int32_t level) {
    switch (level) {
        case 0: return LLVMCodeGenLevelNone;
        case 1: return LLVMCodeGenLevelLess;
        case 3: return LLVMCodeGenLevelAggressive;
        default: return LLVMCodeGenLevelDefault;
    }
}

int64_t wl_init_target_machine(int64_t module, int32_t level) {
    char *triple = LLVMGetDefaultTargetTriple();
    LLVMTargetRef target;
    char *err = NULL;
    if (LLVMGetTargetFromTriple(triple, &target, &err) != 0) {
        if (err) LLVMDisposeMessage(err);
        LLVMDisposeMessage(triple);
        return 0;
    }
    LLVMTargetMachineRef tm = LLVMCreateTargetMachine(
        target, triple, "generic", "",
        with_codegen_level(level), LLVMRelocDefault, LLVMCodeModelDefault);
    LLVMTargetDataRef layout = LLVMCreateTargetDataLayout(tm);
    LLVMSetModuleDataLayout(M(module), layout);
    char *triple2 = LLVMGetDefaultTargetTriple();
    LLVMSetTarget(M(module), triple2);
    LLVMDisposeMessage(triple2);
    LLVMDisposeTargetData(layout);
    LLVMDisposeMessage(triple);
    return P2I(tm);
}
void wl_dispose_target_machine(int64_t tm) { LLVMDisposeTargetMachine(TM(tm)); }

// ── Types ──────────────────────────────────────────────────
int64_t wl_i1_type(int64_t c)   { return P2I(LLVMInt1TypeInContext(C(c))); }
int64_t wl_i8_type(int64_t c)   { return P2I(LLVMInt8TypeInContext(C(c))); }
int64_t wl_i16_type(int64_t c)  { return P2I(LLVMInt16TypeInContext(C(c))); }
int64_t wl_i32_type(int64_t c)  { return P2I(LLVMInt32TypeInContext(C(c))); }
int64_t wl_i64_type(int64_t c)  { return P2I(LLVMInt64TypeInContext(C(c))); }
int64_t wl_f32_type(int64_t c)  { return P2I(LLVMFloatTypeInContext(C(c))); }
int64_t wl_f64_type(int64_t c)  { return P2I(LLVMDoubleTypeInContext(C(c))); }
int64_t wl_void_type(int64_t c) { return P2I(LLVMVoidTypeInContext(C(c))); }
int64_t wl_ptr_type(int64_t c)  { return P2I(LLVMPointerTypeInContext(C(c), 0)); }
int64_t wl_array_type(int64_t elem, int64_t size) {
    return P2I(LLVMArrayType2(T(elem), (uint64_t)size));
}

int64_t wl_function_type(int64_t ret, int64_t params_ptr, int32_t count, int32_t is_vararg) {
    return P2I(LLVMFunctionType(T(ret),
        count > 0 ? (LLVMTypeRef*)(intptr_t)params_ptr : NULL,
        (unsigned)count, is_vararg));
}

int64_t wl_struct_type(int64_t ctx, int64_t elems_ptr, int32_t count, int32_t packed) {
    return P2I(LLVMStructTypeInContext(C(ctx),
        (LLVMTypeRef*)(intptr_t)elems_ptr, (unsigned)count, packed));
}

int64_t wl_struct_create_named(int64_t ctx, with_str name) {
    return P2I(LLVMStructCreateNamed(C(ctx), to_cstr(name)));
}

void wl_struct_set_body(int64_t ty, int64_t elems_ptr, int32_t count, int32_t packed) {
    LLVMStructSetBody(T(ty), (LLVMTypeRef*)(intptr_t)elems_ptr, (unsigned)count, packed);
}

// Convenience: set struct body with exactly 2 element types (avoids Vec ABI issues).
void wl_struct_set_body_2(int64_t ty, int64_t t0, int64_t t1, int32_t packed) {
    LLVMTypeRef elems[2] = { T(t0), T(t1) };
    LLVMStructSetBody(T(ty), elems, 2, packed);
}

int64_t wl_struct_get_type_at(int64_t ty, int32_t idx) {
    return P2I(LLVMStructGetTypeAtIndex(T(ty), (unsigned)idx));
}

int32_t wl_count_struct_elem_types(int64_t ty) {
    return (int32_t)LLVMCountStructElementTypes(T(ty));
}

int64_t wl_get_element_type(int64_t ty) { return P2I(LLVMGetElementType(T(ty))); }
int64_t wl_get_array_length(int64_t ty) { return (int64_t)LLVMGetArrayLength2(T(ty)); }

// ── Type queries ───────────────────────────────────────────
int64_t wl_type_of(int64_t v)           { return P2I(LLVMTypeOf(V(v))); }
int32_t wl_get_type_kind(int64_t ty)    { return (int32_t)LLVMGetTypeKind(T(ty)); }
int64_t wl_get_return_type(int64_t ft)  { return P2I(LLVMGetReturnType(T(ft))); }
int32_t wl_count_params(int64_t fn)     { return (int32_t)LLVMCountParams(V(fn)); }
int32_t wl_count_param_types(int64_t ft){ return (int32_t)LLVMCountParamTypes(T(ft)); }
int64_t wl_get_param(int64_t fn, int32_t i) { return P2I(LLVMGetParam(V(fn), (unsigned)i)); }
int32_t wl_get_int_type_width(int64_t ty) { return (int32_t)LLVMGetIntTypeWidth(T(ty)); }
int32_t wl_is_fn_var_arg(int64_t ft)    { return LLVMIsFunctionVarArg(T(ft)); }
int64_t wl_global_get_value_type(int64_t v) { return P2I(LLVMGlobalGetValueType(V(v))); }
int64_t wl_get_allocated_type(int64_t v) { return P2I(LLVMGetAllocatedType(V(v))); }

// Type kind constants
int32_t wl_void_type_kind(void)     { return LLVMVoidTypeKind; }
int32_t wl_float_type_kind(void)    { return LLVMFloatTypeKind; }
int32_t wl_double_type_kind(void)   { return LLVMDoubleTypeKind; }
int32_t wl_integer_type_kind(void)  { return LLVMIntegerTypeKind; }
int32_t wl_function_type_kind(void) { return LLVMFunctionTypeKind; }
int32_t wl_struct_type_kind(void)   { return LLVMStructTypeKind; }
int32_t wl_array_type_kind(void)    { return LLVMArrayTypeKind; }
int32_t wl_pointer_type_kind(void)  { return LLVMPointerTypeKind; }
int32_t wl_function_value_kind(void){ return LLVMFunctionValueKind; }

// ── Constants ──────────────────────────────────────────────
int64_t wl_const_int(int64_t ty, int64_t val, int32_t sign_ext) {
    return P2I(LLVMConstInt(T(ty), (unsigned long long)val, sign_ext));
}
int64_t wl_const_real(int64_t ty, double val) {
    return P2I(LLVMConstReal(T(ty), val));
}
int64_t wl_const_null(int64_t ty)  { return P2I(LLVMConstNull(T(ty))); }
int64_t wl_get_undef(int64_t ty)   { return P2I(LLVMGetUndef(T(ty))); }
int64_t wl_const_string(int64_t ctx, with_str s, int32_t dont_null) {
    return P2I(LLVMConstStringInContext(C(ctx), s.ptr, (unsigned)s.len, dont_null));
}
int64_t wl_const_struct(int64_t ctx, int64_t vals_ptr, int32_t count, int32_t packed) {
    return P2I(LLVMConstStructInContext(C(ctx),
        (LLVMValueRef*)(intptr_t)vals_ptr, (unsigned)count, packed));
}
int64_t wl_const_named_struct(int64_t ty, int64_t vals_ptr, int32_t count) {
    return P2I(LLVMConstNamedStruct(T(ty),
        (LLVMValueRef*)(intptr_t)vals_ptr, (unsigned)count));
}
int64_t wl_const_bitcast(int64_t val, int64_t ty) {
    return P2I(LLVMConstBitCast(V(val), T(ty)));
}
int64_t wl_const_int_sext_val(int64_t v) { return LLVMConstIntGetSExtValue(V(v)); }
int32_t wl_is_constant(int64_t v)  { return LLVMIsConstant(V(v)); }
int64_t wl_size_of(int64_t ty)     { return P2I(LLVMSizeOf(T(ty))); }

// ── ICmp predicates ────────────────────────────────────────
int32_t wl_int_eq(void)  { return LLVMIntEQ; }
int32_t wl_int_ne(void)  { return LLVMIntNE; }
int32_t wl_int_slt(void) { return LLVMIntSLT; }
int32_t wl_int_sgt(void) { return LLVMIntSGT; }
int32_t wl_int_sle(void) { return LLVMIntSLE; }
int32_t wl_int_sge(void) { return LLVMIntSGE; }
int32_t wl_int_ult(void) { return LLVMIntULT; }
int32_t wl_int_ule(void) { return LLVMIntULE; }
int32_t wl_int_uge(void) { return LLVMIntUGE; }

// ── FCmp predicates ────────────────────────────────────────
int32_t wl_real_oeq(void) { return LLVMRealOEQ; }
int32_t wl_real_one(void) { return LLVMRealONE; }
int32_t wl_real_olt(void) { return LLVMRealOLT; }
int32_t wl_real_ogt(void) { return LLVMRealOGT; }
int32_t wl_real_ole(void) { return LLVMRealOLE; }
int32_t wl_real_oge(void) { return LLVMRealOGE; }

// ── Functions ──────────────────────────────────────────────
int64_t wl_add_function(int64_t m, with_str name, int64_t fn_type) {
    return P2I(LLVMAddFunction(M(m), to_cstr(name), T(fn_type)));
}
int64_t wl_get_named_function(int64_t m, with_str name) {
    return P2I(LLVMGetNamedFunction(M(m), to_cstr(name)));
}
int64_t wl_get_named_global(int64_t m, with_str name) {
    return P2I(LLVMGetNamedGlobal(M(m), to_cstr(name)));
}
int64_t wl_get_first_function(int64_t m) { return P2I(LLVMGetFirstFunction(M(m))); }
int64_t wl_get_next_function(int64_t v)  { return P2I(LLVMGetNextFunction(V(v))); }
int32_t wl_is_declaration(int64_t v)     { return LLVMIsDeclaration(V(v)); }

void wl_add_fn_attr(int64_t ctx, int64_t fn, with_str attr_name) {
    const char *name = to_cstr(attr_name);
    unsigned kind = LLVMGetEnumAttributeKindForName(name, strlen(name));
    if (kind) {
        LLVMAttributeRef attr = LLVMCreateEnumAttribute(C(ctx), kind, 0);
        LLVMAddAttributeAtIndex(V(fn), (LLVMAttributeIndex)-1, attr);
    }
}

// ── Basic blocks ───────────────────────────────────────────
int64_t wl_append_bb(int64_t ctx, int64_t fn, with_str name) {
    return P2I(LLVMAppendBasicBlockInContext(C(ctx), V(fn), to_cstr(name)));
}
void wl_position_at_end(int64_t b, int64_t bb) {
    LLVMPositionBuilderAtEnd(B(b), BB(bb));
}
void wl_position_before(int64_t b, int64_t instr) {
    LLVMPositionBuilderBefore(B(b), V(instr));
}
int64_t wl_get_insert_block(int64_t b)    { return P2I(LLVMGetInsertBlock(B(b))); }
int64_t wl_get_bb_terminator(int64_t bb)  { return P2I(LLVMGetBasicBlockTerminator(BB(bb))); }
int64_t wl_get_entry_bb(int64_t fn)       { return P2I(LLVMGetEntryBasicBlock(V(fn))); }
int64_t wl_get_first_instr(int64_t bb)    { return P2I(LLVMGetFirstInstruction(BB(bb))); }
int64_t wl_bb_as_value(int64_t bb)        { return P2I(LLVMBasicBlockAsValue(BB(bb))); }

// ── Builder: binary arithmetic ─────────────────────────────
#define WL_BINOP(name, fn) \
    int64_t wl_ ## name(int64_t b, int64_t l, int64_t r) { \
        return P2I(fn(B(b), V(l), V(r), "")); \
    }

WL_BINOP(build_add, LLVMBuildAdd)
WL_BINOP(build_sub, LLVMBuildSub)
WL_BINOP(build_mul, LLVMBuildMul)
WL_BINOP(build_sdiv, LLVMBuildSDiv)
WL_BINOP(build_srem, LLVMBuildSRem)
WL_BINOP(build_udiv, LLVMBuildUDiv)
WL_BINOP(build_urem, LLVMBuildURem)
WL_BINOP(build_fadd, LLVMBuildFAdd)
WL_BINOP(build_fsub, LLVMBuildFSub)
WL_BINOP(build_fmul, LLVMBuildFMul)
WL_BINOP(build_fdiv, LLVMBuildFDiv)
WL_BINOP(build_frem, LLVMBuildFRem)
WL_BINOP(build_and, LLVMBuildAnd)
WL_BINOP(build_or, LLVMBuildOr)
WL_BINOP(build_xor, LLVMBuildXor)
WL_BINOP(build_shl, LLVMBuildShl)
WL_BINOP(build_ashr, LLVMBuildAShr)

// ── Builder: unary ─────────────────────────────────────────
#define WL_UNOP(name, fn) \
    int64_t wl_ ## name(int64_t b, int64_t v) { \
        return P2I(fn(B(b), V(v), "")); \
    }

WL_UNOP(build_neg, LLVMBuildNeg)
WL_UNOP(build_not, LLVMBuildNot)
WL_UNOP(build_fneg, LLVMBuildFNeg)

// ── Builder: comparison ────────────────────────────────────
int64_t wl_build_icmp(int64_t b, int32_t pred, int64_t l, int64_t r) {
    return P2I(LLVMBuildICmp(B(b), (LLVMIntPredicate)pred, V(l), V(r), ""));
}
int64_t wl_build_fcmp(int64_t b, int32_t pred, int64_t l, int64_t r) {
    return P2I(LLVMBuildFCmp(B(b), (LLVMRealPredicate)pred, V(l), V(r), ""));
}

// ── Builder: memory ────────────────────────────────────────
int64_t wl_build_alloca(int64_t b, int64_t ty) {
    return P2I(LLVMBuildAlloca(B(b), T(ty), ""));
}
int64_t wl_build_alloca_named(int64_t b, int64_t ty, with_str name) {
    return P2I(LLVMBuildAlloca(B(b), T(ty), to_cstr(name)));
}
int64_t wl_build_load(int64_t b, int64_t ty, int64_t ptr) {
    return P2I(LLVMBuildLoad2(B(b), T(ty), V(ptr), ""));
}
int64_t wl_build_store(int64_t b, int64_t val, int64_t ptr) {
    return P2I(LLVMBuildStore(B(b), V(val), V(ptr)));
}
int64_t wl_build_gep(int64_t b, int64_t ty, int64_t ptr, int64_t idx_ptr, int32_t cnt) {
    return P2I(LLVMBuildGEP2(B(b), T(ty), V(ptr),
        (LLVMValueRef*)(intptr_t)idx_ptr, (unsigned)cnt, ""));
}
int64_t wl_build_struct_gep(int64_t b, int64_t ty, int64_t ptr, int32_t idx) {
    return P2I(LLVMBuildStructGEP2(B(b), T(ty), V(ptr), (unsigned)idx, ""));
}
int64_t wl_build_global_string_ptr(int64_t b, with_str s) {
    return P2I(LLVMBuildGlobalStringPtr(B(b), to_cstr(s), ""));
}

// ── Builder: globals ───────────────────────────────────────
int64_t wl_add_global(int64_t m, int64_t ty, with_str name) {
    return P2I(LLVMAddGlobal(M(m), T(ty), to_cstr(name)));
}
void wl_set_initializer(int64_t g, int64_t v)          { LLVMSetInitializer(V(g), V(v)); }
void wl_set_global_constant(int64_t g, int32_t c)      { LLVMSetGlobalConstant(V(g), c); }
void wl_set_linkage(int64_t g, int32_t link)            { LLVMSetLinkage(V(g), (LLVMLinkage)link); }
int32_t wl_internal_linkage(void) { return LLVMInternalLinkage; }
int32_t wl_private_linkage(void)  { return LLVMPrivateLinkage; }

// ── Builder: control flow ──────────────────────────────────
int64_t wl_build_br(int64_t b, int64_t bb) {
    return P2I(LLVMBuildBr(B(b), BB(bb)));
}
int64_t wl_build_cond_br(int64_t b, int64_t cond, int64_t then_bb, int64_t else_bb) {
    return P2I(LLVMBuildCondBr(B(b), V(cond), BB(then_bb), BB(else_bb)));
}
int64_t wl_build_ret(int64_t b, int64_t val) {
    return P2I(LLVMBuildRet(B(b), V(val)));
}
int64_t wl_build_ret_void(int64_t b) {
    return P2I(LLVMBuildRetVoid(B(b)));
}
int64_t wl_build_unreachable(int64_t b) {
    return P2I(LLVMBuildUnreachable(B(b)));
}
int64_t wl_build_switch(int64_t b, int64_t val, int64_t else_bb, int32_t n) {
    return P2I(LLVMBuildSwitch(B(b), V(val), BB(else_bb), (unsigned)n));
}
void wl_add_case(int64_t sw, int64_t val, int64_t bb) {
    LLVMAddCase(V(sw), V(val), BB(bb));
}

// ── Builder: cast ──────────────────────────────────────────
#define WL_CAST(name, fn) \
    int64_t wl_ ## name(int64_t b, int64_t v, int64_t ty) { \
        return P2I(fn(B(b), V(v), T(ty), "")); \
    }

WL_CAST(build_zext, LLVMBuildZExt)
WL_CAST(build_sext, LLVMBuildSExt)
WL_CAST(build_trunc, LLVMBuildTrunc)
WL_CAST(build_si_to_fp, LLVMBuildSIToFP)
WL_CAST(build_fp_to_si, LLVMBuildFPToSI)
WL_CAST(build_bitcast, LLVMBuildBitCast)
WL_CAST(build_int_to_ptr, LLVMBuildIntToPtr)
WL_CAST(build_ptr_to_int, LLVMBuildPtrToInt)
WL_CAST(build_fp_cast, LLVMBuildFPCast)
WL_CAST(build_fp_ext, LLVMBuildFPExt)

// ── Builder: phi / select / extract / insert ───────────────
int64_t wl_build_phi(int64_t b, int64_t ty) {
    return P2I(LLVMBuildPhi(B(b), T(ty), ""));
}
void wl_add_incoming(int64_t phi, int64_t vals_ptr, int64_t bbs_ptr, int32_t count) {
    LLVMAddIncoming(V(phi),
        (LLVMValueRef*)(intptr_t)vals_ptr,
        (LLVMBasicBlockRef*)(intptr_t)bbs_ptr,
        (unsigned)count);
}
int64_t wl_build_select(int64_t b, int64_t cond, int64_t then_v, int64_t else_v) {
    return P2I(LLVMBuildSelect(B(b), V(cond), V(then_v), V(else_v), ""));
}
int64_t wl_build_extract_value(int64_t b, int64_t agg, int32_t idx) {
    return P2I(LLVMBuildExtractValue(B(b), V(agg), (unsigned)idx, ""));
}
int64_t wl_build_insert_value(int64_t b, int64_t agg, int64_t val, int32_t idx) {
    return P2I(LLVMBuildInsertValue(B(b), V(agg), V(val), (unsigned)idx, ""));
}

// ── Builder: call ──────────────────────────────────────────
int64_t wl_build_call(int64_t b, int64_t fn_ty, int64_t fn, int64_t args_ptr, int32_t cnt) {
    return P2I(LLVMBuildCall2(B(b), T(fn_ty), V(fn),
        cnt > 0 ? (LLVMValueRef*)(intptr_t)args_ptr : NULL,
        (unsigned)cnt, ""));
}

// ── Misc builder / value ops ───────────────────────────────
void wl_instruction_erase(int64_t v)    { LLVMInstructionEraseFromParent(V(v)); }
int32_t wl_get_value_kind(int64_t v)    { return (int32_t)LLVMGetValueKind(V(v)); }
int64_t wl_get_first_use(int64_t v)     { return P2I(LLVMGetFirstUse(V(v))); }
void wl_set_value_name(int64_t v, with_str name) {
    LLVMSetValueName2(V(v), name.ptr, (size_t)name.len);
}

// ── Intrinsics ─────────────────────────────────────────────
int32_t wl_lookup_intrinsic_id(with_str name) {
    return (int32_t)LLVMLookupIntrinsicID(name.ptr, (size_t)name.len);
}
int64_t wl_get_intrinsic_decl(int64_t m, int32_t id, int64_t tys_ptr, int32_t cnt) {
    return P2I(LLVMGetIntrinsicDeclaration(M(m), (unsigned)id,
        (LLVMTypeRef*)(intptr_t)tys_ptr, (size_t)cnt));
}
int64_t wl_intrinsic_get_type(int64_t ctx, int32_t id, int64_t tys_ptr, int32_t cnt) {
    return P2I(LLVMIntrinsicGetType(C(ctx), (unsigned)id,
        (LLVMTypeRef*)(intptr_t)tys_ptr, (size_t)cnt));
}

// ── Data layout queries ────────────────────────────────────
int64_t wl_get_module_data_layout(int64_t m) {
    return P2I(LLVMGetModuleDataLayout(M(m)));
}
int64_t wl_abi_size_of(int64_t dl, int64_t ty) {
    if (dl == 0 || ty == 0) {
        return 0;
    }
    return (int64_t)LLVMABISizeOfType((LLVMTargetDataRef)(intptr_t)dl, T(ty));
}
int32_t wl_abi_align_of(int64_t dl, int64_t ty) {
    if (dl == 0 || ty == 0) {
        return 1;
    }
    return (int32_t)LLVMABIAlignmentOfType((LLVMTargetDataRef)(intptr_t)dl, T(ty));
}

// ── Struct name ────────────────────────────────────────────
with_str wl_get_struct_name(int64_t ty) {
    const char *name = LLVMGetStructName(T(ty));
    if (!name) { with_str e = { "", 0 }; return e; }
    with_str r = { name, (int64_t)strlen(name) };
    return r;
}

// ── Param types ────────────────────────────────────────────
void wl_get_param_types(int64_t fn_ty, int64_t out_ptr) {
    LLVMGetParamTypes(T(fn_ty), (LLVMTypeRef*)(intptr_t)out_ptr);
}

// ── Module verification / emission ─────────────────────────
int32_t wl_verify_module(int64_t m) {
    char *err = NULL;
    int result = LLVMVerifyModule(M(m), LLVMReturnStatusAction, &err);
    if (err) {
        if (result != 0) fprintf(stderr, "LLVM verify error: %s\n", err);
        LLVMDisposeMessage(err);
    }
    if (result != 0) {
        LLVMValueRef fn = LLVMGetFirstFunction(M(m));
        while (fn) {
            if (!LLVMIsDeclaration(fn) &&
                LLVMVerifyFunction(fn, LLVMReturnStatusAction) != 0) {
                size_t len;
                const char *name = LLVMGetValueName2(fn, &len);
                fprintf(stderr, "LLVM verify function: %.*s\n", (int)len, name);
                break;
            }
            fn = LLVMGetNextFunction(fn);
        }
    }
    return result;
}

int32_t wl_emit_object(int64_t tm, int64_t m, with_str path) {
    char path_buf[4096];
    int64_t n = path.len < 4095 ? path.len : 4095;
    memcpy(path_buf, path.ptr, (size_t)n);
    path_buf[n] = 0;
    char *err = NULL;
    int result = LLVMTargetMachineEmitToFile(TM(tm), M(m), path_buf, LLVMObjectFile, &err);
    if (result != 0 && err) {
        fprintf(stderr, "LLVM emit error: %s\n", err);
        LLVMDisposeMessage(err);
    }
    return result;
}

void wl_optimize(int64_t m, int64_t tm, int32_t level) {
    const char *passes;
    switch (level) {
        case 0: passes = "default<O0>"; break;
        case 1: passes = "default<O1>"; break;
        case 3: passes = "default<O3>"; break;
        default: passes = "default<O2>"; break;
    }
    LLVMPassBuilderOptionsRef opts = LLVMCreatePassBuilderOptions();
    LLVMErrorRef err = LLVMRunPasses(M(m), passes, TM(tm), opts);
    if (err) {
        char *msg = LLVMGetErrorMessage(err);
        if (msg) LLVMDisposeErrorMessage(msg);
    }
    LLVMDisposePassBuilderOptions(opts);
}

void wl_print_ir(int64_t m) {
    char *ir = LLVMPrintModuleToString(M(m));
    if (ir) {
        fprintf(stdout, "%s", ir);
        fflush(stdout);
        LLVMDisposeMessage(ir);
    }
}

// ── Vec data pointer helper ────────────────────────────────
int64_t wl_vec_data(with_vec v) {
    return (int64_t)(intptr_t)v.ptr;
}

// Pointer-based variant to avoid large-by-value Vec ABI issues.
int64_t wl_vec_data_ptr(with_vec *v) {
    if (!v) return 0;
    return (int64_t)(intptr_t)v->ptr;
}

// ── Entry alloca helper ────────────────────────────────────
// Creates an alloca in the function's entry block (dominates all uses).
int64_t wl_create_entry_alloca(int64_t builder, int64_t fn, int64_t ty) {
    LLVMBasicBlockRef entry = LLVMGetEntryBasicBlock(V(fn));
    LLVMValueRef first = LLVMGetFirstInstruction(entry);
    LLVMBasicBlockRef saved = LLVMGetInsertBlock(B(builder));
    if (first) {
        LLVMPositionBuilderBefore(B(builder), first);
    } else {
        LLVMPositionBuilderAtEnd(B(builder), entry);
    }
    LLVMValueRef alloca = LLVMBuildAlloca(B(builder), T(ty), "");
    LLVMPositionBuilderAtEnd(B(builder), saved);
    return P2I(alloca);
}
