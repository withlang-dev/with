# D249 — Positioned in-place initializers (`init F(param N)`) and bridged `init` rendering

- **Date:** 2026-11-27
- **Status:** Delegated (D237 — settled by `docs/mission.md` Law 1, Law 5, Law 9; #3149)

## Context

In-place C resources (`resource R wraps T`) previously required every `init`
clause to place the uninitialized storage pointer at parameter 0 (`init F(self)`),
and rendered `init` bodies via `facade_render_params` (discarding parameter
bridge prologues).

Real C libraries routinely initialize caller-allocated in-place resources at a
non-zero parameter — for example libyaml's `yaml_parser_parse(yaml_parser_t *parser,
yaml_event_t *event)`, `yaml_parser_load(parser, document)`, and
`yaml_parser_scan(parser, token)` — and pass paired buffers/nullable text into
initializers such as `yaml_scalar_event_initialize(event, anchor, tag, value, length, ...)`.

## Decision

1. Allow `init F(param N)` (and `init F(param N), ok K`) alongside `init F(self)`
   in WCL `resource` blocks and registry `c facts` files, paralleling D209's
   `drop F(param N)` / `destroys F(param N)` and D243's `of R(param N)`.
2. Render `init` constructors and their D215 free-function forwarders through
   `facade_render_bridge(pool, intern, init_fn, 0, at, storage_arg)` and emit
   `bridge.prologue`, allowing paired `buffer`, `nullable`, `text`, and `reads`
   clauses on `init` functions while keeping `drop`, `destroys`, and `preinit`
   prohibited from pairing buffers.

## Mission fit

- **Law 1 (Write Nothing Twice):** *Test: Could the compiler have derived this
  without asking the programmer?* The C prototype already gives the storage
  parameter's type and position; naming `(param N)` states the one fact C omits
  (which parameter is initialized in place) without requiring manual wrappers.
- **Law 5 (The Signature Is the Contract):** *Test: Can a reader determine
  ownership, borrowing, mutability, and fallibility from the signature alone?*
  `Event.parser_parse(&parser) -> Result[Event, EventError]` presents ownership
  and fallibility directly in the signature.
- **Law 9 (First-Class C Interop):** *Test: Does calling a modeled C library
  require `unsafe`, a manual wrapper, or a foreign build step?* No; callers
  initialize positioned in-place C resources safely with zero `unsafe`.
