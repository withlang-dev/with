# `with migrate swift` — Swift-to-With Source Translator

**Best-effort migration from Swift to With.**

Swift and With share a surprising amount of design philosophy:
value types by default, protocol/trait-based polymorphism, optional
chaining, result types, and async/await. The hard parts are
reference types (classes), ARC, property wrappers, and the Apple
framework layer.

---

## Design Goals

1. **Get 75% of the way there.** Swift's value-type code (structs,
   enums, protocols, generics, closures, error handling) maps
   closely to With. Translate it cleanly.

2. **Flag the reference-type world.** Swift `class`, `weak`,
   `unowned`, ARC, inheritance — these have no direct equivalent.
   Flag with With alternatives.

3. **Strip the Apple layer.** UIKit, SwiftUI, Combine, Foundation
   — these are platform frameworks, not language features. Flag
   them; don't try to translate them.

4. **One command.** `with migrate swift Sources/` translates a
   Swift package.

---

## Usage

```
with migrate swift Sources/main.swift         # single file
with migrate swift Sources/                   # directory
with migrate swift Sources/ -o lib/           # explicit output
with migrate swift Sources/ --check           # dry run
with migrate swift Sources/ --diff            # unified diff
with migrate swift Sources/ --stats           # summary
```

---

## Translation Rules

### Tier 1: Mechanical Syntax (100% automated)

#### Braces → indentation

```swift
func process(x: Int) -> Int {
    if x > 0 {
        return x * 2
    } else {
        return -x
    }
}

// With
fn process(x: i64) -> i64:
    if x > 0:
        return x * 2
    else:
        return -x
```

Strip `{` `}`. Convert to indent-based blocks.

#### Functions

```swift
func add(_ a: Int, _ b: Int) -> Int { a + b }
func greet() { print("hi") }
func greet(name: String) { print("hello \(name)") }

// With
fn add(a: i64, b: i64) -> i64: a + b
fn greet: print("hi")
fn greet(name: str): print(f"hello {name}")
```

`func` → `fn`. Strip `_` (unnamed) parameter labels. Named
parameter labels at call sites → named arguments in With
(same concept, direct translation).

**External/internal parameter names:**
```swift
func move(from source: Point, to dest: Point) { ... }
move(from: a, to: b)

// With
fn move(source: Point, dest: Point): ...
// @migrate: Swift external labels 'from'/'to' removed.
// With uses parameter names directly: move(source: a, dest: b)
move(source: a, dest: b)
```

Swift's dual-name parameters (`from source:`) → use the internal
name only. Flag if the external label was semantically important.

#### Bindings

```swift
let x = 5                  →  let x = 5
var x = 5                  →  var x = 5
let x: Int = 5             →  let x: i64 = 5
```

Direct mapping. `let` → `let`, `var` → `var`.

#### Types

```swift
Int                        →  i64
UInt                       →  u64
Int8 / Int16 / Int32 / Int64  →  i8 / i16 / i32 / i64
UInt8 / UInt16 / UInt32 / UInt64  →  u8 / u16 / u32 / u64
Float                      →  f32
Double                     →  f64
Bool                       →  bool
String                     →  str
Character                  →  i32         // @migrate: Unicode scalar → rune
[T]                        →  Vec[T]
[K: V]                     →  HashMap[K, V]
Set<T>                     →  HashSet[T]
T?                         →  Option[T]
(T, U)                     →  (T, U)      // tuples map directly
Void / ()                  →  ()
Never                      →  Never
```

Swift `Int` is platform-sized (64-bit on modern platforms) → `i64`.
`String` → `str`. `[T]` (array) → `Vec[T]`.
`[K: V]` (dictionary) → `HashMap[K, V]`.

#### Optionals

```swift
let x: Int? = nil          →  let x: Option[i64] = None
let x: Int? = 42           →  let x: Option[i64] = Some(42)
x!                         →  x.unwrap()
x?                         →  x                  // optional chaining (see Tier 2)
x ?? default               →  x ?? default
if let v = x { use(v) }    →  if let Some(v) = x: use(v)
guard let v = x else { return }  →  let v = x ?? return
```

`nil` → `None` (already in Migrate.zig).
`T?` → `Option[T]` (already in Migrate.zig).
`x!` (force unwrap) → `x.unwrap()`.
`x ?? default` → `x ?? default` (same operator in With).
`if let` → `if let Some(v) =`.
`guard let` → `let v = x ?? return` (already in Migrate.zig).

#### String interpolation

