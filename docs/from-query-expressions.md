# Unified `from` Query Expressions

## Overview

With's `from` keyword is a unified query expression that works on any data source. The compiler dispatches to the right query engine based on the source type. One keyword, multiple backends, same position in the grammar.

```with
// Source is Json → jq pipeline
let names = from data | .users | where .age > 30 | .name

// Source is Db → SQL
let users = from db | select name, age | from users | where age > 30
```

This is With's equivalent of C#'s LINQ. Query expressions are parsed at compile time, lowered to engine-specific calls, and type-checked by the compiler. No runtime string parsing. No SQL injection. No jq syntax errors at runtime.

## How dispatch works

The compiler resolves the source expression's type, then selects the query grammar:

| Source type | Grammar | Engine | Lowered to |
|---|---|---|---|
| `Json` | jq-style pipeline | jq VM (migrated C) | `jq_execute(data, ast)` |
| `sqlite.Db` | SQL clauses | SQLite (migrated C) | `sqlite_query(db, sql, params)` |

The parser doesn't need to guess — the type of the first expression after `from` is known during type checking. The `|` pipeline operator and `where` keyword work in both grammars but with different semantics appropriate to each engine.

## Shared principles

These rules apply to all `from` backends:

1. **Compile-time parsing.** The query is parsed by the compiler, not at runtime. Syntax errors are compile errors.
2. **Variable capture.** With variables used inside queries become parameters. They are never interpolated into query strings.
3. **Purity.** Queries never mutate the source. The input data or database connection state is unchanged after a read query.
4. **Expression context.** `from` is an expression — it can appear in assignments, function arguments, `for` loops, `if` conditions.

---

# Part 1: Data Queries (Json)

Queries over JSON, YAML, TOML, and JSONL data. Backed by the jq engine (migrated from C via `with migrate`).

## Modules

```
std.json        — parse/serialize JSON, JSON5, and JSONL, query engine
std.yaml        — parse/serialize YAML, returns Json
std.toml        — parse/serialize TOML, returns Json
```

## Parse functions

```
json.parse(s)           strict JSON
json.parse5(s)          JSON5 (comments, trailing commas, unquoted keys)
json.parse_lines(s)     JSONL (newline-delimited, returns array)
json.stream_lines(f)    JSONL (streaming iterator, constant memory)
yaml.parse(s)           YAML
yaml.parse_all(s)       multi-document YAML
toml.parse(s)           TOML
```

All return `Json`.

## The Json type

```with
// Opaque tagged value — holds any JSON-compatible type.
// Reference-counted, cheap to copy.
// Used as the universal document type for JSON, YAML, TOML.
type Json
```

`Json` holds strings, numbers, bools, nulls, arrays, and objects. YAML and TOML parse into the same type — their data models are subsets of JSON's.

## Library API (Phase 1 — no compiler changes)

### Parsing and serialization

```with
use std.json

let data = json.parse("{\"name\": \"Alice\", \"age\": 30}")
let s = json.to_string(data)              // compact
let pretty = json.to_string_pretty(data)   // indented
```

### Field access

```with
let name = data["name"]
let age = data["age"]
let nested = data["address"]["city"]
let first = data["users"][0]
let missing = data["nope"]     // null, not error
```

### Type extraction

```with
// Returns Option — None if wrong JSON type
let s: str = name.as_str()        // Some("Alice")
let n: i64 = age.as_int()         // Some(30)
let f: f64 = price.as_float()     // Some(9.99)
let b: bool = flag.as_bool()      // Some(true)

// Extract with default
let s = name.string_or("")
let n = age.int_or(0)
let f = price.float_or(0.0)
```

### Type checking

```with
data.is_object()    // true
name.is_string()    // true
age.is_number()     // true
arr.is_array()      // true
data.is_null()      // false
```

### Construction and mutation

```with
let n = json.null()
let i = json.int(42)
let s = json.string("hello")
let a = json.array()
let o = json.object()

var obj = json.object()
obj.set("name", json.string("Alice"))
obj.remove("name")

var arr = json.array()
arr.push(json.int(1))
```

### Iteration

```with
for key, value in obj:
    print(f"{key}: {value}")

for item in arr:
    print(item)
```

### String-based queries

```with
let result = json.query(data, ".users[] | select(.age > 30) | .name")

let q = json.compile(".users[] | select(.active) | .email")
let emails = q.run(data)
q.free()
```

### Error handling

```with
let bad = json.parse("not valid")
if bad.is_error():
    print(json.error_message(bad))
```

