# The With Contract Language (WCL): formal specification, draft

Status: draft for Eric's blessing (2026-11-11). Nothing here is normative.
§16.2b of the specification is normative until these words, or the words
that replace them, land there. This draft changes no rule: it names the
language, gives it one grammar, and states for every clause what it grants,
what stands when it is absent, where it may come from, and what the compiler
checks of it. Where it restates a rule it cites the subsection that owns the
rule today. Section 11 lists every place where writing the rules down in one
form exposed a gap or a choice; those are the questions for the blessing.

The keyword is written `contract` throughout, as the ruling respells it. The
compiler accepts `c facade` until the keyword migrates.

## 1. Names

The **With Contract Language** is the language in which a With program, a
package registry, or the compiler's own evidence states what a C library's
functions do with memory, threads and state, so that calls of them are safe
With (D51).

- A **contract** is a block of it: `c contract name:`.
- A **clause** is a line of a contract.
- A **claim** is a clause that rests on a person's word rather than a proof.
- A **facts file** (`c facts name:`) is a contract every clause of which is a
  claim; each carries a citation. (On main the registry's files are headed
  `c facade name:`; `c facts` is the header this draft proposes, question
  11.9.)
- A **convention profile** (`c convention name.vN:`) is a named set of rules
  that produce clauses by pattern; a contract adopts one.
- A **facade** is not part of this language. The word means the hand-written
  With layer that presents a migrated engine as the standard library (D37,
  D148).

A contract describes **imported declarations**: the functions, types and
constants a `c_import` of the library's headers brings into scope. It states
nothing about a function the import does not bring (a name beginning with
`_`, a function the header declares only under a macro the import does not
define). §16.2b.13.

## 2. Lexical structure

A contract is With source: With's tokens, comments and indentation
(§29). It adds no token. Its words (`contract`, `resource`, `wraps`, `from`,
`drop`, `lend`, and every other word in section 4) are **contextual**: each
is a word of the language only at the position the grammar gives it, and an
ordinary identifier everywhere else in a program. `c` is contextual in the
same way: `c contract`, `c facts` and `c convention` are each two names side
by side at a declaration start, a position no expression can occupy.

A block's body is indented under its header (§29.13 Form 2). An item's
clauses are indented under the item; a clause that takes sub-lines (the
cases of a variadic contract) indents them under itself.

A `//` comment after a clause is, in a facts file, the clause's citation, and
is required there (section 7). Elsewhere it is a comment.

## 3. Grammar

```
unit            = contract | facts | convention

contract        = "c" "contract" name [ "error" TypeName ] ":" INDENT item+ DEDENT
facts           = "c" "facts" name ":" INDENT facts_item+ DEDENT
convention      = "c" "convention" dotted_name ":" INDENT rule+ DEDENT

item            = resource | handle | fn_item | domain | library_clause | adoption
facts_item      = resource | fn_item | domain | library_clause | field_role

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
                | "preinit" c_name
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
                | "consumes" param_ref [ "destroyed_by" param_ref ] | "detaches" param_ref
                | "retains" param_ref "by" param_ref | "retains" "by" param_ref
                | ( "reads" | "fills" | "updates" ) param_ref
                | "nullable" param_ref
return_clause   = "returns" "borrow" TypeName "from" ( param_ref | "params" param_list | "parent" TypeName "of" param_ref )
                | "returns" "static" type
origin_clause   = "preserves" param_ref | "preserves" "domain" name
text_clause     = "text" param_ref
                | "text" "return" "," "owned" "," "freed" "by" c_name
                | "text" "return" "bytes"
buffer_clause   = "buffer" param_ref ( "len" | "capacity" ) param_ref [ "inout" ] [ "elements" ]
callback_clause = "callback" "consumes" param_ref
                | "callback" param_ref "userdata" param_ref
                | "callback" param_ref "argv" param_ref "paired" "with" "argc" param_ref "as" type
                | "callbacks" "none" | "callback_thread" "any"
                | "user_data" "from" c_name "as" type
variadic        = "variadic" param_ref "selected" "by" param_ref ":" NEWLINE INDENT case+ DEDENT
case            = "case" CONST ":" type { case_fact }
domain_clause   = "establishes" "domain" name | "ends" "domain" name | "requires" "domain" name
presentation    = "of" TypeName | "rename" name | param_ref "fixed" literal

param_ref       = "param" ( name | INTEGER | "type" type )
param_list      = INTEGER { "," INTEGER }
field_path      = name { "." name }
literal         = [ "-" ] INTEGER | "null" | "true" | "false"

rule            = name ":" ( "from" | "init" | "drop" | "destroys" ) pattern [ "(" ( "out" param_ref | "self" ) ")" ]
                | name ":" "fn" pattern ( "lend" | "destroys" )
pattern         = name-with-one-"*"
```

