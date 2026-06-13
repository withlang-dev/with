That's a clean three-tier architecture:

```
Layer 3:  Language integration    from data | .users[] | where .age > 30
          (compiler support)      if line =~ /pattern/:

Layer 2:  With-native API         json.parse(), json.query()
          (idiomatic wrapper)     re.match(), re.find_all()

Layer 1:  Migrated C engine       jq VM, PCRE2 internals
          (via with migrate)      raw functions, not user-facing
```

Layer 1 is never touched by users. Layer 2 is what most users import. Layer 3 is sugar for the ones that deserve it.

Which libraries get which layers:


```text
stdlib = With APIs + migration-machine corpus
```

Some libraries are public modules. Some are hidden engine dependencies. Some are just data/spec maintenance inputs. But they all belong in the manifest because the machine’s job is to regenerate a coherent foundation without hand work.

## Add these to the manifest

```text
tzcode / tzdb
libffi
uriparser
libcurl
libarchive
bzip2 / libbz2
xz / liblzma
Brotli
mimalloc
libtommath
yyjson
Expat
GNU libiconv
GNU libunistring
libidn2
publicsuffix-list data
libpsl
nghttp2
libssh2
QCBOR
libmpdec
tree-sitter runtime
cmark
libgit2
libmagic
stb_image_write
stb_image_resize2
```

A few of these are not “user imports this every day” libraries; they are there because the dependency closure should be mechanically reproducible.

## Important dependency consequences

**libcurl becomes the big integration node.** curl’s docs say external libraries provide HTTP compression via zlib/Brotli/zstd, async name resolution via c-ares, HTTP/2 via nghttp2, cookie public-suffix handling via libpsl, international domain names via libidn2, and SCP/SFTP via libssh2. Since you already have mbedTLS, use that as the libcurl TLS backend rather than adding OpenSSL/GnuTLS just for curl. ([Curl][1])

**libarchive forces old compression formats back onto the list.** Its public page says it reads/writes many archive formats and automatically handles gzip, bzip2, lzip, xz, lzma, and compress combinations. That means **bzip2/libbz2** and **xz/liblzma** belong in the migration corpus if you want archive support to be complete, not curated. ([Libarchive][2])

**tzdb is not optional for a serious stdlib.** IANA describes tzdb as code and data representing local-time history worldwide, updated for political changes to time-zone boundaries, UTC offsets, and daylight-saving rules. That is exactly “do not hand-maintain this” territory. ([IANA][3])

**The web-correct stack is Unicode/IDNA/PSL/URL/HTTP, not just sockets.** uriparser gives RFC 3986 URI parsing; libidn2 handles IDNA2008/Punycode/TR46; libunistring provides Unicode string manipulation; libpsl handles the Public Suffix List; and nghttp2 gives HTTP/2 framing/HPACK. ([GitHub][4])

## Expanded migration order

This is a practical topological order, not a statement that every adjacent item depends on the previous one.

```text
0.  PCRE2                    already migrated

# Runtime substrate / portability
1.  mimalloc
2.  libffi
3.  tzcode / tzdb

# Basic compression / hashing closure
4.  zlib
5.  bzip2 / libbz2
6.  xz / liblzma
7.  xxHash
8.  lz4
9.  zstd
10. Brotli

# Unicode / text substrate
11. utf8proc
12. GNU libiconv
13. GNU libunistring
14. libidn2

# Numbers
15. libtommath
16. decNumber
17. libmpdec

# Core data formats
18. yyjson
19. jq dependency: Oniguruma
20. jq
21. libyaml
22. toml-c
23. yxml
24. Expat
25. msgpack-c
26. QCBOR

# Images
27. stb_image
28. stb_image_write
29. stb_image_resize2

# Terminal / diagnostics
30. linenoise
31. libbacktrace

# Storage
32. SQLite
33. LMDB

# Network substrate
34. c-ares
35. libsodium
36. mbedTLS
37. uriparser
38. publicsuffix-list data
39. libpsl
40. nghttp2
41. libssh2
42. llhttp
43. libuv
44. libcurl

# Archives and package/tooling
45. libarchive
46. cmark
47. tree-sitter runtime
48. libgit2
49. libmagic
```

## Public API mapping

