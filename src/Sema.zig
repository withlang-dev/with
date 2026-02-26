//! Semantic analysis: name resolution, type checking, and validation.
//!
//! Sema runs as a validation pass between parsing and codegen.  It walks
//! the AST, resolves all names, computes types for every expression, and
//! reports type errors with source spans.  Codegen continues to work as
//! before — Sema is purely additive validation.

const std = @import("std");
const Ast = @import("Ast.zig");
const BorrowCfg = @import("BorrowCfg.zig");
const Span = @import("Span.zig");
const Diagnostic = @import("Diagnostic.zig");
const InternPool = @import("InternPool.zig");

const Sema = @This();

pub const Symbol = InternPool.Symbol;

// ── Type representation ──────────────────────────────────────────

pub const TypeId = u32;

/// Sentinel for unresolvable / error-recovery types.
pub const error_type: TypeId = 0;

pub const Type = union(enum) {
    /// Poison type for error recovery.
    err,
    /// Primitive integer: i8, i16, i32, i64, u8, u16, u32, u64.
    int: IntType,
    /// Floating-point: f32, f64.
    float: FloatType,
    /// Boolean.
    bool_type,
    /// Void.
    void_type,
    /// String type (built-in str = {ptr, len}).
    str_type,
    /// User-defined struct.
    struct_type: StructType,
    /// User-defined enum.
    enum_type: EnumType,
    /// Array type: [N]T.
    array_type: ArrayType,
    /// Slice type: []T (ptr + len pair).
    slice_type: SliceType,
    /// Tuple type: (T1, T2, ...).
    tuple_type: TupleType,
    /// Range type: `Range[T]` or `RangeInclusive[T]`.
    range_type: RangeType,
    /// Function type: fn(params) -> ret.
    fn_type: FnType,
    /// Pointer type: *const T, *mut T.
    ptr_type: PtrType,
    /// Reference type: &T, &mut T.
    ref_type: RefType,
    /// Type alias (resolved to target).
    alias: TypeId,
    /// Generic function placeholder (not a real type, used for tracking).
    generic_fn,
};

pub const IntType = struct {
    bits: u8,
    signed: bool,
};

pub const FloatType = struct {
    bits: u8, // 32 or 64
};

pub const StructType = struct {
    name: Symbol,
    field_names: []const Symbol,
    field_types: []const TypeId,
    field_defaults: []const bool, // whether field has a default value
};

pub const EnumType = struct {
    name: Symbol,
    variant_names: []const Symbol,
    variant_payloads: []const ?[]const TypeId, // null for unit variants
};

pub const ArrayType = struct {
    element: TypeId,
    size: u64,
};

pub const SliceType = struct {
    element: TypeId,
};

pub const TupleType = struct {
    elements: []const TypeId,
};

pub const RangeType = struct {
    element: TypeId,
    inclusive: bool,
};

pub const FnType = struct {
    params: []const TypeId,
    return_type: TypeId,
    is_variadic: bool,
};

pub const PtrType = struct {
    pointee: TypeId,
    is_mut: bool,
};

pub const RefType = struct {
    pointee: TypeId,
    is_mut: bool,
};

// ── Closure capture analysis (Phase 4) ───────────────────────────

pub const CaptureKind = enum {
    by_borrow,
    by_copy,
    by_move,
};

pub const CaptureInfo = struct {
    symbol: Symbol,
    kind: CaptureKind,
    type_id: TypeId,
};

pub const ClosureAnalysis = struct {
    captures: []const CaptureInfo,
    is_capturing: bool,
};

// ── Borrow tracking (Phase 3) ────────────────────────────────────

pub const BorrowId = u32;

pub const BorrowKind = enum {
    shared, // &T
    exclusive, // &mut T
};

pub const Borrow = struct {
    kind: BorrowKind,
    place: Symbol, // root variable being borrowed
    field: ?Symbol, // borrowed field (null for whole-place borrows)
    created_at: Span,
    ref_binding: Symbol, // the variable holding the reference
};

// ── Scope and binding info ───────────────────────────────────────

pub const VarState = enum {
    live,
    moved,
};

pub const BindingInfo = struct {
    type_id: TypeId,
    is_mut: bool,
    is_task: bool = false,
    is_ephemeral_task: bool = false,
    is_scoped_task: bool = false,
    state: VarState,
    span: Span,
};

pub const Scope = struct {
    parent: ?*Scope,
    bindings: std.AutoHashMapUnmanaged(Symbol, BindingInfo),

    fn init() Scope {
        return .{ .parent = null, .bindings = .{} };
    }

    fn deinit(self: *Scope, allocator: std.mem.Allocator) void {
        self.bindings.deinit(allocator);
    }

    fn lookup(self: *const Scope, sym: Symbol) ?BindingInfo {
        if (self.bindings.get(sym)) |info| return info;
        if (self.parent) |p| return p.lookup(sym);
        return null;
    }

    fn lookupMut(self: *Scope, sym: Symbol) ?*BindingInfo {
        if (self.bindings.getPtr(sym)) |info| return info;
        if (self.parent) |p| return p.lookupMut(sym);
        return null;
    }

    fn put(self: *Scope, allocator: std.mem.Allocator, sym: Symbol, info: BindingInfo) void {
        self.bindings.put(allocator, sym, info) catch {};
    }
};

// ── Function signature info ──────────────────────────────────────

pub const FnSigInfo = struct {
    type_id: TypeId, // TypeId of the fn_type
    return_type: TypeId,
    param_types: []const TypeId,
    is_variadic: bool,
};

const MethodOrigin = enum {
    trait,
    inherent,
};

// ── Sema state ───────────────────────────────────────────────────

allocator: std.mem.Allocator,
pool: *InternPool,
diagnostics: *Diagnostic.DiagnosticList,

/// All types, indexed by TypeId.
types: std.ArrayList(Type),
/// Named type lookup: type name → TypeId.
named_types: std.AutoHashMapUnmanaged(Symbol, TypeId),
/// Function signatures: fn name → FnSigInfo.
fn_sigs: std.AutoHashMapUnmanaged(Symbol, FnSigInfo),
/// Extern function declarations (used for comptime-fn side-effect restrictions).
extern_fn_names: std.AutoHashMapUnmanaged(Symbol, void),
/// Function declarations by name (for parameter trait-object metadata checks).
fn_decls: std.AutoHashMapUnmanaged(Symbol, Ast.FnDecl),
/// Generic function AST decls (for monomorphization).
generic_fns: std.AutoHashMapUnmanaged(Symbol, Ast.FnDecl),
/// Monomorphized generic specialization cache: hash → TypeId (return type).
mono_cache: std.AutoHashMapUnmanaged(u64, FnSigInfo),
/// Methods: type_name Symbol → list of method fn sigs.
methods: std.AutoHashMapUnmanaged(u64, FnSigInfo),
/// Enum variant lookup: variant_name → (enum TypeId, variant index).
variant_lookup: std.AutoHashMapUnmanaged(Symbol, VariantInfo),

/// Trait declarations: trait name → list of required method name symbols.
trait_methods: std.AutoHashMapUnmanaged(Symbol, []const Symbol),
/// Trait declarations: trait name → full TraitDecl (for default method bodies).
trait_decls: std.AutoHashMapUnmanaged(Symbol, Ast.TraitDecl),
/// Trait implementations: type name → list of trait names implemented.
type_impls: std.AutoHashMapUnmanaged(Symbol, std.ArrayList(Symbol)),
/// Locally-declared traits (used for orphan rule checks).
local_trait_names: std.AutoHashMapUnmanaged(Symbol, void),
/// Locally-declared types (used for orphan rule checks).
local_type_names: std.AutoHashMapUnmanaged(Symbol, void),
/// File id for the primary module being checked (used to distinguish local declarations from imports).
local_file_id: Span.FileId,
/// Method declaration origin by top-level declaration index.
method_decl_origins: std.AutoHashMapUnmanaged(usize, MethodOrigin),
/// Method symbols that have at least one inherent implementation.
method_has_inherent: std.AutoHashMapUnmanaged(Symbol, void),

/// Functions marked @[must_use] — emit warning if return value is discarded.
must_use_fns: std.AutoHashMapUnmanaged(Symbol, void) = .{},
/// Functions returning Result/Option (denied pattern E0802 when discarded).
result_option_fns: std.AutoHashMapUnmanaged(Symbol, void) = .{},
/// Async functions returning Task handles (denied pattern E0801 when discarded).
task_fns: std.AutoHashMapUnmanaged(Symbol, void) = .{},

/// Active borrows in current function (Phase 3).
active_borrows: std.ArrayList(Borrow),

/// Closure capture analyses, keyed by closure expr address (Phase 4).
closure_analyses: std.AutoHashMapUnmanaged(usize, ClosureAnalysis),

/// Current function return type (for checking return statements).
current_return_type: TypeId,
/// Current generator yield type when checking a `gen fn` body.
current_gen_yield_type: ?TypeId = null,
/// Nesting depth when checking an expression in direct call-argument position.
closure_direct_arg_depth: u32 = 0,
/// Optional expected type for contextual expression checking.
expected_expr_type: ?TypeId = null,
/// Whether we're inside the RHS of a pipeline (call gets +1 implicit arg).
in_pipeline_rhs: bool = false,
/// Whether the current function being checked is declared `comptime fn`.
in_comptime_fn: bool = false,
/// Whether we're inside a defer expression (control flow is restricted).
in_defer: bool = false,
/// Active async scope binding symbols (`async scope |s|:`).
active_async_scope_symbols: [16]Symbol = undefined,
active_async_scope_depth: u32 = 0,
/// Current scope.
current_scope: *Scope,
/// Root scope (module-level).
root_scope: Scope,

// Canonical type IDs for primitives (set during init).
ty_i8: TypeId,
ty_i16: TypeId,
ty_i32: TypeId,
ty_i64: TypeId,
ty_u8: TypeId,
ty_u16: TypeId,
ty_u32: TypeId,
ty_u64: TypeId,
ty_f32: TypeId,
ty_f64: TypeId,
ty_bool: TypeId,
ty_void: TypeId,
ty_str: TypeId,
ty_str_view: TypeId,

const VariantInfo = struct {
    enum_type: TypeId,
    variant_index: u32,
};

pub fn init(allocator: std.mem.Allocator, pool: *InternPool, diagnostics: *Diagnostic.DiagnosticList) Sema {
    var types: std.ArrayList(Type) = .empty;
    // Index 0 = error type (sentinel).
    types.append(allocator, .err) catch {};

    var self = Sema{
        .allocator = allocator,
        .pool = pool,
        .diagnostics = diagnostics,
        .types = types,
        .named_types = .{},
        .fn_sigs = .{},
        .extern_fn_names = .{},
        .fn_decls = .{},
        .generic_fns = .{},
        .mono_cache = .{},
        .methods = .{},
        .variant_lookup = .{},
        .trait_methods = .{},
        .trait_decls = .{},
        .type_impls = .{},
        .local_trait_names = .{},
        .local_type_names = .{},
        .local_file_id = 0,
        .method_decl_origins = .{},
        .method_has_inherent = .{},
        .active_borrows = .empty,
        .closure_analyses = .{},
        .current_return_type = 0,
        .current_gen_yield_type = null,
        .closure_direct_arg_depth = 0,
        .expected_expr_type = null,
        .active_async_scope_depth = 0,
        .current_scope = undefined,
        .root_scope = Scope.init(),
        .ty_i8 = 0,
        .ty_i16 = 0,
        .ty_i32 = 0,
        .ty_i64 = 0,
        .ty_u8 = 0,
        .ty_u16 = 0,
        .ty_u32 = 0,
        .ty_u64 = 0,
        .ty_f32 = 0,
        .ty_f64 = 0,
        .ty_bool = 0,
        .ty_void = 0,
        .ty_str = 0,
        .ty_str_view = 0,
    };

    // Register primitive types.
    self.ty_i8 = self.addType(.{ .int = .{ .bits = 8, .signed = true } });
    self.ty_i16 = self.addType(.{ .int = .{ .bits = 16, .signed = true } });
    self.ty_i32 = self.addType(.{ .int = .{ .bits = 32, .signed = true } });
    self.ty_i64 = self.addType(.{ .int = .{ .bits = 64, .signed = true } });
    self.ty_u8 = self.addType(.{ .int = .{ .bits = 8, .signed = false } });
    self.ty_u16 = self.addType(.{ .int = .{ .bits = 16, .signed = false } });
    self.ty_u32 = self.addType(.{ .int = .{ .bits = 32, .signed = false } });
    self.ty_u64 = self.addType(.{ .int = .{ .bits = 64, .signed = false } });
    self.ty_f32 = self.addType(.{ .float = .{ .bits = 32 } });
    self.ty_f64 = self.addType(.{ .float = .{ .bits = 64 } });
    self.ty_bool = self.addType(.bool_type);
    self.ty_void = self.addType(.void_type);
    self.ty_str = self.addType(.str_type);
    self.ty_str_view = self.addType(.{ .ref_type = .{
        .pointee = self.ty_str,
        .is_mut = false,
    } });

    // Register primitive names.
    self.registerPrimName("i8", self.ty_i8);
    self.registerPrimName("i16", self.ty_i16);
    self.registerPrimName("i32", self.ty_i32);
    self.registerPrimName("i64", self.ty_i64);
    self.registerPrimName("u8", self.ty_u8);
    self.registerPrimName("u16", self.ty_u16);
    self.registerPrimName("u32", self.ty_u32);
    self.registerPrimName("u64", self.ty_u64);
    self.registerPrimName("f32", self.ty_f32);
    self.registerPrimName("f64", self.ty_f64);
    self.registerPrimName("bool", self.ty_bool);
    self.registerPrimName("void", self.ty_void);
    self.registerPrimName("str", self.ty_str);
    self.registerPrimName("String", self.ty_str);
    self.registerPrimName("StrView", self.ty_str_view);

    // NOTE: current_scope is set in checkModule, not here, because
    // returning by value would make &self.root_scope a dangling pointer.
    self.current_scope = undefined;

    return self;
}

pub fn deinit(self: *Sema) void {
    self.types.deinit(self.allocator);
    self.named_types.deinit(self.allocator);
    self.fn_sigs.deinit(self.allocator);
    self.extern_fn_names.deinit(self.allocator);
    self.fn_decls.deinit(self.allocator);
    self.generic_fns.deinit(self.allocator);
    self.mono_cache.deinit(self.allocator);
    self.methods.deinit(self.allocator);
    self.variant_lookup.deinit(self.allocator);
    self.trait_methods.deinit(self.allocator);
    self.trait_decls.deinit(self.allocator);
    self.type_impls.deinit(self.allocator);
    self.local_trait_names.deinit(self.allocator);
    self.local_type_names.deinit(self.allocator);
    self.method_decl_origins.deinit(self.allocator);
    self.method_has_inherent.deinit(self.allocator);
    self.must_use_fns.deinit(self.allocator);
    self.result_option_fns.deinit(self.allocator);
    self.task_fns.deinit(self.allocator);
    self.active_borrows.deinit(self.allocator);
    self.closure_analyses.deinit(self.allocator);
    self.root_scope.deinit(self.allocator);
}

fn registerPrimName(self: *Sema, name: []const u8, tid: TypeId) void {
    const sym = self.pool.intern(name) catch return;
    self.named_types.put(self.allocator, sym, tid) catch {};
}

fn addType(self: *Sema, ty: Type) TypeId {
    const id: TypeId = @intCast(self.types.items.len);
    self.types.append(self.allocator, ty) catch return error_type;
    return id;
}

pub fn getType(self: *const Sema, tid: TypeId) Type {
    if (tid >= self.types.items.len) return .err;
    return self.types.items[tid];
}

/// Resolve a TypeId through aliases.
pub fn resolveAlias(self: *const Sema, tid: TypeId) TypeId {
    var current = tid;
    var depth: u32 = 0;
    while (depth < 32) : (depth += 1) {
        switch (self.getType(current)) {
            .alias => |target| current = target,
            else => return current,
        }
    }
    return current;
}

// ── Main entry point ─────────────────────────────────────────────

pub fn checkModule(self: *Sema, module: *const Ast.Module) void {
    // Initialize current_scope to root (must be done here, after struct is at
    // its final address, not in init() which returns by value).
    self.current_scope = &self.root_scope;
    self.local_file_id = module.span.file;
    self.computeMethodOrigins(module);

    // Pass 1: Collect all type declarations, function signatures, extern decls.
    self.collectDeclarations(module);
    self.checkCopyDropExclusivity(module);
    self.checkDeriveAnnotations(module);

    // Pass 1.5: Verify trait conformance (impl blocks satisfy trait requirements).
    self.checkTraitConformance(module);

    // Pass 1.7: Validate generic-function bodies against declared trait bounds.
    self.checkGenericBodyBounds(module);

    // Pass 2: Check all function bodies.
    self.checkBodies(module);
}

fn checkCopyDropExclusivity(self: *Sema, module: *const Ast.Module) void {
    const copy_sym = self.pool.intern("Copy") catch return;
    for (module.decls) |decl| {
        if (decl.kind != .type_decl) continue;
        const td = decl.kind.type_decl;

        var derives_copy = false;
        for (td.derive_traits) |trait_sym| {
            if (trait_sym == copy_sym) {
                derives_copy = true;
                break;
            }
        }
        if (!derives_copy) continue;

        if (self.hasDropMethod(td.name)) {
            self.emitError("type cannot be both Copy and Drop", decl.span);
        }
    }
}

fn checkDeriveAnnotations(self: *Sema, module: *const Ast.Module) void {
    for (module.decls) |decl| {
        if (decl.kind != .type_decl) continue;
        const td = decl.kind.type_decl;
        if (td.derive_traits.len == 0) continue;

        for (td.derive_traits) |trait_sym| {
            const trait_name = self.pool.resolve(trait_sym);

            if (std.mem.eql(u8, trait_name, "all")) {
                // derive(all) is conservative by definition: no hard error here.
                continue;
            }

            if (!self.isKnownDeriveTraitName(trait_name)) {
                var buf: [256]u8 = undefined;
                const msg = std.fmt.bufPrint(&buf, "unknown derive trait '{s}'", .{trait_name}) catch "unknown derive trait";
                const alloc_msg = self.allocator.dupe(u8, msg) catch "unknown derive trait";
                self.emitError(alloc_msg, decl.span);
                continue;
            }

            if (std.mem.eql(u8, trait_name, "Copy")) {
                if (!self.typeDeclSupportsDerivedTrait(td, .copy)) {
                    self.emitError("cannot derive Copy for a type with non-Copy fields", decl.span);
                }
                continue;
            }

            if (std.mem.eql(u8, trait_name, "Clone")) {
                if (!self.typeDeclSupportsDerivedTrait(td, .clone)) {
                    self.emitError("cannot derive Clone for a type with non-Clone fields", decl.span);
                }
                continue;
            }

            if (std.mem.eql(u8, trait_name, "Eq") or std.mem.eql(u8, trait_name, "PartialEq")) {
                if (!self.typeDeclSupportsDerivedTrait(td, .eq)) {
                    self.emitError("cannot derive Eq for a type with non-Eq fields", decl.span);
                }
                continue;
            }

            if (std.mem.eql(u8, trait_name, "Builder")) {
                if (td.kind != .struct_def) {
                    self.emitError("@[derive(Builder)] requires a struct type", decl.span);
                }
                continue;
            }
        }
    }
}

const DeriveReq = enum {
    copy,
    clone,
    eq,
};

fn isKnownDeriveTraitName(_: *const Sema, name: []const u8) bool {
    return std.mem.eql(u8, name, "Copy") or
        std.mem.eql(u8, name, "Clone") or
        std.mem.eql(u8, name, "Eq") or
        std.mem.eql(u8, name, "PartialEq") or
        std.mem.eql(u8, name, "Hash") or
        std.mem.eql(u8, name, "Ord") or
        std.mem.eql(u8, name, "Debug") or
        std.mem.eql(u8, name, "Display") or
        std.mem.eql(u8, name, "Builder");
}

fn typeDeclSupportsDerivedTrait(self: *Sema, td: Ast.TypeDecl, req: DeriveReq) bool {
    if (req == .copy and self.hasDropMethod(td.name)) return false;

    return switch (td.kind) {
        .struct_def => |fields| blk: {
            for (fields) |f| {
                if (!self.typeExprSupportsDerivedTrait(f.type_expr, req)) break :blk false;
            }
            break :blk true;
        },
        .enum_def => |variants| blk: {
            for (variants) |v| {
                if (v.payload) |payload| {
                    for (payload) |pt| {
                        if (!self.typeExprSupportsDerivedTrait(pt, req)) break :blk false;
                    }
                }
            }
            break :blk true;
        },
        .alias => |inner| self.typeExprSupportsDerivedTrait(inner, req),
        .distinct => |inner| self.typeExprSupportsDerivedTrait(inner, req),
    };
}

fn typeExprSupportsDerivedTrait(self: *Sema, te: *const Ast.TypeExpr, req: DeriveReq) bool {
    return switch (te.kind) {
        .named => |sym| self.namedTypeSupportsDerivedTrait(self.pool.resolve(sym), req),
        .ptr_type, .ref_type => true,
        .fn_type => req == .copy,
        .array_type => |a| self.typeExprSupportsDerivedTrait(a.element, req),
        .slice_type => req == .copy,
        .tuple_type => |elems| blk: {
            for (elems) |elem| {
                if (!self.typeExprSupportsDerivedTrait(elem, req)) break :blk false;
            }
            break :blk true;
        },
        .optional => |inner| self.typeExprSupportsDerivedTrait(inner, req),
        .trait_object => false,
        .inferred => false,
        .generic => |g| blk: {
            const name = self.pool.resolve(g.name);

            // Conservative treatment for common container/object types.
            if (std.mem.eql(u8, name, "Vec") or
                std.mem.eql(u8, name, "HashMap") or
                std.mem.eql(u8, name, "HashSet") or
                std.mem.eql(u8, name, "BTreeMap") or
                std.mem.eql(u8, name, "SlotMap") or
                std.mem.eql(u8, name, "Box") or
                std.mem.eql(u8, name, "Channel") or
                std.mem.eql(u8, name, "Task"))
            {
                break :blk false;
            }

            // Option/Result derive only if all contained types qualify.
            if (std.mem.eql(u8, name, "Option") or std.mem.eql(u8, name, "Result")) {
                for (g.args) |arg| {
                    if (!self.typeExprSupportsDerivedTrait(arg, req)) break :blk false;
                }
                break :blk true;
            }

            // Unknown generic type: require all arguments to qualify.
            for (g.args) |arg| {
                if (!self.typeExprSupportsDerivedTrait(arg, req)) break :blk false;
            }
            break :blk true;
        },
    };
}

