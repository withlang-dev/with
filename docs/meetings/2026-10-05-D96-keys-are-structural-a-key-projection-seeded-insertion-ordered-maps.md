# D96 — A key is any structurally comparable value; a custom equality is a key projection; maps are seeded and iterate in insertion order

**Laws:** 5, 1 (docs/mission.md).

**Date:** 2026-10-05. **Status:** BDFL ruling (Eric; the reasons below are
his). Spec v7.25: §11.7, §11.8, §4.3c, collection operations. Issues #2161,
#2180. **The compiler, the runtime and std are NON-COMPLIANT until they
catch up**: today a `HashMap`/`HashSet` hashes and compares a key by its
bytes (two equal `(i64, str)` keys are two entries; every 16-byte key is
read as a `str`, so `HashSet[(i64, i64)]` crashes), its iteration order is
slot order, and `Hash.hash_value() -> i64` is the hand-written hash.

**References (read in `.reference`).** Swift streams `hash(into:)` into a
seeded `Hasher` and deprecated `hashValue` as the requirement; Rust bounds
keys by `Eq + Hash`, has no `Hash` for floats, and seeds per map; Zig hashes
any type structurally (`AutoContext`), as bytes when the representation is
unique, refuses floats and slices, seed 0; Go hashes every comparable type
automatically through a per-map seed, allows floats (NaN keys are never
found), refuses slices; Mojo requires `Hashable & Equatable`. Python's
`dict` (3.7) iterates in insertion order over a seeded hash.

## Q1. Which types are keys: every structurally comparable type

`==` is already structural without a derive (#2137), so hashing is too: any
type whose `==` is structural is a key, except floats (Q3). With can allow
keys that Go and Zig refuse, like `Vec[i32]`: their concern is a key
mutated while it is in the map, and With rules that out by construction,
because the map owns its keys and nothing else can mutate them.

## Q2. A custom equality is a key projection, not a hand-written hash

A custom `eq` almost always means "equality is about *this part* of the
value": a tag compared case-insensitively, a record compared by its `id`.
The type declares that part once:

```
impl Key for Tag:
    fn key(): self.name.to_lower()
```

The compiler derives both `==` and the hash from the projection, using its
own structural hashing. Two advantages over `hash_value() -> i64`:
- `==` and the hash cannot disagree: there is one statement of what
  equality means, so no "defines eq but no hash" error is needed.
- The compiler keeps control of the seed. A hand-written `i64` is computed
  without the seed, so two keys that collide in it always collide whatever
  seed the map applies afterwards, which would quietly undermine Q4.

A hand-written `eq` without a projection is not a key; the error suggests
`key()`.

## Q3. Floats are refused as keys

It catches a real bug at compile time (a NaN key is never found again). The
help names a `TotalF64`-style wrapper in `std`, with a total order and its
`-0.0`/NaN rules spelled out, for a program that does want float keys.

## Q4. Seeded hash, insertion-order iteration

With a fixed seed and a public hash function, anyone who chooses keys can
make a map degrade to quadratic time: the 2011 hashDoS class. HTTP headers
and JSON object keys, in the web services the README pitches With for, are
exactly attacker-chosen keys. A random seed usually costs reproducible
iteration order; insertion order removes that cost, as Python's `dict` does:
- Iteration order is reproducible, run to run and host to host, because it
  depends on insertion order, not hash values: the compiler's fixpoint,
  comptime maps and `Debug` output keep it.
- The seed protects against flooding and is otherwise unobservable.
- Deterministic replay still works: the seed comes from the runtime's
  randomness capability, so a replay records it like any random value.

Whatever order ships becomes a contract once programs depend on it (Go
randomizes iteration to prevent that), so it is decided now. Insertion
order fits the STC work: Python's layout, a dense array of entries plus a
separate hash index, sits on top of any hash table engine.

## The byte path

A key whose byte equality provably agrees with its structural `==`
(integers, `bool`, field-less enums, and records of those with no padding;
never a float) may be hashed and compared as bytes, Zig's unique
representation path.

**Reopen if** a key type's structural `==` and its byte representation
can disagree in a way the byte path cannot see.
