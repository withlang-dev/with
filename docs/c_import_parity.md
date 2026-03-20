# c_import: Match Zig — Complete

**Previous plans are dead. This is the only plan.**

Zig's translate-c is ~10K lines across 8 files and translates the
full C language: every declaration, every statement, every expression,
every type, every macro. We will match it. If Zig translates it,
we translate it.

**Method:** Port Zig's architecture to With's codebase. Zig used
libclang before switching to aro — the same API we already use.
Their translate_c.zig is a direct reference implementation for what
we need to build on top of libclang.

---

## Progress Tracker

### Currently Implemented (declaration-only mode)
- [x] Basic clang_bridge.c with libclang FFI
- [x] Type translation via `translate_type_recursive` (primitives, pointers, arrays, records, enums, functions)
- [x] Function declarations (extern, variadic, calling convention, static inline stubs)
- [x] Struct/union declarations (fields, padding, packed, anonymous sub-records, opaque demotion)
- [x] Enum declarations (named, integer type, constants)
- [x] Typedef declarations (builtin map, self-referential detection)
- [x] Variable declarations (extern let/var)
- [x] Macro translation via `cc -E -dM` (integers, floats, strings, chars, expressions)
- [x] Name deduplication (two-pass prepopulate, typedef shadowing, collision mangling)
- [x] Opaque demotion cascade (bitfields, forward decls, unsupported fields)
- [x] c_void / Complex32 / Complex64 helper types
- [x] Reserved word escaping
- [x] `*volatile T` pointer type (parser + sema, no codegen effect yet)
- [x] Token pasting `##` suffix patterns (U, UL, ULL, L, LL, F)
- [x] Forward-declared enums → opaque
- [x] `_Atomic` type → demote to opaque
- [x] Empty struct → padding byte
- [x] Default struct field values (primitives)
- [x] Variadic macro diagnostic
- [x] Cleanup attribute diagnostic
- [x] struct_Foo = Foo alias for typedef twins
- [x] sizeof(param) in macros → sizeof[T]()
- [x] Comma operator in macros → last expression
- [x] 32+ builtin function mappings
- [x] 13 system headers pass (stdio, stdlib, string, unistd, math, errno, signal, sys/types, sys/stat, fcntl, time, limits, stddef)

---

## The Architectural Change

### Current (declaration-only)

```
clang_bridge.c:  Metadata queries only
                 (name, type string, field count, ...)
                 CXTranslationUnit_SkipFunctionBodies ← THIS IS THE PROBLEM

CImport.w:       String pattern matching on metadata
                 Can't see function bodies
                 Can't see expressions
                 Can't see statements
```

### Target (matches Zig)

```
clang_bridge.c:  Full AST traversal primitives
                 Every cursor kind accessible
                 Every operator kind queryable
                 Source text extraction
                 Constant evaluation
                 NO SkipFunctionBodies

CImport.w:       Recursive AST walker
                 ci_trans_top_level_decl()  → dispatches on cursor kind
                 ci_trans_stmt()            → all C statements
                 ci_trans_expr()            → all C expressions
                 ci_trans_type()            → all C types
                 Scope hierarchy            → local variable tracking
                 Name table                 → two-pass prepopulation
                 MacroTranslator            → proper tokenizer + parser
                 PatternList                → all 34 ## patterns
```

---

## Phase 1: AST Bridge Layer (2 sessions)

Expose libclang's full AST to With. This is the foundation everything
else builds on. Without this, nothing else works.

### Session 1: Core AST traversal + cursor introspection

- [x] Cursor handle storage (session-local array, index-based)
- [x] `with_ci_root_cursor` — translation unit root
- [x] `with_ci_num_children` / `with_ci_child` — tree traversal
- [x] `with_ci_cursor_kind` / `with_ci_cursor_spelling` — introspection
- [x] Type handle queries (`with_ci_cursor_type`, `with_ci_type_kind`, etc.)
- [x] Type qualifiers (`is_const`, `is_volatile`, `pointee`, `canonical`)
- [x] Function type queries (`result`, `arg_count`, `arg`, `is_variadic`)
- [x] Array type queries (`array_size`, `array_element`)
- [x] Linkage / storage class / inline queries
- [x] Source location strings (`with_ci_cursor_location`)
- [x] Source text extraction (`with_ci_cursor_source_text`)
- [x] Struct/union/enum specifics (anonymous, bitfield, offset, definition check)
- [x] Target info (pointer width, target triple, sizeof(long), char signedness)
- [ ] Remove `CXTranslationUnit_SkipFunctionBodies` from parse flags