fn namedTypeSupportsDerivedTrait(_: *const Sema, name: []const u8, req: DeriveReq) bool {
    const is_numeric =
        std.mem.eql(u8, name, "i8") or std.mem.eql(u8, name, "i16") or std.mem.eql(u8, name, "i32") or std.mem.eql(u8, name, "i64") or
        std.mem.eql(u8, name, "u8") or std.mem.eql(u8, name, "u16") or std.mem.eql(u8, name, "u32") or std.mem.eql(u8, name, "u64") or
        std.mem.eql(u8, name, "f32") or std.mem.eql(u8, name, "f64");
    if (is_numeric or std.mem.eql(u8, name, "bool") or std.mem.eql(u8, name, "str") or std.mem.eql(u8, name, "StrView")) {
        return true;
    }

    if (std.mem.eql(u8, name, "String")) return req != .copy;

    if (std.mem.eql(u8, name, "Vec") or
        std.mem.eql(u8, name, "HashMap") or
        std.mem.eql(u8, name, "HashSet") or
        std.mem.eql(u8, name, "BTreeMap") or
        std.mem.eql(u8, name, "SlotMap") or
        std.mem.eql(u8, name, "Box") or
        std.mem.eql(u8, name, "Channel") or
        std.mem.eql(u8, name, "Task"))
    {
        return false;
    }

    // User-defined named types are assumed eligible; explicit trait checks
    // for their fields run on their own declaration.
    return true;
}

// ── Pass 1: Declaration collection ───────────────────────────────

fn computeMethodOrigins(self: *Sema, module: *const Ast.Module) void {
    self.method_decl_origins.clearRetainingCapacity();
    self.method_has_inherent.clearRetainingCapacity();

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
            self.method_decl_origins.put(self.allocator, j, origin) catch {};
            if (origin == .inherent and self.isMethodSymbol(fn_decl.name)) {
                self.method_has_inherent.put(self.allocator, fn_decl.name, {}) catch {};
            }
            remaining -= 1;
        }
    }

    // Top-level method syntax (`fn Type.method(...)`) is inherent.
    for (module.decls, 0..) |decl, decl_idx| {
        if (decl.kind != .function) continue;
        const fn_decl = decl.kind.function;
        if (!self.isMethodSymbol(fn_decl.name)) continue;
        if (self.method_decl_origins.get(decl_idx) == null) {
            self.method_has_inherent.put(self.allocator, fn_decl.name, {}) catch {};
        }
    }
}

fn isMethodSymbol(self: *const Sema, sym: Symbol) bool {
    const name = self.pool.resolve(sym);
    return std.mem.indexOfScalar(u8, name, '.') != null;
}

fn shouldSkipTraitMethodDecl(self: *const Sema, decl_index: usize, fn_sym: Symbol) bool {
    if (!self.isMethodSymbol(fn_sym)) return false;
    const origin = self.method_decl_origins.get(decl_index) orelse .inherent;
    return origin == .trait and self.method_has_inherent.get(fn_sym) != null;
}

fn collectDeclarations(self: *Sema, module: *const Ast.Module) void {
    for (module.decls, 0..) |decl, decl_idx| {
        switch (decl.kind) {
            .type_decl => |td| self.collectTypeDecl(td, decl.span),
            .function => |fn_decl| {
                if (self.shouldSkipTraitMethodDecl(decl_idx, fn_decl.name)) continue;
                self.collectFnDecl(fn_decl);
            },
            .extern_fn => |ext| self.collectExternFn(ext),
            .let_decl => |ld| self.collectLetDecl(ld),
            .use_decl => {}, // use decls are no-ops for now
            .c_import => {}, // already expanded by Driver
            .trait_decl => |td| self.collectTraitDecl(td, decl.span),
            .impl_decl => |id| self.collectImplDecl(id, decl.span),
            .poisoned => {},
        }
    }
}

fn collectTypeDecl(self: *Sema, td: Ast.TypeDecl, span: Span) void {
    switch (td.kind) {
        .struct_def => |fields| {
            const field_names = self.allocator.alloc(Symbol, fields.len) catch return;
            const field_types = self.allocator.alloc(TypeId, fields.len) catch return;
            const field_defaults = self.allocator.alloc(bool, fields.len) catch return;

            for (fields, 0..) |field, i| {
                field_names[i] = field.name;
                if (typeExprContainsRef(field.type_expr)) {
                    self.emitError("ephemeral references cannot be stored in structs", field.span);
                }
                if (typeExprIsCollectionWithRef(self, field.type_expr)) {
                    self.emitError("ephemeral references cannot be stored in collections", field.span);
                }
                field_types[i] = if (typeExprContainsTypeParam(field.type_expr, td.type_params))
                    error_type
                else
                    self.resolveTypeExpr(field.type_expr);
                field_defaults[i] = field.default != null;
            }

            const tid = self.addType(.{ .struct_type = .{
                .name = td.name,
                .field_names = field_names,
                .field_types = field_types,
                .field_defaults = field_defaults,
            } });
            self.named_types.put(self.allocator, td.name, tid) catch {};
        },
        .enum_def => |variants| {
            const variant_names = self.allocator.alloc(Symbol, variants.len) catch return;
            const variant_payloads = self.allocator.alloc(?[]const TypeId, variants.len) catch return;

            for (variants, 0..) |v, i| {
                variant_names[i] = v.name;
                if (v.payload) |payload_types| {
                    const ptypes = self.allocator.alloc(TypeId, payload_types.len) catch {
                        variant_payloads[i] = null;
                        continue;
                    };
                    for (payload_types, 0..) |pt, j| {
                        ptypes[j] = self.resolveTypeExpr(pt);
                    }
                    variant_payloads[i] = ptypes;
                } else {
                    variant_payloads[i] = null;
                }
            }

            const tid = self.addType(.{ .enum_type = .{
                .name = td.name,
                .variant_names = variant_names,
                .variant_payloads = variant_payloads,
            } });
            self.named_types.put(self.allocator, td.name, tid) catch {};

            // Register variant lookup.
            for (variant_names, 0..) |vn, i| {
                self.variant_lookup.put(self.allocator, vn, .{
                    .enum_type = tid,
                    .variant_index = @intCast(i),
                }) catch {};
            }
        },
        .alias => |type_expr| {
            const target = if (typeExprContainsTypeParam(type_expr, td.type_params))
                error_type
            else
                self.resolveTypeExpr(type_expr);
            const tid = self.addType(.{ .alias = target });
            self.named_types.put(self.allocator, td.name, tid) catch {};
        },
        .distinct => |type_expr| {
            // Distinct type: nominal wrapper. Treated as a single-field struct in Sema.
            const inner = if (typeExprContainsTypeParam(type_expr, td.type_params))
                error_type
            else
                self.resolveTypeExpr(type_expr);
            const field_names = self.allocator.alloc(Symbol, 1) catch return;
            const field_types = self.allocator.alloc(TypeId, 1) catch return;
            const field_defaults = self.allocator.alloc(bool, 1) catch return;
            field_names[0] = self.pool.intern("value") catch return;
            field_types[0] = inner;
            field_defaults[0] = false;
            const tid = self.addType(.{ .struct_type = .{
                .name = td.name,
                .field_names = field_names,
                .field_types = field_types,
                .field_defaults = field_defaults,
            } });
            self.named_types.put(self.allocator, td.name, tid) catch {};
        },
    }
    if (span.file == self.local_file_id) {
        self.local_type_names.put(self.allocator, td.name, {}) catch {};
    }
}

fn collectFnDecl(self: *Sema, fn_decl: Ast.FnDecl) void {
    self.fn_decls.put(self.allocator, fn_decl.name, fn_decl) catch {};

    // Generic functions: store AST for later monomorphization.
    if (fn_decl.type_params.len > 0) {
        self.validateGenericFnSignature(fn_decl);
        self.generic_fns.put(self.allocator, fn_decl.name, fn_decl) catch {};
        return;
    }

    const param_types = self.allocator.alloc(TypeId, fn_decl.params.len) catch return;
    for (fn_decl.params, 0..) |param, i| {
        if (param.type_expr) |te| {
            param_types[i] = self.resolveTypeExpr(te);
        } else {
            param_types[i] = error_type;
        }
    }

    const ret_type = if (fn_decl.return_type) |rt| blk: {
        if (typeExprContainsRef(rt)) {
            self.emitError("ephemeral references cannot be returned from functions", rt.span);
        }
        break :blk self.resolveTypeExpr(rt);
    } else self.ty_void;

    const fn_tid = self.addType(.{ .fn_type = .{
        .params = param_types,
        .return_type = ret_type,
        .is_variadic = false,
    } });

    self.fn_sigs.put(self.allocator, fn_decl.name, .{
        .type_id = fn_tid,
        .return_type = ret_type,
        .param_types = param_types,
        .is_variadic = false,
    }) catch {};

    // Track @[must_use] functions.
    if (fn_decl.is_must_use) {
        self.must_use_fns.put(self.allocator, fn_decl.name, {}) catch {};
    }
    // Denied pattern E0802: Result/Option return values are implicitly must-use.
    if (fn_decl.return_type) |rt| {
        if (self.typeExprIsResultOrOption(rt)) {
            self.result_option_fns.put(self.allocator, fn_decl.name, {}) catch {};
        }
    }
    // Denied pattern E0801: async function calls produce Task handles.
    if (fn_decl.is_async) {
        self.task_fns.put(self.allocator, fn_decl.name, {}) catch {};
    }
}

fn typeExprIsResultOrOption(self: *Sema, te: *const Ast.TypeExpr) bool {
    return switch (te.kind) {
        .optional => true,
        .generic => |g| blk: {
            const n = self.pool.resolve(g.name);
            break :blk std.mem.eql(u8, n, "Result") or std.mem.eql(u8, n, "Option");
        },
        else => false,
    };
}

fn validateGenericFnSignature(self: *Sema, fn_decl: Ast.FnDecl) void {
    for (fn_decl.params) |param| {
        if (param.type_expr) |te| {
            self.validateGenericTypeExpr(te, fn_decl.type_params);
        }
    }
    if (fn_decl.return_type) |rt| {
        self.validateGenericTypeExpr(rt, fn_decl.type_params);
    }
}

fn validateGenericTypeExpr(self: *Sema, te: *const Ast.TypeExpr, type_params: []const Ast.TypeParam) void {
    switch (te.kind) {
        .named => |sym| {
            if (typeParamExists(type_params, sym)) return;
            if (self.named_types.get(sym) != null) return;
            self.emitError("unknown type", te.span);
        },
        .generic => |g| {
            if (!typeParamExists(type_params, g.name) and self.named_types.get(g.name) == null) {
                self.emitError("unknown type", te.span);
            }
            for (g.args) |arg| {
                self.validateGenericTypeExpr(arg, type_params);
            }
        },
        .ref_type => |rt| self.validateGenericTypeExpr(rt.pointee, type_params),
        .ptr_type => |pt| self.validateGenericTypeExpr(pt.pointee, type_params),
        .fn_type => |ft| {
            for (ft.params) |p| {
                self.validateGenericTypeExpr(p, type_params);
            }
            self.validateGenericTypeExpr(ft.return_type, type_params);
        },
        .tuple_type => |elems| {
            for (elems) |e| {
                self.validateGenericTypeExpr(e, type_params);
            }
        },
        .optional => |inner| self.validateGenericTypeExpr(inner, type_params),
        .array_type => |at| self.validateGenericTypeExpr(at.element, type_params),
        .slice_type => |inner| self.validateGenericTypeExpr(inner, type_params),
        else => {},
    }
}

fn collectExternFn(self: *Sema, ext: Ast.ExternFnDecl) void {
    const param_types = self.allocator.alloc(TypeId, ext.params.len) catch return;
    for (ext.params, 0..) |param, i| {
        if (param.type_expr) |te| {
            param_types[i] = self.resolveTypeExpr(te);
        } else {
            param_types[i] = error_type;
        }
    }

    const ret_type = if (ext.return_type) |rt|
        self.resolveTypeExpr(rt)
    else
        self.ty_void;

    const fn_tid = self.addType(.{ .fn_type = .{
        .params = param_types,
        .return_type = ret_type,
        .is_variadic = ext.is_variadic,
    } });

    self.fn_sigs.put(self.allocator, ext.name, .{
        .type_id = fn_tid,
        .return_type = ret_type,
        .param_types = param_types,
        .is_variadic = ext.is_variadic,
    }) catch {};
    self.extern_fn_names.put(self.allocator, ext.name, {}) catch {};
}

fn collectLetDecl(self: *Sema, ld: Ast.LetDecl) void {
    // Module-level let: resolve type from annotation or infer as error_type
    // (will be checked in pass 2 when we check the value expression).
    const tid = if (ld.type_expr) |te| blk: {
        if (typeExprIsCollectionWithRef(self, te)) {
            self.emitError("ephemeral references cannot be stored in collections", ld.value.span);
        }
        break :blk self.resolveTypeExpr(te);
    } else error_type;

    self.root_scope.put(self.allocator, ld.name, .{
        .type_id = tid,
        .is_mut = ld.is_mut,
        .state = .live,
        .span = Span.zero,
    });
}

fn collectTraitDecl(self: *Sema, td: Ast.TraitDecl, span: Span) void {
    // Collect the method names required by this trait.
    const method_names = self.allocator.alloc(Symbol, td.methods.len) catch return;
    for (td.methods, 0..) |m, i| {
        method_names[i] = m.name;
    }
    self.trait_methods.put(self.allocator, td.name, method_names) catch {};
    // Store trait decl for default method lookup.
    self.trait_decls.put(self.allocator, td.name, td) catch {};
    if (span.file == self.local_file_id) {
        self.local_trait_names.put(self.allocator, td.name, {}) catch {};
    }
}

fn collectImplDecl(self: *Sema, id: Ast.ImplDecl, span: Span) void {
    // Record which traits a type implements.
    const trait_sym = id.trait_name orelse return; // plain `impl Type` has no trait

    if (self.trait_methods.get(trait_sym) == null and self.trait_decls.get(trait_sym) == null) {
        self.emitError("unknown trait", span);
        return;
    }
    if (self.named_types.get(id.type_name) == null) {
        self.emitError("unknown type", span);
        return;
    }

    const trait_is_local = self.local_trait_names.get(trait_sym) != null;
    const type_is_local = self.local_type_names.get(id.type_name) != null;
    if (!trait_is_local and !type_is_local) {
        self.emitError("orphan rule violation: impl requires a local trait or local type", span);
    }

    const gop = self.type_impls.getOrPut(self.allocator, id.type_name) catch return;
    if (!gop.found_existing) {
        gop.value_ptr.* = .empty;
    } else {
        // Coherence check: detect duplicate impl of the same trait for the same type.
        for (gop.value_ptr.items) |existing_trait| {
            if (existing_trait == trait_sym) {
                var buf: [256]u8 = undefined;
                const type_str = self.pool.resolve(id.type_name);
                const trait_str = self.pool.resolve(trait_sym);
                const msg = std.fmt.bufPrint(&buf, "duplicate implementation of trait '{s}' for type '{s}'", .{ trait_str, type_str }) catch "duplicate trait impl";
                const alloc_msg = self.allocator.dupe(u8, msg) catch "duplicate trait impl";
                self.emitError(alloc_msg, span);
                break;
            }
        }
    }
    gop.value_ptr.append(self.allocator, trait_sym) catch {};
}

// ── Pass 1.5: Trait conformance checking ─────────────────────────

fn checkTraitConformance(self: *Sema, module: *const Ast.Module) void {
    // For each impl_decl with a trait_name, verify all required methods exist.
    for (module.decls) |decl| {
        switch (decl.kind) {
            .impl_decl => |id| {
                const trait_sym = id.trait_name orelse continue;
                const required = self.trait_methods.get(trait_sym) orelse continue;

                // Build set of short method names from mangled method_names.
                // method_names are like "Type.method", we need just "method".
                // Get the trait decl to check for default methods.
                const trait_decl = self.trait_decls.get(trait_sym);

                for (required, 0..) |req_name, req_idx| {
                    const req_str = self.pool.resolve(req_name);
                    var found = false;
                    for (id.method_names) |mangled| {
                        const mangled_str = self.pool.resolve(mangled);
                        // Extract method name after the dot: "Type.method" → "method"
                        const short = if (std.mem.indexOfScalar(u8, mangled_str, '.')) |dot_idx|
                            mangled_str[dot_idx + 1 ..]
                        else
                            mangled_str;
                        if (std.mem.eql(u8, short, req_str)) {
                            found = true;
                            break;
                        }
                    }
                    if (!found) {
                        // Check if the trait provides a default implementation.
                        if (trait_decl) |td| {
                            if (req_idx < td.methods.len and td.methods[req_idx].has_default) {
                                continue; // Default method exists — no error.
                            }
                        }
                        var buf: [256]u8 = undefined;
                        const type_str = self.pool.resolve(id.type_name);
                        const trait_str = self.pool.resolve(trait_sym);
                        const msg = std.fmt.bufPrint(&buf, "type '{s}' is missing method '{s}' required by trait '{s}'", .{ type_str, req_str, trait_str }) catch "missing trait method";
                        const alloc_msg = self.allocator.dupe(u8, msg) catch "missing trait method";
                        self.emitError(alloc_msg, decl.span);
                    }
                }
            },
            else => {},
        }
    }
}

const ParamBoundInfo = struct {
    param_name: Symbol,
    bounds: []const Symbol,
};

fn checkGenericBodyBounds(self: *Sema, module: *const Ast.Module) void {
    for (module.decls) |decl| {
        if (decl.kind != .function) continue;
        const fn_decl = decl.kind.function;
        if (fn_decl.type_params.len == 0) continue;
        self.checkGenericFnBodyBounds(fn_decl);
    }
}

fn checkGenericFnBodyBounds(self: *Sema, fn_decl: Ast.FnDecl) void {
    var infos_buf: [32]ParamBoundInfo = undefined;
    var info_count: usize = 0;

    for (fn_decl.params) |param| {
        const te = param.type_expr orelse continue;
        if (te.kind != .named) continue;
        const type_param_sym = te.kind.named;
        for (fn_decl.type_params) |tp| {
            if (tp.name != type_param_sym) continue;
            if (info_count < infos_buf.len) {
                infos_buf[info_count] = .{
                    .param_name = param.name,
                    .bounds = tp.bounds,
                };
                info_count += 1;
            }
            break;
        }
    }

    self.checkGenericExprBounds(fn_decl.body, infos_buf[0..info_count]);
}

fn genericParamBounds(param_infos: []const ParamBoundInfo, param_name: Symbol) ?[]const Symbol {
    for (param_infos) |info| {
        if (info.param_name == param_name) return info.bounds;
    }
    return null;
}

fn traitDefinesMethod(self: *const Sema, trait_sym: Symbol, method_sym: Symbol) bool {
    const methods = self.trait_methods.get(trait_sym) orelse return false;
    for (methods) |m| {
        if (m == method_sym) return true;
    }
    return false;
}

fn checkGenericExprBounds(self: *Sema, expr: *const Ast.Expr, param_infos: []const ParamBoundInfo) void {
    switch (expr.kind) {
        .call => |call_e| {
            if (call_e.callee.kind == .field_access) {
                const fa = call_e.callee.kind.field_access;
                if (fa.expr.kind == .ident) {
                    const recv_sym = fa.expr.kind.ident;
                    if (genericParamBounds(param_infos, recv_sym)) |bounds| {
                        var found = false;
                        for (bounds) |trait_sym| {
                            if (self.traitDefinesMethod(trait_sym, fa.field)) {
                                found = true;
                                break;
                            }
                        }
                        if (!found) {
                            var buf: [256]u8 = undefined;
                            const method_name = self.pool.resolve(fa.field);
                            const msg = std.fmt.bufPrint(
                                &buf,
                                "generic body method '{s}' requires a matching trait bound",
                                .{method_name},
                            ) catch "generic body method requires trait bound";
                            const alloc_msg = self.allocator.dupe(u8, msg) catch "generic body method requires trait bound";
                            self.emitError(alloc_msg, call_e.callee.span);
                        }
                    }
                }
            }
            self.checkGenericExprBounds(call_e.callee, param_infos);
            for (call_e.args) |arg| {
                self.checkGenericExprBounds(arg, param_infos);
            }
        },
        .field_access => |fa| self.checkGenericExprBounds(fa.expr, param_infos),
        .optional_chain => |oc| {
            self.checkGenericExprBounds(oc.expr, param_infos);
            if (oc.args) |args| {
                for (args) |arg| self.checkGenericExprBounds(arg, param_infos);
            }
        },
        .binary => |b| {
            self.checkGenericExprBounds(b.lhs, param_infos);
            self.checkGenericExprBounds(b.rhs, param_infos);
        },
        .unary => |u| self.checkGenericExprBounds(u.operand, param_infos),
        .block => |blk| {
            for (blk.stmts) |stmt| self.checkGenericExprBounds(stmt, param_infos);
            if (blk.tail) |tail| self.checkGenericExprBounds(tail, param_infos);
        },
        .if_expr => |if_e| {
            self.checkGenericExprBounds(if_e.condition, param_infos);
            self.checkGenericExprBounds(if_e.then_body, param_infos);
            if (if_e.else_body) |eb| self.checkGenericExprBounds(eb, param_infos);
        },
        .match_expr => |m| {
            self.checkGenericExprBounds(m.subject, param_infos);
            for (m.arms) |arm| self.checkGenericExprBounds(arm.body, param_infos);
            for (m.arms) |arm| {
                if (arm.guard) |g| self.checkGenericExprBounds(g, param_infos);
            }
        },
        .array_comprehension => |comp| {
            self.checkGenericExprBounds(comp.expr, param_infos);
            self.checkGenericExprBounds(comp.iterable, param_infos);
            if (comp.filter) |flt| self.checkGenericExprBounds(flt, param_infos);
            if (comp.clauses) |clauses| {
                for (clauses) |clause| self.checkGenericExprBounds(clause.iterable, param_infos);
            }
        },
        .with_expr => |w| {
            self.checkGenericExprBounds(w.source, param_infos);
            self.checkGenericExprBounds(w.body, param_infos);
        },
        .record_update => |ru| {
            self.checkGenericExprBounds(ru.source, param_infos);
            for (ru.fields) |f| self.checkGenericExprBounds(f.value, param_infos);
        },
        .let_binding => |lb| self.checkGenericExprBounds(lb.value, param_infos),
        .let_else => |le| {
            self.checkGenericExprBounds(le.value, param_infos);
            self.checkGenericExprBounds(le.else_body, param_infos);
        },
        .tuple_destructure => |td| self.checkGenericExprBounds(td.value, param_infos),
        .assign => |a| {
            self.checkGenericExprBounds(a.target, param_infos);
            self.checkGenericExprBounds(a.value, param_infos);
        },
        .tuple => |items| for (items) |it| self.checkGenericExprBounds(it, param_infos),
        .range => |r| {
            if (r.start) |s| self.checkGenericExprBounds(s, param_infos);
            if (r.end) |e| self.checkGenericExprBounds(e, param_infos);
        },
        .for_expr => |f| {
            self.checkGenericExprBounds(f.iterable, param_infos);
            self.checkGenericExprBounds(f.body, param_infos);
        },
        .while_expr => |w| {
            self.checkGenericExprBounds(w.condition, param_infos);
            self.checkGenericExprBounds(w.body, param_infos);
        },
        .loop_expr => |body| self.checkGenericExprBounds(body, param_infos),
        .yield_expr => |y| self.checkGenericExprBounds(y, param_infos),
        .await_expr => |a| self.checkGenericExprBounds(a, param_infos),
        .async_block => |ab| self.checkGenericExprBounds(ab, param_infos),
        .async_scope => |ascope| self.checkGenericExprBounds(ascope.body, param_infos),
        .spawn_expr => |task| self.checkGenericExprBounds(task, param_infos),
        .select_await => |sa| {
            for (sa.arms) |arm| {
                self.checkGenericExprBounds(arm.task, param_infos);
                self.checkGenericExprBounds(arm.body, param_infos);
            }
        },
        .closure => |cl| self.checkGenericExprBounds(cl.body, param_infos),
        .pipeline => |p| {
            self.checkGenericExprBounds(p.lhs, param_infos);
            self.checkGenericExprBounds(p.rhs, param_infos);
        },
        .cast => |cst| self.checkGenericExprBounds(cst.expr, param_infos),
        .return_expr => |rv| if (rv) |v| self.checkGenericExprBounds(v, param_infos),
        .defer_expr => |dv| self.checkGenericExprBounds(dv, param_infos),
        .comptime_expr => |inner| self.checkGenericExprBounds(inner, param_infos),
        .index => |idx| {
            self.checkGenericExprBounds(idx.expr, param_infos);
            self.checkGenericExprBounds(idx.index, param_infos);
        },
        .slice => |sl| {
            self.checkGenericExprBounds(sl.expr, param_infos);
            if (sl.start) |s| self.checkGenericExprBounds(s, param_infos);
            if (sl.end) |e| self.checkGenericExprBounds(e, param_infos);
        },
        .struct_literal => |sl| {
            for (sl.fields) |f| self.checkGenericExprBounds(f.value, param_infos);
        },
        .enum_variant => |ev| {
            for (ev.args) |arg| self.checkGenericExprBounds(arg, param_infos);
        },
        .array_literal => |items| for (items) |it| self.checkGenericExprBounds(it, param_infos),
        .grouped => |inner| self.checkGenericExprBounds(inner, param_infos),
        else => {},
    }
}

