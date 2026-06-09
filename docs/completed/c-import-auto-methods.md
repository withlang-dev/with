# c_import Auto-Method Generation — Spec & Implementation Notes

## Overview

When `c_import` translates a C header, it already knows every struct
and every function signature. Most well-designed C libraries follow
a naming convention: `structname_method(self, ...)`. The compiler
detects this pattern and auto-generates method syntax so C APIs
feel like native With APIs.

This is sugar. `table.insert("key", "val")` compiles to exactly
`g_hash_table_insert(table, "key", "val")`. Zero runtime cost.
Zero wrapper layer. The flat C functions remain callable — the
method syntax is additive.

## Before / After

**Before (raw c_import):**
```
let table = g_hash_table_new(g_str_hash, g_str_equal)
g_hash_table_insert(table, "name", "Eric")
let val: str = g_hash_table_lookup(table, "name")
g_hash_table_destroy(table)
```

**After (auto-method generation):**
```
let table = GHashTable()
table.insert("name", "Eric")
let val: str = table.lookup("name")
table.destroy()
```

Both the flat C functions and the manual `.destroy()` still work.
Automatic cleanup is generated only by a proven owning wrapper with
`Drop`, not by method-name detection alone.

## Spec

### Detection Rules

Given a struct `S` imported via `c_import`, and a set of functions
also imported from the same header:

**Step 1: Compute candidate prefixes.**

Convert the struct name to snake_case, then check if any functions
begin with that prefix followed by `_`.

```
GHashTable  → g_hash_table_
sqlite3     → sqlite3_
MTLDevice   → mtl_device_    (but also try lowercase: mtldevice_)
SDL_Window  → sdl_window_
RenderTexture2D → render_texture2d_  (but also try: render_texture_2d_)
```

The prefix computation handles:
- CamelCase → snake_case (GHashTable → g_hash_table)
- Abbreviation runs (GList → g_list, not g_l_i_s_t)
- Trailing numbers preserved (Texture2D → texture2d)
- Leading underscores stripped
- If the struct name is already snake_case, use it directly

**Step 2: Match functions to the struct.**

A function `f` is a method candidate for struct `S` if:
1. `f`'s name starts with the computed prefix
2. `f`'s first parameter type is `*S`, `*mut S`, `*const S`,
   or `S` (by value)

A function `f` is a static method (constructor) candidate if:
1. `f`'s name starts with the computed prefix
2. `f`'s return type is `*S`, `*mut S`, or `S` (by value)
3. `f` does NOT take `*S` / `*mut S` as its first parameter

**Step 3: Generate method names.**

Strip the prefix from the function name. The remainder becomes
the method name.

```
g_hash_table_new       → GHashTable.new(...)
g_hash_table_insert    → .insert(...)
g_hash_table_lookup    → .lookup(...)
g_hash_table_size      → .size()
g_hash_table_destroy   → .destroy()
g_hash_table_ref       → .ref()
g_hash_table_unref     → .unref()
```

If the stripped name collides with an existing method on the type
(from an `impl` block in user code), the user's method wins. The
auto-generated method is silently suppressed.

If the stripped name is empty (function name IS the prefix), skip
it — don't generate a method with an empty name.

### Self Parameter Rules

The first parameter determines mutability:

| First param type | Method receiver | Example |
|-----------------|----------------|---------|
| `*mut S` | `self: *mut S` (mutable method) | `table.insert(...)` |
| `*const S` | `self: *const S` (immutable method) | `table.size()` |
| `*S` (ambiguous C pointer) | `self: *mut S` (default to mutable) | |
| `S` (by value, consuming) | `self: S` | rare in C |

### Constructor Rules

Functions that return `*S` / `*mut S` without taking self:

```
// C: GHashTable* g_hash_table_new(GHashFunc, GEqualFunc)
// With: GHashTable.new(hash_fn, equal_fn) → *mut GHashTable

// C: sqlite3* sqlite3_open(const char* filename)  
// With: sqlite3.open("test.db") → *mut sqlite3
```

