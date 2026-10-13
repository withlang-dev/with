# Goose port syntax census

Counts from the compiler lexer, excluding comments and strings. `as` includes intentional representation and floating-point conversions; typed bindings include accumulator widths and D22 owned Copy demands. These counts locate review work, not a claim that every spelling is redundant. The runner and shared RNG adapter are excluded from workload totals.

| workload | `as` tokens | `.clone()` calls | typed local bindings |
|---|---:|---:|---:|
| sum | 1 | 0 | 3 |
| push | 2 | 0 | 5 |
| strlist | 1 | 1 | 3 |
| records | 5 | 0 | 3 |
| tree | 2 | 0 | 4 |
| interp | 2 | 0 | 2 |
| graph | 3 | 1 | 14 |
| words | 1 | 2 | 6 |
| particles | 9 | 0 | 2 |
| sexp | 2 | 0 | 7 |
| lru | 3 | 0 | 14 |
| scene | 7 | 0 | 7 |
| calc | 5 | 0 | 12 |
| bintrees | 2 | 0 | 5 |
| respond | 8 | 0 | 8 |
| blur | 11 | 0 | 2 |
| **total** | **64** | **4** | **97** |

Review categories and storage choices are in [README.md](README.md). Generation width is tracked in [#2279](https://github.com/withlang-dev/with/issues/2279). D111 comparisons should record both measurement changes and removed clone spellings.
