// compiler/LlvmBridge.w — LLVM-C API bridge, written in With.
//
// Provides wl_* prefix functions that accept With-compatible types
// (i64 for opaque handles, with_str for strings).
// All LLVM opaque references passed as i64 and cast via `as *mut u8`.
//
// No C headers needed — all LLVM-C functions declared as extern fn.
// Enum constants hardcoded from LLVM 22 headers (stable C API contract).

// ── Runtime helpers (from rt_core.w) ────────────────────────────
extern fn rt_write(fd: i32, buf: *const u8, len: u64) -> i64
extern fn with_memcpy(dst: *mut u8, src: *const u8, len: i64) -> Unit
extern fn with_nanosleep(ns: i64) -> i32
extern fn pthread_self() -> i64
extern fn abort() -> Unit

// ── LLVM enum constants ─────────────────────────────────────────
let LLVM_CodeGenLevelNone: i32 = 0
let LLVM_CodeGenLevelLess: i32 = 1
let LLVM_CodeGenLevelDefault: i32 = 2
let LLVM_CodeGenLevelAggressive: i32 = 3
let LLVM_RelocDefault: i32 = 0
let LLVM_CodeModelDefault: i32 = 0
let LLVM_VoidTypeKind: i32 = 0
let LLVM_FloatTypeKind: i32 = 2
let LLVM_DoubleTypeKind: i32 = 3
let LLVM_IntegerTypeKind: i32 = 8
let LLVM_FunctionTypeKind: i32 = 9
let LLVM_StructTypeKind: i32 = 10
let LLVM_ArrayTypeKind: i32 = 11
let LLVM_PointerTypeKind: i32 = 12
let LLVM_FunctionValueKind: i32 = 5
let LLVM_GlobalAliasValueKind: i32 = 6
let LLVM_GlobalIFuncValueKind: i32 = 7
let LLVM_GlobalVariableValueKind: i32 = 8
let LLVM_IntEQ: i32 = 32
let LLVM_IntNE: i32 = 33
let LLVM_IntUGT: i32 = 34
let LLVM_IntUGE: i32 = 35
let LLVM_IntULT: i32 = 36
let LLVM_IntULE: i32 = 37
let LLVM_IntSGT: i32 = 38
let LLVM_IntSGE: i32 = 39
let LLVM_IntSLT: i32 = 40
let LLVM_IntSLE: i32 = 41
let LLVM_RealOEQ: i32 = 1
let LLVM_RealOGT: i32 = 2
let LLVM_RealOGE: i32 = 3
let LLVM_RealOLT: i32 = 4
let LLVM_RealOLE: i32 = 5
let LLVM_RealONE: i32 = 6
let LLVM_RealUNO: i32 = 8
let LLVM_ExternalLinkage: i32 = 0
let LLVM_WeakAnyLinkage: i32 = 5
let LLVM_InternalLinkage: i32 = 8
let LLVM_PrivateLinkage: i32 = 9
let LLVM_CCallConv: i32 = 0
let LLVM_FastCallConv: i32 = 8
let LLVM_X86StdcallCallConv: i32 = 64
let LLVM_X86FastcallCallConv: i32 = 65
let LLVM_Win64CallConv: i32 = 79
let LLVM_ObjectFile: i32 = 1
let LLVM_ReturnStatusAction: i32 = 2
let LLVM_TailCallKindMustTail: i32 = 2
let LLVM_DIFlagZero: i32 = 0
let LLVM_DWARFSourceLanguageC: i32 = 1
let LLVM_DWARFEmissionFull: i32 = 1
let LLVM_ModuleFlagBehaviorWarning: i32 = 1
let LLVM_InlineAsmDialectATT: i32 = 0
let LLVM_AtomicOrderingMonotonic: i32 = 2
let LLVM_AtomicOrderingAcquire: i32 = 4
let LLVM_AtomicOrderingRelease: i32 = 5
let LLVM_AtomicOrderingAcquireRelease: i32 = 6
let LLVM_AtomicOrderingSequentiallyConsistent: i32 = 7
let LLVM_AtomicRMWBinOpXchg: i32 = 0
let LLVM_AtomicRMWBinOpAdd: i32 = 1
let LLVM_AtomicRMWBinOpSub: i32 = 2
let LLVM_AtomicRMWBinOpAnd: i32 = 3
let LLVM_AtomicRMWBinOpOr: i32 = 5
let LLVM_AtomicRMWBinOpXor: i32 = 6
let LLVM_AtomicRMWBinOpMax: i32 = 7
let LLVM_AtomicRMWBinOpMin: i32 = 8
let LLVM_AtomicRMWBinOpUMax: i32 = 9
let LLVM_AtomicRMWBinOpUMin: i32 = 10

// ── LLVM-C extern declarations ──────────────────────────────────
// All LLVM types are opaque pointers — declared as *mut u8.
// "P" = pointer param, returns *mut u8 (cast to i64 for With).

extern fn LLVMContextCreate() -> *mut u8
extern fn LLVMContextDispose(ctx: *mut u8)
extern fn LLVMModuleCreateWithNameInContext(name: *const u8, ctx: *mut u8) -> *mut u8
extern fn LLVMDisposeModule(m: *mut u8)
extern fn LLVMCreateBuilderInContext(ctx: *mut u8) -> *mut u8
extern fn LLVMDisposeBuilder(b: *mut u8)
extern fn LLVMGetModuleContext(m: *mut u8) -> *mut u8

// Target
// LLVMInitializeNative* are C macros — use platform-specific symbols directly.
// On aarch64 Darwin: LLVM_NATIVE_TARGET = AArch64
extern fn LLVMInitializeAArch64TargetInfo()
extern fn LLVMInitializeAArch64Target()
extern fn LLVMInitializeAArch64TargetMC()
extern fn LLVMInitializeAArch64AsmPrinter()
extern fn LLVMInitializeAArch64AsmParser()
extern fn LLVMInitializeX86TargetInfo()
extern fn LLVMInitializeX86Target()
extern fn LLVMInitializeX86TargetMC()
extern fn LLVMInitializeX86AsmPrinter()
extern fn LLVMInitializeX86AsmParser()
extern fn LLVMGetDefaultTargetTriple() -> *mut u8
extern fn LLVMGetTargetFromTriple(triple: *const u8, target: *mut *mut u8, err: *mut *mut u8) -> i32
extern fn LLVMCreateTargetMachine(target: *mut u8, triple: *const u8, cpu: *const u8, features: *const u8, level: i32, reloc: i32, model: i32) -> *mut u8
extern fn LLVMCreateTargetDataLayout(tm: *mut u8) -> *mut u8
extern fn LLVMSetModuleDataLayout(m: *mut u8, dl: *mut u8)
extern fn LLVMSetTarget(m: *mut u8, triple: *const u8)
extern fn LLVMDisposeTargetData(dl: *mut u8)
extern fn LLVMDisposeMessage(msg: *mut u8)
extern fn LLVMDisposeTargetMachine(tm: *mut u8)

// IR/Assembly file compilation
extern fn LLVMCreateMemoryBufferWithContentsOfFile(path: *const u8, out_buf: *mut *mut u8, out_msg: *mut *mut u8) -> i32
extern fn LLVMParseIRInContext2(ctx: *mut u8, buf: *mut u8, out_mod: *mut *mut u8, out_msg: *mut *mut u8) -> i32
extern fn LLVMSetModuleInlineAsm2(m: *mut u8, asm_text: *const u8, len: u64)
extern fn LLVMGetBufferStart(buf: *mut u8) -> *const u8
extern fn LLVMGetBufferSize(buf: *mut u8) -> u64
extern fn LLVMDisposeMemoryBuffer(buf: *mut u8)

