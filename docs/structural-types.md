# Structural Types and Anonymous Struct Literals

**Status:** Proposal  
**Author:** (pending)  
**Target:** With language specification, post-v6.6

## Summary

This proposal introduces **structural types** to With: anonymous struct types that are identified by the shape of their fields rather than by a declared name. The feature adds:

1. **Anonymous struct literals** — JavaScript-style inline syntax (`{ name: "Alice", age: 30 }`) that produces a statically-typed, zero-cost struct value.
2. **Anonymous struct types in signatures** — functions can accept parameters typed by shape alone, without requiring a declared struct.
3. **Structural type aliases** — the existing `type Foo { ... }` form gains structural semantics, making it distinct from nominal `struct Foo { ... }`.
4. **Width subtyping** — values with more fields can be passed where values with fewer fields are expected.
5. **Auto-derived standard traits** — `Eq`, `Hash`, `Clone`, `ToString`, `Serializable`, `Deserializable` are automatically implemented for anonymous struct types whose fields support them.
6. **Typed JSON interop** — as a direct consequence of auto-derived serialization, `to_json` and `from_json` work on any serializable type, including anonymous structs, with a dynamic `Json` value type as an escape hatch.

The combined effect is JavaScript-like ergonomics for structured data with full static typing, zero runtime cost, and compile-time error checking.

## Motivation

With targets users who want the ergonomics of Python and Kotlin with the performance of C. The most visible ergonomic gap in the current language is the creation of structured data: every struct used anywhere in a program must be declared upfront with a name. This creates friction at every use site where the data is transient, one-off, or simply doesn't warrant a permanent named type.

Consider a common JavaScript pattern:

```javascript
const payload = {
    user: { name: "Alice", age: 30 },
    action: "create",
    metadata: { source: "web", retries: 3 },
};
```

The equivalent in current With requires declaring three struct types before writing any logic. This is the dominant reason users coming from dynamic languages find systems languages uncomfortable, and it is not a necessary consequence of static typing. TypeScript, Crystal, Scala 3, and Dart all offer structural type inference that closes this gap.

Structural types are the mechanism. Anonymous struct literals are the user-facing syntax. JSON interop is the most immediate concrete benefit, because structural types map cleanly to JSON's shape-based model.

### Goals

- Users can write structured data inline with JavaScript-like syntax
- The resulting types participate in the type system as first-class structural types
- Typos and field mismatches are compile errors; no runtime type checking
- The runtime representation is identical to named structs; zero overhead
- Serialization and deserialization to/from JSON are ergonomic for the common case
- A dynamic escape hatch exists for genuinely unknown-shape data

### Non-goals

- Python-style runtime field addition or deletion
- JavaScript-style implicit type coercion
- First-class support for deeply irregular JSON (handled by the escape hatch)
- Preservation of field order in serialization (implementation-defined)
- Bounded structural generics (may be added in a future revision)

## Core Concept: Structural vs Nominal Types

With currently has one mechanism for naming a set of fields: `struct Foo { ... }`. This proposal introduces a distinct mechanism: the structural type. Both mechanisms can be used to describe the same fields, but they differ in identity and intent.

**Nominal types (`struct Foo { ... }`):** Each declaration creates a unique type identity. Two named structs with identical fields are *different* types. Named structs may have `impl` blocks and participate in user-defined trait implementations.

**Structural types (anonymous or via `type Foo { ... }`):** The type is identified by its fields alone. Two structural types with the same fields are the *same* type. Structural types do not accept `impl` blocks and cannot participate in user-defined trait implementations.

The rule for users:

> Use `type Foo { ... }` when you want a convenient name for a shape.  
> Use `struct Foo { ... }` when you want the type system to enforce a boundary.

This distinction matters most at security or domain boundaries:

```with
struct Password:
    hash: str
    salt: str

struct Login:
    hash: str
    salt: str

fn authenticate(p: Password) -> Result[Session, AuthError]:
    // ...

let login = Login { hash: "...", salt: "..." }
authenticate(login)  // error: Login is not Password
```

