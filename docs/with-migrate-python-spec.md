# `with migrate python` — Python-to-With Source Translator

**Near-complete migration from Python to With.**

Python and With share more surface syntax than any other language pair
in this family of specs: indentation-based blocks, `and`/`or`/`not`,
f-strings, `for x in iter`, `while cond`, `print()`. Well-typed Python
(using PEP 484/526 type hints) migrates with almost no human review.
Untyped Python gets best-effort translation with typed stubs for every
external dependency and `// @migrate:` flags only where type inference
genuinely fails.

The key differentiator: **dependency stub generation**. Python code
routinely imports dozens of third-party packages. Rather than refusing
to translate, the migrator scans every usage of every imported module
and generates typed stub files that panic at runtime. The translated
code compiles immediately. Filling in stubs is a defined,
incremental task, not an open-ended mystery.

---

## Design Goals

1. **Near-100% success on typed Python.** Every Python file with
   complete PEP 484 type hints produces a compilable With file.
   No `comptime_error` stubs. No "manual fixup required" for typed
   code.

2. **Best-effort on untyped Python.** Missing type annotations get
   inferred from usage context, assignment targets, and return paths.
   When inference fails, the type is `// @migrate: unknown type —
   replace with concrete type`. The file still compiles if the user
   accepts the placeholder.

3. **Dependency stubs, not failures.** Any import that doesn't map
   to a With stdlib module gets a generated `<module>_stubs.w` file.
   Stubs are typed where possible, `PyObject` where not. They panic
   at runtime with a clear message. The translated source compiles
   against them.

4. **Idiomatic output.** The migrator doesn't just rename keywords.
   Python classes become structs with `extend` blocks. Comprehensions
   become iterator chains. Exception handling becomes `Result[T,E]`
   with `match`. The output reads like With, not like Python
   transliterated.

5. **One command.** `with migrate python src/` translates an entire
   Python package.

---

## Usage

```
with migrate python foo.py                   # single file → foo.w
with migrate python foo.py -o bar.w          # explicit output path
with migrate python src/ -o out/             # directory mode
with migrate python src/ --check             # dry run: exit 1 if changes needed
with migrate python src/ --diff              # unified diff to stdout
with migrate python src/ --stats             # translation statistics
with migrate python src/ --no-stubs          # skip stub generation
with migrate python src/ --stub-dir stubs/   # write stubs to specific directory
```

**Modes:**
- `write` (default) — write `.w` files and `*_stubs.w` stub files
- `check` — report what would change, exit nonzero if any
- `diff` — print unified diff to stdout

**Options:**
- `-o <path>` — output path (file or directory)
- `--no-stubs` — skip stub file generation (unresolved imports become error comments)
- `--stub-dir <dir>` — write generated stubs to a specific directory
- `--typed-only` — emit `// @migrate:` for all missing type annotations instead of inferring
- `--stats` — print per-file statistics (flags, stubs generated, etc.)
- `--python <path>` — path to Python interpreter for type introspection (optional)

---

## Architecture

```
Python source file(s)
    ↓ Phase 1: Parse
Python AST (via tree-sitter-python, no Python runtime needed)
    ↓ Phase 2: Import analysis
Classify each import: stdlib-mapped | stub-needed | internal
    ↓ Phase 3: Type annotation extraction
Collect all PEP 484/526 annotations; build per-function type maps
    ↓ Phase 4: Usage scan (for untyped code + stubs)
Per-module: collect all call sites, attribute accesses, arg shapes
    ↓ Phase 5: Type inference
Propagate known types through assignments, calls, returns
    ↓ Phase 6: Stub generation
For each external module: emit <module>_stubs.w with inferred types
    ↓ Phase 7: Translation
Python AST → With AST:
  ├─ Declarations (functions, classes, constants, globals)
  ├─ Expressions (operators, calls, comprehensions, lambdas)
  └─ Statements (control flow, assignments, exceptions, context managers)
    ↓ Phase 8: Emit
.w source text with imports, types, functions, stub references
    ↓ Phase 9: Cleanup pass (optional)
Remove unnecessary parens, simplify trivial Result chains
```

### Parser

The migrator uses **tree-sitter-python** for parsing — a pure grammar
that needs no Python runtime, handles all Python 3.10+ syntax, and
produces a concrete syntax tree. The migrator ships with tree-sitter
as a statically linked dependency. It does not exec `python3`.

---

## Translation Rules

### Tier 1: Mechanical Syntax (100% automated)

These translations are always correct. No flags, no caveats.

#### Comments

```python
# This is a comment
```
```
// This is a comment
```

Inline comments (`x = 1  # value`) → `let x = 1  // value`.

Docstrings (triple-quoted strings as first statement of a
function/class/module) are stripped and emitted as a block comment:

```python
def process(x: int) -> int:
    """Multiply x by two."""
    return x * 2
```
```
// Multiply x by two.
fn process(x: i64) -> i64:
    return x * 2
```

#### Literals and booleans

```python
True    →  true
False   →  false
None    →  (context-dependent: see §None below)
```

Integer literals, float literals, string literals, and f-strings are
unchanged. Hex (`0xFF`), octal (`0o77`), binary (`0b1010`) literals
are unchanged.

#### f-strings

Python f-strings and With f-strings use **identical syntax**. No
translation needed:

```python
name = "world"
msg = f"Hello, {name}!"
```
```
let name = "world"
let msg = f"Hello, {name}!"
```

The `!r`/`!s`/`!a` conversion suffixes are flagged:
```python
f"{x!r}"   # → // @migrate: !r conversion — replace with x.debug_str()
```

#### Operators

All arithmetic, comparison, bitwise, and assignment operators are
identical except:

| Python | With | Notes |
|---|---|---|
| `**` | `pow(base, exp)` | No `**` in With |
| `//` | `/` | Integer division; works natively on `i64` |
| `%` | `%` | Same |
| `!=` | `!=` | Same |
| `==` | `==` | Same |
| `and` | `and` | **Identical** |
| `or` | `or` | **Identical** |
| `not` | `not` | **Identical** |
| `in` | (method call, see below) | |
| `not in` | (method call, see below) | |
| `is None` | `== Option.None` | |
| `is not None` | `!= Option.None` | |

`x in collection`:
- `x in list` → `list.contains(x)`
- `x in dict` → `dict.contains_key(x)`
- `x in set` → `set.contains(x)`
- `x in str` → `str.contains(x)`

`x not in collection` → `not collection.contains(x)` (or variant above).

#### Control flow

```python
if cond:
    ...
elif cond2:
    ...
else:
    ...
```
```
if cond:
    ...
else if cond2:
    ...
else:
    ...
```

Only `elif` → `else if` changes. All indentation, `if`, `while`,
`for x in iter:`, `break`, `continue`, `return`, `pass` (dropped)
are otherwise unchanged.

#### Type annotations → With types