// ── Type expression resolution ───────────────────────────────────

fn typeExprContainsRef(te: *const Ast.TypeExpr) bool {
    return switch (te.kind) {
        .ref_type => true,
        .generic => |g| blk: {
            for (g.args) |arg| {
                if (typeExprContainsRef(arg)) break :blk true;
            }
            break :blk false;
        },
        .ptr_type => |pt| typeExprContainsRef(pt.pointee),
        .fn_type => |ft| blk: {
            for (ft.params) |p| {
                if (typeExprContainsRef(p)) break :blk true;
            }
            if (typeExprContainsRef(ft.return_type)) break :blk true;
            break :blk false;
        },
        .tuple_type => |elems| blk: {
            for (elems) |e| {
                if (typeExprContainsRef(e)) break :blk true;
            }
            break :blk false;
        },
        .optional => |inner| typeExprContainsRef(inner),
        .array_type => |at| typeExprContainsRef(at.element),
        .slice_type => |inner| typeExprContainsRef(inner),
        else => false,
    };
}

fn typeParamExists(type_params: []const Ast.TypeParam, sym: Symbol) bool {
    for (type_params) |tp| {
        if (tp.name == sym) return true;
    }
    return false;
}

fn typeExprContainsTypeParam(te: *const Ast.TypeExpr, type_params: []const Ast.TypeParam) bool {
    return switch (te.kind) {
        .named => |sym| typeParamExists(type_params, sym),
        .generic => |g| blk: {
            if (typeParamExists(type_params, g.name)) break :blk true;
            for (g.args) |arg| {
                if (typeExprContainsTypeParam(arg, type_params)) break :blk true;
            }
            break :blk false;
        },
        .ref_type => |rt| typeExprContainsTypeParam(rt.pointee, type_params),
        .ptr_type => |pt| typeExprContainsTypeParam(pt.pointee, type_params),
        .fn_type => |ft| blk: {
            for (ft.params) |p| {
                if (typeExprContainsTypeParam(p, type_params)) break :blk true;
            }
            break :blk typeExprContainsTypeParam(ft.return_type, type_params);
        },
        .tuple_type => |elems| blk: {
            for (elems) |e| {
                if (typeExprContainsTypeParam(e, type_params)) break :blk true;
            }
            break :blk false;
        },
        .optional => |inner| typeExprContainsTypeParam(inner, type_params),
        .array_type => |at| typeExprContainsTypeParam(at.element, type_params),
        .slice_type => |inner| typeExprContainsTypeParam(inner, type_params),
        else => false,
    };
}

fn typeExprContainsSelf(self: *const Sema, te: *const Ast.TypeExpr) bool {
    return switch (te.kind) {
        .named => |sym| std.mem.eql(u8, self.pool.resolve(sym), "Self"),
        .generic => |g| blk: {
            if (std.mem.eql(u8, self.pool.resolve(g.name), "Self")) break :blk true;
            for (g.args) |arg| {
                if (self.typeExprContainsSelf(arg)) break :blk true;
            }
            break :blk false;
        },
        .ref_type => |rt| self.typeExprContainsSelf(rt.pointee),
        .ptr_type => |pt| self.typeExprContainsSelf(pt.pointee),
        .fn_type => |ft| blk: {
            for (ft.params) |p| {
                if (self.typeExprContainsSelf(p)) break :blk true;
            }
            break :blk self.typeExprContainsSelf(ft.return_type);
        },
        .tuple_type => |elems| blk: {
            for (elems) |e| {
                if (self.typeExprContainsSelf(e)) break :blk true;
            }
            break :blk false;
        },
        .optional => |inner| self.typeExprContainsSelf(inner),
        .array_type => |at| self.typeExprContainsSelf(at.element),
        .slice_type => |inner| self.typeExprContainsSelf(inner),
        else => false,
    };
}

fn isCollectionTypeName(name: []const u8) bool {
    return std.mem.eql(u8, name, "Vec") or
        std.mem.eql(u8, name, "HashMap") or
        std.mem.eql(u8, name, "HashSet") or
        std.mem.eql(u8, name, "BTreeMap") or
        std.mem.eql(u8, name, "SlotMap");
}

fn typeExprIsCollectionWithRef(self: *Sema, te: *const Ast.TypeExpr) bool {
    return switch (te.kind) {
        .generic => |g| blk: {
            const name = self.pool.resolve(g.name);
            if (isCollectionTypeName(name)) {
                for (g.args) |arg| {
                    if (typeExprContainsRef(arg)) break :blk true;
                }
            }
            for (g.args) |arg| {
                if (typeExprIsCollectionWithRef(self, arg)) break :blk true;
            }
            break :blk false;
        },
        .ptr_type => |pt| typeExprIsCollectionWithRef(self, pt.pointee),
        .fn_type => |ft| blk: {
            for (ft.params) |p| {
                if (typeExprIsCollectionWithRef(self, p)) break :blk true;
            }
            break :blk typeExprIsCollectionWithRef(self, ft.return_type);
        },
        .tuple_type => |elems| blk: {
            for (elems) |e| {
                if (typeExprIsCollectionWithRef(self, e)) break :blk true;
            }
            break :blk false;
        },
        .optional => |inner| typeExprIsCollectionWithRef(self, inner),
        .array_type => |at| typeExprIsCollectionWithRef(self, at.element),
        .slice_type => |inner| typeExprIsCollectionWithRef(self, inner),
        else => false,
    };
}

pub fn resolveTypeExpr(self: *Sema, te: *const Ast.TypeExpr) TypeId {
    return switch (te.kind) {
        .named => |sym| {
            if (self.named_types.get(sym)) |tid| return tid;
            self.emitError("unknown type", te.span);
            return error_type;
        },
        .ptr_type => |pt| {
            const pointee = self.resolveTypeExpr(pt.pointee);
            return self.addType(.{ .ptr_type = .{
                .pointee = pointee,
                .is_mut = pt.is_mut,
            } });
        },
        .ref_type => |rt| {
            const pointee = self.resolveTypeExpr(rt.pointee);
            return self.addType(.{ .ref_type = .{
                .pointee = pointee,
                .is_mut = rt.is_mut,
            } });
        },
        .fn_type => |ft| {
            const params = self.allocator.alloc(TypeId, ft.params.len) catch return error_type;
            for (ft.params, 0..) |p, i| {
                params[i] = self.resolveTypeExpr(p);
            }
            const ret = self.resolveTypeExpr(ft.return_type);
            return self.addType(.{ .fn_type = .{
                .params = params,
                .return_type = ret,
                .is_variadic = false,
            } });
        },
        .array_type => |at| {
            const elem = self.resolveTypeExpr(at.element);
            return self.addType(.{ .array_type = .{
                .element = elem,
                .size = at.size,
            } });
        },
        .slice_type => |elem_te| {
            const elem = self.resolveTypeExpr(elem_te);
            return self.addType(.{ .slice_type = .{
                .element = elem,
            } });
        },
        .tuple_type => |types| {
            const elems = self.allocator.alloc(TypeId, types.len) catch return error_type;
            for (types, 0..) |t, i| {
                elems[i] = self.resolveTypeExpr(t);
            }
            return self.addType(.{ .tuple_type = .{
                .elements = elems,
            } });
        },
        .optional => |inner| {
            // For now, optional types are not yet fully supported.
            _ = self.resolveTypeExpr(inner);
            return error_type;
        },
        .trait_object => |trait_sym| {
            // dyn Trait — validate object safety.
            if (self.trait_decls.get(trait_sym)) |td| {
                for (td.methods) |method| {
                    // Check that each method has at least one parameter (self).
                    if (method.params.len == 0) {
                        var buf: [256]u8 = undefined;
                        const trait_str = self.pool.resolve(trait_sym);
                        const method_str = self.pool.resolve(method.name);
                        const msg = std.fmt.bufPrint(&buf, "trait '{s}' is not object-safe: method '{s}' has no self parameter", .{ trait_str, method_str }) catch "non-object-safe trait";
                        const alloc_msg = self.allocator.dupe(u8, msg) catch "non-object-safe trait";
                        self.emitError(alloc_msg, te.span);
                    }
                    if (method.has_type_params) {
                        var buf: [256]u8 = undefined;
                        const trait_str = self.pool.resolve(trait_sym);
                        const method_str = self.pool.resolve(method.name);
                        const msg = std.fmt.bufPrint(&buf, "trait '{s}' is not object-safe: method '{s}' is generic", .{ trait_str, method_str }) catch "non-object-safe trait";
                        const alloc_msg = self.allocator.dupe(u8, msg) catch "non-object-safe trait";
                        self.emitError(alloc_msg, te.span);
                    }
                    if (method.return_type) |rt| {
                        if (self.typeExprContainsSelf(rt)) {
                            var buf: [256]u8 = undefined;
                            const trait_str = self.pool.resolve(trait_sym);
                            const method_str = self.pool.resolve(method.name);
                            const msg = std.fmt.bufPrint(&buf, "trait '{s}' is not object-safe: method '{s}' returns Self", .{ trait_str, method_str }) catch "non-object-safe trait";
                            const alloc_msg = self.allocator.dupe(u8, msg) catch "non-object-safe trait";
                            self.emitError(alloc_msg, te.span);
                        }
                    }
                }
            }
            return error_type;
        },
        .generic => {
            // Generic type applications (e.g., Vec[T]) not yet resolved in Sema.
            return error_type;
        },
        .inferred => error_type,
    };
}

// ── Pass 2: Check function bodies ────────────────────────────────

fn checkBodies(self: *Sema, module: *const Ast.Module) void {
    for (module.decls, 0..) |decl, decl_idx| {
        switch (decl.kind) {
            .function => |fn_decl| {
                if (self.shouldSkipTraitMethodDecl(decl_idx, fn_decl.name)) continue;
                // Skip generic functions (checked at instantiation).
                if (fn_decl.type_params.len > 0) continue;
                self.checkFnBody(fn_decl);
            },
            else => {},
        }
    }
}

fn checkFnBody(self: *Sema, fn_decl: Ast.FnDecl) void {
    const sig = self.fn_sigs.get(fn_decl.name) orelse return;

    // Phase 3 groundwork: build a CFG for borrow/liveness analysis.
    var cfg = BorrowCfg.build(self.allocator, fn_decl.body) catch null;
    defer if (cfg) |*g| g.deinit();

    // Push function scope.
    var fn_scope = Scope.init();
    fn_scope.parent = self.current_scope;
    const saved_scope = self.current_scope;
    self.current_scope = &fn_scope;
    defer {
        fn_scope.deinit(self.allocator);
        self.current_scope = saved_scope;
    }

    // Add parameters to scope.
    for (fn_decl.params, 0..) |param, i| {
        const param_type = if (i < sig.param_types.len)
            sig.param_types[i]
        else
            error_type;

        fn_scope.put(self.allocator, param.name, .{
            .type_id = param_type,
            .is_mut = param.is_mut,
            .state = .live,
            .span = param.span,
        });
    }

    // Set current return type.
    const saved_ret = self.current_return_type;
    self.current_return_type = if (fn_decl.is_gen) self.ty_void else sig.return_type;
    defer self.current_return_type = saved_ret;
    const saved_gen_yield = self.current_gen_yield_type;
    self.current_gen_yield_type = if (fn_decl.is_gen) sig.return_type else null;
    defer self.current_gen_yield_type = saved_gen_yield;
    const saved_in_comptime = self.in_comptime_fn;
    self.in_comptime_fn = fn_decl.is_comptime;
    defer self.in_comptime_fn = saved_in_comptime;

    // Check body.
    const expected_body_ty: ?TypeId = if (fn_decl.is_gen)
        self.ty_void
    else if (sig.return_type != error_type)
        sig.return_type
    else
        null;
    const body_type = self.checkExprWithExpected(fn_decl.body, expected_body_ty);
    // If there is no explicit `return`, the body's value is the implicit return.
    if (!fn_decl.is_gen and !hasExplicitReturn(fn_decl.body) and sig.return_type != error_type and body_type != error_type) {
        if (self.isImplicitNarrowing(sig.return_type, body_type)) {
            self.emitError("E0201: implicit narrowing conversion", fn_decl.body.span);
        } else if (!self.typesCompatible(sig.return_type, body_type) and self.arithmeticResultType(sig.return_type, body_type) == error_type) {
            var buf: [256]u8 = undefined;
            const expected = self.typeName(sig.return_type);
            const actual = self.typeName(body_type);
            const msg = std.fmt.bufPrint(&buf, "return type mismatch: expected '{s}', found '{s}'", .{ expected, actual }) catch "return type mismatch";
            const alloc_msg = self.allocator.dupe(u8, msg) catch "return type mismatch";
            self.emitError(alloc_msg, fn_decl.body.span);
        }
    }

    // Validate @[tailrec]: reject non-tail recursive calls and require at least one
    // tail-position self call.
    if (fn_decl.is_tailrec) {
        var saw_tail = false;
        var bad_span: ?Span = null;
        const ok = self.validateTailRecUsage(fn_decl.body, fn_decl.name, true, &saw_tail, &bad_span);
        if (!ok) {
            self.emitError("@[tailrec] recursive call is not in tail position", bad_span orelse fn_decl.body.span);
        } else if (!saw_tail) {
            self.emitError("@[tailrec] function has no recursive tail call", fn_decl.body.span);
        }
    }
}

/// Validate that recursive calls to `fn_name` are only in tail position.
/// Returns false on the first non-tail recursive call and records its span.
fn validateTailRecUsage(
    self: *Sema,
    expr: *const Ast.Expr,
    fn_name: Symbol,
    in_tail: bool,
    saw_tail: *bool,
    bad_span: *?Span,
) bool {
    return switch (expr.kind) {
        .call => |call_e| blk: {
            if (call_e.callee.kind == .ident and call_e.callee.kind.ident == fn_name) {
                if (!in_tail) {
                    bad_span.* = expr.span;
                    break :blk false;
                }
                saw_tail.* = true;
            }
            if (!self.validateTailRecUsage(call_e.callee, fn_name, false, saw_tail, bad_span)) break :blk false;
            for (call_e.args) |arg| {
                if (!self.validateTailRecUsage(arg, fn_name, false, saw_tail, bad_span)) break :blk false;
            }
            break :blk true;
        },
        .grouped => |inner| self.validateTailRecUsage(inner, fn_name, in_tail, saw_tail, bad_span),
        .return_expr => |rv| {
            if (rv) |v| return self.validateTailRecUsage(v, fn_name, true, saw_tail, bad_span);
            return true;
        },
        .block => |blk| blk: {
            for (blk.stmts, 0..) |stmt, i| {
                const is_tail_stmt = in_tail and blk.tail == null and i == blk.stmts.len - 1;
                if (!self.validateTailRecUsage(stmt, fn_name, is_tail_stmt, saw_tail, bad_span)) break :blk false;
            }
            if (blk.tail) |tail| {
                if (!self.validateTailRecUsage(tail, fn_name, in_tail, saw_tail, bad_span)) break :blk false;
            }
            break :blk true;
        },
        .if_expr => |if_e| blk: {
            if (!self.validateTailRecUsage(if_e.condition, fn_name, false, saw_tail, bad_span)) break :blk false;
            if (!self.validateTailRecUsage(if_e.then_body, fn_name, in_tail, saw_tail, bad_span)) break :blk false;
            if (if_e.else_body) |else_body| {
                if (!self.validateTailRecUsage(else_body, fn_name, in_tail, saw_tail, bad_span)) break :blk false;
            }
            break :blk true;
        },
        .match_expr => |m| blk: {
            if (!self.validateTailRecUsage(m.subject, fn_name, false, saw_tail, bad_span)) break :blk false;
            for (m.arms) |arm| {
                if (arm.guard) |g| {
                    if (!self.validateTailRecUsage(g, fn_name, false, saw_tail, bad_span)) break :blk false;
                }
                if (!self.validateTailRecUsage(arm.body, fn_name, in_tail, saw_tail, bad_span)) break :blk false;
            }
            break :blk true;
        },
        .binary => |bin| self.validateTailRecUsage(bin.lhs, fn_name, false, saw_tail, bad_span) and
            self.validateTailRecUsage(bin.rhs, fn_name, false, saw_tail, bad_span),
        .unary => |un| self.validateTailRecUsage(un.operand, fn_name, false, saw_tail, bad_span),
        .field_access => |fa| self.validateTailRecUsage(fa.expr, fn_name, false, saw_tail, bad_span),
        .optional_chain => |oc| blk: {
            if (!self.validateTailRecUsage(oc.expr, fn_name, false, saw_tail, bad_span)) break :blk false;
            if (oc.args) |args| {
                for (args) |arg| {
                    if (!self.validateTailRecUsage(arg, fn_name, false, saw_tail, bad_span)) break :blk false;
                }
            }
            break :blk true;
        },
        .index => |idx| self.validateTailRecUsage(idx.expr, fn_name, false, saw_tail, bad_span) and
            self.validateTailRecUsage(idx.index, fn_name, false, saw_tail, bad_span),
        .slice => |sl| blk: {
            if (!self.validateTailRecUsage(sl.expr, fn_name, false, saw_tail, bad_span)) break :blk false;
            if (sl.start) |s| {
                if (!self.validateTailRecUsage(s, fn_name, false, saw_tail, bad_span)) break :blk false;
            }
            if (sl.end) |e| {
                if (!self.validateTailRecUsage(e, fn_name, false, saw_tail, bad_span)) break :blk false;
            }
            break :blk true;
        },
        .let_binding => |lb| self.validateTailRecUsage(lb.value, fn_name, false, saw_tail, bad_span),
        .let_else => |le| self.validateTailRecUsage(le.value, fn_name, false, saw_tail, bad_span) and
            self.validateTailRecUsage(le.else_body, fn_name, false, saw_tail, bad_span),
        .tuple_destructure => |td| self.validateTailRecUsage(td.value, fn_name, false, saw_tail, bad_span),
        .assign => |a| self.validateTailRecUsage(a.target, fn_name, false, saw_tail, bad_span) and
            self.validateTailRecUsage(a.value, fn_name, false, saw_tail, bad_span),
        .tuple => |elems| blk: {
            for (elems) |elem| {
                if (!self.validateTailRecUsage(elem, fn_name, false, saw_tail, bad_span)) break :blk false;
            }
            break :blk true;
        },
        .range => |r| blk: {
            if (r.start) |s| {
                if (!self.validateTailRecUsage(s, fn_name, false, saw_tail, bad_span)) break :blk false;
            }
            if (r.end) |e| {
                if (!self.validateTailRecUsage(e, fn_name, false, saw_tail, bad_span)) break :blk false;
            }
            break :blk true;
        },
        .await_expr => |inner| self.validateTailRecUsage(inner, fn_name, false, saw_tail, bad_span),
        .async_block => |inner| self.validateTailRecUsage(inner, fn_name, false, saw_tail, bad_span),
        .async_scope => |as| self.validateTailRecUsage(as.body, fn_name, false, saw_tail, bad_span),
        .spawn_expr => |inner| self.validateTailRecUsage(inner, fn_name, false, saw_tail, bad_span),
        .pipeline => |p| self.validateTailRecUsage(p.lhs, fn_name, false, saw_tail, bad_span) and
            self.validateTailRecUsage(p.rhs, fn_name, false, saw_tail, bad_span),
        .while_expr => |w| self.validateTailRecUsage(w.condition, fn_name, false, saw_tail, bad_span) and
            self.validateTailRecUsage(w.body, fn_name, false, saw_tail, bad_span),
        .loop_expr => |body| self.validateTailRecUsage(body, fn_name, false, saw_tail, bad_span),
        .for_expr => |f| self.validateTailRecUsage(f.iterable, fn_name, false, saw_tail, bad_span) and
            self.validateTailRecUsage(f.body, fn_name, false, saw_tail, bad_span),
        .break_expr => |v| if (v) |inner|
            self.validateTailRecUsage(inner, fn_name, false, saw_tail, bad_span)
        else
            true,
        .array_literal => |elems| blk: {
            for (elems) |elem| {
                if (!self.validateTailRecUsage(elem, fn_name, false, saw_tail, bad_span)) break :blk false;
            }
            break :blk true;
        },
        .array_comprehension => |ac| blk: {
            if (!self.validateTailRecUsage(ac.expr, fn_name, false, saw_tail, bad_span)) break :blk false;
            if (!self.validateTailRecUsage(ac.iterable, fn_name, false, saw_tail, bad_span)) break :blk false;
            if (ac.filter) |flt| {
                if (!self.validateTailRecUsage(flt, fn_name, false, saw_tail, bad_span)) break :blk false;
            }
            if (ac.clauses) |clauses| {
                for (clauses) |cl| {
                    if (!self.validateTailRecUsage(cl.iterable, fn_name, false, saw_tail, bad_span)) break :blk false;
                }
            }
            break :blk true;
        },
        .struct_literal => |sl| blk: {
            for (sl.fields) |field_init| {
                if (!self.validateTailRecUsage(field_init.value, fn_name, false, saw_tail, bad_span)) break :blk false;
            }
            break :blk true;
        },
        .enum_variant => |ev| blk: {
            for (ev.args) |arg| {
                if (!self.validateTailRecUsage(arg, fn_name, false, saw_tail, bad_span)) break :blk false;
            }
            break :blk true;
        },
        .closure => |cl| self.validateTailRecUsage(cl.body, fn_name, false, saw_tail, bad_span),
        .cast => |cast_e| self.validateTailRecUsage(cast_e.expr, fn_name, false, saw_tail, bad_span),
        .defer_expr => |inner| self.validateTailRecUsage(inner, fn_name, false, saw_tail, bad_span),
        .with_expr => |w| self.validateTailRecUsage(w.source, fn_name, false, saw_tail, bad_span) and
            self.validateTailRecUsage(w.body, fn_name, in_tail, saw_tail, bad_span),
        .record_update => |ru| blk: {
            if (!self.validateTailRecUsage(ru.source, fn_name, false, saw_tail, bad_span)) break :blk false;
            for (ru.fields) |f| {
                if (!self.validateTailRecUsage(f.value, fn_name, false, saw_tail, bad_span)) break :blk false;
            }
            break :blk true;
        },
        .yield_expr => |inner| self.validateTailRecUsage(inner, fn_name, false, saw_tail, bad_span),
        .comptime_expr => |inner| self.validateTailRecUsage(inner, fn_name, in_tail, saw_tail, bad_span),
        .select_await => |sel| blk: {
            for (sel.arms) |arm| {
                if (!self.validateTailRecUsage(arm.task, fn_name, false, saw_tail, bad_span)) break :blk false;
                if (!self.validateTailRecUsage(arm.body, fn_name, in_tail, saw_tail, bad_span)) break :blk false;
            }
            break :blk true;
        },
        else => true,
    };
}

