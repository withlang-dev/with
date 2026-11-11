# The With Contract Language (WCL): formal specification, draft 3

Status: draft 3, for Eric's blessing. Nothing here is normative and nothing
lands until he blesses it. §16.2b of the specification is normative until a
chapter of this form replaces it, with §16.2b reduced to an introduction.

Sections 1 to 12 restate today's rules and change none. Every proposed rule
change is in section 13, each with the current rule, the proposed rule and
what it breaks. What the checks of this draft found (the grammar against the
parser, every row against §16.2b, the checker's treatment of `destroys`) is
listed in docs/proposals/wcl-spec-findings.md, not folded into the text.

The keyword is written `contract` throughout.

> A foreign capability may enter safe With through a verified fact or an
> explicitly attributable trusted claim. The absence of evidence must not
> silently establish a memory-safety guarantee.

## 1. Names

The **With Contract Language** is the language in which a person, a package
registry, or the compiler's own evidence states what a function does with
memory, threads and state that its signature cannot say, so that a call of
it is safe With.

- A **contract** is a block of it: `c contract name:`. It is what a program
  or the drafter writes.
- A **clause** is a line of a contract.
- A **claim** is a clause that rests on a person's word rather than a proof.
  The definition is about what the clause rests on, not which file it is in.
- A **facts file** (`c facts name:`) is the registry's file for a package:
  every clause in it is a claim and carries a citation, which the header
  alone says.
- A **convention profile** (`c convention name.vN:`) is a versioned set of
  rules that produce clauses by name pattern; a contract adopts one.
- A **facade** is not part of this language. The word means the
  hand-written With layer that presents a migrated engine as the standard
  library (D37, D148).

## 2. Subjects

A contract describes functions. Three kinds of function can be a subject.

| Subject | What it is | Status |
|---|---|---|
| An imported C function | a function, with its types and constants, that a `c_import` of the library's headers brings into scope | specified here; implemented |
| A corpus function | a function of a migrated engine: With source the migrator wrote from C, whose body proves part of its contract and whose remaining facts a person knows (claims.md tier 1) | not yet: the facts-file form is proposed, the migrator does not read it |
| A With function | a hand-written `unsafe fn`, whose caller today has only `unsafe` to say what it knows | not yet. The direction (Eric, 2026-11-11): clauses on an `unsafe fn`, written only in its defining module, with a clause the checker can prove refused as redundant. The expression `claim <fact>` (claims.md tier 2) is the same act at an expression and is specified with the language, not here |

Everything from section 3 on is written for the first subject. The clause
vocabulary is not specific to C: ownership, borrowing, retention,
destruction, nullability and thread capability are facts about any function
whose signature is raw. What is specific to C is where the declarations come
from (section 3) and the base rule (section 4).

A contract states nothing about a function the import does not bring: a name
beginning with `_`, or a function the header declares only under a macro the
import does not define. A contract that names one is an error. §16.2b.13.

## 3. Lexical structure

A contract is With source: With's tokens, comments and indentation (§29). It
adds no token. Its words (`contract`, `resource`, `wraps`, `from`, `drop`,
`lend`, and every other word in section 5) are **contextual**: each is a
word of the language only at the position the grammar gives it, and an
ordinary identifier everywhere else in a program. `c` is contextual in the
same way: `c contract`, `c facts` and `c convention` are each two names side
by side at a declaration start, a position no expression can occupy.

A block's body is indented under its header (§29.13 Form 2). An item's
clauses are indented under the item; a clause with sub-lines (the cases of a
variadic contract) indents them under itself.

A `//` comment after a clause is its citation where one is required
(section 9). Elsewhere it is a comment.

## 4. The base rule: what is raw

The language is defined against what an undescribed imported function is.
A call of it is **raw**, needing `unsafe`, when any of these holds, and safe
otherwise:

| What | Rule |
|---|---|
| A pointer parameter | raw. Its spelling, `const` included, proves nothing (§16.2b.5). A character pointer is no exception (§16.2b.8). |
| A pointer return | raw in the compiler today. §16.2b does not state this row; see section 13.6. |
| A parameter passed by value whose type holds a pointer | raw. A type holds a pointer when it is a pointer or function pointer, or a record, union or array with a member that holds one (§16.2b.5). Returning such a record is not raw: the value is inert until it goes back into C. |
| A function-pointer parameter, and a call through a function pointer | raw (§16.2b.9, §16.11). |
| A variadic function | raw: a variadic signature is an unmodeled contract (§16.3c). |
| A C global | one the header declares `const` or thread-local is safe to read in any program. Any other is safe to read or write when every call into the library that declares it and every access to its globals is provably on one thread, and the library's contract does not say `runs threads`; otherwise reading or writing it is raw. Assigning a global whose type holds a pointer is raw in every program; reading one is not (§16.3b). |
| A function over value records and scalars only | safe as imported. No clause is needed. |

A contract can only move a function from raw to safe by stating what the
base rule could not know, or leave it raw. It never makes a safe import raw
except by a restriction the program asks for.

The record a resource wraps is reached as `.repr`, and only so: `.repr` is
under these raw rules and needs `unsafe`. The record's own fields are read
through the resource without it (section 8.2). Of the fields of the type a
contract generates, `.repr` is the only one a program can name (§16.2b.3).

## 5. Grammar

```
unit            = contract | facts | convention

contract        = "c" "contract" name [ "error" TypeName ] ":" INDENT item+ DEDENT
facts           = "c" "facts" name ":" INDENT item+ DEDENT
convention      = "c" "convention" dotted_name ":" INDENT rule+ DEDENT

item            = resource | handle | fn_item | domain | library_clause
                | adoption | field_role

resource        = "resource" TypeName "wraps" type NEWLINE INDENT resource_clause+ DEDENT
handle          = "handle" TypeName "wraps" type
fn_item         = "fn" c_name NEWLINE [ INDENT fn_clause+ DEDENT ]
domain          = "domain" name domain_kind
domain_kind     = "process" | "thread" | "resource" | "static"
library_clause  = "text" "utf8" | "runs" "threads"
adoption        = "use" "convention" dotted_name
field_role      = "field" name "of" c_name "is" role
role            = "allocator" | "reallocator" | "deallocator" | "context"

resource_clause = production | destruction | status | dependency
                | capability | domain_use | presentation
production      = "from" c_name [ "(" "out" param_ref ")" ] [ "," field_check ]
                | "init" c_name [ "(" "self" ")" ]
                | "preinit" c_name [ "(" "self" ")" ]
field_check     = ( "nullable" | "nonnull" ) "field" field_path
destruction     = "drop" c_name | "destroys" c_name | "abandon" c_name
status          = "ok" CONST { "," CONST } | "message" c_name
dependency      = "borrows" param_ref | "independent"
capability      = "movable" | "thread" thread_cap { thread_cap }
thread_cap      = "creator" | "send" | "share" | "drop_any_thread"
domain_use      = "requires" "domain" name

fn_clause       = effect | return_clause | origin_clause | text_clause
                | buffer_clause | callback_clause | variadic | domain_clause
                | status | "valid" "on" "failed" | presentation
effect          = "lend" | "destroys"
                | "consumes" param_ref [ "destroyed_by" param_ref ]
                | "detaches" param_ref
                | "retains" param_ref "by" param_ref
                | ( "reads" | "fills" | "updates" ) param_ref
                | "nullable" param_ref
return_clause   = "returns" "borrow" TypeName "from" origin
                | "returns" "static" type
origin          = param_ref | "params" ref "," ref
                | "parent" TypeName "of" param_ref
                | "domain" name
origin_clause   = "preserves" param_ref | "preserves" "domain" name
text_clause     = "text" param_ref
                | "text" "return" "," "owned" "," "freed" "by" c_name
                | "text" "return" "bytes"
buffer_clause   = "buffer" param_ref ( "len" param_ref | "capacity" param_ref "inout" ) [ "elements" ]
callback_clause = "callback" "consumes" param_ref
                | "callback" param_ref "userdata" param_ref
                | "callback" param_ref "argv" param_ref "paired" "with" "argc" param_ref "as" type
                | "callbacks" "none" | "callback_thread" "any"
                | "user_data" "from" c_name "as" type
variadic        = "variadic" param_ref "selected" "by" param_ref ":" NEWLINE INDENT case+ DEDENT
case            = "case" CONST ":" case_body
case_body       = type [ retention ]
                | "callback" param_ref "as" type "userdata" "param" CONST
retention       = "retains" "by" param_ref
                  [ "length" "param" CONST "as" type ]
                  [ "until" name { "," name } ]
domain_clause   = "establishes" "domain" name | "ends" "domain" name | "requires" "domain" name
presentation    = "of" TypeName | "rename" name | param_ref "fixed" literal

param_ref       = "param" ( name | INTEGER | "type" type )
ref             = name | INTEGER
field_path      = name { "." name }
literal         = [ "-" ] INTEGER | "null" | "true" | "false"

rule            = name ":" ( "from" | "init" | "drop" | "destroys" ) pattern [ "(" ( "out" param_ref | "self" ) ")" ]
                | name ":" "fn" pattern ( "lend" | "destroys" )
pattern         = a name with "*" wildcards: "*_unref", "g_*_new"
```

`c_name` is the name of an imported function; `CONST` an imported
compile-time constant; `TypeName` a With type name the contract introduces
or names; `type` a With type expression over the imported types.

In the specification and not in the parser on main: `establishes`, `ends`
and `requires domain` (§16.2b.7, v7.49, D200), and `field … is role` in a
contract outside a facts file (decided 2026-11-11).

**A variadic case.** `case C: T` says that when the selector is `C` the
argument is one value of type `T`. `T retains by param N` says the resource
at `N` keeps it; `length param L as U` names the selector whose argument is
its length; `until a, b` names the operations that release it, and is
omitted when destruction and abandonment are the only releases. `case C:
callback param N as T userdata param U` says the argument is a callback of C
type `T` whose userdata is the argument of selector `U`. (§16.2b.5, D194.)

**A convention rule.** `name: from *_new` produces, for every imported
function the pattern matches, the clause it names on the resource `name`;
`name: fn *_get_* lend` produces an fn item. A rule that grants is
**unique-or-nothing**: zero matches contribute nothing, exactly one
contributes the clause, several contribute nothing, and the compiler never
chooses among matches. A profile is a package, versioned, never compiler
knowledge; adopting it is what makes its rules evidence, and a stated clause
overrides anything it produces. (§16.2b.12.)

## 6. What a clause is

Every clause has four properties. Section 8 gives them for each clause.

**6.1 Direction.** A clause **grants** when its being wrong can make safe
code unsafe: it gives ownership, destruction, consumption, retention,
independence, static lifetime, a success convention, a thread capability, a
non-null, an established state, or safety to a call that would otherwise be
raw. A clause **restricts** when its being wrong can only remove capability
or reject a valid program. A clause **presents** when it changes only the
name or shape under which a fact is written in With, never a fact.
(§16.2b.2, the asymmetry rule; mission law 4.)

**6.2 Default.** What holds when the clause is absent. A default is a
restriction: dependent, invalidating, nullable, bytes, creator-thread-bound,
the library's coarse domain, raw.

**Two defaults are grants, and are the known exceptions.**

- With no `runs threads`, the library is taken to run no thread of its own,
  which is one half of the proof that makes a C global safe to touch
  (§16.3). Leaving the clause out grants.
- With no `callback_thread any`, a retained callback is taken to run on the
  registering thread, so its captured state needs no send or share
  capability (§16.2b.10). Leaving the clause out grants.

Both are stated as restrictions in section 8 because writing them restricts.
Section 13.2 proposes removing both.

**6.3 Provenance.** Where the clause came from. Every effective clause
records it, and `with analyze … contract` prints it:

| Provenance | Meaning | Who vouches |
|---|---|---|
| `header` | an ABI or header fact: a type, a layout, a constant, a nullability annotation the header carries | the compiler, reading the header |
| `proof` | drawn by the compiler from the library's own source, with the proof printed beside it | the compiler |
| `annotation` | an ownership annotation the library ships (`__attribute__((malloc))`, `returns_nonnull`, an introspection file). It is the library author's word, not a proof | the library's author |
| `registry` | a line of the package's facts file, with its citation | the registry |
| `stated` | written in a contract in the program, the standard library or the runtime | the program (or the toolchain, for its own) |
| `profile` | produced by a rule of a convention profile the contract adopted | the profile's author, by the program's adoption |
| `default` | no clause; the restriction of 6.2 | nobody: it grants nothing, with the two exceptions of 6.2 |

A clause that grants and that the compiler does not vouch for is a claim
(section 9).

The contract view prints these words today as `clause`, `default`, `proof`,
`annotation`, `registry`; the rename to this table's words is part of the
keyword stack.

**6.4 Check.** What the compiler verifies of the clause against the
declarations, whatever its provenance (section 10), and what it checks when
the program runs (section 11).

## 7. Precedence

For one fact about one function, the effective clause is the first of:

```
header facts and proven contradictions      constrain everything below
stated                                       a contract the program writes
proof
annotation
registry                                     the package's facts file
profile
default
```

A stated clause refines, overrides or suppresses anything below it. It cannot
override a header fact. Two rules hold today for a grant a proof disagrees
with, and they differ by where the grant is written:

- **A stated clause** stands unless the compiler genuinely proves the
  asserted contract impossible; it never falls merely because the compiler
  reached a conclusion of its own (§16.2b.2).
- **A registry line** that contradicts a proof is an error naming both
  (§16.2b.15).

A clause that restates what is already effective from a lower line is
accepted and reported as redundant by the contract audit. Section 13.1
proposes one rule for both.

## 8. Clause reference

G = grants, R = restricts, P = presents.

### 8.1 Items

| Item | Meaning | Dir | Rule |
|---|---|---|---|
| `resource N wraps T` | `N` is a With ownership type whose representation `T` is foreign, in one of three forms: an opaque pointer, a by-value token, an in-place struct. It is not Copy, whatever C's copying of `T` is, and its destroyer runs once. | G | §16.2b.3 |
| `handle N wraps *mut T` | `N` is a callback-scope handle: C passes a `T *` to a callback and the handle is valid for that call. No clauses. | R | §16.2b.9 |
| `fn f` | `f` is described. With no clause it lends every parameter: it keeps nothing and frees nothing. This default is the contract's assertion, not a proof and not a conservative inference: an empty `fn f` is one claim, and is counted as one. | G | §16.2b.5 |
| `domain D kind` | `D` names ownerless C state with that extent. | R | §16.2b.7 |
| `text utf8` | every text return of the library presents as `Option[str]`, validated at the boundary; a return that is not UTF-8 is a contract failure naming the C function, and nothing is repaired. | G | §16.2b.8 |
| `runs threads` | the library runs threads of its own; its globals are shared with them. | R (absence grants, 6.2) | §16.3 |
| `use convention P` | the contract adopts profile `P`'s rules. | the rules' | §16.2b.12 |
| `field F of R is role` | a call through function-pointer field `F` of record `R` is an allocation (returns a fresh allocation the caller owns), a reallocation (consumes its argument and returns one), a deallocation (destroys its argument), or `F` is the hooks' own data (passing it to a hook is not an escape; a function that installs it retains it). A role is never drawn from a field's name. | G | §16.2b.15 |

**Hooks.** Hooks supplied when a resource is produced belong to that
resource. A function that replaces hooks shared by live resources stays raw
unless the contract states that each resource captures its hooks when
produced. (§16.2b.15.)

### 8.2 Resource clauses

| Clause | Meaning | Dir | Default when absent | Rule |
|---|---|---|---|---|
| `from f` | `f` returns a new `N` the caller owns. Whether its NULL means failure is a nullability fact about the return (below). | G | no producer; `N` cannot be made | §16.2b.4 |
| `from f(out param p)` | `f` stores a new `N` through `p`. The compiler sets the slot to NULL, calls `f`, and inspects it: non-null is a produced resource, owned at once, whatever the status says. | G | | §16.2b.4 |
| `from f, nullable field a.b` | a by-value producer: a NULL in field `a.b` of the result means nothing was produced; presents `Option[N]`. Checked when the call returns. | G | | §16.2b.4 |
| `from f, nonnull field a.b` | as above, and a NULL there is a contract failure naming `f`; presents `N`. | G | | §16.2b.4 |
| `init f(self)` | `f` initializes caller-provided storage in place; `N` is pinned: its representation has one address until destruction completes. | G | | §16.2b.4 |
| `preinit f` | `f` constructs the storage `init` fills. Without it the storage begins as the zeroed representation. | G | | §16.2b.4 |
| `drop f` | `f`, taking only the representation, destroys it; `Drop` calls it. | G | a resource with a producer and no destruction path is refused | §16.2b.3 |
| `destroys f` | `f` destroys the resource and takes further arguments; called explicitly, consuming. A resource with `destroys` and no `drop` is refused. | G | | §16.2b.3 |
| `abandon f` | `f`, which invokes no callbacks, runs before the destroyer on a drop path that abandons a half-configured callback pair. | G | | §16.2b.9 |
| `ok C1, C2` | the producers' status is success when it is one of these constants; with several, the `Ok` side carries the one that matched. A success status with nothing produced is `NothingProduced`, an error. | G | the status is uninterpreted: the constructor's result is `(status, Option[N])`. There is no rule that 0 means success | §16.2b.4 |
| `message f` | `f` describes the resource's most recent failure; an error from an operation on the resource carries `message: str`, an owned copy read before any other operation on it. | G | | §16.2b.4 |
| `borrows param p` | the product depends on the resource received at `p` and cannot outlive it. | R | every resource parameter of a producer is a dependency | §16.2b.6 |
| `independent` | the product depends on no parameter. | G | dependent | §16.2b.6 |
| `movable` | an in-place resource may move: no operation retains the representation's address. | G | pinned | §16.2b.3 |
| `thread send` / `share` / `drop_any_thread` | the resource may cross threads, be shared, be destroyed on any thread. `send` requires `drop_any_thread`. | G | `thread creator` | §16.2b.10 |
| `thread creator` | the default, written out. Accepted and reported as redundant. | R | | §16.2b.10 |
| `requires domain D` | the resource is a resource of `D`: live from its producer's return to its destroyer's call; its producers, destroyer and operations require `D`. | R | no domain | §16.2b.7 |

**Who owns "f destroys N".** Today both places state it, and each decides
(run 2026-11-11 on main):

- `destroys f` under `resource N`, with no fn item for `f`: accepted.
- `fn f` with a bare `destroys` and no resource clause naming `f`:
  accepted; `f` is presented as a consuming operation of the resource its
  first parameter receives.
- `destroys f` under the resource and `fn f` written with no `destroys`:
  refused ("a destroying operation must not be callable as a lend; state
  'destroys' on the fn item").

The tree uses both: 38 resource-level `destroys f` lines and 31 bare
fn-item `destroys` lines, including `lib/facades/sqlite3.w` and the
c-interop example. One fact has two spellings and the rule that reconciles
them is a refusal. Section 13.5 proposes one owner.

**The nullability of a pointer producer's return.** `NULL` is information.
A machine-readable annotation is used directly: a return the header or the
library marks nullable presents `Option[N]`, one marked non-null presents
`N`, and unknown nullability is nullable; it never silently becomes
non-null. No clause of the language states it for a pointer producer today;
the by-value producer has one (`nullable field`, `nonnull field`). Section
13.4. (§16.2b.8.)

**The fields of a resource's record.** A field of a by-value or in-place
resource's record is read through the resource (`image.width`): a read
copies the field's value, and is permitted wherever reading that field of
the bare record is permitted (a union member stays raw). Fields are not
assigned through the resource. A
field with the name of an operation the contract presents on the resource,
or the name `repr`, is an error until one is renamed. A pointer resource has
no such reads: reading through it is a claim about C's memory. (§16.2b.3.)

**A call of the `drop` by its imported name.** For a by-value resource the
producers, the operations and the `drop` are what their imported names mean,
and a call of the `drop` by its imported name consumes the resource:
`UnloadImage(image)` ends `image`. (§16.2b.5, §16.2b.11.)

### 8.3 Function clauses

| Clause | Meaning | Dir | Default when absent | Rule |
|---|---|---|---|---|
| `lend` | the function keeps and frees nothing of its resource parameters. | G | on a described fn: lend. On an undescribed function: section 4. | §16.2b.5 |
| `destroys` | the function destroys the resource its first parameter receives; presented as a consuming operation of that resource (see 8.2). | G | | §16.2b.5 |
| `consumes param p` | the callee takes ownership of what `p` receives. `destroyed_by param q` names the callback C later invokes to destroy it. If registration can fail without taking ownership the contract says when transfer occurs; absent that, the caller keeps ownership. | G | observed | §16.2b.5 |
| `detaches param p` | removes the value `p` borrows from its origin and yields it owned, dependent on that origin as a `borrows` child is. | G | | §16.2b.6 |
| `retains param p by param q` | the value at `p` must outlive the resource at `q`; ownership stays outside C. A modeled unregister may release it. | G | a retained pointer makes the function raw | §16.2b.5 |
| `reads param p` | `p` points to one value record the callee only reads; presents `&T`. | G | raw | §16.2b.5 |
| `fills param p` | the callee writes the record without reading it first; presents the operation's result. With passes `T.zeroed()`, so `T` must be zero-valid. | G | raw | §16.2b.5 |
| `updates param p` | the callee reads and writes the record; presents a `mut` parameter. | G | raw | §16.2b.5 |
| `nullable param p` | NULL is accepted at `p`; presents `Option`. Composes with `reads`: `Option[&T]`. | G | an input pointer the contract presents is non-null | §16.2b.8 |
| `returns borrow R from param p` | the result is a view of the resource at `p` and cannot outlive it. `from params p, q`: of both. `from parent T of param p`: of the resource `p`'s resource itself borrows from. `from domain D`: of that foreign state. | G | a returned pointer is raw | §16.2b.6 |
| `returns static T` | the result lives for the whole program. Never inferred from the absence of a visible owner. | G | raw | §16.2b.7 |
| `preserves param p` / `preserves domain D` | the call leaves views of that origin valid. C `const` does not establish it. | G | invalidates | §16.2b.7 |
| `text param p` | `p` is input text read to its NUL and not kept. | G | bytes | §16.2b.8 |
| `text return, owned, freed by f` | the result is new text the caller owns, released with `f`. | G | raw | §16.2b.8 |
| `text return bytes` | under `text utf8`, this result stays bytes. | R | | §16.2b.8 |
| `buffer param b len param n` | `b` and `n` are one input slice C only reads. `capacity param n inout`: one writable slice whose length C writes back. `elements`: the count is in elements, not bytes. Never inferred from the C types. | G | two unrelated parameters; the pointer is raw | §16.2b.8 |
| `callback param c userdata param u` | `c` is called with `u`; a With closure is passed as the pair. | G | raw | §16.2b.9 |
| `callback consumes param p` | the callback takes ownership of `p`. | G | | §16.2b.9 |
| `callback param c argv param a paired with argc param n as &[H]` | the callback's vector is a slice of handles. | G | | §16.2b.9 |
| `user_data from f as &U` | `f` returns the registered userdata. | G | | §16.2b.9 |
| `callbacks none` | the operation invokes no applicable callback. | G | may invoke callbacks | §16.2b.9 |
| `callback_thread any` | a retained callback may run on any thread. | R (absence grants, 6.2) | the registering thread | §16.2b.10 |
| `variadic param v selected by param s:` with cases | the arguments after the fixed ones are, for each selector value stated, what its case says. | G | raw | §16.2b.5 |
| `establishes domain D` | after the call returns, `D` is established. Wrong, every later `requires` passes against state that does not exist. | G | | §16.2b.7 |
| `ends domain D` | after the call, `D` is not established. | R | | §16.2b.7 |
| `requires domain D` | the operation needs `D` established. | R | | §16.2b.7 |
| `ok C` | this operation's status convention. | G | none | §16.2b.4 |
| `valid on failed` | the operation may be called on a resource whose production failed. | G | an operation needs a produced resource | §16.2b.4 |
| `of R` | the operation is presented on resource `R`. Required when its resource parameter's representation is wrapped by more than one resource. | P | the one resource that wraps the representation | §16.2b.3 |
| `rename n` | the With name of the operation. | P | the convention's shortening of the C name | §16.2b.11 |
| `param p fixed literal` | the presented operation omits `p` and always passes the literal. | P | | §16.2b.11 |

**Value records** (`reads`, `fills`, `updates`). The parameter points to one
complete record that is not a resource's representation. Three conditions,
each part of the clause:

1. **Flat.** The record holds no pointer and no function pointer, in itself
   or in any record, union or array inside it. A clause naming a record that
   holds one is refused: such a record is a resource, a buffer, or stays
   raw. The elements of an element-count buffer are flat in the same sense.
2. **No memory but the record's own.** The callee reads and writes no memory
   but the record's, and keeps neither the pointer nor any pointer derived
   from it; the address of a field kept in a static is retention.
3. **`fills` is zero-valid.** With passes `T.zeroed()`; the clause is
   refused on a record that is not zero-valid.

A pointer paired with a count is a buffer, not a value record. A pointer to
the representation of an in-place resource is not a value record: the
operation borrows that resource. (§16.2b.5, D198.)

## 9. Claims

A claim is a clause that grants and that the compiler does not vouch for: a
`stated` grant, a `registry` line, a `profile` match, an `annotation`. An
empty `fn f` is one claim: it asserts that `f` keeps and frees nothing.

1. **Claims are counted and printed.** `with analyze … contract` marks each
   claim and ends with the count, the program's own beside the registry's.
   The ceremony census counts them. `:user-programs-safe` reports the count
   for the release UAT fixtures and examples, so a rising number is visible.
2. **Where a citation is required.** In the registry (every line of a facts
   file), in the standard library, and in the runtime: a claim without one
   is refused with its line. In a program's own source it is not required:
   the clause is reviewed with the program.
3. **A claim in a user program is not refused.** D51 gives an application
   author the contract as the way to make their own C library safe; a
   fixture or an example may state a grant.
4. **No compiler tool writes a claim.** The drafter proves or leaves the
   function raw; the migrator proves or emits `unsafe`. A proof is never
   printed as a claim, and a claim is never printed as a proof.
5. **A registry claim applies only where no proof and no annotation
   decided.** It never widens a proof, and one a proof contradicts is an
   error naming the claim's line and the proof.
6. **A registry claim is pinned.** The lock records the registry commit and
   the facts file's digest.

## 10. Verification

For every contract the compiler checks, against the declarations and
independent of provenance (§16.2b.13):

1. **Names.** Every `c_name` is an imported function; every `CONST` an
   imported compile-time constant; every `param` reference resolves to one
   parameter of the function it is stated on, by name, index or unique type;
   a named domain exists.
2. **Shapes.** A producer returns the representation, or stores it through
   the stated out parameter; `drop` takes only the representation;
   `destroys` takes it first; an `ok` status is an integer; a `buffer`'s
   count is an integer; a `callback`'s parameter is callable; `consumes`
   names a compatible value. A destroyer parameter of type `void *` accepts
   every object-pointer representation and no function-pointer or by-value
   one.
3. **No half-model.** A resource with a producer has a destruction path; a
   resource with `destroys` has a `drop`; a destroyer is not callable as a
   borrow. A described operation that is still raw after the contract covers
   what it states (a variadic with no cases, a pointer the contract does not
   describe) is refused, naming what is left.
4. **One meaning per name.** One function has one contract; a block that
   restates it agrees word for word. A rendered type never shares a name
   with an imported one.
5. **Capabilities compose.** `send` without `drop_any_thread` is refused. A
   profile rule that grants resolves to exactly one function.
6. **Agreement with the header it is applied to.** A contract that names a
   declaration the import lacks is an error, never a silent return to raw.

Verification does not prove what requires trusting the foreign API: a
structurally valid and false contract is a trusted-boundary bug. A contract
is validated against the declarations on every build; ABI compatibility does
not imply semantic compatibility.

A contract that passes is **rendered**: the compiler generates the With
types and operations it states (§16.2b.11). A fact the checker accepted and
the renderer cannot express is a compiler defect, reported as one.

## 11. Run-time checks

Some clauses state a fact the compiler can test when the program runs. Each
is tested in every build, debug and release.

**A contract failure** takes the one failure path an index out of range
takes: today a panic, which prints its message and the calling chain and
exits with status 134. Its message names the function, the clause, and
where the clause came from:

```
panic: LoadImageFromScreen: `from LoadImageFromScreen, nonnull field data` (registry/c/raylib/facts.w:17): C returned it NULL
```

For a registry line the place is the facts file and line; for a stated
clause, the contract's file and line; for an annotation, the header's.

| Clause | Tested | A failure names |
|---|---|---|
| `from f, nonnull field a.b` | when `f` returns: the field is not NULL | `f` |
| `from f, nullable field a.b` | when `f` returns: a NULL is `None`, not a failure | |
| a pointer return marked non-null | when the function returns: it is not NULL (§16.2b.8 names the failure; no clause spells the fact, section 13.4) | the function |
| `text utf8` | when text returns: it is valid UTF-8 | the function |
| a `str` passed as C text (`text param p`, a `str` variadic case) | before the call: the text has no interior NUL, which a C string cannot carry | the function |
| `buffer … len` / `capacity` | before the call: the slice's length fits the C count type | the function |
| `buffer … capacity … inout` | after the call: the length C wrote back is within the capacity | the function |
| `requires domain D` | when the operation is called: `D` is established. Omitted where the compiler proves it; a live resource of `D` proves it, so only producers and functions that take no resource of `D` carry the test | the function |
| `establishes domain D` | when called: `D` is not already established | the call |
| `ends domain D` | when called: no resource of `D` is live | the call |

Not failures: a status that is not `ok` is an `Err`; a NULL in a `nullable`
position is `None`.

Where the compiler proves a test must fail (`requires` with `D` proven not
established; `ends` with a resource of `D` proven live), the call is a
compile error. For `ends` the error names the live resource and the fix.
(§16.2b.4, §16.2b.7, §16.2b.8.)

## 12. Open questions

1. **The `callback` field role** (#3124): a fifth role for a
   function-pointer field that holds the program's own function, whose
   arguments are lent for the call. It gets its own brief.
2. **Corpus functions as a subject** (section 2): the facts-file form of
   claims.md tier 1.
3. **With functions as a subject**: not yet; the direction is recorded in
   section 2.

## 13. Proposed rule changes

None of these is adopted. Sections 1 to 12 describe the rules as they are.

### 13.1 One precedence rule for a grant a proof disagrees with

**Current.** A registry line that contradicts a proof is an error naming
both. A stated clause stands unless the compiler proves the asserted
contract impossible (§16.2b.2, §16.2b.15; section 7).

**Proposed.** Now that a stated grant is a claim like a registry line, one
rule for every claim, wherever it is written:

- A proof **contradicts** a grant when it establishes a fact the grant
  denies: the grant says `lend` and the proof shows the function frees or
  stores the parameter; the grant says `from f` (a fresh allocation) and
  the proof shows every return is a part of a parameter; the grant says
  `returns static` and the proof shows the return is a freed block.
  A contradicted grant is an error naming the grant's line and the proof.
- A proof is **weaker** than a grant when it fails to establish what the
  grant says and establishes nothing against it: the proof stopped at a
  callee no unit defines, or at a function-pointer field no unit decides.
  A weaker proof changes nothing: the grant stands and is counted as a
  claim.

**What it breaks.** A program whose own contract states a grant the
drafter's proof contradicts compiles today and would stop compiling. No
such contract is known in the tree; the count needs a run of the drafter
over every stated contract's library source, which exists only for fetched
packages.

### 13.2 The two default grants

**Current.** With no `runs threads`, a library is taken to run no thread of
its own, which is half of the proof that makes its C globals safe to touch
(§16.3b). With no `callback_thread any`, a retained callback is taken to
run on the registering thread, so its captured state needs no send or
share capability (§16.2b.10).

**Proposed** (Eric's intent, 2026-11-11). The absence of evidence grants
nothing. A library states that it runs no threads, and a retained callback
states its thread, each a counted claim:

```
c facts zlib:
    runs no threads        // <citation: where the library's source or manual shows it starts no thread>

fn curl_easy_setopt
    variadic param 2 selected by param option:
        case CURLOPT_WRITEFUNCTION: callback param 2 as curl_write_callback userdata param CURLOPT_WRITEDATA
    callback_thread registering     // <citation: where the manual says which thread calls it>
```

`runs no threads` is the positive of `runs threads`; a contract states one
or neither, and with neither a C global of the library is raw.
`callback_thread registering` is the positive of `callback_thread any`;
with neither, a retained callback's captured state must be sendable and
shareable.

**What it breaks: the count** (published programs only: `uat/fixtures`,
`examples`, the README programs; `docs/blog` holds no program).

| What | Programs | Contract lines needed |
|---|---|---|
| Touches a C global | 0 found | 0 |
| Registers a retained callback capturing state that is not sendable | 1: `uat/fixtures/libcurl_main.w` (its sink closure captures and mutates the local `total`, and the easy handle retains it) | 1, in `lib/facades/libcurl.w`, which `uat/libcurl.uat` copies into the project: `callback_thread registering` on the write-callback case |
| Registers a retained callback capturing only sendable state | 2: `examples/c-interop/src/main.w` and its test (`create_function_v2` with a plain record) | 0 |

How the first row was counted: a search of the 7 UAT fixtures, the 48
example sources and the README for the globals C's standard library and
these seven libraries declare (`errno`, `stdin`, `stdout`, `stderr`,
`environ`, `optarg`, `tzname` and the like). It was not counted by
compiling each program and asking the checker which imported globals it
reads, which is the reliable count and needs each program's packages
fetched. The second and third rows were read from the programs.

The fixture's own text does not change in either case. The contract file a
UAT scenario copies does, by one line: that file is published with the
scenario, so it comes to Eric before it is edited.

**Fallback, if the count is judged painful.** Keep both defaults, except
that a library whose contract says `runs threads` gets no callback
default: its retained callbacks state their thread.

### 13.3 A contracted library with an undescribed teardown

**Current.** A function over scalars and value records is safe as imported
(section 4). `void engine_shutdown(void)` takes no pointer and is safe to
call, and it can invalidate every live resource of its library. This can
only bite a library whose contract declares resources, since resources come
only from contracts.

**Proposed (a candidate, not adopted).** Once a contract declares a
resource, a function of that library the contract does not describe is raw.

**What it breaks.**

- **raylib.** The registry's facts declare two resources (`ImageData`,
  `WaveData`). The spiral fixture and the spiral example call 19 raylib
  functions; the facts describe 3 (`LoadImageFromScreen`, `UnloadImage`,
  `GetImageColor`). The other 16 (`InitWindow`, `BeginDrawing`,
  `DrawCircle`, `ClearBackground`, `CloseWindow` and the rest) would become
  raw, and both published programs would need `unsafe`, which a user
  program never writes. To keep them safe the facts would describe every
  function a program may call, each bare `fn` a counted claim: raylib's
  header declares several hundred.
- **SDL.** `lib/facades/sdl.w` declares two resources. The SDL fixture calls
  `SDL_Init` and other undescribed functions directly; the same follows.

A narrower rule reaches the same danger with less breakage: only a function
the contract marks can end a resource's validity, which is what `ends
domain D` now states (§16.2b.7, D200). Under D200 a teardown the contract
describes is checked; the gap that remains is a teardown the contract's
author did not know about, and no rule about undescribed functions can
close that without making every undescribed function raw.

### 13.4 A clause for a pointer producer's non-null return

**Current.** §16.2b.8 says `nullable -> Option`, `nonnull -> direct value`,
and that a violated `nonnull` is a contract failure naming the C function.
For a by-value producer the contract spells it (`from f, nonnull field
a.b`). For a pointer producer nothing does: the fact comes only from an
annotation the library ships (`returns_nonnull`, `_Nonnull`), and without
one every pointer producer presents `Option[N]`.

**Proposed.** `from f, nonnull` on a pointer producer: presents `N`; a NULL
return is a contract failure naming `f`. `from f, nullable` states the
default and is redundant.

**What it breaks.** Nothing: it adds a grant. It is the `nonnull` claims.md
tier 1 asks for on a corpus function's return.

### 13.5 One owner for "f destroys N"

**Current.** Both spellings are accepted and each decides: `destroys f`
under `resource N`, and a bare `destroys` on `fn f`. Stated in both places
they must agree; `destroys f` on the resource with an fn item that lends is
refused. The tree has 38 resource-level lines and 31 fn-item lines.

**Proposed.** The fn item owns it: `destroys` is a fact about what a
function does with its parameter, like `consumes` and `lend`. The resource
keeps `drop f`, which is what `Drop` calls. `destroys f` on a resource is
refused, naming the fn-item form.

**What it breaks.** The 38 resource-level lines are respelled, among them
lines in `lib/facades/sqlite3.w` and its copy in the c-interop example, a
published program.

### 13.6 A pointer return: raw, or inert

**Current.** The compiler makes a function that returns a pointer raw
(`ci_function_requires_raw_abi`: a return type that is a pointer). §16.2b
does not say so. What it says is narrower: a parameter passed by value whose
type holds a pointer makes the function raw, and "returning such a record is
not raw: the value is inert until it goes back into C" (§16.2b.5). §16.11
states the boundary the same way: address computation is safe; memory
access or a validity assertion is unsafe. By both sentences a bare returned
pointer is as inert as a returned record that holds one: holding a `*mut T`
asserts nothing, and reading through it already needs `unsafe`.

So the specification does not draw the line the compiler draws, and gives
no reason for it.

**Two ways to make them agree.**

- **The return is inert.** A function whose only raw part is its pointer
  return is safe to call; the pointer is a raw pointer the program can hold,
  compare and pass back to raw code. What it loses: a program can then call
  `curl_easy_init()` safely and drop the pointer, a leak with no `unsafe` in
  sight; With calls leaking a defect. That is a reason, and it is about
  ownership, not about memory access.
- **The return is raw, and the chapter says why.** "A returned pointer may
  be the caller's to free; a call that discards it leaks, and a program that
  frees it twice corrupts memory. Until a contract says whose it is, the
  call is raw." The same reason then applies to a returned record that
  holds a pointer (raylib's `Image`), which §16.2b.5 calls inert: that
  sentence would change, and `LoadImage` without a contract would be raw.

**What each breaks.** The first makes safe a class of calls that are raw
today; no program stops compiling. The second makes raw every function
that returns a record holding a pointer and has no contract; the count
needs a run over the fetched libraries' headers.
