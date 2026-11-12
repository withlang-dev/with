# The With Contract Language: landing order

The order in which the rules §31 marks "adopted 2026-11-11, not yet
implemented" land (Eric, 2026-11-11). Section numbers below are §31's.
Steps (a), (b) and (c) landed on 2026-11-11 (#3268, #3269, #3270); step
(d) on 2026-11-12 (#3273), and its battery was step (e): every published
program compiled and no further line was needed. Step (f) is the last.


The two default grants (sections 4, 6.2, 8.1, 8.3, 10) land in this order.
Nothing is trusted before the first step.

a. **The build cache.** A change to any contract input causes a rebuild. A
   changed contract that keeps an old safety verdict is a soundness bug.
   The inputs a build reads: every module it loads through `use`, a fetched
   package's `contract.w` among them; the project's `with.toml` and each
   fetched package's `metadata.json`, which decide which package's contract
   applies to an import. A registry facts file is not read by a build:
   `with get` reads it, writes its clauses into the package's `contract.w`
   and pins its digest in `contract.json`, so a changed facts file reaches a
   build as a changed `contract.w`.
b. **The checker sees a callback that arrives through a variadic case.**
   Today `callback_thread` on `curl_easy_setopt` is refused as "takes no
   callback".
c. **The view prints a binary's results as evidence** (section 6.3): `with
   analyze … contract` and the contract report print a result drawn for a
   prebuilt binary as evidence, with the configuration analyzed. What is
   accepted does not change in this step.
d. **The two default grants removed,** with the claim lines they make
   necessary landing in the same change: `runs no threads` in the c-interop
   example's contract (approved 2026-11-11); the rule of section 8.6 for a
   destroyer named through a function-pointer global, under which libxml2
   needs no `runs no threads` line; and
   `callback_thread registering` on `fn curl_easy_setopt` in
   `lib/contracts/libcurl.w` on three conditions (its citation says which
   thread libcurl invokes the callback on; the contract leaves `Easy`
   `thread creator`; the compose check of section 10, rule 5 exists).
e. **The recount,** by compiling every published program, to confirm
   nothing else needs a line.
f. **Proofs for prebuilt binaries:** the cost of each way to comply with
   section 6.3 (build from source whenever a contract needs a proof; or
   keep the binary and accept no proof), then the way Eric chooses. The
   default does not change before that. Chosen 2026-11-12: keep the
   binary and accept no proof ("the contract takes the place of proof").
   What the separately configured source shows is written to
   `contract-evidence.txt` and grants nothing; the contract is drawn from
   the headers and the registry. libxml2's registry file states the seven
   claims its UAT program rests on.

The thread-absence proof of section 8.5 is not in this order: it is
specified and not built.

**Note: what `with get` did before step (f)** (2026-11-11, for section 8.5's
"the build that was proved"). For each library it fetches:

- **A system package** (`opengl`, `xorg` and the others it knows as
  `"system"`): it writes link metadata. No source, no contract.
- **A Conan Center binary** (what it uses on Darwin and Linux whenever one
  is linkable): it takes the first static Release package for this os and
  arch, and downloads its `conaninfo.txt`. `metadata.json` records the
  recipe revision, the package id and the package revision; it does not
  record the options. For the contract it fetches the source separately,
  configures it (never builds it) for this platform with the recipe's
  default options, and the drafter reads that configuration's units. The
  configuration it proves is therefore its own, not the binary's, and
  nothing checks that they agree. This is true of every proof the drafter
  draws for a binary today (`drop f // proof: frees param 0`), not only of
  a thread proof.
- **A source build** (always on Windows; with `--from-source`; a package
  with a CMake environment of its own; or when no binary is linkable): it
  builds with CMake, Ninja and `with cc`, and the drafter reads that
  build's `compile_commands.json`. The configuration proved is the one
  linked.
- **A package whose source it cannot configure** (libiconv: autotools;
  OpenSSL: its own Configure script): it links the binary and writes no
  contract ("no proofs from the source").

The seven release UAT scenarios on Darwin fetch every library as a binary:
zlib, bzip2, sqlite3, libxml2 (with zlib and libiconv), libcurl (with
OpenSSL and zlib), SDL, raylib (with GLFW); `opengl` is a system package.
