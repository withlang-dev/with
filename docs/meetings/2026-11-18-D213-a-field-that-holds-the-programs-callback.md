# D213 — A function-pointer field that holds the program's callback

**Laws:** D51 (a safety fact is stated or proven, never drawn from an
absence), 1 (one cited line per field, not a fact repeated on every function
that can reach it).

**Implemented 2026-11-22** (the facts reader, the draft's contradiction and
setter checks). The spec words are in v7.83 (§16.2b.15, §31), with the
amendment below.

**Amended 2026-11-22 (Eric).** The stores that fit the role are stated, not
only the one that contradicts it: a null store, the parameter that the
storing function's own callback clause names, and a whole-record copy. Any
other store (a value the package loaded, computed or was returned, or a
parameter the clause does not name) leaves the field undecided: the role is
not applied and the report names the store. Implemented the same day. Open
beside it: a variadic setter that hands its arguments to an internal
function, which stores the next one (libcurl's `curl_easy_setopt`), stores
no parameter of the storing function, so its field is undecided until a rule
says which variadic argument the store reads.

**Date:** 2026-11-18. **Status:** ruled by Eric. The spec words are derived
and come to him as a diff with the implementation.

**Context.** #3124: in libcurl 8.23.0, 14 public functions
(`curl_easy_perform`, `setopt`, `getinfo`, `pause`, `duphandle`, `reset`,
`recv`, `send`, `upkeep`, `header`, `nextheader`, `curl_ws_recv`,
`curl_ws_send`, `curl_ws_start_frame`) are raw as "retains param 0": the
handle reaches `trc_write`, which calls `data->set.fdebug(data, …)`, the
program's `CURLOPT_DEBUGFUNCTION`. The package never stores into that field
(the program does, through `curl_easy_setopt`), so D211's join does not
decide it.

**Ruling.** `field F of R is callback`: the only values the field holds are
callbacks the program registered through a presented operation. A call
through it lends its arguments for the call and keeps none. It is a cited
claim.

- **The package does not fill it.** A unit that stores a named package
  function into `F` contradicts the role (§31.7). Two stores do not: a null
  store (`curl_easy_reset` clears the field, and the call site tests for
  null), and a whole-record copy from the same field of another record
  (`curl_easy_duphandle` copies the settings; the value is still one the
  program registered). D211 counts a record copy as a write to every field,
  so this source is said to be fine.
- **The drafter finds the setters, from source.** It reads every unit, so
  it knows which functions store into the field; a person does not list
  them. Without the source the role cannot be checked and the field stays
  undecided.
- **Each setter found carries a callback clause in the contract.** One that
  does not is an error naming the function.
- **Raw calls under `unsafe` do not void the role.** `curl_easy_setopt`
  stays callable raw for options the contract does not model; a C function
  stored there by raw code is that `unsafe` block's obligation, as for any
  invariant safe code relies on. Otherwise "a raw path exists" would defeat
  the role for every variadic setter.
- **The role says nothing about threads.** The thread comes from the
  setters' `callback_thread`. For the `runs no threads` proof a call through
  the field is the program's code on the thread the setters' clauses say;
  if any setter says `any`, the call counts as possibly on another thread.

**The fixture the role's soundness rests on.** The debug callback is handed
the easy handle while `curl_easy_perform` holds it exclusively. §16.2b.9
makes that handle a borrow for the callback's scope, so only read-only
operations are available on it: `perform`, `setopt` and `cleanup` on the
lent handle inside the callback are refused, which is libcurl's own rule
against recursing from callbacks. A test pins it.

**Alternatives.** Treating "the package never writes it" as safe: a safety
fact from an absence. A `lend` fact on each of the 14 functions: asserts the
conclusion and hides the reason.

**Known beside it.** libcurl's evidence says "a unit of the package could
not be read" for 40 functions. That fails D198's conditions whatever this
role says, so the 14 may not all become safe when it lands.