// Types
extern fn LLVMInt1TypeInContext(c: *mut u8) -> *mut u8
extern fn LLVMInt8TypeInContext(c: *mut u8) -> *mut u8
extern fn LLVMInt16TypeInContext(c: *mut u8) -> *mut u8
extern fn LLVMInt32TypeInContext(c: *mut u8) -> *mut u8
extern fn LLVMInt64TypeInContext(c: *mut u8) -> *mut u8
extern fn LLVMInt128TypeInContext(c: *mut u8) -> *mut u8
extern fn LLVMIntTypeInContext(c: *mut u8, bits: u32) -> *mut u8
extern fn LLVMFloatTypeInContext(c: *mut u8) -> *mut u8
extern fn LLVMDoubleTypeInContext(c: *mut u8) -> *mut u8
extern fn LLVMVoidTypeInContext(c: *mut u8) -> *mut u8
extern fn LLVMPointerTypeInContext(c: *mut u8, addr_space: u32) -> *mut u8
extern fn LLVMArrayType2(elem: *mut u8, count: u64) -> *mut u8
extern fn LLVMFunctionType(ret: *mut u8, params: *const *mut u8, count: u32, is_vararg: i32) -> *mut u8
extern fn LLVMStructTypeInContext(c: *mut u8, elems: *const *mut u8, count: u32, packed: i32) -> *mut u8
extern fn LLVMStructCreateNamed(c: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMStructSetBody(ty: *mut u8, elems: *const *mut u8, count: u32, packed: i32)
extern fn LLVMStructGetTypeAtIndex(ty: *mut u8, idx: u32) -> *mut u8
extern fn LLVMCountStructElementTypes(ty: *mut u8) -> u32
extern fn LLVMGetElementType(ty: *mut u8) -> *mut u8
extern fn LLVMGetArrayLength2(ty: *mut u8) -> u64

// Type queries
extern fn LLVMTypeOf(v: *mut u8) -> *mut u8
extern fn LLVMGetTypeKind(ty: *mut u8) -> i32
extern fn LLVMGetReturnType(ft: *mut u8) -> *mut u8
extern fn LLVMCountParams(fn_val: *mut u8) -> u32
extern fn LLVMCountParamTypes(ft: *mut u8) -> u32
extern fn LLVMGetParam(fn_val: *mut u8, idx: u32) -> *mut u8
extern fn LLVMGetIntTypeWidth(ty: *mut u8) -> u32
extern fn LLVMIsFunctionVarArg(ft: *mut u8) -> i32
extern fn LLVMGlobalGetValueType(v: *mut u8) -> *mut u8
extern fn LLVMIsAAllocaInst(v: *mut u8) -> *mut u8
extern fn LLVMGetAllocatedType(v: *mut u8) -> *mut u8

// Constants
extern fn LLVMConstInt(ty: *mut u8, val: u64, sign_ext: i32) -> *mut u8
extern fn LLVMConstIntOfArbitraryPrecision(ty: *mut u8, num_words: u32, words: *const u64) -> *mut u8
extern fn LLVMConstReal(ty: *mut u8, val: f64) -> *mut u8
extern fn LLVMConstNull(ty: *mut u8) -> *mut u8
extern fn LLVMGetUndef(ty: *mut u8) -> *mut u8
extern fn LLVMConstStringInContext(c: *mut u8, s: *const u8, len: u32, dont_null: i32) -> *mut u8
extern fn LLVMConstStructInContext(c: *mut u8, vals: *const *mut u8, count: u32, packed: i32) -> *mut u8
extern fn LLVMConstNamedStruct(ty: *mut u8, vals: *const *mut u8, count: u32) -> *mut u8
extern fn LLVMConstArray2(elem_ty: *mut u8, vals: *const *mut u8, count: u64) -> *mut u8
extern fn LLVMConstBitCast(v: *mut u8, ty: *mut u8) -> *mut u8
extern fn LLVMConstIntGetSExtValue(v: *mut u8) -> i64
extern fn LLVMIsConstant(v: *mut u8) -> i32
extern fn LLVMSizeOf(ty: *mut u8) -> *mut u8

// Functions & globals
extern fn LLVMAddFunction(m: *mut u8, name: *const u8, fn_ty: *mut u8) -> *mut u8
extern fn LLVMGetNamedFunction(m: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMGetNamedGlobal(m: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMGetFirstFunction(m: *mut u8) -> *mut u8
extern fn LLVMGetNextFunction(v: *mut u8) -> *mut u8
extern fn LLVMIsDeclaration(v: *mut u8) -> i32
extern fn LLVMGetEnumAttributeKindForName(name: *const u8, len: u64) -> u32
extern fn LLVMCreateEnumAttribute(c: *mut u8, kind: u32, val: u64) -> *mut u8
extern fn LLVMCreateTypeAttribute(c: *mut u8, kind: u32, ty: *mut u8) -> *mut u8
extern fn LLVMAddAttributeAtIndex(v: *mut u8, idx: u32, attr: *mut u8)
extern fn LLVMAddCallSiteAttribute(call: *mut u8, idx: u32, attr: *mut u8)

// Basic blocks
extern fn LLVMAppendBasicBlockInContext(c: *mut u8, fn_val: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMPositionBuilderAtEnd(b: *mut u8, bb: *mut u8)
extern fn LLVMPositionBuilderBefore(b: *mut u8, instr: *mut u8)
extern fn LLVMGetInsertBlock(b: *mut u8) -> *mut u8
extern fn LLVMGetBasicBlockTerminator(bb: *mut u8) -> *mut u8
extern fn LLVMGetEntryBasicBlock(fn_val: *mut u8) -> *mut u8
extern fn LLVMGetFirstInstruction(bb: *mut u8) -> *mut u8
extern fn LLVMBasicBlockAsValue(bb: *mut u8) -> *mut u8

// Builder: arithmetic (all take builder, lhs, rhs, name → value)
extern fn LLVMBuildAdd(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildSub(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildMul(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildNSWAdd(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildNSWSub(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildNSWMul(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildSDiv(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildSRem(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildUDiv(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildURem(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildFAdd(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildFSub(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildFMul(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildFDiv(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildFRem(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildAnd(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildOr(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildXor(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildShl(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildAShr(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildLShr(b: *mut u8, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8

// Builder: unary
extern fn LLVMBuildNeg(b: *mut u8, v: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildNot(b: *mut u8, v: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildFNeg(b: *mut u8, v: *mut u8, name: *const u8) -> *mut u8

// Builder: comparison
extern fn LLVMBuildICmp(b: *mut u8, pred: i32, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildFCmp(b: *mut u8, pred: i32, l: *mut u8, r: *mut u8, name: *const u8) -> *mut u8

// Builder: memory
extern fn LLVMBuildAlloca(b: *mut u8, ty: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildLoad2(b: *mut u8, ty: *mut u8, ptr: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildStore(b: *mut u8, val: *mut u8, ptr: *mut u8) -> *mut u8
extern fn LLVMSetVolatile(inst: *mut u8, is_volatile: i32)
extern fn LLVMBuildGEP2(b: *mut u8, ty: *mut u8, ptr: *mut u8, indices: *const *mut u8, count: u32, name: *const u8) -> *mut u8
extern fn LLVMBuildStructGEP2(b: *mut u8, ty: *mut u8, ptr: *mut u8, idx: u32, name: *const u8) -> *mut u8
extern fn LLVMBuildGlobalStringPtr(b: *mut u8, s: *const u8, name: *const u8) -> *mut u8

// Builder: globals
extern fn LLVMAddGlobal(m: *mut u8, ty: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMSetInitializer(g: *mut u8, v: *mut u8)
extern fn LLVMSetGlobalConstant(g: *mut u8, c: i32)
extern fn LLVMSetLinkage(g: *mut u8, linkage: i32)
extern fn LLVMSetFunctionCallConv(fn_val: *mut u8, cc: u32)

// Builder: control flow
extern fn LLVMBuildBr(b: *mut u8, bb: *mut u8) -> *mut u8
extern fn LLVMBuildCondBr(b: *mut u8, cond: *mut u8, then_bb: *mut u8, else_bb: *mut u8) -> *mut u8
extern fn LLVMBuildRet(b: *mut u8, val: *mut u8) -> *mut u8
extern fn LLVMBuildRetVoid(b: *mut u8) -> *mut u8
extern fn LLVMBuildUnreachable(b: *mut u8) -> *mut u8
extern fn LLVMBuildSwitch(b: *mut u8, val: *mut u8, else_bb: *mut u8, n: u32) -> *mut u8
extern fn LLVMAddCase(sw: *mut u8, val: *mut u8, bb: *mut u8)

// Builder: cast
extern fn LLVMBuildZExt(b: *mut u8, v: *mut u8, ty: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildSExt(b: *mut u8, v: *mut u8, ty: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildTrunc(b: *mut u8, v: *mut u8, ty: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildSIToFP(b: *mut u8, v: *mut u8, ty: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildUIToFP(b: *mut u8, v: *mut u8, ty: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildFPToSI(b: *mut u8, v: *mut u8, ty: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildFPToUI(b: *mut u8, v: *mut u8, ty: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildBitCast(b: *mut u8, v: *mut u8, ty: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildIntToPtr(b: *mut u8, v: *mut u8, ty: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildPtrToInt(b: *mut u8, v: *mut u8, ty: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildFPCast(b: *mut u8, v: *mut u8, ty: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildFPExt(b: *mut u8, v: *mut u8, ty: *mut u8, name: *const u8) -> *mut u8

// Builder: phi / select / extract / insert
extern fn LLVMBuildPhi(b: *mut u8, ty: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMAddIncoming(phi: *mut u8, vals: *const *mut u8, bbs: *const *mut u8, count: u32)
extern fn LLVMBuildSelect(b: *mut u8, cond: *mut u8, then_v: *mut u8, else_v: *mut u8, name: *const u8) -> *mut u8
extern fn LLVMBuildExtractValue(b: *mut u8, agg: *mut u8, idx: u32, name: *const u8) -> *mut u8
extern fn LLVMBuildInsertValue(b: *mut u8, agg: *mut u8, val: *mut u8, idx: u32, name: *const u8) -> *mut u8

// Builder: call
extern fn LLVMBuildCall2(b: *mut u8, fn_ty: *mut u8, fn_val: *mut u8, args: *const *mut u8, count: u32, name: *const u8) -> *mut u8
extern fn LLVMSetTailCall(call: *mut u8, is_tail: i32)
extern fn LLVMSetTailCallKind(call: *mut u8, kind: i32)

// Value ops
extern fn LLVMInstructionEraseFromParent(v: *mut u8)
extern fn LLVMGetValueKind(v: *mut u8) -> i32
extern fn LLVMGetFirstUse(v: *mut u8) -> *mut u8
extern fn LLVMSetValueName2(v: *mut u8, name: *const u8, len: u64)

// Intrinsics
extern fn LLVMLookupIntrinsicID(name: *const u8, len: u64) -> u32
extern fn LLVMGetIntrinsicDeclaration(m: *mut u8, id: u32, tys: *const *mut u8, cnt: u64) -> *mut u8
extern fn LLVMIntrinsicGetType(c: *mut u8, id: u32, tys: *const *mut u8, cnt: u64) -> *mut u8

// Data layout
extern fn LLVMGetModuleDataLayout(m: *mut u8) -> *mut u8
extern fn LLVMABISizeOfType(dl: *mut u8, ty: *mut u8) -> u64
extern fn LLVMABIAlignmentOfType(dl: *mut u8, ty: *mut u8) -> u32

// Struct name
extern fn LLVMGetStructName(ty: *mut u8) -> *const u8

// Param types
extern fn LLVMGetParamTypes(ft: *mut u8, out: *mut *mut u8)

// Verification / emission
extern fn LLVMVerifyModule(m: *mut u8, action: i32, err: *mut *mut u8) -> i32
extern fn LLVMVerifyFunction(fn_val: *mut u8, action: i32) -> i32
extern fn LLVMTargetMachineEmitToFile(tm: *mut u8, m: *mut u8, path: *mut u8, codegen: i32, err: *mut *mut u8) -> i32
extern fn LLVMGetValueName2(v: *mut u8, len: *mut u64) -> *const u8

// Optimization
extern fn LLVMCreatePassBuilderOptions() -> *mut u8
extern fn LLVMDisposePassBuilderOptions(opts: *mut u8)
extern fn LLVMRunPasses(m: *mut u8, passes: *const u8, tm: *mut u8, opts: *mut u8) -> *mut u8
extern fn LLVMRunPassesOnFunction(fn_val: *mut u8, passes: *const u8, tm: *mut u8, opts: *mut u8) -> *mut u8
extern fn LLVMGetErrorMessage(err: *mut u8) -> *mut u8
extern fn LLVMDisposeErrorMessage(msg: *mut u8)

// Printing
extern fn LLVMDumpValue(v: *mut u8)
extern fn LLVMPrintModuleToString(m: *mut u8) -> *mut u8

// Debug info
extern fn LLVMCreateDIBuilder(m: *mut u8) -> *mut u8
extern fn LLVMDisposeDIBuilder(b: *mut u8)
extern fn LLVMDIBuilderFinalize(b: *mut u8)
extern fn LLVMDebugMetadataVersion() -> u32
extern fn LLVMAddModuleFlag(m: *mut u8, behavior: i32, key: *const u8, key_len: u64, val: *mut u8)
extern fn LLVMValueAsMetadata(v: *mut u8) -> *mut u8
extern fn LLVMDIBuilderCreateFile(b: *mut u8, fn_ptr: *const u8, fn_len: u64, dir_ptr: *const u8, dir_len: u64) -> *mut u8
extern fn LLVMDIBuilderCreateCompileUnit(b: *mut u8, lang: i32, file: *mut u8, producer: *const u8, producer_len: u64, is_optimized: i32, flags: *const u8, flags_len: u64, rv: u32, split: *const u8, split_len: u64, kind: i32, dwo_id: u32, split_inlining: i32, profiling: i32, sysroot: *const u8, sysroot_len: u64, sdk: *const u8, sdk_len: u64) -> *mut u8
extern fn LLVMDIBuilderCreateSubroutineType(b: *mut u8, file: *mut u8, params: *const *mut u8, count: u32, flags: i32) -> *mut u8
extern fn LLVMDIBuilderCreateFunction(b: *mut u8, scope: *mut u8, name: *const u8, name_len: u64, linkage: *const u8, linkage_len: u64, file: *mut u8, line: u32, ty: *mut u8, is_local: i32, is_def: i32, scope_line: u32, flags: i32, is_opt: i32) -> *mut u8
extern fn LLVMSetSubprogram(fn_val: *mut u8, sp: *mut u8)
extern fn LLVMDIBuilderCreateDebugLocation(ctx: *mut u8, line: u32, col: u32, scope: *mut u8, inlined: *mut u8) -> *mut u8
extern fn LLVMSetCurrentDebugLocation2(b: *mut u8, loc: *mut u8)
extern fn LLVMGetCurrentDebugLocation2(b: *mut u8) -> *mut u8
extern fn LLVMDIBuilderCreateBasicType(b: *mut u8, name: *const u8, name_len: u64, size: u64, encoding: i32, flags: i32) -> *mut u8
extern fn LLVMDIBuilderCreatePointerType(b: *mut u8, pointee: *mut u8, size: u64, align: u32, addr_space: u32, name: *const u8, name_len: u64) -> *mut u8
extern fn LLVMDIBuilderCreateStructType(b: *mut u8, scope: *mut u8, name: *const u8, name_len: u64, file: *mut u8, line: u32, size: u64, align: u32, flags: i32, derived: *mut u8, elems: *const *mut u8, count: u32, rv_lang: u32, vtable: *mut u8, uid: *const u8, uid_len: u64) -> *mut u8
extern fn LLVMDIBuilderCreateMemberType(b: *mut u8, scope: *mut u8, name: *const u8, name_len: u64, file: *mut u8, line: u32, size: u64, align: u32, offset: u64, flags: i32, ty: *mut u8) -> *mut u8
extern fn LLVMDIBuilderCreateUnspecifiedType(b: *mut u8, name: *const u8, name_len: u64) -> *mut u8
extern fn LLVMDIBuilderCreateAutoVariable(b: *mut u8, scope: *mut u8, name: *const u8, name_len: u64, file: *mut u8, line: u32, ty: *mut u8, preserve: i32, flags: i32, align: u32) -> *mut u8
extern fn LLVMDIBuilderCreateParameterVariable(b: *mut u8, scope: *mut u8, name: *const u8, name_len: u64, arg_no: u32, file: *mut u8, line: u32, ty: *mut u8, preserve: i32, flags: i32) -> *mut u8
extern fn LLVMDIBuilderCreateExpression(b: *mut u8, ops: *const i64, count: u64) -> *mut u8
extern fn LLVMDIBuilderInsertDeclareRecordAtEnd(b: *mut u8, storage: *mut u8, var_info: *mut u8, expr: *mut u8, loc: *mut u8, block: *mut u8)
extern fn LLVMDIBuilderCreateLexicalBlock(b: *mut u8, scope: *mut u8, file: *mut u8, line: u32, col: u32) -> *mut u8

// Atomics
extern fn LLVMBuildAtomicRMW(b: *mut u8, op: i32, ptr: *mut u8, val: *mut u8, ordering: i32, single_thread: i32) -> *mut u8
extern fn LLVMBuildAtomicCmpXchg(b: *mut u8, ptr: *mut u8, expected: *mut u8, desired: *mut u8, success: i32, failure: i32, single_thread: i32) -> *mut u8
extern fn LLVMSetWeak(cmpxchg: *mut u8, is_weak: i32)
extern fn LLVMBuildFence(b: *mut u8, ordering: i32, single_thread: i32, name: *const u8) -> *mut u8
extern fn LLVMSetOrdering(v: *mut u8, ordering: i32)
extern fn LLVMSetAlignment(v: *mut u8, align: u32)
extern fn LLVMGetGlobalParent(v: *mut u8) -> *mut u8
extern fn LLVMGetBasicBlockParent(bb: *mut u8) -> *mut u8

// Inline assembly
extern fn LLVMGetInlineAsm(fn_ty: *mut u8, asm_str: *const u8, asm_len: u64, constraints: *const u8, constraints_len: u64, has_side_effects: i32, is_align_stack: i32, dialect: i32, can_throw: i32) -> *mut u8

// ── String helper ───────────────────────────────────────────────
enum Order: i32:
    Relaxed = 0
    Acquire = 1
    Release = 2
    AcqRel = 3
    SeqCst = 4

type Atomic[T] {
    val: T,
}

let CSTR_THREAD_SLOTS: i32 = 64

var cstr_slot_lock: Atomic[i32]
var cstr_slot_owners: [64]i64 = [0 as i64; 64]
var cstr_slot_indices: [64]i32 = [0 as i32; 64]
var cstr_bufs: [64][4][4096]u8 = [[[0 as u8; 4096]; 4]; 64]

fn cstr_lock():
    while cstr_slot_lock.swap(1, .Acquire) != 0:
        // The lock protects only slot metadata, so contention should be brief.
        let _ = 0

fn cstr_unlock():
    cstr_slot_lock.store(0, .Release)

fn cstr_thread_id() -> i64:
    let tid = unsafe { pthread_self() }
    if tid != 0:
        return tid
    1

fn cstr_slot_for_current_thread() -> i32:
    let tid = cstr_thread_id()
    var slot = -1
    cstr_lock()
    for i in 0..CSTR_THREAD_SLOTS:
        if cstr_slot_owners[i as i64] == tid:
            slot = i
            break
    if slot < 0:
        for i in 0..CSTR_THREAD_SLOTS:
            if cstr_slot_owners[i as i64] == 0:
                cstr_slot_owners[i as i64] = tid
                cstr_slot_indices[i as i64] = 0
                slot = i
                break
    if slot >= 0:
        cstr_slot_indices[slot as i64] = (cstr_slot_indices[slot as i64] + 1) & 3
    cstr_unlock()
    slot

fn to_cstr(s: str) -> *const u8:
    let slot = cstr_slot_for_current_thread()
    if slot < 0:
        let _ = rt_write(2, "error: LLVM bridge exhausted thread-local cstr slots\n" as *const u8, 53)
        unsafe:
            abort()
        return empty_cstr()
    let idx = cstr_slot_indices[slot as i64]
    let n = if s.len() < 4095: s.len() else: 4095
    let src = unsafe *(&s as *const *const u8)
    let dst = &raw mut cstr_bufs[slot as i64][idx as i64] as *mut u8
    with_memcpy(dst, src, n)
    cstr_bufs[slot as i64][idx as i64][n] = 0 as u8
    dst as *const u8

fn c_strlen(s: *const u8) -> i64:
    if s as i64 == 0: return 0
    var i: i64 = 0
    while unsafe *((s as i64 + i) as *const u8) != 0:
        i = i + 1
    i

fn empty_cstr() -> *const u8:
    "\0" as *const u8

// ── Lifecycle ───────────────────────────────────────────────────

pub fn wl_context_create() -> i64: unsafe { LLVMContextCreate() as i64 }

pub fn wl_context_dispose(c: i64) -> Unit: unsafe { LLVMContextDispose(c as *mut u8) }

pub fn wl_module_create(name: str, ctx: i64) -> i64:
    unsafe:
        LLVMModuleCreateWithNameInContext(to_cstr(name), ctx as *mut u8) as i64

pub fn wl_module_dispose(m: i64) -> Unit: unsafe { LLVMDisposeModule(m as *mut u8) }

pub fn wl_builder_create(ctx: i64) -> i64: unsafe { LLVMCreateBuilderInContext(ctx as *mut u8) as i64 }

pub fn wl_builder_dispose(b: i64) -> Unit: unsafe { LLVMDisposeBuilder(b as *mut u8) }

// ── Target initialization ───────────────────────────────────────

var llvm_init_lock_word: Atomic[i32]
var llvm_native_target_done: i32 = 0
var llvm_native_asm_printer_done: i32 = 0
var llvm_native_asm_parser_done: i32 = 0

fn llvm_init_lock():
    var spins = 0
    while llvm_init_lock_word.swap(1, .Acquire) != 0:
        spins = spins + 1
        if spins >= 1024:
            let _ = with_nanosleep(1000)
            spins = 0

fn llvm_init_unlock():
    llvm_init_lock_word.store(0, .Release)

pub fn wl_init_native_target() -> i32:
    unsafe:
        llvm_init_lock()
        if llvm_native_target_done == 0:
            LLVMInitializeAArch64TargetInfo()
            LLVMInitializeAArch64Target()
            LLVMInitializeAArch64TargetMC()
            LLVMInitializeX86TargetInfo()
            LLVMInitializeX86Target()
            LLVMInitializeX86TargetMC()
            llvm_native_target_done = 1
        llvm_init_unlock()
        0

pub fn wl_init_native_asm_printer() -> i32:
    unsafe:
        llvm_init_lock()
        if llvm_native_asm_printer_done == 0:
            LLVMInitializeAArch64AsmPrinter()
            LLVMInitializeX86AsmPrinter()
            llvm_native_asm_printer_done = 1
        llvm_init_unlock()
        0

pub fn wl_init_native_asm_parser() -> i32:
    unsafe:
        llvm_init_lock()
        if llvm_native_asm_parser_done == 0:
            LLVMInitializeAArch64AsmParser()
            LLVMInitializeX86AsmParser()
            llvm_native_asm_parser_done = 1
        llvm_init_unlock()
        0

fn codegen_level(level: i32) -> i32:
    if level == 0: return LLVM_CodeGenLevelNone
    if level == 1: return LLVM_CodeGenLevelLess
    if level == 3: return LLVM_CodeGenLevelAggressive
    LLVM_CodeGenLevelDefault

pub fn wl_init_target_machine(mod_ref: i64, level: i32) -> i64:
    unsafe:
        let triple = LLVMGetDefaultTargetTriple()
        var target: *mut u8 = 0 as *mut u8
        var err: *mut u8 = 0 as *mut u8
        if LLVMGetTargetFromTriple(triple as *const u8, &raw mut target, &raw mut err) != 0:
            if err as i64 != 0:
                let err_len = c_strlen(err as *const u8)
                if err_len > 0:
                    let _ = rt_write(2, err as *const u8, err_len as u64)
                    let _ = rt_write(2, "\n" as *const u8, 1)
                LLVMDisposeMessage(err)
            LLVMDisposeMessage(triple)
            return 0
        let tm = LLVMCreateTargetMachine(target, triple as *const u8,
            c"generic".ptr, empty_cstr(),
            codegen_level(level), LLVM_RelocDefault, LLVM_CodeModelDefault)
        if tm as i64 == 0:
            let msg = "LLVM target machine creation failed\n"
            let _ = rt_write(2, msg as *const u8, 36)
            LLVMDisposeMessage(triple)
            return 0
        let layout = LLVMCreateTargetDataLayout(tm)
        LLVMSetModuleDataLayout(mod_ref as *mut u8, layout)
        let triple2 = LLVMGetDefaultTargetTriple()
        LLVMSetTarget(mod_ref as *mut u8, triple2 as *const u8)
        LLVMDisposeMessage(triple2)
        LLVMDisposeTargetData(layout)
        LLVMDisposeMessage(triple)
        tm as i64

pub fn wl_dispose_target_machine(tm: i64) -> Unit: unsafe { LLVMDisposeTargetMachine(tm as *mut u8) }

// ── Types ───────────────────────────────────────────────────────

pub fn wl_i1_type(c: i64) -> i64: unsafe { LLVMInt1TypeInContext(c as *mut u8) as i64 }
pub fn wl_i8_type(c: i64) -> i64: unsafe { LLVMInt8TypeInContext(c as *mut u8) as i64 }
pub fn wl_i16_type(c: i64) -> i64: unsafe { LLVMInt16TypeInContext(c as *mut u8) as i64 }
pub fn wl_i32_type(c: i64) -> i64: unsafe { LLVMInt32TypeInContext(c as *mut u8) as i64 }
pub fn wl_i64_type(c: i64) -> i64: unsafe { LLVMInt64TypeInContext(c as *mut u8) as i64 }
pub fn wl_i128_type(c: i64) -> i64: unsafe { LLVMInt128TypeInContext(c as *mut u8) as i64 }
pub fn wl_int_type_n(c: i64, bits: i32) -> i64: unsafe { LLVMIntTypeInContext(c as *mut u8, bits as u32) as i64 }
pub fn wl_f32_type(c: i64) -> i64: unsafe { LLVMFloatTypeInContext(c as *mut u8) as i64 }
pub fn wl_f64_type(c: i64) -> i64: unsafe { LLVMDoubleTypeInContext(c as *mut u8) as i64 }
pub fn wl_void_type(c: i64) -> i64: unsafe { LLVMVoidTypeInContext(c as *mut u8) as i64 }
pub fn wl_ptr_type(c: i64) -> i64: unsafe { LLVMPointerTypeInContext(c as *mut u8, 0) as i64 }
pub fn wl_array_type(elem: i64, size: i64) -> i64: unsafe { LLVMArrayType2(elem as *mut u8, size as u64) as i64 }

pub fn wl_function_type(ret: i64, params_ptr: i64, count: i32, is_vararg: i32) -> i64:
    unsafe:
        let params = if count > 0: params_ptr as *const *mut u8 else: 0 as *const *mut u8
        LLVMFunctionType(ret as *mut u8, params, count as u32, is_vararg) as i64

pub fn wl_struct_type(ctx: i64, elems_ptr: i64, count: i32, packed: i32) -> i64:
    unsafe:
        LLVMStructTypeInContext(ctx as *mut u8, elems_ptr as *const *mut u8, count as u32, packed) as i64

pub fn wl_struct_create_named(ctx: i64, name: str) -> i64:
    unsafe:
        LLVMStructCreateNamed(ctx as *mut u8, to_cstr(name)) as i64

pub fn wl_struct_set_body(ty: i64, elems_ptr: i64, count: i32, packed: i32) -> Unit:
    unsafe:
        LLVMStructSetBody(ty as *mut u8, elems_ptr as *const *mut u8, count as u32, packed)

pub fn wl_struct_set_body_2(ty: i64, t0: i64, t1: i64, packed: i32) -> Unit:
    unsafe:
        var elems: [2]i64 = [t0, t1]
        LLVMStructSetBody(ty as *mut u8, &elems as *const *mut u8, 2, packed)

pub fn wl_struct_get_type_at(ty: i64, idx: i32) -> i64: unsafe { LLVMStructGetTypeAtIndex(ty as *mut u8, idx as u32) as i64 }
pub fn wl_count_struct_elem_types(ty: i64) -> i32: unsafe { LLVMCountStructElementTypes(ty as *mut u8) as i32 }
pub fn wl_get_element_type(ty: i64) -> i64: unsafe { LLVMGetElementType(ty as *mut u8) as i64 }
pub fn wl_get_array_length(ty: i64) -> i64: unsafe { LLVMGetArrayLength2(ty as *mut u8) as i64 }

// ── Type queries ────────────────────────────────────────────────

pub fn wl_type_of(v: i64) -> i64: unsafe { LLVMTypeOf(v as *mut u8) as i64 }
pub fn wl_get_type_kind(ty: i64) -> i32: unsafe { LLVMGetTypeKind(ty as *mut u8) }
pub fn wl_get_return_type(ft: i64) -> i64: unsafe { LLVMGetReturnType(ft as *mut u8) as i64 }
pub fn wl_count_params(fn_val: i64) -> i32: unsafe { LLVMCountParams(fn_val as *mut u8) as i32 }
pub fn wl_count_param_types(ft: i64) -> i32: unsafe { LLVMCountParamTypes(ft as *mut u8) as i32 }
pub fn wl_get_param(fn_val: i64, i: i32) -> i64: unsafe { LLVMGetParam(fn_val as *mut u8, i as u32) as i64 }
pub fn wl_get_int_type_width(ty: i64) -> i32: unsafe { LLVMGetIntTypeWidth(ty as *mut u8) as i32 }
pub fn wl_is_fn_var_arg(ft: i64) -> i32: unsafe { LLVMIsFunctionVarArg(ft as *mut u8) }
pub fn wl_global_get_value_type(v: i64) -> i64:
    unsafe:
        if v == 0:
            return 0
        let kind = LLVMGetValueKind(v as *mut u8)
        if kind != LLVM_FunctionValueKind and kind != LLVM_GlobalAliasValueKind and kind != LLVM_GlobalIFuncValueKind and kind != LLVM_GlobalVariableValueKind:
            return 0
        LLVMGlobalGetValueType(v as *mut u8) as i64
pub fn wl_get_allocated_type(v: i64) -> i64:
    unsafe:
        let value = v as *mut u8
        if LLVMIsAAllocaInst(value) as i64 == 0:
            return 0
        LLVMGetAllocatedType(value) as i64

// Type kind constants
pub fn wl_void_type_kind() -> i32: LLVM_VoidTypeKind
pub fn wl_float_type_kind() -> i32: LLVM_FloatTypeKind
pub fn wl_double_type_kind() -> i32: LLVM_DoubleTypeKind
pub fn wl_integer_type_kind() -> i32: LLVM_IntegerTypeKind
pub fn wl_function_type_kind() -> i32: LLVM_FunctionTypeKind
pub fn wl_struct_type_kind() -> i32: LLVM_StructTypeKind
pub fn wl_array_type_kind() -> i32: LLVM_ArrayTypeKind
pub fn wl_pointer_type_kind() -> i32: LLVM_PointerTypeKind
pub fn wl_function_value_kind() -> i32: LLVM_FunctionValueKind

// ── Constants ───────────────────────────────────────────────────

pub fn wl_const_int(ty: i64, val: i64, sign_ext: i32) -> i64:
    unsafe:
        LLVMConstInt(ty as *mut u8, val as u64, sign_ext) as i64

pub fn wl_const_int_words(ty: i64, lo: i64, hi: i64, word_count: i32) -> i64:
    unsafe:
        var words: [2]u64 = [lo as u64, hi as u64]
        LLVMConstIntOfArbitraryPrecision(ty as *mut u8, word_count as u32, &words as *const u64) as i64

pub fn wl_const_real(ty: i64, val: f64) -> i64: unsafe { LLVMConstReal(ty as *mut u8, val) as i64 }
pub fn wl_const_null(ty: i64) -> i64: unsafe { LLVMConstNull(ty as *mut u8) as i64 }
pub fn wl_get_undef(ty: i64) -> i64: unsafe { LLVMGetUndef(ty as *mut u8) as i64 }

pub fn wl_const_string(ctx: i64, s: str, dont_null: i32) -> i64:
    unsafe:
        let sp = *(&s as *const *const u8)
        LLVMConstStringInContext(ctx as *mut u8, sp, s.len() as u32, dont_null) as i64

pub fn wl_const_struct(ctx: i64, vals_ptr: i64, count: i32, packed: i32) -> i64:
    unsafe:
        LLVMConstStructInContext(ctx as *mut u8, vals_ptr as *const *mut u8, count as u32, packed) as i64

pub fn wl_const_named_struct(ty: i64, vals_ptr: i64, count: i32) -> i64:
    unsafe:
        LLVMConstNamedStruct(ty as *mut u8, vals_ptr as *const *mut u8, count as u32) as i64

pub fn wl_const_array(elem_ty: i64, vals_ptr: i64, count: i32) -> i64:
    unsafe:
        LLVMConstArray2(elem_ty as *mut u8, vals_ptr as *const *mut u8, count as u64) as i64

pub fn wl_const_bitcast(val: i64, ty: i64) -> i64: unsafe { LLVMConstBitCast(val as *mut u8, ty as *mut u8) as i64 }
pub fn wl_const_int_sext_val(v: i64) -> i64: unsafe { LLVMConstIntGetSExtValue(v as *mut u8) }
pub fn wl_is_constant(v: i64) -> i32: unsafe { LLVMIsConstant(v as *mut u8) }
pub fn wl_size_of(ty: i64) -> i64: unsafe { LLVMSizeOf(ty as *mut u8) as i64 }

// ── ICmp predicates ─────────────────────────────────────────────

pub fn wl_int_eq() -> i32: LLVM_IntEQ
pub fn wl_int_ne() -> i32: LLVM_IntNE
pub fn wl_int_slt() -> i32: LLVM_IntSLT
pub fn wl_int_sgt() -> i32: LLVM_IntSGT
pub fn wl_int_sle() -> i32: LLVM_IntSLE
pub fn wl_int_sge() -> i32: LLVM_IntSGE
pub fn wl_int_ult() -> i32: LLVM_IntULT
pub fn wl_int_ule() -> i32: LLVM_IntULE
pub fn wl_int_uge() -> i32: LLVM_IntUGE
pub fn wl_int_ugt() -> i32: LLVM_IntUGT

// ── FCmp predicates ─────────────────────────────────────────────

pub fn wl_real_oeq() -> i32: LLVM_RealOEQ
pub fn wl_real_one() -> i32: LLVM_RealONE
pub fn wl_real_olt() -> i32: LLVM_RealOLT
pub fn wl_real_ogt() -> i32: LLVM_RealOGT
pub fn wl_real_ole() -> i32: LLVM_RealOLE
pub fn wl_real_oge() -> i32: LLVM_RealOGE

// ── Functions ───────────────────────────────────────────────────

pub fn wl_add_function(m: i64, name: str, fn_type: i64) -> i64:
    unsafe:
        LLVMAddFunction(m as *mut u8, to_cstr(name), fn_type as *mut u8) as i64

pub fn wl_get_named_function(m: i64, name: str) -> i64:
    unsafe:
        LLVMGetNamedFunction(m as *mut u8, to_cstr(name)) as i64

pub fn wl_get_named_global(m: i64, name: str) -> i64:
    unsafe:
        LLVMGetNamedGlobal(m as *mut u8, to_cstr(name)) as i64

pub fn wl_get_first_function(m: i64) -> i64: unsafe { LLVMGetFirstFunction(m as *mut u8) as i64 }
pub fn wl_get_next_function(v: i64) -> i64: unsafe { LLVMGetNextFunction(v as *mut u8) as i64 }
pub fn wl_is_declaration(v: i64) -> i32: unsafe { LLVMIsDeclaration(v as *mut u8) }

pub fn wl_add_fn_attr(ctx: i64, fn_val: i64, attr_name: str) -> Unit:
    unsafe:
        let name = to_cstr(attr_name)
        let kind = LLVMGetEnumAttributeKindForName(name, c_strlen(name) as u64)
        if kind != 0:
            let attr = LLVMCreateEnumAttribute(ctx as *mut u8, kind, 0)
            // LLVMAttributeIndex -1 = function index (0xFFFFFFFF as u32)
            LLVMAddAttributeAtIndex(fn_val as *mut u8, 4294967295 as u32, attr)

pub fn wl_add_param_attr(ctx: i64, fn_val: i64, param_idx: i32, attr_name: str) -> Unit:
    unsafe:
        let name = to_cstr(attr_name)
        let kind = LLVMGetEnumAttributeKindForName(name, c_strlen(name) as u64)
        if kind != 0:
            let attr = LLVMCreateEnumAttribute(ctx as *mut u8, kind, 0)
            LLVMAddAttributeAtIndex(fn_val as *mut u8, (param_idx + 1) as u32, attr)

pub fn wl_add_param_byval_attr(ctx: i64, fn_val: i64, param_idx: i32, ty: i64) -> Unit:
    unsafe:
        let name = "byval" as *const u8
        let kind = LLVMGetEnumAttributeKindForName(name, 5 as u64)
        if kind != 0:
            let attr = LLVMCreateTypeAttribute(ctx as *mut u8, kind, ty as *mut u8)
            LLVMAddAttributeAtIndex(fn_val as *mut u8, (param_idx + 1) as u32, attr)

pub fn wl_add_sret_attr(ctx: i64, fn_val: i64, param_idx: i32, ty: i64) -> Unit:
    unsafe:
        let name = "sret" as *const u8
        let kind = LLVMGetEnumAttributeKindForName(name, 4 as u64)
        if kind != 0:
            let attr = LLVMCreateTypeAttribute(ctx as *mut u8, kind, ty as *mut u8)
            LLVMAddAttributeAtIndex(fn_val as *mut u8, (param_idx + 1) as u32, attr)

pub fn wl_add_call_param_byval_attr(ctx: i64, call_val: i64, param_idx: i32, ty: i64) -> Unit:
    unsafe:
        let name = "byval" as *const u8
        let kind = LLVMGetEnumAttributeKindForName(name, 5 as u64)
        if kind != 0:
            let attr = LLVMCreateTypeAttribute(ctx as *mut u8, kind, ty as *mut u8)
            LLVMAddCallSiteAttribute(call_val as *mut u8, (param_idx + 1) as u32, attr)

pub fn wl_add_call_sret_attr(ctx: i64, call_val: i64, param_idx: i32, ty: i64) -> Unit:
    unsafe:
        let name = "sret" as *const u8
        let kind = LLVMGetEnumAttributeKindForName(name, 4 as u64)
        if kind != 0:
            let attr = LLVMCreateTypeAttribute(ctx as *mut u8, kind, ty as *mut u8)
            LLVMAddCallSiteAttribute(call_val as *mut u8, (param_idx + 1) as u32, attr)

// ── Basic blocks ────────────────────────────────────────────────

pub fn wl_append_bb(ctx: i64, fn_val: i64, name: str) -> i64:
    unsafe:
        LLVMAppendBasicBlockInContext(ctx as *mut u8, fn_val as *mut u8, to_cstr(name)) as i64

pub fn wl_position_at_end(b: i64, bb: i64) -> Unit:
    unsafe:
        LLVMPositionBuilderAtEnd(b as *mut u8, bb as *mut u8)

pub fn wl_position_before(b: i64, instr: i64) -> Unit:
    unsafe:
        LLVMPositionBuilderBefore(b as *mut u8, instr as *mut u8)

pub fn wl_get_insert_block(b: i64) -> i64: unsafe { LLVMGetInsertBlock(b as *mut u8) as i64 }
pub fn wl_get_bb_terminator(bb: i64) -> i64: unsafe { LLVMGetBasicBlockTerminator(bb as *mut u8) as i64 }
pub fn wl_get_entry_bb(fn_val: i64) -> i64: unsafe { LLVMGetEntryBasicBlock(fn_val as *mut u8) as i64 }
pub fn wl_get_first_instr(bb: i64) -> i64: unsafe { LLVMGetFirstInstruction(bb as *mut u8) as i64 }
pub fn wl_bb_as_value(bb: i64) -> i64: unsafe { LLVMBasicBlockAsValue(bb as *mut u8) as i64 }

// ── Builder: binary arithmetic ──────────────────────────────────

pub fn wl_build_add(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildAdd(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_sub(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildSub(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_mul(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildMul(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_nsw_add(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildNSWAdd(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_nsw_sub(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildNSWSub(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_nsw_mul(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildNSWMul(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_sdiv(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildSDiv(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_srem(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildSRem(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_udiv(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildUDiv(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_urem(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildURem(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_fadd(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildFAdd(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_fsub(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildFSub(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_fmul(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildFMul(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_fdiv(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildFDiv(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_frem(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildFRem(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_and(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildAnd(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_or(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildOr(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_xor(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildXor(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_shl(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildShl(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_ashr(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildAShr(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_lshr(b: i64, l: i64, r: i64) -> i64: unsafe { LLVMBuildLShr(b as *mut u8, l as *mut u8, r as *mut u8, empty_cstr()) as i64 }

// ── Builder: unary ──────────────────────────────────────────────

pub fn wl_build_neg(b: i64, v: i64) -> i64: unsafe { LLVMBuildNeg(b as *mut u8, v as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_not(b: i64, v: i64) -> i64: unsafe { LLVMBuildNot(b as *mut u8, v as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_fneg(b: i64, v: i64) -> i64: unsafe { LLVMBuildFNeg(b as *mut u8, v as *mut u8, empty_cstr()) as i64 }

// ── Builder: comparison ─────────────────────────────────────────

pub fn wl_build_icmp(b: i64, pred: i32, l: i64, r: i64) -> i64:
    unsafe:
        LLVMBuildICmp(b as *mut u8, pred, l as *mut u8, r as *mut u8, empty_cstr()) as i64

pub fn wl_build_fcmp(b: i64, pred: i32, l: i64, r: i64) -> i64:
    unsafe:
        LLVMBuildFCmp(b as *mut u8, pred, l as *mut u8, r as *mut u8, empty_cstr()) as i64

// ── Builder: memory ─────────────────────────────────────────────

pub fn wl_build_alloca(b: i64, ty: i64) -> i64: unsafe { LLVMBuildAlloca(b as *mut u8, ty as *mut u8, empty_cstr()) as i64 }

pub fn wl_build_alloca_named(b: i64, ty: i64, name: str) -> i64:
    unsafe:
        LLVMBuildAlloca(b as *mut u8, ty as *mut u8, to_cstr(name)) as i64

pub fn wl_build_load(b: i64, ty: i64, ptr: i64) -> i64:
    unsafe:
        LLVMBuildLoad2(b as *mut u8, ty as *mut u8, ptr as *mut u8, empty_cstr()) as i64

pub fn wl_build_store(b: i64, val: i64, ptr: i64) -> i64:
    unsafe:
        LLVMBuildStore(b as *mut u8, val as *mut u8, ptr as *mut u8) as i64

pub fn wl_set_volatile(inst: i64, is_volatile: i32) -> Unit:
    unsafe:
        LLVMSetVolatile(inst as *mut u8, if is_volatile != 0: 1 else: 0)

pub fn wl_build_load_volatile(b: i64, ty: i64, ptr: i64) -> i64:
    unsafe:
        let load = LLVMBuildLoad2(b as *mut u8, ty as *mut u8, ptr as *mut u8, empty_cstr())
        LLVMSetVolatile(load, 1)
        load as i64

pub fn wl_build_store_volatile(b: i64, val: i64, ptr: i64) -> i64:
    unsafe:
        let store = LLVMBuildStore(b as *mut u8, val as *mut u8, ptr as *mut u8)
        LLVMSetVolatile(store, 1)
        store as i64

pub fn wl_build_gep(b: i64, ty: i64, ptr: i64, idx_ptr: i64, cnt: i32) -> i64:
    unsafe:
        LLVMBuildGEP2(b as *mut u8, ty as *mut u8, ptr as *mut u8, idx_ptr as *const *mut u8, cnt as u32, empty_cstr()) as i64

pub fn wl_build_struct_gep(b: i64, ty: i64, ptr: i64, idx: i32) -> i64:
    unsafe:
        LLVMBuildStructGEP2(b as *mut u8, ty as *mut u8, ptr as *mut u8, idx as u32, empty_cstr()) as i64

// Length-aware replacement for LLVMBuildGlobalStringPtr: the data must not
// go through to_cstr, whose fixed 4096-byte slot silently truncates longer
// strings (and a C-string API would stop at embedded nulls). Emits a private
// null-terminated constant array global and returns it (opaque pointer).
pub fn wl_build_global_string_ptr(b: i64, s: str) -> i64:
    unsafe:
        let bb = LLVMGetInsertBlock(b as *mut u8)
        let func = LLVMGetBasicBlockParent(bb)
        let mod = LLVMGetGlobalParent(func)
        let ctx = LLVMGetModuleContext(mod)
        var sp = *(&s as *const *const u8)
        if sp as i64 == 0:
            sp = empty_cstr()
        // dont_null = 0: LLVM appends the trailing terminator itself.
        let const_str = LLVMConstStringInContext(ctx, sp, s.len() as u32, 0)
        let g = LLVMAddGlobal(mod, LLVMTypeOf(const_str), to_cstr("str"))
        LLVMSetInitializer(g, const_str)
        LLVMSetGlobalConstant(g, 1)
        LLVMSetLinkage(g, LLVM_PrivateLinkage)
        g as i64

// ── Builder: globals ────────────────────────────────────────────

pub fn wl_add_global(m: i64, ty: i64, name: str) -> i64:
    unsafe:
        LLVMAddGlobal(m as *mut u8, ty as *mut u8, to_cstr(name)) as i64

pub fn wl_set_initializer(g: i64, v: i64) -> Unit: unsafe { LLVMSetInitializer(g as *mut u8, v as *mut u8) }
pub fn wl_set_global_constant(g: i64, c: i32) -> Unit: unsafe { LLVMSetGlobalConstant(g as *mut u8, c) }
pub fn wl_set_linkage(g: i64, link: i32) -> Unit: unsafe { LLVMSetLinkage(g as *mut u8, link) }
pub fn wl_set_call_conv(fn_val: i64, cc: i32) -> Unit: unsafe { LLVMSetFunctionCallConv(fn_val as *mut u8, cc as u32) }

pub fn wl_cc_c() -> i32: LLVM_CCallConv
pub fn wl_cc_fast() -> i32: LLVM_FastCallConv
pub fn wl_cc_x86_stdcall() -> i32: LLVM_X86StdcallCallConv
pub fn wl_cc_x86_fastcall() -> i32: LLVM_X86FastcallCallConv
pub fn wl_cc_x86_thiscall() -> i32: 33
pub fn wl_cc_win64() -> i32: LLVM_Win64CallConv
pub fn wl_cc_aarch64_vfabi() -> i32: 97
pub fn wl_internal_linkage() -> i32: LLVM_InternalLinkage
pub fn wl_private_linkage() -> i32: LLVM_PrivateLinkage

// ── Builder: control flow ───────────────────────────────────────

pub fn wl_build_br(b: i64, bb: i64) -> i64: unsafe { LLVMBuildBr(b as *mut u8, bb as *mut u8) as i64 }
pub fn wl_build_cond_br(b: i64, cond: i64, then_bb: i64, else_bb: i64) -> i64:
    unsafe:
        LLVMBuildCondBr(b as *mut u8, cond as *mut u8, then_bb as *mut u8, else_bb as *mut u8) as i64
pub fn wl_build_ret(b: i64, val: i64) -> i64: unsafe { LLVMBuildRet(b as *mut u8, val as *mut u8) as i64 }
pub fn wl_build_ret_void(b: i64) -> i64: unsafe { LLVMBuildRetVoid(b as *mut u8) as i64 }
pub fn wl_build_unreachable(b: i64) -> i64: unsafe { LLVMBuildUnreachable(b as *mut u8) as i64 }
pub fn wl_build_switch(b: i64, val: i64, else_bb: i64, n: i32) -> i64:
    unsafe:
        LLVMBuildSwitch(b as *mut u8, val as *mut u8, else_bb as *mut u8, n as u32) as i64
pub fn wl_add_case(sw: i64, val: i64, bb: i64) -> Unit:
    unsafe:
        LLVMAddCase(sw as *mut u8, val as *mut u8, bb as *mut u8)

// ── Builder: cast ───────────────────────────────────────────────

pub fn wl_build_zext(b: i64, v: i64, ty: i64) -> i64: unsafe { LLVMBuildZExt(b as *mut u8, v as *mut u8, ty as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_sext(b: i64, v: i64, ty: i64) -> i64: unsafe { LLVMBuildSExt(b as *mut u8, v as *mut u8, ty as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_trunc(b: i64, v: i64, ty: i64) -> i64: unsafe { LLVMBuildTrunc(b as *mut u8, v as *mut u8, ty as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_si_to_fp(b: i64, v: i64, ty: i64) -> i64: unsafe { LLVMBuildSIToFP(b as *mut u8, v as *mut u8, ty as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_ui_to_fp(b: i64, v: i64, ty: i64) -> i64: unsafe { LLVMBuildUIToFP(b as *mut u8, v as *mut u8, ty as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_fp_to_si(b: i64, v: i64, ty: i64) -> i64: unsafe { LLVMBuildFPToSI(b as *mut u8, v as *mut u8, ty as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_fp_to_ui(b: i64, v: i64, ty: i64) -> i64: unsafe { LLVMBuildFPToUI(b as *mut u8, v as *mut u8, ty as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_bitcast(b: i64, v: i64, ty: i64) -> i64: unsafe { LLVMBuildBitCast(b as *mut u8, v as *mut u8, ty as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_int_to_ptr(b: i64, v: i64, ty: i64) -> i64: unsafe { LLVMBuildIntToPtr(b as *mut u8, v as *mut u8, ty as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_ptr_to_int(b: i64, v: i64, ty: i64) -> i64: unsafe { LLVMBuildPtrToInt(b as *mut u8, v as *mut u8, ty as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_fp_cast(b: i64, v: i64, ty: i64) -> i64: unsafe { LLVMBuildFPCast(b as *mut u8, v as *mut u8, ty as *mut u8, empty_cstr()) as i64 }
pub fn wl_build_fp_ext(b: i64, v: i64, ty: i64) -> i64: unsafe { LLVMBuildFPExt(b as *mut u8, v as *mut u8, ty as *mut u8, empty_cstr()) as i64 }

// ── Builder: phi / select / extract / insert ────────────────────

pub fn wl_build_phi(b: i64, ty: i64) -> i64: unsafe { LLVMBuildPhi(b as *mut u8, ty as *mut u8, empty_cstr()) as i64 }

pub fn wl_add_incoming(phi: i64, vals_ptr: i64, bbs_ptr: i64, count: i32) -> Unit:
    unsafe:
        LLVMAddIncoming(phi as *mut u8, vals_ptr as *const *mut u8, bbs_ptr as *const *mut u8, count as u32)

pub fn wl_build_select(b: i64, cond: i64, then_v: i64, else_v: i64) -> i64:
    unsafe:
        LLVMBuildSelect(b as *mut u8, cond as *mut u8, then_v as *mut u8, else_v as *mut u8, empty_cstr()) as i64

pub fn wl_build_extract_value(b: i64, agg: i64, idx: i32) -> i64:
    unsafe:
        LLVMBuildExtractValue(b as *mut u8, agg as *mut u8, idx as u32, empty_cstr()) as i64

pub fn wl_build_insert_value(b: i64, agg: i64, val: i64, idx: i32) -> i64:
    unsafe:
        LLVMBuildInsertValue(b as *mut u8, agg as *mut u8, val as *mut u8, idx as u32, empty_cstr()) as i64

// ── Builder: call ───────────────────────────────────────────────

pub fn wl_build_call(b: i64, fn_ty: i64, fn_val: i64, args_ptr: i64, cnt: i32) -> i64:
    unsafe:
        let args = if cnt > 0: args_ptr as *const *mut u8 else: 0 as *const *mut u8
        LLVMBuildCall2(b as *mut u8, fn_ty as *mut u8, fn_val as *mut u8, args, cnt as u32, empty_cstr()) as i64

pub fn wl_set_tail_call(call: i64) -> Unit: unsafe { LLVMSetTailCall(call as *mut u8, 1) }
pub fn wl_set_musttail_call(call: i64) -> Unit: unsafe { LLVMSetTailCallKind(call as *mut u8, LLVM_TailCallKindMustTail) }

// ── Misc builder / value ops ────────────────────────────────────

pub fn wl_instruction_erase(v: i64) -> Unit: unsafe { LLVMInstructionEraseFromParent(v as *mut u8) }
pub fn wl_get_value_kind(v: i64) -> i32: unsafe { LLVMGetValueKind(v as *mut u8) }
pub fn wl_get_first_use(v: i64) -> i64: unsafe { LLVMGetFirstUse(v as *mut u8) as i64 }

pub fn wl_set_value_name(v: i64, name: str) -> Unit:
    unsafe:
        let sp = *(&name as *const *const u8)
        LLVMSetValueName2(v as *mut u8, sp, name.len() as u64)

// ── Intrinsics ──────────────────────────────────────────────────

pub fn wl_lookup_intrinsic_id(name: str) -> i32:
    unsafe:
        let sp = *(&name as *const *const u8)
        LLVMLookupIntrinsicID(sp, name.len() as u64) as i32

pub fn wl_get_intrinsic_decl(m: i64, id: i32, tys_ptr: i64, cnt: i32) -> i64:
    unsafe:
        LLVMGetIntrinsicDeclaration(m as *mut u8, id as u32, tys_ptr as *const *mut u8, cnt as u64) as i64

pub fn wl_intrinsic_get_type(ctx: i64, id: i32, tys_ptr: i64, cnt: i32) -> i64:
    unsafe:
        LLVMIntrinsicGetType(ctx as *mut u8, id as u32, tys_ptr as *const *mut u8, cnt as u64) as i64

// ── Data layout queries ─────────────────────────────────────────

pub fn wl_get_module_data_layout(m: i64) -> i64: unsafe { LLVMGetModuleDataLayout(m as *mut u8) as i64 }

pub fn wl_abi_size_of(dl: i64, ty: i64) -> i64:
    unsafe:
        if dl == 0 or ty == 0: return 0
        LLVMABISizeOfType(dl as *mut u8, ty as *mut u8) as i64

pub fn wl_abi_align_of(dl: i64, ty: i64) -> i32:
    unsafe:
        if dl == 0 or ty == 0: return 1
        LLVMABIAlignmentOfType(dl as *mut u8, ty as *mut u8) as i32

// ── Struct name ─────────────────────────────────────────────────

pub fn wl_get_struct_name(ty: i64) -> str:
    unsafe:
        let name = LLVMGetStructName(ty as *mut u8)
        if name as i64 == 0: return ""
        let len = c_strlen(name)
        var raw: [2]i64 = [name as i64, len]
        let p = &raw as *const str
        *p

// ── Param types ─────────────────────────────────────────────────

pub fn wl_get_param_types(fn_ty: i64, out_ptr: i64) -> Unit:
    unsafe:
        LLVMGetParamTypes(fn_ty as *mut u8, out_ptr as *mut *mut u8)

pub fn wl_get_fn_param_type(fn_ty: i64, index: i32) -> i64:
    unsafe:
        let count = LLVMCountParamTypes(fn_ty as *mut u8)
        if index as u32 >= count: return 0
        var params: [128]i64 = [0 as i64; 128]
        let actual_count = if count > 128: 128 else: count
        LLVMGetParamTypes(fn_ty as *mut u8, &params as *mut *mut u8)
        params[index as i64]

// ── Module verification / emission ──────────────────────────────

pub fn wl_verify_module(m: i64) -> i32:
    unsafe:
        var err: *mut u8 = 0 as *mut u8
        let result = LLVMVerifyModule(m as *mut u8, LLVM_ReturnStatusAction, &raw mut err)
        if err as i64 != 0:
            if result != 0:
                let msg = "LLVM verify error\n"
                let _ = rt_write(2, msg as *const u8, 18)
                let err_len = c_strlen(err as *const u8)
                if err_len > 0:
                    let _ = rt_write(2, err as *const u8, err_len as u64)
                    let _ = rt_write(2, "\n" as *const u8, 1)
            LLVMDisposeMessage(err)
        result

pub fn wl_emit_object(tm: i64, m: i64, path: str) -> i32:
    unsafe:
        if tm == 0:
            let msg = "LLVM emit error: null target machine\n"
            let _ = rt_write(2, msg as *const u8, 37)
            return 1
        if m == 0:
            let msg = "LLVM emit error: null module\n"
            let _ = rt_write(2, msg as *const u8, 29)
            return 1
        var path_buf: [4096]u8 = [0 as u8; 4096]
        let n = if path.len() < 4095: path.len() else: 4095
        let sp = *(&path as *const *const u8)
        with_memcpy(&path_buf as *mut u8, sp, n)
        path_buf[n] = 0
        var err: *mut u8 = 0 as *mut u8
        let result = LLVMTargetMachineEmitToFile(tm as *mut u8, m as *mut u8, &path_buf as *mut u8, LLVM_ObjectFile, &raw mut err)
        if result != 0 and err as i64 != 0:
            let msg = "LLVM emit error\n"
            let _ = rt_write(2, msg as *const u8, 16)
            LLVMDisposeMessage(err)
        result

pub fn wl_optimize(m: i64, tm: i64, level: i32) -> Unit:
    unsafe:
        let passes = if level == 0: "default<O0>"
            else if level == 1: "default<O1>"
            else if level == 3: "default<O3>"
            else: "default<O2>"
        let opts = LLVMCreatePassBuilderOptions()
        let err = LLVMRunPasses(m as *mut u8, to_cstr(passes), tm as *mut u8, opts)
        if err as i64 != 0:
            let msg = LLVMGetErrorMessage(err)
            if msg as i64 != 0: LLVMDisposeErrorMessage(msg)
        LLVMDisposePassBuilderOptions(opts)

pub fn wl_run_always_inline(m: i64, tm: i64) -> Unit:
    unsafe:
        let opts = LLVMCreatePassBuilderOptions()
        let err = LLVMRunPasses(m as *mut u8, to_cstr("always-inline"), tm as *mut u8, opts)
        if err as i64 != 0:
            let msg = LLVMGetErrorMessage(err)
            if msg as i64 != 0: LLVMDisposeErrorMessage(msg)
        LLVMDisposePassBuilderOptions(opts)

pub fn wl_promote_allocas(fn_val: i64, tm: i64) -> Unit:
    unsafe:
        let opts = LLVMCreatePassBuilderOptions()
        let err = LLVMRunPassesOnFunction(fn_val as *mut u8, to_cstr("mem2reg"), tm as *mut u8, opts)
        if err as i64 != 0:
            let msg = LLVMGetErrorMessage(err)
            if msg as i64 != 0: LLVMDisposeErrorMessage(msg)
        LLVMDisposePassBuilderOptions(opts)

pub fn wl_run_function_passes(fn_val: i64, tm: i64, passes: str) -> i32:
    unsafe:
        let opts = LLVMCreatePassBuilderOptions()
        let err = LLVMRunPassesOnFunction(fn_val as *mut u8, to_cstr(passes), tm as *mut u8, opts)
        if err as i64 != 0:
            let msg = LLVMGetErrorMessage(err)
            if msg as i64 != 0:
                let len = c_strlen(msg as *const u8)
                if len > 0:
                    let _ = rt_write(2, msg as *const u8, len as u64)
                    let _ = rt_write(2, "\n" as *const u8, 1)
                LLVMDisposeErrorMessage(msg)
            LLVMDisposePassBuilderOptions(opts)
            return 1
        LLVMDisposePassBuilderOptions(opts)
        0

pub fn wl_verify_function(fn_val: i64) -> i32:
    unsafe:
        LLVMVerifyFunction(fn_val as *mut u8, LLVM_ReturnStatusAction)

pub fn wl_dump_value(v: i64) -> Unit: unsafe { LLVMDumpValue(v as *mut u8) }

pub fn wl_print_ir(m: i64) -> Unit:
    unsafe:
        let ir = LLVMPrintModuleToString(m as *mut u8)
        if ir as i64 != 0:
            let len = c_strlen(ir as *const u8)
            let _ = rt_write(1, ir as *const u8, len as u64)
            LLVMDisposeMessage(ir)

// ── Vec data pointer helper ─────────────────────────────────────

type WithVec {
    ptr: *mut u8,
    len: i64,
    cap: i64,
    elem_size: i64,
}

pub fn wl_vec_data_ptr(v: i64) -> i64:
    if v == 0: return 0
    (unsafe *(v as *const WithVec)).ptr as i64

// ── Entry alloca helper ─────────────────────────────────────────

pub fn wl_create_entry_alloca(builder: i64, fn_val: i64, ty: i64) -> i64:
    unsafe:
        let entry = LLVMGetEntryBasicBlock(fn_val as *mut u8)
        let first = LLVMGetFirstInstruction(entry)
        let saved = LLVMGetInsertBlock(builder as *mut u8)
        let saved_loc = LLVMGetCurrentDebugLocation2(builder as *mut u8)
        if first as i64 != 0:
            let _ = LLVMPositionBuilderBefore(builder as *mut u8, first)
        else:
            let _ = LLVMPositionBuilderAtEnd(builder as *mut u8, entry)
        let alloca = LLVMBuildAlloca(builder as *mut u8, ty as *mut u8, empty_cstr())
        LLVMPositionBuilderAtEnd(builder as *mut u8, saved)
        LLVMSetCurrentDebugLocation2(builder as *mut u8, saved_loc)
        alloca as i64

// ── Debug info (DWARF) ──────────────────────────────────────────

pub fn wl_di_create_builder(mod_ref: i64) -> i64: unsafe { LLVMCreateDIBuilder(mod_ref as *mut u8) as i64 }

pub fn wl_di_dispose_builder(builder: i64) -> Unit: unsafe { LLVMDisposeDIBuilder(builder as *mut u8) }

pub fn wl_di_finalize(builder: i64) -> Unit: unsafe { LLVMDIBuilderFinalize(builder as *mut u8) }

pub fn wl_debug_metadata_version() -> i32: unsafe { LLVMDebugMetadataVersion() as i32 }

pub fn wl_add_module_flag_int(mod_ref: i64, key: str, val: i32) -> Unit:
    unsafe:
        let k = to_cstr(key)
        let ctx = LLVMGetModuleContext(mod_ref as *mut u8)
        let int_val = LLVMConstInt(LLVMInt32TypeInContext(ctx), val as u64, 0)
        let md = LLVMValueAsMetadata(int_val)
        LLVMAddModuleFlag(mod_ref as *mut u8, LLVM_ModuleFlagBehaviorWarning, k, c_strlen(k) as u64, md)

pub fn wl_di_create_file(builder: i64, filename: str, directory: str) -> i64:
    unsafe:
        let fn_ptr = *(&filename as *const *const u8)
        let dir_ptr = *(&directory as *const *const u8)
        LLVMDIBuilderCreateFile(builder as *mut u8, fn_ptr, filename.len() as u64, dir_ptr, directory.len() as u64) as i64

pub fn wl_di_create_compile_unit(builder: i64, file: i64, producer: str, is_optimized: i32, dwarf_version: i32, lang: i32) -> i64:
    unsafe:
        let _ = dwarf_version
        let pp = *(&producer as *const *const u8)
        LLVMDIBuilderCreateCompileUnit(builder as *mut u8, lang, file as *mut u8,
            pp, producer.len() as u64, is_optimized,
            empty_cstr(), 0, 0, empty_cstr(), 0,
            LLVM_DWARFEmissionFull, 0, 0, 0,
            empty_cstr(), 0, empty_cstr(), 0) as i64

pub fn wl_di_create_subroutine_type(builder: i64, file: i64, param_types_ptr: i64, count: i32) -> i64:
    unsafe:
        let params = if count > 0: param_types_ptr as *const *mut u8 else: 0 as *const *mut u8
        LLVMDIBuilderCreateSubroutineType(builder as *mut u8, file as *mut u8, params, count as u32, LLVM_DIFlagZero) as i64

pub fn wl_di_create_function(builder: i64, scope: i64, name: str, linkage_name: str, file: i64, line: i32, ty: i64, is_definition: i32, scope_line: i32, is_optimized: i32) -> i64:
    unsafe:
        let np = *(&name as *const *const u8)
        let lp = *(&linkage_name as *const *const u8)
        LLVMDIBuilderCreateFunction(builder as *mut u8, scope as *mut u8,
            np, name.len() as u64, lp, linkage_name.len() as u64,
            file as *mut u8, line as u32, ty as *mut u8,
            0, is_definition, scope_line as u32, LLVM_DIFlagZero, is_optimized) as i64

pub fn wl_di_set_subprogram(function: i64, subprogram: i64) -> Unit:
    unsafe:
        LLVMSetSubprogram(function as *mut u8, subprogram as *mut u8)

pub fn wl_di_create_debug_location(context: i64, line: i32, col: i32, scope: i64) -> i64:
    unsafe:
        LLVMDIBuilderCreateDebugLocation(context as *mut u8, line as u32, col as u32, scope as *mut u8, 0 as *mut u8) as i64

pub fn wl_di_set_current_location(builder: i64, location: i64) -> Unit:
    unsafe:
        LLVMSetCurrentDebugLocation2(builder as *mut u8, location as *mut u8)

pub fn wl_di_clear_current_location(builder: i64) -> Unit:
    unsafe:
        LLVMSetCurrentDebugLocation2(builder as *mut u8, 0 as *mut u8)

pub fn wl_di_flag_zero() -> i32: LLVM_DIFlagZero
pub fn wl_dwarf_lang_c() -> i32: LLVM_DWARFSourceLanguageC
pub fn wl_dwarf_lang_with() -> i32: LLVM_DWARFSourceLanguageC

// DW_ATE encoding constants
pub fn wl_dwarf_ate_boolean() -> i32: 2
pub fn wl_dwarf_ate_float() -> i32: 4
pub fn wl_dwarf_ate_signed() -> i32: 5
pub fn wl_dwarf_ate_unsigned() -> i32: 7

// DI type constructors

pub fn wl_di_create_basic_type(builder: i64, name: str, size_in_bits: u64, encoding: i32) -> i64:
    unsafe:
        let np = *(&name as *const *const u8)
        LLVMDIBuilderCreateBasicType(builder as *mut u8, np, name.len() as u64, size_in_bits, encoding, LLVM_DIFlagZero) as i64

pub fn wl_di_create_pointer_type(builder: i64, pointee_ty: i64, size_in_bits: u64) -> i64:
    unsafe:
        let pt = if pointee_ty != 0: pointee_ty as *mut u8 else: 0 as *mut u8
        LLVMDIBuilderCreatePointerType(builder as *mut u8, pt, size_in_bits, 0, 0, empty_cstr(), 0) as i64

pub fn wl_di_create_struct_type(builder: i64, scope: i64, name: str, file: i64, line: i32, size_in_bits: u64, align_in_bits: u32, elements_ptr: i64, num_elements: i32) -> i64:
    unsafe:
        let np = *(&name as *const *const u8)
        let sc = if scope != 0: scope as *mut u8 else: 0 as *mut u8
        let fi = if file != 0: file as *mut u8 else: 0 as *mut u8
        let elems = if num_elements > 0: elements_ptr as *const *mut u8 else: 0 as *const *mut u8
        LLVMDIBuilderCreateStructType(builder as *mut u8, sc, np, name.len() as u64, fi, line as u32, size_in_bits, align_in_bits, LLVM_DIFlagZero, 0 as *mut u8, elems, num_elements as u32, 0, 0 as *mut u8, empty_cstr(), 0) as i64

pub fn wl_di_create_member_type(builder: i64, scope: i64, name: str, file: i64, line: i32, size_in_bits: u64, align_in_bits: u32, offset_in_bits: u64, ty: i64) -> i64:
    unsafe:
        let np = *(&name as *const *const u8)
        let sc = if scope != 0: scope as *mut u8 else: 0 as *mut u8
        let fi = if file != 0: file as *mut u8 else: 0 as *mut u8
        LLVMDIBuilderCreateMemberType(builder as *mut u8, sc, np, name.len() as u64, fi, line as u32, size_in_bits, align_in_bits, offset_in_bits, LLVM_DIFlagZero, ty as *mut u8) as i64

pub fn wl_di_create_unspecified_type(builder: i64, name: str) -> i64:
    unsafe:
        let np = *(&name as *const *const u8)
        LLVMDIBuilderCreateUnspecifiedType(builder as *mut u8, np, name.len() as u64) as i64

pub fn wl_di_create_auto_variable(builder: i64, scope: i64, name: str, file: i64, line: i32, ty: i64) -> i64:
    unsafe:
        let np = *(&name as *const *const u8)
        LLVMDIBuilderCreateAutoVariable(builder as *mut u8, scope as *mut u8, np, name.len() as u64, file as *mut u8, line as u32, ty as *mut u8, 1, LLVM_DIFlagZero, 0) as i64

pub fn wl_di_create_parameter_variable(builder: i64, scope: i64, name: str, arg_no: i32, file: i64, line: i32, ty: i64) -> i64:
    unsafe:
        let np = *(&name as *const *const u8)
        LLVMDIBuilderCreateParameterVariable(builder as *mut u8, scope as *mut u8, np, name.len() as u64, arg_no as u32, file as *mut u8, line as u32, ty as *mut u8, 1, LLVM_DIFlagZero) as i64

pub fn wl_di_create_expression(builder: i64) -> i64:
    unsafe:
        LLVMDIBuilderCreateExpression(builder as *mut u8, 0 as *const i64, 0) as i64

pub fn wl_di_insert_declare_at_end(builder: i64, storage: i64, var_info: i64, expr: i64, debug_loc: i64, block: i64) -> Unit:
    unsafe:
        LLVMDIBuilderInsertDeclareRecordAtEnd(builder as *mut u8, storage as *mut u8, var_info as *mut u8, expr as *mut u8, debug_loc as *mut u8, block as *mut u8)

pub fn wl_di_create_lexical_block(builder: i64, scope: i64, file: i64, line: i32, col: i32) -> i64:
    unsafe:
        LLVMDIBuilderCreateLexicalBlock(builder as *mut u8, scope as *mut u8, file as *mut u8, line as u32, col as u32) as i64

// ── Atomic Operations ───────────────────────────────────────────

fn map_ordering(order: i32) -> i32:
    if order == 0: return LLVM_AtomicOrderingMonotonic
    if order == 1: return LLVM_AtomicOrderingAcquire
    if order == 2: return LLVM_AtomicOrderingRelease
    if order == 3: return LLVM_AtomicOrderingAcquireRelease
    LLVM_AtomicOrderingSequentiallyConsistent

pub fn wl_build_atomic_load(b: i64, ty: i64, ptr: i64, order: i32) -> i64:
    unsafe:
        let load = LLVMBuildLoad2(b as *mut u8, ty as *mut u8, ptr as *mut u8, "atomic_load" as *const u8)
        LLVMSetOrdering(load, map_ordering(order))
        let dl = LLVMGetModuleDataLayout(LLVMGetGlobalParent(LLVMGetBasicBlockParent(LLVMGetInsertBlock(b as *mut u8))))
        LLVMSetAlignment(load, LLVMABIAlignmentOfType(dl, ty as *mut u8))
        load as i64

pub fn wl_build_atomic_store(b: i64, val: i64, ptr: i64, order: i32) -> Unit:
    unsafe:
        let store = LLVMBuildStore(b as *mut u8, val as *mut u8, ptr as *mut u8)
        LLVMSetOrdering(store, map_ordering(order))
        let dl = LLVMGetModuleDataLayout(LLVMGetGlobalParent(LLVMGetBasicBlockParent(LLVMGetInsertBlock(b as *mut u8))))
        LLVMSetAlignment(store, LLVMABIAlignmentOfType(dl, LLVMTypeOf(val as *mut u8)))

fn map_rmw_op(rmw_op: i32) -> i32:
    if rmw_op == 0: return LLVM_AtomicRMWBinOpXchg
    if rmw_op == 1: return LLVM_AtomicRMWBinOpAdd
    if rmw_op == 2: return LLVM_AtomicRMWBinOpSub
    if rmw_op == 3: return LLVM_AtomicRMWBinOpAnd
    if rmw_op == 4: return LLVM_AtomicRMWBinOpOr
    if rmw_op == 5: return LLVM_AtomicRMWBinOpXor
    if rmw_op == 6: return LLVM_AtomicRMWBinOpMin
    if rmw_op == 7: return LLVM_AtomicRMWBinOpMax
    if rmw_op == 8: return LLVM_AtomicRMWBinOpUMin
    if rmw_op == 9: return LLVM_AtomicRMWBinOpUMax
    LLVM_AtomicRMWBinOpXchg

pub fn wl_build_atomic_rmw(b: i64, rmw_op: i32, ptr: i64, val: i64, order: i32) -> i64:
    unsafe:
        LLVMBuildAtomicRMW(b as *mut u8, map_rmw_op(rmw_op), ptr as *mut u8, val as *mut u8, map_ordering(order), 0) as i64

pub fn wl_build_cmpxchg(b: i64, ptr: i64, expected: i64, desired: i64, success_order: i32, failure_order: i32, is_weak: i32) -> i64:
    unsafe:
        let result = LLVMBuildAtomicCmpXchg(b as *mut u8, ptr as *mut u8, expected as *mut u8, desired as *mut u8, map_ordering(success_order), map_ordering(failure_order), 0)
        if is_weak != 0: LLVMSetWeak(result, 1)
        result as i64

pub fn wl_extract_value(b: i64, agg: i64, index: i32) -> i64:
    unsafe:
        LLVMBuildExtractValue(b as *mut u8, agg as *mut u8, index as u32, empty_cstr()) as i64

pub fn wl_build_fence(b: i64, order: i32) -> Unit:
    unsafe:
        let _ = LLVMBuildFence(b as *mut u8, map_ordering(order), 0, empty_cstr())

// ── Inline Assembly ─────────────────────────────────────────────

pub fn wl_get_inline_asm(fn_ty: i64, asm_str: str, constraints: str, has_side_effects: i32, is_align_stack: i32) -> i64:
    unsafe:
        let ap = *(&asm_str as *const *const u8)
        let cp = *(&constraints as *const *const u8)
        LLVMGetInlineAsm(fn_ty as *mut u8,
            ap, asm_str.len() as u64,
            cp, constraints.len() as u64,
            if has_side_effects != 0: 1 else: 0,
            if is_align_stack != 0: 1 else: 0,
            LLVM_InlineAsmDialectATT, 0) as i64

// ── Standalone file compilation ─────────────────────────────────

fn path_to_cstr(path: str, buf: *mut u8) -> *const u8:
    let n = if path.len() < 4095: path.len() else: 4095
    let src = unsafe *(&path as *const *const u8)
    with_memcpy(buf, src, n)
    unsafe *((buf as i64 + n) as *mut u8) = 0
    buf as *const u8

pub fn wl_assemble_to_object(source_path: str, output_path: str) -> i32:
    unsafe:
        let _ = wl_init_native_target()
        let _ = wl_init_native_asm_printer()
        let _ = wl_init_native_asm_parser()
        var src_buf: [4096]u8 = [0 as u8; 4096]
        let src_cstr = path_to_cstr(source_path, &src_buf as *mut u8)
        var mem_buf: *mut u8 = 0 as *mut u8
        var err: *mut u8 = 0 as *mut u8
        if LLVMCreateMemoryBufferWithContentsOfFile(src_cstr, &raw mut mem_buf, &raw mut err) != 0:
            if err as i64 != 0:
                let _ = rt_write(2, "error: could not read assembly file\n" as *const u8, 36)
                LLVMDisposeMessage(err)
            return 1
        let asm_ptr = LLVMGetBufferStart(mem_buf)
        let asm_len = LLVMGetBufferSize(mem_buf)
        let ctx = LLVMContextCreate()
        let m = LLVMModuleCreateWithNameInContext("asm\0" as *const u8, ctx)
        let triple = LLVMGetDefaultTargetTriple()
        LLVMSetTarget(m, triple as *const u8)
        LLVMSetModuleInlineAsm2(m, asm_ptr, asm_len)
        LLVMDisposeMemoryBuffer(mem_buf)
        var target: *mut u8 = 0 as *mut u8
        var terr: *mut u8 = 0 as *mut u8
        if LLVMGetTargetFromTriple(triple as *const u8, &raw mut target, &raw mut terr) != 0:
            if terr as i64 != 0: LLVMDisposeMessage(terr)
            LLVMDisposeMessage(triple)
            LLVMDisposeModule(m)
            LLVMContextDispose(ctx)
            return 1
        let tm = LLVMCreateTargetMachine(target, triple as *const u8, c"generic".ptr, empty_cstr(), LLVM_CodeGenLevelDefault, LLVM_RelocDefault, LLVM_CodeModelDefault)
        LLVMDisposeMessage(triple)
        var out_buf: [4096]u8 = [0 as u8; 4096]
        let out_cstr = path_to_cstr(output_path, &out_buf as *mut u8)
        var emit_err: *mut u8 = 0 as *mut u8
        let rc = LLVMTargetMachineEmitToFile(tm, m, out_cstr as *mut u8, LLVM_ObjectFile, &raw mut emit_err)
        if rc != 0 and emit_err as i64 != 0:
            let _ = rt_write(2, "error: assembly emit failed\n" as *const u8, 28)
            LLVMDisposeMessage(emit_err)
        LLVMDisposeTargetMachine(tm)
        LLVMDisposeModule(m)
        LLVMContextDispose(ctx)
        rc

pub fn wl_compile_ir_to_object(source_path: str, output_path: str) -> i32:
    unsafe:
        let _ = wl_init_native_target()
        let _ = wl_init_native_asm_printer()
        var src_buf: [4096]u8 = [0 as u8; 4096]
        let src_cstr = path_to_cstr(source_path, &src_buf as *mut u8)
        var mem_buf: *mut u8 = 0 as *mut u8
        var err: *mut u8 = 0 as *mut u8
        if LLVMCreateMemoryBufferWithContentsOfFile(src_cstr, &raw mut mem_buf, &raw mut err) != 0:
            if err as i64 != 0:
                let _ = rt_write(2, "error: could not read IR file\n" as *const u8, 30)
                LLVMDisposeMessage(err)
            return 1
        let ctx = LLVMContextCreate()
        var m: *mut u8 = 0 as *mut u8
        var parse_err: *mut u8 = 0 as *mut u8
        if LLVMParseIRInContext2(ctx, mem_buf, &raw mut m, &raw mut parse_err) != 0:
            if parse_err as i64 != 0:
                let _ = rt_write(2, "error: IR parse failed\n" as *const u8, 22)
                LLVMDisposeMessage(parse_err)
            LLVMContextDispose(ctx)
            return 1
        let triple = LLVMGetDefaultTargetTriple()
        LLVMSetTarget(m, triple as *const u8)
        var target: *mut u8 = 0 as *mut u8
        var terr: *mut u8 = 0 as *mut u8
        if LLVMGetTargetFromTriple(triple as *const u8, &raw mut target, &raw mut terr) != 0:
            if terr as i64 != 0: LLVMDisposeMessage(terr)
            LLVMDisposeMessage(triple)
            LLVMDisposeModule(m)
            LLVMContextDispose(ctx)
            return 1
        let tm = LLVMCreateTargetMachine(target, triple as *const u8, c"generic".ptr, empty_cstr(), LLVM_CodeGenLevelDefault, LLVM_RelocDefault, LLVM_CodeModelDefault)
        let layout = LLVMCreateTargetDataLayout(tm)
        LLVMSetModuleDataLayout(m, layout)
        LLVMDisposeTargetData(layout)
        LLVMDisposeMessage(triple)
        var out_buf: [4096]u8 = [0 as u8; 4096]
        let out_cstr = path_to_cstr(output_path, &out_buf as *mut u8)
        var emit_err: *mut u8 = 0 as *mut u8
        let rc = LLVMTargetMachineEmitToFile(tm, m, out_cstr as *mut u8, LLVM_ObjectFile, &raw mut emit_err)
        if rc != 0 and emit_err as i64 != 0:
            let _ = rt_write(2, "error: IR emit failed\n" as *const u8, 21)
            LLVMDisposeMessage(emit_err)
        LLVMDisposeTargetMachine(tm)
        LLVMDisposeModule(m)
        LLVMContextDispose(ctx)
        rc
