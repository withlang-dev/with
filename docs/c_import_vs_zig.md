# c_import: With vs Zig — Definitive Deep Comparison

Zig's translate-c: ~10K lines across 8 files.
Our c_import: ~5.2K lines across 2 files (CImport.w + clang_bridge.c).

---

## 1. Architecture

| Aspect | Zig | With |
|--------|-----|------|
| C frontend | **aro** (Zig's own C compiler, full AST) | **libclang** (cursor-based API) |
| AST access | Full typed AST with every node kind | Cursor handles with lazy child expansion |
| Output format | Builds in-memory Zig AST, then renders | String concatenation |
| Macro source | aro's preprocessor token stream | `cc -E -dM` subprocess |
| Parse flags | N/A (aro parses everything) | `flags=0` (includes function bodies) |

**Key difference:** Zig uses aro which gives it a fully-typed C AST where every expression has a known type at translation time. We use libclang which provides cursors — we can query types but don't have the same typed-expression-tree. This means Zig can make type-aware translation decisions (e.g., signed vs unsigned wrapping for arithmetic) that we cannot.

---

## 2. Name Resolution

| Feature | Zig | With |
|---------|-----|------|
| Strong names | `global_names` HashMap | `with_cimport_is_name_emitted` (C-side global array) |
| Weak names | `weak_global_names` HashMap | Implicit in `ci_prepopulate_names` shadowed string |
| Mangling | `mangleWeakGlobalName` with counter | `ci_unique_name` with `_N` suffix |
| Scope tracking | Full `Scope` hierarchy (Root, Block, Condition, Loop) | None (implicit in AST walker recursion) |
| Alias emission | Post-pass: `alias_list` → `pub const bare = struct_bare` | Inline: `type struct_Foo = Foo` |
| Typedef→unnamed struct | `unnamed_typedefs` maps anonymous types to typedef name | `with_cimport_typedef_anon_record_field_count` inlines fields |

**Real gap:** Zig's `Scope.Block` tracks local variable names across nested scopes and mangles collisions. Our function body translator uses `ci_escape_reserved` for keyword conflicts but doesn't track local scope — two local variables with the same name in different blocks would collide. This only matters for function body translation of complex inline functions.

---

## 3. Type Translation

| Type | Zig | With |
|------|-----|------|
| `void` | `anyopaque` | `void` (in function returns), `c_void` (in pointers) |
| `int` | `c_int` (platform-sized) | `i32` (hardcoded arm64) |
| `long` | `c_long` | `i64` (hardcoded arm64) |
| `char` | `u8` | `i8` |
| `_Bool` | `bool` | `bool` |
| `float` | `f32` | `f32` |
| `double` | `f64` | `f64` |
| `long double` | `c_longdouble` (80-bit on x86) | `f64` (lossy on x86) |
| `_Float16` | `f16` | Not handled |
| `__float128` | `f128` | Not handled |
| `void *` | `?*anyopaque` | `*mut c_void` / `*const c_void` |
| C pointers | `[*c]T` (nullable, arithmetic, casts) | `*mut T` wrapped in `Option[]` |
| Function pointers | `?*const fn(...) callconv(.c) T` | `*const fn(...) -> T` |
| `volatile` qualifier | `*volatile T` preserved in pointer info | `*volatile T` (stored in TY_PTR d2) |
| `restrict` qualifier | `noalias` on function params | Stripped |
| `_Atomic` | `TODO` error | `__UNSUPPORTED` (demotes container) |

**Real gaps:**
1. **`c_int`/`c_long` vs hardcoded sizes** — We hardcode `i32`/`i64` which is correct on arm64 macOS but wrong for cross-compilation.
2. **`[*c]T` pointer semantics** — Zig's C pointer type handles null, arithmetic, and implicit casts. We use `*mut T` + `Option[]` which requires explicit unwrapping.
3. **`char` signedness** — Zig uses `u8`, we use `i8`. On arm64 macOS char is signed, so `i8` is technically correct, but cross-compilation would need `c_char`.

---

## 4. Declaration Translation

### Functions

| Feature | Zig | With |
|---------|-----|------|
| Extern functions | `pub extern "c" fn` | `extern fn` |
| Static functions | Skipped | Skipped |
| Static inline | **Full body translation** with graceful demotion to extern | Try AST body translation, fallback to `comptime_error` stub |
| Non-static inline | Body translated if available | Try AST body translation, fallback to extern |
| Always-inline | `inline fn` with body | Same path as static inline |
| Variadic with body | **Demoted to extern** with warning | Emitted as extern |
| Unnamed params | `arg_N` with mutable redeclaration | `pN` |
| Mutable params | Redeclared as `var arg_param = param` | Not redeclared (With params are immutable) |
| Calling conventions | 14 CC types from C attributes | `@[callconv("...")]` annotation |

**Real gap — graceful demotion:** When Zig fails to translate a function body, it changes `is_extern = true` and keeps the declaration. We emit a `comptime_error` stub instead. Zig's approach is better — the function is still callable as extern even if the body couldn't be translated.

### Variables

| Feature | Zig | With |
|---------|-----|------|
| Const globals | Initializer translated | `ci_try_eval_var_init` tries constant eval, fallback to extern |
| Non-const globals | `pub var` with init | `extern var` |
| Static locals | Wrapped in struct for namespace | Not handled (function bodies skip these) |
| Thread-local | `threadlocal` qualifier | Not handled |

### Structs/Unions

| Feature | Zig | With |
|---------|-----|------|
| Layout | `extern struct` with per-field `align(N)` | `@[packed]` + explicit padding byte arrays |
| Bitfields | Demote to `opaque` with warning | Demote to `opaque` |
| Anonymous fields | `unnamed_N` with name tracking table | `unnamed_N` |
| Flexible array members | `[0]T` + accessor function `fn member(self) [*c]T` | `[0]T` only |
| Empty structs (MSVC) | `_padding: uN` with alignment-aware sizing | `__pad0: u8` always |
| Default values | `@import("std").mem.zeroes(T)` or `0`/`false`/`null` | `0`/`0.0`/`false` for primitives only |
| Member functions | `processContainerMemberFns()` embeds methods | Not supported |

**Real gap — alignment:** Zig computes per-field alignment by inspecting the C layout (offset, size, parent alignment) and emits `align(N)` annotations. We use `@[packed]` with manual padding bytes. Zig's approach produces better LLVM codegen because packed structs disable alignment optimizations. For most cases our approach produces correct layouts, but it may have performance implications.

**Real gap — default values:** Zig uses `std.mem.zeroes(T)` for complex types (pointers → null, nested structs → recursive zeroes). We only zero primitive types. This means `let s = StructWithPointers {}` won't work without explicit initialization in our output.

### Enums

| Feature | Zig | With |
|---------|-----|------|
| Named enums | `pub const enum_Foo = c_int` + constant declarations | `type Foo = i32` + `let` constants |
| Anonymous enums | Translate constants with mangled name | Translate constants (skip type alias) |
| Forward-declared | `opaque` | `opaque` |
| Enum type | Translated from tag type | Mapped from `with_cimport_enum_int_type` string |

---

## 5. Expression Translation

### AST-based (for function bodies)

| Expression | Zig | With |
|------------|-----|------|
| Integer literals | Full (with type-aware promotion) | Via `with_ci_eval_int_value` |
| Float literals | Full (all suffix types) | Strip suffix, raw value |
| String literals | Full (UTF-8/16/32, wide, null-sentinel arrays) | Source text passthrough |
| Char literals | Full (escape sequences) | Via `with_ci_eval_int_value` |
| Binary ops | Type-aware (wrapping for unsigned: `+%`, `-%`, `*%`) | Simple operator mapping (no wrapping) |
| Signed division | `@divTrunc` | `/` |
| Signed remainder | `__helpers.signedRemainder` | `%` |
| Pointer arithmetic | Special signed index casting via `@intCast`/`@bitCast` | Simple `+`/`-` |
| Pointer difference | `transPtrDiffExpr` with `@ptrToInt` and division | Simple `-` |
| Unary ops | Type-aware negate (wrapping for unsigned: `-%`) | Pattern-based (`0 - x`) |
| Address-of | `@address_of` | `&` |
| Deref | Opaque type check, function pointer no-op | `unsafe: *` |
| Casts | 15+ cast kinds (int, float, bool, pointer, bitcast, etc.) | Generic `as` cast |
| Member access | `.field` with type resolution | `.field` |
| Array subscript | Full with optional base | `arr[idx]` |
| Function calls | With builtin dispatch and member fn resolution | With builtin remapping |
| Sizeof/alignof | `@sizeOf`/`@alignOf` with type resolution | `sizeof[T]()` |
| Compound literal | Type-aware init with static/dynamic distinction | Inner expression passthrough |
| Init list | Struct/array/union-specific handlers | Generic item list |
| Inc/dec (pre/post) | Separate pre/post with used/unused tracking | Block expression |
| Comma | Block with discard stmts, last value breaks | Last expression only |
| Ternary | `if (cond) then else else_` | `if cond != 0: then else: else_` |
| _Generic | Resolves to chosen association | Resolves to last child (libclang pre-resolves) |
| Statement expr | Block scope with last expression value | Translate compound stmt |
| Predefined | `__func__` etc. | `"__func__"` string |
| `__builtin_*` | 50 builtins in `builtins.zig` | 50 builtins in `ci_translate_builtin_call` |

**Real gaps:**
1. **Wrapping arithmetic:** Zig emits `+%`, `-%`, `*%` for unsigned integer overflow. We use plain operators. This produces undefined behavior for unsigned overflow in With (if With doesn't define wrapping semantics for unsigned types).
2. **Signed division/remainder:** Zig uses `@divTrunc` and `signedRemainder` for correct C semantics. We use `/` and `%` which may differ (With's `%` might not match C's truncation-toward-zero behavior).
3. **Cast precision:** Zig has 15+ cast kind handlers (`transIntCast`, `transPointerCastExpr`, etc.) that emit `@truncate`, `@bitCast`, `@intFromBool`, `@floatFromInt`, etc. We emit generic `as` casts which may not handle all edge cases.
4. **Pointer arithmetic with signed indices:** Zig emits `@as(usize, @bitCast(@as(isize, @intCast(idx))))` for pointer + signed index. We emit `ptr + idx` which may have incorrect semantics.

### Macro-based (for `#define` bodies)

| Feature | Zig (MacroTranslator) | With (ci_translate_c_expr) |
|---------|----------------------|---------------------------|
| Tokenizer | aro's CToken (proper lexer) | String-level pattern matching |
| Parser | Recursive descent, 13 precedence levels | `ci_find_binary_op_ext` string search |
| Numeric literals | Full (binary, octal, hex, separators, all suffixes, promotion) | Hex/decimal, basic suffix stripping |
| String concat | Adjacent strings via `.array_cat` | `ci_concat_strings` |
| Sizeof | Parsed as unary expression | String match `ci_starts_with(trimmed, "sizeof")` |
| Casts | `parseCCastExpr` with type name resolution | `ci_is_c_type_name` + `ci_map_base_type` |
| Postfix ops | `.field`, `->field`, `[i]`, `()`, `++`, `--` | `[i]` via binary op, no postfix `++`/`--` |
| Comma | Block with discards, last value via `break` | Last expression only |
| Type macros | `parseCTypeName` with struct/union/enum keywords | Not handled |
| Blank macros | `blank_macros` set, chaining detection | Empty value → skip |
| Variable refs | `refs_var_decl` flag → convert to inline fn | Not detected |
| Fn ptr alias | `getFnProto` → create wrapper fn | Not detected |

**Real gaps:**
1. **Token-level parsing vs string matching:** Zig's MacroTranslator uses proper tokenization. Our string-based approach is fragile — nested parentheses, operator precedence, and complex expressions can be parsed incorrectly.
2. **Comma operator semantics:** Zig creates a labeled block where all but the last expression are discarded with `_ = expr;`, and the last breaks with a value. We just take the last expression, losing side effects.
3. **Variable reference detection:** When an object macro references a mutable global, Zig auto-converts it from `pub const` to `pub inline fn`. We don't detect this, so the macro may produce incorrect results at compile time.
4. **Postfix operators in macros:** Zig parses `.field`, `->field`, `(args)`, `[idx]`, `++`, `--` as postfix operators. We handle `[idx]` as binary and don't handle postfix `++`/`--` at all in the macro path.

---

## 6. Statement Translation

| Statement | Zig | With |
|-----------|-----|------|
| Compound stmt | Block scope with push/pop | Recursive, no scope tracking |
| Return | With optional value translation | With optional value |
| If/else | Full with scope | `if cond != 0:` |
| While | Condition with scope | `while cond != 0:` |
| Do-while | `while (true)` + break at end | `while true:` + `if cond == 0: break` |
| For | Init + while + continue expr | Init + while + inc |
| Switch | `switch` with case ranges, labeled break for fallthrough | `if/else if` chain (no fallthrough) |
| Break/continue | Direct | Direct |
| Goto | Labeled blocks with break | `comptime_error("goto not supported")` |
| Labels | Integrated with goto translation | `// label: name` comment |
| Decl stmt | Local variable with init, scope tracking | `var name: type = init` |
| Static assert | `@compileError` | Not handled |
| Inline asm | `asm volatile` | Not handled |

**Real gaps:**
1. **Switch fallthrough:** Zig translates C switch fallthrough using labeled blocks and breaks. Our `if/else if` chain treats each case independently — if the original C code relies on fallthrough, the translation is wrong.
2. **Goto:** Zig translates goto to labeled blocks with break. We emit `comptime_error`. This affects ~1% of static inline functions.
3. **Scope tracking:** Zig pushes/pops scopes and mangles conflicting names. We don't track scopes, so variable shadowing in nested blocks may produce incorrect code.

---

## 7. PatternList (## Token Pasting)

| Pattern | Zig | With |
|---------|-----|------|
| Suffix `##U/UL/ULL/L/LL/F` | 28 patterns (with/without parens, all case variants) | `ci_try_translate_token_paste` + `ci_token_paste_suffix` |
| `CAST_OR_CALL(X,Y)` → `(X)(Y)` | Token-structural match | `ci_translate_c_expr` identifier-in-parens detection |
| `DISCARD(X)` → `(void)(X)` | 10 patterns (const/volatile variants) | `ci_is_discard_pattern` |
| `WL_CONTAINER_OF` | Linux kernel macro | Not handled (Linux-only) |

**Implementation difference:** Zig tokenizes both the template and the input macro, then compares token-by-token. We use string-level detection (`ci_find_str(body, "##")`). Zig's approach is more robust for complex macro bodies; ours works for the common cases.

---

## 8. Error Handling

| Feature | Zig | With |
|---------|-----|------|
| Untranslatable type | `@compileError("...")` with source location comment | `comptime_error("...")` |
| Untranslatable expr | `@compileError("...")` with reason | `comptime_error("untranslatable C macro: NAME")` |
| Demoted function | Changed to `extern` with warning comment | `comptime_error` stub (doesn't preserve extern signature) |
| Location info | `// file:line:col` comments | `// file:line:col` for opaque demotions |
| Warning comments | `// ... warning: reason` for all demotions | Only for opaque demotions |

**Real gap — graceful demotion:** When Zig can't translate a function body, it keeps the function as `extern` — still callable, just without the inline body. We emit a `comptime_error` stub that makes the function uncallable. This is the single most impactful error handling difference.

---

## 9. Summary: What Matters

### Differences that affect real-world usage (HIGH impact)

1. **Graceful function demotion** — Zig demotes untranslatable bodies to extern. We emit comptime_error stubs. Fix: change fallback from stub to extern declaration.

2. **Wrapping arithmetic** — Zig emits `+%`/`-%`/`*%` for unsigned. We use plain operators. Could cause overflow UB.

3. **Pointer default values** — Zig zeros pointers to null in struct defaults. We don't emit defaults for pointer fields. Fix: add `= null` for pointer types in `ci_default_for_type`.

4. **Macro comma operator** — Zig preserves all side effects in a block. We only keep the last expression. Could lose side effects.

### Differences that affect edge cases (MEDIUM impact)

5. **Switch fallthrough** — Our if/else chain doesn't support fallthrough.
6. **Per-field alignment vs packed+padding** — Different struct layout approach.
7. **Platform-specific integer types** — `i32` vs `c_int` for cross-compilation.
8. **String-based macro parser** — Fragile for complex expressions.
9. **Signed division/remainder** — May differ from C semantics.

### Differences that are architectural (LOW impact on correctness)

10. **aro vs libclang** — Same information, different API.
11. **AST output vs string output** — String is simpler, less amenable to partial recovery.
12. **Scope system** — Missing for function body translation of complex functions.
13. **`[*c]T` pointer type** — Language design decision.
14. **Member function registration** — Zig-specific feature.