```swift
"hello \(name), age \(age)"

// With
f"hello {name}, age {age}"
```

`\(expr)` → `{expr}` inside f-string.
Already handled in Migrate.zig (`rewriteSwiftInterpolation`).

#### Protocols → Traits

```swift
protocol Drawable {
    func draw(on canvas: Canvas)
    var bounds: Rect { get }
}

// With
trait Drawable:
    fn draw(self: &Self, canvas: &Canvas)
    fn bounds(self: &Self) -> Rect
```

`protocol` → `trait` (already in Migrate.zig).
Computed properties (`var x: T { get }`) → getter methods.
Protocol requirements → trait methods.

#### Extensions → impl / extend

```swift
extension User: Drawable {
    func draw(on canvas: Canvas) { ... }
}

extension Array where Element: Comparable {
    func sorted() -> [Element] { ... }
}

// With
impl Drawable for User:
    fn draw(self: &Self, canvas: &Canvas): ...

extend Vec[T] where T: Ord:
    fn sorted(self: &Self) -> Vec[T]: ...
```

`extension Type: Protocol` → `impl Protocol for Type` (already
in Migrate.zig). `extension Type` (no protocol) → `extend Type`.
`where` clauses pass through.

#### Enums

```swift
enum Direction {
    case north, south, east, west
}

enum Barcode {
    case upc(Int, Int, Int, Int)
    case qr(String)
}

// With
type Direction =
    | North
    | South
    | East
    | West

type Barcode =
    | Upc(i64, i64, i64, i64)
    | Qr(str)
```

Swift enum `case` → With `|` variants.
Associated values → payload types.
Capitalize variant names (Swift allows lowercase, With prefers
PascalCase for variants).

#### Structs

```swift
struct Point {
    var x: Double
    var y: Double

    func distance(to other: Point) -> Double {
        sqrt(pow(x - other.x, 2) + pow(y - other.y, 2))
    }
}

// With
type Point = {
    x: f64,
    y: f64,
}

impl Point:
    fn distance(self: &Self, other: &Point) -> f64:
        sqrt(pow(self.x - other.x, 2) + pow(self.y - other.y, 2))
```

Struct → `type Name = { fields }`. Methods extracted to `impl`
block. Implicit `self` → explicit `self: &Self`.

#### Memberwise initializer

```swift
let p = Point(x: 1.0, y: 2.0)

// With
let p = Point { x: 1.0, y: 2.0 }
```

Swift's auto-generated memberwise init → With struct literal.

#### Control flow

```swift
if cond { body }              →  if cond: body
if cond { a } else { b }     →  if cond: a else: b
while cond { body }           →  while cond: body
for x in collection { body }  →  for x in collection: body
for i in 0..<10 { body }     →  for i in 0..10: body
for i in 0...9 { body }      →  for i in 0..=9: body
repeat { body } while cond   →  while true: body; if not cond: break
```

Swift `0..<10` → With `0..10` (exclusive).
Swift `0...9` → With `0..=9` (inclusive).
`repeat/while` → `while true` + break.

#### Switch / pattern matching

```swift
switch value {
case .north:
    goNorth()
case .south, .west:
    goOther()
case let .upc(a, b, c, d):
    scanUpc(a, b, c, d)
default:
    fallback()
}

// With
match value:
    Direction.North -> goNorth()
    Direction.South | Direction.West -> goOther()
    Barcode.Upc(a, b, c, d) -> scanUpc(a, b, c, d)
    _ -> fallback()
```

`switch` → `match`. `case` → pattern. `default` → `_`.
Multi-case (`case .a, .b`) → `Pattern1 | Pattern2`.
No fallthrough by default (same as With).
`fallthrough` keyword → flag.

#### `where` clauses in switch

```swift
case let x where x > 0:

// With
x if x > 0 ->
```

Swift `case let x where cond` → With `x if cond ->` (match guard).

#### Closures

```swift
{ (x: Int) -> Int in x + 1 }
{ x in x + 1 }
{ $0 + 1 }
items.map { $0.name }
items.filter { $0.isActive }
items.sorted { $0 < $1 }

// With
(x: i64) -> i64 => x + 1
x => x + 1
it + 1                    // With's `it` implicit parameter
items.map(it.name)        // trailing closure → argument with `it`
items.filter(it.is_active)
items.sorted(it.0 < it.1) // @migrate: verify sort comparator
```

Swift's `$0`, `$1` shorthand → With's `it` for single-parameter
closures. Multi-parameter closures with `$0`, `$1` → flag or
expand to explicit `(a, b) => ...`.

