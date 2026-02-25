//! AST node types for the With language.
//!
//! The AST is produced by the parser and consumed by later passes
//! (type checking, lowering, codegen).  All nodes are arena-allocated.
//! Every node carries a `Span` for diagnostic reporting.

const std = @import("std");
const Span = @import("Span.zig");
const InternPool = @import("InternPool.zig");

/// An interned identifier / keyword handle.
pub const Symbol = InternPool.Symbol;

// ── Top-level ────────────────────────────────────────────────────

/// A parsed source file.
pub const Module = struct {
    decls: []const Decl,
    span: Span,
};

// ── Declarations ─────────────────────────────────────────────────

pub const Decl = struct {
    kind: DeclKind,
    span: Span,
};

pub const DeclKind = union(enum) {
    /// `fn name(params) -> RetType = body`
    function: FnDecl,
    /// `type Name = { fields... }`  or  `type Name = enum { ... }`
    type_decl: TypeDecl,
    /// `use path`
    use_decl: UseDecl,
    /// `let name: Type = expr`  (module-level constant)
    let_decl: LetDecl,
    /// `extern fn name(params) -> RetType`
    extern_fn: ExternFnDecl,
    /// Represents a parse error — this node is skipped by later passes.
    poisoned,
};

pub const Visibility = enum { private, public };

pub const FnDecl = struct {
    name: Symbol,
    params: []const Param,
    return_type: ?*const TypeExpr,
    body: *const Expr,
    is_async: bool,
    is_pub: Visibility,
};

pub const ExternFnDecl = struct {
    name: Symbol,
    params: []const Param,
    return_type: ?*const TypeExpr,
};

pub const Param = struct {
    name: Symbol,
    type_expr: ?*const TypeExpr,
    is_mut: bool,
    span: Span,
};

pub const TypeDecl = struct {
    name: Symbol,
    kind: TypeDeclKind,
    is_pub: Visibility,
};

pub const TypeDeclKind = union(enum) {
    /// `type Foo = { field: Type, ... }`
    struct_def: []const FieldDef,
    /// `type Color = enum { Red, Green, Blue }`
    enum_def: []const VariantDef,
    /// `type Alias = OtherType`
    alias: *const TypeExpr,
};

pub const FieldDef = struct {
    name: Symbol,
    type_expr: *const TypeExpr,
    default: ?*const Expr,
    span: Span,
};

pub const VariantDef = struct {
    name: Symbol,
    payload: ?[]const *const TypeExpr,
    span: Span,
};

pub const UseDecl = struct {
    path: []const Symbol,
};

pub const LetDecl = struct {
    name: Symbol,
    type_expr: ?*const TypeExpr,
    value: *const Expr,
    is_mut: bool,
    is_pub: Visibility,
};

// ── Expressions ──────────────────────────────────────────────────

pub const Expr = struct {
    kind: ExprKind,
    span: Span,
};

pub const ExprKind = union(enum) {
    /// Integer literal: `42`, `0xFF`
    int_literal: i64,
    /// Float literal: `3.14`
    float_literal: f64,
    /// String literal: `"hello"`
    string_literal: Symbol,
    /// Bool literal: `true`, `false`
    bool_literal: bool,
    /// Identifier reference: `x`, `foo`
    ident: Symbol,
    /// Binary operation: `a + b`
    binary: BinaryExpr,
    /// Unary operation: `-x`, `not x`
    unary: UnaryExpr,
    /// Function call: `f(a, b)`
    call: CallExpr,
    /// Field access: `obj.field`
    field_access: FieldAccessExpr,
    /// Index: `arr[i]`
    index: IndexExpr,
    /// Block: indented sequence of statements, final expr is the value
    block: BlockExpr,
    /// If expression: `if cond then a else b`
    if_expr: IfExpr,
    /// Return: `return expr`
    return_expr: ?*const Expr,
    /// Let binding (as statement-expression in a block)
    let_binding: LetBinding,
    /// Assignment: `x = expr`
    assign: AssignExpr,
    /// Tuple: `(a, b, c)`
    tuple: []const *const Expr,
    /// Range: `a..b` or `a..=b`
    range: RangeExpr,
    /// Enum variant shorthand: `.Member`
    variant_shorthand: Symbol,
    /// Await: `expr.await`
    await_expr: *const Expr,
    /// Pipeline: `a |> f`
    pipeline: PipelineExpr,
    /// Grouped expression (parenthesized)
    grouped: *const Expr,
    /// Poisoned — parse error placeholder
    poisoned,
};

pub const BinaryExpr = struct {
    op: BinOp,
    lhs: *const Expr,
    rhs: *const Expr,
};

pub const BinOp = enum {
    add,
    sub,
    mul,
    div,
    mod,
    eq,
    neq,
    lt,
    gt,
    lte,
    gte,
    @"and",
    @"or",
    bit_and,
    bit_or,
    bit_xor,
    shl,
    shr,
    add_wrap,
    sub_wrap,
    mul_wrap,
    default_op, // ??
};

pub const UnaryExpr = struct {
    op: UnaryOp,
    operand: *const Expr,
};

pub const UnaryOp = enum {
    negate,
    not,
    ref_of, // &expr
    deref, // *expr
    try_op, // expr?
};

pub const CallExpr = struct {
    callee: *const Expr,
    args: []const *const Expr,
};

pub const FieldAccessExpr = struct {
    expr: *const Expr,
    field: Symbol,
};

pub const IndexExpr = struct {
    expr: *const Expr,
    index: *const Expr,
};

pub const BlockExpr = struct {
    stmts: []const *const Expr,
    /// The trailing expression whose value is the block's value, if any.
    tail: ?*const Expr,
};

pub const IfExpr = struct {
    condition: *const Expr,
    then_body: *const Expr,
    else_body: ?*const Expr,
};

pub const LetBinding = struct {
    name: Symbol,
    type_expr: ?*const TypeExpr,
    value: *const Expr,
    is_mut: bool,
};

pub const AssignExpr = struct {
    target: *const Expr,
    value: *const Expr,
};

pub const RangeExpr = struct {
    start: ?*const Expr,
    end: ?*const Expr,
    inclusive: bool,
};

pub const PipelineExpr = struct {
    lhs: *const Expr,
    rhs: *const Expr,
};

// ── Type Expressions ─────────────────────────────────────────────

/// A type as written in source code (not yet resolved).
pub const TypeExpr = struct {
    kind: TypeExprKind,
    span: Span,
};

pub const TypeExprKind = union(enum) {
    /// Named type: `i32`, `String`, `MyStruct`
    named: Symbol,
    /// Generic application: `Vec[T]`, `HashMap[K, V]`
    generic: GenericTypeExpr,
    /// Reference: `&T`, `&mut T`
    ref_type: RefTypeExpr,
    /// Pointer: `*const T`, `*mut T`
    ptr_type: PtrTypeExpr,
    /// Function type: `fn(i32, i32) -> i32`
    fn_type: FnTypeExpr,
    /// Tuple type: `(i32, String)`
    tuple_type: []const *const TypeExpr,
    /// Optional: `?T`
    optional: *const TypeExpr,
    /// Inferred (no annotation, placeholder for type checker)
    inferred,
};

pub const GenericTypeExpr = struct {
    name: Symbol,
    args: []const *const TypeExpr,
};

pub const RefTypeExpr = struct {
    is_mut: bool,
    pointee: *const TypeExpr,
};

pub const PtrTypeExpr = struct {
    is_mut: bool,
    pointee: *const TypeExpr,
};

pub const FnTypeExpr = struct {
    params: []const *const TypeExpr,
    return_type: *const TypeExpr,
};
