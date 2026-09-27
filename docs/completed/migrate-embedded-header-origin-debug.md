# Materialized builtin header origins

The system-header predicate recognized installed Clang paths containing
`/clang/`, but not this compiler's materialized builtin resource directory.
That let a header such as `__stddef_null.h` export `NULL` into migrated
output. Both promoted corpus definition files also carried that SDK export.

A minimal fixture undefines NULL, includes `<__stddef_null.h>`, and defines
an ordinary project function. The unfixed migrator emits
`let NULL: *mut c_void = null`. LLDB observed
`cimport_location_path_is_system` receive
`/Users/eric/.cache/with/clang-resource/22/include/__stddef_null.h` and return
`w0=0` to `macro_location_is_system_from_cursor+120`, PC 0x10094cf88.
The backtrace continues through `collect_macro_def`, so the wrong verdict
is recorded as the macro's declaration origin before emission.
Evidence: `/tmp/with-resource-null-lldb.log` and
`/tmp/with-resource-null-migrate.log`.

The shared classifier now recognizes the actual resource directory configured
for libclang. Separator normalization applies to both paths, and the prefix
requires a trailing slash so neighboring project directories stay public.
No cache-root or version spelling is guessed, and no external LLVM resource
lookup is introduced. Macro expansion data and ordinary c_import behavior
remain available through their existing paths.

`behav_migrate_embedded_header_origins.w` forces the builtin NULL definition,
requires its SDK declaration to be absent, and executes a project-owned
alias and a migrated pointer comparison. The old compiler fails the absence
assertion at line 13; the test does not merely depend on a duplicate-name
diagnostic from some other module.

The local Linux bootstrap compiler also exposed the leak as a NULL shadowing
error when running generated code from the repository root. Its completed
stage2 passed the original va_list regression with the extern-signature fix,
so that bootstrap error alone does not establish the old CI failure's cause.

Source check, development stage1/stage2, the new regression and all four
existing macro regressions pass. PCRE2 and zlib regeneration changes only
their shared defs: NULL, the builtin integer-limit macros, and max_align_t
disappear. Every generated implementation file is byte-identical; bundle.w
is maintained separately and retained. Logs:
`/tmp/with-resource-origin-{source-check,stage2,fixed-test,windows-test,macro-test,import-test,paste-test,pcre2,zlib}.log`.

The exact archived c8f70c19 was rebuilt for Linux x86. Its isolated memchr
test reproduces the index panic; its isolated va_list test passes. This
narrows the outstanding CI investigation but does not explain the original
full-suite va_list failure. The updated Linux workflow retains the captures
needed if it recurs.