| Python | With |
|---|---|
| `int` | `i64` |
| `float` | `f64` |
| `bool` | `bool` |
| `str` | `str` |
| `bytes` | `Vec[u8]` |
| `list[T]` | `Vec[T]` |
| `List[T]` | `Vec[T]` |
| `dict[K, V]` | `HashMap[K, V]` |
| `Dict[K, V]` | `HashMap[K, V]` |
| `set[T]` | `HashSet[T]` |
| `Set[T]` | `HashSet[T]` |
| `tuple[A, B]` | `(A, B)` |
| `Tuple[A, B]` | `(A, B)` |
| `Optional[T]` | `Option[T]` |
| `T \| None` | `Option[T]` |
| `Union[T, U]` (non-None) | `// @migrate: union type — use enum` |
| `Any` | `// @migrate: Any — replace with concrete type` |
| `None` (return type) | *(omit return type — void)* |
| `Callable[[A, B], R]` | `(A, B) -> R` |
| `Iterator[T]` | `// @migrate: Iterator[T] — use Vec[T] or custom iter` |
| `Iterable[T]` | `Vec[T]` (with flag if not a list) |
| `Sequence[T]` | `Vec[T]` |
| `Mapping[K, V]` | `HashMap[K, V]` |
| `ClassVar[T]` | `// @migrate: class variable — use module-level let` |
| `Final[T]` | `T` (const semantics via `let`) |

#### Functions

```python
def add(a: int, b: int) -> int:
    return a + b

def greet(name: str) -> None:
    print(f"Hello, {name}")
```
```
fn add(a: i64, b: i64) -> i64:
    return a + b

fn greet(name: str):
    print(f"Hello, {name}")
```

`pass`-only function bodies are dropped (empty function body in With
is legal via returning unit).

Default arguments are preserved:
```python
def connect(host: str, port: int = 8080) -> None: ...
```
```
fn connect(host: str, port: i64 = 8080):
    ...
```

#### `None` handling

`None` has two meanings in Python:

1. **Return type `None`** — the function returns nothing. Omit the
   return type annotation entirely (With functions default to void).

2. **`None` value** — the "nothing" case of an `Optional[T]`. In With
   this is `Option[T]` with value `Option.None`. The migrator infers
   `Option[T]` from context.

```python
def find(items: list[str], target: str) -> Optional[str]:
    for item in items:
        if item == target:
            return item
    return None
```
```
fn find(items: Vec[str], target: str) -> Option[str]:
    for item in items:
        if item == target:
            return Option.Some(item)
    return Option.None
```

When `None` is returned from a function with no declared return type,
the function is inferred as void-returning and the bare `return None`
becomes `return`.

#### Lambdas

```python
double = lambda x: x * 2
add = lambda x, y: x + y
```
```
let double = x => x * 2
let add = (x, y) => x + y
```

#### `range`

```python
range(n)       →  0..n
range(a, b)    →  a..b
range(a, b, 1) →  a..b
range(a, b, step)  →  // @migrate: range with step — use explicit loop
```

#### Built-in functions

| Python | With |
|---|---|
| `len(x)` | `x.len()` |
| `print(x)` | `print(x)` |
| `print(x, end="")` | `print_no_newline(x)` |
| `print(x, file=sys.stderr)` | `eprint(x)` |
| `abs(x)` | `x.abs()` |
| `round(x)` | `x.round()` |
| `int(x)` | `x as i64` |
| `float(x)` | `x as f64` |
| `str(x)` | `x.to_str()` |
| `bool(x)` | `x != 0` (or context-appropriate) |
| `min(a, b)` | `a.min(b)` |
| `max(a, b)` | `a.max(b)` |
| `min(iter)` | `iter.min()` |
| `max(iter)` | `iter.max()` |
| `sum(iter)` | `iter.sum()` |
| `any(iter)` | `iter.any(it)` |
| `all(iter)` | `iter.all(it)` |
| `sorted(iter)` | `iter.sorted()` |
| `sorted(iter, key=fn)` | `iter.sorted_by(fn)` |
| `reversed(iter)` | `iter.rev()` |
| `enumerate(iter)` | `iter.enumerate()` |
| `zip(a, b)` | `a.zip(b)` |
| `map(f, iter)` | `iter.map(f)` |
| `filter(f, iter)` | `iter.filter(f)` |
| `isinstance(x, T)` | `x is T` (see §Pattern matching) |
| `type(x)` | `// @migrate: type() — use match or trait` |
| `id(x)` | `// @migrate: id() — no object identity in With` |
| `hash(x)` | `x.hash()` |
| `repr(x)` | `x.debug_str()` |
| `chr(n)` | `n as u8 as str` |
| `ord(c)` | `c as u8 as i64` |
| `hex(n)` | `f"{n:x}"` |
| `bin(n)` | `f"{n:b}"` |
| `oct(n)` | `f"{n:o}"` |
| `input(prompt)` | `// @migrate: input() — use std.io.read_line()` |
| `open(path, mode)` | `std.fs.open(path, mode)` |
| `exit(n)` | `exit(n)` |

#### String methods

| Python | With |
|---|---|
| `.upper()` | `.to_upper()` |
| `.lower()` | `.to_lower()` |
| `.strip()` | `.trim()` |
| `.lstrip()` | `.trim_start()` |
| `.rstrip()` | `.trim_end()` |
| `.split(sep)` | `.split(sep)` |
| `.split()` | `.split_whitespace()` |
| `.startswith(p)` | `.starts_with(p)` |
| `.endswith(s)` | `.ends_with(s)` |
| `.replace(a, b)` | `.replace(a, b)` |
| `.find(sub)` | `.find(sub)` |
| `.index(sub)` | `.find(sub).unwrap()` |
| `.count(sub)` | `.count(sub)` |
| `.join(iter)` | `iter.join(self)` |
| `.format(...)` | convert to f-string |
| `%` formatting | convert to f-string |
| `.encode()` | `.as_bytes()` |
| `.decode()` | `str.from_utf8(bytes)` |
| `.isdigit()` | `.chars().all(it.is_digit())` |
| `.isalpha()` | `.chars().all(it.is_alpha())` |
| `.isspace()` | `.trim().is_empty()` |
| `.center(w)` | `// @migrate: str.center — not in stdlib` |
| `.zfill(w)` | `f"{x:0>w}"` |

#### List methods

| Python | With |
|---|---|
| `.append(x)` | `.push(x)` |
| `.pop()` | `.pop()` |
| `.pop(i)` | `.remove(i)` |
| `.extend(other)` | `.extend(other)` |
| `.insert(i, x)` | `.insert(i, x)` |
| `.remove(x)` | `.remove_value(x)` |
| `.sort()` | `.sort()` |
| `.sort(key=fn)` | `.sort_by(fn)` |
| `.reverse()` | `.reverse()` |
| `.clear()` | `.clear()` |
| `.copy()` | `.clone()` |
| `.index(x)` | `.find_index(x).unwrap()` |
| `.count(x)` | `.count(x)` |

List indexing: `items[-1]` → `items[items.len() - 1]`.
Negative indexing is flagged when not the common `-1` pattern.

#### Dict methods

