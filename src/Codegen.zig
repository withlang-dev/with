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
/// Generic function ASTs: Symbol → FnDecl (for monomorphization).
generic_fns: std.AutoHashMapUnmanaged(u32, Ast.FnDecl),
/// Already-monomorphized specializations: mangled name → FnInfo.
mono_cache: std.AutoHashMapUnmanaged(u64, FnInfo),
/// Type aliases: Symbol → LLVM type.
type_aliases: std.AutoHashMapUnmanaged(u32, c.LLVMTypeRef),
/// Stack of loop contexts for break/continue.
loop_stack: [16]LoopContext = undefined,
loop_depth: u32 = 0,
closure_counter: u32 = 0,
/// Defer stack for current function.
defer_stack: [32]*const Ast.Expr = undefined,
defer_depth: u32 = 0,
/// Tracks pointee types for references created by &expr.
ref_pointee_types: std.AutoHashMapUnmanaged(u32, c.LLVMTypeRef) = .{},
/// Type context for expressions (set by let bindings, return types, etc.).
expected_type: ?c.LLVMTypeRef = null,
/// Cache of Option enum types keyed by payload LLVM type pointer (cast to usize).
option_type_cache: std.AutoHashMapUnmanaged(usize, OptionResultInfo) = .{},
/// Cache of Result enum types keyed by hash of (ok_type, err_type).
result_type_cache: std.AutoHashMapUnmanaged(u64, OptionResultInfo) = .{},
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
/// VTable globals: hash(type_sym, trait_sym) → LLVM global vtable constant.
vtable_globals: std.AutoHashMapUnmanaged(u64, c.LLVMValueRef) = .{},
/// Trait-typed locals: local Symbol → trait Symbol (tracks which trait a dyn param holds).
trait_locals: std.AutoHashMapUnmanaged(u32, u32) = .{},
/// For functions with dyn Trait params: fn_sym → array of ?trait_sym per param.
/// null means non-trait param.
fn_dyn_params: std.AutoHashMapUnmanaged(u32, []const ?u32) = .{},
/// Stack of scoped local variable lists for Drop emission.
/// Each entry is the count of locals at block entry; on block exit we
/// drop everything above that watermark in reverse order.
scope_locals: [64]ScopedLocal = undefined,
scope_local_count: u32 = 0,
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
/// Whether the program uses async/await (requires fiber runtime linking).
uses_async: bool = false,

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

const ScopedLocal = struct {
    sym: u32,
    alloca: c.LLVMValueRef,
    ty: c.LLVMTypeRef,
};

const LoopContext = struct {
    break_bb: c.LLVMBasicBlockRef,
    continue_bb: c.LLVMBasicBlockRef,
};