fn hasExplicitReturn(expr: *const Ast.Expr) bool {
    return switch (expr.kind) {
        .return_expr => true,
        .block => |blk| blk: {
            for (blk.stmts) |stmt| {
                if (hasExplicitReturn(stmt)) break :blk true;
            }
            if (blk.tail) |tail| {
                if (hasExplicitReturn(tail)) break :blk true;
            }
            break :blk false;
        },
        .if_expr => |if_e| {
            const then_has = hasExplicitReturn(if_e.then_body);
            const else_has = if (if_e.else_body) |eb| hasExplicitReturn(eb) else false;
            return then_has or else_has;
        },
        .match_expr => |m| {
            for (m.arms) |arm| {
                if (hasExplicitReturn(arm.body)) return true;
            }
            return false;
        },
        else => false,
    };
}

// ── Expression type checking ─────────────────────────────────────

fn checkExpr(self: *Sema, expr: *const Ast.Expr) TypeId {
    return switch (expr.kind) {
        .int_literal => |val| {
            // Infer i32 for small values, i64 for large.
            const fits_i32 = val >= std.math.minInt(i32) and val <= std.math.maxInt(i32);
            return if (fits_i32) self.ty_i32 else self.ty_i64;
        },
        .float_literal => self.ty_f64,
        .bool_literal => self.ty_bool,
        .string_literal => self.ty_str,
        .c_string_literal => self.addType(.{ .ptr_type = .{ .pointee = self.ty_i8, .is_mut = false } }),
        .ident => |sym| self.checkIdent(sym, expr.span),
        .binary => |bin| self.checkBinary(bin, expr.span),
        .unary => |un| self.checkUnary(un, expr.span),
        .grouped => |inner| self.checkExpr(inner),
        .block => |blk| self.checkBlock(blk),
        .let_binding => |let_b| self.checkLetBinding(let_b, expr.span),
        .if_expr => |if_e| self.checkIfExpr(if_e),
        .call => |call_e| self.checkCall(call_e, expr.span),
        .return_expr => |ret_val| {
            if (self.in_defer) {
                self.emitError("non-local control flow in defer: return is not allowed inside defer blocks", expr.span);
            }
            return self.checkReturn(ret_val, expr.span);
        },
        .assign => |assign_e| self.checkAssign(assign_e, expr.span),
        .while_expr => |while_e| self.checkWhile(while_e),
        .loop_expr => |body| self.checkLoop(body),
        .for_expr => |for_e| self.checkFor(for_e),
        .break_expr => |brk_val| {
            if (self.in_defer) {
                self.emitError("non-local control flow in defer: break is not allowed inside defer blocks", expr.span);
            }
            if (brk_val) |v| {
                _ = self.checkExpr(v);
            }
            return self.ty_void;
        },
        .continue_expr => {
            if (self.in_defer) {
                self.emitError("non-local control flow in defer: continue is not allowed inside defer blocks", expr.span);
            }
            return self.ty_void;
        },
        .field_access => |fa| self.checkFieldAccess(fa, expr.span),
        .optional_chain => |oc| self.checkOptionalChain(oc, expr.span),
        .index => |idx| self.checkIndex(idx, expr.span),
        .slice => |sl| self.checkSlice(sl),
        .array_literal => |elems| self.checkArrayLiteral(elems),
        .array_comprehension => |comp| {
            // Comprehension bindings are in scope for later clauses, filter, and expr.
            var comp_scope = Scope.init();
            comp_scope.parent = self.current_scope;
            const saved_scope = self.current_scope;
            self.current_scope = &comp_scope;
            defer {
                comp_scope.deinit(self.allocator);
                self.current_scope = saved_scope;
            }

            if (comp.clauses) |clauses| {
                for (clauses) |cl| {
                    const iter_ty = self.checkExpr(cl.iterable);
                    const bind_ty = self.inferForElementType(iter_ty);
                    comp_scope.put(self.allocator, cl.binding, .{
                        .type_id = bind_ty,
                        .is_mut = false,
                        .state = .live,
                        .span = Span.zero,
                    });
                }
            } else {
                const iter_ty = self.checkExpr(comp.iterable);
                const bind_ty = self.inferForElementType(iter_ty);
                comp_scope.put(self.allocator, comp.binding, .{
                    .type_id = bind_ty,
                    .is_mut = false,
                    .state = .live,
                    .span = Span.zero,
                });
            }

            if (comp.filter) |f| _ = self.checkExpr(f);
            const elem_type = self.checkExpr(comp.expr);
            return self.addType(.{ .array_type = .{
                .element = elem_type,
                .size = 0,
            } });
        },
        .struct_literal => |sl| self.checkStructLiteral(sl, expr.span),
        .match_expr => |m| self.checkMatchExpr(m),
        .enum_variant => |ev| self.checkEnumVariant(ev, expr.span),
        .closure => |cl| self.checkClosure(cl, expr.span),
        .cast => |ca| self.checkCast(ca),
        .pipeline => |p| self.checkPipeline(p, expr.span),
        .defer_expr => |d| {
            const saved = self.in_defer;
            self.in_defer = true;
            _ = self.checkExpr(d);
            self.in_defer = saved;
            return self.ty_void;
        },
        .tuple => |elems| self.checkTuple(elems),
        .range => |r| self.checkRange(r),
        .variant_shorthand => |sym| self.checkVariantShorthand(sym, expr.span, self.expected_expr_type),
        .with_expr => |w| {
            const source_ty = self.checkExpr(w.source);
            var bind_ty = source_ty;
            var used_guard_enter = false;
            if (source_ty != error_type) {
                const resolved = self.resolveAlias(source_ty);
                if (self.getTypeName(resolved)) |tn_sym| {
                    const enter_name = if (w.is_mut) "enter_mut" else "enter";
                    const enter_sym = self.pool.intern(enter_name) catch 0;
                    if (enter_sym != 0) {
                        const key = self.methodKey(tn_sym, enter_sym);
                        if (self.fn_sigs.get(key)) |sig| {
                            bind_ty = sig.return_type;
                            used_guard_enter = true;
                        }
                    }
                }
            }
            // Bind the name in a child scope.
            var with_scope = Scope.init();
            with_scope.parent = self.current_scope;
            const saved_scope = self.current_scope;
            self.current_scope = &with_scope;
            defer {
                with_scope.deinit(self.allocator);
                self.current_scope = saved_scope;
            }
            self.current_scope.put(self.allocator, w.name, .{
                .type_id = bind_ty,
                .is_mut = w.is_mut,
                .span = expr.span,
                .state = .live,
            });
            const body_ty = self.checkExpr(w.body);
            // Form 2 builder rule: for mutable non-guarded `with`,
            // if body tail is Unit, result is the mutated binding.
            if (w.is_mut and !used_guard_enter and body_ty == self.ty_void) {
                return source_ty;
            }
            return body_ty;
        },
        .record_update => |ru| {
            const source_ty = self.checkExpr(ru.source);
            if (source_ty == error_type) {
                for (ru.fields) |f| {
                    _ = self.checkExpr(f.value);
                }
                return error_type;
            }

            const resolved = self.resolveAlias(source_ty);
            if (self.getType(resolved) != .struct_type) {
                self.emitError("record update source must be a struct", expr.span);
                for (ru.fields) |f| {
                    _ = self.checkExpr(f.value);
                }
                return error_type;
            }

            const st = self.getType(resolved).struct_type;
            for (ru.fields) |f| {
                const value_ty = self.checkExpr(f.value);

                var found_index: ?usize = null;
                for (st.field_names, 0..) |fname, i| {
                    if (fname == f.name) {
                        found_index = i;
                        break;
                    }
                }
                if (found_index == null) {
                    self.emitError("unknown struct field", f.span);
                    continue;
                }

                const idx = found_index.?;
                const expected_ty = st.field_types[idx];
                if (expected_ty != error_type and value_ty != error_type) {
                    if (self.isImplicitNarrowing(expected_ty, value_ty)) {
                        self.emitError("E0201: implicit narrowing conversion", f.span);
                    } else if (!self.typesCompatible(expected_ty, value_ty) and self.arithmeticResultType(expected_ty, value_ty) == error_type) {
                        var buf: [256]u8 = undefined;
                        const expected_name = self.typeName(expected_ty);
                        const actual_name = self.typeName(value_ty);
                        const msg = std.fmt.bufPrint(
                            &buf,
                            "type mismatch for record update field: expected '{s}', found '{s}'",
                            .{ expected_name, actual_name },
                        ) catch "record update field type mismatch";
                        const alloc_msg = self.allocator.dupe(u8, msg) catch "record update field type mismatch";
                        self.emitError(alloc_msg, f.span);
                    }
                }
            }
            return source_ty;
        },
        .let_else => |le| {
            const val_type = self.checkExpr(le.value);
            // Each binding gets the value's type (payload type not yet resolved in sema).
            for (le.pattern.bindings) |bind_sym| {
                self.current_scope.put(self.allocator, bind_sym, .{
                    .type_id = val_type,
                    .is_mut = le.is_mut,
                    .span = expr.span,
                    .state = .live,
                });
            }
            _ = self.checkExpr(le.else_body);
            if (!self.exprDefinitelyDiverges(le.else_body)) {
                self.emitError("let ... else requires a diverging else branch", le.else_body.span);
            }
            return self.ty_void;
        },
        .tuple_destructure => |td| {
            const val_type = self.checkExpr(td.value);
            if (td.pattern) |pat| {
                self.checkTupleDestructurePattern(&pat, val_type, td.is_mut);
            } else {
                const resolved = self.resolveAlias(val_type);
                const type_info = self.getType(resolved);
                // Legacy flat tuple destructure path.
                for (td.names, 0..) |name, i| {
                    const elem_type = if (type_info == .tuple_type and i < type_info.tuple_type.elements.len)
                        type_info.tuple_type.elements[i]
                    else
                        error_type;
                    self.current_scope.put(self.allocator, name, .{
                        .type_id = elem_type,
                        .is_mut = td.is_mut,
                        .span = expr.span,
                        .state = .live,
                    });
                }
            }
            return self.ty_void;
        },
        .poisoned => error_type,
        .await_expr => |inner| {
            if (self.hasLiveAwaitGuard()) {
                self.emitError("E0701: may_suspend call while no_await_guard value is live", expr.span);
            }
            const awaited_ty = self.checkExpr(inner);
            if (!self.exprIsTask(inner)) {
                self.emitError("await requires a Task value", expr.span);
            }
            return awaited_ty;
        },
        .async_block => |inner| self.checkExpr(inner),
        .spawn_expr => |inner| {
            _ = self.checkExpr(inner);
            if (!self.exprIsTask(inner)) {
                self.emitError("spawn requires a Task value", expr.span);
            }
            return self.ty_void;
        },
        .async_scope => |as| {
            var scope = Scope.init();
            scope.parent = self.current_scope;
            const saved_scope = self.current_scope;
            self.current_scope = &scope;
            defer {
                scope.deinit(self.allocator);
                self.current_scope = saved_scope;
            }

            self.current_scope.put(self.allocator, as.name, .{
                .type_id = self.ty_void,
                .is_mut = false,
                .state = .live,
                .span = expr.span,
            });

            var pushed_async_scope = false;
            if (self.active_async_scope_depth < self.active_async_scope_symbols.len) {
                self.active_async_scope_symbols[self.active_async_scope_depth] = as.name;
                self.active_async_scope_depth += 1;
                pushed_async_scope = true;
            }
            defer {
                if (pushed_async_scope) self.active_async_scope_depth -= 1;
            }

            return self.checkExpr(as.body);
        },
        .comptime_expr => |inner| self.checkExpr(inner),
        .select_await => |sel| {
            if (self.hasLiveAwaitGuard()) {
                self.emitError("E0701: may_suspend call while no_await_guard value is live", expr.span);
            }
            if (sel.arms.len == 0) {
                self.emitError("select await requires at least one arm", expr.span);
                return error_type;
            }
            var result_ty = self.ty_void;
            for (sel.arms) |arm| {
                _ = self.checkExpr(arm.task);
                if (!self.exprIsTask(arm.task)) {
                    self.emitError("select await arm requires a Task value", arm.task.span);
                }
                var arm_scope = Scope.init();
                arm_scope.parent = self.current_scope;
                const saved_scope = self.current_scope;
                self.current_scope = &arm_scope;
                self.current_scope.put(self.allocator, arm.name, .{
                    .type_id = self.ty_i32,
                    .is_mut = false,
                    .span = arm.span,
                    .state = .live,
                });
                result_ty = self.checkExpr(arm.body);
                arm_scope.deinit(self.allocator);
                self.current_scope = saved_scope;
            }
            return result_ty;
        },
        .yield_expr => |inner| {
            const inner_ty = self.checkExpr(inner);
            if (self.current_gen_yield_type) |yield_ty| {
                if (yield_ty != error_type and inner_ty != error_type) {
                    if (self.isImplicitNarrowing(yield_ty, inner_ty)) {
                        self.emitError("E0201: implicit narrowing conversion", expr.span);
                    } else if (!self.typesCompatible(yield_ty, inner_ty) and self.arithmeticResultType(yield_ty, inner_ty) == error_type) {
                        var buf: [256]u8 = undefined;
                        const expected = self.typeName(yield_ty);
                        const actual = self.typeName(inner_ty);
                        const msg = std.fmt.bufPrint(&buf, "yield type mismatch: expected '{s}', found '{s}'", .{
                            expected,
                            actual,
                        }) catch "yield type mismatch";
                        const alloc_msg = self.allocator.dupe(u8, msg) catch "yield type mismatch";
                        self.emitError(alloc_msg, expr.span);
                    }
                }
            } else {
                self.emitError("yield used outside generator function", expr.span);
            }
            return self.ty_void;
        },
    };
}

fn checkExprWithExpected(self: *Sema, expr: *const Ast.Expr, expected: ?TypeId) TypeId {
    const saved = self.expected_expr_type;
    self.expected_expr_type = expected;
    defer self.expected_expr_type = saved;
    return self.checkExpr(expr);
}

fn checkIdent(self: *Sema, sym: Symbol, span: Span) TypeId {
    // Check local/param scope.
    if (self.current_scope.lookup(sym)) |info| {
        // Move semantics: check for use-after-move.
        if (info.state == .moved) {
            self.emitError("use of moved value", span);
            return info.type_id;
        }
        return info.type_id;
    }

    // Check function names (for function pointer references).
    if (self.fn_sigs.get(sym)) |sig| {
        return sig.type_id;
    }

    // Check generic functions.
    if (self.generic_fns.get(sym)) |_| {
        return error_type; // Generic functions need to be called, not referenced directly.
    }

    // Check type names (for static method calls like Counter.new).
    if (self.named_types.get(sym)) |tid| {
        return tid;
    }

    // Check enum variants (bare name like `None`, `Red`).
    if (self.variant_lookup.get(sym)) |vi| {
        return vi.enum_type;
    }

    // Built-in functions.
    if (self.isBuiltinFn(sym)) {
        return error_type; // Built-ins are checked at call sites.
    }

    // Built-in values (None).
    if (self.isBuiltinValue(sym)) {
        return error_type; // Codegen handles the actual type.
    }

    // Unknown identifier — report error.
    self.emitError("undefined variable", span);
    return error_type;
}

fn checkBinary(self: *Sema, bin: Ast.BinaryExpr, span: Span) TypeId {
    const lhs = self.checkExpr(bin.lhs);
    const rhs = self.checkExpr(bin.rhs);

    // Error recovery: if either side is error, propagate.
    if (lhs == error_type or rhs == error_type) return error_type;
    const lhs_ty = self.getType(self.resolveAlias(lhs));
    const rhs_ty = self.getType(self.resolveAlias(rhs));

    return switch (bin.op) {
        // Comparison operators return bool.
        .eq, .neq, .lt, .gt, .lte, .gte => self.ty_bool,
        // Logical operators require bool operands and return bool.
        .@"and", .@"or" => blk: {
            if (lhs != self.ty_bool) {
                self.emitError("left operand of logical operator must be bool", span);
            }
            if (rhs != self.ty_bool) {
                self.emitError("right operand of logical operator must be bool", span);
            }
            break :blk self.ty_bool;
        },
        // Arithmetic: result type is the wider/left type.
        .add, .sub, .mul, .div, .mod => blk: {
            if (bin.op == .add and lhs == self.ty_str and rhs == self.ty_str) {
                break :blk self.ty_str;
            }
            const result = self.arithmeticResultType(lhs, rhs);
            if (result != error_type) break :blk result;
            if (self.operatorOverloadReturnType(bin.op, lhs, rhs, span)) |overload_ret| {
                break :blk overload_ret;
            }
            self.emitError("arithmetic operator requires numeric operands", span);
            break :blk error_type;
        },
        // Bitwise operations.
        .bit_and, .bit_or, .bit_xor, .shl, .shr => blk: {
            if (!isIntType(lhs_ty) or !isIntType(rhs_ty)) {
                self.emitError("bitwise operator requires integer operands", span);
                break :blk error_type;
            }
            break :blk lhs;
        },
        // Wrapping arithmetic.
        .add_wrap, .sub_wrap, .mul_wrap => blk: {
            if (!isIntType(lhs_ty) or !isIntType(rhs_ty)) {
                self.emitError("wrapping arithmetic requires integer operands", span);
                break :blk error_type;
            }
            break :blk lhs;
        },
        // Default operator (??).
        .default_op => lhs,
    };
}

fn operatorOverloadMethodName(op: Ast.BinOp) ?[]const u8 {
    return switch (op) {
        .add => "add",
        .sub => "sub",
        .mul => "mul",
        .div => "div",
        .mod => "mod",
        else => null,
    };
}

fn operatorOverloadReturnType(self: *Sema, op: Ast.BinOp, lhs: TypeId, rhs: TypeId, span: Span) ?TypeId {
    const method_name = operatorOverloadMethodName(op) orelse return null;
    const type_sym = self.getTypeName(self.resolveAlias(lhs)) orelse return null;
    const method_sym = self.pool.intern(method_name) catch return null;
    const key = self.methodKey(type_sym, method_sym);
    const sig = self.fn_sigs.get(key) orelse return null;

    if (sig.param_types.len >= 2) {
        const rhs_expected = sig.param_types[1];
        if (rhs_expected != error_type and rhs != error_type and
            !self.typesCompatible(rhs_expected, rhs) and
            self.arithmeticResultType(rhs_expected, rhs) == error_type)
        {
            self.emitError("operator overload rhs type mismatch", span);
            return error_type;
        }
    }

    return sig.return_type;
}

fn checkUnary(self: *Sema, un: Ast.UnaryExpr, span: Span) TypeId {
    const operand = self.checkExpr(un.operand);
    if (operand == error_type) return error_type;

    return switch (un.op) {
        .negate => operand,
        .not => self.ty_bool,
        .ref_of => {
            // Borrow checking: create shared borrow.
            self.checkBorrowCreate(un.operand, .shared, span);
            return self.addType(.{ .ref_type = .{
                .pointee = operand,
                .is_mut = false,
            } });
        },
        .mut_ref_of => {
            // Borrow checking: create exclusive borrow.
            self.checkBorrowCreate(un.operand, .exclusive, span);
            return self.addType(.{ .ref_type = .{
                .pointee = operand,
                .is_mut = true,
            } });
        },
        .deref => {
            const resolved = self.resolveAlias(operand);
            switch (self.getType(resolved)) {
                .ref_type => |rt| return rt.pointee,
                .ptr_type => |pt| return pt.pointee,
                else => {
                    // Don't report error — codegen may handle this differently.
                    return error_type;
                },
            }
        },
        .try_op => {
            if (self.in_defer) {
                self.emitError("non-local control flow in defer: ? operator is not allowed inside defer blocks", un.operand.span);
            }
            const resolved = self.resolveAlias(operand);
            if (self.getType(resolved) != .enum_type) {
                self.emitError("? operator requires Option or Result", span);
                return error_type;
            }

            const et = self.getType(resolved).enum_type;
            var payload_ty: TypeId = error_type;
            var matched = false;
            for (et.variant_names, 0..) |vn, i| {
                const name = self.pool.resolve(vn);
                if (std.mem.eql(u8, name, "Some") or std.mem.eql(u8, name, "Ok")) {
                    matched = true;
                    if (et.variant_payloads[i]) |payloads| {
                        if (payloads.len > 0) payload_ty = payloads[0];
                    }
                    break;
                }
            }
            if (!matched) {
                self.emitError("? operator requires Option or Result", span);
                return error_type;
            }

            // If payload type cannot be recovered, keep analysis permissive.
            if (payload_ty == error_type) return error_type;
            return payload_ty;
        },
    };
}

