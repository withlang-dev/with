# `std.mssql`: Microsoft SQL Server from the standard library, written clean-room

**Status:** plan, 2026-10-09; the protocol design is `tds.md`. Licensing ruled (Eric, below); one question
is open. **Why:** a customer needs With programs to talk to Microsoft SQL
Server with no setup, the way `std.http` talks to a web server.

## What the user writes

```
use std.mssql

fn main:
    let db = Connection.open("server=db.example.com;database=orders;user=app;password=…")?
    let rows = db.query("select id, name, total from orders where total > @p1", [100])?
    for row in rows:
        print(f"{row.int("id")} {row.str("name")} {row.decimal("total")}")
```

The program writes no `unsafe`, installs nothing and links no C library.
TLS is on by default: `encrypt=strict` (TDS 8.0, TLS before anything else)
where the server supports it, otherwise TLS negotiated in PRELOGIN.
Parameters are always sent as parameters (`sp_executesql`), never spliced
into the SQL text. Errors carry the server's message number, state,
severity and text.

## The ruling: clean-room, no LGPL

FreeTDS is LGPL. Migrating it, or porting it by hand while reading it,
produces a derived work that stays LGPL: the license covers the library
"either verbatim or with modifications and/or translated straightforwardly
into another language" (LGPL 2.1 §0). With and its standard library are
MIT.

**Eric (2026-10-09):** "we need to implement it fresh from the
specification, and from the external facing interfaces, specifications,
and documentation of freeTDS. I'll not be encumbered with lgpl."

### What the implementation may read

- **Microsoft's published specifications**, under the Open Specifications
  Promise:
  - MS-TDS (the protocol: PRELOGIN, LOGIN7, tokens, data types, TDS 8.0);
  - MS-NLMP (NTLM);
  - MS-KILE / RFC 4121 (Kerberos);
  - MS-SSTDS / MS-BINXML where a type needs them.
- **Microsoft's SQL Server documentation:** connection-string keywords,
  encryption and certificate behavior, collations, error numbers.
- **FreeTDS's external surface:** its user guide, its configuration
  documentation (`freetds.conf` keys and their meaning), its NEWS and FAQ,
  and its observable behavior run as a black box against a server. These
  say what a mature client does and which corner cases exist. Facts and
  behavior are not copyrightable; the text is, so nothing is copied from
  it.
- **RFCs** for TLS 1.2/1.3 and X.509, and the IANA registries.

### What it must not read

- FreeTDS's source: `src/`, `include/`, its unit tests and sample code.
  This includes its headers: they are LGPL code, not documentation.
- The source of any other GPL or LGPL TDS client (jTDS, …).

Tests are written fresh, from the specification and against a live server.
Nobody translates FreeTDS's test programs.

### The open question: Microsoft's MIT and BSD drivers

