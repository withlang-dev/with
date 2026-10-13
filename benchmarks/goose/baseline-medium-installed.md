# Goose benchmark port: medium

16 workloads; 5 measured runs after two warmups. Whole-process best wall time and worst measured peak RSS, including input generation and destruction. With -O1; C++/Goose C -O2; Rust -O with one codegen unit. Raw times include process startup. MATCH means complete stdout equals the first successful C++/Rust reference, not equivalent storage semantics.


```text
Darwin arm64
Workspace revision: 5cb113bce720dba2907801293378aa80f4467afb
Goose revision: 35368105e3d50341b79a4cb873cc0261e82dfa42
with v0.15.3.0
Apple clang version 21.0.0 (clang-2100.3.34.2)
Target: arm64-apple-darwin25.6.0
Thread model: posix
InstalledDir: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin
rustc 1.97.1 (8bab26f4f 2026-07-14)
Goose executable: out/benchmarks/goose/compiler/goose
```
| workload | implementation | status | best ns | peak RSS bytes | note |
|---|---|---|---:|---:|---|
| sum | C++ idiomatic variant=0 | MATCH | 39587333 | 132726784 | |
| sum | C++ expert variant=1 | MATCH | 35465541 | 65503232 | |
| sum | Rust sum | MATCH | 36519958 | 65667072 | |
| sum | With | MATCH | 189805208 | 68730880 | |
| sum | Goose sum | MATCH | 34825458 | 65552384 | |
| push | C++ idiomatic variant=0 | MATCH | 49369416 | 266944512 | |
| push | C++ expert variant=1 | MATCH | 38117542 | 133660672 | |
| push | C++ idiomatic variant=2 | MATCH | 43106208 | 134234112 | |
| push | Rust push | MATCH | 34807125 | 131792896 | |
| push | With | MATCH | 70061916 | 136904704 | |
| push | Goose push | MATCH | 36050791 | 131563520 | |
| strlist | C++ idiomatic variant=0 | MATCH | 79385125 | 125009920 | |
| strlist | C++ expert variant=1 | MATCH | 70490083 | 101679104 | |
| strlist | C++ expert variant=2 | MATCH | 68932417 | 72007680 | |
| strlist | Rust strlist_owned | MATCH | 114839083 | 116293632 | |
| strlist | Rust strlist_borrowed | MATCH | 73476833 | 60948480 | |
| strlist | With | MATCH | 248255333 | 263487488 | |
| strlist | Goose strlist | MATCH | 74628334 | 57573376 | |
| records | C++ idiomatic variant=0 | MATCH | 188252459 | 163594240 | |
| records | C++ idiomatic variant=1 | MATCH | 161074500 | 329433088 | |
| records | C++ expert variant=2 | MATCH | 114361000 | 198295552 | |
| records | Rust records | MATCH | 120348625 | 147931136 | |
| records | With | MATCH | 183758458 | 161742848 | |
| records | Goose records_var | MATCH | 83137709 | 38535168 | |
| records | Goose records_fixed | MATCH | 86846750 | 85540864 | |
| tree | C++ idiomatic variant=0 | MATCH | 61918875 | 68894720 | |
| tree | C++ idiomatic variant=1 | MATCH | 58062500 | 68894720 | |
| tree | C++ expert variant=2 | MATCH | 27502916 | 26673152 | |
| tree | Rust tree_box | MATCH | 56271875 | 69074944 | |
| tree | Rust tree_arena | MATCH | 26871416 | 26820608 | |
| tree | With | MATCH | 30292833 | 26771456 | |
| tree | Goose tree | MATCH | 22747333 | 26705920 | |
| interp | C++ idiomatic variant=0 | MATCH | 9599667 | 8323072 | |
| interp | C++ expert variant=1 | MATCH | 7250333 | 11419648 | |
| interp | C++ expert variant=2 | MATCH | 6587083 | 11419648 | |
| interp | Rust interp_box | MATCH | 11111083 | 11157504 | |
| interp | Rust interp_arena | MATCH | 6590459 | 6897664 | |
| interp | With | MATCH | 7039875 | 7913472 | |
| interp | Goose interp | MATCH | 5545125 | 3506176 | |
| graph | C++ idiomatic variant=0 | MATCH | 190214584 | 46530560 | |
| graph | C++ expert variant=1 | MATCH | 71611167 | 57638912 | |
| graph | C++ expert variant=2 | MATCH | 442944875 | 41549824 | |
| graph | Rust graph_nested | MATCH | 155150583 | 46776320 | |
| graph | Rust graph_csr | MATCH | 74622625 | 57835520 | |
| graph | Rust graph_arena | MATCH | 373248708 | 41762816 | |
| graph | With | MATCH | 96617958 | 57802752 | |
| graph | Goose graph | MATCH | 337037000 | 41582592 | |
| graph | Goose graph_csr | MATCH | 66451792 | 57638912 | |
| words | C++ idiomatic variant=0 | MATCH | 257278333 | 212221952 | |
| words | C++ idiomatic variant=1 | MATCH | 262483125 | 212238336 | |
| words | C++ expert variant=2 | MATCH | 197143917 | 248643584 | |
| words | Rust words_hashmap | MATCH | 240495375 | 152829952 | |
| words | Rust words_open | MATCH | 218061541 | 180224000 | |
| words | With | MATCH | 947345208 | 486621184 | |
| words | Goose words | MATCH | 189841958 | 139968512 | |
| words | Goose words_dictionary | MATCH | 206410000 | 120045568 | |
| particles | C++ expert variant=0 | MATCH | 133395917 | 25493504 | |
| particles | C++ idiomatic variant=2 | MATCH | 143552875 | 25477120 | |
| particles | C++ expert variant=1 | MATCH | 194764083 | 25657344 | |
| particles | Rust particles | MATCH | 140607958 | 25657344 | |
| particles | Rust particles_scalar | MATCH | 120527917 | 25657344 | |
| particles | With | MATCH | 132856625 | 26820608 | |
| particles | Goose particles | MATCH | 141285500 | 25542656 | |
| particles | Goose particles_scalar | MATCH | 134353167 | 25542656 | |
| sexp | C++ idiomatic variant=0 | MATCH | 539440750 | 590725120 | |
| sexp | C++ expert variant=1 | MATCH | 374671250 | 437256192 | |
| sexp | Rust sexp_box | MATCH | 522887291 | 340443136 | |
| sexp | Rust sexp_arena | MATCH | 344679375 | 234602496 | |
| sexp | With | MATCH | 747193791 | 429801472 | |
| sexp | Goose sexp | MATCH | 350188542 | 130351104 | |
| lru | C++ idiomatic variant=0 | MATCH | 930107417 | 92274688 | |
| lru | C++ expert variant=1 | MATCH | 134899041 | 51167232 | |
| lru | Rust lru_hashmap | MATCH | 235644875 | 71974912 | |
| lru | Rust lru_open | MATCH | 148651958 | 36683776 | |
| lru | With | MATCH | 1207565291 | 63471616 | |
| lru | Goose lru | MATCH | 139804958 | 34357248 | |
| scene | C++ idiomatic variant=0 | MATCH | 58600875 | 36667392 | |
| scene | C++ expert variant=1 | MATCH | 36926958 | 63602688 | |
| scene | Rust scene_box | MATCH | 49850625 | 37650432 | |
| scene | Rust scene_arena | MATCH | 31656416 | 34291712 | |
| scene | With | MATCH | 53468584 | 35176448 | |
| scene | Goose scene | MATCH | 34063250 | 31309824 | |
| calc | C++ idiomatic variant=0 | MATCH | 741086416 | 1556480 | |
| calc | C++ expert variant=1 | MATCH | 109532583 | 1474560 | |
| calc | Rust calc_box | MATCH | 210210584 | 1736704 | |
| calc | Rust calc_arena | MATCH | 97845375 | 1671168 | |
| calc | With | MATCH | 149212625 | 1540096 | |
| calc | Goose calc | MATCH | 108849792 | 1556480 | |
| bintrees | C++ idiomatic variant=0 | MATCH | 459326125 | 9945088 | |
| bintrees | C++ expert variant=1 | MATCH | 67828334 | 9961472 | |
| bintrees | Rust bintrees_box | MATCH | 448578875 | 10108928 | |
| bintrees | Rust bintrees_arena | MATCH | 58564625 | 8110080 | |
| bintrees | With | MATCH | 121762542 | 5816320 | |
| bintrees | Goose bintrees | MATCH | 69971916 | 7815168 | |
| respond | C++ idiomatic variant=0 | MATCH | 217985375 | 1769472 | |
| respond | C++ expert variant=1 | MATCH | 138665208 | 1474560 | |
| respond | Rust respond_dto | MATCH | 277428125 | 1818624 | |
| respond | Rust respond_stream | MATCH | 140198250 | 1687552 | |
| respond | With | MATCH | 361852291 | 1540096 | |
| respond | Goose respond | MATCH | 118139833 | 1556480 | |
| respond | Goose respond_stream | MATCH | 98716375 | 1540096 | |
| blur | C++ idiomatic variant=0 | MATCH | 88868334 | 17039360 | |
| blur | C++ expert variant=1 | MATCH | 14853875 | 9895936 | |
| blur | Rust blur_index | MATCH | 15412334 | 18038784 | |
| blur | Rust blur_windows | MATCH | 14188959 | 18022400 | |
| blur | With | MATCH | 122430292 | 10027008 | |
| blur | Goose blur | MATCH | 13609959 | 9928704 | |
| blur | Goose blur_rows | MATCH | 13465667 | 9928704 | |

Failures: 0. Pending Goose rows: 0. No ratios are reported; inspect representation notes before comparing timings.
