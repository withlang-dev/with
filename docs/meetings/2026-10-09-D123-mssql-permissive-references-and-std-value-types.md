# D123 — std.mssql may read and port from permissive TDS drivers, recorded in `THIRD_PARTY` from day one; `Decimal`, the date and time types and `Guid` are std types, `Decimal` over a real `i128`

**Date:** 2026-10-09. **Status:** ruled (Eric Hartford). Answers the two
open questions in `docs/proposals/mssql.md` and `docs/proposals/tds.md`.
No specification text changes: both answers govern the proposals and the
std modules they add, whose spec text comes with each module.

**Context.** std.mssql is written clean-room because FreeTDS is LGPL
(`mssql.md`). The proposals asked whether permissive drivers may serve as
references beside MS-TDS (prediction yes, 85%), and where the new value
types SQL Server needs should live (prediction std modules, 70%).

**Ruling (Eric, verbatim).**

"Two quick yeses, each with one thing to watch.

**1. Permissive drivers as references: yes.** The clean-room boundary
exists because of FreeTDS's copyleft license, and MIT, BSD and Apache code
doesn't carry that problem. Two notes:

- **Copying or closely porting code carries attribution duties.** MIT and
  BSD need the copyright notice kept, and Apache-2.0 also requires carrying
  its NOTICE file. Reading for behavior needs nothing, but anything ported
  should be recorded in a `THIRD_PARTY` file from day one, not
  reconstructed later.
- **Their real value is the behavior the spec doesn't document.** MS-TDS is
  good, but every production driver encodes years of server quirks:
  version-specific token oddities, Azure behaviors, edge cases in
  collations. Microsoft's own .NET and JDBC drivers are the authority on
  those. tiberius is the closest design match, since it's also a
  systems-language, async, zero-copy client. FreeTDS stays off the reading
  list until its license changes.

**2. New value types in std: yes.** `Decimal`, dates and times, and `Guid`
are general values that JSON, CSV, Postgres and SQLite will all need. Three
things to get right while they're designed:

- **Land `i128` instead of a two-word stand-in.** SQL Server's `decimal`
  goes to 38 digits, which needs 128 bits. A stand-in becomes legacy the
  day `i128` arrives, and `i128` belongs in the language anyway, given the
  width ruling's future-proofing.
- **Keep time zones out of the first version.** SQL Server's types are
  `date`, `time` (to 100 ns), `datetime2`, and `datetimeoffset`, which
  carries a fixed offset, not a zone. std can model all of those without a
  time-zone database, which is a large project of its own.
- **`Guid` byte order is a trap.** SQL Server's `uniqueidentifier` stores
  the first three fields little-endian on the wire. `std.guid` should hold
  the canonical form, and the conversion should live only in the TDS
  data-types module. Otherwise GUIDs round-trip correctly through SQL
  Server and come out scrambled everywhere else.

**The customer question matters most for scope.** SQL authentication is a
few hundred lines. Microsoft Entra (Azure AD) token login is moderate.
Windows integrated authentication (Kerberos or NTLM) is a project of its
own. If their servers use the last one, it can rival the rest of the driver
in size, so it's worth getting that answer before the phases are fixed."

**What it changes.**
- References: mssql-jdbc and dotnet/SqlClient (MIT, the authority on
  server quirks), go-mssqldb (BSD-3), tedious (MIT) and tiberius
  (Apache-2.0, the closest design) may be read and ported from. Every
  ported or closely followed piece is recorded in `lib/std/mssql/THIRD_PARTY`
  (source, file, license, copyright notice, and Apache's NOTICE text) in the
  same commit that adds it. FreeTDS's source and any GPL or LGPL client stay
  unread.
- Value types: `std.decimal`, `std.time` (`Date`, `Time` to 100 ns,
  `DateTime`, `DateTimeOffset` with a fixed offset, no zones) and
  `std.guid` (canonical RFC 9562 byte order). Phase 2 of std.mssql waits on
  them, and `Decimal` waits on `i128` (`docs/proposals/i128.md`); no
  two-word stand-in is built. The mixed-endian `uniqueidentifier`
  conversion lives only in the TDS data-types module.
- Scope: the phases are fixed only after the customer says which login
  method their servers use.

**What would reopen it.** A permissive driver's license changing; FreeTDS
relicensing (it then joins the reading list); `i128` proving impossible on
a target std.mssql must support.