fn checkBlock(self: *Sema, blk: Ast.BlockExpr) TypeId {
    // Push block scope.
    var block_scope = Scope.init();
    block_scope.parent = self.current_scope;
    const saved = self.current_scope;
    self.current_scope = &block_scope;
    defer {
        // Expire borrows for bindings in this scope (NLL).
        self.expireBorrowsInScope(&block_scope);
        block_scope.deinit(self.allocator);
        self.current_scope = saved;
    }

    var saw_diverging = false;
    for (blk.stmts, 0..) |stmt, stmt_index| {
        if (saw_diverging) {
            self.emitWarning("E0601: unreachable code after return/break/continue", stmt.span);
            break;
        }
        const stmt_ty = self.checkExpr(stmt);
        // Detect diverging statements.
        if (self.exprDefinitelyDiverges(stmt)) {
            saw_diverging = true;
        }
        // Denied pattern diagnostics for discarded values.
        const is_discarded_task = stmt.kind != .spawn_expr and self.exprIsTask(stmt) and !self.exprIsScopedTask(stmt);
        if (is_discarded_task) {
            self.emitWarning("E0801: unused Task value", stmt.span);
        }
        if (stmt.kind == .call) {
            const call_e = stmt.kind.call;
            if (call_e.callee.kind == .ident) {
                const fn_sym = call_e.callee.kind.ident;
                if (self.result_option_fns.get(fn_sym) != null) {
                    self.emitWarning("E0802: unused Result/Option value", stmt.span);
                } else if (self.must_use_fns.get(fn_sym) != null) {
                    self.emitWarning("E0802: return value of @[must_use] function is discarded", stmt.span);
                }
            }
        }
        if (stmt.kind != .call and self.isResultOrOptionTypeId(stmt_ty)) {
            self.emitWarning("E0802: unused Result/Option value", stmt.span);
        }

        // NLL-like expiration: end borrows once their binding is no longer used.
        self.expireDeadBorrows(blk.stmts[stmt_index + 1 ..], blk.tail);
    }

    if (blk.tail) |tail| {
        if (saw_diverging) {
            self.emitWarning("E0601: unreachable code after return/break/continue", tail.span);
            self.expireDeadBorrows(&.{}, null);
            return error_type;
        }
        const tail_ty = self.checkExpr(tail);
        self.expireDeadBorrows(&.{}, null);
        return tail_ty;
    }

    self.expireDeadBorrows(&.{}, null);
    return self.ty_void;
}

fn checkLetBinding(self: *Sema, let_b: Ast.LetBinding, span: Span) TypeId {
    var annotated_type: ?TypeId = null;
    if (let_b.type_expr) |te| {
        annotated_type = self.resolveTypeExpr(te);
    }
    const val_type = self.checkExprWithExpected(let_b.value, annotated_type);

    // Determine binding type from annotation or inference.
    const bind_type = if (let_b.type_expr) |_| blk: {
        const annotated = annotated_type orelse error_type;
        // Check compatibility between annotated and inferred types.
        if (annotated != error_type and val_type != error_type) {
            if (self.isImplicitNarrowing(annotated, val_type)) {
                self.emitError("E0201: implicit narrowing conversion", span);
            } else if (!self.typesCompatible(annotated, val_type) and self.arithmeticResultType(annotated, val_type) == error_type) {
                var buf: [256]u8 = undefined;
                const expected = self.typeName(annotated);
                const actual = self.typeName(val_type);
                const name_str = self.pool.resolve(let_b.name);
                const msg = std.fmt.bufPrint(&buf, "type mismatch in binding '{s}': expected '{s}', found '{s}'", .{ name_str, expected, actual }) catch "type mismatch in let binding";
                const alloc_msg = self.allocator.dupe(u8, msg) catch "type mismatch in let binding";
                self.emitError(alloc_msg, span);
            }
        }
        break :blk annotated;
    } else val_type;

    if (let_b.type_expr) |te| {
        if (typeExprIsCollectionWithRef(self, te)) {
            self.emitError("ephemeral references cannot be stored in collections", span);
        }
    }

    // `let x = y` consumes `y` when `y` is a non-Copy value.
    self.markMovedIfConsumed(let_b.value);

    const is_task_binding = self.exprIsTask(let_b.value);
    const is_scoped_task_binding = self.exprIsScopedTask(let_b.value);
    self.current_scope.put(self.allocator, let_b.name, .{
        .type_id = bind_type,
        .is_mut = let_b.is_mut,
        .is_task = is_task_binding,
        .is_ephemeral_task = is_task_binding and self.exprIsEphemeralTask(let_b.value),
        .is_scoped_task = is_scoped_task_binding,
        .state = .live,
        .span = span,
    });

    // If the value is a &expr, tag the most recent borrow with this binding.
    if (let_b.value.kind == .unary) {
        const op = let_b.value.kind.unary.op;
        if (op == .ref_of or op == .mut_ref_of) {
            if (self.active_borrows.items.len > 0) {
                self.active_borrows.items[self.active_borrows.items.len - 1].ref_binding = let_b.name;
            }
        }
    }

    return self.ty_void;
}

fn checkIfExpr(self: *Sema, if_e: Ast.IfExpr) TypeId {
    const cond = self.checkExpr(if_e.condition);
    _ = cond;

    const then_type = self.checkExpr(if_e.then_body);

    if (if_e.else_body) |else_body| {
        const else_type = self.checkExpr(else_body);
        // If both branches produce non-error types, they should be compatible.
        if (then_type != error_type and else_type != error_type) {
            if (self.typesCompatible(then_type, else_type)) {
                return then_type;
            }
            // Allow numeric coercion (e.g., i32 and i64).
            return self.arithmeticResultType(then_type, else_type);
        }
        if (then_type != error_type) return then_type;
        return else_type;
    }

    return then_type;
}

fn checkReturn(self: *Sema, ret_val: ?*const Ast.Expr, span: Span) TypeId {
    if (ret_val) |val| {
        const expected_ty = if (self.current_return_type != error_type) self.current_return_type else null;
        const val_type = self.checkExprWithExpected(val, expected_ty);
        // Check return type compatibility.
        if (self.current_return_type != error_type and val_type != error_type) {
            if (self.isImplicitNarrowing(self.current_return_type, val_type)) {
                self.emitError("E0201: implicit narrowing conversion", span);
            } else if (!self.typesCompatible(self.current_return_type, val_type) and self.arithmeticResultType(self.current_return_type, val_type) == error_type) {
                var buf: [256]u8 = undefined;
                const expected = self.typeName(self.current_return_type);
                const actual = self.typeName(val_type);
                const msg = std.fmt.bufPrint(&buf, "return type mismatch: expected '{s}', found '{s}'", .{ expected, actual }) catch "return type mismatch";
                const alloc_msg = self.allocator.dupe(u8, msg) catch "return type mismatch";
                self.emitError(alloc_msg, span);
            }
        }
    }
    return self.ty_void;
}

fn checkAssign(self: *Sema, assign_e: Ast.AssignExpr, span: Span) TypeId {
    const target_type = self.checkExpr(assign_e.target);
    const value_type = self.checkExprWithExpected(assign_e.value, if (target_type != error_type) target_type else null);

    // Check mutability: target must be mutable.
    if (assign_e.target.kind == .ident) {
        const target_sym = assign_e.target.kind.ident;
        if (self.current_scope.lookup(target_sym)) |info| {
            if (!info.is_mut) {
                var buf: [256]u8 = undefined;
                const name_str = self.pool.resolve(target_sym);
                const msg = std.fmt.bufPrint(&buf, "cannot assign to immutable variable '{s}'", .{name_str}) catch "immutable assignment";
                const alloc_msg = self.allocator.dupe(u8, msg) catch "immutable assignment";
                self.emitError(alloc_msg, span);
            }
        }
    }

    // Check type compatibility.
    if (target_type != error_type and value_type != error_type) {
        if (self.isImplicitNarrowing(target_type, value_type)) {
            self.emitError("E0201: implicit narrowing conversion", span);
        } else if (!self.typesCompatible(target_type, value_type) and self.arithmeticResultType(target_type, value_type) == error_type) {
            var buf: [256]u8 = undefined;
            const expected = self.typeName(target_type);
            const actual = self.typeName(value_type);
            const msg = std.fmt.bufPrint(&buf, "type mismatch in assignment: expected '{s}', found '{s}'", .{ expected, actual }) catch "type mismatch";
            const alloc_msg = self.allocator.dupe(u8, msg) catch "type mismatch";
            self.emitError(alloc_msg, span);
        }
    }

    // `x = y` consumes `y` when `y` is a non-Copy value.
    self.markMovedIfConsumed(assign_e.value);

    // Assignment reinitializes the target (state → live).
    if (assign_e.target.kind == .ident) {
        const target_sym = assign_e.target.kind.ident;
        if (self.current_scope.lookupMut(target_sym)) |info| {
            info.state = .live;
            const is_task = self.exprIsTask(assign_e.value);
            info.is_task = is_task;
            info.is_ephemeral_task = is_task and self.exprIsEphemeralTask(assign_e.value);
            info.is_scoped_task = self.exprIsScopedTask(assign_e.value);
        }
    }

    return self.ty_void;
}

fn markMovedIfConsumed(self: *Sema, expr: *const Ast.Expr) void {
    switch (expr.kind) {
        .ident => |sym| {
            if (self.current_scope.lookupMut(sym)) |info| {
                if (!self.isCopy(info.type_id)) {
                    info.state = .moved;
                }
            }
        },
        .grouped => |inner| self.markMovedIfConsumed(inner),
        else => {},
    }
}

fn exprIsTask(self: *Sema, expr: *const Ast.Expr) bool {
    return switch (expr.kind) {
        .ident => |sym| blk: {
            if (self.current_scope.lookup(sym)) |info| break :blk info.is_task;
            break :blk false;
        },
        .call => |call_e| blk: {
            if (call_e.callee.kind == .field_access) {
                const fa = call_e.callee.kind.field_access;
                if (fa.expr.kind == .ident and self.isActiveAsyncScopeSymbol(fa.expr.kind.ident)) {
                    if (std.mem.eql(u8, self.pool.resolve(fa.field), "track")) break :blk true;
                }
            }
            if (call_e.callee.kind == .ident) {
                if (self.task_fns.get(call_e.callee.kind.ident) != null) break :blk true;
            }
            break :blk false;
        },
        .async_block => true,
        .grouped => |inner| self.exprIsTask(inner),
        else => false,
    };
}

fn isActiveAsyncScopeSymbol(self: *Sema, sym: Symbol) bool {
    var i: usize = self.active_async_scope_depth;
    while (i > 0) {
        i -= 1;
        if (self.active_async_scope_symbols[i] == sym) return true;
    }
    return false;
}

fn exprIsScopedTask(self: *Sema, expr: *const Ast.Expr) bool {
    return switch (expr.kind) {
        .ident => |sym| blk: {
            if (self.current_scope.lookup(sym)) |info| break :blk info.is_scoped_task;
            break :blk false;
        },
        .call => |call_e| blk: {
            if (call_e.callee.kind == .field_access) {
                const fa = call_e.callee.kind.field_access;
                if (fa.expr.kind == .ident and self.isActiveAsyncScopeSymbol(fa.expr.kind.ident)) {
                    if (std.mem.eql(u8, self.pool.resolve(fa.field), "track")) break :blk true;
                }
            }
            break :blk false;
        },
        .grouped => |inner| self.exprIsScopedTask(inner),
        else => false,
    };
}

fn typeIsEphemeralValue(self: *Sema, ty: TypeId) bool {
    if (ty == error_type) return false;
    const resolved = self.resolveAlias(ty);
    return switch (self.getType(resolved)) {
        .ref_type => true,
        .slice_type => true,
        .tuple_type => |tt| blk: {
            for (tt.elements) |elem| {
                if (self.typeIsEphemeralValue(elem)) break :blk true;
            }
            break :blk false;
        },
        .array_type => |at| self.typeIsEphemeralValue(at.element),
        else => false,
    };
}

fn paramIsByReference(self: *Sema, ty: TypeId) bool {
    if (ty == error_type) return false;
    const resolved = self.resolveAlias(ty);
    return switch (self.getType(resolved)) {
        .ref_type, .ptr_type => true,
        else => false,
    };
}

fn exprIsEphemeralValue(self: *Sema, expr: *const Ast.Expr) bool {
    return switch (expr.kind) {
        .ident => |sym| blk: {
            if (self.current_scope.lookup(sym)) |info| {
                if (info.is_ephemeral_task) break :blk true;
                break :blk self.typeIsEphemeralValue(info.type_id);
            }
            break :blk false;
        },
        .unary => |un| switch (un.op) {
            .ref_of, .mut_ref_of => true,
            else => self.exprIsEphemeralValue(un.operand),
        },
        .grouped => |inner| self.exprIsEphemeralValue(inner),
        .slice => true,
        .call => self.exprIsEphemeralTask(expr),
        else => false,
    };
}

fn asyncBlockCapturesEphemeral(self: *Sema, body: *const Ast.Expr) bool {
    var pseudo_scope = Scope.init();
    defer pseudo_scope.deinit(self.allocator);
    pseudo_scope.parent = self.current_scope;

    var captures: std.ArrayList(CaptureInfo) = .empty;
    defer captures.deinit(self.allocator);
    self.collectCaptures(body, &pseudo_scope, self.current_scope, &captures);

    for (captures.items) |cap| {
        if (self.typeIsEphemeralValue(cap.type_id)) return true;
        if (self.current_scope.lookup(cap.symbol)) |info| {
            if (info.is_ephemeral_task) return true;
        }
    }
    return false;
}

fn exprIsEphemeralTask(self: *Sema, expr: *const Ast.Expr) bool {
    return switch (expr.kind) {
        .ident => |sym| blk: {
            if (self.current_scope.lookup(sym)) |info| break :blk info.is_ephemeral_task;
            break :blk false;
        },
        .call => |call_e| blk: {
            if (call_e.callee.kind != .ident) break :blk false;
            if (self.task_fns.get(call_e.callee.kind.ident) == null) break :blk false;
            for (call_e.args) |arg| {
                if (self.exprIsEphemeralValue(arg)) break :blk true;
            }
            break :blk false;
        },
        .async_block => |body| self.asyncBlockCapturesEphemeral(body),
        .grouped => |inner| self.exprIsEphemeralTask(inner),
        else => false,
    };
}

fn closureExprCapturesNonSend(self: *Sema, expr: *const Ast.Expr) bool {
    return switch (expr.kind) {
        .closure => |cl| blk: {
            if (self.closure_analyses.get(@intFromPtr(cl.body))) |analysis| {
                for (analysis.captures) |cap| {
                    if (self.typeIsEphemeralValue(cap.type_id)) break :blk true;
                    if (self.current_scope.lookup(cap.symbol)) |info| {
                        if (info.is_ephemeral_task) break :blk true;
                    }
                }
            }
            break :blk false;
        },
        .grouped => |inner| self.closureExprCapturesNonSend(inner),
        else => false,
    };
}

fn inferForElementType(self: *Sema, iterable_type: TypeId) TypeId {
    if (iterable_type == error_type) return error_type;
    const resolved = self.resolveAlias(iterable_type);
    switch (self.getType(resolved)) {
        .range_type => |rt| return rt.element,
        .array_type => |at| return at.element,
        .slice_type => |st| return st.element,
        else => return self.ty_i32,
    }
}

fn checkTupleDestructurePattern(self: *Sema, pattern: *const Ast.Pattern, subject_type: TypeId, is_mut: bool) void {
    switch (pattern.kind) {
        .wildcard => {},
        .binding => |sym| {
            self.current_scope.put(self.allocator, sym, .{
                .type_id = subject_type,
                .is_mut = is_mut,
                .state = .live,
                .span = pattern.span,
            });
        },
        .tuple_pattern => |elems| {
            const resolved = self.resolveAlias(subject_type);
            const ty = self.getType(resolved);
            if (ty != .tuple_type) {
                self.emitError("tuple destructuring requires tuple type", pattern.span);
                for (elems) |*elem| {
                    self.checkTupleDestructurePattern(elem, error_type, is_mut);
                }
                return;
            }
            const tuple_elems = ty.tuple_type.elements;
            if (elems.len != tuple_elems.len) {
                self.emitError("tuple destructuring arity mismatch", pattern.span);
            }
            const n = @min(elems.len, tuple_elems.len);
            for (elems[0..n], 0..) |*elem, i| {
                self.checkTupleDestructurePattern(elem, tuple_elems[i], is_mut);
            }
            for (elems[n..]) |*elem| {
                self.checkTupleDestructurePattern(elem, error_type, is_mut);
            }
        },
        else => {
            self.emitError("tuple destructuring only supports bindings, wildcards, and nested tuple patterns", pattern.span);
        },
    }
}

fn checkWhile(self: *Sema, while_e: Ast.WhileExpr) TypeId {
    _ = self.checkExpr(while_e.condition);
    _ = self.checkExpr(while_e.body);
    return self.ty_void;
}

fn checkLoop(self: *Sema, body: *const Ast.Expr) TypeId {
    _ = self.checkExpr(body);
    return self.ty_void;
}

fn exprDefinitelyDiverges(self: *Sema, expr: *const Ast.Expr) bool {
    return switch (expr.kind) {
        .return_expr, .break_expr, .continue_expr => true,
        .block => |blk| blk: {
            for (blk.stmts) |stmt| {
                if (self.exprDefinitelyDiverges(stmt)) break :blk true;
            }
            if (blk.tail) |tail| break :blk self.exprDefinitelyDiverges(tail);
            break :blk false;
        },
        .if_expr => |if_e| blk: {
            if (if_e.else_body) |else_body| {
                break :blk self.exprDefinitelyDiverges(if_e.then_body) and self.exprDefinitelyDiverges(else_body);
            }
            break :blk false;
        },
        .match_expr => |m| blk: {
            if (m.arms.len == 0) break :blk false;
            for (m.arms) |arm| {
                if (!self.exprDefinitelyDiverges(arm.body)) break :blk false;
            }
            break :blk true;
        },
        .loop_expr => true,
        else => false,
    };
}

fn checkFor(self: *Sema, for_e: Ast.ForExpr) TypeId {
    const iterable_type = self.checkExpr(for_e.iterable);
    const loop_var_type = self.inferForElementType(iterable_type);

    // Add loop variable to scope.
    var for_scope = Scope.init();
    for_scope.parent = self.current_scope;
    const saved = self.current_scope;
    self.current_scope = &for_scope;
    defer {
        for_scope.deinit(self.allocator);
        self.current_scope = saved;
    }

    if (for_e.binding_pattern) |bp| {
        self.checkTupleDestructurePattern(&bp, loop_var_type, false);
    } else {
        // Infer loop variable from iterable when available.
        for_scope.put(self.allocator, for_e.binding, .{
            .type_id = loop_var_type,
            .is_mut = false,
            .state = .live,
            .span = Span.zero,
        });
    }

    // If there's an index binding, add it to scope too.
    if (for_e.index_binding) |idx_sym| {
        for_scope.put(self.allocator, idx_sym, .{
            .type_id = self.ty_i64,
            .is_mut = false,
            .state = .live,
            .span = Span.zero,
        });
    }

    _ = self.checkExpr(for_e.body);
    return self.ty_void;
}

fn checkOptionalChain(self: *Sema, oc: Ast.OptionalChainExpr, span: Span) TypeId {
    const base_ty = self.checkExpr(oc.expr);
    if (base_ty == error_type) {
        if (oc.args) |args| {
            for (args) |arg| _ = self.checkExpr(arg);
        }
        return error_type;
    }

    const resolved = self.resolveAlias(base_ty);
    if (self.getType(resolved) != .enum_type) {
        self.emitError("optional chaining requires Option or Result", span);
        if (oc.args) |args| {
            for (args) |arg| _ = self.checkExpr(arg);
        }
        return error_type;
    }

    const et = self.getType(resolved).enum_type;
    var payload_ty: TypeId = error_type;
    var matched = false;
    for (et.variant_names, 0..) |vn, i| {
        const name = self.pool.resolve(vn);
        if (std.mem.eql(u8, name, "Some") or std.mem.eql(u8, name, "Ok")) {
            matched = true;
            if (et.variant_payloads[i]) |payloads| {
                if (payloads.len > 0) payload_ty = payloads[0];
            }
            break;
        }
    }
    if (!matched) {
        self.emitError("optional chaining requires Option or Result", span);
        if (oc.args) |args| {
            for (args) |arg| _ = self.checkExpr(arg);
        }
        return error_type;
    }

    // Validate member access/call against the payload type when available.
    if (payload_ty != error_type) {
        var tmp_scope = Scope.init();
        tmp_scope.parent = self.current_scope;
        const saved_scope = self.current_scope;
        self.current_scope = &tmp_scope;
        defer {
            tmp_scope.deinit(self.allocator);
            self.current_scope = saved_scope;
        }

        const payload_sym = self.pool.intern("__opt_payload") catch 0;
        if (payload_sym != 0) {
            self.current_scope.put(self.allocator, payload_sym, .{
                .type_id = payload_ty,
                .is_mut = false,
                .state = .live,
                .span = span,
            });
            const payload_expr = Ast.Expr{
                .kind = .{ .ident = payload_sym },
                .span = span,
            };
            const member_expr = Ast.FieldAccessExpr{
                .expr = &payload_expr,
                .field = oc.member,
            };
            if (oc.args) |args| {
                _ = self.checkMethodCall(member_expr, args, span);
            } else {
                _ = self.checkFieldAccess(member_expr, span);
            }
        } else if (oc.args) |args| {
            for (args) |arg| _ = self.checkExpr(arg);
        }
    } else if (oc.args) |args| {
        for (args) |arg| _ = self.checkExpr(arg);
    }

    // Preserve container typing (Option/Result).
    return base_ty;
}

fn checkFieldAccess(self: *Sema, fa: Ast.FieldAccessExpr, span: Span) TypeId {
    const obj_type = self.checkExpr(fa.expr);
    if (obj_type == error_type) return error_type;

    const resolved = self.resolveAlias(obj_type);
    const field_base = switch (self.getType(resolved)) {
        .ptr_type => |pt| self.resolveAlias(pt.pointee),
        .ref_type => |rt| self.resolveAlias(rt.pointee),
        else => resolved,
    };

    switch (self.getType(field_base)) {
        .struct_type => |st| {
            // Look up field.
            for (st.field_names, 0..) |fname, i| {
                if (fname == fa.field) {
                    return st.field_types[i];
                }
            }
            // Check for method (Type.method).
            // Methods are stored as regular functions with mangled names.
            self.emitError("unknown struct field", span);
            return error_type;
        },
        .tuple_type => |tt| {
            // Tuple field access: .0, .1, etc.
            const field_name = self.pool.resolve(fa.field);
            const idx = std.fmt.parseInt(u32, field_name, 10) catch return error_type;
            if (idx < tt.elements.len) {
                return tt.elements[idx];
            }
            self.emitError("tuple index out of bounds", span);
            return error_type;
        },
        .array_type => {
            // .len on arrays returns i64.
            const field_name = self.pool.resolve(fa.field);
            if (std.mem.eql(u8, field_name, "len")) {
                return self.ty_i64;
            }
            self.emitError("unknown array field", span);
            return error_type;
        },
        .slice_type => {
            // .len and .ptr on slices.
            const field_name = self.pool.resolve(fa.field);
            if (std.mem.eql(u8, field_name, "len")) {
                return self.ty_i64;
            }
            self.emitError("unknown slice field", span);
            return error_type;
        },
        .str_type => {
            // .len on str returns i64.
            const field_name = self.pool.resolve(fa.field);
            if (std.mem.eql(u8, field_name, "len")) {
                return self.ty_i64;
            }
            self.emitError("unknown str field", span);
            return error_type;
        },
        .enum_type => {
            // Enum variant access: EnumType.Variant
            return field_base;
        },
        else => {
            var buf: [256]u8 = undefined;
            const ty_name = self.typeName(obj_type);
            const field_name = self.pool.resolve(fa.field);
            const msg = std.fmt.bufPrint(
                &buf,
                "type '{s}' has no field '{s}'",
                .{ ty_name, field_name },
            ) catch "invalid field access";
            const alloc_msg = self.allocator.dupe(u8, msg) catch "invalid field access";
            self.emitError(alloc_msg, span);
            return error_type;
        },
    }
}

