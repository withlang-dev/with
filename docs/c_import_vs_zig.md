# c_import: With vs Zig Deep Comparison

Zig's translate-c is ~10K lines across 8 files. Our c_import is ~2100 lines in CImport.w + ~1250 lines in clang_bridge.c. This document catalogs every meaningful difference.

---

## Architecture

### Zig
- Uses **aro** (Zig's own C compiler frontend) to parse C, not libclang
- Gets a full **C AST** with expressions, statements, types — everything
- Translates **function bodies** (statements, loops, if/else, switch, expressions)
- Builds a **Zig AST** in memory, then renders it to source
- Two-pass: `prepopulateGlobalNameTable` then `transTopLevelDecls` then `transMacros`
- Separate `MacroTranslator` with a proper **recursive descent parser** for C macro bodies
- `PatternList` for template-based `##` pattern matching

### With
- Uses **libclang** (via clang_bridge.c FFI) for C parsing
- Only sees declarations — `CXTranslationUnit_SkipFunctionBodies`
- Translates **declarations only** (no function bodies)
- Builds output as **string concatenation** (no AST)
- Two-pass: `ci_prepopulate_names` + `ci_collect_demoted_types` then main loop
- Macros via **separate `cc -E -dM`** preprocessor pass + regex-style string parsing
- Token paste via simple string-based suffix matching

### Impact
Zig can translate static inline functions, initializers, compound literals, and full expressions. We emit `comptime_error` stubs for static inline functions and skip function bodies entirely. This is the single largest gap.

---

## Type Translation

### Pointers

| Feature | Zig | With |
|---------|-----|------|
| `const` qualifier | `[*c]const T` or `*const T` | `*const T` |
| `volatile` qualifier | `*volatile T` (preserved in pointer info) | `*volatile T` (stored in TY_PTR d2, no codegen effect yet) |
| `restrict` qualifier | Stripped (no Zig equivalent) | Stripped |
| `void *` | `?*anyopaque` | `*mut c_void` / `*const c_void` |
| Function pointers | `?*const fn(...) callconv(.c) T` | `*const fn(...) -> T` |
| Nullable pointers | All `[*c]T` pointers are implicitly nullable | `Option[*mut T]` for function params (except self) |
| `[*c]T` (C pointer) | Special C pointer type that allows null, arithmetic, cast | No equivalent — uses `*mut T` |

**Gap: C pointer semantics.** Zig's `[*c]T` is a special pointer type that behaves like C pointers (nullable, allows arithmetic, implicit casts). We use regular `*mut T` wrapped in `Option[]`. This means C APIs that pass null pointers require explicit unwrapping in With but work transparently in Zig.

### Arrays

| Feature | Zig | With |
|---------|-----|------|
| Fixed arrays `T[N]` | `[N]T` | `[N]T` |
| Incomplete arrays `T[]` | `[*c]T` or `[*c]const T` | `*T` (decay to pointer) |
| Flexible array member | `[0]T` + accessor method | `[0]T` (last struct field) |
| VLA | Error: "VLA unsupported" | `__UNSUPPORTED:variable-length array` |

**Gap: Flexible array member accessors.** Zig generates a `fn flexibleMember(self: *Self) [*c]T` accessor. We just emit `[0]T` without an accessor.

### Integers

| Feature | Zig | With |
|---------|-----|------|
| `int` | `c_int` (platform-sized) | `i32` (hardcoded) |
| `long` | `c_long` | `i64` (hardcoded on arm64) |
| `short` | `c_short` | `i16` (hardcoded) |
| `unsigned int` | `c_uint` | `u32` |
| `char` | `u8` (TODO: `c_char`) | `i8` |
| `_Bool` | `bool` | `bool` |
| `__int128` | `i128` | `i128` |

**Gap: Platform-specific integer types.** Zig uses `c_int`, `c_long` etc. which match the target platform's ABI. We hardcode sizes for arm64 macOS. Cross-compilation would produce wrong types.

### Floats

| Feature | Zig | With |
|---------|-----|------|
| `float` | `f32` | `f32` |
| `double` | `f64` | `f64` |
| `long double` | `c_longdouble` | `f64` (lossy on x86) |
| `_Float16` | `f16` | Not handled |
| `__float128` | `f128` | Not handled |

**Gap: `c_longdouble` and exotic float types.** `long double` is 80-bit on x86 but 64-bit on arm64. Hardcoding `f64` is correct on arm64 but wrong for x86 cross-compilation.

### Enums

| Feature | Zig | With |
|---------|-----|------|
| Named enums | `pub const enum_Foo = c_int;` + constants | `type Foo = i32` + `let` constants |
| Anonymous enums | `unnamed_N` mangled name | Skipped |
| Incomplete enums | `opaque` | `opaque` (recently added) |
| Enum values | Separate `pub const FOO: enum_Foo = N;` | `let FOO: i32 = N` |

**Gap: Anonymous enums.** Zig translates them with mangled names. We skip them entirely. This loses constants defined in anonymous enums.

### Structs/Unions

| Feature | Zig | With |
|---------|-----|------|
| Named structs | `pub const struct_Foo = extern struct { ... }` | `type Foo = { ... }` |
| Forward decls | `opaque` (via `opaque_demotes` table) | `opaque` (via `demoted_types` string) |
| Bitfields | Demote entire struct to `opaque` | Demote entire struct to `opaque` |
| Anonymous structs | `unnamed_N` with mangled name | `Name_anon_N` synthetic name |
| Empty structs (MSVC) | Padding field based on alignment | `__pad0: u8` always |
| Field defaults | `@import("std").mem.zeroes(T)` or `0`/`false`/`null` | `0`/`0.0`/`false` for primitive types |
| Alignment attrs | Per-field `align(N)` annotations | `@[packed]` + explicit padding bytes |
| Flexible array | `[0]T` + accessor function | `[0]T` (no accessor) |
| `_Atomic` fields | Demote to opaque (TODO) | Demote to opaque |

**Gap: Field alignment granularity.** Zig computes per-field alignment using the C layout and emits `align(N)` on individual fields. We detect non-natural layout and emit `@[packed]` with manual padding byte arrays. Zig's approach is more precise and produces better codegen.

**Gap: Anonymous enum/struct as typedef child.** Zig has `unnamed_typedefs` table that maps anonymous types to their typedef names. We handle the `typedef struct Foo {} Foo;` case but don't handle `typedef struct { int x; } Point;` (unnamed struct with typedef).

### Typedefs

| Feature | Zig | With |
|---------|-----|------|
| Standard types | `builtin_typedef_map` (12 entries) | `ci_map_builtin_typedef` (21 entries) |
| Self-referential | Detected and skipped | Detected and skipped |
| Underlying type | Recursive type translation | Recursive type translation |

We actually have **more** builtin typedef mappings than Zig (pid_t, uid_t, gid_t, mode_t, off_t, time_t, wchar_t, va_list).

---

## Declaration Translation

### Functions

| Feature | Zig | With |
|---------|-----|------|
| Regular extern | `pub extern "c" fn name(...) T` | `extern fn name(...) -> T` |
| Static functions | Skipped (no linkage) | Skipped |
| Static inline | **Translated body** as `inline fn` | `comptime_error("static inline — wrap in C shim")` |
| Inline | Translated body or demoted to extern | Skipped or comptime_error |
| Variadic | `pub extern "c" fn name(..., ...) T` | `extern fn name(..., ...) -> T` |
| Always-inline | `inline fn` with body | comptime_error stub |
| Calling convention | Per-platform CC mapping | `@[callconv("...")]` annotation |
| Unnamed params | `arg_N` generated name | `pN` generated name |

**Gap: Function body translation.** This is the largest architectural difference. Zig translates ~40 statement/expression types. We skip all bodies. This means:
- Static inline functions (very common in system headers) → we emit stubs
- Functions with bodies that Zig translates inline → we require C shim wrappers
- Initializer expressions → we can't translate

### Variables

| Feature | Zig | With |
|---------|-----|------|
| `const` globals | `pub const name: T = ...` (with initializer) | `extern let name: T` |
| Non-const globals | `pub var name: T = ...` | `extern var name: T` |
| Initializer exprs | Full expression translation | Not translated (extern only) |

**Gap: Variable initializers.** Zig translates const variable initializers (integer constants, string literals, struct literals, etc.). We always emit `extern` and rely on the C linker.

---

## Macro Translation

### Architecture

| Aspect | Zig | With |
|--------|-----|------|
| Source | Preprocessor token stream from aro | `cc -E -dM` output (raw text) |
| Parser | Recursive descent with proper tokenizer | String-based regex-style matching |
| Expression depth | Full C expression grammar | ~10 patterns (binary, unary, ternary, cast, sizeof) |
| Type awareness | Knows about typedefs, can resolve type names | Only knows `ci_is_c_type_name` set |

**Gap: Tokenizer-based parsing vs string matching.** Zig's MacroTranslator uses a proper tokenizer (aro's CToken) and recursive descent parser with operator precedence. Our approach does string-level pattern matching which is fragile for complex expressions.