**Trailing closure syntax:**
```swift
items.map { $0.name }

// With
items.map(it.name)
```

Swift's trailing closure (outside parens) → normal argument.

#### `do/catch` → `match` on Result

```swift
do {
    let data = try readFile(path)
    process(data)
} catch FileError.notFound {
    print("not found")
} catch {
    print("error: \(error)")
}

// With
match readFile(path):
    Ok(data) -> process(data)
    Err(FileError.NotFound) -> print("not found")
    Err(e) -> print(f"error: {e}")
```

Swift's `do/try/catch` → call the function, match on Result.
Individual `try` expressions → `?` operator:

```swift
let data = try readFile(path)

// With
let data = readFile(path)?
```

#### `throws` → `Result`

```swift
func readFile(_ path: String) throws -> Data { ... }

// With
fn readFile(path: str) -> Result[Data, Error]: ...
```

`throws` → `Result[T, Error]` return type. Swift's untyped throws
→ generic `Error`. Swift 6's typed throws (`throws(MyError)`) →
`Result[T, MyError]`.

#### Access control

```swift
public func foo()          →  pub fn foo
internal func foo()        →  fn foo
fileprivate func foo()     →  fn foo        // @migrate: was fileprivate
private func foo()         →  fn foo        // @migrate: was private
open class Foo             →  // @migrate: open class — no equivalent

// With
pub fn foo
fn foo
```

`public` → `pub`. `internal` (default) → nothing (same default).
`fileprivate` and `private` → private with flag. `open` → flag.

#### Comments

```swift
// line comment            →  // line comment
/// doc comment            →  /// doc comment
/* block comment */        →  // @migrate: block comment converted
```

Line and doc comments pass through. Block comments converted to
line comments (With uses `//` only).

#### Semicolons

Strip. Swift doesn't require them but allows them.

---

### Tier 2: Semantic Translations (automated with caveats)

#### Optional chaining

```swift
let city = user.address?.city?.uppercased()

// With
let city = user.address?.city?.to_upper()
// @migrate: optional chaining — verify With supports this chain depth
```

Swift `?.` → With `?.` (same syntax, same semantics per the With
spec §10). Method names may differ (`.uppercased()` → `.to_upper()`).

#### Computed properties → methods

```swift
struct Circle {
    var radius: Double
    var area: Double {
        .pi * radius * radius
    }
    var diameter: Double {
        get { radius * 2 }
        set { radius = newValue / 2 }
    }
}

// With
type Circle = {
    radius: f64,
}

impl Circle:
    fn area(self: &Self) -> f64: PI * self.radius * self.radius
    fn diameter(self: &Self) -> f64: self.radius * 2
    fn set_diameter(self: &mut Self, value: f64): self.radius = value / 2
```

Read-only computed property → getter method.
Read-write computed property → getter + setter methods.
`newValue` → explicit parameter name.

#### Property observers → flag

```swift
var score: Int {
    willSet { print("will change to \(newValue)") }
    didSet { print("changed from \(oldValue)") }
}

// With
// @migrate: property observers (willSet/didSet) — no direct equivalent.
// Use explicit setter method that performs the side effect.
var score: i64
fn set_score(self: &mut Self, value: i64):
    print(f"will change to {value}")
    let old = self.score
    self.score = value
    print(f"changed from {old}")
```

#### Generics

```swift
func swap<T>(_ a: inout T, _ b: inout T) { ... }
struct Stack<Element> { ... }
func largest<T: Comparable>(in array: [T]) -> T { ... }

// With
fn swap[T](a: &mut T, b: &mut T): ...
type Stack[T] = { ... }
fn largest[T: Ord](array: &Vec[T]) -> T: ...
```

`<T>` → `[T]`. `Comparable` → `Ord`. `Equatable` → `Eq`.
`Hashable` → `Hash`. `CustomStringConvertible` → `Display`.
`CustomDebugStringConvertible` → `Debug`.
`Codable` → flag (no direct equivalent).

`inout` → `&mut` reference.

#### Protocol conformance mapping

