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

    // Pass 1: declare all functions and externs (forward declarations).
    // Generic functions are stored for later monomorphization.
    for (module.decls) |decl| {
        switch (decl.kind) {
            .function => |fn_decl| {
                if (fn_decl.type_params.len > 0) {
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
                if (fn_decl.type_params.len == 0) {
                    try self.genFunction(fn_decl);
                }
            },
            else => {},
        }
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
        if (param.type_expr) |te| {
            if (te.kind == .fn_type) {
                fn_sig = self.buildFnTypeFromAst(te.kind.fn_type) catch null;
            } else if (te.kind == .trait_object) {
                // Track dyn Trait parameters for dynamic dispatch.
                self.trait_locals.put(self.allocator, param.name, te.kind.trait_object) catch {};
            }
        }

        self.locals.put(self.allocator, param.name, .{
            .alloca = alloca,
            .ty = param_type,
            .is_mut = param.is_mut,
            .fn_sig = fn_sig,
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
            } else {
                const coerced = self.coerceInt(body_val, ret_type);
                _ = c.LLVMBuildRet(self.builder, coerced);
            }
        } else {
            _ = c.LLVMBuildRetVoid(self.builder);
        }
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
        .struct_literal => |sl| try self.genStructLiteral(sl),
        .match_expr => |m| try self.genMatchExpr(m),
        .enum_variant => |ev| try self.genEnumVariant(ev),
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
        else => error.UnsupportedExpr,
    };
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

    // Check for operator overloading via syntax traits.
    const lhs_type = c.LLVMTypeOf(lhs);
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

    const alloca = c.LLVMBuildAlloca(self.builder, ty, "");
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

    // Track enum type for the local (for println support).
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
        const coerced_else = self.coerceInt(else_val, phi_type);
        var incoming_vals = [_]c.LLVMValueRef{ then_val, coerced_else };
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
                args_buf[0] = obj_val;
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
            if (!local.is_mut) return error.ImmutableAssign;
            const struct_info = self.findStructTypeByLlvm(local.ty) orelse return error.UnsupportedType;
            const idx = self.findFieldIndex(struct_info, fa.field) orelse return error.UnsupportedExpr;

            const gep = c.LLVMBuildStructGEP2(self.builder, local.ty, local.alloca, @intCast(idx), "");
            const val = try self.genExpr(assign.value);
            const coerced = self.coerceInt(val, struct_info.field_types[idx]);
            _ = c.LLVMBuildStore(self.builder, coerced, gep);
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
        // Try to find by i32 tag type — scan enum_types for non-payload enums.
        var it = self.enum_types.iterator();
        while (it.next()) |entry| {
            if (entry.value_ptr.llvm_type == subject_type and c.LLVMGetTypeKind(subject_type) == c.LLVMIntegerTypeKind) {
                enum_info = entry.value_ptr.*;
                break;
            }
        }
    }

    if (m.arms.len == 0) return error.UnsupportedExpr;

    // Create basic blocks for each arm and merge.
    const merge_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "match.end");

    // First pass: identify the wildcard/binding arm.
    var wildcard_arm_idx: ?usize = null;
    for (m.arms, 0..) |arm, i| {
        switch (arm.pattern.kind) {
            .wildcard, .binding => {
                wildcard_arm_idx = i;
                break;
            },
            else => {},
        }
    }

    const default_bb = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "match.default");

    // Create BBs for non-default arms only.
    var arm_bbs_buf: [64]c.LLVMBasicBlockRef = undefined;
    for (0..m.arms.len) |i| {
        if (wildcard_arm_idx != null and wildcard_arm_idx.? == i) {
            arm_bbs_buf[i] = default_bb; // default arm uses default_bb
        } else {
            arm_bbs_buf[i] = c.LLVMAppendBasicBlockInContext(self.context, self.current_function, "match.arm");
        }
    }

    // Build switch.
    const sw = c.LLVMBuildSwitch(self.builder, tag_val, default_bb, @intCast(m.arms.len));

    // Add cases.
    for (m.arms, 0..) |arm, i| {
        switch (arm.pattern.kind) {
            .int_literal => |val| {
                const case_val = c.LLVMConstInt(c.LLVMTypeOf(tag_val), @bitCast(val), 1);
                c.LLVMAddCase(sw, case_val, arm_bbs_buf[i]);
            },
            .bool_literal => |val| {
                const case_val = c.LLVMConstInt(c.LLVMInt1TypeInContext(self.context), @intFromBool(val), 0);
                c.LLVMAddCase(sw, case_val, arm_bbs_buf[i]);
            },
            .variant => |vp| {
                if (enum_info) |ei| {
                    for (ei.variant_names, 0..) |vn, vi| {
                        if (vn == vp.name) {
                            const case_val = c.LLVMConstInt(c.LLVMInt32TypeInContext(self.context), @intCast(vi), 0);
                            c.LLVMAddCase(sw, case_val, arm_bbs_buf[i]);
                            break;
                        }
                    }
                }
            },
            .wildcard, .binding => {},
            else => {},
        }
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
            else => {},
        }

        const arm_val = try self.genExpr(arm.body);
        arm_vals_buf[arm_count] = arm_val;
        arm_from_bbs_buf[arm_count] = c.LLVMGetInsertBlock(self.builder);
        arm_count += 1;
        _ = c.LLVMBuildBr(self.builder, merge_bb);
    }

    // If no wildcard, make default_bb unreachable.
    if (wildcard_arm_idx == null) {
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
        // Print struct: TypeName { field1: val1, field2: val2 }
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