### Expression Support

| Expression | Zig | With |
|------------|-----|------|
| Integer literals | Full (hex, octal, binary, suffixes, separators) | Partial (hex, decimal, suffixes) |
| Float literals | Full (all suffixes, exponents) | Partial |
| String literals | Full (UTF-8, UTF-16, UTF-32, wide) | Basic (ASCII only) |
| Char literals | Full (escape sequences, unicode) | Basic (common escapes) |
| Binary ops | Full precedence climbing | String-based operator search |
| Unary ops | `!`, `~`, `-`, `*`, `&`, `++`, `--`, sizeof, typeof | `!`, `~`, `-`, sizeof |
| Casts | `(type)expr` with full type resolution | `(type)expr` with base types only |
| Ternary | `a ? b : c` → `if (a) b else c` | Same |
| Comma | `(a, b)` → block with discards | `(a, b)` → last expression only |
| Sizeof | `sizeof(type)` and `sizeof(expr)` | `sizeof(type)` and `sizeof(param)` |
| Function calls | With known function resolution | Only builtins and known identifiers |
| Member access | `.field` and `->field` | Not supported |
| Compound literals | `(struct S){.x=1}` | Not supported |
| Assignments | `=`, `+=`, `-=`, etc. | Not supported |
| Increment/decrement | `++`, `--` (pre and post) | Not supported |
| Address-of/deref | `&x`, `*p` | Not supported |
| Array subscript | `a[i]` | Not supported |
| Logical AND/OR | Short-circuit evaluation | Maps to `and`/`or` |

