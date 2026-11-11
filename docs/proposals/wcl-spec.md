# The With Contract Language (WCL): formal specification, draft 2

Status: draft, not ready to bless (Eric's review, 2026-11-11). Nothing here
is normative. §16.2b of the specification is normative until a chapter of
this form lands. This draft changes no rule: it names the language, gives it
one grammar, and states for every clause what it grants, what stands when it
is absent, where it may come from, and what the compiler checks of it.

Two checks have not been done and are owed before blessing:

- **Grammar against the parser.** Section 5 was read against `Parser.w`
  production by production on 2026-11-11 (the item parser, the clause
  parser, the variadic case parser, the convention rule parser, on main at
  e33c3932a) and corrected: a `len` buffer is never `inout` and a `capacity`
  buffer always is; `preinit` takes `(self)` as `init` does; a borrow from
  two parameters names exactly two. What has not been done is the converse:
  a fixture that writes every production and is accepted by the compiler.
  That fixture belongs in the keyword stack, born with the new spelling.
- **Rows against §16.2b.** Each row of section 8 cites the subsection that
  owns its rule. Where a row and §16.2b disagree, §16.2b is right and the
  row is a defect in this draft.

Decided for this document (Eric, 2026-11-11): it becomes its own chapter,
with §16.2b reduced to an introduction that points at it; the provenance
words are renamed in the keyword stack; every unproven grant is a claim and
is counted; a field role may be stated in a program's contract; `thread
creator` written out is flagged redundant; `handle` keeps its word; a facts
file is headed `c facts NAME:`.

The keyword is written `contract` throughout. The compiler accepts
`c facade` until the keyword migrates.

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
| A With function | a hand-written `unsafe fn`, whose caller today has only `unsafe` to say what it knows | not yet: no form is proposed. The expression `claim <fact>` (claims.md tier 2) is the same act at an expression and is specified with the language, not here |

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
| A pointer return | raw: nothing says who owns it, how long it lives, or whether it is NULL. |
| A parameter passed by value whose type holds a pointer | raw. A type holds a pointer when it is a pointer or function pointer, or a record, union or array with a member that holds one (§16.2b.5). Returning such a record is not raw: the value is inert until it goes back into C. |
| A function-pointer parameter, and a call through a function pointer | raw (§16.2b.9, §16.11). |
| A variadic function | raw: a variadic signature is an unmodeled contract (§16.3c). |
| A C global | safe to read or write only where every call in the program that can reach the library is on one thread and the library runs no thread of its own; otherwise raw. A global whose type holds a pointer is raw in every program (§16.3). |
| A function over value records and scalars only | safe as imported. No clause is needed. |

A contract can only move a function from raw to safe by stating what the
base rule could not know, or leave it raw. It never makes a safe import raw
except by a restriction the program asks for.

Inside a rendered type, the record itself is reached as `.repr`, under these
raw rules; `.repr` is the one field of a rendered type a program can name,
and it needs `unsafe` (§16.2b.3).

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
Whether the absence of each should stay a grant is question 12.1.

**6.3 Provenance.** Where the clause came from. Every effective clause
records it, and `with analyze … contract` prints it:

| Provenance | Meaning | A claim? |
|---|---|---|
| `header` | an ABI or header fact: a type, a layout, a constant, a nullability annotation the header carries | no |
| `proof` | drawn by the compiler from the library's own source, with the proof printed beside it | no |
| `annotation` | an ownership annotation the library ships (`__attribute__((malloc))`, an introspection file) | no |
| `stated` | written in a contract in the program, the standard library or the runtime | yes, when it grants and no proof stands under it |
| `registry` | a line of the package's facts file, with its citation | yes |
| `profile` | produced by a rule of an adopted convention profile | yes |
| `default` | no clause; the restriction of 6.2 | no |

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
override a header fact. A proof overrides a stated clause only when it shows
the stated contract impossible, never because it reached a different
conclusion. A registry claim that contradicts a proof is an error naming
both. A clause that restates what is already effective from a lower line is
accepted and reported as redundant by the contract audit. (§16.2b.2,
§16.2b.15.)

## 8. Clause reference

G = grants, R = restricts, P = presents.

### 8.1 Items

| Item | Meaning | Dir | Rule |
|---|---|---|---|
| `resource N wraps T` | `N` is a With type that owns one value of representation `T`: a pointer to a record, an integer handle, a record passed by value, or a record initialized in place. It has identity: it moves, never copies, and its destroyer runs once. | G | §16.2b.3 |
| `handle N wraps *mut T` | `N` is a callback-scope handle: C passes a `T *` to a callback and the handle is valid for that call. No clauses. | R | §16.2b.9 |
| `fn f` | `f` is described. With no clause it lends every parameter: it keeps nothing and frees nothing. This default is the contract's assertion, not a proof and not a conservative inference. | G | §16.2b.5 |
| `domain D kind` | `D` names ownerless C state with that extent. | R | §16.2b.7 |
| `text utf8` | every text return of the library is valid UTF-8 and presents as `str`, validated at the boundary. | G | §16.2b.8 |
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
| `from f` | `f` returns a new `N` the caller owns. | G | no producer; `N` cannot be made | §16.2b.4 |
| `from f(out param p)` | `f` stores a new `N` through `p`. | G | | §16.2b.4 |
| `from f, nullable field a.b` | a by-value producer: a NULL in field `a.b` of the result means nothing was produced; presents `Option[N]`. Checked when the call returns. | G | | §16.2b.4 |
| `from f, nonnull field a.b` | as above, and a NULL there is a contract failure naming `f`; presents `N`. | G | | §16.2b.4 |
| `init f(self)` | `f` initializes caller-provided storage in place; `N` is pinned: its representation has one address until destruction completes. | G | | §16.2b.4 |
| `preinit f` | `f` constructs the storage `init` fills. Without it the storage begins as the zeroed representation. | G | | §16.2b.4 |
| `drop f` | `f`, taking only the representation, destroys it; `Drop` calls it. | G | a resource with a producer and no destruction path is refused | §16.2b.3 |
| `destroys f` | `f` destroys the resource and takes further arguments; called explicitly, consuming. A resource with `destroys` and no `drop` is refused. | G | | §16.2b.3 |
| `abandon f` | `f`, which invokes no callbacks, runs before the destroyer on a drop path that abandons a half-configured callback pair. | G | | §16.2b.9 |
| `ok C1, C2` | the producers' integer status is success when it is one of these constants. | G | no status convention; failure is `None` | §16.2b.4 |
| `message f` | `f` describes the resource's most recent failure. | P | | §16.2b.4 |
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
them is a refusal. Which one owns it is question 12.2.

**The fields of a resource's record.** A field of a by-value or in-place
resource's record is read through the resource (`image.width`): a read
copies the field's value. Fields are not assigned through the resource. A
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

A claim is a clause that grants and has no proof, annotation or header fact
under it: a `stated` grant, a `registry` line, a `profile` match.

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
is tested in every build, debug and release. A failed test is a **contract
failure**: the program stops, as it does for an index out of range, with a
message that names the function or the call the rule names.

| Clause | Tested | A failure names |
|---|---|---|
| `from f, nonnull field a.b` | when `f` returns: the field is not NULL | `f` |
| `from f, nullable field a.b` | when `f` returns: a NULL is `None`, not a failure | |
| `requires domain D` | when the operation is called: `D` is established. Omitted where the compiler proves it; a live resource of `D` proves it, so only producers and functions that take no resource of `D` carry the test. | the function |
| `establishes domain D` | when called: `D` is not already established | the call |
| `ends domain D` | when called: no resource of `D` is live | the call |
| `ok C` | when the function returns: the status is compared; a status that is not `ok` is an `Err`, not a failure | |
| `text utf8` | when text returns: it is validated; invalid UTF-8 is `None` or an error value, not a failure | |

Where the compiler proves a test must fail (`requires` with `D` proven not
established; `ends` with a resource of `D` proven live), the call is a
compile error. For `ends` the error names the live resource and the fix.
(§16.2b.4, §16.2b.7, §16.2b.8.)

## 12. Open questions

1. **The two default grants** (6.2). Whether a library must state that it
   runs no thread of its own before its globals are safe, and whether a
   retained callback must state its thread, or the present defaults stand.
   Changing either removes capability from programs that compile today.
2. **Who owns "f destroys N"** (8.2). Two candidates. The fn item owns it:
   `destroys` is a fact about what a function does with its parameter, like
   `consumes` and `lend`, and the resource-level `destroys f` goes; `drop f`
   stays on the resource because it is what `Drop` calls. Or the resource
   owns it and a bare fn-item `destroys` is refused. The first matches how
   every other effect is stated and removes the agree-or-refuse rule. Either
   way one spelling is deleted from about thirty-five lines of contracts,
   one of them a published example.
3. **The `callback` field role** (#3124): a fifth role for a
   function-pointer field that holds the program's own function, whose
   arguments are lent for the call. It needs its own brief.
4. **Corpus functions and With functions as subjects** (section 2): the
   forms. Tier 1 of claims.md is the proposal for the first.
5. **What a contract failure prints**, exactly, and whether it is the panic
   path (unwinding drops) or an abort. The specification says "a contract
   failure naming the function"; the form is not written anywhere.