**clang_bridge.c — ~400 new lines**

### Session 2: Operator introspection + constant evaluation

- [x] Binary operator kind extraction (`with_ci_binary_op`)
- [x] Unary operator kind extraction (`with_ci_unary_op`)
- [ ] Cast kind extraction (`with_ci_cast_kind`)
- [x] Constant evaluation (`with_ci_eval_as_int`, `_float`, `_str`)
- [x] Calling convention query (`with_ci_calling_conv`)
- [x] Typedef underlying type (`with_ci_typedef_underlying`)
- [x] Member expression queries (`is_arrow`, `field_name`)

**clang_bridge.c — ~400 new lines**

---

## Phase 2: Name Resolution + Scope System (1 session)

### Session 3: Two-pass name table + scope hierarchy

- [ ] Strong name table (functions, variables, typedefs)
- [ ] Weak name table (structs, unions, enums — can be mangled)
- [ ] Weak name mangling (`struct_Foo` when typedef `Foo` exists)
- [ ] Scope stack (push/pop for function bodies)
- [ ] Local name registration with parent-scope collision detection
- [ ] Name resolution (locals → strong → weak → mangle)

**CImport.w — ~200 new lines**

---

## Phase 3: Type Translator (1 session)

### Session 4: Complete type translation

- [ ] Replace string-based type mapping with AST-walking `ci_trans_type`
- [ ] All integer types (platform-aware via target info)
- [ ] All float types (including f16, f128, long double)
- [ ] Pointer types (const, volatile, function pointers, void*)
- [ ] Array types (fixed, incomplete, flexible array members)
- [ ] Function prototype types
- [ ] Record types (trigger struct translation on demand)
- [ ] Enum types (trigger enum translation on demand)
- [ ] Typedef types (builtin map + recursive resolution)
- [ ] Elaborated types (unwrap to named type)
- [ ] Atomic types (demote to opaque)
- [ ] Vector types
- [ ] Complex types

**CImport.w — ~300 lines replacing ~200 existing**

---

## Phase 4: Expression Translator (2 sessions)

### Session 5: Literal + binary + unary + cast expressions

- [ ] Integer literals (with constant evaluation)
- [ ] Float literals
- [ ] String literals
- [ ] Character literals
- [ ] Binary operators (all arithmetic, bitwise, logical, comparison, assignment)
- [ ] Unary operators (negate, not, bitwise not, address-of, deref, pre/post inc/dec)
- [ ] Conditional (ternary) operator
- [ ] C-style cast expressions
- [ ] Implicit cast expressions (unwrap)
- [ ] Parenthesized expressions
- [ ] Declaration reference expressions (identifier resolution)
- [ ] Compound assignment operators

**CImport.w — ~300 new lines**

### Session 6: Member access, subscript, call, sizeof, compound literals

- [ ] Member access (`.field` and `->field`)
- [ ] Array subscript (`a[i]`)
- [ ] Function call expressions (with builtin remapping)
- [ ] sizeof / alignof expressions
- [ ] Initializer list expressions (struct/array init)
- [ ] Compound literal expressions
- [ ] Statement expressions (GNU extension `({...})`)
- [ ] Predefined expressions (`__func__`)
- [ ] Generic selection expressions (`_Generic`)
- [ ] Offsetof expressions
- [ ] VA_ARG expressions
- [ ] All ~50 builtin function remappings

**CImport.w — ~300 new lines**

---

## Phase 5: Statement Translator (2 sessions)

### Session 7: Compound, return, if, while, for, do-while

- [ ] Compound statements (block scope push/pop)
- [ ] Return statements (with/without value)
- [ ] If statements (with/without else)
- [ ] While statements
- [ ] Do-while statements (→ `while true` + break)
- [ ] For statements (→ init + while + increment)
- [ ] Declaration statements (local variable decls with initializers)
- [ ] Null statements (→ `pass`)
- [ ] Break / continue statements

