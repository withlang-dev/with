# `with migrate go` — Go-to-With Source Translator

**Best-effort migration from Go to With.**

Go and With occupy similar territory — simple languages for
building servers, CLI tools, and infrastructure. The syntax
translation is straightforward. The semantic gap is garbage
collection: Go has it, With doesn't. Most Go code translates
cleanly because Go programmers already think in terms of owned
values and explicit error handling. The hard parts are interfaces
with implicit satisfaction, goroutine fan-out patterns, and
code that relies on the GC to clean up.

---

## Design Goals

1. **Get 80% of the way there.** Go is intentionally simple.
   There are few language features to translate. The output
   should be close to idiomatic With.

2. **Flag GC-dependent patterns.** Go code that relies on the
   garbage collector to reclaim unreachable objects needs
   explicit cleanup in With. Flag these sites.

3. **Map goroutines to fibers.** Go's goroutine+channel model
   maps naturally to With's fiber+channel model. Most concurrent
   Go code translates directly.

4. **One command.** `with migrate go cmd/server/` translates a
   Go package.

---

## Usage

```
with migrate go main.go                      # single file
with migrate go ./cmd/server/                # package directory
with migrate go ./...                        # all packages
with migrate go ./cmd/server/ -o server/     # explicit output
with migrate go ./cmd/server/ --check        # dry run
with migrate go ./cmd/server/ --diff         # unified diff
with migrate go ./cmd/server/ --stats        # summary
```

---

## Translation Rules

### Tier 1: Mechanical Syntax (100% automated)

#### Braces → indentation

```go
func process(x int) int {
    if x > 0 {
        return x * 2
    } else {
        return -x
    }
}

// With
fn process(x: i32) -> i32:
    if x > 0:
        return x * 2
    else:
        return -x
```

Strip `{` `}`. Convert to indent-based blocks. Go already
requires braces on same line, so the indentation is consistent.

#### Functions

```go
func add(a, b int) int { return a + b }
func greet() { fmt.Println("hi") }
func swap(a, b int) (int, int) { return b, a }
func (p *Point) Scale(f float64) { p.X *= f; p.Y *= f }

// With
fn add(a: i32, b: i32) -> i32: a + b
fn greet: print("hi")
fn swap(a: i32, b: i32) -> (i32, i32): (b, a)
fn Point.scale(self: &mut Point, f: f64): self.x = self.x * f; self.y = self.y * f
```