| Swift Protocol | With Trait | Notes |
|---|---|---|
| `Equatable` | `Eq` | Direct |
| `Comparable` | `Ord` | Direct |
| `Hashable` | `Hash` | Direct |
| `CustomStringConvertible` | `Display` | `.description` → `.to_str()` |
| `CustomDebugStringConvertible` | `Debug` | Direct |
| `Sequence` | `IntoIter[T]` | Conceptually similar |
| `IteratorProtocol` | `Iter[T]` | `.next()` → `.next()` |
| `Collection` | flag | No single equivalent |
| `Codable` | flag | No serialization framework |
| `Identifiable` | flag | Use `Eq` + `Hash` |
| `Error` | `Error` (trait) | Direct |
| `Sendable` | (implicit) | With's concurrency model handles this |

#### `async/await`

```swift
func fetchUser(id: Int) async throws -> User {
    let data = try await api.get("/users/\(id)")
    return try decode(data)
}

// With
async fn fetchUser(id: i64) -> Result[User, Error]:
    let data = api.get(f"/users/{id}").await?
    decode(data)?
```

`async func` → `async fn`.
`try await expr` → `expr.await?` (postfix).
`async let` → task spawn:

```swift
async let user = fetchUser(id)
async let posts = fetchPosts(id)
let (u, p) = await (user, posts)

// With
let user_task = fetchUser(id)
let posts_task = fetchPosts(id)
let (u, p) = (user_task, posts_task).await
```

#### `Result` type

```swift
let result: Result<Int, Error> = .success(42)
switch result {
case .success(let value): use(value)
case .failure(let error): handle(error)
}

// With
let result: Result[i64, Error] = Ok(42)
match result:
    Ok(value) -> use(value)
    Err(error) -> handle(error)
```

`.success` → `Ok`. `.failure` → `Err`.

#### `defer`

```swift
defer { cleanup() }

// With
defer cleanup()
```

Direct translation. Swift `defer` = With `defer`.

#### Type casting

```swift
x as! Int                  →  x as i64            // @migrate: was forced cast
x as? Int                  →  // @migrate: conditional cast — use match
x is Int                   →  // @migrate: type check — use match
```

`as!` → `as` with flag. `as?` and `is` → flag (With uses pattern
matching for type discrimination, not runtime type checks).

#### String methods

```swift
s.count                    →  s.len()
s.isEmpty                  →  s.is_empty()
s.hasPrefix("x")          →  s.starts_with("x")
s.hasSuffix("x")          →  s.ends_with("x")
s.lowercased()             →  s.to_lower()
s.uppercased()             →  s.to_upper()
s.trimmingCharacters(in: .whitespaces)  →  s.trim()
s.contains("x")           →  s.contains("x")
s.replacingOccurrences(of: "a", with: "b")  →  s.replace("a", "b")
s.split(separator: ",")   →  s.split(",")
s.joined(separator: ", ")  →  parts.join(", ")
```

Map common String methods to With equivalents.

#### Array/Dictionary methods

```swift
arr.append(x)              →  arr.push(x)
arr.count                  →  arr.len()
arr.isEmpty                →  arr.is_empty()
arr.remove(at: i)          →  arr.remove(i)
arr.contains(x)            →  arr.contains(x)
arr.map { ... }            →  arr.map(...)
arr.filter { ... }         →  arr.filter(...)
arr.reduce(0, +)           →  arr.fold(0, (a, b) => a + b)
arr.compactMap { ... }     →  arr.filter_map(...)
arr.flatMap { ... }        →  arr.flat_map(...)
arr.sorted()               →  arr.sort(cmp)  // @migrate: needs comparator
arr.enumerated()           →  arr.enumerate()
arr.first                  →  arr.first()     // @migrate: returns Option
arr.last                   →  arr.last()
dict[key]                  →  dict.get(key)   // @migrate: returns Option
dict[key] = value          →  dict.insert(key, value)
dict.keys                  →  dict.keys()
dict.values                →  dict.values()
```

#### Tuple access

```swift
let pair = (1, "hello")
pair.0                     →  pair.0
pair.1                     →  pair.1
```

Direct translation. Same syntax.

---

### Tier 3: Structural Flags (cannot auto-translate)

#### Classes → flag

```swift
class Animal {
    var name: String
    init(name: String) { self.name = name }
    func speak() { }
}

class Dog: Animal {
    override func speak() { print("woof") }
}

// With
// @migrate: CLASS — With uses structs + traits, not class inheritance.
// Options:
//   1. Convert to struct + trait:
//        trait Animal: fn speak(self: &Self)
//        type Dog = { name: str }
//        impl Animal for Dog: fn speak(self: &Self): print("woof")
//   2. If identity semantics needed: use Handle[T] + SlotMap
//   3. If shared mutation needed: use with lock.write() as mut data: ...
type Dog = {
    name: str,
}
// TODO: restructure class hierarchy as traits
```