| Python | With |
|---|---|
| `.get(k)` | `.get(k)` (returns `Option[V]`) |
| `.get(k, default)` | `.get_or(k, default)` |
| `.keys()` | `.keys()` |
| `.values()` | `.values()` |
| `.items()` | `.entries()` |
| `.update(other)` | `.merge(other)` |
| `.pop(k)` | `.remove(k)` |
| `.clear()` | `.clear()` |
| `.copy()` | `.clone()` |
| `.setdefault(k, v)` | `.get_or_insert(k, v)` |
| `k in d` | `d.contains_key(k)` |
| `del d[k]` | `d.remove(k)` |

#### Set methods

| Python | With |
|---|---|
| `.add(x)` | `.insert(x)` |
| `.remove(x)` | `.remove(x)` |
| `.discard(x)` | `.remove(x)` |
| `.contains(x)` / `x in s` | `.contains(x)` |
| `.union(other)` | `.union(other)` |
| `.intersection(other)` | `.intersection(other)` |
| `.difference(other)` | `.difference(other)` |
| `.issubset(other)` | `.is_subset(other)` |

#### Comprehensions

List comprehensions → iterator chains:

```python
[f(x) for x in items]
```
```
items.map(x => f(x)).collect()
```

```python
[x for x in items if cond(x)]
```
```
items.filter(x => cond(x)).collect()
```

```python
[f(x) for x in items if cond(x)]
```
```
items.filter(x => cond(x)).map(x => f(x)).collect()
```

Nested comprehensions are expanded step by step:

```python
[x for row in matrix for x in row]
```
```
matrix.flat_map(row => row).collect()
```

Dict comprehensions:

```python
{k: v for k, v in pairs}
```
```
pairs.map((k, v) => (k, v)).collect_to_map()
```

```python
{k: f(v) for k, v in d.items()}
```
```
d.entries().map((k, v) => (k, f(v))).collect_to_map()
```

Set comprehensions:

```python
{f(x) for x in items}
```
```
items.map(x => f(x)).collect_to_set()
```

Generator expressions used directly in function calls are converted
to the equivalent iterator chain:

```python
sum(x * x for x in items)
```
```
items.map(x => x * x).sum()
```

#### Classes — dataclasses and simple structs

Python `@dataclass` is a direct struct:

```python
from dataclasses import dataclass

@dataclass
class Point:
    x: float
    y: float
    z: float = 0.0
```
```
type Point = {
    x: f64,
    y: f64,
    z: f64,
}

extend Point:
    fn new(x: f64, y: f64, z: f64 = 0.0) -> Point:
        Point { x, y, z }
```

#### Classes — general

Full class translation:

```python
class Rectangle:
    def __init__(self, width: float, height: float):
        self.width = width
        self.height = height

    def area(self) -> float:
        return self.width * self.height

    def scale(self, factor: float) -> None:
        self.width *= factor
        self.height *= factor

    @staticmethod
    def unit() -> "Rectangle":
        return Rectangle(1.0, 1.0)

    def __str__(self) -> str:
        return f"Rectangle({self.width}, {self.height})"
```
```
type Rectangle = {
    width: f64,
    height: f64,
}

extend Rectangle:
    fn new(width: f64, height: f64) -> Rectangle:
        Rectangle { width, height }

    fn area(self: &Rectangle) -> f64:
        self.width * self.height

    fn scale(self: &mut Rectangle, factor: f64):
        self.width *= factor
        self.height *= factor

    fn unit() -> Rectangle:
        Rectangle.new(1.0, 1.0)

    fn to_str(self: &Rectangle) -> str:
        f"Rectangle({self.width}, {self.height})"
```

**Mutability inference:** If any method assigns to `self.field`, that
method gets `self: &mut Self`. Otherwise `self: &Self`.

**Field discovery:** If `__init__` assigns `self.field = value`, that
field is added to the struct with the type of `value`. Annotated fields
in the class body take precedence.

#### Dunder methods → trait impls

| Python | With |
|---|---|
| `__str__` | `fn to_str(self: &Self) -> str` in `extend` |
| `__repr__` | `fn debug_str(self: &Self) -> str` in `extend` |
| `__len__` | `fn len(self: &Self) -> usize` in `extend` |
| `__eq__` | `impl Eq for Type:` |
| `__ne__` | derived from `Eq` |
| `__lt__`, `__le__`, `__gt__`, `__ge__` | `impl Ord for Type:` |
| `__add__` | `impl Add for Type:` |
| `__sub__` | `impl Sub for Type:` |
| `__mul__` | `impl Mul for Type:` |
| `__hash__` | `impl Hash for Type:` |
| `__contains__` | `fn contains(self: &Self, item: T) -> bool` |
| `__iter__` | `fn iter(self: &Self) -> ...` (flag if complex) |
| `__getitem__` | `fn get(self: &Self, idx: T) -> V` |
| `__setitem__` | `fn set(self: &mut Self, idx: T, val: V)` |
| `__bool__` | `fn is_truthy(self: &Self) -> bool` |
| `__enter__`/`__exit__` | `// @migrate: context manager — implement WithBlock trait` |

#### Inheritance — abstract base → trait

```python
from abc import ABC, abstractmethod

class Shape(ABC):
    @abstractmethod
    def area(self) -> float: ...

    @abstractmethod
    def perimeter(self) -> float: ...
```
```
trait Shape:
    fn area(self: &Self) -> f64
    fn perimeter(self: &Self) -> f64
```

Implementations of abstract classes become `impl`:

```python
class Circle(Shape):
    def __init__(self, r: float):
        self.r = r
    def area(self) -> float:
        return 3.14159 * self.r * self.r
    def perimeter(self) -> float:
        return 2 * 3.14159 * self.r
```
```
type Circle = { r: f64 }

impl Shape for Circle:
    fn area(self: &Circle) -> f64:
        3.14159 * self.r * self.r
    fn perimeter(self: &Circle) -> f64:
        2.0 * 3.14159 * self.r
```

#### typing.Protocol → trait

```python
from typing import Protocol

class Serializable(Protocol):
    def to_json(self) -> str: ...
    def from_json(data: str) -> "Serializable": ...
```
```
trait Serializable:
    fn to_json(self: &Self) -> str
    fn from_json(data: str) -> Self
```

#### TypeVar and Generic → type parameters

```python
from typing import TypeVar, Generic

T = TypeVar('T')

class Stack(Generic[T]):
    def __init__(self) -> None:
        self._items: list[T] = []

    def push(self, item: T) -> None:
        self._items.append(item)

    def pop(self) -> Optional[T]:
        if not self._items:
            return None
        return self._items.pop()
```
```
type Stack[T] = {
    items: Vec[T],
}

extend Stack[T]:
    fn new() -> Stack[T]:
        Stack { items: Vec.new() }

    fn push(self: &mut Stack[T], item: T):
        self.items.push(item)

    fn pop(self: &mut Stack[T]) -> Option[T]:
        if self.items.is_empty():
            return Option.None
        Option.Some(self.items.pop())
```