**CImport.w — ~250 new lines**

### Session 8: Switch, goto/label, local var decls

- [ ] Switch statements (→ match or if/else chain for fallthrough)
- [ ] Case statements
- [ ] Default statements
- [ ] Goto statements (→ `comptime_error` unless With adds goto)
- [ ] Label statements (→ comment)
- [ ] Local variable declarations with type and initializer

**CImport.w — ~250 new lines**

---

## Phase 6: Declaration Translator Rewrite (2 sessions)

### Session 9: Functions, variables, typedefs

- [ ] Function declarations with full body translation
- [ ] Static inline → translated inline function (not comptime_error stub)
- [ ] Always-inline functions
- [ ] Variable declarations with initializer expression translation
- [ ] Constant evaluation for variable initializers
- [ ] Source location comments (`// file:line:col`)

**CImport.w — ~300 lines replacing existing**

### Session 10: Structs, unions, enums (with full fidelity)

- [ ] Per-field alignment annotations (matching Zig's `alignmentForField`)
- [ ] Flexible array member accessor functions
- [ ] Anonymous enum constant translation (don't skip unnamed enums)
- [ ] Anonymous struct typedef handling (`typedef struct { ... } Name;`)
- [ ] Member function registration
- [ ] MSVC empty struct handling (alignment-aware padding)
- [ ] Opaque demotion with warning comments

**CImport.w — ~300 lines replacing existing**

---

## Phase 7: Macro Translator (2 sessions)

### Session 11: C macro tokenizer + PatternList

- [ ] Proper C token scanner (all literal formats, all operators)
- [ ] All 34 PatternList patterns from Zig:
  - [ ] Suffix patterns: `##U`, `##UL`, `##ULL`, `##L`, `##LL`, `##F` (with/without parens, all case variants)
  - [ ] `CAST_OR_CALL(X, Y)` — `(X)(Y)` cast-or-call disambiguation
  - [ ] `DISCARD(X)` — `(void)(X)` with const/volatile variants
  - [ ] `WL_CONTAINER_OF(ptr, sample, member)`

**CImport.w — ~350 new lines**

### Session 12: Recursive descent macro expression parser

- [ ] 13 C operator precedence levels
- [ ] All binary operators with correct associativity
- [ ] All unary prefix operators (-, !, ~, &, *, sizeof, ++, --)
- [ ] All postfix operators (.field, ->field, [i], (args), ++, --)
- [ ] Ternary conditional
- [ ] Cast expressions with type resolution
- [ ] Comma operator (→ block with discards)
- [ ] Known identifier resolution (params, previous macros, global names)
- [ ] Blank macro detection and propagation
- [ ] Variable reference detection (auto-convert to inline fn)
- [ ] Function pointer alias detection

**CImport.w — ~500 new lines**

---

## Phase 8: Integration + @[section] + Volatile Codegen (1 session)

### Session 13: Wire everything together

- [ ] Replace old CImport.w main loop with AST-walking translator
- [ ] `@[section("name")]` — Parser attribute + `LLVMSetSection` in Codegen
- [ ] Volatile codegen — `LLVMSetVolatile` on loads/stores through `*volatile T`
- [ ] Calling convention — `LLVMSetFunctionCallConv`
- [ ] Remove `CXTranslationUnit_SkipFunctionBodies` from parse flags
- [ ] Fixpoint verification

**CImport.w (integration), Parser.w (~30 lines), Codegen.w (~30 lines), llvm_bridge.c (~10 lines)**

---

## Phase 9: Verification (1 session)

### Session 14: Full test suite + Zig comparison

- [ ] 20-header test suite (stdio, stdlib, string, math, unistd, fcntl, sys/stat, errno, signal, pthread, dirent, sys/socket, netinet/in, arpa/inet, stdint, stdbool, float, limits, time, sys/mman)
- [ ] Functional tests: call at least one function from each header
- [ ] Zig comparison: compare output with `zig translate-c` for each header
- [ ] Static inline coverage: >90% translated (not stubbed)
- [ ] Fixpoint: stage 2 == stage 3

---

## Summary

| Session | Phase | Content | Lines | Status |
|---------|-------|---------|-------|--------|
| 1 | 1 | AST bridge: cursor traversal, type queries, linkage | ~400 clang_bridge.c | ✓ |
| 2 | 1 | AST bridge: operator kinds, eval, calling conv | ~400 clang_bridge.c | ✓ |
| 3 | 2 | Name resolution: two-pass, scope hierarchy | ~200 CImport.w | ☐ |
| 4 | 3 | Type translator: all CXTypeKind | ~300 CImport.w | ☐ |
| 5 | 4 | Expr translator part 1: literals, binary, unary, cast | ~300 CImport.w | ☐ |
| 6 | 4 | Expr translator part 2: member, subscript, call, sizeof, init | ~300 CImport.w | ☐ |
| 7 | 5 | Stmt translator part 1: compound, return, if, while, for | ~250 CImport.w | ☐ |
| 8 | 5 | Stmt translator part 2: switch, goto, local decls | ~250 CImport.w | ☐ |
| 9 | 6 | Decl translator: functions with bodies, variables with init | ~300 CImport.w | ☐ |
| 10 | 6 | Decl translator: structs (align, FAM, member fns), enums (anon) | ~300 CImport.w | ☐ |
| 11 | 7 | Macro tokenizer + PatternList (all 34 patterns) | ~350 CImport.w | ☐ |
| 12 | 7 | Macro recursive descent parser (13 precedence levels) | ~500 CImport.w | ☐ |
| 13 | 8 | Integration, @[section], volatile codegen, callconv | ~100 across files | ☐ |
| 14 | 9 | 20-header verification, Zig comparison, fixpoint | tests only | ☐ |

**Total: 14 sessions.**
**New code: ~800 lines clang_bridge.c + ~3500 lines CImport.w = ~4300 lines.**
**Replacing: ~1250 lines clang_bridge.c + ~2100 lines CImport.w = ~3350 lines.**
**Net growth: ~950 lines.** (The new code is denser because it does more per line.)

### What this achieves

Everything Zig translates, we translate:
- Full function body translation (while, for, switch, if, goto, return)
- Full expression translation (all 40+ cursor kinds)
- Full type translation (all qualifiers, all type kinds)
- Full macro translation (proper tokenizer, 13 precedence levels, 34 patterns)
- Full name resolution (two-pass, scope hierarchy)
- Full diagnostics (source locations, warning comments)
- All 50 builtins
- Anonymous enums, anonymous struct typedefs
- Variable initializers
- Calling conventions
- Volatile codegen
- @[section] attribute
- Flexible array member accessors
- Member function registration

### What remains different from Zig

1. **We use libclang. Zig uses aro.** Same information, different API.
   libclang is stable and well-tested. No disadvantage.

2. **We output With source strings. Zig builds a Zig AST.** String
   output is simpler to implement and debug. No disadvantage for
   correctness. Slight disadvantage for error recovery (we can't
   partially succeed on a single declaration as easily).

3. **No `[*c]T` pointer type.** We use `*mut T` + `Option[]`.
   This is a With language design decision, not a c_import gap.

4. **goto → comptime_error** unless With adds goto support. This
   affects <1% of static inline functions in real headers. Zig
   translates goto to labeled blocks with break.

---

## Exit Gate

**Every phase is gated. No phase is complete until all of these pass.**

For each phase:

1. **Read Zig's implementation** of the corresponding feature in
   `.reference/zig/lib/compiler/translate-c/`. Understand every
   edge case they handle. Do not rely on the checklist — inspect
   the actual Zig code.

2. **Inspect our implementation** and verify 100% parity by reading
   both codebases side-by-side. If Zig handles a case we don't,
   it's not done.

3. **Port Zig's translate-c tests** for the feature to With.
   Zig's tests live in `.reference/zig/test/translate_c.zig` and
   `.reference/zig/test/run_translated_c.zig`. Every test case
   that exercises the implemented feature must have a With equivalent.

4. **Run all tests. All pass.** No "skip for now", no "works on my
   machine", no "only fails on edge case X". Green or not done.

5. **No shortcuts, deferrals, or blockages.** If a test reveals a
   bug, fix it before moving on. If a feature is harder than
   expected, spend the time. If a dependency is missing, build it.
   The phase is not complete until every test passes.
