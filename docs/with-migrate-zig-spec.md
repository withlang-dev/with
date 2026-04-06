# `with migrate zig` — Zig-to-With Source Translator

**Best-effort migration from Zig to With.**

Zig and With are close cousins — both are systems languages that
reject hidden control flow, value explicit memory management, and
compile through LLVM. The translation is more mechanical than
Rust because Zig has no lifetimes, no trait system complexity,
and no macro metaprogramming. The hard parts are allocators and
comptime.

---

## Design Goals

1. **Get 85% of the way there.** Zig and With share so much
   philosophy that most code is a syntax transform. The output
   should be close to idiomatic With.

2. **Flag allocator patterns.** Zig threads allocators explicitly
   through every function. With uses implicit allocation. The
   tool strips allocator parameters and flags them.

3. **Flag comptime.** Zig's comptime is more powerful than With's.
   Simple comptime (constants, type selection) translates. Complex
   comptime (type-level computation, comptime loops) is flagged.

4. **One command.** `with migrate zig src/` translates a Zig
   project directory.

---

## Usage

```
with migrate zig src/main.zig             # single file
with migrate zig src/                     # directory (all .zig files)
with migrate zig src/ -o lib/             # explicit output
with migrate zig src/ --check             # dry run
with migrate zig src/ --diff              # unified diff
with migrate zig src/ --stats             # summary
```

---

## Translation Rules

### Tier 1: Mechanical Syntax (100% automated)

#### Braces → indentation

```zig
fn process(x: i32) i32 {
    if (x > 0) {
        return x * 2;
    } else {
        return -x;
    }
}

// With
fn process(x: i32) -> i32:
    if x > 0:
        return x * 2
    else:
        return -x
```

Strip `{` `}` `;`. Remove parens from `if (cond)`, `while (cond)`,
`for (...)`. Convert to indent-based blocks.

#### Bindings

```zig
const x: i32 = 5;          →  let x: i32 = 5
var x: i32 = 5;            →  var x: i32 = 5
const x = value;           →  let x = value
var x: i32 = undefined;    →  var x: i32 = 0   // @migrate: was undefined
_ = expr;                  →  let _ = expr
```

Zig `const` → With `let`. Zig `var` → With `var`.
`undefined` → zero-initialize with flag (With doesn't have
`undefined` — all variables are initialized).

#### Return type syntax

```zig
fn add(a: i32, b: i32) i32 { ... }
fn greet() void { ... }
fn fail() noreturn { ... }

// With
fn add(a: i32, b: i32) -> i32: ...
fn greet: ...
fn fail -> Never: ...
```

Zig puts return type after `)` without `->`. With uses `->`.
`void` → omit. `noreturn` → `Never`.

#### Type syntax

```zig
[]const u8                 →  &[u8]        // slice
[*]u8                      →  *mut u8      // many-pointer
*u8                        →  *mut u8      // single-pointer
*const u8                  →  *const u8
?T                         →  Option[T]
!T                         →  // @migrate: error union, see below
[N]T                       →  [T; N]       // fixed array
@Vector(4, f32)            →  // @migrate: SIMD vector
```

Zig `?T` → `Option[T]`. Zig slices `[]const u8` → `&[u8]`.
Zig pointers `*T` → `*mut T`.

#### Error unions and `try`

```zig
fn read(fd: i32) ![]u8 { ... }
const data = try read(fd);

// With
fn read(fd: i32) -> Result[Vec[u8], Error]: ...
let data = read(fd)?
```

Zig `!T` → `Result[T, Error]`. Zig `try expr` → `expr?`.
Zig `catch` → `// @migrate: use match or ?? instead`:

```zig
const val = expr catch |err| handle(err);
const val = expr catch 0;

// With
let val = expr ?? 0
// or:
let val = match expr:
    Ok(v) -> v
    Err(e) -> handle(e)
```

`orelse` → `??` (already in Migrate.zig).

#### Error sets

```zig
const ReadError = error{
    FileNotFound,
    PermissionDenied,
    Unexpected,
};

// With
type ReadError =
    | FileNotFound
    | PermissionDenied
    | Unexpected
```

Zig `error{...}` → With discriminant enum.

#### `null` → `None`

```zig
const x: ?i32 = null;
if (x) |val| { use(val); }

// With
let x: Option[i32] = None
if let Some(val) = x: use(val)
```

Already in Migrate.zig: `null` → `None`.

#### Optional unwrap / payload capture

