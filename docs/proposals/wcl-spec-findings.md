# WCL chapter, draft 3: what the checks found

For Eric, 2026-11-11. The checks draft 3 owed, as findings. Each says what
was checked, how, and what it found. Where draft 2 was wrong the correction
is in draft 3 and is listed here so it is not silent.

## A1. The grammar against the parser

Read, production by production, on main at e33c3932a: the item parser
(`parse_c_facade` and its item function), the clause parser, the variadic
case parser, the convention rule parser.

1. A `len` buffer is never `inout`; a `capacity` buffer always is. Draft 2
   allowed both on both. Corrected.
2. `preinit f` takes `(self)` as `init f` does. Corrected.
3. `returns borrow R from params a, b` names exactly two parameters, not a
   list. Corrected.
4. `returns borrow R from domain D` is in the parser and §16.2b.6; drafts 1
   and 2 lacked it. Added in draft 2.
5. `consumes param p destroyed_by param q` and `returns borrow T from parent
   T of param p` were missing from draft 1. Added in draft 2.
6. `valid on failed` is an fn clause; draft 1 had it on the resource.
   Corrected in draft 2.
7. In the specification and not in the parser: `establishes domain`, `ends
   domain`, `requires domain` (D200), and `field … is role` outside a facts
   file (decided 2026-11-11).
8. In neither the parser nor the grammar: a clause for a pointer producer's
   non-null return (finding B4 below).

Not done: a fixture that writes every production and is accepted by the
compiler. It belongs in the keyword stack, born with the new spelling.

## A2. Every row against the §16.2b sentence that owns it

Read: §16.2b.1 to §16.2b.13 and §16.2b.15 in full, and §16.3b. Where a row
of draft 2 disagreed, §16.2b is right and draft 3 follows it.

1. **`resource N wraps T`.** Draft 2 listed four representations, one of
   them "an integer handle". §16.2b.3 has three: an opaque pointer, a
   by-value token, an in-place struct.
2. **`message f`.** Draft 2 marked it "presents". It grants: the compiler
   calls `f` on the resource after a failure and copies what it returns.
3. **`text utf8`.** Draft 2 said invalid UTF-8 is "`None` or an error
   value, not a failure". §16.2b.8: it is a contract failure naming the C
   function, and nothing is repaired. It presents `Option[str]`, not `str`.
4. **`ok`.** Draft 2 gave the default as "failure is `None`". §16.2b.4:
   without `ok` the status is uninterpreted and the constructor's result is
   `(status, Option[N])`; with several constants the `Ok` side carries the
   one that matched; a success status with nothing produced is
   `NothingProduced`.
5. **`from f(out param p)`.** Draft 2 omitted the NULL-inspect rule:
   production is not success.
6. **C globals.** Draft 2 dropped that a global the header declares `const`
   or thread-local is safe in any program, and said a pointer-typed global
   "is raw in every program". §16.3b: assigning one is raw; reading is not.
7. **`.repr`.** Draft 2 called it "the one field of a rendered type a
   program can name". §16.2b.3 has two sentences: the record's own fields
   are read through the resource, and of the generated type's own fields
   `.repr` is the only nameable one. Draft 2 merged them into a false one.
8. **Field read-through.** Draft 2 dropped the condition: a read is
   permitted wherever reading that field of the bare record is.
9. **Run-time checks.** Draft 2's table lacked four that the compiler
   emits and §16.2b.8 states: a slice length that does not fit the C count
   type; a copied-back length beyond the capacity; text that is not UTF-8
   under `text utf8`; an interior NUL in text passed to C.
10. **Precedence.** Draft 2 gave one rule ("a registry claim that
    contradicts a proof is an error") and stated the stated-clause rule
    only in passing. §16.2b.2 and §16.2b.15 have two different rules; draft
    3 states both and proposes one in 13.1.

Two places where the specification and the compiler disagree, found in this
pass and not resolved by it:

11. **A pointer producer's NULL.** §16.2b.4: "When trusted evidence
    establishes that a pointer-returning producer signals failure with
    `NULL`, its modeled result is `Option[Resource]` … This is not inferred
    from the return type alone." The compiler presents `Option[N]` for
    every pointer producer with no such evidence (the contract view prints
    "production: direct return; NULL is None" for a bare `from
    curl_easy_init`). The compiler's reading is the restriction (unknown
    nullability is nullable, §16.2b.8), so nothing unsafe follows; the two
    sentences of the specification pull in different directions.