**Gap: Expression completeness.** Zig handles ~25 expression types vs our ~10. The most impactful missing ones are member access, compound literals, and address-of/deref — these appear in system header macros.

### Token Pasting (##)

| Feature | Zig | With |
|---------|-----|------|
| Method | Template pattern matching (PatternList.zig) | String suffix detection |
| Patterns | 32 templates (with/without parens, all suffix combos) | 14 suffix variants |
| Extras | `CAST_OR_CALL`, `WL_CONTAINER_OF`, `DISCARD` | None |
| Matching | Token-level structural matching (parameter indices) | String-level `##` detection |

**Gap: CAST_OR_CALL and DISCARD patterns.** Zig recognizes `(X)(Y)` as either a cast or function call and `(void)(X)` as a discard. We don't handle these patterns.

### Builtins

| Builtin | Zig | With |
|---------|-----|------|
| `__builtin_expect` | Maps to helper | Strips to first arg |
| `__builtin_unreachable` | `@unreachable` | `unreachable()` |
| `__builtin_trap` | Not in map | `abort()` |
| `__builtin_clz/ctz/popcount` | Maps to helpers | Maps to `with_clz/ctz/popcount` |
| `__builtin_bswap*` | `@byteSwap` | Maps to `with_bswap*` |
| `__builtin_abs/labs/llabs` | Maps to helpers | `abs()` |
| `__builtin_memcpy/memset/strlen` | Maps to helpers | Strip prefix |
| Math builtins (ceil/floor/sqrt/sin/cos...) | `@ceil`/`@floor`/`@sqrt`/`@sin`/`@cos`... (Zig builtins) | Strip prefix (stdlib names) |
| `__builtin_constant_p` | Maps to helper | Returns `0` |
| `__builtin_object_size` | Maps to helper | Not handled |
| `__builtin_mul_overflow` | Maps to helper | Not handled |
| `__builtin_huge_valf/inff` | Maps to helpers | Not handled |
| `__builtin_signbit` | Maps to helper | Not handled |
| `__builtin_exp2` | `@exp2` | Not handled |
| `__builtin_assume` | Maps to helper | Not handled |
| `__has_builtin` | Maps to helper | Not handled |
| Checked builtins (`__memcpy_chk`, `__memset_chk`) | Maps to helpers | Not handled |

**Gap: ~18 builtins.** Zig handles 50 builtins (with some having direct Zig builtin tags like `@sqrt`, `@ceil`), we handle ~32. Missing: `object_size`, `mul_overflow`, `huge_valf`, `inff`, `nanf`, `signbit/f`, `exp2/f`, `assume`, `has_builtin`, `labs`, `llabs`, `__memcpy_chk`, `__memset_chk`, `strcmp`, `isinf_sign`. Many are used in system headers.

---

## Name Resolution

| Feature | Zig | With |
|---------|-----|------|
| Global name table | `global_names` (strong) + `weak_global_names` (struct/enum) | Flat `with_cimport_is_name_emitted` |
| Collision resolution | `mangleWeakGlobalName` with counter | `ci_unique_name` with `_N` suffix |
| Struct/typedef twin | struct gets `struct_Foo` name, typedef gets `Foo`, alias emitted | struct gets `Foo`, alias `struct_Foo = Foo` emitted |
| Scope tracking | Full `Scope` hierarchy (Root, Block, Condition) | No scope tracking |
| Alias emission | Post-pass: emit `pub const bare = struct_bare` | Inline: emit `type struct_Foo = Foo` |
| Typedef precedence | Typedefs are "strong names" in prepopulate | Same — typedefs shadow struct names |