```zig
if (opt) |value| { use(value); }
if (opt) |value| { use(value); } else { fallback(); }
while (iter.next()) |item| { process(item); }

// With
if let Some(value) = opt: use(value)
if let Some(value) = opt: use(value) else: fallback()
while let Some(item) = iter.next(): process(item)
```

Zig payload capture `|val|` → With `let Some(val) =`.

#### Error payload capture

```zig
const result = doSomething() catch |err| {
    log.err("failed: {}", .{err});
    return err;
};

// With
let result = match doSomething():
    Ok(v) -> v
    Err(err) ->
        log.error(f"failed: {err}")
        return Err(err)
```

#### `switch` → `match`

```zig
switch (x) {
    0 => "zero",
    1...9 => "digit",
    else => "other",
}

// With
match x:
    0 -> "zero"
    1..=9 -> "digit"
    _ -> "other"
```

`switch` → `match`. `=>` → `->`. `else` → `_`.
Range `1...9` → `1..=9`.

#### `for` loops

```zig
for (items) |item| { process(item); }
for (items, 0..) |item, i| { indexed(i, item); }

// With
for item in items: process(item)
for (i, item) in items.enumerate(): indexed(i, item)
```

Zig's `for (slice) |elem|` → `for elem in slice:`.
Indexed: `for (slice, 0..) |elem, i|` → `for (i, elem) in slice.enumerate():`.

#### `while`

```zig
while (cond) { body; }
while (cond) : (afterthought) { body; }
while (iter.next()) |val| { body; }

// With
while cond: body
while cond:
    body
    afterthought
while let Some(val) = iter.next(): body
```

#### `defer` / `errdefer`

```zig
defer allocator.free(buf);
errdefer allocator.free(buf);

// With
defer free(buf)
// @migrate: errdefer → no direct equivalent.
// Use Result + explicit cleanup, or restructure with `?` operator.
```

`defer` → `defer` (same semantics). `errdefer` → flag
(With doesn't have `errdefer`; the pattern is to use `?` and
let `defer` handle cleanup unconditionally, or restructure).

#### Attributes / builtins

```zig
@as(i32, value)            →  value as i32
@intCast(value)            →  value as i32     // @migrate: verify target type
@ptrCast(ptr)              →  ptr as *mut T    // @migrate: verify target type
@alignCast(ptr)            →  ptr              // @migrate: alignment cast removed
@truncate(value)           →  value as u8      // @migrate: verify target type
@bitCast(T, value)         →  // @migrate: bitcast — use unsafe reinterpret
@sizeOf(T)                 →  sizeof[T]()
@alignOf(T)                →  alignof[T]()
@memcpy(dst, src)          →  mem_copy(dst, src, n)
@memset(dst, val, len)     →  mem_set(dst, val, len)
@min(a, b)                 →  min(a, b)
@max(a, b)                 →  max(a, b)
@import("std")             →  use std
@panic("msg")              →  panic("msg")
@tagName(val)              →  // @migrate: no direct equivalent
@enumFromInt(val)          →  // @migrate: use Type.from_int(val)
@errorName(err)            →  // @migrate: use err.name()
@field(obj, name)          →  // @migrate: no comptime field access
```

`@as(T, x)` → `x as T` (already in Migrate.zig).

#### String literals

```zig
const s = "hello";              // []const u8
const s: [:0]const u8 = "hi";  // null-terminated

// With
let s = "hello"                 // str
let s = c"hi"                   // @migrate: null-terminated → c-string if needed
```

Zig strings are byte slices. With `str` is UTF-8. For most code
the translation is direct. Null-terminated strings (`[:0]`) →
`c"..."` or flag.

#### Struct syntax

```zig
const Point = struct {
    x: f64,
    y: f64,

    pub fn init(x: f64, y: f64) Point {
        return .{ .x = x, .y = y };
    }

    pub fn length(self: Point) f64 {
        return @sqrt(self.x * self.x + self.y * self.y);
    }
};

// With
type Point = {
    x: f64,
    y: f64,
}

impl Point:
    fn init(x: f64, y: f64) -> Point: Point { x, y }
    fn length(self: Point) -> f64: sqrt(self.x * self.x + self.y * self.y)
```

Zig embeds methods inside the struct definition. With separates
them into `impl` blocks.

Anonymous init `.{ .x = 1, .y = 2 }` → `Point { x: 1, y: 2 }`
(need the type name in With).

#### Enum syntax

```zig
const Color = enum {
    red,
    green,
    blue,
};

const Color = enum(u8) {
    red = 0,
    green = 1,
    blue = 2,
};

// With
type Color =
    | red
    | green
    | blue

type Color: u8 =
    | red = 0
    | green = 1
    | blue = 2
```