### JSONL

```with
// Parse all lines into a Json array
let records = json.parse_lines(input_string)

// Stream lazily for large files — constant memory
for record in json.stream_lines(file):
    let level = record["level"].string_or("info")
    if level == "error":
        print(record)
```

### JSON5

JSON5 is a superset of JSON allowing comments, trailing commas, unquoted keys, single-quoted strings, hex numbers. Implemented as a pure With function (~200 lines) that normalizes to strict JSON before parsing.

```with
let config = json.parse5("
    {
        // Database settings
        database: {
            host: 'localhost',
            port: 5432,  // trailing comma OK
        },
    }
")
```

### YAML

```with
use std.yaml

let config = yaml.parse("
  database:
    host: localhost
    port: 5432
")

let host = config["database"]["host"].string_or("localhost")
let output = yaml.to_string(config)
let docs = yaml.parse_all(multi_doc_input)
```

### TOML

```with
use std.toml

let config = toml.parse("[database]\nhost = \"localhost\"\nport = 5432")
let host = config["database"]["host"].string_or("localhost")
```

### All formats interoperate

```with
// All return Json — convert freely between formats
let as_json = json.to_string_pretty(yaml.parse(yaml_input))
let as_yaml = yaml.to_string(json.parse(json_input))
let as_toml = toml.to_string(json.parse(json_input))
```

## Data query syntax (Phase 2 — compiler support)

### Basic form

```with
let names = from data | .users | where .age > 30 | .name
```

Compiles to:

```with
let names = jq_execute(data, jq_pipe([
    jq_field("users"),
    jq_select(jq_gt(jq_field("age"), jq_lit_int(30))),
    jq_field("name"),
]))
```

### Multi-line form

```with
let results = from data
    | .users
    | where .age > 30
    | where .active
    | .name
```

### Null propagation

Field access on missing data returns `null`. It never errors. Null propagates through the pipeline silently.

```with
from data | .foo              // null (missing field)
from data | .foo.bar          // null (chained missing)
from data | .users[99]        // null (out-of-bounds)

// Filter nulls with where
let emails = from data | .users | .email | where . != null
```

#### Null semantics

Concrete rules for how null behaves in every context:

```
Equality:
  null == null        → true
  null == anything    → false
  null != null        → false
  null != anything    → true

Comparisons:
  null > x            → false
  null < x            → false
  null >= x           → false
  null <= x           → false

Arithmetic:
  null + x            → null
  null - x            → null
  null * x            → null
  null / x            → null

Filtering:
  where null          → drops the element (null is falsy)
  where .missing > 5  → drops the element (false due to null comparison)

Field access:
  null.anything       → null
  null[0]             → null

Boolean logic:
  null and x          → false
  null or x           → x
  not null            → true

Type checks:
  null.is_null()      → true
  null.string_or("x") → "x"
  null.int_or(0)      → 0
```

Null propagation means pipelines are safe by default — missing data flows through as null and gets caught at the boundary when you extract to a native With type.

### Auto-iteration

When a pipeline stage accesses a field on an array, the engine automatically maps over elements. No explicit iteration operator needed.

```with
// .users is an array. .name maps over each element automatically.
let names = from data | .users | .name
// Result: ["Alice", "Bob", "Carol"]

// where also auto-iterates — it filters array elements
let adults = from data | .users | where .age >= 18
// Result: array of matching user objects

// Chained access through nested arrays auto-iterates at each level
let tags = from data | .items | .tags | flatten
// Result: all tags from all items, flattened
```

The rule: field access on an array returns an array of that field from each element. `where` on an array filters elements. Transforms like `length`, `sort_by`, `first`, `reverse` operate on the array as a whole.

```with
from data | .users | .name         // ["Alice", "Bob"] — auto-iterates
from data | .users | where .age > 30  // filtered array — auto-iterates
from data | .users | length        // 2 — operates on array as whole
from data | .users | sort_by(.age) // sorted array — operates on array as whole
from data | .users | first         // first element — operates on array as whole
from data | .users | reverse       // reversed array — operates on array as whole
```

This eliminates jq's `[]` operator for the common case. You don't need to think about "iterating" vs "accessing" — you just traverse the data tree and the engine does the right thing.

### Return value semantics

`from` expressions always return a single `Json` value. When the pipeline traverses arrays, the results collect naturally — field access on an array produces an array, `where` produces a filtered array, and so on.