Classes are the biggest migration challenge. Swift classes have:
- Reference semantics (ARC)
- Inheritance
- Identity (`===`)
- `deinit`

With has none of these. Flag every class with an explanation of
the struct + trait alternative.

#### Inheritance → trait decomposition

```swift
class Vehicle {
    var speed: Double = 0
    func describe() -> String { "speed: \(speed)" }
}
class Car: Vehicle {
    var doors: Int
    override func describe() -> String { "\(super.describe()), doors: \(doors)" }
}

// With
// @migrate: class hierarchy → decompose into traits
trait Describable:
    fn describe(self: &Self) -> str

type Vehicle = { speed: f64 }
impl Describable for Vehicle:
    fn describe(self: &Self) -> str: f"speed: {self.speed}"

type Car = { speed: f64, doors: i32 }
impl Describable for Car:
    fn describe(self: &Self) -> str: f"speed: {self.speed}, doors: {self.doors}"
```

No automatic translation — the inheritance hierarchy must be
manually decomposed. Flag with trait decomposition suggestion.

#### `weak` / `unowned` references

```swift
weak var delegate: Delegate?
unowned let owner: Owner

// With
// @migrate: weak/unowned — no ARC in With.
// Options:
//   - Handle[Delegate] if using entity system
//   - &Delegate if ephemeral (borrow, don't own)
//   - Callback closure instead of delegate pattern
```

Already tracked as manual fixup in Migrate.zig.

#### Property wrappers

```swift
@Published var name: String
@State var count: Int
@Binding var text: String
@ObservedObject var model: ViewModel

// With
// @migrate: property wrapper @Published — no direct equivalent.
// Use explicit pub field + notification pattern.
// @migrate: @State/@Binding/@ObservedObject — SwiftUI specific, no equivalent.
```

Property wrappers are deep Swift-specific metaprogramming. Flag.

#### SwiftUI / UIKit / Combine

```swift
struct ContentView: View {
    var body: some View {
        VStack { Text("Hello") }
    }
}

// With
// @migrate: SwiftUI — no equivalent framework.
// This file is platform-specific UI code.
// Entire file flagged for manual rewrite.
```

Apple frameworks don't translate. Flag the entire file.

#### `@MainActor` / actors

```swift
@MainActor
class ViewModel: ObservableObject { ... }

actor BankAccount {
    var balance: Double
    func deposit(_ amount: Double) { balance += amount }
}

// With
// @migrate: @MainActor — no direct equivalent.
// With uses fiber-safe types and explicit synchronization.

// @migrate: actor — use Mutex or channel-based pattern:
type BankAccount = {
    balance: f64,
}
// Wrap in Mutex for thread-safe access:
// let account = Mutex.new(BankAccount { balance: 0.0 })
// with account.lock() as mut a: a.balance = a.balance + amount
```

Swift actors → With `Mutex` + `with` blocks. Flag with example.

#### `some` (opaque return types)

```swift
func makeShape() -> some Shape { Circle(radius: 5) }

// With
fn makeShape() -> impl Shape: Circle { radius: 5.0 }
// @migrate: `some Shape` → `impl Shape` — verify trait is object-safe
```

`some T` → `impl T`. Direct mapping in simple cases.

#### Existential types (`any`)

```swift
let shapes: [any Shape] = [circle, square]

// With
let shapes: Vec[dyn Shape] = [circle, square]
// @migrate: `any Shape` → `dyn Shape` (trait object with vtable)
```

`any Protocol` → `dyn Trait`.

#### Associated types in protocols

```swift
protocol Container {
    associatedtype Item
    func get(_ index: Int) -> Item
}

// With
// @migrate: associated type → use generic trait parameter
trait Container[T]:
    fn get(self: &Self, index: i64) -> T
```

`associatedtype` → generic trait parameter. Same suggestion as
the Rust spec.

#### Key paths

```swift
let getName = \User.name
users.sorted(by: \.age)

// With
// @migrate: key paths — no direct equivalent.
// Use closure: users.sorted((a, b) => a.age < b.age)
// Or with `it`: users.sorted(it.0.age < it.1.age)
```

#### Subscripts

```swift
struct Matrix {
    subscript(row: Int, col: Int) -> Double { ... }
}

// With
// @migrate: subscript → implement Index trait or use method
impl MultiIndex[i64, f64] for Matrix:
    fn get(self: &Self, row: i64, col: i64) -> f64: ...
```