Nominal distinctness prevents the mistake. Under structural typing, this would compile (both have the same fields). Users choose the mechanism based on whether the type represents *this shape of data* or *this particular concept*.

## Anonymous Struct Literals

### Syntax

An anonymous struct literal is a brace-delimited sequence of `identifier: expression` pairs:

```with
let user = { name: "Alice", age: 30 }
```

Keys are bare identifiers, not string literals. This matches the JavaScript shorthand form and simplifies parsing. For keys that are not valid With identifiers, users must use a `HashMap[str, V]` explicitly.

Nested literals are supported:

```with
let server = {
    host: "localhost",
    port: 8080,
    tls: { enabled: true, cert_path: "/etc/cert.pem" },
}
```

Trailing commas are permitted.

### Types Produced

An anonymous struct literal produces an anonymous structural type determined by its field names and their inferred types:

```with
let a = { x: 1, y: 2 }        // type: { x: i32, y: i32 }
let b = { y: 4, x: 3 }        // same type as a (field order is irrelevant)
let c = { x: 1, z: 2 }        // different type (different field names)
```

Two anonymous struct types are the same type if and only if they have the same set of field names with the same field types, regardless of declaration order.

### Inline Types in Signatures

Anonymous struct types may appear directly in function signatures:

```with
fn greet(u: { name: str }) -> str:
    f"hello {u.name}"

greet({ name: "Alice" })
```

This is the usage pattern that turns "shape" into a first-class type: functions can depend on structure without introducing a shared named type. Any value with at least the specified fields can be passed (see *Structural Subtyping*).

### Structural Type Aliases

The `type Foo { ... }` form names a structural type:

```with
type Point { x: f64, y: f64 }

fn distance(p: Point) -> f64:
    sqrt(p.x * p.x + p.y * p.y)

distance({ x: 3.0, y: 4.0 })  // OK; anonymous literal matches Point structurally
```

The alias is transparent. `Point` and `{ x: f64, y: f64 }` are interchangeable everywhere in the type system. Two `type` declarations with identical fields refer to the same structural type.

**Empty type aliases (`type Foo { }`) are not supported.** A structural type with no fields has no useful content. Users who want a marker with no data should declare a named struct: `struct Foo`.

### Field Access and Mutability

Fields are accessed with dot syntax, identical to named structs:

```with
let user = { name: "Alice", age: 30 }
print(user.name)       // "Alice"
print(user.age + 1)    // 31
print(user.nmae)       // error: no field 'nmae' on { name: str, age: i32 }
```

Mutability follows existing With rules:

```with
var user = { name: "Alice", age: 30 }
user.age = 31                       // OK
user = { name: "Bob", age: 25 }     // OK, same type

let user2 = { name: "Alice", age: 30 }
user2.age = 31                      // error: cannot assign to field of immutable binding
```

### Structural Subtyping

Width subtyping is supported: a struct with additional fields is assignable where fewer fields are expected.

```with
fn print_name(u: { name: str }):
    print(u.name)

print_name({ name: "Alice" })              // OK; exact match
print_name({ name: "Bob", age: 30 })       // OK; extra field ignored
```

Width subtyping applies to anonymous struct types and structural `type` aliases. It does **not** apply to nominal `struct` types — those require exact type match.

Depth subtyping is not supported in the initial specification. A field of type `{ x: i32 }` does not accept a value of type `{ x: i32, y: i32 }`; exact type match is required at nested positions. This avoids variance complexity and may be relaxed in a future revision based on usage.

### Cross-Module Identity

Structural types are interned globally across modules. Two modules that independently produce literals of the same shape receive the same TypeId, enabling interoperation without shared declarations.

A consequence: **adding a field to an anonymous struct return type is source-compatible** for callers that use width subtyping. Removing or renaming fields is breaking. This is a significant ergonomic win for evolving APIs.

### Construction Rules