const TypeBinding = struct {
    sym: u32,
    ty: c.LLVMTypeRef,
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

const TraitInfo = struct {
    method_names: []const u32, // ordered method Symbols
    method_return_types: []const c.LLVMTypeRef, // return type for each method
    method_param_counts: []const u32, // param count (excluding self) for each method
    vtable_type: c.LLVMTypeRef, // struct of function pointers
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
        .generic_fns = .{},
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
    self.mono_cache.deinit(self.allocator);
    self.type_aliases.deinit(self.allocator);
    self.ref_pointee_types.deinit(self.allocator);
    self.option_type_cache.deinit(self.allocator);
    self.result_type_cache.deinit(self.allocator);
    self.vec_type_cache.deinit(self.allocator);
    self.vec_local_types.deinit(self.allocator);
    self.hashmap_type_cache.deinit(self.allocator);
    self.hashmap_local_types.deinit(self.allocator);
    self.hashset_type_cache.deinit(self.allocator);
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
    {
        var dp_it = self.fn_dyn_params.iterator();
        while (dp_it.next()) |entry| {
            self.allocator.free(entry.value_ptr.*);
        }
    }
    self.fn_dyn_params.deinit(self.allocator);
    self.gen_field_indices.deinit(self.allocator);
    c.LLVMDisposeBuilder(self.builder);
    c.LLVMDisposeModule(self.module);
    c.LLVMContextDispose(self.context);
    c.LLVMDisposeTargetMachine(self.target_machine);
}

/// Generate LLVM IR for an entire module (two-pass).
pub fn genModule(self: *Codegen, module: *const Ast.Module, pool: *InternPool) Error!void {
    self.pool = pool;

    // Declare built-in str type before user types.
    try self.declareBuiltinStrType();

    // Pass 0: declare struct types.
    for (module.decls) |decl| {
        switch (decl.kind) {
            .type_decl => |td| switch (td.kind) {
                .struct_def => |fields| try self.declareStructType(td.name, fields),
                .enum_def => |variants| try self.declareEnumType(td.name, variants),
                .alias => |type_expr| {
                    const resolved = try self.resolveType(type_expr);
                    self.type_aliases.put(self.allocator, td.name, resolved) catch
                        return error.CodegenAlloc;
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

    // Pass 0.7: declare generator state structs and functions.
    for (module.decls) |decl| {
        switch (decl.kind) {
            .function => |fn_decl| {
                if (fn_decl.is_gen and fn_decl.type_params.len == 0) {
                    try self.declareGenerator(fn_decl);
                }
            },
            else => {},
        }
    }

    // Pass 1: declare all functions and externs (forward declarations).
    // Generic functions are stored for later monomorphization.
    for (module.decls) |decl| {
        switch (decl.kind) {
            .function => |fn_decl| {
                if (fn_decl.is_gen) continue; // already declared in pass 0.7
                if (fn_decl.is_async) {
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
    for (module.decls) |decl| {
        switch (decl.kind) {
            .function => |fn_decl| {
                if (fn_decl.is_gen) {
                    try self.genGeneratorBody(fn_decl);
                } else if (fn_decl.is_async) {
                    try self.genAsyncFunction(fn_decl);
                } else if (fn_decl.type_params.len == 0) {
                    try self.genFunction(fn_decl);
                }
            },
            else => {},
        }
    }

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
        return error.VerifyFailed;
    }
    if (err_msg) |msg| c.LLVMDisposeMessage(msg);
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
    const ir = c.LLVMPrintModuleToString(self.module);
    defer c.LLVMDisposeMessage(ir);
    const slice = std.mem.span(ir);
    var buf: [8192]u8 = undefined;
    var w = std.fs.File.stdout().writer(&buf);
    w.interface.writeAll(slice) catch {};
    w.interface.flush() catch {};
}

// ── Function declaration (pass 1) ────────────────────────────────

fn declareFunction(self: *Codegen, func: Ast.FnDecl) Error!void {
    const ret_type = if (func.return_type) |rt|
        try self.resolveType(rt)
    else
        c.LLVMVoidTypeInContext(self.context);

    var param_types_buf: [64]c.LLVMTypeRef = undefined;
    var has_dyn_param = false;
    var dyn_params_buf: [64]?u32 = undefined;
    for (func.params, 0..) |param, i| {
        dyn_params_buf[i] = null;
        if (param.type_expr) |te| {
            if (te.kind == .fn_type) {
                // fn-type params use fat pointer {ptr, ptr} to support closures.
                const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);
                var fat_types = [_]c.LLVMTypeRef{ ptr_type, ptr_type };
                param_types_buf[i] = c.LLVMStructTypeInContext(self.context, &fat_types, 2, 0);
            } else if (te.kind == .trait_object) {
                // dyn Trait params use fat pointer {data_ptr, vtable_ptr}.
                param_types_buf[i] = try self.resolveType(te);
                dyn_params_buf[i] = te.kind.trait_object;
                has_dyn_param = true;
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
    var name_buf: [256]u8 = undefined;
    if (name.len >= name_buf.len) return error.UnsupportedExpr;
    @memcpy(name_buf[0..name.len], name);
    name_buf[name.len] = 0;

    const function = c.LLVMAddFunction(self.module, &name_buf, fn_type);

    self.functions.put(self.allocator, func.name, .{
        .value = function,
        .fn_type = fn_type,
    }) catch return error.CodegenAlloc;

    // Record dyn Trait param info if any.
    if (has_dyn_param) {
        const dyn_info = self.allocator.alloc(?u32, func.params.len) catch return error.CodegenAlloc;
        @memcpy(dyn_info, dyn_params_buf[0..func.params.len]);
        self.fn_dyn_params.put(self.allocator, func.name, dyn_info) catch return error.CodegenAlloc;
    }
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
    var name_buf: [256]u8 = undefined;
    if (name.len >= name_buf.len) return error.UnsupportedExpr;
    @memcpy(name_buf[0..name.len], name);
    name_buf[name.len] = 0;

    const function = c.LLVMAddFunction(self.module, &name_buf, fn_type);

    self.functions.put(self.allocator, ext.name, .{
        .value = function,
        .fn_type = fn_type,
    }) catch return error.CodegenAlloc;
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
        method_ret_types[i] = if (m.return_type) |rt|
            self.resolveType(rt) catch c.LLVMInt32TypeInContext(self.context)
        else
            c.LLVMVoidTypeInContext(self.context);
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

    // Load concrete type from data pointer: %self = load %ConcreteType, ptr %0
    const data_ptr = c.LLVMGetParam(wrapper_fn, 0);
    const concrete_val = c.LLVMBuildLoad2(self.builder, concrete_type, data_ptr, "self");

    // Build args: [concrete_val, param1, param2, ...]
    var call_args: [64]c.LLVMValueRef = undefined;
    call_args[0] = concrete_val;
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
    return c.LLVMBuildCall2(
        self.builder,
        call_fn_type,
        method_fn_ptr,
        &call_args,
        total_args,
        if (is_void) "" else "dyncall",
    );
}

/// Look up a Display method (Type.display or Type.to_string) for a type.
fn findDisplayMethod(self: *Codegen, type_sym: u32) ?FnInfo {
    const type_name = self.pool.resolve(type_sym);
    // Try "Type.display" first, then "Type.to_string".
    const suffixes = [_][]const u8{ ".display", ".to_string" };
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
            // Load the value and call Type.drop(val).
            const val = c.LLVMBuildLoad2(self.builder, local.ty, local.alloca, "drop.val");
            var args = [_]c.LLVMValueRef{val};
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
    self.defer_depth = 0;
    self.scope_local_count = 0;

    // Set expected_type for function body (helps Ok/Err/None type inference).
    const saved_expected = self.expected_type;
    self.expected_type = self.current_ret_type;

    const entry = c.LLVMAppendBasicBlockInContext(self.context, function, "entry");
    c.LLVMPositionBuilderAtEnd(self.builder, entry);

    // Clear trait_locals for this function scope.
    self.trait_locals.clearRetainingCapacity();

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
            if (te.kind == .fn_type) {
                fn_sig = self.buildFnTypeFromAst(te.kind.fn_type) catch null;
            } else if (te.kind == .trait_object) {
                // Track dyn Trait parameters for dynamic dispatch.
                self.trait_locals.put(self.allocator, param.name, te.kind.trait_object) catch {};
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
    }

    const body_val = try self.genExpr(func.body);

    // Restore expected_type.
    self.expected_type = saved_expected;

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
                _ = c.LLVMBuildRet(self.builder, c.LLVMConstInt(ret_type, 0, 0));
            } else if (body_type != ret_type and self.isResultType(ret_type)) {
                // Implicit Ok wrapping: if return type is Result and body is not,
                // wrap the body value in Ok(...).
                const wrapped = try self.buildResultOk(body_val, ret_type);
                _ = c.LLVMBuildRet(self.builder, wrapped);
            } else {
                const coerced = self.coerceInt(body_val, ret_type);
                _ = c.LLVMBuildRet(self.builder, coerced);
            }
        } else {
            _ = c.LLVMBuildRetVoid(self.builder);
        }
    }
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
        .loop_expr => |body| countYields(body),
        .for_expr => |f| countYields(f.body),
        .if_expr => |ie| {
            var n: u32 = countYields(ie.then_body);
            if (ie.else_body) |eb| n += countYields(eb);
            return n;
        },
        .let_binding => |lb| countYields(lb.value),
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
        .while_expr => |w| {
            collectGenLocals(w.body, names, types, count);
        },
        .loop_expr => |body| collectGenLocals(body, names, types, count),
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
        param_types_buf[1 + i] = i32_type;
    }

    const fn_type = c.LLVMFunctionType(i32_type, &param_types_buf, 1 + param_count, 0);
    const function = c.LLVMAddFunction(self.module, name_z, fn_type);

    // Reset locals for the closure scope.
    self.locals = .empty;
    self.current_function = function;
    self.current_ret_type = i32_type;

    const entry = c.LLVMAppendBasicBlockInContext(self.context, function, "entry");
    c.LLVMPositionBuilderAtEnd(self.builder, entry);

    // Skip param 0 (context pointer — unused for non-capturing).
    // Add closure params as locals starting at param index 1.
    for (cl.params, 0..) |param_sym, i| {
        const param_val = c.LLVMGetParam(function, @intCast(1 + i));
        const param_type = c.LLVMTypeOf(param_val);
        const alloca = c.LLVMBuildAlloca(self.builder, param_type, "");
        _ = c.LLVMBuildStore(self.builder, param_val, alloca);
        self.locals.put(self.allocator, param_sym, .{
            .alloca = alloca,
            .ty = param_type,
            .is_mut = false,
        }) catch return error.CodegenAlloc;
    }

    // Generate body.
    const body_val = try self.genExpr(cl.body);

    // Emit return if no terminator.
    const current_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(current_bb) == null) {
        const coerced = self.coerceInt(body_val, i32_type);
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
        cap_field_types[i] = cap.ty;
    }
    const cap_struct_type = c.LLVMStructTypeInContext(
        self.context,
        &cap_field_types,
        capture_count,
        0,
    );

    // Generate closure function: fn(capture_ptr, params...) -> i32
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
        fn_param_types[1 + i] = i32_type;
    }

    const fn_type = c.LLVMFunctionType(i32_type, &fn_param_types, total_params, 0);
    const function = c.LLVMAddFunction(self.module, name_z, fn_type);

    // Generate function body.
    self.locals = .empty;
    self.current_function = function;
    self.current_ret_type = i32_type;

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
        const loaded = c.LLVMBuildLoad2(self.builder, cap.ty, gep, "");
        const alloca = c.LLVMBuildAlloca(self.builder, cap.ty, "");
        _ = c.LLVMBuildStore(self.builder, loaded, alloca);
        self.locals.put(self.allocator, cap.sym, .{
            .alloca = alloca,
            .ty = cap.ty,
            .is_mut = false,
        }) catch return error.CodegenAlloc;
    }

    // Add user params.
    for (cl.params, 0..) |param_sym, i| {
        const param_val = c.LLVMGetParam(function, @intCast(1 + i));
        const param_type = c.LLVMTypeOf(param_val);
        const alloca = c.LLVMBuildAlloca(self.builder, param_type, "");
        _ = c.LLVMBuildStore(self.builder, param_val, alloca);
        self.locals.put(self.allocator, param_sym, .{
            .alloca = alloca,
            .ty = param_type,
            .is_mut = false,
        }) catch return error.CodegenAlloc;
    }

    // Generate body.
    const body_val = try self.genExpr(cl.body);
    const current_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(current_bb) == null) {
        const coerced = self.coerceInt(body_val, i32_type);
        _ = c.LLVMBuildRet(self.builder, coerced);
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
                    // Load the current value.
                    const val = c.LLVMBuildLoad2(self.builder, info.ty, info.alloca, "");
                    captured[count.*] = .{ .sym = sym, .value = val, .ty = info.ty };
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
        .field_access => |fa| {
            self.findCaptures(fa.expr, closure_params, captured, count);
        },
        .grouped => |inner| {
            self.findCaptures(inner, closure_params, captured, count);
        },
        else => {},
    }
}

// ── Expression codegen ───────────────────────────────────────────

fn genExpr(self: *Codegen, expr: *const Ast.Expr) Error!c.LLVMValueRef {
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
        .ident => |sym| self.genIdent(sym),
        .binary => |bin| try self.genBinary(bin),
        .unary => |un| try self.genUnary(un),
        .grouped => |inner| try self.genExpr(inner),
        .block => |blk| try self.genBlock(blk),
        .let_binding => |let_b| try self.genLetBinding(let_b),
        .if_expr => |if_e| try self.genIfExpr(if_e),
        .call => |call_e| try self.genCall(call_e),
        .return_expr => |ret_val| try self.genReturn(ret_val),
        .assign => |assign_e| try self.genAssign(assign_e),
        .while_expr => |while_e| try self.genWhile(while_e),
        .loop_expr => |body| try self.genLoop(body),
        .for_expr => |for_e| try self.genFor(for_e),
        .break_expr => try self.genBreak(),
        .continue_expr => try self.genContinue(),
        .field_access => |fa| try self.genFieldAccess(fa),
        .index => |idx| try self.genIndex(idx),
        .slice => |sl| try self.genSlice(sl),
        .array_literal => |elems| try self.genArrayLiteral(elems),
        .array_comprehension => |comp| try self.genArrayComprehension(comp),
        .struct_literal => |sl| try self.genStructLiteral(sl),
        .match_expr => |m| try self.genMatchExpr(m),
        .enum_variant => |ev| try self.genEnumVariant(ev),
        .variant_shorthand => |sym| self.genIdent(sym),
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
        .spawn_expr => |inner| try self.genSpawn(inner),
        .comptime_expr => |inner| try self.genComptimeExpr(inner),
        else => error.UnsupportedExpr,
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

    const name = self.pool.resolve(func.name);
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const void_type = c.LLVMVoidTypeInContext(self.context);
    const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);

    // 1. Declare the implementation function: fn_name_async(params) -> ret_type
    var param_types_buf: [32]c.LLVMTypeRef = undefined;
    for (func.params, 0..) |param, i| {
        param_types_buf[i] = if (param.type_expr) |te| self.resolveType(te) catch i32_type else i32_type;
    }
    const ret_type = if (func.return_type) |rt| self.resolveType(rt) catch i32_type else void_type;
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
    const ret_type = if (func.return_type) |rt| self.resolveType(rt) catch i32_type else void_type;

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
                    _ = c.LLVMBuildRet(self.builder, c.LLVMConstInt(ret_type, 0, 0));
                } else {
                    const coerced = self.coerceInt(body_val, ret_type);
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
            // Extend result to i64 if needed.
            const result_i64 = if (ret_type == i64_type)
                result
            else
                c.LLVMBuildSExt(self.builder, result, i64_type, "");
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

/// Generate an await expression: calls with_fiber_await(task_id).
fn genAwait(self: *Codegen, inner: *const Ast.Expr) Error!c.LLVMValueRef {
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

/// Generate a spawn expression: fire-and-forget async task.
/// Evaluates the inner expression (which should be an async function call that
/// returns a task ID), and discards the result.
fn genSpawn(self: *Codegen, inner: *const Ast.Expr) Error!c.LLVMValueRef {
    self.declareAsyncRuntime();

    // Evaluate the inner expression — this is a call to an async function
    // which returns a task ID (i32). We simply discard it.
    _ = try self.genExpr(inner);

    // Return void/zero since spawn is fire-and-forget.
    return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
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
                .add => lhs + rhs,
                .sub => lhs - rhs,
                .mul => lhs * rhs,
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
/// Renames `main` → `main_user`, creates new `main` that calls runtime lifecycle.
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

    const lhs = try self.genExpr(bin.lhs);
    const rhs = try self.genExpr(bin.rhs);

    // String operations: str + str (concat), str == str, str != str.
    const lhs_type = c.LLVMTypeOf(lhs);
    const rhs_type_check = c.LLVMTypeOf(rhs);
    if (self.isStrType(lhs_type) and self.isStrType(rhs_type_check)) {
        if (bin.op == .add) return self.genStrConcat(lhs, rhs);
        if (bin.op == .eq or bin.op == .neq) return self.genStrCompare(lhs, rhs, bin.op);
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
        .add => c.LLVMBuildAdd(self.builder, lhs_c, rhs_c, "add"),
        .sub => c.LLVMBuildSub(self.builder, lhs_c, rhs_c, "sub"),
        .mul => c.LLVMBuildMul(self.builder, lhs_c, rhs_c, "mul"),
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
    const payload_type = self.findEnumPayloadType(lhs_type, 0) orelse i32_type;
    const payload = c.LLVMBuildLoad2(self.builder, payload_type, payload_ptr, "default.payload");
    const then_end_bb = c.LLVMGetInsertBlock(self.builder);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // None/Err path: evaluate default (RHS).
    c.LLVMPositionBuilderAtEnd(self.builder, else_bb);
    const rhs = try self.genExpr(bin.rhs);
    const rhs_coerced = self.coerceInt(rhs, payload_type);
    const else_end_bb = c.LLVMGetInsertBlock(self.builder);
    _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Merge with phi.
    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
    const phi = c.LLVMBuildPhi(self.builder, payload_type, "default.val");
    var incoming_vals = [_]c.LLVMValueRef{ payload, rhs_coerced };
    var incoming_bbs = [_]c.LLVMBasicBlockRef{ then_end_bb, else_end_bb };
    c.LLVMAddIncoming(phi, &incoming_vals, &incoming_bbs, 2);

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

    // Must be a struct type (enum with payload: { i32 tag, [N x i8] payload }).
    if (c.LLVMGetTypeKind(val_type) != c.LLVMStructTypeKind) return error.UnsupportedExpr;

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
        const err_payload_type = self.findEnumPayloadType(val_type, 1);
        if (err_payload_type) |ept| {
            const src_ptr = c.LLVMBuildBitCast(self.builder, src_payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
            const err_val = c.LLVMBuildLoad2(self.builder, ept, src_ptr, "");
            const dst_ptr = c.LLVMBuildBitCast(self.builder, dst_payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
            _ = c.LLVMBuildStore(self.builder, err_val, dst_ptr);
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
    for (blk.stmts) |stmt| {
        _ = try self.genExpr(stmt);
    }
    if (blk.tail) |tail| {
        return try self.genExpr(tail);
    }
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

    // Create the LLVM struct type: { i32, [payload_size x i8] }.
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const i8_type = c.LLVMInt8TypeInContext(self.context);
    const payload_arr = c.LLVMArrayType2(i8_type, payload_size);
    var body_types = [_]c.LLVMTypeRef{ i32_type, payload_arr };
    const llvm_type = c.LLVMStructTypeInContext(self.context, &body_types, 2, 0);

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

    self.enum_types.put(self.allocator, option_sym, .{
        .llvm_type = llvm_type,
        .variant_names = variant_names,
        .variant_payload_types = variant_payload_types,
    }) catch return error.CodegenAlloc;

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

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const i8_type = c.LLVMInt8TypeInContext(self.context);
    const payload_arr = c.LLVMArrayType2(i8_type, max_size);
    var body_types = [_]c.LLVMTypeRef{ i32_type, payload_arr };
    const llvm_type = c.LLVMStructTypeInContext(self.context, &body_types, 2, 0);

    const ok_sym = self.pool.intern("Ok") catch return error.CodegenAlloc;
    const err_sym = self.pool.intern("Err") catch return error.CodegenAlloc;
    const result_sym = self.pool.intern("Result") catch return error.CodegenAlloc;

    const variant_names = self.allocator.alloc(u32, 2) catch return error.CodegenAlloc;
    variant_names[0] = ok_sym;
    variant_names[1] = err_sym;

    const variant_payload_types = self.allocator.alloc(?c.LLVMTypeRef, 2) catch return error.CodegenAlloc;
    variant_payload_types[0] = ok_type;
    variant_payload_types[1] = err_type;

    self.enum_types.put(self.allocator, result_sym, .{
        .llvm_type = llvm_type,
        .variant_names = variant_names,
        .variant_payload_types = variant_payload_types,
    }) catch return error.CodegenAlloc;

    const info: OptionResultInfo = .{
        .llvm_type = llvm_type,
        .payload_type = ok_type,
        .err_type = err_type,
        .enum_sym = result_sym,
    };
    self.result_type_cache.put(self.allocator, key, info) catch return error.CodegenAlloc;
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
    const llvm_type = c.LLVMStructCreateNamed(self.context, "Vec");
    c.LLVMStructSetBody(llvm_type, &body_types, 3, 0);

    const info = VecTypeInfo{ .llvm_type = llvm_type, .elem_type = elem_type };
    self.vec_type_cache.put(self.allocator, key, info) catch return error.CodegenAlloc;
    return info;
}

/// Check if an LLVM type is a Vec type.
fn isVecType(self: *Codegen, ty: c.LLVMTypeRef) bool {
    if (c.LLVMGetTypeKind(ty) != c.LLVMStructTypeKind) return false;
    var it = self.vec_type_cache.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == ty) return true;
    }
    return false;
}

/// Get element type for a Vec type.
fn getVecElemType(self: *Codegen, vec_type: c.LLVMTypeRef) ?c.LLVMTypeRef {
    var it = self.vec_type_cache.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == vec_type) return entry.value_ptr.elem_type;
    }
    return null;
}

/// Ensure realloc is declared.
fn ensureReallocDeclared(self: *Codegen) FnInfo {
    const sym = self.pool.intern("realloc") catch unreachable;
    if (self.functions.get(sym)) |fi| return fi;
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

    return c.LLVMConstInt(c.LLVMVoidTypeInContext(self.context), 0, 0);
}

/// Generate Vec.len() → i64
fn genVecLen(self: *Codegen, obj_val: c.LLVMValueRef, vec_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const i64_type = c.LLVMInt64TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, vec_type, "v");
    _ = c.LLVMBuildStore(self.builder, obj_val, alloca);
    const len_gep = c.LLVMBuildStructGEP2(self.builder, vec_type, alloca, 1, "");
    return c.LLVMBuildLoad2(self.builder, i64_type, len_gep, "vec.len");
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
    const llvm_type = c.LLVMStructCreateNamed(self.context, "HashMap");
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
    return c.LLVMConstInt(c.LLVMVoidTypeInContext(self.context), 0, 0);
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
    const llvm_type = c.LLVMStructCreateNamed(self.context, "HashSet");
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
    return c.LLVMConstInt(c.LLVMVoidTypeInContext(self.context), 0, 0);
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
    const tag_gep = c.LLVMBuildStructGEP2(self.builder, opt_info.llvm_type, alloca, 0, "");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i32_type, 0, 0), tag_gep);
    const payload_gep = c.LLVMBuildStructGEP2(self.builder, opt_info.llvm_type, alloca, 1, "");
    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
    _ = c.LLVMBuildStore(self.builder, val, payload_ptr);

    return c.LLVMBuildLoad2(self.builder, opt_info.llvm_type, alloca, "some.val");
}