12. **A pointer return** (A3).

## A3. A pointer return is raw; a returned record that holds a pointer is not

§16.2b does not draw that line. What it says:

- §16.2b.5: a parameter passed by value whose type holds a pointer makes
  the function raw; "returning such a record is not raw: the value is inert
  until it goes back into C."
- §16.11: "Address computation, comparison, and same-domain raw-pointer
  relabeling are safe. Memory access or validity assertion is unsafe."
- §16.1 says only that for "borrowed pointer returns" and other contracts
  the importer cannot model "the unsafe effect may be at the call boundary".

No sentence says a function that returns a pointer is raw. The compiler
makes it so (`ci_function_requires_raw_abi` tests the return type; checked
by running: a call of `curl_version()` with no contract is "raw c_import
function call requires unsafe context"). By the two sentences above a bare
returned pointer is as inert as a returned record that holds one. The
specification gives no reason for the difference; draft 3 says so in
section 4 and puts the two ways to reconcile it in 13.6.

## A4. A bare fn-item `destroys`, with no resource naming the function

Not refused. Run on main:

```
c facade h:
    resource Handle wraps *mut h
        from h_new
        drop h_free
    fn h_close
        destroys
```

checks, and the contract view shows `h_close` presented as a consuming
operation: "effect: param 0: destroys; receives Handle", "presentation:
move fn Handle.h_close". The converse, `destroys h_close` on the resource
with `fn h_close` written as a lend, is refused. So both places state the
fact and each decides. Uses in the tree: 38 resource-level `destroys f`
lines, 31 bare fn-item `destroys` lines. Proposal in 13.5.

## B4. Pointer-return nullability

§16.2b.8 has the mapping ("`nullable -> Option`, `nonnull -> direct value`")
and names a violated `nonnull` as a contract failure. It is a rule about
facts, and for a pointer producer the only source of the fact is an
annotation the library ships (§16.2b.15 item 2 lists `nonnull` and
`returns_nonnull`). There is no clause for it in the parser, so draft 3
does not put one in the grammar; it states the rule in 8.2, the test in
section 11, and proposes the clause in 13.4. Whether the compiler emits the
run-time test for a `returns_nonnull` return today was not checked.

## C2. The counts

Published programs: 7 UAT fixtures, 48 example sources, the README's
programs. `docs/blog` holds no program.

| What | Programs | Contract lines needed |
|---|---|---|
| Touches a C global | 0 found | 0 |
| Registers a retained callback capturing state that is not sendable | 1: `uat/fixtures/libcurl_main.w` | 1, in `lib/facades/libcurl.w` (copied by `uat/libcurl.uat`) |
| Registers a retained callback capturing only sendable state | 2: `examples/c-interop/src/main.w` and its test | 0 |

The first row is a search for the globals C's standard library and the
seven libraries declare, not a compile of each program with the checker
asked which imported globals it reads. The reliable count needs each
program's packages fetched; it is owed if the ruling turns on this row.

Proposed spellings: `runs no threads` (a library-level clause) and
`callback_thread registering` (on the registering function).

For 13.3, the undescribed-teardown candidate: raylib's two published
programs call 19 functions and the facts describe 3; SDL's fixture calls
functions its contract does not describe. Both would need `unsafe`.

## What was decided under the laws, without asking

- No clause was added to the grammar for a pointer producer's `nonnull`:
  the parser has none, and a restatement does not invent one (law 7).
- Two citations I had written into an example in 13.2 were removed and
  replaced with placeholders: I had not read the sources they named.
- The findings are a separate file so the chapter stays a chapter.

## What would change a published program

Nothing in draft 3 does: it is a document. Two proposals would, if ruled:
13.2 adds one line to `lib/facades/libcurl.w`, which a UAT scenario copies;
13.5 respells `destroys` lines in `lib/facades/sqlite3.w` and its copy in
the c-interop example. Both stop for Eric before any edit.