All fields must be specified in anonymous literals:

```with
let p: { x: i32, y: i32 } = { x: 1 }  // error: missing field 'y'
```

Fields with default values may be omitted, but only when the target type is a named struct or type alias with declared defaults:

```with
type Config { host: str = "localhost", port: i32 = 8080 }
let c: Config = {}  // uses defaults
```

Default values are not specifiable in anonymous struct literals directly.

### Pattern Matching

Anonymous struct types support destructuring:

```with
let { x, y } = get_point()

match pt:
    { x: 0, y: 0 } => "origin"
    { x, y: 0 } => f"on x-axis at {x}"
    _ => "other"

let { name, .. } = user   // partial destructuring
```

### Representation

An anonymous struct literal compiles to a stack-allocated record with fields in alphabetical order. No heap allocation, no boxing, no runtime type information beyond what is required for auto-derived traits. Performance is identical to a hand-declared named struct with the same fields.

Alphabetical ordering is a deterministic canonicalization. It ensures two anonymous struct types with the same fields have the same layout regardless of source order. Users who need a specific layout order must use a named struct.

## Empty Structs and Marker Types

Three rules govern "empty" cases:

**`{}` in expression position is always an empty block.** Not an empty struct, not an empty HashMap. Users who want an empty HashMap write `HashMap.new()`.

**Empty type aliases (`type Foo { }`) are not permitted.** Structural types with no fields have no useful content.

**Empty named structs (`struct Foo`) are permitted and create marker types.** Nominal identity is the only reason to declare a type with no fields; only `struct` provides it.

```with
// Marker / signal types:
struct Ready
struct Done

impl Event for Done:
    fn name(self: &Self) -> str:
        "done"

let d = Done {}
```

## Auto-Derived Traits

Anonymous struct types automatically derive a fixed set of traits, provided their fields' types also implement those traits:

- `Eq` — structural equality; two values are equal iff all corresponding fields are equal
- `Hash` — derived from field values in canonical order
- `Clone` — field-by-field clone
- `ToString` — produces a representation like `"{field: value, ...}"`
- `Serializable` / `Deserializable` — enables JSON interop (see *JSON Interop*)

User-defined traits are **not** auto-derived. Structural types cannot have custom trait implementations; users who need custom behavior must declare a named struct.

This design is analogous to Rust's `#[derive(...)]` but automatic. The auto-derived set is exactly the traits whose implementation can be mechanically determined from structure. Traits requiring user logic cannot be mechanically derived and therefore require nominal types.

## Impl Blocks and Coherence

Structural types (anonymous and `type`-aliased) **cannot** have `impl` blocks. This avoids the coherence problem: if two modules both implemented the same trait for the same shape, there would be no principled way to choose between them.

Users who want methods or custom trait implementations declare a named struct:

```with
// Not allowed:
impl ToString for { name: str }:
    // ...

// Use a named struct instead:
struct NamedThing:
    name: str

impl ToString for NamedThing:
    // ...
```

## Generics

Structural types participate as type arguments in generic code:

```with
fn identity[T](x: T) -> T:
    x

let p = identity({ x: 1, y: 2 })
// T = { x: i32, y: i32 }; return type identical
```

Generic types parameterized over structural types monomorphize per unique shape. `Vec[{ x: i32, y: i32 }]` and `Vec[{ x: i32 }]` produce distinct monomorphizations.

Parametric anonymous struct types are supported:

```with
fn make_pair[T](a: T, b: T) -> { first: T, second: T }:
    { first: a, second: b }
```

**Bounded structural generics** (constraints of the form `T: { name: str }` meaning "any type with at least a `name: str` field") are out of scope for the initial specification. Such constraints would require more complex type inference and may be added in a future revision if users require them.

## Grammar Disambiguation

The token `{` currently begins a block in With. Anonymous struct literals introduce a parsing ambiguity in expression contexts.

**Rule:** In an expression position, if the token sequence after `{` matches `identifier :` followed by an expression, it is an anonymous struct literal. Otherwise it is a block.

