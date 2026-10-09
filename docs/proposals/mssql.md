# `std.mssql`: Microsoft SQL Server from the standard library, migrated from FreeTDS

**Status:** plan, 2026-10-09. Three decisions below are Eric's before
work starts. **Why:** a customer needs With programs to talk to Microsoft
SQL Server with no setup, the way `std.http` talks to a web server.

## What the user writes

```
use std.mssql

fn main:
    let db = Connection.open("server=db.example.com;database=orders;user=app;password=…")?
    let rows = db.query("select id, name, total from orders where total > @p1", [100])?
    for row in rows:
        print(f"{row.int("id")} {row.str("name")} {row.decimal("total")}")
```

The program writes no `unsafe` and no facade, and installs nothing. TLS is
on by default (`encrypt=strict` with TDS 8.0 where the server supports it,
otherwise TLS negotiated in PRELOGIN). Parameters are always sent as
parameters (`sp_executesql`), never spliced into the SQL text. Errors carry
the server's message number, state and text.

## Why FreeTDS

The sourcing rule (`stdlib_sourcing_plan.md`, Eric 2026-09-02) is
hardenedness: take code that decades of production use have already
debugged. FreeTDS (stable 1.5.19) is the open implementation of TDS that
Perl, PHP and Python drivers on Unix have relied on for twenty years. It
speaks TDS 7.1–7.4 and, since 1.5, TDS 8.0 with `strict` encryption. Its
wire library, `src/tds`, is the part we need. The db-lib, ct-lib and ODBC
APIs, the pool server and the apps are not needed.

Facts checked at upstream (NEWS.md, the user guide). It needs no iconv:
built without one, its "internal trivial iconv" converts ISO-8859-1 and
CP1252 to UCS-2. TLS comes from OpenSSL or GnuTLS and is optional at build
time. NTLMv2 is on by default. Kerberos goes through GSSAPI. MARS is
compiled by default. The changelog never mentions Entra ID (Azure AD)
access-token login (FEDAUTH) or Always Encrypted.

## Decisions for Eric

**1. Licensing.** FreeTDS's libraries are LGPL (`COPYING_LIB.txt`); With
and its standard library are MIT. A migrated FreeTDS is a derived work and
stays LGPL. So is a hand port that reads FreeTDS and rewrites it: the
license defines its covered work as the library "either verbatim or with
modifications and/or translated straightforwardly into another language"
(LGPL 2.1 §0). Who or what does the translating does not matter; what the
code is derived from does. Statically linked into a user's program, LGPL requires that the
user can relink the program against a modified library.
- *(a) LGPL module inside std.* `std.mssql`'s bundle carries its own
  license. A `.wo` bundle already is a relinkable object plus its
  interface, so the relinking obligation is met by shipping the bundle's
  migrated source and object, which the tree already does. Every program
  that uses `std.mssql` inherits the obligation; programs that do not are
  untouched, because a program links only the bundles it references.
- *(b) The same migration, shipped as a package* fetched with `with get`
  rather than in std. The license is the same; std stays purely MIT.
- *(c) A clean-room TDS client written in With* from Microsoft's published
  protocol specification (MS-TDS, under the Open Specifications Promise),
  by people who do not read FreeTDS's source and without translating its
  tests (they are LGPL code too). This is MIT, but it is the opposite of the sourcing rule: twenty years of fixed
  protocol corner cases would have to be found again.

Prediction (60%): (a). You asked for it in the standard library, the bundle
model already isolates a corpus's object per program, and the sourcing
rule rules out (c). The cost is the stated per-module license, in the
module's header and in the `--version` notices.

**2. Authentication in scope.** SQL logins (user and password in LOGIN7)
come first. NTLMv2 for domain accounts comes second; FreeTDS carries its
own MD4, MD5, HMAC-MD5 and DES (`src/utils`), so they migrate with the
library. Kerberos needs the
host's GSSAPI (`GSS.framework` on macOS, `libgssapi_krb5` on Linux), a host
library under the zero-dependency rule's allowance for user programs.
**Entra ID token login is not in FreeTDS.** If the customer's servers are
Azure SQL with Entra-only authentication, that login (FEDAUTH in PRELOGIN
and LOGIN7) has to be added on our side. Question for the customer: which
of SQL login, Windows/NTLM, Kerberos or Entra ID do they use?

**3. Facade shape.** The facade sits on `libtds`, FreeTDS's internal wire
API (`tds_connect_and_login`, `tds_submit_query_params`,
`tds_process_tokens`), not on db-lib. db-lib is a 1980s Sybase API whose
row binding is exactly what a With facade replaces. Prediction (80%):
libtds. The cost is that libtds is FreeTDS's internal API: a pin bump may
move it, and the facade's fixtures catch that.

## What has to change around the migrated code