fn checkIndex(self: *Sema, idx: Ast.IndexExpr, _: Span) TypeId {
    const arr_type = self.checkExpr(idx.expr);
    _ = self.checkExpr(idx.index);

    if (arr_type == error_type) return error_type;

    const resolved = self.resolveAlias(arr_type);
    switch (self.getType(resolved)) {
        .array_type => |at| return at.element,
        .slice_type => |st| return st.element,
        else => return error_type,
    }
}

fn checkSlice(self: *Sema, sl: Ast.SliceExpr) TypeId {
    const arr_type = self.checkExpr(sl.expr);
    if (sl.start) |s| _ = self.checkExpr(s);
    if (sl.end) |e| _ = self.checkExpr(e);

    if (arr_type == error_type) return error_type;

    const resolved = self.resolveAlias(arr_type);
    switch (self.getType(resolved)) {
        .array_type => |at| return self.addType(.{ .slice_type = .{ .element = at.element } }),
        .slice_type => return resolved, // slicing a slice returns same slice type
        else => return error_type,
    }
}

fn checkArrayLiteral(self: *Sema, elems: []const *const Ast.Expr) TypeId {
    if (elems.len == 0) return error_type;

    var elem_type: TypeId = error_type;
    for (elems) |elem| {
        const et = self.checkExpr(elem);
        if (elem_type == error_type) {
            elem_type = et;
        }
    }

    return self.addType(.{ .array_type = .{
        .element = elem_type,
        .size = elems.len,
    } });
}

fn checkStructLiteral(self: *Sema, sl: Ast.StructLiteral, span: Span) TypeId {
    // Look up the struct type.
    if (self.named_types.get(sl.name)) |tid| {
        const resolved = self.resolveAlias(tid);
        switch (self.getType(resolved)) {
            .struct_type => |st| {
                const seen = self.allocator.alloc(bool, st.field_names.len) catch return resolved;
                defer self.allocator.free(seen);
                @memset(seen, false);

                // Check each field initializer.
                for (sl.fields) |field_init| {
                    // Find field in struct.
                    var found_index: ?usize = null;
                    for (st.field_names, 0..) |fname, i| {
                        if (fname == field_init.name) {
                            found_index = i;
                            break;
                        }
                    }
                    if (found_index == null) {
                        _ = self.checkExpr(field_init.value);
                        self.emitError("unknown struct field", field_init.span);
                        continue;
                    }

                    const idx = found_index.?;
                    seen[idx] = true;
                    const expected_type = st.field_types[idx];
                    const val_type = self.checkExprWithExpected(field_init.value, expected_type);
                    if (expected_type != error_type and val_type != error_type) {
                        if (self.isImplicitNarrowing(expected_type, val_type)) {
                            self.emitError("E0201: implicit narrowing conversion", field_init.span);
                        } else if (!self.typesCompatible(expected_type, val_type) and self.arithmeticResultType(expected_type, val_type) == error_type) {
                            var buf: [256]u8 = undefined;
                            const expected_name = self.typeName(expected_type);
                            const actual_name = self.typeName(val_type);
                            const msg = std.fmt.bufPrint(&buf, "type mismatch for struct field: expected '{s}', found '{s}'", .{ expected_name, actual_name }) catch "struct field type mismatch";
                            const alloc_msg = self.allocator.dupe(u8, msg) catch "struct field type mismatch";
                            self.emitError(alloc_msg, field_init.span);
                        }
                    }
                }

                // Check missing required fields.
                for (st.field_names, 0..) |_, i| {
                    if (!seen[i] and (i >= st.field_defaults.len or !st.field_defaults[i])) {
                        self.emitError("missing required struct field", span);
                    }
                }
                return resolved;
            },
            else => {},
        }
    }
    return error_type;
}

fn checkMatchExpr(self: *Sema, m: Ast.MatchExpr) TypeId {
    const subject_type = self.checkExpr(m.subject);

    var result_type: TypeId = error_type;

    for (m.arms) |arm| {
        // Check pattern bindings — add to scope.
        var arm_scope = Scope.init();
        arm_scope.parent = self.current_scope;
        const saved = self.current_scope;
        self.current_scope = &arm_scope;

        self.checkPattern(&arm.pattern, subject_type);
        if (arm.guard) |guard| {
            _ = self.checkExpr(guard);
        }
        const arm_type = self.checkExpr(arm.body);

        arm_scope.deinit(self.allocator);
        self.current_scope = saved;

        if (result_type == error_type) {
            result_type = arm_type;
        }
    }

    // Exhaustiveness check.
    self.checkExhaustiveness(m, subject_type);
    // Usefulness check (warn on unreachable arms).
    self.checkUsefulness(m, subject_type);

    return result_type;
}

/// Check whether a match expression covers all possible values.
/// Emits a warning for non-exhaustive matches on enum and bool types.
fn checkExhaustiveness(self: *Sema, m: Ast.MatchExpr, subject_type: TypeId) void {
    const resolved = self.resolveAlias(subject_type);
    const type_info = self.getType(resolved);

    switch (type_info) {
        .enum_type => |et| {
            // Check that all enum variants are covered.
            // A wildcard/binding arm (without guard) covers all remaining variants.
            var has_catchall = false;
            for (m.arms) |arm| {
                if (arm.guard != null) continue; // Guarded arms don't guarantee coverage.
                if (self.patternIsCatchAll(&arm.pattern)) {
                    has_catchall = true;
                    break;
                }
            }
            if (has_catchall) return;

            // Collect covered variant names.
            for (et.variant_names) |vn| {
                var covered = false;
                for (m.arms) |arm| {
                    if (arm.guard != null) continue;
                    if (self.patternCoversVariant(&arm.pattern, vn)) {
                        covered = true;
                        break;
                    }
                }
                if (!covered) {
                    const name_str = self.pool.resolve(vn);
                    const msg = std.fmt.allocPrint(self.allocator, "non-exhaustive match: missing variant '{s}'", .{name_str}) catch return;
                    self.diagnostics.emit(Diagnostic.warn(msg, m.subject.span));
                    return; // One warning is enough.
                }
            }
        },
        .bool_type => {
            var has_true = false;
            var has_false = false;
            var has_catchall = false;
            for (m.arms) |arm| {
                if (arm.guard != null) continue;
                if (self.patternIsCatchAll(&arm.pattern)) {
                    has_catchall = true;
                    break;
                }
                self.patternCoversBool(&arm.pattern, &has_true, &has_false);
            }
            if (!has_catchall and (!has_true or !has_false)) {
                self.diagnostics.emit(Diagnostic.warn("non-exhaustive match on bool", m.subject.span));
            }
        },
        else => {
            // For int/string/other types, don't warn — too noisy for int matches.
        },
    }
}

/// Warn about unreachable match arms (simple usefulness checking).
fn checkUsefulness(self: *Sema, m: Ast.MatchExpr, subject_type: TypeId) void {
    const resolved = self.resolveAlias(subject_type);
    const type_info = self.getType(resolved);

    var has_catchall = false;

    var seen_true = false;
    var seen_false = false;

    var seen_ints: std.AutoHashMapUnmanaged(i64, void) = .{};
    defer seen_ints.deinit(self.allocator);

    var enum_seen: ?[]bool = null;
    defer if (enum_seen) |arr| self.allocator.free(arr);
    if (type_info == .enum_type) {
        const et = type_info.enum_type;
        enum_seen = self.allocator.alloc(bool, et.variant_names.len) catch null;
        if (enum_seen) |arr| @memset(arr, false);
    }

    for (m.arms) |arm| {
        if (has_catchall) {
            self.emitWarning("unreachable match arm: previous arm covers all remaining values", arm.span);
            continue;
        }

        var is_unreachable = false;
        if (arm.guard == null) {
            switch (type_info) {
                .enum_type => |et| {
                    if (enum_seen) |seen| {
                        if (self.patternIsCatchAll(&arm.pattern)) {
                            var any_uncovered = false;
                            for (seen) |covered| {
                                if (!covered) {
                                    any_uncovered = true;
                                    break;
                                }
                            }
                            is_unreachable = !any_uncovered;
                        } else {
                            var can_match_uncovered = false;
                            for (et.variant_names, 0..) |vn, i| {
                                if (self.patternCoversVariant(&arm.pattern, vn) and !seen[i]) {
                                    can_match_uncovered = true;
                                    break;
                                }
                            }
                            is_unreachable = !can_match_uncovered;
                        }
                    }
                },
                .bool_type => {
                    if (self.patternIsCatchAll(&arm.pattern)) {
                        is_unreachable = seen_true and seen_false;
                    } else {
                        var arm_true = false;
                        var arm_false = false;
                        self.patternCoversBool(&arm.pattern, &arm_true, &arm_false);
                        const can_true = arm_true and !seen_true;
                        const can_false = arm_false and !seen_false;
                        is_unreachable = !can_true and !can_false and (arm_true or arm_false);
                    }
                },
                else => {
                    if (patternIntLiteralsCovered(&arm.pattern, &seen_ints)) {
                        is_unreachable = true;
                    }
                },
            }
        }

        if (is_unreachable) {
            self.emitWarning("unreachable match arm", arm.span);
            continue;
        }

        // Update covered-space only for unguarded reachable arms.
        if (arm.guard == null) {
            if (self.patternIsCatchAll(&arm.pattern)) {
                has_catchall = true;
                continue;
            }

            switch (type_info) {
                .enum_type => |et| {
                    if (enum_seen) |seen| {
                        for (et.variant_names, 0..) |vn, i| {
                            if (self.patternCoversVariant(&arm.pattern, vn)) {
                                seen[i] = true;
                            }
                        }
                    }
                },
                .bool_type => {
                    var arm_true = false;
                    var arm_false = false;
                    self.patternCoversBool(&arm.pattern, &arm_true, &arm_false);
                    if (arm_true) seen_true = true;
                    if (arm_false) seen_false = true;
                },
                else => {
                    recordPatternIntLiterals(&arm.pattern, &seen_ints, self.allocator);
                },
            }
        }
    }
}

fn patternIntLiteralsCovered(pattern: *const Ast.Pattern, seen_ints: *const std.AutoHashMapUnmanaged(i64, void)) bool {
    switch (pattern.kind) {
        .int_literal => |val| return seen_ints.get(val) != null,
        .or_pattern => |alts| {
            if (alts.len == 0) return false;
            for (alts) |*alt| {
                if (!patternIntLiteralsCovered(alt, seen_ints)) return false;
            }
            return true;
        },
        .at_binding => |ab| return patternIntLiteralsCovered(ab.pattern, seen_ints),
        else => return false,
    }
}

fn recordPatternIntLiterals(
    pattern: *const Ast.Pattern,
    seen_ints: *std.AutoHashMapUnmanaged(i64, void),
    allocator: std.mem.Allocator,
) void {
    switch (pattern.kind) {
        .int_literal => |val| {
            seen_ints.put(allocator, val, {}) catch {};
        },
        .or_pattern => |alts| {
            for (alts) |*alt| {
                recordPatternIntLiterals(alt, seen_ints, allocator);
            }
        },
        .at_binding => |ab| recordPatternIntLiterals(ab.pattern, seen_ints, allocator),
        else => {},
    }
}

/// Returns true if the pattern is a catch-all (wildcard, binding, or at-binding with catch-all).
fn patternIsCatchAll(self: *Sema, pattern: *const Ast.Pattern) bool {
    switch (pattern.kind) {
        .wildcard, .binding => return true,
        .at_binding => |ab| return self.patternIsCatchAll(ab.pattern),
        .or_pattern => |pats| {
            for (pats) |*p| {
                if (self.patternIsCatchAll(p)) return true;
            }
            return false;
        },
        else => return false,
    }
}

/// Returns true if the pattern covers a specific enum variant (by symbol).
fn patternCoversVariant(self: *Sema, pattern: *const Ast.Pattern, variant: Symbol) bool {
    switch (pattern.kind) {
        .wildcard, .binding => return true,
        .variant => |vp| return vp.name == variant,
        .or_pattern => |pats| {
            for (pats) |*p| {
                if (self.patternCoversVariant(p, variant)) return true;
            }
            return false;
        },
        .at_binding => |ab| return self.patternCoversVariant(ab.pattern, variant),
        else => return false,
    }
}

/// Updates has_true/has_false based on bool patterns.
fn patternCoversBool(self: *Sema, pattern: *const Ast.Pattern, has_true: *bool, has_false: *bool) void {
    switch (pattern.kind) {
        .bool_literal => |val| {
            if (val) has_true.* = true else has_false.* = true;
        },
        .or_pattern => |pats| {
            for (pats) |*p| {
                self.patternCoversBool(p, has_true, has_false);
            }
        },
        .at_binding => |ab| self.patternCoversBool(ab.pattern, has_true, has_false),
        else => {},
    }
}

fn checkPattern(self: *Sema, pattern: *const Ast.Pattern, subject_type: TypeId) void {
    switch (pattern.kind) {
        .wildcard => {},
        .binding => |sym| {
            self.current_scope.put(self.allocator, sym, .{
                .type_id = subject_type,
                .is_mut = false,
                .state = .live,
                .span = pattern.span,
            });
        },
        .int_literal => {},
        .bool_literal => {},
        .string_literal => {},
        .variant => |vp| {
            const subject_resolved = self.resolveAlias(subject_type);
            if (self.getType(subject_resolved) == .enum_type) {
                const et = self.getType(subject_resolved).enum_type;
                var variant_index: ?usize = null;
                for (et.variant_names, 0..) |vn, i| {
                    if (vn == vp.name) {
                        variant_index = i;
                        break;
                    }
                }

                if (variant_index == null) {
                    self.emitError("unknown enum variant in pattern", pattern.span);
                    for (vp.bindings) |binding_sym| {
                        self.current_scope.put(self.allocator, binding_sym, .{
                            .type_id = error_type,
                            .is_mut = false,
                            .state = .live,
                            .span = pattern.span,
                        });
                    }
                    return;
                }

                const payload_opt = et.variant_payloads[variant_index.?];
                const expected_count: usize = if (payload_opt) |payloads| payloads.len else 0;
                if (vp.bindings.len != expected_count) {
                    self.emitError("variant pattern payload arity mismatch", pattern.span);
                }

                if (payload_opt) |payloads| {
                    const bind_count = @min(vp.bindings.len, payloads.len);
                    for (vp.bindings[0..bind_count], 0..) |binding_sym, i| {
                        const payload_type = payloads[i];
                        self.current_scope.put(self.allocator, binding_sym, .{
                            .type_id = payload_type,
                            .is_mut = false,
                            .state = .live,
                            .span = pattern.span,
                        });
                    }
                    for (vp.bindings[bind_count..]) |binding_sym| {
                        self.current_scope.put(self.allocator, binding_sym, .{
                            .type_id = error_type,
                            .is_mut = false,
                            .state = .live,
                            .span = pattern.span,
                        });
                    }
                } else {
                    for (vp.bindings) |binding_sym| {
                        self.current_scope.put(self.allocator, binding_sym, .{
                            .type_id = error_type,
                            .is_mut = false,
                            .state = .live,
                            .span = pattern.span,
                        });
                    }
                }
                return;
            }

            if (self.variant_lookup.get(vp.name) != null) {
                self.emitError("variant pattern used on non-enum type", pattern.span);
            } else {
                self.emitError("unknown enum variant in pattern", pattern.span);
            }
            for (vp.bindings) |binding_sym| {
                self.current_scope.put(self.allocator, binding_sym, .{
                    .type_id = error_type,
                    .is_mut = false,
                    .state = .live,
                    .span = pattern.span,
                });
            }
        },
        .or_pattern => |alternatives| {
            for (alternatives) |*alt| {
                self.checkPattern(alt, subject_type);
            }
        },
        .at_binding => |ab| {
            // Bind the whole matched value, then bind inner pattern names.
            self.current_scope.put(self.allocator, ab.name, .{
                .type_id = subject_type,
                .is_mut = false,
                .state = .live,
                .span = pattern.span,
            });
            self.checkPattern(ab.pattern, subject_type);
        },
        .tuple_pattern => |elems| {
            const resolved = self.resolveAlias(subject_type);
            const ty = self.getType(resolved);
            if (ty != .tuple_type) {
                self.emitError("tuple pattern used on non-tuple type", pattern.span);
                for (elems) |*elem| {
                    self.checkPattern(elem, error_type);
                }
                return;
            }
            const tuple_elems = ty.tuple_type.elements;
            if (elems.len != tuple_elems.len) {
                self.emitError("tuple pattern arity mismatch", pattern.span);
            }
            const n = @min(elems.len, tuple_elems.len);
            for (elems[0..n], 0..) |*elem, i| {
                self.checkPattern(elem, tuple_elems[i]);
            }
            for (elems[n..]) |*elem| {
                self.checkPattern(elem, error_type);
            }
        },
        .range_pattern => {},
        .slice_pattern => |sp| {
            const elem_type: TypeId = blk: {
                if (subject_type == error_type) break :blk error_type;
                const resolved = self.resolveAlias(subject_type);
                switch (self.getType(resolved)) {
                    .array_type => |at| break :blk at.element,
                    .slice_type => |st| break :blk st.element,
                    else => {
                        self.emitError("slice pattern used on non-array/slice type", pattern.span);
                        break :blk error_type;
                    },
                }
            };
            // Bind head element names.
            for (sp.head) |sym| {
                if (sym == 0) continue; // wildcard
                self.current_scope.put(self.allocator, sym, .{
                    .type_id = elem_type,
                    .is_mut = false,
                    .state = .live,
                    .span = pattern.span,
                });
            }
            // Bind rest as i64 (length of remaining elements).
            if (sp.has_rest and sp.rest != 0) {
                self.current_scope.put(self.allocator, sp.rest, .{
                    .type_id = self.ty_i64,
                    .is_mut = false,
                    .state = .live,
                    .span = pattern.span,
                });
            }
            // Bind tail element names.
            for (sp.tail) |sym| {
                if (sym == 0) continue;
                self.current_scope.put(self.allocator, sym, .{
                    .type_id = elem_type,
                    .is_mut = false,
                    .state = .live,
                    .span = pattern.span,
                });
            }
        },
    }
}

fn checkEnumVariant(self: *Sema, ev: Ast.EnumVariantExpr, _: Span) TypeId {
    // Check arguments.
    for (ev.args) |arg| {
        _ = self.checkExpr(arg);
    }

    // Look up enum type.
    if (self.named_types.get(ev.type_name)) |tid| {
        return self.resolveAlias(tid);
    }

    return error_type;
}

fn checkClosure(self: *Sema, cl: Ast.ClosureExpr, span: Span) TypeId {
    // Save enclosing scope for capture detection.
    const enclosing_scope = self.current_scope;

    // Push closure scope.
    var closure_scope = Scope.init();
    closure_scope.parent = self.current_scope;
    const saved = self.current_scope;
    self.current_scope = &closure_scope;
    defer {
        closure_scope.deinit(self.allocator);
        self.current_scope = saved;
    }

    // Add params (inferred as i32 for now, matching codegen).
    const param_types = self.allocator.alloc(TypeId, cl.params.len) catch return error_type;
    for (cl.params, 0..) |param_sym, i| {
        param_types[i] = self.ty_i32;
        closure_scope.put(self.allocator, param_sym, .{
            .type_id = self.ty_i32,
            .is_mut = false,
            .state = .live,
            .span = Span.zero,
        });
    }

    const body_type = self.checkExpr(cl.body);
    _ = body_type;

    // Capture analysis: scan body for identifiers that reference the
    // enclosing scope (not closure params or function-level names).
    var captures_list: std.ArrayList(CaptureInfo) = .empty;
    self.collectCaptures(cl.body, &closure_scope, enclosing_scope, &captures_list);

    const captures = captures_list.toOwnedSlice(self.allocator) catch &.{};
    const is_non_escaping = self.closure_direct_arg_depth > 0;
    for (captures) |cap| {
        const cap_type = self.getType(self.resolveAlias(cap.type_id));
        if (!is_non_escaping and cap_type == .ref_type) {
            self.emitError("closures cannot capture ephemeral references", span);
        }
        // Escaping closures move non-Copy captures into the closure environment.
        if (!is_non_escaping and cap.kind == .by_move) {
            if (enclosing_scope.lookupMut(cap.symbol)) |info| {
                info.state = .moved;
            }
        }
    }
    const analysis = ClosureAnalysis{
        .captures = captures,
        .is_capturing = captures.len > 0,
    };

    // Store analysis keyed by the closure body address.
    self.closure_analyses.put(self.allocator, @intFromPtr(cl.body), analysis) catch {};

    // Return a function type.
    const ret_type = self.ty_i32; // closures default to i32 return
    return self.addType(.{ .fn_type = .{
        .params = param_types,
        .return_type = ret_type,
        .is_variadic = false,
    } });
}

/// Recursively scan an expression for captured variables.
fn collectCaptures(
    self: *Sema,
    expr: *const Ast.Expr,
    closure_scope: *const Scope,
    enclosing_scope: *const Scope,
    captures: *std.ArrayList(CaptureInfo),
) void {
    switch (expr.kind) {
        .ident => |sym| {
            // If this ident is NOT in the closure's own bindings (params)
            // but IS in an enclosing scope, it's a capture.
            if (closure_scope.bindings.get(sym) != null) return;
            if (self.fn_sigs.get(sym) != null) return;
            if (self.named_types.get(sym) != null) return;
            if (self.isBuiltinFn(sym)) return;
            if (self.variant_lookup.get(sym) != null) return;
            if (self.generic_fns.get(sym) != null) return;

            if (enclosing_scope.lookup(sym)) |info| {
                // Check if already captured.
                for (captures.items) |c| {
                    if (c.symbol == sym) return;
                }
                captures.append(self.allocator, .{
                    .symbol = sym,
                    .kind = if (self.isCopy(info.type_id)) .by_copy else .by_move,
                    .type_id = info.type_id,
                }) catch {};
            }
        },
        .binary => |bin| {
            self.collectCaptures(bin.lhs, closure_scope, enclosing_scope, captures);
            self.collectCaptures(bin.rhs, closure_scope, enclosing_scope, captures);
        },
        .unary => |un| {
            self.collectCaptures(un.operand, closure_scope, enclosing_scope, captures);
        },
        .call => |call_e| {
            self.collectCaptures(call_e.callee, closure_scope, enclosing_scope, captures);
            for (call_e.args) |arg| {
                self.collectCaptures(arg, closure_scope, enclosing_scope, captures);
            }
        },
        .block => |blk| {
            for (blk.stmts) |stmt| {
                self.collectCaptures(stmt, closure_scope, enclosing_scope, captures);
            }
            if (blk.tail) |tail| {
                self.collectCaptures(tail, closure_scope, enclosing_scope, captures);
            }
        },
        .if_expr => |if_e| {
            self.collectCaptures(if_e.condition, closure_scope, enclosing_scope, captures);
            self.collectCaptures(if_e.then_body, closure_scope, enclosing_scope, captures);
            if (if_e.else_body) |eb| self.collectCaptures(eb, closure_scope, enclosing_scope, captures);
        },
        .field_access => |fa| {
            self.collectCaptures(fa.expr, closure_scope, enclosing_scope, captures);
        },
        .await_expr => |inner| {
            self.collectCaptures(inner, closure_scope, enclosing_scope, captures);
        },
        .async_block => |inner| {
            self.collectCaptures(inner, closure_scope, enclosing_scope, captures);
        },
        .async_scope => |as| {
            self.collectCaptures(as.body, closure_scope, enclosing_scope, captures);
        },
        .spawn_expr => |inner| {
            self.collectCaptures(inner, closure_scope, enclosing_scope, captures);
        },
        .grouped => |inner| {
            self.collectCaptures(inner, closure_scope, enclosing_scope, captures);
        },
        else => {}, // Other expressions don't contain identifiers to capture.
    }
}