Examples:

```with
let x = { name: "Alice" }           // struct literal
let y = { let z = 5; z }            // block
let a = { do_work(); 42 }           // block
fn foo: { field: 1 }                // struct literal (return position)
```

`{}` is never parsed as an empty anonymous struct. In expression position it is always an empty block.

Ambiguous cases require explicit disambiguation via parentheses:

```with
let x = ({ label: compute() })      // block with labeled expression
let x = { label: compute() }        // struct literal
```

This rule is implementable with one-token lookahead.

## JSON Interop

### Overview

With provides `to_json` and `from_json` functions in `std.json`. These are the direct beneficiary of auto-derived serialization on structural types. Users serialize and deserialize between concrete types and JSON strings without declaring any boilerplate.

The design centers the typed path. A dynamic `Json` value type exists for cases where the shape is unknown.

### Core Functions

```with
// Serialize any serializable type to a JSON string
fn to_json[T: Serializable](value: T) -> str

// Serialize with pretty-printing
fn to_json_pretty[T: Serializable](value: T, indent: i32) -> str

// Deserialize a JSON string into a specified type
fn from_json[T: Deserializable](input: str) -> Result[T, JsonError]

// Strict variant: errors on extra JSON fields
fn from_json_strict[T: Deserializable](input: str) -> Result[T, JsonError]
```

### Serializable Types

A type is serializable if it is one of:

- Integer types: `i8`, `i16`, `i32`, `i64`, `u8`, `u16`, `u32`, `u64` → JSON number
- Floating-point types: `f32`, `f64` → JSON number
- `bool` → JSON boolean
- `str` → JSON string
- `Option[T]` where `T` is serializable → JSON `null` if `None`, else `T`'s encoding
- `Vec[T]` where `T` is serializable → JSON array
- `HashMap[str, V]` where `V` is serializable → JSON object
- Named struct with all fields serializable → JSON object
- Anonymous struct or structural type alias with all fields serializable → JSON object
- `Json` (the dynamic value type) → itself

Types with non-serializable fields (raw pointers, function references, opaque types) cannot be serialized. This is a compile-time error at the call site.

Serialization is implemented via compile-time derivation; no reflection or runtime type inspection is required.

### Field Naming

By default, struct field names map directly to JSON keys:

```with
let u = { first_name: "Alice" }
to_json(u)  // {"first_name":"Alice"}
```

For interop with external APIs that use different casing, named struct fields may declare explicit JSON names via an attribute:

```with
struct User:
    #[json(name = "firstName")]
    first_name: str
```

Anonymous struct literals do not support attributes. Users who need field renaming must use named structs.

### Deserialization Semantics

`from_json[T](input)` parses `input` as JSON, then matches its structure against `T`.

**Required fields:** Absence is an error.

**Optional fields (`Option[U]`):** `None` when absent, `Some(u)` when present.

**Default fields:** Apply when the JSON key is absent.

**Extra fields:** Ignored by default (matches JavaScript expectations). `from_json_strict` errors on extras.

**Type coercion:** JSON numbers are parsed as f64 and converted to the target integer or float type. Fractional values fail conversion to integer targets. String-to-number and number-to-string coercion is **never** performed.

**Null:** Maps to `None` for `Option[T]`; error for non-Option targets.

### Errors

```with
enum JsonError:
    SyntaxError(message: str, offset: i32)
    TypeMismatch(expected: str, got: str, path: str)
    MissingField(field: str, path: str)
    InvalidValue(message: str, path: str)
```

The `path` field uses JSON Pointer notation (`/user/name`) to locate errors.

### Dynamic Values: `Json`

For cases where the JSON shape is not known at compile time:

```with
enum Json:
    Null
    Bool(bool)
    Number(f64)
    String(str)
    Array(Vec[Json])
    Object(HashMap[str, Json])
```

`Json` is itself serializable and deserializable. Parsing unknown JSON works via `from_json[Json](input)`.