#### NamedTuple → struct

```python
from typing import NamedTuple

class Point(NamedTuple):
    x: float
    y: float
```
```
type Point = { x: f64, y: f64 }
```

#### Tuple unpacking and multiple assignment

```python
a, b = func()
x, y, z = point
first, *rest = items
```
```
let (a, b) = func()
let (x, y, z) = point
// @migrate: starred unpacking — use let first = items[0]; let rest = items.slice(1..)
```

Swap:
```python
a, b = b, a
```
```
let __tmp = a
a = b
b = __tmp
```

---

### Tier 2: Semantic Translations (automated with caveats)

These translations are correct in the common case but may need
review for unusual patterns. Each emits a brief comment explaining
the transformation.

#### Exception handling → Result

```python
def parse_int(s: str) -> int:
    try:
        return int(s)
    except ValueError as e:
        raise ValueError(f"bad input: {s}")
```
```
fn parse_int(s: str) -> Result[i64, str]:
    match s.parse_i64():
        Ok(n) -> Ok(n)
        Err(_) -> Err(f"bad input: {s}")
```

General `try/except`:

```python
try:
    result = risky_operation()
except SomeError as e:
    handle_error(e)
except AnotherError:
    handle_other()
finally:
    cleanup()
```
```
// @migrate: exception → Result: review error types
defer cleanup()
match risky_operation():
    Ok(result) ->
        // original try body continues here
    Err(e) ->
        match e:
            SomeError(e) -> handle_error(e)
            AnotherError -> handle_other()
            _ -> return Err(e)
```

`raise` → `return Err(...)` when inside a `Result`-returning function,
`panic(...)` when the error is unrecoverable. The migrator defaults to
`return Err(...)` and flags when the function's return type needs to
change.

```python
raise ValueError("invalid input")
```
```
return Err("invalid input")  // @migrate: was raise ValueError
```

`finally` → `defer` (executed on block exit, same semantics for
non-exception cleanup):

```python
f = open(path)
try:
    data = f.read()
finally:
    f.close()
```
```
let f = std.fs.open(path)
defer f.close()
let data = f.read()
```

#### Context managers (`with`)

```python
with open(path) as f:
    data = f.read()
```
```
// @migrate: context manager — using defer pattern
let f = std.fs.open(path)
defer f.close()
let data = f.read()
```

When the type implements `WithBlock` (a With trait for RAII resource
management), the migrator emits a proper `with` statement instead.

#### String formatting — old style

```python
"Hello, %s! You are %d years old." % (name, age)
"Value: %.2f" % x
```
```
f"Hello, {name}! You are {age} years old."
f"Value: {x:.2f}"
```

`.format()`:

```python
"Hello, {}! You are {} years old.".format(name, age)
"{key}={value}".format(key=k, value=v)
```
```
f"Hello, {name}! You are {age} years old."
f"{k}={v}"
```

#### Walrus operator `:=`

```python
if (n := len(items)) > 10:
    print(f"too many: {n}")
```
```
// @migrate: walrus — hoisted binding
let n = items.len()
if n > 10:
    print(f"too many: {n}")
```

#### Generators — simple cases

Simple generator functions that build a sequence are converted to
Vec builders:

```python
def squares(n: int) -> Iterator[int]:
    for i in range(n):
        yield i * i
```
```
fn squares(n: i64) -> Vec[i64]:
    var result: Vec[i64] = Vec.new()
    for i in 0..n:
        result.push(i * i)
    result
```

Complex generators (`yield from`, generator pipelines, infinite
generators) are flagged:

```python
def fibonacci():
    a, b = 0, 1
    while True:
        yield a
        a, b = b, a + b
```
```
// @migrate: infinite generator — implement as custom iterator type
fn fibonacci() -> Vec[i64]:
    panic("stub: infinite generator — implement custom iterator")
```

#### `async def` / `.await`

```python
async def fetch(url: str) -> str:
    response = await client.get(url)
    return await response.text()
```
```
async fn fetch(url: str) -> str:
    let response = client.get(url).await
    response.text().await
```

`async for` and `async with` are flagged if no direct mapping exists.

#### Decorators

| Python decorator | With equivalent |
|---|---|
| `@staticmethod` | Free function in `extend` block (no `self`) |
| `@classmethod` | Static method — drop `cls` param |
| `@property` (getter only) | Regular method `fn name(self: &Self) -> T` |
| `@property` + `@x.setter` | `// @migrate: property with setter — use explicit get/set methods` |
| `@abstractmethod` | Trait method with no body |
| `@dataclass` | `type Foo = { ... }` (see §Classes) |
| `@functools.lru_cache` | `// @migrate: memoize — implement or use std.cache` |
| `@functools.wraps` | Drop — no decorator protocol in With |
| Custom decorator | `// @migrate: decorator {name} — translate manually` |

#### `isinstance` → match / type check

```python
if isinstance(x, int):
    ...
elif isinstance(x, str):
    ...
```
```
match x:
    i64(_) ->
        ...
    str(_) ->
        ...
```

When the type is a trait/ABC:

```python
if isinstance(shape, Circle):
    area = shape.area()
```
```
if x is Circle:
    let shape = x as Circle
    let area = shape.area()
```

#### `*args` and `**kwargs`

```python
def log(*args, **kwargs):
    print(args, kwargs)
```
```
// @migrate: variadic *args — replace with Vec[T] parameter
// @migrate: keyword **kwargs — replace with struct parameter
fn log(args: Vec[str]):  // @migrate: inferred as str; verify
    print(args)
```

#### `global` and `nonlocal`

```python
count = 0
def increment():
    global count
    count += 1
```
```
var count: i64 = 0  // module-level

fn increment():
    // @migrate: global — use module-level var directly
    count += 1
```

`nonlocal` in nested functions:

```python
def outer():
    x = 0
    def inner():
        nonlocal x
        x += 1
    inner()
    return x
```
```
// @migrate: nonlocal — closures cannot capture &mut; hoist to shared state or return value
fn outer() -> i64:
    var x: i64 = 0
    // inner() captured nonlocal x — refactor to pass x as &mut or return new value
    x
```

#### Slicing

```python
items[a:b]       →  items.slice(a..b)
items[a:]        →  items.slice(a..)
items[:b]        →  items.slice(..b)
items[:]         →  items.clone()
items[::2]       →  // @migrate: step slice — use explicit loop
items[::-1]      →  items.rev().collect()
```

#### Multiple inheritance (concrete)

Single inheritance from a concrete base class is the most common
case and is treated as composition:

```python
class LoggedList(list):
    def append(self, x):
        print(f"appending {x}")
        super().append(x)
```
```
type LoggedList[T] = {
    inner: Vec[T],
}

extend LoggedList[T]:
    fn append(self: &mut LoggedList[T], x: T):
        print(f"appending {x}")
        self.inner.push(x)  // @migrate: super().append → inner.push
```

Multiple concrete bases:

```python
class C(A, B):
    pass
```
```
// @migrate: multiple inheritance — not supported; use composition or trait impls
type C = {
    a: A,
    b: B,
}
```

---

### Tier 3: Flagged Constructs

These constructs have no direct translation. The migrator emits the
original code as a comment and a `// @migrate:` flag explaining the
issue. The file still compiles (the flagged block is commented out).

| Construct | Flag message |
|---|---|
| Metaclasses | `@migrate: metaclass — no equivalent; refactor using traits` |
| `setattr(obj, name, val)` | `@migrate: setattr — no runtime reflection; use explicit field or HashMap` |
| `getattr(obj, name)` | `@migrate: getattr — no runtime reflection` |
| `hasattr(obj, name)` | `@migrate: hasattr — no runtime reflection` |
| `eval(expr)` | `@migrate: eval — no eval in With` |
| `exec(code)` | `@migrate: exec — no exec in With` |
| `__getattr__` / `__setattr__` | `@migrate: dynamic attribute access — use HashMap or trait` |
| `__slots__` | Drop — structs are already slot-based |
| `super()` with concrete inheritance | `@migrate: super() — use self.base_field.method()` |
| Complex `yield from` | `@migrate: yield from — implement as custom iterator` |
| `send()` to generator | `@migrate: generator.send — no coroutine send; use channels` |
| Threading | `@migrate: threading — use fibers (std.fiber)` |
| `asyncio` event loop | `@migrate: asyncio event loop — use With async runtime directly` |
| Dynamic class creation (`type(...)`) | `@migrate: dynamic class — no equivalent` |
| Big integer arithmetic | `@migrate: Python int is arbitrary precision; i64 may overflow` |
| `__del__` (destructor) | `@migrate: __del__ — use defer at call site` |
| `__class_getitem__` | `@migrate: __class_getitem__ — use generic type params` |
| Negative list indexing (non -1) | `@migrate: negative index {n} — use items.len() - {abs(n)}` |
| `dict` preserving insertion order (relied on) | Note added: With HashMap preserves insertion order |
| Implicit string concatenation (`"a" "b"`) | Joined to `"ab"` automatically |

---

## Dependency Stub Generation

This is the key feature that makes Python migration practical.
Python packages import dozens of third-party modules. Without stubs,
the translated code won't compile. With stubs, it compiles immediately
and stubs are filled in incrementally.

### Algorithm

**Step 1: Classify imports.**

Parse every `import` and `from ... import` statement. Classify each
module as:
- **stdlib-mapped** — the module has a direct With stdlib equivalent
  (see §Standard Library Mapping)
- **internal** — the module is another `.py` file in the same package
  being translated
- **stub-needed** — everything else (PyPI packages, unmapped stdlib)

**Step 2: Scan all usages for stub-needed modules.**

For each stub-needed module, walk the entire AST of every file that
imports it. Collect:

- **Function calls:** `module.func(arg1, arg2)` — record name, arity,
  argument types (from annotations or inference), return type (from
  usage context)
- **Class instantiation:** `module.Class(...)` — treated as constructor
  call; records field types from `__init__` if visible
- **Method calls on instances:** `obj.method(...)` where `obj: module.Class`
- **Attribute access:** `module.CONSTANT` or `obj.field`
- **Submodule imports:** `from module.sub import thing`

**Step 3: Infer types from evidence.**

For each collected usage, infer types from:

1. **Explicit type hints** (highest priority): `x: requests.Response = requests.get(url)`
2. **Return value usage**: if `resp.status_code` is compared to `200`,
   infer `status_code: i64`
3. **Argument types**: if `requests.get(url)` is called with `url: str`,
   record `url: str`
4. **Assignment targets**: `data: bytes = resp.content` infers `content: Vec[u8]`
5. **Fallback**: `PyObject` (opaque struct representing unknown Python object)

**Step 4: Generate stub file.**

Emit `<module>_stubs.w` (or `<module/sub>_stubs.w` for submodules).
Structure:

```
// Auto-generated stubs for Python module: <module>
// Generated by: with migrate python
// Fill in real implementations or replace with With bindings.

@[stub("module")]
```

For each free function:
```
@[stub("module")]
fn module_funcname(arg1: T1, arg2: T2) -> ReturnType:
    panic(f"stub: module.funcname — implement or bind native")
```

For each class, an opaque struct + extend block:
```
@[stub("module")]
type ModuleClassName = {
    // opaque — fields inferred from usage
    _handle: i64,
}

@[stub("module")]
extend ModuleClassName:
    fn new(arg1: T1) -> ModuleClassName:
        panic("stub: module.ClassName.__init__ — implement or bind native")
    fn method_name(self: &ModuleClassName, arg: T) -> ReturnType:
        panic(f"stub: module.ClassName.method_name — implement or bind native")
```

For constants/attributes:
```
@[stub("module")]
fn module_constant_name() -> T:
    panic("stub: module.CONSTANT — implement or bind native")
```

**Step 5: Import stubs in translated file.**

At the top of each translated `.w` file, add:
```
import "<module>_stubs.w"
```

### Worked example

**Input Python: `fetcher.py`**

```python
import requests
import numpy as np
from typing import Optional

def fetch_json(url: str, timeout: int = 30) -> Optional[dict]:
    try:
        resp = requests.get(url, timeout=timeout)
        resp.raise_for_status()
        return resp.json()
    except requests.exceptions.RequestException as e:
        print(f"fetch failed: {e}", file=sys.stderr)
        return None

def mean_values(data: list[float]) -> float:
    arr = np.array(data)
    return float(np.mean(arr))
```

**Phase 2 — Import classification:**
- `requests` → stub-needed
- `numpy` (as `np`) → stub-needed

**Phase 3/4 — Usage scan for `requests`:**
- `requests.get(url, timeout=timeout)` → `fn requests_get(url: str, timeout: i64) -> RequestsResponse`
- `resp.raise_for_status()` → `fn raise_for_status(self: &RequestsResponse)`
- `resp.json()` → `fn json(self: &RequestsResponse) -> HashMap[str, PyObject]`
- `requests.exceptions.RequestException` → opaque exception type

**Usage scan for `numpy`:**
- `np.array(data)` where `data: list[float]` → `fn numpy_array_f64(data: Vec[f64]) -> NumpyNdarray`
- `np.mean(arr)` where return converted to `float` → `fn numpy_mean(arr: NumpyNdarray) -> f64`

**Generated `requests_stubs.w`:**

```
// Auto-generated stubs for Python module: requests
// Generated by: with migrate python fetcher.py

@[stub("requests")]
type RequestsResponse = {
    _handle: i64,
}

@[stub("requests")]
extend RequestsResponse:
    fn raise_for_status(self: &RequestsResponse):
        panic("stub: requests.Response.raise_for_status — implement or bind native")

    fn json(self: &RequestsResponse) -> HashMap[str, PyObject]:
        panic("stub: requests.Response.json — implement or bind native")

    fn status_code(self: &RequestsResponse) -> i64:
        panic("stub: requests.Response.status_code — implement or bind native")

@[stub("requests")]
fn requests_get(url: str, timeout: i64 = 30) -> RequestsResponse:
    panic("stub: requests.get — implement or bind native")
```