`c_name` is the name of an imported function; `CONST` an imported
compile-time constant; `TypeName` a With type name the contract introduces
or names; `type` a With type expression over the imported types.

Not in the grammar on main today, and stated here because the specification
has them: `establishes`, `ends` and `requires domain` (§16.2b.7, v7.49).
`case_fact` is the set of facts a variadic case may carry (a callback pair, a
retainer with the operations `until` which the retention lasts, a length);
its productions are the callback and buffer clauses applied to the case's
argument (§16.2b.5).

The grammar was drawn from the parser (`Parser.w`, `parse_c_facade` and the
clause parser) and the examples of §16.2b, on main at 36ced4302. Each row of
section 6 is to be checked against the sentence of §16.2b that owns it
before this is blessed; where a row and §16.2b disagree, §16.2b is right and
the row is a defect in this draft.

## 4. What a clause is

Every clause has four properties. The table in section 6 gives them for each
clause.

**4.1 Direction.** A clause **grants** when its being wrong can make safe
code unsafe: it gives ownership, destruction, consumption, retention,
independence, static lifetime, a success convention, a thread capability, a
non-null, or safety to a call that would otherwise be raw. A clause
**restricts** when its being wrong can only remove capability or reject a
valid program. A clause **presents** when it changes only the name or shape
under which a fact is written in With, never a fact. (§16.2b.2, the asymmetry
rule; mission law 4.)

**4.2 Default.** What holds when the clause is absent. A default is always a
restriction: dependent, invalidating, nullable, bytes, creator-thread-bound,
the library's coarse domain, raw. No grant is a default.

**4.3 Provenance.** Where the clause came from. Every effective clause
records it, and `with analyze … contract` prints it:

| Provenance | Meaning |
|---|---|
| `header` | an ABI or header fact: a type, a layout, a constant, a nullability annotation the header carries |
| `stated` | written in a contract in the program or its package space |
| `proof` | drawn by the compiler from the library's own source, with the proof printed beside it |
| `annotation` | an ownership annotation the library ships (`__attribute__((malloc))`, an introspection file) |
| `claim` | a facts-file clause, with its citation |
| `profile` | produced by a rule of an adopted convention profile |
| `default` | no clause; the restriction of 4.2 |

**4.4 Check.** What the compiler verifies of the clause against the imported
declarations, whatever its provenance (section 8).

## 5. Precedence

For one fact about one function, the effective clause is the first of:

```
header facts and proven contradictions      constrain everything below
stated                                       a contract the program writes
proof
annotation
claim                                        the registry's facts file
profile
default
```

A stated clause refines, overrides or suppresses anything below it. It cannot
override a header fact. A proof overrides a stated clause only when it shows
the stated contract impossible, never because it reached a different
conclusion. A claim that contradicts a proof is an error naming both. A
clause that restates what is already effective from a lower line is accepted
and reported as redundant by the contract audit. (§16.2b.2, §16.2b.15.)

A stated clause and a claim are both a person's word. They differ in who is
answerable and so in where they stand: a stated clause is the program
author's, reviewed with the program, and stands above a proof; a claim is
the registry's, cited, reviewed once for every user, and stands below what
the library itself shows.

## 6. Clause reference

G = grants, R = restricts, P = presents. "May come from" lists the
provenances a clause of that kind is accepted from; a grant is never
accepted from `default`, and from `profile` only by a rule the contract
adopted.

### 6.1 Items