fn checkCast(self: *Sema, ca: Ast.CastExpr) TypeId {
    _ = self.checkExpr(ca.expr);
    return self.resolveTypeExpr(ca.target_type);
}

fn checkPipeline(self: *Sema, p: Ast.PipelineExpr, _: Span) TypeId {
    const lhs = self.checkExpr(p.lhs);
    _ = lhs;
    // Pipeline RHS gets one extra implicit argument from the pipe.
    const saved = self.in_pipeline_rhs;
    self.in_pipeline_rhs = true;
    defer self.in_pipeline_rhs = saved;
    const rhs_ty = self.checkExpr(p.rhs);

    const rhs_supported = switch (p.rhs.kind) {
        .ident => true,
        .call => |call_e| call_e.callee.kind == .ident,
        else => false,
    };
    if (!rhs_supported) {
        self.emitError("pipeline rhs must be a function name or direct function call", p.rhs.span);
        return error_type;
    }
    return rhs_ty;
}

fn checkTuple(self: *Sema, elems: []const *const Ast.Expr) TypeId {
    const elem_types = self.allocator.alloc(TypeId, elems.len) catch return error_type;
    for (elems, 0..) |elem, i| {
        elem_types[i] = self.checkExpr(elem);
    }
    return self.addType(.{ .tuple_type = .{
        .elements = elem_types,
    } });
}

fn checkRange(self: *Sema, r: Ast.RangeExpr) TypeId {
    var elem_type: TypeId = self.ty_i32;
    var has_numeric_bound = false;

    if (r.start) |s| {
        const start_ty = self.checkExpr(s);
        if (start_ty != error_type) {
            const st = self.getType(self.resolveAlias(start_ty));
            if (!isNumericType(st)) {
                self.emitError("range start must be numeric", s.span);
            } else {
                elem_type = start_ty;
                has_numeric_bound = true;
            }
        }
    }

    if (r.end) |e| {
        const end_ty = self.checkExpr(e);
        if (end_ty != error_type) {
            const et = self.getType(self.resolveAlias(end_ty));
            if (!isNumericType(et)) {
                self.emitError("range end must be numeric", e.span);
            } else if (has_numeric_bound) {
                const merged = self.arithmeticResultType(elem_type, end_ty);
                if (merged == error_type) {
                    self.emitError("range bounds must be numeric and compatible", e.span);
                    return error_type;
                }
                elem_type = merged;
            } else {
                elem_type = end_ty;
                has_numeric_bound = true;
            }
        }
    }

    if (!has_numeric_bound and r.start != null and r.end != null) {
        return error_type;
    }

    return self.addType(.{ .range_type = .{
        .element = elem_type,
        .inclusive = r.inclusive,
    } });
}

fn checkVariantShorthand(self: *Sema, sym: Symbol, span: Span, expected: ?TypeId) TypeId {
    if (expected) |exp_ty| {
        const resolved_expected = self.resolveAlias(exp_ty);
        const expected_info = self.getType(resolved_expected);
        if (expected_info == .enum_type) {
            for (expected_info.enum_type.variant_names) |vn| {
                if (vn == sym) return resolved_expected;
            }
            self.emitError("enum variant shorthand does not match expected enum type", span);
            return error_type;
        }
    }

    if (self.variant_lookup.get(sym)) |vi| {
        return vi.enum_type;
    }
    return error_type;
}

fn checkCall(self: *Sema, call_e: Ast.CallExpr, span: Span) TypeId {
    // Handle method call syntax: obj.method(args).
    if (call_e.callee.kind == .field_access) {
        return self.checkMethodCall(call_e.callee.kind.field_access, call_e.args, span);
    }

    // Callee must be an identifier.
    const fn_sym = switch (call_e.callee.kind) {
        .ident => |sym| sym,
        else => {
            // Check callee expression anyway.
            _ = self.checkExpr(call_e.callee);
            for (call_e.args) |arg| _ = self.checkExpr(arg);
            return error_type;
        },
    };

    // Determine expected argument types (for contextual shorthand resolution).
    var expected_params: ?[]const TypeId = null;
    if (self.fn_sigs.get(fn_sym)) |sig| {
        expected_params = sig.param_types;
    } else if (self.current_scope.lookup(fn_sym)) |info| {
        const resolved_local = self.resolveAlias(info.type_id);
        if (self.getType(resolved_local) == .fn_type) {
            expected_params = self.getType(resolved_local).fn_type.params;
        }
    }
    const param_offset: usize = if (self.in_pipeline_rhs) 1 else 0;

    // Check all arguments first and cache types for parameter checks.
    var arg_types: [64]TypeId = undefined;
    for (call_e.args, 0..) |arg, i| {
        const expected_ty = if (expected_params) |params|
            if (i + param_offset < params.len) params[i + param_offset] else null
        else
            null;
        self.closure_direct_arg_depth += 1;
        const ty = self.checkExprWithExpected(arg, expected_ty);
        self.closure_direct_arg_depth -= 1;
        if (i < arg_types.len) arg_types[i] = ty;
    }

    if (self.in_comptime_fn) {
        const fn_name = self.pool.resolve(fn_sym);
        if (std.mem.eql(u8, fn_name, "print") or std.mem.eql(u8, fn_name, "println")) {
            self.emitError("comptime fn cannot perform I/O", span);
        }
        if (self.extern_fn_names.get(fn_sym) != null) {
            self.emitError("comptime fn cannot call extern functions", span);
        }
    }

    // Known function.
    if (self.fn_sigs.get(fn_sym)) |sig| {
        // Check argument count (skip variadic functions).
        // In pipeline context, there's one implicit argument from the pipe.
        const expected = sig.param_types.len;
        const actual = call_e.args.len + (if (self.in_pipeline_rhs) @as(usize, 1) else 0);
        if (!sig.is_variadic and expected != actual) {
            var buf: [256]u8 = undefined;
            const fn_name = self.pool.resolve(fn_sym);
            const msg = std.fmt.bufPrint(&buf, "function '{s}' expects {d} argument(s), found {d}", .{ fn_name, expected, actual }) catch "wrong argument count";
            const alloc_msg = self.allocator.dupe(u8, msg) catch "wrong argument count";
            self.emitError(alloc_msg, span);
        }
        // Check explicit argument types.
        for (call_e.args, 0..) |_, i| {
            const param_i = i + param_offset;
            if (param_i >= sig.param_types.len) break;
            const expected_ty = sig.param_types[param_i];
            const arg_ty = if (i < arg_types.len) arg_types[i] else error_type;
            if (expected_ty != error_type and arg_ty != error_type) {
                if (self.isImplicitNarrowing(expected_ty, arg_ty)) {
                    self.emitError("E0201: implicit narrowing conversion", span);
                } else if (!self.typesCompatible(expected_ty, arg_ty) and self.arithmeticResultType(expected_ty, arg_ty) == error_type) {
                    var buf: [256]u8 = undefined;
                    const fn_name = self.pool.resolve(fn_sym);
                    const expected_name = self.typeName(expected_ty);
                    const actual_name = self.typeName(arg_ty);
                    const msg = std.fmt.bufPrint(
                        &buf,
                        "argument {d} to '{s}' has wrong type: expected '{s}', found '{s}'",
                        .{ i + 1, fn_name, expected_name, actual_name },
                    ) catch "wrong argument type";
                    const alloc_msg = self.allocator.dupe(u8, msg) catch "wrong argument type";
                    self.emitError(alloc_msg, span);
                }
            }
            if (self.exprIsEphemeralTask(call_e.args[i]) and !self.paramIsByReference(expected_ty)) {
                self.emitWarning("ephemeral Task passed by value may escape", call_e.args[i].span);
            }
        }

        // Validate dyn Trait parameter conversions at call sites.
        if (self.fn_decls.get(fn_sym)) |fn_decl| {
            for (call_e.args, 0..) |_, i| {
                const param_i = i + param_offset;
                if (param_i >= fn_decl.params.len) break;
                const param = fn_decl.params[param_i];
                const te = param.type_expr orelse continue;
                const trait_sym = self.traitObjectFromTypeExpr(te) orelse continue;

                const arg_ty = if (i < arg_types.len) arg_types[i] else error_type;
                const concrete_sym = self.dynArgConcreteTypeSymbol(arg_ty) orelse {
                    self.emitError("argument cannot be converted to dyn trait object", call_e.args[i].span);
                    continue;
                };

                const impl_list = self.type_impls.get(concrete_sym);
                var found = false;
                if (impl_list) |list| {
                    for (list.items) |impl_trait| {
                        if (impl_trait == trait_sym) {
                            found = true;
                            break;
                        }
                    }
                }
                if (!found) {
                    var buf: [256]u8 = undefined;
                    const type_str = self.pool.resolve(concrete_sym);
                    const trait_str = self.pool.resolve(trait_sym);
                    const msg = std.fmt.bufPrint(
                        &buf,
                        "type '{s}' does not implement trait '{s}' required for dyn parameter",
                        .{ type_str, trait_str },
                    ) catch "missing dyn trait impl";
                    const alloc_msg = self.allocator.dupe(u8, msg) catch "missing dyn trait impl";
                    self.emitError(alloc_msg, call_e.args[i].span);
                }
            }
        }

        const fn_name = self.pool.resolve(fn_sym);
        if (std.mem.eql(u8, fn_name, "spawn_os")) {
            if (call_e.args.len > 0 and self.closureExprCapturesNonSend(call_e.args[0])) {
                self.emitError("spawn_os requires Send captures (no ephemeral references/tasks)", call_e.args[0].span);
            }
        }
        return sig.return_type;
    }

    // Local variable (function pointer).
    if (self.current_scope.lookup(fn_sym)) |info| {
        const resolved = self.resolveAlias(info.type_id);
        switch (self.getType(resolved)) {
            .fn_type => |ft| {
                const expected = ft.params.len;
                const actual = call_e.args.len + (if (self.in_pipeline_rhs) @as(usize, 1) else 0);
                if (expected != actual) {
                    var buf: [256]u8 = undefined;
                    const fn_name = self.pool.resolve(fn_sym);
                    const msg = std.fmt.bufPrint(&buf, "function '{s}' expects {d} argument(s), found {d}", .{ fn_name, expected, actual }) catch "wrong argument count";
                    const alloc_msg = self.allocator.dupe(u8, msg) catch "wrong argument count";
                    self.emitError(alloc_msg, span);
                }

                for (call_e.args, 0..) |_, i| {
                    const param_i = i + param_offset;
                    if (param_i >= ft.params.len) break;
                    const expected_ty = ft.params[param_i];
                    const arg_ty = if (i < arg_types.len) arg_types[i] else error_type;
                    if (expected_ty != error_type and arg_ty != error_type) {
                        if (self.isImplicitNarrowing(expected_ty, arg_ty)) {
                            self.emitError("E0201: implicit narrowing conversion", span);
                        } else if (!self.typesCompatible(expected_ty, arg_ty) and self.arithmeticResultType(expected_ty, arg_ty) == error_type) {
                            var buf: [256]u8 = undefined;
                            const fn_name = self.pool.resolve(fn_sym);
                            const expected_name = self.typeName(expected_ty);
                            const actual_name = self.typeName(arg_ty);
                            const msg = std.fmt.bufPrint(
                                &buf,
                                "argument {d} to '{s}' has wrong type: expected '{s}', found '{s}'",
                                .{ i + 1, fn_name, expected_name, actual_name },
                            ) catch "wrong argument type";
                            const alloc_msg = self.allocator.dupe(u8, msg) catch "wrong argument type";
                            self.emitError(alloc_msg, span);
                        }
                    }
                    if (self.exprIsEphemeralTask(call_e.args[i]) and !self.paramIsByReference(expected_ty)) {
                        self.emitWarning("ephemeral Task passed by value may escape", call_e.args[i].span);
                    }
                }
                return ft.return_type;
            },
            else => {
                // Might be a pointer used as fn — return error_type, codegen handles it.
                return error_type;
            },
        }
    }

    // Generic function.
    if (self.generic_fns.get(fn_sym)) |gen_fn| {
        return self.checkGenericCall(gen_fn, call_e.args, span);
    }

    // Enum variant constructor.
    if (self.variant_lookup.get(fn_sym)) |vi| {
        return vi.enum_type;
    }

    // Built-in functions (fallback when no user/imported function matches).
    if (self.isBuiltinFn(fn_sym)) {
        return self.checkBuiltinCall(fn_sym, call_e.args, arg_types[0..@min(call_e.args.len, arg_types.len)], span);
    }

    // Unknown function.
    return error_type;
}

fn checkMethodCall(self: *Sema, fa: Ast.FieldAccessExpr, args: []const *const Ast.Expr, span: Span) TypeId {
    const obj_type = self.checkExpr(fa.expr);

    // Check all arguments.
    for (args) |arg| {
        self.closure_direct_arg_depth += 1;
        _ = self.checkExpr(arg);
        self.closure_direct_arg_depth -= 1;
    }

    if (obj_type == error_type) return error_type;

    // Try to find method: look for "TypeName.methodName" in fn_sigs.
    const resolved = self.resolveAlias(obj_type);
    const method_name = self.pool.resolve(fa.field);
    if (std.mem.eql(u8, method_name, "track")) {
        if (fa.expr.kind == .ident and self.isActiveAsyncScopeSymbol(fa.expr.kind.ident)) {
            if (args.len != 1) {
                self.emitError("track() expects exactly one task argument", span);
                return error_type;
            }
            if (!self.exprIsTask(args[0])) {
                self.emitError("track() requires a Task value", span);
                return error_type;
            }
            return self.ty_i32;
        }
        self.emitError("track() is only available inside async scope", span);
        return error_type;
    }
    if (std.mem.eql(u8, method_name, "cancel")) {
        if (self.exprIsTask(fa.expr)) return self.ty_void;
        self.emitError("cancel() requires a Task value", span);
        return error_type;
    }
    if (std.mem.eql(u8, method_name, "as_option")) {
        if (self.getType(resolved) == .ptr_type) return error_type;
        self.emitError("as_option() is only available on raw pointers", span);
        return error_type;
    }
    const type_name_sym = self.getTypeName(resolved);
    if (type_name_sym) |tn_sym| {
        // Look up "Type.method" as a function.
        const method_key = self.methodKey(tn_sym, fa.field);
        if (self.fn_sigs.get(method_key)) |sig| {
            return sig.return_type;
        }
    }

    // Could be a static method call (e.g., Counter.new).
    // The callee expr might be an ident referring to a type.
    if (fa.expr.kind == .ident) {
        const type_sym = fa.expr.kind.ident;
        const method_key = self.methodKey(type_sym, fa.field);
        if (self.fn_sigs.get(method_key)) |sig| {
            return sig.return_type;
        }
    }

    return error_type;
}

fn checkGenericCall(self: *Sema, gen_fn: Ast.FnDecl, args: []const *const Ast.Expr, span: Span) TypeId {
    // Infer type parameter → concrete type bindings from call arguments.
    var type_bindings: [16]struct { param: Ast.Symbol, concrete: TypeId } = undefined;
    var binding_count: u32 = 0;

    for (gen_fn.params, 0..) |param, i| {
        if (i >= args.len) break;
        if (param.type_expr) |te| {
            if (te.kind == .named) {
                const sym = te.kind.named;
                // Check if this is a type parameter.
                for (gen_fn.type_params) |tp| {
                    if (tp.name == sym) {
                        const arg_type = self.checkExpr(args[i]);
                        if (arg_type != error_type) {
                            var existing: ?TypeId = null;
                            for (type_bindings[0..binding_count]) |b| {
                                if (b.param == sym) {
                                    existing = b.concrete;
                                    break;
                                }
                            }
                            if (existing) |bound_ty| {
                                if (!self.typesCompatible(bound_ty, arg_type) and self.arithmeticResultType(bound_ty, arg_type) == error_type) {
                                    var buf: [256]u8 = undefined;
                                    const tp_name = self.pool.resolve(sym);
                                    const a = self.typeName(bound_ty);
                                    const b = self.typeName(arg_type);
                                    const msg = std.fmt.bufPrint(&buf, "cannot infer a single type for '{s}': saw '{s}' and '{s}'", .{ tp_name, a, b }) catch "generic type inference failed";
                                    const alloc_msg = self.allocator.dupe(u8, msg) catch "generic type inference failed";
                                    self.emitError(alloc_msg, span);
                                }
                            } else if (binding_count < 16) {
                                type_bindings[binding_count] = .{ .param = sym, .concrete = arg_type };
                                binding_count += 1;
                            }
                        }
                        break;
                    }
                }
            }
        }
    }

    // Check trait bounds for each type parameter.
    for (gen_fn.type_params) |tp| {
        if (tp.bounds.len == 0) continue;
        // Find the concrete type for this type param.
        var concrete: TypeId = error_type;
        for (type_bindings[0..binding_count]) |b| {
            if (b.param == tp.name) {
                concrete = b.concrete;
                break;
            }
        }
        if (concrete == error_type) continue; // couldn't infer, skip check

        const concrete_sym = self.typeSymbolForBounds(concrete) orelse continue;

        // Check each required trait.
        for (tp.bounds) |trait_sym| {
            const trait_name = self.pool.resolve(trait_sym);
            // Special bound: `T: type` is a compile-time kind constraint, not a trait impl.
            if (std.mem.eql(u8, trait_name, "type")) continue;

            const impl_list = self.type_impls.get(concrete_sym);
            var found = false;
            if (impl_list) |list| {
                for (list.items) |impl_trait| {
                    if (impl_trait == trait_sym) {
                        found = true;
                        break;
                    }
                }
            }
            if (!found) {
                var buf: [256]u8 = undefined;
                const type_str = self.pool.resolve(concrete_sym);
                const trait_str = self.pool.resolve(trait_sym);
                const tp_str = self.pool.resolve(tp.name);
                const msg = std.fmt.bufPrint(&buf, "type '{s}' does not implement trait '{s}' required by bound '{s}: {s}'", .{ type_str, trait_str, tp_str, trait_str }) catch "trait bound not satisfied";
                const alloc_msg = self.allocator.dupe(u8, msg) catch "trait bound not satisfied";
                self.emitError(alloc_msg, span);
            }
        }
    }

    // Return the return type annotation if available.
    if (gen_fn.return_type) |rt| {
        if (rt.kind == .named) {
            const ret_sym = rt.kind.named;
            for (type_bindings[0..binding_count]) |b| {
                if (b.param == ret_sym) return b.concrete;
            }
        }
        const resolved = self.resolveTypeExpr(rt);
        if (resolved != error_type) return resolved;
    }
    return error_type;
}

fn checkBuiltinCall(self: *Sema, fn_sym: Symbol, args: []const *const Ast.Expr, arg_types: []const TypeId, span: Span) TypeId {
    const name = self.pool.resolve(fn_sym);
    if (std.mem.eql(u8, name, "println") or std.mem.eql(u8, name, "print")) {
        return self.ty_void;
    }
    if (std.mem.eql(u8, name, "assert")) {
        if (args.len != 1) {
            self.emitError("assert() expects exactly one argument", span);
            return error_type;
        }
        return self.ty_void;
    }
    if (std.mem.eql(u8, name, "Channel")) {
        if (args.len > 1) {
            self.emitError("Channel() expects zero or one capacity argument", span);
            return error_type;
        }
        if (args.len == 1 and arg_types.len >= 1 and arg_types[0] != error_type) {
            const t = self.getType(self.resolveAlias(arg_types[0]));
            if (!isIntType(t)) {
                self.emitError("Channel() capacity must be an integer", args[0].span);
                return error_type;
            }
        }
        return self.ty_i64;
    }
    if (std.mem.eql(u8, name, "send")) {
        if (args.len != 2) {
            self.emitError("send() expects exactly two arguments", span);
            return error_type;
        }
        if (arg_types.len >= 1 and arg_types[0] != error_type) {
            const ch_t = self.getType(self.resolveAlias(arg_types[0]));
            if (!isIntType(ch_t)) {
                self.emitError("send() expects channel handle as integer value", args[0].span);
                return error_type;
            }
        }
        if (self.exprIsEphemeralValue(args[1]) or self.exprIsEphemeralTask(args[1])) {
            self.emitError("channel send requires Send value", args[1].span);
            return error_type;
        }
        if (arg_types.len >= 2 and arg_types[1] != error_type) {
            const val_t = self.getType(self.resolveAlias(arg_types[1]));
            if (!isIntType(val_t)) {
                self.emitError("send() currently supports integer payloads", args[1].span);
                return error_type;
            }
        }
        return self.ty_void;
    }
    if (std.mem.eql(u8, name, "recv")) {
        if (args.len != 1) {
            self.emitError("recv() expects exactly one argument", span);
            return error_type;
        }
        if (arg_types.len >= 1 and arg_types[0] != error_type) {
            const ch_t = self.getType(self.resolveAlias(arg_types[0]));
            if (!isIntType(ch_t)) {
                self.emitError("recv() expects channel handle as integer value", args[0].span);
                return error_type;
            }
        }
        return self.ty_i32;
    }
    if (std.mem.eql(u8, name, "close")) {
        if (args.len != 1) {
            self.emitError("close() expects exactly one argument", span);
            return error_type;
        }
        if (arg_types.len >= 1 and arg_types[0] != error_type) {
            const ch_t = self.getType(self.resolveAlias(arg_types[0]));
            if (!isIntType(ch_t)) {
                self.emitError("close() expects channel handle as integer value", args[0].span);
                return error_type;
            }
        }
        return self.ty_void;
    }
    return error_type;
}

fn isBuiltinFn(self: *Sema, sym: Symbol) bool {
    const name = self.pool.resolve(sym);
    return std.mem.eql(u8, name, "println") or
        std.mem.eql(u8, name, "print") or
        std.mem.eql(u8, name, "assert") or
        std.mem.eql(u8, name, "Some") or
        std.mem.eql(u8, name, "Ok") or
        std.mem.eql(u8, name, "Err") or
        std.mem.eql(u8, name, "Channel") or
        std.mem.eql(u8, name, "send") or
        std.mem.eql(u8, name, "recv") or
        std.mem.eql(u8, name, "close") or
        std.mem.eql(u8, name, "Vec") or
        std.mem.eql(u8, name, "HashMap") or
        std.mem.eql(u8, name, "HashSet") or
        // Math builtins
        std.mem.eql(u8, name, "abs") or
        std.mem.eql(u8, name, "min") or
        std.mem.eql(u8, name, "max") or
        std.mem.eql(u8, name, "clamp") or
        std.mem.eql(u8, name, "sqrt_f64") or
        std.mem.eql(u8, name, "pow_f64") or
        std.mem.eql(u8, name, "floor_f64") or
        std.mem.eql(u8, name, "ceil_f64") or
        std.mem.eql(u8, name, "sin_f64") or
        std.mem.eql(u8, name, "cos_f64") or
        std.mem.eql(u8, name, "log_f64") or
        std.mem.eql(u8, name, "exp_f64") or
        std.mem.eql(u8, name, "fabs_f64");
}