**Generated `numpy_stubs.w`:**

```
// Auto-generated stubs for Python module: numpy

@[stub("numpy")]
type NumpyNdarray = {
    _handle: i64,
}

@[stub("numpy")]
fn numpy_array_f64(data: Vec[f64]) -> NumpyNdarray:
    panic("stub: numpy.array — implement or bind native")

@[stub("numpy")]
fn numpy_mean(arr: NumpyNdarray) -> f64:
    panic("stub: numpy.mean — implement or bind native")
```

**Translated `fetcher.w`:**

```
// Generated by: with migrate python fetcher.py
// Source: fetcher.py (18 lines, 2 stubs generated)

import "requests_stubs.w"
import "numpy_stubs.w"

fn fetch_json(url: str, timeout: i64 = 30) -> Option[HashMap[str, PyObject]]:
    // @migrate: exception → Result: was try/except requests.exceptions.RequestException
    match requests_get(url, timeout):
        resp ->
            resp.raise_for_status()
            Option.Some(resp.json())
        // @migrate: error path — bind requests.exceptions.RequestException to Err variant

fn mean_values(data: Vec[f64]) -> f64:
    let arr = numpy_array_f64(data)
    numpy_mean(arr)
```

### Opaque type: `PyObject`

When a type can't be inferred, the migrator uses `PyObject` — an
opaque struct defined once in the migration support module:

```
// In migrate_support.w (auto-included when any stub uses it)
type PyObject = { _handle: i64 }
```

`PyObject` signals "this value came from Python and hasn't been typed
yet." It compiles. It panics if any stub using it is called. The user
replaces it with a real type when binding the native library.

### Stub grouping for submodules

`from module.exceptions import SomeError` and `import module` are
grouped into the same `module_stubs.w`. Sub-package paths
(`module.sub.func`) are flattened to `module_sub_func` in the stub
file to avoid name collisions.

---

## Type Inference

The type inference pass runs before translation. It propagates types
forward through the AST, narrowing `// @migrate: unknown type` flags
as far as possible.

### Inference rules (in priority order)

1. **Explicit annotation wins.** `x: int = 5` → `i64`.

2. **Literal assignment.** `x = 42` → `i64`. `x = 3.14` → `f64`.
   `x = "hello"` → `str`. `x = True` → `bool`. `x = []` → `Vec[_]`
   (element type deferred). `x = {}` → `HashMap[_, _]` (deferred).

3. **Call return type.** If `func` is known (stdlib-mapped or annotated),
   the return type propagates to the call result.

4. **Arithmetic propagation.** `z = x + y` where `x: i64` and `y: i64`
   → `z: i64`.

5. **Comparison result.** Any comparison expression → `bool`.

6. **Conditional narrowing.** Inside `if isinstance(x, int):`, `x`
   narrows to `i64` in that branch.

7. **Container element inference.** `items = [1, 2, 3]` → `Vec[i64]`.
   `pairs = {1: "a", 2: "b"}` → `HashMap[i64, str]`.

8. **Cross-function propagation.** If a function is called with a known
   argument type and that function is in the same file, the parameter
   type is inferred.

9. **Fallback: `// @migrate: unknown type`.** Emit the original
   annotation position as a comment. The file still compiles if the
   user accepts the placeholder `PyObject`.

### Confidence levels

The migrator annotates inferred types with a confidence level in
`--stats` output:

- **certain** — from explicit annotation
- **inferred** — from literal or propagation
- **guessed** — from partial evidence (e.g., used in arithmetic → numeric)
- **unknown** — fell back to `PyObject`

---

## Standard Library Mapping

### Mapped: direct With equivalents

| Python module | With equivalent |
|---|---|
| `math.sqrt`, `math.floor`, etc. | `std.math.*` |
| `math.pi`, `math.e` | `std.math.PI`, `std.math.E` |
| `os.path.join` | `std.fs.path_join` |
| `os.path.exists` | `std.fs.exists` |
| `os.path.dirname` | `std.fs.dirname` |
| `os.path.basename` | `std.fs.basename` |
| `os.path.abspath` | `std.fs.absolute` |
| `os.getcwd()` | `std.fs.cwd()` |
| `os.listdir(path)` | `std.fs.read_dir(path)` |
| `os.makedirs(path)` | `std.fs.create_dir_all(path)` |
| `os.remove(path)` | `std.fs.remove_file(path)` |
| `os.environ` | `std.env.vars()` |
| `os.getenv(k)` | `std.env.get(k)` |
| `sys.argv` | `with_args()` |
| `sys.exit(n)` | `exit(n)` |
| `sys.stderr` (write) | `eprint(...)` |
| `sys.stdin.read()` | `std.io.read_all()` |
| `re.compile(pat)` | `std.regex.compile(pat)` |
| `re.match(pat, s)` | `std.regex.match(pat, s)` |
| `re.search(pat, s)` | `std.regex.search(pat, s)` |
| `re.findall(pat, s)` | `std.regex.find_all(pat, s)` |
| `re.sub(pat, repl, s)` | `std.regex.replace(pat, repl, s)` |
| `pathlib.Path(p)` | `std.fs.Path.new(p)` |
| `pathlib.Path.read_text()` | `std.fs.read_to_str(path)` |
| `pathlib.Path.write_text(s)` | `std.fs.write_str(path, s)` |
| `pathlib.Path.exists()` | `std.fs.exists(path)` |
| `json.dumps(obj)` | `std.json.encode(obj)` |
| `json.loads(s)` | `std.json.decode(s)` |
| `time.time()` | `std.time.now_secs()` |
| `time.sleep(n)` | `std.time.sleep_secs(n)` |
| `random.random()` | `std.random.f64()` |
| `random.randint(a, b)` | `std.random.range(a..=b)` |
| `random.choice(items)` | `items[std.random.range(0..items.len())]` |
| `functools.reduce(fn, iter)` | `iter.fold(init, (acc, x) => fn(acc, x))` |
| `functools.partial(f, arg)` | `x => f(arg, x)` (closure) |
| `itertools.chain(a, b)` | `a.chain(b)` |
| `itertools.islice(iter, n)` | `iter.take(n)` |
| `itertools.product(a, b)` | `a.flat_map(x => b.map(y => (x, y)))` |
| `itertools.groupby(iter, key)` | `iter.group_by(key)` |
| `collections.defaultdict(list)` | `HashMap` + `.get_or_insert()` |
| `collections.Counter(iter)` | `iter.fold(HashMap.new(), ...)` |
| `collections.OrderedDict` | `HashMap` (With HashMap preserves insertion order) |
| `hashlib.md5(s).hexdigest()` | `std.crypto.md5(s)` |
| `hashlib.sha256(s).hexdigest()` | `std.crypto.sha256(s)` |
| `base64.b64encode(b)` | `std.encoding.base64_encode(b)` |
| `base64.b64decode(s)` | `std.encoding.base64_decode(s)` |
| `struct.pack(fmt, ...)` | `std.encoding.pack(fmt, ...)` |
| `struct.unpack(fmt, buf)` | `std.encoding.unpack(fmt, buf)` |