| Item | Meaning | Dir | Rule |
|---|---|---|---|
| `resource N wraps T` | `N` is a With type that owns one value of representation `T`: a pointer to a record, an integer handle, or a record passed by value. It has identity: it moves, never copies, and its destroyer runs once. | G | §16.2b.3 |
| `handle N wraps *mut T` | `N` is a callback-scope handle: C passes a `T *` to a callback and the handle is valid for that call. No clauses. | R | §16.2b.9 |
| `fn f` | `f` is described. With no clause it lends every parameter: it keeps nothing, frees nothing. | G | §16.2b.5 |
| `domain D kind` | `D` names ownerless C state with that extent. | R | §16.2b.7 |
| `text utf8` | every text return of the library is valid UTF-8 and presents as `str`, validated at the boundary. | G | §16.2b.8 |
| `runs threads` | the library runs threads of its own; its globals are shared with them. | R | §16.3 |
| `use convention P` | the contract adopts profile `P`'s rules. | (the rules') | §16.2b.12 |
| `field F of R is role` | a call through function-pointer field `F` of record `R` is an allocation, a reallocation, a deallocation, or `F` is the hooks' own data. Facts files only. | G | §16.2b.15 |

### 6.2 Resource clauses

| Clause | Meaning | Dir | Default when absent | Rule |
|---|---|---|---|---|
| `from f` | `f` returns a new `N` the caller owns. | G | no producer; `N` cannot be made | §16.2b.4 |
| `from f(out param p)` | `f` stores a new `N` through `p`. | G | | §16.2b.4 |
| `from f, nullable field a.b` | a by-value producer: a NULL in field `a.b` of the result means nothing was produced; presents `Option[N]`. | G | | §16.2b.4 |
| `from f, nonnull field a.b` | as above, and a NULL there is a contract failure naming `f`; presents `N`. | G | | §16.2b.4 |
| `init f(self)` | `f` initializes caller-provided storage in place; `N` is pinned. | G | | §16.2b.4 |
| `preinit f` | `f` constructs the storage `init` fills. | G | | §16.2b.4 |
| `drop f` | `f`, taking only the representation, destroys it; `Drop` calls it. | G | a resource with a producer and no `drop` or `destroys` is refused | §16.2b.3 |
| `destroys f` | `f` destroys the resource and takes further arguments; called explicitly, consuming. | G | | §16.2b.3 |
| `abandon f` | `f`, which invokes no callbacks, runs before the destroyer on a drop path that abandons a half-configured callback pair. | G | | §16.2b.9 |
| `ok C1, C2` | the producers' integer status is success when it is one of these constants. | G | no status convention; failure is `None` | §16.2b.4 |
| `message f` | `f` describes the resource's most recent failure. | P | | §16.2b.4 |
| `borrows param p` | the product depends on the resource received at `p` and cannot outlive it. | R | every resource parameter of a producer is a dependency | §16.2b.6 |
| `independent` | the product depends on no parameter. | G | dependent | §16.2b.6 |
| `movable` | an in-place resource may move. | G | pinned | §16.2b.3 |
| `thread send` / `share` / `drop_any_thread` | the resource may cross threads, be shared, be destroyed on any thread. `send` requires `drop_any_thread`. | G | `thread creator` | §16.2b.10 |
| `requires domain D` | the resource is a resource of `D`: live from its producer's return to its destroyer's call; its producers, destroyer and operations require `D`. | R | no domain | §16.2b.7 |

### 6.3 Function clauses

