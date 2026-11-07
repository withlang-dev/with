# D196 — A map of IDs the program minted names the unseeded hasher where it is declared

**Laws:** 1, 7 (docs/mission.md). Amends D96's hashing policy at one point.

**Date:** 2026-11-08. **Status:** ruled by Eric on #2372.

**Question.** `with check src/main.w` spends about a third of its time in
SipHash-1-3 over `i32` keys: Sema's symbol, node and type IDs. D96 made
every map seeded SipHash against flooding by attacker-chosen keys. The
compiler's symbol table has no adversary.

**Ruling** (rustc's way, with a narrower spelling than "the compiler's
own maps").
1. One policy at the library surface: `HashMap` is seeded SipHash by
   default for every key type, exactly as D96 says. A different hasher is
   a type chosen where the map is declared — `HashMap[K, V, Minted]`,
   `HashSet[T, Minted]` — with the seeded hasher the default. A program
   that writes `HashMap[i32, V]` gets flooding resistance whether its keys
   come from a parser or a socket.
2. Which maps may opt out: those whose keys are IDs the program minted.
   Symbol, node, type and scope IDs come from a counter inside the
   process; nothing outside it chooses them. Written as the condition, not
   as "the compiler's maps", it covers `with analyze`, the LSP server, UI
   handle tables and live-query row IDs, and refuses a map keyed by a
   parsed integer, which is D96's case. A name the source file supplied,
   interned to an ID, is minted; a map keyed by the name itself stays
   seeded.
3. The fast hasher is a multiply-mix, never the identity: minted IDs are
   sequential, and an identity hash clusters them in a table's low bits.
4. Iteration order is insertion order (D96), independent of the hash, so
   the switch changes no output, no fixpoint, no `Debug` text: a
   performance change with no semantic review, done as a sweep over the
   maps keyed by minted ID types, the fixpoint proving nothing moved.
5. The hasher never depends on the key type (`i32` fast, the rest
   seeded): a key type cannot know its provenance; the map's owner can.

**Also settled in the implementation.** A declared generic type refuses a
wrong argument count: `HashMap[i32, i32, i32]` had been accepted and the
map miscompiled (`get` found nothing), the silent fallback the hasher slot
would otherwise have hidden behind.

**What the others do.** rustc: internal maps `FxHashMap` (unseeded
multiply-rotate), the library `HashMap` seeded SipHash-1-3. Zig: Wyhash
with seed 0 everywhere. Go: AES memhash keyed per process for every key.
Swift: SipHash-1-3 seeded per process for every type.

**Next.** After the sweep, measure again: a seeded SipHash over four bytes
being a third of the checker suggests those maps are probed far more than
they need to be; the second win may be in the probe count, not the hash.
The sweep of `src/` waits for a seed that knows `Minted` (src is compiled
by the pinned seed against its std).