### Stub-generated: no direct With equivalent

These Python stdlib modules have no With equivalent yet. They get
generated stubs the same as third-party packages:

| Python module | Stub file | Notes |
|---|---|---|
| `datetime` | `datetime_stubs.w` | Use `std.time` where possible |
| `io.StringIO` | `io_stubs.w` | Use `str` builder instead |
| `io.BytesIO` | `io_stubs.w` | Use `Vec[u8]` builder instead |
| `socket` | `socket_stubs.w` | Use `std.net` when available |
| `threading` | `threading_stubs.w` | Flag; suggest `std.fiber` |
| `asyncio` | `asyncio_stubs.w` | Flag; suggest With async |
| `subprocess` | `subprocess_stubs.w` | Use `std.process` |
| `shutil` | `shutil_stubs.w` | Use `std.fs` where possible |
| `tempfile` | `tempfile_stubs.w` | Use `std.fs.temp_dir()` |
| `logging` | `logging_stubs.w` | Use `std.log` |
| `argparse` | `argparse_stubs.w` | Use `std.args` |
| `urllib` | `urllib_stubs.w` | Use `std.http` |
| `http.client` | `http_stubs.w` | Use `std.http` |
| `csv` | `csv_stubs.w` | Use `std.csv` |
| `sqlite3` | `sqlite3_stubs.w` | Use `std.db.sqlite` |
| `pickle` | Flag | Serialization; no equivalent |
| `ctypes` | `ctypes_stubs.w` | Use `unsafe` + `c_import` |
| `multiprocessing` | Flag | Use `std.fiber` or processes |
| `concurrent.futures` | `futures_stubs.w` | Use `std.async` |
| `collections.deque` | `// @migrate: deque — use Vec[T]` | |

---

## Multi-File / Package Translation

### Package structure

A Python package:
```
mypackage/
    __init__.py
    utils.py
    models.py
    api/
        __init__.py
        client.py
```

Translates to:
```
mypackage/
    mod.w          (from __init__.py)
    utils.w
    models.w
    api/
        mod.w      (from api/__init__.py)
        client.w
```

`__init__.py` → `mod.w`. All re-exports in `__init__.py` are preserved
as `pub` declarations in `mod.w`.

### Import resolution

```python
from .utils import helper_fn          →  import "./utils.w" (helper_fn)
from ..models import User              →  import "../models.w" (User)
from mypackage.api.client import API   →  import "mypackage/api/client.w" (API)
import mypackage.utils as utils        →  import "mypackage/utils.w" as utils
```