| Clause | Meaning | Dir | Default when absent | Rule |
|---|---|---|---|---|
| `lend` | the function keeps and frees nothing of its resource parameters. | G | on a described fn: lend. On an undescribed function: raw. | §16.2b.5 |
| `destroys` | the function destroys the resource it is given first. | G | | §16.2b.5 |
| `consumes param p` | the callee takes ownership of what `p` receives. `destroyed_by param q`: and releases it with the destroyer passed at `q`. | G | observed | §16.2b.5 |
| `detaches param p` | removes the value `p` borrows from its origin and yields it owned. | G | | §16.2b.5 |
| `retains param p by param q` | the resource at `q` keeps what `p` receives until `q` is destroyed; the value outlives the call and cannot outlive `q`. | G | a retained pointer makes the function raw | §16.2b.5 |
| `reads` / `fills` / `updates param p` | `p` is a pointer to a value record the function only reads, only writes, or both. | G | a pointer to a record with identity | §16.2b.5 |
| `nullable param p` | NULL is accepted at `p`; presents `Option`. | G | by direction: an input is non-null unless the header says otherwise | §16.2b.8 |
| `returns borrow R from param p` | the result is a view of the resource at `p` and cannot outlive it. `from params p, q`: of both. `from parent T of param p`: of the resource that `p`'s resource itself borrows from. | G | a returned pointer to a record is raw | §16.2b.6 |
| `returns static T` | the result lives for the whole program. | G | never inferred | §16.2b.7 |
| `preserves param p` / `preserves domain D` | the call leaves views of that origin valid. | G | invalidates | §16.2b.7 |
| `text param p` | `p` is input text read to its NUL and not kept. | G | bytes | §16.2b.8 |
| `text return, owned, freed by f` | the result is new text the caller owns, released with `f`. | G | raw | §16.2b.8 |
| `text return bytes` | under `text utf8`, this result stays bytes. | R | | §16.2b.8 |
| `buffer param b len param n` | `b` and `n` are one slice; `capacity`, `inout`, `elements` state the count's meaning. | G | two unrelated parameters; the pointer is raw | §16.2b.8 |
| `callback param c userdata param u` | `c` is called with `u`; a With closure is passed as the pair. | G | a function-pointer parameter is raw | §16.2b.9 |
| `callback consumes param p` | the callback takes ownership of `p`. | G | | §16.2b.9 |
| `callback param c argv param a paired with argc param n as &[H]` | the callback's vector is a slice of handles. | G | | §16.2b.9 |
| `user_data from f as &U` | `f` returns the registered userdata. | G | | §16.2b.9 |
| `callbacks none` | the operation invokes no applicable callback. | G | may invoke callbacks | §16.2b.9 |
| `callback_thread any` | a retained callback may run on any thread. | R | the registering thread | §16.2b.10 |
| `variadic param v selected by param s:` with `case C: T` | the arguments after the fixed ones are, for selector value `C`, one argument of type `T`. | G | a variadic call is raw | §16.2b.5 |
| `establishes domain D` | after the call returns, `D` is established. Establishing an established domain is a contract failure naming the call. | R | | §16.2b.7 |
| `ends domain D` | after the call, `D` is not established. With a resource of `D` live, a contract failure naming the call; a compile error where proven. | R | | §16.2b.7 |
| `requires domain D` | checked when called: a contract failure naming the function if `D` is not established. | R | | §16.2b.7 |
| `ok C` | this operation's status convention. | G | none | §16.2b.4 |
| `valid on failed` | the operation may be called on a resource whose production failed (`sqlite3_errmsg` on a database that did not open). | G | an operation needs a produced resource | §16.2b.4 |
| `of R` | the operation is presented on resource `R`. Required when its resource parameter's representation is wrapped by more than one resource. | P | the one resource that wraps the representation | §16.2b.11 |
| `rename n` | the With name of the operation. | P | the convention's shortening of the C name | §16.2b.11 |
| `param p fixed literal` | the presented operation omits `p` and always passes the literal. | P | | §16.2b.11 |

## 7. Claims

A claim is a clause with provenance `claim`: a line of a facts file.

1. **A claim carries a citation**, the `//` text after the clause, naming the
   source line or document that shows the fact. A facts line without one is
   refused with its line number. The cap on uncited claims is zero.
2. **A claim is written by a person.** No tool writes a facts line: the
   drafter proves or leaves the function raw, and the migrator proves or
   emits `unsafe`. A proof is never printed as a claim, and a claim is never
   printed as a proof.
3. **A claim applies only where no proof and no annotation decided.** It
   never widens a proof.
4. **A claim that a proof contradicts is an error** naming the claim's line
   and the proof.
5. **A claim is pinned.** The lock records the registry commit and the facts
   file's digest; a fetch that reads a different file says so.
6. **Claims are countable.** The contract view prints provenance per clause,
   so the claims a program rests on are a query, not a search.

A stated clause in a program's own contract is also a person's word. It
needs no citation: it is reviewed as the program is. (Open question 11.3.)

The expression form `claim <fact>` in With code (docs/proposals/claims.md,
tier 2) is the same act outside a contract. It is not part of WCL and is
specified with the language, not here.

## 8. Verification

For every contract the compiler checks, against the imported declarations
and independent of provenance (§16.2b.13):

1. **Names.** Every `c_name` is an imported function; every `CONST` an
   imported compile-time constant; every `param` reference a parameter of
   the function it is stated on, by name, index or unique type.