fn isBuiltinValue(self: *Sema, sym: Symbol) bool {
    const name = self.pool.resolve(sym);
    return std.mem.eql(u8, name, "None") or
        std.mem.eql(u8, name, "TypeInfo") or
        std.mem.eql(u8, name, "PI") or
        std.mem.eql(u8, name, "E") or
        std.mem.eql(u8, name, "INFINITY") or
        std.mem.eql(u8, name, "NAN");
}

// ── Helper: method key lookup ────────────────────────────────────

fn methodKey(self: *Sema, type_sym: Symbol, method_sym: Symbol) Symbol {
    // Construct "Type.method" symbol.
    const type_name = self.pool.resolve(type_sym);
    const method_name = self.pool.resolve(method_sym);
    var buf: [512]u8 = undefined;
    const combined = std.fmt.bufPrint(&buf, "{s}.{s}", .{ type_name, method_name }) catch return 0;
    return self.pool.intern(combined) catch 0;
}

fn getTypeName(self: *const Sema, tid: TypeId) ?Symbol {
    switch (self.getType(tid)) {
        .struct_type => |st| return st.name,
        .enum_type => |et| return et.name,
        else => return null,
    }
}

fn typeSymbolForBounds(self: *Sema, tid: TypeId) ?Symbol {
    const resolved = self.resolveAlias(tid);
    return switch (self.getType(resolved)) {
        .struct_type => |st| st.name,
        .enum_type => |et| et.name,
        .int => |it| blk: {
            const name = switch (it.bits) {
                8 => if (it.signed) "i8" else "u8",
                16 => if (it.signed) "i16" else "u16",
                32 => if (it.signed) "i32" else "u32",
                64 => if (it.signed) "i64" else "u64",
                else => break :blk null,
            };
            break :blk self.pool.intern(name) catch null;
        },
        .float => |ft| blk: {
            const name = switch (ft.bits) {
                32 => "f32",
                64 => "f64",
                else => break :blk null,
            };
            break :blk self.pool.intern(name) catch null;
        },
        .bool_type => self.pool.intern("bool") catch null,
        .str_type => self.pool.intern("str") catch null,
        else => null,
    };
}

fn traitObjectFromTypeExpr(self: *Sema, te: *const Ast.TypeExpr) ?Symbol {
    return switch (te.kind) {
        .trait_object => |sym| sym,
        .ref_type => |rt| self.traitObjectFromTypeExpr(rt.pointee),
        .ptr_type => |pt| self.traitObjectFromTypeExpr(pt.pointee),
        .generic => |g| blk: {
            const g_name = self.pool.resolve(g.name);
            if (!std.mem.eql(u8, g_name, "Box")) break :blk null;
            if (g.args.len != 1) break :blk null;
            break :blk self.traitObjectFromTypeExpr(g.args[0]);
        },
        else => null,
    };
}

fn dynArgConcreteTypeSymbol(self: *Sema, tid: TypeId) ?Symbol {
    const resolved = self.resolveAlias(tid);
    return switch (self.getType(resolved)) {
        .ref_type => |rt| self.typeSymbolForBounds(rt.pointee),
        .ptr_type => |pt| self.typeSymbolForBounds(pt.pointee),
        else => self.typeSymbolForBounds(resolved),
    };
}

// ── Type compatibility checking ──────────────────────────────────

fn typesCompatible(self: *const Sema, expected: TypeId, actual: TypeId) bool {
    if (expected == actual) return true;
    if (expected == error_type or actual == error_type) return true;

    const exp_resolved = self.resolveAlias(expected);
    const act_resolved = self.resolveAlias(actual);
    if (exp_resolved == act_resolved) return true;

    const exp_type = self.getType(exp_resolved);
    const act_type = self.getType(act_resolved);

    // Integer coercion: any int to any int is OK (codegen handles truncation).
    if (isIntType(exp_type) and isIntType(act_type)) return true;

    // Float coercion: f32 ↔ f64.
    if (isFloatType(exp_type) and isFloatType(act_type)) return true;

    // Int → Float coercion.
    if (isFloatType(exp_type) and isIntType(act_type)) return true;
    if (isIntType(exp_type) and isFloatType(act_type)) return true;

    // str → ptr coercion (for extern C functions).
    if (isPtrType(exp_type) and act_type == .str_type) return true;
    if (exp_type == .str_type and isPtrType(act_type)) return true;

    // Fn type to ptr coercion.
    if (isPtrType(exp_type) and act_type == .fn_type) return true;
    if (exp_type == .fn_type and isPtrType(act_type)) return true;

    // Fn type compatibility (permissive for closures/function pointers).
    if (exp_type == .fn_type and act_type == .fn_type) return true;

    // Array compatibility: same element type and same size.
    if (exp_type == .array_type and act_type == .array_type) {
        return exp_type.array_type.size == act_type.array_type.size and
            self.typesCompatible(exp_type.array_type.element, act_type.array_type.element);
    }

    // Slice compatibility: same element type.
    if (exp_type == .slice_type and act_type == .slice_type) {
        return self.typesCompatible(exp_type.slice_type.element, act_type.slice_type.element);
    }

    // Pointer compatibility: same mutability + compatible pointee.
    if (exp_type == .ptr_type and act_type == .ptr_type) {
        if (exp_type.ptr_type.is_mut != act_type.ptr_type.is_mut) return false;
        return self.typesCompatible(exp_type.ptr_type.pointee, act_type.ptr_type.pointee);
    }

    // Reference compatibility: same mutability + compatible pointee.
    if (exp_type == .ref_type and act_type == .ref_type) {
        if (exp_type.ref_type.is_mut != act_type.ref_type.is_mut) return false;
        return self.typesCompatible(exp_type.ref_type.pointee, act_type.ref_type.pointee);
    }

    // Tuple compatibility: same number of elements, each compatible.
    if (exp_type == .tuple_type and act_type == .tuple_type) {
        const exp_elems = exp_type.tuple_type.elements;
        const act_elems = act_type.tuple_type.elements;
        if (exp_elems.len != act_elems.len) return false;
        for (exp_elems, act_elems) |e, a| {
            if (!self.typesCompatible(e, a)) return false;
        }
        return true;
    }

    if (exp_type == .range_type and act_type == .range_type) {
        if (exp_type.range_type.inclusive != act_type.range_type.inclusive) return false;
        return self.typesCompatible(exp_type.range_type.element, act_type.range_type.element);
    }

    // Struct/enum compatibility by name.
    if (exp_type == .struct_type and act_type == .struct_type) {
        return exp_type.struct_type.name == act_type.struct_type.name;
    }
    if (exp_type == .enum_type and act_type == .enum_type) {
        return exp_type.enum_type.name == act_type.enum_type.name;
    }

    return false;
}

fn arithmeticResultType(self: *const Sema, lhs: TypeId, rhs: TypeId) TypeId {
    if (lhs == error_type) return rhs;
    if (rhs == error_type) return lhs;

    const l = self.getType(self.resolveAlias(lhs));
    const r = self.getType(self.resolveAlias(rhs));

    // Float wins over int.
    if (isFloatType(l) and isFloatType(r)) {
        const lb = l.float.bits;
        const rb = r.float.bits;
        return if (lb >= rb) lhs else rhs;
    }
    if (isFloatType(l)) return lhs;
    if (isFloatType(r)) return rhs;

    // Wider int wins.
    if (isIntType(l) and isIntType(r)) {
        const lb = l.int.bits;
        const rb = r.int.bits;
        return if (lb >= rb) lhs else rhs;
    }

    return error_type;
}

fn isResultOrOptionTypeId(self: *Sema, tid: TypeId) bool {
    if (tid == error_type) return false;
    const resolved = self.resolveAlias(tid);
    if (self.getType(resolved) != .enum_type) return false;
    const et = self.getType(resolved).enum_type;
    var has_some = false;
    var has_none = false;
    var has_ok = false;
    var has_err = false;
    for (et.variant_names) |vn| {
        const name = self.pool.resolve(vn);
        if (std.mem.eql(u8, name, "Some")) has_some = true;
        if (std.mem.eql(u8, name, "None")) has_none = true;
        if (std.mem.eql(u8, name, "Ok")) has_ok = true;
        if (std.mem.eql(u8, name, "Err")) has_err = true;
    }
    return (has_some and has_none) or (has_ok and has_err);
}

fn hasLiveAwaitGuard(self: *Sema) bool {
    var scope_opt: ?*Scope = self.current_scope;
    while (scope_opt) |scope| {
        var it = scope.bindings.iterator();
        while (it.next()) |entry| {
            const info = entry.value_ptr.*;
            if (info.state != .live) continue;
            const name = self.pool.resolve(entry.key_ptr.*);
            if (std.mem.endsWith(u8, name, "_guard")) return true;
        }
        scope_opt = scope.parent;
    }
    return false;
}

fn isImplicitNarrowing(self: *Sema, expected: TypeId, actual: TypeId) bool {
    if (expected == error_type or actual == error_type) return false;
    const exp_ty = self.getType(self.resolveAlias(expected));
    const act_ty = self.getType(self.resolveAlias(actual));

    if (exp_ty == .int and act_ty == .int) {
        if (act_ty.int.bits > exp_ty.int.bits) return true;
        if (act_ty.int.bits == exp_ty.int.bits and act_ty.int.signed and !exp_ty.int.signed) {
            return true;
        }
        return false;
    }
    if (exp_ty == .float and act_ty == .float) {
        return act_ty.float.bits > exp_ty.float.bits;
    }
    if (exp_ty == .int and act_ty == .float) return true;
    return false;
}

// ── Copy type classification (Phase 2: Move Semantics) ───────────

/// Returns true if a value of this type can be implicitly copied.
/// Primitives, pointers, fn types are Copy. Structs are Copy if all
/// fields are Copy. Enums/arrays/tuples follow the same rule.
pub fn isCopy(self: *Sema, tid: TypeId) bool {
    if (tid == error_type) return true; // error types are permissive
    const resolved = self.resolveAlias(tid);
    switch (self.getType(resolved)) {
        .err => return true,
        .int, .float, .bool_type, .void_type, .str_type => return true,
        .ptr_type, .ref_type, .fn_type, .generic_fn => return true,
        .struct_type => |st| {
            // User-defined drop handlers make the type move-only.
            if (self.hasDropMethod(st.name)) return false;
            for (st.field_types) |ft| {
                if (!self.isCopy(ft)) return false;
            }
            return true;
        },
        .enum_type => |et| {
            if (self.hasDropMethod(et.name)) return false;
            for (et.variant_payloads) |payload| {
                if (payload) |ptypes| {
                    for (ptypes) |pt| {
                        if (!self.isCopy(pt)) return false;
                    }
                }
            }
            return true;
        },
        .array_type => |at| return self.isCopy(at.element),
        .slice_type => return true, // slices are {ptr, len} - Copy by default
        .tuple_type => |tt| {
            for (tt.elements) |elem| {
                if (!self.isCopy(elem)) return false;
            }
            return true;
        },
        .range_type => |rt| return self.isCopy(rt.element),
        .alias => return true, // already resolved above
    }
}

fn hasDropMethod(self: *Sema, type_name: Symbol) bool {
    const drop_sym = self.pool.intern("drop") catch return false;
    const key = self.methodKey(type_name, drop_sym);
    return self.fn_sigs.get(key) != null;
}

fn isIntType(t: Type) bool {
    return t == .int;
}

fn isFloatType(t: Type) bool {
    return t == .float;
}

fn isNumericType(t: Type) bool {
    return isIntType(t) or isFloatType(t);
}

fn isPtrType(t: Type) bool {
    return t == .ptr_type or t == .ref_type;
}

// ── Diagnostics ──────────────────────────────────────────────────

// ── Borrow checking (Phase 3) ────────────────────────────────────

fn checkBorrowCreate(self: *Sema, operand: *const Ast.Expr, kind: BorrowKind, span: Span) void {
    // Get the root variable being borrowed.
    const place = switch (operand.kind) {
        .ident => |sym| sym,
        .field_access => |fa| switch (fa.expr.kind) {
            .ident => |sym| sym,
            else => return, // complex expression, skip checking
        },
        .index => |idx| switch (idx.expr.kind) {
            .ident => |sym| sym,
            else => return,
        },
        else => return, // can't track non-place expressions
    };
    const new_field: ?Symbol = switch (operand.kind) {
        .field_access => |fa| fa.field,
        else => null,
    };

    // Check aliasing rules.
    for (self.active_borrows.items) |existing| {
        if (existing.place != place) continue;

        // Disjoint field access: &p.x and &p.y don't conflict.
        if (self.areBorrowsDisjoint(new_field, existing.field)) continue;

        switch (kind) {
            .shared => {
                // New shared borrow: conflicts only with existing exclusive.
                if (existing.kind == .exclusive) {
                    self.emitError("cannot borrow: already mutably borrowed", span);
                    return;
                }
            },
            .exclusive => {
                // New exclusive borrow: conflicts with any existing borrow.
                if (existing.kind == .exclusive) {
                    self.emitError("cannot borrow mutably: already mutably borrowed", span);
                } else {
                    self.emitError("cannot borrow mutably: already borrowed", span);
                }
                return;
            },
        }
    }

    // Record the borrow (will be associated with a binding in checkLetBinding).
    self.active_borrows.append(self.allocator, .{
        .kind = kind,
        .place = place,
        .field = new_field,
        .created_at = span,
        .ref_binding = 0, // will be updated if bound to a let
    }) catch {};
}

fn areBorrowsDisjoint(self: *const Sema, new_field: ?Symbol, existing_field: ?Symbol) bool {
    _ = self;
    // Whole-place borrows overlap with everything on that place.
    if (new_field == null or existing_field == null) return false;
    // Distinct direct field borrows are disjoint.
    return new_field.? != existing_field.?;
}

/// Expire active borrows whose binding is not used in any remaining
/// expressions in the current block (NLL-style liveness).
fn expireDeadBorrows(self: *Sema, future_stmts: []const *const Ast.Expr, future_tail: ?*const Ast.Expr) void {
    var i: usize = 0;
    while (i < self.active_borrows.items.len) {
        const borrow = self.active_borrows.items[i];
        if (borrow.ref_binding == 0) {
            i += 1;
            continue;
        }

        var live = false;
        for (future_stmts) |expr| {
            if (exprUsesSymbol(expr, borrow.ref_binding)) {
                live = true;
                break;
            }
        }
        if (!live) {
            if (future_tail) |tail| {
                live = exprUsesSymbol(tail, borrow.ref_binding);
            }
        }

        if (!live) {
            _ = self.active_borrows.swapRemove(i);
        } else {
            i += 1;
        }
    }
}

fn exprUsesSymbol(expr: *const Ast.Expr, sym: Symbol) bool {
    return switch (expr.kind) {
        .ident => |s| s == sym,
        .binary => |b| exprUsesSymbol(b.lhs, sym) or exprUsesSymbol(b.rhs, sym),
        .unary => |u| exprUsesSymbol(u.operand, sym),
        .call => |c| blk: {
            if (exprUsesSymbol(c.callee, sym)) break :blk true;
            for (c.args) |arg| {
                if (exprUsesSymbol(arg, sym)) break :blk true;
            }
            break :blk false;
        },
        .field_access => |fa| exprUsesSymbol(fa.expr, sym),
        .optional_chain => |oc| blk: {
            if (exprUsesSymbol(oc.expr, sym)) break :blk true;
            if (oc.args) |args| {
                for (args) |arg| {
                    if (exprUsesSymbol(arg, sym)) break :blk true;
                }
            }
            break :blk false;
        },
        .index => |idx| exprUsesSymbol(idx.expr, sym) or exprUsesSymbol(idx.index, sym),
        .slice => |sl| blk: {
            if (exprUsesSymbol(sl.expr, sym)) break :blk true;
            if (sl.start) |s| if (exprUsesSymbol(s, sym)) break :blk true;
            if (sl.end) |e| if (exprUsesSymbol(e, sym)) break :blk true;
            break :blk false;
        },
        .block => |b| blk: {
            for (b.stmts) |stmt| {
                if (exprUsesSymbol(stmt, sym)) break :blk true;
            }
            if (b.tail) |tail| {
                if (exprUsesSymbol(tail, sym)) break :blk true;
            }
            break :blk false;
        },
        .if_expr => |if_e| blk: {
            if (exprUsesSymbol(if_e.condition, sym)) break :blk true;
            if (exprUsesSymbol(if_e.then_body, sym)) break :blk true;
            if (if_e.else_body) |eb| {
                if (exprUsesSymbol(eb, sym)) break :blk true;
            }
            break :blk false;
        },
        .return_expr => |rv| if (rv) |v| exprUsesSymbol(v, sym) else false,
        .let_binding => |lb| exprUsesSymbol(lb.value, sym),
        .let_else => |le| exprUsesSymbol(le.value, sym) or exprUsesSymbol(le.else_body, sym),
        .tuple_destructure => |td| exprUsesSymbol(td.value, sym),
        .assign => |a| exprUsesSymbol(a.target, sym) or exprUsesSymbol(a.value, sym),
        .tuple => |elems| blk: {
            for (elems) |e| {
                if (exprUsesSymbol(e, sym)) break :blk true;
            }
            break :blk false;
        },
        .range => |r| blk: {
            if (r.start) |s| if (exprUsesSymbol(s, sym)) break :blk true;
            if (r.end) |e| if (exprUsesSymbol(e, sym)) break :blk true;
            break :blk false;
        },
        .match_expr => |m| blk: {
            if (exprUsesSymbol(m.subject, sym)) break :blk true;
            for (m.arms) |arm| {
                if (arm.guard) |g| if (exprUsesSymbol(g, sym)) break :blk true;
                if (exprUsesSymbol(arm.body, sym)) break :blk true;
            }
            break :blk false;
        },
        .struct_literal => |sl| blk: {
            for (sl.fields) |f| {
                if (exprUsesSymbol(f.value, sym)) break :blk true;
            }
            break :blk false;
        },
        .array_literal => |elems| blk: {
            for (elems) |e| {
                if (exprUsesSymbol(e, sym)) break :blk true;
            }
            break :blk false;
        },
        .for_expr => |f| exprUsesSymbol(f.iterable, sym) or exprUsesSymbol(f.body, sym),
        .while_expr => |w| exprUsesSymbol(w.condition, sym) or exprUsesSymbol(w.body, sym),
        .loop_expr => |b| exprUsesSymbol(b, sym),
        .break_expr => |v| if (v) |val| exprUsesSymbol(val, sym) else false,
        .comptime_expr => |inner| exprUsesSymbol(inner, sym),
        .pipeline => |p| exprUsesSymbol(p.lhs, sym) or exprUsesSymbol(p.rhs, sym),
        .with_expr => |w| exprUsesSymbol(w.source, sym) or exprUsesSymbol(w.body, sym),
        .record_update => |ru| blk: {
            if (exprUsesSymbol(ru.source, sym)) break :blk true;
            for (ru.fields) |f| {
                if (exprUsesSymbol(f.value, sym)) break :blk true;
            }
            break :blk false;
        },
        .enum_variant => |ev| blk: {
            for (ev.args) |arg| {
                if (exprUsesSymbol(arg, sym)) break :blk true;
            }
            break :blk false;
        },
        .closure => |cl| exprUsesSymbol(cl.body, sym),
        .cast => |ca| exprUsesSymbol(ca.expr, sym),
        .array_comprehension => |ac| blk: {
            if (exprUsesSymbol(ac.expr, sym)) break :blk true;
            if (ac.clauses) |clauses| {
                for (clauses) |cl| {
                    if (exprUsesSymbol(cl.iterable, sym)) break :blk true;
                }
            } else {
                if (exprUsesSymbol(ac.iterable, sym)) break :blk true;
            }
            if (ac.filter) |f| if (exprUsesSymbol(f, sym)) break :blk true;
            break :blk false;
        },
        .await_expr => |inner| exprUsesSymbol(inner, sym),
        .async_block => |inner| exprUsesSymbol(inner, sym),
        .async_scope => |as| exprUsesSymbol(as.body, sym),
        .spawn_expr => |inner| exprUsesSymbol(inner, sym),
        .select_await => |sa| blk: {
            for (sa.arms) |arm| {
                if (exprUsesSymbol(arm.task, sym)) break :blk true;
                if (exprUsesSymbol(arm.body, sym)) break :blk true;
            }
            break :blk false;
        },
        .yield_expr => |inner| exprUsesSymbol(inner, sym),
        else => false,
    };
}

/// Called when a block/scope exits to expire borrows whose ref_binding
/// is in the exiting scope.
fn expireBorrowsInScope(self: *Sema, scope: *const Scope) void {
    // Remove borrows whose ref_binding is defined in this scope.
    var i: usize = 0;
    while (i < self.active_borrows.items.len) {
        const borrow = self.active_borrows.items[i];
        if (borrow.ref_binding != 0 and scope.bindings.get(borrow.ref_binding) != null) {
            _ = self.active_borrows.swapRemove(i);
        } else {
            i += 1;
        }
    }
}

fn emitError(self: *Sema, message: []const u8, span: Span) void {
    self.diagnostics.emit(Diagnostic.err(message, span));
}

fn emitWarning(self: *Sema, message: []const u8, span: Span) void {
    self.diagnostics.emit(Diagnostic.warn(message, span));
}

// ── Type formatting (for error messages) ─────────────────────────

pub fn typeName(self: *const Sema, tid: TypeId) []const u8 {
    const resolved = self.resolveAlias(tid);
    switch (self.getType(resolved)) {
        .err => return "<error>",
        .int => |i| {
            return switch (i.bits) {
                8 => if (i.signed) "i8" else "u8",
                16 => if (i.signed) "i16" else "u16",
                32 => if (i.signed) "i32" else "u32",
                64 => if (i.signed) "i64" else "u64",
                else => "<int>",
            };
        },
        .float => |f| return if (f.bits == 32) "f32" else "f64",
        .bool_type => return "bool",
        .void_type => return "void",
        .str_type => return "str",
        .struct_type => |st| return self.pool.resolve(st.name),
        .enum_type => |et| return self.pool.resolve(et.name),
        .array_type => return "[_]T",
        .slice_type => return "[]T",
        .tuple_type => return "(_, _)",
        .range_type => |rt| return if (rt.inclusive) "RangeInclusive[T]" else "Range[T]",
        .fn_type => return "fn",
        .ptr_type => return "*T",
        .ref_type => return "&T",
        .alias => return "<alias>",
        .generic_fn => return "<generic>",
    }
}