#### Tagged union

```zig
const Value = union(enum) {
    int: i64,
    float: f64,
    string: []const u8,
    none,
};

// With
type Value =
    | Int(i64)
    | Float(f64)
    | String(str)
    | None_
// @migrate: variant names capitalized per With convention
```

Zig `union(enum)` → With discriminant enum with payloads.
Variant names need capitalization (Zig uses lowercase,
With uses PascalCase for variants).

#### Test blocks

```zig
test "addition works" {
    try std.testing.expect(1 + 1 == 2);
}

// With
@[test]
fn test_addition_works:
    assert(1 + 1 == 2)
```

`test "name" { body }` → `@[test] fn test_name: body`.
`std.testing.expect(cond)` → `assert(cond)`.
`std.testing.expectEqual(a, b)` → `assert(a == b)`.

#### Semicolons

Strip `;`. Zig requires them everywhere; With uses none.

#### Comments

```zig
// line comment           →  // line comment
/// doc comment           →  /// doc comment
//! top-level doc         →  //! top-level doc
```

Direct pass-through.

---

### Tier 2: Semantic Translations (automated with caveats)

#### Allocator removal

This is the biggest Zig→With shift. Zig threads allocators
explicitly. With uses implicit allocation.

```zig
fn parse(allocator: std.mem.Allocator, input: []const u8) !Ast {
    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();
    // ...
}

// With
fn parse(input: &[u8]) -> Result[Ast, Error]:
    // @migrate: allocator parameter removed — With uses implicit allocation
    var list = Vec[u8].new()
    defer list.free()
    // ...
```

**Rules:**
1. Remove `allocator: std.mem.Allocator` parameter
2. Remove `allocator` argument from call sites
3. `ArrayList(T).init(allocator)` → `Vec[T].new()`
4. `list.deinit()` → `list.free()` or just remove (With has Drop)
5. `allocator.alloc(T, n)` → `alloc(n * sizeof[T]()) as *mut T`
6. `allocator.free(ptr)` → `free(ptr)`
7. `allocator.create(T)` → `alloc(sizeof[T]()) as *mut T`
8. `allocator.destroy(ptr)` → `free(ptr as *mut c_void)`
9. Flag with `// @migrate: allocator removed`

**ArenaAllocator:**
```zig
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit();
const alloc = arena.allocator();

// With
var arena = Arena.new()
defer arena.free()
// @migrate: arena allocator — With has Arena in std.alloc
```

#### `std` library mapping

```zig
std.debug.print(...)       →  print(...)
std.log.info(...)          →  log.info(...)    // @migrate: use std.log
std.mem.eql(u8, a, b)     →  a == b
std.mem.copy(u8, dst, src) →  mem_copy(dst, src, n)
std.mem.set(u8, buf, val)  →  mem_set(buf, val, n)
std.mem.indexOf(u8, h, n)  →  h.find(n)       // @migrate: verify API
std.sort.sort(T, items, ctx, cmp) → items.sort(cmp)
std.fmt.bufPrint(...)      →  f"..."           // @migrate: approximate
std.fs.cwd()               →  // @migrate: use std.fs functions
std.ArrayList(T)           →  Vec[T]
std.HashMap(K, V, ...)     →  HashMap[K, V]
std.AutoHashMap(K, V)      →  HashMap[K, V]
std.StringHashMap(V)       →  HashMap[str, V]
```

Map common `std` types and functions to With equivalents.
Unmapped ones get flagged.

#### Sentinel-terminated types

```zig
[:0]const u8              →  str           // @migrate: was null-terminated slice
[*:0]const u8             →  *const u8     // @migrate: was null-terminated pointer
```

Zig's sentinel-terminated slices don't exist in With. Translate
to the closest equivalent and flag.

#### Packed structs / extern structs

```zig
const Header = extern struct {
    magic: u32,
    version: u16,
    flags: u16,
};

const Packed = packed struct {
    a: u3,
    b: u5,
};

// With
@[extern]
type Header = {
    magic: u32,
    version: u16,
    flags: u16,
}

// @migrate: packed struct with bit-width fields — needs manual bitfield handling
type Packed = {
    a: u8,   // @migrate: was u3
    b: u8,   // @migrate: was u5
}
```