`func` → `fn`. Receiver `(p *Point)` → method `Point.scale(self: &mut Point)`.
Value receiver `(p Point)` → `self: Point`.
Multi-return `(int, int)` → tuple `(i32, i32)`.
Named returns → flag (With doesn't have naked return).

**Named return values:**
```go
func divide(a, b int) (result int, err error) {
    if b == 0 {
        err = errors.New("division by zero")
        return
    }
    result = a / b
    return
}

// With
fn divide(a: i32, b: i32) -> (i32, Option[Error]):
    if b == 0:
        return (0, Some(Error.new("division by zero")))
    (a / b, None)
// @migrate: named returns removed — naked return expanded
```

Naked `return` → explicit return of all named values.

#### Type declarations

```go
type Point struct {
    X float64
    Y float64
}

// With
type Point = {
    x: f64,
    y: f64,
}
// @migrate: exported fields X,Y lowercased to x,y — With uses lowercase fields
```

Go struct → With `type Name = { fields }`. Go uses PascalCase
for exported fields; With uses lowercase. Lowercase all field
names automatically.

#### Variables and constants

```go
var x int = 5
var y = "hello"
x := 42
const Pi = 3.14159
const (
    A = iota
    B
    C
)

// With
var x: i32 = 5
var y = "hello"
var x = 42
const Pi: f64 = 3.14159
const A: i32 = 0
const B: i32 = 1
const C: i32 = 2
```

`var` → `var`. `:=` → `var` (short declaration).
`const` → `const`. `iota` → expand to explicit values.

#### Types

```go
int                        →  i32    // @migrate: Go int is platform-sized, using i32
int8 / int16 / int32 / int64  →  i8 / i16 / i32 / i64
uint8 / uint16 / uint32 / uint64  →  u8 / u16 / u32 / u64
float32 / float64          →  f32 / f64
bool                       →  bool
string                     →  str
byte                       →  u8
rune                       →  i32
[]T                        →  Vec[T]
[N]T                       →  [T; N]
map[K]V                    →  HashMap[K, V]
*T                         →  *mut T
error                      →  Error   // @migrate: Go error interface → With Error trait
any / interface{}          →  // @migrate: see Tier 3
uintptr                    →  usize
```

Go `int` is platform-sized (32 or 64 bit). Default to `i32`
and flag. `string` → `str`. `[]T` → `Vec[T]`.
`map[K]V` → `HashMap[K, V]`. `byte` → `u8`. `rune` → `i32`.

#### Slices and arrays

```go
s := make([]int, 0, 10)
s = append(s, 42)
len(s)
cap(s)
s[1:3]
copy(dst, src)

// With
var s = Vec[i32].with_capacity(10)
s.push(42)
s.len()
s.cap()
s.slice(1, 3)           // @migrate: verify slice semantics (view vs copy)
mem_copy(dst, src, n)
```

`make([]T, len, cap)` → `Vec[T].with_capacity(cap)` or
`Vec[T].new()`. `append` → `.push()`. `len()` → `.len()`.
`cap()` → `.cap()`. `s[a:b]` → `.slice(a, b)`.

#### Maps

```go
m := make(map[string]int)
m["key"] = 42
v, ok := m["key"]
delete(m, "key")
for k, v := range m { ... }

// With
var m = HashMap[str, i32].new()
m.insert("key", 42)
let v = m.get("key")          // returns Option[i32]
m.remove("key")
for (k, v) in m: ...
```

`m[key]` read → `m.get(key)` (returns `Option`).
`m[key] = val` → `m.insert(key, val)`.
`delete(m, key)` → `m.remove(key)`.
Two-value map access `v, ok := m[key]` → `let v = m.get(key)`
(Option encodes the `ok` boolean).

#### Control flow

```go
if x > 0 { body }                    →  if x > 0: body
if err := f(); err != nil { ... }    →  // see error handling below
for i := 0; i < 10; i++ { body }    →  for i in 0..10: body
for _, v := range items { body }     →  for v in items: body
for i, v := range items { body }     →  for (i, v) in items.enumerate(): body
for k, v := range m { body }         →  for (k, v) in m: body
for { body }                         →  while true: body
for cond { body }                    →  while cond: body
switch x { cases }                   →  match x: cases
select { cases }                     →  select await: cases
```

Go `for` is overloaded. Three-clause `for` with simple
`i := 0; i < N; i++` → `for i in 0..N:`. Range loops map
directly. Infinite loop `for {}` → `while true:`.
Condition-only `for cond {}` → `while cond:`.

#### Switch

```go
switch x {
case 1:
    one()
case 2, 3:
    twoOrThree()
default:
    other()
}

// With
match x:
    1 -> one()
    2 | 3 -> twoOrThree()
    _ -> other()
```

`switch` → `match`. `case` → pattern + `->`.
Multi-value `case 2, 3:` → `2 | 3 ->`.
`default:` → `_ ->`.
Go switch has **no fallthrough** by default (same as With).
`fallthrough` keyword → flag.

**Type switch:**
```go
switch v := x.(type) {
case int:
    useInt(v)
case string:
    useString(v)
}

// With
match x:
    v: i32 -> useInt(v)
    v: str -> useString(v)
// @migrate: type switch — verify With pattern matching supports this
```

#### If-init statements

```go
if err := doSomething(); err != nil {
    return err
}

// With
let err = doSomething()
if err.is_err():
    return err
// or with ? operator:
doSomething()?
```

Go's `if init; cond` → separate declaration + condition.
For the common `if err != nil` pattern, use `?` operator instead.

#### Error handling

```go
result, err := doSomething()
if err != nil {
    return fmt.Errorf("failed: %w", err)
}
use(result)

// With
let result = doSomething()?
// @migrate: Go error wrapping fmt.Errorf("failed: %w", err)
//           → use wrap(err, "failed") from std.errors
use(result)
```

Go's `result, err := f(); if err != nil { return err }` → `f()?`.
This is the highest-value translation — it eliminates Go's most
common boilerplate.

**Detection rule:** When a function returns `(T, error)` and the
call is followed by `if err != nil { return ..., err }`, collapse
to `?` operator. Change the function's return type from
`(T, error)` to `Result[T, Error]`.

```go
func readConfig(path string) (Config, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return Config{}, err
    }
    var cfg Config
    err = json.Unmarshal(data, &cfg)
    if err != nil {
        return Config{}, err
    }
    return cfg, nil
}

// With
fn readConfig(path: str) -> Result[Config, Error]:
    let data = fs.read_file(path)?
    let cfg = json.parse(data)?
    cfg     // implicit Ok wrapping
```

This is the killer feature of the migration tool. Go code
with 15 lines of error checking becomes 3 lines.

#### Multiple return values → Result or tuple

```go
func divide(a, b int) (int, error) { ... }  →  fn divide(a: i32, b: i32) -> Result[i32, Error]
func minmax(s []int) (int, int) { ... }     →  fn minmax(s: &Vec[i32]) -> (i32, i32)
func get(m map[K]V, k K) (V, bool) { ... }  →  fn get(m: &HashMap[K, V], k: K) -> Option[V]
```

**Heuristics:**
- `(T, error)` → `Result[T, Error]`
- `(T, bool)` → `Option[T]` (common in map lookups, type assertions)
- Everything else → tuple

#### `defer`

```go
defer file.Close()
defer mu.Unlock()

// With
defer file.close()
defer mu.unlock()
```

Direct translation. Go `defer` evaluates arguments immediately
(With's `defer` also does). Go defers are LIFO (same as With).

#### `panic` / `recover`

```go
panic("something went wrong")

defer func() {
    if r := recover(); r != nil {
        log.Println("recovered:", r)
    }
}()

// With
panic("something went wrong")

// @migrate: recover() — With does not have panic recovery.
// Panics are fatal. Convert to Result-based error handling.
```

`panic()` → `panic()`. `recover()` → flag (With panics are
not recoverable; convert to error returns).

#### String operations

```go
len(s)                     →  s.len()
s + t                      →  s ++ t       // @migrate: string concat
s[i]                       →  s.byte_at(i)
s[a:b]                     →  s.slice(a, b)
strings.Contains(s, sub)   →  s.contains(sub)
strings.HasPrefix(s, pre)  →  s.starts_with(pre)
strings.HasSuffix(s, suf)  →  s.ends_with(suf)
strings.ToUpper(s)         →  s.to_upper()
strings.ToLower(s)         →  s.to_lower()
strings.TrimSpace(s)       →  s.trim()
strings.Split(s, sep)      →  s.split(sep)
strings.Join(parts, sep)   →  parts.join(sep)
strings.Replace(s, o, n, -1) → s.replace(o, n)
strings.Index(s, sub)      →  s.find(sub)
fmt.Sprintf("...", args)   →  f"..."
strconv.Itoa(n)            →  n.to_string()
strconv.Atoi(s)            →  s.parse_int()  // @migrate: returns Result
```

Map `strings.*` and `strconv.*` functions to With string methods.

#### Imports

```go
import (
    "fmt"
    "os"
    "strings"
    "encoding/json"
    "myproject/internal/config"
)

// With
use std.fmt            // @migrate: Go fmt → With print/f-strings
use std.fs             // @migrate: Go os → With std.fs / std.process
use std.string         // @migrate: Go strings → With str methods
use std.json           // @migrate: Go encoding/json → With std.json
use config             // @migrate: internal package → adjust module path
```

Standard library imports map to With equivalents.
Third-party imports → flag.

#### Visibility

```go
func PublicFunc() {}      →  pub fn public_func:   // @migrate: renamed to snake_case
func privateFunc() {}     →  fn private_func:

type PublicStruct struct { →  pub type PublicStruct = {
    ExportedField int         pub exported_field: i32,
    unexported    int         unexported: i32,
}
```

Go uses PascalCase for public, camelCase for private.
With uses `pub` keyword. Convert names to snake_case.
Flag the renames so the programmer can update call sites.

#### Comments

```go
// line comment            →  // line comment
/* block comment */        →  // block comment     // @migrate: block → line
// Package doc comment     →  /// module doc
```

#### Semicolons

Go inserts them automatically. Nothing to strip.

---

### Tier 2: Semantic Translations (automated with caveats)

#### Goroutines → async tasks

```go
go doWork(arg)
go func() { heavy() }()

// With
spawn doWork(arg)
spawn heavy()
// @migrate: goroutine → With spawn (fire-and-forget fiber)
```

`go f()` → `spawn f()`. With's `spawn` creates a fiber
on the built-in scheduler, same as Go's goroutine on the
Go scheduler.

#### Channels

```go
ch := make(chan int, 10)
ch <- 42
val := <-ch
close(ch)

select {
case msg := <-ch1:
    handle(msg)
case ch2 <- response:
    sent()
case <-time.After(5 * time.Second):
    timeout()
}

// With
let (tx, rx) = chan[i32](10)
tx.send(42).await
let val = rx.recv().await
tx.close()

select await:
    msg = rx1.recv() -> handle(msg)
    _ = tx2.send(response) -> sent()
    _ = sleep(5.seconds()) -> timeout()
```

`make(chan T, n)` → `chan[T](n)` (returns `(Sender, Receiver)` pair).
`ch <- val` → `tx.send(val).await`.
`<-ch` → `rx.recv().await`.
`close(ch)` → `tx.close()`.
`select` → `select await:`.

**Unbuffered channels:**
```go
ch := make(chan int)       →  let (tx, rx) = chan[i32](0)
// @migrate: unbuffered channel — verify With supports capacity 0
```

#### `sync.Mutex`

```go
var mu sync.Mutex
mu.Lock()
defer mu.Unlock()
// critical section

// With
var mu = Mutex.new(data)
with mu.lock() as mut data:
    // critical section
// @migrate: Go Mutex protects by convention. With Mutex wraps the data.
// The protected data must be moved into the Mutex.
```

Go mutexes protect data by convention (the lock and data are
separate). With mutexes wrap the data (`Mutex[T]`). This
requires restructuring — flag.

#### `sync.WaitGroup`

```go
var wg sync.WaitGroup
for _, item := range items {
    wg.Add(1)
    go func(item Item) {
        defer wg.Done()
        process(item)
    }(item)
}
wg.Wait()

// With
let tasks = items.map(item => spawn process(item))
await_all(tasks)
// @migrate: WaitGroup → await_all on task list
```

`WaitGroup` pattern → collect tasks, `await_all`.

#### `context.Context`

```go
func fetch(ctx context.Context, url string) ([]byte, error) {
    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return nil, err
    }
    // ...
}

// With
async fn fetch(ctx: &Context, url: str) -> Result[Vec[u8], Error]:
    // @migrate: context.Context → With std.context.Context
    // Same concept: cancellation + deadline + values
    let req = http.get(url).await?
    // ...
```

Go's `context.Context` maps directly to With's planned
`std.context.Context` (same design: cancellation, deadlines,
values, tree propagation).

#### Error types

```go
type NotFoundError struct {
    Name string
}

func (e *NotFoundError) Error() string {
    return fmt.Sprintf("%s not found", e.Name)
}

var ErrNotFound = errors.New("not found")

fmt.Errorf("failed to open %s: %w", path, err)

// With
type NotFoundError = {
    name: str,
}

impl Error for NotFoundError:
    fn message(self: &Self) -> str: f"{self.name} not found"

let ERR_NOT_FOUND = Error.new("not found")

wrap(err, f"failed to open {path}")
// @migrate: Go error wrapping → With wrap() from std.errors
```

Go's `error` interface → With's `Error` trait.
`errors.New("msg")` → `Error.new("msg")`.
`fmt.Errorf("...: %w", err)` → `wrap(err, "...")`.
`errors.Is(err, target)` → `errors.is(err, target)`.
`errors.As(err, &target)` → `errors.downcast(err)`.

#### Method sets and pointer receivers

```go
func (p Point) Distance() float64 { ... }   // value receiver
func (p *Point) Scale(f float64) { ... }     // pointer receiver

// With
fn Point.distance(self: &Self) -> f64: ...   // borrow
fn Point.scale(self: &mut Self, f: f64): ... // mutable borrow
```

Value receiver → `self: &Self` (borrow, since Go copies anyway
and most value receivers just read).
Pointer receiver → `self: &mut Self` (mutable borrow).
Flag value receivers that mutate (rare but legal in Go — the
mutation is lost).

#### Struct embedding

```go
type Animal struct {
    Name string
}

func (a Animal) Speak() string { return "..." }

type Dog struct {
    Animal
    Breed string
}

// With
type Animal = {
    name: str,
}

impl Animal:
    fn speak(self: &Self) -> str: "..."

type Dog = {
    animal: Animal,    // @migrate: embedding → explicit field
    breed: str,
}

// @migrate: Go embedding delegates methods automatically.
// In With, either:
//   1. Manually delegate: fn Dog.speak(self: &Self) -> str: self.animal.speak()
//   2. Use a trait: trait Speaker: fn speak(self: &Self) -> str
//      impl Speaker for Dog: fn speak(self: &Self) -> str: self.animal.speak()
```

Go embedding → explicit named field. Method delegation must be
manual or trait-based. Flag with explanation.

#### Type assertions

```go
val, ok := x.(string)
if ok { use(val) }

switch v := x.(type) {
case string: useString(v)
case int: useInt(v)
}

// With
// @migrate: type assertion — With uses pattern matching on enums
// If x is a trait object: match x: ...
// If x was interface{}: see Tier 3
```

Type assertions on trait objects → pattern matching.
Type assertions on `interface{}` → flag (see Tier 3).

#### Init functions

```go
func init() {
    registerHandler("foo", fooHandler)
}

// With
// @migrate: Go init() — no direct equivalent.
// With does not have implicit init functions.
// Move initialization to explicit setup or module-level const/let.
```

Flag. With doesn't have `init()`.

#### Blank identifier

```go
_ = potentiallyUnused()
for _, v := range items { ... }

// With
let _ = potentiallyUnused()
for v in items: ...
```

`_ =` → `let _ =`. Range with `_` index → drop the index.

---

### Tier 3: Structural Flags (cannot auto-translate)

#### `interface{}` / `any`

```go
func process(data interface{}) {
    switch v := data.(type) {
    case string: handleString(v)
    case int: handleInt(v)
    default: handleOther(v)
    }
}

// With
// @migrate: interface{}/any — With has no universal base type.
// Options:
//   1. Use a discriminant enum: type Data = | Str(str) | Int(i32) | Other
//   2. Use a trait: fn process(data: &dyn Processable)
//   3. Use generics: fn process[T](data: T)
// Choose based on the actual set of types used.
```

Go's `interface{}` is a universal type. With doesn't have one.
The fix depends on context:
- Known type set → enum
- Behavioral contract → trait
- Parametric → generic

#### Interfaces (implicit satisfaction)

```go
type Reader interface {
    Read(p []byte) (n int, err error)
}

// Any type with a Read method satisfies Reader — no declaration needed.

// With
trait Reader:
    fn read(self: &mut Self, buf: &mut [u8]) -> Result[i32, Error]

// Types must explicitly impl Reader
// @migrate: Go interfaces are implicit. With traits are explicit.
// Add `impl Reader for YourType:` where needed.
```

Go interfaces are satisfied implicitly (structural typing).
With traits require explicit `impl`. The tool can detect which
types satisfy which interfaces (by matching method signatures)
and generate `impl` declarations. This is heuristic — flag.

#### Goroutine leak patterns

```go
func search(query string) []Result {
    ch := make(chan Result)
    for _, source := range sources {
        go func(s Source) {
            ch <- s.Search(query)
        }(source)
    }
    var results []Result
    for range sources {
        results = append(results, <-ch)
    }
    return results
}

// With
// @migrate: goroutine fan-out — verify all spawned fibers are joined.
// With fibers that are abandoned without await may leak.
// Use await_all:
async fn search(query: str) -> Vec[Result]:
    let tasks = sources.map(s => spawn s.search(query))
    await_all(tasks)
```

Go can leak goroutines (they get GC'd eventually or run to
completion). With fibers must be explicitly awaited or cancelled.
Flag fan-out patterns.

#### Reflection (`reflect` package)

```go
v := reflect.ValueOf(x)
t := reflect.TypeOf(x)

// With
// @migrate: reflect — With has no runtime reflection.
// Use generics, traits, or comptime for type-based dispatch.
```

No equivalent. Flag.

#### `unsafe` package

```go
p := unsafe.Pointer(&x)
size := unsafe.Sizeof(x)

// With
let p = &x as *mut c_void
let size = sizeof[T]()
// @migrate: unsafe.Pointer → raw pointer cast (in unsafe block)
```

`unsafe.Pointer` → raw pointer casts in `unsafe`. `unsafe.Sizeof`
→ `sizeof[T]()`.

#### CGo

```go
// #include <stdio.h>
// #include <stdlib.h>
import "C"

func main() {
    cs := C.CString("hello")
    defer C.free(unsafe.Pointer(cs))
    C.puts(cs)
}

// With
c_import("<stdio.h>")
c_import("<stdlib.h>")

fn main:
    let cs = c_string("hello")
    defer free(cs as *mut c_void)
    puts(cs)
// @migrate: CGo → With c_import (direct equivalent)
```

`import "C"` → `c_import(...)`. `C.func()` → `func()` (C
functions are in scope after c_import). The mapping is close.

#### Generics (Go 1.18+)

```go
func Map[T, U any](s []T, f func(T) U) []U {
    result := make([]U, len(s))
    for i, v := range s {
        result[i] = f(v)
    }
    return result
}

// With
fn map_slice[T, U](s: &Vec[T], f: fn(&T) -> U) -> Vec[U]:
    var result = Vec[U].with_capacity(s.len())
    for v in s:
        result.push(f(v))
    result
```

Go generics `[T any]` → With generics `[T]`.
Go constraint `comparable` → With `Eq + Hash`.
Go constraint `~int | ~float64` → With trait or flag.
Custom constraints → translate to With trait bounds or flag.

#### `go:embed`

```go
//go:embed templates/*
var templates embed.FS

// With
// @migrate: go:embed — no direct equivalent.
// Use comptime file embedding (planned) or runtime file loading.
```

#### Build tags

```go
//go:build linux && amd64

// With
// @migrate: build tags → With uses comptime if cfg.target_os == "linux":
```

---

## Quality Grades

| Level | Meaning | Typical Go code |
|---|---|---|
| **A** | Pure syntax + error handling collapse. Compiles. | CLI tools, algorithms, data processing |
| **B** | Goroutine/channel rewrite + minor edits. | Concurrent servers, pipeline patterns |
| **C** | Interface restructuring + embedding decomposition. | Framework-heavy code, middleware stacks |
| **D** | Reflection, CGo, or heavy `interface{}` usage. | ORM internals, serialization frameworks |

---

## The Error Handling Win

The single biggest improvement from Go→With migration is error
handling. Typical Go code:

```go
func processOrder(id string) (*Order, error) {
    user, err := getUser(id)
    if err != nil {
        return nil, fmt.Errorf("get user: %w", err)
    }
    order, err := findOrder(user.ID)
    if err != nil {
        return nil, fmt.Errorf("find order: %w", err)
    }
    err = validateOrder(order)
    if err != nil {
        return nil, fmt.Errorf("validate: %w", err)
    }
    err = chargePayment(order)
    if err != nil {
        return nil, fmt.Errorf("charge: %w", err)
    }
    return order, nil
}
```

After migration:

```
fn processOrder(id: str) -> Result[Order, Error]:
    let user = getUser(id)?
    let order = findOrder(user.id)?
    validateOrder(order)?
    chargePayment(order)?
    order
```

20 lines → 5 lines. Same semantics. This alone justifies the
migration for many Go programmers.

---

## Implementation Plan

### Step 1: Syntax transformer

- `func` → `fn` with receiver extraction
- Brace → indent
- Type syntax (Go types → With types)
- `:=` → `var`
- `const`/`var` declarations
- `iota` expansion
- Control flow (`if`/`for`/`switch`/`select`)
- Semicolon handling (Go auto-inserts)
- PascalCase → snake_case for functions and fields
- `nil` → `None` or `null` depending on context

**Done when:** Simple Go files produce readable With.

### Step 2: Error handling collapse

The highest-value transformation. Detect the pattern:
```
result, err := f()
if err != nil { return ..., err }
```
Collapse to `let result = f()?`.

Change return types: `(T, error)` → `Result[T, Error]`.
Remove `nil` error returns → implicit Ok wrapping.
`fmt.Errorf("...: %w", err)` → `wrap(err, "...")`.

**Done when:** Go error boilerplate collapses to `?` chains.

### Step 3: Goroutine and channel rewriter

- `go f()` → `spawn f()`
- `make(chan T, n)` → `chan[T](n)` with sender/receiver split
- `ch <- val` → `tx.send(val).await`
- `<-ch` → `rx.recv().await`
- `select` → `select await:`
- `sync.WaitGroup` → `await_all`

**Done when:** Concurrent Go code produces With async code.

### Step 4: Standard library mapping

- `fmt.*` → f-strings and `print`
- `strings.*` → `str` methods
- `strconv.*` → parse/format methods
- `os.*` → `std.fs` / `std.process`
- `io.*` → `std.io`
- `sync.*` → `std.sync`
- `context.*` → `std.context`
- `encoding/json.*` → `std.json`
- `net/http.*` → flag (framework-level)

**Done when:** Common stdlib calls produce correct With calls.

### Step 5: Interface → trait generation

Detect Go interfaces and which types satisfy them. Emit
explicit `impl Trait for Type:` blocks. Heuristic: match
method name + signature.

**Done when:** Implicit interface satisfaction is made explicit.

### Step 6: Flag generator and grading

Flag: `interface{}`, `reflect`, `unsafe`, embedding,
`recover`, `init()`, naked returns, `go:embed`, build tags,
CGo, implicit interface satisfaction.

Grade each file A–D.

### Step 7: Multi-file and package rewriting

Handle Go package structure → With module structure.
`import "pkg/path"` → `use path`.
Internal/external packages → module visibility.

**Done when:** `with migrate go ./...` translates a full Go
project.

---

## Philosophy

The migration pitch to Go developers:

> "You already write simple, explicit code. With keeps that
> simplicity and adds three things Go doesn't have:
>
> 1. **The `?` operator.** Your 20-line error-handling functions
>    become 5 lines. Same semantics, one-fifth the noise.
>
> 2. **A real type system.** Generics that work. Sum types
>    instead of `interface{}`. Pattern matching instead of type
>    switches.
>
> 3. **No garbage collector.** Same performance profile as C,
>    with memory safety. Your latency P99 becomes predictable.
>
> Your goroutines become fibers. Your channels stay channels.
> Your `defer` stays `defer`. Your `context.Context` stays
> `Context`. You already know how to write With — you just
> need to stop writing `if err != nil`."
