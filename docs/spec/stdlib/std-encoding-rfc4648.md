# RFC 4648 Encodings

The `std.encoding` family provides native, safe-With implementations of the
Base16, Base32, Base32hex, Base64, and Base64URL encodings defined by
[RFC 4648](https://www.rfc-editor.org/info/rfc4648/). Encoding represents bytes
as text; it does not encrypt data, add entropy, or protect secrets.

## API

These are the family's only public declarations: one shared error and ten codec
functions.

| Module | Encode | Decode |
|---|---|---|
| `std.encoding.base16` | `base16_encode(data: []u8) -> str` | `base16_decode(text: &str) -> Result[Vec[u8], DecodeError]` |
| `std.encoding.base32` | `base32_encode(data: []u8) -> str` | `base32_decode(text: &str) -> Result[Vec[u8], DecodeError]` |
| `std.encoding.base32hex` | `base32hex_encode(data: []u8) -> str` | `base32hex_decode(text: &str) -> Result[Vec[u8], DecodeError]` |
| `std.encoding.base64` | `base64_encode(data: []u8) -> str` | `base64_decode(text: &str) -> Result[Vec[u8], DecodeError]` |
| `std.encoding.base64url` | `base64url_encode(data: []u8) -> str` | `base64url_decode(text: &str) -> Result[Vec[u8], DecodeError]` |

Encoders accept borrowed byte slices; decoders borrow input text and return
owned bytes. Behavior tests cover bound fixed arrays and vectors remaining
usable after encoder calls.

```with
use std.encoding.base64

let input = [102 as u8, 111 as u8, 111 as u8]
let encoded = base64_encode(input)
assert(encoded == "Zm9v")
let decoded = base64_decode(encoded).unwrap()
assert(decoded.len() == 3)
```

## Decode errors and strictness

All decoders use the shared `std.encoding.DecodeError`:

```with
pub error DecodeError =
    | InvalidLength(length: i64)
    | InvalidByte(offset: i64, byte: u8)
    | InvalidPadding(offset: i64)
    | NonCanonicalBits(offset: i64)
```

Errors are selected deterministically: invalid encoded length first, then the
first alphabet or padding violation from left to right, then non-zero unused
bits in the final symbol. Validation and canonical-bit checks complete before
output allocation, so failures return no partial output. No decoder ignores
whitespace, CRLF, NUL, non-ASCII bytes, excess padding, or characters outside
its accepted alphabet. Base32, Base32hex, Base64, and Base64URL require RFC
padding on a partial final quantum.

| Codec | Canonical alphabet | Decode case | Padding |
|---|---|---|---|
| Base16 | `0-9A-F` | ASCII-insensitive | none |
| Base32 | `A-Z2-7` | ASCII-insensitive | required |
| Base32hex | `0-9A-V` | ASCII-insensitive | required |
| Base64 | `A-Za-z0-9+/` | significant | required |
| Base64URL | `A-Za-z0-9-_` | significant | required |

Case-insensitive decoders accept non-canonical letter case, but encoders always
produce uppercase Base16 and Base32-family output. Compare canonical
re-encodings when a single textual representation matters.

## Compatibility note

`std.crypto.sha256.sha256_hex` remains unchanged for its existing callers. It
emits fixed-length lowercase hexadecimal, while RFC 4648 publishes uppercase
Base16. Current implementation differs from RFC 4648. Compliance decision
required. Defer to Eric Hartford.

## RFC 4648 verification checklist

Evidence files:

- `test/behavior/behav_std_encoding_rfc4648_vectors.w` — alphabets, published
  vectors, terminal quanta, case, and Section 9 examples.
- `test/behavior/behav_std_encoding_rfc4648_strict.w` — exact errors,
  non-alphabet bytes, padding, and unused-bit rejection.
- `test/behavior/behav_std_encoding_rfc4648_properties.w` — deterministic
  round trips, boundaries, large input, ownership, and Base32hex order.

| ID | RFC source | Verified requirement | Evidence | Status |
|---|---|---|---|---|
| R01 | §3.1 | Encoders insert no line feeds | vectors + strict round trips | Passed |
| R02 | §3.2 | Required padding is emitted and unpadded input rejected | terminal-quanta + length cases | Passed |
| R03 | §3.3 | Non-alphabet bytes are rejected | whitespace, CRLF, NUL, non-ASCII, cross-alphabet cases | Passed |
| R04 | §3.4 | Each named alphabet is selected explicitly; Base32 rejects `0` and `1` instead of remapping them | exhaustive alphabet loops + rejection cases | Passed |
| R05 | §3.5 | Encoders zero unused bits; decoders reject non-zero unused bits | every terminal shape + `NonCanonicalBits` mutations | Passed |
| R06 | §4/Table 1 | Base64 uses MSB-first 24-to-4 grouping and `+/` | 64-value alphabet, Section 9 examples, round trips | Passed |
| R07 | §5/Table 2 | Base64URL uses `-_` and default padding | forced values 62/63 + cross-alphabet rejection | Passed |
| R08 | §6/Table 3 | Base32 uses `A-Z2-7` and all four partial quanta | 32-value alphabet + terminal tests | Passed |
| R09 | §7/Table 4 | Base32hex uses `0-9A-V` and preserves bit-wise order | 32-value alphabet + exhaustive two-octet order test | Passed |
| R10 | §8/Table 5 | Base16 emits uppercase, has no padding, and decodes case-insensitively | nibble loop + case/length/error cases | Passed |
| R11 | §9 | Published Base64 examples and Base32 grouping are reproduced | explicit Base64 octet examples + Base32 RFC vectors/source grouping review | Passed |
| R12 | §10 | All published vectors use explicit ASCII octets and pass | seven vector lengths across every published family | Passed |
| R13 | §11 | Non-normative ISO C99 sample is not imported | safe-With source/dependency audit | Passed |
| R14 | §12 | Malformed input, including NUL, remains memory-safe | strict corpus + native debug allocator | Passed |
| R15 | §12 | Ignored bytes and unused bits cannot form covert channels | strict rejection and canonical-bit tests | Passed |
| R16 | §12 | Case-insensitive input is intentional but canonical output is uppercase | exhaustive/lowercase decode and re-encode tests | Passed |
| R17 | §12 | Encoding supplies no confidentiality or entropy | module/API security documentation | Passed |

### API and implementation checks

| ID | Verified contract | Evidence | Status |
|---|---|---|---|
| A01 | All five modules and shared error compile together | focused behavior files | Passed |
| A02 | Bound arrays and vectors remain reusable after encoder calls; decoder text is borrowed | ownership property cases | Passed |
| A03 | Error precedence and zero-based context are deterministic | exact-error strict cases | Passed |
| A04 | Complete validation precedes output construction | decoder source review | Passed |
| A05 | Checked lengths and exact capacities are used | source review + boundary lengths | Passed |
| A06 | Runtime and output storage are linear | source review + 65,536-byte corpus | Passed |
| A07 | No unsafe, FFI, external codec, runtime/compiler edit, or `sha256_hex` mutation exists | file-by-file dependency/diff audit | Passed |

### RFC Editor errata

The source snapshot is unchanged. The live
[RFC Editor registry](https://www.rfc-editor.org/errata_search.php?rfc=4648)
contains the six entries below. Verified errata inform the reading; Reported
errata are analyzed without being treated as corrections. `Passed` records
coverage of that treatment, not promotion of an erratum's registry status.

| EID | Registry status | Treatment | Evidence | Status |
|---|---|---|---|---|
| 2837 | Verified / Editorial | Reference article is `000316`; no codec effect | source review | Passed |
| 5855 | Verified / Editorial | Vector strings are explicit ASCII octets | vector fixtures | Passed |
| 7514 | Verified / Editorial | Read “does not hold”; canonical-bit rule unchanged | unused-bit tests | Passed |
| 9030 | Verified / Editorial | Read “a URI”; Base64URL behavior unchanged | Base64URL tests/docs | Passed |
| 4889 | Reported / Technical | Published Base32 octet/group rules and vectors remain controlling | Base32 vectors/grouping tests | Passed |
| 8669 | Reported / Technical | Sections 4/9 and vectors establish Base64 bit order | Base64 examples/vectors | Passed |

### Repository gates

| Gate | Command/evidence | Status |
|---|---|---|
| Focused behavior | three direct `with run` cases | Passed |
| Memory safety | three `with run --debug-alloc` cases, zero leaks/errors | Passed |
| Self-host build | `with build` at repository-mandated `-O1` | Passed |
| Fixpoint | `with build :fixpoint`, stage2 equals stage3 | Passed |
| Full suite | `with build :test` | Passed |
| Evidence record | `with build :test-green`, `with build :last-green` | Passed |
| Production review | Rule 13 correctness, safety, test, dependency, documentation, and scope audit | Passed |

`with build :last-green` also emitted the tracked #680 undeclared-edge notes;
the command completed successfully and archived the passing evidence.
