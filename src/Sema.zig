//! Semantic analysis: name resolution, type checking, and validation.
//!
//! Sema runs as a validation pass between parsing and codegen.  It walks
//! the AST, resolves all names, computes types for every expression, and
//! reports type errors with source spans.  Codegen continues to work as
//! before — Sema is purely additive validation.

const std = @import("std");
const Ast = @import("Ast.zig");
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

const FnSigInfo = struct {
    type_id: TypeId, // TypeId of the fn_type
    return_type: TypeId,
    param_types: []const TypeId,
    is_variadic: bool,
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
/// Trait implementations: type name → list of trait names implemented.
type_impls: std.AutoHashMapUnmanaged(Symbol, std.ArrayList(Symbol)),

/// Active borrows in current function (Phase 3).
active_borrows: std.ArrayList(Borrow),

/// Closure capture analyses, keyed by closure expr address (Phase 4).
closure_analyses: std.AutoHashMapUnmanaged(usize, ClosureAnalysis),

/// Current function return type (for checking return statements).
current_return_type: TypeId,
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
        .generic_fns = .{},
        .mono_cache = .{},
        .methods = .{},
        .variant_lookup = .{},
        .trait_methods = .{},
        .type_impls = .{},
        .active_borrows = .empty,
        .closure_analyses = .{},
        .current_return_type = 0,
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

    // NOTE: current_scope is set in checkModule, not here, because
    // returning by value would make &self.root_scope a dangling pointer.
    self.current_scope = undefined;

    return self;
}