#### String as collection

Swift treats `String` as a `Collection` of `Character`. With
treats `str` as bytes with explicit UTF-8 decoding. Character
iteration needs different patterns:

```swift
for char in string { use(char) }

// With
for cp in string.codepoints(): use(cp)
// @migrate: Swift Character ≠ With codepoint. Swift Character is
// an extended grapheme cluster. Use string.codepoints() for runes
// or string.grapheme_clusters() for Swift-equivalent behavior.
```

---

## Quality Grades

| Level | Meaning | Typical Swift code |
|---|---|---|
| **A** | Pure syntax. Compiles immediately. | Structs, enums, value-type algorithms |
| **B** | Minor edits (method renames, optional syntax). | Protocol-oriented code, error handling |
| **C** | Structural changes (class→struct+trait). | Class hierarchies, delegates |
| **D** | Heavily flagged. Mostly manual. | SwiftUI, Combine, actors, property wrappers |

---

## Implementation Plan

### Step 1: Extend syntax transformer

Port and extend `transformSwift` from Migrate.zig:
- `func` → `fn` (existing)
- `protocol` → `trait` (existing)
- `nil` → `None` (existing)
- String interpolation `\(expr)` → `{expr}` (existing)
- `guard let` → `let v = x ?? return` (existing)
- `extension: Protocol` → `impl Protocol for Type` (existing)
- `T?` → `Option[T]` (existing)
- Add: brace→indent
- Add: `switch` → `match`
- Add: `case` → `|` (enum variants)
- Add: `class` → `type` with flag
- Add: range operators (`0..<10` → `0..10`)
- Add: `throws` → `Result[T, Error]`
- Add: `try expr` → `expr?`
- Add: `try await expr` → `expr.await?`
- Add: `async func` → `async fn`

**Done when:** Swift struct/enum/protocol code produces readable With.

### Step 2: Type and method rewriter

- Swift standard types → With types
- `.count` → `.len()`, `.isEmpty` → `.is_empty()`, etc.
- `Equatable` → `Eq`, `Comparable` → `Ord`, etc.
- Computed properties → getter/setter methods
- Subscripts → `Index` trait impl
- `inout` → `&mut`
- `some T` → `impl T`
- `any T` → `dyn T`

**Done when:** Common Swift patterns produce correct With types
and method calls.

### Step 3: Closure and trailing closure rewriter

- `{ expr }` trailing closure → argument
- `$0` → `it` (single param)
- `$0`, `$1` → `(a, b) =>` (multi param)
- `{ (x: T) -> U in expr }` → `(x: T) -> U => expr`

**Done when:** Functional Swift code (map/filter/reduce chains)
produces idiomatic With.

### Step 4: Class flagger

Detect `class` declarations. Emit struct translation with
comprehensive `// @migrate:` annotation explaining:
- Trait decomposition for inheritance
- `with` blocks for shared mutation
- Handles for identity semantics
- Drop for `deinit`

**Done when:** Every class gets a useful flag with concrete
alternatives.

### Step 5: Framework detector

Detect imports of Apple frameworks (`UIKit`, `SwiftUI`, `Combine`,
`Foundation`, `CoreData`, `AppKit`). Flag entire file:

```
// @migrate: This file uses SwiftUI — no With equivalent.
// Platform-specific UI code must be rewritten for your target platform.
```

### Step 6: Flag generator and grading

Flag: `class`, `weak`, `unowned`, `@MainActor`, `actor`,
property wrappers, key paths, `Codable`, Apple frameworks,
`subscript`, `deinit`, `associatedtype`, class inheritance,
`fallthrough`, `is`/`as?` type casting.

Grade each file A–D.

### Step 7: Multi-file and module rewriting

`import Foundation` → strip (most of Foundation's functionality
is in With's stdlib). `import MyModule` → `use my_module`.
Swift Package Manager structure → With module structure.

**Done when:** `with migrate swift Sources/` translates a full
Swift package.

---

## Philosophy

The migration pitch to Swift developers:

> "You already prefer value types — that's why you use structs
> and protocols. With makes that the only option, and gives you
> a real borrow checker instead of ARC. No `weak self` closures.
> No retain cycles. No runtime reference counting overhead.
>
> Your protocol-oriented code translates almost line-for-line.
> Your class hierarchies are the part that needs rethinking —
> and once you do, the code is simpler."

The tool handles the syntax. The flags guide the architecture.
The programmer does the thinking about class→trait decomposition,
which is the genuinely valuable part of the migration.