```text
time / datetime       -> tzcode + tzdb
ffi                   -> libffi
uri / url             -> uriparser
http.client / fetch   -> libcurl
http.parse_*          -> llhttp
http2                 -> nghttp2
dns                   -> c-ares
tls                   -> mbedTLS
ssh / sftp            -> libssh2
crypto                -> libsodium
archive              -> libarchive
compress.deflate      -> zlib
compress.bzip2        -> bzip2
compress.xz / lzma    -> liblzma
compress.lz4          -> lz4 + xxHash
compress.zstd         -> zstd
compress.br           -> Brotli
hash.xxh*             -> xxHash
json.parse/stringify  -> yyjson
json.query            -> jq
yaml                  -> libyaml
toml                  -> toml-c
xml.tiny              -> yxml
xml.stream            -> Expat
msgpack               -> msgpack-c
cbor                  -> QCBOR
unicode               -> utf8proc + libunistring
idna                  -> libidn2
url.public_suffix     -> libpsl + publicsuffix-list
decimal               -> libmpdec
math.bigint           -> libtommath
term                  -> linenoise
debug.stacktrace      -> libbacktrace
sqlite                -> SQLite
kv                    -> LMDB
image.load            -> stb_image
image.save            -> stb_image_write
image.resize          -> stb_image_resize2
markdown              -> cmark
syntax                -> tree-sitter runtime
git                   -> libgit2
file.type             -> libmagic
```

## Engine-only or mostly hidden

```text
Oniguruma
  Hidden dependency of jq. Not With's public regex engine.

decNumber
  Hidden jq dependency unless you later choose to expose it.

publicsuffix-list data
  Data input for libpsl, not a normal library.

tzdb data
  Data input for time zones, paired with tzcode.

mimalloc
  Runtime/allocator choice, not a user-facing module by default.
```

## Notes on the new ones

**yyjson** is worth adding even though jq exists. jq is a query/transformation engine; yyjson is the lightweight parse/stringify path. Its docs emphasize ANSI C portability, RFC 8259 compliance, strict number formats, UTF-8 validation, and accurate int64/uint64/double handling. ([GitHub][5])

**Expat** complements yxml. yxml is tiny; Expat is the serious stream-oriented XML parser for files too large to fit in RAM. ([Expat][6])

**QCBOR** gives you standards-oriented binary data. CBOR’s RFC describes small code size, small messages, and extensibility as design goals; QCBOR implements the CBOR RFC family. ([RFC Editor][7])

**tree-sitter runtime** is for tooling, not runtime semantics. It gives incremental concrete syntax trees that update efficiently as source edits occur, which is perfect for With’s formatter, LSP, editor integrations, and semantic search. ([Tree-sitter][8])

**cmark** gives package docs and markdown tooling a real CommonMark parser rather than regex soup; libcmark parses CommonMark to an AST and renders multiple formats. ([GitHub][9])

**libgit2** belongs if With has packages. It is a portable, pure-C implementation of Git core methods as a linkable library. ([GitHub][10])

## The new migration-machine rule

```text
Every manifest entry has:
  upstream.url
  upstream.version
  upstream.checksum
  upstream.submodules
  build.profile
  generated_sources policy
  migrate command
  test command
  exported With module, if any
  engine-only flag, if hidden
```

And for “take ’em all,” I would add one more field:

```text
feature_profile = core | web_full | archive_full | tooling_full | engine_dependency
```

That keeps the machine broad without making the public stdlib chaotic. The migration corpus can be huge; the user-facing With API should still feel small, obvious, and curated.

[1]: https://curl.se/docs/libs.html "curl - External Dependencies"
[2]: https://www.libarchive.org/ "
libarchive - C library and command-line tools for reading and writing tar, cpio, zip, ISO, and other archive formats @ GitHub "
[3]: https://www.iana.org/time-zones "Time Zone Database"
[4]: https://github.com/uriparser/uriparser?utm_source=chatgpt.com "uriparser/uriparser: Strictly RFC 3986 compliant URI ..."
[5]: https://github.com/ibireme/yyjson?utm_source=chatgpt.com "ibireme/yyjson: The fastest JSON library in C"
[6]: https://libexpat.github.io/?utm_source=chatgpt.com "Welcome to Expat! · Expat XML parser"
[7]: https://www.rfc-editor.org/rfc/rfc8949.html?utm_source=chatgpt.com "RFC 8949: Concise Binary Object Representation (CBOR)"
[8]: https://tree-sitter.github.io/?utm_source=chatgpt.com "Tree-sitter: Introduction"
[9]: https://github.com/commonmark/cmark?utm_source=chatgpt.com "commonmark/cmark: CommonMark parsing and rendering ..."
[10]: https://github.com/libgit2/libgit2?utm_source=chatgpt.com "libgit2 - the Git linkable library"


The pattern for every library is the same:

```
1. with migrate libfoo.c --no-c-exports -o lib/std/foo/engine.w
2. Write lib/std/foo.w — idiomatic With API wrapping engine internals
3. (Rare) Add compiler support for syntax sugar
```