Microsoft publishes its own SQL Server drivers under permissive licenses
(checked on GitHub, 2026-10-09):
- `microsoft/mssql-jdbc`: MIT.
- `dotnet/SqlClient` (Microsoft.Data.SqlClient): MIT.
- `microsoft/go-mssqldb`: BSD-3-Clause.
- `tediousjs/tedious` (Node): MIT.
- `tiberius-rs/tiberius` (Rust): Apache-2.0 (not Microsoft's, but permissive).

They are the protocol's reference implementations from the vendor, with
the decade of corner cases the sourcing rule values. Reading them, or
porting from them by hand, is allowed by their licenses as long as the
copyright notice is kept, which `std.mssql` would carry beside the MIT
header. None is C, so the migrator does not apply; a port is by hand. They
also implement what FreeTDS lacks: Entra ID (Azure AD) token login
(FEDAUTH) and Always Encrypted.

Prediction (85%): yes, as references beside the specification, with their
notices kept: the vendor's own permissive code is the hardened source the
sourcing rule asks for, and it is not encumbered.

## Scope

**First release.**
- TDS 7.4 and 8.0. Older versions are not supported: SQL Server 2012 and
  later speak 7.4.
- SQL Server logins, and NTLMv2 for domain accounts.
- TLS on by default, with certificate validation and a
  `trust_server_certificate` option for development servers that is off
  by default.
- The common types:
  - int, bigint, smallint, tinyint, bit;
  - decimal/numeric, float/real, money;
  - nvarchar/varchar/nchar/char and the max forms, varbinary;
  - date, time, datetime, datetime2, datetimeoffset;
  - uniqueidentifier;
  - NULL as `Option`.
- Parameterized queries, multiple result sets, row counts, server messages,
  and transactions.
- Azure SQL routing (redirection after login).

**Later, by customer need.**
- Entra ID token login (FEDAUTH).
- Kerberos, through the host's GSSAPI: a host library, under the
  zero-dependency rule's allowance for user programs.
- MARS.
- Bulk copy.
- `varchar` in code-page collations other than UTF-8/CP1252.
- Always Encrypted.
- Table-valued parameters.

Question for the customer: which login method do their servers use (SQL
login, Windows/NTLM, Kerberos, Entra ID)? That orders the "later" list.

## Building blocks the stdlib needs first

**`std.tls`** is the long pole. It is With's own client today, which runs
TLS 1.2 directly on an fd with two ECDHE AES-128-GCM suites. SQL Server
needs three more things:
- **A transport, not an fd.** In TDS 7.x the TLS handshake travels inside
  PRELOGIN packets, so the client hands records to the TDS packet layer.
  In TDS 8.0 TLS runs first, directly on the socket.
- **The suites SQL Server offers.** AES-256-GCM-SHA384 is needed for common
  Windows configurations, and TLS 1.3 for SQL Server 2022's strict mode.
- **Certificate validation:** the host trust store, the hostname
  (`HostNameInCertificate`), and expiry.

**`std.crypto`** gains MD4, MD5 and HMAC-MD5 for NTLMv2 (MS-NLMP), each
written from its RFC and held to the RFC's test vectors, like the existing
primitives.

**Text.**
- UTF-16LE ↔ UTF-8 (`nvarchar`), and CP1252/Latin-1 (`varchar` in the
  default collations), written natively.
- Any other code page is read as bytes until its table is added; it is
  never decoded wrongly (unknown encoding is bytes, §16.2b.2).

## Phases and gates

Each phase lands as one stack with its battery.

1. **Test server and the TDS packet layer.**
   - The test server is SQL Server 2022 in its Linux container
     (`mcr.microsoft.com/mssql/server`) on the Linux host, as an `mssql`
     lane.
   - The packet layer covers framing, PRELOGIN and LOGIN7 (MS-TDS
     §2.2.6), unencrypted, SQL logins.
   - Gate: login succeeds and a wrong password is refused with error 18456.
2. **Tokens and types.**
   - SQL batches and `sp_executesql` with typed parameters.
   - The token stream: COLMETADATA, ROW/NBCROW, DONE*, ERROR/INFO, ENVCHANGE,
     RETURNVALUE.
   - The first-release types.
   - Gate: a round-trip fixture per type, including NULL, the min and max
     values and the `max` forms, compared with what the server's own
     `select` returns.
3. **TLS.** `std.tls` gains the transport, the suites, TLS 1.3 and
   validation. Gate: encrypted login in `strict` (TDS 8.0) and in
   PRELOGIN-negotiated (TDS 7.4) mode, and a refused connection to a
   certificate that does not match.
4. **The facade, `lib/std/mssql.w`.**
   - `Connection` is a resource: dropped means logged out and closed.
   - `query` and `execute`.
   - `Rows` is an iterator of row views valid until the next fetch (D22,
     D44).
   - A transaction is a scoped value, rolled back on drop unless committed.
   - Errors are `MssqlError { number, state, severity, message, server }`.
   - Gates: drop-audit cells for `Connection` and `Rows`, a complexity
     fixture (fetching N rows is linear), and no `unsafe` in any fixture.
5. **NTLMv2:** MD4/MD5/HMAC-MD5 in `std.crypto` (RFC vectors) and the
   MS-NLMP exchange. Gate: a domain login against a server joined to a test
   domain (lane), and MS-NLMP's own worked examples as fixtures.
6. **UAT:** `uat/mssql.uat`, a fresh project that `use`s `std.mssql`,
   creates a table, inserts with parameters, reads it back and prints a
   pass line, against the lane's server (`requires: mssql`).
7. **Benchmarks** against a reference client on the same server:
   connect-and-login time, a 100k-row fetch, and 10k parameterized inserts.
   The reference is Microsoft's ODBC driver or `go-mssqldb`, run as a black
   box. Gate: within 10%, or a profile and a ruling.

## Risks

- **TLS gates the customer.** Phases 1–2 run unencrypted against the lane's
  server, but Azure SQL and default SQL Server 2022 installs refuse
  unencrypted logins, so the customer cannot use the library until
  phase 3.
- **A fresh implementation finds the protocol's corner cases again**
  (collation flags, PLP chunking of the `max` types, ENVCHANGE routing,
  attention and cancel). The specification, the SQL Server documentation,
  black-box comparison against a reference client, and (if allowed) the
  vendor's MIT drivers are how we find them before the customer does.
- **Clean-room discipline.** A clean-room only holds if nobody on it reads
  FreeTDS's source. The rule applies to every agent and person who works on
  `std.mssql`, and each commit's evidence cites the specification sections
  it implements.
- **A live server in CI:** server tests run in a lane, not every battery,
  because SQL Server's container is Linux x86_64 only.
