# TDS in With: a clean-room client for Microsoft SQL Server

**Status:** proposal, 2026-10-09. **Companion:** `mssql.md` holds the
plan: scope, licensing ruling, phases, risks. This file is the design of
the protocol implementation under `std.mssql`.

## The rule this is written under

Eric (2026-10-09): "we need to implement it fresh from the specification,
and from the external facing interfaces, specifications, and documentation
of freeTDS. I'll not be encumbered with lgpl."

So every module is written from:
- Microsoft's Open Specifications: MS-TDS for the protocol, MS-NLMP for
  NTLM;
- SQL Server's documentation;
- RFCs for TLS and X.509;
- FreeTDS's documentation and its behavior as a black box.

Never from FreeTDS's source, headers or tests, nor from any GPL or LGPL
client. Each module's header names the MS-TDS sections it implements, and
each commit's evidence cites them. Permissive implementations as further
references are an open question for Eric (`mssql.md`):
- Microsoft's `mssql-jdbc` and `SqlClient` (MIT);
- `go-mssqldb` (BSD-3);
- `tedious` (MIT);
- tiberius (Apache-2.0).

Eric is asking FreeTDS's authors to relicense. That needs every copyright
holder's agreement, so the work does not wait on it. If FreeTDS becomes
permissive, its tests become a second oracle, and migrating it becomes an
option again to weigh against the code this proposal builds.

## Shape

```
std.mssql                 the user's API: Connection, query, Rows, Transaction, MssqlError
std/mssql/internal/
    transport.w           byte streams: TCP, TLS on TCP, TLS inside PRELOGIN
    packet.w              the 8-byte header, messages split and joined
    prelogin.w            PRELOGIN options and the encryption decision
    login.w               LOGIN7, FeatureExt, password obfuscation
    tokens.w              the token stream, pulled one token at a time
    types.w               TYPE_INFO and value decoding and encoding
    request.w             SQL batch, RPC (sp_executesql), ALL_HEADERS, attention
    session.w             the client state machine, ENVCHANGE state, routing
    ntlm.w                MS-NLMP (phase 5)
```

`internal` modules are reachable only from `std.mssql` (D100). The user
never names a packet, a token or a TDS version.

## The client state machine (MS-TDS §3.2)

A connection is one value of an enum whose variants are the spec's client
states:
- Sent Initial PRELOGIN;
- Sent TLS/SSL Negotiation;
- Sent LOGIN7 (with SPNEGO, or with Federated Authentication, later);
- Logged In;
- Sent Client Request;
- Sent Attention;
- Routing Completed;
- Final.

Each transition is a `match` arm that consumes the old state and returns
the new one, so a message that is illegal in a state does not type-check
as a call in it. One request is in flight per connection (no MARS in the
first release).

## Transport and encryption

Three transports implement one `Transport` interface (read, write, close):
1. **TCP**, for the unencrypted phases and for a server that explicitly
   allows plaintext.
2. **TLS on TCP**, for TDS 8.0 (`encrypt=strict`). TLS starts right after
   the TCP connect. The client offers the ALPN protocol `tds/8.0` (MS-TDS
   §1.7: a server that sees no ALPN assumes TDS 8.0), and PRELOGIN then
   runs inside TLS.
3. **TLS inside PRELOGIN**, for TDS 7.x. After the cleartext PRELOGIN
   exchange agrees on encryption, the TLS handshake records travel as the
   data of type-0x12 (PRELOGIN) packets (MS-TDS §2.2.6.5); after the
   handshake the session continues as TLS on the TCP stream.

`std.tls` gains the ability to run its handshake over any `Transport`.

**The encryption decision.** It follows MS-TDS §2.2.6.5's tables, with the
client's policy chosen by `encrypt=`:
- `strict` (the default when the server supports TDS 8.0): transport 2.
- `mandatory`: send ENCRYPT_ON (0x01). Encrypt the whole connection if the
  server answers ENCRYPT_ON or ENCRYPT_REQ. Terminate if it answers
  ENCRYPT_NOT_SUP.
- `optional`, which must be asked for: as `mandatory`, but a server that
  answers ENCRYPT_NOT_SUP is used in plaintext. The client never offers
  ENCRYPT_OFF, the mode in which only the login packet is encrypted.