**Gap: Scope tracking.** Zig maintains a full scope hierarchy for local declarations. We only handle global scope since we skip function bodies. This is fine for our current architecture.

---

## Error Handling

| Feature | Zig | With |
|---------|-----|------|
| Untranslatable type | `@compileError("...")` with source location | `comptime_error("...")` |
| Untranslatable expr | `@compileError("...")` with reason | `comptime_error("untranslatable C macro: NAME")` |
| Demoted function | Demoted to `extern` with warning comment | comptime_error stub |
| Location info | `// file:line:col` comments | No location info |
| Warning comments | `// ... warning: reason` | No warnings |

**Gap: Source locations and warnings.** Zig emits source location comments (`// /usr/include/stdio.h:42:1`) and warning messages explaining why a translation was demoted. We emit no source locations or explanatory comments.

---

## Feature Matrix Summary

| Category | Zig | With | Delta |
|----------|-----|------|-------|
| Type translation | 95% | 80% | Platform-specific int/float types, `[*c]T` semantics |
| Function declarations | 100% | 90% | Static inline bodies, always-inline |
| Struct translation | 95% | 85% | Per-field alignment, anonymous struct typedefs |
| Enum translation | 95% | 80% | Anonymous enums |
| Variable declarations | 95% | 70% | Initializer expressions |
| Macro translation | 85% | 55% | Expression depth, tokenizer-based parsing |
| Builtin mapping | ~44 builtins | ~32 builtins | 12 missing |
| Function bodies | Full translation | Skip entirely | Largest gap |
| Error diagnostics | Excellent (locations, warnings) | Basic (name only) | Locations, warnings |

---

## Priority Gaps to Close (ordered by impact)

### P0 — Would unblock significant use cases (ALL DONE)
1. ~~**Anonymous enum constants**~~ — DONE: detect `(unnamed`/`(anonymous` synthetic names, skip type alias but emit constants
2. ~~**Missing builtins**~~ — DONE: 18 new builtins added (exp2, signbit, labs, llabs, strcmp, __memcpy_chk, __memset_chk, huge_valf, inff, nanf, object_size, mul_overflow, assume, has_builtin, isinf_sign)
3. ~~**CAST_OR_CALL pattern**~~ — DONE: `(X)(Y)` where X is an identifier → function call
4. ~~**DISCARD pattern**~~ — DONE: `(void)(X)` and const/volatile variants → evaluate X

### P1 — Correctness improvements
5. ~~**Anonymous struct typedef**~~ — DONE: `typedef struct { int x; } Point;` inlined as `type Point = { x: i32 = 0 }`
6. **Flexible array member accessor** — generate accessor function
7. **Source location comments** — `// file:line:col` for debugging
8. **Platform-specific integer types** — `c_int` vs hardcoded `i32`

### P2 — Completeness
9. **Static inline body translation** — translate simple function bodies
10. **Variable initializers** — translate const expressions
11. **Member access in macros** — `.field` and `->field`
12. **More macro expression types** — `&`, `*`, `++`, `--`, `[]`

---

## Zig Architectural Details Worth Noting

### Macro Translation uses a real tokenizer
Zig's MacroTranslator uses aro's CToken tokenizer and builds a recursive descent parser with proper C operator precedence (13 levels). Our string-based approach is fragile for nested expressions. Key difference: Zig's parser handles comma operator by creating labeled blocks with discard statements (not just taking the last expression).

### Pattern matching is token-structural, not string-based
Zig's PatternList tokenizes both the template and the input macro, then compares token-by-token (modulo parameter indices). Our `##` handling does string-level `ci_find_str(body, "##")`. Zig has 34 patterns including `CAST_OR_CALL(X,Y)` → `(X)(Y)` and `DISCARD(X)` → `(void)(X)` with const/volatile variants.

### Zero-value default generation is type-aware
Zig's `createZeroValueNode` dispatches on the C type: `bool` → `false`, `int/float` → `0`, `pointer` → `null`, anything else → `@import("std").mem.zeroes(T)`. Our `ci_default_for_type` only handles primitives (no pointer null, no complex-type zeroes).

### Variable reference detection in macros
Zig detects when an object macro references a mutable global variable (`refs_var_decl` flag) and automatically converts it from `pub const` to `pub inline fn` returning the expression. We don't detect this.

### Flexible array member accessors
Zig generates `fn flexibleMember(self: anytype) [*c]T` accessor functions for flexible array members (`T field[]` at end of struct). We just emit `[0]T` with no accessor.

### Scope-aware member function registration
Zig's `Scope.Root.addMemberFunction` associates functions with struct/union types and embeds them as methods during `processContainerMemberFns()`. Functions like `struct_init(self: *struct_Foo)` become methods on the translated struct. We have no equivalent.