```with
// Returns a Json array: ["Alice", "Bob", "Carol"]
let names = from data | .users | .name

// Returns a single Json value: "Alice"
let first = from data | .users[0].name

// Returns a Json array (filtered): [{...}, {...}]
let adults = from data | .users | where .age >= 18
```

One `Json` in, one `Json` out. No streams, no lazy evaluation, no special iterator types.

### Field access

```with
from data | .name              // data["name"]
from data | .address.city      // data["address"]["city"]
from data | .users[0]          // data["users"][0]
from data | .users | .name     // all user names (auto-iterates)
```

### Filtering with `where`

```with
from data | .users | where .age > 30
from data | .users | where .active and .age >= 18
from data | .users | where .name != "admin"
```

### Transforms

```with
from data | .users | .name | ascii_downcase
from data | .scores | sort
from data | .items | length
from data | .tags | unique
from data | .users | reverse
from data | .users | limit(10)
from data | .users | map(.name)
from data | .users | sort_by(.age)
from data | .users | group_by(.department)
from data | .users | first
from data | .users | last
from data | .values | flatten
from data | .users | keys
```

### Numeric / statistical builtins

```with
from data | .scores | sum
from data | .scores | mean
from data | .scores | median
from data | .scores | stdev
from data | .scores | variance
from data | .latencies | percentile(99)
from data | .users | where .active | count
from data | .measurements | corr(.height, .weight)
from data | .ages | histogram(10)
```

Group + aggregate (pandas-style):

```with
from data | .employees
    | group_by(.department)
    | map({
        dept: .[0].department,
        headcount: length,
        avg_salary: map(.salary) | mean
    })
```

### Object construction

```with
from data | .users | { name: .name, years: .age }

from data | .users
    | where .active
    | { display: .name, contact: .email }
```

### Array collection

```with
from data | [.users | .name]    // explicit array wrap (usually unnecessary — auto-iteration already produces arrays)
```

### Arithmetic and conditionals

```with
from data | .users | { name: .name, birth_year: 2025 - .age }
from data | .items | where (.price * .quantity) > 100
from data | .users | if .age >= 18: "adult" else: "minor"
```

### Variable capture

```with
let threshold = 30
let names = from data | .users | where .age > threshold | .name

let field_name = "email"
let emails = from data | .users | .[field_name]
```

### Data query grammar

```
data_query     := 'from' json_expr pipeline
pipeline       := ('|' stage)*
stage          := field_access | filter | transform | construction
field_access   := '.' IDENTIFIER ('.' IDENTIFIER)* ('[' expr ']')?
filter         := 'where' expr
transform      := builtin_call
construction   := '{' field_pair (',' field_pair)* '}'
field_pair     := IDENTIFIER ':' stage_expr
builtin_call   := IDENTIFIER '(' args ')'
```

Field access on arrays auto-iterates. No explicit iteration operator in the grammar.

---

# Part 2: SQL Queries (sqlite.Db)

Queries over SQLite databases. Backed by SQLite (migrated from C via `with migrate`).

## Module

```
std.sqlite      — embedded SQL database engine
```

## Library API (Phase 1 — no compiler changes)

### Open and execute

```with
use std.sqlite

let db = sqlite.open("app.db")

db.exec("CREATE TABLE IF NOT EXISTS users (name TEXT, age INTEGER, active BOOLEAN)")
db.exec("INSERT INTO users VALUES (?, ?, ?)", "Alice", 30, true)
```

### Query

```with
// Returns iterator of Row
for row in db.query("SELECT name, age FROM users WHERE age > ?", 20):
    let name = row.str("name")
    let age = row.int("age")
    print(f"{name}: {age}")

// Single value
let count = db.query_one("SELECT COUNT(*) FROM users WHERE active = ?", true).int(0)
```

### Row type

```with
// Access by name
row.str("name")         // -> str
row.int("age")          // -> i64
row.float("score")      // -> f64
row.bool("active")      // -> bool
row.blob("data")        // -> [u8]
row.is_null("field")    // -> bool

// Access by index
row.str(0)
row.int(1)
```

### Prepared statements

```with
let stmt = db.prepare("SELECT name FROM users WHERE dept = ? AND age > ?")
let engineering = stmt.query("Engineering", 25)
let marketing = stmt.query("Marketing", 30)
stmt.close()
```

### Transactions

```with
db.transaction():
    db.exec("UPDATE accounts SET balance = balance - ? WHERE id = ?", 100, from_id)
    db.exec("UPDATE accounts SET balance = balance + ? WHERE id = ?", 100, to_id)
```

