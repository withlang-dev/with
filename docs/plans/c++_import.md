# `c_import` of `steam_api_flat.h`: The Minimum

## Scope

This is the smallest change that lets `c_import` read Valve's
`steam/steam_api_flat.h`:

```with
use c_import("steam/steam_api_flat.h", lang: "c++", link: "steam_api")
```

It imports the header's `extern "C"` functions, the structs, enums, and
typedefs they use, the callback structs with their IDs, and the integral
constants. Nothing else. Stage 0 (§3) confirmed this list against SDK 1.65.

It is not general C++ support. Out of scope:

- inferring the language from an extension or a failed C parse;
- namespaces;
- C++ builtin types beyond `bool`;
- C++ standard-library include handling;
- a design for classes beyond "opaque".

A header that needs more than this fails as loudly as it does today.

Eric approved this plan, including the wording in §6, on 2026-09-27.
This is a plan, not the specification: `docs/spec/ffi.md` does not change
until the §6 wording lands there, as its own step. Paths are relative to
the repository root and were verified at `99939352`.

---

## 1. Why it fails today

- `steam_api_flat.h` starts with `#include "steam/steam_api.h"`. That pulls
  in `steam_api_common.h`, with `class CCallbackBase` (virtual methods),
  `template<…> class CCallResult`, and the `ISteam*` interface classes.
  Valve's documentation calls the header "not pure C code", even though
  the functions use C linkage and calling conventions.
- `c_import` parses with `-x c`, hard-coded at all four parse sites
  (`src/compiler/ClangBridge.w:1989-1991`, `:3096-3098`, `:3192-3194`,
  `:3293-3295`). Any clang error fails the import (`:1921-1934`).
- Even parsed as C++, the importer would collect nothing useful:
  - `collect_decl` (`ClangBridge.w:1246-1259`) never descends into
    `extern "C"`. Each `S_API` function sits under a LinkageSpec cursor, so
    the whole flat API would be invisible.
  - Without a linkage check, a C++ inline function such as `SteamAPI_Init()`
    would be emitted as an unmangled `extern fn`.

---

## 2. Changes

Five changes. None alters the output of an existing C import.

### 2.1 The `lang:` option

- `lang: "c"` (the default) or `lang: "c++"`. Any other value is an error.
- **Parser:** pack it beside `strict` in `NK_C_IMPORT`'s extra pool
  (`src/Parser.w:2594-2813`) and pass it through
  `Zcu.expand_c_imports_frontend` (`src/compiler/Frontend.w:355-568`) to
  `process_c_import_with_defines` (`src/CImport.w:579-782`).
- **Cache:** add it to the key in `c_import_cache_key_frontend`
  (`Frontend.w:763-803`). Bump `#format:cimport-v18` only if C output
  changes, which it should not.

### 2.2 One argv builder

The four argv blocks are copies (`ClangBridge.w:1974-2004`, `:3083-3111`,
`:3179-3207`, `:3280-3308`). Replace them with one helper that takes the
language, so the declaration parse, the macro collection, and both macro
probe parses always agree. In C++ mode it passes `-x c++` and otherwise
nothing new: clang's default C++ standard, and the same `-isysroot`,
`-resource-dir`, `-D_DEFAULT_SOURCE`, and `-I` arguments as C.

### 2.3 Collection in C++ mode

In `collect_decl`, C++ mode only:

- **Recurse into LinkageSpec cursors** (kind 23). Collect the functions and
  variables inside, which have C linkage by construction.
- **Skip functions and non-`const` variables outside a LinkageSpec.** These
  have C++ linkage, including inline functions with bodies, so they are
  never emitted and never omission-reported.
- **Keep structs, unions, enums, typedefs, and `const` variables with
  evaluable initializers** as C does. Examples are
  `const int k_iSteamUserStatsCallbacks = 1100;` and the
  `uint64_steamid` typedefs.
- **Classes (kind 4)** referenced by an imported declaration become opaque
  types (§16.9). That is how the flat API uses `ISteamUserStats*`. The
  mechanism is either collecting them as records and letting §2.4 demote
  them, or confirming that `collect_undefined_records` (`:1359-1369`)
  already treats a referenced, uncollected class as opaque. Stage 1
  settles which.

This needs one new cursor-kind constant (LinkageSpec, 23), plus
ClassDecl (4) if stage 1 goes the first way. It needs no new libclang
function: linkage is decided by where the declaration sits, not by
mangling.