/// Build an Option None value: { tag: 1, payload: zeroinit }.
fn buildOptionNone(self: *Codegen, opt_llvm_type: c.LLVMTypeRef) c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, opt_llvm_type, "none");
    const tag_gep = c.LLVMBuildStructGEP2(self.builder, opt_llvm_type, alloca, 0, "");
    _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(i32_type, 1, 0), tag_gep);
    return c.LLVMBuildLoad2(self.builder, opt_llvm_type, alloca, "none.val");
}

/// Build a Result Ok value: { tag: 0, payload: val }.
fn buildResultOk(self: *Codegen, val: c.LLVMValueRef, result_type: c.LLVMTypeRef) Error!c.LLVMValueRef {
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const alloca = c.LLVMBuildAlloca(self.builder, result_type, "ok");
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
        if (entry.value_ptr.llvm_type == opt_type) {
            return entry.value_ptr.payload_type;
        }
    }
    // Check result cache too.
    var it2 = self.result_type_cache.iterator();
    while (it2.next()) |entry| {
        if (entry.value_ptr.llvm_type == opt_type) {
            return entry.value_ptr.payload_type;
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

    // Branch: if not Some, abort.
    const cur_fn = self.current_function orelse return error.UnsupportedExpr;
    const some_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "unwrap.some");
    const abort_bb = c.LLVMAppendBasicBlockInContext(self.context, cur_fn, "unwrap.abort");
    _ = c.LLVMBuildCondBr(self.builder, is_some, some_bb, abort_bb);

    // Abort block: call abort().
    c.LLVMPositionBuilderAtEnd(self.builder, abort_bb);
    const abort_info = self.ensureAbortDeclared() catch return error.CodegenAlloc;
    _ = c.LLVMBuildCall2(self.builder, abort_info.fn_type, abort_info.value, null, 0, "");
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

    const val = try self.genExpr(let_b.value);

    // Type from annotation, or inferred from value.
    const ty = if (let_b.type_expr) |te|
        try self.resolveType(te)
    else
        c.LLVMTypeOf(val);

    // In generator mode, reuse the pre-created alloca from the entry block
    // to avoid SSA dominance violations.
    const alloca = if (self.gen_state_ptr != null) blk: {
        if (self.locals.get(let_b.name)) |existing| {
            break :blk existing.alloca;
        }
        break :blk c.LLVMBuildAlloca(self.builder, ty, "");
    } else c.LLVMBuildAlloca(self.builder, ty, "");
    const coerced = self.coerceInt(val, ty);
    _ = c.LLVMBuildStore(self.builder, coerced, alloca);

    self.locals.put(self.allocator, let_b.name, .{
        .alloca = alloca,
        .ty = ty,
        .is_mut = let_b.is_mut,
    }) catch return error.CodegenAlloc;

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

fn genTupleDestructure(self: *Codegen, td: Ast.TupleDestructure) Error!c.LLVMValueRef {
    const tuple_val = try self.genExpr(td.value);
    const tuple_type = c.LLVMTypeOf(tuple_val);

    // Store the tuple value to memory so we can GEP into it.
    const tuple_alloca = c.LLVMBuildAlloca(self.builder, tuple_type, "tuple.tmp");
    _ = c.LLVMBuildStore(self.builder, tuple_val, tuple_alloca);

    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const num_fields = c.LLVMCountStructElementTypes(tuple_type);

    for (td.names, 0..) |name, i| {
        if (i >= num_fields) break; // more names than tuple elements
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

    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn genIdent(self: *Codegen, sym: u32) Error!c.LLVMValueRef {
    if (self.locals.get(sym)) |info| {
        return c.LLVMBuildLoad2(self.builder, info.ty, info.alloca, "");
    }

    // Check if this is an unqualified enum variant name (before built-in None check).
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
    else
        c.LLVMGetUndef(c.LLVMTypeOf(then_val));
    const else_end_bb = c.LLVMGetInsertBlock(self.builder);
    const else_terminated = c.LLVMGetBasicBlockTerminator(else_end_bb) != null;
    if (!else_terminated) _ = c.LLVMBuildBr(self.builder, merge_bb);

    // Merge with phi node.
    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);

    // If both branches terminated (e.g. both return), the merge block is dead.
    if (then_terminated and else_terminated) {
        return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
    }

    // Determine phi type from a non-terminated branch's value.
    const phi_type = if (!then_terminated)
        c.LLVMTypeOf(then_val)
    else
        c.LLVMTypeOf(else_val);

    // If the result type is void, no phi needed.
    if (phi_type == c.LLVMVoidTypeInContext(self.context)) {
        return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
    }

    const phi = c.LLVMBuildPhi(self.builder, phi_type, "ifval");

    // Only add incoming edges from non-terminated branches.
    if (!then_terminated and !else_terminated) {
        // Implicit Ok wrapping: if types mismatch and phi_type is Result, wrap the other.
        var final_then = then_val;
        var final_else = else_val;
        const then_type = c.LLVMTypeOf(then_val);
        const else_type = c.LLVMTypeOf(else_val);
        if (then_type != else_type) {
            if (self.isResultType(then_type) and !self.isResultType(else_type)) {
                // Wrap else in Ok.
                c.LLVMPositionBuilderAtEnd(self.builder, else_end_bb);
                // Remove the existing branch to merge_bb (we'll re-add it).
                c.LLVMInstructionEraseFromParent(c.LLVMGetBasicBlockTerminator(else_end_bb));
                final_else = self.buildResultOk(else_val, then_type) catch return error.UnsupportedExpr;
                _ = c.LLVMBuildBr(self.builder, merge_bb);
                c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
            } else if (self.isResultType(else_type) and !self.isResultType(then_type)) {
                // Wrap then in Ok.
                c.LLVMPositionBuilderAtEnd(self.builder, then_end_bb);
                c.LLVMInstructionEraseFromParent(c.LLVMGetBasicBlockTerminator(then_end_bb));
                final_then = self.buildResultOk(then_val, else_type) catch return error.UnsupportedExpr;
                _ = c.LLVMBuildBr(self.builder, merge_bb);
                c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);
            } else {
                final_else = self.coerceInt(else_val, phi_type);
            }
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
        if (call_e.args.len != 1) return error.UnsupportedExpr;
        const arg_val = try self.genExpr(call_e.args[0]);
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
    if (fn_sym == channel_sym) {
        return self.genChannelCreate(call_e.args);
    }

    // Built-in: send(ch, value) — send to channel
    const send_sym = self.pool.intern("send") catch return error.CodegenAlloc;
    if (fn_sym == send_sym) {
        return self.genChannelSend(call_e.args);
    }

    // Built-in: recv(ch) — receive from channel
    const recv_sym = self.pool.intern("recv") catch return error.CodegenAlloc;
    if (fn_sym == recv_sym) {
        return self.genChannelRecv(call_e.args);
    }

    // Built-in: close(ch) — close a channel
    const close_sym = self.pool.intern("close") catch return error.CodegenAlloc;
    if (fn_sym == close_sym) {
        return self.genChannelClose(call_e.args);
    }

    // Check if this is a known function.
    if (self.functions.get(fn_sym)) |fn_info| {
        var args_buf: [64]c.LLVMValueRef = undefined;
        for (call_e.args, 0..) |arg, i| {
            args_buf[i] = try self.genExpr(arg);
        }

        // Coerce arguments to match parameter types.
        const param_count: u32 = c.LLVMCountParams(fn_info.value);
        const dyn_params = self.fn_dyn_params.get(fn_sym);
        for (0..@min(call_e.args.len, param_count)) |i| {
            const param_type = c.LLVMTypeOf(c.LLVMGetParam(fn_info.value, @intCast(i)));
            const arg_type = c.LLVMTypeOf(args_buf[i]);

            // Convert concrete value → dyn Trait fat pointer.
            if (dyn_params) |dp| {
                if (i < dp.len) {
                    if (dp[i]) |trait_sym| {
                        // This param expects dyn Trait — wrap concrete value.
                        if (self.findTypeSymbol(arg_type)) |type_sym| {
                            args_buf[i] = try self.buildDynTraitValue(args_buf[i], type_sym, trait_sym);
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

            // Auto-coerce str → ptr when param expects a pointer.
            if (c.LLVMGetTypeKind(param_type) == c.LLVMPointerTypeKind and self.isStrType(arg_type)) {
                args_buf[i] = self.extractStrPtr(args_buf[i]);
            } else {
                args_buf[i] = self.coerceInt(args_buf[i], param_type);
            }
        }

        // For variadic functions, coerce remaining args (str → ptr, float → double).
        const is_variadic = c.LLVMIsFunctionVarArg(fn_info.fn_type) != 0;
        if (is_variadic) {
            for (param_count..@intCast(call_e.args.len)) |i| {
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

        const ret_type = c.LLVMGetReturnType(fn_info.fn_type);
        const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);

        return c.LLVMBuildCall2(
            self.builder,
            fn_info.fn_type,
            fn_info.value,
            if (call_e.args.len > 0) &args_buf else null,
            @intCast(call_e.args.len),
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

            // Use the stored fn_sig if available, otherwise assume all i32.
            const fn_type = if (local_info.fn_sig) |sig| sig else blk: {
                const i32_type = c.LLVMInt32TypeInContext(self.context);
                var param_types_buf: [16]c.LLVMTypeRef = undefined;
                for (0..arg_count) |i| {
                    param_types_buf[i] = i32_type;
                }
                break :blk c.LLVMFunctionType(i32_type, &param_types_buf, arg_count, 0);
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
                    args_buf[i] = self.coerceInt(args_buf[i], fn_param_types[i]);
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
            const ptr_type = c.LLVMPointerTypeInContext(self.context, 0);

            // Extract fn_ptr (field 0) and capture_ptr (field 1).
            const fn_ptr = c.LLVMBuildExtractValue(self.builder, loaded, 0, "fn_ptr");
            const cap_ptr = c.LLVMBuildExtractValue(self.builder, loaded, 1, "cap_ptr");

            const arg_count: u32 = @intCast(call_e.args.len);
            const total_params = 1 + arg_count;

            // Use stored fn_sig (includes ctx param) if available, otherwise build default.
            const call_fn_type = if (local_info.fn_sig) |sig| sig else blk: {
                const i32_type = c.LLVMInt32TypeInContext(self.context);
                var fn_param_types_buf: [17]c.LLVMTypeRef = undefined;
                fn_param_types_buf[0] = ptr_type;
                for (0..arg_count) |i| {
                    fn_param_types_buf[1 + i] = i32_type;
                }
                break :blk c.LLVMFunctionType(i32_type, &fn_param_types_buf, total_params, 0);
            };

            // Build args: [capture_ptr, user_args...]
            var args_buf: [65]c.LLVMValueRef = undefined;
            args_buf[0] = cap_ptr;
            for (call_e.args, 0..) |arg, i| {
                args_buf[1 + i] = try self.genExpr(arg);
            }

            // Coerce user args to match fn_sig params (skip ctx param at index 0).
            if (local_info.fn_sig != null) {
                const sig_param_count = c.LLVMCountParamTypes(call_fn_type);
                if (sig_param_count > 1) {
                    var fn_param_types_arr: [17]c.LLVMTypeRef = undefined;
                    c.LLVMGetParamTypes(call_fn_type, &fn_param_types_arr);
                    for (1..@min(1 + call_e.args.len, sig_param_count)) |pi| {
                        args_buf[pi] = self.coerceInt(args_buf[pi], fn_param_types_arr[pi]);
                    }
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

    self.current_function = function;
    self.current_ret_type = ret_llvm_type;
    self.locals = .empty;

    const entry = c.LLVMAppendBasicBlockInContext(self.context, function, "entry");
    c.LLVMPositionBuilderAtEnd(self.builder, entry);

    // Add parameters as locals.
    for (gen_fn.params, 0..) |param, i| {
        const param_val = c.LLVMGetParam(function, @intCast(i));
        const param_type = c.LLVMTypeOf(param_val);
        const alloca = c.LLVMBuildAlloca(self.builder, param_type, "");
        _ = c.LLVMBuildStore(self.builder, param_val, alloca);
        self.locals.put(self.allocator, param.name, .{
            .alloca = alloca,
            .ty = param_type,
            .is_mut = param.is_mut,
        }) catch return error.CodegenAlloc;
    }

    // Generate body.
    const body_val = try self.genExpr(gen_fn.body);

    // Emit implicit return if needed.
    const current_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(current_bb) == null) {
        const is_void = ret_llvm_type == c.LLVMVoidTypeInContext(self.context);
        if (!is_void) {
            const coerced = self.coerceInt(body_val, ret_llvm_type);
            _ = c.LLVMBuildRet(self.builder, coerced);
        } else {
            _ = c.LLVMBuildRetVoid(self.builder);
        }
    }

    // Restore state.
    self.locals.deinit(self.allocator);
    self.current_function = saved_function;
    self.current_ret_type = saved_ret_type;
    self.locals = saved_locals;
    c.LLVMPositionBuilderAtEnd(self.builder, saved_bb);

    // Now call the monomorphized function.
    // Coerce args to match the specialization's param types.
    for (0..@min(args.len, param_count)) |i| {
        args_buf[i] = self.coerceInt(args_buf[i], param_types[i]);
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
    self: *const Codegen,
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
        else => {},
    }
    _ = self;
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
                    for (type_map[0..type_map_len]) |entry| {
                        if (entry.sym == sym) return entry.ty;
                    }
                    return error.UnsupportedType; // type param not inferred
                }
            }
            // Not a type param — resolve normally.
            return self.resolveType(type_expr);
        },
        else => return self.resolveType(type_expr),
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

fn genMethodCall(self: *Codegen, fa: Ast.FieldAccessExpr, args: []const *const Ast.Expr) Error!c.LLVMValueRef {
    const method_name = self.pool.resolve(fa.field);

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

        const is_type = self.struct_types.get(ident_sym) != null or
            self.enum_types.get(ident_sym) != null;
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
                        args_buf[i] = self.coerceInt(args_buf[i], param_type);
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
            }
        }
    }

    // Evaluate the object.
    const obj_val = try self.genExpr(fa.expr);
    const obj_type = c.LLVMTypeOf(obj_val);

    // Built-in Option/Result methods: unwrap(), unwrap_or(default), is_some(), is_none(), expect(msg).
    if (c.LLVMGetTypeKind(obj_type) == c.LLVMStructTypeKind) {
        if (self.isOptionOrResultType(obj_type)) {
            if (std.mem.eql(u8, method_name, "unwrap")) {
                return self.genOptionUnwrap(obj_val, obj_type, null);
            } else if (std.mem.eql(u8, method_name, "expect")) {
                const msg = if (args.len > 0) try self.genExpr(args[0]) else null;
                return self.genOptionUnwrap(obj_val, obj_type, msg);
            } else if (std.mem.eql(u8, method_name, "unwrap_or")) {
                if (args.len < 1) return error.UnsupportedExpr;
                const default_val = try self.genExpr(args[0]);
                return self.genOptionUnwrapOr(obj_val, obj_type, default_val);
            } else if (std.mem.eql(u8, method_name, "is_some")) {
                return self.genOptionIsSome(obj_val, obj_type);
            } else if (std.mem.eql(u8, method_name, "is_none")) {
                return self.genOptionIsNone(obj_val, obj_type);
            } else if (std.mem.eql(u8, method_name, "is_ok")) {
                return self.genOptionIsSome(obj_val, obj_type);
            } else if (std.mem.eql(u8, method_name, "is_err")) {
                return self.genOptionIsNone(obj_val, obj_type);
            }
        }
    }

    // Built-in Vec methods: len(), get(i), is_empty(), push(val), pop().
    if (self.isVecType(obj_type)) {
        if (std.mem.eql(u8, method_name, "len")) {
            return self.genVecLen(obj_val, obj_type);
        } else if (std.mem.eql(u8, method_name, "get")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const idx = try self.genExpr(args[0]);
            return self.genVecGet(obj_val, obj_type, idx);
        } else if (std.mem.eql(u8, method_name, "is_empty")) {
            const i64_type = c.LLVMInt64TypeInContext(self.context);
            const len = try self.genVecLen(obj_val, obj_type);
            return c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, len, c.LLVMConstInt(i64_type, 0, 0), "is_empty");
        } else if (std.mem.eql(u8, method_name, "push")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const val = try self.genExpr(args[0]);
            // Need alloca of the vec local — look it up from the expression
            if (fa.expr.kind == .ident) {
                const sym = fa.expr.kind.ident;
                if (self.locals.get(sym)) |local| {
                    return self.genVecPush(local.alloca, obj_type, val);
                }
            }
            return error.UnsupportedExpr;
        } else if (std.mem.eql(u8, method_name, "pop")) {
            if (fa.expr.kind == .ident) {
                const sym = fa.expr.kind.ident;
                if (self.locals.get(sym)) |local| {
                    return self.genVecPop(local.alloca, obj_type);
                }
            }
            return error.UnsupportedExpr;
        } else if (std.mem.eql(u8, method_name, "join")) {
            // Vec[str].join(sep) → str
            if (args.len < 1) return error.UnsupportedExpr;
            const sep = try self.genExpr(args[0]);
            return self.genVecJoin(obj_val, sep);
        }
    }

    // Built-in HashMap methods: len(), get(key), contains(key), insert(key, val), remove(key).
    if (self.isHashMapType(obj_type)) {
        if (std.mem.eql(u8, method_name, "len")) {
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
            // Need alloca for mutation
            if (fa.expr.kind == .ident) {
                const sym = fa.expr.kind.ident;
                if (self.locals.get(sym)) |local| {
                    return self.genHashMapInsert(local.alloca, obj_type, key, val);
                }
            }
            return error.UnsupportedExpr;
        } else if (std.mem.eql(u8, method_name, "remove")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const key = try self.genExpr(args[0]);
            if (fa.expr.kind == .ident) {
                const sym = fa.expr.kind.ident;
                if (self.locals.get(sym)) |local| {
                    return self.genHashMapRemove(local.alloca, obj_type, key);
                }
            }
            return error.UnsupportedExpr;
        }
    }

    // Built-in HashSet methods: len(), is_empty(), insert(val), contains(val), remove(val).
    if (self.isHashSetType(obj_type)) {
        if (std.mem.eql(u8, method_name, "len")) {
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
            if (fa.expr.kind == .ident) {
                const sym = fa.expr.kind.ident;
                if (self.locals.get(sym)) |local| {
                    return self.genHashSetInsert(local.alloca, obj_type, val);
                }
            }
            return error.UnsupportedExpr;
        } else if (std.mem.eql(u8, method_name, "remove")) {
            if (args.len < 1) return error.UnsupportedExpr;
            const val = try self.genExpr(args[0]);
            if (fa.expr.kind == .ident) {
                const sym = fa.expr.kind.ident;
                if (self.locals.get(sym)) |local| {
                    return self.genHashSetRemove(local.alloca, obj_type, val);
                }
            }
            return error.UnsupportedExpr;
        }
    }

    // Built-in string methods: len(), is_empty(), contains(), starts_with(), ends_with(),
    // find(), to_upper(), to_lower(), trim(), repeat(), slice().
    if (self.isStrType(obj_type)) {
        if (std.mem.eql(u8, method_name, "len")) {
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

    // Built-in array methods: len(), is_empty(), first(), last(), contains(val).
    if (c.LLVMGetTypeKind(obj_type) == c.LLVMArrayTypeKind) {
        if (std.mem.eql(u8, method_name, "len")) {
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
    {
        var it = self.struct_types.iterator();
        while (it.next()) |entry| {
            if (entry.value_ptr.llvm_type == obj_type) {
                type_name_str = self.pool.resolve(entry.key_ptr.*);
                break;
            }
        }
    }
    // Also search enum_types.
    if (type_name_str == null) {
        var it = self.enum_types.iterator();
        while (it.next()) |entry| {
            if (entry.value_ptr.llvm_type == obj_type) {
                type_name_str = self.pool.resolve(entry.key_ptr.*);
                break;
            }
        }
    }

    if (type_name_str) |tn| {
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
                    c.LLVMGetTypeKind(obj_type) != c.LLVMPointerTypeKind)
                {
                    // Method expects pointer but we have a value — pass the alloca address.
                    if (fa.expr.kind == .ident) {
                        const sym = fa.expr.kind.ident;
                        if (self.locals.get(sym)) |local| {
                            args_buf[0] = local.alloca;
                        } else {
                            args_buf[0] = obj_val;
                        }
                    } else {
                        // For non-ident expressions, alloca a temp and pass its address.
                        const tmp = c.LLVMBuildAlloca(self.builder, obj_type, "tmp.self");
                        _ = c.LLVMBuildStore(self.builder, obj_val, tmp);
                        args_buf[0] = tmp;
                    }
                } else {
                    args_buf[0] = obj_val;
                }
                for (args, 0..) |arg, i| {
                    args_buf[i + 1] = try self.genExpr(arg);
                }
                const total_args = args.len + 1;

                // Coerce arguments.
                const param_count: u32 = c.LLVMCountParams(fn_info.value);
                for (0..@min(total_args, param_count)) |i| {
                    const param_type = c.LLVMTypeOf(c.LLVMGetParam(fn_info.value, @intCast(i)));
                    const arg_type = c.LLVMTypeOf(args_buf[i]);
                    if (c.LLVMGetTypeKind(param_type) == c.LLVMPointerTypeKind and self.isStrType(arg_type)) {
                        args_buf[i] = self.extractStrPtr(args_buf[i]);
                    } else if (c.LLVMGetTypeKind(param_type) != c.LLVMPointerTypeKind or c.LLVMGetTypeKind(arg_type) != c.LLVMPointerTypeKind) {
                        args_buf[i] = self.coerceInt(args_buf[i], param_type);
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
        }
    }

    // Dynamic dispatch: check if the object is a dyn Trait fat pointer.
    // Identify via trait_locals map (set when param has dyn Trait type).
    if (fa.expr.kind == .ident) {
        const ident_sym = fa.expr.kind.ident;
        if (self.trait_locals.get(ident_sym)) |trait_sym| {
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
        const fn_info = self.functions.get(fn_sym) orelse return error.UnsupportedExpr;

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
                args_buf[i] = self.coerceInt(args_buf[i], param_type);
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

    // If rhs is an identifier (bare function name), call as f(lhs).
    if (p.rhs.kind == .ident) {
        const fn_sym = p.rhs.kind.ident;
        const fn_info = self.functions.get(fn_sym) orelse return error.UnsupportedExpr;

        var args_buf: [1]c.LLVMValueRef = .{lhs_val};

        // Coerce argument.
        const param_count: u32 = c.LLVMCountParams(fn_info.value);
        if (param_count > 0) {
            const param_type = c.LLVMTypeOf(c.LLVMGetParam(fn_info.value, 0));
            const arg_type = c.LLVMTypeOf(args_buf[0]);
            if (c.LLVMGetTypeKind(param_type) == c.LLVMPointerTypeKind and self.isStrType(arg_type)) {
                args_buf[0] = self.extractStrPtr(args_buf[0]);
            } else {
                args_buf[0] = self.coerceInt(args_buf[0], param_type);
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

    return error.UnsupportedExpr;
}

fn genReturn(self: *Codegen, ret_val: ?*const Ast.Expr) Error!c.LLVMValueRef {
    const ret_type = self.current_ret_type;
    const is_void = ret_type == c.LLVMVoidTypeInContext(self.context);

    if (ret_val) |val| {
        const v = try self.genExpr(val);
        const coerced = self.coerceInt(v, ret_type);
        // Emit drops and deferred expressions before return.
        try self.emitDrops(0);
        try self.emitDefers();
        _ = c.LLVMBuildRet(self.builder, coerced);
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
    // code that follows the return in the same block.
    const dead_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "ret.dead");
    c.LLVMPositionBuilderAtEnd(self.builder, dead_bb);

    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn genAssign(self: *Codegen, assign: Ast.AssignExpr) Error!c.LLVMValueRef {
    switch (assign.target.kind) {
        .ident => |sym| {
            const info = self.locals.get(sym) orelse return error.UnsupportedExpr;
            if (!info.is_mut) return error.ImmutableAssign;
            const val = try self.genExpr(assign.value);
            const coerced = self.coerceInt(val, info.ty);
            _ = c.LLVMBuildStore(self.builder, coerced, info.alloca);
        },
        .field_access => |fa| {
            // p.x = expr → GEP into the local's alloca + store
            const obj_sym = switch (fa.expr.kind) {
                .ident => |s| s,
                else => return error.UnsupportedExpr,
            };
            const local = self.locals.get(obj_sym) orelse return error.UnsupportedExpr;
            if (!local.is_mut and local.pointee_struct == null) return error.ImmutableAssign;

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
            if (!local.is_mut) return error.ImmutableAssign;

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
    self.loop_stack[self.loop_depth] = .{ .break_bb = end_bb, .continue_bb = cond_bb };
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

fn genLoop(self: *Codegen, body: *const Ast.Expr) Error!c.LLVMValueRef {
    const function = self.current_function;
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "loop.body");
    const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "loop.end");

    // Push loop context.
    if (self.loop_depth >= self.loop_stack.len) return error.UnsupportedExpr;
    self.loop_stack[self.loop_depth] = .{ .break_bb = end_bb, .continue_bb = body_bb };
    self.loop_depth += 1;

    _ = c.LLVMBuildBr(self.builder, body_bb);

    c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
    _ = try self.genExpr(body);
    const body_end_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(body_end_bb) == null) {
        _ = c.LLVMBuildBr(self.builder, body_bb);
    }

    // Pop loop context.
    self.loop_depth -= 1;

    c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn genFor(self: *Codegen, for_e: Ast.ForExpr) Error!c.LLVMValueRef {
    // Check if the iterable is a range expression or an array.
    if (for_e.iterable.kind == .range) {
        return self.genForRange(for_e);
    }
    // Check if iterable is a slice variable.
    if (for_e.iterable.kind == .ident) {
        if (self.slice_elem_types.get(for_e.iterable.kind.ident)) |_| {
            return self.genForSlice(for_e);
        }
    }
    // Check if iterable is a struct with a next() method (custom iterator).
    if (for_e.iterable.kind == .ident) {
        if (self.locals.get(for_e.iterable.kind.ident)) |local| {
            if (c.LLVMGetTypeKind(local.ty) == c.LLVMStructTypeKind) {
                if (self.findNextMethod(local.ty)) |_| {
                    return self.genForIterator(for_e);
                }
            }
        }
    }
    // Otherwise, try to generate as an array iteration.
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

    self.locals.put(self.allocator, for_e.binding, .{
        .alloca = alloca,
        .ty = iter_type,
        .is_mut = false,
    }) catch return error.CodegenAlloc;

    const function = self.current_function;
    const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.cond");
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.body");
    const inc_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.inc");
    const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.end");

    // Push loop context (continue goes to inc, break goes to end).
    if (self.loop_depth >= self.loop_stack.len) return error.UnsupportedExpr;
    self.loop_stack[self.loop_depth] = .{ .break_bb = end_bb, .continue_bb = inc_bb };
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

    self.locals.put(self.allocator, for_e.binding, .{
        .alloca = elem_alloca,
        .ty = elem_type,
        .is_mut = false,
    }) catch return error.CodegenAlloc;

    const function = self.current_function;
    const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.cond");
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.body");
    const inc_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.inc");
    const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.end");

    if (self.loop_depth >= self.loop_stack.len) return error.UnsupportedExpr;
    self.loop_stack[self.loop_depth] = .{ .break_bb = end_bb, .continue_bb = inc_bb };
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
    self.locals.put(self.allocator, for_e.binding, .{
        .alloca = elem_alloca,
        .ty = elem_type,
        .is_mut = false,
    }) catch return error.CodegenAlloc;

    const function = self.current_function;
    const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.cond");
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.body");
    const inc_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.inc");
    const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "for.end");

    if (self.loop_depth >= self.loop_stack.len) return error.UnsupportedExpr;
    self.loop_stack[self.loop_depth] = .{ .break_bb = end_bb, .continue_bb = inc_bb };
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

/// Find the `Type.next` method for a struct type. Returns the FnInfo if found.
fn findNextMethod(self: *Codegen, struct_type: c.LLVMTypeRef) ?FnInfo {
    // Look up the struct type name.
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
    // Build "Type.next" method name.
    var name_buf: [256]u8 = undefined;
    if (type_name.len + 5 >= name_buf.len) return null;
    @memcpy(name_buf[0..type_name.len], type_name);
    @memcpy(name_buf[type_name.len .. type_name.len + 5], ".next");
    const method_name = name_buf[0 .. type_name.len + 5];
    const method_sym = self.pool.intern(method_name) catch return null;
    return self.functions.get(method_sym);
}

/// Generate a for-in loop over a custom iterator with a next() method.
/// Desugars to: loop { match iter.next() { Some(x) -> body, None -> break } }
fn genForIterator(self: *Codegen, for_e: Ast.ForExpr) Error!c.LLVMValueRef {
    const iter_sym = for_e.iterable.kind.ident;
    const local = self.locals.get(iter_sym) orelse return error.UnsupportedExpr;
    const fn_info = self.findNextMethod(local.ty) orelse return error.UnsupportedExpr;

    const function = self.current_function;
    const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "iter.cond");
    const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "iter.body");
    const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "iter.end");

    if (self.loop_depth >= self.loop_stack.len) return error.UnsupportedExpr;
    self.loop_stack[self.loop_depth] = .{ .break_bb = end_bb, .continue_bb = cond_bb };
    self.loop_depth += 1;

    _ = c.LLVMBuildBr(self.builder, cond_bb);

    // Condition block: call next(), check tag.
    c.LLVMPositionBuilderAtEnd(self.builder, cond_bb);

    // Pass pointer to iterator (self param) if the method takes a pointer, otherwise pass by value.
    // Most iterator next() methods take *mut self, so pass pointer.
    var args_buf = [_]c.LLVMValueRef{local.alloca};
    const result = c.LLVMBuildCall2(self.builder, fn_info.fn_type, fn_info.value, &args_buf, 1, "next.result");
    const result_type = c.LLVMTypeOf(result);

    // Extract tag (field 0).
    const tag = c.LLVMBuildExtractValue(self.builder, result, 0, "tag");
    const is_some = c.LLVMBuildICmp(self.builder, c.LLVMIntEQ, tag, c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0), "is.some");
    _ = c.LLVMBuildCondBr(self.builder, is_some, body_bb, end_bb);

    // Body block: extract payload and bind to loop variable.
    c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
    const result_alloca = c.LLVMBuildAlloca(self.builder, result_type, "next.tmp");
    _ = c.LLVMBuildStore(self.builder, result, result_alloca);
    const payload_gep = c.LLVMBuildStructGEP2(self.builder, result_type, result_alloca, 1, "payload.ptr");
    // Determine the payload type from the Option type's payload.
    const payload_ptr = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");

    // Try to find the payload type from option_type_cache.
    var elem_type: c.LLVMTypeRef = c.LLVMInt32TypeInContext(self.context); // default
    var opt_it = self.option_type_cache.iterator();
    while (opt_it.next()) |entry| {
        if (entry.value_ptr.llvm_type == result_type) {
            elem_type = entry.value_ptr.payload_type;
            break;
        }
    }

    const elem_val = c.LLVMBuildLoad2(self.builder, elem_type, payload_ptr, "iter.elem");
    const elem_alloca = c.LLVMBuildAlloca(self.builder, elem_type, "for.elem");
    _ = c.LLVMBuildStore(self.builder, elem_val, elem_alloca);

    self.locals.put(self.allocator, for_e.binding, .{
        .alloca = elem_alloca,
        .ty = elem_type,
        .is_mut = false,
    }) catch return error.CodegenAlloc;

    _ = try self.genExpr(for_e.body);
    const body_end_bb = c.LLVMGetInsertBlock(self.builder);
    if (c.LLVMGetBasicBlockTerminator(body_end_bb) == null) {
        _ = c.LLVMBuildBr(self.builder, cond_bb);
    }

    self.loop_depth -= 1;
    c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
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

    // Create a local binding.
    const alloca = c.LLVMBuildAlloca(self.builder, source_type, "with");
    _ = c.LLVMBuildStore(self.builder, source_val, alloca);
    self.locals.put(self.allocator, w.name, .{
        .alloca = alloca,
        .ty = source_type,
        .is_mut = w.is_mut,
    }) catch return error.CodegenAlloc;

    // Track for Drop.
    if (self.scope_local_count < self.scope_locals.len) {
        self.scope_locals[self.scope_local_count] = .{
            .sym = w.name,
            .alloca = alloca,
            .ty = source_type,
        };
        self.scope_local_count += 1;
    }

    // Generate the body.
    const body_val = try self.genExpr(w.body);

    // Form 2 (builder): if mut and body returns void, return the binding value.
    if (w.is_mut) {
        const body_type = c.LLVMTypeOf(body_val);
        if (body_type == c.LLVMVoidTypeInContext(self.context)) {
            // Body was void (assignments, etc.) → return the builder value.
            return c.LLVMBuildLoad2(self.builder, source_type, alloca, "with.val");
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

fn genBreak(self: *Codegen) Error!c.LLVMValueRef {
    if (self.loop_depth == 0) return error.UnsupportedExpr;
    const ctx = self.loop_stack[self.loop_depth - 1];
    _ = c.LLVMBuildBr(self.builder, ctx.break_bb);

    // Dead block for any code after break.
    const dead_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "break.dead");
    c.LLVMPositionBuilderAtEnd(self.builder, dead_bb);

    return c.LLVMGetUndef(c.LLVMVoidTypeInContext(self.context));
}

fn genContinue(self: *Codegen) Error!c.LLVMValueRef {
    if (self.loop_depth == 0) return error.UnsupportedExpr;
    const ctx = self.loop_stack[self.loop_depth - 1];
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

    var llvm_field_types_buf: [64]c.LLVMTypeRef = undefined;
    for (fields, 0..) |f, i| {
        field_names[i] = f.name;
        field_types[i] = try self.resolveType(f.type_expr);
        field_defaults[i] = f.default;
        llvm_field_types_buf[i] = field_types[i];
    }

    c.LLVMStructSetBody(
        struct_type,
        if (fields.len > 0) &llvm_field_types_buf else null,
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

    self.enum_types.put(self.allocator, name_sym, .{
        .llvm_type = llvm_type,
        .variant_names = variant_names,
        .variant_payload_types = variant_payload_types,
    }) catch return error.CodegenAlloc;
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
    const info = self.struct_types.get(sl.name) orelse return error.UnsupportedType;

    // Alloca for the struct.
    const alloca = c.LLVMBuildAlloca(self.builder, info.llvm_type, "struct");

    // Track which fields are explicitly provided.
    var provided: [64]bool = .{false} ** 64;

    // Store each explicitly provided field.
    for (sl.fields) |field| {
        const idx = self.findFieldIndex(info, field.name) orelse return error.UnsupportedExpr;
        provided[idx] = true;
        const gep = c.LLVMBuildStructGEP2(self.builder, info.llvm_type, alloca, @intCast(idx), "");
        const val = try self.genExpr(field.value);
        const coerced = self.coerceInt(val, info.field_types[idx]);
        _ = c.LLVMBuildStore(self.builder, coerced, gep);
    }

    // Fill in defaults for missing fields.
    for (info.field_names, 0..) |_, i| {
        if (!provided[i]) {
            if (info.field_defaults[i]) |default_expr| {
                const gep = c.LLVMBuildStructGEP2(self.builder, info.llvm_type, alloca, @intCast(i), "");
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
            const payload_val = try self.genExpr(ev.args[0]);
            const payload_gep = c.LLVMBuildStructGEP2(self.builder, enum_info.llvm_type, alloca, 1, "payload");
            // Bitcast the payload storage (which is [N x i8]) to the payload type ptr.
            const payload_store = c.LLVMBuildBitCast(self.builder, payload_gep, c.LLVMPointerTypeInContext(self.context, 0), "");
            const coerced = self.coerceInt(payload_val, payload_type);
            _ = c.LLVMBuildStore(self.builder, coerced, payload_store);
        }
    }

    return c.LLVMBuildLoad2(self.builder, enum_info.llvm_type, alloca, "enum.val");
}

fn genMatchExpr(self: *Codegen, m: Ast.MatchExpr) Error!c.LLVMValueRef {
    const subject = try self.genExpr(m.subject);
    const subject_type = c.LLVMTypeOf(subject);

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
        var it = self.enum_types.iterator();
        while (it.next()) |entry| {
            if (entry.value_ptr.llvm_type == subject_type) {
                enum_info = entry.value_ptr.*;
                break;
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

    // Build switch.
    const sw = c.LLVMBuildSwitch(self.builder, tag_val, default_bb, @intCast(m.arms.len));

    // Add cases.
    for (m.arms, 0..) |arm, i| {
        self.addMatchCase(sw, arm.pattern, tag_val, arm_bbs_buf[i], enum_info);
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
                if (vp.bindings.len > 0 and enum_info != null) {
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

                                    // Bind the first payload name.
                                    const bind_sym = vp.bindings[0];
                                    const bind_alloca = c.LLVMBuildAlloca(self.builder, payload_type, "");
                                    _ = c.LLVMBuildStore(self.builder, payload_val, bind_alloca);
                                    self.locals.put(self.allocator, bind_sym, .{
                                        .alloca = bind_alloca,
                                        .ty = payload_type,
                                        .is_mut = false,
                                    }) catch return error.CodegenAlloc;
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
                    if (vp.bindings.len > 0 and enum_info != null) {
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
                                        const ba2 = c.LLVMBuildAlloca(self.builder, payload_type, "");
                                        _ = c.LLVMBuildStore(self.builder, pval, ba2);
                                        self.locals.put(self.allocator, vp.bindings[0], .{
                                            .alloca = ba2,
                                            .ty = payload_type,
                                            .is_mut = false,
                                        }) catch return error.CodegenAlloc;
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

        // Handle guard clause: if guard is false, jump to next arm or default.
        if (arm.guard) |guard| {
            const guard_val = try self.genExpr(guard);
            const guard_cond = if (c.LLVMTypeOf(guard_val) == c.LLVMInt1TypeInContext(self.context))
                guard_val
            else
                c.LLVMBuildICmp(self.builder, c.LLVMIntNE, guard_val, c.LLVMConstNull(c.LLVMTypeOf(guard_val)), "guard");
            const body_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "guard.pass");
            // On guard failure, fall through to default (or next arm's BB).
            const fallthrough_bb = if (i + 1 < m.arms.len) arm_bbs_buf[i + 1] else default_bb;
            _ = c.LLVMBuildCondBr(self.builder, guard_cond, body_bb, fallthrough_bb);
            c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
        }

        const arm_val = try self.genExpr(arm.body);
        arm_vals_buf[arm_count] = arm_val;
        arm_from_bbs_buf[arm_count] = c.LLVMGetInsertBlock(self.builder);
        arm_count += 1;
        _ = c.LLVMBuildBr(self.builder, merge_bb);
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

fn isResultType(self: *Codegen, ty: c.LLVMTypeRef) bool {
    var it = self.result_type_cache.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.llvm_type == ty) return true;
    }
    return false;
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
        .range_pattern => {
            // Range patterns handled separately with comparison chains, not switch cases.
        },
        .wildcard, .binding => {},
        .string_literal => {},
    }
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
    // Currently only supports range-based comprehensions: [expr for x in start..end]
    if (comp.iterable.kind != .range) return error.UnsupportedExpr;
    const range = comp.iterable.kind.range;

    // Evaluate range bounds.
    const i32_type = c.LLVMInt32TypeInContext(self.context);
    const start_val = if (range.start) |s| try self.genExpr(s) else c.LLVMConstInt(i32_type, 0, 0);
    const end_val = if (range.end) |e| try self.genExpr(e) else return error.UnsupportedExpr;

    // Compute array size = end - start (or end - start + 1 for inclusive).
    const iter_type = c.LLVMTypeOf(end_val);
    const coerced_start = self.coerceInt(start_val, iter_type);
    var size_val = c.LLVMBuildSub(self.builder, end_val, coerced_start, "comp.size");
    if (range.inclusive) {
        size_val = c.LLVMBuildAdd(self.builder, size_val, c.LLVMConstInt(iter_type, 1, 0), "comp.size.inc");
    }

    // For fixed-size arrays, we need constant bounds. Try to evaluate.
    // If bounds are constants, create a fixed-size array.
    const start_const = c.LLVMIsConstant(coerced_start);
    const end_const = c.LLVMIsConstant(end_val);

    if (start_const != 0 and end_const != 0) {
        // Constants: we can determine size at compile time.
        const start_int: i64 = c.LLVMConstIntGetSExtValue(coerced_start);
        const end_int: i64 = c.LLVMConstIntGetSExtValue(end_val);
        const array_size: u64 = @intCast(if (range.inclusive) end_int - start_int + 1 else end_int - start_int);

        // Evaluate first element to determine element type.
        // We need to set up the binding variable first.
        const binding_alloca = c.LLVMBuildAlloca(self.builder, iter_type, "comp.var");
        _ = c.LLVMBuildStore(self.builder, coerced_start, binding_alloca);

        // Save and set up binding.
        const old_local = self.locals.get(comp.binding);
        self.locals.put(self.allocator, comp.binding, .{
            .alloca = binding_alloca,
            .ty = iter_type,
            .is_mut = false,
        }) catch return error.CodegenAlloc;

        // Generate first element to get the element type.
        const first_val = try self.genExpr(comp.expr);
        const elem_type = c.LLVMTypeOf(first_val);
        const arr_type = c.LLVMArrayType2(elem_type, array_size);

        // Allocate the result array.
        const arr_alloca = c.LLVMBuildAlloca(self.builder, arr_type, "comp.arr");

        // Store first element.
        const zero = c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
        if (comp.filter == null) {
            // No filter: simple indexed store.
            var idx0 = [_]c.LLVMValueRef{ zero, c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0) };
            const gep0 = c.LLVMBuildGEP2(self.builder, arr_type, arr_alloca, &idx0, 2, "");
            _ = c.LLVMBuildStore(self.builder, first_val, gep0);
        }

        // Generate the loop for remaining elements.
        const function = self.current_function;
        const cond_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "comp.cond");
        const body_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "comp.body");
        const inc_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "comp.inc");
        const end_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "comp.end");

        // Index counter.
        const idx_alloca = c.LLVMBuildAlloca(self.builder, iter_type, "comp.idx");

        if (comp.filter == null) {
            // Start loop from second element (first already stored above).
            const second = c.LLVMBuildAdd(self.builder, coerced_start, c.LLVMConstInt(iter_type, 1, 0), "");
            _ = c.LLVMBuildStore(self.builder, second, binding_alloca);
            _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(iter_type, 1, 0), idx_alloca);
        } else {
            // With filter, start from beginning (no pre-store).
            _ = c.LLVMBuildStore(self.builder, coerced_start, binding_alloca);
            _ = c.LLVMBuildStore(self.builder, c.LLVMConstInt(iter_type, 0, 0), idx_alloca);
        }

        _ = c.LLVMBuildBr(self.builder, cond_bb);

        // Condition: binding < end.
        c.LLVMPositionBuilderAtEnd(self.builder, cond_bb);
        const cur = c.LLVMBuildLoad2(self.builder, iter_type, binding_alloca, "");
        const cmp_op: c_uint = if (range.inclusive) c.LLVMIntSLE else c.LLVMIntSLT;
        const cond = c.LLVMBuildICmp(self.builder, cmp_op, cur, end_val, "comp.cmp");
        _ = c.LLVMBuildCondBr(self.builder, cond, body_bb, end_bb);

        // Body: evaluate expr, store in array.
        c.LLVMPositionBuilderAtEnd(self.builder, body_bb);
        const val = try self.genExpr(comp.expr);
        const cur_idx = c.LLVMBuildLoad2(self.builder, iter_type, idx_alloca, "");

        if (comp.filter) |filter| {
            // With filter: conditionally store.
            const filter_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "comp.filter");
            const store_bb = c.LLVMAppendBasicBlockInContext(self.context, function, "comp.store");

            const filter_val = try self.genExpr(filter);
            _ = c.LLVMBuildCondBr(self.builder, filter_val, store_bb, filter_bb);

            // Store path.
            c.LLVMPositionBuilderAtEnd(self.builder, store_bb);
            var store_indices = [_]c.LLVMValueRef{ zero, cur_idx };
            const gep = c.LLVMBuildGEP2(self.builder, arr_type, arr_alloca, &store_indices, 2, "");
            _ = c.LLVMBuildStore(self.builder, val, gep);
            // Increment idx.
            const next_idx = c.LLVMBuildAdd(self.builder, cur_idx, c.LLVMConstInt(iter_type, 1, 0), "");
            _ = c.LLVMBuildStore(self.builder, next_idx, idx_alloca);
            _ = c.LLVMBuildBr(self.builder, inc_bb);

            // Skip path (filter_bb): just go to inc.
            c.LLVMPositionBuilderAtEnd(self.builder, filter_bb);
            _ = c.LLVMBuildBr(self.builder, inc_bb);
        } else {
            // No filter: always store.
            var store_indices = [_]c.LLVMValueRef{ zero, cur_idx };
            const gep = c.LLVMBuildGEP2(self.builder, arr_type, arr_alloca, &store_indices, 2, "");
            _ = c.LLVMBuildStore(self.builder, val, gep);
            // Increment idx.
            const next_idx = c.LLVMBuildAdd(self.builder, cur_idx, c.LLVMConstInt(iter_type, 1, 0), "");
            _ = c.LLVMBuildStore(self.builder, next_idx, idx_alloca);
            _ = c.LLVMBuildBr(self.builder, inc_bb);
        }

        // Increment: binding += 1.
        c.LLVMPositionBuilderAtEnd(self.builder, inc_bb);
        const loaded = c.LLVMBuildLoad2(self.builder, iter_type, binding_alloca, "");
        const next = c.LLVMBuildAdd(self.builder, loaded, c.LLVMConstInt(iter_type, 1, 0), "");
        _ = c.LLVMBuildStore(self.builder, next, binding_alloca);
        _ = c.LLVMBuildBr(self.builder, cond_bb);

        // End: restore old binding and load result.
        c.LLVMPositionBuilderAtEnd(self.builder, end_bb);
        if (old_local) |ol| {
            self.locals.put(self.allocator, comp.binding, ol) catch return error.CodegenAlloc;
        }
        return c.LLVMBuildLoad2(self.builder, arr_type, arr_alloca, "comp.result");
    }

    return error.UnsupportedExpr;
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

    if (c.LLVMGetTypeKind(obj_type) == c.LLVMStructTypeKind) {
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

/// Resolve a simple interpolation expression (identifier, field access, method call).
fn resolveInterpExpr(self: *Codegen, expr_text: []const u8) Error!?c.LLVMValueRef {
    // Simple identifier: "name"
    const trimmed = std.mem.trim(u8, expr_text, " \t");
    if (trimmed.len == 0) return null;

    // Check for field access: "obj.field"
    if (std.mem.indexOfScalar(u8, trimmed, '.')) |dot_pos| {
        const obj_name = trimmed[0..dot_pos];
        const field_name = trimmed[dot_pos + 1 ..];

        const obj_sym = self.pool.intern(obj_name) catch return error.CodegenAlloc;
        const field_sym = self.pool.intern(field_name) catch return error.CodegenAlloc;

        if (self.locals.get(obj_sym)) |local_info| {
            const val = c.LLVMBuildLoad2(self.builder, local_info.ty, local_info.alloca, "");
            const val_type = c.LLVMTypeOf(val);

            // Check for array .len
            if (c.LLVMGetTypeKind(val_type) == c.LLVMArrayTypeKind) {
                const len_sym = self.pool.intern("len") catch return error.CodegenAlloc;
                if (field_sym == len_sym) {
                    const len = c.LLVMGetArrayLength2(val_type);
                    return c.LLVMConstInt(c.LLVMInt64TypeInContext(self.context), len, 0);
                }
            }

            // Check for str .len
            if (self.isStrType(val_type)) {
                const len_sym = self.pool.intern("len") catch return error.CodegenAlloc;
                if (field_sym == len_sym) {
                    const str_info = self.findStructTypeByLlvm(val_type) orelse return null;
                    const idx = self.findFieldIndex(str_info, field_sym) orelse return null;
                    const tmp = c.LLVMBuildAlloca(self.builder, val_type, "");
                    _ = c.LLVMBuildStore(self.builder, val, tmp);
                    const gep = c.LLVMBuildStructGEP2(self.builder, val_type, tmp, @intCast(idx), "");
                    return c.LLVMBuildLoad2(self.builder, str_info.field_types[idx], gep, "");
                }
            }

            // Struct field access
            if (self.findStructTypeByLlvm(val_type)) |struct_info| {
                const idx = self.findFieldIndex(struct_info, field_sym) orelse return null;
                const tmp = c.LLVMBuildAlloca(self.builder, val_type, "");
                _ = c.LLVMBuildStore(self.builder, val, tmp);
                const gep = c.LLVMBuildStructGEP2(self.builder, val_type, tmp, @intCast(idx), "");
                return c.LLVMBuildLoad2(self.builder, struct_info.field_types[idx], gep, "");
            }
        }
        return null;
    }

    // Simple identifier lookup
    const sym = self.pool.intern(trimmed) catch return error.CodegenAlloc;
    if (self.locals.get(sym)) |local_info| {
        return c.LLVMBuildLoad2(self.builder, local_info.ty, local_info.alloca, "");
    }

    return null;
}

/// Built-in: assert(condition) — abort if false.
fn genAssertBuiltin(self: *Codegen, args: []const *const Ast.Expr) Error!c.LLVMValueRef {
    if (args.len < 1) return error.UnsupportedExpr;

    const cond = try self.genExpr(args[0]);
    const cond_bool = self.coerceToBool(cond);

    const abort_info = try self.ensureAbortDeclared();

    // if (!cond) abort();
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
    _ = c.LLVMBuildCall2(self.builder, abort_info.fn_type, abort_info.value, null, 0, "");
    _ = c.LLVMBuildUnreachable(self.builder);

    c.LLVMPositionBuilderAtEnd(self.builder, merge_bb);

    return c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), 0, 0);
}

fn genStringLiteral(self: *Codegen, sym: u32) Error!c.LLVMValueRef {
    const text = self.pool.resolve(sym);
    var buf: [4096]u8 = undefined;
    if (text.len >= buf.len) return error.UnsupportedExpr;

    // Process escape sequences.
    var out_len: usize = 0;
    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        if (text[i] == '\\' and i + 1 < text.len) {
            i += 1;
            buf[out_len] = switch (text[i]) {
                'n' => '\n',
                't' => '\t',
                'r' => '\r',
                '0' => 0,
                '\\' => '\\',
                '"' => '"',
                else => text[i],
            };
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
        s.ptr,                                         d.len,
        d.ptr,                                         d.len,
        ptrs_buf,
        lens_buf,
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
            // Look up user-defined struct types (includes built-in str).
            if (self.struct_types.get(sym)) |info| return info.llvm_type;
            // Look up user-defined enum types.
            if (self.enum_types.get(sym)) |info| return info.llvm_type;
            // Look up type aliases.
            if (self.type_aliases.get(sym)) |ty| return ty;
            return error.UnsupportedType;
        },
        .ptr_type => c.LLVMPointerTypeInContext(self.context, 0),
        .ref_type => c.LLVMPointerTypeInContext(self.context, 0),
        .fn_type => c.LLVMPointerTypeInContext(self.context, 0),
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