**TLS through `std.tls`.** FreeTDS's `tls.c` calls OpenSSL or GnuTLS, and
the zero-dependency rule rules out both. The migration builds FreeTDS with
neither and supplies its TLS entry points from `std.tls`, With's own TLS
client. That client needs three things it does not have:
- **A transport, not an fd.** In TDS 7.x the TLS handshake travels inside
  PRELOGIN packets: the client must hand records to FreeTDS's packet layer
  rather than to a socket. TDS 8.0 (`strict`) runs TLS first, directly on
  the socket.
- **The cipher suites SQL Server offers.** `std.tls` has two (ECDHE with
  AES-128-GCM). It needs AES-256-GCM-SHA384 for the common Windows
  configurations, and TLS 1.3 for SQL Server 2022's strict mode.
- **Certificate validation:** a CA bundle from the host trust store,
  hostname checking (`HostNameInCertificate`), and an explicit
  `trust_server_certificate` option for development servers, off by default.

**Character sets.** No iconv. The internal converter covers UTF-8,
UCS-2/UTF-16LE (`nvarchar`) and ISO-8859-1/CP1252. `varchar` columns in
other code-page collations (CP1250, CP932, …) are added as conversion
tables in a later phase. Until then such a column is read as bytes, never
as wrongly decoded text (unknown encoding is bytes, §16.2b.2).

**Configuration files.** `freetds.conf` and `interfaces` are not read by
default. The connection string is the configuration.

## Phases and gates

Each phase lands as one stack with its battery (the corpus pipeline in
`stdlib_sourcing_plan.md`).

1. **Pin and configure.** FreeTDS 1.5.19, tarball sha256 in
   `build/freetds.w` as a `Corpus`. Generate `config.h` per target (darwin,
   linux, windows; wasm32 is out of scope: no sockets) for no iconv, no TLS
   library, no GSSAPI. Gate: the reference target unpacks and verifies.
2. **Migrate `src/tds` (its internal iconv is `src/tds/iconv.c`) and the
   parts of `src/utils` it uses** (NTLM's MD4/MD5/HMAC-MD5/DES) as the
   `tds` bundle under `lib/std/tds/`. Gate: the migrated tree
   compiles under the gate. Every migrator failure is fixed in the migrator
   as a general rule and the corpus is re-migrated, never edited (D112).
3. **Upstream tests.**
   - FreeTDS's `src/tds/unittests` migrate as the oracle. Those that need
     no server (conversions, NTLM vectors, packet encoding) run in the
     battery.
   - Those that need a server run in a `mssql` lane against SQL Server
     2022 in its Linux container (`mcr.microsoft.com/mssql/server`) on the
     Linux host.
   - Gate: the same pass set as upstream's C build against the same server.
4. **TLS.** `std.tls` gains the transport abstraction, the suites, TLS 1.3
   and validation; FreeTDS's TLS entry points are supplied from it. Gate:
   encrypted login with `encrypt=strict` (TDS 8.0) and with
   PRELOGIN-negotiated TLS (TDS 7.4), and a refused connection to a server
   with a bad certificate.
5. **The facade, `lib/std/mssql.w`.**
   - `Connection` (a resource; dropped means logged out and closed).
   - `query` and `execute` with typed parameters.
   - `Rows` as an iterator of row views valid until the next fetch (D22,
     D44).
   - Typed column reads covering int, bigint, decimal, float, bit,
     nvarchar/varchar, varbinary, date/time/datetime2/datetimeoffset,
     uniqueidentifier, and NULL as `Option`.
   - Transactions as a scoped value: rolled back on drop unless committed.
   - Errors as `MssqlError { number, state, severity, message, server }`.
   - Gates: the drop audit's cells for `Connection` and `Rows`, a complexity
     fixture (fetching N rows is linear), fixtures for each type round trip,
     and no `unsafe` in any fixture.
6. **UAT:** `uat/mssql.uat`, a fresh project that `use`s `std.mssql`,
   creates a table, inserts with parameters, reads it back and prints a
   pass line. It runs against the lane's server (`requires: mssql`).
7. **Benchmarks** against FreeTDS's C build on the same server: connect and
   login time, a 100k-row fetch, and 10k parameterized inserts, recorded
   beside the facade. Gate: within 10% of C, or a profile and a ruling.
8. **Later, by customer need:** Kerberos, more `varchar` code pages, MARS,
   bulk copy (TDS BCP), Entra ID login.

## Risks

- **`std.tls` is the long pole.** Phases 2–3 can proceed over unencrypted
  connections to the lane's server, but the customer cannot use the library
  until phase 4 lands: Azure SQL and default SQL Server 2022 installs refuse
  unencrypted logins.
- **The migrator meets a new style of C.** FreeTDS uses `#if` per platform,
  a callback-heavy token processor and its own memory pools. Each failure
  is migrator work, fixed generally (as pcre2 and zlib were).
- **libtds API drift** across pins; the facade fixtures are the tripwire.
- **A live server in CI:** server tests run in a lane, not on every
  battery, because SQL Server's container is Linux x86_64 only.