The constructor name is the stripped suffix: `g_hash_table_new` → `.new`,
`g_hash_table_new_full` → `.new_full`.

**Callable type syntax:** If a type has a `.new` method (auto-generated
or user-written), the type name itself becomes callable as sugar:

```
let table = GHashTable(g_str_hash, g_str_equal)
// equivalent to:
let table = GHashTable.new(g_str_hash, g_str_equal)
```

This applies to all types, not just c_import types.

### Constructor Default Parameters

When a constructor takes function pointer parameters, and the
c_import header exports exactly one function matching that pointer
type, that function is used as the default value.

```
// c_import sees:
//   GHashFunc  = fn(*const c_void) -> c_uint
//   GEqualFunc = fn(*const c_void, *const c_void) -> i32
//   g_str_hash: GHashFunc     ← only export matching this type
//   g_str_equal: GEqualFunc   ← only export matching this type
//
// Auto-generates constructor with defaults:
//   fn new(hash_func: GHashFunc = g_str_hash,
//          key_equal_func: GEqualFunc = g_str_equal) -> *mut GHashTable

let table = GHashTable()                  // uses defaults
let table = GHashTable(my_hash, my_eq)    // explicit overrides
```

**Ambiguity rule:** If the header exports multiple functions matching
a parameter's type (e.g., `g_str_hash`, `g_int_hash`, and
`g_direct_hash` all have type `GHashFunc`), no default is inferred
for that parameter. The user must pass it explicitly. This is
conservative — the compiler only provides defaults when the choice
is unambiguous.

**Non-function-pointer parameters** never get auto-defaults.
Only function pointer types are candidates, because they represent
strategy/policy choices where the header often exports a single
standard implementation.

### Destructor Candidates and Ownership Wrappers

Name patterns such as `prefix_destroy`, `prefix_free`, `prefix_close`,
`prefix_unref`, and `prefix_release` are only hints. They may appear in
import manifests or diagnostics as likely cleanup candidates, but they
do not prove ownership and must not cause generated cleanup by
themselves.

Automatic cleanup is valid only when `c_import` has real ownership
evidence: explicit annotations, imported metadata, conservative source
analysis, curated library-specific conventions, or a handwritten owning
wrapper. When that evidence exists, cleanup is expressed as an owning
With wrapper whose `Drop` calls the correct C destructor.

The old scope-local auto-defer rule has been removed. The compiler no
longer inserts `defer obj.destroy()` from names alone, because that
does not compose with moves, returns, storage in structs, or reference
counting. Raw C handles remain raw until wrapped by a proven ownership
model.

### Ambiguity Resolution

If multiple structs could claim the same function (e.g., a function
named `list_node_free` where both `List` and `ListNode` exist),
the **longer prefix wins**. `ListNode` matches `list_node_` which
is longer than `List` matching `list_`.

If two prefixes have equal length, neither claims the function.
It remains a free function.

### Opt-Out

If the auto-generated methods conflict with user intent, the user
can suppress them per-type:

```
use c_import("<glib.h>", no_methods: "GHashTable")
```

Or globally:

```
use c_import("<glib.h>", no_methods: true)
```

The flat C functions are always available regardless of this setting.

## Implementation Notes

### Where It Lives

The auto-method generation happens in `src/CImport.w`, after all
functions and structs have been collected and translated. It is a
post-processing pass over the already-translated declarations —
it does not change how functions or structs are parsed or
type-checked.

### Data Flow

```
1. c_import translates all structs → list of (name, type_info)
2. c_import translates all functions → list of (name, params, return_type)
3. NEW: auto_method_pass runs:
   a. For each struct, compute candidate prefix
   b. For each function, check if it matches any struct's prefix
   c. Group matches: { struct_name → [(method_name, fn_name, is_constructor)] }
   d. Emit synthetic impl blocks as With source text
4. Synthetic impl blocks are appended to the c_import output
5. Sema/codegen sees them as normal impl blocks
```