### Bridge to Json

```with
// Query SQLite, get results as Json, then use data pipelines
let data = db.query_json("SELECT * FROM users WHERE active = 1")
let names = from data | .name
```

## SQL query syntax (Phase 2 — compiler support)

### Basic form

```with
let users = from db
    | select name, age
    | from users
    | where age > 30
    | order by age desc
    | limit 10
```

Compiles to:

```with
let users = sqlite_query(db,
    "SELECT name, age FROM users WHERE age > ?1 ORDER BY age DESC LIMIT 10",
    [30])
```

### Variable capture — no SQL injection by construction

With variables become numbered parameters. The compiler never interpolates values into SQL strings.

```with
let min_age = 30
let dept = "Engineering"

let team = from db
    | select name, age
    | from employees
    | where dept = $dept and age >= $min_age
    | order by age desc

// Compiles to:
// sqlite_query(db, "SELECT name, age FROM employees WHERE dept = ?1 AND age >= ?2 ORDER BY age DESC", [dept, min_age])
```

The `$variable` prefix explicitly marks With variables inside SQL context. Column names are bare identifiers.

### SELECT

```with
// All columns
let all = from db | select * | from users

// Specific columns
let names = from db | select name, age | from users

// Expressions and aliases
let report = from db
    | select name, age, salary * 12 as annual
    | from employees

// Aggregates
let stats = from db
    | select dept, count(*) as headcount, avg(salary) as avg_salary
    | from employees
    | group by dept
```

### JOIN

```with
let results = from db
    | select u.name, o.total
    | from users u
    | join orders o on u.id = o.user_id
    | where o.total > 100
    | order by o.total desc

let all_users = from db
    | select u.name, coalesce(count(o.id), 0) as order_count
    | from users u
    | left join orders o on u.id = o.user_id
    | group by u.name
```

### Subqueries

```with
let high_spenders = from db
    | select name
    | from users
    | where id in (from db | select user_id | from orders | where total > 1000)
```

### INSERT / UPDATE / DELETE

```with
// Insert
from db | insert into users (name, age) values ($name, $age)

// Update
from db | update users set active = false | where age < 18

// Delete
from db | delete from users | where active = false

// Returning
let inserted = from db
    | insert into users (name, age) values ($name, $age)
    | returning id, name
```

### Return type

SQL `from` expressions return an iterator of `sqlite.Row`.

```with
for row in from db | select name, age | from users:
    print(f"{row.str("name")}: {row.int("age")}")

let users = (from db | select * | from users).to_list()
let user = (from db | select * | from users | where id = $user_id).first()
let count = (from db | select count(*) | from users).int(0)
```

### SQL query grammar

```
sql_query      := 'from' db_expr sql_pipeline
sql_pipeline   := ('|' sql_clause)*
sql_clause     := select_clause | from_clause | where_clause
               |  join_clause | order_clause | group_clause
               |  having_clause | limit_clause
               |  insert_clause | update_clause | delete_clause
               |  returning_clause
select_clause  := 'select' column_list
from_clause    := 'from' table_name alias?
where_clause   := 'where' sql_expr
join_clause    := ('join' | 'left join' | 'inner join') table_name 'on' sql_expr
order_clause   := 'order' 'by' column_list ('asc' | 'desc')?
group_clause   := 'group' 'by' column_list
having_clause  := 'having' sql_expr
limit_clause   := 'limit' expr ('offset' expr)?
insert_clause  := 'insert' 'into' table_name '(' column_list ')' 'values' '(' expr_list ')'
update_clause  := 'update' table_name 'set' assign_list
delete_clause  := 'delete' 'from' table_name
returning_clause := 'returning' column_list
```

---

# Part 3: Bridge Between Worlds

The two query backends connect through `Json`. SQLite results convert to `Json` for further pipeline processing.

```with
// SQL query → Json → data pipeline
let stats = (from db
    | select author, count(*) as posts, sum(views) as total_views
    | from posts
    | where published = true
    | group by author
    | order by total_views desc
).to_json()

// Now use jq pipeline for further shaping
let report = from stats
    | { writer: .author, impact: .total_views }
    | where .impact > 1000

// Or stream JSONL logs then enrich from database
for record in json.stream_lines(open("app.log")):
    let user_id = (from record | .user_id).int_or(0)
    if user_id > 0:
        let user = (from db | select name | from users | where id = $user_id).first()
        print(f"{user.str("name")}: {record["message"].string_or("")}")
```

---

