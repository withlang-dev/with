# 18.5 Toolchain

A single binary provides all tools:

```
with build [--release] [--target <triple>]   # build the project
with run <file>                              # compile and run
with check <file>                            # typecheck only, no codegen
with test                                    # run the test suite
with fmt                                     # format source
with doc [--open]                            # generate documentation
with repl                                    # interactive session
with init                                    # create a new project
with uat [<scenario>]                        # run the project's acceptance scenarios (uat/*.uat, §18.5d)
with migrate <c-sources>                     # translate C to With (§13.5b, §16)
with emit-c-header <file>                    # emit C declarations for @[c_export] (§16.5)
with cc <clang arguments>                    # the C compiler inside this binary (§18.8)
with version [--abi-sha | --self-id] | with help   # --abi-sha: the ABI identity .wo bundles key on; --self-id: the sha256 of this compiler's unstamped image (empty for an unstamped binary), the build cache's identity for a compiler
with -e <code> | -n <code> | -p <code>      # one-liners (§18.5b)
```

Additional flags: `--emit-c` (C source backend, used for
bootstrapping new platforms), `--emit-obj`, `--overflow=<mode>`
(§4.2.3), `--no-std` (§18.7), `--strict-effects` (§17.1b),
`--debug-alloc` (run under the native debug allocator),
`--trace-alloc` (trace allocation requests to standard error while running programs or tests),
`-O0`..`-O3`. The `--dump-*` family
(`tokens`, `ast`, `resolved`, `typed`, `mir`, `async-mir`,
`project-info`) and the `ir`/`ast`/`tokens` subcommands are
compiler-diagnostic surface: available, but implementation-internal
and not covered by stability guarantees.

Cross-compilation is a normal mode, not special.

`with analyze` provides a foreign-contract view: the effective modeled
foreign contract (§16.2b) — resources, producers, destroyers, effects,
retention, borrowed results, dependencies, status conventions, nullability,
domains, preservation, static lifetime, callback and thread facts,
presentation — with the provenance of every fact, and the relationships
between origins, domains and the views that depend on them. It flags
suspicious configurations: a producer with no destroy path, a destroyer
presented as a lend, a retained callback with no owner, an illegal thread
combination, an ambiguous profile match, a profile fact shadowed by an
override, and a function whose name and shape resemble a destroyer but which
is exposed as a lend. The last is advisory: it changes no contract, and an
explicit `lend` records that the author reviewed it. Tooling that proposes
or reports a lend states that it is an assertion about foreign behavior,
never a conservative inference.

Facade-generation tooling may emit a draft facade from the heuristics
§16.2b.2 permits tooling to use. Every capability-granting line it proposes
is commented out with its provenance; the author uncomments what they trust,
and the compiler verifies each clause (§16.2b.13). A generated facade is
ordinary With source in the project's source or package space (a `facades/`
directory is a convention, not a compiler location) and is never adopted
silently.
