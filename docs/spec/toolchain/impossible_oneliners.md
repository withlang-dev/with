# Impossible With One-Liners

This document groups the `IMPOSSIBLE_ONELINER` entries in
[`with_oneliners.md`](with_oneliners.md) by the capability that is missing
today. “Impossible” means there is no working, reusable With API from which to
write an honest concise port. It does not mean arbitrary source text could
never be forced onto one physical line.

## Missing HTML entity codec

Affected recipes:

- HTML-decode a string
- Download a webpage, strip HTML, and decode all HTML entities

With can fetch a page through `std.http` and remove tags with a regex, but it
has no HTML entity encoder or decoder. A complete decoder is not just five
calls to `replace`: it must handle the full named-entity table, decimal and
hexadecimal numeric references, Unicode scalar validation, legacy names with
optional semicolons, and the context-sensitive error recovery defined for
HTML. Embedding a partial table in a one-liner would silently change the
recipe’s meaning, while embedding the complete table would no longer be a
useful one-liner.

The planned XML tokenizer only covers XML’s five predefined entity references,
which is deliberately smaller than HTML’s entity vocabulary. Reusing that
subset would therefore not implement either affected recipe correctly.

Potential redesigns:

- Specify and implement `std.encoding.html.decode_entities(text)` and
  `encode_entities(text)`. The specification should name the HTML entity-table
  version and define strict versus browser-compatible handling of malformed
  references.
- Generate an embedded trie or perfect-hash table from the chosen entity data,
  then decode numeric references directly into a `StringBuilder`. Generated
  data keeps the implementation complete without hand-maintained replacement
  chains.
- If HTML remains outside the standard library, make ecosystem dependencies
  usable from a one-liner: for example, a package-qualified `use` that the
  compiler can resolve and fetch without requiring a throwaway project file.

With a standard module, the shapes could be as small as:

    with -e 'use std.encoding.html;print(decode_entities("Tom &amp; Sue"))'

    with -e 'use std.encoding.html;use std.http;write(decode_entities(/<[^>]+>/g.replace_all(https_get("https://example.com"),"")))'

## Listener APIs are runtime stubs

Affected recipe:

- Launch a simple web server

[`lib/std/net.w`](../lib/std/net.w) exposes `tcp_listen`, `tcp_accept`, and
`udp_bind`, so the source-level API appears to support servers. The user
runtime does not implement those operations: the corresponding functions in
[`rt/rt_core.w`](../rt/rt_core.w) unconditionally return `-1`. The failure is
therefore below one-liner syntax; every server written against the advertised
API fails before it can accept a connection. There is also no high-level HTTP
server package in the repository. The standard-library plan intentionally
places HTTP servers in the ecosystem, but no fetchable one-liner dependency
currently fills that role. The runtime defect is tracked in
[#658](https://github.com/withlang-dev/with/issues/658).

Potential redesigns:

- Implement socket creation, `bind`, `listen`, `accept`, and UDP binding in
  platform-specific With runtime modules for Darwin, Linux, and Windows. Keep
  this compiler-owned code in With rather than adding a C helper.
- Replace raw `i32`/`-1` results at the public boundary with typed
  `Result[TcpListener, NetError]`, `TcpStream`, and `UdpSocket` APIs. A listener
  should own and close its descriptor, expose its selected address (including
  port `0`), and support an incoming-connection iterator or generator.
- Keep HTTP serving out of `std`, as the library plan proposes, but publish a
  small ecosystem package and let `with -e` resolve it directly. A handler API
  such as `serve(8080, request => Response.text("hello"))` would make the
  original recipe concise without making HTTP policy part of the core runtime.
- Alternatively, standardize only a tiny development server in `std.http`,
  with explicit limits: HTTP/1.1, loopback by default, bounded request sizes,
  and no implicit TLS. This gives scripts a dependable surface while leaving
  production servers to packages.

The low-level implementation should first be verified with loopback tests that
bind an ephemeral port, connect, accept, exchange bytes, and close both ends.
Only after that succeeds can a simple HTTP server one-liner be considered
working.
