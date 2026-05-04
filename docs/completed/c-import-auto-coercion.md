# c_import Auto-Coercion at ABI Boundaries — Spec

## Problem

C APIs use `void*` everywhere. glib, CoreFoundation, Win32,
POSIX — every major C library passes data through opaque
pointers. Today in With, calling these APIs requires explicit
casts:

```
// What you have to write today:
g_hash_table_insert(table, "name" as *mut c_void, "Eric" as *mut c_void)
let val = g_hash_table_lookup(table, "name" as *mut c_void) as *const u8
```

This defeats With's "C interop should feel native" promise.

## Solution

The compiler auto-coerces at `c_import` function call boundaries
when the conversion is unambiguous. The user writes normal With
types. The compiler inserts the ABI translation.

```
// What you write:
table.insert("name", "Eric")
let val: str = table.lookup("name")
```

## Coercion Rules

### Parameters (With → C)

When calling a function imported via `c_import`, if an argument
type doesn't match the parameter type, the compiler attempts
auto-coercion:

| Argument type | Parameter type | Coercion |
|---------------|---------------|----------|
| `str` | `*mut c_void` | pointer to string data |
| `str` | `*const c_void` | pointer to string data |
| `str` | `*const u8` | pointer to string data |
| `str` | `*const c_char` | pointer to string data (null-terminated) |
| `str` | `*mut c_char` | pointer to copy (caller must free — warn) |
| `i32` | `c_int` | identity (same repr) |
| `bool` | `c_int` | 1 or 0 |
| `*mut T` | `*mut c_void` | pointer cast |
| `*const T` | `*const c_void` | pointer cast |

These coercions ONLY apply at `c_import` function call sites.
They do not apply to user-defined functions, assignments, or
any other context. This prevents accidental implicit conversions
in pure With code while making C calls seamless.

### Returns (C → With)

When the return type of a `c_import` function is `*mut c_void`
or `*const c_void`, the compiler coerces based on the receiving
context:

| Return type | Receiving context | Coercion |
|-------------|-------------------|----------|
| `*mut c_void` | `let x: str = ...` | null-check + strlen → str view |
| `*mut c_void` | `let x: *mut T = ...` | pointer cast |
| `*const c_void` | `let x: str = ...` | null-check + strlen → str view |
| `*const c_void` | `let x: *mut T = ...` | pointer cast |
| `*mut c_void` | no annotation | stays `*mut c_void` (no inference) |

The `str` coercion inserts a runtime null check. If the pointer
is null, the result is an empty string `""` (not a crash). This
matches the behavior of `ptr.as_option().unwrap_or("")`.

Without a type annotation, no coercion happens — the value stays
`*mut c_void`. The compiler never guesses.

### Null Safety

`*mut c_void` → `str` coercion always null-checks:

```
// Generated shim for: let name: str = table.lookup("name")
let __raw = g_hash_table_lookup(table, "name" as *mut c_void)
let name: str = if __raw != null: str_from_cstr(__raw as *const u8) else: ""
```

The user can opt into explicit null handling instead:

```
let name: Option[str] = table.lookup("name")
// None if null, Some(str) if non-null
```

### What Does NOT Auto-Coerce

- `str` → `*mut i32` (not a void pointer — no coercion)
- `i32` → `*mut c_void` (integer to pointer — never implicit)
- `f64` → `c_int` (lossy — never implicit)
- `Vec[T]` → `*mut c_void` (complex type — never implicit)
- `str` → `*mut c_void` in non-c_import functions (user code
  doesn't get auto-coercion — only c_import boundaries)

The rule: **coercions are only between types where the conversion
is unambiguous and lossless at the representation level.**

## Interaction with Auto-Methods

Auto-methods inherit the coercion rules of the underlying C
function. When `table.insert("name", "Eric")` is called:

1. Sema resolves `.insert` to the auto-generated method
2. The method body calls `g_hash_table_insert(self, key, value)`
3. The method signature has `key: *mut c_void, value: *mut c_void`
4. Auto-coercion applies: `"name"` → `*mut c_void`, `"Eric"` → `*mut c_void`

The coercion fires on the auto-generated method's parameters
because the method is marked as originating from `c_import`.

## Implementation

### Sema Changes (~60 lines)

In `check_call`, after normal argument type checking fails for a
c_import-origin function, attempt auto-coercion:

```
fn try_c_import_coercion(self: Sema, arg_type: i32, param_type: i32) -> i32:
    // str → *mut c_void / *const c_void
    if arg_type == self.ty_str and self.is_void_ptr(param_type):
        return param_type  // coercion succeeds
    // str → *const u8 / *const c_char
    if arg_type == self.ty_str and self.is_byte_ptr(param_type):
        return param_type
    // *mut T → *mut c_void
    if self.is_ptr(arg_type) and self.is_void_ptr(param_type):
        return param_type
    // bool → c_int
    if arg_type == self.ty_bool and self.is_c_int(param_type):
        return param_type
    0  // no coercion
```

Mark the coercion on the AST node so Codegen knows to insert
the conversion.

### Codegen Changes (~40 lines)

When emitting a call to a c_import function with a coerced
argument:

- `str` → `*mut c_void`: emit pointer to string data (GEP to
  the data field of the str struct)
- `str` → `*const c_char`: emit pointer + ensure null termination
- `*mut T` → `*mut c_void`: emit bitcast (no-op on LLVM)
- `bool` → `c_int`: emit zext i1 to i32

For return coercions:
- `*mut c_void` → `str`: emit null check + strlen + str construction
- `*mut c_void` → `*mut T`: emit bitcast

### What NOT To Change

- Do not change `c_import` translation output. The function
  signatures stay as-is (`*mut c_void` parameters). The coercion
  is in Sema/Codegen, not in CImport.
- Do not apply coercions to non-c_import functions. User-defined
  functions that take `*mut c_void` still require explicit casts.
- Do not coerce in assignment context (only function calls).

## Edge Cases

**Multiple coercion paths:** If both `str → *const c_void` and
`str → *const u8` could apply, prefer the parameter's actual type.
There's no ambiguity — the parameter type is known.

**Null string argument:** Passing `""` (empty string) to a
`*mut c_void` parameter passes a valid non-null pointer to a
zero-length string. To pass null explicitly, write `null`.

**String lifetime:** When `str` is coerced to `*mut c_void` for
a function parameter, the string data must live at least as long
as the function call. For string literals, this is always true
(static lifetime). For local strings, With's borrow checker
ensures the string is live at the call site.
