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

| Library | Layer 1 (engine) | Layer 2 (API) | Layer 3 (syntax) |
|---|---|---|---|
| PCRE2 | migrated C | `re.match()`, `re.find_all()` | `/pattern/`, `=~` |
| jq | migrated C | `json.parse()`, `json.query()` | `from data \| .field` |
| libsodium | migrated C | `crypto.encrypt()`, `crypto.hash()` | — |
| mbedTLS | migrated C | `tls.connect()`, `tls.listen()` | — |
| zlib | migrated C | `compress.deflate()`, `compress.inflate()` | — |
| LMDB | migrated C | `kv.open()`, `kv.get()`, `kv.put()` | — |
| libuv | migrated C | `async.spawn()`, `async.tcp_connect()` | `await`, `async fn` |
| utf8proc | migrated C | `unicode.normalize()`, `unicode.is_letter()` | — |
| xxHash | migrated C | `hash.xxh64()` | — |
| libyaml | migrated C | `yaml.parse()` → returns `Json` | `from` (shared with json) |
| toml-c | migrated C | `toml.parse()` → returns `Json` | `from` (shared with json) |
| llhttp | migrated C | `http.parse_request()` | — |
| linenoise | migrated C | `term.readline()`, `term.history()` | — |
| libbacktrace | migrated C | `debug.stacktrace()` | — |
| SQLite | migrated C | `sqlite.open()`, `sqlite.query()` | maybe `from` for SQL |
| c-ares | migrated C | `dns.resolve()`, `dns.lookup()` | — |
| zstd | migrated C | `compress.zstd.encode()` | — |
| lz4 | migrated C | `compress.lz4.encode()` | — |
| yxml | migrated C | `xml.parse()` | — |
| msgpack-c | migrated C | `msgpack.pack()`, `msgpack.unpack()` | — |
| stb_image | migrated C | `image.load()`, `image.save()` | — |

Only three get Layer 3: regex, JSON/YAML/TOML (shared `from`), and async. These are the patterns where syntax genuinely reduces friction — matching patterns inline, querying data pipelines, and concurrent execution. Everything else is perfectly fine as a function call.

The pattern for every library is the same:

```
1. with migrate libfoo.c --no-c-exports -o lib/std/foo/engine.w
2. Write lib/std/foo.w — idiomatic With API wrapping engine internals
3. (Rare) Add compiler support for syntax sugar
```

Step 1 takes days. Step 2 takes hours. Step 3 takes weeks and only happens for the select few that earn it.