### Output Format

The auto-method pass emits With source text that gets parsed
alongside the other c_import output. For GHashTable:

```
impl GHashTable:
    fn new(hash_func: GHashFunc = g_str_hash,
           key_equal_func: GEqualFunc = g_str_equal) -> *mut GHashTable:
        g_hash_table_new(hash_func, key_equal_func)

    fn insert(self: *mut GHashTable, key: str, value: str):
        g_hash_table_insert(self, key, value)

    fn lookup(self: *mut GHashTable, key: str) -> *mut c_void:
        g_hash_table_lookup(self, key)

    fn size(self: *mut GHashTable) -> c_uint:
        g_hash_table_size(self)

    fn destroy(self: *mut GHashTable):
        g_hash_table_destroy(self)
```

Destructor-looking wrappers remain ordinary raw methods unless
ownership metadata proves an owning wrapper. Name matching alone does
not emit cleanup metadata.

This is regular With code. Sema type-checks it normally. Codegen
inlines the wrapper bodies (trivial single-call forwards). LLVM
eliminates them entirely. Zero overhead.

### Prefix Computation Algorithm

```
fn compute_c_prefix(struct_name: str) -> str:
    var result = ""
    var prev_was_upper = false
    var prev_was_lower = false
    for i in 0..struct_name.len():
        let ch = struct_name[i]
        if is_upper(ch):
            if prev_was_lower:
                result = result ++ "_"
            // Don't insert _ between consecutive capitals
            // (handles "GHash" → "g_hash" not "g_h_a_s_h")
            else if prev_was_upper and i + 1 < struct_name.len() and is_lower(struct_name[i+1]):
                result = result ++ "_"
            result = result ++ to_lower(ch)
            prev_was_upper = true
            prev_was_lower = false
        else if is_digit(ch):
            result = result ++ ch
            prev_was_upper = false
            prev_was_lower = false
        else:
            // Underscore or lowercase
            result = result ++ ch
            prev_was_upper = false
            prev_was_lower = is_lower(ch)
    result ++ "_"
```

Test cases:
```
GHashTable     → "g_hash_table_"
GList          → "g_list_"
sqlite3        → "sqlite3_"
SDL_Window     → "sdl_window_"    (underscore preserved)
MTLDevice      → "mtl_device_"
RenderTexture2D → "render_texture2_d_"  // may need special handling
Vec3           → "vec3_"
HTTPServer     → "http_server_"   (abbreviation run)
```

Edge case: if the computed prefix doesn't match any functions,
no methods are generated. No error, no warning. The heuristic
simply didn't match this library's naming convention.

### Handling Opaque Types

Many C structs imported as `type S = opaque` (forward-declared,
no fields visible). Auto-methods work identically for opaque
types — the methods take `*mut S` and call the flat functions.
This is the most common case for C API types (FILE, sqlite3,
GHashTable internals, etc.).

### Avoiding Duplicate Methods

If the same function matches multiple structs (rare but possible
with short prefixes), only the longest-prefix match generates
a method. Track which functions have been claimed.

If a struct already has a manually-written `impl` block (from user
code, not c_import), those method names take priority. The
auto-method pass checks for collisions before emitting.

### Caching

Auto-method output is part of the c_import cache. The cache key
already includes the header content hash. No additional cache
invalidation needed — if the header changes, the cache misses
and methods are regenerated.

### What NOT To Do

- Do not generate methods for functions that don't take the struct
  as first parameter (except constructors). A function like
  `g_hash_table_iter_init(iter, table)` where `table` is the
  SECOND parameter is NOT a method on GHashTable.

- Do not rename methods beyond stripping the prefix. The C name
  `g_hash_table_get_keys` becomes `.get_keys()`, not `.keys()`.
  Renaming is lossy and makes it harder to find the C docs.