Circular imports are detected. When a cycle is found, one of the
imports is moved to the function level (Python's standard solution)
and flagged:
```
// @migrate: circular import — moved to function scope
```

### `__all__` → pub visibility

```python
__all__ = ["Foo", "bar", "baz"]
```

Marks `Foo`, `bar`, `baz` as `pub` in the translated file.
Everything else is package-private (the default in With).

### `if __name__ == "__main__":`

```python
if __name__ == "__main__":
    main()
```
```
fn main():
    main()
```

The guard is stripped. The body becomes `fn main()` in With's
entry point convention.

---

## Correctness Notes

### Integer precision

Python `int` is arbitrary precision. With's `i64` overflows at 2^63.
The migrator emits a note when literals exceed safe i64 range, or when
patterns like `x ** 64` suggest big-integer usage:

```
// @migrate: Python int is arbitrary precision; i64 may overflow for large values
```

### String mutability

Python strings are immutable. With `str` is also immutable. No issue.

### Reference semantics vs value semantics

Python objects are always references. With structs are values by
default. The migrator passes structs by reference (`&Self`) for method
receivers, but struct assignment copies. When a Python function mutates
an object that was "passed" as an argument, the With translation must
use `&mut`:

```python
def fill(items: list[int], value: int) -> None:
    for i in range(len(items)):
        items[i] = value
```
```
fn fill(items: &mut Vec[i64], value: i64):
    for i in 0..items.len():
        items.set(i, value)
```

The migrator detects mutation of list/dict arguments and promotes them
to `&mut` parameters automatically.

### Dict insertion order

Python 3.7+ dicts preserve insertion order. With `HashMap` preserves
insertion order. No semantic difference.

### `None` vs `Option`

Python `None` is a runtime value. In With, `Option[T]` is a type
wrapper. Migrated code using `None` as a sentinel in a list or dict
gets flagged:

```python
items: list[Optional[int]] = [1, None, 3]
```
```
let items: Vec[Option[i64]] = [Option.Some(1), Option.None, Option.Some(3)]
```

### Float equality

Python and With both use IEEE 754. `==` on floats has the same
semantics. No change needed.

### Exception message strings

`raise ValueError("msg")` → `return Err("msg")` preserves the message
as a string. When the except clause catches by exception type, the
migrator emits a match on an enum variant. If multiple exception types
are used, the migrator generates an error enum:

```python
# multiple exception types used as errors
class ParseError(Exception): pass
class NetworkError(Exception): pass
```
```
type AppError =
    | ParseError(str)
    | NetworkError(str)
```

---

## Output Format

### Single translated file

```
// Generated by: with migrate python fetcher.py
// Source: fetcher.py (42 lines)
// Stubs: requests_stubs.w, numpy_stubs.w
// Flags: 3 @migrate comments require review
// Types: 28 certain, 6 inferred, 2 guessed, 1 unknown (PyObject)

import "requests_stubs.w"
import "numpy_stubs.w"

// ── Types ──────────────────────────────────────────────

type Config = {
    host: str,
    port: i64,
    timeout: i64,
}

// ── Functions ──────────────────────────────────────────

fn fetch_json(url: str, timeout: i64 = 30) -> Option[HashMap[str, PyObject]]:
    // @migrate: exception → Result: was try/except requests.exceptions.RequestException
    let resp = requests_get(url, timeout)
    resp.raise_for_status()
    Option.Some(resp.json())

fn mean_values(data: Vec[f64]) -> f64:
    let arr = numpy_array_f64(data)
    numpy_mean(arr)
```

### Statistics output (`--stats`)

```
with migrate python src/ --stats

src/fetcher.py     → src/fetcher.w       42 lines  2 stubs  3 flags  1 unknown
src/models.py      → src/models.w        87 lines  0 stubs  1 flag   0 unknown
src/api/client.py  → src/api/client.w   156 lines  3 stubs  7 flags  4 unknown
...

Stub files written:
  requests_stubs.w      (12 functions, 3 types)
  numpy_stubs.w         (41 functions, 2 types)
  pandas_stubs.w        (78 functions, 7 types)

Total: 8 files, 1247 lines
Types: 892 certain, 143 inferred, 37 guessed, 9 unknown (PyObject)
Stubs: 3 modules, 131 stubs generated
Flags: 24 @migrate comments require review
```

---

## Implementation Plan

### Step 1: Parser integration

Integrate **tree-sitter-python** as a statically-linked library.
Write `src/MigratePython.w` with a `py_parse_file` function that:
- Reads a `.py` file
- Returns a tree-sitter CST root node
- Exposes cursor-walk APIs (`py_cursor_kind`, `py_cursor_child`, etc.)

No Python runtime. No subprocess. Pure grammar parsing.

**Done when:** `with migrate python hello.py` can parse and print the
CST of a trivial Python file.

### Step 2: Type annotation translator

Write `py_translate_type(node) -> str`:
- Converts Python type annotation AST nodes to With type strings
- Handles all Tier 1 type mappings (see §Type annotations)
- Returns `"// @migrate: unknown type"` for unrecognized forms

**Done when:** All type annotations in `mypy`'s own test suite
translate without unknown-type flags.

### Step 3: Expression and statement translator

Write `py_trans_expr(node, ctx) -> str` and
`py_trans_stmt(node, ctx, indent) -> str`.

Start with Tier 1 constructs (no semantic transformation needed):
- Literals, f-strings, identifiers
- Binary/unary operators (including `**` → `pow`, `//` → `/`)
- Attribute access, subscript, function calls
- Comprehensions (all four forms)
- Lambda
- `if`/`else if` (from `elif`), `while`, `for x in iter`, `break`, `continue`
- `return`, `pass` (dropped)
- `let`/`var` bindings from `=` assignments with annotation

**Done when:** `with migrate python` translates a pure-computation
Python file (no classes, no exceptions, no imports) to compilable With.

### Step 4: Class translator

Write `py_trans_class(node, ctx) -> str`:
- Detect `@dataclass` → pure struct
- Detect `(ABC)` or `(Protocol)` → trait
- General class → struct + `extend` block
- Field discovery from `__init__` assignments
- Mutability inference from self-mutation analysis
- Dunder method dispatch to trait impls or `extend` methods
- `@staticmethod` / `@classmethod` handling
- Single concrete inheritance → composition pattern

**Done when:** The class translator handles all classes in the
Python `dataclasses` module test suite and the `typing` module
examples.

### Step 5: Exception → Result translator

Write `py_trans_try(node, ctx, indent) -> str`:
- `try/except/finally` → `match result_expr:` + `defer cleanup()`
- `raise Foo("msg")` → `return Err("msg")`
- Multi-exception type detection → generate error enum
- `finally` → `defer`

**Done when:** A file with ten different exception patterns (bare
raise, re-raise, multi-except, finally, chained) translates
correctly and compiles.

### Step 6: Import classifier and stdlib mapper

Write `py_classify_imports(file_ast) -> ImportMap`:
- Parse all `import` and `from...import` statements
- Look up each module in the stdlib mapping table
- Classify as mapped / internal / stub-needed
- Return per-name resolved targets

Write `py_emit_stdlib_import(module, name) -> str`:
- Emits the correct With stdlib import for a mapped module/name

**Done when:** Files that import only mapped stdlib modules (`os`,
`re`, `math`, `sys`, `json`) translate without any stub files.

### Step 7: Dependency scanner and stub generator

Write `py_scan_usages(file_ast, module_name) -> UsageMap`:
- Collects all calls, attribute accesses, instantiations for a module
- Infers argument types and return types per the inference rules
- Returns a typed usage map

Write `py_gen_stub_file(module_name, usage_map) -> str`:
- Emits the `<module>_stubs.w` file
- Groups methods per class
- Uses `PyObject` fallback for unknown types
- Marks everything `@[stub("module")]`

**Done when:** Translating a file that imports `requests` and `numpy`
produces valid, compilable stub files for both modules.

### Step 8: Type inference pass

Write `py_infer_types(file_ast, known_types) -> TypeMap`:
- Propagates types per the inference rules (§Type Inference)
- Annotates all variable bindings with inferred types
- Tracks confidence levels

**Done when:** A Python file with zero type annotations (but clear
literal types) translates with all `i64`/`f64`/`str`/`bool` types
inferred — zero `PyObject` usages.

### Step 9: Multi-file / package mode

Write `py_trans_package(src_dir, out_dir)`:
- Walks the package directory tree
- Maintains a cross-file symbol table for inter-module type resolution
- Resolves relative imports (`from .utils import`)
- Detects and reports circular import cycles
- Translates `__init__.py` → `mod.w`
- Writes all stub files to `--stub-dir` (or alongside translated files)

**Done when:** `with migrate python src/ -o out/` translates a
multi-file Python package with cross-module imports and produces
compilable output for all files.

### Step 10: CLI integration

Wire `with migrate python` into the main `with migrate` dispatch in
`src/Migrate.w` (parallel to the existing `rust`, `go`, `swift`,
`zig` subcommands).

Implement all CLI modes: `write`, `check`, `diff`, `--stats`,
`--no-stubs`, `--stub-dir`, `--typed-only`.

**Done when:** CLI matches the usage section of this spec exactly.

### Step 11: Validation target

**Target: [Textual](https://github.com/Textualize/textual)** — a
well-typed Python TUI framework (~30K lines, extensive type annotations,
minimal third-party deps beyond `rich`).

1. Clone Textual to `.reference/textual/`
2. `with migrate python .reference/textual/src/ -o .reference/textual-migrated/`
3. Build: all translated files must compile (stubs satisfy imports)
4. Check flag count: target < 5% of statements flagged
5. Check unknown-type count: target < 2% of type positions are `PyObject`
6. Iterate on translator bugs until both targets met

**Done when:** Textual's entire source tree translates with build
success and meets the flag/unknown-type targets.

---

## Design Rationale

### Why tree-sitter, not Python's own `ast` module?

The migrator must run without a Python installation. tree-sitter is a
C library with a statically-linked grammar — it parses Python 3.10+
syntax from any host, including the `with` binary itself. The Python
`ast` module requires a running Python interpreter and produces an AST
tied to the host Python version.

### Why stubs rather than refusing to translate?

A migrator that refuses files with unknown imports is useless on real
Python code. Real Python code imports dozens of packages. Stubs make
the output compile immediately. The user gets a working program with
explicit "TODO" panics rather than a pile of untranslatable files.
Incremental stub filling is a defined, bounded task.

### Why Result, not exceptions?

Python exceptions are a control-flow mechanism that With doesn't have.
The idiomatic With equivalent is `Result[T, E]`. The migration to
`Result` is often an improvement: error paths become explicit,
composable, and visible at call sites. The migrator takes the
opinionated position that translated code should be idiomatic With,
not Python-with-panics.

### Why `i64` for Python `int`?

Python `int` is arbitrary precision, but almost all practical Python
code uses values that fit in 64 bits. `i64` is the natural choice for
"a whole number" in With (matching Python's `int` semantic of
"any integer"). The migrator flags when it detects big-integer patterns
so the programmer can decide whether to use a big-int library or
restructure the algorithm.