`extern struct` → `@[extern] type`. `packed struct` → flag
(With doesn't have sub-byte fields in the same way).

#### Comptime (simple cases)

```zig
comptime var i: usize = 0;
inline while (i < 4) : (i += 1) { ... }

const len = comptime blk: {
    break :blk calcLen(input);
};

// With
// Simple constant:
const len: usize = comptime calcLen(input)

// Comptime loop:
// @migrate: comptime loop — unroll manually or use comptime if
```

Simple `comptime` expressions → `comptime` (With has basic
comptime evaluation). Comptime loops and comptime blocks with
complex logic → flag.

#### Optionals in boolean context

```zig
if (maybe_ptr) |ptr| { use(ptr); }
if (maybe_ptr == null) { ... }
const val = opt orelse default;
const val = opt.?;

// With
if let Some(ptr) = maybe_ptr: use(ptr)
if maybe_ptr.is_none(): ...
let val = opt ?? default
let val = opt.unwrap()
```

`opt.?` → `opt.unwrap()`. `orelse` → `??`.

#### Multi-value return / tuples

```zig
fn divmod(a: i32, b: i32) struct { q: i32, r: i32 } {
    return .{ .q = a / b, .r = a % b };
}

// With
fn divmod(a: i32, b: i32) -> (i32, i32):
    (a / b, a % b)
// @migrate: anonymous struct return → tuple (field names lost)
```

Zig's anonymous struct returns → With tuples. Named fields are
lost in the translation — flag if field names matter.

---

### Tier 3: Structural Flags (cannot auto-translate)

#### Comptime type computation

```zig
fn Matrix(comptime T: type, comptime rows: usize, comptime cols: usize) type {
    return struct {
        data: [rows * cols]T,
        // ...
    };
}

// With
// @migrate: comptime type function — no direct equivalent.
// With options:
//   1. Use generic type: type Matrix[T] = { data: Vec[T], rows: i32, cols: i32 }
//   2. Use comptime if for a fixed set of instantiations
// Original Zig code preserved as comment below.
```

Zig's `comptime` type-level functions are more powerful than
With's generics. Flag with alternatives.

#### `anytype` parameters

```zig
fn print(value: anytype) void { ... }

// With
// @migrate: anytype → use generic with trait bound
fn print[T: Debug](value: T): ...
```

`anytype` → generic `T` with appropriate trait bound. The tool
guesses `Debug` or `Display` as the bound; human picks the right one.

#### Custom allocator interface

```zig
pub const Allocator = struct {
    ptr: *anyopaque,
    vtable: *const VTable,
    // ...
};

// With
// @migrate: Zig Allocator interface — With uses implicit allocation.
// For custom allocators, use Arena or Pool from std.alloc.
```

#### `@cImport` / `@cInclude`

```zig
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
});

// With
c_import("<stdio.h>")
c_import("<stdlib.h>")
```

Direct mapping. Zig `@cImport`/`@cInclude` → With `c_import`.

#### Async (Zig's suspended model)

```zig
// Zig async is frame-based, fundamentally different from With fibers
var frame = async doWork();
const result = await frame;

// With
// @migrate: Zig async uses stackless frames. With uses stackful fibers.
let task = doWork()     // returns Task[T] in async context
let result = task.await
```

Zig's async is stackless (suspended frames). With's is stackful
(fibers). Simple cases translate directly. Complex frame
manipulation → flag.

#### `@fieldParentPtr`

```zig
const node = @fieldParentPtr(Node, "link", link_ptr);

// With
// @migrate: @fieldParentPtr — use container_of pattern or restructure
```

No equivalent. Flag.

#### Bit manipulation builtins

```zig
@clz(x)                   →  with_clz(x)     // available via runtime
@ctz(x)                   →  with_ctz(x)
@popCount(x)              →  with_popcount(x)
@byteSwap(x)              →  with_bswap32(x)  // @migrate: verify width
@bitReverse(x)            →  // @migrate: no direct equivalent
```

Some builtins have runtime wrappers. Others need manual
translation.

#### Vectors (SIMD)

```zig
const v: @Vector(4, f32) = .{ 1, 2, 3, 4 };

// With
// @migrate: SIMD vector — no direct equivalent.
// Use std.math Array operations or manual loop.
```

#### Build system (`build.zig`)

Not translated. `build.zig` → `with.toml` is a manual step.
The tool emits a comment listing dependencies and build options.

---

## Quality Grades

| Level | Meaning | Typical Zig code |
|---|---|---|
| **A** | Pure syntax. Compiles immediately. | Algorithms, data structures, math |
| **B** | Allocator removal + minor edits. | Most library code |
| **C** | Comptime or structural changes. | Generic/metaprogramming-heavy code |
| **D** | Heavily flagged. | SIMD, custom allocators, async frames |

---

## Why Zig→With Is Easier Than Rust→With

| Dimension | Zig→With | Rust→With |
|---|---|---|
| Lifetimes | Neither has them | Must remove Rust's |
| References in structs | Neither restricts (Zig uses pointers) | Rust allows, With bans |
| Allocators | Zig explicit → With implicit (flag) | Rust implicit → With implicit (direct) |
| Error handling | `!T` + `try` → `Result[T,E]` + `?` | Same model (direct) |
| Traits | Zig has interfaces, loosely similar | Rust traits map closely |
| Closures | Zig has limited closures | Rust closures map well |
| Macros | Zig has none (comptime instead) | Rust has complex macro system |
| Async | Different models (flag) | Different models (flag) |
| Generics | `comptime` type params → `[T]` | `<T>` → `[T]` |
| Braces/semicolons | Remove | Remove |

The biggest Zig-specific challenge is **allocator threading** —
it's everywhere in Zig code and nowhere in With. The tool strips
it mechanically but must flag every instance so the programmer
can verify the implicit allocation is correct.

The easiest part is that Zig has **no lifetime annotations, no
proc macros, no `Pin`, no `Arc/Rc`**. These are the hardest parts
of Rust migration and simply don't exist in Zig.

---

## Implementation Plan

### Step 1: Extend syntax transformer

Port and extend `transformZig` from Migrate.zig:
- Brace → indent (existing)
- `const` → `let` (existing)
- `try` → `?` (existing)
- `orelse` → `??` (existing)
- `null` → `None` (existing)
- `@as(T, x)` → `x as T` (existing)
- Add: return type `fn() T {` → `fn -> T:`
- Add: `if (cond)` → `if cond:`
- Add: `while (cond)` → `while cond:`
- Add: `switch` → `match`
- Add: payload capture `|val|` → `let Some(val) =`
- Add: struct/enum/union syntax
- Add: semicolon stripping

**Done when:** Simple Zig files produce readable With syntax.

### Step 2: Type rewriter

- `?T` → `Option[T]`
- `!T` → `Result[T, Error]`
- `[]const u8` → `&[u8]` or `str`
- `[*]T` → `*mut T`
- `*T` → `*mut T`, `*const T` → `*const T`
- `[N]T` → `[T; N]`
- `std.ArrayList(T)` → `Vec[T]`
- `std.AutoHashMap(K, V)` → `HashMap[K, V]`
- `void` → omit, `noreturn` → `Never`
- `anytype` → `T` with flag
- `undefined` → zero value with flag

**Done when:** Common Zig types produce correct With types.

### Step 3: Allocator stripper

- Detect `allocator: std.mem.Allocator` parameter → remove
- Remove `allocator` from call sites
- `.init(allocator)` → `.new()`
- `.deinit()` → `.free()` or remove
- `allocator.alloc(T, n)` → `alloc(n * sizeof[T]())`
- `allocator.free(ptr)` → `free(ptr)`
- Flag every removal

**Done when:** Zig code with standard allocator patterns translates
without allocator references.

### Step 4: Builtin and std mapping

- `@` builtins → With equivalents or flags
- `std.debug.print` → `print`
- `std.mem.*` → With memory functions
- `std.testing.*` → With assert functions
- `std.sort.*` → `.sort()` methods

**Done when:** Common std usage translates.

### Step 5: Struct/impl restructuring

Zig puts methods inside struct definitions. With separates
them. Extract methods into `impl` blocks.

**Done when:** Zig structs with methods produce With type + impl.

### Step 6: Flag generator and grading

Walk translated output. Flag:
- `comptime` type functions
- `anytype` parameters
- SIMD vectors
- `@fieldParentPtr`
- `errdefer`
- Complex comptime blocks
- Custom allocator types
- Async frames

Grade each file A–D.

### Step 7: Multi-file and module rewriting

Handle `@import` → `use`. Map Zig's file-is-a-module to With's
module structure.

**Done when:** `with migrate zig src/` translates a full project.

---

## Philosophy

Zig programmers already think like With programmers. Both
communities value:
- Explicit over implicit
- No hidden allocations (Zig) / no hidden control flow (With)
- Simple language, powerful stdlib
- C interop as a first-class concern

The migration pitch is:

> "You already write code this way. With just gives you
> the borrow checker, `async`/`await`, traits, and real generics —
> without the allocator threading. Your Zig intuitions transfer
> directly. The only new concept is `with` blocks."