# Unified scope rules

## Inside `from` with Json source

- `.identifier` is JSON field access
- Bare identifiers resolve as With variables first, then as query builtins
- `where` is a filter keyword
- `|` is pipeline
- All other With operators work normally

## Inside `from` with Db source

- Bare identifiers are SQL column names
- `$identifier` marks With variables (become query parameters)
- `where` is SQL WHERE
- `|` separates SQL clauses
- SQL functions (`count`, `avg`, `coalesce`, etc.) work normally

## Outside `from`

All syntax has its normal With meaning. No ambiguity.

---

# Compiler lowering

## Data queries

```with
from data | .users | where .age > 30 | .name
```

Lowers to:

```with
jq_execute(data, jq_pipe([
    jq_field("users"),
    jq_select(jq_gt(jq_field("age"), jq_lit_int(30))),
    jq_field("name"),
]))
```

The engine handles auto-iteration internally: when `jq_field("name")` encounters an array input, it maps over elements. No explicit `jq_iterate()` node needed in the common case.

## SQL queries

```with
from db | select name | from users | where age > $min_age
```

Lowers to:

```with
sqlite_query(db, "SELECT name FROM users WHERE age > ?1", [min_age])
```

## Data query AST nodes

```
jq_field(name: str)                    // .name (auto-iterates over arrays)
jq_index(i: i64)                       // .[0]
jq_select(condition: JqNode)           // where ...
jq_pipe(stages: [JqNode])             // a | b | c
jq_lit_int(v: i64)                     // integer literal
jq_lit_float(v: f64)                   // float literal
jq_lit_str(v: str)                     // string literal
jq_lit_bool(v: bool)                   // bool literal
jq_lit_null()                          // null
jq_gt, jq_lt, jq_eq, jq_ne,           // comparisons
jq_gte, jq_lte
jq_and, jq_or, jq_not                 // logic
jq_add, jq_sub, jq_mul, jq_div        // arithmetic
jq_object(pairs: [(str, JqNode)])     // { k: v, ... }
jq_array(inner: JqNode)               // [ expr ]
jq_call(name: str, args: [JqNode])    // length, sort, mean, etc.
jq_if(cond, then, else)                // conditional
jq_identity()                          // .
jq_var(name: str)                      // captured With variable
jq_flatten()                           // flatten nested arrays
```

Note: there is no `jq_iterate()` node. Auto-iteration is handled by the engine — when `jq_field` or `jq_select` receives an array input, it maps over elements automatically.

---

# Compiler guarantees

| Guarantee | Data queries | SQL queries |
|---|---|---|
| Compile-time syntax check | Query pipeline validated | SQL syntax validated |
| No injection | N/A (data, not strings) | Variables become `?N` parameters |
| No runtime parsing | AST built at compile time | SQL string built at compile time |
| Variable capture | By value into query closures | By value into parameter array |
| Purity | Input `Json` never mutated | SELECT doesn't modify DB |

---

# Error conditions

## Compile-time errors (caught before your program runs)

| Error | Data queries | SQL queries |
|---|---|---|
| Malformed pipeline | `from data \| .users \| where` (missing condition) | `from db \| select * form users` (typo) |
| Unknown builtin | `from data \| .users \| frobnicate` | N/A (SQL functions validated by SQLite) |
| Bad variable capture | `from data \| .users \| where .age > $x` (undefined `x`) | `from db \| select * \| from users \| where id = $x` (undefined `x`) |
| Unclosed construction | `from data \| { name: .name` (missing `}`) | N/A |

## Runtime behavior (not errors — handled gracefully)

| Situation | Behavior |
|---|---|
| Missing field (`.foo` on object without `foo`) | Returns `null` |
| Field access on wrong type (`.name` on a number) | Returns `null` |
| Out-of-bounds index (`.[99]` on 3-element array) | Returns `null` |
| Chained null access (`.foo.bar.baz` where `foo` is missing) | Returns `null` |
| `where` condition evaluates to null | Element dropped (null is falsy) |
| Arithmetic on null (`null + 5`) | Returns `null` |
| `mean` / `sum` on empty array | Returns `null` |
| `first` on empty array | Returns `null` |

## Runtime errors (program faults)

| Situation | Behavior |
|---|---|
| Division by zero (non-null) | Runtime error |
| SQLite constraint violation | Runtime error from `db.exec` / `db.query` |
| Database file not found | Runtime error from `sqlite.open` |
| Invalid JSON string | `json.parse` returns error value (check with `.is_error()`) |
| Invalid YAML/TOML string | `yaml.parse` / `toml.parse` returns error value |

