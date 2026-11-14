# 31. The With Contract Language

This chapter is normative. Where it differs from §16.2b it rules; §16.2b
opens with the list of those places and of its subsections that remain.

The body states the rules the compiler implements and the rules adopted on
2026-11-11. An adopted rule the compiler does not implement is marked
**adopted 2026-11-11, not yet implemented**: the product is non-compliant
with it until it lands. The order they land in is kept in
wcl-landing-order.md.

The keyword is written `contract` throughout (`c contract`, `c facts`).

> A foreign capability may enter safe With through a verified fact or an
> explicitly attributable trusted claim. The absence of evidence must not
> silently establish a memory-safety guarantee.

This is mission law 12 ("the programmer has the last word on what the
compiler cannot see") and law 4 ("a fact is inferred only when being wrong
cannot create unsafety") applied to foreign code: the compiler proves what
it can and restricts what it cannot; a person may take responsibility in
writing; the compiler records whose word each fact is.

## 31.1 Names

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

## 31.2 Subjects

A contract describes functions. Three kinds of function can be a subject.

| Subject | What it is | Status |
|---|---|---|
| An imported C function | a function, with its types and constants, that a `c_import` of the library's headers brings into scope | specified here; implemented |
| A corpus function | a function of a migrated engine: With source the migrator wrote from C, whose body proves part of its contract and whose remaining facts a person knows (claims.md tier 1) | not yet: the facts-file form is proposed, the migrator does not read it |
| A With function | a hand-written `unsafe fn`, whose caller today has only `unsafe` to say what it knows | not yet. The direction (Eric, 2026-11-11): clauses on an `unsafe fn`, written only in its defining module, with a clause the checker can prove refused as redundant. The expression `claim <fact>` (claims.md tier 2) is the same act at an expression and is specified with the language, not here |

Everything from §31.3 on is written for the first subject. The clause
vocabulary is not specific to C: ownership, borrowing, retention,
destruction, nullability and thread capability are facts about any function
whose signature is raw. What is specific to C is where the declarations come
from (§31.3) and the base rule (§31.4).

A contract states nothing about a function the import does not bring: a name
beginning with `_`, or a function the header declares only under a macro the
import does not define. A contract that names one is an error. §16.2b.13.

## 31.3 Lexical structure

A contract is With source: With's tokens, comments and indentation (§29). It
adds no token. Its words (`contract`, `resource`, `wraps`, `from`, `drop`,
`lend`, and every other word in §31.5) are **contextual**: each is a
word of the language only at the position the grammar gives it, and an
ordinary identifier everywhere else in a program. `c` is contextual in the
same way: `c contract`, `c facts` and `c convention` are each two names side
by side at a declaration start, a position no expression can occupy.

A block's body is indented under its header (§29.13 Form 2). An item's
clauses are indented under the item; a clause with sub-lines (the cases of a
variadic contract) indents them under itself.

A `//` comment after a clause is its citation where one is required
(§31.9). Elsewhere it is a comment.

## 31.4 The base rule: what is raw

The language is defined against what an undescribed imported function is.
A function a contract names, in an `fn` item or in a resource's `from`,
`init`, `drop`, `destroys`, `abandon` or `freed by`, is described. The base
rule does not apply to it: it has the meaning the contract gives it.
A call of it is **raw**, needing `unsafe`, when any of these holds, and safe
otherwise:

| What | Rule |
|---|---|
| A pointer parameter | raw. Its spelling, `const` included, proves nothing (§16.2b.5). A character pointer is no exception (§16.2b.8). |
| A pointer return | **inert: a function whose only raw part is a pointer return is safe to call**. A raw pointer in safe code cannot be read, freed or passed back to C without `unsafe` or a contract. A possible leak is not a reason to make the call raw: a returned record, descriptor or id leaks the same way. |
| A parameter passed by value whose type holds a pointer | raw. A type holds a pointer when it is a pointer or function pointer, or a record, union or array with a member that holds one (§16.2b.5). Returning such a record is not raw: the value is inert until it goes back into C. |
| A function-pointer parameter, and a call through a function pointer | raw (§16.2b.9, §16.11). |
| A variadic function | raw: a variadic signature is an unmodeled contract (§16.3c). |
| A C global | one the header declares `const` is safe to read in any program, and one it declares thread-local is safe to read and to write. Any other is safe to read or write when every call into the library that declares it and every access to its globals is provably on one thread, and the library runs no threads of its own: its contract says `runs no threads`, by a proof or by a claim (§31.8.1). Otherwise reading or writing it is raw. Assigning a global whose type holds a pointer is raw in every program; reading one is not (§16.3b). |
| A function over value records and scalars only | safe as imported. No clause is needed. |
| A proven invalidator | raw. Where the drafter proves that an undescribed function frees or resets memory reachable from a declared resource, a call of it is raw, with the proof printed, until a contract describes it. A function with no proof against it is unaffected. What a contract then writes is in §31.8.4. **Adopted 2026-11-11, not yet implemented.** |

A contract can only move a function from raw to safe by stating what the
base rule could not know, or leave it raw. It never makes a safe import raw
except by a restriction the program asks for. A proof can: the last row.

The record a resource wraps is reached as `.repr`, and only so: `.repr` is
under these raw rules and needs `unsafe`. The record's own fields are read
through the resource without it (§31.8.2). Of the fields of the type a
contract generates, `.repr` is the only one a program can name (§16.2b.3).

## 31.5 Grammar

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
library_clause  = [ "override" ] ( "text" "utf8" | "runs" [ "no" ] "threads" )
adoption        = "use" "convention" dotted_name
field_role      = [ "override" ] "field" name "of" c_name "is" role
role            = "allocator" | "reallocator" | "deallocator" | "context"

resource_clause = [ "override" ] ( production | destruction | status | dependency
                | capability | domain_use | presentation )
production      = "from" c_name [ "(" "out" param_ref ")" ] [ "," ( field_check | "nonnull" ) ]
                | "init" c_name [ "(" "self" ")" ]
                | "preinit" c_name [ "(" "self" ")" ]
field_check     = ( "nullable" | "nonnull" ) "field" field_path
destruction     = "drop" c_name | "destroys" c_name | "abandon" c_name
status          = "ok" CONST { "," CONST } | "message" c_name
dependency      = "borrows" param_ref | "independent"
capability      = "movable" | "thread" thread_cap { thread_cap }
thread_cap      = "creator" | "send" | "share" | "drop_any_thread"
domain_use      = "requires" "domain" name

fn_clause       = [ "override" ] ( effect | return_clause | origin_clause | text_clause
                | buffer_clause | callback_clause | variadic | domain_clause
                | status | "valid" "on" "failed" | presentation )
effect          = "lend"
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
                | "callbacks" "none" | "callback_thread" ( "any" | "registering" )
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
                | name ":" "fn" pattern "lend"
pattern         = a name with "*" wildcards: "*_unref", "g_*_new"
```

`override` is written only before a clause that grants (§31.6.1). Before
a clause that restricts or presents it is an error: there is nothing a proof
could be overridden about. It is not written before an item header; the
grant of an empty `fn f` is overridden by writing the `lend` out.

`c_name` is the name of an imported function. After `freed by`, `drop` and
`destroys` it may also be an imported global of function-pointer type
(§31.8.6). `CONST` is an imported
compile-time constant; `TypeName` a With type name the contract introduces
or names; `type` a With type expression over the imported types.

Adopted 2026-11-11 and not in the parser: `override` (§31.7).

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
`name: fn *_get_* lend` produces an fn item. A destroyer is named by a
resource rule (`name: destroys *_close`), never by an fn rule. A rule that grants is
**unique-or-nothing**: zero matches contribute nothing, exactly one
contributes the clause, several contribute nothing, and the compiler never
chooses among matches. A profile is a package, versioned, never compiler
knowledge; adopting it is what makes its rules evidence, and a stated clause
overrides anything it produces. (§16.2b.12.)

## 31.6 What a clause is

Every clause has four properties. §31.8 gives them for each clause.

**31.6.1 Direction.** A clause **grants** when its being wrong can make safe
code unsafe: it gives ownership, destruction, consumption, retention,
independence, static lifetime, a success convention, a thread capability, a
non-null, an established state, or safety to a call that would otherwise be
raw. A clause **restricts** when its being wrong can only remove capability
or reject a valid program. A clause **presents** when it changes only the
name or shape under which a fact is written in With, never a fact.
(§16.2b.2, the asymmetry rule; mission law 4.)

**31.6.2 Default.** What holds when the clause is absent. A default is a
restriction: dependent, invalidating, nullable, bytes, creator-thread-bound,
the library's coarse domain, raw.

**No default grants.** The absence of evidence grants nothing.

- A library's threads. A contract says `runs threads`, `runs no threads`, or
  neither. With neither, the library is not known to run no threads, and its
  C globals are raw (§31.4). `runs no threads` is a grant: it has
  provenance `proof` where the drafter proves it (§31.8.5) and is a
  counted claim where a person states it.
- A retained callback's thread. The registering function says
  `callback_thread any`, `callback_thread registering`, or neither. With
  neither, the callback may run on any thread, so its captured state must
  be sendable and shareable. `callback_thread registering` is a grant and a
  counted claim.

Today the compiler has both as default grants: with no `runs threads` a
library is taken to run none, and with no `callback_thread any` a retained
callback is taken to run on the registering thread.

**31.6.3 Provenance.** Where the clause came from. Every effective clause
records it, and `with analyze … contract` prints it:

| Provenance | Meaning | Who vouches |
|---|---|---|
| `header` | an ABI or header fact: a type, a layout, a constant, a nullability annotation the header carries | the compiler, reading the header |
| `proof` | drawn by the compiler from the library's own source, with the proof printed beside it | the compiler |
| `annotation` | an ownership annotation the library ships (`__attribute__((malloc))`, `returns_nonnull`, an introspection file). It is the library author's word, not a proof | the library's author |
| `registry` | a line of the package's facts file, with its citation | the registry |
| `stated` | written in a contract in the program, the standard library or the runtime | the program (or the toolchain, for its own) |
| `profile` | produced by a rule of a convention profile the contract adopted | the profile's author, by the program's adoption |
| `default` | no clause; the restriction of 6.2 | nobody: it grants nothing |

**A proof and the build it analyzed.** A proof about compiled foreign code
holds only for the build it analyzed. Where the analyzed source and the
linked artifact cannot be established as the same build, the result is
evidence, not proof: it is printed in the report, it grants nothing, and a
person may state the claim (§31.8.5, "The build that was proved").

A clause that grants and that the compiler does not vouch for is a claim
(§31.9). `override` is not a provenance: an overriding clause is
`stated`, and the view prints the marker and the proof it stands against
beside it (§31.7).

The contract view prints these words today as `clause`, `default`, `proof`,
`annotation`, `registry`; the rename to this table's words is part of the
keyword stack.

**31.6.4 Check.** What the compiler verifies of the clause against the
declarations, whatever its provenance (§31.10), and what it checks when
the program runs (§31.11).

## 31.7 Precedence

For one fact about one function, the effective clause is the first of:

```
header facts      constrain everything below; never overridden
stated            a contract the program, the standard library or the runtime writes
proof
annotation
registry          the package's facts file
profile
default
```

A stated clause refines, replaces or suppresses a proof, an annotation, a
registry line, a profile match and a default. It cannot change a header fact
(layout, types, constants). A stated restriction always stands over a proof
that would grant more. A stated grant stands too, with one condition, which
is not a level of this list: a proof must not contradict it.

**A grant and a proof** (adopted 2026-11-11; mission law 12. Implemented
for `lend` and `from` in a function or resource clause. Not yet
implemented: `returns static`, `runs no threads` and a field role against
a proof, the gate on a stale override, the citation in the standard
library and the runtime, and the counts in the census and
`:user-programs-safe`).

- A proof **contradicts** a grant when it establishes a fact the grant
  denies: the grant says `lend` and the proof shows the function frees or
  stores the parameter; the grant says `from f` and the proof shows every
  return is a part of a parameter; the grant says `returns static` and the
  proof shows the return is a freed block.
- A proof is **weaker** than a grant when it fails to establish what the
  grant says and establishes nothing against it: it stopped at a callee no
  unit defines, or at a function-pointer field no unit decides. A weaker
  proof changes nothing: the grant stands and is counted as a claim.
- A proof that contradicts a stated grant is an error, unless the clause is
  marked `override`. The marker is not a precedence level: it suppresses
  the contradiction error for that one clause, and the grant then stands as
  any stated clause does.
- The proofs a stated contract is held against are the ones `with get`
  recorded for the package it describes: a project's `contracts/<name>.w`
  against `contract-proofs.txt` of `c.<name>`. A package with none recorded
  contradicts nothing.
- `override` is available on every grant: a resource clause, a function
  clause, a library clause (`override runs no threads`, against a proof
  that the library starts a thread) and a field role. It applies only to
  grants.
- **A stale override is not an error.** An override with no contradicting
  proof is accepted, reported by the contract audit as stale, and counted
  in its own bucket. A contract must compile on compiler versions whose
  proofs differ, in both directions, including inside a dependency the user
  cannot edit: a newer compiler may prove what an older one could not, and
  an older one may lack the proof the override answers. The toolchain's own
  gate fails on a stale override in this tree.
- Only a stated contract may override. A facts file may not: a registry
  line that contradicts a proof is an error naming both. A header fact
  cannot be overridden.
- Run-time checks are unaffected. An override changes what the compiler
  trusts, not what it tests.
- Overrides are counted apart from claims, and stale overrides apart from
  both, in `with analyze … contract`, the census and the
  `:user-programs-safe` report. In the standard library and the runtime an
  override needs a citation.
- **No tool writes an override.** The contradiction error's help is prose,
  never a machine-applicable fix-it; the drafter, the migrator and `with
  fix` never produce one. A tool may delete a stale one.
- Every override is a possible compiler bug. The contradiction error prints
  the proof and says how to report a proof believed wrong; a report is
  treated as a compiler bug.

**The marker.** The word `override` before the clause:

```
c contract engine:
    override runs no threads   // engine.c 40: the worker is started only under ENGINE_ASYNC, which this build never defines
    fn engine_peek
        override lend      // engine.c 212: the store is into the caller's own scratch slot
    fn engine_reset
        override lend      // stale: nothing this compiler proves contradicts it
```

The error without the marker:

```
error: `lend` on `engine_peek` contradicts a proof: the function stores param 0
 --> src/contracts/engine.w:14:9
  = proof: engine_peek passes param 0 to cache_put at param 1 (engine.c:212), which stores it in a field (cache.c:88)
  = help: if the proof is wrong about this library, the clause can be marked `override`; the program then answers for the fact
  = help: a proof believed wrong is a compiler bug: report it with this message, the function and the library's version
```

Neither help line is a fix-it: no tool applies it.

The report, in `with analyze … contract` (the three counts are separate;
`clauses` is their sum with `proven`):

```
library engine; contract:engine@src/contracts/engine.w
    threads: runs no threads  [override@src/contracts/engine.w:2, against proof: engine_start calls pthread_create (engine.c:44)]
fn engine_peek; contract:engine@src/contracts/engine.w; clause:fn@src/contracts/engine.w:3
    effect: param 0: *mut engine e: lend  [override@src/contracts/engine.w:4, against proof: stores param 0 (cache.c:88)]
fn engine_reset; contract:engine@src/contracts/engine.w; clause:fn@src/contracts/engine.w:5
    effect: param 0: *mut engine e: lend  [stale override@src/contracts/engine.w:6: no proof contradicts it]
fn engine_name; contract:engine@src/contracts/engine.w; clause:fn@src/contracts/engine.w:7
    effect: param 0: *mut engine e: lend  [claim: stated@src/contracts/engine.w:7]
contract-audit: clauses=41 proven=28 claimed=10 overrides=2 stale-overrides=1
contract-audit: stale override at src/contracts/engine.w:6: `lend` on `engine_reset`; no proof contradicts it, so `override` can be deleted
```

A clause that restates what is already effective from a lower line is
accepted and reported as redundant by the contract audit.

## 31.8 Clause reference

G = grants, R = restricts, P = presents.

### 31.8.1 Items

| Item | Meaning | Dir | Rule |
|---|---|---|---|
| `resource N wraps T` | `N` is a With ownership type whose representation `T` is foreign, in one of three forms: an opaque pointer, a by-value token, an in-place struct. It is not Copy, whatever C's copying of `T` is, and its destroyer runs once. | G | §16.2b.3 |
| `handle N wraps *mut T` | `N` is a callback-scope handle: C passes a `T *` to a callback and the handle is valid for that call. No clauses. | R | §16.2b.9 |
| `fn f` | `f` is described. A described function lends the resource parameters whose mode nothing else decides: of those it keeps nothing and frees nothing. A resource's `drop` or `destroys` line decides the mode of that function's resource parameter. This default is the contract's assertion, not a proof and not a conservative inference: an `fn f` that lends by it is one claim, and is counted as one. | G | §16.2b.5 |
| `domain D kind` | `D` names ownerless C state with that extent. | R | §16.2b.7 |
| `text utf8` | every text return of the library presents as `Option[str]`, validated at the boundary; a return that is not UTF-8 is a contract failure naming the C function, and nothing is repaired. | G | §16.2b.8 |
| `runs threads` | the library runs threads of its own; its globals are shared with them. Accepted and reported as redundant once absence grants nothing (6.2); it stays the way to say so on the record. | R | §16.3 |
| `runs no threads` | the library's code runs, and its state is read or written, only on a thread on which the program has called into the library (§31.8.5), which is one half of what makes its C globals safe to touch (§31.4). A claim, stated or the registry's, until the closed-world proof of §31.8.5 exists; then also provenance `proof`. | G | §16.3 |
| `use convention P` | the contract adopts profile `P`'s rules. | the rules' | §16.2b.12 |
| `field F of R is role` | a call through function-pointer field `F` of record `R` is an allocation (returns a fresh allocation the caller owns), a reallocation (consumes its argument and returns one), a deallocation (destroys its argument), or `F` is the hooks' own data (passing it to a hook is not an escape; a function that installs it retains it). A role is never drawn from a field's name. | G | §16.2b.15 |

**Hooks.** Hooks supplied when a resource is produced belong to that
resource. A function that replaces hooks shared by live resources stays raw
unless the contract states that each resource captures its hooks when
produced. (§16.2b.15.)

### 31.8.2 Resource clauses

| Clause | Meaning | Dir | Default when absent | Rule |
|---|---|---|---|---|
| `from f` | `f` returns a new `N` the caller owns; presents `Option[N]`, a NULL being nothing produced. | G | no producer; `N` cannot be made | §16.2b.4 |
| `from f, nonnull` | a pointer producer that never returns NULL: presents `N`; a NULL return is a contract failure naming `f`. | G | `Option[N]` | §16.2b.8 |
| `from f(out param p)` | `f` stores a new `N` through `p`. The compiler sets the slot to NULL, calls `f`, and inspects it: non-null is a produced resource, owned at once, whatever the status says. | G | | §16.2b.4 |
| `from f, nullable field a.b` | a by-value producer: a NULL in field `a.b` of the result means nothing was produced; presents `Option[N]`. Checked when the call returns. | G | | §16.2b.4 |
| `from f, nonnull field a.b` | as above, and a NULL there is a contract failure naming `f`; presents `N`. | G | | §16.2b.4 |
| `init f(self)` | `f` initializes caller-provided storage in place; `N` is pinned: its representation has one address until destruction completes. | G | | §16.2b.4 |
| `preinit f` | `f` constructs the storage `init` fills. Without it the storage begins as the zeroed representation. | G | | §16.2b.4 |
| `drop f` | `f`, taking only the representation, destroys it; `Drop` calls it. | G | a resource with a producer and no destruction path is refused | §16.2b.3 |
| `destroys f` | `f` destroys the resource and takes further arguments; called explicitly, consuming. A resource with `destroys` and no `drop` is refused. The resource owns this fact, with `from`, `init`, `drop` and `abandon`. | G | | §16.2b.3 |
| `abandon f` | `f`, which invokes no callbacks, runs before the destroyer on a drop path that abandons a half-configured callback pair. | G | | §16.2b.9 |
| `ok C1, C2` | the producers' status is success when it is one of these constants; with several, the `Ok` side carries the one that matched. A success status with nothing produced is `NothingProduced`, an error. | G | the status is uninterpreted: the constructor's result is `(status, Option[N])`. There is no rule that 0 means success | §16.2b.4 |
| `message f` | `f` describes the resource's most recent failure; an error from an operation on the resource carries `message: str`, an owned copy read before any other operation on it. | G | | §16.2b.4 |
| `borrows param p` | the product depends on the resource received at `p` and cannot outlive it. | R | every resource parameter of a producer is a dependency | §16.2b.6 |
| `independent` | the product depends on no parameter. | G | dependent | §16.2b.6 |
| `movable` | an in-place resource may move: no operation retains the representation's address. | G | pinned | §16.2b.3 |
| `thread send` / `share` / `drop_any_thread` | the resource may cross threads, be shared, be destroyed on any thread. `send` requires `drop_any_thread`. | G | `thread creator` | §16.2b.10 |
| `thread creator` | the default, written out. Accepted and reported as redundant. | R | | §16.2b.10 |
| `requires domain D` | the resource is a resource of `D`: live from its producer's return to its destroyer's call; its producers, destroyer and operations require `D`. | R | no domain | §16.2b.7 |

**Who owns "f destroys N".** The resource does: `drop f` or `destroys f` under `resource N` decides the mode
of `f`'s resource parameter. An fn item for `f` carries its other clauses,
does not repeat the fact, and an explicit `lend` on it is an error. A
`destroys` on an fn item is refused, naming the resource form.

```
resource Engine wraps *mut RawEngine
    from engine_new
    drop engine_free
    destroys engine_close
fn engine_close
    rename close
```

**The nullability of a pointer producer's return.** `NULL` is information.
A machine-readable annotation is used directly: a return the header or the
library marks non-null presents `N`. Otherwise the contract says so with
`from f, nonnull`, and unknown nullability is nullable: it never silently
becomes non-null. (§16.2b.8.)

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

### 31.8.3 Function clauses

| Clause | Meaning | Dir | Default when absent | Rule |
|---|---|---|---|---|
| `lend` | the function keeps and frees nothing of its resource parameters. An error on a function a resource's `drop` or `destroys` names. | G | on a described fn: lend, for the resource parameters whose mode nothing else decides. On an undescribed function: §31.4. | §16.2b.5 |
| `consumes param p` | the callee takes ownership of what `p` receives. `destroyed_by param q` names the callback C later invokes to destroy it. If registration can fail without taking ownership the contract says when transfer occurs; absent that, the caller keeps ownership. | G | observed | §16.2b.5 |
| `detaches param p` | removes the value `p` borrows from its origin and yields it owned, dependent on that origin as a `borrows` child is. | G | | §16.2b.6 |
| `retains param p by param q` | the value at `p` must outlive the resource at `q`; ownership stays outside C. A modeled unregister may release it. | G | a retained pointer makes the function raw | §16.2b.5 |
| `reads param p` | `p` points to one value record the callee only reads; presents `&T`. | G | raw | §16.2b.5 |
| `fills param p` | the callee writes the record without reading it first; presents the operation's result. With passes `T.zeroed()`, so `T` must be zero-valid. | G | raw | §16.2b.5 |
| `updates param p` | the callee reads and writes the record; presents a `mut` parameter. | G | raw | §16.2b.5 |
| `nullable param p` | NULL is accepted at `p`; presents `Option`. Composes with `reads`: `Option[&T]`. | G | an input pointer the contract presents is non-null | §16.2b.8 |
| `returns borrow R from param p` | the result is a view of the resource at `p` and cannot outlive it. `from params p, q`: of both. `from parent T of param p`: of the resource `p`'s resource itself borrows from. `from domain D`: of that foreign state. | G | the call is safe and the result is a raw pointer | §16.2b.6 |
| `returns static T` | the result lives for the whole program. Never inferred from the absence of a visible owner. | G | the call is safe and the result is a raw pointer | §16.2b.7 |
| `preserves param p` / `preserves domain D` | the call leaves views of that origin valid. `preserves domain D` also says the call leaves `D` established and every resource of `D` valid (adopted 2026-11-11, §31.8.4). C `const` does not establish it. | G | invalidates | §16.2b.7 |
| `text param p` | `p` is input text read to its NUL and not kept. | G | bytes | §16.2b.8 |
| `text return, owned, freed by f` | the result is new text the caller owns, released with `f`. | G | the call is safe and the result is a raw pointer | §16.2b.8 |
| `text return bytes` | under `text utf8`, this result stays bytes. | R | | §16.2b.8 |
| `buffer param b len param n` | `b` and `n` are one input slice C only reads. `capacity param n inout`: one writable slice whose length C writes back. `elements`: the count is in elements, not bytes. Never inferred from the C types. | G | two unrelated parameters; the pointer is raw | §16.2b.8 |
| `callback param c userdata param u` | `c` is called with `u`; a With closure is passed as the pair. | G | raw | §16.2b.9 |
| `callback consumes param p` | the callback takes ownership of `p`. | G | | §16.2b.9 |
| `callback param c argv param a paired with argc param n as &[H]` | the callback's vector is a slice of handles. | G | | §16.2b.9 |
| `user_data from f as &U` | `f` returns the registered userdata. | G | the call is safe and the result is a raw pointer | §16.2b.9 |
| `callbacks none` | the operation invokes no applicable callback. | G | may invoke callbacks | §16.2b.9 |
| `callback_thread any` | a retained callback may run on any thread. The default, written out: accepted and reported as redundant once absence grants nothing (6.2). | R | any thread: the captured state must be sendable and shareable | §16.2b.10 |
| `callback_thread registering` | a retained callback runs only on the thread that registered it, so its captured state needs no send or share capability. True only while the retaining resource cannot change threads: refused where that resource is `thread send` (§31.10, rule 5). | G | any thread | §16.2b.10 |
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

### 31.8.4 Describing a proven invalidator

(Adopted 2026-11-11, not yet implemented.) The drafter has proven that `f`,
which no contract describes, frees or resets memory reachable from a
declared resource `N`; a call of `f` is raw until a contract describes it
(§31.4). The proof names one fact, and a contract answers that fact. An
override names the specific fact disputed. It is never a general exemption
from analysis: no clause says "do not analyze `f`".

**The author agrees with the proof.** The honest description is one of:

| What `f` does | The contract writes |
|---|---|
| takes an `N` and destroys it | `drop f` or `destroys f` under `resource N` |
| takes an `N` and resets it: the `N` stays valid, what was borrowed from it does not | `fn f` with no `preserves`: a described function lends its resource parameter and invalidates its views, which is the default |
| takes no `N` and tears down state every `N` depends on | `ends domain D` on `fn f`, with `requires domain D` on `resource N`. The call is then checked: a live `N` is a contract failure, or a compile error where the compiler proves one live (§31.11) |

**The author disputes the proof.** The grant that denies the proven fact is
written, marked `override`:

| The proof says | The contract writes |
|---|---|
| `f` frees or stores the `N` it is passed | `override lend` on `fn f` |
| `f` invalidates what was borrowed from the `N` it is passed | `override preserves param p` on `fn f` |
| `f`, which takes no `N`, frees or resets memory reachable from every `N` | `override preserves domain D` on `fn f`, where `resource N` says `requires domain D` |

**`f` takes no resource and the contract declares no domain.** There is
then no clause for the marker to sit on, and the contract gains one by
saying what is true: state that a function with no resource parameter can
free is ownerless state every `N` depends on, which is what a domain is.
The contract declares it, puts `N` in it, and then agrees or disputes as
above:

```
c contract engine:
    domain engine process
    resource Engine wraps *mut RawEngine
        requires domain engine
        from engine_new
        drop engine_free
    fn engine_shutdown
        ends domain engine                  // agreeing with the proof
    fn engine_trim
        override preserves domain engine    // disputing it: cache.c 310, trim frees only unreferenced pages
```

**When the domain is established.** A domain that no function
`establishes` is established from the start of the program until a call
that `ends` it, and never again after that. So where a contract declares a
domain for this purpose:

- with no function that `ends` it, the domain is always established and
  `engine_new` carries no run-time check;
- with a function that `ends` it, `engine_new` carries the `requires
  domain` check of §31.11. After the ending call, a call of
  `engine_new` is a contract failure naming `engine_new`, and a compile
  error where the compiler proves the domain ended.

**What `preserves domain D` covers** (adopted 2026-11-11; §16.2b.7 defines
preservation over views only, and gains this sentence):

> `preserves domain D` states that the call leaves `D` established, and
> leaves valid every view of `D` and every resource of `D`.

### 31.8.5 `runs no threads`: the property and its proof

**The property.** `runs no threads` does not mean "starts no thread". It
means:

> The library's code runs, and the library's state is read or written, only
> on a thread on which the program has called into the library.

Initialization that completes before the program's `main` begins is
outside the property: no thread of the program exists yet, and nothing the
program does can observe it.

That is the fact the global rule of §31.4 needs: with it, and with
every call into the library proven to be on one thread, one thread touches
the library's state. A library can start no thread and still fail it: by
handing its own function, or the address of its own state, to code that
uses it later from another thread.

**The proof is specified here and not built.** The analysis produces no
provenance `proof` for this clause. A library has `runs no threads` only
from a stated claim or a registry claim, counted as one.

**The proof** (adopted 2026-11-11, not implemented) is closed-world: it
holds only when the drafter has seen everything the library can reach. It
holds when all of these hold, and fails otherwise, naming the first thing
that failed. With no proof the clause is not written.

1. **Every unit was read.** A unit of the build the drafter could not parse
   fails the proof, naming the unit.
2. **Every outside function is known.** Every function the library calls,
   or takes the address of, that no unit defines is on the list of known
   synchronous functions below. Any other fails the proof, naming it. This
   is what makes the proof closed: a function that starts a thread, loads
   code, registers a handler, or keeps a pointer for later is simply not on
   the list.
3. **No inline assembly.** An assembly statement or a file-scope assembly
   block in any unit fails the proof: it can make a system call the
   drafter cannot read.
4. **Every indirect call resolves.** A call through a pointer reaches a
   function whose address something took. An address taken inside the
   library is a reference, and rule 2 has judged it. A pointer the program
   supplied (a callback parameter, or a function-pointer field or global
   the contract gives a role) is the program's code, run on the calling
   thread. Any other source fails the proof: a pointer returned or written
   by an outside function, or read from a record or a global that a header
   outside the package defines.
5. **No OpenMP directive.** A construct that creates a team starts threads
   through a call the source does not show.
6. **Every automatic entry point is recognized and judged.** An automatic
   entry point is code of the library that runs without the program
   calling it. The analysis looks for them in every unit:
   - A function with the `constructor` attribute is allowed: in a library
     linked into the program it runs to completion before `main`, which is
     outside the property. Its body is library code and rules 2 to 5 judge
     it.
   - A function with the `destructor` attribute fails the proof, for the
     reason `atexit` is excluded: it runs on whichever thread exits the
     program.
   - A Windows `DllMain` fails the proof: the loader calls it on every
     thread that starts or exits.
   - An entry point the analysis does not recognize fails the proof. A
     `section` attribute or pragma on a function or on an object that
     holds a function's address, an `init` or `fini` pragma, and an
     attribute the analysis does not know on a function definition are
     each taken as one: placing a function's address in an initializer,
     terminator or thread-local-callback section (`.init_array`,
     `.fini_array`, `.ctors`, `.dtors`, `__mod_init_func`,
     `__mod_term_func`, `.CRT$X…`) is how an entry point is made without
     the two attributes.

**The known synchronous functions.** A function is on this list when it
does all of its work before it returns, on the thread that called it: it
starts no thread, calls a function it was given only before it returns,
and keeps no pointer it was given for use after it returns. (Two listed
exceptions keep a function for later; each is explained.) A header named
whole means the functions ISO C declares in it, not what a platform adds
to it (`putenv`, which keeps the string it is given, is POSIX and is not
on the list).

| Group | Functions |
|---|---|
| ISO C, by header | every function of `<assert.h>`, `<complex.h>`, `<ctype.h>`, `<fenv.h>`, `<inttypes.h>`, `<locale.h>`, `<math.h>`, `<setjmp.h>`, `<stdatomic.h>`, `<stdio.h>`, `<stdlib.h>`, `<string.h>`, `<time.h>`, `<uchar.h>`, `<wchar.h>`, `<wctype.h>`, **except** the six below |
| ISO C `<threads.h>` | only `call_once`, `mtx_init`, `mtx_lock`, `mtx_timedlock`, `mtx_trylock`, `mtx_unlock`, `mtx_destroy`, `cnd_init`, `cnd_signal`, `cnd_broadcast`, `cnd_wait`, `cnd_timedwait`, `cnd_destroy`, `tss_create`, `tss_get`, `tss_set`, `tss_delete`, `thrd_current`, `thrd_equal`, `thrd_yield`, `thrd_sleep` |
| Compiler builtins | `__builtin_X` where `X` is on this list, and a builtin the compiler expands in place (`__builtin_expect`, `__builtin_clz`, `__builtin_bswap32`, the overflow and atomic builtins) |
| POSIX strings and memory | `strdup`, `strndup`, `strnlen`, `strcasecmp`, `strncasecmp`, `stpcpy`, `stpncpy`, `strtok_r`, `strlcpy`, `strlcat`, `memccpy`, `memmem`, `posix_memalign`, `mmap`, `munmap`, `mprotect`, `madvise`, `sysconf`, `getpagesize` |
| POSIX files | `open`, `openat`, `close`, `read`, `write`, `pread`, `pwrite`, `readv`, `writev`, `lseek`, `fstat`, `stat`, `lstat`, `fstatat`, `access`, `unlink`, `rename`, `mkdir`, `rmdir`, `opendir`, `readdir`, `closedir`, `dup`, `dup2`, `pipe`, `fcntl`, `ftruncate`, `fsync`, `isatty`, `getcwd`, `fileno`, `fdopen` |
| POSIX time and identity | `clock_gettime`, `gettimeofday`, `nanosleep`, `usleep`, `sleep`, `getpid`, `getuid`, `geteuid` |
| POSIX sockets | `socket`, `connect`, `bind`, `listen`, `accept`, `send`, `recv`, `sendto`, `recvfrom`, `shutdown`, `setsockopt`, `getsockopt`, `getaddrinfo`, `freeaddrinfo`, `select`, `poll` |
| POSIX thread synchronization | `pthread_once`, `pthread_self`, `pthread_equal`, `pthread_mutex_init`, `pthread_mutex_destroy`, `pthread_mutex_lock`, `pthread_mutex_trylock`, `pthread_mutex_unlock`, the `pthread_mutexattr_*`, `pthread_rwlock_*` and `pthread_cond_*` functions, `pthread_key_create`, `pthread_key_delete`, `pthread_getspecific`, `pthread_setspecific` |
| Windows | `HeapAlloc`, `HeapReAlloc`, `HeapFree`, `GetProcessHeap`, `VirtualAlloc`, `VirtualFree`, `CreateFileA`, `CreateFileW`, `ReadFile`, `WriteFile`, `CloseHandle`, `GetLastError`, `SetLastError`, `InitializeCriticalSection`, `EnterCriticalSection`, `LeaveCriticalSection`, `DeleteCriticalSection`, `InitOnceExecuteOnce`, `TlsAlloc`, `TlsGetValue`, `TlsSetValue`, `TlsFree`, `QueryPerformanceCounter`, `QueryPerformanceFrequency`, `GetTickCount64`, `Sleep`, `GetCurrentThreadId`, `GetCurrentProcessId` |

**The ISO C functions that are not on it.** Every function of the headers
named whole was checked against the definition. Six fail it:

| Function | Why it fails |
|---|---|
| `atexit`, `at_quick_exit` | keep a function; it runs on whichever thread exits the program |
| `set_constraint_handler_s` | keeps a function; it runs on whichever thread next violates a run-time constraint |
| `setbuf`, `setvbuf` | keep the buffer they are given; the C library reads and writes it on whichever thread next uses the stream |
| `strtok` | keeps a pointer into the string it is given, in state the whole process shares; a later `strtok(NULL, …)` on any thread reads and writes that string |

These keep or return a pointer and are on the list, each for a reason:

- `qsort`, `bsearch` (and `qsort_s`, `bsearch_s`) call the function they
  are given, and only before they return.
- `getenv`, `setlocale`, `localeconv`, `strerror`, `tmpnam`, `asctime`,
  `ctime`, `gmtime`, `localtime` return a pointer into the C library's own
  storage. They keep nothing they were given. What the library does with
  the result is its own code, on the calling thread.
- `mbrtowc`, `wcrtomb` and the other restartable conversions use the state
  they are given, or their own, only during the call. `wcstok` and
  `strtok_s` store their position through a pointer the caller supplies.
- `fopen`, `freopen`, `tmpfile` return a stream the C library owns; they
  keep no pointer they were given. A stream the library hands to the
  program is a pointer in a signature, and the base rule covers it.
- `longjmp` does not return: it transfers control on the calling thread.
  `exit`, `quick_exit`, `_Exit`, `abort` end the program from the calling
  thread, which is one the program called into the library on.
- `system` runs a command in another process and waits for it. That
  process shares no memory with the library.

**Why `pthread_key_create` and `tss_create` are on it.** Each registers a
destructor that runs later, at a thread's exit. It runs only on a thread
that stored a value under the key, and a thread stores one only by running
the library's code, which is a thread on which the program called into the
library. That is inside the property. The global rule separately requires
every call into the library to be on one thread, so the destructor runs on
that thread.

**Why `signal` and `sigaction` are not.** A handler runs at an arbitrary
point, and in a program with several threads on any thread that has not
blocked the signal.

**What a failure names.** A function that is not on the list fails the
proof by rule 2 whatever it is. For these the message says what the
function does:

| Platform | Starts a thread |
|---|---|
| POSIX (Darwin, Linux) | `pthread_create` |
| C11 | `thrd_create` |
| Darwin | `dispatch_async`, `dispatch_async_f`, `dispatch_group_async`, `dispatch_group_async_f`, `dispatch_after`, `dispatch_after_f`, `dispatch_apply`, `dispatch_apply_f`, `dispatch_barrier_async`, `dispatch_barrier_async_f`, `dispatch_source_create`, `pthread_create_suspended_np`, `pthread_workqueue_addthreads_np` |
| Linux | `clone`, `clone3`, `syscall`, `getaddrinfo_a`, `timer_create`, `mq_notify`, `lio_listio`, `aio_read`, `aio_write`, `aio_fsync` |
| Windows | `CreateThread`, `CreateRemoteThread`, `CreateRemoteThreadEx`, `_beginthread`, `_beginthreadex`, `QueueUserWorkItem`, `CreateThreadpoolWork`, `SubmitThreadpoolWork`, `TrySubmitThreadpoolCallback`, `CreateThreadpoolTimer`, `CreateThreadpoolWait`, `CreateThreadpoolIo`, `RegisterWaitForSingleObject`, `CreateTimerQueueTimer`, `timeSetEvent`, `QueueUserAPC` |
| wasm32 | `wasi_thread_spawn`, `__wasi_thread_spawn` |

and for these, that it loads code the drafter cannot see: `dlopen`,
`dlsym`, `dlvsym`, `LoadLibraryA`, `LoadLibraryW`, `LoadLibraryExA`,
`LoadLibraryExW`, `GetProcAddress`.

**The build that was proved.** A proof holds for one target, one set of
macros and one set of units: the same source with a different option can
compile a file that starts a thread. So a proof is drawn only where the
source analyzed and the artifact linked are established as the same build
(§31.6.3). This holds for every proof the drafter draws about a
library's code, not only this one:

| How the library reaches the program | What the drafter knows | The result |
|---|---|---|
| Built from source by `with get` (CMake, Ninja and `with cc`) | everything: the units and the macros are the build's own `compile_commands.json`, and the library linked is that build's output | drawn |
| A project's own C sources, compiled by its `build.w` | everything, when the project's build compiles every C unit of the library its contract describes: the units and flags are the build's compile targets | drawn at build time. `runs no threads` is then effective with provenance `proof` without being written, and `with analyze … contract` prints it. Where it does not hold, the program states the one-line claim |
| A prebuilt binary (a Conan Center package) | the package states its settings (os, arch, compiler, build type) and its options in `conaninfo.txt`. It does not state the flags its builder's environment added | evidence, not proof: printed in the report with the configuration analyzed, granting nothing. Configuring the source with the settings and options the package records does not establish that the builds are the same |
| A system package (`c.<name> = "system"`) | nothing: there is no source | none |

What `with get` does today is in the note in wcl-landing-order.md: it prints and
trusts the third row's result as a proof.

**What the proof is expected to cover, and what it will not.** It is
expected to hold for leaf libraries whose only outside calls are to the C
library: of the published programs' libraries, zlib, bzip2 and the
c-interop example's `tally.c` (expected, not run), and only where the
library is built from source. It will not hold for a library that calls
another library (libxml2 calls zlib and libiconv and links `dl`; libcurl
calls OpenSSL and zlib), one that starts threads or loads code (sqlite3's
sorter and its extension loader, SDL, raylib), or a prebuilt binary. Those
have `runs no threads` only as a claim, or do not have it.

### 31.8.6 A destroyer named through a function-pointer global

(Adopted 2026-11-11. Implemented for `freed by`. Not yet implemented: the
form after `drop` and `destroys`, the error for a contract that describes a
function that assigns the global, and the drafter's contradiction check.) The function a
`freed by`, `drop` or `destroys` clause names is an imported function, or
an imported global of function-pointer type. libxml2's `xmlFree` is the
case: `xmlmemory.h` declares `XMLPUBVAR xmlFreeFunc xmlFree;`, and the
registry's facts say `text return, owned, freed by xmlFree`.

- A global so named is a hook of the library (§16.2b.15). The clause
  states two facts: that a call through it is a deallocation, and that the
  library assigns it only in functions that stay raw.
- A function that assigns it stays raw, as a function that replaces hooks
  shared by live resources does, whatever a contract says of its
  parameters: a contract that describes one is an error naming the clause.
  Assigning it from With is raw, as assigning any global that holds a
  pointer is. So nothing safe code can call writes the pointer; a program
  that replaces it does so inside `unsafe`, and answers there for no other
  thread reading it meanwhile.
- The read of the global that the generated call makes rests on that
  statement. It is not under the global rule of §31.4 and does not need
  `runs no threads`. A read of the global the program itself writes is
  under that rule as any other.
- Where the clause is a claim, its citation shows both facts: that the
  pointer is the deallocator of what the clause frees, and every function
  of the library that assigns it. Where the drafter has the library's
  source and finds an assignment in a function the contract presents as
  safe, that is a contradiction of the clause, an error naming both
  (§31.7).
- The pointer is read at each call, never cached, so a pointer a raw call
  replaced is the one called.
- The generated code never calls a null pointer. Before each call it tests
  the pointer read from the global; NULL is a contract failure naming the
  clause and the global (§31.11).
- In a build where the name is not a global (libxml2 with `xmlFree` defined
  as the macro `(*__xmlFree())`), the clause names nothing the import has,
  which is an error by verification rule 6.

Tests owed with the implementation: the global NULL at the call (the
contract failure, with its message), and the global replaced by a raw call
between production and release (the replacement is what runs).

## 31.9 Claims

A claim is a clause that grants and that the compiler does not vouch for: a
`stated` grant, a `registry` line, a `profile` match, an `annotation`. An
empty `fn f` is one claim: it asserts that `f` keeps and frees nothing.

0. **Overrides are not claims.** A claim stands where no proof spoke; an
   override stands against one. They are counted apart, and a stale
   override apart from both (§31.7).
1. **Claims are counted and printed.** `with analyze … contract` marks each
   claim and ends with the count, the program's own beside the registry's.
   The ceremony census counts them. `:user-programs-safe` reports the count
   for the release UAT fixtures and examples, so a rising number is visible.
2. **Where a citation is required.** In the registry (every line of a facts
   file), in the standard library, and in the runtime: a claim without one
   is refused with its line. A citation on an `fn` or `resource` line covers
   the clauses under it that carry none. In a program's own source it is not
   required: the clause is reviewed with the program.
3. **A claim in a user program is not refused.** D51 gives an application
   author the contract as the way to make their own C library safe; a
   fixture or an example may state a grant.
4. **No compiler tool writes a claim or an override.** The drafter proves
   or leaves the function raw; the migrator proves or emits `unsafe`. A
   proof is never printed as a claim, and a claim is never printed as a
   proof.
5. **A registry claim applies only where no proof and no annotation
   decided.** It never widens a proof, and one a proof contradicts is an
   error naming the claim's line and the proof.
6. **A registry claim is pinned.** The lock records the registry commit and
   the facts file's digest.

## 31.10 Verification

For every contract the compiler checks, against the declarations and
independent of provenance (§16.2b.13):

1. **Names.** Every `c_name` is an imported function, or, after `freed
   by`, `drop` and `destroys`, an imported global of function-pointer type
   (§31.8.6); every `CONST` an
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
5. **Capabilities compose.** `send` without `drop_any_thread` is refused.
   `callback_thread registering` on a callback retained by a resource that
   is `thread send` is refused: the resource can move to another thread and
   take the callback with it. A
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

## 31.11 Run-time checks

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
| `from f, nonnull`, or a pointer return the library marks non-null | when the function returns: it is not NULL | the function |
| `text utf8` | when text returns: it is valid UTF-8 | the function |
| a `str` passed as C text (`text param p`, a `str` variadic case) | before the call: the text has no interior NUL, which a C string cannot carry | the function |
| `buffer … len` / `capacity` | before the call: the slice's length fits the C count type | the function |
| `buffer … capacity … inout` | after the call: the length C wrote back is within the capacity | the function |
| `freed by g`, `drop g`, `destroys g` where `g` is a function-pointer global | before each call through it: the pointer read from `g` is not NULL. **Implemented for `freed by g`; `drop g` and `destroys g` are not yet implemented.** | the clause and the global |
| `requires domain D` | when the operation is called: `D` is established. Omitted where the compiler proves it; a live resource of `D` proves it, so only producers and functions that take no resource of `D` carry the test | the function |
| `establishes domain D` | when called: `D` is not already established | the call |
| `ends domain D` | when called: no resource of `D` is live | the call |

Not failures: a status that is not `ok` is an `Err`; a NULL in a `nullable`
position is `None`. An `override` removes no test: it changes what the
compiler trusts, not what it tests.

Where the compiler proves a test must fail (`requires` with `D` proven not
established; `ends` with a resource of `D` proven live), the call is a
compile error. For `ends` the error names the live resource and the fix.
(§16.2b.4, §16.2b.7, §16.2b.8.)

## 31.12 Known limits and open questions

**A teardown nobody described and nothing proved** (a known limit). A
function over scalars is safe as imported. `void engine_shutdown(void)`
takes no pointer, is safe to call, and can invalidate every live resource of
its library. A teardown the contract describes is checked (`ends domain D`,
§31.11). One the drafter proves frees or resets memory reachable from a
declared resource is raw until described (§31.4, proven invalidators).
What remains is a teardown of a library the drafter has no source for, in a
contract whose author did not describe it: it is safe to call and unchecked.
No rule about undescribed functions closes that without making every
undescribed function of a contracted library raw, which would put `unsafe`
in every raylib and SDL program; that rule was considered and not adopted
(2026-11-11).

**A sendable resource with a callback that follows it** (a future clause,
not for now). `callback_thread registering` is refused on a `thread send`
resource (§31.10, rule 5). libcurl is the case: it invokes the write
callback on the thread that makes the transfer call, and an easy handle may
be passed between threads. The clause that would say so is "the callback
runs on the thread that calls into the library on that resource"; with it a
sendable resource could carry a closure that is sendable and need not be
shareable. Until it exists such a resource takes the default: any thread.

Open:

1. **The `callback` field role** (#3124): a fifth role for a
   function-pointer field that holds the program's own function, whose
   arguments are lent for the call. It gets its own brief.
2. **Corpus functions as a subject** (§31.2): the facts-file form of
   claims.md tier 1.
3. **With functions as a subject**: not yet; the direction is recorded in
   §31.2.