### 2.4 Record layout check in C++ mode

Fields come only from FieldDecls. A C++ record with a vtable pointer or a
base class would get a With layout that is too small. The C fallback for a
record with no fields, `{ __pad0: u8 }` plus `Copy` (`CImport.w:2156-2163`),
would turn an interface class into a 1-byte value.

So, in C++ mode, every record's translated size and field offsets are
compared with `clang_Type_getSizeOf` and `clang_Type_getOffsetOf`, which
are already bound. Any mismatch demotes the record to opaque, and the
existing cascade (`CImport.w:1261-1288`) demotes records that hold it by
value.

For Steam this means:

- **Plain structs:** `CallbackMsg_t` and callback structs such as
  `UserStatsStored_t` and `GameOverlayActivated_t` import as values.
- **`#pragma pack(push, 4)`** is already honored
  (`CImport.w:2188-2295`).
- **CSteamID** contains a bitfield union, which the C rules already demote.
  Callback structs that hold a CSteamID by value (`UserStatsReceived_t`,
  for example) become opaque. The flat functions pass IDs as `uint64_steamid`
  instead, so no flat function needs CSteamID. This matches Valve's note
  that CSteamID and CGameID need special handling. The minimum leaves them
  opaque.
- **Empty callback structs** (`SteamShutdown_t`) are size 1 in C++, so the
  `__pad0` fallback happens to be right there. The size check confirms it.

### 2.5 Nested enumerators named by their record

Steam gives each callback struct `enum { k_iCallback = … };`. Today nested
anonymous enums are hoisted to file scope (`ClangBridge.w:1284-1318`), and
collisions are renamed `_2`, `_3` (`CImport.w:852-863`). That turns the
callback IDs into `k_iCallback`, `k_iCallback_2`, and so on, which is
useless for manual dispatch.

In C++ mode, an enumerator of an anonymous enum nested in a record is named
`<Record>_<enumerator>`, for example `UserStatsStored_t_k_iCallback`. C
mode keeps file-scope names: in C those enumerators really are file-scope,
and a collision is a C error.

---

## 3. Stages

| Stage | Change | Notes |
|---|---|---|
| 0 | **Check the list against the real header. Done; results below.** Dump the pinned SDK's `steam_api_flat.h` with the compiler's own clang (`with cc -x c++ -fsyntax-only -Xclang -ast-dump=json …`, `src/compiler/ClangDriver.w`). Record which cursor kinds the flat functions and callback structs reach; any `using` alias, `enum class`, or fixed-type enum; namespaced types; references; and C++ standard-library includes | Each finding either needs nothing, or adds one line to §2. For example, `using` aliases would mean collecting TypeAliasDecl (36) like TypedefDecl, and a fixed-type enum used by a flat function would need the enum use-site fix |
| 1 | §2.2, the argv helper, with no behavior change | Can land before the spec sentence |
| 2 | §2.1, §2.3, §2.4, §2.5, plus tests | Plan approved 2026-09-27 |
| 3 | Acceptance against the SDK (§4) | Out of tree: the SDK is not redistributable |

### Stage 0 results (SDK 1.65, 2026-09-27)

The header was checked with the compiler's own clang (`with cc`,
`v0.15.2.1-g99939352f`, clang 22.1.6), against a local copy of the SDK
headers. The SDK terms permit redistributing only `redistributable_bin/`,
so the headers are never committed anywhere, and acceptance runs where a
licensed copy exists:

- **As C:** 20 errors, the first at `steamtypes.h:122` ("must use 'enum'
  tag", then `bool`).
- **As C++:** no errors, using only `-isysroot` and `-I`. §2.2 needs
  nothing beyond `-x c++`.
- **Includes:** only `<string.h>`, `<stdint.h>`, and `<stdio.h>`, so no C++
  standard-library handling is needed.
- **No C++ constructs to add:** there are no `using` aliases,
  `enum class`, fixed-type enums, or namespaces anywhere in `public/steam/`.
  No TypeAliasDecl work is needed, and the enum use-site fix is not needed
  for Steam.
- **`S_API`** is `extern "C"` (plus visibility or `dllexport`) on every
  platform, which confirms §2.3's rule. `steam_api_flat.h` declares 1,021
  `S_API` functions; `steam_api.h` has 18 more.
- **34 flat functions take C++ references**, such as
  `const SteamNetworkingIdentity &`, all in networking and matchmaking. They
  hit the existing unsupported-type path and are omitted and reported, so
  they need `only:` or a non-`strict` import. Mapping `T&` to `*T`, which is
  ABI-identical, would be a later one-line addition. It is not part of the
  minimum.
- **155 nested `k_iCallback` enumerators**, which confirms §2.5.
- **Base classes** appear only in the `CCallback` templates in
  `steam_api_common.h`, which nothing in the flat surface references.
- **The macOS library's install name** is `@loader_path/libsteam_api.dylib`,
  so on macOS it is found beside the executable without an rpath. §5 is
  needed on Linux only.
- **SDK 1.65** removed `ISteamUtils::IsRunningOnSteamDeck()`. Its
  replacements are `IsRunningOnSteamHardware()` and
  `GetSteamHardwareDefaultConfig()`. The accessors in this SDK are
  `SteamUserStats_v013`, `SteamUtils_v011`, `SteamFriends_v018`, and
  `SteamApps_v009`.

---

## 4. Tests

No C++ compiler is needed. The pattern in
`test/behavior/behav_c_export_defines_a_c_imported_prototype.w` supplies
bodies: `@[c_export("name")]` With functions define the symbols that the
imported prototypes name.

- **`test/behavior/behav_c_import_cxx_flat.{h,w}`:** a header shaped like
  Steam's, with a C++-only construct beside every C-linkage one:
  - an interface class with virtual methods, used by pointer;
  - a template;
  - an inline C++ function;
  - `S_API`-style `extern "C"` declarations taking the interface pointer,
    `bool`, `const char*`, and `uint64` typedefs;
  - a `#pragma pack(push, 4)` callback struct with a `uint64` field and a
    nested `enum { k_iCallback = base + 2 }`;
  - `const int base = 1100;`.

  The `.w` file exports the functions with `@[c_export]`, calls them
  through the import, and prints the struct size and offsets, the callback
  ID, and the returned values.
- **`test/compile_errors/`:**
  - calling the inline C++ function is an unknown name;
  - using the interface class by value is an error;
  - `lang: "fortran"` is an error.
- **Regression:** a C import produces byte-for-byte the same output as
  before, with no `lang:` and with `lang: "c"`.
- **Cache:** the same header with `lang: "c"` and `lang: "c++"` gives two
  entries.
- **Acceptance, against the SDK:**
  - The import compiles.
  - Its functions, structs, and constants match `steam_api.json` from the
    same SDK.
  - A program linked against `libsteam_api` and run with `steam_appid.txt`
    = 480 (Spacewar) initializes Steam, sets and clears a test
    achievement, and receives `UserStatsStored_t` through manual dispatch.

---

## 5. Linking the library: a separate, small change

Imported functions are direct calls, so the program links `libsteam_api`.
Steam ships that library beside the executable. With's linker has no rpath
support (no `rpath`, `$ORIGIN`, or `@executable_path` anywhere in `src/`),
so on Linux the loader would not find `libsteam_api.so` without
`LD_LIBRARY_PATH`.

The minimum is one list of runtime search paths:

- `[link] rpath = ["$ORIGIN"]` in `with.toml`, parsed beside
  `libs`/`search_paths` (`src/compiler/ProjectConfig.w:281-288`), and/or
  `Target.rpath(...)` in `lib/std/build.w`.
- `src/compiler/Link.w` emits `-Wl,-rpath,<path>` on the Linux link line
  (`:331-367`) and the macOS equivalent. `@executable_path` is the macOS
  spelling of `$ORIGIN`.

This is independent of C++. A program that loads the library with `dlopen`
does not need it, but then it cannot call the imported functions directly;
it gets only the imported types and constants.

---

## 6. Proposed spec wording (approved with the plan, 2026-09-27; not yet in the spec)

For `docs/spec/ffi.md` §16.1, after the list of imported declaration kinds:

> `lang: "c++"` reads the header as C++ and imports only its declarations
> with C language linkage, the structs, unions, enums and typedefs they use,
> and integral constants. A class is an opaque type (§16.9); declarations
> with C++ linkage are not imported. `lang: "c"` is the default.

For `docs/spec/implementation/with-implementation-notes.md:1401`: "C++
(not supported)" becomes "C++ (only the C-linkage surface, with
`lang: "c++"`)".