- Do not generate methods for function-pointer typedefs or
  callback registration functions. Only concrete functions.

- Do not attempt to generate overloads. If the C API has
  `g_hash_table_insert` and `g_hash_table_insert_full`, they
  become `.insert()` and `.insert_full()`. No magic.

- Do not special-case any library. The same algorithm runs on
  glib, SDL, SQLite, OpenSSL, raylib, POSIX, and everything
  else. If a library doesn't follow naming conventions, the
  user gets flat functions (which still work fine).

- Do not infer ownership from names. Name patterns may suggest likely
  destructor candidates in metadata or diagnostics, but automatic
  cleanup requires proven ownership and must be represented by a
  `Drop`-owning wrapper.

### Implementation Order

1. Prefix computation function (~30 lines)
2. Function-to-struct matching loop (~40 lines)
3. Constructor vs method classification (~20 lines)
4. Destructor candidate recording for manifests/diagnostics (~15 lines)
5. Constructor default parameter inference (~30 lines)
6. Callable type syntax (TypeName(...) → TypeName.new(...)) (~15 lines in Parser.w)
7. With source text emission for matched methods (~60 lines)
8. Proven ownership metadata and generated `Drop` wrapper support
9. Integration into c_import output pipeline (~10 lines)
10. Cache compatibility verification (~0 lines, already works)

Total: ~290 lines across CImport.w, Parser.w, and Sema.w.

### Test Cases

```c
// test_auto_methods.h

typedef struct MyVec { float x, y, z; } MyVec;
MyVec my_vec_new(float x, float y, float z);
float my_vec_length(const MyVec* v);
MyVec my_vec_add(const MyVec* a, const MyVec* b);
void my_vec_scale(MyVec* v, float s);
void my_vec_free(MyVec* v);

// Should NOT become a method (second param is MyVec, not first):
void unrelated_fn(int x, const MyVec* v);
```

```
use c_import("test_auto_methods.h")

fn main:
    let v = MyVec(1.0, 2.0, 3.0)    // MyVec.new method wrapper
    let len = v.length()
    // Raw handle cleanup remains explicit until an owning Drop wrapper exists.

    var v2 = my_vec_new(4.0, 5.0, 6.0)
    my_vec_scale(&mut v2, 0.5)
    my_vec_free(&mut v2)                 // user manages manually
```

### Real-World Library Examples

**glib:**
```
let table = GHashTable()             // g_hash_table_new method wrapper
table.insert("k", "v")              // g_hash_table_insert
let v: str = table.lookup("k")      // g_hash_table_lookup
table.destroy()                      // explicit raw-handle cleanup
```

**SQLite:**
```
let db = sqlite3.open(":memory:")        // sqlite3_open method wrapper
db.exec("CREATE TABLE ...")              // sqlite3_exec
db.close()                               // explicit raw-handle cleanup
```

**SDL2:**
```
let win = SDL_Window.create("Game", 0, 0, 800, 600, flags)
// Note: SDL uses SDL_DestroyWindow not SDL_Window_destroy
// The prefix detection handles this: SDL_Window → sdl_window_
// SDL_DestroyWindow doesn't match the prefix pattern.
// No auto-method. User calls it directly:
defer SDL_DestroyWindow(win)
```

SDL is an example where the naming convention doesn't perfectly
match. The auto-method pass generates what it can and leaves the
rest as flat functions. No ownership wrapper is generated without
ownership evidence, so the user writes explicit cleanup or uses a
handwritten owning wrapper.

**raylib:**
```
// raylib uses flat functions without struct prefixes:
// InitWindow(), BeginDrawing(), DrawCircle(), etc.
// No auto-methods generated. That's correct — raylib's API
// is already ergonomic as flat function calls.
```

This is the right behavior: the heuristic does nothing when
there's nothing to do.