Certificate validation is on in every encrypted mode:
- the host's trust store;
- the hostname, or `host_name_in_certificate`;
- expiry.

`trust_server_certificate=true` exists for development and is refused
together with `strict`.

## Packets (MS-TDS §2.2.3)

A message is a sequence of packets, each with an 8-byte header: type,
status, length (big-endian), SPID, packet id, window. The last packet sets
the end-of-message status bit.
- **Writing:** a message is split at the negotiated packet size (4096 until
  an ENVCHANGE says otherwise), and the packet id counts up and wraps.
- **Reading:** packets are joined into the message the token reader sees.
  A row is read in place where it lies inside one packet and copied only
  when it spans packets.
- **Cancel:** an attention packet. Results are then read and discarded
  until the DONE that acknowledges the attention.

## PRELOGIN and LOGIN7 (MS-TDS §2.2.6.5, §2.2.6.4)

**PRELOGIN** sends these options:
- VERSION (0x00, first, required);
- ENCRYPTION (0x01);
- INSTOPT (0x02), the instance name;
- THREADID (0x03);
- MARS (0x04), off;
- TRACEID (0x05), a fresh connection id;
- TERMINATOR (0xFF).

The client terminates when INSTOPT comes back 1.

**LOGIN7**:
- **Fixed part:** TDSVersion is 7.4, PacketSize is the requested size, and
  the option flags set fUseDB, fDatabase (INIT_DB_FATAL), fODBC (so the
  session gets ANSI defaults), fUnknownCollationHandling and fExtension.
- **Variable part:** host name, user name, password, app name
  (`with-mssql`), server name, client interface name, language, database.
  Each is UTF-16LE, at most 128 characters (§2.2.6.4's validation rules,
  checked before sending).
- **Password obfuscation:** for each byte, swap the high and low nibbles,
  then XOR with 0xA5 (§2.2.6.4). This is obfuscation, not protection: the
  password is sent only inside TLS unless the user chose `optional`
  against a plaintext server, and that case says so in the connection's
  warnings.
- **FeatureExt:** UTF8_SUPPORT (0x0A, so `varchar` columns in UTF-8
  collations decode as UTF-8), then TERMINATOR (0xFF). Later:
  - FEDAUTH (0x02) for Entra ID;
  - SESSIONRECOVERY (0x01) for reconnecting a dropped session.

Login succeeds on LOGINACK, which carries the TDS version the server
chose, and fails on an ERROR token (18456 for bad credentials) followed by
DONE.

## The token stream (MS-TDS §2.2.7)

`tokens.w` is a pull reader: `next()` returns the next token as an enum
value over views into the current message. Nothing is decoded until it is
asked for.

| Token | What the session does |
| --- | --- |
| COLMETADATA | becomes the current result's column list (names, TYPE_INFO, collation, nullability) |
| ROW / NBCROW | a row view over the message; NBCROW's null bitmap marks NULL columns |
| DONE / DONEPROC / DONEINPROC | ends a statement: status bits for more results, error and row count |
| ERROR / INFO | an `MssqlError` (number, state, class, message, server, procedure, line) or a message on the connection |
| ENVCHANGE | updates session state: database, language, collation, packet size, transaction descriptor (begin, commit, rollback), routing |
| LOGINACK / FEATUREEXTACK | the negotiated TDS version and the features the server accepted |
| RETURNVALUE (0xAC) / RETURNSTATUS | output parameters and a procedure's return status |
| ORDER, TABNAME, COLINFO | read and skipped |

An unknown token ends the connection with an error naming its byte and
offset. A token's declared length is always checked against the message's
remaining bytes before anything is read, so a malformed or hostile stream
is refused instead of overread.

## Types (MS-TDS §2.2.5)

Each column's TYPE_INFO decides its With type:

| SQL Server | With |
| --- | --- |
| tinyint, smallint, int, bigint (INTN) | `u8`, `i16`, `i32`, `i64` |
| bit | `bool` |
| real, float | `f32`, `f64` |
| decimal, numeric, money, smallmoney | `Decimal` (new: up to 38 digits, a 128-bit coefficient and a scale) |
| char, varchar, nchar, nvarchar, and the `max` forms | `str` |
| binary, varbinary, `varbinary(max)` | `List[u8]` |
| date, time, datetime2, datetime, smalldatetime | `Date`, `Time`, `DateTime` (new) |
| datetimeoffset | `DateTimeOffset` (new) |
| uniqueidentifier | `Guid` (new; mixed byte order on the wire) |
| any of the above, NULL | `Option[...]` of it |

- **Text.** `nchar`/`nvarchar` are UTF-16LE and decode to `str`.
  `char`/`varchar` decode by the column's collation: UTF-8 when the
  collation says so and UTF8_SUPPORT was acknowledged, CP1252 for the
  default Latin1 collations. Any other code page refuses to decode as text
  and is available as bytes (unknown encoding is bytes).
- **Large values.** The `max` types arrive as PLP (partially length-prefixed):
  a total length, which may be unknown, then chunks, then a zero
  terminator. They are read into one value; streaming large values is a
  later feature.
- **Prerequisites.** `Decimal`, the date and time types and `Guid` do not
  exist in std yet (`std.time` has `now` and `Duration` only). They are
  added as std types in their own changes before phase 2. `Decimal` needs
  `i128` (`i128.md`) or a two-word representation until then.

## Requests (MS-TDS: SQL batch, RPC request)

- **SQL batch** (`db.execute(sql)` with no parameters): ALL_HEADERS
  carrying the transaction descriptor header (required since TDS 7.2),
  then the text in UTF-16LE.
- **RPC to `sp_executesql`** (every call with parameters). The statement is
  `@stmt`; the parameter declaration string (`@p1 int, @p2 nvarchar(4000)`)
  is built from the With values' types; then the values in TYPE_INFO
  form. Parameters are never spliced into the text.
- **Transactions.** `db.begin()` returns a `Transaction` value. Its commit
  and rollback are requests, and the descriptor comes from ENVCHANGE. If
  it is dropped without `commit()`, it rolls back.

## Errors

Every failure is an `MssqlError`:
- **Server errors** carry number, state, class, message, server,
  procedure and line.
- **Protocol errors** name the MS-TDS rule broken and the byte offset.
- **Transport and TLS errors** name the step: connect, handshake,
  certificate (with the reason) or read.
- **Login failure** keeps the server's message (18456 and its state).

A class-20-or-higher error, or a protocol error, ends the connection (it is
`Final`); anything else leaves it usable.

## Routing and timeouts

- **Routing.** An ENVCHANGE routing token after login (Azure SQL gateways,
  read-only replicas) closes the connection and repeats the login against
  the named host and port, once per connection (MS-TDS, ENVCHANGE routing).
- **Timeouts.** Connect, login and command timeouts are options with
  defaults (15 s, 15 s, none). A command timeout sends an attention.

## Testing

1. **Byte-exact fixtures** from MS-TDS §4's sample messages (PRELOGIN
   §4.1, LOGIN7 §4.2, the SQL batch and RPC samples, the token streams):
   encoders reproduce them and decoders read them.
2. **A live server** (SQL Server 2022's Linux container on the Linux host,
   the `mssql` lane), with a type-by-type round trip covering min, max,
   NULL and the `max` forms, error paths, cancel and transactions. 2017
   and 2019 containers join the lane's matrix for TDS 7.4 without strict
   mode.
3. **Malformed streams.** A fuzzer feeds truncated and corrupted token
   streams to the reader. Every input ends in an error, never a crash or
   an overread, which the debug allocator and bounds checks confirm.
4. **Black-box comparison:** the same queries through Microsoft's ODBC
   driver (`sqlcmd`), compared value by value.

## Open questions

1. Permissive drivers as references beside the specification (Eric;
   prediction yes, 85%, in `mssql.md`).
2. Where `Decimal`, `Date`/`Time`/`DateTime`/`DateTimeOffset` and `Guid`
   live: `std.decimal`, `std.time`, `std.guid`, or inside `std.mssql`
   until another library needs them. Prediction: std modules (70%),
   because JSON, CSV and other databases need the same values.
3. Async: the first release is blocking, one request per connection.
   `std.task` integration follows the async proposal.