Accessor methods on `Json`:

```with
impl Json:
    fn get(self: &Json, key: str) -> Option[&Json]
    fn at(self: &Json, index: i64) -> Option[&Json]
    fn as_bool(self: &Json) -> Option[bool]
    fn as_i64(self: &Json) -> Option[i64]
    fn as_f64(self: &Json) -> Option[f64]
    fn as_str(self: &Json) -> Option[str]
    fn as_array(self: &Json) -> Option[&Vec[Json]]
    fn as_object(self: &Json) -> Option[&HashMap[str, Json]]
    fn is_null(self: &Json) -> bool
```

### Mixed Typed and Dynamic

`Json` may appear as a field type in an otherwise-typed struct, allowing partial typing:

```with
type Response { status: i32, headers: HashMap[str, str], body: Json }

let r = from_json[Response](api_response).unwrap()
// r.status is i32 (typed)
// r.body is Json (shape varies by endpoint)
```

This composition is essential. Users typically know the outer envelope of an API response but not the inner payload.

## Examples

### Configuration

```with
type Config {
    server: {
        host: str,
        port: i32,
        tls: { enabled: bool, cert_path: Option[str] },
    },
    logging: {
        level: str,
        targets: Vec[str],
    },
}

fn load_config(path: str) -> Result[Config, ConfigError]:
    let contents = fs.read_to_string(path)?
    match from_json[Config](contents):
        Ok(c) => Ok(c)
        Err(e) => Err(ConfigError.InvalidJson(e))
```

### Structural function parameter

```with
fn greet(u: { name: str }) -> str:
    f"hello {u.name}"

greet({ name: "Alice" })                    // exact match
greet({ name: "Bob", age: 30 })             // width subtyping
```

### API client

```with
fn fetch_user(id: i32) -> Result[{ name: str, email: str }, HttpError]:
    let response = http.get(f"/users/{id}")?
    from_json[{ name: str, email: str }](response.body)
        .map_err(HttpError.InvalidResponse)
```

### Domain boundary with named structs

```with
struct Password:
    hash: str
    salt: str

struct SessionToken:
    token: str
    expires_at: i64

// Password and SessionToken are nominal; even with identical fields,
// the type system keeps them distinct.
```

### Unknown JSON shape

```with
fn inspect_payload(raw: str):
    let v = from_json[Json](raw).unwrap()
    match v:
        Json.Object(map) =>
            for (k, val) in map:
                print(f"{k}: {val}")
        _ => print("not an object")
```

### Marker type

```with
struct RequestComplete

fn on_complete(e: RequestComplete):
    print("done")
```

## Design Principles

**Structural equivalence for shapes; nominal distinctness for concepts.** Two tools with two purposes. Users choose based on whether they need type-system-enforced boundaries.

**Zero-cost abstraction.** Structural types compile identically to equivalent named structs. No boxing, no runtime type information beyond what auto-derived traits require.

**Typed first, dynamic escape hatch.** The primary API targets users who know their data's shape. `Json` exists for the minority case.

**Fail at compile time when possible.** Typos, type mismatches, and missing fields are compile errors. Runtime errors are confined to the JSON deserialization boundary, which is inherently a runtime operation.

**Auto-derive only mechanically-deriveable traits.** `Eq`, `Hash`, `Clone`, `ToString`, `Serializable`, `Deserializable` all derive from structure alone. Traits requiring user logic need nominal types.

## Implementation Outline

### Phase 1: Structural types and anonymous struct literals

1. **Parser.** Anonymous struct literal as primary expression. Disambiguation rule for `{` in expression contexts. Pattern destructuring support.
2. **Type system.** Structural type kind. Structural equivalence via canonical field ordering and global interning. Distinguish structural aliases from nominal structs throughout the type system.
3. **Semantic analysis.** Type inference for anonymous literals. Width subtyping at function boundaries. Field access resolution on structural types.
4. **Auto-derive machinery.** Generate `Eq`, `Hash`, `Clone`, `ToString`, `Serializable`, `Deserializable` implementations for each structural type when field types support them.
5. **MIR lowering.** Identical treatment of structural and nominal structs at the MIR level.
6. **Code generation.** Alphabetical field layout matches the type system's canonical ordering.
7. **Cross-module identity.** Shared TypeIds across modules for shapes that unify.