pub fn deinit(self: *Sema) void {
    self.types.deinit(self.allocator);
    self.named_types.deinit(self.allocator);
    self.fn_sigs.deinit(self.allocator);
    self.generic_fns.deinit(self.allocator);
    self.mono_cache.deinit(self.allocator);
    self.methods.deinit(self.allocator);
    self.variant_lookup.deinit(self.allocator);
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

fn getType(self: *const Sema, tid: TypeId) Type {
    if (tid >= self.types.items.len) return .err;
    return self.types.items[tid];
}

/// Resolve a TypeId through aliases.
fn resolveAlias(self: *const Sema, tid: TypeId) TypeId {
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

    // Pass 1: Collect all type declarations, function signatures, extern decls.
    self.collectDeclarations(module);

    // Pass 1.5: Verify trait conformance (impl blocks satisfy trait requirements).
    self.checkTraitConformance(module);

    // Pass 2: Check all function bodies.
    self.checkBodies(module);
}

// ── Pass 1: Declaration collection ───────────────────────────────

fn collectDeclarations(self: *Sema, module: *const Ast.Module) void {
    for (module.decls) |decl| {
        switch (decl.kind) {
            .type_decl => |td| self.collectTypeDecl(td, decl.span),
            .function => |fn_decl| self.collectFnDecl(fn_decl),
            .extern_fn => |ext| self.collectExternFn(ext),
            .let_decl => |ld| self.collectLetDecl(ld),
            .use_decl => {}, // use decls are no-ops for now
            .c_import => {}, // already expanded by Driver
            .trait_decl => |td| self.collectTraitDecl(td),
            .impl_decl => |id| self.collectImplDecl(id),
            .poisoned => {},
        }
    }
}

fn collectTypeDecl(self: *Sema, td: Ast.TypeDecl, _: Span) void {
    switch (td.kind) {
        .struct_def => |fields| {
            const field_names = self.allocator.alloc(Symbol, fields.len) catch return;
            const field_types = self.allocator.alloc(TypeId, fields.len) catch return;
            const field_defaults = self.allocator.alloc(bool, fields.len) catch return;

            for (fields, 0..) |field, i| {
                field_names[i] = field.name;
                field_types[i] = self.resolveTypeExpr(field.type_expr);
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
            const target = self.resolveTypeExpr(type_expr);
            const tid = self.addType(.{ .alias = target });
            self.named_types.put(self.allocator, td.name, tid) catch {};
        },
    }
}

fn collectFnDecl(self: *Sema, fn_decl: Ast.FnDecl) void {
    // Generic functions: store AST for later monomorphization.
    if (fn_decl.type_params.len > 0) {
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

    const ret_type = if (fn_decl.return_type) |rt|
        self.resolveTypeExpr(rt)
    else
        self.ty_void;

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
}

fn collectLetDecl(self: *Sema, ld: Ast.LetDecl) void {
    // Module-level let: resolve type from annotation or infer as error_type
    // (will be checked in pass 2 when we check the value expression).
    const tid = if (ld.type_expr) |te|
        self.resolveTypeExpr(te)
    else
        error_type;

    self.root_scope.put(self.allocator, ld.name, .{
        .type_id = tid,
        .is_mut = ld.is_mut,
        .state = .live,
        .span = Span.zero,
    });
}

fn collectTraitDecl(self: *Sema, td: Ast.TraitDecl) void {
    // Collect the method names required by this trait.
    const method_names = self.allocator.alloc(Symbol, td.methods.len) catch return;
    for (td.methods, 0..) |m, i| {
        method_names[i] = m.name;
    }
    self.trait_methods.put(self.allocator, td.name, method_names) catch {};
}

fn collectImplDecl(self: *Sema, id: Ast.ImplDecl) void {
    // Record which traits a type implements.
    const trait_sym = id.trait_name orelse return; // plain `impl Type` has no trait
    const gop = self.type_impls.getOrPut(self.allocator, id.type_name) catch return;
    if (!gop.found_existing) {
        gop.value_ptr.* = .empty;
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
                for (required) |req_name| {
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

// ── Type expression resolution ───────────────────────────────────

fn resolveTypeExpr(self: *Sema, te: *const Ast.TypeExpr) TypeId {
    return switch (te.kind) {
        .named => |sym| {
            if (self.named_types.get(sym)) |tid| return tid;
            // Unknown type name — don't report error, it might be forward-referenced.
            // If it's truly unknown, codegen will catch it.
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
        .trait_object => {
            // dyn Trait — trait object type. Treated as opaque for now.
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
    for (module.decls) |decl| {
        switch (decl.kind) {
            .function => |fn_decl| {
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
    self.current_return_type = sig.return_type;
    defer self.current_return_type = saved_ret;

    // Check body.
    _ = self.checkExpr(fn_decl.body);
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
        .ident => |sym| self.checkIdent(sym, expr.span),
        .binary => |bin| self.checkBinary(bin, expr.span),
        .unary => |un| self.checkUnary(un, expr.span),
        .grouped => |inner| self.checkExpr(inner),
        .block => |blk| self.checkBlock(blk),
        .let_binding => |let_b| self.checkLetBinding(let_b, expr.span),
        .if_expr => |if_e| self.checkIfExpr(if_e),
        .call => |call_e| self.checkCall(call_e, expr.span),
        .return_expr => |ret_val| self.checkReturn(ret_val, expr.span),
        .assign => |assign_e| self.checkAssign(assign_e, expr.span),
        .while_expr => |while_e| self.checkWhile(while_e),
        .loop_expr => |body| self.checkLoop(body),
        .for_expr => |for_e| self.checkFor(for_e),
        .break_expr => self.ty_void,
        .continue_expr => self.ty_void,
        .field_access => |fa| self.checkFieldAccess(fa, expr.span),
        .index => |idx| self.checkIndex(idx, expr.span),
        .slice => |sl| self.checkSlice(sl),
        .array_literal => |elems| self.checkArrayLiteral(elems),
        .struct_literal => |sl| self.checkStructLiteral(sl, expr.span),
        .match_expr => |m| self.checkMatchExpr(m),
        .enum_variant => |ev| self.checkEnumVariant(ev, expr.span),
        .closure => |cl| self.checkClosure(cl),
        .cast => |ca| self.checkCast(ca),
        .pipeline => |p| self.checkPipeline(p, expr.span),
        .defer_expr => |d| {
            _ = self.checkExpr(d);
            return self.ty_void;
        },
        .tuple => |elems| self.checkTuple(elems),
        .range => |r| self.checkRange(r),
        .variant_shorthand => |sym| self.checkVariantShorthand(sym, expr.span),
        .with_expr => |w| {
            const source_ty = self.checkExpr(w.source);
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
                .type_id = source_ty,
                .is_mut = w.is_mut,
                .span = expr.span,
                .state = .live,
            });
            return self.checkExpr(w.body);
        },
        .record_update => |ru| {
            const source_ty = self.checkExpr(ru.source);
            for (ru.fields) |f| {
                _ = self.checkExpr(f.value);
            }
            return source_ty;
        },
        .tuple_destructure => |td| {
            const val_type = self.checkExpr(td.value);
            // Each binding gets error_type for now (tuple element types).
            for (td.names) |name| {
                self.current_scope.put(self.allocator, name, .{
                    .type_id = error_type,
                    .is_mut = td.is_mut,
                    .span = expr.span,
                    .state = .live,
                });
            }
            _ = val_type;
            return self.ty_void;
        },
        .poisoned => error_type,
        .await_expr => |inner| self.checkExpr(inner),
    };
}

fn checkIdent(self: *Sema, sym: Symbol, span: Span) TypeId {
    // Check local/param scope.
    if (self.current_scope.lookup(sym)) |info| {
        // Move semantics: check for use-after-move.
        if (info.state == .moved) {
            self.emitError("use of moved value", span);
            return info.type_id;
        }
        // If non-Copy, mark as moved.
        if (!self.isCopy(info.type_id)) {
            if (self.current_scope.lookupMut(sym)) |mut_info| {
                mut_info.state = .moved;
            }
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

fn checkBinary(self: *Sema, bin: Ast.BinaryExpr, _: Span) TypeId {
    const lhs = self.checkExpr(bin.lhs);
    const rhs = self.checkExpr(bin.rhs);

    // Error recovery: if either side is error, propagate.
    if (lhs == error_type or rhs == error_type) return error_type;

    return switch (bin.op) {
        // Comparison operators return bool.
        .eq, .neq, .lt, .gt, .lte, .gte => self.ty_bool,
        // Logical operators return bool.
        .@"and", .@"or" => self.ty_bool,
        // Arithmetic: result type is the wider/left type.
        .add, .sub, .mul, .div, .mod => self.arithmeticResultType(lhs, rhs),
        // Bitwise operations.
        .bit_and, .bit_or, .bit_xor, .shl, .shr => lhs,
        // Wrapping arithmetic.
        .add_wrap, .sub_wrap, .mul_wrap => lhs,
        // Default operator (??).
        .default_op => lhs,
    };
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
            // ? operator — will be fully implemented in Phase 5.
            return error_type;
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

    for (blk.stmts) |stmt| {
        _ = self.checkExpr(stmt);
    }

    if (blk.tail) |tail| {
        return self.checkExpr(tail);
    }

    return self.ty_void;
}

fn checkLetBinding(self: *Sema, let_b: Ast.LetBinding, span: Span) TypeId {
    const val_type = self.checkExpr(let_b.value);

    // Determine binding type from annotation or inference.
    const bind_type = if (let_b.type_expr) |te| blk: {
        const annotated = self.resolveTypeExpr(te);
        // Check compatibility between annotated and inferred types.
        if (annotated != error_type and val_type != error_type) {
            if (!self.typesCompatible(annotated, val_type)) {
                self.emitError("type mismatch in let binding", span);
            }
        }
        break :blk annotated;
    } else val_type;

    self.current_scope.put(self.allocator, let_b.name, .{
        .type_id = bind_type,
        .is_mut = let_b.is_mut,
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

fn checkReturn(self: *Sema, ret_val: ?*const Ast.Expr, _: Span) TypeId {
    if (ret_val) |val| {
        _ = self.checkExpr(val);
    }
    return self.ty_void;
}

fn checkAssign(self: *Sema, assign_e: Ast.AssignExpr, _: Span) TypeId {
    _ = self.checkExpr(assign_e.target);
    _ = self.checkExpr(assign_e.value);

    // Assignment reinitializes the target (state → live).
    if (assign_e.target.kind == .ident) {
        const target_sym = assign_e.target.kind.ident;
        if (self.current_scope.lookupMut(target_sym)) |info| {
            info.state = .live;
        }
    }

    return self.ty_void;
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

fn checkFor(self: *Sema, for_e: Ast.ForExpr) TypeId {
    const iterable_type = self.checkExpr(for_e.iterable);
    _ = iterable_type;

    // Add loop variable to scope.
    var for_scope = Scope.init();
    for_scope.parent = self.current_scope;
    const saved = self.current_scope;
    self.current_scope = &for_scope;
    defer {
        for_scope.deinit(self.allocator);
        self.current_scope = saved;
    }

    // For now, infer loop variable as i32 (matching codegen behavior for ranges).
    for_scope.put(self.allocator, for_e.binding, .{
        .type_id = self.ty_i32,
        .is_mut = false,
        .state = .live,
        .span = Span.zero,
    });

    _ = self.checkExpr(for_e.body);
    return self.ty_void;
}

fn checkFieldAccess(self: *Sema, fa: Ast.FieldAccessExpr, span: Span) TypeId {
    const obj_type = self.checkExpr(fa.expr);
    if (obj_type == error_type) return error_type;

    const resolved = self.resolveAlias(obj_type);
    switch (self.getType(resolved)) {
        .struct_type => |st| {
            // Look up field.
            for (st.field_names, 0..) |fname, i| {
                if (fname == fa.field) {
                    return st.field_types[i];
                }
            }
            // Check for method (Type.method).
            // Methods are stored as regular functions with mangled names.
            // For now, don't report error — codegen handles method dispatch.
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
            return error_type;
        },
        .slice_type => {
            // .len and .ptr on slices.
            const field_name = self.pool.resolve(fa.field);
            if (std.mem.eql(u8, field_name, "len")) {
                return self.ty_i64;
            }
            return error_type;
        },
        .str_type => {
            // .len on str returns i64.
            const field_name = self.pool.resolve(fa.field);
            if (std.mem.eql(u8, field_name, "len")) {
                return self.ty_i64;
            }
            return error_type;
        },
        .enum_type => {
            // Enum variant access: EnumType.Variant
            return resolved;
        },
        else => return error_type,
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

fn checkStructLiteral(self: *Sema, sl: Ast.StructLiteral, _: Span) TypeId {
    // Look up the struct type.
    if (self.named_types.get(sl.name)) |tid| {
        const resolved = self.resolveAlias(tid);
        switch (self.getType(resolved)) {
            .struct_type => |st| {
                // Check each field initializer.
                for (sl.fields) |field_init| {
                    const val_type = self.checkExpr(field_init.value);
                    _ = val_type;

                    // Find field in struct.
                    var found = false;
                    for (st.field_names) |fname| {
                        if (fname == field_init.name) {
                            found = true;
                            break;
                        }
                    }
                    if (!found) {
                        self.emitError("unknown struct field", field_init.span);
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

    return result_type;
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
            // Add payload bindings.
            if (self.variant_lookup.get(vp.name)) |vi| {
                const resolved = self.resolveAlias(vi.enum_type);
                switch (self.getType(resolved)) {
                    .enum_type => |et| {
                        if (vi.variant_index < et.variant_payloads.len) {
                            if (et.variant_payloads[vi.variant_index]) |payloads| {
                                for (vp.bindings, 0..) |binding_sym, i| {
                                    const payload_type = if (i < payloads.len) payloads[i] else error_type;
                                    self.current_scope.put(self.allocator, binding_sym, .{
                                        .type_id = payload_type,
                                        .is_mut = false,
                                        .state = .live,
                                        .span = pattern.span,
                                    });
                                }
                            }
                        }
                    },
                    else => {},
                }
            } else {
                // Unknown variant — add bindings as error_type.
                for (vp.bindings) |binding_sym| {
                    self.current_scope.put(self.allocator, binding_sym, .{
                        .type_id = error_type,
                        .is_mut = false,
                        .state = .live,
                        .span = pattern.span,
                    });
                }
            }
        },
        .or_pattern => |alternatives| {
            for (alternatives) |*alt| {
                self.checkPattern(alt, subject_type);
            }
        },
        .at_binding => |ab| {
            self.checkPattern(ab.pattern, subject_type);
        },
        .range_pattern => {},
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

fn checkClosure(self: *Sema, cl: Ast.ClosureExpr) TypeId {
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
    // Pipeline RHS should be a function — check it.
    return self.checkExpr(p.rhs);
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
    if (r.start) |s| _ = self.checkExpr(s);
    if (r.end) |e| _ = self.checkExpr(e);
    return self.ty_i32; // ranges produce i32 iterables
}

fn checkVariantShorthand(self: *Sema, sym: Symbol, _: Span) TypeId {
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

    // Check all arguments first.
    for (call_e.args) |arg| {
        _ = self.checkExpr(arg);
    }

    // Built-in functions.
    if (self.isBuiltinFn(fn_sym)) {
        return self.checkBuiltinCall(fn_sym, call_e.args);
    }

    // Known function.
    if (self.fn_sigs.get(fn_sym)) |sig| {
        return sig.return_type;
    }

    // Local variable (function pointer).
    if (self.current_scope.lookup(fn_sym)) |info| {
        const resolved = self.resolveAlias(info.type_id);
        switch (self.getType(resolved)) {
            .fn_type => |ft| return ft.return_type,
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

    // Unknown function.
    return error_type;
}

fn checkMethodCall(self: *Sema, fa: Ast.FieldAccessExpr, args: []const *const Ast.Expr, _: Span) TypeId {
    const obj_type = self.checkExpr(fa.expr);

    // Check all arguments.
    for (args) |arg| {
        _ = self.checkExpr(arg);
    }

    if (obj_type == error_type) return error_type;

    // Try to find method: look for "TypeName.methodName" in fn_sigs.
    const resolved = self.resolveAlias(obj_type);
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
                        if (arg_type != error_type and binding_count < 16) {
                            // Check if already bound.
                            var already = false;
                            for (type_bindings[0..binding_count]) |b| {
                                if (b.param == sym) {
                                    already = true;
                                    break;
                                }
                            }
                            if (!already) {
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

        // Get the concrete type's name (must be a struct or enum).
        const resolved = self.resolveAlias(concrete);
        const concrete_name: ?Ast.Symbol = switch (self.getType(resolved)) {
            .struct_type => |st| st.name,
            .enum_type => |et| et.name,
            else => null,
        };
        if (concrete_name == null) continue; // can't check bounds on primitives yet

        // Check each required trait.
        for (tp.bounds) |trait_sym| {
            const impl_list = self.type_impls.get(concrete_name.?);
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
                const type_str = if (concrete_name) |cn| self.pool.resolve(cn) else "<unknown>";
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
        const resolved = self.resolveTypeExpr(rt);
        if (resolved != error_type) return resolved;
    }
    return error_type;
}

fn checkBuiltinCall(self: *Sema, fn_sym: Symbol, args: []const *const Ast.Expr) TypeId {
    _ = args;
    const name = self.pool.resolve(fn_sym);
    if (std.mem.eql(u8, name, "println") or std.mem.eql(u8, name, "print")) {
        return self.ty_void;
    }
    if (std.mem.eql(u8, name, "assert")) {
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
        std.mem.eql(u8, name, "Err");
}

fn isBuiltinValue(self: *Sema, sym: Symbol) bool {
    const name = self.pool.resolve(sym);
    return std.mem.eql(u8, name, "None");
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

    return lhs;
}

// ── Copy type classification (Phase 2: Move Semantics) ───────────

/// Returns true if a value of this type can be implicitly copied.
/// Primitives, pointers, fn types are Copy. Structs are Copy if all
/// fields are Copy. Enums/arrays/tuples follow the same rule.
pub fn isCopy(self: *const Sema, tid: TypeId) bool {
    if (tid == error_type) return true; // error types are permissive
    const resolved = self.resolveAlias(tid);
    switch (self.getType(resolved)) {
        .err => return true,
        .int, .float, .bool_type, .void_type, .str_type => return true,
        .ptr_type, .ref_type, .fn_type, .generic_fn => return true,
        .struct_type => |st| {
            for (st.field_types) |ft| {
                if (!self.isCopy(ft)) return false;
            }
            return true;
        },
        .enum_type => |et| {
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
        .alias => return true, // already resolved above
    }
}

fn isIntType(t: Type) bool {
    return t == .int;
}

fn isFloatType(t: Type) bool {
    return t == .float;
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

    // Check aliasing rules.
    for (self.active_borrows.items) |existing| {
        if (existing.place != place) continue;

        // Disjoint field access: &p.x and &p.y don't conflict.
        if (self.areBorrowsDisjoint(operand, existing.ref_binding)) continue;

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
        .created_at = span,
        .ref_binding = 0, // will be updated if bound to a let
    }) catch {};
}

fn areBorrowsDisjoint(self: *const Sema, new_operand: *const Ast.Expr, existing_binding: Symbol) bool {
    // For now, only check field disjointness for direct field access.
    // &p.x and &p.y are disjoint; &p.x and &p are not.
    _ = self;
    _ = new_operand;
    _ = existing_binding;
    return false; // conservative: assume not disjoint
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
        .tuple_type => return "(_, _)",
        .fn_type => return "fn",
        .ptr_type => return "*T",
        .ref_type => return "&T",
        .alias => return "<alias>",
        .generic_fn => return "<generic>",
    }
}
