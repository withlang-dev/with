//! LLVM IR code generation from the With AST.
//!
//! Translates parsed AST nodes into LLVM IR using the LLVM-C API,
//! then emits object files via the LLVM target machine.

const std = @import("std");
const Ast = @import("Ast.zig");
const InternPool = @import("InternPool.zig");

const c = @cImport({
    @cInclude("llvm-c/Core.h");
    @cInclude("llvm-c/Target.h");
    @cInclude("llvm-c/TargetMachine.h");
    @cInclude("llvm-c/Analysis.h");
    @cInclude("llvm-c/Transforms/PassBuilder.h");
});

const Codegen = @This();

context: c.LLVMContextRef,
module: c.LLVMModuleRef,
builder: c.LLVMBuilderRef,
target_machine: c.LLVMTargetMachineRef,
pool: *InternPool,
allocator: std.mem.Allocator,
/// The LLVM return type of the function currently being generated.
current_ret_type: c.LLVMTypeRef,
/// The LLVM function currently being generated (needed for creating BBs).
current_function: c.LLVMValueRef,
/// Local variables in the current function: Symbol → alloca + type.
locals: std.AutoHashMapUnmanaged(u32, LocalInfo),
/// All declared functions/externs: Symbol → LLVM function + type.
functions: std.AutoHashMapUnmanaged(u32, FnInfo),
/// User-defined struct types: Symbol → StructTypeInfo.
struct_types: std.AutoHashMapUnmanaged(u32, StructTypeInfo),
/// User-defined enum types: Symbol → EnumTypeInfo.
enum_types: std.AutoHashMapUnmanaged(u32, EnumTypeInfo),
/// Enum types indexed by LLVM type pointer (for match expression lookup).
enum_types_by_llvm: std.AutoHashMapUnmanaged(usize, EnumTypeInfo),
/// Generic function ASTs: Symbol → FnDecl (for monomorphization).
generic_fns: std.AutoHashMapUnmanaged(u32, Ast.FnDecl),
/// Generic struct type declarations: Symbol → TypeDecl (for monomorphization).
generic_structs: std.AutoHashMapUnmanaged(u32, Ast.TypeDecl),
/// Already-monomorphized specializations: mangled name → FnInfo.
mono_cache: std.AutoHashMapUnmanaged(u64, FnInfo),
/// Type aliases: Symbol → LLVM type.
type_aliases: std.AutoHashMapUnmanaged(u32, c.LLVMTypeRef),
/// Module-level constants: Symbol → LLVM global value.
module_constants: std.AutoHashMapUnmanaged(u32, c.LLVMValueRef) = .{},
/// Stack of loop contexts for break/continue.
loop_stack: [16]LoopContext = undefined,
loop_depth: u32 = 0,
/// Tail-call optimization state: when non-null, recursive calls branch back.
tailrec_body_bb: ?c.LLVMBasicBlockRef = null,
tailrec_param_allocas: ?[]c.LLVMValueRef = null,
tailrec_fn_sym: ?u32 = null,
closure_counter: u32 = 0,
/// Defer stack for current function.
defer_stack: [32]*const Ast.Expr = undefined,
defer_depth: u32 = 0,
/// Inferred return types from Sema: fn name → synthetic TypeExpr.
inferred_return_types: std.AutoHashMapUnmanaged(u32, *const Ast.TypeExpr) = .{},
/// Tracks pointee types for references created by &expr.
ref_pointee_types: std.AutoHashMapUnmanaged(u32, c.LLVMTypeRef) = .{},
/// Type context for expressions (set by let bindings, return types, etc.).
expected_type: ?c.LLVMTypeRef = null,
/// Cache of Option enum types keyed by payload LLVM type pointer (cast to usize).
option_type_cache: std.AutoHashMapUnmanaged(usize, OptionResultInfo) = .{},
/// Cache of Result enum types keyed by hash of (ok_type, err_type).
result_type_cache: std.AutoHashMapUnmanaged(u64, OptionResultInfo) = .{},
/// Cache of ContextError structs keyed by source error LLVM type pointer.
context_error_type_cache: std.AutoHashMapUnmanaged(usize, ContextErrorInfo) = .{},
/// Slice element types: local symbol → element LLVM type.
/// Tracks which locals are slice types so we can index into them.
slice_elem_types: std.AutoHashMapUnmanaged(u32, c.LLVMTypeRef) = .{},
/// Enum-typed locals: local symbol → enum type symbol.
/// Tracks which locals hold enum values for println.
enum_local_types: std.AutoHashMapUnmanaged(u32, u32) = .{},
/// Drop functions: struct type Symbol → FnInfo for Type.drop.
drop_fns: std.AutoHashMapUnmanaged(u32, FnInfo) = .{},
/// Trait declarations: trait name Symbol → TraitInfo.
trait_infos: std.AutoHashMapUnmanaged(u32, TraitInfo) = .{},
/// Trait AST declarations: trait name Symbol → TraitDecl (for default method bodies).
trait_decl_map: std.AutoHashMapUnmanaged(u32, Ast.TraitDecl) = .{},
/// VTable globals: hash(type_sym, trait_sym) → LLVM global vtable constant.
vtable_globals: std.AutoHashMapUnmanaged(u64, c.LLVMValueRef) = .{},
/// Trait-typed locals: local Symbol → trait Symbol (tracks which trait a dyn param holds).
trait_locals: std.AutoHashMapUnmanaged(u32, u32) = .{},
/// Dyn-typed locals with known concrete implementor: local Symbol → concrete type Symbol.
/// Used for direct-call devirtualization when concrete type is known at compile time.
trait_local_concrete_types: std.AutoHashMapUnmanaged(u32, u32) = .{},
/// For functions with dyn Trait params: fn_sym → array of ?trait_sym per param.
/// null means non-trait param.
fn_dyn_params: std.AutoHashMapUnmanaged(u32, []const ?u32) = .{},
/// For functions with &T ref params: fn_sym → array of bools per param.
/// true means the param is a reference type (&T or &mut T).
fn_ref_params: std.AutoHashMapUnmanaged(u32, []const bool) = .{},
/// For functions returning Result[_, E]: fn_sym → E symbol (when named).
fn_result_err_symbols: std.AutoHashMapUnmanaged(u32, u32) = .{},
/// Functions declared with a Result return type.
fn_returns_result: std.AutoHashMapUnmanaged(u32, void) = .{},
/// Functions returning Result[Unit, E] (implicit Ok(()) on empty tail).
fn_result_unit_returns: std.AutoHashMapUnmanaged(u32, void) = .{},
/// Current function's Result error symbol (if return type is Result[_, E]).
current_result_err_symbol: ?u32 = null,
/// Current function has declared return type Result[_, _].
current_fn_returns_result: bool = false,
/// Whether an explicit `return` was emitted in the current function.
current_fn_saw_explicit_return: bool = false,
/// Async function symbols (spawn wrappers) for await/task tracking.
async_fn_symbols: std.AutoHashMapUnmanaged(u32, void) = .{},
/// Async function result types: async fn symbol -> implementation return type.
async_fn_ret_types: std.AutoHashMapUnmanaged(u32, c.LLVMTypeRef) = .{},
/// Locals known to hold task IDs.
task_locals: std.AutoHashMapUnmanaged(u32, void) = .{},
/// Task local result types: local symbol -> awaited result LLVM type.
task_local_result_types: std.AutoHashMapUnmanaged(u32, c.LLVMTypeRef) = .{},
/// Locals known to hold containers of Task values:
/// local symbol -> task payload LLVM type.
task_container_local_elem_types: std.AutoHashMapUnmanaged(u32, c.LLVMTypeRef) = .{},
/// Active async-scope tracking frames (`async scope |s|:`).
async_scope_frames: [16]AsyncScopeFrame = undefined,
async_scope_depth: u32 = 0,
/// Stack of scoped local variable lists for Drop emission.
/// Each entry is the count of locals at block entry; on block exit we
/// drop everything above that watermark in reverse order.
scope_locals: [64]ScopedLocal = undefined,
scope_local_count: u32 = 0,
/// Comptime error message (set by comptime_error call, read by Driver).
comptime_error_msg: ?[]const u8 = null,
/// Codegen error detail message (set before returning codegen errors, read by Driver).
codegen_error_detail: ?[]const u8 = null,
/// Generator state: pointer to the state struct (self param) during next() codegen.
gen_state_ptr: ?c.LLVMValueRef = null,
/// Generator state: the LLVM struct type of the state.
gen_state_type: ?c.LLVMTypeRef = null,
/// Generator state: mapping from local symbol → field index in state struct.
gen_field_indices: std.AutoHashMapUnmanaged(u32, u32) = .{},
/// Generator state: array of resume basic blocks (one per yield point).
gen_resume_bbs: [32]c.LLVMBasicBlockRef = undefined,
/// Generator state: the "done" basic block (returns None).
gen_done_bb: ?c.LLVMBasicBlockRef = null,
/// Generator state: the Option type for yield values.
gen_option_type: ?c.LLVMTypeRef = null,
/// Generator state: the payload type for yield values.
gen_payload_type: ?c.LLVMTypeRef = null,
/// Generator state: number of yield points found.
gen_yield_count: u32 = 0,
/// Generator state: current yield index during codegen.
gen_current_yield: u32 = 0,
/// Cache of Vec types keyed by element LLVM type pointer.
vec_type_cache: std.AutoHashMapUnmanaged(usize, VecTypeInfo) = .{},
/// Vec-typed locals: local symbol → element LLVM type.
vec_local_types: std.AutoHashMapUnmanaged(u32, c.LLVMTypeRef) = .{},
/// Cache of HashMap types keyed by combined key+val type pointer hash.
hashmap_type_cache: std.AutoHashMapUnmanaged(u64, HashMapTypeInfo) = .{},
/// HashMap-typed locals: local symbol → HashMapTypeInfo.
hashmap_local_types: std.AutoHashMapUnmanaged(u32, HashMapTypeInfo) = .{},
/// Cache of HashSet types keyed by element type pointer.
hashset_type_cache: std.AutoHashMapUnmanaged(usize, HashSetTypeInfo) = .{},
/// `@[derive(Builder)]` metadata keyed by owner type symbol.
derive_builder_types: std.AutoHashMapUnmanaged(u32, BuilderMeta) = .{},
/// Reverse lookup: builder LLVM type pointer -> owner type symbol.
builder_owner_by_type: std.AutoHashMapUnmanaged(usize, u32) = .{},
/// Whether the program uses async/await (requires fiber runtime linking).
uses_async: bool = false,
/// Active generic type-parameter substitutions while emitting a monomorphized body.
active_type_bindings: [16]TypeBinding = undefined,
active_type_bindings_len: u32 = 0,
/// Function param defaults: fn_sym → param list (for default arg insertion).
fn_default_params: std.AutoHashMapUnmanaged(u32, []const Ast.Param) = .{},
/// Source file path for __FILE__ built-in.
source_file: []const u8 = "<unknown>",
/// Source text for line number computation (__LINE__ built-in).
source_text: []const u8 = "",

const VecTypeInfo = struct {
    llvm_type: c.LLVMTypeRef, // struct { ptr, i64, i64 }
    elem_type: c.LLVMTypeRef,
};

const HashMapTypeInfo = struct {
    llvm_type: c.LLVMTypeRef, // named struct { ptr }
    key_type: c.LLVMTypeRef,
    val_type: c.LLVMTypeRef,
    is_str_key: bool,
};

const HashSetTypeInfo = struct {
    llvm_type: c.LLVMTypeRef, // named struct { ptr } (same shape as HashMap)
    elem_type: c.LLVMTypeRef,
    hm_info: HashMapTypeInfo, // underlying HashMap[T, i8]
};

const BuilderMeta = struct {
    llvm_type: c.LLVMTypeRef, // struct { T, i64 mask }
    required_mask: u64,
    default_mask: u64,
};

const ScopedLocal = struct {
    sym: u32,
    alloca: c.LLVMValueRef,
    ty: c.LLVMTypeRef,
};

const LoopContext = struct {
    break_bb: c.LLVMBasicBlockRef,
    continue_bb: c.LLVMBasicBlockRef,
    result_alloca: ?c.LLVMValueRef = null,
    label: ?u32 = null,
};

const TypeBinding = struct {
    sym: u32,
    ty: c.LLVMTypeRef,
};

const AsyncScopeFrame = struct {
    symbol: u32,
    tasks: [64]c.LLVMValueRef = undefined,
    task_count: u32 = 0,
};

const TypeObjectInfo = struct {
    llvm_type: c.LLVMTypeRef,
    name: []const u8,
    struct_sym: ?u32 = null,
    enum_sym: ?u32 = null,
};

const LocalInfo = struct {
    alloca: c.LLVMValueRef,
    ty: c.LLVMTypeRef,
    is_mut: bool,
    /// For function pointer locals: the underlying fn type for LLVMBuildCall2.
    fn_sig: ?c.LLVMTypeRef = null,
    /// For pointer-to-struct locals: the pointee struct type (for field access through pointers).
    pointee_struct: ?u32 = null,
};

const FnInfo = struct {
    value: c.LLVMValueRef,
    fn_type: c.LLVMTypeRef,
};

const StructTypeInfo = struct {
    llvm_type: c.LLVMTypeRef,
    field_names: []const u32,
    field_types: []const c.LLVMTypeRef,
    field_defaults: []const ?*const Ast.Expr,
};

const EnumTypeInfo = struct {
    llvm_type: c.LLVMTypeRef,
    variant_names: []const u32, // Symbol for each variant
    variant_payload_types: []const ?c.LLVMTypeRef, // null for unit variants
};

const OptionResultInfo = struct {
    llvm_type: c.LLVMTypeRef, // { i32 tag, [N x i8] payload }
    payload_type: c.LLVMTypeRef, // T for Option, ok_type for Result
    err_type: ?c.LLVMTypeRef, // E for Result, null for Option
    enum_sym: u32, // Symbol for the enum type name
};

const ContextErrorInfo = struct {
    llvm_type: c.LLVMTypeRef, // struct { str, E }
    source_type: c.LLVMTypeRef, // E
};

const TraitInfo = struct {
    method_names: []const u32, // ordered method Symbols
    method_return_types: []const c.LLVMTypeRef, // return type for each method
    method_param_counts: []const u32, // param count (excluding self) for each method
    vtable_type: c.LLVMTypeRef, // struct of function pointers
};

const MethodOrigin = enum {
    trait,
    inherent,
};

pub const Error = error{
    LlvmInitFailed,
    TargetLookupFailed,
    EmitFailed,
    VerifyFailed,
    UnsupportedExpr,
    UnsupportedType,
    CodegenAlloc,
    ImmutableAssign,
};

pub fn init(module_name: [*:0]const u8, allocator: std.mem.Allocator) Error!Codegen {
    // Initialize native target.
    if (c.LLVMInitializeNativeTarget() != 0)
        return error.LlvmInitFailed;
    if (c.LLVMInitializeNativeAsmPrinter() != 0)
        return error.LlvmInitFailed;

    const context = c.LLVMContextCreate();
    const module = c.LLVMModuleCreateWithNameInContext(module_name, context);
    const builder = c.LLVMCreateBuilderInContext(context);

    // Get native target triple and create target machine.
    const triple = c.LLVMGetDefaultTargetTriple();
    var target: c.LLVMTargetRef = null;
    var err_msg: [*c]u8 = null;
    if (c.LLVMGetTargetFromTriple(triple, &target, &err_msg) != 0) {
        if (err_msg) |msg| c.LLVMDisposeMessage(msg);
        return error.TargetLookupFailed;
    }

    const target_machine = c.LLVMCreateTargetMachine(
        target,
        triple,
        "generic",
        "",
        c.LLVMCodeGenLevelDefault,
        c.LLVMRelocDefault,
        c.LLVMCodeModelDefault,
    );
    c.LLVMDisposeMessage(triple);

    // Set module target triple and data layout.
    const layout = c.LLVMCreateTargetDataLayout(target_machine);
    c.LLVMSetModuleDataLayout(module, layout);
    c.LLVMSetTarget(module, c.LLVMGetDefaultTargetTriple());
    c.LLVMDisposeTargetData(layout);

    return .{
        .context = context,
        .module = module,
        .builder = builder,
        .target_machine = target_machine,
        .pool = undefined, // set in genModule
        .allocator = allocator,
        .current_ret_type = null,
        .current_function = null,
        .locals = .{},
        .functions = .{},
        .struct_types = .{},
        .enum_types = .{},
        .enum_types_by_llvm = .{},
        .generic_fns = .{},
        .generic_structs = .{},
        .mono_cache = .{},
        .type_aliases = .{},
    };
}

pub fn deinit(self: *Codegen) void {
    var st_it = self.struct_types.iterator();
    while (st_it.next()) |entry| {
        self.allocator.free(entry.value_ptr.field_names);
        self.allocator.free(entry.value_ptr.field_types);
        self.allocator.free(entry.value_ptr.field_defaults);
    }
    self.struct_types.deinit(self.allocator);
    var et_it = self.enum_types.iterator();
    while (et_it.next()) |entry| {
        self.allocator.free(entry.value_ptr.variant_names);
        self.allocator.free(entry.value_ptr.variant_payload_types);
    }
    self.enum_types.deinit(self.allocator);
    self.functions.deinit(self.allocator);
    self.locals.deinit(self.allocator);
    self.generic_fns.deinit(self.allocator);
    self.generic_structs.deinit(self.allocator);
    self.mono_cache.deinit(self.allocator);
    self.type_aliases.deinit(self.allocator);
    self.module_constants.deinit(self.allocator);
    self.ref_pointee_types.deinit(self.allocator);
    self.option_type_cache.deinit(self.allocator);
    self.result_type_cache.deinit(self.allocator);
    self.context_error_type_cache.deinit(self.allocator);
    self.vec_type_cache.deinit(self.allocator);
    self.vec_local_types.deinit(self.allocator);
    self.hashmap_type_cache.deinit(self.allocator);
    self.hashmap_local_types.deinit(self.allocator);
    self.hashset_type_cache.deinit(self.allocator);
    self.derive_builder_types.deinit(self.allocator);
    self.builder_owner_by_type.deinit(self.allocator);
    self.drop_fns.deinit(self.allocator);
    self.slice_elem_types.deinit(self.allocator);
    self.enum_local_types.deinit(self.allocator);
    {
        var ti_it = self.trait_infos.iterator();
        while (ti_it.next()) |entry| {
            self.allocator.free(entry.value_ptr.method_names);
            self.allocator.free(entry.value_ptr.method_return_types);
            self.allocator.free(entry.value_ptr.method_param_counts);
        }
    }
    self.trait_infos.deinit(self.allocator);
    self.vtable_globals.deinit(self.allocator);
    self.trait_locals.deinit(self.allocator);
    self.trait_local_concrete_types.deinit(self.allocator);
    {
        var dp_it = self.fn_dyn_params.iterator();
        while (dp_it.next()) |entry| {
            self.allocator.free(entry.value_ptr.*);
        }
    }
    self.fn_dyn_params.deinit(self.allocator);
    {
        var rp_it = self.fn_ref_params.iterator();
        while (rp_it.next()) |entry| {
            self.allocator.free(entry.value_ptr.*);
        }
    }
    self.fn_ref_params.deinit(self.allocator);
    self.fn_default_params.deinit(self.allocator);
    self.fn_result_err_symbols.deinit(self.allocator);
    self.fn_returns_result.deinit(self.allocator);
    self.fn_result_unit_returns.deinit(self.allocator);
    self.async_fn_symbols.deinit(self.allocator);
    self.async_fn_ret_types.deinit(self.allocator);
    self.task_locals.deinit(self.allocator);
    self.task_local_result_types.deinit(self.allocator);
    self.task_container_local_elem_types.deinit(self.allocator);
    self.gen_field_indices.deinit(self.allocator);
    c.LLVMDisposeBuilder(self.builder);
    c.LLVMDisposeModule(self.module);
    c.LLVMContextDispose(self.context);
    c.LLVMDisposeTargetMachine(self.target_machine);
}

fn computeMethodOrigins(
    self: *Codegen,
    module: *const Ast.Module,
    method_decl_origins: *std.AutoHashMapUnmanaged(usize, MethodOrigin),
    method_has_inherent: *std.AutoHashMapUnmanaged(u32, void),
) void {
    method_decl_origins.clearRetainingCapacity();
    method_has_inherent.clearRetainingCapacity();

    // impl blocks are parsed as: method function decls, then one impl_decl.
    for (module.decls, 0..) |decl, decl_idx| {
        if (decl.kind != .impl_decl) continue;
        const id = decl.kind.impl_decl;
        const origin: MethodOrigin = if (id.trait_name == null) .inherent else .trait;

        var remaining = id.method_names.len;
        var j = decl_idx;
        while (remaining > 0 and j > 0) {
            j -= 1;
            if (module.decls[j].kind != .function) continue;
            const fn_decl = module.decls[j].kind.function;
            method_decl_origins.put(self.allocator, j, origin) catch {};
            if (origin == .inherent and self.isMethodSymbol(fn_decl.name)) {
                method_has_inherent.put(self.allocator, fn_decl.name, {}) catch {};
            }
            remaining -= 1;
        }
    }

    // Top-level method syntax (`fn Type.method(...)`) is inherent.
    for (module.decls, 0..) |decl, decl_idx| {
        if (decl.kind != .function) continue;
        const fn_decl = decl.kind.function;
        if (!self.isMethodSymbol(fn_decl.name)) continue;
        if (method_decl_origins.get(decl_idx) == null) {
            method_has_inherent.put(self.allocator, fn_decl.name, {}) catch {};
        }
    }
}

fn isMethodSymbol(self: *const Codegen, sym: u32) bool {
    const name = self.pool.resolve(sym);
    return std.mem.indexOfScalar(u8, name, '.') != null;
}

fn shouldSkipTraitMethodDecl(
    self: *const Codegen,
    decl_index: usize,
    fn_sym: u32,
    method_decl_origins: *const std.AutoHashMapUnmanaged(usize, MethodOrigin),
    method_has_inherent: *const std.AutoHashMapUnmanaged(u32, void),
) bool {
    if (!self.isMethodSymbol(fn_sym)) return false;
    const origin = method_decl_origins.get(decl_index) orelse .inherent;
    return origin == .trait and method_has_inherent.get(fn_sym) != null;
}

/// Generate LLVM IR for an entire module (two-pass).
pub fn genModule(self: *Codegen, module: *const Ast.Module, pool: *InternPool) Error!void {
    self.pool = pool;

    var method_decl_origins: std.AutoHashMapUnmanaged(usize, MethodOrigin) = .{};
    defer method_decl_origins.deinit(self.allocator);
    var method_has_inherent: std.AutoHashMapUnmanaged(u32, void) = .{};
    defer method_has_inherent.deinit(self.allocator);
    self.computeMethodOrigins(module, &method_decl_origins, &method_has_inherent);

    // Declare built-in str type before user types.
    try self.declareBuiltinStrType();

    // Pass 0: declare struct types.
    for (module.decls) |decl| {
        switch (decl.kind) {
            .type_decl => |td| switch (td.kind) {
                .struct_def => |fields| if (td.type_params.len == 0) {
                    try self.declareStructType(td.name, fields);
                } else {
                    self.generic_structs.put(self.allocator, td.name, td) catch
                        return error.CodegenAlloc;
                },
                .enum_def => |variants| try self.declareEnumType(td.name, variants),
                .alias => |type_expr| {
                    const resolved = try self.resolveType(type_expr);
                    self.type_aliases.put(self.allocator, td.name, resolved) catch
                        return error.CodegenAlloc;
                },
                .distinct => |type_expr| {
                    // Distinct type: create a single-field struct wrapper.
                    const inner = try self.resolveType(type_expr);
                    const name_str = self.pool.resolve(td.name);
                    var field_types = [_]c.LLVMTypeRef{inner};
                    const wrapper = c.LLVMStructCreateNamed(self.context, @ptrCast(name_str));
                    c.LLVMStructSetBody(wrapper, &field_types, 1, 0);
                    const field_names = self.allocator.alloc(u32, 1) catch return error.CodegenAlloc;
                    const val_sym = self.pool.intern("value") catch return error.CodegenAlloc;
                    field_names[0] = val_sym;
                    const ft = self.allocator.alloc(c.LLVMTypeRef, 1) catch return error.CodegenAlloc;
                    ft[0] = inner;
                    const defaults = self.allocator.alloc(?*const Ast.Expr, 1) catch return error.CodegenAlloc;
                    defaults[0] = null;
                    self.struct_types.put(self.allocator, td.name, .{
                        .llvm_type = wrapper,
                        .field_names = field_names,
                        .field_types = ft,
                        .field_defaults = defaults,
                    }) catch return error.CodegenAlloc;
                },
            },
            else => {},
        }
    }

    // Pass 0.5: collect trait declarations.
    for (module.decls) |decl| {
        switch (decl.kind) {
            .trait_decl => |td| try self.collectTraitInfo(td),
            else => {},
        }
    }

    // Pass 0.6: process top-level let/var declarations as module constants.
    for (module.decls) |decl| {
        switch (decl.kind) {
            .let_decl => |ld| try self.genModuleConstant(ld),
            else => {},
        }
    }

    // Pass 0.7: declare generator state structs and functions.
    for (module.decls, 0..) |decl, decl_idx| {
        switch (decl.kind) {
            .function => |fn_decl| {
                if (self.shouldSkipTraitMethodDecl(
                    decl_idx,
                    fn_decl.name,
                    &method_decl_origins,
                    &method_has_inherent,
                )) continue;
                if (fn_decl.is_gen and fn_decl.type_params.len == 0) {
                    try self.declareGenerator(fn_decl);
                }
            },
            else => {},
        }
    }

    // Pass 0.8: generate derived trait methods (@[derive(...)]).
    for (module.decls) |decl| {
        switch (decl.kind) {
            .type_decl => |td| {
                if (td.derive_traits.len > 0) {
                    try self.generateDerivedMethods(td);
                }
            },
            else => {},
        }
    }

    // Pass 1: declare all functions and externs (forward declarations).
    // Generic functions are stored for later monomorphization.
    for (module.decls, 0..) |decl, decl_idx| {
        switch (decl.kind) {
            .function => |fn_decl| {
                if (self.shouldSkipTraitMethodDecl(
                    decl_idx,
                    fn_decl.name,
                    &method_decl_origins,
                    &method_has_inherent,
                )) continue;
                if (fn_decl.is_gen) continue; // already declared in pass 0.7
                if (fn_decl.is_async) {
                    self.async_fn_symbols.put(self.allocator, fn_decl.name, {}) catch
                        return error.CodegenAlloc;
                    try self.declareAsyncFunction(fn_decl);
                } else if (fn_decl.type_params.len > 0) {
                    self.generic_fns.put(self.allocator, fn_decl.name, fn_decl) catch
                        return error.CodegenAlloc;
                } else {
                    try self.declareFunction(fn_decl);
                }
            },
            .extern_fn => |ext| try self.declareExternFn(ext),
            else => {},
        }
    }

    // Pass 1.3: generate default trait method implementations.
    // For each impl Trait for Type, check for missing methods with defaults.
    for (module.decls) |decl| {
        switch (decl.kind) {
            .impl_decl => |id| try self.generateDefaultMethods(id),
            else => {},
        }
    }

    // Pass 1.5: detect Drop functions (Type.drop patterns).
    try self.detectDropFunctions();

    // Pass 1.6: generate vtable globals for impl declarations.
    for (module.decls) |decl| {
        switch (decl.kind) {
            .impl_decl => |id| try self.generateVtable(id),
            else => {},
        }
    }

    // Pass 2: generate function bodies (skip generic functions).
    for (module.decls, 0..) |decl, decl_idx| {
        switch (decl.kind) {
            .function => |fn_decl| {
                if (self.shouldSkipTraitMethodDecl(
                    decl_idx,
                    fn_decl.name,
                    &method_decl_origins,
                    &method_has_inherent,
                )) continue;
                if (fn_decl.is_gen) {
                    self.genGeneratorBody(fn_decl) catch |err| {
                        const fn_name = self.pool.resolve(fn_decl.name);
                        const detail = self.codegen_error_detail orelse @errorName(err);
                        var buf: [384]u8 = undefined;
                        const msg = std.fmt.bufPrint(&buf, "codegen failed in generator '{s}': {s}", .{ fn_name, detail }) catch "codegen failed";
                        self.codegen_error_detail = self.allocator.dupe(u8, msg) catch null;
                        return err;
                    };
                } else if (fn_decl.is_async) {
                    self.genAsyncFunction(fn_decl) catch |err| {
                        const fn_name = self.pool.resolve(fn_decl.name);
                        const detail = self.codegen_error_detail orelse @errorName(err);
                        var buf: [384]u8 = undefined;
                        const msg = std.fmt.bufPrint(&buf, "codegen failed in async function '{s}': {s}", .{ fn_name, detail }) catch "codegen failed";
                        self.codegen_error_detail = self.allocator.dupe(u8, msg) catch null;
                        return err;
                    };
                } else if (fn_decl.type_params.len == 0) {
                    self.genFunction(fn_decl) catch |err| {
                        const fn_name = self.pool.resolve(fn_decl.name);
                        const detail = self.codegen_error_detail orelse @errorName(err);
                        var buf: [384]u8 = undefined;
                        const msg = std.fmt.bufPrint(&buf, "codegen failed in function '{s}': {s}", .{ fn_name, detail }) catch "codegen failed";
                        self.codegen_error_detail = self.allocator.dupe(u8, msg) catch null;
                        return err;
                    };
                }
            },
            else => {},
        }
    }

    // If main returns void, emit an OS-facing wrapper that returns 0.
    // The type system stays honest: fn main: has return type Unit.
    // The wrapper is what the OS sees.
    try self.wrapMainForExit();

    // If async is used, wrap main to init/run/shutdown the runtime.
    if (self.uses_async) {
        try self.wrapMainForAsync();
    }

    try self.verify();
}

/// Verify the LLVM module.
fn verify(self: *const Codegen) Error!void {
    var err_msg: [*c]u8 = null;
    if (c.LLVMVerifyModule(self.module, c.LLVMReturnStatusAction, &err_msg) != 0) {
        if (err_msg) |msg| {
            const slice = std.mem.span(msg);
            var buf: [8192]u8 = undefined;
            var w = std.fs.File.stderr().writer(&buf);
            w.interface.print("LLVM verify error: {s}\n", .{slice}) catch {};
            w.interface.flush() catch {};
            c.LLVMDisposeMessage(msg);
        }
        // Best-effort: identify which function fails verification.
        var fn_val = c.LLVMGetFirstFunction(self.module);
        while (fn_val != null) : (fn_val = c.LLVMGetNextFunction(fn_val)) {
            if (c.LLVMIsDeclaration(fn_val) != 0) continue;
            if (c.LLVMVerifyFunction(fn_val, c.LLVMReturnStatusAction) != 0) {
                var name_len: usize = 0;
                const name_ptr = c.LLVMGetValueName2(fn_val, &name_len);
                const name_slice: []const u8 = if (name_ptr != null) name_ptr[0..name_len] else "<unknown>";
                var buf2: [1024]u8 = undefined;
                var w2 = std.fs.File.stderr().writer(&buf2);
                w2.interface.print("LLVM verify function: {s}\n", .{name_slice}) catch {};
                w2.interface.flush() catch {};
                break;
            }
        }
        return error.VerifyFailed;
    }
    if (err_msg) |msg| c.LLVMDisposeMessage(msg);
}

/// Run optimization passes on the module.
pub fn optimize(self: *Codegen, level: u8) void {
    // Use the new pass manager API (LLVM 18+).
    const passes: [*:0]const u8 = switch (level) {
        0 => "default<O0>",
        1 => "default<O1>",
        3 => "default<O3>",
        else => "default<O2>",
    };
    const opts = c.LLVMCreatePassBuilderOptions();
    defer c.LLVMDisposePassBuilderOptions(opts);
    const err = c.LLVMRunPasses(self.module, passes, self.target_machine, opts);
    if (err != null) {
        const msg = c.LLVMGetErrorMessage(err);
        if (msg != null) {
            c.LLVMDisposeErrorMessage(msg);
        }
    }
}

/// Emit an object file to the given path.
pub fn emitObjectFile(self: *Codegen, path: [*:0]const u8) Error!void {
    var err_msg: [*c]u8 = null;
    if (c.LLVMTargetMachineEmitToFile(
        self.target_machine,
        self.module,
        path,
        c.LLVMObjectFile,
        &err_msg,
    ) != 0) {
        if (err_msg) |msg| {
            // Write error to stderr before disposing.
            var buf: [4096]u8 = undefined;
            var w = std.fs.File.stderr().writer(&buf);
            const slice = std.mem.span(msg);
            w.interface.print("LLVM emit error: {s}\n", .{slice}) catch {};
            w.interface.flush() catch {};
            c.LLVMDisposeMessage(msg);
        }
        return error.EmitFailed;
    }
}

/// Print LLVM IR text to stdout.
pub fn printIR(self: *const Codegen) void {
    var buf: [8192]u8 = undefined;
    var w = std.fs.File.stdout().writer(&buf);
    self.writeIR(&w.interface) catch {};
    w.interface.flush() catch {};
}

/// Write LLVM IR text to the provided writer.
pub fn writeIR(self: *const Codegen, writer: anytype) !void {
    const ir = c.LLVMPrintModuleToString(self.module);
    defer c.LLVMDisposeMessage(ir);
    const slice = std.mem.span(ir);
    try writer.writeAll(slice);
}

/// Return LLVM IR text as an owned slice.
pub fn irStringAlloc(self: *const Codegen, allocator: std.mem.Allocator) ![]u8 {
    const ir = c.LLVMPrintModuleToString(self.module);
    defer c.LLVMDisposeMessage(ir);
    const slice = std.mem.span(ir);
    return try allocator.dupe(u8, slice);
}

// ── Function declaration (pass 1) ────────────────────────────────

fn isResultReturnType(self: *Codegen, ret: ?*const Ast.TypeExpr) bool {
    const rt = ret orelse return false;
    if (rt.kind != .generic) return false;
    const g = rt.kind.generic;
    if (g.args.len != 2) return false;
    const g_name = self.pool.resolve(g.name);
    return std.mem.eql(u8, g_name, "Result");
}

fn resultErrSymbolFromReturnType(self: *Codegen, ret: ?*const Ast.TypeExpr) ?u32 {
    const rt = ret orelse return null;
    if (!self.isResultReturnType(ret)) return null;
    const g = rt.kind.generic;
    if (g.args[1].kind != .named) return null;
    return g.args[1].kind.named;
}

fn isResultUnitReturnType(self: *Codegen, ret: ?*const Ast.TypeExpr) bool {
    const rt = ret orelse return false;
    if (rt.kind != .generic) return false;
    const g = rt.kind.generic;
    if (!self.isResultReturnType(ret)) return false;
    if (g.args[0].kind != .named) return false;
    const ok_name = self.pool.resolve(g.args[0].kind.named);
    return std.mem.eql(u8, ok_name, "Unit");
}

/// Extract a trait symbol when a parameter type syntactically denotes a dyn trait object.
/// Supports plain `dyn Trait`, wrapped refs/ptrs (`&dyn Trait`, `*dyn Trait`), and
/// `Box[dyn Trait]`.
fn dynTraitFromTypeExpr(self: *Codegen, te: *const Ast.TypeExpr) ?u32 {
    return switch (te.kind) {
        .trait_object => |sym| sym,
        .ref_type => |rt| dynTraitFromTypeExpr(self, rt.pointee),
        .ptr_type => |pt| dynTraitFromTypeExpr(self, pt.pointee),
        .generic => |g| blk: {
            const name = self.pool.resolve(g.name);
            if (!std.mem.eql(u8, name, "Box") or g.args.len != 1) break :blk null;
            break :blk dynTraitFromTypeExpr(self, g.args[0]);
        },
        else => null,
    };
}

fn declareFunction(self: *Codegen, func: Ast.FnDecl) Error!void {
    const ret_type = if (func.return_type) |rt|
        try self.resolveType(rt)
    else if (self.inferred_return_types.get(func.name)) |inferred_te|
        try self.resolveType(inferred_te)
    else
        c.LLVMVoidTypeInContext(self.context);

    var param_types_buf: [64]c.LLVMTypeRef = undefined;
    var has_dyn_param = false;
    var has_ref_param = false;
    var dyn_params_buf: [64]?u32 = undefined;
    var ref_params_buf: [64]bool = undefined;
    var method_owner_name: ?[]const u8 = null;
    {
        const fn_name = self.pool.resolve(func.name);
        if (std.mem.indexOfScalar(u8, fn_name, '.')) |dot| {
            if (dot > 0) {
                method_owner_name = fn_name[0..dot];
            }
        }
    }
    for (func.params, 0..) |param, i| {
        dyn_params_buf[i] = null;
        ref_params_buf[i] = false;
        if (param.type_expr) |te| {
            if (i == 0 and method_owner_name != null) {
                const param_name = self.pool.resolve(param.name);
                var is_receiver = std.mem.eql(u8, param_name, "self");
                if (!is_receiver and te.kind == .named) {
                    const n = self.pool.resolve(te.kind.named);
                    is_receiver = std.mem.eql(u8, n, "Self") or std.mem.eql(u8, n, method_owner_name.?);
                }
                if (is_receiver) {
                    // Lower method receiver to pointer so mutations persist.
                    param_types_buf[i] = c.LLVMPointerTypeInContext(self.context, 0);
                    ref_params_buf[i] = true;
                    has_ref_param = true;
                    continue;
                }
            }
            if (te.kind == .fn_type) {
                // fn-type params use fat pointer {ptr, ptr} to support closures.
                const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
                var fat_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
                param_types_buf[i] = c.LLVMStructTypeInContext(self.context, &fat_types, 2, 0);
            } else if (dynTraitFromTypeExpr(self, te)) |trait_sym| {
                // Any dyn-typed parameter form uses the same runtime fat pointer
                // representation {data_ptr, vtable_ptr}.
                param_types_buf[i] = try self.resolveType(te);
                dyn_params_buf[i] = trait_sym;
                has_dyn_param = true;
            } else if (te.kind == .ref_type) {
                // Track reference params for auto-referencing.
                param_types_buf[i] = try self.resolveType(te);
                ref_params_buf[i] = true;
                has_ref_param = true;
            } else {
                param_types_buf[i] = try self.resolveType(te);
            }
        } else {
            return error.UnsupportedType;
        }
    }

    const fn_type = c.LLVMFunctionType(
        ret_type,
        if (func.params.len > 0) &param_types_buf else null,
        @intCast(func.params.len),
        0,
    );

    const name = self.pool.resolve(func.name);
    // @[entry] — use "main" as the LLVM function name (§18.7).
    const effective_name = if (func.is_entry) "main" else name;
    var name_buf: [256]u8 = undefined;
    if (effective_name.len >= name_buf.len) return error.UnsupportedExpr;
    @memcpy(name_buf[0..effective_name.len], effective_name);
    name_buf[effective_name.len] = 0;

    const function = c.LLVMAddFunction(self.module, &name_buf, fn_type);

    // Apply @[inline] / @[noinline] LLVM function attributes.
    if (func.is_inline) {
        c.LLVMAddAttributeAtIndex(function, @bitCast(@as(i32, -1)), c.LLVMCreateEnumAttribute(
            self.context,
            c.LLVMGetEnumAttributeKindForName("alwaysinline", 12),
            0,
        ));
    } else if (func.is_noinline) {
        c.LLVMAddAttributeAtIndex(function, @bitCast(@as(i32, -1)), c.LLVMCreateEnumAttribute(
            self.context,
            c.LLVMGetEnumAttributeKindForName("noinline", 8),
            0,
        ));
    }

    self.functions.put(self.allocator, func.name, .{
        .value = function,
        .fn_type = fn_type,
    }) catch return error.CodegenAlloc;

    // Record param defaults for default-arg insertion at call sites.
    {
        var has_defaults = false;
        for (func.params) |p| {
            if (p.default_value != null) {
                has_defaults = true;
                break;
            }
        }
        if (has_defaults) {
            self.fn_default_params.put(self.allocator, func.name, func.params) catch return error.CodegenAlloc;
        }
    }

    // Record dyn Trait param info if any.
    if (has_dyn_param) {
        const dyn_info = self.allocator.alloc(?u32, func.params.len) catch return error.CodegenAlloc;
        @memcpy(dyn_info, dyn_params_buf[0..func.params.len]);
        self.fn_dyn_params.put(self.allocator, func.name, dyn_info) catch return error.CodegenAlloc;
    }

    // Record ref param info for auto-referencing.
    if (has_ref_param) {
        const ref_info = self.allocator.alloc(bool, func.params.len) catch return error.CodegenAlloc;
        @memcpy(ref_info, ref_params_buf[0..func.params.len]);
        self.fn_ref_params.put(self.allocator, func.name, ref_info) catch return error.CodegenAlloc;
    }

    if (self.resultErrSymbolFromReturnType(func.return_type)) |err_sym| {
        self.fn_result_err_symbols.put(self.allocator, func.name, err_sym) catch return error.CodegenAlloc;
    }
    if (self.isResultReturnType(func.return_type)) {
        self.fn_returns_result.put(self.allocator, func.name, {}) catch return error.CodegenAlloc;
    }
    if (self.isResultUnitReturnType(func.return_type)) {
        self.fn_result_unit_returns.put(self.allocator, func.name, {}) catch return error.CodegenAlloc;
    }
}

fn findStructTypeSymbolByName(self: *Codegen, name: []const u8) ?u32 {
    var it = self.struct_types.iterator();
    while (it.next()) |entry| {
        const sym = entry.key_ptr.*;
        if (std.mem.eql(u8, self.pool.resolve(sym), name)) return sym;
    }
    return null;
}

fn declareExternFn(self: *Codegen, ext: Ast.ExternFnDecl) Error!void {
    // Skip duplicate extern fn declarations (from overlapping c_imports).
    if (self.functions.get(ext.name) != null) return;

    const ret_type = if (ext.return_type) |rt|
        try self.resolveType(rt)
    else
        c.LLVMVoidTypeInContext(self.context);

    var param_types_buf: [64]c.LLVMTypeRef = undefined;
    for (ext.params, 0..) |param, i| {
        if (param.type_expr) |te| {
            param_types_buf[i] = try self.resolveType(te);
        } else {
            return error.UnsupportedType;
        }
    }

    const fn_type = c.LLVMFunctionType(
        ret_type,
        if (ext.params.len > 0) &param_types_buf else null,
        @intCast(ext.params.len),
        @intFromBool(ext.is_variadic),
    );

    const name = self.pool.resolve(ext.name);
    const link_name = canonicalExternName(name);
    var name_buf: [256]u8 = undefined;
    if (link_name.len >= name_buf.len) return error.UnsupportedExpr;
    @memcpy(name_buf[0..link_name.len], link_name);
    name_buf[link_name.len] = 0;

    const function = c.LLVMGetNamedFunction(self.module, &name_buf) orelse
        c.LLVMAddFunction(self.module, &name_buf, fn_type);
    const actual_fn_type = c.LLVMGlobalGetValueType(function);
    const info = FnInfo{
        .value = function,
        .fn_type = actual_fn_type,
    };

    self.functions.put(self.allocator, ext.name, info) catch return error.CodegenAlloc;

    // Also register the canonical symbol name so runtime helpers (e.g. malloc)
    // reuse this declaration instead of redeclaring `name.<n>` variants.
    if (!std.mem.eql(u8, link_name, name)) {
        const canonical_sym = self.pool.intern(link_name) catch return error.CodegenAlloc;
        if (self.functions.get(canonical_sym) == null) {
            self.functions.put(self.allocator, canonical_sym, info) catch return error.CodegenAlloc;
        }
    }
}

/// c_import may suffix C symbols as `name.<n>` to avoid parser collisions.
/// For linking, map those extern declarations back to the base C symbol name.
fn canonicalExternName(name: []const u8) []const u8 {
    if (std.mem.lastIndexOfScalar(u8, name, '.')) |dot| {
        if (dot > 0 and dot + 1 < name.len) {
            var i = dot + 1;
            while (i < name.len) : (i += 1) {
                const ch = name[i];
                if (ch < '0' or ch > '9') return name;
            }
            return name[0..dot];
        }
    }
    return name;
}

// ── Drop detection ──────────────────────────────────────────────

/// Scan declared functions for `Type.drop` patterns and register them.
fn detectDropFunctions(self: *Codegen) Error!void {
    var it = self.functions.iterator();
    while (it.next()) |entry| {
        const name = self.pool.resolve(entry.key_ptr.*);
        // Look for "X.drop" pattern.
        if (std.mem.endsWith(u8, name, ".drop")) {
            const type_name = name[0 .. name.len - 5]; // strip ".drop"
            if (type_name.len > 0) {
                const type_sym = self.pool.intern(type_name) catch return error.CodegenAlloc;
                if (self.struct_types.get(type_sym) != null or self.enum_types.get(type_sym) != null) {
                    self.drop_fns.put(self.allocator, type_sym, entry.value_ptr.*) catch
                        return error.CodegenAlloc;
                }
            }
        }
    }
}

/// Check if a given LLVM type has a drop function registered.
fn findDropFn(self: *Codegen, ty: c.LLVMTypeRef) ?FnInfo {
    // Search struct_types for matching LLVM type, then check drop_fns.
    var st_it = self.struct_types.iterator();
    while (st_it.next()) |entry| {
        if (entry.value_ptr.llvm_type == ty) {
            return self.drop_fns.get(entry.key_ptr.*);
        }
    }
    // Also search enum_types.
    var et_it = self.enum_types.iterator();
    while (et_it.next()) |entry| {
        if (entry.value_ptr.llvm_type == ty) {
            return self.drop_fns.get(entry.key_ptr.*);
        }
    }
    return null;
}

// ── Trait / Dynamic dispatch ──────────────────────────────────────

/// Collect a trait declaration into trait_infos.
fn collectTraitInfo(self: *Codegen, td: Ast.TraitDecl) Error!void {
    const method_count = td.methods.len;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);

    // Build arrays of method info.
    const method_names = self.allocator.alloc(u32, method_count) catch return error.CodegenAlloc;
    const method_ret_types = self.allocator.alloc(c.LLVMTypeRef, method_count) catch return error.CodegenAlloc;
    const method_param_counts = self.allocator.alloc(u32, method_count) catch return error.CodegenAlloc;

    // Build vtable struct type: one ptr per method.
    var vtable_fields: [64]c.LLVMTypeRef = undefined;
    for (td.methods, 0..) |m, i| {
        method_names[i] = m.name;
        method_ret_types[i] = if (m.return_type) |rt| blk: {
            const resolved = self.resolveType(rt) catch blk2: {
                if (rt.kind == .named) {
                    const n = self.pool.resolve(rt.kind.named);
                    if (std.mem.eql(u8, n, "str") or std.mem.eql(u8, n, "String") or std.mem.eql(u8, n, "StrView")) {
                        const str_sym = self.pool.intern("str") catch break :blk2 c.LLVMInt32TypeInContext(self.context);
                        if (self.struct_types.get(str_sym)) |st| break :blk2 st.llvm_type;
                    }
                    if (self.struct_types.get(rt.kind.named)) |st| break :blk2 st.llvm_type;
                    if (self.enum_types.get(rt.kind.named)) |et| break :blk2 et.llvm_type;
                    if (self.type_aliases.get(rt.kind.named)) |aty| break :blk2 aty;
                }
                break :blk2 c.LLVMInt32TypeInContext(self.context);
            };
            break :blk resolved;
        } else c.LLVMVoidTypeInContext(self.context);
        // params count excludes self (first param).
        method_param_counts[i] = if (m.params.len > 0) @intCast(m.params.len - 1) else 0;
        vtable_fields[i] = ptr_type; // function pointer
    }

    const vtable_type = c.LLVMStructTypeInContext(
        self.context,
        &vtable_fields,
        @intCast(method_count),
        0,
    );

    self.trait_infos.put(self.allocator, td.name, .{
        .method_names = method_names,
        .method_return_types = method_ret_types,
        .method_param_counts = method_param_counts,
        .vtable_type = vtable_type,
    }) catch return error.CodegenAlloc;

    // Store the full trait decl for default method body generation.
    self.trait_decl_map.put(self.allocator, td.name, td) catch return error.CodegenAlloc;
}

/// Generate default method implementations for missing trait methods.
/// For each method in the trait that has a default body and isn't overridden
/// in the impl block, create a mangled Type.method function.
fn generateDefaultMethods(self: *Codegen, id: Ast.ImplDecl) Error!void {
    const trait_sym = id.trait_name orelse return;
    const td = self.trait_decl_map.get(trait_sym) orelse return;
    const type_name = self.pool.resolve(id.type_name);

    for (td.methods) |method| {
        if (!method.has_default) continue;
        const default_body = method.default_body orelse continue;

        // Build mangled name "Type.method"
        const method_name = self.pool.resolve(method.name);
        var name_buf: [512]u8 = undefined;
        @memcpy(name_buf[0..type_name.len], type_name);
        name_buf[type_name.len] = '.';
        @memcpy(name_buf[type_name.len + 1 ..][0..method_name.len], method_name);
        const mangled_len = type_name.len + 1 + method_name.len;
        const mangled = name_buf[0..mangled_len];
        const fn_sym = self.pool.intern(mangled) catch return error.CodegenAlloc;

        // Skip if already implemented (override exists).
        if (self.functions.get(fn_sym) != null) continue;

        // Resolve parameter types (self param uses the struct type).
        var param_types_buf: [64]c.LLVMTypeRef = undefined;
        for (method.params, 0..) |param, i| {
            if (param.type_expr) |te| {
                // Check for Self type — resolve to the concrete struct type.
                if (te.kind == .named) {
                    const named_str = self.pool.resolve(te.kind.named);
                    if (std.mem.eql(u8, named_str, "Self")) {
                        if (self.struct_types.get(id.type_name)) |sti| {
                            param_types_buf[i] = sti.llvm_type;
                            continue;
                        }
                    }
                }
                param_types_buf[i] = self.resolveType(te) catch
                    c.LLVMInt32TypeInContext(self.context);
            } else {
                param_types_buf[i] = c.LLVMInt32TypeInContext(self.context);
            }
        }

        const ret_type = if (method.return_type) |rt|
            self.resolveType(rt) catch c.LLVMInt32TypeInContext(self.context)
        else
            c.LLVMVoidTypeInContext(self.context);

        const fn_type = c.LLVMFunctionType(
            ret_type,
            if (method.params.len > 0) &param_types_buf else null,
            @intCast(method.params.len),
            0,
        );

        // Null-terminate the mangled name.
        name_buf[mangled_len] = 0;
        const function = c.LLVMAddFunction(self.module, @ptrCast(name_buf[0..mangled_len :0]), fn_type);

        self.functions.put(self.allocator, fn_sym, .{
            .value = function,
            .fn_type = fn_type,
        }) catch return error.CodegenAlloc;

        // Generate the function body.
        const saved_fn = self.current_function;
        const saved_ret = self.current_ret_type;
        const saved_expected = self.expected_type;

        self.current_function = function;
        self.current_ret_type = ret_type;
        self.expected_type = ret_type;
        self.locals.clearRetainingCapacity();
        self.task_locals.clearRetainingCapacity();
        self.task_local_result_types.clearRetainingCapacity();
        self.task_container_local_elem_types.clearRetainingCapacity();
        self.vec_local_types.clearRetainingCapacity();

        const entry = c.LLVMAppendBasicBlockInContext(self.context, function, "entry");
        c.LLVMPositionBuilderAtEnd(self.builder, entry);

        // Add parameters as locals.
        for (method.params, 0..) |param, i| {
            const param_val = c.LLVMGetParam(function, @intCast(i));
            const param_type = c.LLVMTypeOf(param_val);
            const alloca = c.LLVMBuildAlloca(self.builder, param_type, "");
            _ = c.LLVMBuildStore(self.builder, param_val, alloca);

            // Map "self" to the concrete type's struct.
            var pointee_struct: ?u32 = null;
            if (param.type_expr) |te| {
                if (te.kind == .named) {
                    const pn = self.pool.resolve(te.kind.named);
                    if (std.mem.eql(u8, pn, "Self")) {
                        pointee_struct = id.type_name;
                    }
                }
            }

            self.locals.put(self.allocator, param.name, .{
                .alloca = alloca,
                .ty = param_type,
                .is_mut = param.is_mut,
                .fn_sig = null,
                .pointee_struct = pointee_struct,
            }) catch return error.CodegenAlloc;
        }

        const body_val = self.genExpr(default_body) catch {
            // If codegen fails, add unreachable terminator.
            _ = c.LLVMBuildUnreachable(self.builder);
            self.current_function = saved_fn;
            self.current_ret_type = saved_ret;
            self.expected_type = saved_expected;
            continue;
        };

        // Emit return if block isn't already terminated.
        const current_bb = c.LLVMGetInsertBlock(self.builder);
        if (c.LLVMGetBasicBlockTerminator(current_bb) == null) {
            if (ret_type == c.LLVMVoidTypeInContext(self.context)) {
                _ = c.LLVMBuildRetVoid(self.builder);
            } else {
                _ = c.LLVMBuildRet(self.builder, body_val);
            }
        }

        self.current_function = saved_fn;
        self.current_ret_type = saved_ret;
        self.expected_type = saved_expected;
    }
}

/// Generate a vtable global constant for an impl declaration.
fn generateVtable(self: *Codegen, id: Ast.ImplDecl) Error!void {
    const trait_sym = id.trait_name orelse return; // plain `impl Type` — no vtable
    const trait_info = self.trait_infos.get(trait_sym) orelse return;

    // For each trait method, find the corresponding Type.method function.
    const method_count = trait_info.method_names.len;
    var vtable_values: [64]c.LLVMValueRef = undefined;

    for (trait_info.method_names, 0..) |method_sym, i| {
        const method_name = self.pool.resolve(method_sym);
        const type_name = self.pool.resolve(id.type_name);

        // Build mangled name "Type.method".
        var name_buf: [512]u8 = undefined;
        @memcpy(name_buf[0..type_name.len], type_name);
        name_buf[type_name.len] = '.';
        @memcpy(name_buf[type_name.len + 1 ..][0..method_name.len], method_name);
        const mangled = name_buf[0 .. type_name.len + 1 + method_name.len];
        const fn_sym = self.pool.intern(mangled) catch return error.CodegenAlloc;

        if (self.functions.get(fn_sym)) |fn_info| {
            // Create a dynwrap function: fn(ptr, params...) -> ret
            // that loads the concrete type from the data pointer and calls the real method.
            vtable_values[i] = try self.createDynWrapper(fn_info, id.type_name, trait_info, i);
        } else {
            // Method not found — use null placeholder.
            vtable_values[i] = c.LLVMConstNull(c.LLVMPointerTypeInContext(self.context, 0));
        }
    }

    // Build the vtable global constant.
    const vtable_const = c.LLVMConstStructInContext(
        self.context,
        &vtable_values,
        @intCast(method_count),
        0,
    );

    // Create a global variable for the vtable.
    const type_name = self.pool.resolve(id.type_name);
    const trait_name = self.pool.resolve(trait_sym);
    var global_name_buf: [512]u8 = undefined;
    const prefix = "__vtable_";
    @memcpy(global_name_buf[0..prefix.len], prefix);
    @memcpy(global_name_buf[prefix.len..][0..type_name.len], type_name);
    global_name_buf[prefix.len + type_name.len] = '_';
    @memcpy(global_name_buf[prefix.len + type_name.len + 1 ..][0..trait_name.len], trait_name);
    const global_name_len = prefix.len + type_name.len + 1 + trait_name.len;
    global_name_buf[global_name_len] = 0;

    const vtable_global = c.LLVMAddGlobal(self.module, trait_info.vtable_type, &global_name_buf);
    c.LLVMSetInitializer(vtable_global, vtable_const);
    c.LLVMSetGlobalConstant(vtable_global, 1);
    c.LLVMSetLinkage(vtable_global, c.LLVMInternalLinkage);

    // Cache it: hash(type_sym, trait_sym) → global.
    const hash_key = @as(u64, id.type_name) << 32 | @as(u64, trait_sym);
    self.vtable_globals.put(self.allocator, hash_key, vtable_global) catch
        return error.CodegenAlloc;
}

/// Create a dynamic dispatch wrapper: fn(ptr, params...) -> ret
/// that loads the concrete struct from the data pointer and calls the real method.
fn createDynWrapper(self: *Codegen, fn_info: FnInfo, type_sym: u32, trait_info: TraitInfo, method_idx: usize) Error!c.LLVMValueRef {
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);

    // Get the concrete struct type.
    const struct_info = self.struct_types.get(type_sym);
    const concrete_type = if (struct_info) |si| si.llvm_type else return fn_info.value;

    // Build wrapper fn type: fn(ptr, params...) -> ret
    const orig_param_count = c.LLVMCountParams(fn_info.value);
    const ret_type = c.LLVMGetReturnType(fn_info.fn_type);

    // The wrapper takes ptr (data) + same non-self params as the original.
    // Original: fn(ConcreteType, param1, param2, ...) -> ret
    // Wrapper:  fn(ptr, param1, param2, ...) -> ret
    var wrapper_param_types: [64]c.LLVMTypeRef = undefined;
    wrapper_param_types[0] = ptr_type; // data pointer (self)

    // Copy non-self param types from original.
    if (orig_param_count > 1) {
        var orig_param_types: [64]c.LLVMTypeRef = undefined;
        c.LLVMGetParamTypes(fn_info.fn_type, &orig_param_types);
        for (1..orig_param_count) |i| {
            wrapper_param_types[i] = orig_param_types[i];
        }
    }

    const wrapper_fn_type = c.LLVMFunctionType(ret_type, &wrapper_param_types, orig_param_count, 0);

    // Generate unique wrapper name.
    const type_name = self.pool.resolve(type_sym);
    const method_name = self.pool.resolve(trait_info.method_names[method_idx]);
    var name_buf: [512]u8 = undefined;
    const dynwrap = "__dynwrap_";
    @memcpy(name_buf[0..dynwrap.len], dynwrap);
    @memcpy(name_buf[dynwrap.len..][0..type_name.len], type_name);
    name_buf[dynwrap.len + type_name.len] = '_';
    @memcpy(name_buf[dynwrap.len + type_name.len + 1 ..][0..method_name.len], method_name);
    const wrapper_name_len = dynwrap.len + type_name.len + 1 + method_name.len;
    name_buf[wrapper_name_len] = 0;

    const wrapper_fn = c.LLVMAddFunction(self.module, &name_buf, wrapper_fn_type);
    c.LLVMSetLinkage(wrapper_fn, c.LLVMInternalLinkage);

    // Save/restore builder state.
    const saved_bb = c.LLVMGetInsertBlock(self.builder);
    const saved_fn = self.current_function;

    const bb = c.LLVMAppendBasicBlockInContext(self.context, wrapper_fn, "entry");
    c.LLVMPositionBuilderAtEnd(self.builder, bb);

    // Check if the original method's first parameter is a pointer (e.g. self: &Type).
    const data_ptr = c.LLVMGetParam(wrapper_fn, 0);
    var call_args: [64]c.LLVMValueRef = undefined;
    if (orig_param_count > 0) {
        const first_orig_param_type = c.LLVMTypeOf(c.LLVMGetParam(fn_info.value, 0));
        if (c.LLVMGetTypeKind(first_orig_param_type) == c.LLVMPointerTypeKind) {
            // Method takes self by reference — pass data pointer directly.
            call_args[0] = data_ptr;
        } else {
            // Method takes self by value — load concrete type from data pointer.
            const concrete_val = c.LLVMBuildLoad2(self.builder, concrete_type, data_ptr, "self");
            call_args[0] = concrete_val;
        }
    }
    for (1..orig_param_count) |i| {
        call_args[i] = c.LLVMGetParam(wrapper_fn, @intCast(i));
    }

    const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
    const result = c.LLVMBuildCall2(
        self.builder,
        fn_info.fn_type,
        fn_info.value,
        &call_args,
        orig_param_count,
        if (is_void) "" else "res",
    );

    if (is_void) {
        _ = c.LLVMBuildRetVoid(self.builder);
    } else {
        _ = c.LLVMBuildRet(self.builder, result);
    }

    // Restore builder state.
    if (saved_bb) |bb_ref| {
        c.LLVMPositionBuilderAtEnd(self.builder, bb_ref);
    }
    self.current_function = saved_fn;

    return wrapper_fn;
}

const DynConcreteArgInfo = struct {
    type_sym: u32,
    use_ptr: bool,
};

/// Determine whether an expression flowing into a dyn-typed position has a
/// known concrete implementor type, and whether to wrap it by value or pointer.
fn dynConcreteArgInfo(
    self: *Codegen,
    arg_expr: *const Ast.Expr,
    arg_type: c.LLVMTypeRef,
) ?DynConcreteArgInfo {
    if (self.findTypeSymbol(arg_type)) |type_sym| {
        return .{ .type_sym = type_sym, .use_ptr = false };
    }
    if (c.LLVMGetTypeKind(arg_type) != c.LLVMPointerTypeKind) return null;

    if (arg_expr.kind == .unary) {
        const un = arg_expr.kind.unary;
        if (un.op == .ref_of or un.op == .mut_ref_of) {
            if (un.operand.kind == .ident) {
                const base_sym = un.operand.kind.ident;
                if (self.locals.get(base_sym)) |base_local| {
                    if (self.findTypeSymbol(base_local.ty)) |type_sym| {
                        return .{ .type_sym = type_sym, .use_ptr = true };
                    }
                }
            }
        }
    }

    if (arg_expr.kind == .ident) {
        const arg_sym = arg_expr.kind.ident;
        if (self.ref_pointee_types.get(arg_sym)) |pointee_ty| {
            if (self.findTypeSymbol(pointee_ty)) |type_sym| {
                return .{ .type_sym = type_sym, .use_ptr = true };
            }
        }
        if (self.locals.get(arg_sym)) |arg_local| {
            if (arg_local.pointee_struct) |ps| {
                return .{ .type_sym = ps, .use_ptr = true };
            }
        }
    }

    return null;
}

/// Build a dyn Trait fat pointer from a concrete value.
/// Returns {data_ptr, vtable_ptr} struct.
fn buildDynTraitValue(self: *Codegen, concrete_val: c.LLVMValueRef, type_sym: u32, trait_sym: u32) Error!c.LLVMValueRef {
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const concrete_type = c.LLVMTypeOf(concrete_val);

    // Alloca the concrete value and get a pointer to it.
    const alloca = c.LLVMBuildAlloca(self.builder, concrete_type, "dyn.data");
    _ = c.LLVMBuildStore(self.builder, concrete_val, alloca);

    // Look up vtable global.
    const hash_key = @as(u64, type_sym) << 32 | @as(u64, trait_sym);
    const vtable_global = self.vtable_globals.get(hash_key) orelse return error.UnsupportedExpr;

    // Build fat pointer: {data_ptr, vtable_ptr}.
    var fat_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
    const fat_type = c.LLVMStructTypeInContext(self.context, &fat_types, 2, 0);

    var fat_val = c.LLVMGetUndef(fat_type);
    fat_val = c.LLVMBuildInsertValue(self.builder, fat_val, alloca, 0, "dyn.withdata");
    fat_val = c.LLVMBuildInsertValue(self.builder, fat_val, vtable_global, 1, "dyn.withvtable");

    return fat_val;
}

/// Build a dyn Trait fat pointer from an existing pointer to concrete data.
fn buildDynTraitValueFromPtr(self: *Codegen, data_ptr: c.LLVMValueRef, type_sym: u32, trait_sym: u32) Error!c.LLVMValueRef {
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);

    const hash_key = @as(u64, type_sym) << 32 | @as(u64, trait_sym);
    const vtable_global = self.vtable_globals.get(hash_key) orelse return error.UnsupportedExpr;

    var fat_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
    const fat_type = c.LLVMStructTypeInContext(self.context, &fat_types, 2, 0);

    const erased_ptr = c.LLVMBuildBitCast(self.builder, data_ptr, ptr_type, "dyn.data.cast");
    var fat_val = c.LLVMGetUndef(fat_type);
    fat_val = c.LLVMBuildInsertValue(self.builder, fat_val, erased_ptr, 0, "dyn.withdata");
    fat_val = c.LLVMBuildInsertValue(self.builder, fat_val, vtable_global, 1, "dyn.withvtable");
    return fat_val;
}

/// Dispatch a method call on a dyn Trait object through its vtable.
fn genDynDispatch(self: *Codegen, fat_ptr: c.LLVMValueRef, trait_sym: u32, method_sym: u32, args: []const *const Ast.Expr) Error!c.LLVMValueRef {
    const trait_info = self.trait_infos.get(trait_sym) orelse return error.UnsupportedExpr;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);

    // Find method index in the trait's method list.
    var method_idx: ?usize = null;
    for (trait_info.method_names, 0..) |mn, i| {
        if (mn == method_sym) {
            method_idx = i;
            break;
        }
    }
    const idx = method_idx orelse return error.UnsupportedExpr;

    // Extract data_ptr (field 0) and vtable_ptr (field 1) from fat pointer.
    const data_ptr = c.LLVMBuildExtractValue(self.builder, fat_ptr, 0, "dyn.data");
    const vtable_ptr = c.LLVMBuildExtractValue(self.builder, fat_ptr, 1, "dyn.vtable");

    // GEP into vtable struct to get the method function pointer.
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    var indices = [_]c.LLVMValueRef{
        c.LLVMConstInt(i32_type, 0, 0),
        c.LLVMConstInt(i32_type, @intCast(idx), 0),
    };
    const method_gep = c.LLVMBuildGEP2(self.builder, trait_info.vtable_type, vtable_ptr, &indices, 2, "vtable.gep");
    const method_fn_ptr = c.LLVMBuildLoad2(self.builder, ptr_type, method_gep, "vtable.fn");

    // Build call args: [data_ptr, arg1, arg2, ...]
    var call_args: [64]c.LLVMValueRef = undefined;
    call_args[0] = data_ptr; // self (as opaque pointer)
    for (args, 0..) |arg, i| {
        call_args[1 + i] = try self.genExpr(arg);
    }
    const total_args: u32 = @intCast(1 + args.len);

    // Build the call function type: fn(ptr, params...) -> ret
    const ret_type = trait_info.method_return_types[idx];
    var fn_param_types: [64]c.LLVMTypeRef = undefined;
    fn_param_types[0] = ptr_type; // data pointer (self)
    // For now, use the types of the actual arguments for non-self params.
    for (args, 0..) |_, i| {
        fn_param_types[1 + i] = c.LLVMTypeOf(call_args[1 + i]);
    }

    const call_fn_type = c.LLVMFunctionType(ret_type, &fn_param_types, total_args, 0);

    const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
    const dyn_call = c.LLVMBuildCall2(
        self.builder,
        call_fn_type,
        method_fn_ptr,
        &call_args,
        total_args,
        if (is_void) "" else "dyncall",
    );
    return dyn_call;
}

/// Attempt to devirtualize a dyn dispatch call when the concrete implementor
/// is known at compile time.
fn genKnownConcreteDispatch(
    self: *Codegen,
    fat_ptr: c.LLVMValueRef,
    concrete_sym: u32,
    method_sym: u32,
    args: []const *const Ast.Expr,
) Error!?c.LLVMValueRef {
    const type_name = self.pool.resolve(concrete_sym);
    const method_name = self.pool.resolve(method_sym);
    var name_buf: [512]u8 = undefined;
    if (type_name.len + 1 + method_name.len >= name_buf.len) return null;
    @memcpy(name_buf[0..type_name.len], type_name);
    name_buf[type_name.len] = '.';
    @memcpy(name_buf[type_name.len + 1 ..][0..method_name.len], method_name);
    const mangled = name_buf[0 .. type_name.len + 1 + method_name.len];
    const fn_sym = self.pool.intern(mangled) catch return error.CodegenAlloc;
    const fn_info = self.functions.get(fn_sym) orelse return null;

    var call_args: [64]c.LLVMValueRef = undefined;
    const total_args: u32 = @intCast(1 + args.len);
    if (c.LLVMCountParams(fn_info.value) < 1) return null;

    const self_param_type = c.LLVMTypeOf(c.LLVMGetParam(fn_info.value, 0));
    const data_ptr = c.LLVMBuildExtractValue(self.builder, fat_ptr, 0, "devirt.data");
    if (c.LLVMGetTypeKind(self_param_type) == c.LLVMPointerTypeKind) {
        call_args[0] = c.LLVMBuildBitCast(self.builder, data_ptr, self_param_type, "devirt.self.ptr");
    } else {
        call_args[0] = c.LLVMBuildLoad2(self.builder, self_param_type, data_ptr, "devirt.self");
    }

    for (args, 0..) |arg, i| {
        call_args[1 + i] = try self.genExpr(arg);
    }

    const param_count: u32 = c.LLVMCountParams(fn_info.value);
    for (0..@min(total_args, param_count)) |i| {
        const param_type = c.LLVMTypeOf(c.LLVMGetParam(fn_info.value, @intCast(i)));
        const arg_type = c.LLVMTypeOf(call_args[i]);
        if (c.LLVMGetTypeKind(param_type) == c.LLVMPointerTypeKind and self.isStrType(arg_type)) {
            call_args[i] = self.extractStrPtr(call_args[i]);
        } else if (c.LLVMGetTypeKind(param_type) != c.LLVMPointerTypeKind or c.LLVMGetTypeKind(arg_type) != c.LLVMPointerTypeKind) {
            call_args[i] = self.coerceInt(call_args[i], param_type);
        }
    }

    const ret_type = c.LLVMGetReturnType(fn_info.fn_type);
    const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
    return c.LLVMBuildCall2(
        self.builder,
        fn_info.fn_type,
        fn_info.value,
        &call_args,
        total_args,
        if (is_void) "" else "devirt.call",
    );
}

/// Look up a display-style method for a type.
fn findDisplayMethod(self: *Codegen, type_sym: u32) ?FnInfo {
    const type_name = self.pool.resolve(type_sym);
    // Try "Type.display" first, then "Type.to_string", then "Type.debug".
    const suffixes = [_][]const u8{ ".display", ".to_string", ".debug" };
    for (suffixes) |suffix| {
        var name_buf: [512]u8 = undefined;
        if (type_name.len + suffix.len < name_buf.len) {
            @memcpy(name_buf[0..type_name.len], type_name);
            @memcpy(name_buf[type_name.len..][0..suffix.len], suffix);
            const mangled = name_buf[0 .. type_name.len + suffix.len];
            const fn_sym = self.pool.intern(mangled) catch return null;
            if (self.functions.get(fn_sym)) |fn_info| {
                return fn_info;
            }
        }
    }
    return null;
}

/// Look up a debug-style method for a type (for :? format specifier).
fn findDebugMethod(self: *Codegen, type_sym: u32) ?FnInfo {
    const type_name = self.pool.resolve(type_sym);
    var name_buf: [512]u8 = undefined;
    const suffix = ".debug";
    if (type_name.len + suffix.len < name_buf.len) {
        @memcpy(name_buf[0..type_name.len], type_name);
        @memcpy(name_buf[type_name.len..][0..suffix.len], suffix);
        const mangled = name_buf[0 .. type_name.len + suffix.len];
        const fn_sym = self.pool.intern(mangled) catch return null;
        if (self.functions.get(fn_sym)) |fn_info| {
            return fn_info;
        }
    }
    return null;
}

/// Find the type symbol for a concrete LLVM type.
fn findTypeSymbol(self: *Codegen, llvm_type: c.LLVMTypeRef) ?u32 {
    var it = self.struct_types.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == llvm_type) return entry.key_ptr.*;
    }
    var eit = self.enum_types.iterator();
    while (eit.next()) |entry| {
        if (entry.value_ptr.llvm_type == llvm_type) return entry.key_ptr.*;
    }
    return null;
}

/// Emit drop calls for scoped locals from index `from` to `scope_local_count`
/// in reverse order.
fn emitDrops(self: *Codegen, from: u32) Error!void {
    var i = self.scope_local_count;
    while (i > from) {
        i -= 1;
        const local = self.scope_locals[i];
        if (self.findDropFn(local.ty)) |drop_info| {
            // Check if drop function takes a pointer (reference) or value.
            const param_count = c.LLVMCountParamTypes(drop_info.fn_type);
            var drop_param_types: [1]c.LLVMTypeRef = undefined;
            if (param_count >= 1) {
                c.LLVMGetParamTypes(drop_info.fn_type, &drop_param_types);
            }
            const first_param_is_ptr = param_count >= 1 and c.LLVMGetTypeKind(drop_param_types[0]) == c.LLVMPointerTypeKind;

            var args: [1]c.LLVMValueRef = undefined;
            if (first_param_is_ptr) {
                // Drop takes &Self — pass pointer to local.
                args[0] = local.alloca;
            } else {
                // Drop takes Self by value — load and pass.
                args[0] = c.LLVMBuildLoad2(self.builder, local.ty, local.alloca, "drop.val");
            }
            const ret_type = c.LLVMGetReturnType(drop_info.fn_type);
            const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
            _ = c.LLVMBuildCall2(
                self.builder,
                drop_info.fn_type,
                drop_info.value,
                &args,
                1,
                if (is_void) "" else "drop",
            );
        }
    }
}

// ── Function codegen (pass 2) ────────────────────────────────────

fn genFunction(self: *Codegen, func: Ast.FnDecl) Error!void {
    const fn_info = self.functions.get(func.name) orelse return error.UnsupportedExpr;
    const function = fn_info.value;

    self.current_function = function;
    self.current_ret_type = c.LLVMGetReturnType(fn_info.fn_type);
    self.locals.clearRetainingCapacity();
    self.task_locals.clearRetainingCapacity();
    self.task_local_result_types.clearRetainingCapacity();
    self.task_container_local_elem_types.clearRetainingCapacity();
    self.vec_local_types.clearRetainingCapacity();
    self.defer_depth = 0;
    self.scope_local_count = 0;

    // Set expected_type for function body (helps Ok/Err/None type inference).
    const saved_expected = self.expected_type;
    self.expected_type = self.current_ret_type;
    const saved_result_err_sym = self.current_result_err_symbol;
    const saved_fn_returns_result = self.current_fn_returns_result;
    const saved_fn_saw_return = self.current_fn_saw_explicit_return;
    self.current_result_err_symbol = self.fn_result_err_symbols.get(func.name);
    self.current_fn_returns_result = self.fn_returns_result.get(func.name) != null;
    self.current_fn_saw_explicit_return = false;

    const entry = c.LLVMAppendBasicBlockInContext(self.context, function, "entry");
    c.LLVMPositionBuilderAtEnd(self.builder, entry);

    // Clear trait_locals for this function scope.
    self.trait_locals.clearRetainingCapacity();
    self.trait_local_concrete_types.clearRetainingCapacity();

    // Save/setup tailrec state.
    const saved_tailrec_bb = self.tailrec_body_bb;
    const saved_tailrec_params = self.tailrec_param_allocas;
    const saved_tailrec_sym = self.tailrec_fn_sym;
    self.tailrec_body_bb = null;
    self.tailrec_param_allocas = null;
    self.tailrec_fn_sym = null;

    var method_owner_sym: u32 = 0;
    var method_owner_name: ?[]const u8 = null;
    {
        const fn_name = self.pool.resolve(func.name);
        if (std.mem.indexOfScalar(u8, fn_name, '.')) |dot| {
            if (dot > 0) {
                method_owner_name = fn_name[0..dot];
                method_owner_sym = self.pool.intern(fn_name[0..dot]) catch 0;
            }
        }
    }

    // Add function parameters as locals (alloca + store).
    for (func.params, 0..) |param, i| {
        const param_val = c.LLVMGetParam(function, @intCast(i));
        const param_type = c.LLVMTypeOf(param_val);
        const alloca = c.LLVMBuildAlloca(self.builder, param_type, "");
        _ = c.LLVMBuildStore(self.builder, param_val, alloca);

        // If this parameter has a fn_type annotation, build the LLVM fn type.
        var fn_sig: ?c.LLVMTypeRef = null;
        var pointee_struct: ?u32 = null;
        if (param.type_expr) |te| {
            if (i == 0 and c.LLVMGetTypeKind(param_type) == c.LLVMPointerTypeKind) {
                const param_name = self.pool.resolve(param.name);
                if (std.mem.eql(u8, param_name, "self")) {
                    if (te.kind == .named) {
                        const n = self.pool.resolve(te.kind.named);
                        if (std.mem.eql(u8, n, "Self")) {
                            if (method_owner_sym != 0 and self.struct_types.get(method_owner_sym) != null) {
                                pointee_struct = method_owner_sym;
                            } else if (method_owner_name) |owner| {
                                pointee_struct = self.findStructTypeSymbolByName(owner);
                            }
                        } else if (method_owner_name != null and std.mem.eql(u8, n, method_owner_name.?)) {
                            pointee_struct = te.kind.named;
                        } else {
                            pointee_struct = te.kind.named;
                        }
                    }
                }
            }
            if (te.kind == .fn_type) {
                fn_sig = self.buildFnTypeFromAst(te.kind.fn_type) catch null;
            } else if (dynTraitFromTypeExpr(self, te)) |trait_sym| {
                // Track dyn-typed parameters (`dyn`, `&dyn`, `Box[dyn]`) for
                // dynamic method dispatch in `x.method(...)`.
                self.trait_locals.put(self.allocator, param.name, trait_sym) catch {};
            } else if (te.kind == .generic and std.mem.eql(u8, self.pool.resolve(te.kind.generic.name), "Vec")) {
                if (self.resolveType(te)) |vec_ty| {
                    self.vec_local_types.put(self.allocator, param.name, vec_ty) catch {};
                } else |_| {}
            } else if (te.kind == .ref_type and te.kind.ref_type.pointee.kind == .generic and
                std.mem.eql(u8, self.pool.resolve(te.kind.ref_type.pointee.kind.generic.name), "Vec"))
            {
                if (self.resolveType(te.kind.ref_type.pointee)) |vec_ty| {
                    self.vec_local_types.put(self.allocator, param.name, vec_ty) catch {};
                } else |_| {}
            } else if (te.kind == .slice_type) {
                if (self.resolveType(te.kind.slice_type)) |elem_ty| {
                    self.slice_elem_types.put(self.allocator, param.name, elem_ty) catch {};
                } else |_| {}
            } else if (te.kind == .ref_type and te.kind.ref_type.pointee.kind == .slice_type) {
                if (self.resolveType(te.kind.ref_type.pointee.kind.slice_type)) |elem_ty| {
                    self.slice_elem_types.put(self.allocator, param.name, elem_ty) catch {};
                } else |_| {}
            } else if (te.kind == .ptr_type or te.kind == .ref_type) {
                // Track pointer-to-struct for field access through pointers.
                const pointee_te = if (te.kind == .ptr_type) te.kind.ptr_type.pointee else te.kind.ref_type.pointee;
                if (pointee_te.kind == .named) {
                    const ps = pointee_te.kind.named;
                    if (self.struct_types.get(ps) != null) {
                        pointee_struct = ps;
                    }
                }
            }
        }

        self.locals.put(self.allocator, param.name, .{
            .alloca = alloca,
            .ty = param_type,
            .is_mut = param.is_mut,
            .fn_sig = fn_sig,
            .pointee_struct = pointee_struct,
        }) catch return error.CodegenAlloc;

        if (param.type_expr) |te| {
            if (self.typeExprTaskResultType(te)) |task_result_ty| {
                self.task_locals.put(self.allocator, param.name, {}) catch return error.CodegenAlloc;
                self.task_local_result_types.put(self.allocator, param.name, task_result_ty) catch return error.CodegenAlloc;
            }
            if (self.typeExprTaskContainerElementTypeFromTypeExpr(te)) |task_elem_ty| {
                self.task_container_local_elem_types.put(self.allocator, param.name, task_elem_ty) catch return error.CodegenAlloc;
            }
        }
    }

    // @[tailrec]: create body BB that recursive calls branch back to.
    if (func.is_tailrec and func.params.len > 0) {
        const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "tailrec.body");
        _ = c.LLVMBuildBr(self.builder, body_bb);
        c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
        self.tailrec_body_bb = body_bb;
        self.tailrec_fn_sym = func.name;

        // Collect param allocas for updating on tail call.
        const allocas = self.allocator.alloc(c.LLVMValueRef, func.params.len) catch
            return error.CodegenAlloc;
        for (func.params, 0..) |param, i| {
            if (self.locals.get(param.name)) |local| {
                allocas[i] = local.alloca;
            } else {
                allocas[i] = null;
            }
        }
        self.tailrec_param_allocas = allocas;
    }

    const body_val = try self.genExpr(func.body);

    // Only emit implicit return if the current block has no terminator
    // (i.e. body didn't end with an explicit return).
    const current_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(current_bb) == null) {
        const ret_type = self.current_ret_type;
        const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
        try self.emitDrops(0);
        try self.emitDefers();
        if (!is_void) {
            // If body_val is void (e.g. block ended with a statement not an
            // expression, or after an unconditional return in a dead BB),
            // use a zero default rather than the void undef.
            const body_type = c.LLVMTypeOf(body_val);
            if (body_type == c.LLVMVoidTypeInContext(self.context)) {
                if (self.current_fn_returns_result) {
                    if (self.fn_result_unit_returns.get(func.name) != null) {
                        const unit_val = c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
                        const wrapped = try self.buildResultOk(unit_val, ret_type);
                        _ = c.LLVMBuildRet(self.builder, wrapped);
                    } else {
                        try self.emitImplicitUnreachablePanic(func.body.span);
                    }
                } else {
                    if (self.current_fn_saw_explicit_return) {
                        try self.emitImplicitUnreachablePanic(func.body.span);
                    } else {
                        // Implicit default return: return the type's default value.
                        const default_val = self.buildDefaultValue(ret_type);
                        _ = c.LLVMBuildRet(self.builder, default_val);
                    }
                }
            } else if (body_type != ret_type and self.current_fn_returns_result) {
                // Implicit Ok wrapping: if return type is Result and body is not,
                // wrap the body value in Ok(...).
                const wrapped = try self.buildResultOk(body_val, ret_type);
                _ = c.LLVMBuildRet(self.builder, wrapped);
            } else {
                const coerced = try self.coerceValueForType(body_val, ret_type);
                _ = c.LLVMBuildRet(self.builder, coerced);
            }
        } else {
            _ = c.LLVMBuildRetVoid(self.builder);
        }
    }

    // Restore expected/result context.
    self.expected_type = saved_expected;
    self.current_result_err_symbol = saved_result_err_sym;
    self.current_fn_returns_result = saved_fn_returns_result;
    self.current_fn_saw_explicit_return = saved_fn_saw_return;

    if (self.tailrec_param_allocas) |allocas| {
        self.allocator.free(allocas);
    }

    // Restore tailrec state.
    self.tailrec_body_bb = saved_tailrec_bb;
    self.tailrec_param_allocas = saved_tailrec_params;
    self.tailrec_fn_sym = saved_tailrec_sym;
}

// ── Generator support ────────────────────────────────────────────

/// Count yield expressions in an AST node (recursive).
fn countYields(expr: *const Ast.Expr) u32 {
    return switch (expr.kind) {
        .yield_expr => 1,
        .block => |b| {
            var n: u32 = 0;
            for (b.stmts) |s| n += countYields(s);
            if (b.tail) |t| n += countYields(t);
            return n;
        },
        .while_expr => |w| {
            var n: u32 = 0;
            n += countYields(w.condition);
            n += countYields(w.body);
            return n;
        },
        .loop_expr => |le| countYields(le.body),
        .for_expr => |f| countYields(f.body),
        .if_expr => |ie| {
            var n: u32 = countYields(ie.then_body);
            if (ie.else_body) |eb| n += countYields(eb);
            return n;
        },
        .let_binding => |lb| countYields(lb.value),
        .let_else => |le| countYields(le.value) + countYields(le.else_body),
        .assign => |a| countYields(a.value),
        .defer_expr => |d| countYields(d),
        else => 0,
    };
}

/// Collect local variable declarations from an AST (name + type).
/// Appends to the provided buffers.
fn collectGenLocals(
    expr: *const Ast.Expr,
    names: *[32]u32,
    types: *[32]?*const Ast.TypeExpr,
    count: *u32,
) void {
    switch (expr.kind) {
        .block => |b| {
            for (b.stmts) |s| collectGenLocals(s, names, types, count);
            if (b.tail) |t| collectGenLocals(t, names, types, count);
        },
        .let_binding => |lb| {
            if (count.* < 32) {
                names[count.*] = lb.name;
                types[count.*] = lb.type_expr;
                count.* += 1;
            }
        },
        .let_else => |le| {
            // Each binding in the pattern becomes a local variable.
            for (le.pattern.bindings) |bind_sym| {
                if (count.* < 32) {
                    names[count.*] = bind_sym;
                    types[count.*] = null;
                    count.* += 1;
                }
            }
        },
        .while_expr => |w| {
            collectGenLocals(w.body, names, types, count);
        },
        .loop_expr => |le| collectGenLocals(le.body, names, types, count),
        .for_expr => |f| collectGenLocals(f.body, names, types, count),
        .if_expr => |ie| {
            collectGenLocals(ie.then_body, names, types, count);
            if (ie.else_body) |eb| collectGenLocals(eb, names, types, count);
        },
        else => {},
    }
}

/// Declare a generator: create state struct, constructor function, and next() method.
fn declareGenerator(self: *Codegen, func: Ast.FnDecl) Error!void {
    // Resolve the yield element type from the return type annotation.
    const yield_type = if (func.return_type) |rt|
        try self.resolveType(rt)
    else
        c.LLVMInt32TypeInContext(self.context);

    // Get or create the Option[YieldType] type.
    const opt_info = try self.getOrCreateOptionType(yield_type);
    const option_type = opt_info.llvm_type;

    // Build the state struct type: { i32 state, param1_T, ..., local1_T, ... }
    // For now, all locals default to i32 if type annotation is missing.
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    var field_types_buf: [64]c.LLVMTypeRef = undefined;
    var field_names_buf: [64]u32 = undefined;
    var field_count: u32 = 0;

    // Field 0: state tag (i32).
    const state_sym = self.pool.intern("__state") catch return error.CodegenAlloc;
    field_types_buf[field_count] = i32_type;
    field_names_buf[field_count] = state_sym;
    field_count += 1;

    // Fields for parameters.
    for (func.params) |param| {
        const pt = if (param.type_expr) |te| try self.resolveType(te) else i32_type;
        field_types_buf[field_count] = pt;
        field_names_buf[field_count] = param.name;
        field_count += 1;
    }

    // Collect local variable declarations from the body.
    var local_names: [32]u32 = undefined;
    var local_types: [32]?*const Ast.TypeExpr = undefined;
    var local_count: u32 = 0;
    collectGenLocals(func.body, &local_names, &local_types, &local_count);

    for (0..local_count) |i| {
        const lt = if (local_types[i]) |te| self.resolveType(te) catch i32_type else i32_type;
        // Avoid duplicate field names (let bindings may shadow).
        var dup = false;
        for (field_names_buf[0..field_count]) |fn_sym| {
            if (fn_sym == local_names[i]) {
                dup = true;
                break;
            }
        }
        if (!dup) {
            field_types_buf[field_count] = lt;
            field_names_buf[field_count] = local_names[i];
            field_count += 1;
        }
    }

    // Create the LLVM struct type.
    const gen_name = self.pool.resolve(func.name);
    var struct_name_buf: [256]u8 = undefined;
    const sn_len = @min(gen_name.len, struct_name_buf.len - 7);
    @memcpy(struct_name_buf[0..sn_len], gen_name[0..sn_len]);
    @memcpy(struct_name_buf[sn_len .. sn_len + 6], "_State");
    struct_name_buf[sn_len + 6] = 0;

    const state_struct = c.LLVMStructCreateNamed(self.context, &struct_name_buf);
    c.LLVMStructSetBody(state_struct, &field_types_buf, @intCast(field_count), 0);

    // Register the state struct type.
    const state_sym_name = self.pool.intern(struct_name_buf[0 .. sn_len + 6]) catch return error.CodegenAlloc;

    // Allocate persistent field info.
    const field_names_alloc = self.allocator.alloc(u32, field_count) catch return error.CodegenAlloc;
    @memcpy(field_names_alloc, field_names_buf[0..field_count]);
    const field_types_alloc = self.allocator.alloc(c.LLVMTypeRef, field_count) catch return error.CodegenAlloc;
    @memcpy(field_types_alloc, field_types_buf[0..field_count]);
    const field_defaults = self.allocator.alloc(?*const Ast.Expr, field_count) catch return error.CodegenAlloc;
    @memset(field_defaults, null);

    self.struct_types.put(self.allocator, state_sym_name, .{
        .llvm_type = state_struct,
        .field_names = field_names_alloc,
        .field_types = field_types_alloc,
        .field_defaults = field_defaults,
    }) catch return error.CodegenAlloc;

    // Create the constructor function: fn gen_name(params...) -> StateStruct
    var ctor_param_types: [64]c.LLVMTypeRef = undefined;
    for (func.params, 0..) |param, i| {
        ctor_param_types[i] = if (param.type_expr) |te| try self.resolveType(te) else i32_type;
    }

    const ctor_fn_type = c.LLVMFunctionType(
        state_struct,
        if (func.params.len > 0) &ctor_param_types else null,
        @intCast(func.params.len),
        0,
    );

    var ctor_name_buf: [256]u8 = undefined;
    if (gen_name.len >= ctor_name_buf.len) return error.UnsupportedExpr;
    @memcpy(ctor_name_buf[0..gen_name.len], gen_name);
    ctor_name_buf[gen_name.len] = 0;

    const ctor_fn = c.LLVMAddFunction(self.module, &ctor_name_buf, ctor_fn_type);
    self.functions.put(self.allocator, func.name, .{
        .value = ctor_fn,
        .fn_type = ctor_fn_type,
    }) catch return error.CodegenAlloc;

    // Create the next() method: fn StateType.next(*StateStruct) -> Option[T]
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    var next_param_types = [_]c.LLVMTypeRef{ptr_type};
    const next_fn_type = c.LLVMFunctionType(option_type, &next_param_types, 1, 0);

    // Mangle name as "StateName.next"
    var next_name_buf: [256]u8 = undefined;
    const next_prefix = struct_name_buf[0 .. sn_len + 6];
    if (next_prefix.len + 5 >= next_name_buf.len) return error.UnsupportedExpr;
    @memcpy(next_name_buf[0..next_prefix.len], next_prefix);
    @memcpy(next_name_buf[next_prefix.len .. next_prefix.len + 5], ".next");
    next_name_buf[next_prefix.len + 5] = 0;

    const next_fn = c.LLVMAddFunction(self.module, &next_name_buf, next_fn_type);
    const next_sym = self.pool.intern(next_name_buf[0 .. next_prefix.len + 5]) catch return error.CodegenAlloc;
    self.functions.put(self.allocator, next_sym, .{
        .value = next_fn,
        .fn_type = next_fn_type,
    }) catch return error.CodegenAlloc;
}

/// Generate the constructor body and next() state machine for a generator.
fn genGeneratorBody(self: *Codegen, func: Ast.FnDecl) Error!void {
    const i32_type = c.LLVMInt32TypeInContext(self.context);

    // Resolve yield type.
    const yield_type = if (func.return_type) |rt|
        try self.resolveType(rt)
    else
        i32_type;

    const opt_info = try self.getOrCreateOptionType(yield_type);
    const option_type = opt_info.llvm_type;

    // Look up the generator's state struct.
    const gen_name = self.pool.resolve(func.name);
    var struct_name_buf: [256]u8 = undefined;
    const sn_len = @min(gen_name.len, struct_name_buf.len - 7);
    @memcpy(struct_name_buf[0..sn_len], gen_name[0..sn_len]);
    @memcpy(struct_name_buf[sn_len .. sn_len + 6], "_State");

    const state_sym_name = self.pool.intern(struct_name_buf[0 .. sn_len + 6]) catch return error.CodegenAlloc;
    const sti = self.struct_types.get(state_sym_name) orelse return error.UnsupportedExpr;
    const state_struct = sti.llvm_type;

    // ── Generate constructor body ──
    const ctor_info = self.functions.get(func.name) orelse return error.UnsupportedExpr;
    const ctor_fn = ctor_info.value;
    {
        const saved_fn = self.current_function;
        const saved_ret = self.current_ret_type;
        const saved_bb = c.LLVMGetInsertBlock(self.builder);
        const saved_locals = self.locals;

        self.current_function = ctor_fn;
        self.current_ret_type = state_struct;
        self.locals = .{};

        const entry = c.LLVMAppendBasicBlockInContext(self.context, ctor_fn, "entry");
        c.LLVMPositionBuilderAtEnd(self.builder, entry);

        // Allocate the state struct.
        const alloca = c.LLVMBuildAlloca(self.builder, state_struct, "state");

        // Set state tag = 0.
        const state_gep = c.LLVMBuildStructGEP2(self.builder, state_struct, alloca, 0, "state.tag");
        _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i32_type, 0, 0), state_gep);

        // Copy parameters into state struct fields (starting at index 1).
        for (func.params, 0..) |_, i| {
            const param_val = c.LLVMGetParam(ctor_fn, @intCast(i));
            const field_gep = c.LLVMBuildStructGEP2(self.builder, state_struct, alloca, @intCast(i + 1), "");
            _ = c.LLVMBuildStore(self.builder, param_val, field_gep);
        }

        // Zero-initialize local fields.
        for (func.params.len + 1..sti.field_names.len) |i| {
            const field_gep = c.LLVMBuildStructGEP2(self.builder, state_struct, alloca, @intCast(i), "");
            _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(sti.field_types[i], 0, 0), field_gep);
        }

        const result = c.LLVMBuildLoad2(self.builder, state_struct, alloca, "state.val");
        _ = c.LLVMBuildRet(self.builder, result);

        self.current_function = saved_fn;
        self.current_ret_type = saved_ret;
        self.locals = saved_locals;
        if (saved_bb != null) c.LLVMPositionBuilderAtEnd(self.builder, saved_bb);
    }

    // ── Generate next() body ──
    var next_name_buf: [256]u8 = undefined;
    const next_prefix = struct_name_buf[0 .. sn_len + 6];
    @memcpy(next_name_buf[0..next_prefix.len], next_prefix);
    @memcpy(next_name_buf[next_prefix.len .. next_prefix.len + 5], ".next");
    const next_sym = self.pool.intern(next_name_buf[0 .. next_prefix.len + 5]) catch return error.CodegenAlloc;
    const next_info = self.functions.get(next_sym) orelse return error.UnsupportedExpr;
    const next_fn = next_info.value;

    {
        const saved_fn = self.current_function;
        const saved_ret = self.current_ret_type;
        const saved_bb = c.LLVMGetInsertBlock(self.builder);
        const saved_locals = self.locals;
        const saved_expected = self.expected_type;

        self.current_function = next_fn;
        self.current_ret_type = option_type;
        self.locals = .{};
        self.defer_depth = 0;
        self.scope_local_count = 0;

        // Set generator state for genExpr to use.
        self.gen_state_ptr = c.LLVMGetParam(next_fn, 0);
        self.gen_state_type = state_struct;
        self.gen_option_type = option_type;
        self.gen_payload_type = yield_type;
        self.gen_yield_count = countYields(func.body);
        self.gen_current_yield = 0;
        self.gen_field_indices.clearRetainingCapacity();

        // Build field index mapping.
        for (sti.field_names, 0..) |fn_sym, i| {
            self.gen_field_indices.put(self.allocator, fn_sym, @intCast(i)) catch {};
        }

        const entry_bb = c.LLVMAppendBasicBlockInContext(self.context, next_fn, "entry");
        const start_bb = c.LLVMAppendBasicBlockInContext(self.context, next_fn, "state.0");
        const done_bb = c.LLVMAppendBasicBlockInContext(self.context, next_fn, "done");
        self.gen_done_bb = done_bb;

        // Create resume basic blocks for each yield point.
        for (0..self.gen_yield_count) |i| {
            var resume_name: [32]u8 = undefined;
            const rn = std.fmt.bufPrint(&resume_name, "resume.{d}", .{i}) catch "resume";
            var rn_buf: [32]u8 = undefined;
            @memcpy(rn_buf[0..rn.len], rn);
            rn_buf[rn.len] = 0;
            self.gen_resume_bbs[i] = c.LLVMAppendBasicBlockInContext(self.context, next_fn, &rn_buf);
        }

        // Entry block: create all local allocas here so they dominate all uses.
        c.LLVMPositionBuilderAtEnd(self.builder, entry_bb);
        const self_ptr = c.LLVMGetParam(next_fn, 0);

        // Create local allocas in the entry block (dominates everything).
        for (1..sti.field_names.len) |i| {
            const field_sym = sti.field_names[i];
            const field_ty = sti.field_types[i];
            const local_alloca = c.LLVMBuildAlloca(self.builder, field_ty, "");
            self.locals.put(self.allocator, field_sym, .{
                .alloca = local_alloca,
                .ty = field_ty,
                .is_mut = true,
            }) catch {};
        }

        // Load state tag and switch.
        const state_tag_gep = c.LLVMBuildStructGEP2(self.builder, state_struct, self_ptr, 0, "state.tag.ptr");
        const state_tag = c.LLVMBuildLoad2(self.builder, i32_type, state_tag_gep, "state.tag");
        const switch_inst = c.LLVMBuildSwitch(self.builder, state_tag, done_bb, @intCast(self.gen_yield_count + 1));
        c.LLVMAddCase(switch_inst, c.LLVMConstInt(i32_type, 0, 0), start_bb);
        for (0..self.gen_yield_count) |i| {
            c.LLVMAddCase(switch_inst, c.LLVMConstInt(i32_type, @intCast(i + 1), 0), self.gen_resume_bbs[i]);
        }

        // Start block: load all state struct fields into local allocas.
        c.LLVMPositionBuilderAtEnd(self.builder, start_bb);
        for (1..sti.field_names.len) |i| {
            const field_sym = sti.field_names[i];
            const field_ty = sti.field_types[i];
            const field_gep = c.LLVMBuildStructGEP2(self.builder, state_struct, self_ptr, @intCast(i), "");
            const field_val = c.LLVMBuildLoad2(self.builder, field_ty, field_gep, "");
            if (self.locals.get(field_sym)) |local| {
                _ = c.LLVMBuildStore(self.builder, field_val, local.alloca);
            }
        }

        self.expected_type = option_type;

        // Generate the body.  yield_expr handling in genExpr will:
        // 1. Save all locals back to the state struct.
        // 2. Set state tag = yield_index + 1.
        // 3. Return Some(yield_value).
        // 4. Position builder at the resume block.
        _ = self.genExpr(func.body) catch {
            // If body gen fails, ensure done_bb is terminated.
            c.LLVMPositionBuilderAtEnd(self.builder, done_bb);
            _ = c.LLVMBuildRet(self.builder, self.buildOptionNone(option_type));
            // Terminate any unterminated resume blocks.
            for (0..self.gen_yield_count) |i| {
                if (c.LLVMGetBasicBlockTerminator(self.gen_resume_bbs[i]) == null) {
                    c.LLVMPositionBuilderAtEnd(self.builder, self.gen_resume_bbs[i]);
                    _ = c.LLVMBuildBr(self.builder, done_bb);
                }
            }
            self.gen_state_ptr = null;
            self.gen_state_type = null;
            self.gen_done_bb = null;
            self.gen_option_type = null;
            self.gen_payload_type = null;

            self.current_function = saved_fn;
            self.current_ret_type = saved_ret;
            self.locals = saved_locals;
            self.expected_type = saved_expected;
            if (saved_bb != null) c.LLVMPositionBuilderAtEnd(self.builder, saved_bb);
            return;
        };

        // After the body, if current block has no terminator, fall through to done.
        const final_bb = c.LLVMGetInsertBlock(self.builder);
        if (c.LLVMGetBasicBlockTerminator(final_bb) == null) {
            _ = c.LLVMBuildBr(self.builder, done_bb);
        }

        // Done block: return None.
        c.LLVMPositionBuilderAtEnd(self.builder, done_bb);
        const done_state_gep = c.LLVMBuildStructGEP2(self.builder, state_struct, self_ptr, 0, "");
        _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i32_type, @as(c_ulonglong, @intCast(self.gen_yield_count + 100)), 0), done_state_gep);
        _ = c.LLVMBuildRet(self.builder, self.buildOptionNone(option_type));

        // Ensure all resume blocks are terminated.
        for (0..self.gen_yield_count) |i| {
            if (c.LLVMGetBasicBlockTerminator(self.gen_resume_bbs[i]) == null) {
                c.LLVMPositionBuilderAtEnd(self.builder, self.gen_resume_bbs[i]);
                // Load locals from state, same as start_bb.
                for (1..sti.field_names.len) |fi| {
                    const field_sym = sti.field_names[fi];
                    const field_ty = sti.field_types[fi];
                    const field_gep = c.LLVMBuildStructGEP2(self.builder, state_struct, self_ptr, @intCast(fi), "");
                    const field_val = c.LLVMBuildLoad2(self.builder, field_ty, field_gep, "");
                    if (self.locals.get(field_sym)) |local| {
                        _ = c.LLVMBuildStore(self.builder, field_val, local.alloca);
                    }
                }
                _ = c.LLVMBuildBr(self.builder, done_bb);
            }
        }

        // Cleanup generator state.
        self.gen_state_ptr = null;
        self.gen_state_type = null;
        self.gen_done_bb = null;
        self.gen_option_type = null;
        self.gen_payload_type = null;

        self.current_function = saved_fn;
        self.current_ret_type = saved_ret;
        self.locals = saved_locals;
        self.expected_type = saved_expected;
        if (saved_bb != null) c.LLVMPositionBuilderAtEnd(self.builder, saved_bb);
    }
}

const CapturedVar = struct {
    sym: u32,
    value: c.LLVMValueRef,
    ty: c.LLVMTypeRef,
    is_mut: bool = false,
};

fn genClosure(self: *Codegen, cl: Ast.ClosureExpr) Error!c.LLVMValueRef {
    // Detect captured variables by scanning the body for idents in parent locals.
    var captured: [16]CapturedVar = undefined;
    var capture_count: u32 = 0;
    self.findCaptures(cl.body, cl.params, &captured, &capture_count);

    if (capture_count > 0) {
        return self.genCapturingClosure(cl, &captured, capture_count);
    }

    return self.genNonCapturingClosure(cl);
}

fn genNonCapturingClosure(self: *Codegen, cl: Ast.ClosureExpr) Error!c.LLVMValueRef {
    // Save current function state.
    const saved_function = self.current_function;
    const saved_ret_type = self.current_ret_type;
    const saved_bb = c.LLVMGetInsertBlock(self.builder);
    const saved_locals = self.locals;

    // Generate a unique name for the closure function.
    var name_buf: [32]u8 = undefined;
    const name_len = std.fmt.bufPrint(&name_buf, "__closure_{d}\x00", .{self.closure_counter}) catch
        return error.CodegenAlloc;
    self.closure_counter += 1;
    const name_z: [*:0]const u8 = @ptrCast(name_len.ptr);

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const param_count: u32 = @intCast(cl.params.len);

    // All closures take a context pointer as first parameter (uniform convention).
    var param_types_buf: [17]c.LLVMTypeRef = undefined;
    param_types_buf[0] = ptr_type; // context/captures pointer
    for (0..param_count) |i| {
        // Use annotated type if available, otherwise default to i32.
        if (i < cl.param_types.len) {
            if (cl.param_types[i]) |ty_expr| {
                param_types_buf[1 + i] = try self.resolveType(ty_expr);
            } else {
                param_types_buf[1 + i] = i32_type;
            }
        } else {
            param_types_buf[1 + i] = i32_type;
        }
    }

    // Resolve return type: use annotation if provided; unannotated closures
    // default to i32 in Stage 0 and are restricted to i32-compatible bodies.
    const has_explicit_ret = cl.return_type != null;
    const ret_type = if (cl.return_type) |rt| try self.resolveType(rt) else i32_type;

    const fn_type = c.LLVMFunctionType(ret_type, &param_types_buf, 1 + param_count, 0);
    const function = c.LLVMAddFunction(self.module, name_z, fn_type);

    // Reset locals for the closure scope.
    self.locals = .empty;
    self.current_function = function;
    self.current_ret_type = ret_type;

    const entry = c.LLVMAppendBasicBlockInContext(self.context, function, "entry");
    c.LLVMPositionBuilderAtEnd(self.builder, entry);

    // Skip param 0 (context pointer — unused for non-capturing).
    // Add closure params as locals starting at param index 1.
    for (cl.params, 0..) |param_sym, i| {
        const param_val = c.LLVMGetParam(function, @intCast(1 + i));
        const param_type = c.LLVMTypeOf(param_val);
        const alloca = c.LLVMBuildAlloca(self.builder, param_type, "");
        _ = c.LLVMBuildStore(self.builder, param_val, alloca);
        var pointee_struct: ?u32 = null;
        if (i < cl.param_types.len) {
            if (cl.param_types[i]) |te| {
                if (te.kind == .ref_type or te.kind == .ptr_type) {
                    const pointee_te = if (te.kind == .ref_type) te.kind.ref_type.pointee else te.kind.ptr_type.pointee;
                    if (pointee_te.kind == .named and self.struct_types.get(pointee_te.kind.named) != null) {
                        pointee_struct = pointee_te.kind.named;
                    }
                }
            }
        }
        self.locals.put(self.allocator, param_sym, .{
            .alloca = alloca,
            .ty = param_type,
            .is_mut = false,
            .pointee_struct = pointee_struct,
        }) catch return error.CodegenAlloc;
    }

    // Generate body.
    const body_val = try self.genExpr(cl.body);
    if (!has_explicit_ret) {
        const body_type = c.LLVMTypeOf(body_val);
        const body_kind = c.LLVMGetTypeKind(body_type);
        if (body_kind != c.LLVMIntegerTypeKind and body_type != c.LLVMVoidTypeInContext(self.context)) {
            self.codegen_error_detail = self.allocator.dupe(
                u8,
                "Stage 0 requires explicit closure return types for non-integer bodies",
            ) catch null;
            return error.UnsupportedExpr;
        }
    }

    // Emit return if no terminator.
    const current_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(current_bb) == null) {
        const coerced = self.coerceInt(body_val, ret_type);
        _ = c.LLVMBuildRet(self.builder, coerced);
    }

    // Restore parent function state.
    self.locals.deinit(self.allocator);
    self.current_function = saved_function;
    self.current_ret_type = saved_ret_type;
    self.locals = saved_locals;
    c.LLVMPositionBuilderAtEnd(self.builder, saved_bb);

    // Build fat pointer: { fn_ptr, null } — uniform closure representation.
    var fat_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
    const fat_type = c.LLVMStructTypeInContext(self.context, &fat_types, 2, 0);
    const null_ptr = c.LLVMConstNull(ptr_type);
    var result = c.LLVMGetUndef(fat_type);
    result = c.LLVMBuildInsertValue(self.builder, result, function, 0, "");
    result = c.LLVMBuildInsertValue(self.builder, result, null_ptr, 1, "");
    return result;
}

fn genCapturingClosure(
    self: *Codegen,
    cl: Ast.ClosureExpr,
    captured: []const CapturedVar,
    capture_count: u32,
) Error!c.LLVMValueRef {
    const saved_function = self.current_function;
    const saved_ret_type = self.current_ret_type;
    const saved_bb = c.LLVMGetInsertBlock(self.builder);
    const saved_locals = self.locals;

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);

    // Build capture struct type.
    var cap_field_types: [16]c.LLVMTypeRef = undefined;
    for (captured[0..capture_count], 0..) |cap, i| {
        if (cap.is_mut) {
            // Mutable capture: store pointer to original variable
            cap_field_types[i] = ptr_type;
        } else {
            cap_field_types[i] = cap.ty;
        }
    }
    const cap_struct_type = c.LLVMStructTypeInContext(
        self.context,
        &cap_field_types,
        capture_count,
        0,
    );

    // Generate closure function: fn(capture_ptr, params...) -> ret_type
    var name_buf: [32]u8 = undefined;
    const name_len = std.fmt.bufPrint(&name_buf, "__closure_{d}\x00", .{self.closure_counter}) catch
        return error.CodegenAlloc;
    self.closure_counter += 1;
    const name_z: [*:0]const u8 = @ptrCast(name_len.ptr);

    const param_count: u32 = @intCast(cl.params.len);
    const total_params = 1 + param_count; // capture_ptr + user params

    var fn_param_types: [17]c.LLVMTypeRef = undefined;
    fn_param_types[0] = ptr_type; // capture struct pointer
    for (0..param_count) |i| {
        if (i < cl.param_types.len) {
            if (cl.param_types[i]) |ty_expr| {
                fn_param_types[1 + i] = try self.resolveType(ty_expr);
            } else {
                fn_param_types[1 + i] = i32_type;
            }
        } else {
            fn_param_types[1 + i] = i32_type;
        }
    }

    const has_explicit_ret = cl.return_type != null;
    const cap_ret_type = if (cl.return_type) |rt| try self.resolveType(rt) else i32_type;

    const fn_type = c.LLVMFunctionType(cap_ret_type, &fn_param_types, total_params, 0);
    const function = c.LLVMAddFunction(self.module, name_z, fn_type);

    // Generate function body.
    self.locals = .empty;
    self.current_function = function;
    self.current_ret_type = cap_ret_type;

    const entry = c.LLVMAppendBasicBlockInContext(self.context, function, "entry");
    c.LLVMPositionBuilderAtEnd(self.builder, entry);

    // Extract captured values from capture struct (param 0).
    const cap_ptr = c.LLVMGetParam(function, 0);
    for (captured[0..capture_count], 0..) |cap, i| {
        const gep = c.LLVMBuildStructGEP2(
            self.builder,
            cap_struct_type,
            cap_ptr,
            @intCast(i),
            "",
        );
        if (cap.is_mut) {
            // Mutable capture: the struct field is a pointer to the original variable.
            // Load the pointer, then use it directly as the local's alloca.
            const original_ptr = c.LLVMBuildLoad2(self.builder, ptr_type, gep, "");
            self.locals.put(self.allocator, cap.sym, .{
                .alloca = original_ptr,
                .ty = cap.ty,
                .is_mut = true,
            }) catch return error.CodegenAlloc;
        } else {
            // Immutable capture: load value and store in local alloca.
            const loaded = c.LLVMBuildLoad2(self.builder, cap.ty, gep, "");
            const alloca = c.LLVMBuildAlloca(self.builder, cap.ty, "");
            _ = c.LLVMBuildStore(self.builder, loaded, alloca);
            self.locals.put(self.allocator, cap.sym, .{
                .alloca = alloca,
                .ty = cap.ty,
                .is_mut = false,
            }) catch return error.CodegenAlloc;
        }
    }

    // Add user params.
    for (cl.params, 0..) |param_sym, i| {
        const param_val = c.LLVMGetParam(function, @intCast(1 + i));
        const param_type = c.LLVMTypeOf(param_val);
        const alloca = c.LLVMBuildAlloca(self.builder, param_type, "");
        _ = c.LLVMBuildStore(self.builder, param_val, alloca);
        var pointee_struct: ?u32 = null;
        if (i < cl.param_types.len) {
            if (cl.param_types[i]) |te| {
                if (te.kind == .ref_type or te.kind == .ptr_type) {
                    const pointee_te = if (te.kind == .ref_type) te.kind.ref_type.pointee else te.kind.ptr_type.pointee;
                    if (pointee_te.kind == .named and self.struct_types.get(pointee_te.kind.named) != null) {
                        pointee_struct = pointee_te.kind.named;
                    }
                }
            }
        }
        self.locals.put(self.allocator, param_sym, .{
            .alloca = alloca,
            .ty = param_type,
            .is_mut = false,
            .pointee_struct = pointee_struct,
        }) catch return error.CodegenAlloc;
    }

    // Generate body.
    const body_val = try self.genExpr(cl.body);
    if (!has_explicit_ret) {
        const body_type = c.LLVMTypeOf(body_val);
        const body_kind = c.LLVMGetTypeKind(body_type);
        if (body_kind != c.LLVMIntegerTypeKind and body_type != c.LLVMVoidTypeInContext(self.context)) {
            self.codegen_error_detail = self.allocator.dupe(
                u8,
                "Stage 0 requires explicit closure return types for non-integer bodies",
            ) catch null;
            return error.UnsupportedExpr;
        }
    }
    const current_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(current_bb) == null) {
        const body_type = c.LLVMTypeOf(body_val);
        if (body_type == c.LLVMVoidTypeInContext(self.context) or cap_ret_type == c.LLVMVoidTypeInContext(self.context)) {
            // Body is void (e.g. assignment) — need to adjust.
            // If return type was inferred as i32 but body is void, fix up.
            if (cap_ret_type != c.LLVMVoidTypeInContext(self.context)) {
                // Return default 0 for i32 return type.
                _ = c.LLVMBuildRet(self.builder, c.LLVMConstInt(cap_ret_type, 0, 0));
            } else {
                _ = c.LLVMBuildRetVoid(self.builder);
            }
        } else {
            const coerced = self.coerceInt(body_val, cap_ret_type);
            _ = c.LLVMBuildRet(self.builder, coerced);
        }
    }

    // Restore parent state.
    self.locals.deinit(self.allocator);
    self.current_function = saved_function;
    self.current_ret_type = saved_ret_type;
    self.locals = saved_locals;
    c.LLVMPositionBuilderAtEnd(self.builder, saved_bb);

    // Build capture struct at the call site.
    const cap_alloca = c.LLVMBuildAlloca(self.builder, cap_struct_type, "captures");
    for (captured[0..capture_count], 0..) |cap, i| {
        const gep = c.LLVMBuildStructGEP2(
            self.builder,
            cap_struct_type,
            cap_alloca,
            @intCast(i),
            "",
        );
        _ = c.LLVMBuildStore(self.builder, cap.value, gep);
    }

    // Build fat pointer: { fn_ptr, capture_struct_ptr }.
    var fat_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
    const fat_type = c.LLVMStructTypeInContext(self.context, &fat_types, 2, 0);
    const fat_alloca = c.LLVMBuildAlloca(self.builder, fat_type, "closure");

    // Store fn_ptr.
    const fn_gep = c.LLVMBuildStructGEP2(self.builder, fat_type, fat_alloca, 0, "");
    _ = c.LLVMBuildStore(self.builder, function, fn_gep);

    // Store capture_ptr.
    const cap_gep = c.LLVMBuildStructGEP2(self.builder, fat_type, fat_alloca, 1, "");
    _ = c.LLVMBuildStore(self.builder, cap_alloca, cap_gep);

    return c.LLVMBuildLoad2(self.builder, fat_type, fat_alloca, "closure.val");
}

/// Wrap a named function as a fat pointer {wrapper_fn, null} for passing to fn-type params.
/// Creates a thin wrapper that adds a context pointer as first param and forwards the rest.
fn wrapFunctionAsFatPointer(self: *Codegen, func: c.LLVMValueRef, orig_fn_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);

    // Get the original function's param types and return type.
    const orig_param_count = c.LLVMCountParamTypes(orig_fn_type);
    const ret_type = c.LLVMGetReturnType(orig_fn_type);

    // Build wrapper function type: fn(ctx: ptr, orig_params...) -> ret_type
    var wrapper_param_types: [17]c.LLVMTypeRef = undefined;
    wrapper_param_types[0] = ptr_type; // ctx pointer (ignored)
    var orig_param_types: [16]c.LLVMTypeRef = undefined;
    c.LLVMGetParamTypes(orig_fn_type, &orig_param_types);
    for (0..orig_param_count) |i| {
        wrapper_param_types[1 + i] = orig_param_types[i];
    }
    const total_params = 1 + orig_param_count;
    const wrapper_fn_type = c.LLVMFunctionType(ret_type, &wrapper_param_types, total_params, 0);

    // Create wrapper function.
    var name_buf: [32]u8 = undefined;
    const name_len = std.fmt.bufPrint(&name_buf, "__wrap_{d}\x00", .{self.closure_counter}) catch
        return error.CodegenAlloc;
    self.closure_counter += 1;
    const name_z: [*:0]const u8 = @ptrCast(name_len.ptr);

    const wrapper = c.LLVMAddFunction(self.module, name_z, wrapper_fn_type);

    // Build wrapper body: call original function with params 1..N (skip ctx).
    const saved_bb = c.LLVMGetInsertBlock(self.builder);
    const entry = c.LLVMAppendBasicBlockInContext(self.context, wrapper, "entry");
    c.LLVMPositionBuilderAtEnd(self.builder, entry);

    var call_args: [16]c.LLVMValueRef = undefined;
    for (0..orig_param_count) |i| {
        call_args[i] = c.LLVMGetParam(wrapper, @intCast(1 + i));
    }

    const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
    const call_result = c.LLVMBuildCall2(
        self.builder,
        orig_fn_type,
        func,
        if (orig_param_count > 0) &call_args else null,
        orig_param_count,
        if (is_void) "" else "call",
    );

    if (is_void) {
        _ = c.LLVMBuildRetVoid(self.builder);
    } else {
        _ = c.LLVMBuildRet(self.builder, call_result);
    }

    // Restore builder position.
    c.LLVMPositionBuilderAtEnd(self.builder, saved_bb);

    // Build fat pointer: {wrapper, null}
    var fat_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
    const fat_type = c.LLVMStructTypeInContext(self.context, &fat_types, 2, 0);
    const null_ptr = c.LLVMConstNull(ptr_type);
    var result = c.LLVMGetUndef(fat_type);
    result = c.LLVMBuildInsertValue(self.builder, result, wrapper, 0, "");
    result = c.LLVMBuildInsertValue(self.builder, result, null_ptr, 1, "");
    return result;
}

/// Scan a closure body for identifiers that reference parent locals.
fn findCaptures(
    self: *Codegen,
    expr: *const Ast.Expr,
    closure_params: []const Ast.Symbol,
    captured: *[16]CapturedVar,
    count: *u32,
) void {
    switch (expr.kind) {
        .ident => |sym| {
            // Skip if it's a closure param.
            for (closure_params) |p| {
                if (p == sym) return;
            }
            // Skip if it's a known function.
            if (self.functions.get(sym) != null) return;
            // Skip if it's an enum variant.
            var e_it = self.enum_types.iterator();
            while (e_it.next()) |entry| {
                for (entry.value_ptr.variant_names) |vn| {
                    if (vn == sym) return;
                }
            }
            // If it's a parent local, it's a capture.
            if (self.locals.get(sym)) |info| {
                // Check if already captured.
                for (captured[0..count.*]) |cap| {
                    if (cap.sym == sym) return;
                }
                if (count.* < 16) {
                    if (info.is_mut) {
                        // Mutable capture: capture by reference (pointer to alloca).
                        captured[count.*] = .{
                            .sym = sym,
                            .value = info.alloca, // pointer, not loaded value
                            .ty = info.ty,
                            .is_mut = true,
                        };
                    } else {
                        // Immutable capture: capture by value.
                        const val = c.LLVMBuildLoad2(self.builder, info.ty, info.alloca, "");
                        captured[count.*] = .{ .sym = sym, .value = val, .ty = info.ty };
                    }
                    count.* += 1;
                }
            }
        },
        .binary => |bin| {
            self.findCaptures(bin.lhs, closure_params, captured, count);
            self.findCaptures(bin.rhs, closure_params, captured, count);
        },
        .unary => |un| {
            self.findCaptures(un.operand, closure_params, captured, count);
        },
        .call => |call_e| {
            self.findCaptures(call_e.callee, closure_params, captured, count);
            for (call_e.args) |arg| {
                self.findCaptures(arg, closure_params, captured, count);
            }
        },
        .block => |blk| {
            for (blk.stmts) |stmt| {
                self.findCaptures(stmt, closure_params, captured, count);
            }
            if (blk.tail) |tail| {
                self.findCaptures(tail, closure_params, captured, count);
            }
        },
        .if_expr => |if_e| {
            self.findCaptures(if_e.condition, closure_params, captured, count);
            self.findCaptures(if_e.then_body, closure_params, captured, count);
            if (if_e.else_body) |eb| self.findCaptures(eb, closure_params, captured, count);
        },
        .let_binding => |lb| {
            self.findCaptures(lb.value, closure_params, captured, count);
        },
        .let_else => |le| {
            self.findCaptures(le.value, closure_params, captured, count);
            self.findCaptures(le.else_body, closure_params, captured, count);
        },
        .tuple_destructure => |td| {
            self.findCaptures(td.value, closure_params, captured, count);
        },
        .assign => |a| {
            self.findCaptures(a.target, closure_params, captured, count);
            self.findCaptures(a.value, closure_params, captured, count);
        },
        .tuple => |elems| {
            for (elems) |elem| {
                self.findCaptures(elem, closure_params, captured, count);
            }
        },
        .range => |r| {
            if (r.start) |s| self.findCaptures(s, closure_params, captured, count);
            if (r.end) |e| self.findCaptures(e, closure_params, captured, count);
        },
        .field_access => |fa| {
            self.findCaptures(fa.expr, closure_params, captured, count);
        },
        .optional_chain => |oc| {
            self.findCaptures(oc.expr, closure_params, captured, count);
            if (oc.args) |args| {
                for (args) |arg| {
                    self.findCaptures(arg, closure_params, captured, count);
                }
            }
        },
        .index => |idx| {
            self.findCaptures(idx.expr, closure_params, captured, count);
            self.findCaptures(idx.index, closure_params, captured, count);
        },
        .slice => |sl| {
            self.findCaptures(sl.expr, closure_params, captured, count);
            if (sl.start) |s| self.findCaptures(s, closure_params, captured, count);
            if (sl.end) |e| self.findCaptures(e, closure_params, captured, count);
        },
        .pipeline => |p| {
            self.findCaptures(p.lhs, closure_params, captured, count);
            self.findCaptures(p.rhs, closure_params, captured, count);
        },
        .while_expr => |w| {
            self.findCaptures(w.condition, closure_params, captured, count);
            self.findCaptures(w.body, closure_params, captured, count);
        },
        .loop_expr => |le| self.findCaptures(le.body, closure_params, captured, count),
        .for_expr => |f| {
            self.findCaptures(f.iterable, closure_params, captured, count);
            self.findCaptures(f.body, closure_params, captured, count);
        },
        .break_expr => |be| if (be.value) |inner| self.findCaptures(inner, closure_params, captured, count),
        .array_literal => |elems| {
            for (elems) |elem| {
                self.findCaptures(elem, closure_params, captured, count);
            }
        },
        .array_comprehension => |ac| {
            self.findCaptures(ac.expr, closure_params, captured, count);
            self.findCaptures(ac.iterable, closure_params, captured, count);
            if (ac.filter) |f| self.findCaptures(f, closure_params, captured, count);
            if (ac.clauses) |clauses| {
                for (clauses) |clause| {
                    self.findCaptures(clause.iterable, closure_params, captured, count);
                }
            }
        },
        .struct_literal => |sl| {
            for (sl.fields) |field| {
                self.findCaptures(field.value, closure_params, captured, count);
            }
        },
        .match_expr => |m| {
            self.findCaptures(m.subject, closure_params, captured, count);
            for (m.arms) |arm| {
                if (arm.guard) |g| self.findCaptures(g, closure_params, captured, count);
                self.findCaptures(arm.body, closure_params, captured, count);
            }
        },
        .enum_variant => |ev| {
            for (ev.args) |arg| {
                self.findCaptures(arg, closure_params, captured, count);
            }
        },
        .closure => |cl| self.findCaptures(cl.body, closure_params, captured, count),
        .cast => |ca| self.findCaptures(ca.expr, closure_params, captured, count),
        .defer_expr => |inner| self.findCaptures(inner, closure_params, captured, count),
        .with_expr => |w| {
            self.findCaptures(w.source, closure_params, captured, count);
            self.findCaptures(w.body, closure_params, captured, count);
        },
        .record_update => |ru| {
            self.findCaptures(ru.source, closure_params, captured, count);
            for (ru.fields) |field| {
                self.findCaptures(field.value, closure_params, captured, count);
            }
        },
        .yield_expr => |inner| self.findCaptures(inner, closure_params, captured, count),
        .await_expr => |inner| self.findCaptures(inner, closure_params, captured, count),
        .async_block => |inner| self.findCaptures(inner, closure_params, captured, count),
        .async_scope => |as| self.findCaptures(as.body, closure_params, captured, count),
        .spawn_expr => |inner| self.findCaptures(inner, closure_params, captured, count),
        .comptime_expr => |inner| self.findCaptures(inner, closure_params, captured, count),
        .select_await => |sa| {
            for (sa.arms) |arm| {
                self.findCaptures(arm.task, closure_params, captured, count);
                self.findCaptures(arm.body, closure_params, captured, count);
            }
        },
        .grouped => |inner| {
            self.findCaptures(inner, closure_params, captured, count);
        },
        else => {},
    }
}

// ── Expression codegen ───────────────────────────────────────────

fn genExpr(self: *Codegen, expr: *const Ast.Expr) Error!c.LLVMValueRef {
    return self.genExprInner(expr) catch |err| {
        if (err == error.UnsupportedExpr and self.codegen_error_detail == null) {
            const line = self.spanToLine(expr.span);
            var buf: [256]u8 = undefined;
            const msg = std.fmt.bufPrint(&buf, "unsupported expression while lowering '{s}' at {s}:{d}", .{ @tagName(expr.kind), self.source_file, line }) catch "unsupported expression";
            self.codegen_error_detail = self.allocator.dupe(u8, msg) catch null;
        }
        return err;
    };
}

fn genExprInner(self: *Codegen, expr: *const Ast.Expr) Error!c.LLVMValueRef {
    return switch (expr.kind) {
        .int_literal => |val| blk: {
            const fits_i32 = val >= std.math.minInt(i32) and val <= std.math.maxInt(i32);
            const ty = if (fits_i32)
                c.LLVMInt32TypeInContext(self.context)
            else
                c.LLVMInt64TypeInContext(self.context);
            break :blk c.LLVMConstInt(ty, @bitCast(val), 1);
        },
        .float_literal => |val| c.LLVMConstReal(
            c.LLVMDoubleTypeInContext(self.context),
            val,
        ),
        .bool_literal => |val| c.LLVMConstInt(
            c.LLVMInt1TypeInContext(self.context),
            @intFromBool(val),
            0,
        ),
        .string_literal => |sym| try self.genStringLiteral(sym),
        .c_string_literal => |sym| try self.genCStringLiteral(sym),
        .ident => |sym| blk: {
            // __FILE__ → str constant with source file path
            const file_sym = self.pool.intern("__FILE__") catch return error.CodegenAlloc;
            if (sym == file_sym) {
                break :blk try self.genStringLiteralRaw(self.source_file);
            }
            // __LINE__ → u32 constant with source line number
            const line_sym = self.pool.intern("__LINE__") catch return error.CodegenAlloc;
            if (sym == line_sym) {
                const line_no = self.spanToLine(expr.span);
                break :blk c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), line_no, 0);
            }
            break :blk self.genIdent(sym);
        },
        .binary => |bin| try self.genBinary(bin),
        .unary => |un| try self.genUnary(un),
        .grouped => |inner| try self.genExpr(inner),
        .block => |blk| try self.genBlock(blk),
        .let_binding => |let_b| try self.genLetBinding(let_b),
        .let_else => |le| try self.genLetElse(le),
        .if_expr => |if_e| try self.genIfExpr(if_e),
        .call => |call_e| try self.genCall(call_e),
        .return_expr => |ret_val| try self.genReturn(ret_val),
        .assign => |assign_e| try self.genAssign(assign_e),
        .while_expr => |while_e| try self.genWhile(while_e),
        .loop_expr => |le| try self.genLoop(le),
        .for_expr => |for_e| try self.genFor(for_e),
        .break_expr => |be| try self.genBreak(be),
        .continue_expr => |ce| try self.genContinue(ce),
        .field_access => |fa| try self.genFieldAccess(fa),
        .optional_chain => |oc| try self.genOptionalChain(oc),
        .index => |idx| try self.genIndex(idx),
        .slice => |sl| try self.genSlice(sl),
        .array_literal => |elems| try self.genArrayLiteral(elems),
        .array_comprehension => |comp| try self.genArrayComprehension(comp),
        .struct_literal => |sl| try self.genStructLiteral(sl),
        .match_expr => |m| try self.genMatchExpr(m),
        .enum_variant => |ev| try self.genEnumVariant(ev),
        .variant_shorthand => |vs| {
            if (vs.args.len > 0) {
                // .Variant(args) → treat as call to Variant(args)
                return self.genCall(.{ .callee = &.{ .kind = .{ .ident = vs.name }, .span = expr.span }, .args = vs.args });
            }
            return self.genIdent(vs.name);
        },
        .closure => |cl| try self.genClosure(cl),
        .cast => |ca| try self.genCast(ca),
        .pipeline => |p| try self.genPipeline(p),
        .defer_expr => |d| {
            // Push deferred expression onto stack — don't evaluate yet.
            if (self.defer_depth < 32) {
                self.defer_stack[self.defer_depth] = d;
                self.defer_depth += 1;
            }
            return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
        },
        .tuple => |elems| try self.genTuple(elems),
        .with_expr => |w| try self.genWithExpr(w),
        .record_update => |ru| try self.genRecordUpdate(ru),
        .tuple_destructure => |td| try self.genTupleDestructure(td),
        .yield_expr => |val| try self.genYield(val),
        .await_expr => |inner| try self.genAwait(inner),
        .async_block => |inner| try self.genAsyncBlock(inner),
        .spawn_expr => |inner| try self.genSpawn(inner),
        .async_scope => |as| try self.genAsyncScope(as),
        .comptime_expr => |inner| try self.genComptimeExpr(inner),
        .select_await => |sel| try self.genSelectAwait(sel),
        else => {
            const line = self.spanToLine(expr.span);
            var buf: [256]u8 = undefined;
            const msg = std.fmt.bufPrint(&buf, "unsupported expression kind '{s}' at {s}:{d}", .{ @tagName(expr.kind), self.source_file, line }) catch "unsupported expression";
            self.codegen_error_detail = self.allocator.dupe(u8, msg) catch null;
            return error.UnsupportedExpr;
        },
    };
}

/// Generate a yield expression inside a generator's next() method.
/// Saves locals to state struct, sets state tag, returns Some(value).
fn genYield(self: *Codegen, val_expr: *const Ast.Expr) Error!c.LLVMValueRef {
    const state_ptr = self.gen_state_ptr orelse return error.UnsupportedExpr;
    const state_type = self.gen_state_type orelse return error.UnsupportedExpr;
    _ = self.gen_option_type orelse return error.UnsupportedExpr;

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const yield_idx = self.gen_current_yield;
    self.gen_current_yield += 1;

    // Evaluate the yield value.
    const yield_val = try self.genExpr(val_expr);

    // Save all locals back to the state struct.
    var it = self.locals.iterator();
    while (it.next()) |entry| {
        const sym = entry.key_ptr.*;
        const local = entry.value_ptr.*;
        if (self.gen_field_indices.get(sym)) |field_idx| {
            const val = c.LLVMBuildLoad2(self.builder, local.ty, local.alloca, "");
            const gep = c.LLVMBuildStructGEP2(self.builder, state_type, state_ptr, field_idx, "");
            _ = c.LLVMBuildStore(self.builder, val, gep);
        }
    }

    // Set state tag to yield_idx + 1 (the resume state).
    const state_tag_gep = c.LLVMBuildStructGEP2(self.builder, state_type, state_ptr, 0, "");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i32_type, @intCast(yield_idx + 1), 0), state_tag_gep);

    // Build Some(yield_val) and return it.
    const some_val = try self.buildOptionSome(yield_val);
    _ = c.LLVMBuildRet(self.builder, some_val);

    // Position at the resume block for code that follows this yield.
    if (yield_idx < self.gen_yield_count) {
        const resume_bb = self.gen_resume_bbs[yield_idx];
        c.LLVMPositionBuilderAtEnd(self.builder, resume_bb);

        // Reload all locals from state struct.
        var it2 = self.locals.iterator();
        while (it2.next()) |entry2| {
            const sym2 = entry2.key_ptr.*;
            const local2 = entry2.value_ptr.*;
            if (self.gen_field_indices.get(sym2)) |field_idx| {
                const gep = c.LLVMBuildStructGEP2(self.builder, state_type, state_ptr, field_idx, "");
                const reloaded = c.LLVMBuildLoad2(self.builder, local2.ty, gep, "");
                _ = c.LLVMBuildStore(self.builder, reloaded, local2.alloca);
            }
        }
    }

    // The yield expression itself evaluates to void (in the state machine, control
    // continues after yield with reloaded locals).
    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

// ── Async/Await codegen ─────────────────────────────────────────────

/// Declare the fiber runtime extern functions (lazy, called once).
fn declareAsyncRuntime(self: *Codegen) void {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const void_type = c.LLVMVoidTypeInContext(self.context);
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);

    // void with_runtime_init(void)
    if (c.LLVMGetNamedFunction(self.module, "with_runtime_init") == null) {
        var no_params: [0]c.LLVMTypeRef = undefined;
        const init_ft = c.LLVMFunctionType(void_type, &no_params, 0, 0);
        _ = c.LLVMAddFunction(self.module, "with_runtime_init", init_ft);
    }

    // void with_runtime_run(void)
    if (c.LLVMGetNamedFunction(self.module, "with_runtime_run") == null) {
        var no_params: [0]c.LLVMTypeRef = undefined;
        const run_ft = c.LLVMFunctionType(void_type, &no_params, 0, 0);
        _ = c.LLVMAddFunction(self.module, "with_runtime_run", run_ft);
    }

    // void with_runtime_shutdown(void)
    if (c.LLVMGetNamedFunction(self.module, "with_runtime_shutdown") == null) {
        var no_params: [0]c.LLVMTypeRef = undefined;
        const shutdown_ft = c.LLVMFunctionType(void_type, &no_params, 0, 0);
        _ = c.LLVMAddFunction(self.module, "with_runtime_shutdown", shutdown_ft);
    }

    // i32 with_fiber_spawn(fn_ptr, void_ptr)
    if (c.LLVMGetNamedFunction(self.module, "with_fiber_spawn") == null) {
        var spawn_params = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
        const spawn_ft = c.LLVMFunctionType(i32_type, &spawn_params, 2, 0);
        _ = c.LLVMAddFunction(self.module, "with_fiber_spawn", spawn_ft);
    }

    // i64 with_fiber_await(i32)
    if (c.LLVMGetNamedFunction(self.module, "with_fiber_await") == null) {
        var await_params = [_]c.LLVMTypeRef{i32_type};
        const await_ft = c.LLVMFunctionType(i64_type, &await_params, 1, 0);
        _ = c.LLVMAddFunction(self.module, "with_fiber_await", await_ft);
    }

    // i32 with_fiber_cancel(i32)
    if (c.LLVMGetNamedFunction(self.module, "with_fiber_cancel") == null) {
        var cancel_params = [_]c.LLVMTypeRef{i32_type};
        const cancel_ft = c.LLVMFunctionType(i32_type, &cancel_params, 1, 0);
        _ = c.LLVMAddFunction(self.module, "with_fiber_cancel", cancel_ft);
    }

    // void with_fiber_set_result(i64)
    if (c.LLVMGetNamedFunction(self.module, "with_fiber_set_result") == null) {
        var set_params = [_]c.LLVMTypeRef{i64_type};
        const set_ft = c.LLVMFunctionType(void_type, &set_params, 1, 0);
        _ = c.LLVMAddFunction(self.module, "with_fiber_set_result", set_ft);
    }

    // void with_fiber_yield(void)
    if (c.LLVMGetNamedFunction(self.module, "with_fiber_yield") == null) {
        var no_params: [0]c.LLVMTypeRef = undefined;
        const yield_ft = c.LLVMFunctionType(void_type, &no_params, 0, 0);
        _ = c.LLVMAddFunction(self.module, "with_fiber_yield", yield_ft);
    }

    self.uses_async = true;
}

/// Declare an async function. Creates:
/// 1. The actual implementation: `fn_name_async(params) -> ret_type`
/// 2. An args struct type for the parameters
/// 3. A fiber entry trampoline: `fn_name_fiber(arg: *void) -> void`
/// 4. The public function: `fn_name(params) -> i32` (returns Task ID)
fn declareAsyncFunction(self: *Codegen, func: Ast.FnDecl) Error!void {
    self.declareAsyncRuntime();

    // Interning during async declaration can reallocate the string pool and
    // invalidate slices from pool.resolve(). Keep a stable local copy.
    var name_buf: [256]u8 = undefined;
    const name_src = self.pool.resolve(func.name);
    if (name_src.len >= name_buf.len) return error.UnsupportedExpr;
    @memcpy(name_buf[0..name_src.len], name_src);
    const name = name_buf[0..name_src.len];

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const void_type = c.LLVMVoidTypeInContext(self.context);
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);

    // 1. Declare the implementation function: fn_name_async(params) -> ret_type
    var param_types_buf: [32]c.LLVMTypeRef = undefined;
    for (func.params, 0..) |param, i| {
        param_types_buf[i] = if (param.type_expr) |te| self.resolveType(te) catch i32_type else i32_type;
    }
    const ret_type = if (func.return_type) |rt|
        self.resolveType(rt) catch i32_type
    else if (self.inferred_return_types.get(func.name)) |inferred_te|
        self.resolveType(inferred_te) catch i32_type
    else
        void_type;
    self.async_fn_ret_types.put(self.allocator, func.name, ret_type) catch return error.CodegenAlloc;
    const param_count: u32 = @intCast(func.params.len);
    const impl_fn_type = c.LLVMFunctionType(ret_type, &param_types_buf, param_count, 0);

    var impl_name_buf: [256]u8 = undefined;
    const impl_name = std.fmt.bufPrint(&impl_name_buf, "{s}_async", .{name}) catch return error.CodegenAlloc;
    impl_name_buf[impl_name.len] = 0;
    const impl_fn = c.LLVMAddFunction(self.module, impl_name_buf[0..impl_name.len :0], impl_fn_type);

    // Store the impl function so genAsyncFunction can find it.
    // Use a mangled symbol.
    const impl_sym = self.pool.intern(impl_name) catch return error.CodegenAlloc;
    self.functions.put(self.allocator, impl_sym, .{
        .value = impl_fn,
        .fn_type = impl_fn_type,
    }) catch return error.CodegenAlloc;

    // 2. Create args struct if params exist.
    var args_struct_type: c.LLVMTypeRef = undefined;
    if (param_count > 0) {
        args_struct_type = c.LLVMStructTypeInContext(self.context, &param_types_buf, param_count, 0);
    } else {
        args_struct_type = c.LLVMStructTypeInContext(self.context, null, 0, 0);
    }

    // 3. Declare fiber trampoline: fn_name_fiber(arg: *void) -> void
    var tramp_params = [_]c.LLVMTypeRef{ptr_type};
    const tramp_fn_type = c.LLVMFunctionType(void_type, &tramp_params, 1, 0);
    var tramp_name_buf: [256]u8 = undefined;
    const tramp_name = std.fmt.bufPrint(&tramp_name_buf, "{s}_fiber", .{name}) catch return error.CodegenAlloc;
    tramp_name_buf[tramp_name.len] = 0;
    _ = c.LLVMAddFunction(self.module, tramp_name_buf[0..tramp_name.len :0], tramp_fn_type);

    // 4. Declare the public spawn function: fn_name(params) -> i32 (Task ID)
    const spawn_fn_type = c.LLVMFunctionType(i32_type, &param_types_buf, param_count, 0);
    var spawn_name_buf: [256]u8 = undefined;
    const spawn_name = std.fmt.bufPrint(&spawn_name_buf, "{s}", .{name}) catch return error.CodegenAlloc;
    spawn_name_buf[spawn_name.len] = 0;
    const spawn_fn = c.LLVMAddFunction(self.module, spawn_name_buf[0..spawn_name.len :0], spawn_fn_type);

    // Store the public function under the original name.
    self.functions.put(self.allocator, func.name, .{
        .value = spawn_fn,
        .fn_type = spawn_fn_type,
    }) catch return error.CodegenAlloc;

    // tramp_fn and args_struct_type will be reconstructed in genAsyncFunction.
}

/// Generate the body of an async function (impl, trampoline, spawn wrapper).
fn genAsyncFunction(self: *Codegen, func: Ast.FnDecl) Error!void {
    // Copy function name to stack buffer since pool.intern() during body
    // generation can invalidate slices returned by pool.resolve().
    var name_buf: [256]u8 = undefined;
    const name_src = self.pool.resolve(func.name);
    const name_len = @min(name_src.len, name_buf.len);
    @memcpy(name_buf[0..name_len], name_src[0..name_len]);
    const name: []const u8 = name_buf[0..name_len];
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const void_type = c.LLVMVoidTypeInContext(self.context);
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);

    // Find the implementation function.
    var impl_name_buf: [256]u8 = undefined;
    const impl_name = std.fmt.bufPrint(&impl_name_buf, "{s}_async", .{name}) catch return error.CodegenAlloc;
    const impl_sym = self.pool.intern(impl_name) catch return error.CodegenAlloc;
    const impl_info = self.functions.get(impl_sym) orelse return error.UnsupportedExpr;
    const impl_fn = impl_info.value;

    // Get param types.
    const param_count: u32 = @intCast(func.params.len);
    var param_types_buf: [32]c.LLVMTypeRef = undefined;
    for (func.params, 0..) |param, i| {
        param_types_buf[i] = if (param.type_expr) |te| self.resolveType(te) catch i32_type else i32_type;
    }
    const ret_type = if (func.return_type) |rt|
        self.resolveType(rt) catch i32_type
    else if (self.inferred_return_types.get(func.name)) |inferred_te|
        self.resolveType(inferred_te) catch i32_type
    else
        void_type;

    // Args struct type.
    var args_struct_type: c.LLVMTypeRef = undefined;
    if (param_count > 0) {
        args_struct_type = c.LLVMStructTypeInContext(self.context, &param_types_buf, param_count, 0);
    } else {
        args_struct_type = c.LLVMStructTypeInContext(self.context, null, 0, 0);
    }

    // ── 1. Generate the implementation function body ─────────────────
    {
        self.current_function = impl_fn;
        self.current_ret_type = ret_type;
        self.locals.clearRetainingCapacity();
        self.task_locals.clearRetainingCapacity();
        self.task_local_result_types.clearRetainingCapacity();
        self.task_container_local_elem_types.clearRetainingCapacity();
        self.vec_local_types.clearRetainingCapacity();
        self.defer_depth = 0;
        self.scope_local_count = 0;
        self.trait_locals.clearRetainingCapacity();

        const saved_expected = self.expected_type;
        self.expected_type = ret_type;

        const entry = c.LLVMAppendBasicBlockInContext(self.context, impl_fn, "entry");
        c.LLVMPositionBuilderAtEnd(self.builder, entry);

        // Add params as locals.
        for (func.params, 0..) |param, i| {
            const param_val = c.LLVMGetParam(impl_fn, @intCast(i));
            const param_type = c.LLVMTypeOf(param_val);
            const alloca = c.LLVMBuildAlloca(self.builder, param_type, "");
            _ = c.LLVMBuildStore(self.builder, param_val, alloca);
            self.locals.put(self.allocator, param.name, .{
                .alloca = alloca,
                .ty = param_type,
                .is_mut = param.is_mut,
            }) catch return error.CodegenAlloc;

            if (param.type_expr) |te| {
                if (te.kind == .generic and std.mem.eql(u8, self.pool.resolve(te.kind.generic.name), "Vec")) {
                    if (self.resolveType(te)) |vec_ty| {
                        self.vec_local_types.put(self.allocator, param.name, vec_ty) catch {};
                    } else |_| {}
                } else if (te.kind == .ref_type and te.kind.ref_type.pointee.kind == .generic and
                    std.mem.eql(u8, self.pool.resolve(te.kind.ref_type.pointee.kind.generic.name), "Vec"))
                {
                    if (self.resolveType(te.kind.ref_type.pointee)) |vec_ty| {
                        self.vec_local_types.put(self.allocator, param.name, vec_ty) catch {};
                    } else |_| {}
                }

                if (self.typeExprTaskResultType(te)) |task_result_ty| {
                    self.task_locals.put(self.allocator, param.name, {}) catch return error.CodegenAlloc;
                    self.task_local_result_types.put(self.allocator, param.name, task_result_ty) catch return error.CodegenAlloc;
                }
                if (self.typeExprTaskContainerElementTypeFromTypeExpr(te)) |task_elem_ty| {
                    self.task_container_local_elem_types.put(self.allocator, param.name, task_elem_ty) catch return error.CodegenAlloc;
                }
            }
        }

        const body_val = try self.genExpr(func.body);

        self.expected_type = saved_expected;

        const current_bb = c.LLVMGetInsertBlock(self.builder);
        if (c.LLVMGetBasicBlockTerminator(current_bb) == null) {
            const is_void = ret_type == void_type;
            try self.emitDrops(0);
            try self.emitDefers();
            if (!is_void) {
                const body_type = c.LLVMTypeOf(body_val);
                if (body_type == void_type) {
                    if (self.isResultType(ret_type)) {
                        const unit_val = c.LLVMConstInt(i32_type, 0, 0);
                        const ok_val = try self.buildResultOk(unit_val, ret_type);
                        _ = c.LLVMBuildRet(self.builder, ok_val);
                    } else if (c.LLVMGetTypeKind(ret_type) == c.LLVMIntegerTypeKind) {
                        _ = c.LLVMBuildRet(self.builder, c.LLVMConstInt(ret_type, 0, 0));
                    } else {
                        _ = c.LLVMBuildRet(self.builder, c.LLVMGetUndef(ret_type));
                    }
                } else {
                    const coerced = try self.coerceValueForType(body_val, ret_type);
                    _ = c.LLVMBuildRet(self.builder, coerced);
                }
            } else {
                _ = c.LLVMBuildRetVoid(self.builder);
            }
        }
    }

    // ── 2. Generate the fiber trampoline ─────────────────────────────
    {
        var tramp_name_buf: [256]u8 = undefined;
        const tramp_name = std.fmt.bufPrint(&tramp_name_buf, "{s}_fiber", .{name}) catch return error.CodegenAlloc;
        tramp_name_buf[tramp_name.len] = 0;
        const tramp_fn = c.LLVMGetNamedFunction(self.module, tramp_name_buf[0..tramp_name.len :0]) orelse return error.UnsupportedExpr;

        self.current_function = tramp_fn;
        const entry = c.LLVMAppendBasicBlockInContext(self.context, tramp_fn, "entry");
        c.LLVMPositionBuilderAtEnd(self.builder, entry);

        // Load args from the void* parameter.
        const arg_ptr = c.LLVMGetParam(tramp_fn, 0);

        // Call the implementation function.
        var call_args: [32]c.LLVMValueRef = undefined;
        for (0..param_count) |i| {
            const idx: u32 = @intCast(i);
            var indices = [_]c.LLVMValueRef{
                c.LLVMConstInt(i32_type, 0, 0),
                c.LLVMConstInt(i32_type, idx, 0),
            };
            const gep = c.LLVMBuildGEP2(self.builder, args_struct_type, arg_ptr, &indices, 2, "");
            call_args[i] = c.LLVMBuildLoad2(self.builder, param_types_buf[i], gep, "");
        }

        const result = c.LLVMBuildCall2(self.builder, impl_info.fn_type, impl_fn, &call_args, param_count, "");

        // Store result via with_fiber_set_result.
        if (ret_type != void_type) {
            const set_result_fn = c.LLVMGetNamedFunction(self.module, "with_fiber_set_result") orelse return error.UnsupportedExpr;
            var set_params = [_]c.LLVMTypeRef{i64_type};
            const set_ft = c.LLVMFunctionType(void_type, &set_params, 1, 0);
            const result_i64 = try self.packTaskResultToI64(result, ret_type);
            var set_args = [_]c.LLVMValueRef{result_i64};
            _ = c.LLVMBuildCall2(self.builder, set_ft, set_result_fn, &set_args, 1, "");
        }
        _ = c.LLVMBuildRetVoid(self.builder);
    }

    // ── 3. Generate the spawn wrapper ────────────────────────────────
    {
        const spawn_info = self.functions.get(func.name) orelse return error.UnsupportedExpr;
        const spawn_fn = spawn_info.value;

        self.current_function = spawn_fn;
        const entry = c.LLVMAppendBasicBlockInContext(self.context, spawn_fn, "entry");
        c.LLVMPositionBuilderAtEnd(self.builder, entry);

        // Allocate args struct on heap (malloc).
        const args_size = c.LLVMSizeOf(args_struct_type);
        const malloc_fn = self.getOrDeclareMalloc();
        var malloc_args = [_]c.LLVMValueRef{args_size};
        const i64_type_local = c.LLVMInt64TypeInContext(self.context);
        var malloc_param_types = [_]c.LLVMTypeRef{i64_type_local};
        const malloc_ft = c.LLVMFunctionType(ptr_type, &malloc_param_types, 1, 0);
        const args_ptr = c.LLVMBuildCall2(self.builder, malloc_ft, malloc_fn, &malloc_args, 1, "args");

        // Store each parameter into the args struct.
        for (0..param_count) |i| {
            const idx: u32 = @intCast(i);
            const param_val = c.LLVMGetParam(spawn_fn, idx);
            var indices = [_]c.LLVMValueRef{
                c.LLVMConstInt(i32_type, 0, 0),
                c.LLVMConstInt(i32_type, idx, 0),
            };
            const gep = c.LLVMBuildGEP2(self.builder, args_struct_type, args_ptr, &indices, 2, "");
            _ = c.LLVMBuildStore(self.builder, param_val, gep);
        }

        // Call with_fiber_spawn(trampoline_fn, args_ptr).
        var tramp_name_buf2: [256]u8 = undefined;
        const tramp_name2 = std.fmt.bufPrint(&tramp_name_buf2, "{s}_fiber", .{name}) catch return error.CodegenAlloc;
        tramp_name_buf2[tramp_name2.len] = 0;
        const tramp_fn = c.LLVMGetNamedFunction(self.module, tramp_name_buf2[0..tramp_name2.len :0]) orelse return error.UnsupportedExpr;

        const spawn_rt_fn = c.LLVMGetNamedFunction(self.module, "with_fiber_spawn") orelse return error.UnsupportedExpr;
        var spawn_params = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
        const spawn_ft = c.LLVMFunctionType(i32_type, &spawn_params, 2, 0);
        var spawn_args = [_]c.LLVMValueRef{ tramp_fn, args_ptr };
        const task_id = c.LLVMBuildCall2(self.builder, spawn_ft, spawn_rt_fn, &spawn_args, 2, "task");

        _ = c.LLVMBuildRet(self.builder, task_id);
    }
}

fn findActiveAsyncScopeFrame(self: *Codegen, sym: u32) ?*AsyncScopeFrame {
    var i: usize = self.async_scope_depth;
    while (i > 0) {
        i -= 1;
        if (self.async_scope_frames[i].symbol == sym) {
            return &self.async_scope_frames[i];
        }
    }
    return null;
}

fn typeExprTaskResultType(self: *Codegen, te: *const Ast.TypeExpr) ?c.LLVMTypeRef {
    return switch (te.kind) {
        .ref_type => |rt| self.typeExprTaskResultType(rt.pointee),
        .ptr_type => |pt| self.typeExprTaskResultType(pt.pointee),
        .generic => |g| blk: {
            const n = self.pool.resolve(g.name);
            if (!(std.mem.eql(u8, n, "Task") and g.args.len == 1)) break :blk null;
            break :blk self.resolveType(g.args[0]) catch null;
        },
        else => null,
    };
}

fn typeExprTaskContainerElementTypeFromTypeExpr(self: *Codegen, te: *const Ast.TypeExpr) ?c.LLVMTypeRef {
    return switch (te.kind) {
        .ref_type => |rt| self.typeExprTaskContainerElementTypeFromTypeExpr(rt.pointee),
        .ptr_type => |pt| self.typeExprTaskContainerElementTypeFromTypeExpr(pt.pointee),
        .array_type => |at| self.typeExprTaskResultType(at.element),
        .slice_type => |inner| self.typeExprTaskResultType(inner),
        .generic => |g| blk: {
            const n = self.pool.resolve(g.name);
            if (!(std.mem.eql(u8, n, "Vec") and g.args.len == 1)) break :blk null;
            break :blk self.typeExprTaskResultType(g.args[0]);
        },
        else => null,
    };
}

fn typeExprTaskResultTypeWithParams(
    self: *Codegen,
    te: *const Ast.TypeExpr,
    type_params: []const Ast.TypeParam,
    type_map: *[16]TypeBinding,
    type_map_len: u32,
) ?c.LLVMTypeRef {
    return switch (te.kind) {
        .ref_type => |rt| self.typeExprTaskResultTypeWithParams(rt.pointee, type_params, type_map, type_map_len),
        .ptr_type => |pt| self.typeExprTaskResultTypeWithParams(pt.pointee, type_params, type_map, type_map_len),
        .generic => |g| blk: {
            const n = self.pool.resolve(g.name);
            if (!(std.mem.eql(u8, n, "Task") and g.args.len == 1)) break :blk null;
            break :blk self.resolveTypeWithParams(g.args[0], type_params, type_map, type_map_len) catch null;
        },
        else => null,
    };
}

fn typeExprTaskContainerElementTypeWithParams(
    self: *Codegen,
    te: *const Ast.TypeExpr,
    type_params: []const Ast.TypeParam,
    type_map: *[16]TypeBinding,
    type_map_len: u32,
) ?c.LLVMTypeRef {
    return switch (te.kind) {
        .ref_type => |rt| self.typeExprTaskContainerElementTypeWithParams(rt.pointee, type_params, type_map, type_map_len),
        .ptr_type => |pt| self.typeExprTaskContainerElementTypeWithParams(pt.pointee, type_params, type_map, type_map_len),
        .array_type => |at| self.typeExprTaskResultTypeWithParams(at.element, type_params, type_map, type_map_len),
        .slice_type => |inner| self.typeExprTaskResultTypeWithParams(inner, type_params, type_map, type_map_len),
        .generic => |g| blk: {
            const n = self.pool.resolve(g.name);
            if (!(std.mem.eql(u8, n, "Vec") and g.args.len == 1)) break :blk null;
            break :blk self.typeExprTaskResultTypeWithParams(g.args[0], type_params, type_map, type_map_len);
        },
        else => null,
    };
}

fn exprProducesTask(self: *Codegen, expr: *const Ast.Expr) bool {
    if (self.inferTaskResultType(expr) != null) return true;
    return switch (expr.kind) {
        .ident => |sym| self.task_locals.get(sym) != null,
        .call => |call_e| blk: {
            if (call_e.callee.kind == .field_access) {
                const fa = call_e.callee.kind.field_access;
                if (fa.expr.kind == .ident and self.findActiveAsyncScopeFrame(fa.expr.kind.ident) != null) {
                    if (std.mem.eql(u8, self.pool.resolve(fa.field), "track")) break :blk true;
                }
            }
            if (call_e.callee.kind == .ident) {
                break :blk self.async_fn_symbols.get(call_e.callee.kind.ident) != null;
            }
            break :blk false;
        },
        .async_block => true,
        .tuple => |elems| blk: {
            if (elems.len < 2 or elems.len > 12) break :blk false;
            for (elems) |elem| {
                if (!self.exprProducesTask(elem)) break :blk false;
            }
            break :blk true;
        },
        .index => |idx| self.inferTaskContainerElementType(idx.expr) != null,
        .grouped => |inner| self.exprProducesTask(inner),
        else => false,
    };
}

fn inferTaskContainerElementType(self: *Codegen, expr: *const Ast.Expr) ?c.LLVMTypeRef {
    return switch (expr.kind) {
        .ident => |sym| self.task_container_local_elem_types.get(sym),
        .grouped => |inner| self.inferTaskContainerElementType(inner),
        .slice => |sl| self.inferTaskContainerElementType(sl.expr),
        .array_literal => |elems| blk: {
            var elem_ty: ?c.LLVMTypeRef = null;
            for (elems) |elem| {
                const cur = self.inferTaskResultType(elem) orelse break :blk null;
                if (elem_ty == null) {
                    elem_ty = cur;
                } else if (elem_ty.? != cur) {
                    break :blk null;
                }
            }
            break :blk elem_ty;
        },
        .call => |call_e| blk: {
            if (call_e.callee.kind != .field_access) break :blk null;
            const fa = call_e.callee.kind.field_access;
            const method_name = self.pool.resolve(fa.field);
            if (std.mem.eql(u8, method_name, "iter") and call_e.args.len == 0) {
                break :blk self.inferTaskContainerElementType(fa.expr);
            }
            if (fa.expr.kind != .ident) break :blk null;
            const type_name = self.pool.resolve(fa.expr.kind.ident);
            if (!(std.mem.eql(u8, type_name, "Vec") and std.mem.eql(u8, method_name, "of"))) {
                break :blk null;
            }
            var elem_ty: ?c.LLVMTypeRef = null;
            for (call_e.args) |arg| {
                const cur = self.inferTaskResultType(arg) orelse break :blk null;
                if (elem_ty == null) {
                    elem_ty = cur;
                } else if (elem_ty.? != cur) {
                    break :blk null;
                }
            }
            break :blk elem_ty;
        },
        else => null,
    };
}

fn inferTaskResultType(self: *Codegen, expr: *const Ast.Expr) ?c.LLVMTypeRef {
    return switch (expr.kind) {
        .ident => |sym| self.task_local_result_types.get(sym),
        .grouped => |inner| self.inferTaskResultType(inner),
        .call => |call_e| blk: {
            if (call_e.callee.kind == .ident) {
                if (self.async_fn_ret_types.get(call_e.callee.kind.ident)) |ret_ty| {
                    break :blk ret_ty;
                }
            } else if (call_e.callee.kind == .field_access) {
                const fa = call_e.callee.kind.field_access;
                if (fa.expr.kind == .ident and self.findActiveAsyncScopeFrame(fa.expr.kind.ident) != null and
                    std.mem.eql(u8, self.pool.resolve(fa.field), "track") and call_e.args.len >= 1)
                {
                    break :blk self.inferTaskResultType(call_e.args[0]);
                }
                if (std.mem.eql(u8, self.pool.resolve(fa.field), "get") and call_e.args.len >= 1) {
                    break :blk self.inferTaskContainerElementType(fa.expr);
                }
            }
            break :blk null;
        },
        .index => |idx| self.inferTaskContainerElementType(idx.expr),
        // Async blocks currently lower through an i32-returning impl.
        .async_block => c.LLVMInt32TypeInContext(self.context),
        else => null,
    };
}

fn packTaskResultToI64(self: *Codegen, value: c.LLVMValueRef, value_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const kind = c.LLVMGetTypeKind(value_type);

    if (kind == c.LLVMIntegerTypeKind) {
        const width = c.LLVMGetIntTypeWidth(value_type);
        if (width == 64) return value;
        if (width < 64) return c.LLVMBuildSExt(self.builder, value, i64_type, "task.res.sext");
        return c.LLVMBuildTrunc(self.builder, value, i64_type, "task.res.trunc");
    }
    if (kind == c.LLVMPointerTypeKind) {
        return c.LLVMBuildPtrToInt(self.builder, value, i64_type, "task.res.ptr.i64");
    }
    if (kind == c.LLVMDoubleTypeKind) {
        return c.LLVMBuildBitCast(self.builder, value, i64_type, "task.res.f64.bits");
    }
    if (kind == c.LLVMFloatTypeKind) {
        const i32_type = c.LLVMInt32TypeInContext(self.context);
        const bits = c.LLVMBuildBitCast(self.builder, value, i32_type, "task.res.f32.bits");
        return c.LLVMBuildSExt(self.builder, bits, i64_type, "task.res.f32.i64");
    }

    // Box aggregate/non-scalar returns and pass pointer bits through i64 channel.
    const malloc_fn = self.getOrDeclareMalloc();
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const size = c.LLVMSizeOf(value_type);
    var malloc_args = [_]c.LLVMValueRef{size};
    var malloc_param_types = [_]c.LLVMTypeRef{i64_type};
    const malloc_ft = c.LLVMFunctionType(ptr_type, &malloc_param_types, 1, 0);
    const raw_ptr = c.LLVMBuildCall2(self.builder, malloc_ft, malloc_fn, &malloc_args, 1, "task.res.box");
    _ = c.LLVMBuildStore(self.builder, value, raw_ptr);
    return c.LLVMBuildPtrToInt(self.builder, raw_ptr, i64_type, "task.res.box.i64");
}

fn unpackTaskResultFromI64(self: *Codegen, raw_i64: c.LLVMValueRef, result_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const void_type = c.LLVMVoidTypeInContext(self.context);
    const kind = c.LLVMGetTypeKind(result_type);

    if (result_type == void_type) {
        return c.LLVMGetUndef(void_type);
    }
    if (kind == c.LLVMIntegerTypeKind) {
        const width = c.LLVMGetIntTypeWidth(result_type);
        if (width == 64) return raw_i64;
        if (width < 64) return c.LLVMBuildTrunc(self.builder, raw_i64, result_type, "await.trunc");
        return c.LLVMBuildSExt(self.builder, raw_i64, result_type, "await.sext");
    }
    if (kind == c.LLVMPointerTypeKind) {
        return c.LLVMBuildIntToPtr(self.builder, raw_i64, result_type, "await.ptr");
    }
    if (kind == c.LLVMDoubleTypeKind) {
        return c.LLVMBuildBitCast(self.builder, raw_i64, result_type, "await.f64");
    }
    if (kind == c.LLVMFloatTypeKind) {
        const bits = c.LLVMBuildTrunc(self.builder, raw_i64, i32_type, "await.f32.bits");
        return c.LLVMBuildBitCast(self.builder, bits, result_type, "await.f32");
    }

    // Boxed aggregate path.
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const raw_ptr = c.LLVMBuildIntToPtr(self.builder, raw_i64, ptr_type, "await.box.ptr");
    const value = c.LLVMBuildLoad2(self.builder, result_type, raw_ptr, "await.box.load");
    const free_fn = self.ensureFreeDeclared();
    var free_args = [_]c.LLVMValueRef{raw_ptr};
    _ = c.LLVMBuildCall2(self.builder, free_fn.fn_type, free_fn.value, &free_args, 1, "");
    return value;
}

/// Generate `async: body` by lowering to a spawned fiber with capture payload.
fn genAsyncBlock(self: *Codegen, body: *const Ast.Expr) Error!c.LLVMValueRef {
    self.declareAsyncRuntime();

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const void_type = c.LLVMVoidTypeInContext(self.context);
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);

    // Capture locals referenced by the async block body.
    var captured: [16]CapturedVar = undefined;
    var capture_count: u32 = 0;
    self.findCaptures(body, &.{}, &captured, &capture_count);

    // Async blocks capture by value. For mutable locals, findCaptures stores
    // the source alloca pointer; load the current value now so the task gets
    // a stable snapshot rather than a borrowed stack pointer.
    var capture_i: usize = 0;
    while (capture_i < capture_count) : (capture_i += 1) {
        if (captured[capture_i].is_mut) {
            captured[capture_i].value = c.LLVMBuildLoad2(
                self.builder,
                captured[capture_i].ty,
                captured[capture_i].value,
                "async.cap.load",
            );
        }
    }

    var cap_field_types: [16]c.LLVMTypeRef = undefined;
    for (captured[0..capture_count], 0..) |cap, i| {
        cap_field_types[i] = cap.ty;
    }
    const cap_struct_type = if (capture_count > 0)
        c.LLVMStructTypeInContext(self.context, &cap_field_types, capture_count, 0)
    else
        c.LLVMStructTypeInContext(self.context, null, 0, 0);
    const cap_ptr_type = c.LLVMPointerType(cap_struct_type, 0);

    const block_id = self.closure_counter;
    self.closure_counter += 1;

    // 1) Build implementation fn: __async_block_impl_N(*capture) -> i32
    var impl_name_buf: [64]u8 = undefined;
    const impl_name = std.fmt.bufPrint(&impl_name_buf, "__async_block_impl_{d}\x00", .{block_id}) catch return error.CodegenAlloc;
    const impl_name_z: [*:0]const u8 = @ptrCast(impl_name.ptr);

    var impl_param_types = [_]c.LLVMTypeRef{cap_ptr_type};
    const impl_ft = c.LLVMFunctionType(i32_type, &impl_param_types, 1, 0);
    const impl_fn = c.LLVMAddFunction(self.module, impl_name_z, impl_ft);

    const saved_function = self.current_function;
    const saved_ret_type = self.current_ret_type;
    const saved_bb = c.LLVMGetInsertBlock(self.builder);
    const saved_locals = self.locals;
    const saved_task_locals = self.task_locals;
    const saved_task_result_locals = self.task_local_result_types;
    const saved_task_container_locals = self.task_container_local_elem_types;
    const saved_scope_local_count = self.scope_local_count;
    const saved_defer_depth = self.defer_depth;
    const saved_expected = self.expected_type;
    const saved_trait_locals = self.trait_locals;

    self.current_function = impl_fn;
    self.current_ret_type = i32_type;
    self.locals = .empty;
    self.task_locals = .{};
    self.task_local_result_types = .{};
    self.task_container_local_elem_types = .{};
    self.scope_local_count = 0;
    self.defer_depth = 0;
    self.expected_type = i32_type;
    self.trait_locals = .{};

    const impl_entry = c.LLVMAppendBasicBlockInContext(self.context, impl_fn, "entry");
    c.LLVMPositionBuilderAtEnd(self.builder, impl_entry);

    const cap_ptr_arg = c.LLVMGetParam(impl_fn, 0);
    for (captured[0..capture_count], 0..) |cap, i| {
        const field_gep = c.LLVMBuildStructGEP2(self.builder, cap_struct_type, cap_ptr_arg, @intCast(i), "");
        const loaded = c.LLVMBuildLoad2(self.builder, cap.ty, field_gep, "");
        const alloca = c.LLVMBuildAlloca(self.builder, cap.ty, "");
        _ = c.LLVMBuildStore(self.builder, loaded, alloca);
        self.locals.put(self.allocator, cap.sym, .{
            .alloca = alloca,
            .ty = cap.ty,
            .is_mut = cap.is_mut,
        }) catch return error.CodegenAlloc;
    }

    const body_val = try self.genExpr(body);
    const impl_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(impl_bb) == null) {
        const coerced = self.coerceInt(body_val, i32_type);
        _ = c.LLVMBuildRet(self.builder, coerced);
    }

    self.locals.deinit(self.allocator);
    self.task_locals.deinit(self.allocator);
    self.task_local_result_types.deinit(self.allocator);
    self.task_container_local_elem_types.deinit(self.allocator);
    self.task_container_local_elem_types.deinit(self.allocator);
    self.trait_locals.deinit(self.allocator);
    self.current_function = saved_function;
    self.current_ret_type = saved_ret_type;
    self.locals = saved_locals;
    self.task_locals = saved_task_locals;
    self.task_local_result_types = saved_task_result_locals;
    self.task_container_local_elem_types = saved_task_container_locals;
    self.task_container_local_elem_types = saved_task_container_locals;
    self.scope_local_count = saved_scope_local_count;
    self.defer_depth = saved_defer_depth;
    self.expected_type = saved_expected;
    self.trait_locals = saved_trait_locals;
    c.LLVMPositionBuilderAtEnd(self.builder, saved_bb);

    // 2) Build fiber trampoline: __async_block_fiber_N(void*) -> void
    var tramp_name_buf: [64]u8 = undefined;
    const tramp_name = std.fmt.bufPrint(&tramp_name_buf, "__async_block_fiber_{d}\x00", .{block_id}) catch return error.CodegenAlloc;
    const tramp_name_z: [*:0]const u8 = @ptrCast(tramp_name.ptr);

    var tramp_param_types = [_]c.LLVMTypeRef{ptr_type};
    const tramp_ft = c.LLVMFunctionType(void_type, &tramp_param_types, 1, 0);
    const tramp_fn = c.LLVMAddFunction(self.module, tramp_name_z, tramp_ft);

    const saved_fn_for_tramp = self.current_function;
    const saved_ret_for_tramp = self.current_ret_type;
    const saved_bb_for_tramp = c.LLVMGetInsertBlock(self.builder);

    self.current_function = tramp_fn;
    self.current_ret_type = void_type;
    const tramp_entry = c.LLVMAppendBasicBlockInContext(self.context, tramp_fn, "entry");
    c.LLVMPositionBuilderAtEnd(self.builder, tramp_entry);

    const raw_arg_ptr = c.LLVMGetParam(tramp_fn, 0);
    const typed_cap_ptr = c.LLVMBuildBitCast(self.builder, raw_arg_ptr, cap_ptr_type, "cap.ptr");
    var impl_call_args = [_]c.LLVMValueRef{typed_cap_ptr};
    const impl_result = c.LLVMBuildCall2(self.builder, impl_ft, impl_fn, &impl_call_args, 1, "async.block.res");
    const result_i64 = c.LLVMBuildSExt(self.builder, impl_result, i64_type, "async.block.res.i64");

    const set_result_fn = c.LLVMGetNamedFunction(self.module, "with_fiber_set_result") orelse return error.UnsupportedExpr;
    var set_params = [_]c.LLVMTypeRef{i64_type};
    const set_ft = c.LLVMFunctionType(void_type, &set_params, 1, 0);
    var set_args = [_]c.LLVMValueRef{result_i64};
    _ = c.LLVMBuildCall2(self.builder, set_ft, set_result_fn, &set_args, 1, "");
    _ = c.LLVMBuildRetVoid(self.builder);

    self.current_function = saved_fn_for_tramp;
    self.current_ret_type = saved_ret_for_tramp;
    c.LLVMPositionBuilderAtEnd(self.builder, saved_bb_for_tramp);

    // 3) Allocate capture payload and spawn.
    var cap_payload_ptr: c.LLVMValueRef = c.LLVMConstNull(ptr_type);
    if (capture_count > 0) {
        const cap_size = c.LLVMSizeOf(cap_struct_type);
        const malloc_fn = self.getOrDeclareMalloc();
        var malloc_args = [_]c.LLVMValueRef{cap_size};
        var malloc_param_types = [_]c.LLVMTypeRef{i64_type};
        const malloc_ft = c.LLVMFunctionType(ptr_type, &malloc_param_types, 1, 0);
        const cap_raw = c.LLVMBuildCall2(self.builder, malloc_ft, malloc_fn, &malloc_args, 1, "async.block.cap");
        const cap_heap_ptr = c.LLVMBuildBitCast(self.builder, cap_raw, cap_ptr_type, "async.block.cap.ptr");
        for (captured[0..capture_count], 0..) |cap, i| {
            const field_gep = c.LLVMBuildStructGEP2(self.builder, cap_struct_type, cap_heap_ptr, @intCast(i), "");
            _ = c.LLVMBuildStore(self.builder, cap.value, field_gep);
        }
        cap_payload_ptr = cap_raw;
    }

    const spawn_rt_fn = c.LLVMGetNamedFunction(self.module, "with_fiber_spawn") orelse return error.UnsupportedExpr;
    var spawn_params = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
    const spawn_ft = c.LLVMFunctionType(i32_type, &spawn_params, 2, 0);
    var spawn_args = [_]c.LLVMValueRef{ tramp_fn, cap_payload_ptr };
    return c.LLVMBuildCall2(self.builder, spawn_ft, spawn_rt_fn, &spawn_args, 2, "task");
}

/// Generate an await expression: calls with_fiber_await(task_id).
fn genAwait(self: *Codegen, inner: *const Ast.Expr) Error!c.LLVMValueRef {
    if (inner.kind == .tuple) {
        return self.genAwaitTuple(inner.kind.tuple);
    }

    if (!self.exprProducesTask(inner)) {
        // Non-task await is treated as identity for async-block expression ergonomics.
        return self.genExpr(inner);
    }

    self.declareAsyncRuntime();

    // Evaluate the inner expression (should be a Task ID, i.e., i32).
    const task_id = try self.genExpr(inner);

    // Call with_fiber_await(task_id) -> i64.
    const await_fn = c.LLVMGetNamedFunction(self.module, "with_fiber_await") orelse return error.UnsupportedExpr;
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    var await_params = [_]c.LLVMTypeRef{i32_type};
    const await_ft = c.LLVMFunctionType(i64_type, &await_params, 1, 0);

    var args = [_]c.LLVMValueRef{task_id};
    const result_i64 = c.LLVMBuildCall2(self.builder, await_ft, await_fn, &args, 1, "await.result");

    if (self.inferTaskResultType(inner)) |task_result_type| {
        return self.unpackTaskResultFromI64(result_i64, task_result_type);
    }

    // Truncate i64 result to i32 (common case). If expected_type is set, use that.
    if (self.expected_type) |expected| {
        if (expected == i32_type) {
            return c.LLVMBuildTrunc(self.builder, result_i64, i32_type, "await.trunc");
        }
        if (expected == i64_type) {
            return result_i64;
        }
    }
    // Default: truncate to i32.
    return c.LLVMBuildTrunc(self.builder, result_i64, i32_type, "await.trunc");
}

fn genAwaitTuple(self: *Codegen, elems: []const *const Ast.Expr) Error!c.LLVMValueRef {
    if (elems.len < 2 or elems.len > 12) return error.UnsupportedExpr;

    self.declareAsyncRuntime();

    const await_fn = c.LLVMGetNamedFunction(self.module, "with_fiber_await") orelse return error.UnsupportedExpr;
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    var await_params = [_]c.LLVMTypeRef{i32_type};
    const await_ft = c.LLVMFunctionType(i64_type, &await_params, 1, 0);

    var task_ids: [16]c.LLVMValueRef = undefined;
    for (elems, 0..) |elem, i| {
        task_ids[i] = try self.genExpr(elem);
    }

    var values: [16]c.LLVMValueRef = undefined;
    var types: [16]c.LLVMTypeRef = undefined;
    for (elems, 0..) |elem, i| {
        var args = [_]c.LLVMValueRef{task_ids[i]};
        const result_i64 = c.LLVMBuildCall2(self.builder, await_ft, await_fn, &args, 1, "await.result");

        const value = if (self.inferTaskResultType(elem)) |task_result_type|
            try self.unpackTaskResultFromI64(result_i64, task_result_type)
        else
            c.LLVMBuildTrunc(self.builder, result_i64, i32_type, "await.trunc");

        values[i] = value;
        types[i] = c.LLVMTypeOf(value);
    }

    const count: u32 = @intCast(elems.len);
    const tuple_type = c.LLVMStructTypeInContext(self.context, &types, count, 0);
    const alloca = c.LLVMBuildAlloca(self.builder, tuple_type, "await.tuple");
    for (0..count) |i| {
        const idx: u32 = @intCast(i);
        var indices = [_]c.LLVMValueRef{
            c.LLVMConstInt(i32_type, 0, 0),
            c.LLVMConstInt(i32_type, idx, 0),
        };
        const gep = c.LLVMBuildGEP2(self.builder, tuple_type, alloca, &indices, 2, "");
        _ = c.LLVMBuildStore(self.builder, values[i], gep);
    }
    return c.LLVMBuildLoad2(self.builder, tuple_type, alloca, "await.tuple.val");
}

/// Generate a spawn expression: fire-and-forget async task.
/// Evaluates the inner expression (which should be an async function call that
/// returns a task ID), and discards the result.
fn genSpawn(self: *Codegen, inner: *const Ast.Expr) Error!c.LLVMValueRef {
    self.declareAsyncRuntime();

    // Evaluate the inner expression — this is a call to an async function
    // which returns a task ID (i32).
    return try self.genExpr(inner);
}

/// Generate `async scope |s|: body`.
/// Tracked tasks registered via `s.track(task)` are canceled and awaited
/// at scope exit to enforce bounded lifetime.
fn genAsyncScope(self: *Codegen, as: Ast.AsyncScopeExpr) Error!c.LLVMValueRef {
    self.declareAsyncRuntime();

    if (self.async_scope_depth >= self.async_scope_frames.len) return error.UnsupportedExpr;

    const frame_idx = self.async_scope_depth;
    self.async_scope_frames[frame_idx].symbol = as.name;
    self.async_scope_frames[frame_idx].task_count = 0;
    self.async_scope_depth += 1;
    defer self.async_scope_depth -= 1;

    const body_val = try self.genExpr(as.body);

    const current_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(current_bb) == null) {
        const i32_type = c.LLVMInt32TypeInContext(self.context);
        const i64_type = c.LLVMInt64TypeInContext(self.context);

        const cancel_fn = c.LLVMGetNamedFunction(self.module, "with_fiber_cancel") orelse return error.UnsupportedExpr;
        var cancel_params = [_]c.LLVMTypeRef{i32_type};
        const cancel_ft = c.LLVMFunctionType(i32_type, &cancel_params, 1, 0);

        const await_fn = c.LLVMGetNamedFunction(self.module, "with_fiber_await") orelse return error.UnsupportedExpr;
        var await_params = [_]c.LLVMTypeRef{i32_type};
        const await_ft = c.LLVMFunctionType(i64_type, &await_params, 1, 0);

        const frame = &self.async_scope_frames[frame_idx];
        for (0..frame.task_count) |i| {
            const task_id = frame.tasks[i];
            var cancel_args = [_]c.LLVMValueRef{task_id};
            _ = c.LLVMBuildCall2(self.builder, cancel_ft, cancel_fn, &cancel_args, 1, "");
            var await_args = [_]c.LLVMValueRef{task_id};
            _ = c.LLVMBuildCall2(self.builder, await_ft, await_fn, &await_args, 1, "");
        }
    }

    return body_val;
}

/// Generate a select await expression.
/// Spawns all tasks, calls with_fiber_select to race them,
/// then branches based on which completed first.
fn genSelectAwait(self: *Codegen, sel: Ast.SelectAwaitExpr) Error!c.LLVMValueRef {
    self.declareAsyncRuntime();

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const arm_count: u32 = @intCast(sel.arms.len);

    if (sel.arms.len == 0 or sel.arms.len > 16) return error.UnsupportedExpr;

    // Declare with_fiber_select if not already declared.
    if (c.LLVMGetNamedFunction(self.module, "with_fiber_select") == null) {
        var select_params = [_]c.LLVMTypeRef{ ptr_type, i32_type, ptr_type };
        const select_ft = c.LLVMFunctionType(i32_type, &select_params, 3, 0);
        _ = c.LLVMAddFunction(self.module, "with_fiber_select", select_ft);
    }

    // Evaluate all task expressions (each returns a task ID: i32).
    var task_ids_buf: [16]c.LLVMValueRef = undefined;
    for (sel.arms, 0..) |arm, i| {
        task_ids_buf[i] = try self.genExpr(arm.task);
    }

    // Build an array of task IDs on the stack.
    const arr_type = c.LLVMArrayType2(i32_type, arm_count);
    const ids_alloca = c.LLVMBuildAlloca(self.builder, arr_type, "select.ids");
    const zero = c.LLVMConstInt(i32_type, 0, 0);
    for (0..arm_count) |i| {
        const idx: u32 = @intCast(i);
        var indices = [_]c.LLVMValueRef{ zero, c.LLVMConstInt(i32_type, idx, 0) };
        const gep = c.LLVMBuildGEP2(self.builder, arr_type, ids_alloca, &indices, 2, "");
        _ = c.LLVMBuildStore(self.builder, task_ids_buf[i], gep);
    }

    // Allocate result_out on stack.
    const result_alloca = c.LLVMBuildAlloca(self.builder, i64_type, "select.result");

    // Call with_fiber_select(ids_ptr, count, &result_out) -> i32 (winning index).
    const select_fn = c.LLVMGetNamedFunction(self.module, "with_fiber_select") orelse return error.UnsupportedExpr;
    var select_params_types = [_]c.LLVMTypeRef{ ptr_type, i32_type, ptr_type };
    const select_ft = c.LLVMFunctionType(i32_type, &select_params_types, 3, 0);

    const ids_ptr = c.LLVMBuildBitCast(self.builder, ids_alloca, ptr_type, "");
    var call_args = [_]c.LLVMValueRef{
        ids_ptr,
        c.LLVMConstInt(i32_type, arm_count, 0),
        result_alloca,
    };
    const winner_idx = c.LLVMBuildCall2(self.builder, select_ft, select_fn, &call_args, 3, "select.winner");

    // Load the result value.
    const result_val = c.LLVMBuildLoad2(self.builder, i64_type, result_alloca, "select.val");

    // Build switch on winner_idx to dispatch to the right arm.
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "select.end");
    const default_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "select.default");

    const sw = c.LLVMBuildSwitch(self.builder, winner_idx, default_bb, arm_count);

    var arm_vals: [16]c.LLVMValueRef = undefined;
    var arm_bbs: [16]c.LLVMBasicBlockRef = undefined;
    var val_count: u32 = 0;

    for (sel.arms, 0..) |arm, i| {
        const idx: u32 = @intCast(i);
        const arm_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "select.arm");
        c.LLVMAddCase(sw, c.LLVMConstInt(i32_type, idx, 0), arm_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, arm_bb);

        // Bind the result to the arm's name (truncate i64 -> i32).
        const truncated = c.LLVMBuildTrunc(self.builder, result_val, i32_type, "select.trunc");
        const bind_alloca = c.LLVMBuildAlloca(self.builder, i32_type, "");
        const saved_local = self.locals.get(arm.name);
        _ = c.LLVMBuildStore(self.builder, truncated, bind_alloca);
        self.locals.put(self.allocator, arm.name, .{
            .alloca = bind_alloca,
            .ty = i32_type,
            .is_mut = false,
        }) catch return error.CodegenAlloc;

        // Generate body.
        const body_val = try self.genExpr(arm.body);
        if (saved_local) |old| {
            self.locals.put(self.allocator, arm.name, old) catch return error.CodegenAlloc;
        } else {
            _ = self.locals.remove(arm.name);
        }
        const from_bb = c.LLVMGetInsertBlock(self.builder);
        if (c.LLVMGetBasicBlockTerminator(from_bb) == null) {
            _ = c.LLVMBuildBr(self.builder, merge_bb);
        }

        arm_vals[val_count] = body_val;
        arm_bbs[val_count] = from_bb;
        val_count += 1;
    }

    // Default block (shouldn't be reached).
    c.LLVMPositionBuilderAtEnd(self.builder, default_bb);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Merge block.
    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);

    // If arms produce values, create a phi node.
    if (val_count > 0 and arm_vals[0] != null) {
        const result_type = c.LLVMTypeOf(arm_vals[0]);
        if (result_type != c.LLVMVoidTypeInContext(self.context)) {
            const phi = c.LLVMBuildPhi(self.builder, result_type, "select.phi");
            // Add incoming from each arm.
            for (0..val_count) |i| {
                var vals = [_]c.LLVMValueRef{arm_vals[i]};
                var bbs = [_]c.LLVMBasicBlockRef{arm_bbs[i]};
                c.LLVMAddIncoming(phi, &vals, &bbs, 1);
            }
            // Add default incoming.
            var def_vals = [_]c.LLVMValueRef{c.LLVMGetUndef(result_type)};
            var def_bbs = [_]c.LLVMBasicBlockRef{default_bb};
            c.LLVMAddIncoming(phi, &def_vals, &def_bbs, 1);
            return phi;
        }
    }

    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

/// Generate a comptime expression. Evaluates the inner expression at compile time.
/// For `comptime if cond then a else b`, only emits code for the taken branch.
/// For `comptime <arithmetic>`, evaluates to a constant.
fn genComptimeExpr(self: *Codegen, inner: *const Ast.Expr) Error!c.LLVMValueRef {
    switch (inner.kind) {
        .if_expr => |ie| {
            // Evaluate condition at compile time.
            if (self.evalComptimeCondition(ie.condition)) |cond_val| {
                if (cond_val) {
                    return self.genExpr(ie.then_body);
                } else if (ie.else_body) |eb| {
                    return self.genExpr(eb);
                } else {
                    return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
                }
            }
            // Fallback: generate as regular if.
            return self.genIfExpr(ie);
        },
        .int_literal => |v| {
            return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), @bitCast(@as(i64, v)), 0);
        },
        .bool_literal => |v| {
            return c.LLVMConstInt(c.LLVMInt1TypeInContext(self.context), if (v) 1 else 0, 0);
        },
        .binary => |b| {
            // Try to evaluate binary expression at compile time.
            if (self.evalComptimeInt(inner)) |v| {
                return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), @bitCast(@as(i64, v)), 0);
            }
            // Fallback: generate as regular expression.
            return self.genBinary(b);
        },
        .block => |blk| {
            // Comptime block: evaluate each statement, return tail value.
            for (blk.stmts) |stmt| {
                _ = try self.genComptimeExpr(stmt);
            }
            if (blk.tail) |tail| {
                return self.genComptimeExpr(tail);
            }
            return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
        },
        .string_literal => {
            // Comptime string literal — just generate normally.
            return self.genExpr(inner);
        },
        else => {
            // For anything else, just generate it normally.
            return self.genExpr(inner);
        },
    }
}

/// Try to evaluate a condition expression at compile time (returns null if not constant).
fn evalComptimeCondition(self: *Codegen, expr: *const Ast.Expr) ?bool {
    switch (expr.kind) {
        .bool_literal => |v| return v,
        .binary => |b| {
            const lhs = self.evalComptimeInt(b.lhs) orelse return null;
            const rhs = self.evalComptimeInt(b.rhs) orelse return null;
            return switch (b.op) {
                .eq => lhs == rhs,
                .neq => lhs != rhs,
                .lt => lhs < rhs,
                .gt => lhs > rhs,
                .lte => lhs <= rhs,
                .gte => lhs >= rhs,
                else => null,
            };
        },
        .unary => |u| {
            if (u.op == .not) {
                const inner = self.evalComptimeCondition(u.operand) orelse return null;
                return !inner;
            }
            return null;
        },
        else => return null,
    }
}

/// Try to evaluate an integer expression at compile time (returns null if not constant).
fn evalComptimeInt(self: *Codegen, expr: *const Ast.Expr) ?i64 {
    switch (expr.kind) {
        .int_literal => |v| return v,
        .bool_literal => |v| return if (v) 1 else 0,
        .binary => |b| {
            const lhs = self.evalComptimeInt(b.lhs) orelse return null;
            const rhs = self.evalComptimeInt(b.rhs) orelse return null;
            return switch (b.op) {
                .add, .add_wrap => lhs +% rhs,
                .sub, .sub_wrap => lhs -% rhs,
                .mul, .mul_wrap => lhs *% rhs,
                .div => if (rhs != 0) @divTrunc(lhs, rhs) else null,
                .mod => if (rhs != 0) @rem(lhs, rhs) else null,
                .bit_and => lhs & rhs,
                .bit_or => lhs | rhs,
                .bit_xor => lhs ^ rhs,
                .shl => lhs << @intCast(@min(rhs, 63)),
                .shr => lhs >> @intCast(@min(rhs, 63)),
                else => null,
            };
        },
        .unary => |u| {
            if (u.op == .negate) {
                const v = self.evalComptimeInt(u.operand) orelse return null;
                return -v;
            }
            return null;
        },
        else => return null,
    }
}

/// Declare channel runtime functions if not already declared.
fn declareChannelRuntime(self: *Codegen) void {
    self.declareAsyncRuntime(); // Channels depend on the fiber runtime

    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const void_type = c.LLVMVoidTypeInContext(self.context);

    // void* with_channel_create(i32 capacity)
    if (c.LLVMGetNamedFunction(self.module, "with_channel_create") == null) {
        var params = [_]c.LLVMTypeRef{i32_type};
        const ft = c.LLVMFunctionType(ptr_type, &params, 1, 0);
        _ = c.LLVMAddFunction(self.module, "with_channel_create", ft);
    }

    // void with_channel_send(void*, i64)
    if (c.LLVMGetNamedFunction(self.module, "with_channel_send") == null) {
        var params = [_]c.LLVMTypeRef{ ptr_type, i64_type };
        const ft = c.LLVMFunctionType(void_type, &params, 2, 0);
        _ = c.LLVMAddFunction(self.module, "with_channel_send", ft);
    }

    // i64 with_channel_recv(void*)
    if (c.LLVMGetNamedFunction(self.module, "with_channel_recv") == null) {
        var params = [_]c.LLVMTypeRef{ptr_type};
        const ft = c.LLVMFunctionType(i64_type, &params, 1, 0);
        _ = c.LLVMAddFunction(self.module, "with_channel_recv", ft);
    }

    // void with_channel_close(void*)
    if (c.LLVMGetNamedFunction(self.module, "with_channel_close") == null) {
        var params = [_]c.LLVMTypeRef{ptr_type};
        const ft = c.LLVMFunctionType(void_type, &params, 1, 0);
        _ = c.LLVMAddFunction(self.module, "with_channel_close", ft);
    }

    // void with_channel_destroy(void*)
    if (c.LLVMGetNamedFunction(self.module, "with_channel_destroy") == null) {
        var params = [_]c.LLVMTypeRef{ptr_type};
        const ft = c.LLVMFunctionType(void_type, &params, 1, 0);
        _ = c.LLVMAddFunction(self.module, "with_channel_destroy", ft);
    }
}

/// Generate Channel(capacity) — returns an opaque pointer (as i64).
fn genChannelCreate(self: *Codegen, args: []const *const Ast.Expr) Error!c.LLVMValueRef {
    self.declareChannelRuntime();
    self.uses_async = true;

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);

    var capacity: c.LLVMValueRef = c.LLVMConstInt(i32_type, 256, 0);
    if (args.len >= 1) {
        capacity = try self.genExpr(args[0]);
    }

    const create_fn = c.LLVMGetNamedFunction(self.module, "with_channel_create") orelse return error.UnsupportedExpr;
    var create_params = [_]c.LLVMTypeRef{i32_type};
    const create_ft = c.LLVMFunctionType(ptr_type, &create_params, 1, 0);
    var create_args = [_]c.LLVMValueRef{capacity};
    const ch_ptr = c.LLVMBuildCall2(self.builder, create_ft, create_fn, &create_args, 1, "ch.ptr");

    // Cast pointer to i64 so it can be stored in a regular i64 variable.
    return c.LLVMBuildPtrToInt(self.builder, ch_ptr, i64_type, "ch.handle");
}

/// Generate send(ch, value) — sends an i64 value to the channel.
fn genChannelSend(self: *Codegen, args: []const *const Ast.Expr) Error!c.LLVMValueRef {
    if (args.len != 2) return error.UnsupportedExpr;
    self.declareChannelRuntime();

    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const void_type = c.LLVMVoidTypeInContext(self.context);

    const ch_handle = try self.genExpr(args[0]);
    var value = try self.genExpr(args[1]);

    // Extend i32 to i64 if needed.
    const val_type = c.LLVMTypeOf(value);
    if (val_type == c.LLVMInt32TypeInContext(self.context)) {
        value = c.LLVMBuildSExt(self.builder, value, i64_type, "send.ext");
    }

    // Convert handle (i64) back to pointer.
    const ch_ptr = c.LLVMBuildIntToPtr(self.builder, ch_handle, ptr_type, "ch.ptr");

    const send_fn = c.LLVMGetNamedFunction(self.module, "with_channel_send") orelse return error.UnsupportedExpr;
    var send_params = [_]c.LLVMTypeRef{ ptr_type, i64_type };
    const send_ft = c.LLVMFunctionType(void_type, &send_params, 2, 0);
    var send_args = [_]c.LLVMValueRef{ ch_ptr, value };
    _ = c.LLVMBuildCall2(self.builder, send_ft, send_fn, &send_args, 2, "");

    return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
}

/// Generate recv(ch) — receives an i64 value from the channel.
fn genChannelRecv(self: *Codegen, args: []const *const Ast.Expr) Error!c.LLVMValueRef {
    if (args.len != 1) return error.UnsupportedExpr;
    self.declareChannelRuntime();

    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const i32_type = c.LLVMInt32TypeInContext(self.context);

    const ch_handle = try self.genExpr(args[0]);
    const ch_ptr = c.LLVMBuildIntToPtr(self.builder, ch_handle, ptr_type, "ch.ptr");

    const recv_fn = c.LLVMGetNamedFunction(self.module, "with_channel_recv") orelse return error.UnsupportedExpr;
    var recv_params = [_]c.LLVMTypeRef{ptr_type};
    const recv_ft = c.LLVMFunctionType(i64_type, &recv_params, 1, 0);
    var recv_args = [_]c.LLVMValueRef{ch_ptr};
    const result_i64 = c.LLVMBuildCall2(self.builder, recv_ft, recv_fn, &recv_args, 1, "recv.result");

    // Truncate to i32 by default.
    if (self.expected_type) |expected| {
        if (expected == i64_type) return result_i64;
    }
    return c.LLVMBuildTrunc(self.builder, result_i64, i32_type, "recv.trunc");
}

/// Generate close(ch) — closes a channel.
fn genChannelClose(self: *Codegen, args: []const *const Ast.Expr) Error!c.LLVMValueRef {
    if (args.len != 1) return error.UnsupportedExpr;
    self.declareChannelRuntime();

    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const void_type = c.LLVMVoidTypeInContext(self.context);

    const ch_handle = try self.genExpr(args[0]);
    const ch_ptr = c.LLVMBuildIntToPtr(self.builder, ch_handle, ptr_type, "ch.ptr");

    const close_fn = c.LLVMGetNamedFunction(self.module, "with_channel_close") orelse return error.UnsupportedExpr;
    var close_params = [_]c.LLVMTypeRef{ptr_type};
    const close_ft = c.LLVMFunctionType(void_type, &close_params, 1, 0);
    var close_args = [_]c.LLVMValueRef{ch_ptr};
    _ = c.LLVMBuildCall2(self.builder, close_ft, close_fn, &close_args, 1, "");

    return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
}

/// Wrap the user's main function to init/run/shutdown the fiber runtime.
/// If main returns void (fn main:), emit an OS-facing wrapper:
///   define i32 @main() { call @__with_main(); ret i32 0 }
/// If main already returns i32, no wrapping is needed.
fn wrapMainForExit(self: *Codegen) Error!void {
    const original_main = c.LLVMGetNamedFunction(self.module, "main") orelse return;
    const user_fn_type = c.LLVMGlobalGetValueType(original_main);
    const ret_type = c.LLVMGetReturnType(user_fn_type);
    const void_type = c.LLVMVoidTypeInContext(self.context);

    // Only wrap if main returns void (Unit). If it returns i32, the user
    // controls the exit code directly — no wrapper needed.
    if (ret_type != void_type) return;

    const i32_type = c.LLVMInt32TypeInContext(self.context);

    // Rename user's main so we can take the "main" symbol.
    c.LLVMSetValueName2(original_main, "__with_main", 11);

    // Create the OS-facing main() -> i32.
    var no_params: [0]c.LLVMTypeRef = undefined;
    const main_ft = c.LLVMFunctionType(i32_type, &no_params, 0, 0);
    const new_main = c.LLVMAddFunction(self.module, "main", main_ft);
    const entry = c.LLVMAppendBasicBlockInContext(self.context, new_main, "entry");
    c.LLVMPositionBuilderAtEnd(self.builder, entry);

    // Call the user's void main.
    const user_ft = c.LLVMFunctionType(void_type, &no_params, 0, 0);
    _ = c.LLVMBuildCall2(self.builder, user_ft, original_main, null, 0, "");

    // Return 0 to the OS.
    _ = c.LLVMBuildRet(self.builder, c.LLVMConstInt(i32_type, 0, 0));
}

fn wrapMainForAsync(self: *Codegen) Error!void {
    const original_main = c.LLVMGetNamedFunction(self.module, "main") orelse return;
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const void_type = c.LLVMVoidTypeInContext(self.context);

    // Rename original main.
    c.LLVMSetValueName2(original_main, "main_user", 9);

    // Create new main.
    var no_params: [0]c.LLVMTypeRef = undefined;
    const main_ft = c.LLVMFunctionType(i32_type, &no_params, 0, 0);
    const new_main = c.LLVMAddFunction(self.module, "main", main_ft);
    const entry = c.LLVMAppendBasicBlockInContext(self.context, new_main, "entry");
    c.LLVMPositionBuilderAtEnd(self.builder, entry);

    // Call with_runtime_init().
    const init_fn = c.LLVMGetNamedFunction(self.module, "with_runtime_init") orelse return error.UnsupportedExpr;
    const void_ft = c.LLVMFunctionType(void_type, &no_params, 0, 0);
    _ = c.LLVMBuildCall2(self.builder, void_ft, init_fn, null, 0, "");

    // Call main_user().
    const user_main_ft = c.LLVMFunctionType(i32_type, &no_params, 0, 0);
    const user_result = c.LLVMBuildCall2(self.builder, user_main_ft, original_main, null, 0, "user.result");

    // Call with_runtime_run() — runs remaining fibers.
    const run_fn = c.LLVMGetNamedFunction(self.module, "with_runtime_run") orelse return error.UnsupportedExpr;
    _ = c.LLVMBuildCall2(self.builder, void_ft, run_fn, null, 0, "");

    // Call with_runtime_shutdown().
    const shutdown_fn = c.LLVMGetNamedFunction(self.module, "with_runtime_shutdown") orelse return error.UnsupportedExpr;
    _ = c.LLVMBuildCall2(self.builder, void_ft, shutdown_fn, null, 0, "");

    _ = c.LLVMBuildRet(self.builder, user_result);
}

/// Get or declare malloc for heap allocation.
fn getOrDeclareMalloc(self: *Codegen) c.LLVMValueRef {
    if (c.LLVMGetNamedFunction(self.module, "malloc")) |f| return f;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    var params = [_]c.LLVMTypeRef{i64_type};
    const ft = c.LLVMFunctionType(ptr_type, &params, 1, 0);
    return c.LLVMAddFunction(self.module, "malloc", ft);
}

fn genTuple(self: *Codegen, elems: []const *const Ast.Expr) Error!c.LLVMValueRef {
    // Generate all element values and collect their types.
    var vals: [16]c.LLVMValueRef = undefined;
    var types: [16]c.LLVMTypeRef = undefined;
    for (elems, 0..) |elem, i| {
        vals[i] = try self.genExpr(elem);
        types[i] = c.LLVMTypeOf(vals[i]);
    }

    // Create an anonymous struct type for the tuple.
    const count: u32 = @intCast(elems.len);
    const tuple_type = c.LLVMStructTypeInContext(self.context, &types, count, 0);

    // Alloca, store each field, load result.
    const alloca = c.LLVMBuildAlloca(self.builder, tuple_type, "tuple");
    for (0..count) |i| {
        const idx: u32 = @intCast(i);
        var indices = [_]c.LLVMValueRef{
            c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0),
            c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), idx, 0),
        };
        const gep = c.LLVMBuildGEP2(self.builder, tuple_type, alloca, &indices, 2, "");
        _ = c.LLVMBuildStore(self.builder, vals[i], gep);
    }
    return c.LLVMBuildLoad2(self.builder, tuple_type, alloca, "tuple.val");
}

fn genBinary(self: *Codegen, bin: Ast.BinaryExpr) Error!c.LLVMValueRef {
    // Short-circuit for `and` / `or`.
    if (bin.op == .@"and") return self.genShortCircuitAnd(bin);
    if (bin.op == .@"or") return self.genShortCircuitOr(bin);
    if (bin.op == .default_op) return self.genDefaultOp(bin);
    if (bin.op == .in_op or bin.op == .not_in) return self.genInExpr(bin);

    const lhs = try self.genExpr(bin.lhs);
    const rhs = try self.genExpr(bin.rhs);

    // String operations: str + str (concat), str == str, str != str.
    const lhs_type = c.LLVMTypeOf(lhs);
    const rhs_type_check = c.LLVMTypeOf(rhs);
    if (self.isStrType(lhs_type) and self.isStrType(rhs_type_check)) {
        if (bin.op == .add or bin.op == .concat) return self.genStrConcat(lhs, rhs);
        if (bin.op == .eq or bin.op == .neq) return self.genStrCompare(lhs, rhs, bin.op);
    }
    // ++ on non-str types: treat as string concat after coercion.
    if (bin.op == .concat) {
        return self.genStrConcat(lhs, rhs);
    }

    // Check for operator overloading via syntax traits.
    if (c.LLVMGetTypeKind(lhs_type) == c.LLVMStructTypeKind) {
        if (self.tryOperatorOverload(bin.op, lhs, lhs_type, rhs)) |result| {
            return result;
        }
    }

    // Handle pointer comparisons (e.g., ptr != 0, ptr == 0).
    const lhs_kind_raw = c.LLVMGetTypeKind(lhs_type);
    const rhs_type = c.LLVMTypeOf(rhs);
    const rhs_kind_raw = c.LLVMGetTypeKind(rhs_type);
    if (lhs_kind_raw == c.LLVMPointerTypeKind or rhs_kind_raw == c.LLVMPointerTypeKind) {
        const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
        const lhs_p = if (lhs_kind_raw == c.LLVMPointerTypeKind) lhs else c.LLVMConstNull(ptr_type);
        const rhs_p = if (rhs_kind_raw == c.LLVMPointerTypeKind) rhs else c.LLVMConstNull(ptr_type);
        return switch (bin.op) {
            .eq => c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, lhs_p, rhs_p, "eq"),
            .neq => c.LLVMBuildICmp(self.builder, c.LLVMIntNE, lhs_p, rhs_p, "ne"),
            else => error.UnsupportedExpr,
        };
    }

    // Ensure operands have the same integer width for comparisons/arithmetic.
    const lhs_c, const rhs_c = self.coerceBinaryOperands(lhs, rhs);

    // Check if operands are floating-point.
    const lhs_kind = c.LLVMGetTypeKind(c.LLVMTypeOf(lhs_c));
    const is_float = (lhs_kind == c.LLVMFloatTypeKind or lhs_kind == c.LLVMDoubleTypeKind);

    if (is_float) {
        return switch (bin.op) {
            .add => c.LLVMBuildFAdd(self.builder, lhs_c, rhs_c, "fadd"),
            .sub => c.LLVMBuildFSub(self.builder, lhs_c, rhs_c, "fsub"),
            .mul => c.LLVMBuildFMul(self.builder, lhs_c, rhs_c, "fmul"),
            .div => c.LLVMBuildFDiv(self.builder, lhs_c, rhs_c, "fdiv"),
            .mod => c.LLVMBuildFRem(self.builder, lhs_c, rhs_c, "fmod"),
            .eq => c.LLVMBuildFCmp(self.builder, c.LLVMRealOEQ, lhs_c, rhs_c, "feq"),
            .neq => c.LLVMBuildFCmp(self.builder, c.LLVMRealONE, lhs_c, rhs_c, "fne"),
            .lt => c.LLVMBuildFCmp(self.builder, c.LLVMRealOLT, lhs_c, rhs_c, "flt"),
            .gt => c.LLVMBuildFCmp(self.builder, c.LLVMRealOGT, lhs_c, rhs_c, "fgt"),
            .lte => c.LLVMBuildFCmp(self.builder, c.LLVMRealOLE, lhs_c, rhs_c, "fle"),
            .gte => c.LLVMBuildFCmp(self.builder, c.LLVMRealOGE, lhs_c, rhs_c, "fge"),
            else => error.UnsupportedExpr,
        };
    }

    return switch (bin.op) {
        .add => self.genCheckedArith(lhs_c, rhs_c, "llvm.sadd.with.overflow", "add"),
        .sub => self.genCheckedArith(lhs_c, rhs_c, "llvm.ssub.with.overflow", "sub"),
        .mul => self.genCheckedArith(lhs_c, rhs_c, "llvm.smul.with.overflow", "mul"),
        .add_wrap => c.LLVMBuildAdd(self.builder, lhs_c, rhs_c, "add"),
        .sub_wrap => c.LLVMBuildSub(self.builder, lhs_c, rhs_c, "sub"),
        .mul_wrap => c.LLVMBuildMul(self.builder, lhs_c, rhs_c, "mul"),
        .div => c.LLVMBuildSDiv(self.builder, lhs_c, rhs_c, "div"),
        .mod => c.LLVMBuildSRem(self.builder, lhs_c, rhs_c, "mod"),
        .eq => c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, lhs_c, rhs_c, "eq"),
        .neq => c.LLVMBuildICmp(self.builder, c.LLVMIntNE, lhs_c, rhs_c, "ne"),
        .lt => c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, lhs_c, rhs_c, "lt"),
        .gt => c.LLVMBuildICmp(self.builder, c.LLVMIntSGT, lhs_c, rhs_c, "gt"),
        .lte => c.LLVMBuildICmp(self.builder, c.LLVMIntSLE, lhs_c, rhs_c, "le"),
        .gte => c.LLVMBuildICmp(self.builder, c.LLVMIntSGE, lhs_c, rhs_c, "ge"),
        .bit_and => c.LLVMBuildAnd(self.builder, lhs_c, rhs_c, "and"),
        .bit_or => c.LLVMBuildOr(self.builder, lhs_c, rhs_c, "or"),
        .bit_xor => c.LLVMBuildXor(self.builder, lhs_c, rhs_c, "xor"),
        .shl => c.LLVMBuildShl(self.builder, lhs_c, rhs_c, "shl"),
        .shr => c.LLVMBuildAShr(self.builder, lhs_c, rhs_c, "shr"),
        else => error.UnsupportedExpr,
    };
}

/// Checked integer arithmetic using LLVM overflow intrinsics (§4.2).
/// Calls abort() on overflow. Used for +, -, * on signed integers.
fn genCheckedArith(
    self: *Codegen,
    lhs: c.LLVMValueRef,
    rhs: c.LLVMValueRef,
    intrinsic_name: [*:0]const u8,
    label: [*:0]const u8,
) Error!c.LLVMValueRef {
    const int_type = c.LLVMTypeOf(lhs);
    // Look up the intrinsic (e.g., llvm.sadd.with.overflow.i32).
    const intrinsic_id = c.LLVMLookupIntrinsicID(intrinsic_name, std.mem.len(intrinsic_name));
    if (intrinsic_id == 0) {
        // Fallback: if intrinsic not found, use plain wrapping arithmetic.
        if (std.mem.eql(u8, std.mem.span(intrinsic_name), "llvm.sadd.with.overflow"))
            return c.LLVMBuildAdd(self.builder, lhs, rhs, label);
        if (std.mem.eql(u8, std.mem.span(intrinsic_name), "llvm.ssub.with.overflow"))
            return c.LLVMBuildSub(self.builder, lhs, rhs, label);
        return c.LLVMBuildMul(self.builder, lhs, rhs, label);
    }

    var overloaded_types = [_]c.LLVMTypeRef{int_type};
    const intrinsic_fn = c.LLVMGetIntrinsicDeclaration(self.module, intrinsic_id, &overloaded_types, 1);
    const intrinsic_fn_type = c.LLVMIntrinsicGetType(self.context, intrinsic_id, &overloaded_types, 1);

    var call_args = [_]c.LLVMValueRef{ lhs, rhs };
    const result_struct = c.LLVMBuildCall2(self.builder, intrinsic_fn_type, intrinsic_fn, &call_args, 2, "");

    // Extract {result, overflow_bit}.
    const value = c.LLVMBuildExtractValue(self.builder, result_struct, 0, label);
    const overflow = c.LLVMBuildExtractValue(self.builder, result_struct, 1, "overflow");

    // Branch: if overflow, abort.
    const cur_fn = self.current_function;
    const overflow_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "overflow.trap");
    const ok_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "overflow.ok");

    _ = c.LLVMBuildCondBr(self.builder, overflow, overflow_bb, ok_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, overflow_bb);
    // Write error message to stderr (fd 2) via write(), then _exit(134).
    const write_info = self.ensureWriteDeclared() catch return error.CodegenAlloc;
    const panic_msg = c.LLVMBuildGlobalStringPtr(self.builder, "runtime panic: integer overflow\n", "overflow.msg");
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    var write_args = [_]c.LLVMValueRef{
        c.LLVMConstInt(i32_type, 2, 0), // fd = stderr
        panic_msg,
        c.LLVMConstInt(i32_type, 33, 0), // len of message
    };
    _ = c.LLVMBuildCall2(self.builder, write_info.fn_type, write_info.value, &write_args, 3, "");
    const exit_info = self.ensureExitDeclared() catch return error.CodegenAlloc;
    var exit_args = [_]c.LLVMValueRef{c.LLVMConstInt(i32_type, 134, 0)};
    _ = c.LLVMBuildCall2(self.builder, exit_info.fn_type, exit_info.value, &exit_args, 1, "");
    _ = c.LLVMBuildUnreachable(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, ok_bb);
    return value;
}

fn genShortCircuitAnd(self: *Codegen, bin: Ast.BinaryExpr) Error!c.LLVMValueRef {
    const function = self.current_function;
    const lhs = try self.genExpr(bin.lhs);
    const lhs_bool = self.coerceToBool(lhs);
    const lhs_bb = c.LLVMGetInsertBlock(self.builder);

    const rhs_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "and.rhs");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "and.merge");

    _ = c.LLVMBuildCondBr(self.builder, lhs_bool, rhs_bb, merge_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, rhs_bb);
    const rhs = try self.genExpr(bin.rhs);
    const rhs_bool = self.coerceToBool(rhs);
    const rhs_end_bb = c.LLVMGetInsertBlock(self.builder);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const i1_type = c.LLVMInt1TypeInContext(self.context);
    const phi = c.LLVMBuildPhi(self.builder, i1_type, "and");
    var incoming_vals = [_]c.LLVMValueRef{
        c.LLVMConstInt(i1_type, 0, 0), // false from LHS
        rhs_bool,
    };
    var incoming_bbs = [_]c.LLVMBasicBlockRef{ lhs_bb, rhs_end_bb };
    c.LLVMAddIncoming(phi, &incoming_vals, &incoming_bbs, 2);

    return phi;
}

fn genShortCircuitOr(self: *Codegen, bin: Ast.BinaryExpr) Error!c.LLVMValueRef {
    const function = self.current_function;
    const lhs = try self.genExpr(bin.lhs);
    const lhs_bool = self.coerceToBool(lhs);
    const lhs_bb = c.LLVMGetInsertBlock(self.builder);

    const rhs_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "or.rhs");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "or.merge");

    _ = c.LLVMBuildCondBr(self.builder, lhs_bool, merge_bb, rhs_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, rhs_bb);
    const rhs = try self.genExpr(bin.rhs);
    const rhs_bool = self.coerceToBool(rhs);
    const rhs_end_bb = c.LLVMGetInsertBlock(self.builder);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const i1_type = c.LLVMInt1TypeInContext(self.context);
    const phi = c.LLVMBuildPhi(self.builder, i1_type, "or");
    var incoming_vals = [_]c.LLVMValueRef{
        c.LLVMConstInt(i1_type, 1, 0), // true from LHS
        rhs_bool,
    };
    var incoming_bbs = [_]c.LLVMBasicBlockRef{ lhs_bb, rhs_end_bb };
    c.LLVMAddIncoming(phi, &incoming_vals, &incoming_bbs, 2);

    return phi;
}

/// Try to resolve a binary op via operator overloading (syntax traits).
/// Returns null if no matching method found.
fn tryOperatorOverload(
    self: *Codegen,
    op: Ast.BinOp,
    lhs: c.LLVMValueRef,
    lhs_type: c.LLVMTypeRef,
    rhs: c.LLVMValueRef,
) ?c.LLVMValueRef {
    const method_name = switch (op) {
        .add => "add",
        .sub => "sub",
        .mul => "mul",
        .div => "div",
        .mod => "mod",
        .eq => "eq",
        .neq => "neq",
        .lt => "lt",
        .gt => "gt",
        .lte => "lte",
        .gte => "gte",
        else => return null,
    };

    // Find the type name for this struct.
    var type_name_str: ?[]const u8 = null;
    {
        var it = self.struct_types.iterator();
        while (it.next()) |entry| {
            if (entry.value_ptr.llvm_type == lhs_type) {
                type_name_str = self.pool.resolve(entry.key_ptr.*);
                break;
            }
        }
    }
    const tn = type_name_str orelse return null;

    // Build mangled name "Type.method".
    var name_buf: [512]u8 = undefined;
    if (tn.len + 1 + method_name.len >= name_buf.len) return null;
    @memcpy(name_buf[0..tn.len], tn);
    name_buf[tn.len] = '.';
    @memcpy(name_buf[tn.len + 1 ..][0..method_name.len], method_name);
    const mangled = name_buf[0 .. tn.len + 1 + method_name.len];
    const fn_sym = self.pool.intern(mangled) catch return null;

    const fn_info = self.functions.get(fn_sym) orelse return null;

    // Call Type.method(self, rhs).
    var args_buf = [_]c.LLVMValueRef{ lhs, rhs };
    const ret_type = c.LLVMGetReturnType(fn_info.fn_type);
    const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
    return c.LLVMBuildCall2(
        self.builder,
        fn_info.fn_type,
        fn_info.value,
        &args_buf,
        2,
        if (is_void) "" else "op",
    );
}

/// Implement `??` (default operator): unwrap Option/Result or use default value.
fn genDefaultOp(self: *Codegen, bin: Ast.BinaryExpr) Error!c.LLVMValueRef {
    const lhs = try self.genExpr(bin.lhs);
    const lhs_type = c.LLVMTypeOf(lhs);

    // LHS must be a struct (enum with payload).
    if (c.LLVMGetTypeKind(lhs_type) != c.LLVMStructTypeKind) return error.UnsupportedExpr;

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const function = self.current_function;

    // Store LHS so we can GEP into it.
    const tmp = c.LLVMBuildAlloca(self.builder, lhs_type, "default.tmp");
    _ = c.LLVMBuildStore(self.builder, lhs, tmp);

    // Extract tag.
    const tag_gep = c.LLVMBuildStructGEP2(self.builder, lhs_type, tmp, 0, "");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "default.tag");

    const is_some = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "default.some");

    const then_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "default.some");
    const else_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "default.none");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "default.merge");

    _ = c.LLVMBuildCondBr(self.builder, is_some, then_bb, else_bb);

    // Some/Ok path: extract payload.
    c.LLVMPositionBuilderAtEnd(self.builder, then_bb);
    const payload_gep = c.LLVMBuildStructGEP2(self.builder, lhs_type, tmp, 1, "");
    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const payload_type = self.getOptionPayloadType(lhs_type) orelse self.findEnumPayloadType(lhs_type, 0) orelse i32_type;
    const payload = c.LLVMBuildLoad2(self.builder, payload_type, payload_ptr, "default.payload");
    const then_end_bb = c.LLVMGetInsertBlock(self.builder);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // None/Err path: evaluate default (RHS). This may diverge (return/break/continue).
    c.LLVMPositionBuilderAtEnd(self.builder, else_bb);
    const rhs = try self.genExpr(bin.rhs);
    const else_end_bb = c.LLVMGetInsertBlock(self.builder);
    const else_bb_terminated = c.LLVMGetBasicBlockTerminator(else_bb) != null;
    const else_end_terminated = c.LLVMGetBasicBlockTerminator(else_end_bb) != null;
    const rhs_is_void = c.LLVMTypeOf(rhs) == c.LLVMVoidTypeInContext(self.context);
    const else_cur_dead = else_end_bb != else_bb and !else_end_terminated;
    const rhs_diverged = rhs_is_void and else_bb_terminated and else_cur_dead;
    const else_terminated = else_end_terminated or rhs_diverged;
    var rhs_coerced: c.LLVMValueRef = undefined;
    if (rhs_diverged) {
        _ = c.LLVMBuildUnreachable(self.builder);
    } else if (!else_terminated) {
        rhs_coerced = self.coerceInt(rhs, payload_type);
        _ = c.LLVMBuildBr(self.builder, merge_bb);
    }

    // Merge with phi.
    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, payload_type, "default.val");
    if (else_terminated) {
        var incoming_vals = [_]c.LLVMValueRef{payload};
        var incoming_bbs = [_]c.LLVMBasicBlockRef{then_end_bb};
        c.LLVMAddIncoming(phi, &incoming_vals, &incoming_bbs, 1);
    } else {
        var incoming_vals = [_]c.LLVMValueRef{ payload, rhs_coerced };
        var incoming_bbs = [_]c.LLVMBasicBlockRef{ then_end_bb, else_end_bb };
        c.LLVMAddIncoming(phi, &incoming_vals, &incoming_bbs, 2);
    }

    return phi;
}

/// Generate `x in collection` or `x not in collection`.
/// Dispatches based on RHS AST kind: array literal, range, or collection type.
fn genInExpr(self: *Codegen, bin: Ast.BinaryExpr) Error!c.LLVMValueRef {
    const negate = bin.op == .not_in;
    const i1_type = c.LLVMInt1TypeInContext(self.context);

    // Path A: RHS is array literal — unroll to comparison chain (zero allocation)
    if (bin.rhs.kind == .array_literal) {
        const elements = bin.rhs.kind.array_literal;
        const lhs = try self.genExpr(bin.lhs);

        if (elements.len == 0) {
            return c.LLVMConstInt(i1_type, if (negate) 1 else 0, 0);
        }

        var result = c.LLVMConstInt(i1_type, 0, 0);
        const lhs_type = c.LLVMTypeOf(lhs);
        for (elements) |elem_expr| {
            const elem = try self.genExpr(elem_expr);
            const eq = if (self.isStrType(lhs_type))
                try self.genStrCompare(lhs, elem, .eq)
            else blk: {
                const lhs_c, const elem_c = self.coerceBinaryOperands(lhs, elem);
                break :blk c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, lhs_c, elem_c, "eq");
            };
            result = c.LLVMBuildOr(self.builder, result, eq, "");
        }

        return if (negate) c.LLVMBuildNot(self.builder, result, "not_in") else result;
    }

    // Path B: RHS is range — generate bounds check
    if (bin.rhs.kind == .range) {
        const range = bin.rhs.kind.range;
        const lhs = try self.genExpr(bin.lhs);
        const start = if (range.start) |s| try self.genExpr(s) else return error.UnsupportedExpr;
        const end = if (range.end) |e| try self.genExpr(e) else return error.UnsupportedExpr;

        const lhs_type = c.LLVMTypeOf(lhs);
        const lhs_kind = c.LLVMGetTypeKind(lhs_type);
        const is_float = (lhs_kind == c.LLVMFloatTypeKind or lhs_kind == c.LLVMDoubleTypeKind);

        if (is_float) {
            const ge = c.LLVMBuildFCmp(self.builder, c.LLVMRealOGE, lhs, start, "range.ge");
            const le_op: c_uint = if (range.inclusive) c.LLVMRealOLE else c.LLVMRealOLT;
            const le = c.LLVMBuildFCmp(self.builder, le_op, lhs, end, "range.le");
            const in_range = c.LLVMBuildAnd(self.builder, ge, le, "range.in");
            return if (negate) c.LLVMBuildNot(self.builder, in_range, "not_in") else in_range;
        }

        const lhs_c, const start_c = self.coerceBinaryOperands(lhs, start);
        const lhs_c2, const end_c = self.coerceBinaryOperands(lhs_c, end);
        _ = lhs_c2;
        const ge = c.LLVMBuildICmp(self.builder, c.LLVMIntSGE, lhs_c, start_c, "range.ge");
        const le_op: c_uint = if (range.inclusive) c.LLVMIntSLE else c.LLVMIntSLT;
        const le = c.LLVMBuildICmp(self.builder, le_op, lhs_c, end_c, "range.le");
        const in_range = c.LLVMBuildAnd(self.builder, ge, le, "range.in");

        return if (negate) c.LLVMBuildNot(self.builder, in_range, "not_in") else in_range;
    }

    // Path C: Collection — dispatch to the appropriate contains method
    const lhs = try self.genExpr(bin.lhs);
    const rhs = try self.genExpr(bin.rhs);
    const rhs_type = c.LLVMTypeOf(rhs);

    const result = if (self.isStrType(rhs_type))
        try self.genStrContains(rhs, lhs)
    else if (self.isHashMapType(rhs_type))
        try self.genHashMapContains(rhs, rhs_type, lhs)
    else if (self.isHashSetType(rhs_type))
        try self.genHashSetContains(rhs, rhs_type, lhs)
    else if (self.isVecType(rhs_type))
        try self.genVecContains(rhs, rhs_type, lhs)
    else if (c.LLVMGetTypeKind(rhs_type) == c.LLVMArrayTypeKind)
        try self.genArrayContains(rhs, rhs_type, lhs)
    else
        return error.UnsupportedExpr;

    return if (negate) c.LLVMBuildNot(self.builder, result, "not_in") else result;
}

fn getResultErrType(self: *Codegen, result_type: c.LLVMTypeRef) ?c.LLVMTypeRef {
    var it = self.result_type_cache.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == result_type) {
            return entry.value_ptr.err_type;
        }
    }
    return null;
}

fn genOptionalChainMember(self: *Codegen, oc: Ast.OptionalChainExpr, payload: c.LLVMValueRef, payload_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    var name_buf: [32]u8 = undefined;
    const name = std.fmt.bufPrint(&name_buf, "__opt_payload_{d}", .{self.closure_counter}) catch return error.CodegenAlloc;
    self.closure_counter += 1;
    const payload_sym = self.pool.intern(name) catch return error.CodegenAlloc;

    const payload_alloca = c.LLVMBuildAlloca(self.builder, payload_type, "opt.payload");
    _ = c.LLVMBuildStore(self.builder, payload, payload_alloca);

    const old_local = self.locals.get(payload_sym);
    self.locals.put(self.allocator, payload_sym, .{
        .alloca = payload_alloca,
        .ty = payload_type,
        .is_mut = false,
    }) catch return error.CodegenAlloc;
    defer {
        if (old_local) |ol| {
            self.locals.put(self.allocator, payload_sym, ol) catch {};
        } else {
            _ = self.locals.remove(payload_sym);
        }
    }

    var payload_expr = Ast.Expr{
        .kind = .{ .ident = payload_sym },
        .span = oc.expr.span,
    };
    const member = Ast.FieldAccessExpr{
        .expr = &payload_expr,
        .field = oc.member,
    };

    if (oc.args) |args| {
        return self.genMethodCall(member, args);
    }
    return self.genFieldAccess(member);
}

fn genOptionalChain(self: *Codegen, oc: Ast.OptionalChainExpr) Error!c.LLVMValueRef {
    const base = try self.genExpr(oc.expr);
    const base_type = c.LLVMTypeOf(base);
    if (!self.isOptionOrResultType(base_type)) return error.UnsupportedExpr;

    const payload_type = self.getOptionPayloadType(base_type) orelse return error.UnsupportedExpr;
    const is_result = self.isResultType(base_type);
    const base_err_type = if (is_result)
        (self.getResultErrType(base_type) orelse c.LLVMInt32TypeInContext(self.context))
    else
        null;

    const cur_fn = self.current_function;
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const base_tmp = c.LLVMBuildAlloca(self.builder, base_type, "opt.base");
    _ = c.LLVMBuildStore(self.builder, base, base_tmp);

    const tag_gep = c.LLVMBuildStructGEP2(self.builder, base_type, base_tmp, 0, "opt.tag.ptr");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "opt.tag");
    const is_ok = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "opt.is_ok");

    const then_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "opt.then");
    const else_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "opt.else");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "opt.merge");
    _ = c.LLVMBuildCondBr(self.builder, is_ok, then_bb, else_bb);

    // Success branch: evaluate the chained member on payload.
    c.LLVMPositionBuilderAtEnd(self.builder, then_bb);
    const payload_gep = c.LLVMBuildStructGEP2(self.builder, base_type, base_tmp, 1, "opt.payload.ptr");
    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const payload_val = c.LLVMBuildLoad2(self.builder, payload_type, payload_ptr, "opt.payload");
    const member_val = try self.genOptionalChainMember(oc, payload_val, payload_type);
    const member_type = c.LLVMTypeOf(member_val);

    var then_result: c.LLVMValueRef = undefined;
    var out_type: c.LLVMTypeRef = undefined;

    if (!is_result) {
        const flatten = self.isOptionOrResultType(member_type) and !self.isResultType(member_type);
        if (flatten) {
            out_type = member_type;
            then_result = member_val;
        } else {
            const out_info = try self.getOrCreateOptionType(member_type);
            out_type = out_info.llvm_type;
            then_result = try self.buildOptionSome(member_val);
        }
    } else {
        const member_err_type = if (self.isResultType(member_type)) self.getResultErrType(member_type) else null;
        const flatten = self.isResultType(member_type) and member_err_type != null and member_err_type.? == base_err_type.?;
        if (flatten) {
            out_type = member_type;
            then_result = member_val;
        } else {
            const out_info = try self.getOrCreateResultType(member_type, base_err_type.?);
            out_type = out_info.llvm_type;
            then_result = try self.buildResultOk(member_val, out_type);
        }
    }
    const then_end = c.LLVMGetInsertBlock(self.builder);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Failure branch: propagate None/Err.
    c.LLVMPositionBuilderAtEnd(self.builder, else_bb);
    const else_result = if (!is_result)
        self.buildOptionNone(out_type)
    else blk: {
        const err_payload_type = self.findEnumPayloadType(base_type, 1) orelse base_err_type.?;
        const err_gep = c.LLVMBuildStructGEP2(self.builder, base_type, base_tmp, 1, "opt.err.ptr");
        const err_ptr = c.LLVMBuildBitCast(self.builder, err_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
        const err_val = c.LLVMBuildLoad2(self.builder, err_payload_type, err_ptr, "opt.err");
        break :blk try self.buildResultErr(err_val, out_type);
    };
    const else_end = c.LLVMGetInsertBlock(self.builder);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, out_type, "opt.chain");
    var vals = [_]c.LLVMValueRef{ then_result, else_result };
    var bbs = [_]c.LLVMBasicBlockRef{ then_end, else_end };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

fn genUnary(self: *Codegen, un: Ast.UnaryExpr) Error!c.LLVMValueRef {
    return switch (un.op) {
        .ref_of, .mut_ref_of => {
            // &expr / &mut expr — return the address (alloca pointer) of the operand.
            return self.genAddrOf(un.operand);
        },
        .deref => {
            // *expr — load through a pointer.
            const ptr_val = try self.genExpr(un.operand);
            // We need to know what type the pointer points to. For now,
            // treat all derefs as loading an i32 or use the pointee type.
            // Try to infer pointee type from context.
            const ptr_type = c.LLVMTypeOf(ptr_val);
            const type_kind = c.LLVMGetTypeKind(ptr_type);
            if (type_kind == c.LLVMPointerTypeKind) {
                // Opaque pointer — we need to know the pointee type.
                // Look it up from the operand if it's an identifier.
                const pointee_type = self.inferPointeeType(un.operand);
                return c.LLVMBuildLoad2(self.builder, pointee_type, ptr_val, "deref");
            }
            return error.UnsupportedExpr;
        },
        .try_op => {
            // expr? — try/unwrap: extract payload on tag==0 (Some/Ok), early return on tag==1 (None/Err).
            if (un.operand.kind == .await_expr and un.operand.kind.await_expr.kind == .tuple) {
                return self.genTryTupleOp(un.operand);
            }
            return self.genTryOp(un.operand);
        },
        else => {
            const operand = try self.genExpr(un.operand);
            return switch (un.op) {
                .negate => blk2: {
                    const kind = c.LLVMGetTypeKind(c.LLVMTypeOf(operand));
                    break :blk2 if (kind == c.LLVMFloatTypeKind or kind == c.LLVMDoubleTypeKind)
                        c.LLVMBuildFNeg(self.builder, operand, "fneg")
                    else
                        c.LLVMBuildNeg(self.builder, operand, "neg");
                },
                .not => blk: {
                    const bool_val = self.coerceToBool(operand);
                    break :blk c.LLVMBuildXor(
                        self.builder,
                        bool_val,
                        c.LLVMConstInt(c.LLVMInt1TypeInContext(self.context), 1, 0),
                        "not",
                    );
                },
                else => error.UnsupportedExpr,
            };
        },
    };
}

/// Implement the `?` (try) operator: unwrap Option/Result, or early return.
fn genTryOp(self: *Codegen, operand: *const Ast.Expr) Error!c.LLVMValueRef {
    const val = try self.genExpr(operand);
    const val_type = c.LLVMTypeOf(val);
    const src_err_sym = self.trySourceErrSymbol(operand);
    if (self.isTupleTryType(val_type)) {
        return self.genTryTupleValue(val, val_type);
    }
    return self.genTryValue(val, val_type, src_err_sym);
}

fn genTryTupleOp(self: *Codegen, operand: *const Ast.Expr) Error!c.LLVMValueRef {
    const tuple_val = try self.genExpr(operand);
    const tuple_type = c.LLVMTypeOf(tuple_val);
    return self.genTryTupleValue(tuple_val, tuple_type);
}

fn genTryTupleValue(self: *Codegen, tuple_val: c.LLVMValueRef, tuple_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    if (c.LLVMGetTypeKind(tuple_type) != c.LLVMStructTypeKind) return error.UnsupportedExpr;

    const elem_count_u32 = c.LLVMCountStructElementTypes(tuple_type);
    const elem_count: usize = @intCast(elem_count_u32);
    if (elem_count == 0) return error.UnsupportedExpr;

    var payload_types: [32]c.LLVMTypeRef = undefined;
    var unwrapped_vals: [32]c.LLVMValueRef = undefined;
    if (elem_count > payload_types.len) return error.UnsupportedExpr;

    for (0..elem_count) |i| {
        const elem_val = c.LLVMBuildExtractValue(self.builder, tuple_val, @intCast(i), "try.tuple.elem");
        const elem_type = c.LLVMTypeOf(elem_val);
        const unwrapped = try self.genTryValue(elem_val, elem_type, null);
        unwrapped_vals[i] = unwrapped;
        payload_types[i] = c.LLVMTypeOf(unwrapped);
    }

    const out_tuple_type = c.LLVMStructTypeInContext(self.context, &payload_types, @intCast(elem_count), 0);
    const out_alloca = c.LLVMBuildAlloca(self.builder, out_tuple_type, "try.tuple.out");

    for (0..elem_count) |i| {
        const gep = c.LLVMBuildStructGEP2(self.builder, out_tuple_type, out_alloca, @intCast(i), "try.tuple.gep");
        _ = c.LLVMBuildStore(self.builder, unwrapped_vals[i], gep);
    }

    return c.LLVMBuildLoad2(self.builder, out_tuple_type, out_alloca, "try.tuple.val");
}

fn isTupleTryType(self: *Codegen, ty: c.LLVMTypeRef) bool {
    if (c.LLVMGetTypeKind(ty) != c.LLVMStructTypeKind) return false;
    if (self.isOptionType(ty) or self.isResultType(ty)) return false;
    if (self.findStructTypeByLlvm(ty) != null) return false;

    const elem_count_u32 = c.LLVMCountStructElementTypes(ty);
    const elem_count: usize = @intCast(elem_count_u32);
    if (elem_count == 0 or elem_count > 32) return false;

    var elem_types: [32]c.LLVMTypeRef = undefined;
    c.LLVMGetStructElementTypes(ty, &elem_types);
    for (0..elem_count) |i| {
        const et = elem_types[i];
        if (c.LLVMGetTypeKind(et) != c.LLVMStructTypeKind) return false;
        if (!self.isOptionType(et) and !self.isResultType(et)) return false;
    }
    return true;
}

fn genTryValue(self: *Codegen, val: c.LLVMValueRef, val_type: c.LLVMTypeRef, src_err_sym: ?u32) Error!c.LLVMValueRef {
    const dst_err_sym = self.current_result_err_symbol;

    // Must be a struct type (enum with payload: { i32 tag, [N x i8] payload }).
    if (c.LLVMGetTypeKind(val_type) != c.LLVMStructTypeKind) return error.UnsupportedExpr;

    const src_is_result = self.isResultType(val_type);
    const src_is_option = self.isOptionType(val_type);
    if (!src_is_result and !src_is_option) return error.UnsupportedExpr;

    const dst_is_result = self.isResultType(self.current_ret_type);
    const dst_is_option = self.isOptionType(self.current_ret_type);
    if (!dst_is_result and !dst_is_option) return error.UnsupportedExpr;
    if ((src_is_result and !dst_is_result) or (src_is_option and !dst_is_option)) {
        // Phase 2 lowering supports Result->Result and Option->Option only.
        return error.UnsupportedExpr;
    }

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const function = self.current_function;

    // Store the value so we can GEP into it.
    const tmp = c.LLVMBuildAlloca(self.builder, val_type, "try.tmp");
    _ = c.LLVMBuildStore(self.builder, val, tmp);

    // Extract tag.
    const tag_gep = c.LLVMBuildStructGEP2(self.builder, val_type, tmp, 0, "");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "try.tag");

    // Tag == 0 means Some/Ok (success), tag != 0 means None/Err (failure).
    const is_ok = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "try.ok");

    const then_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "try.then");
    const else_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "try.else");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "try.merge");

    _ = c.LLVMBuildCondBr(self.builder, is_ok, then_bb, else_bb);

    // Success path: extract payload.
    c.LLVMPositionBuilderAtEnd(self.builder, then_bb);
    const payload_gep = c.LLVMBuildStructGEP2(self.builder, val_type, tmp, 1, "");
    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");

    // Find the payload type by looking up the enum info.
    const payload_type = self.findEnumPayloadType(val_type, 0) orelse i32_type;
    const payload = c.LLVMBuildLoad2(self.builder, payload_type, payload_ptr, "try.payload");
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Failure path: early return with the same value (propagate None/Err).
    c.LLVMPositionBuilderAtEnd(self.builder, else_bb);

    // Emit any defers before returning.
    try self.emitDefers();

    // The return type should match the caller function's return type.
    // If the function returns the same enum type, just return the value.
    // If the function returns a different type, we need to construct a None/Err.
    if (self.current_ret_type == val_type) {
        _ = c.LLVMBuildRet(self.builder, val);
    } else if (c.LLVMGetTypeKind(self.current_ret_type) == c.LLVMStructTypeKind) {
        // Build a None/Err for the return type.
        // For Option: return None of return type.
        // For Result: propagate the Err payload.
        const ret_alloca = c.LLVMBuildAlloca(self.builder, self.current_ret_type, "try.ret");
        const ret_tag_gep = c.LLVMBuildStructGEP2(self.builder, self.current_ret_type, ret_alloca, 0, "");
        _ = c.LLVMBuildStore(self.builder, tag, ret_tag_gep); // propagate tag (1 for None/Err)

        // Copy the error payload if it exists (for Result propagation).
        const src_payload_gep = c.LLVMBuildStructGEP2(self.builder, val_type, tmp, 1, "");
        const dst_payload_gep = c.LLVMBuildStructGEP2(self.builder, self.current_ret_type, ret_alloca, 1, "");
        const src_err_type = self.findEnumPayloadType(val_type, 1);
        const dst_err_type = self.findEnumPayloadType(self.current_ret_type, 1);
        if (src_err_type) |set| {
            if (dst_err_type) |det| {
                const src_ptr = c.LLVMBuildBitCast(self.builder, src_payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
                const src_err_val = c.LLVMBuildLoad2(self.builder, set, src_ptr, "");
                const conv_err_val = blk: {
                    if (set == det) break :blk src_err_val;
                    if (src_err_sym != null and dst_err_sym != null and src_err_sym.? != dst_err_sym.?) {
                        if (self.convertErrorValueBySymbols(src_err_val, set, dst_err_sym.?, src_err_sym.?)) |wrapped| {
                            break :blk wrapped;
                        }
                    }
                    if (self.convertErrorValue(src_err_val, set, det)) |converted| {
                        break :blk converted;
                    }
                    break :blk self.coerceInt(src_err_val, det);
                };

                const dst_ptr = c.LLVMBuildBitCast(self.builder, dst_payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
                _ = c.LLVMBuildStore(self.builder, conv_err_val, dst_ptr);
            }
        }

        const ret_val = c.LLVMBuildLoad2(self.builder, self.current_ret_type, ret_alloca, "try.err");
        _ = c.LLVMBuildRet(self.builder, ret_val);
    } else {
        // Return type is not an enum struct — just return a default value.
        _ = c.LLVMBuildRet(self.builder, c.LLVMConstInt(self.current_ret_type, 0, 0));
    }

    // Continue at merge block with the unwrapped payload.
    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, payload_type, "try.val");
    var incoming_vals = [_]c.LLVMValueRef{payload};
    var incoming_bbs = [_]c.LLVMBasicBlockRef{then_bb};
    c.LLVMAddIncoming(phi, &incoming_vals, &incoming_bbs, 1);

    return phi;
}

/// Find the payload LLVM type for variant at index `variant_idx` of an enum.
fn findEnumPayloadType(self: *Codegen, llvm_type: c.LLVMTypeRef, variant_idx: u32) ?c.LLVMTypeRef {
    // First consult specialized Option/Result caches because enum_types is keyed
    // by symbol name and generic instantiations (Result/Option) share names.
    var opt_it = self.option_type_cache.iterator();
    while (opt_it.next()) |entry| {
        const info = entry.value_ptr.*;
        if (info.llvm_type == llvm_type) {
            return switch (variant_idx) {
                0 => info.payload_type, // Some
                1 => null, // None
                else => null,
            };
        }
    }

    var res_it = self.result_type_cache.iterator();
    while (res_it.next()) |entry| {
        const info = entry.value_ptr.*;
        if (info.llvm_type == llvm_type) {
            return switch (variant_idx) {
                0 => info.payload_type, // Ok
                1 => info.err_type, // Err
                else => null,
            };
        }
    }

    var it = self.enum_types.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == llvm_type) {
            if (variant_idx < entry.value_ptr.variant_payload_types.len) {
                return entry.value_ptr.variant_payload_types[variant_idx];
            }
        }
    }
    return null;
}

fn trySourceErrSymbol(self: *Codegen, operand: *const Ast.Expr) ?u32 {
    switch (operand.kind) {
        .call => |call_e| {
            if (call_e.callee.kind == .ident) {
                return self.fn_result_err_symbols.get(call_e.callee.kind.ident);
            }
        },
        .grouped => |inner| return self.trySourceErrSymbol(inner),
        else => {},
    }
    return null;
}

fn sourceToWrapperVariant(self: *Codegen, source_err_sym: u32) ?u32 {
    const src_name = self.pool.resolve(source_err_sym);
    const suffix = "Error";
    const variant_text = if (src_name.len > suffix.len and std.mem.endsWith(u8, src_name, suffix))
        src_name[0 .. src_name.len - suffix.len]
    else
        src_name;
    return self.pool.intern(variant_text) catch null;
}

fn convertErrorValueBySymbols(
    self: *Codegen,
    src_err_val: c.LLVMValueRef,
    src_err_type: c.LLVMTypeRef,
    dst_err_sym: u32,
    source_err_sym: u32,
) ?c.LLVMValueRef {
    const dst_enum = self.enum_types.get(dst_err_sym) orelse return null;
    const variant_sym = self.sourceToWrapperVariant(source_err_sym) orelse return null;

    for (dst_enum.variant_names, 0..) |vn, i| {
        if (vn != variant_sym) continue;
        const payload_opt = if (i < dst_enum.variant_payload_types.len)
            dst_enum.variant_payload_types[i]
        else
            null;
        if (payload_opt == null) return null;
        const payload_ty = payload_opt.?;
        if (payload_ty != src_err_type) return null;

        const dst_err_type = dst_enum.llvm_type;
        const i32_type = c.LLVMInt32TypeInContext(self.context);
        const alloca = c.LLVMBuildAlloca(self.builder, dst_err_type, "err.conv.sym");
        const tag_gep = c.LLVMBuildStructGEP2(self.builder, dst_err_type, alloca, 0, "");
        _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i32_type, @intCast(i), 0), tag_gep);
        const payload_gep = c.LLVMBuildStructGEP2(self.builder, dst_err_type, alloca, 1, "");
        const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
        _ = c.LLVMBuildStore(self.builder, src_err_val, payload_ptr);
        return c.LLVMBuildLoad2(self.builder, dst_err_type, alloca, "err.conv.sym.val");
    }

    return null;
}

/// Convert an error payload value `src_err_val: src_err_type` into `dst_err_type`
/// when `dst_err_type` is an enum that has a variant carrying `src_err_type`.
fn convertErrorValue(
    self: *Codegen,
    src_err_val: c.LLVMValueRef,
    src_err_type: c.LLVMTypeRef,
    dst_err_type: c.LLVMTypeRef,
) ?c.LLVMValueRef {
    if (src_err_type == dst_err_type) return src_err_val;
    if (c.LLVMGetTypeKind(dst_err_type) != c.LLVMStructTypeKind) return null;

    var it = self.enum_types.iterator();
    while (it.next()) |entry| {
        const enum_info = entry.value_ptr.*;
        if (enum_info.llvm_type != dst_err_type) continue;

        for (enum_info.variant_payload_types, 0..) |payload_opt, i| {
            if (payload_opt) |payload_ty| {
                if (payload_ty == src_err_type) {
                    const i32_type = c.LLVMInt32TypeInContext(self.context);
                    const alloca = c.LLVMBuildAlloca(self.builder, dst_err_type, "err.conv");
                    const tag_gep = c.LLVMBuildStructGEP2(self.builder, dst_err_type, alloca, 0, "err.conv.tag");
                    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i32_type, @intCast(i), 0), tag_gep);

                    const payload_gep = c.LLVMBuildStructGEP2(self.builder, dst_err_type, alloca, 1, "err.conv.payload");
                    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
                    _ = c.LLVMBuildStore(self.builder, src_err_val, payload_ptr);

                    return c.LLVMBuildLoad2(self.builder, dst_err_type, alloca, "err.conv.val");
                }
            }
        }
        return null;
    }
    return null;
}

/// Get the address (alloca pointer) of an expression for &expr.
fn genAddrOf(self: *Codegen, operand: *const Ast.Expr) Error!c.LLVMValueRef {
    switch (operand.kind) {
        .ident => |sym| {
            // Return the alloca pointer directly (not loading the value).
            if (self.locals.get(sym)) |info| {
                return info.alloca;
            }
            return error.UnsupportedExpr;
        },
        .field_access => |fa| {
            // &obj.field — return GEP to the field.
            return self.genFieldAddrOf(fa);
        },
        .index => |idx| {
            // &arr[i] — return GEP to the element.
            return self.genIndexAddrOf(idx);
        },
        else => {
            // For arbitrary expressions, evaluate and store in a temp alloca.
            const val = try self.genExpr(operand);
            const ty = c.LLVMTypeOf(val);
            const alloca = c.LLVMBuildAlloca(self.builder, ty, "ref.tmp");
            _ = c.LLVMBuildStore(self.builder, val, alloca);
            return alloca;
        },
    }
}

/// Get the address of a struct field for &obj.field.
fn genFieldAddrOf(self: *Codegen, fa: Ast.FieldAccessExpr) Error!c.LLVMValueRef {
    // Get the struct alloca pointer.
    switch (fa.expr.kind) {
        .ident => |sym| {
            if (self.locals.get(sym)) |info| {
                // Find field index.
                const struct_type = info.ty;
                var si_it = self.struct_types.iterator();
                while (si_it.next()) |entry| {
                    if (entry.value_ptr.llvm_type == struct_type) {
                        for (entry.value_ptr.field_names, 0..) |fname, idx| {
                            if (fname == fa.field) {
                                return c.LLVMBuildStructGEP2(
                                    self.builder,
                                    struct_type,
                                    info.alloca,
                                    @intCast(idx),
                                    "field.addr",
                                );
                            }
                        }
                    }
                }
            }
        },
        else => {},
    }
    // Fallback: evaluate and take addr.
    const val = try self.genFieldAccess(fa);
    const ty = c.LLVMTypeOf(val);
    const alloca = c.LLVMBuildAlloca(self.builder, ty, "field.ref.tmp");
    _ = c.LLVMBuildStore(self.builder, val, alloca);
    return alloca;
}

/// Get the address of an array element for &arr[i].
fn genIndexAddrOf(self: *Codegen, idx: Ast.IndexExpr) Error!c.LLVMValueRef {
    switch (idx.expr.kind) {
        .ident => |sym| {
            if (self.locals.get(sym)) |info| {
                const index_val = try self.genExpr(idx.index);
                var indices = [_]c.LLVMValueRef{
                    c.LLVMConstInt(c.LLVMInt64TypeInContext(self.context), 0, 0),
                    index_val,
                };
                return c.LLVMBuildGEP2(
                    self.builder,
                    info.ty,
                    info.alloca,
                    &indices,
                    2,
                    "elem.addr",
                );
            }
        },
        else => {},
    }
    // Fallback: evaluate and take addr.
    const val = try self.genIndex(idx);
    const ty = c.LLVMTypeOf(val);
    const alloca = c.LLVMBuildAlloca(self.builder, ty, "elem.ref.tmp");
    _ = c.LLVMBuildStore(self.builder, val, alloca);
    return alloca;
}

/// Infer the pointee type for a deref (*expr) by looking at the operand.
fn inferPointeeType(self: *Codegen, operand: *const Ast.Expr) c.LLVMTypeRef {
    switch (operand.kind) {
        .ident => |sym| {
            // Check our ref pointee type tracking.
            if (self.ref_pointee_types.get(sym)) |pointee_ty| {
                return pointee_ty;
            }
            if (self.locals.get(sym)) |info| {
                _ = info;
            }
        },
        else => {},
    }
    // Default to i32 for now.
    return c.LLVMInt32TypeInContext(self.context);
}

fn genBlock(self: *Codegen, blk: Ast.BlockExpr) Error!c.LLVMValueRef {
    const scope_start = self.scope_local_count;

    for (blk.stmts) |stmt| {
        _ = try self.genExpr(stmt);
    }
    if (blk.tail) |tail| {
        const v = try self.genExpr(tail);
        try self.emitDrops(scope_start);
        self.scope_local_count = scope_start;
        return v;
    }
    try self.emitDrops(scope_start);
    self.scope_local_count = scope_start;
    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

/// Find or create an Option enum type for a given payload LLVM type.
/// Option layout: { i32 tag, [sizeof(T) x i8] } where 0=Some, 1=None.
fn getOrCreateOptionType(self: *Codegen, payload_type: c.LLVMTypeRef) Error!OptionResultInfo {
    const key: usize = @intFromPtr(payload_type);
    if (self.option_type_cache.get(key)) |info| return info;

    // Compute payload size.
    const data_layout = c.LLVMGetModuleDataLayout(self.module);
    const payload_size = c.LLVMABISizeOfType(data_layout, payload_type);
    const slot_size: u64 = 8;
    const slot_count = if (payload_size == 0) 1 else (payload_size + slot_size - 1) / slot_size;

    // Create the LLVM struct type: { i32, [payload_size x i8] }.
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const payload_arr = c.LLVMArrayType2(i64_type, slot_count);
    var body_types = [_]c.LLVMTypeRef{ i32_type, payload_arr };
    var name_buf: [64]u8 = undefined;
    const name_z = std.fmt.bufPrintZ(&name_buf, "__with.Option.{x}", .{key}) catch return error.CodegenAlloc;
    const llvm_type = c.LLVMStructCreateNamed(self.context, name_z);
    c.LLVMStructSetBody(llvm_type, &body_types, 2, 0);

    // Register in enum_types with variant names Some (0) and None (1).
    const some_sym = self.pool.intern("Some") catch return error.CodegenAlloc;
    const none_sym = self.pool.intern("None") catch return error.CodegenAlloc;
    const option_sym = self.pool.intern("Option") catch return error.CodegenAlloc;

    const variant_names = self.allocator.alloc(u32, 2) catch return error.CodegenAlloc;
    variant_names[0] = some_sym;
    variant_names[1] = none_sym;

    const variant_payload_types = self.allocator.alloc(?c.LLVMTypeRef, 2) catch return error.CodegenAlloc;
    variant_payload_types[0] = payload_type; // Some(T)
    variant_payload_types[1] = null; // None

    const enum_type_info: EnumTypeInfo = .{
        .llvm_type = llvm_type,
        .variant_names = variant_names,
        .variant_payload_types = variant_payload_types,
    };
    self.enum_types.put(self.allocator, option_sym, enum_type_info) catch return error.CodegenAlloc;
    self.enum_types_by_llvm.put(self.allocator, @intFromPtr(llvm_type), enum_type_info) catch return error.CodegenAlloc;

    const info: OptionResultInfo = .{
        .llvm_type = llvm_type,
        .payload_type = payload_type,
        .err_type = null,
        .enum_sym = option_sym,
    };
    self.option_type_cache.put(self.allocator, key, info) catch return error.CodegenAlloc;
    return info;
}

/// Find or create a Result enum type for given Ok and Err LLVM types.
/// Result layout: { i32 tag, [max(sizeof(T),sizeof(E)) x i8] } where 0=Ok, 1=Err.
fn getOrCreateResultType(self: *Codegen, ok_type: c.LLVMTypeRef, err_type: c.LLVMTypeRef) Error!OptionResultInfo {
    const key: u64 = @as(u64, @intFromPtr(ok_type)) ^ (@as(u64, @intFromPtr(err_type)) << 32);
    if (self.result_type_cache.get(key)) |info| return info;

    const data_layout = c.LLVMGetModuleDataLayout(self.module);
    const ok_size = c.LLVMABISizeOfType(data_layout, ok_type);
    const err_size = c.LLVMABISizeOfType(data_layout, err_type);
    const max_size = @max(ok_size, err_size);
    const slot_size: u64 = 8;
    const slot_count = if (max_size == 0) 1 else (max_size + slot_size - 1) / slot_size;

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const payload_arr = c.LLVMArrayType2(i64_type, slot_count);
    var body_types = [_]c.LLVMTypeRef{ i32_type, payload_arr };
    var name_buf: [72]u8 = undefined;
    const name_z = std.fmt.bufPrintZ(&name_buf, "__with.Result.{x}", .{key}) catch return error.CodegenAlloc;
    const llvm_type = c.LLVMStructCreateNamed(self.context, name_z);
    c.LLVMStructSetBody(llvm_type, &body_types, 2, 0);

    const ok_sym = self.pool.intern("Ok") catch return error.CodegenAlloc;
    const err_sym = self.pool.intern("Err") catch return error.CodegenAlloc;
    const result_sym = self.pool.intern("Result") catch return error.CodegenAlloc;

    const variant_names = self.allocator.alloc(u32, 2) catch return error.CodegenAlloc;
    variant_names[0] = ok_sym;
    variant_names[1] = err_sym;

    const variant_payload_types = self.allocator.alloc(?c.LLVMTypeRef, 2) catch return error.CodegenAlloc;
    variant_payload_types[0] = ok_type;
    variant_payload_types[1] = err_type;

    const result_enum_info: EnumTypeInfo = .{
        .llvm_type = llvm_type,
        .variant_names = variant_names,
        .variant_payload_types = variant_payload_types,
    };
    self.enum_types.put(self.allocator, result_sym, result_enum_info) catch return error.CodegenAlloc;
    self.enum_types_by_llvm.put(self.allocator, @intFromPtr(llvm_type), result_enum_info) catch return error.CodegenAlloc;

    const info: OptionResultInfo = .{
        .llvm_type = llvm_type,
        .payload_type = ok_type,
        .err_type = err_type,
        .enum_sym = result_sym,
    };
    self.result_type_cache.put(self.allocator, key, info) catch return error.CodegenAlloc;
    return info;
}

/// Find or create ContextError[E] as a struct { str, E }.
fn getOrCreateContextErrorType(self: *Codegen, source_type: c.LLVMTypeRef) Error!ContextErrorInfo {
    const key: usize = @intFromPtr(source_type);
    if (self.context_error_type_cache.get(key)) |info| return info;

    const str_sym = self.pool.intern("str") catch return error.CodegenAlloc;
    const str_type = if (self.struct_types.get(str_sym)) |info|
        info.llvm_type
    else blk: {
        // Fallback to the canonical str layout { ptr, i64 }.
        var fields = [_]c.LLVMTypeRef{
            c.LLVMPointerTypeInContext(self.context, 0),
            c.LLVMInt64TypeInContext(self.context),
        };
        break :blk c.LLVMStructTypeInContext(self.context, &fields, 2, 0);
    };

    var name_buf: [80]u8 = undefined;
    const name_z = std.fmt.bufPrintZ(&name_buf, "__with.ContextError.{x}", .{key}) catch return error.CodegenAlloc;
    const llvm_type = c.LLVMStructCreateNamed(self.context, name_z);
    var body_types = [_]c.LLVMTypeRef{ str_type, source_type };
    c.LLVMStructSetBody(llvm_type, &body_types, 2, 0);

    const info: ContextErrorInfo = .{
        .llvm_type = llvm_type,
        .source_type = source_type,
    };
    self.context_error_type_cache.put(self.allocator, key, info) catch return error.CodegenAlloc;
    return info;
}

/// Get or create a Vec[T] type for given element type.
/// Vec layout: struct { ptr: *T, len: i64, cap: i64 }
fn getOrCreateVecType(self: *Codegen, elem_type: c.LLVMTypeRef) Error!VecTypeInfo {
    const key: usize = @intFromPtr(elem_type);
    if (self.vec_type_cache.get(key)) |info| return info;

    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);

    var body_types = [_]c.LLVMTypeRef{ ptr_type, i64_type, i64_type };
    var name_buf: [64]u8 = undefined;
    const name_z = std.fmt.bufPrintZ(&name_buf, "__with.Vec.{x}", .{key}) catch return error.CodegenAlloc;
    const llvm_type = c.LLVMStructCreateNamed(self.context, name_z);
    c.LLVMStructSetBody(llvm_type, &body_types, 3, 0);

    const info = VecTypeInfo{ .llvm_type = llvm_type, .elem_type = elem_type };
    self.vec_type_cache.put(self.allocator, key, info) catch return error.CodegenAlloc;
    return info;
}

/// Check if an LLVM type is a Vec type.
fn isVecType(self: *Codegen, ty: c.LLVMTypeRef) bool {
    return self.getVecElemType(ty) != null;
}

/// Get element type for a Vec type.
fn getVecElemType(self: *Codegen, vec_type: c.LLVMTypeRef) ?c.LLVMTypeRef {
    var it = self.vec_type_cache.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == vec_type) return entry.value_ptr.elem_type;
    }
    if (c.LLVMGetTypeKind(vec_type) == c.LLVMStructTypeKind) {
        const target_name_ptr = c.LLVMGetStructName(vec_type);
        if (target_name_ptr != null) {
            const target_name = std.mem.span(target_name_ptr);
            var it2 = self.vec_type_cache.iterator();
            while (it2.next()) |entry| {
                const cached_ty = entry.value_ptr.llvm_type;
                if (c.LLVMGetTypeKind(cached_ty) != c.LLVMStructTypeKind) continue;
                const cached_name_ptr = c.LLVMGetStructName(cached_ty);
                if (cached_name_ptr == null) continue;
                const cached_name = std.mem.span(cached_name_ptr);
                if (std.mem.eql(u8, cached_name, target_name)) {
                    return entry.value_ptr.elem_type;
                }
            }
        }
    }
    return null;
}

/// Ensure realloc is declared.
fn ensureReallocDeclared(self: *Codegen) FnInfo {
    const sym = self.pool.intern("realloc") catch unreachable;
    if (self.functions.get(sym)) |fi| return fi;
    if (c.LLVMGetNamedFunction(self.module, "realloc")) |func| {
        const fi_existing: FnInfo = .{
            .value = func,
            .fn_type = c.LLVMGlobalGetValueType(func),
        };
        self.functions.put(self.allocator, sym, fi_existing) catch {};
        return fi_existing;
    }
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    var param_types = [_]c.LLVMTypeRef{ ptr_type, i64_type };
    const fn_type = c.LLVMFunctionType(ptr_type, &param_types, 2, 0);
    const func = c.LLVMAddFunction(self.module, "realloc", fn_type);
    const fi: FnInfo = .{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, sym, fi) catch {};
    return fi;
}

/// Generate Vec.new() — creates an empty Vec.
fn genVecNew(self: *Codegen, elem_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const vec_info = try self.getOrCreateVecType(elem_type);
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, vec_info.llvm_type, "vec");
    // ptr = null, len = 0, cap = 0
    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, vec_info.llvm_type, alloca, 0, "");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstNull(ptr_type), ptr_gep);
    const len_gep = c.LLVMBuildStructGEP2(self.builder, vec_info.llvm_type, alloca, 1, "");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i64_type, 0, 0), len_gep);
    const cap_gep = c.LLVMBuildStructGEP2(self.builder, vec_info.llvm_type, alloca, 2, "");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i64_type, 0, 0), cap_gep);
    return c.LLVMBuildLoad2(self.builder, vec_info.llvm_type, alloca, "vec.val");
}

/// Generate Vec.push(val) — mutates the vec in-place (requires the local's alloca).
/// This needs the alloca pointer, not the loaded value.
fn genVecPush(self: *Codegen, vec_alloca: c.LLVMValueRef, vec_type: c.LLVMTypeRef, elem_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const elem_type = self.getVecElemType(vec_type) orelse return error.UnsupportedExpr;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const cur_fn = self.current_function orelse return error.UnsupportedExpr;

    // Load len and cap
    const len_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 1, "");
    const len = c.LLVMBuildLoad2(self.builder, i64_type, len_gep, "len");
    const cap_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 2, "");
    const cap = c.LLVMBuildLoad2(self.builder, i64_type, cap_gep, "cap");

    // Check if need to grow
    const needs_grow = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, len, cap, "needs_grow");
    const grow_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "vec.grow");
    const push_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "vec.push");
    _ = c.LLVMBuildCondBr(self.builder, needs_grow, grow_bb, push_bb);

    // Grow: new_cap = max(cap * 2, 4)
    c.LLVMPositionBuilderAtEnd(self.builder, grow_bb);
    const double_cap = c.LLVMBuildMul(self.builder, cap, c.LLVMConstInt(i64_type, 2, 0), "");
    const four = c.LLVMConstInt(i64_type, 4, 0);
    const is_small = c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, double_cap, four, "");
    const new_cap = c.LLVMBuildSelect(self.builder, is_small, four, double_cap, "new_cap");
    // Compute element size
    const data_layout = c.LLVMGetModuleDataLayout(self.module);
    const elem_size_val = c.LLVMConstInt(i64_type, c.LLVMABISizeOfType(data_layout, elem_type), 0);
    const new_size = c.LLVMBuildMul(self.builder, new_cap, elem_size_val, "new_size");
    // Realloc
    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 0, "");
    const old_ptr = c.LLVMBuildLoad2(self.builder, ptr_type, ptr_gep, "old_ptr");
    const realloc_fn = self.ensureReallocDeclared();
    var realloc_args = [_]c.LLVMValueRef{ old_ptr, new_size };
    const new_ptr = c.LLVMBuildCall2(self.builder, realloc_fn.fn_type, realloc_fn.value, &realloc_args, 2, "new_ptr");
    _ = c.LLVMBuildStore(self.builder, new_ptr, ptr_gep);
    _ = c.LLVMBuildStore(self.builder, new_cap, cap_gep);
    _ = c.LLVMBuildBr(self.builder, push_bb);

    // Push: store elem at ptr[len], len++
    c.LLVMPositionBuilderAtEnd(self.builder, push_bb);
    const ptr_gep2 = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 0, "");
    const cur_ptr = c.LLVMBuildLoad2(self.builder, ptr_type, ptr_gep2, "ptr");
    const cur_len = c.LLVMBuildLoad2(self.builder, i64_type, len_gep, "cur_len");
    var gep_idx = [_]c.LLVMValueRef{cur_len};
    const elem_ptr = c.LLVMBuildGEP2(self.builder, elem_type, cur_ptr, &gep_idx, 1, "elem_ptr");
    _ = c.LLVMBuildStore(self.builder, elem_val, elem_ptr);
    const new_len = c.LLVMBuildAdd(self.builder, cur_len, c.LLVMConstInt(i64_type, 1, 0), "");
    _ = c.LLVMBuildStore(self.builder, new_len, len_gep);

    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

/// Generate Vec.len() → i64
fn genVecLen(self: *Codegen, obj_val: c.LLVMValueRef, vec_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, vec_type, "v");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);
    const len_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, alloca, 1, "");
    return c.LLVMBuildLoad2(self.builder, i64_type, len_gep, "vec.len");
}

/// Vec.contains(needle) → bool — linear scan
fn genVecContains(self: *Codegen, vec_val: c.LLVMValueRef, vec_type: c.LLVMTypeRef, needle: c.LLVMValueRef) Error!c.LLVMValueRef {
    const elem_type = self.getVecElemType(vec_type) orelse return error.UnsupportedExpr;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const i1_type = c.LLVMInt1TypeInContext(self.context);
    const function = self.current_function;

    // Store vec to access fields via GEP.
    const alloca = c.LLVMBuildAlloca(self.builder, vec_type, "vc");
    _ = c.LLVMBuildStore(self.builder, vec_val, alloca);
    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, alloca, 0, "");
    const data_ptr = c.LLVMBuildLoad2(self.builder, ptr_type, ptr_gep, "vc.ptr");
    const len_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, alloca, 1, "");
    const len = c.LLVMBuildLoad2(self.builder, i64_type, len_gep, "vc.len");

    // Loop: for i in 0..len, check elem[i] == needle.
    const entry_bb = c.LLVMGetInsertBlock(self.builder);
    const loop_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "vc.loop");
    const found_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "vc.found");
    const done_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "vc.done");

    _ = c.LLVMBuildBr(self.builder, loop_bb);

    // Loop header: i = phi(0 from entry, i+1 from loop body)
    c.LLVMPositionBuilderAtEnd(self.builder, loop_bb);
    const i_phi = c.LLVMBuildPhi(self.builder, i64_type, "vc.i");
    const cond = c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, i_phi, len, "vc.cond");

    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "vc.body");
    _ = c.LLVMBuildCondBr(self.builder, cond, body_bb, done_bb);

    // Loop body: load elem[i], compare
    c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
    var gep_idx = [_]c.LLVMValueRef{i_phi};
    const elem_ptr = c.LLVMBuildGEP2(self.builder, elem_type, data_ptr, &gep_idx, 1, "vc.ep");
    const elem = c.LLVMBuildLoad2(self.builder, elem_type, elem_ptr, "vc.el");

    const eq = if (self.isStrType(elem_type))
        try self.genStrCompare(elem, needle, .eq)
    else
        c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, elem, needle, "vc.eq");

    _ = c.LLVMBuildCondBr(self.builder, eq, found_bb, loop_bb);

    // Increment i
    const i_next = c.LLVMBuildAdd(self.builder, i_phi, c.LLVMConstInt(i64_type, 1, 0), "vc.inc");
    var phi_vals = [_]c.LLVMValueRef{ c.LLVMConstInt(i64_type, 0, 0), i_next };
    var phi_bbs = [_]c.LLVMBasicBlockRef{ entry_bb, body_bb };
    c.LLVMAddIncoming(i_phi, &phi_vals, &phi_bbs, 2);

    // Found path
    c.LLVMPositionBuilderAtEnd(self.builder, found_bb);
    _ = c.LLVMBuildBr(self.builder, done_bb);

    // Done: phi(false from loop header, true from found)
    c.LLVMPositionBuilderAtEnd(self.builder, done_bb);
    const result_phi = c.LLVMBuildPhi(self.builder, i1_type, "vc.result");
    var res_vals = [_]c.LLVMValueRef{ c.LLVMConstInt(i1_type, 0, 0), c.LLVMConstInt(i1_type, 1, 0) };
    var res_bbs = [_]c.LLVMBasicBlockRef{ loop_bb, found_bb };
    c.LLVMAddIncoming(result_phi, &res_vals, &res_bbs, 2);

    return result_phi;
}

/// Generate Vec.get(idx) → T
fn genVecGet(self: *Codegen, obj_val: c.LLVMValueRef, vec_type: c.LLVMTypeRef, idx: c.LLVMValueRef) Error!c.LLVMValueRef {
    const elem_type = self.getVecElemType(vec_type) orelse return error.UnsupportedExpr;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, vec_type, "v");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);
    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, alloca, 0, "");
    const ptr = c.LLVMBuildLoad2(self.builder, ptr_type, ptr_gep, "ptr");
    const idx_i64 = self.coerceInt(idx, i64_type);
    var gep_idx = [_]c.LLVMValueRef{idx_i64};
    const elem_ptr = c.LLVMBuildGEP2(self.builder, elem_type, ptr, &gep_idx, 1, "");
    return c.LLVMBuildLoad2(self.builder, elem_type, elem_ptr, "vec.get");
}

/// Generate Vec.set_i32(idx, val) -> Unit with bounds check.
fn genVecSetI32(self: *Codegen, vec_alloca: c.LLVMValueRef, vec_type: c.LLVMTypeRef, idx: c.LLVMValueRef, val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const elem_type = self.getVecElemType(vec_type) orelse return error.UnsupportedExpr;
    if (c.LLVMGetTypeKind(elem_type) != c.LLVMIntegerTypeKind or c.LLVMGetIntTypeWidth(elem_type) != 32) {
        return error.UnsupportedExpr;
    }

    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const idx_i64 = self.coerceInt(idx, i64_type);

    const len_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 1, "vec.set.len.gep");
    const len = c.LLVMBuildLoad2(self.builder, i64_type, len_gep, "vec.set.len");

    const ge_zero = c.LLVMBuildICmp(
        self.builder,
        c.LLVMIntSGE,
        idx_i64,
        c.LLVMConstInt(i64_type, 0, 0),
        "vec.set.ge0",
    );
    const lt_len = c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, idx_i64, len, "vec.set.ltlen");
    const in_bounds = c.LLVMBuildAnd(self.builder, ge_zero, lt_len, "vec.set.in_bounds");

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const store_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "vec.set.store");
    const done_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "vec.set.done");
    _ = c.LLVMBuildCondBr(self.builder, in_bounds, store_bb, done_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, store_bb);
    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 0, "vec.set.ptr.gep");
    const ptr = c.LLVMBuildLoad2(self.builder, ptr_type, ptr_gep, "vec.set.ptr");
    var gep_idx = [_]c.LLVMValueRef{idx_i64};
    const elem_ptr = c.LLVMBuildGEP2(self.builder, elem_type, ptr, &gep_idx, 1, "vec.set.elem.ptr");
    _ = c.LLVMBuildStore(self.builder, self.coerceInt(val, elem_type), elem_ptr);
    _ = c.LLVMBuildBr(self.builder, done_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, done_bb);
    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

/// Generate Vec.pop() → ?T
fn genVecPop(self: *Codegen, vec_alloca: c.LLVMValueRef, vec_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const elem_type = self.getVecElemType(vec_type) orelse return error.UnsupportedExpr;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const cur_fn = self.current_function orelse return error.UnsupportedExpr;

    const len_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 1, "");
    const len = c.LLVMBuildLoad2(self.builder, i64_type, len_gep, "len");
    const is_empty = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, len, c.LLVMConstInt(i64_type, 0, 0), "");

    const some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "pop.some");
    const none_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "pop.none");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "pop.merge");
    _ = c.LLVMBuildCondBr(self.builder, is_empty, none_bb, some_bb);

    // Some: decrement len, load element
    c.LLVMPositionBuilderAtEnd(self.builder, some_bb);
    const new_len = c.LLVMBuildSub(self.builder, len, c.LLVMConstInt(i64_type, 1, 0), "");
    _ = c.LLVMBuildStore(self.builder, new_len, len_gep);
    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 0, "");
    const ptr = c.LLVMBuildLoad2(self.builder, ptr_type, ptr_gep, "ptr");
    var gep_idx = [_]c.LLVMValueRef{new_len};
    const elem_ptr = c.LLVMBuildGEP2(self.builder, elem_type, ptr, &gep_idx, 1, "");
    const elem_val = c.LLVMBuildLoad2(self.builder, elem_type, elem_ptr, "elem");
    const some_val = try self.buildOptionSome(elem_val);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const some_exit = c.LLVMGetInsertBlock(self.builder);

    // None
    c.LLVMPositionBuilderAtEnd(self.builder, none_bb);
    const opt_info = try self.getOrCreateOptionType(elem_type);
    const none_val = self.buildOptionNone(opt_info.llvm_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const none_exit = c.LLVMGetInsertBlock(self.builder);

    // Merge
    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, opt_info.llvm_type, "pop.result");
    var vals = [_]c.LLVMValueRef{ some_val, none_val };
    var bbs = [_]c.LLVMBasicBlockRef{ some_exit, none_exit };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

// ---- HashMap[K,V] ----

/// Get or create a HashMap[K,V] type.
/// HashMap layout: named struct { ptr } — the ptr points to a C-allocated WithHashMap.
fn getOrCreateHashMapType(self: *Codegen, key_type: c.LLVMTypeRef, val_type: c.LLVMTypeRef) Error!HashMapTypeInfo {
    const cache_key: u64 = @intFromPtr(key_type) ^ (@as(u64, @intFromPtr(val_type)) << 1);
    if (self.hashmap_type_cache.get(cache_key)) |info| return info;

    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    var body = [_]c.LLVMTypeRef{ptr_type};
    var name_buf: [80]u8 = undefined;
    const name_z = std.fmt.bufPrintZ(&name_buf, "__with.HashMap.{x}", .{cache_key}) catch return error.CodegenAlloc;
    const llvm_type = c.LLVMStructCreateNamed(self.context, name_z);
    c.LLVMStructSetBody(llvm_type, &body, 1, 0);

    const is_str_key = self.isStrType(key_type);
    const info = HashMapTypeInfo{
        .llvm_type = llvm_type,
        .key_type = key_type,
        .val_type = val_type,
        .is_str_key = is_str_key,
    };
    self.hashmap_type_cache.put(self.allocator, cache_key, info) catch return error.CodegenAlloc;
    return info;
}

/// Check if an LLVM type is a HashMap type.
fn isHashMapType(self: *Codegen, ty: c.LLVMTypeRef) bool {
    if (c.LLVMGetTypeKind(ty) != c.LLVMStructTypeKind) return false;
    var it = self.hashmap_type_cache.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == ty) return true;
    }
    return false;
}

/// Get HashMapTypeInfo for a HashMap LLVM type.
fn getHashMapTypeInfo(self: *Codegen, ty: c.LLVMTypeRef) ?HashMapTypeInfo {
    var it = self.hashmap_type_cache.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == ty) return entry.value_ptr.*;
    }
    return null;
}

/// Ensure with_hashmap_new is declared.
fn ensureHashMapNewDeclared(self: *Codegen) FnInfo {
    const sym = self.pool.intern("with_hashmap_new") catch unreachable;
    if (self.functions.get(sym)) |fi| return fi;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    var param_types = [_]c.LLVMTypeRef{ i64_type, i64_type };
    const fn_type = c.LLVMFunctionType(ptr_type, &param_types, 2, 0);
    const func = c.LLVMAddFunction(self.module, "with_hashmap_new", fn_type);
    const fi: FnInfo = .{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, sym, fi) catch {};
    return fi;
}

/// Ensure with_hashmap_insert is declared.
fn ensureHashMapInsertDeclared(self: *Codegen) FnInfo {
    const sym = self.pool.intern("with_hashmap_insert") catch unreachable;
    if (self.functions.get(sym)) |fi| return fi;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    var param_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type, ptr_type, i64_type };
    const fn_type = c.LLVMFunctionType(c.LLVMVoidTypeInContext(self.context), &param_types, 4, 0);
    const func = c.LLVMAddFunction(self.module, "with_hashmap_insert", fn_type);
    const fi: FnInfo = .{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, sym, fi) catch {};
    return fi;
}

/// Ensure with_hashmap_get is declared.
fn ensureHashMapGetDeclared(self: *Codegen) FnInfo {
    const sym = self.pool.intern("with_hashmap_get") catch unreachable;
    if (self.functions.get(sym)) |fi| return fi;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    var param_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type, ptr_type, i64_type };
    const fn_type = c.LLVMFunctionType(i64_type, &param_types, 4, 0);
    const func = c.LLVMAddFunction(self.module, "with_hashmap_get", fn_type);
    const fi: FnInfo = .{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, sym, fi) catch {};
    return fi;
}

/// Ensure with_hashmap_contains is declared.
fn ensureHashMapContainsDeclared(self: *Codegen) FnInfo {
    const sym = self.pool.intern("with_hashmap_contains") catch unreachable;
    if (self.functions.get(sym)) |fi| return fi;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    var param_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type, i64_type };
    const fn_type = c.LLVMFunctionType(i64_type, &param_types, 3, 0);
    const func = c.LLVMAddFunction(self.module, "with_hashmap_contains", fn_type);
    const fi: FnInfo = .{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, sym, fi) catch {};
    return fi;
}

/// Ensure with_hashmap_remove is declared.
fn ensureHashMapRemoveDeclared(self: *Codegen) FnInfo {
    const sym = self.pool.intern("with_hashmap_remove") catch unreachable;
    if (self.functions.get(sym)) |fi| return fi;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    var param_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type, i64_type };
    const fn_type = c.LLVMFunctionType(i64_type, &param_types, 3, 0);
    const func = c.LLVMAddFunction(self.module, "with_hashmap_remove", fn_type);
    const fi: FnInfo = .{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, sym, fi) catch {};
    return fi;
}

/// Ensure with_hashmap_len is declared.
fn ensureHashMapLenDeclared(self: *Codegen) FnInfo {
    const sym = self.pool.intern("with_hashmap_len") catch unreachable;
    if (self.functions.get(sym)) |fi| return fi;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    var param_types = [_]c.LLVMTypeRef{ptr_type};
    const fn_type = c.LLVMFunctionType(i64_type, &param_types, 1, 0);
    const func = c.LLVMAddFunction(self.module, "with_hashmap_len", fn_type);
    const fi: FnInfo = .{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, sym, fi) catch {};
    return fi;
}

/// Generate HashMap.new() — creates a new empty HashMap.
fn genHashMapNew(self: *Codegen, key_type: c.LLVMTypeRef, val_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const hm_info = try self.getOrCreateHashMapType(key_type, val_type);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const new_info = self.ensureHashMapNewDeclared();

    // Call with_hashmap_new(key_size, val_size)
    const data_layout = c.LLVMGetModuleDataLayout(self.module);
    const key_size = c.LLVMABISizeOfType(data_layout, key_type);
    const val_size = c.LLVMABISizeOfType(data_layout, val_type);
    var call_args = [_]c.LLVMValueRef{
        c.LLVMConstInt(i64_type, key_size, 0),
        c.LLVMConstInt(i64_type, val_size, 0),
    };
    const map_ptr = c.LLVMBuildCall2(self.builder, new_info.fn_type, new_info.value, &call_args, 2, "hashmap.ptr");

    // Wrap in HashMap struct { ptr }
    const alloca = c.LLVMBuildAlloca(self.builder, hm_info.llvm_type, "hashmap");
    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, hm_info.llvm_type, alloca, 0, "");
    _ = c.LLVMBuildStore(self.builder, map_ptr, ptr_gep);
    return c.LLVMBuildLoad2(self.builder, hm_info.llvm_type, alloca, "hashmap.val");
}

/// Generate map.insert(key, val) — inserts or updates a key-value pair.
fn genHashMapInsert(self: *Codegen, map_alloca: c.LLVMValueRef, map_type: c.LLVMTypeRef, key_val: c.LLVMValueRef, val_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const hm_info = self.getHashMapTypeInfo(map_type) orelse return error.UnsupportedExpr;
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const insert_info = self.ensureHashMapInsertDeclared();

    // Extract the C map pointer from the struct
    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, map_type, map_alloca, 0, "");
    const map_ptr = c.LLVMBuildLoad2(self.builder, c.LLVMPointerTypeInContext(self.context, 0), ptr_gep, "map.ptr");

    // Store key to alloca so we can pass pointer
    const key_alloca = c.LLVMBuildAlloca(self.builder, hm_info.key_type, "key.tmp");
    _ = c.LLVMBuildStore(self.builder, key_val, key_alloca);
    // Store val to alloca
    const val_alloca = c.LLVMBuildAlloca(self.builder, hm_info.val_type, "val.tmp");
    _ = c.LLVMBuildStore(self.builder, val_val, val_alloca);

    const is_str = c.LLVMConstInt(i64_type, if (hm_info.is_str_key) 1 else 0, 0);
    var call_args = [_]c.LLVMValueRef{ map_ptr, key_alloca, val_alloca, is_str };
    _ = c.LLVMBuildCall2(self.builder, insert_info.fn_type, insert_info.value, &call_args, 4, "");
    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

/// Generate map.get(key) → Option[V].
fn genHashMapGet(self: *Codegen, map_val: c.LLVMValueRef, map_type: c.LLVMTypeRef, key_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const hm_info = self.getHashMapTypeInfo(map_type) orelse return error.UnsupportedExpr;
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const get_info = self.ensureHashMapGetDeclared();

    // Extract the C map pointer
    const map_ptr = c.LLVMBuildExtractValue(self.builder, map_val, 0, "map.ptr");

    // Store key to alloca
    const key_alloca = c.LLVMBuildAlloca(self.builder, hm_info.key_type, "key.tmp");
    _ = c.LLVMBuildStore(self.builder, key_val, key_alloca);
    // Alloca for output value
    const out_alloca = c.LLVMBuildAlloca(self.builder, hm_info.val_type, "out.tmp");

    const is_str = c.LLVMConstInt(i64_type, if (hm_info.is_str_key) 1 else 0, 0);
    var call_args = [_]c.LLVMValueRef{ map_ptr, key_alloca, out_alloca, is_str };
    const found = c.LLVMBuildCall2(self.builder, get_info.fn_type, get_info.value, &call_args, 4, "found");

    // Branch: if found==1 → Some(val), else None
    const cond = c.LLVMBuildICmp(self.builder, c.LLVMIntNE, found, c.LLVMConstInt(i64_type, 0, 0), "");
    const some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "get.some");
    const none_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "get.none");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "get.merge");
    _ = c.LLVMBuildCondBr(self.builder, cond, some_bb, none_bb);

    // Some
    c.LLVMPositionBuilderAtEnd(self.builder, some_bb);
    const val = c.LLVMBuildLoad2(self.builder, hm_info.val_type, out_alloca, "val");
    const some_val = try self.buildOptionSome(val);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const some_exit = c.LLVMGetInsertBlock(self.builder);

    // None
    c.LLVMPositionBuilderAtEnd(self.builder, none_bb);
    const opt_info = try self.getOrCreateOptionType(hm_info.val_type);
    const none_val = self.buildOptionNone(opt_info.llvm_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const none_exit = c.LLVMGetInsertBlock(self.builder);

    // Merge
    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, opt_info.llvm_type, "get.result");
    var vals = [_]c.LLVMValueRef{ some_val, none_val };
    var bbs = [_]c.LLVMBasicBlockRef{ some_exit, none_exit };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

/// Generate map.contains(key) → bool.
fn genHashMapContains(self: *Codegen, map_val: c.LLVMValueRef, map_type: c.LLVMTypeRef, key_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const hm_info = self.getHashMapTypeInfo(map_type) orelse return error.UnsupportedExpr;
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const contains_info = self.ensureHashMapContainsDeclared();

    const map_ptr = c.LLVMBuildExtractValue(self.builder, map_val, 0, "map.ptr");
    const key_alloca = c.LLVMBuildAlloca(self.builder, hm_info.key_type, "key.tmp");
    _ = c.LLVMBuildStore(self.builder, key_val, key_alloca);

    const is_str = c.LLVMConstInt(i64_type, if (hm_info.is_str_key) 1 else 0, 0);
    var call_args = [_]c.LLVMValueRef{ map_ptr, key_alloca, is_str };
    const result = c.LLVMBuildCall2(self.builder, contains_info.fn_type, contains_info.value, &call_args, 3, "contains");
    return c.LLVMBuildICmp(self.builder, c.LLVMIntNE, result, c.LLVMConstInt(i64_type, 0, 0), "contains.bool");
}

/// Generate map.remove(key) → bool.
fn genHashMapRemove(self: *Codegen, map_alloca: c.LLVMValueRef, map_type: c.LLVMTypeRef, key_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const hm_info = self.getHashMapTypeInfo(map_type) orelse return error.UnsupportedExpr;
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const remove_info = self.ensureHashMapRemoveDeclared();

    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, map_type, map_alloca, 0, "");
    const map_ptr = c.LLVMBuildLoad2(self.builder, c.LLVMPointerTypeInContext(self.context, 0), ptr_gep, "map.ptr");

    const key_alloca = c.LLVMBuildAlloca(self.builder, hm_info.key_type, "key.tmp");
    _ = c.LLVMBuildStore(self.builder, key_val, key_alloca);

    const is_str = c.LLVMConstInt(i64_type, if (hm_info.is_str_key) 1 else 0, 0);
    var call_args = [_]c.LLVMValueRef{ map_ptr, key_alloca, is_str };
    const result = c.LLVMBuildCall2(self.builder, remove_info.fn_type, remove_info.value, &call_args, 3, "removed");
    return c.LLVMBuildICmp(self.builder, c.LLVMIntNE, result, c.LLVMConstInt(i64_type, 0, 0), "removed.bool");
}

/// Generate map.len() → i64.
fn genHashMapLen(self: *Codegen, map_val: c.LLVMValueRef, map_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    _ = map_type;
    const len_info = self.ensureHashMapLenDeclared();
    const map_ptr = c.LLVMBuildExtractValue(self.builder, map_val, 0, "map.ptr");
    var call_args = [_]c.LLVMValueRef{map_ptr};
    return c.LLVMBuildCall2(self.builder, len_info.fn_type, len_info.value, &call_args, 1, "map.len");
}

/// Generate map.increment(key)/map.decrement(key) for integer-valued maps.
fn genHashMapBump(
    self: *Codegen,
    map_alloca: c.LLVMValueRef,
    map_val: c.LLVMValueRef,
    map_type: c.LLVMTypeRef,
    key_val: c.LLVMValueRef,
    delta: i64,
) Error!c.LLVMValueRef {
    const hm_info = self.getHashMapTypeInfo(map_type) orelse return error.UnsupportedExpr;
    if (c.LLVMGetTypeKind(hm_info.val_type) != c.LLVMIntegerTypeKind) return error.UnsupportedExpr;

    const opt_val = try self.genHashMapGet(map_val, map_type, key_val);
    const zero = c.LLVMConstInt(hm_info.val_type, 0, 0);
    const cur = try self.genOptionUnwrapOr(opt_val, c.LLVMTypeOf(opt_val), zero);

    const magnitude: u64 = @intCast(if (delta < 0) 0 - delta else delta);
    const step = c.LLVMConstInt(hm_info.val_type, magnitude, 0);
    const next = if (delta < 0)
        c.LLVMBuildSub(self.builder, cur, step, "map.bump")
    else
        c.LLVMBuildAdd(self.builder, cur, step, "map.bump");

    _ = try self.genHashMapInsert(map_alloca, map_type, key_val, next);
    return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
}

/// Generate map.update(key, default, f): if key exists, set f(current); else set default.
fn genHashMapUpdate(
    self: *Codegen,
    map_alloca: c.LLVMValueRef,
    map_val: c.LLVMValueRef,
    map_type: c.LLVMTypeRef,
    key_val: c.LLVMValueRef,
    default_val: c.LLVMValueRef,
    fn_val: c.LLVMValueRef,
) Error!c.LLVMValueRef {
    const hm_info = self.getHashMapTypeInfo(map_type) orelse return error.UnsupportedExpr;
    const cur_fn = self.current_function orelse return error.UnsupportedExpr;

    const opt_val = try self.genHashMapGet(map_val, map_type, key_val);
    const opt_type = c.LLVMTypeOf(opt_val);
    const has_value = try self.genOptionIsSome(opt_val, opt_type);

    const some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "map.update.some");
    const none_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "map.update.none");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "map.update.merge");
    _ = c.LLVMBuildCondBr(self.builder, has_value, some_bb, none_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, some_bb);
    const cur = try self.genOptionUnwrap(opt_val, opt_type, null);
    const mapped = try self.callFnValueWithArg(fn_val, cur);
    const mapped_coerced = self.coerceInt(mapped, hm_info.val_type);
    _ = try self.genHashMapInsert(map_alloca, map_type, key_val, mapped_coerced);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, none_bb);
    const default_coerced = self.coerceInt(default_val, hm_info.val_type);
    _ = try self.genHashMapInsert(map_alloca, map_type, key_val, default_coerced);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
}

/// Generate map.append(key, value) for HashMap[K, Vec[T]].
fn genHashMapAppend(
    self: *Codegen,
    map_alloca: c.LLVMValueRef,
    map_val: c.LLVMValueRef,
    map_type: c.LLVMTypeRef,
    key_val: c.LLVMValueRef,
    elem_val: c.LLVMValueRef,
) Error!c.LLVMValueRef {
    const hm_info = self.getHashMapTypeInfo(map_type) orelse return error.UnsupportedExpr;
    if (!self.isVecType(hm_info.val_type)) return error.UnsupportedExpr;
    const vec_elem_type = self.getVecElemType(hm_info.val_type) orelse return error.UnsupportedExpr;

    const opt_val = try self.genHashMapGet(map_val, map_type, key_val);
    const empty_vec = try self.genVecNew(vec_elem_type);
    const cur_vec = try self.genOptionUnwrapOr(opt_val, c.LLVMTypeOf(opt_val), empty_vec);

    const vec_alloca = c.LLVMBuildAlloca(self.builder, hm_info.val_type, "map.append.vec");
    _ = c.LLVMBuildStore(self.builder, cur_vec, vec_alloca);
    const coerced_elem = self.coerceInt(elem_val, vec_elem_type);
    _ = try self.genVecPush(vec_alloca, hm_info.val_type, coerced_elem);
    const next_vec = c.LLVMBuildLoad2(self.builder, hm_info.val_type, vec_alloca, "map.append.next");

    _ = try self.genHashMapInsert(map_alloca, map_type, key_val, next_vec);
    return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
}

// ---- HashSet[T] ----

/// Get or create a HashSet[T] type. Internally it's a HashMap[T, i8].
fn getOrCreateHashSetType(self: *Codegen, elem_type: c.LLVMTypeRef) Error!HashSetTypeInfo {
    const key: usize = @intFromPtr(elem_type);
    if (self.hashset_type_cache.get(key)) |info| return info;

    // Create underlying HashMap[T, i8]
    const i8_type = c.LLVMInt8TypeInContext(self.context);
    const hm_info = try self.getOrCreateHashMapType(elem_type, i8_type);

    // HashSet uses a distinct named struct so isHashSetType can distinguish it
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    var body = [_]c.LLVMTypeRef{ptr_type};
    var name_buf: [80]u8 = undefined;
    const name_z = std.fmt.bufPrintZ(&name_buf, "__with.HashSet.{x}", .{key}) catch return error.CodegenAlloc;
    const llvm_type = c.LLVMStructCreateNamed(self.context, name_z);
    c.LLVMStructSetBody(llvm_type, &body, 1, 0);

    const info = HashSetTypeInfo{
        .llvm_type = llvm_type,
        .elem_type = elem_type,
        .hm_info = hm_info,
    };
    self.hashset_type_cache.put(self.allocator, key, info) catch return error.CodegenAlloc;
    return info;
}

/// Check if an LLVM type is a HashSet type.
fn isHashSetType(self: *Codegen, ty: c.LLVMTypeRef) bool {
    if (c.LLVMGetTypeKind(ty) != c.LLVMStructTypeKind) return false;
    var it = self.hashset_type_cache.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == ty) return true;
    }
    return false;
}

/// Get HashSetTypeInfo for a HashSet LLVM type.
fn getHashSetTypeInfo(self: *Codegen, ty: c.LLVMTypeRef) ?HashSetTypeInfo {
    var it = self.hashset_type_cache.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == ty) return entry.value_ptr.*;
    }
    return null;
}

/// Generate HashSet.new() — creates a new empty set.
fn genHashSetNew(self: *Codegen, elem_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const hs_info = try self.getOrCreateHashSetType(elem_type);
    const i8_type = c.LLVMInt8TypeInContext(self.context);
    // Reuse HashMap.new with i8 as value type
    const hm_val = try self.genHashMapNew(elem_type, i8_type);

    // Extract ptr from HashMap struct and wrap in HashSet struct
    const map_ptr = c.LLVMBuildExtractValue(self.builder, hm_val, 0, "map.ptr");
    const alloca = c.LLVMBuildAlloca(self.builder, hs_info.llvm_type, "hashset");
    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, hs_info.llvm_type, alloca, 0, "");
    _ = c.LLVMBuildStore(self.builder, map_ptr, ptr_gep);
    return c.LLVMBuildLoad2(self.builder, hs_info.llvm_type, alloca, "hashset.val");
}

/// Generate set.insert(val) — adds an element.
fn genHashSetInsert(self: *Codegen, set_alloca: c.LLVMValueRef, set_type: c.LLVMTypeRef, elem_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const hs_info = self.getHashSetTypeInfo(set_type) orelse return error.UnsupportedExpr;
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const i8_type = c.LLVMInt8TypeInContext(self.context);
    const insert_info = self.ensureHashMapInsertDeclared();

    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, set_type, set_alloca, 0, "");
    const map_ptr = c.LLVMBuildLoad2(self.builder, c.LLVMPointerTypeInContext(self.context, 0), ptr_gep, "set.ptr");

    const key_alloca = c.LLVMBuildAlloca(self.builder, hs_info.elem_type, "key.tmp");
    _ = c.LLVMBuildStore(self.builder, elem_val, key_alloca);
    const val_alloca = c.LLVMBuildAlloca(self.builder, i8_type, "dummy.tmp");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i8_type, 1, 0), val_alloca);

    const is_str = c.LLVMConstInt(i64_type, if (hs_info.hm_info.is_str_key) 1 else 0, 0);
    var call_args = [_]c.LLVMValueRef{ map_ptr, key_alloca, val_alloca, is_str };
    _ = c.LLVMBuildCall2(self.builder, insert_info.fn_type, insert_info.value, &call_args, 4, "");
    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

/// Generate set.contains(val) → bool.
fn genHashSetContains(self: *Codegen, set_val: c.LLVMValueRef, set_type: c.LLVMTypeRef, elem_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const hs_info = self.getHashSetTypeInfo(set_type) orelse return error.UnsupportedExpr;
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const contains_info = self.ensureHashMapContainsDeclared();

    const map_ptr = c.LLVMBuildExtractValue(self.builder, set_val, 0, "set.ptr");
    const key_alloca = c.LLVMBuildAlloca(self.builder, hs_info.elem_type, "key.tmp");
    _ = c.LLVMBuildStore(self.builder, elem_val, key_alloca);

    const is_str = c.LLVMConstInt(i64_type, if (hs_info.hm_info.is_str_key) 1 else 0, 0);
    var call_args = [_]c.LLVMValueRef{ map_ptr, key_alloca, is_str };
    const result = c.LLVMBuildCall2(self.builder, contains_info.fn_type, contains_info.value, &call_args, 3, "contains");
    return c.LLVMBuildICmp(self.builder, c.LLVMIntNE, result, c.LLVMConstInt(i64_type, 0, 0), "contains.bool");
}

/// Generate set.remove(val) → bool.
fn genHashSetRemove(self: *Codegen, set_alloca: c.LLVMValueRef, set_type: c.LLVMTypeRef, elem_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const hs_info = self.getHashSetTypeInfo(set_type) orelse return error.UnsupportedExpr;
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const remove_info = self.ensureHashMapRemoveDeclared();

    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, set_type, set_alloca, 0, "");
    const map_ptr = c.LLVMBuildLoad2(self.builder, c.LLVMPointerTypeInContext(self.context, 0), ptr_gep, "set.ptr");

    const key_alloca = c.LLVMBuildAlloca(self.builder, hs_info.elem_type, "key.tmp");
    _ = c.LLVMBuildStore(self.builder, elem_val, key_alloca);

    const is_str = c.LLVMConstInt(i64_type, if (hs_info.hm_info.is_str_key) 1 else 0, 0);
    var call_args = [_]c.LLVMValueRef{ map_ptr, key_alloca, is_str };
    const result = c.LLVMBuildCall2(self.builder, remove_info.fn_type, remove_info.value, &call_args, 3, "removed");
    return c.LLVMBuildICmp(self.builder, c.LLVMIntNE, result, c.LLVMConstInt(i64_type, 0, 0), "removed.bool");
}

/// Generate set.len() → i64.
fn genHashSetLen(self: *Codegen, set_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const len_info = self.ensureHashMapLenDeclared();
    const map_ptr = c.LLVMBuildExtractValue(self.builder, set_val, 0, "set.ptr");
    var call_args = [_]c.LLVMValueRef{map_ptr};
    return c.LLVMBuildCall2(self.builder, len_info.fn_type, len_info.value, &call_args, 1, "set.len");
}

/// Build an Option Some value: { tag: 0, payload: val }.
fn buildOptionSome(self: *Codegen, val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const payload_type = c.LLVMTypeOf(val);
    const opt_info = try self.getOrCreateOptionType(payload_type);
    const i32_type = c.LLVMInt32TypeInContext(self.context);

    const alloca = c.LLVMBuildAlloca(self.builder, opt_info.llvm_type, "some");
    // Zero-init to avoid poison in padding bytes.
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstNull(opt_info.llvm_type), alloca);
    const tag_gep = c.LLVMBuildStructGEP2(self.builder, opt_info.llvm_type, alloca, 0, "");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i32_type, 0, 0), tag_gep);
    const payload_gep = c.LLVMBuildStructGEP2(self.builder, opt_info.llvm_type, alloca, 1, "");
    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    _ = c.LLVMBuildStore(self.builder, val, payload_ptr);

    return c.LLVMBuildLoad2(self.builder, opt_info.llvm_type, alloca, "some.val");
}

/// Build an Option None value: { tag: 1, payload: zeroinit }.
/// Build the default value for a type that implements Default.
/// Returns the zero/default value for the given LLVM type.
fn buildDefaultValue(_: *Codegen, ret_type: c.LLVMTypeRef) c.LLVMValueRef {
    const kind = c.LLVMGetTypeKind(ret_type);
    return switch (kind) {
        c.LLVMIntegerTypeKind => c.LLVMConstInt(ret_type, 0, 0),
        c.LLVMFloatTypeKind, c.LLVMDoubleTypeKind => c.LLVMConstReal(ret_type, 0.0),
        else => c.LLVMConstNull(ret_type),
    };
}

fn buildOptionNone(self: *Codegen, opt_llvm_type: c.LLVMTypeRef) c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, opt_llvm_type, "none");
    // Zero-init so payload bytes are defined.
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstNull(opt_llvm_type), alloca);
    const tag_gep = c.LLVMBuildStructGEP2(self.builder, opt_llvm_type, alloca, 0, "");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i32_type, 1, 0), tag_gep);
    return c.LLVMBuildLoad2(self.builder, opt_llvm_type, alloca, "none.val");
}

/// Build a Result Ok value: { tag: 0, payload: val }.
fn buildResultOk(self: *Codegen, val: c.LLVMValueRef, result_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, result_type, "ok");
    // Zero-init to avoid poison in unused payload bytes.
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstNull(result_type), alloca);
    const tag_gep = c.LLVMBuildStructGEP2(self.builder, result_type, alloca, 0, "");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i32_type, 0, 0), tag_gep);
    const payload_gep = c.LLVMBuildStructGEP2(self.builder, result_type, alloca, 1, "");
    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    _ = c.LLVMBuildStore(self.builder, val, payload_ptr);
    return c.LLVMBuildLoad2(self.builder, result_type, alloca, "ok.val");
}

/// Build a Result Err value: { tag: 1, payload: val }.
fn buildResultErr(self: *Codegen, val: c.LLVMValueRef, result_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, result_type, "err");
    // Zero-init to avoid poison in unused payload bytes.
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstNull(result_type), alloca);
    const tag_gep = c.LLVMBuildStructGEP2(self.builder, result_type, alloca, 0, "");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i32_type, 1, 0), tag_gep);
    const payload_gep = c.LLVMBuildStructGEP2(self.builder, result_type, alloca, 1, "");
    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    _ = c.LLVMBuildStore(self.builder, val, payload_ptr);
    return c.LLVMBuildLoad2(self.builder, result_type, alloca, "err.val");
}

/// Check if an LLVM struct type is an Option or Result type.
/// These have the layout { i32 tag, [N x i8] payload }.
fn isOptionOrResultType(self: *Codegen, ty: c.LLVMTypeRef) bool {
    if (c.LLVMGetTypeKind(ty) != c.LLVMStructTypeKind) return false;
    const num_elements = c.LLVMCountStructElementTypes(ty);
    if (num_elements != 2) return false;
    // First element should be i32 (tag).
    const first = c.LLVMStructGetTypeAtIndex(ty, 0);
    if (first != c.LLVMInt32TypeInContext(self.context)) return false;
    // Second element should be an array type (payload storage).
    const second = c.LLVMStructGetTypeAtIndex(ty, 1);
    return c.LLVMGetTypeKind(second) == c.LLVMArrayTypeKind;
}

/// Get the payload type from an Option/Result type.
/// Searches the option_type_cache for the type.
fn getOptionPayloadType(self: *Codegen, opt_type: c.LLVMTypeRef) ?c.LLVMTypeRef {
    var it = self.option_type_cache.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == opt_type or self.sameStructTypeName(entry.value_ptr.llvm_type, opt_type)) {
            return entry.value_ptr.payload_type;
        }
    }
    // Check result cache too.
    var it2 = self.result_type_cache.iterator();
    while (it2.next()) |entry| {
        if (entry.value_ptr.llvm_type == opt_type or self.sameStructTypeName(entry.value_ptr.llvm_type, opt_type)) {
            return entry.value_ptr.payload_type;
        }
    }
    // Fallback: scan enum type registry (needed for some nested Option shapes).
    var it3 = self.enum_types.iterator();
    while (it3.next()) |entry| {
        if (entry.value_ptr.llvm_type == opt_type and entry.value_ptr.variant_payload_types.len > 0) {
            return entry.value_ptr.variant_payload_types[0];
        }
    }
    return null;
}

/// Generate Option.unwrap() — returns payload or aborts.
fn genOptionUnwrap(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef, _: ?c.LLVMValueRef) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);

    // Store the value to memory so we can GEP it.
    const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "opt");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);

    // Load tag.
    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");

    // Check tag == 0 (Some/Ok).
    const is_some = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "is_some");

    // Branch: if not Some, terminate with a non-zero code.
    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "unwrap.some");
    const abort_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "unwrap.abort");
    _ = c.LLVMBuildCondBr(self.builder, is_some, some_bb, abort_bb);

    // Failure block: _exit(134).
    c.LLVMPositionBuilderAtEnd(self.builder, abort_bb);
    const exit_info = try self.ensureExitDeclared();
    var exit_args = [_]c.LLVMValueRef{c.LLVMConstInt(i32_type, 134, 0)};
    _ = c.LLVMBuildCall2(self.builder, exit_info.fn_type, exit_info.value, &exit_args, 1, "");
    _ = c.LLVMBuildUnreachable(self.builder);

    // Some block: extract payload.
    c.LLVMPositionBuilderAtEnd(self.builder, some_bb);
    const payload_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "payload");

    // Get payload type.
    const payload_type = self.getOptionPayloadType(obj_type) orelse i32_type;
    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    return c.LLVMBuildLoad2(self.builder, payload_type, payload_ptr, "unwrap.val");
}

/// Generate Option.unwrap_or(default) — returns payload or default value.
fn genOptionUnwrapOr(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef, default_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);

    const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "opt");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);

    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
    const is_some = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "is_some");

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "unwrap_or.some");
    const none_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "unwrap_or.none");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "unwrap_or.merge");
    _ = c.LLVMBuildCondBr(self.builder, is_some, some_bb, none_bb);

    // Some: extract payload.
    c.LLVMPositionBuilderAtEnd(self.builder, some_bb);
    const payload_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "payload");
    const payload_type = self.getOptionPayloadType(obj_type) orelse i32_type;
    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const some_val = c.LLVMBuildLoad2(self.builder, payload_type, payload_ptr, "some.val");
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // None: use default.
    c.LLVMPositionBuilderAtEnd(self.builder, none_bb);
    const coerced_default = self.coerceInt(default_val, payload_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Merge with phi.
    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, payload_type, "unwrap_or.result");
    var vals = [_]c.LLVMValueRef{ some_val, coerced_default };
    var bbs = [_]c.LLVMBasicBlockRef{ some_bb, none_bb };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

/// Generate Option.is_some() — returns true if tag == 0.
fn genOptionIsSome(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "opt");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);
    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
    return c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "is_some");
}

/// Generate Option.is_none() — returns true if tag != 0.
fn genOptionIsNone(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "opt");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);
    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
    return c.LLVMBuildICmp(self.builder, c.LLVMIntNE, tag, c.LLVMConstInt(i32_type, 0, 0), "is_none");
}

/// Helper: call a function value (either raw fn pointer or closure fat pointer) with one argument.
/// Returns the call result.
fn callFnValueWithArg(self: *Codegen, fn_val: c.LLVMValueRef, arg: c.LLVMValueRef) Error!c.LLVMValueRef {
    return self.callFnValueWithArgHinted(fn_val, arg, null);
}

fn callFnValueWithArgHinted(self: *Codegen, fn_val: c.LLVMValueRef, arg: c.LLVMValueRef, ret_type_hint: ?c.LLVMTypeRef) Error!c.LLVMValueRef {
    const fn_val_type = c.LLVMTypeOf(fn_val);
    const kind = c.LLVMGetTypeKind(fn_val_type);

    if (kind == c.LLVMPointerTypeKind) {
        // Raw function pointer — need to figure out the function type.
        // Try to get it as a function value (global).
        const val_kind = c.LLVMGetValueKind(fn_val);
        if (val_kind == c.LLVMFunctionValueKind) {
            const fn_type = c.LLVMGlobalGetValueType(fn_val);
            const ret_type = c.LLVMGetReturnType(fn_type);
            var args_buf = [_]c.LLVMValueRef{arg};
            // Coerce argument to the parameter type.
            const param_count = c.LLVMCountParamTypes(fn_type);
            if (param_count >= 1) {
                var param_types: [1]c.LLVMTypeRef = undefined;
                c.LLVMGetParamTypes(fn_type, &param_types);
                args_buf[0] = self.coerceInt(arg, param_types[0]);
            }
            const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
            return c.LLVMBuildCall2(self.builder, fn_type, fn_val, &args_buf, 1, if (is_void) "" else "map.call");
        }
        // Pointer to function type (e.g. fn parameter/local): use declared signature.
        const pointee_type = c.LLVMGetElementType(fn_val_type);
        if (c.LLVMGetTypeKind(pointee_type) == c.LLVMFunctionTypeKind and c.LLVMCountParamTypes(pointee_type) == 1) {
            var param_types: [1]c.LLVMTypeRef = undefined;
            c.LLVMGetParamTypes(pointee_type, &param_types);
            var args_buf = [_]c.LLVMValueRef{self.coerceInt(arg, param_types[0])};
            const ret_type = c.LLVMGetReturnType(pointee_type);
            const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
            return c.LLVMBuildCall2(self.builder, pointee_type, fn_val, &args_buf, 1, if (is_void) "" else "map.call");
        }
        // Fallback: use hint or infer signature as fn(arg_type) -> arg_type.
        const arg_type = c.LLVMTypeOf(arg);
        const fallback_ret = ret_type_hint orelse arg_type;
        var param_types = [_]c.LLVMTypeRef{arg_type};
        const fn_type = c.LLVMFunctionType(fallback_ret, &param_types, 1, 0);
        var args_buf = [_]c.LLVMValueRef{arg};
        const is_void = fallback_ret == c.LLVMVoidTypeInContext(self.context);
        return c.LLVMBuildCall2(self.builder, fn_type, fn_val, &args_buf, 1, if (is_void) "" else "map.call");
    } else if (kind == c.LLVMStructTypeKind) {
        // Fat pointer: { fn_ptr, capture_ptr }.
        const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
        const fn_ptr = c.LLVMBuildExtractValue(self.builder, fn_val, 0, "fn_ptr");
        const cap_ptr = c.LLVMBuildExtractValue(self.builder, fn_val, 1, "cap_ptr");

        // The closure fn signature is: fn(capture_ptr, arg) -> ret.
        // We need to figure out the function type. Check if it's a known function.
        const val_kind = c.LLVMGetValueKind(fn_ptr);
        if (val_kind == c.LLVMFunctionValueKind) {
            const fn_type = c.LLVMGlobalGetValueType(fn_ptr);
            const ret_type = c.LLVMGetReturnType(fn_type);
            var args_buf = [_]c.LLVMValueRef{ cap_ptr, arg };
            const param_count = c.LLVMCountParamTypes(fn_type);
            if (param_count >= 2) {
                var param_types: [2]c.LLVMTypeRef = undefined;
                c.LLVMGetParamTypes(fn_type, &param_types);
                args_buf[1] = self.coerceInt(arg, param_types[1]);
            }
            const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
            return c.LLVMBuildCall2(self.builder, fn_type, fn_ptr, &args_buf, 2, if (is_void) "" else "map.call");
        }

        // Fallback: use hint or infer signature as fn(ptr, arg_type) -> arg_type.
        const arg_type = c.LLVMTypeOf(arg);
        const fallback_ret = ret_type_hint orelse arg_type;
        var param_types = [_]c.LLVMTypeRef{ ptr_type, arg_type };
        const fn_type = c.LLVMFunctionType(fallback_ret, &param_types, 2, 0);
        var args_buf = [_]c.LLVMValueRef{ cap_ptr, arg };
        const is_void = fallback_ret == c.LLVMVoidTypeInContext(self.context);
        return c.LLVMBuildCall2(self.builder, fn_type, fn_ptr, &args_buf, 2, if (is_void) "" else "map.call");
    }

    return error.UnsupportedExpr;
}

/// Helper: call a function value (raw fn pointer or closure fat pointer) with no arguments.
fn callFnValueNoArgs(self: *Codegen, fn_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    return self.callFnValueNoArgsHinted(fn_val, null);
}

fn callFnValueNoArgsHinted(self: *Codegen, fn_val: c.LLVMValueRef, ret_type_hint: ?c.LLVMTypeRef) Error!c.LLVMValueRef {
    const fn_val_type = c.LLVMTypeOf(fn_val);
    const kind = c.LLVMGetTypeKind(fn_val_type);

    if (kind == c.LLVMPointerTypeKind) {
        const val_kind = c.LLVMGetValueKind(fn_val);
        if (val_kind == c.LLVMFunctionValueKind) {
            const fn_type = c.LLVMGlobalGetValueType(fn_val);
            const ret_type = c.LLVMGetReturnType(fn_type);
            const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
            return c.LLVMBuildCall2(self.builder, fn_type, fn_val, null, 0, if (is_void) "" else "call0");
        }
        // Fallback with hint: construct fn() -> ret_type.
        if (ret_type_hint) |hint| {
            const fn_type = c.LLVMFunctionType(hint, null, 0, 0);
            const is_void = hint == c.LLVMVoidTypeInContext(self.context);
            return c.LLVMBuildCall2(self.builder, fn_type, fn_val, null, 0, if (is_void) "" else "call0");
        }
        return error.UnsupportedExpr;
    } else if (kind == c.LLVMStructTypeKind) {
        // Closure fat pointer: { fn_ptr, capture_ptr }.
        const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
        const fn_ptr = c.LLVMBuildExtractValue(self.builder, fn_val, 0, "fn_ptr");
        const cap_ptr = c.LLVMBuildExtractValue(self.builder, fn_val, 1, "cap_ptr");

        const val_kind = c.LLVMGetValueKind(fn_ptr);
        if (val_kind == c.LLVMFunctionValueKind) {
            const fn_type = c.LLVMGlobalGetValueType(fn_ptr);
            const ret_type = c.LLVMGetReturnType(fn_type);
            if (c.LLVMCountParamTypes(fn_type) < 1) return error.UnsupportedExpr;
            var args_buf = [_]c.LLVMValueRef{cap_ptr};
            const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
            return c.LLVMBuildCall2(self.builder, fn_type, fn_ptr, &args_buf, 1, if (is_void) "" else "call0");
        }
        // Fallback with hint: construct fn(ptr) -> ret_type.
        if (ret_type_hint) |hint| {
            var param_types = [_]c.LLVMTypeRef{ptr_type};
            const fn_type = c.LLVMFunctionType(hint, &param_types, 1, 0);
            var args_buf = [_]c.LLVMValueRef{cap_ptr};
            const is_void = hint == c.LLVMVoidTypeInContext(self.context);
            return c.LLVMBuildCall2(self.builder, fn_type, fn_ptr, &args_buf, 1, if (is_void) "" else "call0");
        }
        return error.UnsupportedExpr;
    }

    return error.UnsupportedExpr;
}

/// Infer return type of a unary callable (fn(T)->U or closure form).
fn inferUnaryFnReturnType(self: *Codegen, fn_val: c.LLVMValueRef) ?c.LLVMTypeRef {
    const fn_val_type = c.LLVMTypeOf(fn_val);
    const kind = c.LLVMGetTypeKind(fn_val_type);

    if (kind == c.LLVMPointerTypeKind) {
        const val_kind = c.LLVMGetValueKind(fn_val);
        if (val_kind == c.LLVMFunctionValueKind) {
            const fn_type = c.LLVMGlobalGetValueType(fn_val);
            if (c.LLVMCountParamTypes(fn_type) != 1) return null;
            return c.LLVMGetReturnType(fn_type);
        }
        const elem_type = c.LLVMGetElementType(fn_val_type);
        if (c.LLVMGetTypeKind(elem_type) == c.LLVMFunctionTypeKind) {
            if (c.LLVMCountParamTypes(elem_type) != 1) return null;
            return c.LLVMGetReturnType(elem_type);
        }
        return null;
    }

    if (kind == c.LLVMStructTypeKind) {
        const fn_ptr = c.LLVMBuildExtractValue(self.builder, fn_val, 0, "fn_ptr.type");
        const fn_ptr_type = c.LLVMTypeOf(fn_ptr);
        if (c.LLVMGetTypeKind(fn_ptr_type) != c.LLVMPointerTypeKind) return null;
        const elem_type = c.LLVMGetElementType(fn_ptr_type);
        if (c.LLVMGetTypeKind(elem_type) != c.LLVMFunctionTypeKind) return null;
        // Closure ABI is fn(ctx_ptr, arg) -> ret.
        if (c.LLVMCountParamTypes(elem_type) < 2) return null;
        return c.LLVMGetReturnType(elem_type);
    }

    return null;
}

/// Generate Option.map(f) — if Some(x), return Some(f(x)); if None, return None.
fn genOptionMap(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef, fn_arg: *const Ast.Expr) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "opt");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);

    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
    const is_some = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "is_some");

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "map.some");
    const none_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "map.none");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "map.merge");
    _ = c.LLVMBuildCondBr(self.builder, is_some, some_bb, none_bb);

    // Some: extract payload, call f(payload), wrap in Some.
    c.LLVMPositionBuilderAtEnd(self.builder, some_bb);
    const payload_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "payload");
    const payload_type = self.getOptionPayloadType(obj_type) orelse i32_type;
    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const payload_val = c.LLVMBuildLoad2(self.builder, payload_type, payload_ptr, "payload.val");

    const fn_val = try self.genExpr(fn_arg);
    const mapped_val = try self.callFnValueWithArg(fn_val, payload_val);
    const some_result = try self.buildOptionSome(mapped_val);
    const some_result_type = c.LLVMTypeOf(some_result);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const some_end_bb = c.LLVMGetInsertBlock(self.builder);

    // None: return None of the new type.
    c.LLVMPositionBuilderAtEnd(self.builder, none_bb);
    const none_result = self.buildOptionNone(some_result_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Merge.
    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, some_result_type, "map.result");
    var vals = [_]c.LLVMValueRef{ some_result, none_result };
    var bbs = [_]c.LLVMBasicBlockRef{ some_end_bb, none_bb };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

/// Generate Option.and_then(f) — if Some(x), return f(x); if None, return None.
/// f must return Option[U].
fn genOptionAndThen(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef, fn_arg: *const Ast.Expr) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "opt");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);

    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
    const is_some = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "is_some");

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "andthen.some");
    const none_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "andthen.none");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "andthen.merge");
    _ = c.LLVMBuildCondBr(self.builder, is_some, some_bb, none_bb);

    // Some: extract payload, call f(payload) — returns Option[U] directly.
    c.LLVMPositionBuilderAtEnd(self.builder, some_bb);
    const payload_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "payload");
    const payload_type = self.getOptionPayloadType(obj_type) orelse i32_type;
    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const payload_val = c.LLVMBuildLoad2(self.builder, payload_type, payload_ptr, "payload.val");

    const fn_val = try self.genExpr(fn_arg);
    // f returns Option[U] directly; use obj_type as hint (same Option layout).
    const some_result = try self.callFnValueWithArgHinted(fn_val, payload_val, obj_type);
    const result_type = c.LLVMTypeOf(some_result);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const some_end_bb = c.LLVMGetInsertBlock(self.builder);

    // None: return None of result type.
    c.LLVMPositionBuilderAtEnd(self.builder, none_bb);
    const none_result = self.buildOptionNone(result_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Merge.
    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, result_type, "andthen.result");
    var vals = [_]c.LLVMValueRef{ some_result, none_result };
    var bbs = [_]c.LLVMBasicBlockRef{ some_end_bb, none_bb };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

/// Generate Option.filter(f) — if Some(x) and f(x) is true, return Some(x); else None.
fn genOptionFilter(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef, fn_arg: *const Ast.Expr) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "opt");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);

    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
    const is_some = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "is_some");

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "filter.some");
    const none_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "filter.none");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "filter.merge");
    _ = c.LLVMBuildCondBr(self.builder, is_some, some_bb, none_bb);

    // Some: extract payload, call f(payload), check bool result.
    c.LLVMPositionBuilderAtEnd(self.builder, some_bb);
    const payload_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "payload");
    const payload_type = self.getOptionPayloadType(obj_type) orelse i32_type;
    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const payload_val = c.LLVMBuildLoad2(self.builder, payload_type, payload_ptr, "payload.val");

    const fn_val = try self.genExpr(fn_arg);
    const pred_result = try self.callFnValueWithArg(fn_val, payload_val);
    const pred_bool = self.coerceToBool(pred_result);

    const keep_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "filter.keep");
    const drop_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "filter.drop");
    _ = c.LLVMBuildCondBr(self.builder, pred_bool, keep_bb, drop_bb);

    // Keep: return original Some value.
    c.LLVMPositionBuilderAtEnd(self.builder, keep_bb);
    const kept = c.LLVMBuildLoad2(self.builder, obj_type, alloca, "kept");
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Drop: return None.
    c.LLVMPositionBuilderAtEnd(self.builder, drop_bb);
    const dropped = self.buildOptionNone(obj_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // None: return None.
    c.LLVMPositionBuilderAtEnd(self.builder, none_bb);
    const none_result = self.buildOptionNone(obj_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Merge: phi with three predecessors.
    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, obj_type, "filter.result");
    var vals = [_]c.LLVMValueRef{ kept, dropped, none_result };
    var bbs = [_]c.LLVMBasicBlockRef{ keep_bb, drop_bb, none_bb };
    c.LLVMAddIncoming(phi, &vals, &bbs, 3);
    return phi;
}

/// Generate Option.or_else(f) — if Some(x), return Some(x); else return f().
fn genOptionOrElse(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef, fn_arg: *const Ast.Expr) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "opt");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);

    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
    const is_some = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "is_some");

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "orelse.some");
    const none_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "orelse.none");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "orelse.merge");
    _ = c.LLVMBuildCondBr(self.builder, is_some, some_bb, none_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, some_bb);
    const some_result = obj_val;
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const some_end_bb = c.LLVMGetInsertBlock(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, none_bb);
    const fn_val = try self.genExpr(fn_arg);
    // f() returns Option[T] (same as obj_type); pass hint.
    const fallback = try self.callFnValueNoArgsHinted(fn_val, obj_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const none_end_bb = c.LLVMGetInsertBlock(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, obj_type, "orelse.result");
    var vals = [_]c.LLVMValueRef{ some_result, fallback };
    var bbs = [_]c.LLVMBasicBlockRef{ some_end_bb, none_end_bb };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

/// Generate Option.zip(other) — Some((a,b)) when both are Some, else None.
fn genOptionZip(
    self: *Codegen,
    lhs_val: c.LLVMValueRef,
    lhs_type: c.LLVMTypeRef,
    rhs_val: c.LLVMValueRef,
    rhs_type: c.LLVMTypeRef,
) Error!c.LLVMValueRef {
    if (!self.isOptionType(lhs_type) or !self.isOptionType(rhs_type)) return error.UnsupportedExpr;
    const lhs_payload_type = self.getOptionPayloadType(lhs_type) orelse return error.UnsupportedExpr;
    const rhs_payload_type = self.getOptionPayloadType(rhs_type) orelse return error.UnsupportedExpr;

    var tuple_fields = [_]c.LLVMTypeRef{ lhs_payload_type, rhs_payload_type };
    const tuple_type = c.LLVMStructTypeInContext(self.context, &tuple_fields, 2, 0);
    const tuple_opt_info = try self.getOrCreateOptionType(tuple_type);
    const out_type = tuple_opt_info.llvm_type;

    const i32_type = c.LLVMInt32TypeInContext(self.context);

    const lhs_alloca = c.LLVMBuildAlloca(self.builder, lhs_type, "zip.lhs");
    const rhs_alloca = c.LLVMBuildAlloca(self.builder, rhs_type, "zip.rhs");
    _ = c.LLVMBuildStore(self.builder, lhs_val, lhs_alloca);
    _ = c.LLVMBuildStore(self.builder, rhs_val, rhs_alloca);

    const lhs_tag_gep = c.LLVMBuildStructGEP2(self.builder, lhs_type, lhs_alloca, 0, "tag");
    const rhs_tag_gep = c.LLVMBuildStructGEP2(self.builder, rhs_type, rhs_alloca, 0, "tag");
    const lhs_tag = c.LLVMBuildLoad2(self.builder, i32_type, lhs_tag_gep, "tag.val");
    const rhs_tag = c.LLVMBuildLoad2(self.builder, i32_type, rhs_tag_gep, "tag.val");
    const lhs_some = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, lhs_tag, c.LLVMConstInt(i32_type, 0, 0), "lhs.some");
    const rhs_some = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, rhs_tag, c.LLVMConstInt(i32_type, 0, 0), "rhs.some");
    const both_some = c.LLVMBuildAnd(self.builder, lhs_some, rhs_some, "both.some");

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "zip.some");
    const none_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "zip.none");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "zip.merge");
    _ = c.LLVMBuildCondBr(self.builder, both_some, some_bb, none_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, some_bb);
    const lhs_payload_gep = c.LLVMBuildStructGEP2(self.builder, lhs_type, lhs_alloca, 1, "payload");
    const rhs_payload_gep = c.LLVMBuildStructGEP2(self.builder, rhs_type, rhs_alloca, 1, "payload");
    const lhs_payload_ptr = c.LLVMBuildBitCast(self.builder, lhs_payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const rhs_payload_ptr = c.LLVMBuildBitCast(self.builder, rhs_payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const lhs_payload = c.LLVMBuildLoad2(self.builder, lhs_payload_type, lhs_payload_ptr, "lhs.payload");
    const rhs_payload = c.LLVMBuildLoad2(self.builder, rhs_payload_type, rhs_payload_ptr, "rhs.payload");

    const tuple_alloca = c.LLVMBuildAlloca(self.builder, tuple_type, "zip.tuple");
    const t0 = c.LLVMBuildStructGEP2(self.builder, tuple_type, tuple_alloca, 0, "");
    const t1 = c.LLVMBuildStructGEP2(self.builder, tuple_type, tuple_alloca, 1, "");
    _ = c.LLVMBuildStore(self.builder, lhs_payload, t0);
    _ = c.LLVMBuildStore(self.builder, rhs_payload, t1);
    const tuple_val = c.LLVMBuildLoad2(self.builder, tuple_type, tuple_alloca, "zip.tuple.val");
    const some_result = try self.buildOptionSome(tuple_val);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const some_end_bb = c.LLVMGetInsertBlock(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, none_bb);
    const none_result = self.buildOptionNone(out_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const none_end_bb = c.LLVMGetInsertBlock(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, out_type, "zip.result");
    var vals = [_]c.LLVMValueRef{ some_result, none_result };
    var bbs = [_]c.LLVMBasicBlockRef{ some_end_bb, none_end_bb };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

/// Generate Option.flatten() for Option[Option[T]].
fn genOptionFlatten(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const inner_opt_type = self.getOptionPayloadType(obj_type) orelse blk: {
        if (self.expected_type) |et| {
            if (et != obj_type and self.isOptionType(et)) break :blk et;
        }
        if (self.current_ret_type != null and self.current_ret_type != obj_type and self.isOptionType(self.current_ret_type)) {
            break :blk self.current_ret_type;
        }
        return error.UnsupportedExpr;
    };

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "opt");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);
    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
    const is_some = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "is_some");

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "flatten.some");
    const none_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "flatten.none");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "flatten.merge");
    _ = c.LLVMBuildCondBr(self.builder, is_some, some_bb, none_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, some_bb);
    const payload_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "payload");
    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const inner_val = c.LLVMBuildLoad2(self.builder, inner_opt_type, payload_ptr, "inner.opt");
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const some_end_bb = c.LLVMGetInsertBlock(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, none_bb);
    const none_val = self.buildOptionNone(inner_opt_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const none_end_bb = c.LLVMGetInsertBlock(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, inner_opt_type, "flatten.result");
    var vals = [_]c.LLVMValueRef{ inner_val, none_val };
    var bbs = [_]c.LLVMBasicBlockRef{ some_end_bb, none_end_bb };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

/// Generate Option.cloned() — currently a by-value identity copy.
fn genOptionCloned(_: *Codegen, obj_val: c.LLVMValueRef, _: c.LLVMTypeRef) c.LLVMValueRef {
    return obj_val;
}

/// Generate Option.transpose() for Option[Result[T, E]].
/// Some(Ok(v))  -> Ok(Some(v))
/// Some(Err(e)) -> Err(e)
/// None         -> Ok(None)
fn genOptionTranspose(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const inner_result_type = self.getOptionPayloadType(obj_type) orelse return error.UnsupportedExpr;
    if (!self.isResultType(inner_result_type)) return error.UnsupportedExpr;

    const ok_type = self.getOptionPayloadType(inner_result_type) orelse return error.UnsupportedExpr;
    const err_type = self.getResultErrType(inner_result_type) orelse return error.UnsupportedExpr;
    const opt_ok_info = try self.getOrCreateOptionType(ok_type);
    const out_result_info = try self.getOrCreateResultType(opt_ok_info.llvm_type, err_type);
    const out_type = out_result_info.llvm_type;

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const outer_alloca = c.LLVMBuildAlloca(self.builder, obj_type, "opt");
    _ = c.LLVMBuildStore(self.builder, obj_val, outer_alloca);

    const outer_tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, outer_alloca, 0, "tag");
    const outer_tag = c.LLVMBuildLoad2(self.builder, i32_type, outer_tag_gep, "tag.val");
    const outer_some = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, outer_tag, c.LLVMConstInt(i32_type, 0, 0), "is_some");

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "transpose.some");
    const none_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "transpose.none");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "transpose.merge");
    _ = c.LLVMBuildCondBr(self.builder, outer_some, some_bb, none_bb);

    // None -> Ok(None)
    c.LLVMPositionBuilderAtEnd(self.builder, none_bb);
    const none_opt = self.buildOptionNone(opt_ok_info.llvm_type);
    const none_result = try self.buildResultOk(none_opt, out_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const none_end_bb = c.LLVMGetInsertBlock(self.builder);

    // Some(inner_result) -> branch on inner tag.
    c.LLVMPositionBuilderAtEnd(self.builder, some_bb);
    const outer_payload_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, outer_alloca, 1, "payload");
    const outer_payload_ptr = c.LLVMBuildBitCast(self.builder, outer_payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const inner_result_val = c.LLVMBuildLoad2(self.builder, inner_result_type, outer_payload_ptr, "inner.result");

    const inner_alloca = c.LLVMBuildAlloca(self.builder, inner_result_type, "inner.res");
    _ = c.LLVMBuildStore(self.builder, inner_result_val, inner_alloca);
    const inner_tag_gep = c.LLVMBuildStructGEP2(self.builder, inner_result_type, inner_alloca, 0, "tag");
    const inner_tag = c.LLVMBuildLoad2(self.builder, i32_type, inner_tag_gep, "tag.val");
    const inner_ok = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, inner_tag, c.LLVMConstInt(i32_type, 0, 0), "is_ok");

    const inner_ok_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "transpose.inner.ok");
    const inner_err_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "transpose.inner.err");
    const inner_merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "transpose.inner.merge");
    _ = c.LLVMBuildCondBr(self.builder, inner_ok, inner_ok_bb, inner_err_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, inner_ok_bb);
    const inner_payload_gep_ok = c.LLVMBuildStructGEP2(self.builder, inner_result_type, inner_alloca, 1, "payload");
    const inner_payload_ptr_ok = c.LLVMBuildBitCast(self.builder, inner_payload_gep_ok, c.LLVMPointerTypeInContext(self.context, 0), "");
    const ok_val = c.LLVMBuildLoad2(self.builder, ok_type, inner_payload_ptr_ok, "ok.val");
    const some_opt = try self.buildOptionSome(ok_val);
    const ok_result = try self.buildResultOk(some_opt, out_type);
    _ = c.LLVMBuildBr(self.builder, inner_merge_bb);
    const inner_ok_end_bb = c.LLVMGetInsertBlock(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, inner_err_bb);
    const inner_payload_gep_err = c.LLVMBuildStructGEP2(self.builder, inner_result_type, inner_alloca, 1, "payload");
    const inner_payload_ptr_err = c.LLVMBuildBitCast(self.builder, inner_payload_gep_err, c.LLVMPointerTypeInContext(self.context, 0), "");
    const err_val = c.LLVMBuildLoad2(self.builder, err_type, inner_payload_ptr_err, "err.val");
    const err_result = try self.buildResultErr(err_val, out_type);
    _ = c.LLVMBuildBr(self.builder, inner_merge_bb);
    const inner_err_end_bb = c.LLVMGetInsertBlock(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, inner_merge_bb);
    const some_result = c.LLVMBuildPhi(self.builder, out_type, "transpose.some.result");
    var some_vals = [_]c.LLVMValueRef{ ok_result, err_result };
    var some_bbs = [_]c.LLVMBasicBlockRef{ inner_ok_end_bb, inner_err_end_bb };
    c.LLVMAddIncoming(some_result, &some_vals, &some_bbs, 2);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const some_end_bb = c.LLVMGetInsertBlock(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, out_type, "transpose.result");
    var vals = [_]c.LLVMValueRef{ some_result, none_result };
    var bbs = [_]c.LLVMBasicBlockRef{ some_end_bb, none_end_bb };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

/// Generate Result.map(f) — if Ok(x), return Ok(f(x)); if Err(e), return Err(e).
fn genResultMap(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef, fn_arg: *const Ast.Expr) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "res");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);

    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
    const is_ok = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "is_ok");

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const ok_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rmap.ok");
    const err_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rmap.err");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rmap.merge");
    _ = c.LLVMBuildCondBr(self.builder, is_ok, ok_bb, err_bb);

    // Find original err type.
    var orig_err_type: c.LLVMTypeRef = i32_type;
    {
        var it = self.result_type_cache.iterator();
        while (it.next()) |entry| {
            if (entry.value_ptr.llvm_type == obj_type) {
                orig_err_type = entry.value_ptr.err_type orelse i32_type;
                break;
            }
        }
    }

    // Ok: extract payload, call f(payload), wrap in new Ok.
    c.LLVMPositionBuilderAtEnd(self.builder, ok_bb);
    const ok_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "payload");
    const payload_type = self.getOptionPayloadType(obj_type) orelse i32_type;
    const ok_ptr = c.LLVMBuildBitCast(self.builder, ok_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const payload_val = c.LLVMBuildLoad2(self.builder, payload_type, ok_ptr, "payload.val");

    const fn_val = try self.genExpr(fn_arg);
    const mapped_val = try self.callFnValueWithArg(fn_val, payload_val);

    // Create new Result type with mapped ok type and same err type.
    const mapped_ok_type = c.LLVMTypeOf(mapped_val);
    const new_result_info = try self.getOrCreateResultType(mapped_ok_type, orig_err_type);
    const ok_result = try self.buildResultOk(mapped_val, new_result_info.llvm_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const ok_end_bb = c.LLVMGetInsertBlock(self.builder);

    // Err: re-wrap the error value (separate GEP in this BB).
    c.LLVMPositionBuilderAtEnd(self.builder, err_bb);
    const err_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "err.payload");
    const err_payload_ptr = c.LLVMBuildBitCast(self.builder, err_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const err_val = c.LLVMBuildLoad2(self.builder, orig_err_type, err_payload_ptr, "err.val");
    const err_result = try self.buildResultErr(err_val, new_result_info.llvm_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Merge.
    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, new_result_info.llvm_type, "rmap.result");
    var vals = [_]c.LLVMValueRef{ ok_result, err_result };
    var bbs = [_]c.LLVMBasicBlockRef{ ok_end_bb, err_bb };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

/// Generate Result.and_then(f) — if Ok(x), return f(x); if Err(e), return Err(e).
/// f must return Result[U, E] and preserves the original error payload.
fn genResultAndThen(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef, fn_arg: *const Ast.Expr) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "res");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);

    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
    const is_ok = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "is_ok");

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const ok_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "randthen.ok");
    const err_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "randthen.err");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "randthen.merge");
    _ = c.LLVMBuildCondBr(self.builder, is_ok, ok_bb, err_bb);

    const orig_ok_type = self.getOptionPayloadType(obj_type) orelse i32_type;
    const orig_err_type = self.getResultErrType(obj_type) orelse i32_type;

    // Ok: call f(ok_val) -> Result[U, E].
    c.LLVMPositionBuilderAtEnd(self.builder, ok_bb);
    const ok_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "ok.payload");
    const ok_payload_ptr = c.LLVMBuildBitCast(self.builder, ok_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const ok_val = c.LLVMBuildLoad2(self.builder, orig_ok_type, ok_payload_ptr, "ok.val");

    const fn_val = try self.genExpr(fn_arg);
    const ok_result = try self.callFnValueWithArg(fn_val, ok_val);
    const out_result_type = c.LLVMTypeOf(ok_result);
    if (!self.isResultType(out_result_type)) return error.UnsupportedExpr;
    const out_ok_type = self.getOptionPayloadType(out_result_type) orelse return error.UnsupportedExpr;
    const out_err_type = self.getResultErrType(out_result_type) orelse return error.UnsupportedExpr;
    if (out_err_type != orig_err_type and !self.sameStructTypeName(out_err_type, orig_err_type)) {
        return error.UnsupportedExpr;
    }
    const out_result_info = try self.getOrCreateResultType(out_ok_type, orig_err_type);
    if (out_result_info.llvm_type != out_result_type and !self.sameStructTypeName(out_result_info.llvm_type, out_result_type)) {
        return error.UnsupportedExpr;
    }
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const ok_end_bb = c.LLVMGetInsertBlock(self.builder);

    // Err: preserve and rewrap the original error payload.
    c.LLVMPositionBuilderAtEnd(self.builder, err_bb);
    const err_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "err.payload");
    const err_payload_ptr = c.LLVMBuildBitCast(self.builder, err_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const err_val = c.LLVMBuildLoad2(self.builder, orig_err_type, err_payload_ptr, "err.val");
    const err_result = try self.buildResultErr(err_val, out_result_info.llvm_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const err_end_bb = c.LLVMGetInsertBlock(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, out_result_info.llvm_type, "randthen.result");
    var vals = [_]c.LLVMValueRef{ ok_result, err_result };
    var bbs = [_]c.LLVMBasicBlockRef{ ok_end_bb, err_end_bb };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

/// Generate Result.map_err(f) — if Ok(x), return Ok(x); if Err(e), return Err(f(e)).
fn genResultMapErr(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef, fn_arg: *const Ast.Expr) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "res");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);

    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
    const is_ok = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "is_ok");

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const ok_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rmaperr.ok");
    const err_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rmaperr.err");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rmaperr.merge");
    _ = c.LLVMBuildCondBr(self.builder, is_ok, ok_bb, err_bb);

    // Find original types.
    var orig_ok_type: c.LLVMTypeRef = i32_type;
    var orig_err_type: c.LLVMTypeRef = i32_type;
    var it = self.result_type_cache.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == obj_type) {
            orig_ok_type = entry.value_ptr.payload_type;
            orig_err_type = entry.value_ptr.err_type orelse i32_type;
            break;
        }
    }

    // Err: extract error payload, call f(err), create new Result with mapped err type.
    c.LLVMPositionBuilderAtEnd(self.builder, err_bb);
    const err_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "err.payload");
    const err_payload_ptr = c.LLVMBuildBitCast(self.builder, err_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const err_val = c.LLVMBuildLoad2(self.builder, orig_err_type, err_payload_ptr, "err.val");

    const fn_val = try self.genExpr(fn_arg);
    const mapped_err = try self.callFnValueWithArg(fn_val, err_val);
    const new_err_type = c.LLVMTypeOf(mapped_err);
    const new_result_info = try self.getOrCreateResultType(orig_ok_type, new_err_type);
    const err_result = try self.buildResultErr(mapped_err, new_result_info.llvm_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Ok: re-wrap the ok value (separate GEP in this BB).
    c.LLVMPositionBuilderAtEnd(self.builder, ok_bb);
    const ok_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "ok.payload");
    const ok_payload_ptr = c.LLVMBuildBitCast(self.builder, ok_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const ok_val = c.LLVMBuildLoad2(self.builder, orig_ok_type, ok_payload_ptr, "ok.val");
    const ok_result = try self.buildResultOk(ok_val, new_result_info.llvm_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const ok_end_bb = c.LLVMGetInsertBlock(self.builder);

    // Merge.
    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, new_result_info.llvm_type, "rmaperr.result");
    var vals = [_]c.LLVMValueRef{ ok_result, err_result };
    var bbs = [_]c.LLVMBasicBlockRef{ ok_end_bb, err_bb };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

/// Generate Result.or_else(f) — if Err(e), return f(e); if Ok(x), return Ok(x).
fn genResultOrElse(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef, fn_arg: *const Ast.Expr) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "res");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);

    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
    const is_ok = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "is_ok");

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const ok_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "ror.ok");
    const err_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "ror.err");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "ror.merge");
    _ = c.LLVMBuildCondBr(self.builder, is_ok, ok_bb, err_bb);

    // Find original Result payload/error types.
    const orig_ok_type = self.getOptionPayloadType(obj_type) orelse i32_type;
    const orig_err_type = self.getResultErrType(obj_type) orelse i32_type;

    // Err: extract error payload, call f(err) -> Result[Ok, E2].
    c.LLVMPositionBuilderAtEnd(self.builder, err_bb);
    const err_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "err.payload");
    const err_payload_ptr = c.LLVMBuildBitCast(self.builder, err_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const err_val = c.LLVMBuildLoad2(self.builder, orig_err_type, err_payload_ptr, "err.val");

    const fn_val = try self.genExpr(fn_arg);
    const mapped_result = try self.callFnValueWithArg(fn_val, err_val);
    const mapped_type = c.LLVMTypeOf(mapped_result);
    if (!self.isResultType(mapped_type)) return error.UnsupportedExpr;
    const mapped_ok_type = self.getOptionPayloadType(mapped_type) orelse return error.UnsupportedExpr;
    if (mapped_ok_type != orig_ok_type and !self.sameStructTypeName(mapped_ok_type, orig_ok_type)) {
        return error.UnsupportedExpr;
    }
    const mapped_err_type = self.getResultErrType(mapped_type) orelse return error.UnsupportedExpr;
    const new_result_info = try self.getOrCreateResultType(orig_ok_type, mapped_err_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const err_end_bb = c.LLVMGetInsertBlock(self.builder);

    // Ok: re-wrap ok payload in Result[Ok, E2].
    c.LLVMPositionBuilderAtEnd(self.builder, ok_bb);
    const ok_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "ok.payload");
    const ok_payload_ptr = c.LLVMBuildBitCast(self.builder, ok_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const ok_val = c.LLVMBuildLoad2(self.builder, orig_ok_type, ok_payload_ptr, "ok.val");
    const ok_result = try self.buildResultOk(ok_val, new_result_info.llvm_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const ok_end_bb = c.LLVMGetInsertBlock(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, new_result_info.llvm_type, "ror.result");
    var vals = [_]c.LLVMValueRef{ ok_result, mapped_result };
    var bbs = [_]c.LLVMBasicBlockRef{ ok_end_bb, err_end_bb };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

/// Generate Result.transpose() for Result[Option[T], E] -> Option[Result[T, E]].
fn genResultTranspose(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    if (!self.isResultType(obj_type)) return error.UnsupportedExpr;

    const opt_ok_type = self.getOptionPayloadType(obj_type) orelse return error.UnsupportedExpr;
    if (!self.isOptionType(opt_ok_type)) return error.UnsupportedExpr;
    const inner_ok_type = self.getOptionPayloadType(opt_ok_type) orelse return error.UnsupportedExpr;
    const err_type = self.getResultErrType(obj_type) orelse return error.UnsupportedExpr;

    const inner_result_info = try self.getOrCreateResultType(inner_ok_type, err_type);
    const out_option_info = try self.getOrCreateOptionType(inner_result_info.llvm_type);
    const out_type = out_option_info.llvm_type;

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const res_alloca = c.LLVMBuildAlloca(self.builder, obj_type, "res");
    _ = c.LLVMBuildStore(self.builder, obj_val, res_alloca);
    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, res_alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
    const is_ok = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "is_ok");

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const ok_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rtr.ok");
    const err_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rtr.err");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rtr.merge");
    _ = c.LLVMBuildCondBr(self.builder, is_ok, ok_bb, err_bb);

    // Err(e) -> Some(Err(e))
    c.LLVMPositionBuilderAtEnd(self.builder, err_bb);
    const err_payload_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, res_alloca, 1, "payload");
    const err_payload_ptr = c.LLVMBuildBitCast(self.builder, err_payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const err_val = c.LLVMBuildLoad2(self.builder, err_type, err_payload_ptr, "err.val");
    const inner_err = try self.buildResultErr(err_val, inner_result_info.llvm_type);
    const some_err = try self.buildOptionSome(inner_err);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const err_end_bb = c.LLVMGetInsertBlock(self.builder);

    // Ok(opt) -> if Some(v) => Some(Ok(v)); if None => None.
    c.LLVMPositionBuilderAtEnd(self.builder, ok_bb);
    const ok_payload_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, res_alloca, 1, "payload");
    const ok_payload_ptr = c.LLVMBuildBitCast(self.builder, ok_payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const ok_opt_val = c.LLVMBuildLoad2(self.builder, opt_ok_type, ok_payload_ptr, "ok.opt");

    const opt_alloca = c.LLVMBuildAlloca(self.builder, opt_ok_type, "opt");
    _ = c.LLVMBuildStore(self.builder, ok_opt_val, opt_alloca);
    const opt_tag_gep = c.LLVMBuildStructGEP2(self.builder, opt_ok_type, opt_alloca, 0, "tag");
    const opt_tag = c.LLVMBuildLoad2(self.builder, i32_type, opt_tag_gep, "tag.val");
    const opt_some = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, opt_tag, c.LLVMConstInt(i32_type, 0, 0), "is_some");

    const opt_some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rtr.opt.some");
    const opt_none_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rtr.opt.none");
    const opt_merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rtr.opt.merge");
    _ = c.LLVMBuildCondBr(self.builder, opt_some, opt_some_bb, opt_none_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, opt_some_bb);
    const opt_inner_gep = c.LLVMBuildStructGEP2(self.builder, opt_ok_type, opt_alloca, 1, "payload");
    const opt_inner_ptr = c.LLVMBuildBitCast(self.builder, opt_inner_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const ok_val = c.LLVMBuildLoad2(self.builder, inner_ok_type, opt_inner_ptr, "ok.val");
    const inner_ok = try self.buildResultOk(ok_val, inner_result_info.llvm_type);
    const some_ok = try self.buildOptionSome(inner_ok);
    _ = c.LLVMBuildBr(self.builder, opt_merge_bb);
    const opt_some_end_bb = c.LLVMGetInsertBlock(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, opt_none_bb);
    const none_out = self.buildOptionNone(out_type);
    _ = c.LLVMBuildBr(self.builder, opt_merge_bb);
    const opt_none_end_bb = c.LLVMGetInsertBlock(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, opt_merge_bb);
    const ok_branch_result = c.LLVMBuildPhi(self.builder, out_type, "rtr.ok.branch");
    var ok_vals = [_]c.LLVMValueRef{ some_ok, none_out };
    var ok_bbs = [_]c.LLVMBasicBlockRef{ opt_some_end_bb, opt_none_end_bb };
    c.LLVMAddIncoming(ok_branch_result, &ok_vals, &ok_bbs, 2);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const ok_end_bb = c.LLVMGetInsertBlock(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, out_type, "rtr.result");
    var vals = [_]c.LLVMValueRef{ ok_branch_result, some_err };
    var bbs = [_]c.LLVMBasicBlockRef{ ok_end_bb, err_end_bb };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

/// Generate Result.context(msg) — wraps Err(e) into Err(ContextError[E]{msg, e}).
fn genResultContext(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef, msg_arg: *const Ast.Expr) Error!c.LLVMValueRef {
    if (!self.isResultType(obj_type)) return error.UnsupportedExpr;

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "res");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);

    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
    const is_ok = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "is_ok");

    // context(msg) is eager: evaluate msg before branching.
    const msg_val = try self.genExpr(msg_arg);
    const msg_type = c.LLVMTypeOf(msg_val);

    const ok_type = self.getOptionPayloadType(obj_type) orelse i32_type;
    const err_type = self.getResultErrType(obj_type) orelse i32_type;
    const ctx_info = try self.getOrCreateContextErrorType(err_type);
    const out_info = try self.getOrCreateResultType(ok_type, ctx_info.llvm_type);

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const ok_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rctx.ok");
    const err_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rctx.err");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rctx.merge");
    _ = c.LLVMBuildCondBr(self.builder, is_ok, ok_bb, err_bb);

    // Ok: passthrough payload into new Result type.
    c.LLVMPositionBuilderAtEnd(self.builder, ok_bb);
    const ok_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "ok.payload");
    const ok_ptr = c.LLVMBuildBitCast(self.builder, ok_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const ok_val = c.LLVMBuildLoad2(self.builder, ok_type, ok_ptr, "ok.val");
    const ok_result = try self.buildResultOk(ok_val, out_info.llvm_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const ok_end_bb = c.LLVMGetInsertBlock(self.builder);

    // Err: build ContextError { message, source } and wrap as Err.
    c.LLVMPositionBuilderAtEnd(self.builder, err_bb);
    const err_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "err.payload");
    const err_ptr = c.LLVMBuildBitCast(self.builder, err_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const err_val = c.LLVMBuildLoad2(self.builder, err_type, err_ptr, "err.val");

    const ctx_msg_type = c.LLVMStructGetTypeAtIndex(ctx_info.llvm_type, 0);
    if (msg_type != ctx_msg_type and !self.sameStructTypeName(msg_type, ctx_msg_type)) return error.UnsupportedExpr;

    const ctx_alloca = c.LLVMBuildAlloca(self.builder, ctx_info.llvm_type, "ctx.err");
    const msg_gep = c.LLVMBuildStructGEP2(self.builder, ctx_info.llvm_type, ctx_alloca, 0, "ctx.msg");
    _ = c.LLVMBuildStore(self.builder, msg_val, msg_gep);
    const src_gep = c.LLVMBuildStructGEP2(self.builder, ctx_info.llvm_type, ctx_alloca, 1, "ctx.src");
    _ = c.LLVMBuildStore(self.builder, err_val, src_gep);
    const ctx_val = c.LLVMBuildLoad2(self.builder, ctx_info.llvm_type, ctx_alloca, "ctx.val");
    const err_result = try self.buildResultErr(ctx_val, out_info.llvm_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const err_end_bb = c.LLVMGetInsertBlock(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, out_info.llvm_type, "rctx.result");
    var vals = [_]c.LLVMValueRef{ ok_result, err_result };
    var bbs = [_]c.LLVMBasicBlockRef{ ok_end_bb, err_end_bb };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

/// Generate Result.with_context(f) — lazily computes message only on Err.
fn genResultWithContext(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef, fn_arg: *const Ast.Expr) Error!c.LLVMValueRef {
    if (!self.isResultType(obj_type)) return error.UnsupportedExpr;

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "res");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);

    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
    const is_ok = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "is_ok");

    const ok_type = self.getOptionPayloadType(obj_type) orelse i32_type;
    const err_type = self.getResultErrType(obj_type) orelse i32_type;
    const ctx_info = try self.getOrCreateContextErrorType(err_type);
    const out_info = try self.getOrCreateResultType(ok_type, ctx_info.llvm_type);

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const ok_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rwctx.ok");
    const err_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rwctx.err");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "rwctx.merge");
    _ = c.LLVMBuildCondBr(self.builder, is_ok, ok_bb, err_bb);

    // Ok: passthrough payload into new Result type.
    c.LLVMPositionBuilderAtEnd(self.builder, ok_bb);
    const ok_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "ok.payload");
    const ok_ptr = c.LLVMBuildBitCast(self.builder, ok_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const ok_val = c.LLVMBuildLoad2(self.builder, ok_type, ok_ptr, "ok.val");
    const ok_result = try self.buildResultOk(ok_val, out_info.llvm_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const ok_end_bb = c.LLVMGetInsertBlock(self.builder);

    // Err: evaluate message thunk and wrap { message, source }.
    c.LLVMPositionBuilderAtEnd(self.builder, err_bb);
    const err_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "err.payload");
    const err_ptr = c.LLVMBuildBitCast(self.builder, err_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const err_val = c.LLVMBuildLoad2(self.builder, err_type, err_ptr, "err.val");

    const fn_val = try self.genExpr(fn_arg);
    const msg_val = try self.callFnValueNoArgs(fn_val);
    const msg_type = c.LLVMTypeOf(msg_val);
    const ctx_msg_type = c.LLVMStructGetTypeAtIndex(ctx_info.llvm_type, 0);
    if (msg_type != ctx_msg_type and !self.sameStructTypeName(msg_type, ctx_msg_type)) return error.UnsupportedExpr;

    const ctx_alloca = c.LLVMBuildAlloca(self.builder, ctx_info.llvm_type, "ctx.err");
    const msg_gep = c.LLVMBuildStructGEP2(self.builder, ctx_info.llvm_type, ctx_alloca, 0, "ctx.msg");
    _ = c.LLVMBuildStore(self.builder, msg_val, msg_gep);
    const src_gep = c.LLVMBuildStructGEP2(self.builder, ctx_info.llvm_type, ctx_alloca, 1, "ctx.src");
    _ = c.LLVMBuildStore(self.builder, err_val, src_gep);
    const ctx_val = c.LLVMBuildLoad2(self.builder, ctx_info.llvm_type, ctx_alloca, "ctx.val");
    const err_result = try self.buildResultErr(ctx_val, out_info.llvm_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);
    const err_end_bb = c.LLVMGetInsertBlock(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, out_info.llvm_type, "rwctx.result");
    var vals = [_]c.LLVMValueRef{ ok_result, err_result };
    var bbs = [_]c.LLVMBasicBlockRef{ ok_end_bb, err_end_bb };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

/// Generate Result.ok() — if Ok(x), return Some(x); if Err(_), return None.
fn genResultToOk(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "res");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);

    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
    const is_ok = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "is_ok");

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const ok_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "tok.ok");
    const err_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "tok.err");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "tok.merge");
    _ = c.LLVMBuildCondBr(self.builder, is_ok, ok_bb, err_bb);

    // Ok: extract payload, wrap in Some.
    c.LLVMPositionBuilderAtEnd(self.builder, ok_bb);
    const payload_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "payload");
    const payload_type = self.getOptionPayloadType(obj_type) orelse i32_type;
    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const ok_val = c.LLVMBuildLoad2(self.builder, payload_type, payload_ptr, "ok.val");
    const some_result = try self.buildOptionSome(ok_val);
    const opt_type = c.LLVMTypeOf(some_result);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Err: return None.
    c.LLVMPositionBuilderAtEnd(self.builder, err_bb);
    const none_result = self.buildOptionNone(opt_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Merge.
    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, opt_type, "tok.result");
    var vals = [_]c.LLVMValueRef{ some_result, none_result };
    var bbs = [_]c.LLVMBasicBlockRef{ ok_bb, err_bb };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

/// Generate Result.err() — if Err(e), return Some(e); if Ok(_), return None.
fn genResultToErr(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "res");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);

    const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
    const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
    const is_err = c.LLVMBuildICmp(self.builder, c.LLVMIntNE, tag, c.LLVMConstInt(i32_type, 0, 0), "is_err");

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const err_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "terr.err");
    const ok_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "terr.ok");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "terr.merge");
    _ = c.LLVMBuildCondBr(self.builder, is_err, err_bb, ok_bb);

    // Err: extract error payload, wrap in Some.
    c.LLVMPositionBuilderAtEnd(self.builder, err_bb);
    // Find err type from result cache.
    var err_type: c.LLVMTypeRef = i32_type;
    var it = self.result_type_cache.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == obj_type) {
            err_type = entry.value_ptr.err_type orelse i32_type;
            break;
        }
    }
    const payload_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "payload");
    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const err_val = c.LLVMBuildLoad2(self.builder, err_type, payload_ptr, "err.val");
    const some_result = try self.buildOptionSome(err_val);
    const opt_type = c.LLVMTypeOf(some_result);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Ok: return None.
    c.LLVMPositionBuilderAtEnd(self.builder, ok_bb);
    const none_result = self.buildOptionNone(opt_type);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Merge.
    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, opt_type, "terr.result");
    var vals = [_]c.LLVMValueRef{ some_result, none_result };
    var bbs = [_]c.LLVMBasicBlockRef{ err_bb, ok_bb };
    c.LLVMAddIncoming(phi, &vals, &bbs, 2);
    return phi;
}

/// Get or declare the abort() function.
fn getOrDeclareAbort(self: *Codegen) ?c.LLVMValueRef {
    const info = self.ensureAbortDeclared() catch return null;
    return info.value;
}

fn genLetBinding(self: *Codegen, let_b: Ast.LetBinding) Error!c.LLVMValueRef {
    // Set expected_type from annotation for type context (helps None, Err).
    const saved_expected = self.expected_type;
    defer self.expected_type = saved_expected;
    if (let_b.type_expr) |te| {
        self.expected_type = self.resolveType(te) catch null;
    }

    var val = try self.genExpr(let_b.value);
    var dyn_trait_sym: ?u32 = null;
    var dyn_concrete_sym: ?u32 = null;
    if (let_b.type_expr) |te| {
        dyn_trait_sym = dynTraitFromTypeExpr(self, te);
        if (dyn_trait_sym) |trait_sym| {
            const arg_type = c.LLVMTypeOf(val);
            if (self.dynConcreteArgInfo(let_b.value, arg_type)) |info| {
                if (info.use_ptr) {
                    val = try self.buildDynTraitValueFromPtr(val, info.type_sym, trait_sym);
                } else {
                    val = try self.buildDynTraitValue(val, info.type_sym, trait_sym);
                }
                dyn_concrete_sym = info.type_sym;
            }
        }
    }

    // Type from annotation, or inferred from value.
    const ty = if (let_b.type_expr) |te|
        try self.resolveType(te)
    else
        c.LLVMTypeOf(val);

    var local_fn_sig: ?c.LLVMTypeRef = null;
    if (let_b.type_expr) |te| {
        if (te.kind == .fn_type) {
            local_fn_sig = self.buildFnTypeFromAst(te.kind.fn_type) catch null;
        }
    }
    if (local_fn_sig == null) {
        local_fn_sig = self.inferCallableFnSigFromExpr(let_b.value);
    }
    if (local_fn_sig == null) {
        local_fn_sig = self.inferCallableFnSigFromStorageType(ty);
    }

    // In generator mode, reuse the pre-created alloca from the entry block
    // to avoid SSA dominance violations.
    const alloca = if (self.gen_state_ptr != null) blk: {
        if (self.locals.get(let_b.name)) |existing| {
            break :blk existing.alloca;
        }
        break :blk c.LLVMBuildAlloca(self.builder, ty, "");
    } else c.LLVMBuildAlloca(self.builder, ty, "");
    const coerced = try self.coerceValueForType(val, ty);
    _ = c.LLVMBuildStore(self.builder, coerced, alloca);

    self.locals.put(self.allocator, let_b.name, .{
        .alloca = alloca,
        .ty = ty,
        .is_mut = let_b.is_mut,
        .fn_sig = local_fn_sig,
    }) catch return error.CodegenAlloc;

    if (dyn_trait_sym) |trait_sym| {
        self.trait_locals.put(self.allocator, let_b.name, trait_sym) catch {};
        if (dyn_concrete_sym) |concrete_sym| {
            self.trait_local_concrete_types.put(self.allocator, let_b.name, concrete_sym) catch {};
        } else {
            _ = self.trait_local_concrete_types.remove(let_b.name);
        }
    } else {
        _ = self.trait_locals.remove(let_b.name);
        _ = self.trait_local_concrete_types.remove(let_b.name);
    }

    // Track locals that hold async task IDs so `.await` can distinguish
    // real task handles from plain integers.
    if (self.exprProducesTask(let_b.value)) {
        self.task_locals.put(self.allocator, let_b.name, {}) catch return error.CodegenAlloc;
        if (self.inferTaskResultType(let_b.value)) |task_result_ty| {
            self.task_local_result_types.put(self.allocator, let_b.name, task_result_ty) catch return error.CodegenAlloc;
        } else {
            _ = self.task_local_result_types.remove(let_b.name);
        }
    } else {
        _ = self.task_locals.remove(let_b.name);
        _ = self.task_local_result_types.remove(let_b.name);
    }
    if (self.inferTaskContainerElementType(let_b.value)) |task_elem_ty| {
        self.task_container_local_elem_types.put(self.allocator, let_b.name, task_elem_ty) catch return error.CodegenAlloc;
    } else {
        _ = self.task_container_local_elem_types.remove(let_b.name);
    }

    // Track this local for Drop emission at scope exit.
    if (self.scope_local_count < self.scope_locals.len) {
        self.scope_locals[self.scope_local_count] = .{
            .sym = let_b.name,
            .alloca = alloca,
            .ty = ty,
        };
        self.scope_local_count += 1;
    }

    // Track enum type for the local (for println/match support).
    // First: use explicit type annotation if available.
    var enum_tracked = false;
    if (let_b.type_expr) |te| {
        if (te.kind == .named) {
            if (self.enum_types.get(te.kind.named) != null) {
                self.enum_local_types.put(self.allocator, let_b.name, te.kind.named) catch {};
                enum_tracked = true;
            }
        }
    }
    if (!enum_tracked) {
        if (let_b.value.kind == .ident) {
            const val_sym = let_b.value.kind.ident;
            // Check if the ident is an enum variant.
            var eit = self.enum_types.iterator();
            while (eit.next()) |entry| {
                for (entry.value_ptr.variant_names) |vn| {
                    if (vn == val_sym) {
                        self.enum_local_types.put(self.allocator, let_b.name, entry.key_ptr.*) catch {};
                        break;
                    }
                }
            }
        } else if (let_b.value.kind == .enum_variant) {
            self.enum_local_types.put(self.allocator, let_b.name, let_b.value.kind.enum_variant.type_name) catch {};
        }
    }

    // Track slice element type if the binding is a slice type.
    if (let_b.type_expr) |te| {
        if (te.kind == .slice_type) {
            const elem_ty = self.resolveType(te.kind.slice_type) catch null;
            if (elem_ty) |et| {
                self.slice_elem_types.put(self.allocator, let_b.name, et) catch {};
            }
        }
    }
    // Also track slice element type from slice expressions (inferred).
    if (let_b.value.kind == .slice) {
        // Infer element type from the source array/slice.
        if (let_b.value.kind.slice.expr.kind == .ident) {
            const src_sym = let_b.value.kind.slice.expr.kind.ident;
            if (self.slice_elem_types.get(src_sym)) |et| {
                self.slice_elem_types.put(self.allocator, let_b.name, et) catch {};
            } else if (self.locals.get(src_sym)) |src_local| {
                if (c.LLVMGetTypeKind(src_local.ty) == c.LLVMArrayTypeKind) {
                    self.slice_elem_types.put(self.allocator, let_b.name, c.LLVMGetElementType(src_local.ty)) catch {};
                }
            }
        }
    }

    // Track pointee type if value is a reference (&expr or &mut expr).
    if (let_b.value.kind == .unary and (let_b.value.kind.unary.op == .ref_of or let_b.value.kind.unary.op == .mut_ref_of)) {
        const ref_operand = let_b.value.kind.unary.operand;
        if (ref_operand.kind == .ident) {
            if (self.locals.get(ref_operand.kind.ident)) |pointee_info| {
                self.ref_pointee_types.put(self.allocator, let_b.name, pointee_info.ty) catch {};
            }
        }
    }

    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn genLetElse(self: *Codegen, le: Ast.LetElse) Error!c.LLVMValueRef {
    // Evaluate the value expression (should be an Option/Result enum).
    const subject = try self.genExpr(le.value);
    const subject_type = c.LLVMTypeOf(subject);

    // Store subject to memory so we can GEP into it (entry block for dominance).
    const tmp = self.createEntryAlloca(subject_type, "letelse.subj");
    _ = c.LLVMBuildStore(self.builder, subject, tmp);

    // Extract tag (field 0).
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const tag_gep = c.LLVMBuildStructGEP2(self.builder, subject_type, tmp, 0, "tag.ptr");
    const tag_val = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag");

    // Find enum info by matching the LLVM type.
    var enum_info: ?EnumTypeInfo = null;
    {
        var it = self.enum_types.iterator();
        while (it.next()) |entry| {
            if (entry.value_ptr.llvm_type == subject_type) {
                enum_info = entry.value_ptr.*;
                break;
            }
        }
    }

    // Find the variant index for the pattern name.
    var variant_idx: ?u32 = null;
    var payload_type: ?c.LLVMTypeRef = null;
    if (enum_info) |ei| {
        for (ei.variant_names, 0..) |vn, vi| {
            if (vn == le.pattern.name) {
                variant_idx = @intCast(vi);
                payload_type = ei.variant_payload_types[vi];
                break;
            }
        }
    }

    const expected_tag = c.LLVMConstInt(i32_type, variant_idx orelse 0, 0);
    const cmp = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag_val, expected_tag, "letelse.match");

    // Create basic blocks.
    const match_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "letelse.match");
    const else_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "letelse.else");
    const cont_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "letelse.cont");

    _ = c.LLVMBuildCondBr(self.builder, cmp, match_bb, else_bb);

    // -- Match block: extract payload and bind variables --
    c.LLVMPositionBuilderAtEnd(self.builder, match_bb);

    if (le.pattern.bindings.len > 0 and payload_type != null) {
        const pt = payload_type.?;
        const payload_gep = c.LLVMBuildStructGEP2(self.builder, subject_type, tmp, 1, "payload.ptr");
        const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
        const payload_val = c.LLVMBuildLoad2(self.builder, pt, payload_ptr, "payload");

        const bind_sym = le.pattern.bindings[0];
        // Place alloca in entry block so it dominates all uses (including cont_bb).
        const bind_alloca = self.createEntryAlloca(pt, "");
        _ = c.LLVMBuildStore(self.builder, payload_val, bind_alloca);
        self.locals.put(self.allocator, bind_sym, .{
            .alloca = bind_alloca,
            .ty = pt,
            .is_mut = le.is_mut,
        }) catch return error.CodegenAlloc;

        // Track for Drop emission.
        if (self.scope_local_count < self.scope_locals.len) {
            self.scope_locals[self.scope_local_count] = .{
                .sym = bind_sym,
                .alloca = bind_alloca,
                .ty = pt,
            };
            self.scope_local_count += 1;
        }
    }

    _ = c.LLVMBuildBr(self.builder, cont_bb);

    // -- Else block: execute diverging body (return/break/continue) --
    c.LLVMPositionBuilderAtEnd(self.builder, else_bb);
    _ = try self.genExpr(le.else_body);

    // After genExpr, the builder may be on a different block (e.g. ret.dead).
    // Ensure whatever block the builder is on has a terminator.
    const current_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(current_bb) == null) {
        _ = c.LLVMBuildBr(self.builder, cont_bb);
    }

    // -- Continue block --
    c.LLVMPositionBuilderAtEnd(self.builder, cont_bb);

    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn bindPatternFromPtr(self: *Codegen, pattern: Ast.Pattern, value_type: c.LLVMTypeRef, value_ptr: c.LLVMValueRef, is_mut: bool) Error!void {
    switch (pattern.kind) {
        .wildcard => {},
        .binding => |sym| {
            const value = c.LLVMBuildLoad2(self.builder, value_type, value_ptr, "pat.bind");
            const alloca = c.LLVMBuildAlloca(self.builder, value_type, "pat.local");
            _ = c.LLVMBuildStore(self.builder, value, alloca);
            self.locals.put(self.allocator, sym, .{
                .alloca = alloca,
                .ty = value_type,
                .is_mut = is_mut,
            }) catch return error.CodegenAlloc;
        },
        .at_binding => |ab| {
            const whole = c.LLVMBuildLoad2(self.builder, value_type, value_ptr, "pat.at");
            const alloca = c.LLVMBuildAlloca(self.builder, value_type, "pat.at.local");
            _ = c.LLVMBuildStore(self.builder, whole, alloca);
            self.locals.put(self.allocator, ab.name, .{
                .alloca = alloca,
                .ty = value_type,
                .is_mut = is_mut,
            }) catch return error.CodegenAlloc;
            try self.bindPatternFromPtr(ab.pattern.*, value_type, value_ptr, is_mut);
        },
        .tuple_pattern => |elems| {
            if (c.LLVMGetTypeKind(value_type) != c.LLVMStructTypeKind) return error.UnsupportedExpr;
            const field_count: usize = @intCast(c.LLVMCountStructElementTypes(value_type));
            const bind_count: usize = @min(elems.len, field_count);
            const i32_type = c.LLVMInt32TypeInContext(self.context);
            for (elems[0..bind_count], 0..) |elem, i| {
                const idx: u32 = @intCast(i);
                const elem_type = c.LLVMStructGetTypeAtIndex(value_type, idx);
                var indices = [_]c.LLVMValueRef{
                    c.LLVMConstInt(i32_type, 0, 0),
                    c.LLVMConstInt(i32_type, idx, 0),
                };
                const elem_ptr = c.LLVMBuildGEP2(self.builder, value_type, value_ptr, &indices, 2, "pat.tup.gep");
                try self.bindPatternFromPtr(elem, elem_type, elem_ptr, is_mut);
            }
        },
        else => {},
    }
}

fn bindPatternFromValue(self: *Codegen, pattern: Ast.Pattern, value: c.LLVMValueRef, value_type: c.LLVMTypeRef, is_mut: bool) Error!void {
    const tmp = c.LLVMBuildAlloca(self.builder, value_type, "pat.tmp");
    _ = c.LLVMBuildStore(self.builder, value, tmp);
    try self.bindPatternFromPtr(pattern, value_type, tmp, is_mut);
}

fn genTupleDestructure(self: *Codegen, td: Ast.TupleDestructure) Error!c.LLVMValueRef {
    const tuple_val = try self.genExpr(td.value);
    const tuple_type = c.LLVMTypeOf(tuple_val);

    if (td.pattern) |pat| {
        try self.bindPatternFromValue(pat, tuple_val, tuple_type, td.is_mut);
    } else {
        // Legacy flat tuple destructure path.
        const tuple_alloca = c.LLVMBuildAlloca(self.builder, tuple_type, "tuple.tmp");
        _ = c.LLVMBuildStore(self.builder, tuple_val, tuple_alloca);

        const i32_type = c.LLVMInt32TypeInContext(self.context);
        const num_fields = c.LLVMCountStructElementTypes(tuple_type);
        for (td.names, 0..) |name, i| {
            if (i >= num_fields) break;
            const idx: u32 = @intCast(i);
            const elem_type = c.LLVMStructGetTypeAtIndex(tuple_type, idx);
            var indices = [_]c.LLVMValueRef{
                c.LLVMConstInt(i32_type, 0, 0),
                c.LLVMConstInt(i32_type, idx, 0),
            };
            const elem_ptr = c.LLVMBuildGEP2(self.builder, tuple_type, tuple_alloca, &indices, 2, "");
            const elem_val = c.LLVMBuildLoad2(self.builder, elem_type, elem_ptr, "");
            const alloca = c.LLVMBuildAlloca(self.builder, elem_type, "");
            _ = c.LLVMBuildStore(self.builder, elem_val, alloca);
            self.locals.put(self.allocator, name, .{
                .alloca = alloca,
                .ty = elem_type,
                .is_mut = td.is_mut,
            }) catch return error.CodegenAlloc;
        }
    }

    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn genIdent(self: *Codegen, sym: u32) Error!c.LLVMValueRef {
    if (self.locals.get(sym)) |info| {
        return c.LLVMBuildLoad2(self.builder, info.ty, info.alloca, "");
    }

    // Check module-level constants.
    if (self.module_constants.get(sym)) |global| {
        const gtype = c.LLVMGlobalGetValueType(global);
        return c.LLVMBuildLoad2(self.builder, gtype, global, "const");
    }

    // Check if expected_type is a known enum and has this variant — prefer it over
    // the general enum_types iteration to correctly disambiguate when multiple
    // enum types share variant names (e.g. Option[i32] and Option[str] both have "None").
    if (self.expected_type) |et| {
        if (c.LLVMGetTypeKind(et) == c.LLVMStructTypeKind) {
            if (self.enum_types_by_llvm.get(@intFromPtr(et))) |ei| {
                for (ei.variant_names, 0..) |vn, i| {
                    if (vn == sym) {
                        const tag_val = c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), @intCast(i), 0);
                        const alloca = c.LLVMBuildAlloca(self.builder, ei.llvm_type, "enum");
                        const tag_gep = c.LLVMBuildStructGEP2(self.builder, ei.llvm_type, alloca, 0, "");
                        _ = c.LLVMBuildStore(self.builder, tag_val, tag_gep);
                        return c.LLVMBuildLoad2(self.builder, ei.llvm_type, alloca, "enum.val");
                    }
                }
            }
        }
    }

    // Check if this is an unqualified enum variant name.
    var it = self.enum_types.iterator();
    while (it.next()) |entry| {
        const ei = entry.value_ptr.*;
        for (ei.variant_names, 0..) |vn, i| {
            if (vn == sym) {
                // Found the variant — construct it.
                const tag_val = c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), @intCast(i), 0);
                const has_payload = c.LLVMGetTypeKind(ei.llvm_type) == c.LLVMStructTypeKind;
                if (!has_payload) {
                    return tag_val;
                }
                // Unit variant of payload enum — build struct with zero-filled payload.
                const alloca = c.LLVMBuildAlloca(self.builder, ei.llvm_type, "enum");
                const tag_gep = c.LLVMBuildStructGEP2(self.builder, ei.llvm_type, alloca, 0, "");
                _ = c.LLVMBuildStore(self.builder, tag_val, tag_gep);
                return c.LLVMBuildLoad2(self.builder, ei.llvm_type, alloca, "enum.val");
            }
        }
    }

    // Check if this is a function name — return function pointer value.
    if (self.functions.get(sym)) |fn_info| {
        return fn_info.value;
    }

    // Built-in math constants
    const pi_sym = self.pool.intern("PI") catch return error.CodegenAlloc;
    if (sym == pi_sym) {
        return c.LLVMConstReal(c.LLVMDoubleTypeInContext(self.context), 3.14159265358979323846);
    }
    const e_sym = self.pool.intern("E") catch return error.CodegenAlloc;
    if (sym == e_sym) {
        return c.LLVMConstReal(c.LLVMDoubleTypeInContext(self.context), 2.71828182845904523536);
    }
    const inf_sym = self.pool.intern("INFINITY") catch return error.CodegenAlloc;
    if (sym == inf_sym) {
        return c.LLVMConstReal(c.LLVMDoubleTypeInContext(self.context), std.math.inf(f64));
    }
    const nan_sym = self.pool.intern("NAN") catch return error.CodegenAlloc;
    if (sym == nan_sym) {
        return c.LLVMConstReal(c.LLVMDoubleTypeInContext(self.context), std.math.nan(f64));
    }

    // Built-in: None — creates Option None value using expected type context.
    // (Only reached if no user-defined enum variant matched.)
    const none_sym = self.pool.intern("None") catch return error.CodegenAlloc;
    if (sym == none_sym) {
        if (self.expected_type) |et| {
            if (c.LLVMGetTypeKind(et) == c.LLVMStructTypeKind) {
                return self.buildOptionNone(et);
            }
        }
        // Default: create Option[i32] None.
        const i32_type = c.LLVMInt32TypeInContext(self.context);
        const opt_info = try self.getOrCreateOptionType(i32_type);
        return self.buildOptionNone(opt_info.llvm_type);
    }

    return error.UnsupportedExpr;
}

fn genIfExpr(self: *Codegen, if_e: Ast.IfExpr) Error!c.LLVMValueRef {
    const raw_cond = try self.genExpr(if_e.condition);
    const cond = self.coerceToBool(raw_cond);

    const function = self.current_function;
    const then_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "then");
    const else_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "else");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "merge");

    _ = c.LLVMBuildCondBr(self.builder, cond, then_bb, else_bb);

    // Then branch.
    c.LLVMPositionBuilderAtEnd(self.builder, then_bb);
    const then_val = try self.genExpr(if_e.then_body);
    const then_end_bb = c.LLVMGetInsertBlock(self.builder);
    const then_terminated = c.LLVMGetBasicBlockTerminator(then_end_bb) != null;
    if (!then_terminated) _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Else branch.
    c.LLVMPositionBuilderAtEnd(self.builder, else_bb);
    const else_val = if (if_e.else_body) |eb|
        try self.genExpr(eb)
    else blk: {
        // No else body. If the then branch is a Result type and we're in a
        // Result[Unit, E] returning function, produce Ok(()) instead of undef.
        const then_type = c.LLVMTypeOf(then_val);
        if (self.isResultType(then_type) and self.current_fn_returns_result) {
            const unit_val = c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
            break :blk try self.buildResultOk(unit_val, then_type);
        }
        break :blk c.LLVMGetUndef(then_type);
    };
    const else_end_bb = c.LLVMGetInsertBlock(self.builder);
    const else_terminated = c.LLVMGetBasicBlockTerminator(else_end_bb) != null;
    if (!else_terminated) _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Merge with phi node.
    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);

    // If both branches terminated (e.g. both return), the merge block is dead.
    if (then_terminated and else_terminated) {
        return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
    }

    // Determine initial phi type from a non-terminated branch's value.
    var phi_type = if (!then_terminated)
        c.LLVMTypeOf(then_val)
    else
        c.LLVMTypeOf(else_val);

    // If the result type is void, no phi needed.
    if (phi_type == c.LLVMVoidTypeInContext(self.context)) {
        return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
    }

    // Implicit Ok wrapping: if types mismatch and one side is Result, wrap the other.
    // Do this BEFORE creating the phi node so the phi type is correct.
    var final_then = then_val;
    var final_else = else_val;
    if (!then_terminated and !else_terminated) {
        const then_type = c.LLVMTypeOf(then_val);
        const else_type = c.LLVMTypeOf(else_val);
        if (then_type != else_type) {
            if (self.isResultType(then_type) and !self.isResultType(else_type)) {
                // Wrap else in Ok.
                c.LLVMPositionBuilderAtEnd(self.builder, else_end_bb);
                c.LLVMInstructionEraseFromParent(c.LLVMGetBasicBlockTerminator(else_end_bb));
                final_else = self.buildResultOk(else_val, then_type) catch return error.UnsupportedExpr;
                _ = c.LLVMBuildBr(self.builder, merge_bb);
                c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
                phi_type = then_type;
            } else if (self.isResultType(else_type) and !self.isResultType(then_type)) {
                // Wrap then in Ok.
                c.LLVMPositionBuilderAtEnd(self.builder, then_end_bb);
                c.LLVMInstructionEraseFromParent(c.LLVMGetBasicBlockTerminator(then_end_bb));
                final_then = self.buildResultOk(then_val, else_type) catch return error.UnsupportedExpr;
                _ = c.LLVMBuildBr(self.builder, merge_bb);
                c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
                phi_type = else_type;
            }
        }
    }

    const phi = c.LLVMBuildPhi(self.builder, phi_type, "ifval");

    if (!then_terminated and !else_terminated) {
        const then_type_final = c.LLVMTypeOf(final_then);
        const else_type_final = c.LLVMTypeOf(final_else);
        if (then_type_final != else_type_final) {
            final_else = self.coerceInt(final_else, phi_type);
        }
        var incoming_vals = [_]c.LLVMValueRef{ final_then, final_else };
        var incoming_bbs = [_]c.LLVMBasicBlockRef{ then_end_bb, else_end_bb };
        c.LLVMAddIncoming(phi, &incoming_vals, &incoming_bbs, 2);
    } else if (!then_terminated) {
        var incoming_vals = [_]c.LLVMValueRef{then_val};
        var incoming_bbs = [_]c.LLVMBasicBlockRef{then_end_bb};
        c.LLVMAddIncoming(phi, &incoming_vals, &incoming_bbs, 1);
    } else {
        var incoming_vals = [_]c.LLVMValueRef{else_val};
        var incoming_bbs = [_]c.LLVMBasicBlockRef{else_end_bb};
        c.LLVMAddIncoming(phi, &incoming_vals, &incoming_bbs, 1);
    }

    return phi;
}

fn genCall(self: *Codegen, call_e: Ast.CallExpr) Error!c.LLVMValueRef {
    return self.genCallInner(call_e) catch |err| {
        if (err == error.UnsupportedExpr and self.codegen_error_detail == null) {
            var callee_buf: [160]u8 = undefined;
            const callee_name: []const u8 = switch (call_e.callee.kind) {
                .ident => |sym| self.pool.resolve(sym),
                .field_access => |fa| blk: {
                    if (fa.expr.kind == .ident) {
                        const lhs = self.pool.resolve(fa.expr.kind.ident);
                        const rhs = self.pool.resolve(fa.field);
                        break :blk std.fmt.bufPrint(&callee_buf, "{s}.{s}", .{ lhs, rhs }) catch "<field-call>";
                    }
                    break :blk "<field-call>";
                },
                else => "<expr-call>",
            };
            var msg_buf: [256]u8 = undefined;
            const msg = std.fmt.bufPrint(&msg_buf, "unsupported call to '{s}'", .{callee_name}) catch "unsupported call";
            self.codegen_error_detail = self.allocator.dupe(u8, msg) catch null;
        }
        return err;
    };
}

fn inferCallableFnSigFromStorageType(self: *Codegen, storage_ty: c.LLVMTypeRef) ?c.LLVMTypeRef {
    _ = self;

    const kind = c.LLVMGetTypeKind(storage_ty);
    if (kind == c.LLVMPointerTypeKind) {
        const pointee = c.LLVMGetElementType(storage_ty);
        if (c.LLVMGetTypeKind(pointee) == c.LLVMFunctionTypeKind) {
            return pointee;
        }
        return null;
    }

    if (kind == c.LLVMStructTypeKind) {
        const elem_count_u32 = c.LLVMCountStructElementTypes(storage_ty);
        if (elem_count_u32 < 1) return null;
        const elem_count: usize = @intCast(elem_count_u32);
        if (elem_count > 16) return null;

        var elem_types: [16]c.LLVMTypeRef = undefined;
        c.LLVMGetStructElementTypes(storage_ty, &elem_types);

        const fn_ptr_ty = elem_types[0];
        if (c.LLVMGetTypeKind(fn_ptr_ty) != c.LLVMPointerTypeKind) return null;

        const maybe_fn_ty = c.LLVMGetElementType(fn_ptr_ty);
        if (c.LLVMGetTypeKind(maybe_fn_ty) == c.LLVMFunctionTypeKind) {
            return maybe_fn_ty;
        }
    }

    return null;
}

fn buildFnSigFromClosureExpr(self: *Codegen, cl: Ast.ClosureExpr) ?c.LLVMTypeRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);

    const param_count = cl.params.len;
    if (param_count > 16) return null;

    var fn_param_types: [17]c.LLVMTypeRef = undefined;
    fn_param_types[0] = ptr_type; // closure context/captures
    for (0..param_count) |i| {
        if (i < cl.param_types.len) {
            if (cl.param_types[i]) |te| {
                fn_param_types[1 + i] = self.resolveType(te) catch return null;
            } else {
                fn_param_types[1 + i] = i32_type;
            }
        } else {
            fn_param_types[1 + i] = i32_type;
        }
    }

    const ret_type = if (cl.return_type) |rt|
        self.resolveType(rt) catch return null
    else
        i32_type;

    return c.LLVMFunctionType(ret_type, &fn_param_types, @intCast(1 + param_count), 0);
}

fn inferCallableFnSigFromExpr(self: *Codegen, expr: *const Ast.Expr) ?c.LLVMTypeRef {
    return switch (expr.kind) {
        .ident => |sym| blk: {
            if (self.functions.get(sym)) |fi| break :blk fi.fn_type;
            if (self.locals.get(sym)) |li| break :blk li.fn_sig orelse self.inferCallableFnSigFromStorageType(li.ty);
            break :blk null;
        },
        .closure => |cl| self.buildFnSigFromClosureExpr(cl),
        .grouped => |inner| self.inferCallableFnSigFromExpr(inner),
        else => null,
    };
}

fn genCallInner(self: *Codegen, call_e: Ast.CallExpr) Error!c.LLVMValueRef {
    // Handle method call syntax: `obj.method(args)` → look up `Type.method(obj, args)`
    if (call_e.callee.kind == .field_access) {
        const fa = call_e.callee.kind.field_access;
        return self.genMethodCall(fa, call_e.args);
    }

    // Callee must be an identifier (function name).
    const fn_sym = switch (call_e.callee.kind) {
        .ident => |sym| sym,
        else => return error.UnsupportedExpr,
    };

    // Built-in: println(args...)
    const println_sym = self.pool.intern("println") catch return error.CodegenAlloc;
    if (fn_sym == println_sym) {
        return self.genPrintln(call_e.args);
    }

    // Built-in: print(args...) — same as println but no trailing newline
    const print_sym = self.pool.intern("print") catch return error.CodegenAlloc;
    if (fn_sym == print_sym) {
        return self.genPrint(call_e.args);
    }

    // Built-in: assert(cond) — abort if false
    const assert_sym = self.pool.intern("assert") catch return error.CodegenAlloc;
    if (fn_sym == assert_sym) {
        return self.genAssertBuiltin(call_e.args);
    }

    // Built-in: todo([msg]) / unreachable([msg]) — diverge with Never.
    const todo_sym = self.pool.intern("todo") catch return error.CodegenAlloc;
    if (fn_sym == todo_sym) {
        return self.genDivergeBuiltin(call_e.args);
    }
    const unreachable_sym = self.pool.intern("unreachable") catch return error.CodegenAlloc;
    if (fn_sym == unreachable_sym) {
        return self.genDivergeBuiltin(call_e.args);
    }

    // Built-in: comptime_error("msg") — emit compile-time error
    const comptime_error_sym = self.pool.intern("comptime_error") catch return error.CodegenAlloc;
    if (fn_sym == comptime_error_sym) {
        if (call_e.args.len > 0) {
            if (call_e.args[0].kind == .string_literal) {
                const msg_sym = call_e.args[0].kind.string_literal;
                self.emitComptimeError(msg_sym);
            }
        }
        return error.UnsupportedExpr;
    }

    // Built-in: Some(val) — wraps a value in Option.
    const some_sym = self.pool.intern("Some") catch return error.CodegenAlloc;
    if (fn_sym == some_sym) {
        if (call_e.args.len != 1) return error.UnsupportedExpr;
        const arg_val = try self.genExpr(call_e.args[0]);
        return self.buildOptionSome(arg_val);
    }

    // Built-in: Ok(val) — wraps a value in Result.
    const ok_sym = self.pool.intern("Ok") catch return error.CodegenAlloc;
    if (fn_sym == ok_sym) {
        if (call_e.args.len > 1) return error.UnsupportedExpr;
        const i32_type = c.LLVMInt32TypeInContext(self.context);
        if (call_e.args.len == 0) {
            // Unit elision: Ok() is accepted only in Unit-like (i32-backed) payload positions.
            if (self.expected_type) |et| {
                if (self.isResultType(et)) {
                    const payload_ty = self.findEnumPayloadType(et, 0) orelse i32_type;
                    if (payload_ty != i32_type) return error.UnsupportedExpr;
                }
            }
        }
        const arg_val = if (call_e.args.len == 1)
            try self.genExpr(call_e.args[0])
        else
            c.LLVMConstInt(i32_type, 0, 0);
        // Use expected_type if available (from let binding annotation or return type).
        if (self.expected_type) |et| {
            if (c.LLVMGetTypeKind(et) == c.LLVMStructTypeKind) {
                return self.buildResultOk(arg_val, et);
            }
        }
        // Default: create Result[T, i32].
        const err_type = c.LLVMInt32TypeInContext(self.context);
        const result_info = try self.getOrCreateResultType(c.LLVMTypeOf(arg_val), err_type);
        return self.buildResultOk(arg_val, result_info.llvm_type);
    }

    // Built-in: Err(val) — wraps an error in Result.
    const err_sym = self.pool.intern("Err") catch return error.CodegenAlloc;
    if (fn_sym == err_sym) {
        if (call_e.args.len != 1) return error.UnsupportedExpr;
        const arg_val = try self.genExpr(call_e.args[0]);
        if (self.expected_type) |et| {
            if (c.LLVMGetTypeKind(et) == c.LLVMStructTypeKind) {
                return self.buildResultErr(arg_val, et);
            }
        }
        // Default: create Result[i32, T].
        const ok_type = c.LLVMInt32TypeInContext(self.context);
        const result_info = try self.getOrCreateResultType(ok_type, c.LLVMTypeOf(arg_val));
        return self.buildResultErr(arg_val, result_info.llvm_type);
    }

    // Built-in: Channel(capacity) — create a new channel
    const channel_sym = self.pool.intern("Channel") catch return error.CodegenAlloc;
    if (fn_sym == channel_sym and self.functions.get(fn_sym) == null and self.generic_fns.get(fn_sym) == null) {
        return self.genChannelCreate(call_e.args);
    }

    // Built-in: send(ch, value) — send to channel
    const send_sym = self.pool.intern("send") catch return error.CodegenAlloc;
    if (fn_sym == send_sym and self.functions.get(fn_sym) == null and self.generic_fns.get(fn_sym) == null) {
        return self.genChannelSend(call_e.args);
    }

    // Built-in: recv(ch) — receive from channel
    const recv_sym = self.pool.intern("recv") catch return error.CodegenAlloc;
    if (fn_sym == recv_sym and self.functions.get(fn_sym) == null and self.generic_fns.get(fn_sym) == null) {
        return self.genChannelRecv(call_e.args);
    }

    // Built-in: close(ch) — close a channel
    const close_sym = self.pool.intern("close") catch return error.CodegenAlloc;
    if (fn_sym == close_sym and self.functions.get(fn_sym) == null and self.generic_fns.get(fn_sym) == null) {
        return self.genChannelClose(call_e.args);
    }

    // Built-in math functions (std.math)
    const abs_sym = self.pool.intern("abs") catch return error.CodegenAlloc;
    if (fn_sym == abs_sym) {
        return self.genMathAbs(call_e.args);
    }
    const min_sym = self.pool.intern("min") catch return error.CodegenAlloc;
    if (fn_sym == min_sym) {
        return self.genMathMin(call_e.args);
    }
    const max_sym = self.pool.intern("max") catch return error.CodegenAlloc;
    if (fn_sym == max_sym) {
        return self.genMathMax(call_e.args);
    }
    const clamp_sym = self.pool.intern("clamp") catch return error.CodegenAlloc;
    if (fn_sym == clamp_sym) {
        return self.genMathClamp(call_e.args);
    }
    const sqrt_f64_sym = self.pool.intern("sqrt_f64") catch return error.CodegenAlloc;
    if (fn_sym == sqrt_f64_sym) {
        return self.genMathUnaryF64(call_e.args, "llvm.sqrt.f64");
    }
    const pow_f64_sym = self.pool.intern("pow_f64") catch return error.CodegenAlloc;
    if (fn_sym == pow_f64_sym) {
        return self.genMathBinaryF64(call_e.args, "llvm.pow.f64");
    }
    const floor_f64_sym = self.pool.intern("floor_f64") catch return error.CodegenAlloc;
    if (fn_sym == floor_f64_sym) {
        return self.genMathUnaryF64(call_e.args, "llvm.floor.f64");
    }
    const ceil_f64_sym = self.pool.intern("ceil_f64") catch return error.CodegenAlloc;
    if (fn_sym == ceil_f64_sym) {
        return self.genMathUnaryF64(call_e.args, "llvm.ceil.f64");
    }
    const sin_f64_sym = self.pool.intern("sin_f64") catch return error.CodegenAlloc;
    if (fn_sym == sin_f64_sym) {
        return self.genMathUnaryF64(call_e.args, "llvm.sin.f64");
    }
    const cos_f64_sym = self.pool.intern("cos_f64") catch return error.CodegenAlloc;
    if (fn_sym == cos_f64_sym) {
        return self.genMathUnaryF64(call_e.args, "llvm.cos.f64");
    }
    const log_f64_sym = self.pool.intern("log_f64") catch return error.CodegenAlloc;
    if (fn_sym == log_f64_sym) {
        return self.genMathUnaryF64(call_e.args, "llvm.log.f64");
    }
    const exp_f64_sym = self.pool.intern("exp_f64") catch return error.CodegenAlloc;
    if (fn_sym == exp_f64_sym) {
        return self.genMathUnaryF64(call_e.args, "llvm.exp.f64");
    }
    const fabs_f64_sym = self.pool.intern("fabs_f64") catch return error.CodegenAlloc;
    if (fn_sym == fabs_f64_sym) {
        return self.genMathUnaryF64(call_e.args, "llvm.fabs.f64");
    }

    // Check if this is a known function.
    if (self.functions.get(fn_sym)) |fn_info| {
        var args_buf: [64]c.LLVMValueRef = undefined;
        for (call_e.args, 0..) |arg, i| {
            args_buf[i] = try self.genExpr(arg);
        }

        // Fill in default values for omitted arguments.
        const param_count: u32 = c.LLVMCountParams(fn_info.value);
        var effective_arg_count = call_e.args.len;
        if (effective_arg_count < param_count) {
            if (self.fn_default_params.get(fn_sym)) |params| {
                for (effective_arg_count..@min(params.len, param_count)) |i| {
                    if (params[i].default_value) |default_expr| {
                        args_buf[i] = try self.genExpr(default_expr);
                        effective_arg_count = i + 1;
                    }
                }
            }
        }

        // Coerce arguments to match parameter types.
        const dyn_params = self.fn_dyn_params.get(fn_sym);
        for (0..@min(effective_arg_count, param_count)) |i| {
            const param_type = c.LLVMTypeOf(c.LLVMGetParam(fn_info.value, @intCast(i)));
            const arg_type = c.LLVMTypeOf(args_buf[i]);

            // Convert concrete value → dyn Trait fat pointer.
            if (i < call_e.args.len) {
                if (dyn_params) |dp| {
                    if (i < dp.len) {
                        if (dp[i]) |trait_sym| {
                            // This param expects dyn Trait — wrap concrete arg when known.
                            if (self.dynConcreteArgInfo(call_e.args[i], arg_type)) |info| {
                                if (info.use_ptr) {
                                    args_buf[i] = try self.buildDynTraitValueFromPtr(args_buf[i], info.type_sym, trait_sym);
                                } else {
                                    args_buf[i] = try self.buildDynTraitValue(args_buf[i], info.type_sym, trait_sym);
                                }
                                continue;
                            }
                        }
                    }
                }

                // Wrap named function references as fat pointers for fn-type params.
                if (c.LLVMGetTypeKind(param_type) == c.LLVMStructTypeKind and
                    c.LLVMGetTypeKind(arg_type) == c.LLVMPointerTypeKind)
                {
                    if (call_e.args[i].kind == .ident) {
                        const arg_sym = call_e.args[i].kind.ident;
                        if (self.functions.get(arg_sym)) |arg_fn_info| {
                            args_buf[i] = try self.wrapFunctionAsFatPointer(arg_fn_info.value, arg_fn_info.fn_type);
                            continue;
                        }
                    }
                }
            }

            // Auto-referencing: if param is &T (pointer) and arg is T (struct value),
            // auto-insert alloca to create a reference. Only for shared borrows.
            const ref_params = self.fn_ref_params.get(fn_sym);
            if (ref_params) |rp| {
                if (i < rp.len and rp[i]) {
                    if (c.LLVMGetTypeKind(param_type) == c.LLVMPointerTypeKind and
                        c.LLVMGetTypeKind(arg_type) == c.LLVMStructTypeKind)
                    {
                        // Auto-alloca the value and pass the pointer.
                        const tmp = c.LLVMBuildAlloca(self.builder, arg_type, "autoref");
                        _ = c.LLVMBuildStore(self.builder, args_buf[i], tmp);
                        args_buf[i] = tmp;
                        continue;
                    }
                }
            }

            // Auto-coerce c"..." → str when the callee expects a struct-like string parameter.
            if (i < call_e.args.len and call_e.args[i].kind == .c_string_literal and
                c.LLVMGetTypeKind(arg_type) == c.LLVMPointerTypeKind and
                c.LLVMGetTypeKind(param_type) == c.LLVMStructTypeKind)
            {
                args_buf[i] = try self.cStrPtrToStr(args_buf[i]);
            } else if (self.isStrType(param_type) and c.LLVMGetTypeKind(arg_type) == c.LLVMPointerTypeKind) {
                args_buf[i] = try self.cStrPtrToStr(args_buf[i]);
            } else if (c.LLVMGetTypeKind(param_type) == c.LLVMPointerTypeKind and self.isStrType(arg_type)) {
                args_buf[i] = self.extractStrPtr(args_buf[i]);
            } else {
                args_buf[i] = try self.coerceValueForType(args_buf[i], param_type);
            }
        }

        // For variadic functions, coerce remaining args (str → ptr, float → double).
        const is_variadic = c.LLVMIsFunctionVarArg(fn_info.fn_type) != 0;
        if (is_variadic) {
            for (param_count..@intCast(effective_arg_count)) |i| {
                const arg_type = c.LLVMTypeOf(args_buf[i]);
                if (self.isStrType(arg_type)) {
                    args_buf[i] = self.extractStrPtr(args_buf[i]);
                }
                // Promote float to double for variadic (C ABI requirement)
                if (c.LLVMGetTypeKind(arg_type) == c.LLVMFloatTypeKind) {
                    args_buf[i] = c.LLVMBuildFPExt(self.builder, args_buf[i], c.LLVMDoubleTypeInContext(self.context), "");
                }
            }
        }

        // @[tailrec]: convert self-recursive call to a jump back.
        if (self.tailrec_fn_sym != null and fn_sym == self.tailrec_fn_sym.?) {
            if (self.tailrec_body_bb != null and self.tailrec_param_allocas != null) {
                const allocas = self.tailrec_param_allocas.?;
                // Store new arg values into param allocas.
                for (0..@min(effective_arg_count, allocas.len)) |i| {
                    _ = c.LLVMBuildStore(self.builder, args_buf[i], allocas[i]);
                }
                // Branch back to the start of the function body.
                _ = c.LLVMBuildBr(self.builder, self.tailrec_body_bb.?);

                // Dead block for any code after the tail call.
                const dead_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "tailrec.dead");
                c.LLVMPositionBuilderAtEnd(self.builder, dead_bb);

                return c.LLVMGetUndef(c.LLVMGetReturnType(fn_info.fn_type));
            }
        }

        const ret_type = c.LLVMGetReturnType(fn_info.fn_type);
        const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);

        return c.LLVMBuildCall2(
            self.builder,
            fn_info.fn_type,
            fn_info.value,
            if (effective_arg_count > 0) &args_buf else null,
            @intCast(effective_arg_count),
            if (is_void) "" else "call",
        );
    }

    // Check if this is a local variable holding a function pointer or closure.
    if (self.locals.get(fn_sym)) |local_info| {
        const loaded = c.LLVMBuildLoad2(self.builder, local_info.ty, local_info.alloca, "fnptr");
        const loaded_type = c.LLVMTypeOf(loaded);
        const loaded_kind = c.LLVMGetTypeKind(loaded_type);

        if (loaded_kind == c.LLVMPointerTypeKind) {
            // It's a bare function pointer (non-capturing closure or fn param).
            const arg_count: u32 = @intCast(call_e.args.len);

            const fn_type = local_info.fn_sig orelse self.inferCallableFnSigFromStorageType(local_info.ty) orelse {
                var msg_buf: [256]u8 = undefined;
                const name = self.pool.resolve(fn_sym);
                const msg = std.fmt.bufPrint(
                    &msg_buf,
                    "cannot call '{s}' without a resolved fn signature in Stage 0; add an explicit fn type",
                    .{name},
                ) catch "missing fn signature in Stage 0";
                self.codegen_error_detail = self.allocator.dupe(u8, msg) catch null;
                return error.UnsupportedExpr;
            };

            var args_buf: [64]c.LLVMValueRef = undefined;
            for (call_e.args, 0..) |arg, i| {
                args_buf[i] = try self.genExpr(arg);
            }

            // Coerce args to match fn type params.
            const param_count = c.LLVMCountParamTypes(fn_type);
            if (param_count > 0) {
                var fn_param_types: [16]c.LLVMTypeRef = undefined;
                c.LLVMGetParamTypes(fn_type, &fn_param_types);
                for (0..@min(call_e.args.len, param_count)) |i| {
                    args_buf[i] = try self.coerceValueForType(args_buf[i], fn_param_types[i]);
                }
            }

            const ret = c.LLVMGetReturnType(fn_type);
            const void_ret = ret == c.LLVMVoidTypeInContext(self.context);
            return c.LLVMBuildCall2(
                self.builder,
                fn_type,
                loaded,
                if (arg_count > 0) &args_buf else null,
                arg_count,
                if (void_ret) "" else "call",
            );
        } else if (loaded_kind == c.LLVMStructTypeKind) {
            // It's a closure fat pointer: {fn_ptr, capture_ptr}.

            // Extract fn_ptr (field 0) and capture_ptr (field 1).
            const fn_ptr = c.LLVMBuildExtractValue(self.builder, loaded, 0, "fn_ptr");
            const cap_ptr = c.LLVMBuildExtractValue(self.builder, loaded, 1, "cap_ptr");

            const arg_count: u32 = @intCast(call_e.args.len);
            const total_params = 1 + arg_count;

            // Require a resolved closure signature in Stage 0.
            const call_fn_type = local_info.fn_sig orelse self.inferCallableFnSigFromStorageType(local_info.ty) orelse {
                var msg_buf: [256]u8 = undefined;
                const name = self.pool.resolve(fn_sym);
                const msg = std.fmt.bufPrint(
                    &msg_buf,
                    "cannot call closure '{s}' without a resolved fn signature in Stage 0; add explicit fn type annotations",
                    .{name},
                ) catch "missing closure signature in Stage 0";
                self.codegen_error_detail = self.allocator.dupe(u8, msg) catch null;
                return error.UnsupportedExpr;
            };

            // Build args: [capture_ptr, user_args...]
            var args_buf: [65]c.LLVMValueRef = undefined;
            args_buf[0] = cap_ptr;
            for (call_e.args, 0..) |arg, i| {
                args_buf[1 + i] = try self.genExpr(arg);
            }

            // Coerce user args to match fn_sig params (skip ctx param at index 0).
            const sig_param_count = c.LLVMCountParamTypes(call_fn_type);
            if (sig_param_count > 1) {
                var fn_param_types_arr: [17]c.LLVMTypeRef = undefined;
                c.LLVMGetParamTypes(call_fn_type, &fn_param_types_arr);
                for (1..@min(1 + call_e.args.len, sig_param_count)) |pi| {
                    args_buf[pi] = try self.coerceValueForType(args_buf[pi], fn_param_types_arr[pi]);
                }
            }

            const ret_type = c.LLVMGetReturnType(call_fn_type);
            const void_ret = ret_type == c.LLVMVoidTypeInContext(self.context);

            return c.LLVMBuildCall2(
                self.builder,
                call_fn_type,
                fn_ptr,
                &args_buf,
                total_params,
                if (void_ret) "" else "call",
            );
        }
    }

    // Check if this is a generic function that needs monomorphization.
    if (self.generic_fns.get(fn_sym)) |gen_fn| {
        return self.monomorphizeCall(gen_fn, call_e.args);
    }

    // Check if this is an enum variant constructor.
    {
        var e_it = self.enum_types.iterator();
        while (e_it.next()) |entry| {
            const e_sym = entry.key_ptr.*;
            const ei = entry.value_ptr.*;
            for (ei.variant_names, 0..) |vn, vi| {
                if (vn == fn_sym) {
                    _ = vi;
                    return self.genEnumVariant(.{
                        .type_name = e_sym,
                        .variant_name = fn_sym,
                        .args = call_e.args,
                    });
                }
            }
        }
    }

    return error.UnsupportedExpr;
}

fn monomorphizeCall(self: *Codegen, gen_fn: Ast.FnDecl, args: []const *const Ast.Expr) Error!c.LLVMValueRef {
    // Step 1: evaluate all arguments to get LLVM values and types.
    var args_buf: [64]c.LLVMValueRef = undefined;
    var arg_types: [64]c.LLVMTypeRef = undefined;
    for (args, 0..) |arg, i| {
        args_buf[i] = try self.genExpr(arg);
        arg_types[i] = c.LLVMTypeOf(args_buf[i]);
    }

    // Step 2: infer type parameters from argument types.
    // Build a mapping: type_param Symbol → LLVM type.
    var type_map: [16]TypeBinding = undefined;
    var type_map_len: u32 = 0;

    for (gen_fn.params, 0..) |param, i| {
        if (i >= args.len) break;
        if (param.type_expr) |te| {
            self.inferTypeParams(te, arg_types[i], gen_fn.type_params, &type_map, &type_map_len);
            // Refine generic fn-type bindings from closure annotations when available.
            if (te.kind == .fn_type and args[i].kind == .closure) {
                const expected_ft = te.kind.fn_type;
                const cl = args[i].kind.closure;

                if (cl.return_type) |rt| {
                    const rt_ty = self.resolveType(rt) catch null;
                    if (rt_ty) |ty| {
                        self.inferTypeParams(expected_ft.return_type, ty, gen_fn.type_params, &type_map, &type_map_len);
                    }
                }

                const n = @min(expected_ft.params.len, cl.param_types.len);
                for (0..n) |pi| {
                    if (cl.param_types[pi]) |pt| {
                        const pt_ty = self.resolveType(pt) catch null;
                        if (pt_ty) |ty| {
                            self.inferTypeParams(expected_ft.params[pi], ty, gen_fn.type_params, &type_map, &type_map_len);
                        }
                    }
                }
            }
        }
    }

    // Step 3: build mangled name for this specialization.
    var mangled_buf: [256]u8 = undefined;
    const base_name = self.pool.resolve(gen_fn.name);
    var pos: usize = 0;
    @memcpy(mangled_buf[pos..][0..base_name.len], base_name);
    pos += base_name.len;
    for (gen_fn.type_params) |tp| {
        mangled_buf[pos] = '_';
        pos += 1;
        mangled_buf[pos] = '_';
        pos += 1;
        const type_name = self.llvmTypeName(self.lookupTypeParam(tp.name, &type_map, type_map_len));
        @memcpy(mangled_buf[pos..][0..type_name.len], type_name);
        pos += type_name.len;
    }
    mangled_buf[pos] = 0;
    const mangled_z: [*:0]const u8 = @ptrCast(mangled_buf[0..pos :0]);

    // Step 4: check cache.
    const cache_key = std.hash.Wyhash.hash(0, mangled_buf[0..pos]);
    if (self.mono_cache.get(cache_key)) |fn_info| {
        // Already monomorphized. Just call it.
        const ret_type = c.LLVMGetReturnType(fn_info.fn_type);
        const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
        return c.LLVMBuildCall2(
            self.builder,
            fn_info.fn_type,
            fn_info.value,
            if (args.len > 0) &args_buf else null,
            @intCast(args.len),
            if (is_void) "" else "call",
        );
    }

    // Step 5: monomorphize — create a specialized function.
    // Resolve parameter types with type_map substitution.
    const param_count: u32 = @intCast(gen_fn.params.len);
    var param_types: [64]c.LLVMTypeRef = undefined;
    for (gen_fn.params, 0..) |param, i| {
        if (param.type_expr) |te| {
            param_types[i] = self.resolveTypeWithParams(te, gen_fn.type_params, &type_map, type_map_len) catch
                return error.UnsupportedType;
        } else if (i < args.len) {
            param_types[i] = arg_types[i];
        } else {
            param_types[i] = c.LLVMInt32TypeInContext(self.context);
        }
    }

    // Resolve return type.
    const ret_llvm_type = if (gen_fn.return_type) |rt|
        self.resolveTypeWithParams(rt, gen_fn.type_params, &type_map, type_map_len) catch
            return error.UnsupportedType
    else
        c.LLVMInt32TypeInContext(self.context);

    const fn_type = c.LLVMFunctionType(ret_llvm_type, &param_types, param_count, 0);
    const function = c.LLVMAddFunction(self.module, mangled_z, fn_type);

    // Save to cache.
    const fn_info: FnInfo = .{ .value = function, .fn_type = fn_type };
    self.mono_cache.put(self.allocator, cache_key, fn_info) catch return error.CodegenAlloc;

    // Save/restore codegen state.
    const saved_function = self.current_function;
    const saved_ret_type = self.current_ret_type;
    const saved_bb = c.LLVMGetInsertBlock(self.builder);
    const saved_locals = self.locals;
    const saved_task_locals = self.task_locals;
    const saved_task_result_locals = self.task_local_result_types;
    const saved_task_container_locals = self.task_container_local_elem_types;
    const saved_type_bindings = self.active_type_bindings;
    const saved_type_bindings_len = self.active_type_bindings_len;

    self.current_function = function;
    self.current_ret_type = ret_llvm_type;
    self.locals = .empty;
    self.task_locals = .{};
    self.task_local_result_types = .{};
    self.task_container_local_elem_types = .{};
    self.active_type_bindings_len = type_map_len;
    for (0..type_map_len) |i| {
        self.active_type_bindings[i] = type_map[i];
    }

    const entry = c.LLVMAppendBasicBlockInContext(self.context, function, "entry");
    c.LLVMPositionBuilderAtEnd(self.builder, entry);

    // Add parameters as locals.
    for (gen_fn.params, 0..) |param, i| {
        const param_val = c.LLVMGetParam(function, @intCast(i));
        const param_type = c.LLVMTypeOf(param_val);
        const alloca = c.LLVMBuildAlloca(self.builder, param_type, "");
        _ = c.LLVMBuildStore(self.builder, param_val, alloca);
        var fn_sig: ?c.LLVMTypeRef = null;
        if (param.type_expr) |te| {
            if (te.kind == .fn_type) {
                const ft = te.kind.fn_type;
                const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
                var fn_param_types: [17]c.LLVMTypeRef = undefined;
                fn_param_types[0] = ptr_type; // closure ctx/captures pointer
                for (ft.params, 0..) |p, pi| {
                    fn_param_types[1 + pi] = try self.resolveTypeWithParams(p, gen_fn.type_params, &type_map, type_map_len);
                }
                const fn_ret_type = try self.resolveTypeWithParams(ft.return_type, gen_fn.type_params, &type_map, type_map_len);
                fn_sig = c.LLVMFunctionType(fn_ret_type, &fn_param_types, @intCast(1 + ft.params.len), 0);
            }
        }
        self.locals.put(self.allocator, param.name, .{
            .alloca = alloca,
            .ty = param_type,
            .is_mut = param.is_mut,
            .fn_sig = fn_sig,
        }) catch return error.CodegenAlloc;

        if (param.type_expr) |te| {
            if (self.typeExprTaskResultTypeWithParams(te, gen_fn.type_params, &type_map, type_map_len)) |task_result_ty| {
                self.task_locals.put(self.allocator, param.name, {}) catch return error.CodegenAlloc;
                self.task_local_result_types.put(self.allocator, param.name, task_result_ty) catch return error.CodegenAlloc;
            }
            if (self.typeExprTaskContainerElementTypeWithParams(te, gen_fn.type_params, &type_map, type_map_len)) |task_elem_ty| {
                self.task_container_local_elem_types.put(self.allocator, param.name, task_elem_ty) catch return error.CodegenAlloc;
            }
        }
    }

    // Generate body.
    const body_val = try self.genExpr(gen_fn.body);

    // Emit implicit return if needed.
    const current_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(current_bb) == null) {
        const is_void = ret_llvm_type == c.LLVMVoidTypeInContext(self.context);
        if (!is_void) {
            const coerced = try self.coerceValueForType(body_val, ret_llvm_type);
            _ = c.LLVMBuildRet(self.builder, coerced);
        } else {
            _ = c.LLVMBuildRetVoid(self.builder);
        }
    }

    // Restore state.
    self.locals.deinit(self.allocator);
    self.task_locals.deinit(self.allocator);
    self.task_local_result_types.deinit(self.allocator);
    self.task_container_local_elem_types.deinit(self.allocator);
    self.current_function = saved_function;
    self.current_ret_type = saved_ret_type;
    self.locals = saved_locals;
    self.task_locals = saved_task_locals;
    self.task_local_result_types = saved_task_result_locals;
    self.task_container_local_elem_types = saved_task_container_locals;
    self.active_type_bindings = saved_type_bindings;
    self.active_type_bindings_len = saved_type_bindings_len;
    c.LLVMPositionBuilderAtEnd(self.builder, saved_bb);

    // Now call the monomorphized function.
    // Coerce args to match the specialization's param types.
    for (0..@min(args.len, param_count)) |i| {
        args_buf[i] = try self.coerceValueForType(args_buf[i], param_types[i]);
    }

    const is_void = ret_llvm_type == c.LLVMVoidTypeInContext(self.context);
    return c.LLVMBuildCall2(
        self.builder,
        fn_type,
        function,
        if (args.len > 0) &args_buf else null,
        @intCast(args.len),
        if (is_void) "" else "call",
    );
}

fn inferTypeParams(
    self: *Codegen,
    type_expr: *const Ast.TypeExpr,
    arg_type: c.LLVMTypeRef,
    type_params: []const Ast.TypeParam,
    type_map: *[16]TypeBinding,
    type_map_len: *u32,
) void {
    switch (type_expr.kind) {
        .named => |sym| {
            // Check if this is a type parameter.
            for (type_params) |tp| {
                if (tp.name == sym) {
                    // Check if already bound.
                    for (type_map[0..type_map_len.*]) |entry| {
                        if (entry.sym == sym) return; // already bound
                    }
                    if (type_map_len.* < 16) {
                        type_map[type_map_len.*] = .{ .sym = sym, .ty = arg_type };
                        type_map_len.* += 1;
                    }
                    return;
                }
            }
        },
        .ptr_type, .ref_type => {
            // If the arg is a pointer, try to infer from pointee.
            // For now, just bind the whole thing.
        },
        .generic => |g| {
            const name = self.pool.resolve(g.name);
            if (std.mem.eql(u8, name, "Vec") and g.args.len == 1) {
                if (self.getVecElemType(arg_type)) |elem_type| {
                    self.inferTypeParams(g.args[0], elem_type, type_params, type_map, type_map_len);
                    return;
                }
            } else if (std.mem.eql(u8, name, "HashMap") and g.args.len == 2) {
                if (self.getHashMapTypeInfo(arg_type)) |hm_info| {
                    self.inferTypeParams(g.args[0], hm_info.key_type, type_params, type_map, type_map_len);
                    self.inferTypeParams(g.args[1], hm_info.val_type, type_params, type_map, type_map_len);
                    return;
                }
            } else if (std.mem.eql(u8, name, "HashSet") and g.args.len == 1) {
                if (self.getHashSetTypeInfo(arg_type)) |hs_info| {
                    self.inferTypeParams(g.args[0], hs_info.elem_type, type_params, type_map, type_map_len);
                    return;
                }
            } else if (std.mem.eql(u8, name, "Option") and g.args.len == 1) {
                if (self.isOptionOrResultType(arg_type) and !self.isResultType(arg_type)) {
                    if (self.getOptionPayloadType(arg_type)) |payload_type| {
                        self.inferTypeParams(g.args[0], payload_type, type_params, type_map, type_map_len);
                        return;
                    }
                }
            }
        },
        else => {},
    }
}

fn lookupTypeParam(
    _: *const Codegen,
    sym: u32,
    type_map: *const [16]TypeBinding,
    type_map_len: u32,
) c.LLVMTypeRef {
    for (type_map[0..type_map_len]) |entry| {
        if (entry.sym == sym) return entry.ty;
    }
    return null;
}

fn lookupActiveTypeParam(self: *const Codegen, sym: u32) ?c.LLVMTypeRef {
    for (self.active_type_bindings[0..self.active_type_bindings_len]) |entry| {
        if (entry.sym == sym) return entry.ty;
    }
    return null;
}

fn resolveTypeObjectInfo(self: *Codegen, ident_sym: u32, ident_name: []const u8) ?TypeObjectInfo {
    if (self.struct_types.get(ident_sym)) |st| {
        return .{
            .llvm_type = st.llvm_type,
            .name = ident_name,
            .struct_sym = ident_sym,
        };
    }
    if (self.enum_types.get(ident_sym)) |et| {
        return .{
            .llvm_type = et.llvm_type,
            .name = ident_name,
            .enum_sym = ident_sym,
        };
    }

    if (std.mem.eql(u8, ident_name, "i8")) return .{ .llvm_type = c.LLVMInt8TypeInContext(self.context), .name = ident_name };
    if (std.mem.eql(u8, ident_name, "i16")) return .{ .llvm_type = c.LLVMInt16TypeInContext(self.context), .name = ident_name };
    if (std.mem.eql(u8, ident_name, "i32")) return .{ .llvm_type = c.LLVMInt32TypeInContext(self.context), .name = ident_name };
    if (std.mem.eql(u8, ident_name, "i64")) return .{ .llvm_type = c.LLVMInt64TypeInContext(self.context), .name = ident_name };
    if (std.mem.eql(u8, ident_name, "u8")) return .{ .llvm_type = c.LLVMInt8TypeInContext(self.context), .name = ident_name };
    if (std.mem.eql(u8, ident_name, "u16")) return .{ .llvm_type = c.LLVMInt16TypeInContext(self.context), .name = ident_name };
    if (std.mem.eql(u8, ident_name, "u32")) return .{ .llvm_type = c.LLVMInt32TypeInContext(self.context), .name = ident_name };
    if (std.mem.eql(u8, ident_name, "u64")) return .{ .llvm_type = c.LLVMInt64TypeInContext(self.context), .name = ident_name };
    if (std.mem.eql(u8, ident_name, "bool")) return .{ .llvm_type = c.LLVMInt1TypeInContext(self.context), .name = ident_name };
    if (std.mem.eql(u8, ident_name, "f32")) return .{ .llvm_type = c.LLVMFloatTypeInContext(self.context), .name = ident_name };
    if (std.mem.eql(u8, ident_name, "f64")) return .{ .llvm_type = c.LLVMDoubleTypeInContext(self.context), .name = ident_name };

    if (self.lookupActiveTypeParam(ident_sym)) |bound_ty| {
        var info: TypeObjectInfo = .{
            .llvm_type = bound_ty,
            .name = self.llvmTypeName(bound_ty),
        };

        var st_it = self.struct_types.iterator();
        while (st_it.next()) |entry| {
            if (entry.value_ptr.llvm_type == bound_ty) {
                info.struct_sym = entry.key_ptr.*;
                info.name = self.pool.resolve(entry.key_ptr.*);
                return info;
            }
        }
        var et_it = self.enum_types.iterator();
        while (et_it.next()) |entry| {
            if (entry.value_ptr.llvm_type == bound_ty) {
                info.enum_sym = entry.key_ptr.*;
                info.name = self.pool.resolve(entry.key_ptr.*);
                return info;
            }
        }
        return info;
    }

    return null;
}

fn buildIntArrayCount(self: *Codegen, count: usize) c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const arr_type = c.LLVMArrayType2(i32_type, @intCast(count));
    return c.LLVMConstNull(arr_type);
}

fn isCopyLlvmType(self: *Codegen, ty: c.LLVMTypeRef) bool {
    const kind = c.LLVMGetTypeKind(ty);
    switch (kind) {
        c.LLVMIntegerTypeKind,
        c.LLVMFloatTypeKind,
        c.LLVMDoubleTypeKind,
        c.LLVMPointerTypeKind,
        => return true,
        c.LLVMArrayTypeKind => {
            const elem_ty = c.LLVMGetElementType(ty);
            return self.isCopyLlvmType(elem_ty);
        },
        c.LLVMStructTypeKind => {
            if (self.findStructTypeByLlvm(ty)) |st| {
                for (st.field_types) |ft| {
                    if (!self.isCopyLlvmType(ft)) return false;
                }
                return true;
            }
            return false;
        },
        else => return false,
    }
}

fn llvmTypeName(_: *const Codegen, ty: c.LLVMTypeRef) []const u8 {
    if (ty == null) return "unknown";
    const kind = c.LLVMGetTypeKind(ty);
    if (kind == c.LLVMIntegerTypeKind) {
        const width = c.LLVMGetIntTypeWidth(ty);
        return switch (width) {
            1 => "bool",
            8 => "i8",
            16 => "i16",
            32 => "i32",
            64 => "i64",
            else => "int",
        };
    }
    if (kind == c.LLVMDoubleTypeKind) return "f64";
    if (kind == c.LLVMFloatTypeKind) return "f32";
    if (kind == c.LLVMPointerTypeKind) return "ptr";
    if (kind == c.LLVMStructTypeKind) {
        const name_ptr = c.LLVMGetStructName(ty);
        if (name_ptr != null) {
            return std.mem.span(name_ptr);
        }
        return "struct";
    }
    if (kind == c.LLVMArrayTypeKind) return "array";
    return "unknown";
}

fn resolveTypeWithParams(
    self: *Codegen,
    type_expr: *const Ast.TypeExpr,
    type_params: []const Ast.TypeParam,
    type_map: *const [16]TypeBinding,
    type_map_len: u32,
) Error!c.LLVMTypeRef {
    switch (type_expr.kind) {
        .named => |sym| {
            // Check if it's a type parameter — substitute.
            for (type_params) |tp| {
                if (tp.name == sym) {
                    return lookupTypeParam(self, sym, type_map, type_map_len) orelse
                        error.UnsupportedType;
                }
            }
            // Not a type param — resolve normally.
            return self.resolveType(type_expr);
        },
        .ptr_type => |pt| {
            if (dynTraitFromTypeExpr(self, pt.pointee) != null) {
                const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
                var fat_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
                return c.LLVMStructTypeInContext(self.context, &fat_types, 2, 0);
            }
            return c.LLVMPointerTypeInContext(self.context, 0);
        },
        .ref_type => |rt| {
            if (dynTraitFromTypeExpr(self, rt.pointee) != null) {
                const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
                var fat_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
                return c.LLVMStructTypeInContext(self.context, &fat_types, 2, 0);
            }
            return c.LLVMPointerTypeInContext(self.context, 0);
        },
        .fn_type => {
            // fn types are represented as closure fat pointers {fn_ptr, captures_ptr}
            // to support both capturing and non-capturing closures uniformly.
            const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
            var fat_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
            return c.LLVMStructTypeInContext(self.context, &fat_types, 2, 0);
        },
        .array_type => |arr| {
            const elem = try self.resolveTypeWithParams(arr.element, type_params, type_map, type_map_len);
            return c.LLVMArrayType2(elem, arr.size);
        },
        .slice_type => |elem_te| {
            _ = try self.resolveTypeWithParams(elem_te, type_params, type_map, type_map_len);
            var body_types = [_]c.LLVMTypeRef{
                c.LLVMPointerTypeInContext(self.context, 0),
                c.LLVMInt64TypeInContext(self.context),
            };
            return c.LLVMStructTypeInContext(self.context, &body_types, 2, 0);
        },
        .optional => |inner| {
            const payload_type = try self.resolveTypeWithParams(inner, type_params, type_map, type_map_len);
            const opt_info = try self.getOrCreateOptionType(payload_type);
            return opt_info.llvm_type;
        },
        .tuple_type => |types| {
            var elem_types: [16]c.LLVMTypeRef = undefined;
            for (types, 0..) |t, i| {
                elem_types[i] = try self.resolveTypeWithParams(t, type_params, type_map, type_map_len);
            }
            return c.LLVMStructTypeInContext(self.context, &elem_types, @intCast(types.len), 0);
        },
        .generic => |g| {
            const name = self.pool.resolve(g.name);
            if (std.mem.eql(u8, name, "Task")) {
                if (g.args.len != 1) return error.UnsupportedType;
                // Task[T] is represented as an opaque task handle in Stage0.
                // Still resolve T so invalid payload type expressions fail early.
                _ = try self.resolveTypeWithParams(g.args[0], type_params, type_map, type_map_len);
                return c.LLVMInt32TypeInContext(self.context);
            }
            if (std.mem.eql(u8, name, "Option")) {
                if (g.args.len != 1) return error.UnsupportedType;
                const payload_type = try self.resolveTypeWithParams(g.args[0], type_params, type_map, type_map_len);
                const opt_info = try self.getOrCreateOptionType(payload_type);
                return opt_info.llvm_type;
            }
            if (std.mem.eql(u8, name, "Result")) {
                if (g.args.len != 2) return error.UnsupportedType;
                const ok_type = try self.resolveTypeWithParams(g.args[0], type_params, type_map, type_map_len);
                const err_type = try self.resolveTypeWithParams(g.args[1], type_params, type_map, type_map_len);
                const res_info = try self.getOrCreateResultType(ok_type, err_type);
                return res_info.llvm_type;
            }
            if (std.mem.eql(u8, name, "ContextError")) {
                if (g.args.len != 1) return error.UnsupportedType;
                const source_type = try self.resolveTypeWithParams(g.args[0], type_params, type_map, type_map_len);
                const ctx_info = try self.getOrCreateContextErrorType(source_type);
                return ctx_info.llvm_type;
            }
            if (std.mem.eql(u8, name, "Vec")) {
                if (g.args.len != 1) return error.UnsupportedType;
                const elem_type = try self.resolveTypeWithParams(g.args[0], type_params, type_map, type_map_len);
                const vec_info = try self.getOrCreateVecType(elem_type);
                return vec_info.llvm_type;
            }
            if (std.mem.eql(u8, name, "HashMap")) {
                if (g.args.len != 2) return error.UnsupportedType;
                const key_type = try self.resolveTypeWithParams(g.args[0], type_params, type_map, type_map_len);
                const val_type = try self.resolveTypeWithParams(g.args[1], type_params, type_map, type_map_len);
                const hm_info = try self.getOrCreateHashMapType(key_type, val_type);
                return hm_info.llvm_type;
            }
            if (std.mem.eql(u8, name, "HashSet")) {
                if (g.args.len != 1) return error.UnsupportedType;
                const elem_type = try self.resolveTypeWithParams(g.args[0], type_params, type_map, type_map_len);
                const hs_info = try self.getOrCreateHashSetType(elem_type);
                return hs_info.llvm_type;
            }
            if (std.mem.eql(u8, name, "Box")) {
                if (g.args.len != 1) return error.UnsupportedType;
                if (dynTraitFromTypeExpr(self, g.args[0]) != null) {
                    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
                    var fat_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
                    return c.LLVMStructTypeInContext(self.context, &fat_types, 2, 0);
                }
                return c.LLVMPointerTypeInContext(self.context, 0);
            }
            // User-defined generic struct: look up in generic_structs and monomorphize.
            if (self.generic_structs.get(g.name)) |gs| {
                // Resolve type arguments with the current type bindings.
                var resolved_types: [8]c.LLVMTypeRef = undefined;
                for (g.args, 0..) |arg, ai| {
                    resolved_types[ai] = try self.resolveTypeWithParams(arg, type_params, type_map, type_map_len);
                }
                // Check if already monomorphized.
                if (self.struct_types.get(gs.name)) |si| {
                    return si.llvm_type;
                }
                // Monomorphize: create concrete struct type.
                try self.monomorphizeGenericStructFromTypes(gs, resolved_types[0..g.args.len]);
                if (self.struct_types.get(gs.name)) |si| {
                    return si.llvm_type;
                }
            }
            return error.UnsupportedType;
        },
        .trait_object => {
            const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
            var fat_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
            return c.LLVMStructTypeInContext(self.context, &fat_types, 2, 0);
        },
        .inferred => return error.UnsupportedType,
    }
}

fn genCast(self: *Codegen, ca: Ast.CastExpr) Error!c.LLVMValueRef {
    const val = try self.genExpr(ca.expr);
    const target_type = try self.resolveType(ca.target_type);
    const src_type = c.LLVMTypeOf(val);

    const src_kind = c.LLVMGetTypeKind(src_type);
    const dst_kind = c.LLVMGetTypeKind(target_type);

    // Int → Int cast.
    if (src_kind == c.LLVMIntegerTypeKind and dst_kind == c.LLVMIntegerTypeKind) {
        const src_bits = c.LLVMGetIntTypeWidth(src_type);
        const dst_bits = c.LLVMGetIntTypeWidth(target_type);
        if (dst_bits > src_bits) {
            return c.LLVMBuildSExt(self.builder, val, target_type, "cast");
        } else if (dst_bits < src_bits) {
            return c.LLVMBuildTrunc(self.builder, val, target_type, "cast");
        }
        return val; // same size
    }

    // Int → Float cast.
    if (src_kind == c.LLVMIntegerTypeKind and (dst_kind == c.LLVMFloatTypeKind or dst_kind == c.LLVMDoubleTypeKind)) {
        return c.LLVMBuildSIToFP(self.builder, val, target_type, "cast");
    }

    // Float → Int cast.
    if ((src_kind == c.LLVMFloatTypeKind or src_kind == c.LLVMDoubleTypeKind) and dst_kind == c.LLVMIntegerTypeKind) {
        return c.LLVMBuildFPToSI(self.builder, val, target_type, "cast");
    }

    // Float → Float cast.
    if ((src_kind == c.LLVMFloatTypeKind or src_kind == c.LLVMDoubleTypeKind) and
        (dst_kind == c.LLVMFloatTypeKind or dst_kind == c.LLVMDoubleTypeKind))
    {
        return c.LLVMBuildFPCast(self.builder, val, target_type, "cast");
    }

    return error.UnsupportedExpr;
}

fn getMutableReceiverPtr(self: *Codegen, recv_expr: *const Ast.Expr) Error!c.LLVMValueRef {
    switch (recv_expr.kind) {
        .ident => |sym| {
            const local = self.locals.get(sym) orelse return error.UnsupportedExpr;
            if (c.LLVMGetTypeKind(local.ty) == c.LLVMPointerTypeKind) {
                if (local.pointee_struct != null) {
                    return c.LLVMBuildLoad2(self.builder, local.ty, local.alloca, "recv.ptr.self");
                }
                // Fallback for pointer locals where pointee_struct metadata is missing.
                const pointee = c.LLVMGetElementType(local.ty);
                if (c.LLVMGetTypeKind(pointee) == c.LLVMStructTypeKind) {
                    return c.LLVMBuildLoad2(self.builder, local.ty, local.alloca, "recv.ptr.load");
                }
            }
            return local.alloca;
        },
        .field_access => |fa| {
            if (fa.expr.kind == .ident) {
                const base_sym = fa.expr.kind.ident;
                const base_local = self.locals.get(base_sym) orelse return error.UnsupportedExpr;

                if (base_local.pointee_struct) |ps| {
                    const struct_info = self.struct_types.get(ps) orelse return error.UnsupportedType;
                    const idx = self.findFieldIndex(struct_info, fa.field) orelse return error.UnsupportedExpr;
                    const ptr_val = c.LLVMBuildLoad2(self.builder, base_local.ty, base_local.alloca, "recv.ptr.base");
                    return c.LLVMBuildStructGEP2(
                        self.builder,
                        struct_info.llvm_type,
                        ptr_val,
                        @intCast(idx),
                        "recv.ptr.field",
                    );
                }

                // Fallback for pointer-typed locals where pointee_struct metadata is missing.
                if (c.LLVMGetTypeKind(base_local.ty) == c.LLVMPointerTypeKind) {
                    const pointee = c.LLVMGetElementType(base_local.ty);
                    if (c.LLVMGetTypeKind(pointee) == c.LLVMStructTypeKind) {
                        if (self.findStructTypeByLlvm(pointee)) |struct_info| {
                            if (self.findFieldIndex(struct_info, fa.field)) |idx| {
                                const ptr_val = c.LLVMBuildLoad2(self.builder, base_local.ty, base_local.alloca, "recv.ptr.base");
                                return c.LLVMBuildStructGEP2(
                                    self.builder,
                                    pointee,
                                    ptr_val,
                                    @intCast(idx),
                                    "recv.ptr.field",
                                );
                            }
                        }
                    }
                }

                const struct_info = self.findStructTypeByLlvm(base_local.ty) orelse return error.UnsupportedType;
                const idx = self.findFieldIndex(struct_info, fa.field) orelse return error.UnsupportedExpr;
                return c.LLVMBuildStructGEP2(self.builder, base_local.ty, base_local.alloca, @intCast(idx), "recv.ptr.field");
            }

            // Nested field access: recursively compute pointer to the base field.
            const base_ptr = try self.getMutableReceiverPtr(fa.expr);
            const base_val = try self.genExpr(fa.expr);
            var base_ty = c.LLVMTypeOf(base_val);
            if (c.LLVMGetTypeKind(base_ty) == c.LLVMPointerTypeKind) {
                const pointee = c.LLVMGetElementType(base_ty);
                if (c.LLVMGetTypeKind(pointee) != c.LLVMStructTypeKind) return error.UnsupportedType;
                base_ty = pointee;
            }
            const struct_info = self.findStructTypeByLlvm(base_ty) orelse return error.UnsupportedType;
            const idx = self.findFieldIndex(struct_info, fa.field) orelse return error.UnsupportedExpr;
            return c.LLVMBuildStructGEP2(self.builder, base_ty, base_ptr, @intCast(idx), "recv.ptr.field");
        },
        else => return error.UnsupportedExpr,
    }
}

fn genMethodCall(self: *Codegen, fa: Ast.FieldAccessExpr, args: []const *const Ast.Expr) Error!c.LLVMValueRef {
    const method_name = self.pool.resolve(fa.field);

    // Async-scope API: s.track(task_expr)
    // Handle this before evaluating the receiver as a normal value; `s` is
    // a scope marker symbol, not a runtime object local.
    if (std.mem.eql(u8, method_name, "track") and fa.expr.kind == .ident) {
        if (self.findActiveAsyncScopeFrame(fa.expr.kind.ident)) |frame| {
            if (args.len != 1) return error.UnsupportedExpr;
            const task_val = try self.genExpr(args[0]);
            if (frame.task_count < frame.tasks.len) {
                frame.tasks[frame.task_count] = task_val;
                frame.task_count += 1;
            }
            return task_val;
        }
    }

    // Check for static method call: `Type.method(args)` where Type is a type name.
    if (fa.expr.kind == .ident) {
        const ident_sym = fa.expr.kind.ident;
        const ident_name = self.pool.resolve(ident_sym);

        // Vec static methods: Vec.new(), Vec.of(...)
        if (std.mem.eql(u8, ident_name, "Vec")) {
            if (std.mem.eql(u8, method_name, "new")) {
                // Vec.new() — requires expected_type context (from type annotation)
                if (self.expected_type) |exp| {
                    if (self.isVecType(exp)) {
                        const elem_type = self.getVecElemType(exp).?;
                        return self.genVecNew(elem_type);
                    }
                }
                // Default to Vec[i32] if no type context
                return self.genVecNew(c.LLVMInt32TypeInContext(self.context));
            } else if (std.mem.eql(u8, method_name, "of")) {
                // Vec.of(a, b, c) — infer type from first arg
                if (args.len == 0) return self.genVecNew(c.LLVMInt32TypeInContext(self.context));
                const first = try self.genExpr(args[0]);
                const elem_type = c.LLVMTypeOf(first);
                const vec_info = try self.getOrCreateVecType(elem_type);
                // Create Vec, then push all elements
                const result = try self.genVecNew(elem_type);
                const alloca = c.LLVMBuildAlloca(self.builder, vec_info.llvm_type, "vec.of");
                _ = c.LLVMBuildStore(self.builder, result, alloca);
                _ = try self.genVecPush(alloca, vec_info.llvm_type, first);
                for (args[1..]) |arg| {
                    const val = try self.genExpr(arg);
                    _ = try self.genVecPush(alloca, vec_info.llvm_type, val);
                }
                return c.LLVMBuildLoad2(self.builder, vec_info.llvm_type, alloca, "vec.of");
            }
        }

        // HashMap static methods: HashMap.new()
        if (std.mem.eql(u8, ident_name, "HashMap")) {
            if (std.mem.eql(u8, method_name, "new")) {
                if (self.expected_type) |exp| {
                    if (self.isHashMapType(exp)) {
                        const hm_info = self.getHashMapTypeInfo(exp).?;
                        return self.genHashMapNew(hm_info.key_type, hm_info.val_type);
                    }
                }
                const str_type = self.getStrType();
                return self.genHashMapNew(str_type, c.LLVMInt32TypeInContext(self.context));
            }
        }

        // HashSet static methods: HashSet.new()
        if (std.mem.eql(u8, ident_name, "HashSet")) {
            if (std.mem.eql(u8, method_name, "new")) {
                if (self.expected_type) |exp| {
                    if (self.isHashSetType(exp)) {
                        const hs_info = self.getHashSetTypeInfo(exp).?;
                        return self.genHashSetNew(hs_info.elem_type);
                    }
                }
                return self.genHashSetNew(c.LLVMInt32TypeInContext(self.context));
            }
        }

        // TypeInfo equivalent API in non-generic contexts:
        //   TypeInfo.fields(Point), TypeInfo.size(Point), ...
        if (std.mem.eql(u8, ident_name, "TypeInfo")) {
            if (args.len < 1) return error.UnsupportedExpr;
            if (args[0].kind != .ident) return error.UnsupportedExpr;
            const target_sym = args[0].kind.ident;
            const target_name = self.pool.resolve(target_sym);
            const target_obj = self.resolveTypeObjectInfo(target_sym, target_name) orelse return error.UnsupportedExpr;

            if (std.mem.eql(u8, method_name, "fields") and args.len == 1) {
                if (target_obj.struct_sym) |ss| {
                    if (self.struct_types.get(ss)) |st| {
                        return self.buildIntArrayCount(st.field_names.len);
                    }
                }
                return self.buildIntArrayCount(0);
            }
            if (std.mem.eql(u8, method_name, "variants") and args.len == 1) {
                if (target_obj.enum_sym) |es| {
                    if (self.enum_types.get(es)) |et| {
                        return self.buildIntArrayCount(et.variant_names.len);
                    }
                }
                return self.buildIntArrayCount(0);
            }
            if (std.mem.eql(u8, method_name, "name") and args.len == 1) {
                const name_sym = self.pool.intern(target_obj.name) catch return error.CodegenAlloc;
                return self.genStringLiteral(name_sym);
            }
            if (std.mem.eql(u8, method_name, "size") and args.len == 1) {
                const dl = c.LLVMGetModuleDataLayout(self.module);
                const size = c.LLVMABISizeOfType(dl, target_obj.llvm_type);
                return c.LLVMConstInt(c.LLVMInt64TypeInContext(self.context), size, 0);
            }
            if (std.mem.eql(u8, method_name, "align") and args.len == 1) {
                const dl = c.LLVMGetModuleDataLayout(self.module);
                const abi_align = c.LLVMABIAlignmentOfType(dl, target_obj.llvm_type);
                return c.LLVMConstInt(c.LLVMInt64TypeInContext(self.context), abi_align, 0);
            }
            if (std.mem.eql(u8, method_name, "is_copy") and args.len == 1) {
                return c.LLVMConstInt(
                    c.LLVMInt1TypeInContext(self.context),
                    if (self.isCopyLlvmType(target_obj.llvm_type)) 1 else 0,
                    0,
                );
            }
            if (std.mem.eql(u8, method_name, "implements") and args.len == 2) {
                // Placeholder for non-generic TypeInfo.implements API.
                return c.LLVMConstInt(c.LLVMInt1TypeInContext(self.context), 0, 0);
            }
            return error.UnsupportedExpr;
        }

        if (self.resolveTypeObjectInfo(ident_sym, ident_name)) |type_obj| {
            // Type-as-object API: T.fields(), T.variants(), T.name(), ...
            if (std.mem.eql(u8, method_name, "fields") and args.len == 0) {
                if (type_obj.struct_sym) |ss| {
                    if (self.struct_types.get(ss)) |st| {
                        return self.buildIntArrayCount(st.field_names.len);
                    }
                }
                return self.buildIntArrayCount(0);
            }
            if (std.mem.eql(u8, method_name, "variants") and args.len == 0) {
                if (type_obj.enum_sym) |es| {
                    if (self.enum_types.get(es)) |et| {
                        return self.buildIntArrayCount(et.variant_names.len);
                    }
                }
                return self.buildIntArrayCount(0);
            }
            if (std.mem.eql(u8, method_name, "name") and args.len == 0) {
                const name_sym = self.pool.intern(type_obj.name) catch return error.CodegenAlloc;
                return self.genStringLiteral(name_sym);
            }
            if (std.mem.eql(u8, method_name, "size") and args.len == 0) {
                const dl = c.LLVMGetModuleDataLayout(self.module);
                const size = c.LLVMABISizeOfType(dl, type_obj.llvm_type);
                return c.LLVMConstInt(c.LLVMInt64TypeInContext(self.context), size, 0);
            }
            if (std.mem.eql(u8, method_name, "align") and args.len == 0) {
                const dl = c.LLVMGetModuleDataLayout(self.module);
                const abi_align = c.LLVMABIAlignmentOfType(dl, type_obj.llvm_type);
                return c.LLVMConstInt(c.LLVMInt64TypeInContext(self.context), abi_align, 0);
            }
            if (std.mem.eql(u8, method_name, "is_copy") and args.len == 0) {
                return c.LLVMConstInt(
                    c.LLVMInt1TypeInContext(self.context),
                    if (self.isCopyLlvmType(type_obj.llvm_type)) 1 else 0,
                    0,
                );
            }
            if (std.mem.eql(u8, method_name, "implements") and args.len == 1) {
                // Basic placeholder for comptime-style trait queries.
                return c.LLVMConstInt(c.LLVMInt1TypeInContext(self.context), 0, 0);
            }

            // Derive(Builder)-style API: Type.builder()
            if (std.mem.eql(u8, method_name, "builder") and args.len == 0) {
                if (type_obj.struct_sym) |ss| {
                    if (self.derive_builder_types.get(ss)) |bm| {
                        const st = self.struct_types.get(ss) orelse return error.UnsupportedExpr;
                        const alloca = c.LLVMBuildAlloca(self.builder, bm.llvm_type, "builder.init");

                        // Initialize builder.value
                        const value_gep = c.LLVMBuildStructGEP2(self.builder, bm.llvm_type, alloca, 0, "");
                        const value_alloca = c.LLVMBuildAlloca(self.builder, st.llvm_type, "builder.value");
                        for (st.field_types, 0..) |ft, i| {
                            const gep = c.LLVMBuildStructGEP2(self.builder, st.llvm_type, value_alloca, @intCast(i), "");
                            const value = if (st.field_defaults[i]) |def_expr| blk: {
                                const v = try self.genExpr(def_expr);
                                break :blk self.coerceInt(v, ft);
                            } else c.LLVMConstNull(ft);
                            _ = c.LLVMBuildStore(self.builder, value, gep);
                        }
                        const init_value = c.LLVMBuildLoad2(self.builder, st.llvm_type, value_alloca, "builder.value.init");
                        _ = c.LLVMBuildStore(self.builder, init_value, value_gep);

                        // Initialize builder.mask with fields that already have defaults.
                        const mask_gep = c.LLVMBuildStructGEP2(self.builder, bm.llvm_type, alloca, 1, "");
                        const i64_type = c.LLVMInt64TypeInContext(self.context);
                        _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i64_type, bm.default_mask, 0), mask_gep);

                        return c.LLVMBuildLoad2(self.builder, bm.llvm_type, alloca, "builder.val");
                    }
                }
            }
        }

        // Slice helper methods on named locals.
        if (self.slice_elem_types.get(ident_sym)) |elem_type| {
            if (self.locals.get(ident_sym)) |slice_local| {
                if (std.mem.eql(u8, method_name, "iter")) {
                    if (args.len != 0) return error.UnsupportedExpr;
                    var slice_val: c.LLVMValueRef = undefined;
                    if (c.LLVMGetTypeKind(slice_local.ty) == c.LLVMPointerTypeKind) {
                        // Ref-slice (`&[]T`): first load the reference pointer, then
                        // load the slice struct `{ptr,len}` from that address.
                        const slice_ref = c.LLVMBuildLoad2(self.builder, slice_local.ty, slice_local.alloca, "slice.iter.ref.src");
                        var slice_fields = [_]c.LLVMTypeRef{
                            c.LLVMPointerTypeInContext(self.context, 0),
                            c.LLVMInt64TypeInContext(self.context),
                        };
                        const slice_ty = c.LLVMStructTypeInContext(self.context, &slice_fields, 2, 0);
                        slice_val = c.LLVMBuildLoad2(self.builder, slice_ty, slice_ref, "slice.iter.ref");
                    } else {
                        // By-value slice (`[]T`).
                        slice_val = c.LLVMBuildLoad2(self.builder, slice_local.ty, slice_local.alloca, "slice.iter.src");
                    }
                    return self.genSliceToVec(slice_val, elem_type);
                }
            }
        }

        const is_type = self.struct_types.get(ident_sym) != null or
            self.enum_types.get(ident_sym) != null or
            self.type_aliases.get(ident_sym) != null;
        if (is_type) {
            // Static call — no `self` arg, just call Type.method(args).
            var name_buf: [512]u8 = undefined;
            if (ident_name.len + 1 + method_name.len < name_buf.len) {
                @memcpy(name_buf[0..ident_name.len], ident_name);
                name_buf[ident_name.len] = '.';
                @memcpy(name_buf[ident_name.len + 1 ..][0..method_name.len], method_name);
                const mangled = name_buf[0 .. ident_name.len + 1 + method_name.len];
                const fn_sym = self.pool.intern(mangled) catch return error.CodegenAlloc;

                if (self.functions.get(fn_sym)) |fn_info| {
                    var args_buf: [64]c.LLVMValueRef = undefined;
                    for (args, 0..) |arg, i| {
                        args_buf[i] = try self.genExpr(arg);
                    }
                    // Coerce args.
                    const param_count: u32 = c.LLVMCountParams(fn_info.value);
                    for (0..@min(args.len, param_count)) |i| {
                        const param_type = c.LLVMTypeOf(c.LLVMGetParam(fn_info.value, @intCast(i)));
                        const arg_type = c.LLVMTypeOf(args_buf[i]);
                        if (c.LLVMGetTypeKind(param_type) == c.LLVMPointerTypeKind and
                            c.LLVMGetTypeKind(arg_type) == c.LLVMStructTypeKind)
                        {
                            if (args[i].kind == .ident) {
                                const sym = args[i].kind.ident;
                                if (self.locals.get(sym)) |local| {
                                    args_buf[i] = local.alloca;
                                    continue;
                                }
                            } else if (args[i].kind == .field_access) {
                                const fa_arg = args[i].kind.field_access;
                                if (fa_arg.expr.kind == .ident) {
                                    const base_sym = fa_arg.expr.kind.ident;
                                    if (self.locals.get(base_sym)) |base_local| {
                                        if (base_local.pointee_struct) |ps| {
                                            if (self.struct_types.get(ps)) |si| {
                                                if (self.findFieldIndex(si, fa_arg.field)) |idx| {
                                                    const base_ptr = c.LLVMBuildLoad2(self.builder, base_local.ty, base_local.alloca, "base.ptr");
                                                    const field_ptr = c.LLVMBuildStructGEP2(self.builder, si.llvm_type, base_ptr, @intCast(idx), "field.ptr");
                                                    args_buf[i] = field_ptr;
                                                    continue;
                                                }
                                            }
                                        } else if (self.findStructTypeByLlvm(base_local.ty)) |si| {
                                            if (self.findFieldIndex(si, fa_arg.field)) |idx| {
                                                const field_ptr = c.LLVMBuildStructGEP2(self.builder, base_local.ty, base_local.alloca, @intCast(idx), "field.ptr");
                                                args_buf[i] = field_ptr;
                                                continue;
                                            }
                                        }
                                    }
                                }
                            }
                            const tmp = c.LLVMBuildAlloca(self.builder, arg_type, "autoptr");
                            _ = c.LLVMBuildStore(self.builder, args_buf[i], tmp);
                            args_buf[i] = tmp;
                            continue;
                        }
                        if (i < args.len and args[i].kind == .c_string_literal and
                            c.LLVMGetTypeKind(arg_type) == c.LLVMPointerTypeKind and
                            c.LLVMGetTypeKind(param_type) == c.LLVMStructTypeKind)
                        {
                            args_buf[i] = try self.cStrPtrToStr(args_buf[i]);
                        } else if (self.isStrType(param_type) and c.LLVMGetTypeKind(arg_type) == c.LLVMPointerTypeKind) {
                            args_buf[i] = try self.cStrPtrToStr(args_buf[i]);
                        } else if (c.LLVMGetTypeKind(param_type) == c.LLVMPointerTypeKind and self.isStrType(arg_type)) {
                            args_buf[i] = self.extractStrPtr(args_buf[i]);
                        } else {
                            args_buf[i] = try self.coerceValueForType(args_buf[i], param_type);
                        }
                    }
                    const ret_type = c.LLVMGetReturnType(fn_info.fn_type);
                    const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
                    return c.LLVMBuildCall2(
                        self.builder,
                        fn_info.fn_type,
                        fn_info.value,
                        if (args.len > 0) &args_buf else null,
                        @intCast(args.len),
                        if (is_void) "" else "call",
                    );
                }
                if (self.generic_fns.get(fn_sym)) |gen_fn| {
                    return self.monomorphizeCall(gen_fn, args);
                }
            }
        }
    }

    // Evaluate the object.
    const obj_val = try self.genExpr(fa.expr);
    const obj_type = c.LLVMTypeOf(obj_val);
    var dispatch_obj_val = obj_val;
    var dispatch_obj_type = obj_type;
    if (c.LLVMGetTypeKind(obj_type) == c.LLVMPointerTypeKind) {
        const pointee = c.LLVMGetElementType(obj_type);
        const pointee_kind = c.LLVMGetTypeKind(pointee);
        if (pointee_kind == c.LLVMStructTypeKind or pointee_kind == c.LLVMArrayTypeKind) {
            dispatch_obj_type = pointee;
            dispatch_obj_val = c.LLVMBuildLoad2(self.builder, pointee, obj_val, "mcall.recv");
        }
    }

    // Derive(Builder)-style chaining on builder values:
    //   T.builder().field(v).build()
    if (self.builder_owner_by_type.get(@intFromPtr(obj_type))) |owner_sym| {
        const bm = self.derive_builder_types.get(owner_sym) orelse return error.UnsupportedExpr;
        const st = self.struct_types.get(owner_sym) orelse return error.UnsupportedExpr;

        if (std.mem.eql(u8, method_name, "build") and args.len == 0) {
            const i64_type = c.LLVMInt64TypeInContext(self.context);
            const alloca = c.LLVMBuildAlloca(self.builder, bm.llvm_type, "builder.tmp");
            _ = c.LLVMBuildStore(self.builder, obj_val, alloca);

            const mask_gep = c.LLVMBuildStructGEP2(self.builder, bm.llvm_type, alloca, 1, "");
            const mask_val = c.LLVMBuildLoad2(self.builder, i64_type, mask_gep, "builder.mask");
            const req_mask = c.LLVMConstInt(i64_type, bm.required_mask, 0);
            const set_bits = c.LLVMBuildAnd(self.builder, mask_val, req_mask, "builder.setbits");
            const has_all = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, set_bits, req_mask, "builder.ready");

            const cur_fn = self.current_function orelse return error.UnsupportedExpr;
            const then_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "builder.ready");
            const else_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "builder.missing");
            const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "builder.merge");
            _ = c.LLVMBuildCondBr(self.builder, has_all, then_bb, else_bb);

            c.LLVMPositionBuilderAtEnd(self.builder, then_bb);
            const value_gep_ok = c.LLVMBuildStructGEP2(self.builder, bm.llvm_type, alloca, 0, "");
            const ready_val = c.LLVMBuildLoad2(self.builder, st.llvm_type, value_gep_ok, "builder.value");
            const some_val = try self.buildOptionSome(ready_val);
            _ = c.LLVMBuildBr(self.builder, merge_bb);
            const then_end = c.LLVMGetInsertBlock(self.builder);

            c.LLVMPositionBuilderAtEnd(self.builder, else_bb);
            const opt_ty = try self.getOrCreateOptionType(st.llvm_type);
            const none_val = self.buildOptionNone(opt_ty.llvm_type);
            _ = c.LLVMBuildBr(self.builder, merge_bb);
            const else_end = c.LLVMGetInsertBlock(self.builder);

            c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
            var incoming_vals = [_]c.LLVMValueRef{ some_val, none_val };
            var incoming_bbs = [_]c.LLVMBasicBlockRef{ then_end, else_end };
            const phi = c.LLVMBuildPhi(self.builder, c.LLVMTypeOf(some_val), "builder.out");
            c.LLVMAddIncoming(phi, &incoming_vals, &incoming_bbs, 2);
            return phi;
        }

        if (args.len == 1) {
            if (self.findFieldIndex(st, fa.field)) |idx| {
                const alloca = c.LLVMBuildAlloca(self.builder, bm.llvm_type, "builder.set");
                _ = c.LLVMBuildStore(self.builder, obj_val, alloca);

                const value_gep = c.LLVMBuildStructGEP2(self.builder, bm.llvm_type, alloca, 0, "");
                const value_ptr = c.LLVMBuildAlloca(self.builder, st.llvm_type, "builder.value.ptr");
                const current_value = c.LLVMBuildLoad2(self.builder, st.llvm_type, value_gep, "builder.value.cur");
                _ = c.LLVMBuildStore(self.builder, current_value, value_ptr);

                const field_gep = c.LLVMBuildStructGEP2(self.builder, st.llvm_type, value_ptr, @intCast(idx), "");
                const field_val = try self.genExpr(args[0]);
                const coerced = self.coerceInt(field_val, st.field_types[idx]);
                _ = c.LLVMBuildStore(self.builder, coerced, field_gep);
                const updated_value = c.LLVMBuildLoad2(self.builder, st.llvm_type, value_ptr, "builder.value.updated");
                _ = c.LLVMBuildStore(self.builder, updated_value, value_gep);

                const mask_gep = c.LLVMBuildStructGEP2(self.builder, bm.llvm_type, alloca, 1, "");
                const i64_type = c.LLVMInt64TypeInContext(self.context);
                const old_mask = c.LLVMBuildLoad2(self.builder, i64_type, mask_gep, "builder.mask.old");
                const bit = c.LLVMConstInt(i64_type, if (idx < 64) (@as(u64, 1) << @intCast(idx)) else 0, 0);
                const new_mask = c.LLVMBuildOr(self.builder, old_mask, bit, "builder.mask.new");
                _ = c.LLVMBuildStore(self.builder, new_mask, mask_gep);

                return c.LLVMBuildLoad2(self.builder, bm.llvm_type, alloca, "builder.updated");
            }
        }
    }

    // Task API: task.cancel()
    if (std.mem.eql(u8, method_name, "cancel")) {
        if (c.LLVMGetTypeKind(obj_type) == c.LLVMIntegerTypeKind and c.LLVMGetIntTypeWidth(obj_type) == 32) {
            self.declareAsyncRuntime();
            const cancel_fn = c.LLVMGetNamedFunction(self.module, "with_fiber_cancel") orelse return error.UnsupportedExpr;
            const i32_type = c.LLVMInt32TypeInContext(self.context);
            var cancel_params = [_]c.LLVMTypeRef{i32_type};
            const cancel_ft = c.LLVMFunctionType(i32_type, &cancel_params, 1, 0);
            var cancel_args = [_]c.LLVMValueRef{obj_val};
            _ = c.LLVMBuildCall2(self.builder, cancel_ft, cancel_fn, &cancel_args, 1, "task.cancel");
            return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
        }
    }

    // Raw-pointer convenience: ptr.as_option()
    if (std.mem.eql(u8, method_name, "as_option") and c.LLVMGetTypeKind(obj_type) == c.LLVMPointerTypeKind) {
        if (args.len != 0) return error.UnsupportedExpr;
        const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
        const is_nonnull = c.LLVMBuildICmp(self.builder, c.LLVMIntNE, obj_val, c.LLVMConstNull(ptr_type), "ptr.nonnull");

        const cur_fn = self.current_function orelse return error.UnsupportedExpr;
        const some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "ptr.some");
        const none_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "ptr.none");
        const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "ptr.opt.merge");
        _ = c.LLVMBuildCondBr(self.builder, is_nonnull, some_bb, none_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, some_bb);
        const some_val = try self.buildOptionSome(obj_val);
        const opt_type = c.LLVMTypeOf(some_val);
        _ = c.LLVMBuildBr(self.builder, merge_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, none_bb);
        const none_val = self.buildOptionNone(opt_type);
        _ = c.LLVMBuildBr(self.builder, merge_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
        const phi = c.LLVMBuildPhi(self.builder, opt_type, "ptr.opt");
        var vals = [_]c.LLVMValueRef{ some_val, none_val };
        var bbs = [_]c.LLVMBasicBlockRef{ some_bb, none_bb };
        c.LLVMAddIncoming(phi, &vals, &bbs, 2);
        return phi;
    }

    // Built-in Option/Result methods: unwrap(), unwrap_or(default), is_some(), is_none(), expect(msg).
    if (c.LLVMGetTypeKind(obj_type) == c.LLVMStructTypeKind) {
        if (self.isOptionOrResultType(obj_type)) {
            if (std.mem.eql(u8, method_name, "unwrap")) {
                return self.genOptionUnwrap(obj_val, obj_type, null);
            } else if (std.mem.eql(u8, method_name, "expect")) {
                const msg = if (args.len > 0) try self.genExpr(args[0]) else null;
                return self.genOptionUnwrap(obj_val, obj_type, msg);
            } else if (std.mem.eql(u8, method_name, "unwrap_or")) {
                const i32_type = c.LLVMInt32TypeInContext(self.context);
                const default_val = if (args.len >= 1)
                    try self.genExpr(args[0])
                else blk: {
                    // Unit elision: unwrap_or() -> unwrap_or(()) in Unit-like (i32-backed) contexts.
                    const payload_ty = self.getOptionPayloadType(obj_type) orelse i32_type;
                    if (payload_ty != i32_type) return error.UnsupportedExpr;
                    break :blk c.LLVMConstInt(i32_type, 0, 0);
                };
                return self.genOptionUnwrapOr(obj_val, obj_type, default_val);
            } else if (std.mem.eql(u8, method_name, "is_some")) {
                return self.genOptionIsSome(obj_val, obj_type);
            } else if (std.mem.eql(u8, method_name, "is_none")) {
                return self.genOptionIsNone(obj_val, obj_type);
            } else if (std.mem.eql(u8, method_name, "is_ok")) {
                return self.genOptionIsSome(obj_val, obj_type);
            } else if (std.mem.eql(u8, method_name, "is_err")) {
                return self.genOptionIsNone(obj_val, obj_type);
            } else if (std.mem.eql(u8, method_name, "map")) {
                if (args.len < 1) return error.UnsupportedExpr;
                if (self.isResultType(obj_type)) {
                    return self.genResultMap(obj_val, obj_type, args[0]);
                }
                return self.genOptionMap(obj_val, obj_type, args[0]);
            } else if (std.mem.eql(u8, method_name, "and_then")) {
                if (args.len < 1) return error.UnsupportedExpr;
                if (self.isResultType(obj_type)) {
                    return self.genResultAndThen(obj_val, obj_type, args[0]);
                }
                return self.genOptionAndThen(obj_val, obj_type, args[0]);
            } else if (std.mem.eql(u8, method_name, "filter")) {
                if (args.len < 1) return error.UnsupportedExpr;
                return self.genOptionFilter(obj_val, obj_type, args[0]);
            } else if (std.mem.eql(u8, method_name, "or_else")) {
                if (args.len < 1) return error.UnsupportedExpr;
                if (self.isResultType(obj_type)) {
                    return self.genResultOrElse(obj_val, obj_type, args[0]);
                }
                return self.genOptionOrElse(obj_val, obj_type, args[0]);
            } else if (std.mem.eql(u8, method_name, "zip")) {
                if (args.len < 1) return error.UnsupportedExpr;
                if (self.isResultType(obj_type)) return error.UnsupportedExpr;
                const rhs_val = try self.genExpr(args[0]);
                const rhs_type = c.LLVMTypeOf(rhs_val);
                return self.genOptionZip(obj_val, obj_type, rhs_val, rhs_type);
            } else if (std.mem.eql(u8, method_name, "flatten")) {
                if (self.isResultType(obj_type)) return error.UnsupportedExpr;
                return self.genOptionFlatten(obj_val, obj_type);
            } else if (std.mem.eql(u8, method_name, "cloned")) {
                if (self.isResultType(obj_type)) return error.UnsupportedExpr;
                return self.genOptionCloned(obj_val, obj_type);
            } else if (std.mem.eql(u8, method_name, "transpose")) {
                if (self.isResultType(obj_type)) {
                    return self.genResultTranspose(obj_val, obj_type);
                }
                return self.genOptionTranspose(obj_val, obj_type);
            } else if (std.mem.eql(u8, method_name, "context")) {
                if (args.len < 1) return error.UnsupportedExpr;
                if (!self.isResultType(obj_type)) return error.UnsupportedExpr;
                return self.genResultContext(obj_val, obj_type, args[0]);
            } else if (std.mem.eql(u8, method_name, "with_context")) {
                if (args.len < 1) return error.UnsupportedExpr;
                if (!self.isResultType(obj_type)) return error.UnsupportedExpr;
                return self.genResultWithContext(obj_val, obj_type, args[0]);
            } else if (std.mem.eql(u8, method_name, "map_err")) {
                if (args.len < 1) return error.UnsupportedExpr;
                if (!self.isResultType(obj_type)) return error.UnsupportedExpr;
                return self.genResultMapErr(obj_val, obj_type, args[0]);
            } else if (std.mem.eql(u8, method_name, "ok")) {
                if (self.isResultType(obj_type)) {
                    return self.genResultToOk(obj_val, obj_type);
                }
            } else if (std.mem.eql(u8, method_name, "err")) {
                if (self.isResultType(obj_type)) {
                    return self.genResultToErr(obj_val, obj_type);
                }
            }
        }
    }

    // Auto-generated enum accessors: .is_X() -> bool, .as_X() -> ?T
    if (c.LLVMGetTypeKind(obj_type) == c.LLVMStructTypeKind or
        c.LLVMGetTypeKind(obj_type) == c.LLVMIntegerTypeKind)
    {
        // Determine requested variant (for disambiguation across enums that
        // share the same lowered LLVM type layout).
        var requested_variant_sym: ?u32 = null;
        if (method_name.len > 3 and std.mem.startsWith(u8, method_name, "is_")) {
            requested_variant_sym = self.pool.intern(method_name[3..]) catch return error.CodegenAlloc;
        } else if (method_name.len > 3 and std.mem.startsWith(u8, method_name, "as_")) {
            var variant_name = method_name[3..];
            if (std.mem.endsWith(u8, variant_name, "_ref")) {
                variant_name = variant_name[0 .. variant_name.len - 4];
            } else if (std.mem.endsWith(u8, variant_name, "_mut")) {
                variant_name = variant_name[0 .. variant_name.len - 4];
            }
            requested_variant_sym = self.pool.intern(variant_name) catch return error.CodegenAlloc;
        }

        // Find which enum type this is.
        // Prefer symbol-tracked enum types for locals, then resolve by variant
        // name when available, and finally fall back to first by type.
        var found_ei: ?EnumTypeInfo = null;
        if (fa.expr.kind == .ident) {
            if (self.enum_local_types.get(fa.expr.kind.ident)) |enum_sym| {
                if (self.enum_types.get(enum_sym)) |ei| {
                    if (ei.llvm_type == obj_type) {
                        found_ei = ei;
                    }
                }
            }
        }
        if (found_ei == null) {
            var fallback_ei: ?EnumTypeInfo = null;
            var ei_it = self.enum_types.iterator();
            while (ei_it.next()) |entry| {
                if (entry.value_ptr.llvm_type != obj_type) continue;
                if (fallback_ei == null) fallback_ei = entry.value_ptr.*;
                if (requested_variant_sym) |variant_sym| {
                    for (entry.value_ptr.variant_names) |vn| {
                        if (vn == variant_sym) {
                            found_ei = entry.value_ptr.*;
                            break;
                        }
                    }
                    if (found_ei != null) break;
                } else {
                    found_ei = entry.value_ptr.*;
                    break;
                }
            }
            if (found_ei == null) found_ei = fallback_ei;
        }
        if (found_ei) |ei| {
            // .is_X() → check tag == variant index
            if (method_name.len > 3 and std.mem.startsWith(u8, method_name, "is_")) {
                const variant_name = method_name[3..];
                const variant_sym = self.pool.intern(variant_name) catch return error.CodegenAlloc;
                for (ei.variant_names, 0..) |vn, idx| {
                    if (vn == variant_sym) {
                        const i32_type = c.LLVMInt32TypeInContext(self.context);
                        const has_payload = c.LLVMGetTypeKind(obj_type) == c.LLVMStructTypeKind;
                        const tag = if (has_payload) blk: {
                            const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "enum");
                            _ = c.LLVMBuildStore(self.builder, obj_val, alloca);
                            const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
                            break :blk c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
                        } else obj_val;
                        return c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, @intCast(idx), 0), "is_variant");
                    }
                }
            }

            // .as_X() → if tag matches, return Some(payload); else None
            if (method_name.len > 3 and std.mem.startsWith(u8, method_name, "as_")) {
                var variant_name = method_name[3..];
                if (std.mem.endsWith(u8, variant_name, "_ref")) {
                    variant_name = variant_name[0 .. variant_name.len - 4];
                } else if (std.mem.endsWith(u8, variant_name, "_mut")) {
                    variant_name = variant_name[0 .. variant_name.len - 4];
                }
                const variant_sym = self.pool.intern(variant_name) catch return error.CodegenAlloc;
                for (ei.variant_names, 0..) |vn, idx| {
                    if (vn == variant_sym) {
                        const i32_type = c.LLVMInt32TypeInContext(self.context);
                        const has_payload = c.LLVMGetTypeKind(obj_type) == c.LLVMStructTypeKind;

                        // Get payload type for this variant.
                        const payload_type: ?c.LLVMTypeRef = if (idx < ei.variant_payload_types.len)
                            ei.variant_payload_types[idx]
                        else
                            null;

                        if (payload_type) |pt| {
                            if (!has_payload) return error.UnsupportedExpr;

                            const alloca = c.LLVMBuildAlloca(self.builder, obj_type, "enum");
                            _ = c.LLVMBuildStore(self.builder, obj_val, alloca);
                            const tag_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 0, "tag");
                            const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag.val");
                            const is_match = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, @intCast(idx), 0), "is_variant");

                            const cur_fn = self.current_function orelse return error.UnsupportedExpr;
                            const match_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "as.match");
                            const nomatch_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "as.nomatch");
                            const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "as.merge");
                            _ = c.LLVMBuildCondBr(self.builder, is_match, match_bb, nomatch_bb);

                            // Match: extract payload, wrap in Some.
                            c.LLVMPositionBuilderAtEnd(self.builder, match_bb);
                            const payload_gep = c.LLVMBuildStructGEP2(self.builder, obj_type, alloca, 1, "payload");
                            const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
                            const payload_val = c.LLVMBuildLoad2(self.builder, pt, payload_ptr, "as.payload");
                            const some_val = try self.buildOptionSome(payload_val);
                            const opt_type = c.LLVMTypeOf(some_val);
                            _ = c.LLVMBuildBr(self.builder, merge_bb);

                            // No match: return None.
                            c.LLVMPositionBuilderAtEnd(self.builder, nomatch_bb);
                            const none_val = self.buildOptionNone(opt_type);
                            _ = c.LLVMBuildBr(self.builder, merge_bb);

                            // Merge.
                            c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
                            const phi = c.LLVMBuildPhi(self.builder, opt_type, "as.result");
                            var vals = [_]c.LLVMValueRef{ some_val, none_val };
                            var bbs = [_]c.LLVMBasicBlockRef{ match_bb, nomatch_bb };
                            c.LLVMAddIncoming(phi, &vals, &bbs, 2);
                            return phi;
                        }
                        break;
                    }
                }
            }
        }
    }

    // Built-in Vec methods: len(), get(i), is_empty(), push(val), pop().
    var vec_obj_type = obj_type;
    var vec_obj_val = obj_val;
    var vec_recv_ptr_override: ?c.LLVMValueRef = null;
    if (fa.expr.kind == .ident) {
        const recv_sym = fa.expr.kind.ident;
        if (self.vec_local_types.get(recv_sym)) |tracked_vec_ty| {
            if (tracked_vec_ty != vec_obj_type) {
                if (self.locals.get(recv_sym)) |recv_local| {
                    if (c.LLVMGetTypeKind(recv_local.ty) == c.LLVMPointerTypeKind) {
                        const vec_ptr = c.LLVMBuildLoad2(self.builder, recv_local.ty, recv_local.alloca, "vec.ref.ptr");
                        vec_recv_ptr_override = vec_ptr;
                        vec_obj_type = tracked_vec_ty;
                        vec_obj_val = c.LLVMBuildLoad2(self.builder, tracked_vec_ty, vec_ptr, "vec.ref.val");
                    } else {
                        vec_obj_type = tracked_vec_ty;
                    }
                }
            }
        } else if (!self.isVecType(vec_obj_type)) {
            // Fallback: check locals for pointer-to-vec pattern
            if (self.locals.get(recv_sym)) |recv_local| {
                if (c.LLVMGetTypeKind(recv_local.ty) == c.LLVMPointerTypeKind) {
                    if (self.isVecType(recv_local.ty)) {
                        const vec_ptr = c.LLVMBuildLoad2(self.builder, recv_local.ty, recv_local.alloca, "vec.ref.ptr");
                        vec_recv_ptr_override = vec_ptr;
                        vec_obj_type = recv_local.ty;
                        vec_obj_val = c.LLVMBuildLoad2(self.builder, recv_local.ty, vec_ptr, "vec.ref.val");
                    }
                }
            }
        }
    }
    if (self.isVecType(vec_obj_type)) {
        if (std.mem.eql(u8, method_name, "len") or std.mem.eql(u8, method_name, "count")) {
            return self.genVecLen(vec_obj_val, vec_obj_type);
        } else if (std.mem.eql(u8, method_name, "get")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const idx = try self.genExpr(args[0]);
            return self.genVecGet(vec_obj_val, vec_obj_type, idx);
        } else if (std.mem.eql(u8, method_name, "is_empty")) {
            const i64_type = c.LLVMInt64TypeInContext(self.context);
            const len = try self.genVecLen(vec_obj_val, vec_obj_type);
            return c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, len, c.LLVMConstInt(i64_type, 0, 0), "is_empty");
        } else if (std.mem.eql(u8, method_name, "push")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const val = try self.genExpr(args[0]);
            const actual_elem_ty = c.LLVMTypeOf(val);
            // If the Vec was created without a type annotation (defaulting to
            // i32), upgrade the Vec type to match the first push.
            var push_vec_type = vec_obj_type;
            const cached_elem = self.getVecElemType(vec_obj_type);
            if (cached_elem != null and cached_elem.? != actual_elem_ty) {
                const vec_info = self.getOrCreateVecType(actual_elem_ty) catch null;
                if (vec_info) |vi| {
                    push_vec_type = vi.llvm_type;
                    if (fa.expr.kind == .ident) {
                        const recv_sym = fa.expr.kind.ident;
                        self.vec_local_types.put(self.allocator, recv_sym, vi.llvm_type) catch {};
                    }
                }
            }
            const recv_ptr = vec_recv_ptr_override orelse try self.getMutableReceiverPtr(fa.expr);
            return self.genVecPush(recv_ptr, push_vec_type, val);
        } else if (std.mem.eql(u8, method_name, "set_i32")) {
            if (args.len < 2) return error.UnsupportedExpr;
            const idx = try self.genExpr(args[0]);
            const val = try self.genExpr(args[1]);
            const recv_ptr = vec_recv_ptr_override orelse try self.getMutableReceiverPtr(fa.expr);
            return self.genVecSetI32(recv_ptr, vec_obj_type, idx, val);
        } else if (std.mem.eql(u8, method_name, "pop")) {
            const recv_ptr = vec_recv_ptr_override orelse try self.getMutableReceiverPtr(fa.expr);
            return self.genVecPop(recv_ptr, vec_obj_type);
        } else if (std.mem.eql(u8, method_name, "join")) {
            // Vec[str].join(sep) → str
            if (args.len < 1) return error.UnsupportedExpr;
            const sep = try self.genExpr(args[0]);
            return self.genVecJoin(vec_obj_val, sep);
        } else if (std.mem.eql(u8, method_name, "fold")) {
            // Vec[T].fold(init, fn(acc, elem) -> acc) -> acc
            if (args.len < 2) return error.UnsupportedExpr;
            const init_val = try self.genExpr(args[0]);
            const fn_val = try self.genExpr(args[1]);
            return self.genVecFold(vec_obj_val, vec_obj_type, init_val, fn_val);
        } else if (std.mem.eql(u8, method_name, "map")) {
            // Vec[T].map(fn(elem) -> U) -> Vec[U]
            if (args.len < 1) return error.UnsupportedExpr;
            const fn_val = try self.genExpr(args[0]);
            return self.genVecMap(vec_obj_val, vec_obj_type, fn_val);
        } else if (std.mem.eql(u8, method_name, "filter")) {
            // Vec[T].filter(fn(elem) -> bool) -> Vec[T]
            if (args.len < 1) return error.UnsupportedExpr;
            const fn_val = try self.genExpr(args[0]);
            return self.genVecFilter(vec_obj_val, vec_obj_type, fn_val);
        } else if (std.mem.eql(u8, method_name, "sequence")) {
            if (args.len != 0) return error.UnsupportedExpr;
            return self.genVecSequence(vec_obj_val, vec_obj_type);
        } else if (std.mem.eql(u8, method_name, "traverse")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const fn_val = try self.genExpr(args[0]);
            return self.genVecTraverse(vec_obj_val, vec_obj_type, fn_val);
        } else if (std.mem.eql(u8, method_name, "contains")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const needle = try self.genExpr(args[0]);
            return self.genVecContains(vec_obj_val, vec_obj_type, needle);
        } else if (std.mem.eql(u8, method_name, "collect")) {
            if (args.len != 0) return error.UnsupportedExpr;
            return vec_obj_val;
        }
    }

    // Built-in HashMap methods:
    // len(), get(key), contains(key), insert(key, val), remove(key),
    // increment(key), decrement(key), update(key, default, f), append(key, value).
    if (self.isHashMapType(obj_type)) {
        if (std.mem.eql(u8, method_name, "len") or std.mem.eql(u8, method_name, "count")) {
            return self.genHashMapLen(obj_val, obj_type);
        } else if (std.mem.eql(u8, method_name, "get")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const key = try self.genExpr(args[0]);
            return self.genHashMapGet(obj_val, obj_type, key);
        } else if (std.mem.eql(u8, method_name, "contains")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const key = try self.genExpr(args[0]);
            return self.genHashMapContains(obj_val, obj_type, key);
        } else if (std.mem.eql(u8, method_name, "insert")) {
            if (args.len < 2) return error.UnsupportedExpr;
            const key = try self.genExpr(args[0]);
            const val = try self.genExpr(args[1]);
            const recv_ptr = try self.getMutableReceiverPtr(fa.expr);
            return self.genHashMapInsert(recv_ptr, obj_type, key, val);
        } else if (std.mem.eql(u8, method_name, "remove")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const key = try self.genExpr(args[0]);
            const recv_ptr = try self.getMutableReceiverPtr(fa.expr);
            return self.genHashMapRemove(recv_ptr, obj_type, key);
        } else if (std.mem.eql(u8, method_name, "increment")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const key = try self.genExpr(args[0]);
            const recv_ptr = try self.getMutableReceiverPtr(fa.expr);
            return self.genHashMapBump(recv_ptr, obj_val, obj_type, key, 1);
        } else if (std.mem.eql(u8, method_name, "decrement")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const key = try self.genExpr(args[0]);
            const recv_ptr = try self.getMutableReceiverPtr(fa.expr);
            return self.genHashMapBump(recv_ptr, obj_val, obj_type, key, -1);
        } else if (std.mem.eql(u8, method_name, "update")) {
            if (args.len < 3) return error.UnsupportedExpr;
            const key = try self.genExpr(args[0]);
            const default_val = try self.genExpr(args[1]);
            const fn_val = try self.genExpr(args[2]);
            const recv_ptr = try self.getMutableReceiverPtr(fa.expr);
            return self.genHashMapUpdate(recv_ptr, obj_val, obj_type, key, default_val, fn_val);
        } else if (std.mem.eql(u8, method_name, "append")) {
            if (args.len < 2) return error.UnsupportedExpr;
            const key = try self.genExpr(args[0]);
            const elem = try self.genExpr(args[1]);
            const recv_ptr = try self.getMutableReceiverPtr(fa.expr);
            return self.genHashMapAppend(recv_ptr, obj_val, obj_type, key, elem);
        }
    }

    // Built-in HashSet methods: len()/count, is_empty(), insert(val), contains(val), remove(val).
    if (self.isHashSetType(obj_type)) {
        if (std.mem.eql(u8, method_name, "len") or std.mem.eql(u8, method_name, "count")) {
            return self.genHashSetLen(obj_val);
        } else if (std.mem.eql(u8, method_name, "is_empty")) {
            const i64_type = c.LLVMInt64TypeInContext(self.context);
            const len = try self.genHashSetLen(obj_val);
            return c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, len, c.LLVMConstInt(i64_type, 0, 0), "is_empty");
        } else if (std.mem.eql(u8, method_name, "contains")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const val = try self.genExpr(args[0]);
            return self.genHashSetContains(obj_val, obj_type, val);
        } else if (std.mem.eql(u8, method_name, "insert")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const val = try self.genExpr(args[0]);
            const recv_ptr = try self.getMutableReceiverPtr(fa.expr);
            return self.genHashSetInsert(recv_ptr, obj_type, val);
        } else if (std.mem.eql(u8, method_name, "remove")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const val = try self.genExpr(args[0]);
            const recv_ptr = try self.getMutableReceiverPtr(fa.expr);
            return self.genHashSetRemove(recv_ptr, obj_type, val);
        }
    }

    // Built-in string methods: len(), is_empty(), contains(), starts_with(), ends_with(),
    // find(), to_upper(), to_lower(), trim(), repeat(), slice().
    if (self.isStrType(obj_type)) {
        if (std.mem.eql(u8, method_name, "to_owned") or std.mem.eql(u8, method_name, "as_view")) {
            if (args.len != 0) return error.UnsupportedExpr;
            // `str`, `String`, and `StrView` share the same lowered representation.
            return obj_val;
        } else if (std.mem.eql(u8, method_name, "len")) {
            return self.genStrLen(obj_val);
        } else if (std.mem.eql(u8, method_name, "is_empty")) {
            return self.genStrIsEmpty(obj_val);
        } else if (std.mem.eql(u8, method_name, "contains")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const needle = try self.genExpr(args[0]);
            return self.genStrContains(obj_val, needle);
        } else if (std.mem.eql(u8, method_name, "starts_with")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const prefix = try self.genExpr(args[0]);
            return self.genStrStartsWith(obj_val, prefix);
        } else if (std.mem.eql(u8, method_name, "ends_with")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const suffix = try self.genExpr(args[0]);
            return self.genStrEndsWith(obj_val, suffix);
        } else if (std.mem.eql(u8, method_name, "find")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const needle = try self.genExpr(args[0]);
            return self.genStrFind(obj_val, needle);
        } else if (std.mem.eql(u8, method_name, "to_upper")) {
            return self.genStrToCase(obj_val, true);
        } else if (std.mem.eql(u8, method_name, "to_lower")) {
            return self.genStrToCase(obj_val, false);
        } else if (std.mem.eql(u8, method_name, "trim")) {
            return self.genStrTrim(obj_val);
        } else if (std.mem.eql(u8, method_name, "repeat")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const count = try self.genExpr(args[0]);
            return self.genStrRepeat(obj_val, count);
        } else if (std.mem.eql(u8, method_name, "slice")) {
            if (args.len < 2) return error.UnsupportedExpr;
            const start = try self.genExpr(args[0]);
            const end = try self.genExpr(args[1]);
            return self.genStrSlice(obj_val, start, end);
        } else if (std.mem.eql(u8, method_name, "byte_at")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const index_val = try self.genExpr(args[0]);
            const index_i64 = self.coerceInt(index_val, c.LLVMInt64TypeInContext(self.context));
            const str_ptr = self.extractStrPtr(obj_val);
            var gep_idx = [_]c.LLVMValueRef{index_i64};
            const byte_ptr = c.LLVMBuildGEP2(
                self.builder,
                c.LLVMInt8TypeInContext(self.context),
                str_ptr,
                &gep_idx,
                1,
                "str.byte.ptr",
            );
            return c.LLVMBuildLoad2(self.builder, c.LLVMInt8TypeInContext(self.context), byte_ptr, "str.byte");
        } else if (std.mem.eql(u8, method_name, "split")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const delim = try self.genExpr(args[0]);
            return self.genStrSplit(obj_val, delim);
        } else if (std.mem.eql(u8, method_name, "replace")) {
            if (args.len < 2) return error.UnsupportedExpr;
            const old_s = try self.genExpr(args[0]);
            const new_s = try self.genExpr(args[1]);
            return self.genStrReplace(obj_val, old_s, new_s);
        }
    }

    // Built-in array methods: len()/count, is_empty(), first(), last(), contains(val).
    if (c.LLVMGetTypeKind(obj_type) == c.LLVMArrayTypeKind) {
        if (std.mem.eql(u8, method_name, "len") or std.mem.eql(u8, method_name, "count")) {
            const len = c.LLVMGetArrayLength2(obj_type);
            return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), len, 0);
        } else if (std.mem.eql(u8, method_name, "is_empty")) {
            const len = c.LLVMGetArrayLength2(obj_type);
            return c.LLVMConstInt(c.LLVMInt1TypeInContext(self.context), if (len == 0) 1 else 0, 0);
        } else if (std.mem.eql(u8, method_name, "first")) {
            return c.LLVMBuildExtractValue(self.builder, obj_val, 0, "first");
        } else if (std.mem.eql(u8, method_name, "last")) {
            const len = c.LLVMGetArrayLength2(obj_type);
            return c.LLVMBuildExtractValue(self.builder, obj_val, @intCast(len - 1), "last");
        } else if (std.mem.eql(u8, method_name, "contains")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const needle = try self.genExpr(args[0]);
            return self.genArrayContains(obj_val, obj_type, needle);
        } else if (std.mem.eql(u8, method_name, "reverse")) {
            return self.genArrayReverse(obj_val, obj_type);
        } else if (std.mem.eql(u8, method_name, "map")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const fn_val = try self.genExpr(args[0]);
            return self.genArrayMap(obj_val, obj_type, fn_val);
        } else if (std.mem.eql(u8, method_name, "reduce")) {
            if (args.len < 2) return error.UnsupportedExpr;
            const fn_val = try self.genExpr(args[0]);
            const initial = try self.genExpr(args[1]);
            return self.genArrayReduce(obj_val, obj_type, fn_val, initial);
        } else if (std.mem.eql(u8, method_name, "sum")) {
            return self.genArraySum(obj_val, obj_type);
        }
    }

    // Search struct_types for matching type.
    var type_name_str: ?[]const u8 = null;
    var type_name_sym: ?u32 = null;
    if (fa.expr.kind == .ident) {
        const recv_sym = fa.expr.kind.ident;
        if (self.locals.get(recv_sym)) |local| {
            if (local.pointee_struct) |ps| {
                type_name_sym = ps;
                type_name_str = self.pool.resolve(ps);
            }
        }
    }
    {
        if (type_name_str == null) {
            var it = self.struct_types.iterator();
            while (it.next()) |entry| {
                if (entry.value_ptr.llvm_type == dispatch_obj_type) {
                    type_name_str = self.pool.resolve(entry.key_ptr.*);
                    type_name_sym = entry.key_ptr.*;
                    break;
                }
            }
        }
    }
    // Also search enum_types.
    if (type_name_str == null) {
        var it = self.enum_types.iterator();
        while (it.next()) |entry| {
            if (entry.value_ptr.llvm_type == dispatch_obj_type) {
                type_name_str = self.pool.resolve(entry.key_ptr.*);
                type_name_sym = entry.key_ptr.*;
                break;
            }
        }
    }

    if (type_name_str) |tn| {
        const tn_sym = type_name_sym orelse 0;
        // Build mangled name "Type.method".
        var name_buf: [512]u8 = undefined;
        if (tn.len + 1 + method_name.len < name_buf.len) {
            @memcpy(name_buf[0..tn.len], tn);
            name_buf[tn.len] = '.';
            @memcpy(name_buf[tn.len + 1 ..][0..method_name.len], method_name);
            const mangled = name_buf[0 .. tn.len + 1 + method_name.len];
            const fn_sym = self.pool.intern(mangled) catch return error.CodegenAlloc;

            if (self.functions.get(fn_sym)) |fn_info| {
                // Call with obj as first arg.
                var args_buf: [64]c.LLVMValueRef = undefined;
                // Check if first param expects a pointer (e.g. self: *mut T).
                const first_param_type = if (c.LLVMCountParams(fn_info.value) > 0)
                    c.LLVMTypeOf(c.LLVMGetParam(fn_info.value, 0))
                else
                    null;
                if (first_param_type != null and c.LLVMGetTypeKind(first_param_type.?) == c.LLVMPointerTypeKind and
                    c.LLVMGetTypeKind(dispatch_obj_type) != c.LLVMPointerTypeKind)
                {
                    // Method expects pointer but we have a value.
                    // Prefer a real mutable receiver pointer (ident/field/deref lvalues);
                    // only fall back to a temporary for unsupported expressions.
                    args_buf[0] = self.getMutableReceiverPtr(fa.expr) catch blk: {
                        const tmp = c.LLVMBuildAlloca(self.builder, dispatch_obj_type, "tmp.self");
                        _ = c.LLVMBuildStore(self.builder, dispatch_obj_val, tmp);
                        break :blk tmp;
                    };
                } else {
                    args_buf[0] = dispatch_obj_val;
                }
                for (args, 0..) |arg, i| {
                    args_buf[i + 1] = try self.genExpr(arg);
                }
                const total_args = args.len + 1;

                // Coerce arguments.
                const param_count: u32 = c.LLVMCountParams(fn_info.value);
                const m_ref_params = self.fn_ref_params.get(fn_sym);
                for (0..@min(total_args, param_count)) |i| {
                    const param_type = c.LLVMTypeOf(c.LLVMGetParam(fn_info.value, @intCast(i)));
                    const arg_type = c.LLVMTypeOf(args_buf[i]);
                    // Auto-referencing for non-self args in method calls.
                    if (m_ref_params) |rp| {
                        if (i < rp.len and rp[i]) {
                            if (c.LLVMGetTypeKind(param_type) == c.LLVMPointerTypeKind and
                                c.LLVMGetTypeKind(arg_type) == c.LLVMStructTypeKind)
                            {
                                const tmp = c.LLVMBuildAlloca(self.builder, arg_type, "autoref");
                                _ = c.LLVMBuildStore(self.builder, args_buf[i], tmp);
                                args_buf[i] = tmp;
                                continue;
                            }
                        }
                    }
                    if (i < args.len and args[i].kind == .c_string_literal and
                        c.LLVMGetTypeKind(arg_type) == c.LLVMPointerTypeKind and
                        c.LLVMGetTypeKind(param_type) == c.LLVMStructTypeKind)
                    {
                        args_buf[i] = try self.cStrPtrToStr(args_buf[i]);
                    } else if (self.isStrType(param_type) and c.LLVMGetTypeKind(arg_type) == c.LLVMPointerTypeKind) {
                        args_buf[i] = try self.cStrPtrToStr(args_buf[i]);
                    } else if (c.LLVMGetTypeKind(param_type) == c.LLVMPointerTypeKind and self.isStrType(arg_type)) {
                        args_buf[i] = self.extractStrPtr(args_buf[i]);
                    } else if (c.LLVMGetTypeKind(param_type) != c.LLVMPointerTypeKind or c.LLVMGetTypeKind(arg_type) != c.LLVMPointerTypeKind) {
                        args_buf[i] = try self.coerceValueForType(args_buf[i], param_type);
                    }
                }

                const ret_type = c.LLVMGetReturnType(fn_info.fn_type);
                const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);

                return c.LLVMBuildCall2(
                    self.builder,
                    fn_info.fn_type,
                    fn_info.value,
                    &args_buf,
                    @intCast(total_args),
                    if (is_void) "" else "mcall",
                );
            }
            if (self.generic_fns.get(fn_sym)) |gen_fn| {
                var all_args: [65]*const Ast.Expr = undefined;
                all_args[0] = fa.expr;
                for (args, 0..) |arg, i| {
                    all_args[i + 1] = arg;
                }
                return self.monomorphizeCall(gen_fn, all_args[0 .. args.len + 1]);
            }

            _ = tn_sym;
        }
    }

    // Dynamic dispatch: check if the object is a dyn Trait fat pointer.
    // Identify via trait_locals map (set when param has dyn Trait type).
    if (fa.expr.kind == .ident) {
        const ident_sym = fa.expr.kind.ident;
        if (self.trait_locals.get(ident_sym)) |trait_sym| {
            if (self.trait_local_concrete_types.get(ident_sym)) |concrete_sym| {
                if (try self.genKnownConcreteDispatch(obj_val, concrete_sym, fa.field, args)) |direct| {
                    return direct;
                }
            }
            return self.genDynDispatch(obj_val, trait_sym, fa.field, args);
        }
    }

    return error.UnsupportedExpr;
}

fn genPipeline(self: *Codegen, p: Ast.PipelineExpr) Error!c.LLVMValueRef {
    // `a |> f` desugars to `f(a)`
    // `a |> f(b, c)` desugars to `f(a, b, c)` (insert lhs as first arg)
    const lhs_val = try self.genExpr(p.lhs);

    // If rhs is a call expression, prepend lhs as first argument.
    if (p.rhs.kind == .call) {
        const call_e = p.rhs.kind.call;
        const fn_sym = switch (call_e.callee.kind) {
            .ident => |sym| sym,
            else => return error.UnsupportedExpr,
        };
        if (self.functions.get(fn_sym)) |fn_info| {
            var args_buf: [64]c.LLVMValueRef = undefined;
            args_buf[0] = lhs_val;
            for (call_e.args, 0..) |arg, i| {
                args_buf[i + 1] = try self.genExpr(arg);
            }
            const total_args = call_e.args.len + 1;

            // Coerce arguments to match parameter types.
            const param_count: u32 = c.LLVMCountParams(fn_info.value);
            for (0..@min(total_args, param_count)) |i| {
                const param_type = c.LLVMTypeOf(c.LLVMGetParam(fn_info.value, @intCast(i)));
                const arg_type = c.LLVMTypeOf(args_buf[i]);
                if (c.LLVMGetTypeKind(param_type) == c.LLVMPointerTypeKind and self.isStrType(arg_type)) {
                    args_buf[i] = self.extractStrPtr(args_buf[i]);
                } else {
                    args_buf[i] = try self.coerceValueForType(args_buf[i], param_type);
                }
            }

            const ret_type = c.LLVMGetReturnType(fn_info.fn_type);
            const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);

            return c.LLVMBuildCall2(
                self.builder,
                fn_info.fn_type,
                fn_info.value,
                &args_buf,
                @intCast(total_args),
                if (is_void) "" else "pipe",
            );
        }

        if (self.generic_fns.get(fn_sym)) |gen_fn| {
            var all_args: [65]*const Ast.Expr = undefined;
            all_args[0] = p.lhs;
            for (call_e.args, 0..) |arg, i| {
                all_args[i + 1] = arg;
            }
            return self.monomorphizeCall(gen_fn, all_args[0 .. call_e.args.len + 1]);
        }

        // Method-style fallback: `lhs |> map(f)` => `lhs.map(f)`.
        return self.genMethodCall(.{
            .expr = p.lhs,
            .field = fn_sym,
        }, call_e.args) catch |err| switch (err) {
            // Implicit iterator insertion:
            // `lhs |> map(f)` -> `lhs.iter().map(f)` when direct method dispatch is unavailable.
            error.UnsupportedExpr => self.genPipelineViaImplicitIter(p.lhs, fn_sym, call_e.args),
            else => err,
        };
    }

    // If rhs is an identifier (bare function name), call as f(lhs).
    if (p.rhs.kind == .ident) {
        const fn_sym = p.rhs.kind.ident;

        // Check if it's a known top-level function.
        if (self.functions.get(fn_sym)) |fn_info| {
            var args_buf: [1]c.LLVMValueRef = .{lhs_val};

            // Coerce argument.
            const param_count: u32 = c.LLVMCountParams(fn_info.value);
            if (param_count > 0) {
                const param_type = c.LLVMTypeOf(c.LLVMGetParam(fn_info.value, 0));
                const arg_type = c.LLVMTypeOf(args_buf[0]);
                if (c.LLVMGetTypeKind(param_type) == c.LLVMPointerTypeKind and self.isStrType(arg_type)) {
                    args_buf[0] = self.extractStrPtr(args_buf[0]);
                } else {
                    args_buf[0] = try self.coerceValueForType(args_buf[0], param_type);
                }
            }

            const ret_type = c.LLVMGetReturnType(fn_info.fn_type);
            const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);

            return c.LLVMBuildCall2(
                self.builder,
                fn_info.fn_type,
                fn_info.value,
                &args_buf,
                1,
                if (is_void) "" else "pipe",
            );
        }

        // Check if it's a local variable (e.g. a closure fat pointer).
        if (self.locals.get(fn_sym)) |local_info| {
            const loaded = c.LLVMBuildLoad2(self.builder, local_info.ty, local_info.alloca, "");
            const loaded_kind = c.LLVMGetTypeKind(local_info.ty);

            if (loaded_kind == c.LLVMStructTypeKind) {
                // Closure fat pointer: {fn_ptr, capture_ptr}
                const fn_ptr = c.LLVMBuildExtractValue(self.builder, loaded, 0, "fn_ptr");
                const cap_ptr = c.LLVMBuildExtractValue(self.builder, loaded, 1, "cap_ptr");

                const call_fn_type = local_info.fn_sig orelse self.inferCallableFnSigFromStorageType(local_info.ty) orelse {
                    var msg_buf: [256]u8 = undefined;
                    const name = self.pool.resolve(fn_sym);
                    const msg = std.fmt.bufPrint(
                        &msg_buf,
                        "cannot pipeline into closure '{s}' without a resolved fn signature in Stage 0; add an explicit fn type",
                        .{name},
                    ) catch "missing closure signature in Stage 0";
                    self.codegen_error_detail = self.allocator.dupe(u8, msg) catch null;
                    return error.UnsupportedExpr;
                };
                if (c.LLVMCountParamTypes(call_fn_type) < 2) {
                    self.codegen_error_detail = self.allocator.dupe(
                        u8,
                        "pipeline closure call requires a unary closure signature in Stage 0",
                    ) catch null;
                    return error.UnsupportedExpr;
                }

                var args_buf: [2]c.LLVMValueRef = undefined;
                args_buf[0] = cap_ptr;
                var param_types_arr: [17]c.LLVMTypeRef = undefined;
                c.LLVMGetParamTypes(call_fn_type, &param_types_arr);
                args_buf[1] = try self.coerceValueForType(lhs_val, param_types_arr[1]);

                const ret_type = c.LLVMGetReturnType(call_fn_type);
                const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);

                return c.LLVMBuildCall2(
                    self.builder,
                    call_fn_type,
                    fn_ptr,
                    &args_buf,
                    2,
                    if (is_void) "" else "pipe",
                );
            }
        }

        // Method-style fallback: `lhs |> collect` => `lhs.collect()`.
        return self.genMethodCall(.{
            .expr = p.lhs,
            .field = fn_sym,
        }, &.{}) catch |err| switch (err) {
            // Implicit iterator insertion:
            // `lhs |> count` -> `lhs.iter().count` when direct method dispatch is unavailable.
            error.UnsupportedExpr => self.genPipelineViaImplicitIter(p.lhs, fn_sym, &.{}),
            else => err,
        };
    }

    return error.UnsupportedExpr;
}

fn genPipelineViaImplicitIter(
    self: *Codegen,
    lhs: *const Ast.Expr,
    fn_sym: u32,
    args: []const *const Ast.Expr,
) Error!c.LLVMValueRef {
    const method_name = self.pool.resolve(fn_sym);
    if (!(std.mem.eql(u8, method_name, "map") or
        std.mem.eql(u8, method_name, "filter") or
        std.mem.eql(u8, method_name, "count") or
        std.mem.eql(u8, method_name, "collect")))
    {
        return error.UnsupportedExpr;
    }

    const iter_sym = self.pool.intern("iter") catch return error.CodegenAlloc;
    const iter_val = self.genMethodCall(.{
        .expr = lhs,
        .field = iter_sym,
    }, &.{}) catch return error.UnsupportedExpr;

    const iter_ty = c.LLVMTypeOf(iter_val);
    if (!self.isVecType(iter_ty)) return error.UnsupportedExpr;

    if (std.mem.eql(u8, method_name, "collect")) {
        if (args.len != 0) return error.UnsupportedExpr;
        return iter_val;
    }
    if (std.mem.eql(u8, method_name, "count")) {
        if (args.len != 0) return error.UnsupportedExpr;
        return self.genVecLen(iter_val, iter_ty);
    }
    if (std.mem.eql(u8, method_name, "map")) {
        if (args.len < 1) return error.UnsupportedExpr;
        const fn_val = try self.genExpr(args[0]);
        return self.genVecMap(iter_val, iter_ty, fn_val);
    }
    if (std.mem.eql(u8, method_name, "filter")) {
        if (args.len < 1) return error.UnsupportedExpr;
        const fn_val = try self.genExpr(args[0]);
        return self.genVecFilter(iter_val, iter_ty, fn_val);
    }
    return error.UnsupportedExpr;
}

fn genReturn(self: *Codegen, ret_val: ?*const Ast.Expr) Error!c.LLVMValueRef {
    const ret_type = self.current_ret_type;
    const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
    self.current_fn_saw_explicit_return = true;

    if (ret_val) |val| {
        const v = try self.genExpr(val);
        const out_val = blk: {
            if (self.current_fn_returns_result) {
                const v_type = c.LLVMTypeOf(v);
                if (v_type == ret_type) break :blk v;
                if (self.isResultType(v_type)) return error.UnsupportedExpr;
                break :blk try self.buildResultOk(v, ret_type);
            }
            break :blk try self.coerceValueForType(v, ret_type);
        };
        // Emit drops and deferred expressions before return.
        try self.emitDrops(0);
        try self.emitDefers();
        _ = c.LLVMBuildRet(self.builder, out_val);
    } else if (is_void) {
        try self.emitDrops(0);
        try self.emitDefers();
        _ = c.LLVMBuildRetVoid(self.builder);
    } else {
        try self.emitDrops(0);
        try self.emitDefers();
        _ = c.LLVMBuildRetVoid(self.builder);
    }

    // Create a dead basic block so LLVM has a valid insertion point for any
    // code that follows the return in the same source block. Intentionally do
    // not terminate this block here; later codegen may emit additional
    // instructions/terminators into it for other syntactic paths.
    const dead_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "ret.dead");
    c.LLVMPositionBuilderAtEnd(self.builder, dead_bb);

    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn genAssign(self: *Codegen, assign: Ast.AssignExpr) Error!c.LLVMValueRef {
    switch (assign.target.kind) {
        .ident => |sym| {
            const info = self.locals.get(sym) orelse return error.UnsupportedExpr;
            if (!info.is_mut) {
                self.setAssignError(assign.target.span, self.pool.resolve(sym));
                return error.ImmutableAssign;
            }
            const val = try self.genExpr(assign.value);
            const coerced = try self.coerceValueForType(val, info.ty);
            _ = c.LLVMBuildStore(self.builder, coerced, info.alloca);
            _ = self.trait_local_concrete_types.remove(sym);
            if (self.exprProducesTask(assign.value)) {
                self.task_locals.put(self.allocator, sym, {}) catch return error.CodegenAlloc;
                if (self.inferTaskResultType(assign.value)) |task_result_ty| {
                    self.task_local_result_types.put(self.allocator, sym, task_result_ty) catch return error.CodegenAlloc;
                } else {
                    _ = self.task_local_result_types.remove(sym);
                }
            } else {
                _ = self.task_locals.remove(sym);
                _ = self.task_local_result_types.remove(sym);
            }
            if (self.inferTaskContainerElementType(assign.value)) |task_elem_ty| {
                self.task_container_local_elem_types.put(self.allocator, sym, task_elem_ty) catch return error.CodegenAlloc;
            } else {
                _ = self.task_container_local_elem_types.remove(sym);
            }
        },
        .field_access => |fa| {
            // p.x = expr → GEP into the local's alloca + store
            const obj_sym = switch (fa.expr.kind) {
                .ident => |s| s,
                else => return error.UnsupportedExpr,
            };
            const local = self.locals.get(obj_sym) orelse return error.UnsupportedExpr;
            if (!local.is_mut and local.pointee_struct == null) {
                // Allow field mutation for by-value struct parameters
                // (their alloca can be GEP'd directly for field access).
                const is_struct = self.findStructTypeByLlvm(local.ty) != null;
                if (!is_struct) {
                    self.setAssignError(assign.target.span, self.pool.resolve(obj_sym));
                    return error.ImmutableAssign;
                }
            }

            // Pointer-to-struct field assignment (e.g. self.field = val where self: *mut T).
            if (local.pointee_struct) |ps| {
                const struct_info = self.struct_types.get(ps) orelse return error.UnsupportedType;
                const idx = self.findFieldIndex(struct_info, fa.field) orelse return error.UnsupportedExpr;
                const ptr_val = c.LLVMBuildLoad2(self.builder, local.ty, local.alloca, "ptr");
                const gep = c.LLVMBuildStructGEP2(self.builder, struct_info.llvm_type, ptr_val, @intCast(idx), "");
                const val = try self.genExpr(assign.value);
                const coerced = self.coerceInt(val, struct_info.field_types[idx]);
                _ = c.LLVMBuildStore(self.builder, coerced, gep);
            } else {
                const struct_info = self.findStructTypeByLlvm(local.ty) orelse return error.UnsupportedType;
                const idx = self.findFieldIndex(struct_info, fa.field) orelse return error.UnsupportedExpr;
                const gep = c.LLVMBuildStructGEP2(self.builder, local.ty, local.alloca, @intCast(idx), "");
                const val = try self.genExpr(assign.value);
                const coerced = self.coerceInt(val, struct_info.field_types[idx]);
                _ = c.LLVMBuildStore(self.builder, coerced, gep);
            }
        },
        .index => |idx| {
            // arr[i] = expr
            const arr_sym = switch (idx.expr.kind) {
                .ident => |s| s,
                else => return error.UnsupportedExpr,
            };
            const local = self.locals.get(arr_sym) orelse return error.UnsupportedExpr;
            if (!local.is_mut) {
                self.setAssignError(assign.target.span, self.pool.resolve(arr_sym));
                return error.ImmutableAssign;
            }

            const index_val = try self.genExpr(idx.index);
            const i32_type = c.LLVMInt32TypeInContext(self.context);
            const index_i32 = self.coerceInt(index_val, i32_type);
            const zero = c.LLVMConstInt(i32_type, 0, 0);
            var indices = [_]c.LLVMValueRef{ zero, index_i32 };
            const gep = c.LLVMBuildGEP2(self.builder, local.ty, local.alloca, &indices, 2, "");

            const elem_type = c.LLVMGetElementType(local.ty);
            const val = try self.genExpr(assign.value);
            const coerced = self.coerceInt(val, elem_type);
            _ = c.LLVMBuildStore(self.builder, coerced, gep);
        },
        .unary => |un| {
            if (un.op == .deref) {
                // *ptr = expr — store through a pointer.
                const ptr_val = try self.genExpr(un.operand);
                const val = try self.genExpr(assign.value);
                const pointee_type = self.inferPointeeType(un.operand);
                const coerced = self.coerceInt(val, pointee_type);
                _ = c.LLVMBuildStore(self.builder, coerced, ptr_val);
            } else {
                return error.UnsupportedExpr;
            }
        },
        else => return error.UnsupportedExpr,
    }

    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn genWhile(self: *Codegen, while_e: Ast.WhileExpr) Error!c.LLVMValueRef {
    const function = self.current_function;
    const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "while.cond");
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "while.body");
    const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "while.end");

    // Push loop context for break/continue.
    if (self.loop_depth >= self.loop_stack.len) return error.UnsupportedExpr;
    self.loop_stack[self.loop_depth] = .{ .break_bb = end_bb, .continue_bb = cond_bb, .label = while_e.label };
    self.loop_depth += 1;

    _ = c.LLVMBuildBr(self.builder, cond_bb);

    // Condition block.
    c.LLVMPositionBuilderAtEnd(self.builder, cond_bb);
    const cond_val = try self.genExpr(while_e.condition);
    const cond_bool = self.coerceToBool(cond_val);
    _ = c.LLVMBuildCondBr(self.builder, cond_bool, body_bb, end_bb);

    // Body block.
    c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
    _ = try self.genExpr(while_e.body);
    // Only branch back to cond if body didn't terminate (e.g. via return/break/continue).
    const body_end_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(body_end_bb) == null) {
        _ = c.LLVMBuildBr(self.builder, cond_bb);
    }

    // Pop loop context.
    self.loop_depth -= 1;

    // Continue after loop.
    c.LLVMPositionBuilderAtEnd(self.builder, end_bb);

    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn genLoop(self: *Codegen, le: Ast.LoopExpr) Error!c.LLVMValueRef {
    const function = self.current_function;
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "loop.body");
    const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "loop.end");

    // Push loop context.
    if (self.loop_depth >= self.loop_stack.len) return error.UnsupportedExpr;
    self.loop_stack[self.loop_depth] = .{ .break_bb = end_bb, .continue_bb = body_bb, .label = le.label };
    self.loop_depth += 1;

    _ = c.LLVMBuildBr(self.builder, body_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
    _ = try self.genExpr(le.body);
    const body_end_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(body_end_bb) == null) {
        _ = c.LLVMBuildBr(self.builder, body_bb);
    }

    // Pop loop context — capture result_alloca before popping.
    const result_alloca = self.loop_stack[self.loop_depth - 1].result_alloca;
    self.loop_depth -= 1;

    c.LLVMPositionBuilderAtEnd(self.builder, end_bb);

    // If a break-with-value was used, load and return the result.
    if (result_alloca) |alloca| {
        const alloca_ty = c.LLVMGetAllocatedType(alloca);
        return c.LLVMBuildLoad2(self.builder, alloca_ty, alloca, "loop.val");
    }
    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn genFor(self: *Codegen, for_e: Ast.ForExpr) Error!c.LLVMValueRef {
    // Ranges iterate directly.
    if (for_e.iterable.kind == .range) {
        return self.genForRange(for_e);
    }

    // Slices iterate directly.
    if (for_e.iterable.kind == .ident) {
        if (self.slice_elem_types.get(for_e.iterable.kind.ident)) |_| {
            return self.genForSlice(for_e);
        }
    }

    // Existing local iterator variable with next().
    if (for_e.iterable.kind == .ident) {
        if (self.locals.get(for_e.iterable.kind.ident)) |local| {
            if (self.findNextMethod(local.ty) != null) {
                return self.genForIterator(for_e);
            }
        }
    }

    // Evaluate once for protocol lowering.
    const iterable_val = try self.genExpr(for_e.iterable);
    const iterable_ty = c.LLVMTypeOf(iterable_val);

    // Built-in Vec fast path.
    if (self.isVecType(iterable_ty)) {
        return self.genForVec(for_e, iterable_val);
    }

    // Iterator protocol: if expression already has next(), use as-is.
    if (self.findNextMethod(iterable_ty) != null) {
        return self.genForIteratorValue(for_e, iterable_val);
    }

    // Iterator protocol: otherwise, auto-insert .iter() when available.
    if (self.callMethodNoArgs(iterable_val, iterable_ty, "iter")) |iter_obj| {
        if (self.findNextMethod(c.LLVMTypeOf(iter_obj)) != null) {
            return self.genForIteratorValue(for_e, iter_obj);
        }
    }

    // Fall back to array iteration.
    return self.genForArray(for_e);
}

fn genForRange(self: *Codegen, for_e: Ast.ForExpr) Error!c.LLVMValueRef {
    const range = for_e.iterable.kind.range;

    const start_val = if (range.start) |s| try self.genExpr(s) else c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
    const end_val = if (range.end) |e| try self.genExpr(e) else return error.UnsupportedExpr;

    // Determine type from end value.
    const iter_type = c.LLVMTypeOf(end_val);
    const coerced_start = self.coerceInt(start_val, iter_type);

    // Create loop variable alloca.
    const alloca = c.LLVMBuildAlloca(self.builder, iter_type, "");
    _ = c.LLVMBuildStore(self.builder, coerced_start, alloca);

    if (for_e.binding_pattern == null) {
        self.locals.put(self.allocator, for_e.binding, .{
            .alloca = alloca,
            .ty = iter_type,
            .is_mut = false,
        }) catch return error.CodegenAlloc;
    }

    const function = self.current_function;
    const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.cond");
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.body");
    const inc_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.inc");
    const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.end");

    // Push loop context (continue goes to inc, break goes to end).
    if (self.loop_depth >= self.loop_stack.len) return error.UnsupportedExpr;
    self.loop_stack[self.loop_depth] = .{ .break_bb = end_bb, .continue_bb = inc_bb, .label = for_e.label };
    self.loop_depth += 1;

    _ = c.LLVMBuildBr(self.builder, cond_bb);

    // Condition: i < end (or i <= end for inclusive).
    c.LLVMPositionBuilderAtEnd(self.builder, cond_bb);
    const current = c.LLVMBuildLoad2(self.builder, iter_type, alloca, "");
    const coerced_end = self.coerceInt(end_val, iter_type);
    const cmp_op: c_uint = if (range.inclusive) c.LLVMIntSLE else c.LLVMIntSLT;
    const cond = c.LLVMBuildICmp(self.builder, cmp_op, current, coerced_end, "for.cmp");
    _ = c.LLVMBuildCondBr(self.builder, cond, body_bb, end_bb);

    // Body.
    c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
    if (for_e.binding_pattern) |bp| {
        const cur_val = c.LLVMBuildLoad2(self.builder, iter_type, alloca, "for.cur");
        try self.bindPatternFromValue(bp, cur_val, iter_type, false);
    }
    _ = try self.genExpr(for_e.body);
    const body_end_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(body_end_bb) == null) {
        _ = c.LLVMBuildBr(self.builder, inc_bb);
    }

    // Increment: i = i + 1.
    c.LLVMPositionBuilderAtEnd(self.builder, inc_bb);
    const loaded = c.LLVMBuildLoad2(self.builder, iter_type, alloca, "");
    const one = c.LLVMConstInt(iter_type, 1, 0);
    const next = c.LLVMBuildAdd(self.builder, loaded, one, "inc");
    _ = c.LLVMBuildStore(self.builder, next, alloca);
    _ = c.LLVMBuildBr(self.builder, cond_bb);

    // Pop loop context.
    self.loop_depth -= 1;

    c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn genForArray(self: *Codegen, for_e: Ast.ForExpr) Error!c.LLVMValueRef {
    // Generate the iterable expression (should be an array).
    const arr_val = try self.genExpr(for_e.iterable);
    const arr_type = c.LLVMTypeOf(arr_val);

    // Check if it's an array type.
    if (c.LLVMGetTypeKind(arr_type) != c.LLVMArrayTypeKind) return error.UnsupportedExpr;

    const arr_len = c.LLVMGetArrayLength2(arr_type);
    const elem_type = c.LLVMGetElementType(arr_type);
    const i64_type = c.LLVMInt64TypeInContext(self.context);

    // Store array to memory so we can GEP into it.
    const arr_alloca = c.LLVMBuildAlloca(self.builder, arr_type, "for.arr");
    _ = c.LLVMBuildStore(self.builder, arr_val, arr_alloca);

    // Create index variable (i64).
    const idx_alloca = c.LLVMBuildAlloca(self.builder, i64_type, "for.idx");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i64_type, 0, 0), idx_alloca);

    // Create element variable for the binding.
    const elem_alloca = c.LLVMBuildAlloca(self.builder, elem_type, "for.elem");
    const loop_task_elem_ty = self.inferTaskContainerElementType(for_e.iterable);

    if (for_e.binding_pattern == null) {
        self.locals.put(self.allocator, for_e.binding, .{
            .alloca = elem_alloca,
            .ty = elem_type,
            .is_mut = false,
        }) catch return error.CodegenAlloc;
        if (loop_task_elem_ty) |task_ty| {
            self.task_locals.put(self.allocator, for_e.binding, {}) catch return error.CodegenAlloc;
            self.task_local_result_types.put(self.allocator, for_e.binding, task_ty) catch return error.CodegenAlloc;
        } else {
            _ = self.task_locals.remove(for_e.binding);
            _ = self.task_local_result_types.remove(for_e.binding);
        }
    }

    // If there's an index binding (for x, i in arr), expose the index as a local.
    if (for_e.index_binding) |idx_sym| {
        self.locals.put(self.allocator, idx_sym, .{
            .alloca = idx_alloca,
            .ty = i64_type,
            .is_mut = false,
        }) catch return error.CodegenAlloc;
    }

    const function = self.current_function;
    const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.cond");
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.body");
    const inc_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.inc");
    const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.end");

    if (self.loop_depth >= self.loop_stack.len) return error.UnsupportedExpr;
    self.loop_stack[self.loop_depth] = .{ .break_bb = end_bb, .continue_bb = inc_bb, .label = for_e.label };
    self.loop_depth += 1;

    _ = c.LLVMBuildBr(self.builder, cond_bb);

    // Condition: idx < arr_len.
    c.LLVMPositionBuilderAtEnd(self.builder, cond_bb);
    const current_idx = c.LLVMBuildLoad2(self.builder, i64_type, idx_alloca, "idx");
    const len_val = c.LLVMConstInt(i64_type, arr_len, 0);
    const cond = c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, current_idx, len_val, "for.cmp");
    _ = c.LLVMBuildCondBr(self.builder, cond, body_bb, end_bb);

    // Body: load element, then execute body.
    c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
    var indices = [_]c.LLVMValueRef{ c.LLVMConstInt(i64_type, 0, 0), current_idx };
    const elem_ptr = c.LLVMBuildGEP2(self.builder, arr_type, arr_alloca, &indices, 2, "elem.ptr");
    const elem_val = c.LLVMBuildLoad2(self.builder, elem_type, elem_ptr, "elem");
    _ = c.LLVMBuildStore(self.builder, elem_val, elem_alloca);
    if (for_e.binding_pattern) |bp| {
        try self.bindPatternFromValue(bp, elem_val, elem_type, false);
    }

    _ = try self.genExpr(for_e.body);
    const body_end_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(body_end_bb) == null) {
        _ = c.LLVMBuildBr(self.builder, inc_bb);
    }

    // Increment index.
    c.LLVMPositionBuilderAtEnd(self.builder, inc_bb);
    const loaded_idx = c.LLVMBuildLoad2(self.builder, i64_type, idx_alloca, "idx");
    const next_idx = c.LLVMBuildAdd(self.builder, loaded_idx, c.LLVMConstInt(i64_type, 1, 0), "inc");
    _ = c.LLVMBuildStore(self.builder, next_idx, idx_alloca);
    _ = c.LLVMBuildBr(self.builder, cond_bb);

    self.loop_depth -= 1;

    c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn genForVec(self: *Codegen, for_e: Ast.ForExpr, vec_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const vec_type = c.LLVMTypeOf(vec_val);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const elem_type = self.getVecElemType(vec_type) orelse c.LLVMInt32TypeInContext(self.context);

    // Store vec to memory.
    const vec_alloca = c.LLVMBuildAlloca(self.builder, vec_type, "for.vec");
    _ = c.LLVMBuildStore(self.builder, vec_val, vec_alloca);

    // Get data pointer and length.
    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 0, "vec.ptr.ptr");
    const data_ptr = c.LLVMBuildLoad2(self.builder, c.LLVMPointerTypeInContext(self.context, 0), ptr_gep, "vec.ptr");
    const len_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 1, "vec.len.ptr");
    const vec_len = c.LLVMBuildLoad2(self.builder, i64_type, len_gep, "vec.len");

    // Create index and element variables.
    const idx_alloca = c.LLVMBuildAlloca(self.builder, i64_type, "for.idx");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i64_type, 0, 0), idx_alloca);
    const elem_alloca = c.LLVMBuildAlloca(self.builder, elem_type, "for.elem");
    const loop_task_elem_ty = self.inferTaskContainerElementType(for_e.iterable);

    if (for_e.binding_pattern == null) {
        self.locals.put(self.allocator, for_e.binding, .{
            .alloca = elem_alloca,
            .ty = elem_type,
            .is_mut = false,
        }) catch return error.CodegenAlloc;
        if (loop_task_elem_ty) |task_ty| {
            self.task_locals.put(self.allocator, for_e.binding, {}) catch return error.CodegenAlloc;
            self.task_local_result_types.put(self.allocator, for_e.binding, task_ty) catch return error.CodegenAlloc;
        } else {
            _ = self.task_locals.remove(for_e.binding);
            _ = self.task_local_result_types.remove(for_e.binding);
        }
    }

    // If there's an index binding (for x, i in vec), expose the index as a local.
    if (for_e.index_binding) |idx_sym| {
        self.locals.put(self.allocator, idx_sym, .{
            .alloca = idx_alloca,
            .ty = i64_type,
            .is_mut = false,
        }) catch return error.CodegenAlloc;
    }

    const function = self.current_function;
    const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "forvec.cond");
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "forvec.body");
    const inc_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "forvec.inc");
    const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "forvec.end");

    if (self.loop_depth >= self.loop_stack.len) return error.UnsupportedExpr;
    self.loop_stack[self.loop_depth] = .{ .break_bb = end_bb, .continue_bb = inc_bb, .label = for_e.label };
    self.loop_depth += 1;

    _ = c.LLVMBuildBr(self.builder, cond_bb);

    // Condition: idx < len.
    c.LLVMPositionBuilderAtEnd(self.builder, cond_bb);
    const current_idx = c.LLVMBuildLoad2(self.builder, i64_type, idx_alloca, "idx");
    const cond = c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, current_idx, vec_len, "for.cmp");
    _ = c.LLVMBuildCondBr(self.builder, cond, body_bb, end_bb);

    // Body: load element from data_ptr[idx].
    c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
    var gep_idx = [_]c.LLVMValueRef{current_idx};
    const elem_ptr = c.LLVMBuildGEP2(self.builder, elem_type, data_ptr, &gep_idx, 1, "elem.ptr");
    const elem_val = c.LLVMBuildLoad2(self.builder, elem_type, elem_ptr, "elem");
    _ = c.LLVMBuildStore(self.builder, elem_val, elem_alloca);
    if (for_e.binding_pattern) |bp| {
        try self.bindPatternFromValue(bp, elem_val, elem_type, false);
    }

    _ = try self.genExpr(for_e.body);
    const body_end = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(body_end) == null) {
        _ = c.LLVMBuildBr(self.builder, inc_bb);
    }

    // Increment.
    c.LLVMPositionBuilderAtEnd(self.builder, inc_bb);
    const loaded_idx = c.LLVMBuildLoad2(self.builder, i64_type, idx_alloca, "idx");
    const next_idx = c.LLVMBuildAdd(self.builder, loaded_idx, c.LLVMConstInt(i64_type, 1, 0), "inc");
    _ = c.LLVMBuildStore(self.builder, next_idx, idx_alloca);
    _ = c.LLVMBuildBr(self.builder, cond_bb);

    self.loop_depth -= 1;
    c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn genForSlice(self: *Codegen, for_e: Ast.ForExpr) Error!c.LLVMValueRef {
    const slice_sym = for_e.iterable.kind.ident;
    const local = self.locals.get(slice_sym) orelse return error.UnsupportedExpr;
    const elem_type = self.slice_elem_types.get(slice_sym) orelse return error.UnsupportedExpr;
    const i64_type = c.LLVMInt64TypeInContext(self.context);

    // Load the slice struct.
    const slice_val = c.LLVMBuildLoad2(self.builder, local.ty, local.alloca, "");
    const slice_ptr = c.LLVMBuildExtractValue(self.builder, slice_val, 0, "slice.ptr");
    const slice_len = c.LLVMBuildExtractValue(self.builder, slice_val, 1, "slice.len");

    // Create index variable.
    const idx_alloca = c.LLVMBuildAlloca(self.builder, i64_type, "for.idx");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i64_type, 0, 0), idx_alloca);

    // Create element variable for the binding.
    const elem_alloca = c.LLVMBuildAlloca(self.builder, elem_type, "for.elem");
    const loop_task_elem_ty = self.inferTaskContainerElementType(for_e.iterable);
    if (for_e.binding_pattern == null) {
        self.locals.put(self.allocator, for_e.binding, .{
            .alloca = elem_alloca,
            .ty = elem_type,
            .is_mut = false,
        }) catch return error.CodegenAlloc;
        if (loop_task_elem_ty) |task_ty| {
            self.task_locals.put(self.allocator, for_e.binding, {}) catch return error.CodegenAlloc;
            self.task_local_result_types.put(self.allocator, for_e.binding, task_ty) catch return error.CodegenAlloc;
        } else {
            _ = self.task_locals.remove(for_e.binding);
            _ = self.task_local_result_types.remove(for_e.binding);
        }
    }

    const function = self.current_function;
    const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.cond");
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.body");
    const inc_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.inc");
    const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.end");

    if (self.loop_depth >= self.loop_stack.len) return error.UnsupportedExpr;
    self.loop_stack[self.loop_depth] = .{ .break_bb = end_bb, .continue_bb = inc_bb, .label = for_e.label };
    self.loop_depth += 1;

    _ = c.LLVMBuildBr(self.builder, cond_bb);

    // Condition: idx < len.
    c.LLVMPositionBuilderAtEnd(self.builder, cond_bb);
    const current_idx = c.LLVMBuildLoad2(self.builder, i64_type, idx_alloca, "idx");
    const cond = c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, current_idx, slice_len, "for.cmp");
    _ = c.LLVMBuildCondBr(self.builder, cond, body_bb, end_bb);

    // Body: load element from ptr + idx.
    c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
    var gep_indices = [_]c.LLVMValueRef{current_idx};
    const elem_ptr = c.LLVMBuildGEP2(self.builder, elem_type, slice_ptr, &gep_indices, 1, "elem.ptr");
    const elem_val = c.LLVMBuildLoad2(self.builder, elem_type, elem_ptr, "elem");
    _ = c.LLVMBuildStore(self.builder, elem_val, elem_alloca);
    if (for_e.binding_pattern) |bp| {
        try self.bindPatternFromValue(bp, elem_val, elem_type, false);
    }

    _ = try self.genExpr(for_e.body);
    const body_end_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(body_end_bb) == null) {
        _ = c.LLVMBuildBr(self.builder, inc_bb);
    }

    // Increment index.
    c.LLVMPositionBuilderAtEnd(self.builder, inc_bb);
    const loaded_idx = c.LLVMBuildLoad2(self.builder, i64_type, idx_alloca, "idx");
    const next_idx = c.LLVMBuildAdd(self.builder, loaded_idx, c.LLVMConstInt(i64_type, 1, 0), "inc");
    _ = c.LLVMBuildStore(self.builder, next_idx, idx_alloca);
    _ = c.LLVMBuildBr(self.builder, cond_bb);

    self.loop_depth -= 1;

    c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn normalizeReceiverStructType(self: *Codegen, receiver_type: c.LLVMTypeRef) ?c.LLVMTypeRef {
    _ = self;
    if (c.LLVMGetTypeKind(receiver_type) == c.LLVMStructTypeKind) return receiver_type;
    if (c.LLVMGetTypeKind(receiver_type) == c.LLVMPointerTypeKind) {
        const elem = c.LLVMGetElementType(receiver_type);
        if (c.LLVMGetTypeKind(elem) == c.LLVMStructTypeKind) return elem;
    }
    return null;
}

fn findMethod(self: *Codegen, receiver_type: c.LLVMTypeRef, method_name: []const u8) ?FnInfo {
    const struct_type = self.normalizeReceiverStructType(receiver_type) orelse return null;

    var type_sym: ?u32 = null;
    var it = self.struct_types.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == struct_type) {
            type_sym = entry.key_ptr.*;
            break;
        }
    }
    const ts = type_sym orelse return null;
    const type_name = self.pool.resolve(ts);

    var name_buf: [256]u8 = undefined;
    if (type_name.len + 1 + method_name.len >= name_buf.len) return null;
    @memcpy(name_buf[0..type_name.len], type_name);
    name_buf[type_name.len] = '.';
    @memcpy(name_buf[type_name.len + 1 .. type_name.len + 1 + method_name.len], method_name);
    const mangled = name_buf[0 .. type_name.len + 1 + method_name.len];
    const method_sym = self.pool.intern(mangled) catch return null;
    return self.functions.get(method_sym);
}

/// Find the `Type.next` method for a struct receiver.
fn findNextMethod(self: *Codegen, receiver_type: c.LLVMTypeRef) ?FnInfo {
    return self.findMethod(receiver_type, "next");
}

/// Invoke an instance method with no explicit arguments (`obj.method()`).
/// Returns `null` when no matching method exists.
fn callMethodNoArgs(
    self: *Codegen,
    obj_val: c.LLVMValueRef,
    obj_type: c.LLVMTypeRef,
    method_name: []const u8,
) ?c.LLVMValueRef {
    const fn_info = self.findMethod(obj_type, method_name) orelse return null;
    const param_count: u32 = c.LLVMCountParams(fn_info.value);

    var call_args: [1]c.LLVMValueRef = undefined;
    var arg_count: u32 = 0;

    if (param_count > 0) {
        const self_param_type = c.LLVMTypeOf(c.LLVMGetParam(fn_info.value, 0));
        const self_param_kind = c.LLVMGetTypeKind(self_param_type);
        const obj_kind = c.LLVMGetTypeKind(obj_type);

        var self_arg = obj_val;
        if (self_param_kind == c.LLVMPointerTypeKind) {
            if (obj_kind == c.LLVMPointerTypeKind) {
                if (self_param_type != obj_type) {
                    self_arg = c.LLVMBuildBitCast(self.builder, obj_val, self_param_type, "for.self.cast");
                }
            } else {
                const tmp = c.LLVMBuildAlloca(self.builder, obj_type, "for.self.addr");
                _ = c.LLVMBuildStore(self.builder, obj_val, tmp);
                self_arg = if (self_param_type == c.LLVMTypeOf(tmp))
                    tmp
                else
                    c.LLVMBuildBitCast(self.builder, tmp, self_param_type, "for.self.cast");
            }
        } else {
            if (obj_kind == c.LLVMPointerTypeKind and c.LLVMGetTypeKind(c.LLVMGetElementType(obj_type)) == c.LLVMStructTypeKind) {
                const pointee = c.LLVMGetElementType(obj_type);
                self_arg = c.LLVMBuildLoad2(self.builder, pointee, obj_val, "for.self.load");
            }
            self_arg = self.coerceInt(self_arg, self_param_type);
        }

        call_args[0] = self_arg;
        arg_count = 1;
    }

    const ret_type = c.LLVMGetReturnType(fn_info.fn_type);
    const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
    return c.LLVMBuildCall2(
        self.builder,
        fn_info.fn_type,
        fn_info.value,
        if (arg_count == 0) null else &call_args,
        arg_count,
        if (is_void) "" else "for.mcall",
    );
}

/// Generate a for-in loop over iterator storage (`iter_ptr` points to iterator state).
fn genForIteratorFromPtr(
    self: *Codegen,
    for_e: Ast.ForExpr,
    iter_ptr: c.LLVMValueRef,
    iter_type: c.LLVMTypeRef,
) Error!c.LLVMValueRef {
    const fn_info = self.findNextMethod(iter_type) orelse return error.UnsupportedExpr;
    const i32_type = c.LLVMInt32TypeInContext(self.context);

    const function = self.current_function;
    const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "iter.cond");
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "iter.body");
    const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "iter.end");

    if (self.loop_depth >= self.loop_stack.len) return error.UnsupportedExpr;
    self.loop_stack[self.loop_depth] = .{ .break_bb = end_bb, .continue_bb = cond_bb, .label = for_e.label };
    self.loop_depth += 1;

    _ = c.LLVMBuildBr(self.builder, cond_bb);
    c.LLVMPositionBuilderAtEnd(self.builder, cond_bb);

    var call_args: [1]c.LLVMValueRef = undefined;
    var arg_count: u32 = 0;
    if (c.LLVMCountParams(fn_info.value) > 0) {
        const self_param_type = c.LLVMTypeOf(c.LLVMGetParam(fn_info.value, 0));
        var self_arg = iter_ptr;
        if (c.LLVMGetTypeKind(self_param_type) == c.LLVMPointerTypeKind) {
            if (c.LLVMTypeOf(iter_ptr) != self_param_type) {
                self_arg = c.LLVMBuildBitCast(self.builder, iter_ptr, self_param_type, "iter.self.cast");
            }
        } else {
            self_arg = c.LLVMBuildLoad2(self.builder, iter_type, iter_ptr, "iter.self");
            self_arg = self.coerceInt(self_arg, self_param_type);
        }
        call_args[0] = self_arg;
        arg_count = 1;
    }

    const result = c.LLVMBuildCall2(
        self.builder,
        fn_info.fn_type,
        fn_info.value,
        if (arg_count == 0) null else &call_args,
        arg_count,
        "next.result",
    );
    const result_type = c.LLVMTypeOf(result);

    var elem_type_opt: ?c.LLVMTypeRef = null;
    var opt_it = self.option_type_cache.iterator();
    while (opt_it.next()) |entry| {
        if (entry.value_ptr.llvm_type == result_type) {
            elem_type_opt = entry.value_ptr.payload_type;
            break;
        }
    }
    const elem_type = elem_type_opt orelse return error.UnsupportedExpr;

    // Option layout: tag == 0 -> Some(payload), tag == 1 -> None.
    const tag = c.LLVMBuildExtractValue(self.builder, result, 0, "tag");
    const is_some = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "is.some");
    _ = c.LLVMBuildCondBr(self.builder, is_some, body_bb, end_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
    const result_alloca = c.LLVMBuildAlloca(self.builder, result_type, "next.tmp");
    _ = c.LLVMBuildStore(self.builder, result, result_alloca);
    const payload_gep = c.LLVMBuildStructGEP2(self.builder, result_type, result_alloca, 1, "payload.ptr");
    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    const elem_val = c.LLVMBuildLoad2(self.builder, elem_type, payload_ptr, "iter.elem");

    const elem_alloca = c.LLVMBuildAlloca(self.builder, elem_type, "for.elem");
    const loop_task_elem_ty = self.inferTaskContainerElementType(for_e.iterable);
    _ = c.LLVMBuildStore(self.builder, elem_val, elem_alloca);
    if (for_e.binding_pattern == null) {
        self.locals.put(self.allocator, for_e.binding, .{
            .alloca = elem_alloca,
            .ty = elem_type,
            .is_mut = false,
        }) catch return error.CodegenAlloc;
        if (loop_task_elem_ty) |task_ty| {
            self.task_locals.put(self.allocator, for_e.binding, {}) catch return error.CodegenAlloc;
            self.task_local_result_types.put(self.allocator, for_e.binding, task_ty) catch return error.CodegenAlloc;
        } else {
            _ = self.task_locals.remove(for_e.binding);
            _ = self.task_local_result_types.remove(for_e.binding);
        }
    }
    if (for_e.binding_pattern) |bp| {
        try self.bindPatternFromValue(bp, elem_val, elem_type, false);
    }

    _ = try self.genExpr(for_e.body);
    const body_end_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(body_end_bb) == null) {
        _ = c.LLVMBuildBr(self.builder, cond_bb);
    }

    self.loop_depth -= 1;
    c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

/// Generate a for-in loop over an iterator value expression.
fn genForIteratorValue(self: *Codegen, for_e: Ast.ForExpr, iter_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const iter_val_type = c.LLVMTypeOf(iter_val);
    const iter_struct_type = self.normalizeReceiverStructType(iter_val_type) orelse return error.UnsupportedExpr;

    if (c.LLVMGetTypeKind(iter_val_type) == c.LLVMPointerTypeKind) {
        return self.genForIteratorFromPtr(for_e, iter_val, iter_struct_type);
    }

    const iter_alloca = c.LLVMBuildAlloca(self.builder, iter_val_type, "for.iter");
    _ = c.LLVMBuildStore(self.builder, iter_val, iter_alloca);
    return self.genForIteratorFromPtr(for_e, iter_alloca, iter_val_type);
}

/// Generate a for-in loop over a named local iterator.
fn genForIterator(self: *Codegen, for_e: Ast.ForExpr) Error!c.LLVMValueRef {
    const iter_sym = for_e.iterable.kind.ident;
    const local = self.locals.get(iter_sym) orelse return error.UnsupportedExpr;
    return self.genForIteratorFromPtr(for_e, local.alloca, local.ty);
}

fn emitDefers(self: *Codegen) Error!void {
    // Emit deferred expressions in reverse order (LIFO).
    var i: u32 = self.defer_depth;
    while (i > 0) {
        i -= 1;
        _ = try self.genExpr(self.defer_stack[i]);
    }
}

/// Generate a `with` expression.
/// Form 3 (binding): `with expr as name: body` → let name = expr; body
/// Form 2 (builder): `with expr as mut name: body` → var name = expr; body; name
fn genWithExpr(self: *Codegen, w: Ast.WithExpr) Error!c.LLVMValueRef {
    // Evaluate the source expression.
    const source_val = try self.genExpr(w.source);
    const source_type = c.LLVMTypeOf(source_val);

    // Always materialize the source value so guards live for the full with-scope.
    const guard_alloca = c.LLVMBuildAlloca(self.builder, source_type, "with.guard");
    _ = c.LLVMBuildStore(self.builder, source_val, guard_alloca);

    // Track guard for Drop.
    if (self.scope_local_count < self.scope_locals.len) {
        self.scope_locals[self.scope_local_count] = .{
            .sym = w.name,
            .alloca = guard_alloca,
            .ty = source_type,
        };
        self.scope_local_count += 1;
    }

    // Option/Result unwrapping: if the source is Option[T] or Result[T,E],
    // extract the payload and conditionally execute the body only if Some/Ok.
    if (self.isOptionOrResultType(source_type)) {
        const is_some = try self.genOptionIsSome(source_val, source_type);
        const cur_fn = self.current_function orelse return error.UnsupportedExpr;
        const some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "with.some");
        const end_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "with.end");
        _ = c.LLVMBuildCondBr(self.builder, is_some, some_bb, end_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, some_bb);
        // Extract the payload.
        const payload = try self.genOptionUnwrap(source_val, source_type, null);
        const payload_type = c.LLVMTypeOf(payload);
        const payload_alloca = c.LLVMBuildAlloca(self.builder, payload_type, "with.payload");
        _ = c.LLVMBuildStore(self.builder, payload, payload_alloca);

        // Bind the name to the extracted payload.
        self.locals.put(self.allocator, w.name, .{
            .alloca = payload_alloca,
            .ty = payload_type,
            .is_mut = w.is_mut,
        }) catch return error.CodegenAlloc;

        const body_val = try self.genExpr(w.body);
        const current_bb2 = c.LLVMGetInsertBlock(self.builder);
        if (c.LLVMGetBasicBlockTerminator(current_bb2) == null) {
            _ = c.LLVMBuildBr(self.builder, end_bb);
        }

        c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
        return body_val;
    }

    // Form 1 guarded lowering:
    // if Type.enter/enter_mut exists, bind `name` to that method's result.
    var bind_alloca = guard_alloca;
    var bind_type = source_type;
    var bind_pointee_struct: ?u32 = null;
    var used_guard_enter = false;
    if (self.findTypeSymbol(source_type)) |type_sym| {
        const type_name = self.pool.resolve(type_sym);
        const method_name = if (w.is_mut) "enter_mut" else "enter";
        var name_buf: [512]u8 = undefined;
        if (type_name.len + 1 + method_name.len < name_buf.len) {
            @memcpy(name_buf[0..type_name.len], type_name);
            name_buf[type_name.len] = '.';
            @memcpy(name_buf[type_name.len + 1 ..][0..method_name.len], method_name);
            const mangled = name_buf[0 .. type_name.len + 1 + method_name.len];
            const method_sym = self.pool.intern(mangled) catch 0;
            if (method_sym != 0) {
                // Callback-style guarded lowering for generic Scoped.enter:
                // call `Type.enter(&source, |x: &U| -> &U x)` to materialize
                // a binding value compatible with current `with` lowering.
                if (self.generic_fns.get(method_sym)) |enter_fn| {
                    if (enter_fn.params.len >= 2 and enter_fn.params[1].type_expr != null) {
                        const cb_ty = enter_fn.params[1].type_expr.?;
                        if (cb_ty.kind == .fn_type and cb_ty.kind.fn_type.params.len >= 1) {
                            const cb_param_ty = cb_ty.kind.fn_type.params[0];

                            var src_name_buf: [48]u8 = undefined;
                            const src_name = std.fmt.bufPrint(&src_name_buf, "__with_src_{d}", .{self.closure_counter}) catch return error.CodegenAlloc;
                            const src_sym = self.pool.intern(src_name) catch return error.CodegenAlloc;
                            self.closure_counter += 1;

                            self.locals.put(self.allocator, src_sym, .{
                                .alloca = guard_alloca,
                                .ty = source_type,
                                .is_mut = false,
                            }) catch return error.CodegenAlloc;
                            defer _ = self.locals.remove(src_sym);

                            const src_ident = Ast.Expr{
                                .kind = .{ .ident = src_sym },
                                .span = w.source.span,
                            };
                            const src_ref = Ast.Expr{
                                .kind = .{ .unary = .{
                                    .op = .ref_of,
                                    .operand = &src_ident,
                                } },
                                .span = w.source.span,
                            };

                            var cb_name_buf: [48]u8 = undefined;
                            const cb_name = std.fmt.bufPrint(&cb_name_buf, "__with_param_{d}", .{self.closure_counter}) catch return error.CodegenAlloc;
                            const cb_sym = self.pool.intern(cb_name) catch return error.CodegenAlloc;
                            self.closure_counter += 1;

                            const cb_ident = Ast.Expr{
                                .kind = .{ .ident = cb_sym },
                                .span = w.body.span,
                            };
                            const cb_params = [_]u32{cb_sym};
                            const cb_param_types = [_]?*const Ast.TypeExpr{cb_param_ty};
                            const cb_expr = Ast.Expr{
                                .kind = .{ .closure = .{
                                    .params = cb_params[0..],
                                    .param_types = cb_param_types[0..],
                                    .return_type = cb_param_ty,
                                    .body = &cb_ident,
                                } },
                                .span = w.body.span,
                            };

                            const callee_expr = Ast.Expr{
                                .kind = .{ .ident = method_sym },
                                .span = w.source.span,
                            };
                            const call_args = [_]*const Ast.Expr{ &src_ref, &cb_expr };
                            const call_expr = Ast.Expr{
                                .kind = .{ .call = .{
                                    .callee = &callee_expr,
                                    .args = call_args[0..],
                                } },
                                .span = w.source.span.merge(w.body.span),
                            };

                            const entered = try self.genExpr(&call_expr);
                            const ret_type = c.LLVMTypeOf(entered);
                            bind_alloca = c.LLVMBuildAlloca(self.builder, ret_type, "with.bind");
                            _ = c.LLVMBuildStore(self.builder, entered, bind_alloca);
                            bind_type = ret_type;
                            used_guard_enter = true;

                            if (cb_param_ty.kind == .ref_type or cb_param_ty.kind == .ptr_type) {
                                const pointee_te = if (cb_param_ty.kind == .ref_type) cb_param_ty.kind.ref_type.pointee else cb_param_ty.kind.ptr_type.pointee;
                                if (pointee_te.kind == .named and self.struct_types.get(pointee_te.kind.named) != null) {
                                    bind_pointee_struct = pointee_te.kind.named;
                                }
                            }
                        }
                    }
                }

                if (!used_guard_enter) {
                    if (self.functions.get(method_sym)) |fn_info| {
                        const param_count: u32 = c.LLVMCountParams(fn_info.value);
                        var args_buf: [1]c.LLVMValueRef = undefined;
                        var arg_count: u32 = 0;
                        if (param_count > 0) {
                            const self_param_ty = c.LLVMTypeOf(c.LLVMGetParam(fn_info.value, 0));
                            var self_arg: c.LLVMValueRef = undefined;
                            if (c.LLVMGetTypeKind(self_param_ty) == c.LLVMPointerTypeKind) {
                                self_arg = if (self_param_ty == c.LLVMTypeOf(guard_alloca))
                                    guard_alloca
                                else
                                    c.LLVMBuildBitCast(self.builder, guard_alloca, self_param_ty, "with.self.cast");
                            } else {
                                self_arg = c.LLVMBuildLoad2(self.builder, source_type, guard_alloca, "with.guard.val");
                                self_arg = self.coerceInt(self_arg, self_param_ty);
                            }
                            args_buf[0] = self_arg;
                            arg_count = 1;
                        }

                        const ret_type = c.LLVMGetReturnType(fn_info.fn_type);
                        const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
                        const entered = c.LLVMBuildCall2(
                            self.builder,
                            fn_info.fn_type,
                            fn_info.value,
                            if (arg_count > 0) &args_buf else null,
                            arg_count,
                            if (is_void) "" else "with.enter",
                        );
                        if (!is_void) {
                            bind_alloca = c.LLVMBuildAlloca(self.builder, ret_type, "with.bind");
                            _ = c.LLVMBuildStore(self.builder, entered, bind_alloca);
                            bind_type = ret_type;
                            used_guard_enter = true;
                        }
                    }
                }

                if (used_guard_enter) {
                    // Track bound entered value for Drop independently.
                    if (self.scope_local_count < self.scope_locals.len) {
                        self.scope_locals[self.scope_local_count] = .{
                            .sym = w.name,
                            .alloca = bind_alloca,
                            .ty = bind_type,
                        };
                        self.scope_local_count += 1;
                    }
                }
            }
        }
    }

    // Create the visible local binding.
    self.locals.put(self.allocator, w.name, .{
        .alloca = bind_alloca,
        .ty = bind_type,
        .is_mut = w.is_mut,
        .pointee_struct = bind_pointee_struct,
    }) catch return error.CodegenAlloc;

    // Generate the body.
    const body_val = try self.genExpr(w.body);

    // Form 2 (builder fallback): if mut and body returns void, return binding value.
    // Guarded Form 1 (`enter_mut`) always returns the body value directly.
    if (w.is_mut and !used_guard_enter) {
        const body_type = c.LLVMTypeOf(body_val);
        if (body_type == c.LLVMVoidTypeInContext(self.context)) {
            // Body was void (assignments, etc.) → return the builder value.
            return c.LLVMBuildLoad2(self.builder, bind_type, bind_alloca, "with.val");
        }
    }

    return body_val;
}

/// Generate a record update expression: `{ source with field: val, ... }`.
/// Copies all fields from source, overriding specified ones.
fn genRecordUpdate(self: *Codegen, ru: Ast.RecordUpdateExpr) Error!c.LLVMValueRef {
    // Evaluate the source expression.
    const source_val = try self.genExpr(ru.source);
    const source_type = c.LLVMTypeOf(source_val);

    // Find the struct type info by matching LLVM type.
    const struct_info = self.findStructTypeByLlvm(source_type) orelse
        return error.UnsupportedType;

    // Create a new struct with all fields from source, overriding specified ones.
    const alloca = c.LLVMBuildAlloca(self.builder, source_type, "update");

    // First, copy all fields from the source.
    _ = c.LLVMBuildStore(self.builder, source_val, alloca);

    // Then, override the specified fields.
    for (ru.fields) |field| {
        const idx = self.findFieldIndex(struct_info, field.name) orelse
            return error.UnsupportedExpr;
        const gep = c.LLVMBuildStructGEP2(self.builder, source_type, alloca, @intCast(idx), "");
        const val = try self.genExpr(field.value);
        const coerced = self.coerceInt(val, struct_info.field_types[idx]);
        _ = c.LLVMBuildStore(self.builder, coerced, gep);
    }

    return c.LLVMBuildLoad2(self.builder, source_type, alloca, "updated");
}

fn findLoopByLabel(self: *Codegen, label: ?u32) ?*LoopContext {
    if (label) |lbl| {
        // Search the loop stack for a matching label
        var i: usize = self.loop_depth;
        while (i > 0) {
            i -= 1;
            if (self.loop_stack[i].label) |loop_lbl| {
                if (loop_lbl == lbl) return &self.loop_stack[i];
            }
        }
        return null;
    }
    // No label — use innermost loop
    if (self.loop_depth == 0) return null;
    return &self.loop_stack[self.loop_depth - 1];
}

fn genBreak(self: *Codegen, be: Ast.BreakExpr) Error!c.LLVMValueRef {
    if (self.loop_depth == 0) return error.UnsupportedExpr;
    var ctx = self.findLoopByLabel(be.label) orelse return error.UnsupportedExpr;

    // If there's a break value, generate it and store to the loop result alloca.
    if (be.value) |val_expr| {
        const val = try self.genExpr(val_expr);
        // Lazily create the result alloca on first break-with-value.
        if (ctx.result_alloca == null) {
            const val_type = c.LLVMTypeOf(val);
            ctx.result_alloca = c.LLVMBuildAlloca(self.builder, val_type, "loop.result");
        }
        _ = c.LLVMBuildStore(self.builder, val, ctx.result_alloca.?);
    }

    _ = c.LLVMBuildBr(self.builder, ctx.break_bb);

    // Dead block for any code after break.
    const dead_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "break.dead");
    c.LLVMPositionBuilderAtEnd(self.builder, dead_bb);

    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn genContinue(self: *Codegen, ce: Ast.ContinueExpr) Error!c.LLVMValueRef {
    if (self.loop_depth == 0) return error.UnsupportedExpr;
    const ctx = self.findLoopByLabel(ce.label) orelse return error.UnsupportedExpr;
    _ = c.LLVMBuildBr(self.builder, ctx.continue_bb);

    // Dead block for any code after continue.
    const dead_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "cont.dead");
    c.LLVMPositionBuilderAtEnd(self.builder, dead_bb);

    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn declareStructType(self: *Codegen, name_sym: u32, fields: []const Ast.FieldDef) Error!void {
    const name = self.pool.resolve(name_sym);
    var name_buf: [256]u8 = undefined;
    if (name.len >= name_buf.len) return error.UnsupportedExpr;
    @memcpy(name_buf[0..name.len], name);
    name_buf[name.len] = 0;

    const struct_type = c.LLVMStructCreateNamed(self.context, &name_buf);

    const field_names = self.allocator.alloc(u32, fields.len) catch return error.CodegenAlloc;
    const field_types = self.allocator.alloc(c.LLVMTypeRef, fields.len) catch return error.CodegenAlloc;
    const field_defaults = self.allocator.alloc(?*const Ast.Expr, fields.len) catch return error.CodegenAlloc;

    for (fields, 0..) |f, i| {
        field_names[i] = f.name;
        field_types[i] = try self.resolveType(f.type_expr);
        field_defaults[i] = f.default;
    }

    c.LLVMStructSetBody(
        struct_type,
        if (fields.len > 0) field_types.ptr else null,
        @intCast(fields.len),
        0,
    );

    self.struct_types.put(self.allocator, name_sym, .{
        .llvm_type = struct_type,
        .field_names = field_names,
        .field_types = field_types,
        .field_defaults = field_defaults,
    }) catch return error.CodegenAlloc;
}

/// Monomorphize a generic struct by inferring type params from literal field values.
fn monomorphizeGenericStruct(self: *Codegen, td: Ast.TypeDecl, sl: Ast.StructLiteral) Error!void {
    const fields = td.kind.struct_def;

    // Build type param → LLVM type mapping from literal field values.
    // We generate each field value to get its LLVM type, then map type params.
    var type_map: [8]struct { param: u32, llvm_type: c.LLVMTypeRef } = undefined;
    var type_map_len: usize = 0;

    for (sl.fields) |lit_field| {
        // Find corresponding def field.
        for (fields) |def_field| {
            if (def_field.name == lit_field.name) {
                // If this field's type is a type param, infer it.
                if (def_field.type_expr.kind == .named) {
                    const sym = def_field.type_expr.kind.named;
                    for (td.type_params) |tp| {
                        if (tp.name == sym) {
                            // Infer the LLVM type from the literal expression.
                            const llvm_ty = self.inferExprType(lit_field.value) orelse continue;
                            // Store mapping if not already present.
                            var found = false;
                            for (type_map[0..type_map_len]) |entry| {
                                if (entry.param == sym) {
                                    found = true;
                                    break;
                                }
                            }
                            if (!found and type_map_len < 8) {
                                type_map[type_map_len] = .{ .param = sym, .llvm_type = llvm_ty };
                                type_map_len += 1;
                            }
                            break;
                        }
                    }
                }
                break;
            }
        }
    }

    // Now create the monomorphized struct type.
    const name = self.pool.resolve(td.name);
    var name_buf: [256]u8 = undefined;
    if (name.len >= name_buf.len) return error.UnsupportedExpr;
    @memcpy(name_buf[0..name.len], name);
    name_buf[name.len] = 0;

    const struct_type = c.LLVMStructCreateNamed(self.context, &name_buf);

    const field_names = self.allocator.alloc(u32, fields.len) catch return error.CodegenAlloc;
    const field_types = self.allocator.alloc(c.LLVMTypeRef, fields.len) catch return error.CodegenAlloc;
    const field_defaults = self.allocator.alloc(?*const Ast.Expr, fields.len) catch return error.CodegenAlloc;

    for (fields, 0..) |f, i| {
        field_names[i] = f.name;
        field_defaults[i] = f.default;

        // Resolve the field type, substituting type params.
        if (f.type_expr.kind == .named) {
            const sym = f.type_expr.kind.named;
            var resolved = false;
            for (type_map[0..type_map_len]) |entry| {
                if (entry.param == sym) {
                    field_types[i] = entry.llvm_type;
                    resolved = true;
                    break;
                }
            }
            if (!resolved) {
                field_types[i] = try self.resolveType(f.type_expr);
            }
        } else {
            field_types[i] = try self.resolveType(f.type_expr);
        }
    }

    c.LLVMStructSetBody(
        struct_type,
        if (fields.len > 0) field_types.ptr else null,
        @intCast(fields.len),
        0,
    );

    self.struct_types.put(self.allocator, td.name, .{
        .llvm_type = struct_type,
        .field_names = field_names,
        .field_types = field_types,
        .field_defaults = field_defaults,
    }) catch return error.CodegenAlloc;
}

/// Monomorphize a generic struct given resolved LLVM types for its type parameters.
/// Used when a generic function's return type references a generic struct (e.g. `-> Wrapper[T]`).
fn monomorphizeGenericStructFromTypes(self: *Codegen, td: Ast.TypeDecl, resolved_types: []const c.LLVMTypeRef) Error!void {
    const fields = td.kind.struct_def;

    // Build type param → LLVM type mapping from resolved_types.
    var type_map: [8]struct { param: u32, llvm_type: c.LLVMTypeRef } = undefined;
    var type_map_len: usize = 0;
    for (td.type_params, 0..) |tp, i| {
        if (i < resolved_types.len) {
            type_map[type_map_len] = .{ .param = tp.name, .llvm_type = resolved_types[i] };
            type_map_len += 1;
        }
    }

    // Create the monomorphized struct type.
    const name = self.pool.resolve(td.name);
    var name_buf: [256]u8 = undefined;
    if (name.len >= name_buf.len) return error.UnsupportedExpr;
    @memcpy(name_buf[0..name.len], name);
    name_buf[name.len] = 0;

    const struct_type = c.LLVMStructCreateNamed(self.context, &name_buf);

    const field_names = self.allocator.alloc(u32, fields.len) catch return error.CodegenAlloc;
    const field_types = self.allocator.alloc(c.LLVMTypeRef, fields.len) catch return error.CodegenAlloc;
    const field_defaults = self.allocator.alloc(?*const Ast.Expr, fields.len) catch return error.CodegenAlloc;

    for (fields, 0..) |f, i| {
        field_names[i] = f.name;
        field_defaults[i] = f.default;

        if (f.type_expr.kind == .named) {
            const sym = f.type_expr.kind.named;
            var resolved = false;
            for (type_map[0..type_map_len]) |entry| {
                if (entry.param == sym) {
                    field_types[i] = entry.llvm_type;
                    resolved = true;
                    break;
                }
            }
            if (!resolved) {
                field_types[i] = try self.resolveType(f.type_expr);
            }
        } else {
            field_types[i] = try self.resolveType(f.type_expr);
        }
    }

    c.LLVMStructSetBody(
        struct_type,
        if (fields.len > 0) field_types.ptr else null,
        @intCast(fields.len),
        0,
    );

    self.struct_types.put(self.allocator, td.name, .{
        .llvm_type = struct_type,
        .field_names = field_names,
        .field_types = field_types,
        .field_defaults = field_defaults,
    }) catch return error.CodegenAlloc;
}

/// Generate a module-level constant from a top-level `let` declaration.
fn genModuleConstant(self: *Codegen, ld: Ast.LetDecl) Error!void {
    // Determine the type.
    const val_type = if (ld.type_expr) |te| try self.resolveType(te) else blk: {
        break :blk switch (ld.value.kind) {
            .int_literal => c.LLVMInt32TypeInContext(self.context),
            .float_literal => c.LLVMDoubleTypeInContext(self.context),
            .bool_literal => c.LLVMInt1TypeInContext(self.context),
            .string_literal => self.getStrType(),
            .unary => |un| if (un.op == .negate and un.operand.kind == .int_literal)
                c.LLVMInt32TypeInContext(self.context)
            else
                return,
            else => return,
        };
    };

    // Determine the constant value from the initializer expression.
    const const_val: c.LLVMValueRef = switch (ld.value.kind) {
        .int_literal => |v| c.LLVMConstInt(val_type, @bitCast(@as(i64, v)), 1),
        .float_literal => |v| c.LLVMConstReal(val_type, v),
        .bool_literal => |v| c.LLVMConstInt(val_type, if (v) 1 else 0, 0),
        .string_literal => |sym| blk: {
            // Build a constant str struct {ptr, i64} without using the builder.
            const text = self.pool.resolve(sym);
            // Create a global string constant.
            var str_buf: [4096]u8 = undefined;
            if (text.len >= str_buf.len) return;
            @memcpy(str_buf[0..text.len], text);
            str_buf[text.len] = 0;
            const str_global = c.LLVMAddGlobal(
                self.module,
                c.LLVMArrayType2(c.LLVMInt8TypeInContext(self.context), @intCast(text.len + 1)),
                "__str_data",
            );
            c.LLVMSetInitializer(str_global, c.LLVMConstStringInContext(
                self.context,
                @ptrCast(str_buf[0..text.len]),
                @intCast(text.len),
                0,
            ));
            c.LLVMSetGlobalConstant(str_global, 1);
            c.LLVMSetLinkage(str_global, c.LLVMPrivateLinkage);

            const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
            const str_ptr = c.LLVMConstBitCast(str_global, ptr_type);
            const len_val = c.LLVMConstInt(c.LLVMInt64TypeInContext(self.context), @intCast(text.len), 0);
            var fields_arr = [_]c.LLVMValueRef{ str_ptr, len_val };
            // Use the named %str type so the value is recognized as str by println.
            break :blk c.LLVMConstNamedStruct(val_type, &fields_arr, 2);
        },
        .unary => |un| blk: {
            if (un.op == .negate and un.operand.kind == .int_literal) {
                const v = un.operand.kind.int_literal;
                break :blk c.LLVMConstInt(val_type, @bitCast(-@as(i64, v)), 1);
            }
            return;
        },
        else => return,
    };

    // Create a global variable for the constant.
    const name = self.pool.resolve(ld.name);
    var name_buf: [256]u8 = undefined;
    @memcpy(name_buf[0..name.len], name);
    name_buf[name.len] = 0;
    const global = c.LLVMAddGlobal(self.module, val_type, &name_buf);
    c.LLVMSetInitializer(global, const_val);
    c.LLVMSetGlobalConstant(global, if (!ld.is_mut) 1 else 0);
    c.LLVMSetLinkage(global, c.LLVMInternalLinkage);
    self.module_constants.put(self.allocator, ld.name, global) catch return error.CodegenAlloc;
}

/// Infer the LLVM type of an expression without generating code.
fn inferExprType(self: *Codegen, expr: *const Ast.Expr) ?c.LLVMTypeRef {
    return switch (expr.kind) {
        .int_literal => c.LLVMInt32TypeInContext(self.context),
        .float_literal => c.LLVMDoubleTypeInContext(self.context),
        .bool_literal => c.LLVMInt1TypeInContext(self.context),
        .string_literal => self.getStrType(),
        .ident => |sym| {
            if (self.locals.get(sym)) |local| return local.ty;
            return null;
        },
        else => null,
    };
}

fn llvmTypeSupportsDeriveEq(self: *Codegen, ty: c.LLVMTypeRef) bool {
    const kind = c.LLVMGetTypeKind(ty);
    return switch (kind) {
        c.LLVMIntegerTypeKind, c.LLVMFloatTypeKind, c.LLVMDoubleTypeKind, c.LLVMPointerTypeKind => true,
        c.LLVMStructTypeKind => blk: {
            if (self.isStrType(ty)) break :blk true;
            if (self.findTypeSymbol(ty)) |nested_sym| {
                const nested_name = self.pool.resolve(nested_sym);
                var buf: [512]u8 = undefined;
                if (nested_name.len + 3 >= buf.len) break :blk false;
                @memcpy(buf[0..nested_name.len], nested_name);
                buf[nested_name.len] = '.';
                @memcpy(buf[nested_name.len + 1 ..][0..2], "eq");
                const sym = self.pool.intern(buf[0 .. nested_name.len + 3]) catch break :blk false;
                break :blk self.functions.get(sym) != null;
            }
            break :blk false;
        },
        else => false,
    };
}

fn llvmTypeSupportsDeriveClone(self: *Codegen, ty: c.LLVMTypeRef) bool {
    const kind = c.LLVMGetTypeKind(ty);
    return switch (kind) {
        c.LLVMIntegerTypeKind, c.LLVMFloatTypeKind, c.LLVMDoubleTypeKind, c.LLVMPointerTypeKind => true,
        c.LLVMStructTypeKind => self.isStrType(ty),
        else => false,
    };
}

fn registerBuilderDerive(self: *Codegen, td: Ast.TypeDecl, st: StructTypeInfo) Error!void {
    if (self.derive_builder_types.get(td.name) != null) return;

    const type_name = self.pool.resolve(td.name);
    var name_buf: [512]u8 = undefined;
    const builder_name = std.fmt.bufPrintZ(&name_buf, "__with.Builder.{s}", .{type_name}) catch return error.CodegenAlloc;
    const builder_ty = c.LLVMStructCreateNamed(self.context, builder_name);

    const i64_type = c.LLVMInt64TypeInContext(self.context);
    var body = [_]c.LLVMTypeRef{ st.llvm_type, i64_type };
    c.LLVMStructSetBody(builder_ty, &body, 2, 0);

    var required_mask: u64 = 0;
    var default_mask: u64 = 0;
    for (st.field_names, 0..) |_, i| {
        if (i >= 64) continue;
        const bit: u64 = (@as(u64, 1) << @intCast(i));
        if (st.field_defaults[i] != null) {
            default_mask |= bit;
        } else {
            required_mask |= bit;
        }
    }

    self.derive_builder_types.put(self.allocator, td.name, .{
        .llvm_type = builder_ty,
        .required_mask = required_mask,
        .default_mask = default_mask,
    }) catch return error.CodegenAlloc;
    self.builder_owner_by_type.put(self.allocator, @intFromPtr(builder_ty), td.name) catch
        return error.CodegenAlloc;
}

/// Generate derived trait methods for a struct with @[derive(...)].
fn generateDerivedMethods(self: *Codegen, td: Ast.TypeDecl) Error!void {
    const st = self.struct_types.get(td.name) orelse return;
    const type_name = self.pool.resolve(td.name);

    // Check what traits to derive.
    var derive_eq = false;
    var derive_clone = false;
    var derive_builder = false;
    for (td.derive_traits) |trait_sym| {
        const trait_name = self.pool.resolve(trait_sym);
        if (std.mem.eql(u8, trait_name, "Eq") or std.mem.eql(u8, trait_name, "PartialEq")) {
            derive_eq = true;
        } else if (std.mem.eql(u8, trait_name, "Clone")) {
            derive_clone = true;
        } else if (std.mem.eql(u8, trait_name, "Builder")) {
            derive_builder = true;
        } else if (std.mem.eql(u8, trait_name, "all")) {
            var can_eq = true;
            var can_clone = true;
            for (st.field_types) |ft| {
                if (!self.llvmTypeSupportsDeriveEq(ft)) can_eq = false;
                if (!self.llvmTypeSupportsDeriveClone(ft)) can_clone = false;
            }
            derive_eq = derive_eq or can_eq;
            derive_clone = derive_clone or can_clone;
        }
    }

    // Generate Type.eq(self, other) -> bool
    if (derive_eq) {
        try self.generateDeriveEq(td.name, type_name, st);
    }

    // Generate Type.clone(self) -> Type
    if (derive_clone) {
        try self.generateDeriveClone(td.name, type_name, st);
    }

    // Register derived builder metadata for Type.builder()/builder chaining.
    if (derive_builder) {
        try self.registerBuilderDerive(td, st);
    }
}

fn generateDeriveEq(self: *Codegen, type_sym: u32, type_name: []const u8, st: StructTypeInfo) Error!void {
    // Build mangled name "Type.eq"
    var name_buf: [512]u8 = undefined;
    @memcpy(name_buf[0..type_name.len], type_name);
    name_buf[type_name.len] = '.';
    @memcpy(name_buf[type_name.len + 1 ..][0..2], "eq");
    const mangled_len = type_name.len + 3;
    const fn_sym = self.pool.intern(name_buf[0..mangled_len]) catch return error.CodegenAlloc;

    // Skip if already implemented.
    if (self.functions.get(fn_sym) != null) return;

    // fn eq(self: Type, other: Type) -> bool
    var param_types = [_]c.LLVMTypeRef{ st.llvm_type, st.llvm_type };
    const bool_type = c.LLVMInt1TypeInContext(self.context);
    const fn_type = c.LLVMFunctionType(bool_type, &param_types, 2, 0);

    name_buf[mangled_len] = 0;
    const function = c.LLVMAddFunction(self.module, @ptrCast(name_buf[0..mangled_len :0]), fn_type);

    self.functions.put(self.allocator, fn_sym, .{
        .value = function,
        .fn_type = fn_type,
    }) catch return error.CodegenAlloc;

    // Generate body: compare all fields.
    const saved_fn = self.current_function;
    const saved_ret = self.current_ret_type;
    self.current_function = function;
    self.current_ret_type = bool_type;

    const entry_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "entry");
    c.LLVMPositionBuilderAtEnd(self.builder, entry_bb);

    const self_val = c.LLVMGetParam(function, 0);
    const other_val = c.LLVMGetParam(function, 1);

    if (st.field_names.len == 0) {
        // No fields — always equal.
        _ = c.LLVMBuildRet(self.builder, c.LLVMConstInt(bool_type, 1, 0));
    } else {
        // Compare all fields with AND.
        var result = c.LLVMConstInt(bool_type, 1, 0);
        for (st.field_types, 0..) |ft, i| {
            const field_a = c.LLVMBuildExtractValue(self.builder, self_val, @intCast(i), "a");
            const field_b = c.LLVMBuildExtractValue(self.builder, other_val, @intCast(i), "b");
            const field_eq = switch (c.LLVMGetTypeKind(ft)) {
                c.LLVMIntegerTypeKind => c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, field_a, field_b, "eq"),
                c.LLVMFloatTypeKind, c.LLVMDoubleTypeKind => c.LLVMBuildFCmp(self.builder, c.LLVMRealOEQ, field_a, field_b, "eq"),
                c.LLVMStructTypeKind => blk: {
                    // Nested struct — call its .eq method if available.
                    if (self.findTypeSymbol(ft)) |nested_sym| {
                        var nested_name_buf: [512]u8 = undefined;
                        const nested_name = self.pool.resolve(nested_sym);
                        @memcpy(nested_name_buf[0..nested_name.len], nested_name);
                        nested_name_buf[nested_name.len] = '.';
                        @memcpy(nested_name_buf[nested_name.len + 1 ..][0..2], "eq");
                        const nested_fn_sym = self.pool.intern(nested_name_buf[0 .. nested_name.len + 3]) catch break :blk c.LLVMConstInt(bool_type, 1, 0);
                        if (self.functions.get(nested_fn_sym)) |nested_fn| {
                            var nested_args = [_]c.LLVMValueRef{ field_a, field_b };
                            break :blk c.LLVMBuildCall2(self.builder, nested_fn.fn_type, nested_fn.value, &nested_args, 2, "nesteq");
                        }
                    }
                    break :blk c.LLVMConstInt(bool_type, 1, 0);
                },
                else => c.LLVMConstInt(bool_type, 1, 0),
            };
            result = c.LLVMBuildAnd(self.builder, result, field_eq, "and");
        }
        _ = c.LLVMBuildRet(self.builder, result);
    }

    self.current_function = saved_fn;
    self.current_ret_type = saved_ret;

    // Register impl for this trait.
    _ = type_sym;
}

fn generateDeriveClone(self: *Codegen, type_sym: u32, type_name: []const u8, st: StructTypeInfo) Error!void {
    _ = type_sym;
    // Build mangled name "Type.clone"
    var name_buf: [512]u8 = undefined;
    @memcpy(name_buf[0..type_name.len], type_name);
    name_buf[type_name.len] = '.';
    @memcpy(name_buf[type_name.len + 1 ..][0..5], "clone");
    const mangled_len = type_name.len + 6;
    const fn_sym = self.pool.intern(name_buf[0..mangled_len]) catch return error.CodegenAlloc;

    // Skip if already implemented.
    if (self.functions.get(fn_sym) != null) return;

    // fn clone(self: Type) -> Type
    var param_types = [_]c.LLVMTypeRef{st.llvm_type};
    const fn_type = c.LLVMFunctionType(st.llvm_type, &param_types, 1, 0);

    name_buf[mangled_len] = 0;
    const function = c.LLVMAddFunction(self.module, @ptrCast(name_buf[0..mangled_len :0]), fn_type);

    self.functions.put(self.allocator, fn_sym, .{
        .value = function,
        .fn_type = fn_type,
    }) catch return error.CodegenAlloc;

    // Generate body: just return self (bitwise copy).
    const saved_fn = self.current_function;
    const saved_ret = self.current_ret_type;
    self.current_function = function;
    self.current_ret_type = st.llvm_type;

    const entry_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "entry");
    c.LLVMPositionBuilderAtEnd(self.builder, entry_bb);

    _ = c.LLVMBuildRet(self.builder, c.LLVMGetParam(function, 0));

    self.current_function = saved_fn;
    self.current_ret_type = saved_ret;
}

fn declareEnumType(self: *Codegen, name_sym: u32, variants: []const Ast.VariantDef) Error!void {
    // For now, enums with no payload variants are just i32 tags.
    // Enums with payload variants become { i32 tag, [max_payload_size x i8] }.
    // For simplicity, we support single-typed payloads per variant.
    const variant_names = self.allocator.alloc(u32, variants.len) catch return error.CodegenAlloc;
    const variant_payload_types = self.allocator.alloc(?c.LLVMTypeRef, variants.len) catch return error.CodegenAlloc;

    var has_payload = false;
    var max_payload_size: u64 = 0;

    for (variants, 0..) |v, i| {
        variant_names[i] = v.name;
        if (v.payload) |payload_types| {
            if (payload_types.len == 1) {
                const pt = self.resolveType(payload_types[0]) catch {
                    variant_payload_types[i] = null;
                    continue;
                };
                variant_payload_types[i] = pt;
                has_payload = true;
                const size = c.LLVMABISizeOfType(c.LLVMGetModuleDataLayout(self.module), pt);
                if (size > max_payload_size) max_payload_size = size;
            } else if (payload_types.len > 1) {
                // Multi-payload variant: create an anonymous struct for the payload.
                var field_types_buf: [16]c.LLVMTypeRef = undefined;
                var ok = true;
                for (payload_types, 0..) |pt_expr, pi| {
                    field_types_buf[pi] = self.resolveType(pt_expr) catch {
                        ok = false;
                        break;
                    };
                }
                if (ok) {
                    const payload_struct = c.LLVMStructTypeInContext(
                        self.context,
                        &field_types_buf,
                        @intCast(payload_types.len),
                        0,
                    );
                    variant_payload_types[i] = payload_struct;
                    has_payload = true;
                    const size = c.LLVMABISizeOfType(c.LLVMGetModuleDataLayout(self.module), payload_struct);
                    if (size > max_payload_size) max_payload_size = size;
                } else {
                    variant_payload_types[i] = null;
                }
            } else {
                variant_payload_types[i] = null;
            }
        } else {
            variant_payload_types[i] = null;
        }
    }

    // Create the LLVM type.
    const name = self.pool.resolve(name_sym);
    var name_buf: [256]u8 = undefined;
    if (name.len >= name_buf.len) return error.UnsupportedExpr;
    @memcpy(name_buf[0..name.len], name);
    name_buf[name.len] = 0;

    var llvm_type: c.LLVMTypeRef = undefined;
    if (has_payload) {
        // { i32 tag, [max_payload_size x i8] }
        const enum_struct = c.LLVMStructCreateNamed(self.context, &name_buf);
        var body_types = [_]c.LLVMTypeRef{
            c.LLVMInt32TypeInContext(self.context), // tag
            c.LLVMArrayType2(c.LLVMInt8TypeInContext(self.context), max_payload_size), // payload
        };
        c.LLVMStructSetBody(enum_struct, &body_types, 2, 0);
        llvm_type = enum_struct;
    } else {
        // No payload — just an i32 tag.
        llvm_type = c.LLVMInt32TypeInContext(self.context);
    }

    const user_enum_info: EnumTypeInfo = .{
        .llvm_type = llvm_type,
        .variant_names = variant_names,
        .variant_payload_types = variant_payload_types,
    };
    self.enum_types.put(self.allocator, name_sym, user_enum_info) catch return error.CodegenAlloc;
    self.enum_types_by_llvm.put(self.allocator, @intFromPtr(llvm_type), user_enum_info) catch return error.CodegenAlloc;
}

fn declareBuiltinStrType(self: *Codegen) Error!void {
    const str_sym = self.pool.intern("str") catch return error.CodegenAlloc;
    const ptr_sym = self.pool.intern("ptr") catch return error.CodegenAlloc;
    const len_sym = self.pool.intern("len") catch return error.CodegenAlloc;

    const str_type = c.LLVMStructCreateNamed(self.context, "str");
    var body_types = [_]c.LLVMTypeRef{
        c.LLVMPointerTypeInContext(self.context, 0), // ptr
        c.LLVMInt64TypeInContext(self.context), // len
    };
    c.LLVMStructSetBody(str_type, &body_types, 2, 0);

    const field_names = self.allocator.alloc(u32, 2) catch return error.CodegenAlloc;
    field_names[0] = ptr_sym;
    field_names[1] = len_sym;

    const field_types = self.allocator.alloc(c.LLVMTypeRef, 2) catch return error.CodegenAlloc;
    field_types[0] = body_types[0];
    field_types[1] = body_types[1];

    const field_defaults = self.allocator.alloc(?*const Ast.Expr, 2) catch return error.CodegenAlloc;
    field_defaults[0] = null;
    field_defaults[1] = null;

    self.struct_types.put(self.allocator, str_sym, .{
        .llvm_type = str_type,
        .field_names = field_names,
        .field_types = field_types,
        .field_defaults = field_defaults,
    }) catch return error.CodegenAlloc;
}

fn genStructLiteral(self: *Codegen, sl: Ast.StructLiteral) Error!c.LLVMValueRef {
    const info = self.struct_types.get(sl.name) orelse blk: {
        // Try monomorphizing a generic struct.
        const gs = self.generic_structs.get(sl.name) orelse return error.UnsupportedType;
        try self.monomorphizeGenericStruct(gs, sl);
        break :blk self.struct_types.get(sl.name) orelse return error.UnsupportedType;
    };

    // Alloca for the struct.
    const alloca = c.LLVMBuildAlloca(self.builder, info.llvm_type, "struct");

    // Field initializers should inherit the declared field type as context
    // (e.g. HashMap.new() inside struct literals).
    const saved_expected = self.expected_type;
    defer self.expected_type = saved_expected;

    // Track which fields are explicitly provided.
    const provided = self.allocator.alloc(bool, info.field_names.len) catch return error.CodegenAlloc;
    @memset(provided, false);

    // Store each explicitly provided field.
    for (sl.fields) |field| {
        const idx = self.findFieldIndex(info, field.name) orelse return error.UnsupportedExpr;
        provided[idx] = true;
        const gep = c.LLVMBuildStructGEP2(self.builder, info.llvm_type, alloca, @intCast(idx), "");
        self.expected_type = info.field_types[idx];
        const val = try self.genExpr(field.value);
        const coerced = self.coerceInt(val, info.field_types[idx]);
        _ = c.LLVMBuildStore(self.builder, coerced, gep);
    }

    // Fill in defaults for missing fields.
    for (info.field_names, 0..) |_, i| {
        if (!provided[i]) {
            if (info.field_defaults[i]) |default_expr| {
                const gep = c.LLVMBuildStructGEP2(self.builder, info.llvm_type, alloca, @intCast(i), "");
                self.expected_type = info.field_types[i];
                const val = try self.genExpr(default_expr);
                const coerced = self.coerceInt(val, info.field_types[i]);
                _ = c.LLVMBuildStore(self.builder, coerced, gep);
            }
            // If no default and not provided, field is uninitialized (could add error later).
        }
    }

    // Load and return the whole struct.
    return c.LLVMBuildLoad2(self.builder, info.llvm_type, alloca, "struct.val");
}

fn genEnumVariant(self: *Codegen, ev: Ast.EnumVariantExpr) Error!c.LLVMValueRef {
    const enum_info = self.enum_types.get(ev.type_name) orelse return error.UnsupportedType;
    const i32_type = c.LLVMInt32TypeInContext(self.context);

    // Find variant index.
    var tag_idx: ?u32 = null;
    for (enum_info.variant_names, 0..) |vn, i| {
        if (vn == ev.variant_name) {
            tag_idx = @intCast(i);
            break;
        }
    }
    const idx = tag_idx orelse return error.UnsupportedExpr;
    const tag_val = c.LLVMConstInt(i32_type, idx, 0);

    // Check if enum has payload.
    const has_payload = c.LLVMGetTypeKind(enum_info.llvm_type) == c.LLVMStructTypeKind;

    if (!has_payload) {
        // Simple tag enum — just return the i32 tag.
        return tag_val;
    }

    // Enum with payload — create { tag, payload }.
    const alloca = c.LLVMBuildAlloca(self.builder, enum_info.llvm_type, "enum");

    // Store tag.
    const tag_gep = c.LLVMBuildStructGEP2(self.builder, enum_info.llvm_type, alloca, 0, "tag");
    _ = c.LLVMBuildStore(self.builder, tag_val, tag_gep);

    // Store payload if this variant has one.
    if (enum_info.variant_payload_types[idx]) |payload_type| {
        if (ev.args.len > 0) {
            const payload_gep = c.LLVMBuildStructGEP2(self.builder, enum_info.llvm_type, alloca, 1, "payload");
            // Bitcast the payload storage (which is [N x i8]) to the payload type ptr.
            const payload_store = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");

            if (ev.args.len == 1) {
                // Single-payload variant.
                const payload_val = try self.genExpr(ev.args[0]);
                const coerced = self.coerceInt(payload_val, payload_type);
                _ = c.LLVMBuildStore(self.builder, coerced, payload_store);
            } else {
                // Multi-payload variant: payload_type is a struct, store each field.
                const struct_alloca = c.LLVMBuildAlloca(self.builder, payload_type, "mp.tmp");
                for (ev.args, 0..) |arg, fi| {
                    const field_val = try self.genExpr(arg);
                    const field_gep = c.LLVMBuildStructGEP2(self.builder, payload_type, struct_alloca, @intCast(fi), "mp.field");
                    _ = c.LLVMBuildStore(self.builder, field_val, field_gep);
                }
                const struct_val = c.LLVMBuildLoad2(self.builder, payload_type, struct_alloca, "mp.val");
                _ = c.LLVMBuildStore(self.builder, struct_val, payload_store);
            }
        }
    }

    return c.LLVMBuildLoad2(self.builder, enum_info.llvm_type, alloca, "enum.val");
}

/// Recursively bind nested patterns against a payload value.
/// For example, `Some(Some(v))` extracts the inner Option's payload and binds `v`.
/// Generate an implicit guard for nested patterns like Some(Some(v)).
/// If the inner tag doesn't match, branch to the fallthrough arm.
fn genNestedPatternGuard(
    self: *Codegen,
    payload_val: c.LLVMValueRef,
    payload_type: c.LLVMTypeRef,
    nested_patterns: []const Ast.Pattern,
    guard_fallthrough: *[64]?usize,
    arm_bbs: *[64]c.LLVMBasicBlockRef,
    arm_idx: usize,
    num_arms: usize,
    default_bb: c.LLVMBasicBlockRef,
) Error!void {
    if (nested_patterns.len != 1) return;
    const pat = nested_patterns[0];

    switch (pat.kind) {
        .variant => |inner_vp| {
            // The payload is an enum (e.g. inner Option).
            // Check if it's an Option/Result type with struct layout {tag, payload}.
            if (self.isOptionOrResultType(payload_type)) {
                // Extract inner tag.
                const tmp_inner = c.LLVMBuildAlloca(self.builder, payload_type, "nest.inner.tmp");
                _ = c.LLVMBuildStore(self.builder, payload_val, tmp_inner);
                const inner_tag_gep = c.LLVMBuildStructGEP2(self.builder, payload_type, tmp_inner, 0, "nest.inner.tag.ptr");
                const inner_tag_type = c.LLVMStructGetTypeAtIndex(payload_type, 0);
                const inner_tag = c.LLVMBuildLoad2(self.builder, inner_tag_type, inner_tag_gep, "nest.inner.tag");

                // Determine expected inner tag value.
                const inner_name_str = self.pool.resolve(inner_vp.name);
                var expected_tag: u64 = 0;
                if (std.mem.eql(u8, inner_name_str, "None") or std.mem.eql(u8, inner_name_str, "Err")) {
                    expected_tag = 1;
                }
                const expected = c.LLVMConstInt(inner_tag_type, expected_tag, 0);
                const cmp = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, inner_tag, expected, "nest.guard");

                // Branch: match → continue in body_bb, mismatch → fallthrough.
                const body_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "nest.pass");
                const fallthrough_bb = if (guard_fallthrough[arm_idx]) |next_same|
                    arm_bbs[next_same]
                else if (arm_idx + 1 < num_arms)
                    arm_bbs[arm_idx + 1]
                else
                    default_bb;
                _ = c.LLVMBuildCondBr(self.builder, cmp, body_bb, fallthrough_bb);
                c.LLVMPositionBuilderAtEnd(self.builder, body_bb);

                // After guard passes: bind inner patterns.
                // Use getOptionPayloadType + bitcast (same as genOptionUnwrap).
                const actual_payload_type = self.getOptionPayloadType(payload_type) orelse c.LLVMInt32TypeInContext(self.context);
                if (inner_vp.nested_patterns.len > 0) {
                    // Extract inner payload for deeper recursion.
                    const payload_gep = c.LLVMBuildStructGEP2(self.builder, payload_type, tmp_inner, 1, "nest.inner.p");
                    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
                    const inner_payload = c.LLVMBuildLoad2(self.builder, actual_payload_type, payload_ptr, "nest.inner.payload");
                    try self.genNestedPatternGuard(inner_payload, actual_payload_type, inner_vp.nested_patterns, guard_fallthrough, arm_bbs, arm_idx, num_arms, default_bb);
                } else if (inner_vp.bindings.len > 0) {
                    // Inner variant has bindings (e.g., Some(v)): extract and bind payload.
                    const payload_gep = c.LLVMBuildStructGEP2(self.builder, payload_type, tmp_inner, 1, "nest.bind.ptr");
                    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
                    const inner_payload = c.LLVMBuildLoad2(self.builder, actual_payload_type, payload_ptr, "nest.bind.val");
                    if (inner_vp.bindings.len == 1) {
                        const bind_sym = inner_vp.bindings[0];
                        const bind_alloca = c.LLVMBuildAlloca(self.builder, actual_payload_type, "nest.bind");
                        _ = c.LLVMBuildStore(self.builder, inner_payload, bind_alloca);
                        self.locals.put(self.allocator, bind_sym, .{
                            .alloca = bind_alloca,
                            .ty = actual_payload_type,
                            .is_mut = false,
                        }) catch return error.CodegenAlloc;
                    }
                }
            }
        },
        .binding, .wildcard => {
            // Simple binding/wildcard: no guard needed, always matches.
        },
        else => {},
    }
}

fn bindNestedPatterns(self: *Codegen, payload_val: c.LLVMValueRef, payload_type: c.LLVMTypeRef, patterns: []const Ast.Pattern) Error!void {
    if (patterns.len != 1) return; // Only single nested pattern supported for now.
    const pat = patterns[0];
    switch (pat.kind) {
        .binding => |sym| {
            // Simple binding: bind the payload directly.
            const bind_alloca = c.LLVMBuildAlloca(self.builder, payload_type, "nested.bind");
            _ = c.LLVMBuildStore(self.builder, payload_val, bind_alloca);
            self.locals.put(self.allocator, sym, .{
                .alloca = bind_alloca,
                .ty = payload_type,
                .is_mut = false,
            }) catch return error.CodegenAlloc;
        },
        .wildcard => {}, // Nothing to bind.
        .variant => |inner_vp| {
            // Nested variant pattern: the payload is itself an enum (e.g., inner Option).
            // Extract the inner payload if the inner variant matches.
            if (self.isOptionOrResultType(payload_type)) {
                // For Option/Result: extract inner payload via unwrap.
                const inner_payload = try self.genOptionUnwrap(payload_val, payload_type, null);
                const inner_payload_type = c.LLVMTypeOf(inner_payload);
                if (inner_vp.nested_patterns.len > 0) {
                    try self.bindNestedPatterns(inner_payload, inner_payload_type, inner_vp.nested_patterns);
                } else if (inner_vp.bindings.len == 1) {
                    const bind_sym = inner_vp.bindings[0];
                    const bind_alloca = c.LLVMBuildAlloca(self.builder, inner_payload_type, "nested.inner");
                    _ = c.LLVMBuildStore(self.builder, inner_payload, bind_alloca);
                    self.locals.put(self.allocator, bind_sym, .{
                        .alloca = bind_alloca,
                        .ty = inner_payload_type,
                        .is_mut = false,
                    }) catch return error.CodegenAlloc;
                }
            }
        },
        else => {},
    }
}

fn genMatchExpr(self: *Codegen, m: Ast.MatchExpr) Error!c.LLVMValueRef {
    const subject = try self.genExpr(m.subject);
    const subject_type = c.LLVMTypeOf(subject);

    // Tuple-pattern match path.
    var has_tuple_patterns = false;
    for (m.arms) |arm| {
        if (arm.pattern.kind == .tuple_pattern) {
            has_tuple_patterns = true;
            break;
        }
    }
    if (has_tuple_patterns) {
        return self.genTupleMatch(m, subject, subject_type);
    }

    // Struct-pattern match path.
    var has_struct_patterns = false;
    for (m.arms) |arm| {
        if (arm.pattern.kind == .struct_pattern) {
            has_struct_patterns = true;
            break;
        }
    }
    if (has_struct_patterns) {
        return self.genStructMatch(m, subject, subject_type);
    }

    // Check if any arm uses slice patterns — use array/vec match path.
    var has_slice = false;
    for (m.arms) |arm| {
        if (arm.pattern.kind == .slice_pattern) {
            has_slice = true;
            break;
        }
    }
    if (has_slice) {
        return self.genSliceMatch(m, subject, subject_type);
    }

    // Check if any arm uses string literal patterns — use strcmp chain.
    var has_string_patterns = false;
    for (m.arms) |arm| {
        if (arm.pattern.kind == .string_literal) {
            has_string_patterns = true;
            break;
        }
    }
    if (has_string_patterns) {
        return self.genStringMatch(m, subject, subject_type);
    }

    // Determine if this is an enum match or an integer/value match.
    const is_enum_struct = c.LLVMGetTypeKind(subject_type) == c.LLVMStructTypeKind and !self.isStrType(subject_type);

    // Extract the tag for enum types.
    var tag_val: c.LLVMValueRef = undefined;
    if (is_enum_struct) {
        // Subject is an enum struct — extract tag (field 0).
        const tmp = c.LLVMBuildAlloca(self.builder, subject_type, "match.subj");
        _ = c.LLVMBuildStore(self.builder, subject, tmp);
        const tag_gep = c.LLVMBuildStructGEP2(self.builder, subject_type, tmp, 0, "tag.ptr");
        tag_val = c.LLVMBuildLoad2(self.builder, c.LLVMInt32TypeInContext(self.context), tag_gep, "tag");
    } else {
        // Subject is a simple integer value (or simple enum = i32 tag).
        tag_val = subject;
    }

    // Find the enum type info if this is an enum.
    var enum_info: ?EnumTypeInfo = null;
    if (is_enum_struct) {
        // Fast lookup by LLVM type pointer.
        if (self.enum_types_by_llvm.get(@intFromPtr(subject_type))) |ei| {
            enum_info = ei;
        } else {
            // Fallback: scan by type equality.
            var it = self.enum_types.iterator();
            while (it.next()) |entry| {
                if (entry.value_ptr.llvm_type == subject_type) {
                    enum_info = entry.value_ptr.*;
                    break;
                }
            }
        }
    } else {
        // Try to find by tracked enum type (from enum_local_types).
        if (m.subject.kind == .ident) {
            if (self.enum_local_types.get(m.subject.kind.ident)) |enum_sym| {
                if (self.enum_types.get(enum_sym)) |ei| {
                    enum_info = ei;
                }
            }
        }
        // Fallback: scan enum_types for non-payload enums with matching type.
        if (enum_info == null) {
            var it = self.enum_types.iterator();
            while (it.next()) |entry| {
                if (entry.value_ptr.llvm_type == subject_type and c.LLVMGetTypeKind(subject_type) == c.LLVMIntegerTypeKind) {
                    enum_info = entry.value_ptr.*;
                    break;
                }
            }
        }
    }

    if (m.arms.len == 0) return error.UnsupportedExpr;

    // Create basic blocks for each arm and merge.
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "match.end");

    // First pass: identify the wildcard/binding arm and check for range patterns.
    var wildcard_arm_idx: ?usize = null;
    var has_range_patterns = false;
    for (m.arms, 0..) |arm, i| {
        switch (arm.pattern.kind) {
            .wildcard, .binding => {
                if (wildcard_arm_idx == null) wildcard_arm_idx = i;
            },
            .range_pattern => {
                has_range_patterns = true;
            },
            else => {},
        }
    }

    const default_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "match.default");

    // Create BBs for each arm.
    var arm_bbs_buf: [64]c.LLVMBasicBlockRef = undefined;
    for (0..m.arms.len) |i| {
        if (!has_range_patterns and wildcard_arm_idx != null and wildcard_arm_idx.? == i) {
            arm_bbs_buf[i] = default_bb; // default arm uses default_bb (only when no ranges)
        } else {
            arm_bbs_buf[i] = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "match.arm");
        }
    }

    // Pre-pass: detect duplicate variant/int tags and build guard fallthrough chain.
    // For arms with the same tag, only the first gets a switch case; subsequent ones
    // are reached via guard fallthrough from prior same-tag arms.
    var guard_fallthrough: [64]?usize = .{null} ** 64;
    var skip_case: [64]bool = .{false} ** 64;
    {
        var ia: usize = 0;
        while (ia < m.arms.len) : (ia += 1) {
            if (skip_case[ia]) continue;
            const tag_a = getPatternTag(m.arms[ia].pattern, enum_info) orelse continue;
            var prev_in_group: usize = ia;
            var ib: usize = ia + 1;
            while (ib < m.arms.len) : (ib += 1) {
                const tag_b = getPatternTag(m.arms[ib].pattern, enum_info) orelse continue;
                if (tag_a == tag_b) {
                    guard_fallthrough[prev_in_group] = ib;
                    skip_case[ib] = true;
                    prev_in_group = ib;
                }
            }
        }
    }

    // Build switch.
    const sw = c.LLVMBuildSwitch(self.builder, tag_val, default_bb, @intCast(m.arms.len));

    // Add cases (skip duplicates — they're reached via guard fallthrough).
    for (m.arms, 0..) |arm, i| {
        if (!skip_case[i]) {
            self.addMatchCase(sw, arm.pattern, tag_val, arm_bbs_buf[i], enum_info);
        }
    }

    // Handle range patterns: chain comparisons from default_bb.
    if (has_range_patterns) {
        c.LLVMPositionBuilderAtEnd(self.builder, default_bb);
        // Build chain of range checks. Final fallthrough goes to wildcard arm or unreachable.
        const final_dest = if (wildcard_arm_idx) |wci| arm_bbs_buf[wci] else blk: {
            const unr = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "range.unreachable");
            c.LLVMPositionBuilderAtEnd(self.builder, unr);
            _ = c.LLVMBuildUnreachable(self.builder);
            break :blk unr;
        };
        // Build range checks in reverse order so first range is checked first.
        var next_check = final_dest;
        var ri: usize = m.arms.len;
        while (ri > 0) {
            ri -= 1;
            const arm_pat = m.arms[ri].pattern;
            if (arm_pat.kind == .range_pattern) {
                const rp = arm_pat.kind.range_pattern;
                const val_type = c.LLVMTypeOf(tag_val);
                const start_val = c.LLVMConstInt(val_type, @bitCast(rp.start), 1);
                const end_val = c.LLVMConstInt(val_type, @bitCast(rp.end), 1);
                const check_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "range.check");
                c.LLVMPositionBuilderAtEnd(self.builder, check_bb);
                const ge = c.LLVMBuildICmp(self.builder, c.LLVMIntSGE, tag_val, start_val, "range.ge");
                const le_op: c_uint = if (rp.inclusive) c.LLVMIntSLE else c.LLVMIntSLT;
                const le = c.LLVMBuildICmp(self.builder, le_op, tag_val, end_val, "range.le");
                const in_range = c.LLVMBuildAnd(self.builder, ge, le, "range.in");
                _ = c.LLVMBuildCondBr(self.builder, in_range, arm_bbs_buf[ri], next_check);
                next_check = check_bb;
            }
        }
        // Wire default_bb to first range check.
        c.LLVMPositionBuilderAtEnd(self.builder, default_bb);
        _ = c.LLVMBuildBr(self.builder, next_check);
    }

    // Generate code for each arm.
    var arm_vals_buf: [64]c.LLVMValueRef = undefined;
    var arm_from_bbs_buf: [64]c.LLVMBasicBlockRef = undefined;
    var arm_count: u32 = 0;

    for (m.arms, 0..) |arm, i| {
        c.LLVMPositionBuilderAtEnd(self.builder, arm_bbs_buf[i]);

        // Bind pattern variables.
        switch (arm.pattern.kind) {
            .variant => |vp| {
                if ((vp.bindings.len > 0 or vp.nested_patterns.len > 0) and enum_info != null) {
                    // Extract payload and bind to local.
                    const ei = enum_info.?;
                    for (ei.variant_names, 0..) |vn, vi| {
                        if (vn == vp.name) {
                            if (ei.variant_payload_types[vi]) |payload_type| {
                                if (is_enum_struct) {
                                    // Extract payload from { tag, [N x i8] }.
                                    const tmp = c.LLVMBuildAlloca(self.builder, subject_type, "match.subj2");
                                    _ = c.LLVMBuildStore(self.builder, subject, tmp);
                                    const payload_gep = c.LLVMBuildStructGEP2(self.builder, subject_type, tmp, 1, "payload.ptr");
                                    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
                                    const payload_val = c.LLVMBuildLoad2(self.builder, payload_type, payload_ptr, "payload");

                                    if (vp.nested_patterns.len > 0) {
                                        // Nested pattern: binding is deferred to genNestedPatternGuard
                                        // which runs after the inner tag check passes. Do NOT call
                                        // bindNestedPatterns here as it uses genOptionUnwrap which
                                        // aborts if the inner tag doesn't match.
                                    } else if (vp.bindings.len == 1) {
                                        // Single binding: bind the whole payload.
                                        const bind_sym = vp.bindings[0];
                                        const bind_alloca = c.LLVMBuildAlloca(self.builder, payload_type, "");
                                        _ = c.LLVMBuildStore(self.builder, payload_val, bind_alloca);
                                        self.locals.put(self.allocator, bind_sym, .{
                                            .alloca = bind_alloca,
                                            .ty = payload_type,
                                            .is_mut = false,
                                        }) catch return error.CodegenAlloc;
                                    } else {
                                        // Multi-binding: payload_type is a struct, extract each field.
                                        const pval_alloca = c.LLVMBuildAlloca(self.builder, payload_type, "mp.ext");
                                        _ = c.LLVMBuildStore(self.builder, payload_val, pval_alloca);
                                        for (vp.bindings, 0..) |bind_sym, bi| {
                                            const field_ty = c.LLVMStructGetTypeAtIndex(payload_type, @intCast(bi));
                                            const field_gep = c.LLVMBuildStructGEP2(self.builder, payload_type, pval_alloca, @intCast(bi), "mp.f");
                                            const field_val = c.LLVMBuildLoad2(self.builder, field_ty, field_gep, "mp.v");
                                            const bind_alloca = c.LLVMBuildAlloca(self.builder, field_ty, "");
                                            _ = c.LLVMBuildStore(self.builder, field_val, bind_alloca);
                                            self.locals.put(self.allocator, bind_sym, .{
                                                .alloca = bind_alloca,
                                                .ty = field_ty,
                                                .is_mut = false,
                                            }) catch return error.CodegenAlloc;
                                        }
                                    }
                                }
                            }
                            break;
                        }
                    }
                }
            },
            .binding => |sym| {
                // Bind the whole subject to the name.
                const bind_alloca = c.LLVMBuildAlloca(self.builder, subject_type, "");
                _ = c.LLVMBuildStore(self.builder, subject, bind_alloca);
                self.locals.put(self.allocator, sym, .{
                    .alloca = bind_alloca,
                    .ty = subject_type,
                    .is_mut = false,
                }) catch return error.CodegenAlloc;
            },
            .at_binding => |ab| {
                // Bind the whole subject to the @ name.
                const whole_alloca = c.LLVMBuildAlloca(self.builder, subject_type, "at.bind");
                _ = c.LLVMBuildStore(self.builder, subject, whole_alloca);
                self.locals.put(self.allocator, ab.name, .{
                    .alloca = whole_alloca,
                    .ty = subject_type,
                    .is_mut = false,
                }) catch return error.CodegenAlloc;
                // Also bind inner pattern variables (e.g. variant payload).
                if (ab.pattern.kind == .variant) {
                    const vp = ab.pattern.kind.variant;
                    if ((vp.bindings.len > 0 or vp.nested_patterns.len > 0) and enum_info != null) {
                        const ei = enum_info.?;
                        for (ei.variant_names, 0..) |vn, vi| {
                            if (vn == vp.name) {
                                if (ei.variant_payload_types[vi]) |payload_type| {
                                    if (is_enum_struct) {
                                        const tmp2 = c.LLVMBuildAlloca(self.builder, subject_type, "at.subj");
                                        _ = c.LLVMBuildStore(self.builder, subject, tmp2);
                                        const pgep = c.LLVMBuildStructGEP2(self.builder, subject_type, tmp2, 1, "");
                                        const pptr = c.LLVMBuildBitCast(self.builder, pgep, c.LLVMPointerTypeInContext(self.context, 0), "");
                                        const pval = c.LLVMBuildLoad2(self.builder, payload_type, pptr, "at.payload");

                                        if (vp.bindings.len == 1) {
                                            const ba2 = c.LLVMBuildAlloca(self.builder, payload_type, "");
                                            _ = c.LLVMBuildStore(self.builder, pval, ba2);
                                            self.locals.put(self.allocator, vp.bindings[0], .{
                                                .alloca = ba2,
                                                .ty = payload_type,
                                                .is_mut = false,
                                            }) catch return error.CodegenAlloc;
                                        } else {
                                            // Multi-binding at_binding extraction.
                                            const pval_alloca = c.LLVMBuildAlloca(self.builder, payload_type, "at.mp");
                                            _ = c.LLVMBuildStore(self.builder, pval, pval_alloca);
                                            for (vp.bindings, 0..) |bind_sym, bi| {
                                                const field_ty = c.LLVMStructGetTypeAtIndex(payload_type, @intCast(bi));
                                                const field_gep = c.LLVMBuildStructGEP2(self.builder, payload_type, pval_alloca, @intCast(bi), "at.mp.f");
                                                const field_val = c.LLVMBuildLoad2(self.builder, field_ty, field_gep, "at.mp.v");
                                                const ba2 = c.LLVMBuildAlloca(self.builder, field_ty, "");
                                                _ = c.LLVMBuildStore(self.builder, field_val, ba2);
                                                self.locals.put(self.allocator, bind_sym, .{
                                                    .alloca = ba2,
                                                    .ty = field_ty,
                                                    .is_mut = false,
                                                }) catch return error.CodegenAlloc;
                                            }
                                        }
                                    }
                                }
                                break;
                            }
                        }
                    }
                }
            },
            else => {},
        }

        // Handle implicit nested pattern guard: for arms like Some(Some(v)) vs Some(None),
        // generate an inner-tag check that falls through to next same-tag arm if it doesn't match.
        if (arm.pattern.kind == .variant) {
            const vp = arm.pattern.kind.variant;
            if (vp.nested_patterns.len > 0 and enum_info != null) {
                const ei = enum_info.?;
                for (ei.variant_names, 0..) |vn, vi| {
                    if (vn == vp.name) {
                        if (ei.variant_payload_types[vi]) |payload_type| {
                            if (is_enum_struct) {
                                // Extract payload from subject.
                                const tmp_n = c.LLVMBuildAlloca(self.builder, subject_type, "nest.subj");
                                _ = c.LLVMBuildStore(self.builder, subject, tmp_n);
                                const pgep_n = c.LLVMBuildStructGEP2(self.builder, subject_type, tmp_n, 1, "nest.p.ptr");
                                const pptr_n = c.LLVMBuildBitCast(self.builder, pgep_n, c.LLVMPointerTypeInContext(self.context, 0), "");
                                const payload_val_n = c.LLVMBuildLoad2(self.builder, payload_type, pptr_n, "nest.payload");
                                // Generate nested guard checks.
                                try self.genNestedPatternGuard(payload_val_n, payload_type, vp.nested_patterns, &guard_fallthrough, &arm_bbs_buf, i, m.arms.len, default_bb);
                            }
                        }
                        break;
                    }
                }
            }
        }

        // Handle guard clause: if guard is false, jump to next same-tag arm or default.
        if (arm.guard) |guard| {
            const guard_val = try self.genExpr(guard);
            const guard_cond = if (c.LLVMTypeOf(guard_val) == c.LLVMInt1TypeInContext(self.context))
                guard_val
            else
                c.LLVMBuildICmp(self.builder, c.LLVMIntNE, guard_val, c.LLVMConstNull(c.LLVMTypeOf(guard_val)), "guard");
            const body_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "guard.pass");
            // On guard failure: prefer next arm with same tag, else next arm, else default.
            const fallthrough_bb = if (guard_fallthrough[i]) |next_same|
                arm_bbs_buf[next_same]
            else if (i + 1 < m.arms.len)
                arm_bbs_buf[i + 1]
            else
                default_bb;
            _ = c.LLVMBuildCondBr(self.builder, guard_cond, body_bb, fallthrough_bb);
            c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
        }

        const arm_val = try self.genExpr(arm.body);

        // If the arm body diverges (break, continue, return), the builder is
        // positioned in a dead block (no predecessors, no terminator) that was
        // created after the diverging instruction. Detect this by checking:
        //   1. arm value is void (diverging expressions return void undef)
        //   2. current block differs from arm entry (new blocks were created)
        //   3. current block has no terminator AND no predecessors (truly dead)
        // Note: intermediate blocks created by overflow checks etc. ARE live
        // (they have predecessors), so checking arm_bbs_buf[i] termination
        // alone would incorrectly flag those.
        const cur_bb = c.LLVMGetInsertBlock(self.builder);
        const arm_val_is_void = c.LLVMTypeOf(arm_val) == c.LLVMVoidTypeInContext(self.context);
        const cur_bb_is_dead = cur_bb != arm_bbs_buf[i] and
            c.LLVMGetBasicBlockTerminator(cur_bb) == null and
            c.LLVMGetFirstUse(c.LLVMBasicBlockAsValue(cur_bb)) == null;
        const arm_body_diverged = arm_val_is_void and cur_bb_is_dead;

        if (arm_body_diverged) {
            // Arm already branched away (break/return/continue). Add unreachable
            // to the dead block and skip the phi contribution.
            _ = c.LLVMBuildUnreachable(self.builder);
        } else if (c.LLVMGetBasicBlockTerminator(cur_bb) == null) {
            arm_vals_buf[arm_count] = arm_val;
            arm_from_bbs_buf[arm_count] = cur_bb;
            arm_count += 1;
            _ = c.LLVMBuildBr(self.builder, merge_bb);
        }
    }

    // If no wildcard and no range patterns, make default_bb unreachable.
    if (wildcard_arm_idx == null and !has_range_patterns) {
        c.LLVMPositionBuilderAtEnd(self.builder, default_bb);
        _ = c.LLVMBuildUnreachable(self.builder);
    }

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);

    // Build phi.
    if (arm_count > 0) {
        const result_type = c.LLVMTypeOf(arm_vals_buf[0]);
        const is_void = result_type == c.LLVMVoidTypeInContext(self.context);
        if (is_void) {
            return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
        }
        const phi = c.LLVMBuildPhi(self.builder, result_type, "match.result");
        c.LLVMAddIncoming(phi, &arm_vals_buf, &arm_from_bbs_buf, arm_count);
        return phi;
    }

    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn buildTuplePatternCond(self: *Codegen, pattern: Ast.Pattern, value_type: c.LLVMTypeRef, value_ptr: c.LLVMValueRef) Error!c.LLVMValueRef {
    const i1_type = c.LLVMInt1TypeInContext(self.context);
    switch (pattern.kind) {
        .wildcard, .binding => return c.LLVMConstInt(i1_type, 1, 0),
        .at_binding => |ab| return self.buildTuplePatternCond(ab.pattern.*, value_type, value_ptr),
        .or_pattern => |alts| {
            if (alts.len == 0) return c.LLVMConstInt(i1_type, 0, 0);
            var cond = c.LLVMConstInt(i1_type, 0, 0);
            for (alts) |alt| {
                const alt_cond = try self.buildTuplePatternCond(alt, value_type, value_ptr);
                cond = c.LLVMBuildOr(self.builder, cond, alt_cond, "pat.or");
            }
            return cond;
        },
        .int_literal => |lit| {
            if (c.LLVMGetTypeKind(value_type) != c.LLVMIntegerTypeKind) return c.LLVMConstInt(i1_type, 0, 0);
            const value = c.LLVMBuildLoad2(self.builder, value_type, value_ptr, "pat.int");
            const lit_val = c.LLVMConstInt(value_type, @bitCast(lit), 1);
            return c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, value, lit_val, "pat.int.eq");
        },
        .bool_literal => |lit| {
            if (c.LLVMGetTypeKind(value_type) != c.LLVMIntegerTypeKind) return c.LLVMConstInt(i1_type, 0, 0);
            const value = c.LLVMBuildLoad2(self.builder, value_type, value_ptr, "pat.bool");
            const lit_val = c.LLVMConstInt(value_type, @intFromBool(lit), 0);
            return c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, value, lit_val, "pat.bool.eq");
        },
        .tuple_pattern => |elems| {
            if (c.LLVMGetTypeKind(value_type) != c.LLVMStructTypeKind) return c.LLVMConstInt(i1_type, 0, 0);
            const field_count: usize = @intCast(c.LLVMCountStructElementTypes(value_type));
            if (elems.len != field_count) return c.LLVMConstInt(i1_type, 0, 0);

            var cond = c.LLVMConstInt(i1_type, 1, 0);
            const i32_type = c.LLVMInt32TypeInContext(self.context);
            for (elems, 0..) |elem, i| {
                const idx: u32 = @intCast(i);
                const elem_type = c.LLVMStructGetTypeAtIndex(value_type, idx);
                var indices = [_]c.LLVMValueRef{
                    c.LLVMConstInt(i32_type, 0, 0),
                    c.LLVMConstInt(i32_type, idx, 0),
                };
                const elem_ptr = c.LLVMBuildGEP2(self.builder, value_type, value_ptr, &indices, 2, "pat.tuple.gep");
                const sub = try self.buildTuplePatternCond(elem, elem_type, elem_ptr);
                cond = c.LLVMBuildAnd(self.builder, cond, sub, "pat.tuple.and");
            }
            return cond;
        },
        else => return c.LLVMConstInt(i1_type, 0, 0),
    }
}

fn genStructMatch(self: *Codegen, m: Ast.MatchExpr, subject: c.LLVMValueRef, subject_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "structmatch.end");
    const subj_alloca = c.LLVMBuildAlloca(self.builder, subject_type, "structmatch.subj");
    _ = c.LLVMBuildStore(self.builder, subject, subj_alloca);

    // Find struct type info by matching LLVM type.
    var struct_info: ?StructTypeInfo = null;
    {
        var it = self.struct_types.iterator();
        while (it.next()) |entry| {
            if (entry.value_ptr.llvm_type == subject_type) {
                struct_info = entry.value_ptr.*;
                break;
            }
        }
    }
    if (struct_info == null) return error.UnsupportedExpr;
    const sinfo = struct_info.?;

    var arm_vals_buf: [64]c.LLVMValueRef = undefined;
    var arm_from_bbs_buf: [64]c.LLVMBasicBlockRef = undefined;
    var arm_count: u32 = 0;

    for (m.arms) |arm| {
        const arm_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "structmatch.arm");
        const next_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "structmatch.next");

        switch (arm.pattern.kind) {
            .wildcard, .binding => {
                _ = c.LLVMBuildBr(self.builder, arm_bb);
            },
            .struct_pattern => |sp| {
                // Build condition: AND all field comparisons.
                var cond: c.LLVMValueRef = c.LLVMConstInt(c.LLVMInt1TypeInContext(self.context), 1, 0); // true
                for (sp.fields) |field| {
                    if (field.pattern) |pat| {
                        // Find field index.
                        var field_idx: ?u32 = null;
                        for (sinfo.field_names, 0..) |fn_sym, fi| {
                            if (fn_sym == field.name) {
                                field_idx = @intCast(fi);
                                break;
                            }
                        }
                        if (field_idx) |fi| {
                            const field_gep = c.LLVMBuildStructGEP2(self.builder, subject_type, subj_alloca, fi, "sp.field.ptr");
                            const field_val = c.LLVMBuildLoad2(self.builder, sinfo.field_types[fi], field_gep, "sp.field");
                            const field_cond = self.buildPatternCond(pat.*, field_val);
                            cond = c.LLVMBuildAnd(self.builder, cond, field_cond, "sp.and");
                        }
                    }
                }
                _ = c.LLVMBuildCondBr(self.builder, cond, arm_bb, next_bb);
            },
            else => {
                _ = c.LLVMBuildBr(self.builder, next_bb);
            },
        }

        c.LLVMPositionBuilderAtEnd(self.builder, arm_bb);

        // Bind pattern variables.
        switch (arm.pattern.kind) {
            .struct_pattern => |sp| {
                for (sp.fields) |field| {
                    if (field.pattern == null) {
                        // Shorthand binding: bind field value to variable
                        var field_idx: ?u32 = null;
                        for (sinfo.field_names, 0..) |fn_sym, fi| {
                            if (fn_sym == field.name) {
                                field_idx = @intCast(fi);
                                break;
                            }
                        }
                        if (field_idx) |fi| {
                            const field_gep = c.LLVMBuildStructGEP2(self.builder, subject_type, subj_alloca, fi, "sp.bind.ptr");
                            const field_val = c.LLVMBuildLoad2(self.builder, sinfo.field_types[fi], field_gep, "sp.bind");
                            const local_alloca = c.LLVMBuildAlloca(self.builder, sinfo.field_types[fi], "sp.local");
                            _ = c.LLVMBuildStore(self.builder, field_val, local_alloca);
                            self.locals.put(self.allocator, field.name, .{
                                .alloca = local_alloca,
                                .ty = sinfo.field_types[fi],
                                .is_mut = false,
                            }) catch return error.CodegenAlloc;
                        }
                    } else if (field.pattern) |pat| {
                        // If the field value pattern is a binding, bind it
                        if (pat.kind == .binding) {
                            var field_idx: ?u32 = null;
                            for (sinfo.field_names, 0..) |fn_sym, fi| {
                                if (fn_sym == field.name) {
                                    field_idx = @intCast(fi);
                                    break;
                                }
                            }
                            if (field_idx) |fi| {
                                const field_gep = c.LLVMBuildStructGEP2(self.builder, subject_type, subj_alloca, fi, "sp.pbind.ptr");
                                const field_val = c.LLVMBuildLoad2(self.builder, sinfo.field_types[fi], field_gep, "sp.pbind");
                                const local_alloca = c.LLVMBuildAlloca(self.builder, sinfo.field_types[fi], "sp.plocal");
                                _ = c.LLVMBuildStore(self.builder, field_val, local_alloca);
                                self.locals.put(self.allocator, pat.kind.binding, .{
                                    .alloca = local_alloca,
                                    .ty = sinfo.field_types[fi],
                                    .is_mut = false,
                                }) catch return error.CodegenAlloc;
                            }
                        }
                    }
                }
            },
            .binding => |sym| {
                self.locals.put(self.allocator, sym, .{
                    .alloca = subj_alloca,
                    .ty = subject_type,
                    .is_mut = false,
                }) catch return error.CodegenAlloc;
            },
            else => {},
        }

        if (arm.guard) |guard| {
            const guard_val = try self.genExpr(guard);
            const guard_cond = if (c.LLVMTypeOf(guard_val) == c.LLVMInt1TypeInContext(self.context))
                guard_val
            else
                c.LLVMBuildICmp(self.builder, c.LLVMIntNE, guard_val, c.LLVMConstNull(c.LLVMTypeOf(guard_val)), "guard");
            const guard_pass_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "structmatch.guard");
            _ = c.LLVMBuildCondBr(self.builder, guard_cond, guard_pass_bb, next_bb);
            c.LLVMPositionBuilderAtEnd(self.builder, guard_pass_bb);
        }

        const arm_val = try self.genExpr(arm.body);
        const arm_end = c.LLVMGetInsertBlock(self.builder);
        if (c.LLVMGetBasicBlockTerminator(arm_end) == null) {
            arm_vals_buf[arm_count] = arm_val;
            arm_from_bbs_buf[arm_count] = arm_end;
            arm_count += 1;
            _ = c.LLVMBuildBr(self.builder, merge_bb);
        }

        c.LLVMPositionBuilderAtEnd(self.builder, next_bb);
    }

    const fallthrough = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(fallthrough) == null) {
        _ = c.LLVMBuildUnreachable(self.builder);
    }

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    if (arm_count > 0) {
        const result_type = c.LLVMTypeOf(arm_vals_buf[0]);
        if (result_type == c.LLVMVoidTypeInContext(self.context)) {
            return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
        }
        const phi = c.LLVMBuildPhi(self.builder, result_type, "structmatch.result");
        c.LLVMAddIncoming(phi, &arm_vals_buf, &arm_from_bbs_buf, arm_count);
        return phi;
    }
    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

/// Build a condition for a simple pattern (int, bool comparison).
fn buildPatternCond(self: *Codegen, pattern: Ast.Pattern, val: c.LLVMValueRef) c.LLVMValueRef {
    return switch (pattern.kind) {
        .int_literal => |v| c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, val, c.LLVMConstInt(c.LLVMTypeOf(val), @bitCast(v), 1), "pat.eq"),
        .bool_literal => |v| c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, val, c.LLVMConstInt(c.LLVMInt1TypeInContext(self.context), @intFromBool(v), 0), "pat.eq"),
        .wildcard, .binding => c.LLVMConstInt(c.LLVMInt1TypeInContext(self.context), 1, 0), // always true
        else => c.LLVMConstInt(c.LLVMInt1TypeInContext(self.context), 1, 0),
    };
}

fn genTupleMatch(self: *Codegen, m: Ast.MatchExpr, subject: c.LLVMValueRef, subject_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "tuplematch.end");
    const subj_alloca = c.LLVMBuildAlloca(self.builder, subject_type, "tuplematch.subj");
    _ = c.LLVMBuildStore(self.builder, subject, subj_alloca);

    var arm_vals_buf: [64]c.LLVMValueRef = undefined;
    var arm_from_bbs_buf: [64]c.LLVMBasicBlockRef = undefined;
    var arm_count: u32 = 0;

    for (m.arms) |arm| {
        const arm_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "tuplematch.arm");
        const next_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "tuplematch.next");

        switch (arm.pattern.kind) {
            .wildcard, .binding => {
                _ = c.LLVMBuildBr(self.builder, arm_bb);
            },
            else => {
                const cond = try self.buildTuplePatternCond(arm.pattern, subject_type, subj_alloca);
                _ = c.LLVMBuildCondBr(self.builder, cond, arm_bb, next_bb);
            },
        }

        c.LLVMPositionBuilderAtEnd(self.builder, arm_bb);
        try self.bindPatternFromPtr(arm.pattern, subject_type, subj_alloca, false);

        if (arm.guard) |guard| {
            const guard_val = try self.genExpr(guard);
            const guard_cond = if (c.LLVMTypeOf(guard_val) == c.LLVMInt1TypeInContext(self.context))
                guard_val
            else
                c.LLVMBuildICmp(self.builder, c.LLVMIntNE, guard_val, c.LLVMConstNull(c.LLVMTypeOf(guard_val)), "guard");
            const guard_pass_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "tuplematch.guard");
            _ = c.LLVMBuildCondBr(self.builder, guard_cond, guard_pass_bb, next_bb);
            c.LLVMPositionBuilderAtEnd(self.builder, guard_pass_bb);
        }

        const arm_val = try self.genExpr(arm.body);
        const arm_end = c.LLVMGetInsertBlock(self.builder);
        if (c.LLVMGetBasicBlockTerminator(arm_end) == null) {
            arm_vals_buf[arm_count] = arm_val;
            arm_from_bbs_buf[arm_count] = arm_end;
            arm_count += 1;
            _ = c.LLVMBuildBr(self.builder, merge_bb);
        }

        c.LLVMPositionBuilderAtEnd(self.builder, next_bb);
    }

    const fallthrough = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(fallthrough) == null) {
        _ = c.LLVMBuildUnreachable(self.builder);
    }

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    if (arm_count > 0) {
        const result_type = c.LLVMTypeOf(arm_vals_buf[0]);
        if (result_type == c.LLVMVoidTypeInContext(self.context)) {
            return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
        }
        const phi = c.LLVMBuildPhi(self.builder, result_type, "tuplematch.result");
        c.LLVMAddIncoming(phi, &arm_vals_buf, &arm_from_bbs_buf, arm_count);
        return phi;
    }
    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

/// Generate a match on arrays/vecs with slice patterns.
/// Uses if-else chain comparing lengths rather than switch on tags.
fn genSliceMatch(self: *Codegen, m: Ast.MatchExpr, subject: c.LLVMValueRef, subject_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    // Get the array length and element pointer.
    var arr_len: c.LLVMValueRef = undefined;
    var arr_ptr: c.LLVMValueRef = undefined;
    var elem_type: c.LLVMTypeRef = undefined;
    const i64_type = c.LLVMInt64TypeInContext(self.context);

    if (c.LLVMGetTypeKind(subject_type) == c.LLVMArrayTypeKind) {
        // Fixed-size array: [T; N]
        const arr_len_const: u64 = c.LLVMGetArrayLength2(subject_type);
        arr_len = c.LLVMConstInt(i64_type, arr_len_const, 0);
        elem_type = c.LLVMGetElementType(subject_type);
        // Store array to get a pointer for GEP.
        const tmp = c.LLVMBuildAlloca(self.builder, subject_type, "arr.tmp");
        _ = c.LLVMBuildStore(self.builder, subject, tmp);
        arr_ptr = tmp;
    } else if (self.isVecType(subject_type)) {
        // Vec: { ptr, len, cap }
        const tmp = c.LLVMBuildAlloca(self.builder, subject_type, "vec.tmp");
        _ = c.LLVMBuildStore(self.builder, subject, tmp);
        const len_gep = c.LLVMBuildStructGEP2(self.builder, subject_type, tmp, 1, "len.ptr");
        arr_len = c.LLVMBuildLoad2(self.builder, i64_type, len_gep, "vec.len");
        const ptr_gep = c.LLVMBuildStructGEP2(self.builder, subject_type, tmp, 0, "ptr.ptr");
        arr_ptr = c.LLVMBuildLoad2(self.builder, c.LLVMPointerTypeInContext(self.context, 0), ptr_gep, "vec.ptr");
        elem_type = c.LLVMInt32TypeInContext(self.context); // default; could detect
    } else {
        return error.UnsupportedExpr;
    }

    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "slice.end");
    var arm_vals_buf: [64]c.LLVMValueRef = undefined;
    var arm_from_bbs_buf: [64]c.LLVMBasicBlockRef = undefined;
    var arm_count: u32 = 0;
    const is_fixed_arr = c.LLVMGetTypeKind(subject_type) == c.LLVMArrayTypeKind;

    for (m.arms) |arm| {
        const arm_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "slice.arm");
        const next_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "slice.next");

        switch (arm.pattern.kind) {
            .slice_pattern => |sp| {
                const min_required: u64 = @intCast(sp.head.len + sp.tail.len);
                const min_val = c.LLVMConstInt(i64_type, min_required, 0);
                const cond = if (sp.has_rest)
                    // [a, ..rest] matches len >= head.len + tail.len
                    c.LLVMBuildICmp(self.builder, c.LLVMIntSGE, arr_len, min_val, "len.ge")
                else
                    // [a, b] matches len == head.len
                    c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, arr_len, min_val, "len.eq");
                _ = c.LLVMBuildCondBr(self.builder, cond, arm_bb, next_bb);

                c.LLVMPositionBuilderAtEnd(self.builder, arm_bb);

                // Bind head elements.
                for (sp.head, 0..) |bind_sym, idx| {
                    if (bind_sym == 0) continue; // wildcard _
                    const idx_val = c.LLVMConstInt(i64_type, @intCast(idx), 0);
                    const elem_val = if (is_fixed_arr) blk: {
                        var indices = [_]c.LLVMValueRef{
                            c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0),
                            c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), @intCast(idx), 0),
                        };
                        const gep = c.LLVMBuildGEP2(self.builder, subject_type, arr_ptr, &indices, 2, "elem.ptr");
                        break :blk c.LLVMBuildLoad2(self.builder, elem_type, gep, "elem");
                    } else blk: {
                        var vec_idx = [_]c.LLVMValueRef{idx_val};
                        const gep = c.LLVMBuildGEP2(self.builder, elem_type, arr_ptr, &vec_idx, 1, "elem.ptr");
                        break :blk c.LLVMBuildLoad2(self.builder, elem_type, gep, "elem");
                    };
                    const ea = c.LLVMBuildAlloca(self.builder, elem_type, "");
                    _ = c.LLVMBuildStore(self.builder, elem_val, ea);
                    self.locals.put(self.allocator, bind_sym, .{
                        .alloca = ea,
                        .ty = elem_type,
                        .is_mut = false,
                    }) catch return error.CodegenAlloc;
                }

                // Bind rest as array length.
                if (sp.has_rest and sp.rest != 0) {
                    // rest = arr_len - head.len - tail.len
                    const head_count = c.LLVMConstInt(i64_type, @intCast(sp.head.len), 0);
                    const tail_count = c.LLVMConstInt(i64_type, @intCast(sp.tail.len), 0);
                    const rest_len = c.LLVMBuildSub(self.builder, arr_len, c.LLVMBuildAdd(self.builder, head_count, tail_count, ""), "rest.len");
                    const ra = c.LLVMBuildAlloca(self.builder, i64_type, "rest");
                    _ = c.LLVMBuildStore(self.builder, rest_len, ra);
                    self.locals.put(self.allocator, sp.rest, .{
                        .alloca = ra,
                        .ty = i64_type,
                        .is_mut = false,
                    }) catch return error.CodegenAlloc;
                }

                // Bind tail elements from the end: [.., a, b]
                if (sp.tail.len > 0) {
                    const tail_len_val = c.LLVMConstInt(i64_type, @intCast(sp.tail.len), 0);
                    const tail_start = c.LLVMBuildSub(self.builder, arr_len, tail_len_val, "tail.start");
                    for (sp.tail, 0..) |bind_sym, tail_i| {
                        if (bind_sym == 0) continue; // wildcard _
                        const off = c.LLVMConstInt(i64_type, @intCast(tail_i), 0);
                        const elem_idx = c.LLVMBuildAdd(self.builder, tail_start, off, "tail.idx");
                        const elem_val = if (is_fixed_arr) blk: {
                            var indices = [_]c.LLVMValueRef{
                                c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0),
                                self.coerceInt(elem_idx, c.LLVMInt32TypeInContext(self.context)),
                            };
                            const gep = c.LLVMBuildGEP2(self.builder, subject_type, arr_ptr, &indices, 2, "tail.ptr");
                            break :blk c.LLVMBuildLoad2(self.builder, elem_type, gep, "tail.elem");
                        } else blk: {
                            var vec_idx = [_]c.LLVMValueRef{elem_idx};
                            const gep = c.LLVMBuildGEP2(self.builder, elem_type, arr_ptr, &vec_idx, 1, "tail.ptr");
                            break :blk c.LLVMBuildLoad2(self.builder, elem_type, gep, "tail.elem");
                        };

                        const ba = c.LLVMBuildAlloca(self.builder, elem_type, "tail.bind");
                        _ = c.LLVMBuildStore(self.builder, elem_val, ba);
                        self.locals.put(self.allocator, bind_sym, .{
                            .alloca = ba,
                            .ty = elem_type,
                            .is_mut = false,
                        }) catch return error.CodegenAlloc;
                    }
                }
            },
            .wildcard => {
                // Wildcard matches anything.
                _ = c.LLVMBuildBr(self.builder, arm_bb);
                c.LLVMPositionBuilderAtEnd(self.builder, arm_bb);
            },
            .binding => |sym| {
                _ = c.LLVMBuildBr(self.builder, arm_bb);
                c.LLVMPositionBuilderAtEnd(self.builder, arm_bb);
                const ba = c.LLVMBuildAlloca(self.builder, subject_type, "");
                _ = c.LLVMBuildStore(self.builder, subject, ba);
                self.locals.put(self.allocator, sym, .{
                    .alloca = ba,
                    .ty = subject_type,
                    .is_mut = false,
                }) catch return error.CodegenAlloc;
            },
            else => {
                _ = c.LLVMBuildBr(self.builder, arm_bb);
                c.LLVMPositionBuilderAtEnd(self.builder, arm_bb);
            },
        }

        const arm_val = try self.genExpr(arm.body);
        arm_vals_buf[arm_count] = arm_val;
        arm_from_bbs_buf[arm_count] = c.LLVMGetInsertBlock(self.builder);
        arm_count += 1;
        _ = c.LLVMBuildBr(self.builder, merge_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, next_bb);
    }

    // After all arms, unreachable.
    _ = c.LLVMBuildUnreachable(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);

    if (arm_count > 0) {
        const result_type = c.LLVMTypeOf(arm_vals_buf[0]);
        if (result_type == c.LLVMVoidTypeInContext(self.context)) {
            return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
        }
        const phi = c.LLVMBuildPhi(self.builder, result_type, "slice.result");
        c.LLVMAddIncoming(phi, &arm_vals_buf, &arm_from_bbs_buf, arm_count);
        return phi;
    }
    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

/// Generate match expression for string patterns using strcmp chains.
fn genStringMatch(self: *Codegen, m: Ast.MatchExpr, subject: c.LLVMValueRef, subject_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    _ = subject_type;
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "strmatch.end");

    // Extract ptr and len from subject str struct.
    const subj_alloca = c.LLVMBuildAlloca(self.builder, c.LLVMTypeOf(subject), "strmatch.subj");
    _ = c.LLVMBuildStore(self.builder, subject, subj_alloca);
    const str_type = c.LLVMTypeOf(subject);
    const subj_ptr_gep = c.LLVMBuildStructGEP2(self.builder, str_type, subj_alloca, 0, "subj.ptr.gep");
    const subj_ptr = c.LLVMBuildLoad2(self.builder, c.LLVMPointerTypeInContext(self.context, 0), subj_ptr_gep, "subj.ptr");
    const subj_len_gep = c.LLVMBuildStructGEP2(self.builder, str_type, subj_alloca, 1, "subj.len.gep");
    const subj_len = c.LLVMBuildLoad2(self.builder, c.LLVMInt64TypeInContext(self.context), subj_len_gep, "subj.len");

    const strncmp_fn = self.ensureStrncmpDeclared();

    var arm_vals_buf: [64]c.LLVMValueRef = undefined;
    var arm_from_bbs_buf: [64]c.LLVMBasicBlockRef = undefined;
    var arm_count: u32 = 0;
    var had_wildcard = false;

    // Build chain of comparisons: for each string pattern, compare length + content.
    var i: usize = 0;
    while (i < m.arms.len) : (i += 1) {
        const arm = m.arms[i];
        switch (arm.pattern.kind) {
            .string_literal => |pat_sym| {
                const pat_str = self.pool.resolve(pat_sym);
                const pat_len = pat_str.len;

                // Check length first.
                const pat_len_val = c.LLVMConstInt(c.LLVMInt64TypeInContext(self.context), @intCast(pat_len), 0);
                const len_eq = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, subj_len, pat_len_val, "len.eq");

                const len_ok_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "strmatch.lenok");
                const next_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "strmatch.next");
                _ = c.LLVMBuildCondBr(self.builder, len_eq, len_ok_bb, next_bb);

                // Length matches — compare content with strncmp.
                c.LLVMPositionBuilderAtEnd(self.builder, len_ok_bb);
                const pat_global = c.LLVMBuildGlobalStringPtr(self.builder, @ptrCast(pat_str.ptr), "pat.str");
                var cmp_args = [3]c.LLVMValueRef{ subj_ptr, pat_global, pat_len_val };
                const cmp_result = c.LLVMBuildCall2(self.builder, strncmp_fn.fn_type, strncmp_fn.value, &cmp_args, 3, "strcmp");
                const str_eq = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, cmp_result, c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0), "str.eq");

                const body_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "strmatch.body");
                _ = c.LLVMBuildCondBr(self.builder, str_eq, body_bb, next_bb);

                // Generate arm body.
                c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
                if (arm.guard) |guard| {
                    const guard_val = try self.genExpr(guard);
                    const guard_cond = if (c.LLVMTypeOf(guard_val) == c.LLVMInt1TypeInContext(self.context))
                        guard_val
                    else
                        c.LLVMBuildICmp(self.builder, c.LLVMIntNE, guard_val, c.LLVMConstNull(c.LLVMTypeOf(guard_val)), "guard");
                    const guard_pass_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "strmatch.guard");
                    _ = c.LLVMBuildCondBr(self.builder, guard_cond, guard_pass_bb, next_bb);
                    c.LLVMPositionBuilderAtEnd(self.builder, guard_pass_bb);
                }
                const arm_val = try self.genExpr(arm.body);
                arm_vals_buf[arm_count] = arm_val;
                arm_from_bbs_buf[arm_count] = c.LLVMGetInsertBlock(self.builder);
                arm_count += 1;
                _ = c.LLVMBuildBr(self.builder, merge_bb);

                // Position for next comparison.
                c.LLVMPositionBuilderAtEnd(self.builder, next_bb);
            },
            .wildcard, .binding => {
                // Default arm — generate body directly in the current fallthrough block.
                had_wildcard = true;
                if (arm.pattern.kind == .binding) {
                    const sym = arm.pattern.kind.binding;
                    const bind_alloca = c.LLVMBuildAlloca(self.builder, c.LLVMTypeOf(subject), "");
                    _ = c.LLVMBuildStore(self.builder, subject, bind_alloca);
                    self.locals.put(self.allocator, sym, .{
                        .alloca = bind_alloca,
                        .ty = c.LLVMTypeOf(subject),
                        .is_mut = false,
                    }) catch return error.CodegenAlloc;
                }
                const arm_val = try self.genExpr(arm.body);
                arm_vals_buf[arm_count] = arm_val;
                arm_from_bbs_buf[arm_count] = c.LLVMGetInsertBlock(self.builder);
                arm_count += 1;
                _ = c.LLVMBuildBr(self.builder, merge_bb);
                break; // wildcard is terminal — stop processing arms
            },
            else => {},
        }
    }

    // If no wildcard arm, the fallthrough path needs to terminate.
    if (!had_wildcard) {
        _ = c.LLVMBuildUnreachable(self.builder);
    }

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    if (arm_count > 0) {
        const result_type = c.LLVMTypeOf(arm_vals_buf[0]);
        if (result_type == c.LLVMVoidTypeInContext(self.context)) {
            return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
        }
        const phi = c.LLVMBuildPhi(self.builder, result_type, "strmatch.result");
        c.LLVMAddIncoming(phi, &arm_vals_buf, &arm_from_bbs_buf, arm_count);
        return phi;
    }
    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn isResultType(self: *Codegen, ty: c.LLVMTypeRef) bool {
    var it = self.result_type_cache.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == ty or self.sameStructTypeName(entry.value_ptr.llvm_type, ty)) return true;
    }
    return false;
}

fn isOptionType(self: *Codegen, ty: c.LLVMTypeRef) bool {
    var it = self.option_type_cache.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == ty or self.sameStructTypeName(entry.value_ptr.llvm_type, ty)) return true;
    }
    return false;
}

fn sameStructTypeName(_: *Codegen, lhs: c.LLVMTypeRef, rhs: c.LLVMTypeRef) bool {
    if (c.LLVMGetTypeKind(lhs) != c.LLVMStructTypeKind or c.LLVMGetTypeKind(rhs) != c.LLVMStructTypeKind) return false;
    const lhs_name = c.LLVMGetStructName(lhs);
    const rhs_name = c.LLVMGetStructName(rhs);
    if (lhs_name == null or rhs_name == null) return false;
    return std.mem.eql(u8, std.mem.span(lhs_name), std.mem.span(rhs_name));
}

fn addMatchCase(self: *Codegen, sw: c.LLVMValueRef, pattern: Ast.Pattern, tag_val: c.LLVMValueRef, target_bb: c.LLVMBasicBlockRef, enum_info: ?EnumTypeInfo) void {
    switch (pattern.kind) {
        .int_literal => |val| {
            const case_val = c.LLVMConstInt(c.LLVMTypeOf(tag_val), @bitCast(val), 1);
            c.LLVMAddCase(sw, case_val, target_bb);
        },
        .bool_literal => |val| {
            const case_val = c.LLVMConstInt(c.LLVMInt1TypeInContext(self.context), @intFromBool(val), 0);
            c.LLVMAddCase(sw, case_val, target_bb);
        },
        .variant => |vp| {
            if (enum_info) |ei| {
                for (ei.variant_names, 0..) |vn, vi| {
                    if (vn == vp.name) {
                        const case_val = c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), @intCast(vi), 0);
                        c.LLVMAddCase(sw, case_val, target_bb);
                        break;
                    }
                }
            }
        },
        .or_pattern => |alternatives| {
            for (alternatives) |alt| {
                self.addMatchCase(sw, alt, tag_val, target_bb, enum_info);
            }
        },
        .at_binding => |ab| {
            // Dispatch to inner pattern for case matching.
            self.addMatchCase(sw, ab.pattern.*, tag_val, target_bb, enum_info);
        },
        .tuple_pattern => {},
        .range_pattern => {
            // Range patterns handled separately with comparison chains, not switch cases.
        },
        .wildcard, .binding => {},
        .string_literal => {},
        .slice_pattern => {}, // handled in genSliceMatch
        .struct_pattern => {}, // handled via comparison chain
    }
}

/// Extract the effective tag value for a pattern (for duplicate detection).
/// Returns null for patterns that don't map to a single switch case value.
fn getPatternTag(pattern: Ast.Pattern, enum_info: ?EnumTypeInfo) ?i64 {
    return switch (pattern.kind) {
        .variant => |vp| {
            if (enum_info) |ei| {
                for (ei.variant_names, 0..) |vn, vi| {
                    if (vn == vp.name) return @intCast(vi);
                }
            }
            return null;
        },
        .int_literal => |val| val,
        .bool_literal => |val| @intFromBool(val),
        .at_binding => |ab| getPatternTag(ab.pattern.*, enum_info),
        .tuple_pattern => null,
        else => null,
    };
}

fn genArrayLiteral(self: *Codegen, elems: []const *const Ast.Expr) Error!c.LLVMValueRef {
    if (elems.len == 0) return error.UnsupportedExpr;

    // Generate all elements first.
    var vals_buf: [256]c.LLVMValueRef = undefined;
    for (elems, 0..) |elem, i| {
        vals_buf[i] = try self.genExpr(elem);
    }

    // Determine element type from first element.
    const elem_type = c.LLVMTypeOf(vals_buf[0]);
    const array_type = c.LLVMArrayType2(elem_type, @intCast(elems.len));

    const alloca = c.LLVMBuildAlloca(self.builder, array_type, "arr");
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const zero = c.LLVMConstInt(i32_type, 0, 0);

    for (0..elems.len) |i| {
        var indices = [_]c.LLVMValueRef{ zero, c.LLVMConstInt(i32_type, @intCast(i), 0) };
        const gep = c.LLVMBuildGEP2(self.builder, array_type, alloca, &indices, 2, "");
        const coerced = self.coerceInt(vals_buf[i], elem_type);
        _ = c.LLVMBuildStore(self.builder, coerced, gep);
    }

    return c.LLVMBuildLoad2(self.builder, array_type, alloca, "arr.val");
}

fn genArrayComprehension(self: *Codegen, comp: Ast.ArrayComprehension) Error!c.LLVMValueRef {
    const ClauseInfo = struct {
        binding: u32,
        iter_type: c.LLVMTypeRef,
        start_val: c.LLVMValueRef, // constant of iter_type
        len: u64,
        stride: u64,
        alloca: c.LLVMValueRef,
        old_local: ?LocalInfo,
    };

    var one_clause = [_]Ast.ComprehensionClause{.{
        .binding = comp.binding,
        .iterable = comp.iterable,
    }};
    const clauses = if (comp.clauses) |cs| cs else one_clause[0..];
    if (clauses.len == 0) return error.UnsupportedExpr;

    var infos: std.ArrayList(ClauseInfo) = .empty;
    defer infos.deinit(self.allocator);
    infos.ensureTotalCapacity(self.allocator, clauses.len) catch return error.CodegenAlloc;

    // Parse all clauses as constant ranges so we can materialize a fixed-size array.
    for (clauses) |cl| {
        if (cl.iterable.kind != .range) return error.UnsupportedExpr;
        const range = cl.iterable.kind.range;

        const i32_type = c.LLVMInt32TypeInContext(self.context);
        const start_raw = if (range.start) |s| try self.genExpr(s) else c.LLVMConstInt(i32_type, 0, 0);
        const end_raw = if (range.end) |e| try self.genExpr(e) else return error.UnsupportedExpr;
        const iter_type = c.LLVMTypeOf(end_raw);
        const start_val = self.coerceInt(start_raw, iter_type);
        const end_val = self.coerceInt(end_raw, iter_type);

        if (c.LLVMIsConstant(start_val) == 0 or c.LLVMIsConstant(end_val) == 0) {
            return error.UnsupportedExpr;
        }

        const start_i: i64 = c.LLVMConstIntGetSExtValue(start_val);
        const end_i: i64 = c.LLVMConstIntGetSExtValue(end_val);
        const len: u64 = if (range.inclusive)
            (if (end_i >= start_i) @as(u64, @intCast(end_i - start_i + 1)) else 0)
        else
            (if (end_i > start_i) @as(u64, @intCast(end_i - start_i)) else 0);

        infos.appendAssumeCapacity(.{
            .binding = cl.binding,
            .iter_type = iter_type,
            .start_val = start_val,
            .len = len,
            .stride = 1,
            .alloca = undefined,
            .old_local = null,
        });
    }

    // Precompute clause strides and total Cartesian product size.
    var total_size: u64 = 1;
    var i: usize = infos.items.len;
    while (i > 0) {
        i -= 1;
        infos.items[i].stride = total_size;
        const mul = @mulWithOverflow(total_size, infos.items[i].len);
        if (mul[1] != 0) return error.UnsupportedExpr;
        total_size = mul[0];
    }

    // Bind clause variables in local scope for element/filter generation.
    for (infos.items) |*info| {
        const binding_alloca = c.LLVMBuildAlloca(self.builder, info.iter_type, "comp.var");
        _ = c.LLVMBuildStore(self.builder, info.start_val, binding_alloca);
        info.alloca = binding_alloca;
        info.old_local = self.locals.get(info.binding);
        self.locals.put(self.allocator, info.binding, .{
            .alloca = binding_alloca,
            .ty = info.iter_type,
            .is_mut = false,
        }) catch return error.CodegenAlloc;
    }
    defer {
        for (infos.items) |info| {
            if (info.old_local) |old| {
                self.locals.put(self.allocator, info.binding, old) catch {};
            } else {
                _ = self.locals.remove(info.binding);
            }
        }
    }

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const zero_i32 = c.LLVMConstInt(i32_type, 0, 0);
    const zero_i64 = c.LLVMConstInt(i64_type, 0, 0);
    const one_i64 = c.LLVMConstInt(i64_type, 1, 0);
    const total_i64 = c.LLVMConstInt(i64_type, total_size, 0);

    // Evaluate first element once to get result element type and avoid duplicate
    // evaluation for iteration 0.
    const first_val = try self.genExpr(comp.expr);
    const elem_type = c.LLVMTypeOf(first_val);
    const arr_type = c.LLVMArrayType2(elem_type, total_size);
    const arr_alloca = c.LLVMBuildAlloca(self.builder, arr_type, "comp.arr");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstNull(arr_type), arr_alloca);

    // Dense output index used when filter excludes some combinations.
    const out_idx_alloca = c.LLVMBuildAlloca(self.builder, i64_type, "comp.out_idx");
    _ = c.LLVMBuildStore(self.builder, zero_i64, out_idx_alloca);

    if (total_size > 0) {
        if (comp.filter) |filter_expr| {
            const function = self.current_function;
            const first_store_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "comp.first.store");
            const first_after_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "comp.first.after");
            const filter_val = try self.genExpr(filter_expr);
            _ = c.LLVMBuildCondBr(self.builder, filter_val, first_store_bb, first_after_bb);

            c.LLVMPositionBuilderAtEnd(self.builder, first_store_bb);
            const out_idx = c.LLVMBuildLoad2(self.builder, i64_type, out_idx_alloca, "");
            var idxs = [_]c.LLVMValueRef{ zero_i32, out_idx };
            const gep = c.LLVMBuildGEP2(self.builder, arr_type, arr_alloca, &idxs, 2, "");
            _ = c.LLVMBuildStore(self.builder, self.coerceInt(first_val, elem_type), gep);
            const out_next = c.LLVMBuildAdd(self.builder, out_idx, one_i64, "");
            _ = c.LLVMBuildStore(self.builder, out_next, out_idx_alloca);
            _ = c.LLVMBuildBr(self.builder, first_after_bb);

            c.LLVMPositionBuilderAtEnd(self.builder, first_after_bb);
        } else {
            var idx0 = [_]c.LLVMValueRef{ zero_i32, zero_i64 };
            const gep0 = c.LLVMBuildGEP2(self.builder, arr_type, arr_alloca, &idx0, 2, "");
            _ = c.LLVMBuildStore(self.builder, self.coerceInt(first_val, elem_type), gep0);
            _ = c.LLVMBuildStore(self.builder, one_i64, out_idx_alloca);
        }
    }

    // Remaining Cartesian iterations (start at flat index 1).
    if (total_size > 1) {
        const function = self.current_function;
        const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "comp.cond");
        const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "comp.body");
        const inc_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "comp.inc");
        const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "comp.end");

        const flat_alloca = c.LLVMBuildAlloca(self.builder, i64_type, "comp.flat");
        _ = c.LLVMBuildStore(self.builder, one_i64, flat_alloca);
        _ = c.LLVMBuildBr(self.builder, cond_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, cond_bb);
        const flat_cur = c.LLVMBuildLoad2(self.builder, i64_type, flat_alloca, "");
        const cond = c.LLVMBuildICmp(self.builder, c.LLVMIntULT, flat_cur, total_i64, "comp.cmp");
        _ = c.LLVMBuildCondBr(self.builder, cond, body_bb, end_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
        var rem = c.LLVMBuildLoad2(self.builder, i64_type, flat_alloca, "");
        for (infos.items, 0..) |info, idx| {
            const stride_const = c.LLVMConstInt(i64_type, info.stride, 0);
            const q = if (info.stride == 1)
                rem
            else
                c.LLVMBuildUDiv(self.builder, rem, stride_const, "comp.q");
            if (idx + 1 < infos.items.len and info.stride != 1) {
                rem = c.LLVMBuildURem(self.builder, rem, stride_const, "comp.r");
            }
            const q_cast = self.coerceInt(q, info.iter_type);
            const bind_val = c.LLVMBuildAdd(self.builder, info.start_val, q_cast, "comp.bind");
            _ = c.LLVMBuildStore(self.builder, bind_val, info.alloca);
        }

        if (comp.filter) |filter_expr| {
            const filter_val = try self.genExpr(filter_expr);
            const store_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "comp.store");
            const skip_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "comp.skip");
            _ = c.LLVMBuildCondBr(self.builder, filter_val, store_bb, skip_bb);

            c.LLVMPositionBuilderAtEnd(self.builder, store_bb);
            const val = try self.genExpr(comp.expr);
            const out_idx = c.LLVMBuildLoad2(self.builder, i64_type, out_idx_alloca, "");
            var store_idxs = [_]c.LLVMValueRef{ zero_i32, out_idx };
            const store_gep = c.LLVMBuildGEP2(self.builder, arr_type, arr_alloca, &store_idxs, 2, "");
            _ = c.LLVMBuildStore(self.builder, self.coerceInt(val, elem_type), store_gep);
            const out_next = c.LLVMBuildAdd(self.builder, out_idx, one_i64, "");
            _ = c.LLVMBuildStore(self.builder, out_next, out_idx_alloca);
            if (c.LLVMGetBasicBlockTerminator(c.LLVMGetInsertBlock(self.builder)) == null) {
                _ = c.LLVMBuildBr(self.builder, inc_bb);
            }

            c.LLVMPositionBuilderAtEnd(self.builder, skip_bb);
            if (c.LLVMGetBasicBlockTerminator(c.LLVMGetInsertBlock(self.builder)) == null) {
                _ = c.LLVMBuildBr(self.builder, inc_bb);
            }
        } else {
            const val = try self.genExpr(comp.expr);
            const out_idx = c.LLVMBuildLoad2(self.builder, i64_type, out_idx_alloca, "");
            var store_idxs = [_]c.LLVMValueRef{ zero_i32, out_idx };
            const store_gep = c.LLVMBuildGEP2(self.builder, arr_type, arr_alloca, &store_idxs, 2, "");
            _ = c.LLVMBuildStore(self.builder, self.coerceInt(val, elem_type), store_gep);
            const out_next = c.LLVMBuildAdd(self.builder, out_idx, one_i64, "");
            _ = c.LLVMBuildStore(self.builder, out_next, out_idx_alloca);
            if (c.LLVMGetBasicBlockTerminator(c.LLVMGetInsertBlock(self.builder)) == null) {
                _ = c.LLVMBuildBr(self.builder, inc_bb);
            }
        }

        c.LLVMPositionBuilderAtEnd(self.builder, inc_bb);
        const flat_loaded = c.LLVMBuildLoad2(self.builder, i64_type, flat_alloca, "");
        const flat_next = c.LLVMBuildAdd(self.builder, flat_loaded, one_i64, "");
        _ = c.LLVMBuildStore(self.builder, flat_next, flat_alloca);
        _ = c.LLVMBuildBr(self.builder, cond_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
    }

    return c.LLVMBuildLoad2(self.builder, arr_type, arr_alloca, "comp.result");
}

fn genIndex(self: *Codegen, idx: Ast.IndexExpr) Error!c.LLVMValueRef {
    // Fast path: direct local variable indexing.
    if (idx.expr.kind == .ident) {
        const arr_sym = idx.expr.kind.ident;
        if (self.locals.get(arr_sym)) |local| {
            // Array indexing.
            if (c.LLVMGetTypeKind(local.ty) == c.LLVMArrayTypeKind) {
                const index_val = try self.genExpr(idx.index);
                const i32_type = c.LLVMInt32TypeInContext(self.context);
                const index_i32 = self.coerceInt(index_val, i32_type);
                const zero = c.LLVMConstInt(i32_type, 0, 0);
                var indices = [_]c.LLVMValueRef{ zero, index_i32 };
                const gep = c.LLVMBuildGEP2(self.builder, local.ty, local.alloca, &indices, 2, "");
                const elem_type = c.LLVMGetElementType(local.ty);
                return c.LLVMBuildLoad2(self.builder, elem_type, gep, "elem");
            }
            // Slice indexing: extract ptr, GEP, load.
            if (self.slice_elem_types.get(arr_sym)) |elem_type| {
                const slice_val = c.LLVMBuildLoad2(self.builder, local.ty, local.alloca, "");
                const ptr = c.LLVMBuildExtractValue(self.builder, slice_val, 0, "slice.ptr");
                const index_val = try self.genExpr(idx.index);
                const index_i64 = self.coerceInt(index_val, c.LLVMInt64TypeInContext(self.context));
                var slice_gep_idx = [_]c.LLVMValueRef{index_i64};
                const elem_ptr = c.LLVMBuildGEP2(self.builder, elem_type, ptr, &slice_gep_idx, 1, "");
                return c.LLVMBuildLoad2(self.builder, elem_type, elem_ptr, "slice.elem");
            }
            // String indexing: s[i] → byte at index i (as i8).
            if (self.isStrType(local.ty)) {
                const str_val = c.LLVMBuildLoad2(self.builder, local.ty, local.alloca, "");
                const str_ptr = self.extractStrPtr(str_val);
                const index_val = try self.genExpr(idx.index);
                const index_i64 = self.coerceInt(index_val, c.LLVMInt64TypeInContext(self.context));
                var gep_idx = [_]c.LLVMValueRef{index_i64};
                const byte_ptr = c.LLVMBuildGEP2(self.builder, c.LLVMInt8TypeInContext(self.context), str_ptr, &gep_idx, 1, "str.byte.ptr");
                return c.LLVMBuildLoad2(self.builder, c.LLVMInt8TypeInContext(self.context), byte_ptr, "str.byte");
            }
            // Vec indexing: v[i] -> v.get(i)
            if (self.isVecType(local.ty)) {
                const vec_val = c.LLVMBuildLoad2(self.builder, local.ty, local.alloca, "");
                const index_val = try self.genExpr(idx.index);
                return self.genVecGet(vec_val, local.ty, index_val);
            }
            // HashMap indexing: map[key] -> map.get(key).unwrap()
            if (self.isHashMapType(local.ty)) {
                const map_val = c.LLVMBuildLoad2(self.builder, local.ty, local.alloca, "");
                const key_val = try self.genExpr(idx.index);
                const opt_val = try self.genHashMapGet(map_val, local.ty, key_val);
                const opt_type = c.LLVMTypeOf(opt_val);
                return self.genOptionUnwrap(opt_val, opt_type, null);
            }
            // Struct with `get` method → operator overload.
            if (c.LLVMGetTypeKind(local.ty) == c.LLVMStructTypeKind) {
                const obj_val = c.LLVMBuildLoad2(self.builder, local.ty, local.alloca, "");
                return self.tryIndexOverload(obj_val, local.ty, idx.index);
            }
        }
    }

    // General path: evaluate the expression, check its type.
    const obj_val = try self.genExpr(idx.expr);
    const obj_type = c.LLVMTypeOf(obj_val);

    // String indexing from non-local expressions (e.g. self.text[i]).
    if (self.isStrType(obj_type)) {
        const str_ptr = self.extractStrPtr(obj_val);
        const index_val = try self.genExpr(idx.index);
        const index_i64 = self.coerceInt(index_val, c.LLVMInt64TypeInContext(self.context));
        var gep_idx = [_]c.LLVMValueRef{index_i64};
        const byte_ptr = c.LLVMBuildGEP2(self.builder, c.LLVMInt8TypeInContext(self.context), str_ptr, &gep_idx, 1, "str.byte.ptr");
        return c.LLVMBuildLoad2(self.builder, c.LLVMInt8TypeInContext(self.context), byte_ptr, "str.byte");
    }

    if (c.LLVMGetTypeKind(obj_type) == c.LLVMStructTypeKind) {
        if (self.isVecType(obj_type)) {
            const index_val = try self.genExpr(idx.index);
            return self.genVecGet(obj_val, obj_type, index_val);
        }
        if (self.isHashMapType(obj_type)) {
            const key_val = try self.genExpr(idx.index);
            const opt_val = try self.genHashMapGet(obj_val, obj_type, key_val);
            const opt_type = c.LLVMTypeOf(opt_val);
            return self.genOptionUnwrap(opt_val, opt_type, null);
        }
        return self.tryIndexOverload(obj_val, obj_type, idx.index);
    }

    return error.UnsupportedExpr;
}

fn genSlice(self: *Codegen, sl: Ast.SliceExpr) Error!c.LLVMValueRef {
    // Slicing an array: arr[start..end] → { ptr_to_element, len }
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const i32_type = c.LLVMInt32TypeInContext(self.context);

    if (sl.expr.kind == .ident) {
        const arr_sym = sl.expr.kind.ident;
        if (self.locals.get(arr_sym)) |local| {
            // Slicing a fixed array.
            if (c.LLVMGetTypeKind(local.ty) == c.LLVMArrayTypeKind) {
                const elem_type = c.LLVMGetElementType(local.ty);
                const arr_len = c.LLVMGetArrayLength2(local.ty);

                const start_val = if (sl.start) |s|
                    self.coerceInt(try self.genExpr(s), i64_type)
                else
                    c.LLVMConstInt(i64_type, 0, 0);

                const end_val = if (sl.end) |e|
                    self.coerceInt(try self.genExpr(e), i64_type)
                else
                    c.LLVMConstInt(i64_type, arr_len, 0);

                // GEP to get pointer to start element.
                const start_i32 = c.LLVMBuildTrunc(self.builder, start_val, i32_type, "");
                const zero = c.LLVMConstInt(i32_type, 0, 0);
                var indices = [_]c.LLVMValueRef{ zero, start_i32 };
                const elem_ptr = c.LLVMBuildGEP2(self.builder, local.ty, local.alloca, &indices, 2, "");

                // Length = end - start.
                const len = c.LLVMBuildSub(self.builder, end_val, start_val, "slice.len");

                // Build slice struct { ptr, len }.
                var body_types = [_]c.LLVMTypeRef{
                    c.LLVMPointerTypeInContext(self.context, 0),
                    i64_type,
                };
                const slice_type = c.LLVMStructTypeInContext(self.context, &body_types, 2, 0);

                var result = c.LLVMGetUndef(slice_type);
                result = c.LLVMBuildInsertValue(self.builder, result, elem_ptr, 0, "");
                result = c.LLVMBuildInsertValue(self.builder, result, len, 1, "");

                // Track element type for later indexing.
                _ = elem_type;
                return result;
            }

            // Slicing a slice.
            if (self.slice_elem_types.get(arr_sym)) |_| {
                const slice_val = c.LLVMBuildLoad2(self.builder, local.ty, local.alloca, "");
                const src_ptr = c.LLVMBuildExtractValue(self.builder, slice_val, 0, "src.ptr");
                const src_len = c.LLVMBuildExtractValue(self.builder, slice_val, 1, "src.len");

                const start_val = if (sl.start) |s|
                    self.coerceInt(try self.genExpr(s), i64_type)
                else
                    c.LLVMConstInt(i64_type, 0, 0);

                const end_val = if (sl.end) |e|
                    self.coerceInt(try self.genExpr(e), i64_type)
                else
                    src_len;

                const elem_type = self.slice_elem_types.get(arr_sym).?;
                var reslice_idx = [_]c.LLVMValueRef{start_val};
                const new_ptr = c.LLVMBuildGEP2(self.builder, elem_type, src_ptr, &reslice_idx, 1, "");
                const new_len = c.LLVMBuildSub(self.builder, end_val, start_val, "slice.len");

                var result = c.LLVMGetUndef(local.ty);
                result = c.LLVMBuildInsertValue(self.builder, result, new_ptr, 0, "");
                result = c.LLVMBuildInsertValue(self.builder, result, new_len, 1, "");
                return result;
            }
        }
    }

    return error.UnsupportedExpr;
}

fn tryIndexOverload(self: *Codegen, obj_val: c.LLVMValueRef, obj_type: c.LLVMTypeRef, index_expr: *const Ast.Expr) Error!c.LLVMValueRef {
    // Look for Type.get(self, index) method.
    var type_name_str: ?[]const u8 = null;
    {
        var it = self.struct_types.iterator();
        while (it.next()) |entry| {
            if (entry.value_ptr.llvm_type == obj_type) {
                type_name_str = self.pool.resolve(entry.key_ptr.*);
                break;
            }
        }
    }
    const tn = type_name_str orelse return error.UnsupportedExpr;

    var name_buf: [512]u8 = undefined;
    const method_name = "get";
    if (tn.len + 1 + method_name.len >= name_buf.len) return error.UnsupportedExpr;
    @memcpy(name_buf[0..tn.len], tn);
    name_buf[tn.len] = '.';
    @memcpy(name_buf[tn.len + 1 ..][0..method_name.len], method_name);
    const mangled = name_buf[0 .. tn.len + 1 + method_name.len];
    const fn_sym = self.pool.intern(mangled) catch return error.CodegenAlloc;

    const fn_info = self.functions.get(fn_sym) orelse return error.UnsupportedExpr;

    const index_val = try self.genExpr(index_expr);
    var args_buf = [_]c.LLVMValueRef{ obj_val, index_val };
    const ret_type = c.LLVMGetReturnType(fn_info.fn_type);
    const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);
    return c.LLVMBuildCall2(
        self.builder,
        fn_info.fn_type,
        fn_info.value,
        &args_buf,
        2,
        if (is_void) "" else "idx",
    );
}

fn genFieldAccess(self: *Codegen, fa: Ast.FieldAccessExpr) Error!c.LLVMValueRef {
    // Fast path: direct local variable access (avoids temp alloca).
    if (fa.expr.kind == .ident) {
        const sym = fa.expr.kind.ident;
        const local = self.locals.get(sym) orelse return error.UnsupportedExpr;

        // Check for array .len first.
        if (c.LLVMGetTypeKind(local.ty) == c.LLVMArrayTypeKind) {
            const field_name = self.pool.resolve(fa.field);
            if (std.mem.eql(u8, field_name, "len")) {
                const len = c.LLVMGetArrayLength2(local.ty);
                return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), len, 0);
            }
            return error.UnsupportedExpr;
        }

        // Check for slice .len (slice is { ptr, i64 } struct).
        if (self.slice_elem_types.get(sym)) |_| {
            const field_name = self.pool.resolve(fa.field);
            if (std.mem.eql(u8, field_name, "len")) {
                const slice_val = c.LLVMBuildLoad2(self.builder, local.ty, local.alloca, "");
                return c.LLVMBuildExtractValue(self.builder, slice_val, 1, "slice.len");
            }
            if (std.mem.eql(u8, field_name, "ptr")) {
                const slice_val = c.LLVMBuildLoad2(self.builder, local.ty, local.alloca, "");
                return c.LLVMBuildExtractValue(self.builder, slice_val, 0, "slice.ptr");
            }
            return error.UnsupportedExpr;
        }

        // Check for tuple field access (.0, .1, etc.)
        if (c.LLVMGetTypeKind(local.ty) == c.LLVMStructTypeKind) {
            const field_name = self.pool.resolve(fa.field);
            if (std.fmt.parseInt(u32, field_name, 10)) |idx| {
                const elem_type = c.LLVMStructGetTypeAtIndex(local.ty, idx);
                const gep = c.LLVMBuildStructGEP2(self.builder, local.ty, local.alloca, idx, "");
                return c.LLVMBuildLoad2(self.builder, elem_type, gep, "tuple.elem");
            } else |_| {}
        }

        // Check for pointer-to-struct field access (e.g. c.current where c: *mut Counter).
        if (local.pointee_struct) |ps| {
            const struct_info = self.struct_types.get(ps) orelse return error.UnsupportedType;
            const idx = self.findFieldIndex(struct_info, fa.field) orelse return error.UnsupportedExpr;
            // Load the pointer value, then GEP into the struct.
            const ptr_val = c.LLVMBuildLoad2(self.builder, local.ty, local.alloca, "ptr");
            const gep = c.LLVMBuildStructGEP2(self.builder, struct_info.llvm_type, ptr_val, @intCast(idx), "");
            return c.LLVMBuildLoad2(self.builder, struct_info.field_types[idx], gep, "ptr.field");
        }

        // Auto-dereference: if local is a pointer (from let r = &p), check ref_pointee_types.
        if (c.LLVMGetTypeKind(local.ty) == c.LLVMPointerTypeKind) {
            if (self.ref_pointee_types.get(sym)) |pointee_ty| {
                if (self.findStructTypeByLlvm(pointee_ty)) |struct_info| {
                    const idx = self.findFieldIndex(struct_info, fa.field) orelse return error.UnsupportedExpr;
                    const ptr_val = c.LLVMBuildLoad2(self.builder, local.ty, local.alloca, "ptr");
                    const gep = c.LLVMBuildStructGEP2(self.builder, pointee_ty, ptr_val, @intCast(idx), "");
                    return c.LLVMBuildLoad2(self.builder, struct_info.field_types[idx], gep, "deref.field");
                }
            }
        }

        // Find which struct type this local is.
        const struct_info = self.findStructTypeByLlvm(local.ty) orelse return error.UnsupportedType;
        const idx = self.findFieldIndex(struct_info, fa.field) orelse return error.UnsupportedExpr;

        const gep = c.LLVMBuildStructGEP2(self.builder, local.ty, local.alloca, @intCast(idx), "");
        return c.LLVMBuildLoad2(self.builder, struct_info.field_types[idx], gep, "field");
    }

    // General path: evaluate inner expression, store to temp, GEP into it.
    const val = try self.genExpr(fa.expr);
    const val_type = c.LLVMTypeOf(val);

    // Check for array .len.
    if (c.LLVMGetTypeKind(val_type) == c.LLVMArrayTypeKind) {
        const field_name = self.pool.resolve(fa.field);
        if (std.mem.eql(u8, field_name, "len")) {
            const len = c.LLVMGetArrayLength2(val_type);
            return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), len, 0);
        }
        return error.UnsupportedExpr;
    }

    // Check for tuple field access (.0, .1, etc.)
    if (c.LLVMGetTypeKind(val_type) == c.LLVMStructTypeKind) {
        const field_name = self.pool.resolve(fa.field);
        if (std.fmt.parseInt(u32, field_name, 10)) |idx| {
            const elem_type = c.LLVMStructGetTypeAtIndex(val_type, idx);
            const tmp = c.LLVMBuildAlloca(self.builder, val_type, "tmp");
            _ = c.LLVMBuildStore(self.builder, val, tmp);
            const gep = c.LLVMBuildStructGEP2(self.builder, val_type, tmp, idx, "");
            return c.LLVMBuildLoad2(self.builder, elem_type, gep, "tuple.elem");
        } else |_| {}
    }

    // Auto-dereference: if val is a pointer, try to find the struct it points to
    // and GEP through the pointer directly.
    if (c.LLVMGetTypeKind(val_type) == c.LLVMPointerTypeKind) {
        // Try to infer the pointee struct type from the expression.
        if (fa.expr.kind == .ident) {
            const sym = fa.expr.kind.ident;
            if (self.ref_pointee_types.get(sym)) |pointee_ty| {
                if (self.findStructTypeByLlvm(pointee_ty)) |struct_info| {
                    const idx = self.findFieldIndex(struct_info, fa.field) orelse return error.UnsupportedExpr;
                    const gep = c.LLVMBuildStructGEP2(self.builder, pointee_ty, val, @intCast(idx), "");
                    return c.LLVMBuildLoad2(self.builder, struct_info.field_types[idx], gep, "deref.field");
                }
            }
        }
    }

    // Must be a struct type.
    const struct_info = self.findStructTypeByLlvm(val_type) orelse return error.UnsupportedType;
    const idx = self.findFieldIndex(struct_info, fa.field) orelse return error.UnsupportedExpr;

    // Store to temp alloca so we can GEP into it.
    const tmp = c.LLVMBuildAlloca(self.builder, val_type, "tmp");
    _ = c.LLVMBuildStore(self.builder, val, tmp);
    const gep = c.LLVMBuildStructGEP2(self.builder, val_type, tmp, @intCast(idx), "");
    return c.LLVMBuildLoad2(self.builder, struct_info.field_types[idx], gep, "field");
}

fn findFieldIndex(self: *const Codegen, info: StructTypeInfo, field_sym: u32) ?usize {
    _ = self;
    for (info.field_names, 0..) |name, i| {
        if (name == field_sym) return i;
    }
    return null;
}

fn findStructTypeByLlvm(self: *const Codegen, llvm_type: c.LLVMTypeRef) ?StructTypeInfo {
    var it = self.struct_types.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == llvm_type) return entry.value_ptr.*;
    }
    return null;
}

// ── Built-in functions ────────────────────────────────────────────

/// Ensure printf is declared as an extern.
fn ensurePrintfDeclared(self: *Codegen) Error!FnInfo {
    const printf_sym = self.pool.intern("printf") catch return error.CodegenAlloc;
    if (self.functions.get(printf_sym)) |info| return info;

    // Declare: extern fn printf(fmt: *const i8, ...) -> i32
    var param_types = [_]c.LLVMTypeRef{c.LLVMPointerTypeInContext(self.context, 0)};
    const fn_type = c.LLVMFunctionType(
        c.LLVMInt32TypeInContext(self.context),
        &param_types,
        1,
        1, // variadic
    );
    const func = c.LLVMAddFunction(self.module, "printf", fn_type);
    const info = FnInfo{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, printf_sym, info) catch return error.CodegenAlloc;
    return info;
}

/// Ensure abort() is declared as an extern.
fn ensureAbortDeclared(self: *Codegen) Error!FnInfo {
    const abort_sym = self.pool.intern("abort") catch return error.CodegenAlloc;
    if (self.functions.get(abort_sym)) |info| return info;

    const fn_type = c.LLVMFunctionType(c.LLVMVoidTypeInContext(self.context), null, 0, 0);
    const func = c.LLVMAddFunction(self.module, "abort", fn_type);
    const info = FnInfo{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, abort_sym, info) catch return error.CodegenAlloc;
    return info;
}

/// Ensure write() is declared as an extern (unbuffered I/O for panic messages).
fn ensureWriteDeclared(self: *Codegen) Error!FnInfo {
    const write_sym = self.pool.intern("write") catch return error.CodegenAlloc;
    if (self.functions.get(write_sym)) |info| return info;

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    var param_types = [_]c.LLVMTypeRef{ i32_type, ptr_type, i32_type };
    const fn_type = c.LLVMFunctionType(i32_type, &param_types, 3, 0);
    const func = c.LLVMAddFunction(self.module, "write", fn_type);
    const info = FnInfo{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, write_sym, info) catch return error.CodegenAlloc;
    return info;
}

/// Ensure _exit() is declared as an extern (immediate process termination).
fn ensureExitDeclared(self: *Codegen) Error!FnInfo {
    const exit_sym = self.pool.intern("_exit") catch return error.CodegenAlloc;
    if (self.functions.get(exit_sym)) |info| return info;

    var param_types = [_]c.LLVMTypeRef{c.LLVMInt32TypeInContext(self.context)};
    const fn_type = c.LLVMFunctionType(c.LLVMVoidTypeInContext(self.context), &param_types, 1, 0);
    const func = c.LLVMAddFunction(self.module, "_exit", fn_type);
    const info = FnInfo{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, exit_sym, info) catch return error.CodegenAlloc;
    return info;
}

/// Emit an implicit unreachable panic that reports source file and line.
fn emitImplicitUnreachablePanic(self: *Codegen, span: @import("Span.zig")) Error!void {
    const write_info = try self.ensureWriteDeclared();
    const exit_info = try self.ensureExitDeclared();
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const line = self.spanToLine(span);
    var msg_buf: [1200]u8 = undefined;
    const panic_msg: [:0]const u8 = std.fmt.bufPrintZ(
        &msg_buf,
        "entered implicit unreachable code at {s}:{d}\n",
        .{ self.source_file, line },
    ) catch "entered implicit unreachable code\n";
    const msg_ptr = c.LLVMBuildGlobalStringPtr(self.builder, panic_msg, "implicit.unreachable.msg");
    var write_args = [_]c.LLVMValueRef{
        c.LLVMConstInt(i32_type, 2, 0), // stderr fd
        msg_ptr,
        c.LLVMConstInt(i32_type, @intCast(panic_msg.len), 0),
    };
    _ = c.LLVMBuildCall2(self.builder, write_info.fn_type, write_info.value, &write_args, 3, "");

    var exit_args = [_]c.LLVMValueRef{c.LLVMConstInt(i32_type, 134, 0)};
    _ = c.LLVMBuildCall2(self.builder, exit_info.fn_type, exit_info.value, &exit_args, 1, "");
    _ = c.LLVMBuildUnreachable(self.builder);
}

/// Declare or look up a C library function by name.
fn getOrDeclareCFn(
    self: *Codegen,
    name: [*:0]const u8,
    param_types: []const c.LLVMTypeRef,
    ret_type: c.LLVMTypeRef,
    is_variadic: bool,
) FnInfo {
    // Check if already declared in the LLVM module.
    const existing = c.LLVMGetNamedFunction(self.module, name);
    if (existing) |func| {
        const fn_type = c.LLVMGlobalGetValueType(func);
        return .{ .value = func, .fn_type = fn_type };
    }
    const fn_type = c.LLVMFunctionType(
        ret_type,
        @constCast(param_types.ptr),
        @intCast(param_types.len),
        if (is_variadic) 1 else 0,
    );
    const func = c.LLVMAddFunction(self.module, name, fn_type);
    return .{ .value = func, .fn_type = fn_type };
}

/// Format specifier for an LLVM type.
fn formatSpecForType(self: *Codegen, val: c.LLVMValueRef) []const u8 {
    const ty = c.LLVMTypeOf(val);
    const kind = c.LLVMGetTypeKind(ty);

    if (kind == c.LLVMIntegerTypeKind) {
        const width = c.LLVMGetIntTypeWidth(ty);
        if (width == 1) return "%s"; // bool — will be converted to "true"/"false"
        if (width <= 32) return "%d";
        return "%lld";
    }
    if (kind == c.LLVMFloatTypeKind or kind == c.LLVMDoubleTypeKind) {
        return "%g";
    }
    if (kind == c.LLVMPointerTypeKind) {
        return "%s";
    }
    // Check if it's the str struct type
    if (self.isStrType(ty)) {
        return "%s";
    }
    return "%d"; // fallback
}

/// Generate a printf call for a single value (used by print/println).
fn genPrintValue(self: *Codegen, val: c.LLVMValueRef, printf_info: FnInfo) Error!void {
    const ty = c.LLVMTypeOf(val);
    const kind = c.LLVMGetTypeKind(ty);

    var print_val = val;
    var fmt: []const u8 = "%d";

    if (self.isStrType(ty)) {
        // str struct → extract .ptr field
        print_val = self.extractStrPtr(val);
        fmt = "%s";
    } else if (kind == c.LLVMPointerTypeKind) {
        fmt = "%s";
    } else if (kind == c.LLVMIntegerTypeKind) {
        const width = c.LLVMGetIntTypeWidth(ty);
        if (width == 1) {
            // Bool: select "true" or "false"
            const true_str = c.LLVMBuildGlobalStringPtr(self.builder, "true", "");
            const false_str = c.LLVMBuildGlobalStringPtr(self.builder, "false", "");
            print_val = c.LLVMBuildSelect(self.builder, val, true_str, false_str, "boolstr");
            fmt = "%s";
        } else if (width <= 32) {
            fmt = "%d";
        } else {
            fmt = "%lld";
        }
    } else if (kind == c.LLVMFloatTypeKind or kind == c.LLVMDoubleTypeKind) {
        // Promote float to double for printf
        if (kind == c.LLVMFloatTypeKind) {
            print_val = c.LLVMBuildFPExt(self.builder, val, c.LLVMDoubleTypeInContext(self.context), "");
        }
        fmt = "%g";
    } else if (kind == c.LLVMStructTypeKind) {
        // Check for Display trait: Type.display(self) -> str or Type.to_string(self) -> str
        if (self.findTypeSymbol(ty)) |type_sym| {
            if (self.findDisplayMethod(type_sym)) |display_fn| {
                // Call Type.display(val) → get str result, print it.
                var call_args = [_]c.LLVMValueRef{val};
                const result = c.LLVMBuildCall2(
                    self.builder,
                    display_fn.fn_type,
                    display_fn.value,
                    &call_args,
                    1,
                    "display",
                );
                const result_type = c.LLVMTypeOf(result);
                if (self.isStrType(result_type)) {
                    const str_ptr = self.extractStrPtr(result);
                    const s_fmt = c.LLVMBuildGlobalStringPtr(self.builder, "%s", "fmt");
                    var s_args = [_]c.LLVMValueRef{ s_fmt, str_ptr };
                    _ = c.LLVMBuildCall2(self.builder, printf_info.fn_type, printf_info.value, &s_args, 2, "");
                } else {
                    // Non-str return — print the result value.
                    try self.genPrintValue(result, printf_info);
                }
                return;
            }
        }
        // Default: print struct fields.
        try self.genPrintStruct(val, ty, printf_info);
        return;
    }

    const fmt_str = c.LLVMBuildGlobalStringPtr(self.builder, @ptrCast(fmt.ptr), "fmt");
    var args = [_]c.LLVMValueRef{ fmt_str, print_val };
    _ = c.LLVMBuildCall2(self.builder, printf_info.fn_type, printf_info.value, &args, 2, "");
}

fn genPrintStruct(self: *Codegen, val: c.LLVMValueRef, ty: c.LLVMTypeRef, printf_info: FnInfo) Error!void {
    // Find the struct type info and its name.
    var struct_info: ?StructTypeInfo = null;
    var type_name_sym: u32 = 0;
    {
        var it = self.struct_types.iterator();
        while (it.next()) |entry| {
            if (entry.value_ptr.llvm_type == ty) {
                struct_info = entry.value_ptr.*;
                type_name_sym = entry.key_ptr.*;
                break;
            }
        }
    }

    // Store val to temp alloca for GEP access.
    const alloca = c.LLVMBuildAlloca(self.builder, ty, "print.tmp");
    _ = c.LLVMBuildStore(self.builder, val, alloca);

    if (struct_info) |si| {
        // Print "TypeName { "
        const name_str = self.pool.resolve(type_name_sym);
        var open_buf: [256]u8 = undefined;
        const open_len = @min(name_str.len, 240);
        @memcpy(open_buf[0..open_len], name_str[0..open_len]);
        @memcpy(open_buf[open_len..][0..3], " { ");
        open_buf[open_len + 3] = 0;
        const open_z: [*:0]const u8 = @ptrCast(open_buf[0 .. open_len + 3 :0]);
        const open_global = c.LLVMBuildGlobalStringPtr(self.builder, open_z, "");
        var open_args = [_]c.LLVMValueRef{open_global};
        _ = c.LLVMBuildCall2(self.builder, printf_info.fn_type, printf_info.value, &open_args, 1, "");

        // Print each field.
        for (si.field_names, 0..) |field_sym, i| {
            if (i > 0) {
                const comma_str = c.LLVMBuildGlobalStringPtr(self.builder, ", ", "");
                var comma_args = [_]c.LLVMValueRef{comma_str};
                _ = c.LLVMBuildCall2(self.builder, printf_info.fn_type, printf_info.value, &comma_args, 1, "");
            }

            // Print "field_name: "
            const field_name = self.pool.resolve(field_sym);
            var label_buf: [256]u8 = undefined;
            const fl = @min(field_name.len, 250);
            @memcpy(label_buf[0..fl], field_name[0..fl]);
            @memcpy(label_buf[fl..][0..2], ": ");
            label_buf[fl + 2] = 0;
            const label_z: [*:0]const u8 = @ptrCast(label_buf[0 .. fl + 2 :0]);
            const label_global = c.LLVMBuildGlobalStringPtr(self.builder, label_z, "");
            var label_args = [_]c.LLVMValueRef{label_global};
            _ = c.LLVMBuildCall2(self.builder, printf_info.fn_type, printf_info.value, &label_args, 1, "");

            // Get field value and print it.
            const idx: u32 = @intCast(i);
            const gep = c.LLVMBuildStructGEP2(self.builder, ty, alloca, idx, "");
            const field_val = c.LLVMBuildLoad2(self.builder, si.field_types[i], gep, "");
            try self.genPrintValue(field_val, printf_info);
        }

        // Print " }"
        const close_str = c.LLVMBuildGlobalStringPtr(self.builder, " }", "");
        var close_args = [_]c.LLVMValueRef{close_str};
        _ = c.LLVMBuildCall2(self.builder, printf_info.fn_type, printf_info.value, &close_args, 1, "");
    } else {
        // Check if it's an enum type.
        var enum_info: ?EnumTypeInfo = null;
        var enum_sym: u32 = 0;
        {
            var eit = self.enum_types.iterator();
            while (eit.next()) |entry| {
                if (entry.value_ptr.llvm_type == ty) {
                    enum_info = entry.value_ptr.*;
                    enum_sym = entry.key_ptr.*;
                    break;
                }
            }
        }
        if (enum_info) |ei| {
            try self.genPrintEnum(val, ty, alloca, ei, enum_sym, printf_info);
        } else {
            // Unknown struct, just print "<struct>"
            const unknown_str = c.LLVMBuildGlobalStringPtr(self.builder, "<struct>", "");
            var unknown_args = [_]c.LLVMValueRef{unknown_str};
            _ = c.LLVMBuildCall2(self.builder, printf_info.fn_type, printf_info.value, &unknown_args, 1, "");
        }
    }
}

fn genPrintSimpleEnum(self: *Codegen, tag_val: c.LLVMValueRef, ei: EnumTypeInfo, printf_info: FnInfo) Error!void {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const function = self.current_function;
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "print.merge");

    const num_variants = ei.variant_names.len;
    const switch_inst = c.LLVMBuildSwitch(self.builder, tag_val, merge_bb, @intCast(num_variants));

    for (ei.variant_names, 0..) |variant_sym, i| {
        const variant_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "print.v");
        c.LLVMAddCase(switch_inst, c.LLVMConstInt(i32_type, @intCast(i), 0), variant_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, variant_bb);

        const variant_name = self.pool.resolve(variant_sym);
        var name_buf: [256]u8 = undefined;
        const nl = @min(variant_name.len, 254);
        @memcpy(name_buf[0..nl], variant_name[0..nl]);
        name_buf[nl] = 0;
        const name_z: [*:0]const u8 = @ptrCast(name_buf[0..nl :0]);
        const fmt_str = c.LLVMBuildGlobalStringPtr(self.builder, "%s", "");
        const name_global = c.LLVMBuildGlobalStringPtr(self.builder, name_z, "");
        var print_args = [_]c.LLVMValueRef{ fmt_str, name_global };
        _ = c.LLVMBuildCall2(self.builder, printf_info.fn_type, printf_info.value, &print_args, 2, "");

        _ = c.LLVMBuildBr(self.builder, merge_bb);
    }

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
}

fn genPrintEnum(
    self: *Codegen,
    val: c.LLVMValueRef,
    ty: c.LLVMTypeRef,
    alloca: c.LLVMValueRef,
    ei: EnumTypeInfo,
    enum_sym: u32,
    printf_info: FnInfo,
) Error!void {
    _ = enum_sym;
    const i32_type = c.LLVMInt32TypeInContext(self.context);

    // Extract tag from the enum struct.
    const tag_gep = c.LLVMBuildStructGEP2(self.builder, ty, alloca, 0, "");
    const tag_val = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "tag");

    // Build a switch that prints the appropriate variant name.
    const function = self.current_function;
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "print.merge");

    // Create BBs for each variant.
    const num_variants = ei.variant_names.len;
    const switch_inst = c.LLVMBuildSwitch(self.builder, tag_val, merge_bb, @intCast(num_variants));

    for (ei.variant_names, 0..) |variant_sym, i| {
        const variant_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "print.variant");
        c.LLVMAddCase(switch_inst, c.LLVMConstInt(i32_type, @intCast(i), 0), variant_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, variant_bb);

        const variant_name = self.pool.resolve(variant_sym);

        if (ei.variant_payload_types[i]) |payload_type| {
            // Variant with payload: print "VariantName(payload)"
            var name_buf: [256]u8 = undefined;
            const nl = @min(variant_name.len, 250);
            @memcpy(name_buf[0..nl], variant_name[0..nl]);
            name_buf[nl] = '(';
            name_buf[nl + 1] = 0;
            const name_z: [*:0]const u8 = @ptrCast(name_buf[0 .. nl + 1 :0]);
            const name_global = c.LLVMBuildGlobalStringPtr(self.builder, name_z, "");
            var name_args = [_]c.LLVMValueRef{name_global};
            _ = c.LLVMBuildCall2(self.builder, printf_info.fn_type, printf_info.value, &name_args, 1, "");

            // Extract payload: GEP into field 1 (payload bytes), bitcast to payload type.
            const payload_gep = c.LLVMBuildStructGEP2(self.builder, ty, alloca, 1, "");
            const payload_val = c.LLVMBuildLoad2(self.builder, payload_type, payload_gep, "payload");
            try self.genPrintValue(payload_val, printf_info);

            const close_str = c.LLVMBuildGlobalStringPtr(self.builder, ")", "");
            var close_args = [_]c.LLVMValueRef{close_str};
            _ = c.LLVMBuildCall2(self.builder, printf_info.fn_type, printf_info.value, &close_args, 1, "");
        } else {
            // Unit variant: just print "VariantName"
            var name_buf: [256]u8 = undefined;
            const nl = @min(variant_name.len, 254);
            @memcpy(name_buf[0..nl], variant_name[0..nl]);
            name_buf[nl] = 0;
            const name_z: [*:0]const u8 = @ptrCast(name_buf[0..nl :0]);
            const name_global = c.LLVMBuildGlobalStringPtr(self.builder, name_z, "");
            var name_args = [_]c.LLVMValueRef{name_global};
            _ = c.LLVMBuildCall2(self.builder, printf_info.fn_type, printf_info.value, &name_args, 1, "");
        }

        _ = c.LLVMBuildBr(self.builder, merge_bb);
    }

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    _ = val; // val was already stored to alloca
}

/// Generate a print/println call with string interpolation support.
/// If a single string literal arg contains `{expr}` patterns, builds a printf format string.
fn genPrintlnOrPrint(self: *Codegen, args: []const *const Ast.Expr, add_newline: bool) Error!c.LLVMValueRef {
    const printf_info = try self.ensurePrintfDeclared();

    if (args.len == 0) {
        if (add_newline) {
            const nl = c.LLVMBuildGlobalStringPtr(self.builder, "\n", "nl");
            var nl_args = [_]c.LLVMValueRef{nl};
            _ = c.LLVMBuildCall2(self.builder, printf_info.fn_type, printf_info.value, &nl_args, 1, "");
        }
        return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
    }

    // Check if the first arg is a string literal with interpolation.
    if (args.len == 1 and args[0].kind == .string_literal) {
        const text = self.pool.resolve(args[0].kind.string_literal);
        if (std.mem.indexOfScalar(u8, text, '{') != null) {
            // String interpolation: parse "{expr}" patterns.
            return self.genInterpolatedPrint(text, printf_info, add_newline);
        }
    }

    // Non-interpolated: print each arg.
    for (args) |arg| {
        const val = try self.genExpr(arg);
        // Check if arg is an enum-typed local.
        const printed_enum = blk: {
            if (arg.kind == .ident) {
                if (self.enum_local_types.get(arg.kind.ident)) |enum_sym| {
                    if (self.enum_types.get(enum_sym)) |ei| {
                        if (c.LLVMGetTypeKind(ei.llvm_type) == c.LLVMStructTypeKind) {
                            // Payload enum — use genPrintStruct path (already handles it).
                            break :blk false;
                        } else {
                            // Simple enum (i32) — print variant name.
                            try self.genPrintSimpleEnum(val, ei, printf_info);
                            break :blk true;
                        }
                    }
                }
            }
            break :blk false;
        };
        if (!printed_enum) {
            try self.genPrintValue(val, printf_info);
        }
    }
    if (add_newline) {
        const nl = c.LLVMBuildGlobalStringPtr(self.builder, "\n", "nl");
        var nl_args = [_]c.LLVMValueRef{nl};
        _ = c.LLVMBuildCall2(self.builder, printf_info.fn_type, printf_info.value, &nl_args, 1, "");
    }

    return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
}

/// Built-in: println(args...) — print with trailing newline.
fn genPrintln(self: *Codegen, args: []const *const Ast.Expr) Error!c.LLVMValueRef {
    return self.genPrintlnOrPrint(args, true);
}

/// Built-in: print(args...) — print without trailing newline.
fn genPrint(self: *Codegen, args: []const *const Ast.Expr) Error!c.LLVMValueRef {
    return self.genPrintlnOrPrint(args, false);
}

/// Handle string interpolation: "text {expr} more {expr2}" → printf("text %d more %s\n", expr, expr2)
fn genInterpolatedPrint(
    self: *Codegen,
    text: []const u8,
    printf_info: FnInfo,
    add_newline: bool,
) Error!c.LLVMValueRef {
    // Phase 1: Parse the string into literal segments and expression names.
    // Collect expression values and build format string.
    var fmt_buf: [4096]u8 = undefined;
    var fmt_len: usize = 0;
    var expr_vals: [32]c.LLVMValueRef = undefined;
    var expr_count: usize = 0;

    var i: usize = 0;
    while (i < text.len) {
        if (text[i] == '\\' and i + 1 < text.len) {
            // Escape sequence
            i += 1;
            switch (text[i]) {
                'n' => {
                    fmt_buf[fmt_len] = '\n';
                    fmt_len += 1;
                },
                't' => {
                    fmt_buf[fmt_len] = '\t';
                    fmt_len += 1;
                },
                'r' => {
                    fmt_buf[fmt_len] = '\r';
                    fmt_len += 1;
                },
                '\\' => {
                    fmt_buf[fmt_len] = '\\';
                    fmt_len += 1;
                },
                '"' => {
                    fmt_buf[fmt_len] = '"';
                    fmt_len += 1;
                },
                '{' => {
                    fmt_buf[fmt_len] = '{';
                    fmt_len += 1;
                },
                else => {
                    fmt_buf[fmt_len] = text[i];
                    fmt_len += 1;
                },
            }
            i += 1;
        } else if (text[i] == '{') {
            // Start of interpolation expression
            i += 1;
            const expr_start = i;
            var brace_depth: u32 = 1;
            // Find matching close brace, handling format specifiers after ':'
            var format_spec_start: ?usize = null;
            while (i < text.len and brace_depth > 0) {
                if (text[i] == '{') brace_depth += 1;
                if (text[i] == '}') brace_depth -= 1;
                if (text[i] == ':' and brace_depth == 1 and format_spec_start == null) {
                    format_spec_start = i;
                }
                if (brace_depth > 0) i += 1;
            }
            if (brace_depth == 0) {
                const expr_end = if (format_spec_start) |fs| fs else i;
                const expr_text = text[expr_start..expr_end];
                // Try to resolve the expression. For now: simple identifiers and field access.
                if (try self.resolveInterpExpr(expr_text)) |val| {
                    // Check for :? debug format specifier.
                    if (format_spec_start) |fs| {
                        const spec_text = text[fs + 1 .. i];
                        if (std.mem.eql(u8, spec_text, "?")) {
                            // Call .debug() method on the value.
                            const ty2 = c.LLVMTypeOf(val);
                            if (c.LLVMGetTypeKind(ty2) == c.LLVMStructTypeKind) {
                                if (self.findTypeSymbol(ty2)) |type_sym| {
                                    if (self.findDebugMethod(type_sym)) |debug_fn| {
                                        var debug_args = [_]c.LLVMValueRef{val};
                                        const debug_result = c.LLVMBuildCall2(
                                            self.builder,
                                            debug_fn.fn_type,
                                            debug_fn.value,
                                            &debug_args,
                                            1,
                                            "debug",
                                        );
                                        // debug() returns str — extract ptr.
                                        if (self.isStrType(c.LLVMTypeOf(debug_result))) {
                                            expr_vals[expr_count] = self.extractStrPtr(debug_result);
                                        } else {
                                            expr_vals[expr_count] = debug_result;
                                        }
                                        const spec = "%s";
                                        @memcpy(fmt_buf[fmt_len..][0..spec.len], spec);
                                        fmt_len += spec.len;
                                        expr_count += 1;
                                        i += 1;
                                        continue;
                                    }
                                }
                            }
                            // Fallthrough: no debug method, use default formatting.
                        }
                    }

                    // Determine format specifier based on type
                    const ty = c.LLVMTypeOf(val);
                    const kind = c.LLVMGetTypeKind(ty);

                    if (self.isStrType(ty)) {
                        // Extract ptr from str struct
                        expr_vals[expr_count] = self.extractStrPtr(val);
                        const spec = "%s";
                        @memcpy(fmt_buf[fmt_len..][0..spec.len], spec);
                        fmt_len += spec.len;
                    } else if (kind == c.LLVMPointerTypeKind) {
                        expr_vals[expr_count] = val;
                        const spec = "%s";
                        @memcpy(fmt_buf[fmt_len..][0..spec.len], spec);
                        fmt_len += spec.len;
                    } else if (kind == c.LLVMIntegerTypeKind) {
                        const width = c.LLVMGetIntTypeWidth(ty);
                        if (width == 1) {
                            // Bool: select "true"/"false"
                            const true_s = c.LLVMBuildGlobalStringPtr(self.builder, "true", "");
                            const false_s = c.LLVMBuildGlobalStringPtr(self.builder, "false", "");
                            expr_vals[expr_count] = c.LLVMBuildSelect(self.builder, val, true_s, false_s, "");
                            const spec = "%s";
                            @memcpy(fmt_buf[fmt_len..][0..spec.len], spec);
                            fmt_len += spec.len;
                        } else if (width <= 32) {
                            expr_vals[expr_count] = val;
                            const spec = "%d";
                            @memcpy(fmt_buf[fmt_len..][0..spec.len], spec);
                            fmt_len += spec.len;
                        } else {
                            expr_vals[expr_count] = val;
                            const spec = "%lld";
                            @memcpy(fmt_buf[fmt_len..][0..spec.len], spec);
                            fmt_len += spec.len;
                        }
                    } else if (kind == c.LLVMFloatTypeKind or kind == c.LLVMDoubleTypeKind) {
                        // Check for format specifier like .2 or .1
                        if (format_spec_start) |fs| {
                            const spec_text = text[fs + 1 .. i]; // e.g., ".2" or ".1"
                            // Build format spec: "%.<n>f"
                            fmt_buf[fmt_len] = '%';
                            fmt_len += 1;
                            @memcpy(fmt_buf[fmt_len..][0..spec_text.len], spec_text);
                            fmt_len += spec_text.len;
                            fmt_buf[fmt_len] = 'f';
                            fmt_len += 1;
                        } else {
                            const spec = "%g";
                            @memcpy(fmt_buf[fmt_len..][0..spec.len], spec);
                            fmt_len += spec.len;
                        }
                        // Promote float to double for printf
                        if (kind == c.LLVMFloatTypeKind) {
                            expr_vals[expr_count] = c.LLVMBuildFPExt(self.builder, val, c.LLVMDoubleTypeInContext(self.context), "");
                        } else {
                            expr_vals[expr_count] = val;
                        }
                    } else {
                        expr_vals[expr_count] = val;
                        const spec = "%d";
                        @memcpy(fmt_buf[fmt_len..][0..spec.len], spec);
                        fmt_len += spec.len;
                    }
                    expr_count += 1;
                } else {
                    // Couldn't resolve expression, print it literally
                    fmt_buf[fmt_len] = '{';
                    fmt_len += 1;
                    @memcpy(fmt_buf[fmt_len..][0..expr_text.len], expr_text);
                    fmt_len += expr_text.len;
                    fmt_buf[fmt_len] = '}';
                    fmt_len += 1;
                }
                i += 1; // skip closing }
            }
        } else {
            // Literal character - escape % for printf
            if (text[i] == '%') {
                fmt_buf[fmt_len] = '%';
                fmt_len += 1;
                fmt_buf[fmt_len] = '%';
                fmt_len += 1;
            } else {
                fmt_buf[fmt_len] = text[i];
                fmt_len += 1;
            }
            i += 1;
        }
    }

    if (add_newline) {
        fmt_buf[fmt_len] = '\n';
        fmt_len += 1;
    }
    fmt_buf[fmt_len] = 0;

    // Build the printf call with format string + expressions.
    const fmt_str = c.LLVMBuildGlobalStringPtr(self.builder, @ptrCast(fmt_buf[0..fmt_len :0]), "fmt");
    var call_args: [34]c.LLVMValueRef = undefined;
    call_args[0] = fmt_str;
    for (0..expr_count) |j| {
        call_args[j + 1] = expr_vals[j];
    }
    _ = c.LLVMBuildCall2(
        self.builder,
        printf_info.fn_type,
        printf_info.value,
        &call_args,
        @intCast(expr_count + 1),
        "",
    );

    return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
}

/// Resolve an interpolation expression used in print/println strings.
/// Supports identifiers, field paths, literals, grouping, and numeric +/-/*//%.
fn resolveInterpExpr(self: *Codegen, expr_text: []const u8) Error!?c.LLVMValueRef {
    const trimmed = std.mem.trim(u8, expr_text, " \t\r\n");
    if (trimmed.len == 0) return null;

    var pos: usize = 0;
    const val = try self.parseInterpAddSub(trimmed, &pos);
    if (val == null) return null;
    self.skipInterpWs(trimmed, &pos);
    if (pos != trimmed.len) return null;
    return val;
}

fn skipInterpWs(_: *Codegen, text: []const u8, pos: *usize) void {
    while (pos.* < text.len) : (pos.* += 1) {
        const ch = text[pos.*];
        if (ch != ' ' and ch != '\t' and ch != '\r' and ch != '\n') break;
    }
}

fn isInterpIdentStart(ch: u8) bool {
    return std.ascii.isAlphabetic(ch) or ch == '_';
}

fn isInterpIdentContinue(ch: u8) bool {
    return std.ascii.isAlphanumeric(ch) or ch == '_';
}

fn parseInterpAddSub(self: *Codegen, text: []const u8, pos: *usize) Error!?c.LLVMValueRef {
    var lhs = try self.parseInterpMulDiv(text, pos);
    if (lhs == null) return null;

    while (true) {
        self.skipInterpWs(text, pos);
        if (pos.* >= text.len) break;
        const op = text[pos.*];
        if (op != '+' and op != '-') break;
        pos.* += 1;

        const rhs = try self.parseInterpMulDiv(text, pos);
        if (rhs == null) return null;
        lhs = try self.buildInterpBinary(lhs.?, rhs.?, op);
    }

    return lhs;
}

fn parseInterpMulDiv(self: *Codegen, text: []const u8, pos: *usize) Error!?c.LLVMValueRef {
    var lhs = try self.parseInterpUnary(text, pos);
    if (lhs == null) return null;

    while (true) {
        self.skipInterpWs(text, pos);
        if (pos.* >= text.len) break;
        const op = text[pos.*];
        if (op != '*' and op != '/' and op != '%') break;
        pos.* += 1;

        const rhs = try self.parseInterpUnary(text, pos);
        if (rhs == null) return null;
        lhs = try self.buildInterpBinary(lhs.?, rhs.?, op);
    }

    return lhs;
}

fn parseInterpUnary(self: *Codegen, text: []const u8, pos: *usize) Error!?c.LLVMValueRef {
    self.skipInterpWs(text, pos);
    if (pos.* >= text.len) return null;

    const op = text[pos.*];
    if (op == '+' or op == '-') {
        pos.* += 1;
        const inner = try self.parseInterpUnary(text, pos);
        if (inner == null) return null;
        if (op == '+') return inner;

        const ty = c.LLVMTypeOf(inner.?);
        return switch (c.LLVMGetTypeKind(ty)) {
            c.LLVMIntegerTypeKind => c.LLVMBuildNeg(self.builder, inner.?, "interp.neg"),
            c.LLVMFloatTypeKind, c.LLVMDoubleTypeKind => c.LLVMBuildFNeg(self.builder, inner.?, "interp.fneg"),
            else => null,
        };
    }

    return self.parseInterpPrimary(text, pos);
}

fn parseInterpPrimary(self: *Codegen, text: []const u8, pos: *usize) Error!?c.LLVMValueRef {
    self.skipInterpWs(text, pos);
    if (pos.* >= text.len) return null;

    const ch = text[pos.*];

    if (ch == '(') {
        pos.* += 1;
        const inner = try self.parseInterpAddSub(text, pos);
        if (inner == null) return null;
        self.skipInterpWs(text, pos);
        if (pos.* >= text.len or text[pos.*] != ')') return null;
        pos.* += 1;
        return inner;
    }

    if (std.ascii.isDigit(ch)) {
        const start = pos.*;
        while (pos.* < text.len and std.ascii.isDigit(text[pos.*])) : (pos.* += 1) {}

        var is_float = false;
        if (pos.* < text.len and text[pos.*] == '.') {
            if (pos.* + 1 < text.len and std.ascii.isDigit(text[pos.* + 1])) {
                is_float = true;
                pos.* += 1;
                while (pos.* < text.len and std.ascii.isDigit(text[pos.*])) : (pos.* += 1) {}
            }
        }

        const lit = text[start..pos.*];
        if (is_float) {
            const val = std.fmt.parseFloat(f64, lit) catch return null;
            return c.LLVMConstReal(c.LLVMDoubleTypeInContext(self.context), val);
        }
        const val = std.fmt.parseInt(i64, lit, 0) catch return null;
        return c.LLVMConstInt(c.LLVMInt64TypeInContext(self.context), @bitCast(val), 1);
    }

    if (isInterpIdentStart(ch)) {
        const start = pos.*;
        pos.* += 1;
        while (pos.* < text.len and isInterpIdentContinue(text[pos.*])) : (pos.* += 1) {}
        while (pos.* < text.len and text[pos.*] == '.') {
            const dot = pos.*;
            pos.* += 1;
            if (pos.* >= text.len or !isInterpIdentStart(text[pos.*])) {
                pos.* = dot;
                break;
            }
            pos.* += 1;
            while (pos.* < text.len and isInterpIdentContinue(text[pos.*])) : (pos.* += 1) {}
        }
        return self.resolveInterpPath(text[start..pos.*]);
    }

    return null;
}

fn buildInterpBinary(self: *Codegen, lhs: c.LLVMValueRef, rhs: c.LLVMValueRef, op: u8) Error!?c.LLVMValueRef {
    const lhs_kind = c.LLVMGetTypeKind(c.LLVMTypeOf(lhs));
    const rhs_kind = c.LLVMGetTypeKind(c.LLVMTypeOf(rhs));
    const lhs_numeric = lhs_kind == c.LLVMIntegerTypeKind or lhs_kind == c.LLVMFloatTypeKind or lhs_kind == c.LLVMDoubleTypeKind;
    const rhs_numeric = rhs_kind == c.LLVMIntegerTypeKind or rhs_kind == c.LLVMFloatTypeKind or rhs_kind == c.LLVMDoubleTypeKind;
    if (!lhs_numeric or !rhs_numeric) return null;

    const lhs_c, const rhs_c = self.coerceBinaryOperands(lhs, rhs);
    const kind = c.LLVMGetTypeKind(c.LLVMTypeOf(lhs_c));
    const is_float = kind == c.LLVMFloatTypeKind or kind == c.LLVMDoubleTypeKind;

    if (is_float) {
        return switch (op) {
            '+' => c.LLVMBuildFAdd(self.builder, lhs_c, rhs_c, "interp.fadd"),
            '-' => c.LLVMBuildFSub(self.builder, lhs_c, rhs_c, "interp.fsub"),
            '*' => c.LLVMBuildFMul(self.builder, lhs_c, rhs_c, "interp.fmul"),
            '/' => c.LLVMBuildFDiv(self.builder, lhs_c, rhs_c, "interp.fdiv"),
            '%' => c.LLVMBuildFRem(self.builder, lhs_c, rhs_c, "interp.fmod"),
            else => null,
        };
    }

    return switch (op) {
        '+' => c.LLVMBuildAdd(self.builder, lhs_c, rhs_c, "interp.add"),
        '-' => c.LLVMBuildSub(self.builder, lhs_c, rhs_c, "interp.sub"),
        '*' => c.LLVMBuildMul(self.builder, lhs_c, rhs_c, "interp.mul"),
        '/' => c.LLVMBuildSDiv(self.builder, lhs_c, rhs_c, "interp.div"),
        '%' => c.LLVMBuildSRem(self.builder, lhs_c, rhs_c, "interp.mod"),
        else => null,
    };
}

fn resolveInterpPath(self: *Codegen, path_text: []const u8) Error!?c.LLVMValueRef {
    const path = std.mem.trim(u8, path_text, " \t\r\n");
    if (path.len == 0) return null;

    const first_dot = std.mem.indexOfScalar(u8, path, '.') orelse path.len;
    const base_name = path[0..first_dot];
    const base_sym = self.pool.intern(base_name) catch return error.CodegenAlloc;
    const local_info = self.locals.get(base_sym) orelse return null;
    var val = c.LLVMBuildLoad2(self.builder, local_info.ty, local_info.alloca, "");

    var cursor = first_dot;
    while (cursor < path.len) {
        if (path[cursor] != '.') return null;
        cursor += 1;
        if (cursor >= path.len) return null;

        const seg_start = cursor;
        while (cursor < path.len and path[cursor] != '.') : (cursor += 1) {}
        const segment = path[seg_start..cursor];
        if (segment.len == 0) return null;
        const seg_sym = self.pool.intern(segment) catch return error.CodegenAlloc;

        const val_type = c.LLVMTypeOf(val);
        if (segment.len == 3 and std.mem.eql(u8, segment, "len")) {
            if (c.LLVMGetTypeKind(val_type) == c.LLVMArrayTypeKind) {
                const len = c.LLVMGetArrayLength2(val_type);
                val = c.LLVMConstInt(c.LLVMInt64TypeInContext(self.context), len, 0);
                continue;
            }
            if (self.isStrType(val_type)) {
                const str_info = self.findStructTypeByLlvm(val_type) orelse return null;
                const idx = self.findFieldIndex(str_info, seg_sym) orelse return null;
                const tmp = c.LLVMBuildAlloca(self.builder, val_type, "");
                _ = c.LLVMBuildStore(self.builder, val, tmp);
                const gep = c.LLVMBuildStructGEP2(self.builder, val_type, tmp, @intCast(idx), "");
                val = c.LLVMBuildLoad2(self.builder, str_info.field_types[idx], gep, "");
                continue;
            }
        }

        const struct_info = self.findStructTypeByLlvm(val_type) orelse return null;
        const field_idx = self.findFieldIndex(struct_info, seg_sym) orelse return null;
        const tmp = c.LLVMBuildAlloca(self.builder, val_type, "");
        _ = c.LLVMBuildStore(self.builder, val, tmp);
        const gep = c.LLVMBuildStructGEP2(self.builder, val_type, tmp, @intCast(field_idx), "");
        val = c.LLVMBuildLoad2(self.builder, struct_info.field_types[field_idx], gep, "");
    }

    return val;
}

/// Built-in: todo([msg]) / unreachable([msg]) — unconditional divergence.
fn genDivergeBuiltin(self: *Codegen, args: []const *const Ast.Expr) Error!c.LLVMValueRef {
    if (args.len > 1) return error.UnsupportedExpr;
    if (args.len == 1) {
        // Evaluate optional message expression for side effects/validation.
        _ = try self.genExpr(args[0]);
    }

    const cur_fn = self.current_function;
    const exit_info = try self.ensureExitDeclared();
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    var exit_args = [_]c.LLVMValueRef{c.LLVMConstInt(i32_type, 134, 0)};
    _ = c.LLVMBuildCall2(self.builder, exit_info.fn_type, exit_info.value, &exit_args, 1, "");
    _ = c.LLVMBuildUnreachable(self.builder);

    // Keep a valid insertion point for subsequent source statements in the
    // same syntactic block.
    const dead_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "diverge.dead");
    c.LLVMPositionBuilderAtEnd(self.builder, dead_bb);

    if (self.expected_type) |et| {
        return c.LLVMGetUndef(et);
    }
    return c.LLVMGetUndef(c.LLVMInt32TypeInContext(self.context));
}

/// Built-in: assert(condition) — abort if false.
fn genAssertBuiltin(self: *Codegen, args: []const *const Ast.Expr) Error!c.LLVMValueRef {
    if (args.len < 1) return error.UnsupportedExpr;

    const cond = try self.genExpr(args[0]);
    const cond_bool = self.coerceToBool(cond);

    // if (!cond) _exit(134);
    const then_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "assert.fail");
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "assert.ok");

    _ = c.LLVMBuildCondBr(self.builder, cond_bool, merge_bb, then_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, then_bb);
    // Print assertion failure message if a second arg is provided
    if (args.len > 1) {
        const printf_info = try self.ensurePrintfDeclared();
        const msg = try self.genExpr(args[1]);
        try self.genPrintValue(msg, printf_info);
        const nl = c.LLVMBuildGlobalStringPtr(self.builder, "\n", "");
        var nl_args = [_]c.LLVMValueRef{nl};
        _ = c.LLVMBuildCall2(self.builder, printf_info.fn_type, printf_info.value, &nl_args, 1, "");
    }
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const exit_info = try self.ensureExitDeclared();
    var exit_args = [_]c.LLVMValueRef{c.LLVMConstInt(i32_type, 134, 0)};
    _ = c.LLVMBuildCall2(self.builder, exit_info.fn_type, exit_info.value, &exit_args, 1, "");
    _ = c.LLVMBuildUnreachable(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);

    return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
}

// ── Math builtins ──────────────────────────────────────────────

fn genMathAbs(self: *Codegen, args: []const *const Ast.Expr) Error!c.LLVMValueRef {
    if (args.len != 1) return error.UnsupportedExpr;
    const val = try self.genExpr(args[0]);
    const val_kind = c.LLVMGetTypeKind(c.LLVMTypeOf(val));
    const is_float = (val_kind == c.LLVMFloatTypeKind or val_kind == c.LLVMDoubleTypeKind);
    if (is_float) {
        const zero = c.LLVMConstReal(c.LLVMTypeOf(val), 0.0);
        const neg = c.LLVMBuildFNeg(self.builder, val, "fneg");
        const is_neg = c.LLVMBuildFCmp(self.builder, c.LLVMRealOLT, val, zero, "isneg");
        return c.LLVMBuildSelect(self.builder, is_neg, neg, val, "abs");
    }
    // abs(x) = select(x < 0, -x, x)
    const zero = c.LLVMConstInt(c.LLVMTypeOf(val), 0, 0);
    const neg = c.LLVMBuildNeg(self.builder, val, "neg");
    const is_neg = c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, val, zero, "isneg");
    return c.LLVMBuildSelect(self.builder, is_neg, neg, val, "abs");
}

fn genMathMin(self: *Codegen, args: []const *const Ast.Expr) Error!c.LLVMValueRef {
    if (args.len != 2) return error.UnsupportedExpr;
    const a = try self.genExpr(args[0]);
    const b = try self.genExpr(args[1]);
    const a_kind = c.LLVMGetTypeKind(c.LLVMTypeOf(a));
    const is_float = (a_kind == c.LLVMFloatTypeKind or a_kind == c.LLVMDoubleTypeKind);
    const cmp = if (is_float)
        c.LLVMBuildFCmp(self.builder, c.LLVMRealOLT, a, b, "flt")
    else
        c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, a, b, "lt");
    return c.LLVMBuildSelect(self.builder, cmp, a, b, "min");
}

fn genMathMax(self: *Codegen, args: []const *const Ast.Expr) Error!c.LLVMValueRef {
    if (args.len != 2) return error.UnsupportedExpr;
    const a = try self.genExpr(args[0]);
    const b = try self.genExpr(args[1]);
    const a_kind = c.LLVMGetTypeKind(c.LLVMTypeOf(a));
    const is_float = (a_kind == c.LLVMFloatTypeKind or a_kind == c.LLVMDoubleTypeKind);
    const cmp = if (is_float)
        c.LLVMBuildFCmp(self.builder, c.LLVMRealOGT, a, b, "fgt")
    else
        c.LLVMBuildICmp(self.builder, c.LLVMIntSGT, a, b, "gt");
    return c.LLVMBuildSelect(self.builder, cmp, a, b, "max");
}

fn genMathClamp(self: *Codegen, args: []const *const Ast.Expr) Error!c.LLVMValueRef {
    if (args.len != 3) return error.UnsupportedExpr;
    const val = try self.genExpr(args[0]);
    const lo = try self.genExpr(args[1]);
    const hi = try self.genExpr(args[2]);
    const val_kind = c.LLVMGetTypeKind(c.LLVMTypeOf(val));
    const is_float = (val_kind == c.LLVMFloatTypeKind or val_kind == c.LLVMDoubleTypeKind);
    // clamp(x, lo, hi) = min(max(x, lo), hi)
    const cmp_lo = if (is_float)
        c.LLVMBuildFCmp(self.builder, c.LLVMRealOGT, val, lo, "gt.lo")
    else
        c.LLVMBuildICmp(self.builder, c.LLVMIntSGT, val, lo, "gt.lo");
    const max_val = c.LLVMBuildSelect(self.builder, cmp_lo, val, lo, "max.lo");
    const cmp_hi = if (is_float)
        c.LLVMBuildFCmp(self.builder, c.LLVMRealOLT, max_val, hi, "lt.hi")
    else
        c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, max_val, hi, "lt.hi");
    return c.LLVMBuildSelect(self.builder, cmp_hi, max_val, hi, "clamp");
}

fn genMathUnaryF64(self: *Codegen, args: []const *const Ast.Expr, intrinsic_name: [*:0]const u8) Error!c.LLVMValueRef {
    if (args.len != 1) return error.UnsupportedExpr;
    const arg = try self.genExpr(args[0]);
    // Ensure arg is f64
    const f64_type = c.LLVMDoubleTypeInContext(self.context);
    const val = if (c.LLVMGetTypeKind(c.LLVMTypeOf(arg)) == c.LLVMFloatTypeKind)
        c.LLVMBuildFPExt(self.builder, arg, f64_type, "ext")
    else
        arg;
    // Get or declare the LLVM intrinsic
    var param_types = [_]c.LLVMTypeRef{f64_type};
    const fn_type = c.LLVMFunctionType(f64_type, &param_types, 1, 0);
    var func = c.LLVMGetNamedFunction(self.module, intrinsic_name);
    if (func == null) {
        func = c.LLVMAddFunction(self.module, intrinsic_name, fn_type);
    }
    var call_args = [_]c.LLVMValueRef{val};
    return c.LLVMBuildCall2(self.builder, fn_type, func, &call_args, 1, "math");
}

fn genMathBinaryF64(self: *Codegen, args: []const *const Ast.Expr, intrinsic_name: [*:0]const u8) Error!c.LLVMValueRef {
    if (args.len != 2) return error.UnsupportedExpr;
    const arg0 = try self.genExpr(args[0]);
    const arg1 = try self.genExpr(args[1]);
    const f64_type = c.LLVMDoubleTypeInContext(self.context);
    const val0 = if (c.LLVMGetTypeKind(c.LLVMTypeOf(arg0)) == c.LLVMFloatTypeKind)
        c.LLVMBuildFPExt(self.builder, arg0, f64_type, "ext")
    else
        arg0;
    const val1 = if (c.LLVMGetTypeKind(c.LLVMTypeOf(arg1)) == c.LLVMFloatTypeKind)
        c.LLVMBuildFPExt(self.builder, arg1, f64_type, "ext")
    else
        arg1;
    var param_types = [_]c.LLVMTypeRef{ f64_type, f64_type };
    const fn_type = c.LLVMFunctionType(f64_type, &param_types, 2, 0);
    var func = c.LLVMGetNamedFunction(self.module, intrinsic_name);
    if (func == null) {
        func = c.LLVMAddFunction(self.module, intrinsic_name, fn_type);
    }
    var call_args = [_]c.LLVMValueRef{ val0, val1 };
    return c.LLVMBuildCall2(self.builder, fn_type, func, &call_args, 2, "math");
}

fn genStringLiteral(self: *Codegen, sym: u32) Error!c.LLVMValueRef {
    const tagged = self.pool.resolve(sym);
    if (stripRawStringTag(tagged)) |raw_text| {
        return self.genStringLiteralRaw(raw_text);
    }
    const text = tagged;

    // Check for interpolation: unescaped '{' in the string.
    var has_interp = false;
    {
        var j: usize = 0;
        while (j < text.len) : (j += 1) {
            if (text[j] == '\\') {
                j += 1; // skip escaped char
            } else if (text[j] == '{') {
                has_interp = true;
                break;
            }
        }
    }

    if (has_interp) {
        return self.genInterpolatedString(text);
    }

    return self.genPlainStringLiteral(text);
}

fn stripRawStringTag(text: []const u8) ?[]const u8 {
    const prefix = "\x01raw\x01";
    if (text.len < prefix.len) return null;
    if (!std.mem.eql(u8, text[0..prefix.len], prefix)) return null;
    return text[prefix.len..];
}

/// Generate a plain (non-interpolated) string literal as a str struct.
fn genPlainStringLiteral(self: *Codegen, text: []const u8) Error!c.LLVMValueRef {
    var buf: [4096]u8 = undefined;
    if (text.len >= buf.len) return error.UnsupportedExpr;

    // Process escape sequences.
    var out_len: usize = 0;
    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        if (text[i] == '\\' and i + 1 < text.len) {
            i += 1;
            if (text[i] == 'x' and i + 2 < text.len) {
                const hi = hexDigitValueByte(text[i + 1]);
                const lo = hexDigitValueByte(text[i + 2]);
                if (hi >= 0 and lo >= 0) {
                    buf[out_len] = @intCast((hi * 16) + lo);
                    i += 2;
                } else {
                    buf[out_len] = text[i];
                }
            } else {
                buf[out_len] = switch (text[i]) {
                    'n' => '\n',
                    't' => '\t',
                    'r' => '\r',
                    '0' => 0,
                    '\\' => '\\',
                    '"' => '"',
                    else => text[i],
                };
            }
        } else {
            buf[out_len] = text[i];
        }
        out_len += 1;
    }
    buf[out_len] = 0;

    const str_ptr = c.LLVMBuildGlobalStringPtr(self.builder, @ptrCast(buf[0..out_len :0]), "str.data");

    // Look up the built-in str type.
    const str_sym = self.pool.intern("str") catch return error.CodegenAlloc;
    const str_info = self.struct_types.get(str_sym) orelse return error.UnsupportedType;

    const alloca = c.LLVMBuildAlloca(self.builder, str_info.llvm_type, "str");
    // Field 0: ptr
    const gep_ptr = c.LLVMBuildStructGEP2(self.builder, str_info.llvm_type, alloca, 0, "");
    _ = c.LLVMBuildStore(self.builder, str_ptr, gep_ptr);
    // Field 1: len
    const gep_len = c.LLVMBuildStructGEP2(self.builder, str_info.llvm_type, alloca, 1, "");
    const len_val = c.LLVMConstInt(c.LLVMInt64TypeInContext(self.context), @intCast(out_len), 0);
    _ = c.LLVMBuildStore(self.builder, len_val, gep_len);

    return c.LLVMBuildLoad2(self.builder, str_info.llvm_type, alloca, "str.val");
}

/// Generate a str value from a raw byte slice (no escape processing).
/// Used for __FILE__ and other compiler-generated strings.
fn genStringLiteralRaw(self: *Codegen, text: []const u8) Error!c.LLVMValueRef {
    var buf: [4096]u8 = undefined;
    if (text.len >= buf.len) return error.UnsupportedExpr;
    @memcpy(buf[0..text.len], text);
    buf[text.len] = 0;

    const str_ptr = c.LLVMBuildGlobalStringPtr(self.builder, @ptrCast(buf[0..text.len :0]), "str.data");
    const str_sym = self.pool.intern("str") catch return error.CodegenAlloc;
    const str_info = self.struct_types.get(str_sym) orelse return error.UnsupportedType;

    const alloca = c.LLVMBuildAlloca(self.builder, str_info.llvm_type, "str");
    const gep_ptr = c.LLVMBuildStructGEP2(self.builder, str_info.llvm_type, alloca, 0, "");
    _ = c.LLVMBuildStore(self.builder, str_ptr, gep_ptr);
    const gep_len = c.LLVMBuildStructGEP2(self.builder, str_info.llvm_type, alloca, 1, "");
    const len_val = c.LLVMConstInt(c.LLVMInt64TypeInContext(self.context), @intCast(text.len), 0);
    _ = c.LLVMBuildStore(self.builder, len_val, gep_len);

    return c.LLVMBuildLoad2(self.builder, str_info.llvm_type, alloca, "str.val");
}

/// Record a detailed error message for assignment to immutable variable.
fn setAssignError(self: *Codegen, span: @import("Span.zig"), name: []const u8) void {
    const line = self.spanToLine(span);
    var buf: [256]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "cannot assign to immutable variable '{s}' at {s}:{d}", .{ name, self.source_file, line }) catch "cannot assign to immutable variable";
    self.codegen_error_detail = self.allocator.dupe(u8, msg) catch null;
}

/// Convert a span byte offset to a 1-indexed line number using source text.
fn spanToLine(self: *const Codegen, span: @import("Span.zig")) u32 {
    if (self.source_text.len == 0 or span.start == 0) return 1;
    var line: u32 = 1;
    const end = @min(span.start, @as(u32, @intCast(self.source_text.len)));
    for (self.source_text[0..end]) |ch| {
        if (ch == '\n') line += 1;
    }
    return line;
}

/// Generate an interpolated string as a str value using snprintf.
fn genInterpolatedString(self: *Codegen, text: []const u8) Error!c.LLVMValueRef {
    // Phase 1: Parse interpolation, build format string and collect expression values.
    var fmt_buf: [4096]u8 = undefined;
    var fmt_len: usize = 0;
    var expr_vals: [32]c.LLVMValueRef = undefined;
    var expr_count: usize = 0;

    var i: usize = 0;
    while (i < text.len) {
        if (text[i] == '\\' and i + 1 < text.len) {
            i += 1;
            switch (text[i]) {
                'n' => {
                    fmt_buf[fmt_len] = '\n';
                    fmt_len += 1;
                },
                't' => {
                    fmt_buf[fmt_len] = '\t';
                    fmt_len += 1;
                },
                'r' => {
                    fmt_buf[fmt_len] = '\r';
                    fmt_len += 1;
                },
                '\\' => {
                    fmt_buf[fmt_len] = '\\';
                    fmt_len += 1;
                },
                '"' => {
                    fmt_buf[fmt_len] = '"';
                    fmt_len += 1;
                },
                '{' => {
                    fmt_buf[fmt_len] = '{';
                    fmt_len += 1;
                },
                else => {
                    fmt_buf[fmt_len] = text[i];
                    fmt_len += 1;
                },
            }
            i += 1;
        } else if (text[i] == '{') {
            i += 1;
            const expr_start = i;
            var brace_depth: u32 = 1;
            var format_spec_start: ?usize = null;
            while (i < text.len and brace_depth > 0) {
                if (text[i] == '{') brace_depth += 1;
                if (text[i] == '}') brace_depth -= 1;
                if (text[i] == ':' and brace_depth == 1 and format_spec_start == null) {
                    format_spec_start = i;
                }
                if (brace_depth > 0) i += 1;
            }
            if (brace_depth == 0) {
                const expr_end = if (format_spec_start) |fs| fs else i;
                const expr_text = text[expr_start..expr_end];
                if (try self.resolveInterpExpr(expr_text)) |val| {
                    const ty = c.LLVMTypeOf(val);
                    const kind = c.LLVMGetTypeKind(ty);

                    if (self.isStrType(ty)) {
                        expr_vals[expr_count] = self.extractStrPtr(val);
                        const spec = "%s";
                        @memcpy(fmt_buf[fmt_len..][0..spec.len], spec);
                        fmt_len += spec.len;
                    } else if (kind == c.LLVMPointerTypeKind) {
                        expr_vals[expr_count] = val;
                        const spec = "%s";
                        @memcpy(fmt_buf[fmt_len..][0..spec.len], spec);
                        fmt_len += spec.len;
                    } else if (kind == c.LLVMIntegerTypeKind) {
                        const width = c.LLVMGetIntTypeWidth(ty);
                        if (width == 1) {
                            const true_s = c.LLVMBuildGlobalStringPtr(self.builder, "true", "");
                            const false_s = c.LLVMBuildGlobalStringPtr(self.builder, "false", "");
                            expr_vals[expr_count] = c.LLVMBuildSelect(self.builder, val, true_s, false_s, "");
                            const spec = "%s";
                            @memcpy(fmt_buf[fmt_len..][0..spec.len], spec);
                            fmt_len += spec.len;
                        } else if (width <= 32) {
                            expr_vals[expr_count] = val;
                            const spec = "%d";
                            @memcpy(fmt_buf[fmt_len..][0..spec.len], spec);
                            fmt_len += spec.len;
                        } else {
                            expr_vals[expr_count] = val;
                            const spec = "%lld";
                            @memcpy(fmt_buf[fmt_len..][0..spec.len], spec);
                            fmt_len += spec.len;
                        }
                    } else if (kind == c.LLVMFloatTypeKind or kind == c.LLVMDoubleTypeKind) {
                        if (format_spec_start) |fs| {
                            const spec_text = text[fs + 1 .. i];
                            fmt_buf[fmt_len] = '%';
                            fmt_len += 1;
                            @memcpy(fmt_buf[fmt_len..][0..spec_text.len], spec_text);
                            fmt_len += spec_text.len;
                            fmt_buf[fmt_len] = 'f';
                            fmt_len += 1;
                        } else {
                            const spec = "%g";
                            @memcpy(fmt_buf[fmt_len..][0..spec.len], spec);
                            fmt_len += spec.len;
                        }
                        if (kind == c.LLVMFloatTypeKind) {
                            expr_vals[expr_count] = c.LLVMBuildFPExt(self.builder, val, c.LLVMDoubleTypeInContext(self.context), "");
                        } else {
                            expr_vals[expr_count] = val;
                        }
                    } else {
                        expr_vals[expr_count] = val;
                        const spec = "%d";
                        @memcpy(fmt_buf[fmt_len..][0..spec.len], spec);
                        fmt_len += spec.len;
                    }
                    expr_count += 1;
                } else {
                    fmt_buf[fmt_len] = '{';
                    fmt_len += 1;
                    @memcpy(fmt_buf[fmt_len..][0..expr_text.len], expr_text);
                    fmt_len += expr_text.len;
                    fmt_buf[fmt_len] = '}';
                    fmt_len += 1;
                }
                i += 1;
            }
        } else {
            if (text[i] == '%') {
                fmt_buf[fmt_len] = '%';
                fmt_len += 1;
                fmt_buf[fmt_len] = '%';
                fmt_len += 1;
            } else {
                fmt_buf[fmt_len] = text[i];
                fmt_len += 1;
            }
            i += 1;
        }
    }
    fmt_buf[fmt_len] = 0;

    // Phase 2: Use snprintf to build the string at runtime.
    const snprintf_fn = self.getOrDeclareCFn("snprintf", &.{
        c.LLVMPointerTypeInContext(self.context, 0),
        c.LLVMInt64TypeInContext(self.context),
        c.LLVMPointerTypeInContext(self.context, 0),
    }, c.LLVMInt32TypeInContext(self.context), true);

    const fmt_str = c.LLVMBuildGlobalStringPtr(self.builder, @ptrCast(fmt_buf[0..fmt_len :0]), "interp.fmt");
    const null_ptr = c.LLVMConstNull(c.LLVMPointerTypeInContext(self.context, 0));
    const zero_i64 = c.LLVMConstInt(c.LLVMInt64TypeInContext(self.context), 0, 0);

    // First call: snprintf(NULL, 0, fmt, ...) to get needed length.
    var size_args: [34]c.LLVMValueRef = undefined;
    size_args[0] = null_ptr;
    size_args[1] = zero_i64;
    size_args[2] = fmt_str;
    for (0..expr_count) |j| {
        size_args[j + 3] = expr_vals[j];
    }
    const needed = c.LLVMBuildCall2(
        self.builder,
        snprintf_fn.fn_type,
        snprintf_fn.value,
        &size_args,
        @intCast(expr_count + 3),
        "needed",
    );

    // malloc(needed + 1)
    const malloc_fn = self.getOrDeclareCFn("malloc", &.{
        c.LLVMInt64TypeInContext(self.context),
    }, c.LLVMPointerTypeInContext(self.context, 0), false);

    const needed_i64 = c.LLVMBuildSExt(self.builder, needed, c.LLVMInt64TypeInContext(self.context), "");
    const one_i64 = c.LLVMConstInt(c.LLVMInt64TypeInContext(self.context), 1, 0);
    const buf_size = c.LLVMBuildAdd(self.builder, needed_i64, one_i64, "bufsize");
    var malloc_args = [_]c.LLVMValueRef{buf_size};
    const buf_ptr = c.LLVMBuildCall2(
        self.builder,
        malloc_fn.fn_type,
        malloc_fn.value,
        &malloc_args,
        1,
        "interp.buf",
    );

    // Second call: snprintf(buf, needed+1, fmt, ...)
    var fill_args: [34]c.LLVMValueRef = undefined;
    fill_args[0] = buf_ptr;
    fill_args[1] = buf_size;
    fill_args[2] = fmt_str;
    for (0..expr_count) |j| {
        fill_args[j + 3] = expr_vals[j];
    }
    _ = c.LLVMBuildCall2(
        self.builder,
        snprintf_fn.fn_type,
        snprintf_fn.value,
        &fill_args,
        @intCast(expr_count + 3),
        "",
    );

    // Build str struct { ptr, len }.
    const str_sym = self.pool.intern("str") catch return error.CodegenAlloc;
    const str_info = self.struct_types.get(str_sym) orelse return error.UnsupportedType;

    const alloca = c.LLVMBuildAlloca(self.builder, str_info.llvm_type, "str");
    const gep_ptr = c.LLVMBuildStructGEP2(self.builder, str_info.llvm_type, alloca, 0, "");
    _ = c.LLVMBuildStore(self.builder, buf_ptr, gep_ptr);
    const gep_len = c.LLVMBuildStructGEP2(self.builder, str_info.llvm_type, alloca, 1, "");
    _ = c.LLVMBuildStore(self.builder, needed_i64, gep_len);

    return c.LLVMBuildLoad2(self.builder, str_info.llvm_type, alloca, "str.val");
}

fn genCStringLiteral(self: *Codegen, sym: u32) Error!c.LLVMValueRef {
    const text = self.pool.resolve(sym);
    var buf: [4096]u8 = undefined;
    if (text.len >= buf.len) return error.UnsupportedExpr;

    // Process escape sequences.
    var out_len: usize = 0;
    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        if (text[i] == '\\' and i + 1 < text.len) {
            i += 1;
            if (text[i] == 'x' and i + 2 < text.len) {
                const hi = hexDigitValueByte(text[i + 1]);
                const lo = hexDigitValueByte(text[i + 2]);
                if (hi >= 0 and lo >= 0) {
                    buf[out_len] = @intCast((hi * 16) + lo);
                    i += 2;
                } else {
                    buf[out_len] = text[i];
                }
            } else {
                buf[out_len] = switch (text[i]) {
                    'n' => '\n',
                    't' => '\t',
                    'r' => '\r',
                    '0' => 0,
                    '\\' => '\\',
                    '"' => '"',
                    else => text[i],
                };
            }
        } else {
            buf[out_len] = text[i];
        }
        out_len += 1;
    }
    buf[out_len] = 0;

    // Return a *const i8 pointing to a null-terminated global string constant.
    return c.LLVMBuildGlobalStringPtr(self.builder, @ptrCast(buf[0..out_len :0]), "cstr");
}

fn hexDigitValueByte(ch: u8) i32 {
    if (ch >= '0' and ch <= '9') return @as(i32, ch - '0');
    if (ch >= 'a' and ch <= 'f') return @as(i32, ch - 'a') + 10;
    if (ch >= 'A' and ch <= 'F') return @as(i32, ch - 'A') + 10;
    return -1;
}

// ── Type coercion ────────────────────────────────────────────────

/// Coerce a value to i1 (boolean). If it's already i1, return as-is.
/// For wider integers, emit `val != 0`.
fn coerceToBool(self: *Codegen, val: c.LLVMValueRef) c.LLVMValueRef {
    const val_type = c.LLVMTypeOf(val);
    if (c.LLVMGetTypeKind(val_type) == c.LLVMIntegerTypeKind) {
        const width = c.LLVMGetIntTypeWidth(val_type);
        if (width == 1) return val;
        return c.LLVMBuildICmp(
            self.builder,
            c.LLVMIntNE,
            val,
            c.LLVMConstInt(val_type, 0, 0),
            "tobool",
        );
    }
    return val;
}

/// If `val` is an integer and `target_type` is a different-width integer,
/// insert a trunc or sext.  Otherwise return `val` unchanged.
fn coerceValueForType(self: *Codegen, val: c.LLVMValueRef, target_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const val_type = c.LLVMTypeOf(val);
    // Auto-collect: array-valued pipeline termini can materialize into Vec[T]
    // when destination type context requires Vec[T].
    if (self.isVecType(target_type) and c.LLVMGetTypeKind(val_type) == c.LLVMArrayTypeKind) {
        return try self.coerceArrayToVec(val, val_type, target_type);
    }
    return self.coerceInt(val, target_type);
}

fn coerceArrayToVec(
    self: *Codegen,
    arr_val: c.LLVMValueRef,
    arr_type: c.LLVMTypeRef,
    vec_type: c.LLVMTypeRef,
) Error!c.LLVMValueRef {
    const elem_type = self.getVecElemType(vec_type) orelse return error.UnsupportedExpr;
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const arr_len: usize = @intCast(c.LLVMGetArrayLength2(arr_type));

    var vec_val = try self.genVecNew(elem_type);
    const vec_alloca = c.LLVMBuildAlloca(self.builder, vec_type, "autocollect.vec");
    _ = c.LLVMBuildStore(self.builder, vec_val, vec_alloca);

    const arr_alloca = c.LLVMBuildAlloca(self.builder, arr_type, "autocollect.arr");
    _ = c.LLVMBuildStore(self.builder, arr_val, arr_alloca);

    for (0..arr_len) |i| {
        var idxs = [_]c.LLVMValueRef{
            c.LLVMConstInt(i64_type, 0, 0),
            c.LLVMConstInt(i64_type, i, 0),
        };
        const elem_ptr = c.LLVMBuildGEP2(self.builder, arr_type, arr_alloca, &idxs, 2, "autocollect.elem.ptr");
        const src_elem_ty = c.LLVMGetElementType(arr_type);
        var elem_val = c.LLVMBuildLoad2(self.builder, src_elem_ty, elem_ptr, "autocollect.elem");
        elem_val = self.coerceInt(elem_val, elem_type);
        _ = try self.genVecPush(vec_alloca, vec_type, elem_val);
    }

    vec_val = c.LLVMBuildLoad2(self.builder, vec_type, vec_alloca, "autocollect.vec.val");
    return vec_val;
}

fn coerceInt(self: *Codegen, val: c.LLVMValueRef, target_type: c.LLVMTypeRef) c.LLVMValueRef {
    const val_type = c.LLVMTypeOf(val);
    const val_kind = c.LLVMGetTypeKind(val_type);
    const tgt_kind = c.LLVMGetTypeKind(target_type);
    if (val_kind != c.LLVMIntegerTypeKind or tgt_kind != c.LLVMIntegerTypeKind)
        return val;
    const val_bits = c.LLVMGetIntTypeWidth(val_type);
    const tgt_bits = c.LLVMGetIntTypeWidth(target_type);
    if (val_bits == tgt_bits) return val;
    if (val_bits > tgt_bits)
        return c.LLVMBuildTrunc(self.builder, val, target_type, "trunc");
    return c.LLVMBuildSExt(self.builder, val, target_type, "sext");
}

/// Widen the narrower operand so both have the same integer width.
fn coerceBinaryOperands(self: *Codegen, lhs: c.LLVMValueRef, rhs: c.LLVMValueRef) struct { c.LLVMValueRef, c.LLVMValueRef } {
    const lt = c.LLVMTypeOf(lhs);
    const rt = c.LLVMTypeOf(rhs);
    if (c.LLVMGetTypeKind(lt) != c.LLVMIntegerTypeKind or
        c.LLVMGetTypeKind(rt) != c.LLVMIntegerTypeKind)
        return .{ lhs, rhs };
    const lw = c.LLVMGetIntTypeWidth(lt);
    const rw = c.LLVMGetIntTypeWidth(rt);
    if (lw == rw) return .{ lhs, rhs };
    if (lw > rw)
        return .{ lhs, c.LLVMBuildSExt(self.builder, rhs, lt, "sext") };
    return .{ c.LLVMBuildSExt(self.builder, lhs, rt, "sext"), rhs };
}

// ── str type helpers ─────────────────────────────────────────────

fn isStrType(self: *Codegen, ty: c.LLVMTypeRef) bool {
    const str_sym = self.pool.intern("str") catch return false;
    const str_info = self.struct_types.get(str_sym) orelse return false;
    return ty == str_info.llvm_type;
}

/// Get the LLVM type for str.
fn getStrType(self: *Codegen) c.LLVMTypeRef {
    const str_sym = self.pool.intern("str") catch unreachable;
    const str_info = self.struct_types.get(str_sym).?;
    return str_info.llvm_type;
}

/// Generate string concatenation: str + str → new str.
fn genStrConcat(self: *Codegen, lhs: c.LLVMValueRef, rhs: c.LLVMValueRef) Error!c.LLVMValueRef {
    const str_sym = self.pool.intern("str") catch return error.CodegenAlloc;
    const str_info = self.struct_types.get(str_sym) orelse return error.UnsupportedExpr;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);

    // Extract ptr and len from both strings.
    const lhs_alloca = c.LLVMBuildAlloca(self.builder, str_info.llvm_type, "lhs.str");
    _ = c.LLVMBuildStore(self.builder, lhs, lhs_alloca);
    const lhs_ptr_gep = c.LLVMBuildStructGEP2(self.builder, str_info.llvm_type, lhs_alloca, 0, "");
    const lhs_ptr = c.LLVMBuildLoad2(self.builder, ptr_type, lhs_ptr_gep, "lhs.ptr");
    const lhs_len_gep = c.LLVMBuildStructGEP2(self.builder, str_info.llvm_type, lhs_alloca, 1, "");
    const lhs_len = c.LLVMBuildLoad2(self.builder, i64_type, lhs_len_gep, "lhs.len");

    const rhs_alloca = c.LLVMBuildAlloca(self.builder, str_info.llvm_type, "rhs.str");
    _ = c.LLVMBuildStore(self.builder, rhs, rhs_alloca);
    const rhs_ptr_gep = c.LLVMBuildStructGEP2(self.builder, str_info.llvm_type, rhs_alloca, 0, "");
    const rhs_ptr = c.LLVMBuildLoad2(self.builder, ptr_type, rhs_ptr_gep, "rhs.ptr");
    const rhs_len_gep = c.LLVMBuildStructGEP2(self.builder, str_info.llvm_type, rhs_alloca, 1, "");
    const rhs_len = c.LLVMBuildLoad2(self.builder, i64_type, rhs_len_gep, "rhs.len");

    // total_len = lhs.len + rhs.len
    const total_len = c.LLVMBuildAdd(self.builder, lhs_len, rhs_len, "total.len");

    // Allocate buffer: malloc(total_len + 1) for null terminator.
    const one = c.LLVMConstInt(i64_type, 1, 0);
    const alloc_size = c.LLVMBuildAdd(self.builder, total_len, one, "alloc.size");

    // Ensure malloc is declared.
    const malloc_fn = self.ensureMallocDeclared();
    var malloc_args = [_]c.LLVMValueRef{alloc_size};
    const new_buf = c.LLVMBuildCall2(self.builder, malloc_fn.fn_type, malloc_fn.value, &malloc_args, 1, "concat.buf");

    // Ensure memcpy is declared.
    const memcpy_fn = self.ensureMemcpyDeclared();

    // memcpy(new_buf, lhs.ptr, lhs.len)
    var copy1_args = [_]c.LLVMValueRef{ new_buf, lhs_ptr, lhs_len };
    _ = c.LLVMBuildCall2(self.builder, memcpy_fn.fn_type, memcpy_fn.value, &copy1_args, 3, "");

    // memcpy(new_buf + lhs.len, rhs.ptr, rhs.len)
    var gep_idx1 = [_]c.LLVMValueRef{lhs_len};
    const dest2 = c.LLVMBuildGEP2(self.builder, c.LLVMInt8TypeInContext(self.context), new_buf, &gep_idx1, 1, "dest2");
    var copy2_args = [_]c.LLVMValueRef{ dest2, rhs_ptr, rhs_len };
    _ = c.LLVMBuildCall2(self.builder, memcpy_fn.fn_type, memcpy_fn.value, &copy2_args, 3, "");

    // Null-terminate: new_buf[total_len] = 0
    var gep_idx2 = [_]c.LLVMValueRef{total_len};
    const end_ptr = c.LLVMBuildGEP2(self.builder, c.LLVMInt8TypeInContext(self.context), new_buf, &gep_idx2, 1, "end");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(c.LLVMInt8TypeInContext(self.context), 0, 0), end_ptr);

    // Build result: str { ptr: new_buf, len: total_len }
    const result_alloca = c.LLVMBuildAlloca(self.builder, str_info.llvm_type, "concat.result");
    const result_ptr_gep = c.LLVMBuildStructGEP2(self.builder, str_info.llvm_type, result_alloca, 0, "");
    _ = c.LLVMBuildStore(self.builder, new_buf, result_ptr_gep);
    const result_len_gep = c.LLVMBuildStructGEP2(self.builder, str_info.llvm_type, result_alloca, 1, "");
    _ = c.LLVMBuildStore(self.builder, total_len, result_len_gep);

    return c.LLVMBuildLoad2(self.builder, str_info.llvm_type, result_alloca, "concat");
}

/// Generate string comparison: str == str or str != str.
/// Uses length check + memcmp for correct comparison of non-null-terminated strings.
fn genStrCompare(self: *Codegen, lhs: c.LLVMValueRef, rhs: c.LLVMValueRef, op: Ast.BinOp) Error!c.LLVMValueRef {
    const l = self.extractStrPtrAndLen(lhs);
    const r = self.extractStrPtrAndLen(rhs);

    // First: check lengths are equal.
    const len_eq = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, l.len, r.len, "len_eq");

    // Then: memcmp(lhs.ptr, rhs.ptr, lhs.len) == 0
    const memcmp_fn = self.ensureMemcmpDeclared();
    var call_args = [_]c.LLVMValueRef{ l.ptr, r.ptr, l.len };
    const cmp_result = c.LLVMBuildCall2(self.builder, memcmp_fn.fn_type, memcmp_fn.value, &call_args, 3, "memcmp");
    const zero = c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
    const mem_eq = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, cmp_result, zero, "mem_eq");

    // Both conditions must hold: len_eq AND mem_eq
    const both = c.LLVMBuildAnd(self.builder, len_eq, mem_eq, "streq");

    return if (op == .eq) both else c.LLVMBuildNot(self.builder, both, "strne");
}

/// Ensure memcmp is declared.
fn ensureMemcmpDeclared(self: *Codegen) FnInfo {
    const sym = self.pool.intern("memcmp") catch unreachable;
    if (self.functions.get(sym)) |fi| return fi;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    var param_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type, i64_type };
    const fn_type = c.LLVMFunctionType(i32_type, &param_types, 3, 0);
    const func = c.LLVMAddFunction(self.module, "memcmp", fn_type);
    const fi: FnInfo = .{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, sym, fi) catch {};
    return fi;
}

/// Helper: extract (ptr, len) from a str value.
fn extractStrPtrAndLen(self: *Codegen, val: c.LLVMValueRef) struct { ptr: c.LLVMValueRef, len: c.LLVMValueRef } {
    const str_sym = self.pool.intern("str") catch unreachable;
    const str_info = self.struct_types.get(str_sym).?;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, str_info.llvm_type, "s");
    _ = c.LLVMBuildStore(self.builder, val, alloca);
    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, str_info.llvm_type, alloca, 0, "");
    const ptr = c.LLVMBuildLoad2(self.builder, ptr_type, ptr_gep, "s.ptr");
    const len_gep = c.LLVMBuildStructGEP2(self.builder, str_info.llvm_type, alloca, 1, "");
    const len = c.LLVMBuildLoad2(self.builder, i64_type, len_gep, "s.len");
    return .{ .ptr = ptr, .len = len };
}

/// Helper: build a str value from ptr and len.
fn buildStrValue(self: *Codegen, ptr: c.LLVMValueRef, len: c.LLVMValueRef) c.LLVMValueRef {
    const str_sym = self.pool.intern("str") catch unreachable;
    const str_info = self.struct_types.get(str_sym).?;
    const alloca = c.LLVMBuildAlloca(self.builder, str_info.llvm_type, "str.result");
    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, str_info.llvm_type, alloca, 0, "");
    _ = c.LLVMBuildStore(self.builder, ptr, ptr_gep);
    const len_gep = c.LLVMBuildStructGEP2(self.builder, str_info.llvm_type, alloca, 1, "");
    _ = c.LLVMBuildStore(self.builder, len, len_gep);
    return c.LLVMBuildLoad2(self.builder, str_info.llvm_type, alloca, "str.val");
}

/// Convert a C string pointer (`*u8` / `char*`) into a `str` value by calling strlen.
fn cStrPtrToStr(self: *Codegen, ptr_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const strlen_info = self.getOrDeclareCFn("strlen", &.{ptr_type}, i64_type, false);
    var call_args = [_]c.LLVMValueRef{ptr_val};
    const len = c.LLVMBuildCall2(self.builder, strlen_info.fn_type, strlen_info.value, &call_args, 1, "cstr.len");
    return self.buildStrValue(ptr_val, len);
}

/// Ensure strstr is declared.
fn ensureStrstrDeclared(self: *Codegen) FnInfo {
    const sym = self.pool.intern("strstr") catch unreachable;
    if (self.functions.get(sym)) |fi| return fi;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    var param_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
    const fn_type = c.LLVMFunctionType(ptr_type, &param_types, 2, 0);
    const func = c.LLVMAddFunction(self.module, "strstr", fn_type);
    const fi: FnInfo = .{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, sym, fi) catch {};
    return fi;
}

/// Ensure strncmp is declared.
fn ensureStrncmpDeclared(self: *Codegen) FnInfo {
    const sym = self.pool.intern("strncmp") catch unreachable;
    if (self.functions.get(sym)) |fi| return fi;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    var param_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type, i64_type };
    const fn_type = c.LLVMFunctionType(i32_type, &param_types, 3, 0);
    const func = c.LLVMAddFunction(self.module, "strncmp", fn_type);
    const fi: FnInfo = .{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, sym, fi) catch {};
    return fi;
}

/// Ensure free is declared.
fn ensureFreeDeclared(self: *Codegen) FnInfo {
    const sym = self.pool.intern("free") catch unreachable;
    if (self.functions.get(sym)) |fi| return fi;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const void_type = c.LLVMVoidTypeInContext(self.context);
    var param_types = [_]c.LLVMTypeRef{ptr_type};
    const fn_type = c.LLVMFunctionType(void_type, &param_types, 1, 0);
    const func = c.LLVMAddFunction(self.module, "free", fn_type);
    const fi: FnInfo = .{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, sym, fi) catch {};
    return fi;
}

/// str.len() → i64
fn genStrLen(self: *Codegen, obj_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const s = self.extractStrPtrAndLen(obj_val);
    return s.len;
}

/// str.is_empty() → bool
fn genStrIsEmpty(self: *Codegen, obj_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const s = self.extractStrPtrAndLen(obj_val);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    return c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, s.len, c.LLVMConstInt(i64_type, 0, 0), "is_empty");
}

/// str.contains(needle) → bool — uses strstr(ptr, needle.ptr) != null
fn genStrContains(self: *Codegen, obj_val: c.LLVMValueRef, needle: c.LLVMValueRef) Error!c.LLVMValueRef {
    const s = self.extractStrPtrAndLen(obj_val);
    const n = self.extractStrPtrAndLen(needle);
    const strstr_fn = self.ensureStrstrDeclared();
    var call_args = [_]c.LLVMValueRef{ s.ptr, n.ptr };
    const result = c.LLVMBuildCall2(self.builder, strstr_fn.fn_type, strstr_fn.value, &call_args, 2, "strstr");
    const null_ptr = c.LLVMConstNull(c.LLVMPointerTypeInContext(self.context, 0));
    return c.LLVMBuildICmp(self.builder, c.LLVMIntNE, result, null_ptr, "contains");
}

/// str.starts_with(prefix) → bool — strncmp(ptr, prefix.ptr, prefix.len) == 0
fn genStrStartsWith(self: *Codegen, obj_val: c.LLVMValueRef, prefix: c.LLVMValueRef) Error!c.LLVMValueRef {
    const s = self.extractStrPtrAndLen(obj_val);
    const p = self.extractStrPtrAndLen(prefix);
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    // First check: s.len >= p.len
    const len_ok = c.LLVMBuildICmp(self.builder, c.LLVMIntSGE, s.len, p.len, "len_ok");
    const strncmp_fn = self.ensureStrncmpDeclared();
    var cmp_args = [_]c.LLVMValueRef{ s.ptr, p.ptr, p.len };
    const cmp_result = c.LLVMBuildCall2(self.builder, strncmp_fn.fn_type, strncmp_fn.value, &cmp_args, 3, "cmp");
    const is_eq = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, cmp_result, c.LLVMConstInt(i32_type, 0, 0), "eq");
    return c.LLVMBuildAnd(self.builder, len_ok, is_eq, "starts_with");
}

/// str.ends_with(suffix) → bool
fn genStrEndsWith(self: *Codegen, obj_val: c.LLVMValueRef, suffix: c.LLVMValueRef) Error!c.LLVMValueRef {
    const s = self.extractStrPtrAndLen(obj_val);
    const sfx = self.extractStrPtrAndLen(suffix);
    const i8_type = c.LLVMInt8TypeInContext(self.context);
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    // Check s.len >= sfx.len
    const len_ok = c.LLVMBuildICmp(self.builder, c.LLVMIntSGE, s.len, sfx.len, "len_ok");
    // offset = s.len - sfx.len
    const offset = c.LLVMBuildSub(self.builder, s.len, sfx.len, "offset");
    var gep_idx = [_]c.LLVMValueRef{offset};
    const tail_ptr = c.LLVMBuildGEP2(self.builder, i8_type, s.ptr, &gep_idx, 1, "tail");
    const strncmp_fn = self.ensureStrncmpDeclared();
    var cmp_args = [_]c.LLVMValueRef{ tail_ptr, sfx.ptr, sfx.len };
    const cmp_result = c.LLVMBuildCall2(self.builder, strncmp_fn.fn_type, strncmp_fn.value, &cmp_args, 3, "cmp");
    const is_eq = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, cmp_result, c.LLVMConstInt(i32_type, 0, 0), "eq");
    return c.LLVMBuildAnd(self.builder, len_ok, is_eq, "ends_with");
}

/// str.find(needle) → i64 (-1 if not found)
fn genStrFind(self: *Codegen, obj_val: c.LLVMValueRef, needle: c.LLVMValueRef) Error!c.LLVMValueRef {
    const s = self.extractStrPtrAndLen(obj_val);
    const n = self.extractStrPtrAndLen(needle);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const strstr_fn = self.ensureStrstrDeclared();
    var call_args = [_]c.LLVMValueRef{ s.ptr, n.ptr };
    const result = c.LLVMBuildCall2(self.builder, strstr_fn.fn_type, strstr_fn.value, &call_args, 2, "strstr");
    const null_ptr = c.LLVMConstNull(c.LLVMPointerTypeInContext(self.context, 0));
    const is_found = c.LLVMBuildICmp(self.builder, c.LLVMIntNE, result, null_ptr, "found");
    // If found: result_ptr - s.ptr, else -1
    const result_int = c.LLVMBuildPtrToInt(self.builder, result, i64_type, "res_int");
    const base_int = c.LLVMBuildPtrToInt(self.builder, s.ptr, i64_type, "base_int");
    const idx = c.LLVMBuildSub(self.builder, result_int, base_int, "idx");
    const neg_one = c.LLVMConstInt(i64_type, @bitCast(@as(i64, -1)), 0);
    return c.LLVMBuildSelect(self.builder, is_found, idx, neg_one, "find");
}

/// str.to_upper() / str.to_lower() → new str
fn genStrToCase(self: *Codegen, obj_val: c.LLVMValueRef, upper: bool) Error!c.LLVMValueRef {
    const s = self.extractStrPtrAndLen(obj_val);
    const i8_type = c.LLVMInt8TypeInContext(self.context);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const one = c.LLVMConstInt(i64_type, 1, 0);
    // Allocate new buffer: malloc(len + 1)
    const alloc_size = c.LLVMBuildAdd(self.builder, s.len, one, "alloc");
    const malloc_fn = self.ensureMallocDeclared();
    var malloc_args = [_]c.LLVMValueRef{alloc_size};
    const new_buf = c.LLVMBuildCall2(self.builder, malloc_fn.fn_type, malloc_fn.value, &malloc_args, 1, "buf");
    // Loop: for each byte, convert case
    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const loop_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "case.loop");
    const done_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "case.done");
    const entry_bb = c.LLVMGetInsertBlock(self.builder);
    _ = c.LLVMBuildBr(self.builder, loop_bb);
    c.LLVMPositionBuilderAtEnd(self.builder, loop_bb);
    const phi_i = c.LLVMBuildPhi(self.builder, i64_type, "i");
    // Load byte
    var gep_src = [_]c.LLVMValueRef{phi_i};
    const src_byte_ptr = c.LLVMBuildGEP2(self.builder, i8_type, s.ptr, &gep_src, 1, "");
    const byte_val = c.LLVMBuildLoad2(self.builder, i8_type, src_byte_ptr, "ch");
    // Convert: check if in range and flip case
    const byte_i32 = c.LLVMBuildZExt(self.builder, byte_val, c.LLVMInt32TypeInContext(self.context), "");
    const from_lo: u64 = if (upper) 'a' else 'A';
    const from_hi: u64 = if (upper) 'z' else 'Z';
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const lo = c.LLVMConstInt(i32_type, from_lo, 0);
    const hi = c.LLVMConstInt(i32_type, from_hi, 0);
    const ge = c.LLVMBuildICmp(self.builder, c.LLVMIntUGE, byte_i32, lo, "ge");
    const le = c.LLVMBuildICmp(self.builder, c.LLVMIntULE, byte_i32, hi, "le");
    const in_range = c.LLVMBuildAnd(self.builder, ge, le, "in_range");
    const case_diff: u64 = 'a' - 'A';
    const diff = c.LLVMConstInt(i32_type, case_diff, 0);
    const converted = if (upper)
        c.LLVMBuildSub(self.builder, byte_i32, diff, "conv")
    else
        c.LLVMBuildAdd(self.builder, byte_i32, diff, "conv");
    const result_i32 = c.LLVMBuildSelect(self.builder, in_range, converted, byte_i32, "");
    const result_byte = c.LLVMBuildTrunc(self.builder, result_i32, i8_type, "");
    // Store to new buffer
    var gep_dst = [_]c.LLVMValueRef{phi_i};
    const dst_byte_ptr = c.LLVMBuildGEP2(self.builder, i8_type, new_buf, &gep_dst, 1, "");
    _ = c.LLVMBuildStore(self.builder, result_byte, dst_byte_ptr);
    // i++
    const next_i = c.LLVMBuildAdd(self.builder, phi_i, one, "next_i");
    const at_end = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, next_i, s.len, "at_end");
    _ = c.LLVMBuildCondBr(self.builder, at_end, done_bb, loop_bb);
    // Phi incoming
    var phi_vals = [_]c.LLVMValueRef{ c.LLVMConstInt(i64_type, 0, 0), next_i };
    var phi_bbs = [_]c.LLVMBasicBlockRef{ entry_bb, loop_bb };
    c.LLVMAddIncoming(phi_i, &phi_vals, &phi_bbs, 2);
    // Done: null-terminate and build str
    c.LLVMPositionBuilderAtEnd(self.builder, done_bb);
    var gep_end = [_]c.LLVMValueRef{s.len};
    const end_ptr = c.LLVMBuildGEP2(self.builder, i8_type, new_buf, &gep_end, 1, "");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i8_type, 0, 0), end_ptr);
    return self.buildStrValue(new_buf, s.len);
}

/// str.trim() → new str (trim leading/trailing whitespace, returns a slice — no allocation)
/// Uses alloca-based approach to avoid SSA dominance issues across blocks.
fn genStrTrim(self: *Codegen, obj_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const s = self.extractStrPtrAndLen(obj_val);
    const i8_type = c.LLVMInt8TypeInContext(self.context);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const one = c.LLVMConstInt(i64_type, 1, 0);
    const zero = c.LLVMConstInt(i64_type, 0, 0);
    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const i32_ty = c.LLVMInt32TypeInContext(self.context);

    // Use allocas to store start/end results across blocks.
    const start_slot = c.LLVMBuildAlloca(self.builder, i64_type, "trim.start_slot");
    const end_slot = c.LLVMBuildAlloca(self.builder, i64_type, "trim.end_slot");
    _ = c.LLVMBuildStore(self.builder, zero, start_slot);
    _ = c.LLVMBuildStore(self.builder, s.len, end_slot);

    // Phase 1: Find start (skip leading whitespace)
    const find_start_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trim.fwd");
    const find_end_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trim.rev");
    const done_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trim.done");
    const entry_bb = c.LLVMGetInsertBlock(self.builder);
    _ = c.LLVMBuildBr(self.builder, find_start_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, find_start_bb);
    const start_phi = c.LLVMBuildPhi(self.builder, i64_type, "i");
    const at_end = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, start_phi, s.len, "");
    const check_fwd_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trim.check_fwd");
    _ = c.LLVMBuildCondBr(self.builder, at_end, done_bb, check_fwd_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, check_fwd_bb);
    var gep_s = [_]c.LLVMValueRef{start_phi};
    const ch_ptr = c.LLVMBuildGEP2(self.builder, i8_type, s.ptr, &gep_s, 1, "");
    const ch = c.LLVMBuildLoad2(self.builder, i8_type, ch_ptr, "ch");
    const ch32 = c.LLVMBuildZExt(self.builder, ch, i32_ty, "");
    const is_ws_fwd = self.buildIsWhitespace(ch32);
    const next_start = c.LLVMBuildAdd(self.builder, start_phi, one, "");
    _ = c.LLVMBuildCondBr(self.builder, is_ws_fwd, find_start_bb, find_end_bb);
    // Store start when we find non-whitespace
    var start_phi_vals = [_]c.LLVMValueRef{ zero, next_start };
    var start_phi_bbs = [_]c.LLVMBasicBlockRef{ entry_bb, check_fwd_bb };
    c.LLVMAddIncoming(start_phi, &start_phi_vals, &start_phi_bbs, 2);

    // Phase 2: Find end (skip trailing whitespace from len backwards)
    c.LLVMPositionBuilderAtEnd(self.builder, find_end_bb);
    _ = c.LLVMBuildStore(self.builder, start_phi, start_slot);
    const rev_loop_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trim.rev_loop");
    _ = c.LLVMBuildBr(self.builder, rev_loop_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, rev_loop_bb);
    const end_phi = c.LLVMBuildPhi(self.builder, i64_type, "j");
    const end_gt_start = c.LLVMBuildICmp(self.builder, c.LLVMIntSGT, end_phi, start_phi, "");
    const check_rev_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trim.check_rev");
    _ = c.LLVMBuildCondBr(self.builder, end_gt_start, check_rev_bb, done_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, check_rev_bb);
    const end_minus = c.LLVMBuildSub(self.builder, end_phi, one, "");
    var gep_e = [_]c.LLVMValueRef{end_minus};
    const ch_ptr_e = c.LLVMBuildGEP2(self.builder, i8_type, s.ptr, &gep_e, 1, "");
    const ch_e = c.LLVMBuildLoad2(self.builder, i8_type, ch_ptr_e, "ch_e");
    const ch_e32 = c.LLVMBuildZExt(self.builder, ch_e, i32_ty, "");
    const is_ws_rev = self.buildIsWhitespace(ch_e32);
    // If whitespace, store decremented end and loop; otherwise store current end and exit
    const store_end_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trim.store_end");
    _ = c.LLVMBuildCondBr(self.builder, is_ws_rev, rev_loop_bb, store_end_bb);
    var end_phi_vals = [_]c.LLVMValueRef{ s.len, end_minus };
    var end_phi_bbs = [_]c.LLVMBasicBlockRef{ find_end_bb, check_rev_bb };
    c.LLVMAddIncoming(end_phi, &end_phi_vals, &end_phi_bbs, 2);

    c.LLVMPositionBuilderAtEnd(self.builder, store_end_bb);
    _ = c.LLVMBuildStore(self.builder, end_phi, end_slot);
    _ = c.LLVMBuildBr(self.builder, done_bb);

    // Done: read start/end from allocas and build result str
    c.LLVMPositionBuilderAtEnd(self.builder, done_bb);
    const final_start = c.LLVMBuildLoad2(self.builder, i64_type, start_slot, "trim.s");
    const final_end = c.LLVMBuildLoad2(self.builder, i64_type, end_slot, "trim.e");
    const new_len = c.LLVMBuildSub(self.builder, final_end, final_start, "trim.len");
    var gep_start = [_]c.LLVMValueRef{final_start};
    const new_ptr = c.LLVMBuildGEP2(self.builder, i8_type, s.ptr, &gep_start, 1, "trim.ptr");
    return self.buildStrValue(new_ptr, new_len);
}

/// Helper: build is-whitespace check for a char (i32).
fn buildIsWhitespace(self: *Codegen, ch32: c.LLVMValueRef) c.LLVMValueRef {
    const i32_ty = c.LLVMInt32TypeInContext(self.context);
    const is_space = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, ch32, c.LLVMConstInt(i32_ty, ' ', 0), "");
    const is_tab = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, ch32, c.LLVMConstInt(i32_ty, '\t', 0), "");
    const is_nl = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, ch32, c.LLVMConstInt(i32_ty, '\n', 0), "");
    const is_cr = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, ch32, c.LLVMConstInt(i32_ty, '\r', 0), "");
    const ws1 = c.LLVMBuildOr(self.builder, is_space, is_tab, "");
    const ws2 = c.LLVMBuildOr(self.builder, is_nl, is_cr, "");
    return c.LLVMBuildOr(self.builder, ws1, ws2, "is_ws");
}

/// str.repeat(n) → new str
fn genStrRepeat(self: *Codegen, obj_val: c.LLVMValueRef, count: c.LLVMValueRef) Error!c.LLVMValueRef {
    const s = self.extractStrPtrAndLen(obj_val);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const i8_type = c.LLVMInt8TypeInContext(self.context);
    const one = c.LLVMConstInt(i64_type, 1, 0);
    // Coerce count to i64
    const count_i64 = self.coerceInt(count, i64_type);
    // total_len = len * count
    const total_len = c.LLVMBuildMul(self.builder, s.len, count_i64, "total");
    const alloc_size = c.LLVMBuildAdd(self.builder, total_len, one, "alloc");
    const malloc_fn = self.ensureMallocDeclared();
    var malloc_args = [_]c.LLVMValueRef{alloc_size};
    const new_buf = c.LLVMBuildCall2(self.builder, malloc_fn.fn_type, malloc_fn.value, &malloc_args, 1, "buf");
    // Loop: memcpy(buf + i*len, ptr, len) for i in 0..count
    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const loop_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "repeat.loop");
    const done_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "repeat.done");
    const entry_bb = c.LLVMGetInsertBlock(self.builder);
    _ = c.LLVMBuildBr(self.builder, loop_bb);
    c.LLVMPositionBuilderAtEnd(self.builder, loop_bb);
    const phi_i = c.LLVMBuildPhi(self.builder, i64_type, "i");
    const at_end = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, phi_i, count_i64, "");
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "repeat.body");
    _ = c.LLVMBuildCondBr(self.builder, at_end, done_bb, body_bb);
    c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
    const offset = c.LLVMBuildMul(self.builder, phi_i, s.len, "off");
    var gep_idx = [_]c.LLVMValueRef{offset};
    const dst = c.LLVMBuildGEP2(self.builder, i8_type, new_buf, &gep_idx, 1, "dst");
    const memcpy_fn = self.ensureMemcpyDeclared();
    var cpy_args = [_]c.LLVMValueRef{ dst, s.ptr, s.len };
    _ = c.LLVMBuildCall2(self.builder, memcpy_fn.fn_type, memcpy_fn.value, &cpy_args, 3, "");
    const next_i = c.LLVMBuildAdd(self.builder, phi_i, one, "");
    _ = c.LLVMBuildBr(self.builder, loop_bb);
    var phi_vals = [_]c.LLVMValueRef{ c.LLVMConstInt(i64_type, 0, 0), next_i };
    var phi_bbs = [_]c.LLVMBasicBlockRef{ entry_bb, body_bb };
    c.LLVMAddIncoming(phi_i, &phi_vals, &phi_bbs, 2);
    // Done: null-terminate
    c.LLVMPositionBuilderAtEnd(self.builder, done_bb);
    var gep_end = [_]c.LLVMValueRef{total_len};
    const end_ptr = c.LLVMBuildGEP2(self.builder, i8_type, new_buf, &gep_end, 1, "");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i8_type, 0, 0), end_ptr);
    return self.buildStrValue(new_buf, total_len);
}

/// str.slice(start, end) → new str (returns a view, no allocation)
fn genStrSlice(self: *Codegen, obj_val: c.LLVMValueRef, start: c.LLVMValueRef, end: c.LLVMValueRef) Error!c.LLVMValueRef {
    const s = self.extractStrPtrAndLen(obj_val);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const i8_type = c.LLVMInt8TypeInContext(self.context);
    const start_i64 = self.coerceInt(start, i64_type);
    const end_i64 = self.coerceInt(end, i64_type);
    var gep_idx = [_]c.LLVMValueRef{start_i64};
    const new_ptr = c.LLVMBuildGEP2(self.builder, i8_type, s.ptr, &gep_idx, 1, "slice.ptr");
    const new_len = c.LLVMBuildSub(self.builder, end_i64, start_i64, "slice.len");
    return self.buildStrValue(new_ptr, new_len);
}

/// str.split(delim) → Vec[str] — calls with_str_split C helper.
fn genStrSplit(self: *Codegen, obj_val: c.LLVMValueRef, delim: c.LLVMValueRef) Error!c.LLVMValueRef {
    const s = self.extractStrPtrAndLen(obj_val);
    const d = self.extractStrPtrAndLen(delim);
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);

    // Declare with_str_split if needed
    const split_fn = self.ensureSplitHelperDeclared();

    // Allocate stack buffers for up to 256 parts
    const max_parts: u64 = 256;
    const ptrs_arr_type = c.LLVMArrayType2(ptr_type, max_parts);
    const lens_arr_type = c.LLVMArrayType2(i64_type, max_parts);
    const ptrs_buf = c.LLVMBuildAlloca(self.builder, ptrs_arr_type, "ptrs_buf");
    const lens_buf = c.LLVMBuildAlloca(self.builder, lens_arr_type, "lens_buf");

    // Call with_str_split(src, src_len, delim, delim_len, ptrs_buf, lens_buf, max_parts)
    var call_args = [_]c.LLVMValueRef{
        s.ptr,                                  d.len,
        d.ptr,                                  d.len,
        ptrs_buf,                               lens_buf,
        c.LLVMConstInt(i64_type, max_parts, 0),
    };
    // Fix: first arg is src, second is src_len
    call_args[0] = s.ptr;
    call_args[1] = s.len;
    call_args[2] = d.ptr;
    call_args[3] = d.len;
    const count = c.LLVMBuildCall2(self.builder, split_fn.fn_type, split_fn.value, &call_args, 7, "count");

    // Build a Vec[str] from the results
    const str_sym = self.pool.intern("str") catch return error.CodegenAlloc;
    const str_info = self.struct_types.get(str_sym) orelse return error.UnsupportedExpr;
    const vec_info = try self.getOrCreateVecType(str_info.llvm_type);

    // Create empty Vec and push each part
    const vec_alloca = c.LLVMBuildAlloca(self.builder, vec_info.llvm_type, "split_vec");
    const initial = try self.genVecNew(str_info.llvm_type);
    _ = c.LLVMBuildStore(self.builder, initial, vec_alloca);

    // Loop: for i in 0..count, push str { ptrs[i], lens[i] }
    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const loop_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "split.loop");
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "split.body");
    const done_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "split.done");
    const entry_bb = c.LLVMGetInsertBlock(self.builder);
    _ = c.LLVMBuildBr(self.builder, loop_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, loop_bb);
    const phi_i = c.LLVMBuildPhi(self.builder, i64_type, "i");
    const at_end = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, phi_i, count, "");
    _ = c.LLVMBuildCondBr(self.builder, at_end, done_bb, body_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
    // Load ptr and len for part i
    const zero_idx = c.LLVMConstInt(c.LLVMInt64TypeInContext(self.context), 0, 0);
    var ptr_gep_idx = [_]c.LLVMValueRef{ zero_idx, phi_i };
    const part_ptr_ptr = c.LLVMBuildGEP2(self.builder, ptrs_arr_type, ptrs_buf, &ptr_gep_idx, 2, "");
    const part_ptr = c.LLVMBuildLoad2(self.builder, ptr_type, part_ptr_ptr, "part.ptr");
    var len_gep_idx = [_]c.LLVMValueRef{ zero_idx, phi_i };
    const part_len_ptr = c.LLVMBuildGEP2(self.builder, lens_arr_type, lens_buf, &len_gep_idx, 2, "");
    const part_len = c.LLVMBuildLoad2(self.builder, i64_type, part_len_ptr, "part.len");

    // Build str value and push to Vec
    const str_val = self.buildStrValue(part_ptr, part_len);
    _ = try self.genVecPush(vec_alloca, vec_info.llvm_type, str_val);

    // After push, the builder may be in a different BB (due to grow/push blocks)
    const after_push_bb = c.LLVMGetInsertBlock(self.builder);
    const next_i = c.LLVMBuildAdd(self.builder, phi_i, c.LLVMConstInt(i64_type, 1, 0), "");
    _ = c.LLVMBuildBr(self.builder, loop_bb);
    var phi_vals = [_]c.LLVMValueRef{ c.LLVMConstInt(i64_type, 0, 0), next_i };
    var phi_bbs = [_]c.LLVMBasicBlockRef{ entry_bb, after_push_bb };
    c.LLVMAddIncoming(phi_i, &phi_vals, &phi_bbs, 2);

    c.LLVMPositionBuilderAtEnd(self.builder, done_bb);
    return c.LLVMBuildLoad2(self.builder, vec_info.llvm_type, vec_alloca, "split.result");
}

/// Ensure with_str_split helper is declared.
fn ensureSplitHelperDeclared(self: *Codegen) FnInfo {
    const sym = self.pool.intern("with_str_split") catch unreachable;
    if (self.functions.get(sym)) |fi| return fi;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    // int64_t with_str_split(const char*, int64_t, const char*, int64_t, void**, int64_t*, int64_t)
    var param_types = [_]c.LLVMTypeRef{ ptr_type, i64_type, ptr_type, i64_type, ptr_type, ptr_type, i64_type };
    const fn_type = c.LLVMFunctionType(i64_type, &param_types, 7, 0);
    const func = c.LLVMAddFunction(self.module, "with_str_split", fn_type);
    const fi: FnInfo = .{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, sym, fi) catch {};
    return fi;
}

/// str.replace(old, new) → new str — simple search and replace.
fn genStrReplace(self: *Codegen, obj_val: c.LLVMValueRef, old_s: c.LLVMValueRef, new_s: c.LLVMValueRef) Error!c.LLVMValueRef {
    // Split by old, then join with new
    const parts_vec = try self.genStrSplit(obj_val, old_s);
    return self.genVecJoin(parts_vec, new_s);
}

/// Vec[str].join(sep) → str — calls with_str_join C helper.
fn genVecJoin(self: *Codegen, vec_val: c.LLVMValueRef, sep: c.LLVMValueRef) Error!c.LLVMValueRef {
    const str_sym = self.pool.intern("str") catch return error.CodegenAlloc;
    const str_info = self.struct_types.get(str_sym) orelse return error.UnsupportedExpr;
    const vec_info = try self.getOrCreateVecType(str_info.llvm_type);
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);

    // Extract Vec fields: ptr, len
    const vec_alloca = c.LLVMBuildAlloca(self.builder, vec_info.llvm_type, "jv");
    _ = c.LLVMBuildStore(self.builder, vec_val, vec_alloca);
    const vec_ptr_gep = c.LLVMBuildStructGEP2(self.builder, vec_info.llvm_type, vec_alloca, 0, "");
    const vec_ptr = c.LLVMBuildLoad2(self.builder, ptr_type, vec_ptr_gep, "v.ptr");
    const vec_len_gep = c.LLVMBuildStructGEP2(self.builder, vec_info.llvm_type, vec_alloca, 1, "");
    const vec_len = c.LLVMBuildLoad2(self.builder, i64_type, vec_len_gep, "v.len");

    // Extract sep ptr and len
    const sep_info = self.extractStrPtrAndLen(sep);

    // Build arrays of ptrs and lens from Vec[str] elements.
    // Each str element is { ptr, i64 }, so we need to extract those.
    // Allocate temp arrays for ptrs and lens
    const max_parts: u64 = 256;
    const ptrs_arr_type = c.LLVMArrayType2(ptr_type, max_parts);
    const lens_arr_type = c.LLVMArrayType2(i64_type, max_parts);
    const ptrs_buf = c.LLVMBuildAlloca(self.builder, ptrs_arr_type, "j_ptrs");
    const lens_buf = c.LLVMBuildAlloca(self.builder, lens_arr_type, "j_lens");

    // Loop: extract ptr+len from each str in the Vec
    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const loop_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "join.loop");
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "join.body");
    const done_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "join.done");
    const entry_bb = c.LLVMGetInsertBlock(self.builder);
    _ = c.LLVMBuildBr(self.builder, loop_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, loop_bb);
    const phi_i = c.LLVMBuildPhi(self.builder, i64_type, "i");
    const at_end = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, phi_i, vec_len, "");
    _ = c.LLVMBuildCondBr(self.builder, at_end, done_bb, body_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
    // Load str element from Vec
    var elem_gep_idx = [_]c.LLVMValueRef{phi_i};
    const elem_ptr = c.LLVMBuildGEP2(self.builder, str_info.llvm_type, vec_ptr, &elem_gep_idx, 1, "");
    const str_val = c.LLVMBuildLoad2(self.builder, str_info.llvm_type, elem_ptr, "str_elem");
    const str_parts = self.extractStrPtrAndLen(str_val);
    // Store ptr and len into temp arrays
    const zero_idx = c.LLVMConstInt(i64_type, 0, 0);
    var ptr_gep = [_]c.LLVMValueRef{ zero_idx, phi_i };
    const ptr_slot = c.LLVMBuildGEP2(self.builder, ptrs_arr_type, ptrs_buf, &ptr_gep, 2, "");
    _ = c.LLVMBuildStore(self.builder, str_parts.ptr, ptr_slot);
    var len_gep = [_]c.LLVMValueRef{ zero_idx, phi_i };
    const len_slot = c.LLVMBuildGEP2(self.builder, lens_arr_type, lens_buf, &len_gep, 2, "");
    _ = c.LLVMBuildStore(self.builder, str_parts.len, len_slot);

    const next_i = c.LLVMBuildAdd(self.builder, phi_i, c.LLVMConstInt(i64_type, 1, 0), "");
    _ = c.LLVMBuildBr(self.builder, loop_bb);
    var phi_vals = [_]c.LLVMValueRef{ c.LLVMConstInt(i64_type, 0, 0), next_i };
    var phi_bbs = [_]c.LLVMBasicBlockRef{ entry_bb, body_bb };
    c.LLVMAddIncoming(phi_i, &phi_vals, &phi_bbs, 2);

    // Call with_str_join
    c.LLVMPositionBuilderAtEnd(self.builder, done_bb);
    const join_fn = self.ensureJoinHelperDeclared();
    const out_len_slot = c.LLVMBuildAlloca(self.builder, i64_type, "out_len");
    var join_args = [_]c.LLVMValueRef{ ptrs_buf, lens_buf, vec_len, sep_info.ptr, sep_info.len, out_len_slot };
    const result_ptr = c.LLVMBuildCall2(self.builder, join_fn.fn_type, join_fn.value, &join_args, 6, "joined");
    const result_len = c.LLVMBuildLoad2(self.builder, i64_type, out_len_slot, "joined.len");
    return self.buildStrValue(result_ptr, result_len);
}

/// Ensure with_str_join helper is declared.
fn ensureJoinHelperDeclared(self: *Codegen) FnInfo {
    const sym = self.pool.intern("with_str_join") catch unreachable;
    if (self.functions.get(sym)) |fi| return fi;
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    // char* with_str_join(void**, int64_t*, int64_t, const char*, int64_t, int64_t*)
    var param_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type, i64_type, ptr_type, i64_type, ptr_type };
    const fn_type = c.LLVMFunctionType(ptr_type, &param_types, 6, 0);
    const func = c.LLVMAddFunction(self.module, "with_str_join", fn_type);
    const fi: FnInfo = .{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, sym, fi) catch {};
    return fi;
}

/// Vec[T].fold(init, fn(acc, elem) -> acc) -> acc
fn genVecFold(self: *Codegen, vec_val: c.LLVMValueRef, vec_type: c.LLVMTypeRef, init_val: c.LLVMValueRef, fn_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const elem_type = self.getVecElemType(vec_type) orelse return error.UnsupportedExpr;
    const acc_type = c.LLVMTypeOf(init_val);

    // Extract Vec data_ptr and len.
    const vec_alloca = c.LLVMBuildAlloca(self.builder, vec_type, "fold.vec");
    _ = c.LLVMBuildStore(self.builder, vec_val, vec_alloca);
    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 0, "");
    const data_ptr = c.LLVMBuildLoad2(self.builder, c.LLVMPointerTypeInContext(self.context, 0), ptr_gep, "data");
    const len_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 1, "");
    const vec_len = c.LLVMBuildLoad2(self.builder, i64_type, len_gep, "len");

    // Create loop: idx alloca, acc alloca.
    const idx_alloca = c.LLVMBuildAlloca(self.builder, i64_type, "fold.idx");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i64_type, 0, 0), idx_alloca);
    const acc_alloca = c.LLVMBuildAlloca(self.builder, acc_type, "fold.acc");
    _ = c.LLVMBuildStore(self.builder, init_val, acc_alloca);

    const function = self.current_function;
    const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "fold.cond");
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "fold.body");
    const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "fold.end");
    _ = c.LLVMBuildBr(self.builder, cond_bb);

    // Condition: idx < len.
    c.LLVMPositionBuilderAtEnd(self.builder, cond_bb);
    const idx = c.LLVMBuildLoad2(self.builder, i64_type, idx_alloca, "idx");
    const cond = c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, idx, vec_len, "fold.cmp");
    _ = c.LLVMBuildCondBr(self.builder, cond, body_bb, end_bb);

    // Body: load elem, call fn(acc, elem), store result, inc idx.
    c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
    var gep_idx = [_]c.LLVMValueRef{idx};
    const elem_ptr = c.LLVMBuildGEP2(self.builder, elem_type, data_ptr, &gep_idx, 1, "elem.ptr");
    const elem = c.LLVMBuildLoad2(self.builder, elem_type, elem_ptr, "elem");
    const acc = c.LLVMBuildLoad2(self.builder, acc_type, acc_alloca, "acc");

    // Call fn_val(acc, elem).
    const fn_val_type = c.LLVMTypeOf(fn_val);
    const fn_kind = c.LLVMGetTypeKind(fn_val_type);
    const call_result = if (fn_kind == c.LLVMStructTypeKind) blk: {
        // Fat pointer closure: {fn_ptr, cap_ptr}
        const fn_ptr = c.LLVMBuildExtractValue(self.builder, fn_val, 0, "fn_ptr");
        const cap_ptr = c.LLVMBuildExtractValue(self.builder, fn_val, 1, "cap_ptr");
        const val_kind = c.LLVMGetValueKind(fn_ptr);
        if (val_kind == c.LLVMFunctionValueKind) {
            const ft = c.LLVMGlobalGetValueType(fn_ptr);
            var call_args = [_]c.LLVMValueRef{ cap_ptr, acc, elem };
            break :blk c.LLVMBuildCall2(self.builder, ft, fn_ptr, &call_args, 3, "fold.r");
        }
        const ptr_t = c.LLVMPointerTypeInContext(self.context, 0);
        var pt = [_]c.LLVMTypeRef{ ptr_t, acc_type, elem_type };
        const ft = c.LLVMFunctionType(acc_type, &pt, 3, 0);
        var call_args = [_]c.LLVMValueRef{ cap_ptr, acc, elem };
        break :blk c.LLVMBuildCall2(self.builder, ft, fn_ptr, &call_args, 3, "fold.r");
    } else blk: {
        // Regular function pointer.
        const val_kind = c.LLVMGetValueKind(fn_val);
        if (val_kind == c.LLVMFunctionValueKind) {
            const ft = c.LLVMGlobalGetValueType(fn_val);
            var call_args = [_]c.LLVMValueRef{ acc, elem };
            break :blk c.LLVMBuildCall2(self.builder, ft, fn_val, &call_args, 2, "fold.r");
        }
        var pt = [_]c.LLVMTypeRef{ acc_type, elem_type };
        const ft = c.LLVMFunctionType(acc_type, &pt, 2, 0);
        var call_args = [_]c.LLVMValueRef{ acc, elem };
        break :blk c.LLVMBuildCall2(self.builder, ft, fn_val, &call_args, 2, "fold.r");
    };
    _ = c.LLVMBuildStore(self.builder, call_result, acc_alloca);
    const next_idx = c.LLVMBuildAdd(self.builder, idx, c.LLVMConstInt(i64_type, 1, 0), "inc");
    _ = c.LLVMBuildStore(self.builder, next_idx, idx_alloca);
    _ = c.LLVMBuildBr(self.builder, cond_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
    return c.LLVMBuildLoad2(self.builder, acc_type, acc_alloca, "fold.result");
}

/// Vec[T].map(fn(elem) -> U) -> Vec[U]
fn genVecMap(self: *Codegen, vec_val: c.LLVMValueRef, vec_type: c.LLVMTypeRef, fn_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const elem_type = self.getVecElemType(vec_type) orelse return error.UnsupportedExpr;

    // Extract Vec data_ptr and len.
    const vec_alloca = c.LLVMBuildAlloca(self.builder, vec_type, "map.vec");
    _ = c.LLVMBuildStore(self.builder, vec_val, vec_alloca);
    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 0, "");
    const data_ptr = c.LLVMBuildLoad2(self.builder, c.LLVMPointerTypeInContext(self.context, 0), ptr_gep, "data");
    const len_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 1, "");
    const vec_len = c.LLVMBuildLoad2(self.builder, i64_type, len_gep, "len");

    // Infer result element type from callable signature (fn(T) -> U).
    const result_elem_type = self.inferUnaryFnReturnType(fn_val) orelse elem_type;
    const result_vec_info = try self.getOrCreateVecType(result_elem_type);

    // Create result Vec.
    const result_alloca = c.LLVMBuildAlloca(self.builder, result_vec_info.llvm_type, "map.result");
    const new_vec = try self.genVecNew(result_elem_type);
    _ = c.LLVMBuildStore(self.builder, new_vec, result_alloca);

    // Loop over input vec.
    const idx_alloca = c.LLVMBuildAlloca(self.builder, i64_type, "map.idx");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i64_type, 0, 0), idx_alloca);

    const function = self.current_function;
    const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "map.cond");
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "map.body");
    const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "map.end");
    _ = c.LLVMBuildBr(self.builder, cond_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, cond_bb);
    const idx = c.LLVMBuildLoad2(self.builder, i64_type, idx_alloca, "idx");
    const cond = c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, idx, vec_len, "map.cmp");
    _ = c.LLVMBuildCondBr(self.builder, cond, body_bb, end_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
    var gep_idx = [_]c.LLVMValueRef{idx};
    const elem_ptr = c.LLVMBuildGEP2(self.builder, elem_type, data_ptr, &gep_idx, 1, "elem.ptr");
    const elem = c.LLVMBuildLoad2(self.builder, elem_type, elem_ptr, "elem");

    // Call fn_val(elem).
    const mapped = try self.callFnValueWithArg(fn_val, elem);
    _ = try self.genVecPush(result_alloca, result_vec_info.llvm_type, mapped);

    const next_idx = c.LLVMBuildAdd(self.builder, idx, c.LLVMConstInt(i64_type, 1, 0), "inc");
    _ = c.LLVMBuildStore(self.builder, next_idx, idx_alloca);
    _ = c.LLVMBuildBr(self.builder, cond_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
    return c.LLVMBuildLoad2(self.builder, result_vec_info.llvm_type, result_alloca, "map.result");
}

/// Convert a slice `{ptr,len}` into a Vec with copied elements.
fn genSliceToVec(self: *Codegen, slice_val: c.LLVMValueRef, elem_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const vec_info = try self.getOrCreateVecType(elem_type);

    const result_alloca = c.LLVMBuildAlloca(self.builder, vec_info.llvm_type, "slice.vec");
    const new_vec = try self.genVecNew(elem_type);
    _ = c.LLVMBuildStore(self.builder, new_vec, result_alloca);

    const data_ptr = c.LLVMBuildExtractValue(self.builder, slice_val, 0, "slice.ptr");
    const len = c.LLVMBuildExtractValue(self.builder, slice_val, 1, "slice.len");
    const idx_alloca = c.LLVMBuildAlloca(self.builder, i64_type, "slice.idx");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i64_type, 0, 0), idx_alloca);

    const function = self.current_function;
    const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "slice2vec.cond");
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "slice2vec.body");
    const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "slice2vec.end");
    _ = c.LLVMBuildBr(self.builder, cond_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, cond_bb);
    const idx = c.LLVMBuildLoad2(self.builder, i64_type, idx_alloca, "idx");
    const cond = c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, idx, len, "slice2vec.cmp");
    _ = c.LLVMBuildCondBr(self.builder, cond, body_bb, end_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
    var gep_idx = [_]c.LLVMValueRef{idx};
    const elem_ptr = c.LLVMBuildGEP2(self.builder, elem_type, data_ptr, &gep_idx, 1, "slice.elem.ptr");
    const elem = c.LLVMBuildLoad2(self.builder, elem_type, elem_ptr, "slice.elem");
    _ = try self.genVecPush(result_alloca, vec_info.llvm_type, elem);

    const next_idx = c.LLVMBuildAdd(self.builder, idx, c.LLVMConstInt(i64_type, 1, 0), "inc");
    _ = c.LLVMBuildStore(self.builder, next_idx, idx_alloca);
    _ = c.LLVMBuildBr(self.builder, cond_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
    return c.LLVMBuildLoad2(self.builder, vec_info.llvm_type, result_alloca, "slice.vec.out");
}

/// Vec[T].filter(fn(elem) -> bool) -> Vec[T]
fn genVecFilter(self: *Codegen, vec_val: c.LLVMValueRef, vec_type: c.LLVMTypeRef, fn_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const elem_type = self.getVecElemType(vec_type) orelse return error.UnsupportedExpr;
    const vec_info = try self.getOrCreateVecType(elem_type);

    // Extract Vec data_ptr and len.
    const vec_alloca = c.LLVMBuildAlloca(self.builder, vec_type, "filt.vec");
    _ = c.LLVMBuildStore(self.builder, vec_val, vec_alloca);
    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 0, "");
    const data_ptr = c.LLVMBuildLoad2(self.builder, c.LLVMPointerTypeInContext(self.context, 0), ptr_gep, "data");
    const len_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 1, "");
    const vec_len = c.LLVMBuildLoad2(self.builder, i64_type, len_gep, "len");

    // Create result Vec.
    const result_alloca = c.LLVMBuildAlloca(self.builder, vec_info.llvm_type, "filt.result");
    const new_vec = try self.genVecNew(elem_type);
    _ = c.LLVMBuildStore(self.builder, new_vec, result_alloca);

    // Loop.
    const idx_alloca = c.LLVMBuildAlloca(self.builder, i64_type, "filt.idx");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i64_type, 0, 0), idx_alloca);

    const function = self.current_function;
    const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "filt.cond");
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "filt.body");
    const push_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "filt.push");
    const skip_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "filt.skip");
    const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "filt.end");
    _ = c.LLVMBuildBr(self.builder, cond_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, cond_bb);
    const idx = c.LLVMBuildLoad2(self.builder, i64_type, idx_alloca, "idx");
    const cond = c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, idx, vec_len, "filt.cmp");
    _ = c.LLVMBuildCondBr(self.builder, cond, body_bb, end_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
    var gep_idx = [_]c.LLVMValueRef{idx};
    const elem_ptr = c.LLVMBuildGEP2(self.builder, elem_type, data_ptr, &gep_idx, 1, "elem.ptr");
    const elem = c.LLVMBuildLoad2(self.builder, elem_type, elem_ptr, "elem");

    // Call fn_val(elem) -> bool.
    const pred_result = try self.callFnValueWithArg(fn_val, elem);
    // Truncate to i1 if needed.
    const i1_type = c.LLVMInt1TypeInContext(self.context);
    const pred_bool = if (c.LLVMTypeOf(pred_result) != i1_type)
        c.LLVMBuildTrunc(self.builder, pred_result, i1_type, "pred")
    else
        pred_result;
    _ = c.LLVMBuildCondBr(self.builder, pred_bool, push_bb, skip_bb);

    // Push element if predicate is true.
    c.LLVMPositionBuilderAtEnd(self.builder, push_bb);
    _ = try self.genVecPush(result_alloca, vec_info.llvm_type, elem);
    _ = c.LLVMBuildBr(self.builder, skip_bb);

    // Increment and loop.
    c.LLVMPositionBuilderAtEnd(self.builder, skip_bb);
    const next_idx = c.LLVMBuildAdd(self.builder, idx, c.LLVMConstInt(i64_type, 1, 0), "inc");
    _ = c.LLVMBuildStore(self.builder, next_idx, idx_alloca);
    _ = c.LLVMBuildBr(self.builder, cond_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
    return c.LLVMBuildLoad2(self.builder, vec_info.llvm_type, result_alloca, "filt.result");
}

/// Vec[Option[T]].sequence() -> Option[Vec[T]]
/// Vec[Result[T, E]].sequence() -> Result[Vec[T], E]
fn genVecSequence(self: *Codegen, vec_val: c.LLVMValueRef, vec_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const elem_type = self.getVecElemType(vec_type) orelse return error.UnsupportedExpr;

    // Extract Vec data_ptr and len.
    const vec_alloca = c.LLVMBuildAlloca(self.builder, vec_type, "seq.vec");
    _ = c.LLVMBuildStore(self.builder, vec_val, vec_alloca);
    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 0, "");
    const data_ptr = c.LLVMBuildLoad2(self.builder, c.LLVMPointerTypeInContext(self.context, 0), ptr_gep, "data");
    const len_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 1, "");
    const vec_len = c.LLVMBuildLoad2(self.builder, i64_type, len_gep, "len");
    const idx_alloca = c.LLVMBuildAlloca(self.builder, i64_type, "seq.idx");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i64_type, 0, 0), idx_alloca);

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;

    if (self.isOptionType(elem_type)) {
        const payload_type = self.getOptionPayloadType(elem_type) orelse return error.UnsupportedExpr;
        const out_vec_info = try self.getOrCreateVecType(payload_type);
        const out_opt_info = try self.getOrCreateOptionType(out_vec_info.llvm_type);

        const out_vec_alloca = c.LLVMBuildAlloca(self.builder, out_vec_info.llvm_type, "seq.out.vec");
        const empty_vec = try self.genVecNew(payload_type);
        _ = c.LLVMBuildStore(self.builder, empty_vec, out_vec_alloca);
        const ret_alloca = c.LLVMBuildAlloca(self.builder, out_opt_info.llvm_type, "seq.ret");

        const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "seq.opt.cond");
        const body_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "seq.opt.body");
        const some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "seq.opt.some");
        const none_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "seq.opt.none");
        const done_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "seq.opt.done");
        const end_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "seq.opt.end");
        _ = c.LLVMBuildBr(self.builder, cond_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, cond_bb);
        const idx = c.LLVMBuildLoad2(self.builder, i64_type, idx_alloca, "idx");
        const has_more = c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, idx, vec_len, "seq.opt.has_more");
        _ = c.LLVMBuildCondBr(self.builder, has_more, body_bb, done_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
        var elem_idx = [_]c.LLVMValueRef{idx};
        const elem_ptr = c.LLVMBuildGEP2(self.builder, elem_type, data_ptr, &elem_idx, 1, "seq.elem.ptr");
        const elem_val = c.LLVMBuildLoad2(self.builder, elem_type, elem_ptr, "seq.elem");
        const elem_alloca = c.LLVMBuildAlloca(self.builder, elem_type, "seq.elem.alloca");
        _ = c.LLVMBuildStore(self.builder, elem_val, elem_alloca);
        const tag_gep = c.LLVMBuildStructGEP2(self.builder, elem_type, elem_alloca, 0, "seq.tag");
        const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "seq.tag.val");
        const is_some = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "seq.is_some");
        _ = c.LLVMBuildCondBr(self.builder, is_some, some_bb, none_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, some_bb);
        const payload_gep = c.LLVMBuildStructGEP2(self.builder, elem_type, elem_alloca, 1, "seq.payload");
        const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
        const payload_val = c.LLVMBuildLoad2(self.builder, payload_type, payload_ptr, "seq.payload.val");
        _ = try self.genVecPush(out_vec_alloca, out_vec_info.llvm_type, payload_val);
        const next_idx = c.LLVMBuildAdd(self.builder, idx, c.LLVMConstInt(i64_type, 1, 0), "seq.next");
        _ = c.LLVMBuildStore(self.builder, next_idx, idx_alloca);
        _ = c.LLVMBuildBr(self.builder, cond_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, none_bb);
        const none_val = self.buildOptionNone(out_opt_info.llvm_type);
        _ = c.LLVMBuildStore(self.builder, none_val, ret_alloca);
        _ = c.LLVMBuildBr(self.builder, end_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, done_bb);
        const out_vec = c.LLVMBuildLoad2(self.builder, out_vec_info.llvm_type, out_vec_alloca, "seq.out.vec.val");
        const some_val = try self.buildOptionSome(out_vec);
        _ = c.LLVMBuildStore(self.builder, some_val, ret_alloca);
        _ = c.LLVMBuildBr(self.builder, end_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
        return c.LLVMBuildLoad2(self.builder, out_opt_info.llvm_type, ret_alloca, "seq.opt.result");
    }

    if (self.isResultType(elem_type)) {
        const ok_type = self.getOptionPayloadType(elem_type) orelse return error.UnsupportedExpr;
        const err_type = self.getResultErrType(elem_type) orelse return error.UnsupportedExpr;
        const out_vec_info = try self.getOrCreateVecType(ok_type);
        const out_res_info = try self.getOrCreateResultType(out_vec_info.llvm_type, err_type);

        const out_vec_alloca = c.LLVMBuildAlloca(self.builder, out_vec_info.llvm_type, "seq.out.vec");
        const empty_vec = try self.genVecNew(ok_type);
        _ = c.LLVMBuildStore(self.builder, empty_vec, out_vec_alloca);
        const ret_alloca = c.LLVMBuildAlloca(self.builder, out_res_info.llvm_type, "seq.ret");

        const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "seq.res.cond");
        const body_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "seq.res.body");
        const ok_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "seq.res.ok");
        const err_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "seq.res.err");
        const done_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "seq.res.done");
        const end_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "seq.res.end");
        _ = c.LLVMBuildBr(self.builder, cond_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, cond_bb);
        const idx = c.LLVMBuildLoad2(self.builder, i64_type, idx_alloca, "idx");
        const has_more = c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, idx, vec_len, "seq.res.has_more");
        _ = c.LLVMBuildCondBr(self.builder, has_more, body_bb, done_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
        var elem_idx = [_]c.LLVMValueRef{idx};
        const elem_ptr = c.LLVMBuildGEP2(self.builder, elem_type, data_ptr, &elem_idx, 1, "seq.elem.ptr");
        const elem_val = c.LLVMBuildLoad2(self.builder, elem_type, elem_ptr, "seq.elem");
        const elem_alloca = c.LLVMBuildAlloca(self.builder, elem_type, "seq.elem.alloca");
        _ = c.LLVMBuildStore(self.builder, elem_val, elem_alloca);
        const tag_gep = c.LLVMBuildStructGEP2(self.builder, elem_type, elem_alloca, 0, "seq.tag");
        const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "seq.tag.val");
        const is_ok = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "seq.is_ok");
        _ = c.LLVMBuildCondBr(self.builder, is_ok, ok_bb, err_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, ok_bb);
        const payload_gep = c.LLVMBuildStructGEP2(self.builder, elem_type, elem_alloca, 1, "seq.payload");
        const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
        const payload_val = c.LLVMBuildLoad2(self.builder, ok_type, payload_ptr, "seq.payload.val");
        _ = try self.genVecPush(out_vec_alloca, out_vec_info.llvm_type, payload_val);
        const next_idx = c.LLVMBuildAdd(self.builder, idx, c.LLVMConstInt(i64_type, 1, 0), "seq.next");
        _ = c.LLVMBuildStore(self.builder, next_idx, idx_alloca);
        _ = c.LLVMBuildBr(self.builder, cond_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, err_bb);
        const err_gep = c.LLVMBuildStructGEP2(self.builder, elem_type, elem_alloca, 1, "seq.err");
        const err_ptr = c.LLVMBuildBitCast(self.builder, err_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
        const err_val = c.LLVMBuildLoad2(self.builder, err_type, err_ptr, "seq.err.val");
        const err_result = try self.buildResultErr(err_val, out_res_info.llvm_type);
        _ = c.LLVMBuildStore(self.builder, err_result, ret_alloca);
        _ = c.LLVMBuildBr(self.builder, end_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, done_bb);
        const out_vec = c.LLVMBuildLoad2(self.builder, out_vec_info.llvm_type, out_vec_alloca, "seq.out.vec.val");
        const ok_result = try self.buildResultOk(out_vec, out_res_info.llvm_type);
        _ = c.LLVMBuildStore(self.builder, ok_result, ret_alloca);
        _ = c.LLVMBuildBr(self.builder, end_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
        return c.LLVMBuildLoad2(self.builder, out_res_info.llvm_type, ret_alloca, "seq.res.result");
    }

    return error.UnsupportedExpr;
}

/// Vec[T].traverse(f) — map each element with f then sequence.
fn genVecTraverse(self: *Codegen, vec_val: c.LLVMValueRef, vec_type: c.LLVMTypeRef, fn_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const elem_type = self.getVecElemType(vec_type) orelse return error.UnsupportedExpr;
    const mapped_type = self.inferUnaryFnReturnType(fn_val) orelse return error.UnsupportedExpr;

    // Extract Vec data_ptr and len.
    const vec_alloca = c.LLVMBuildAlloca(self.builder, vec_type, "trav.vec");
    _ = c.LLVMBuildStore(self.builder, vec_val, vec_alloca);
    const ptr_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 0, "");
    const data_ptr = c.LLVMBuildLoad2(self.builder, c.LLVMPointerTypeInContext(self.context, 0), ptr_gep, "data");
    const len_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, vec_alloca, 1, "");
    const vec_len = c.LLVMBuildLoad2(self.builder, i64_type, len_gep, "len");
    const idx_alloca = c.LLVMBuildAlloca(self.builder, i64_type, "trav.idx");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i64_type, 0, 0), idx_alloca);

    const cur_fn = self.current_function orelse return error.UnsupportedExpr;

    if (self.isOptionType(mapped_type)) {
        const payload_type = self.getOptionPayloadType(mapped_type) orelse return error.UnsupportedExpr;
        const out_vec_info = try self.getOrCreateVecType(payload_type);
        const out_opt_info = try self.getOrCreateOptionType(out_vec_info.llvm_type);

        const out_vec_alloca = c.LLVMBuildAlloca(self.builder, out_vec_info.llvm_type, "trav.out.vec");
        const empty_vec = try self.genVecNew(payload_type);
        _ = c.LLVMBuildStore(self.builder, empty_vec, out_vec_alloca);
        const ret_alloca = c.LLVMBuildAlloca(self.builder, out_opt_info.llvm_type, "trav.ret");

        const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trav.opt.cond");
        const body_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trav.opt.body");
        const some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trav.opt.some");
        const none_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trav.opt.none");
        const done_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trav.opt.done");
        const end_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trav.opt.end");
        _ = c.LLVMBuildBr(self.builder, cond_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, cond_bb);
        const idx = c.LLVMBuildLoad2(self.builder, i64_type, idx_alloca, "idx");
        const has_more = c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, idx, vec_len, "trav.opt.has_more");
        _ = c.LLVMBuildCondBr(self.builder, has_more, body_bb, done_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
        var elem_idx = [_]c.LLVMValueRef{idx};
        const elem_ptr = c.LLVMBuildGEP2(self.builder, elem_type, data_ptr, &elem_idx, 1, "trav.elem.ptr");
        const elem_val = c.LLVMBuildLoad2(self.builder, elem_type, elem_ptr, "trav.elem");
        const mapped_val = try self.callFnValueWithArg(fn_val, elem_val);
        const mapped_val_type = c.LLVMTypeOf(mapped_val);
        if (!self.isOptionType(mapped_val_type)) return error.UnsupportedExpr;
        const mapped_alloca = c.LLVMBuildAlloca(self.builder, mapped_val_type, "trav.mapped");
        _ = c.LLVMBuildStore(self.builder, mapped_val, mapped_alloca);
        const tag_gep = c.LLVMBuildStructGEP2(self.builder, mapped_val_type, mapped_alloca, 0, "trav.tag");
        const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "trav.tag.val");
        const is_some = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "trav.is_some");
        _ = c.LLVMBuildCondBr(self.builder, is_some, some_bb, none_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, some_bb);
        const mapped_payload_type = self.getOptionPayloadType(mapped_val_type) orelse return error.UnsupportedExpr;
        if (mapped_payload_type != payload_type and !self.sameStructTypeName(mapped_payload_type, payload_type)) {
            return error.UnsupportedExpr;
        }
        const payload_gep = c.LLVMBuildStructGEP2(self.builder, mapped_val_type, mapped_alloca, 1, "trav.payload");
        const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
        const payload_val = c.LLVMBuildLoad2(self.builder, payload_type, payload_ptr, "trav.payload.val");
        _ = try self.genVecPush(out_vec_alloca, out_vec_info.llvm_type, payload_val);
        const next_idx = c.LLVMBuildAdd(self.builder, idx, c.LLVMConstInt(i64_type, 1, 0), "trav.next");
        _ = c.LLVMBuildStore(self.builder, next_idx, idx_alloca);
        _ = c.LLVMBuildBr(self.builder, cond_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, none_bb);
        const none_val = self.buildOptionNone(out_opt_info.llvm_type);
        _ = c.LLVMBuildStore(self.builder, none_val, ret_alloca);
        _ = c.LLVMBuildBr(self.builder, end_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, done_bb);
        const out_vec = c.LLVMBuildLoad2(self.builder, out_vec_info.llvm_type, out_vec_alloca, "trav.out.vec.val");
        const some_val = try self.buildOptionSome(out_vec);
        _ = c.LLVMBuildStore(self.builder, some_val, ret_alloca);
        _ = c.LLVMBuildBr(self.builder, end_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
        return c.LLVMBuildLoad2(self.builder, out_opt_info.llvm_type, ret_alloca, "trav.opt.result");
    }

    if (self.isResultType(mapped_type)) {
        const ok_type = self.getOptionPayloadType(mapped_type) orelse return error.UnsupportedExpr;
        const err_type = self.getResultErrType(mapped_type) orelse return error.UnsupportedExpr;
        const out_vec_info = try self.getOrCreateVecType(ok_type);
        const out_res_info = try self.getOrCreateResultType(out_vec_info.llvm_type, err_type);

        const out_vec_alloca = c.LLVMBuildAlloca(self.builder, out_vec_info.llvm_type, "trav.out.vec");
        const empty_vec = try self.genVecNew(ok_type);
        _ = c.LLVMBuildStore(self.builder, empty_vec, out_vec_alloca);
        const ret_alloca = c.LLVMBuildAlloca(self.builder, out_res_info.llvm_type, "trav.ret");

        const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trav.res.cond");
        const body_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trav.res.body");
        const ok_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trav.res.ok");
        const err_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trav.res.err");
        const done_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trav.res.done");
        const end_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "trav.res.end");
        _ = c.LLVMBuildBr(self.builder, cond_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, cond_bb);
        const idx = c.LLVMBuildLoad2(self.builder, i64_type, idx_alloca, "idx");
        const has_more = c.LLVMBuildICmp(self.builder, c.LLVMIntSLT, idx, vec_len, "trav.res.has_more");
        _ = c.LLVMBuildCondBr(self.builder, has_more, body_bb, done_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
        var elem_idx = [_]c.LLVMValueRef{idx};
        const elem_ptr = c.LLVMBuildGEP2(self.builder, elem_type, data_ptr, &elem_idx, 1, "trav.elem.ptr");
        const elem_val = c.LLVMBuildLoad2(self.builder, elem_type, elem_ptr, "trav.elem");
        const mapped_val = try self.callFnValueWithArg(fn_val, elem_val);
        const mapped_val_type = c.LLVMTypeOf(mapped_val);
        if (!self.isResultType(mapped_val_type)) return error.UnsupportedExpr;
        const mapped_alloca = c.LLVMBuildAlloca(self.builder, mapped_val_type, "trav.mapped");
        _ = c.LLVMBuildStore(self.builder, mapped_val, mapped_alloca);
        const tag_gep = c.LLVMBuildStructGEP2(self.builder, mapped_val_type, mapped_alloca, 0, "trav.tag");
        const tag = c.LLVMBuildLoad2(self.builder, i32_type, tag_gep, "trav.tag.val");
        const is_ok = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(i32_type, 0, 0), "trav.is_ok");
        _ = c.LLVMBuildCondBr(self.builder, is_ok, ok_bb, err_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, ok_bb);
        const mapped_ok_type = self.getOptionPayloadType(mapped_val_type) orelse return error.UnsupportedExpr;
        const mapped_err_type = self.getResultErrType(mapped_val_type) orelse return error.UnsupportedExpr;
        if ((mapped_ok_type != ok_type and !self.sameStructTypeName(mapped_ok_type, ok_type)) or
            (mapped_err_type != err_type and !self.sameStructTypeName(mapped_err_type, err_type)))
        {
            return error.UnsupportedExpr;
        }
        const payload_gep = c.LLVMBuildStructGEP2(self.builder, mapped_val_type, mapped_alloca, 1, "trav.payload");
        const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
        const payload_val = c.LLVMBuildLoad2(self.builder, ok_type, payload_ptr, "trav.payload.val");
        _ = try self.genVecPush(out_vec_alloca, out_vec_info.llvm_type, payload_val);
        const next_idx = c.LLVMBuildAdd(self.builder, idx, c.LLVMConstInt(i64_type, 1, 0), "trav.next");
        _ = c.LLVMBuildStore(self.builder, next_idx, idx_alloca);
        _ = c.LLVMBuildBr(self.builder, cond_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, err_bb);
        const err_gep = c.LLVMBuildStructGEP2(self.builder, mapped_val_type, mapped_alloca, 1, "trav.err");
        const err_ptr = c.LLVMBuildBitCast(self.builder, err_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
        const err_val = c.LLVMBuildLoad2(self.builder, err_type, err_ptr, "trav.err.val");
        const err_result = try self.buildResultErr(err_val, out_res_info.llvm_type);
        _ = c.LLVMBuildStore(self.builder, err_result, ret_alloca);
        _ = c.LLVMBuildBr(self.builder, end_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, done_bb);
        const out_vec = c.LLVMBuildLoad2(self.builder, out_vec_info.llvm_type, out_vec_alloca, "trav.out.vec.val");
        const ok_result = try self.buildResultOk(out_vec, out_res_info.llvm_type);
        _ = c.LLVMBuildStore(self.builder, ok_result, ret_alloca);
        _ = c.LLVMBuildBr(self.builder, end_bb);

        c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
        return c.LLVMBuildLoad2(self.builder, out_res_info.llvm_type, ret_alloca, "trav.res.result");
    }

    return error.UnsupportedExpr;
}

/// array.contains(needle) → bool — linear scan
fn genArrayContains(self: *Codegen, arr_val: c.LLVMValueRef, arr_type: c.LLVMTypeRef, needle: c.LLVMValueRef) Error!c.LLVMValueRef {
    const len = c.LLVMGetArrayLength2(arr_type);
    if (len == 0) return c.LLVMConstInt(c.LLVMInt1TypeInContext(self.context), 0, 0);
    // Unrolled: OR together (arr[i] == needle) for each i
    var result = c.LLVMConstInt(c.LLVMInt1TypeInContext(self.context), 0, 0);
    for (0..len) |i| {
        const elem = c.LLVMBuildExtractValue(self.builder, arr_val, @intCast(i), "elem");
        const eq = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, elem, needle, "eq");
        result = c.LLVMBuildOr(self.builder, result, eq, "");
    }
    return result;
}

/// array.reverse() → new array with elements in reverse order
fn genArrayReverse(self: *Codegen, arr_val: c.LLVMValueRef, arr_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const len = c.LLVMGetArrayLength2(arr_type);
    if (len == 0) return arr_val;
    var result = c.LLVMGetUndef(arr_type);
    for (0..len) |i| {
        const elem = c.LLVMBuildExtractValue(self.builder, arr_val, @intCast(len - 1 - i), "rev");
        result = c.LLVMBuildInsertValue(self.builder, result, elem, @intCast(i), "");
    }
    return result;
}

/// array.map(fn) → new array — applies fn to each element.
fn genArrayMap(self: *Codegen, arr_val: c.LLVMValueRef, arr_type: c.LLVMTypeRef, fn_val: c.LLVMValueRef) Error!c.LLVMValueRef {
    const len = c.LLVMGetArrayLength2(arr_type);
    if (len == 0) return arr_val;
    // Get the fn type to determine result element type.
    // fn_val is a function pointer — we need to call it with each element.
    const elem_type = c.LLVMGetElementType(arr_type);
    // Call fn_val(elem) for first element to determine return type.
    const first = c.LLVMBuildExtractValue(self.builder, arr_val, 0, "elem");
    var call_args = [_]c.LLVMValueRef{first};
    // Build fn type: (elem_type) -> result_type; assume same type for now
    var map_param_types = [_]c.LLVMTypeRef{elem_type};
    const fn_type = c.LLVMFunctionType(elem_type, &map_param_types, 1, 0);
    const first_result = c.LLVMBuildCall2(self.builder, fn_type, fn_val, &call_args, 1, "map.r");
    const result_elem_type = c.LLVMTypeOf(first_result);
    const result_arr_type = c.LLVMArrayType2(result_elem_type, len);
    var result = c.LLVMGetUndef(result_arr_type);
    result = c.LLVMBuildInsertValue(self.builder, result, first_result, 0, "");
    for (1..len) |i| {
        const elem = c.LLVMBuildExtractValue(self.builder, arr_val, @intCast(i), "elem");
        var args = [_]c.LLVMValueRef{elem};
        const r = c.LLVMBuildCall2(self.builder, fn_type, fn_val, &args, 1, "map.r");
        result = c.LLVMBuildInsertValue(self.builder, result, r, @intCast(i), "");
    }
    return result;
}

/// array.reduce(fn, init) → T — fold array with binary function.
fn genArrayReduce(self: *Codegen, arr_val: c.LLVMValueRef, arr_type: c.LLVMTypeRef, fn_val: c.LLVMValueRef, initial: c.LLVMValueRef) Error!c.LLVMValueRef {
    const len = c.LLVMGetArrayLength2(arr_type);
    if (len == 0) return initial;
    const elem_type = c.LLVMGetElementType(arr_type);
    const acc_type = c.LLVMTypeOf(initial);
    // Build fn type: (acc, elem) -> acc
    var param_types = [_]c.LLVMTypeRef{ acc_type, elem_type };
    const fn_type = c.LLVMFunctionType(acc_type, &param_types, 2, 0);
    var acc = initial;
    for (0..len) |i| {
        const elem = c.LLVMBuildExtractValue(self.builder, arr_val, @intCast(i), "elem");
        var call_args = [_]c.LLVMValueRef{ acc, elem };
        acc = c.LLVMBuildCall2(self.builder, fn_type, fn_val, &call_args, 2, "acc");
    }
    return acc;
}

/// array.sum() → T — sum all elements.
fn genArraySum(self: *Codegen, arr_val: c.LLVMValueRef, arr_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const len = c.LLVMGetArrayLength2(arr_type);
    const elem_type = c.LLVMGetElementType(arr_type);
    if (len == 0) return c.LLVMConstInt(elem_type, 0, 0);
    var acc = c.LLVMBuildExtractValue(self.builder, arr_val, 0, "sum");
    for (1..len) |i| {
        const elem = c.LLVMBuildExtractValue(self.builder, arr_val, @intCast(i), "elem");
        const kind = c.LLVMGetTypeKind(elem_type);
        if (kind == c.LLVMFloatTypeKind or kind == c.LLVMDoubleTypeKind) {
            acc = c.LLVMBuildFAdd(self.builder, acc, elem, "sum");
        } else {
            acc = c.LLVMBuildAdd(self.builder, acc, elem, "sum");
        }
    }
    return acc;
}

/// Ensure malloc is declared.
fn ensureMallocDeclared(self: *Codegen) FnInfo {
    const malloc_sym = self.pool.intern("malloc") catch unreachable;
    if (self.functions.get(malloc_sym)) |fi| return fi;
    if (c.LLVMGetNamedFunction(self.module, "malloc")) |func| {
        const fi_existing: FnInfo = .{
            .value = func,
            .fn_type = c.LLVMGlobalGetValueType(func),
        };
        self.functions.put(self.allocator, malloc_sym, fi_existing) catch {};
        return fi_existing;
    }
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    var param_types = [_]c.LLVMTypeRef{i64_type};
    const fn_type = c.LLVMFunctionType(ptr_type, &param_types, 1, 0);
    const func = c.LLVMAddFunction(self.module, "malloc", fn_type);
    const fi: FnInfo = .{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, malloc_sym, fi) catch {};
    return fi;
}

/// Ensure memcpy is declared.
fn ensureMemcpyDeclared(self: *Codegen) FnInfo {
    const memcpy_sym = self.pool.intern("memcpy") catch unreachable;
    if (self.functions.get(memcpy_sym)) |fi| return fi;
    if (c.LLVMGetNamedFunction(self.module, "memcpy")) |func| {
        const fi_existing: FnInfo = .{
            .value = func,
            .fn_type = c.LLVMGlobalGetValueType(func),
        };
        self.functions.put(self.allocator, memcpy_sym, fi_existing) catch {};
        return fi_existing;
    }
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    var param_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type, i64_type };
    const fn_type = c.LLVMFunctionType(ptr_type, &param_types, 3, 0);
    const func = c.LLVMAddFunction(self.module, "memcpy", fn_type);
    const fi: FnInfo = .{ .value = func, .fn_type = fn_type };
    self.functions.put(self.allocator, memcpy_sym, fi) catch {};
    return fi;
}

fn extractStrPtr(self: *Codegen, val: c.LLVMValueRef) c.LLVMValueRef {
    const str_sym = self.pool.intern("str") catch return val;
    const str_info = self.struct_types.get(str_sym) orelse return val;
    // Alloca, store the str value, GEP field 0 (ptr), load.
    const alloca = c.LLVMBuildAlloca(self.builder, str_info.llvm_type, "");
    _ = c.LLVMBuildStore(self.builder, val, alloca);
    const gep = c.LLVMBuildStructGEP2(self.builder, str_info.llvm_type, alloca, 0, "");
    return c.LLVMBuildLoad2(self.builder, c.LLVMPointerTypeInContext(self.context, 0), gep, "str.ptr");
}

// ── Type resolution ──────────────────────────────────────────────

fn resolveType(self: *Codegen, type_expr: *const Ast.TypeExpr) Error!c.LLVMTypeRef {
    return switch (type_expr.kind) {
        .named => |sym| {
            const name = self.pool.resolve(sym);
            if (std.mem.eql(u8, name, "i32")) return c.LLVMInt32TypeInContext(self.context);
            if (std.mem.eql(u8, name, "i64")) return c.LLVMInt64TypeInContext(self.context);
            if (std.mem.eql(u8, name, "i16")) return c.LLVMInt16TypeInContext(self.context);
            if (std.mem.eql(u8, name, "i8")) return c.LLVMInt8TypeInContext(self.context);
            if (std.mem.eql(u8, name, "u8")) return c.LLVMInt8TypeInContext(self.context);
            if (std.mem.eql(u8, name, "u16")) return c.LLVMInt16TypeInContext(self.context);
            if (std.mem.eql(u8, name, "u32")) return c.LLVMInt32TypeInContext(self.context);
            if (std.mem.eql(u8, name, "u64")) return c.LLVMInt64TypeInContext(self.context);
            if (std.mem.eql(u8, name, "bool")) return c.LLVMInt1TypeInContext(self.context);
            if (std.mem.eql(u8, name, "f64")) return c.LLVMDoubleTypeInContext(self.context);
            if (std.mem.eql(u8, name, "f32")) return c.LLVMFloatTypeInContext(self.context);
            if (std.mem.eql(u8, name, "void")) return c.LLVMVoidTypeInContext(self.context);
            if (std.mem.eql(u8, name, "Never")) return c.LLVMVoidTypeInContext(self.context);
            if (std.mem.eql(u8, name, "Unit")) return c.LLVMInt32TypeInContext(self.context);
            if (std.mem.eql(u8, name, "String") or std.mem.eql(u8, name, "StrView")) {
                const str_sym = self.pool.intern("str") catch return error.UnsupportedType;
                if (self.struct_types.get(str_sym)) |info| return info.llvm_type;
                return error.UnsupportedType;
            }
            // Look up user-defined struct types (includes built-in str).
            if (self.struct_types.get(sym)) |info| return info.llvm_type;
            // Look up user-defined enum types.
            if (self.enum_types.get(sym)) |info| return info.llvm_type;
            // Look up type aliases.
            if (self.type_aliases.get(sym)) |ty| return ty;
            return error.UnsupportedType;
        },
        .ptr_type => |pt| {
            // Pointer-to-dyn is represented as a trait-object fat pointer.
            if (dynTraitFromTypeExpr(self, pt.pointee) != null) {
                const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
                var fat_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
                return c.LLVMStructTypeInContext(self.context, &fat_types, 2, 0);
            }
            return c.LLVMPointerTypeInContext(self.context, 0);
        },
        .ref_type => |rt| {
            // `&dyn Trait` lowers to the same fat pointer representation as `dyn Trait`.
            if (dynTraitFromTypeExpr(self, rt.pointee) != null) {
                const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
                var fat_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
                return c.LLVMStructTypeInContext(self.context, &fat_types, 2, 0);
            }
            return c.LLVMPointerTypeInContext(self.context, 0);
        },
        .fn_type => {
            const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
            var fat_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
            return c.LLVMStructTypeInContext(self.context, &fat_types, 2, 0);
        },
        .array_type => |arr| {
            const elem = try self.resolveType(arr.element);
            return c.LLVMArrayType2(elem, arr.size);
        },
        .slice_type => |elem_te| {
            _ = try self.resolveType(elem_te);
            // Slice is { ptr, i64 } — same layout as str.
            var body_types = [_]c.LLVMTypeRef{
                c.LLVMPointerTypeInContext(self.context, 0),
                c.LLVMInt64TypeInContext(self.context),
            };
            return c.LLVMStructTypeInContext(self.context, &body_types, 2, 0);
        },
        .optional => |inner| {
            // ?T is sugar for Option[T].
            const payload_type = try self.resolveType(inner);
            const opt_info = try self.getOrCreateOptionType(payload_type);
            return opt_info.llvm_type;
        },
        .tuple_type => |types| {
            var elem_types: [16]c.LLVMTypeRef = undefined;
            for (types, 0..) |t, i| {
                elem_types[i] = try self.resolveType(t);
            }
            return c.LLVMStructTypeInContext(self.context, &elem_types, @intCast(types.len), 0);
        },
        .generic => |g| {
            const name = self.pool.resolve(g.name);
            if (std.mem.eql(u8, name, "Task")) {
                if (g.args.len != 1) return error.UnsupportedType;
                // Task[T] lowers to runtime task-id handles (i32).
                _ = try self.resolveType(g.args[0]);
                return c.LLVMInt32TypeInContext(self.context);
            }
            if (std.mem.eql(u8, name, "Option")) {
                if (g.args.len != 1) return error.UnsupportedType;
                const payload_type = try self.resolveType(g.args[0]);
                const opt_info = try self.getOrCreateOptionType(payload_type);
                return opt_info.llvm_type;
            }
            if (std.mem.eql(u8, name, "Result")) {
                if (g.args.len != 2) return error.UnsupportedType;
                const ok_type = try self.resolveType(g.args[0]);
                const err_type = try self.resolveType(g.args[1]);
                const res_info = try self.getOrCreateResultType(ok_type, err_type);
                return res_info.llvm_type;
            }
            if (std.mem.eql(u8, name, "ContextError")) {
                if (g.args.len != 1) return error.UnsupportedType;
                const source_type = try self.resolveType(g.args[0]);
                const ctx_info = try self.getOrCreateContextErrorType(source_type);
                return ctx_info.llvm_type;
            }
            if (std.mem.eql(u8, name, "Vec")) {
                if (g.args.len != 1) return error.UnsupportedType;
                const elem_type = try self.resolveType(g.args[0]);
                const vec_info = try self.getOrCreateVecType(elem_type);
                return vec_info.llvm_type;
            }
            if (std.mem.eql(u8, name, "HashMap")) {
                if (g.args.len != 2) return error.UnsupportedType;
                const key_type = try self.resolveType(g.args[0]);
                const val_type = try self.resolveType(g.args[1]);
                const hm_info = try self.getOrCreateHashMapType(key_type, val_type);
                return hm_info.llvm_type;
            }
            if (std.mem.eql(u8, name, "HashSet")) {
                if (g.args.len != 1) return error.UnsupportedType;
                const elem_type = try self.resolveType(g.args[0]);
                const hs_info = try self.getOrCreateHashSetType(elem_type);
                return hs_info.llvm_type;
            }
            if (std.mem.eql(u8, name, "Box")) {
                if (g.args.len != 1) return error.UnsupportedType;
                if (dynTraitFromTypeExpr(self, g.args[0]) != null) {
                    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
                    var fat_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
                    return c.LLVMStructTypeInContext(self.context, &fat_types, 2, 0);
                }
                return c.LLVMPointerTypeInContext(self.context, 0);
            }
            return error.UnsupportedType;
        },
        .trait_object => {
            // dyn Trait → fat pointer {data_ptr, vtable_ptr}
            const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
            var fat_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
            return c.LLVMStructTypeInContext(self.context, &fat_types, 2, 0);
        },
        .inferred => error.UnsupportedType,
    };
}

/// Store a comptime_error message for reporting by the Driver.
fn emitComptimeError(self: *Codegen, msg_sym: u32) void {
    self.comptime_error_msg = self.pool.resolve(msg_sym);
}

/// Create an alloca in the function's entry block (ensures it dominates all uses).
fn createEntryAlloca(self: *Codegen, ty: c.LLVMTypeRef, name: [*:0]const u8) c.LLVMValueRef {
    const entry_bb = c.LLVMGetEntryBasicBlock(self.current_function);
    const first_instr = c.LLVMGetFirstInstruction(entry_bb);
    const saved_bb = c.LLVMGetInsertBlock(self.builder);
    if (first_instr != null) {
        c.LLVMPositionBuilderBefore(self.builder, first_instr);
    } else {
        c.LLVMPositionBuilderAtEnd(self.builder, entry_bb);
    }
    const alloca = c.LLVMBuildAlloca(self.builder, ty, name);
    c.LLVMPositionBuilderAtEnd(self.builder, saved_bb);
    return alloca;
}

/// Build an LLVM function type from an AST FnTypeExpr.
fn buildFnTypeFromAst(self: *Codegen, ft: Ast.FnTypeExpr) Error!c.LLVMTypeRef {
    // Build fn type with ctx pointer as first param (uniform closure convention).
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
    var param_types: [17]c.LLVMTypeRef = undefined;
    param_types[0] = ptr_type; // context/captures pointer
    for (ft.params, 0..) |p, i| {
        param_types[1 + i] = try self.resolveType(p);
    }
    const ret_type = try self.resolveType(ft.return_type);
    return c.LLVMFunctionType(ret_type, &param_types, @intCast(1 + ft.params.len), 0);
}