Estimated scope: 7–10 implementation sessions.

### Phase 2: JSON interop

1. **JSON parser and tokenizer.** Pure With implementation. Produces `Json` values.
2. **JSON serializer for `Json` values.** Inverse of parser.
3. **Type-directed derivation.** Compiler-generated serialize and deserialize code for any serializable type. Relies on Phase 1 auto-derive infrastructure.
4. **Generic entry points.** `to_json[T]`, `from_json[T]`, `to_json_pretty[T]`, `from_json_strict[T]`.
5. **Error types and path tracking.** Full `JsonError` with JSON Pointer locations.
6. **Field renaming attribute.** `#[json(name = "...")]` on named struct fields.

Estimated scope: 4–5 implementation sessions.

### Combined scope

11–15 implementation sessions. Non-trivial. Should follow completion of the current compiler and migrator bug backlog rather than running in parallel.

## Alternatives Considered

### HashMap[str, Any] as the literal type

Rejected: violates zero-cost principle (boxing), defers typos to runtime, requires adding `Any` as a base type with attendant complexity, does not match the common case (fixed-shape structured data).

### HashMap[str, str] via stringification

Rejected: lossy, non-local behavior (type depends on whether any value is a string), contradicts user expectations of value preservation.

### Kotlin-style `mapOf` factory without new syntax

Rejected: does not address the stated ergonomic goal. Kotlin's tolerance for this friction reflects a different design target.

### Nominal anonymous types

Rejected: prevents using anonymous literals across function boundaries (each call site would have a distinct type). Defeats the purpose of anonymous types.

### User-implementable traits on structural types

Rejected: creates coherence problems with no principled solution. Users who want custom trait implementations can declare a named struct.

### Allowing `{}` as an empty HashMap or empty struct literal

Rejected: non-local type determination (absence of fields vs presence produces different types) and overlapping interpretations (empty block, empty struct, empty map). `{}` remains an empty block in all expression contexts.

## Open Questions

**Unicode handling in JSON strings.** UTF-8 pass-through vs `\uXXXX` escaping. Recommend UTF-8 default with strict-ASCII option.

**Integer overflow during deserialization.** Error by default. Alternative: `from_json_lossy` with saturation or truncation. Recommend keeping error-by-default.

**Field order in serialized output.** Alphabetical (deterministic) vs declaration order (intuitive). Recommend alphabetical; declaration order available for named structs via explicit attributes.

**`Json` namespace.** Top-level export from `std.json` vs `std.json.Value`. Recommend top-level `Json` because it is frequently reached for.

**Depth subtyping.** Disallowed initially. Reconsider based on usage.

**Bounded structural generics (`T: { name: str }`).** Deferred from initial specification. Evaluate after anonymous literals ship.

**Recursive type aliases and literal inference.** Type inference for nested literals matching recursive type aliases needs care. Some cases may require explicit annotation.

## Summary

This proposal adds structural types to With's type system, with anonymous struct literals as the user-facing syntax and typed JSON interop as the immediate practical benefit. The feature set composes cleanly with existing language features and gives users three clear choices for structured data:

| Tool | Use when |
|---|---|
| Anonymous literal `{ field: value }` | One-off structured data, inline use |
| Type alias `type Foo { ... }` | Convenient name for a shape, reusable across modules |
| Named struct `struct Foo { ... }` | Type system boundary, supports methods and traits |

The rule is simple enough to remember:

> Use `type` for shapes. Use `struct` for concepts.

The resulting language combines JavaScript syntax, Kotlin ergonomics, and C performance for the structured-data case — a combination no existing systems language offers cleanly.