The design principle: data traversal never crashes. Missing or wrong-typed data produces `null`. Only programmer errors (division by zero) and I/O failures (file not found, constraint violations) produce runtime errors.

---

# What `from` is NOT

- **Not an ORM.** No object mapping, no schema migration, no model classes.
- **Not a new query language.** Data queries follow jq conventions. SQL queries are standard SQL. No invented syntax.
- **Not dynamically typed.** The query engines operate on `Json` / SQLite internally, but With code around them is fully statically typed. Type extraction happens at the boundary.
- **Not required.** `json.parse` + `["field"]` and `db.query("SELECT ...")` work fine. `from` expressions add compile-time checking and ergonomics.
- **Not lazy.** Data queries return concrete `Json` values. Auto-iteration collects results into arrays. SQL queries return row iterators that execute immediately.
- **Not mutable.** Data queries never modify input. SQL SELECT/queries don't modify the database. INSERT/UPDATE/DELETE are explicit and intentional.

---

# Full example

```with
use std.json
use std.yaml
use std.sqlite

fn main:
    // --- Data queries ---

    // Parse API response and query with jq pipeline
    let response = json.parse(http_get("https://api.example.com/users"))

    let active_users = from response
        | .users
        | where .active and .age >= 18
        | sort_by(.age)
        | { name: .name, email: .email }

    // Read YAML config
    let config = yaml.parse(read_file("config.yaml"))
    let db_path = (from config | .database.path).string_or("app.db")

    // --- SQL queries ---

    let db = sqlite.open(db_path)

    db.exec("CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY,
        name TEXT,
        email TEXT,
        age INTEGER,
        department TEXT
    )")

    // Sync API data to database
    for user in active_users:
        let name = user["name"].string_or("")
        let email = user["email"].string_or("")
        from db | insert into users (name, email)
            values ($name, $email)

    // Query database with compile-time checked SQL
    let report = from db
        | select department, count(*) as headcount, avg(age) as avg_age
        | from users
        | group by department
        | order by headcount desc

    for row in report:
        print(f"{row.str("department")}: {row.int("headcount")} people")

    // --- Bridge: SQL → Json → data pipeline ---

    let dept_json = (from db
        | select department, count(*) as n
        | from users
        | group by department
    ).to_json()

    let top_dept = (from dept_json | sort_by(.n) | reverse | first | .department)
        .string_or("unknown")

    print(f"Largest department: {top_dept}")

    // --- Stream logs and enrich from database ---

    for record in json.stream_lines(open("app.log")):
        if (from record | .level).string_or("") == "error":
            let uid = (from record | .user_id).int_or(0)
            let user = (from db
                | select name
                | from users
                | where id = $uid
            ).first()
            print(f"Error by {user.str("name")}: {record["message"].string_or("")}")

    db.close()
```

---

# Implementation order

| Step | What | Compiler changes | Depends on |
|---|---|---|---|
| 1 | `std.json` library — parse, query (string-based), field access, construction | None | jq migration |
| 2 | `std.yaml` — parse YAML to `Json` | None | libyaml migration |
| 3 | `std.toml` — parse TOML to `Json` | None | toml-c migration |
| 4 | `std.sqlite` library — open, query, exec, Row, transactions | None | SQLite migration |
| 5 | Numeric builtins — sum, mean, stdev, percentile, etc. | None | std.json + std.math |
| 6 | `from` parser for data queries | New expression kind | Step 1 |
| 7 | `from` parser for SQL queries | Type-dispatched grammar | Steps 4, 6 |
| 8 | AST lowering for data queries | Emit `jq_execute` calls | Step 6 |
| 9 | SQL lowering + parameter capture | Emit `sqlite_query` calls | Step 7 |
| 10 | Optimizations — constant folding, inline simple queries | Codegen | Steps 8, 9 |

Steps 1-5 ship as libraries with string-based APIs. Steps 6-9 add compiler syntax. Step 10 is performance polish. Each step ships independently.

## C libraries to migrate

| Library | Lines | License | Purpose |
|---|---|---|---|
| jq | ~15K | MIT | JSON query engine, value system, builtins |
| libyaml | ~8K | MIT | YAML parser/emitter |
| toml-c | ~3K | MIT | TOML parser |
| SQLite | ~250K | Public domain | Embedded SQL database engine |

JSON5 (~200 lines) and JSONL are implemented as native With code.