2. **Shapes.** A producer returns the representation, or stores it through
   the stated out parameter; `drop` takes only the representation;
   `destroys` takes it first; an `ok` status is an integer; a `buffer`'s
   count is an integer; a `callback`'s parameter is callable.
3. **No half-model.** A resource with a producer has a `drop` or a
   `destroys`. A described operation that is still raw after the contract
   covers what it states (a variadic with no cases, a pointer the contract
   does not describe) is refused, naming what is left.
4. **One meaning per name.** One function has one contract; a contract block
   that restates it must agree word for word. A rendered type never shares a
   name with an imported one.
5. **Capabilities compose.** `send` without `drop_any_thread`, a destroyer
   presented as a lend, a retained callback with no owner are refused.
6. **Agreement with the header it is applied to.** A contract that names a
   declaration the import lacks is an error, never a silent return to raw.

A contract that passes is **rendered**: the compiler generates the With
types and operations it states (§16.2b.11). A fact the checker accepted and
the renderer cannot express is a compiler defect, reported as one.

## 9. Where contracts come from

| Source | File | Provenance of its clauses |
|---|---|---|
| The program | a `c contract` block in its source, or `contracts/<name>.w` in the project | `stated` |
| A fetched package | `.with/deps/c/<name>/<version>/contract.w`, written by `with get` from the package's source, with its report beside it | `proof`, `annotation`, `claim`, each printed |
| The registry | `registry/c/<name>/facts.w`, read by `with get` | `claim` |
| The standard library and runtime | contract blocks beside the `c_import` or `extern` they describe | `stated` |

A fetched package's contract applies through every `c_import` that resolves
to a file inside the package, as if the program had named it. A program's
own block replaces any item it also states; the rest of the fetched contract
stands. (§16.2b.15.)

## 10. Tools

- `with analyze <file> contract` prints the effective contract with the
  provenance of every clause and the audit's findings.
- `with contract report c.<package> [<function>]` prints the same view for a
  fetched package's contract, and for each function left raw, why.
- `with migrate <dir> --contract <name>` drafts a contract from a C source
  tree, each clause with its proof.
- A drafted contract never states a grant it did not prove.

## 11. Questions the formal statement raises

Each is a place where §16.2b, read as one grammar, leaves a choice. None is
decided here.

1. **Where the normative text lives.** Three options: this document becomes
   a chapter of the specification and §16.2b is reduced to an introduction
   that points at it; §16.2b is rewritten in this form in place; or this
   stays a companion and §16.2b stays as it is. One owner per fact argues
   against the third.
2. **The provenance words.** The contract view prints `clause`, `default`,
   `proof`, `annotation`, `registry`. Section 4.3 writes `stated` and
   `claim` for `clause` and `registry`, following the ruling's vocabulary.
   Renaming them changes the view's text and the fixtures that snapshot it.
3. **Is a stated clause a claim?** The ruling says a claim is a clause that
   rests on a person's word rather than a proof. A grant written in a
   program's own contract is exactly that, and today needs no citation.
   Either "claim" means the facts-file form only (section 7 as written), or
   every unproven grant is a claim and the program's own are counted with
   the registry's. The second is the stricter reading and makes the census
   honest; it does not by itself require a citation in program source.
4. **`field … is role` in a program's contract.** It is accepted only in a
   facts file today. A program that links a library the registry does not
   describe has no place to state a field's role.
5. **The callback role** (the brief for #3124): a fifth role, `callback`,
   for a function-pointer field that holds the program's own function, whose
   arguments are lent for the call.
6. **`thread creator` as a written clause.** It is the default; writing it
   is redundant and is accepted. The grammar lists it; the audit could flag
   it as it flags other restatements.
7. **File and directory names after the rename.** `contract.w`,
   `contract-report.txt`, `contract.json`, a project's `contracts/`
   directory and the `contracts.<name>` module path are derived from the
   ruling, not stated in it.
9. **A facts file's header.** `c facts name:` (this draft) or `c contract
   name:`. The file is named `facts.w` either way. A distinct header lets
   the reader require a citation on every clause by the header alone.
8. **`handle`'s keyword.** A callback-scope handle is a kind of resource
   with no clauses. It keeps its own item word here because the parser has
   one; it could be `resource N wraps *mut T` with a `callback scope`
   clause. No change proposed.
