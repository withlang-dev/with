# D76 — Modeled-C Amendment 2: effects without views; callback arguments and user data

**Date:** 2026-09-28. **Status:** BDFL ruling (Eric: "yes to both", after a
plain-language explanation of each). Recorded in the ruling document as
Amendment 2.

1. **Process-global C state (§16.2b.14, ruling §52, #1608).** Signals, the
   current directory, the descriptor table, resource limits, process groups
   and children, and the stdio streams are effects the runtime audit
   records, not domains: a domain exists to invalidate a safe view, and safe
   code holds no view of any of them (`getcwd` copies; a descriptor is a
   number; `FILE*` is never presented safely). Declaring domains nobody's
   view depends on would be ceremony with no guardrail. Any of them becomes a
   domain the first time a facade presents a safe view whose validity it
   decides.
2. **Callback arguments and user data (§16.2b.9, ruling §44, #1779).** A
   registering function's clause may present `argv`/`argc` as `&[Value]` of
   a callback-scope handle and the registered user data as the `&U` the
   facade boxed; the compiler generates the wrapper. Before, an SQL function
   body needed `unsafe` to read its arguments or its user data — a user
   program never writes `unsafe`. The pairing follows D64's buffer rule; the
   facade already owns the boxed `U`. Both views last for the invocation only.

Implementation status: 1 is an audit/record change; 2 is NON-COMPLIANT until
the facade clause and wrapper generation land.
