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
    /// `use c_import("...")` — C header import via libclang
    c_import: CImportDecl,
    /// `trait Name = ...` — trait declaration
    trait_decl: TraitDecl,
    /// `impl Trait for Type = ...` — trait implementation record
    impl_decl: ImplDecl,
    /// Represents a parse error — this node is skipped by later passes.
    poisoned,
};

pub const CImportDecl = struct {
    header_code: []const u8,
};

pub const TraitDecl = struct {
    name: Symbol,
    methods: []const TraitMethodSig,
    is_pub: Visibility,
};

pub const ImplDecl = struct {
    trait_name: ?Symbol, // null for plain `impl Type` or `extend Type`
    type_name: Symbol,
    method_names: []const Symbol, // mangled names like "Type.method"
};

pub const TraitMethodSig = struct {
    name: Symbol,
    params: []const Param,
    return_type: ?*const TypeExpr,
    has_default: bool,
    span: Span,
};

pub const Visibility = enum { private, public };

/// A generic type parameter with optional trait bounds.
/// `T` or `T: Show` or `T: Show + Hash`
pub const TypeParam = struct {
    name: Symbol,
    bounds: []const Symbol, // trait names (empty if no bounds)
};

pub const FnDecl = struct {
    name: Symbol,
    type_params: []const TypeParam,
    params: []const Param,
    return_type: ?*const TypeExpr,
    body: *const Expr,
    is_async: bool,
    is_gen: bool,
    is_pub: Visibility,
};

pub const ExternFnDecl = struct {
    name: Symbol,
    params: []const Param,
    return_type: ?*const TypeExpr,
    is_variadic: bool,
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
    /// Slice: `arr[a..b]`
    slice: SliceExpr,
    /// Block: indented sequence of statements, final expr is the value
    block: BlockExpr,
    /// If expression: `if cond then a else b`
    if_expr: IfExpr,
    /// Return: `return expr`
    return_expr: ?*const Expr,
    /// Let binding (as statement-expression in a block)
    let_binding: LetBinding,
    /// Tuple destructuring: `let (a, b) = expr`
    tuple_destructure: TupleDestructure,
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
    /// While loop: `while cond: body`
    while_expr: WhileExpr,
    /// Infinite loop: `loop: body`
    loop_expr: *const Expr,
    /// For loop: `for x in range: body`
    for_expr: ForExpr,
    /// Break out of a loop
    break_expr,
    /// Continue to next loop iteration
    continue_expr,
    /// Array literal: `[1, 2, 3]`
    array_literal: []const *const Expr,
    /// Array comprehension: `[expr for x in iter]` or `[expr for x in iter if cond]`
    array_comprehension: ArrayComprehension,
    /// Struct literal: `Point { x: 1, y: 2 }`
    struct_literal: StructLiteral,
    /// Match expression: `match expr { pattern -> body, ... }`
    match_expr: MatchExpr,
    /// Enum variant constructor: `Color.Red` or `Shape.Circle(5.0)`
    enum_variant: EnumVariantExpr,
    /// Closure: `|a, b| a + b`
    closure: ClosureExpr,
    /// Type cast: `x as i64`
    cast: CastExpr,
    /// Defer: `defer expr`
    defer_expr: *const Expr,
    /// With expression: `with expr as [mut] name: body`
    with_expr: WithExpr,
    /// Record update: `{ expr with field: val, ... }`
    record_update: RecordUpdateExpr,
    /// Yield: `yield expr` (inside gen fn)
    yield_expr: *const Expr,
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
    mut_ref_of, // &mut expr
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

pub const SliceExpr = struct {
    expr: *const Expr,
    start: ?*const Expr,
    end: ?*const Expr,
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

pub const TupleDestructure = struct {
    names: []const Symbol,
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

pub const WhileExpr = struct {
    condition: *const Expr,
    body: *const Expr,
};

pub const ForExpr = struct {
    binding: Symbol,
    iterable: *const Expr,
    body: *const Expr,
};

pub const ArrayComprehension = struct {
    expr: *const Expr, // the expression to compute per element
    binding: Symbol, // loop variable name
    iterable: *const Expr, // what to iterate over
    filter: ?*const Expr, // optional if-condition
};

pub const StructLiteral = struct {
    name: Symbol,
    fields: []const FieldInit,
};

pub const FieldInit = struct {
    name: Symbol,
    value: *const Expr,
    span: Span,
};

pub const PipelineExpr = struct {
    lhs: *const Expr,
    rhs: *const Expr,
};

pub const MatchExpr = struct {
    subject: *const Expr,
    arms: []const MatchArm,
};

pub const MatchArm = struct {
    pattern: Pattern,
    guard: ?*const Expr = null,
    body: *const Expr,
    span: Span,
};

pub const Pattern = struct {
    kind: PatternKind,
    span: Span,
};

pub const PatternKind = union(enum) {
    /// Wildcard: `_`
    wildcard,
    /// Variable binding: `x`
    binding: Symbol,
    /// Integer literal: `42`
    int_literal: i64,
    /// Bool literal: `true`, `false`
    bool_literal: bool,
    /// String literal: `"hello"`
    string_literal: Symbol,
    /// Enum variant pattern: `Circle(r)` or `None`
    variant: VariantPattern,
    /// Or-pattern: `A | B`
    or_pattern: []const Pattern,
    /// At-binding: `name @ Pattern` — binds whole value and destructures
    at_binding: AtBinding,
    /// Range pattern: `1..=5` or `1..5`
    range_pattern: RangePattern,
};

pub const RangePattern = struct {
    start: i64,
    end: i64,
    inclusive: bool,
};

pub const AtBinding = struct {
    name: Symbol,
    pattern: *const Pattern,
};

pub const VariantPattern = struct {
    /// The variant name (e.g. `Circle`, `None`)
    name: Symbol,
    /// Payload bindings (e.g. the `r` in `Circle(r)`)
    bindings: []const Symbol,
};

pub const EnumVariantExpr = struct {
    /// The enum type name (e.g. `Color`)
    type_name: Symbol,
    /// The variant name (e.g. `Red`)
    variant_name: Symbol,
    /// Arguments (e.g. `5.0` in `Circle(5.0)`)
    args: []const *const Expr,
};

pub const ClosureExpr = struct {
    params: []const Symbol,
    body: *const Expr,
};

pub const CastExpr = struct {
    expr: *const Expr,
    target_type: *const TypeExpr,
};

pub const WithExpr = struct {
    /// The expression being bound: `with THIS as name: body`
    source: *const Expr,
    /// The binding name
    name: Symbol,
    /// Whether the binding is mutable (Form 2: builder pattern)
    is_mut: bool,
    /// The body expression
    body: *const Expr,
};

pub const RecordUpdateExpr = struct {
    /// The source expression: `{ THIS with field: val }`
    source: *const Expr,
    /// The struct type name (inferred from source)
    type_name: Symbol,
    /// Field overrides
    fields: []const FieldInit,
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
    /// Array type: `[N]T`
    array_type: ArrayTypeExpr,
    /// Slice type: `[]T`
    slice_type: *const TypeExpr,
    /// Trait object: `dyn Trait`
    trait_object: Symbol,
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

pub const ArrayTypeExpr = struct {
    size: u64,
    element: *const TypeExpr,
};
