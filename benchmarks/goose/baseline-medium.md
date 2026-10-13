# Goose benchmark port: medium

16 workloads; 5 measured runs after two warmups. Whole-process best wall time and worst measured peak RSS, including input generation and destruction. With -O1; C++/Goose C -O2; Rust -O with one codegen unit. Raw times include process startup. MATCH means complete stdout equals the first successful C++/Rust reference, not equivalent storage semantics.


```text
Darwin arm64
Workspace revision: 5cb113bce720dba2907801293378aa80f4467afb
Goose revision: 35368105e3d50341b79a4cb873cc0261e82dfa42
With compiler executable: /Users/eric/with/out/bootstrap/bin/with-stage1
with v0.15.3.0-g5cb113bce
With compiler SHA-256: 0e78562661060d13664817c3106cb2754a6f985fae5dbbb435dc7c920d4cb4ef  /Users/eric/with/out/bootstrap/bin/with-stage1
Apple clang version 21.0.0 (clang-2100.3.34.2)
Target: arm64-apple-darwin25.6.0
Thread model: posix
InstalledDir: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin
rustc 1.97.1 (8bab26f4f 2026-07-14)
Goose executable: out/benchmarks/goose/compiler/goose
```
| workload | implementation | status | best ns | peak RSS bytes | note |
|---|---|---|---:|---:|---|
| sum | C++ idiomatic variant=0 | MATCH | 39570417 | 132726784 | |
| sum | C++ expert variant=1 | MATCH | 35078958 | 65503232 | |
| sum | Rust sum | MATCH | 36439584 | 65667072 | |
| sum | With | MATCH | 190766292 | 68714496 | |
| sum | Goose sum | MATCH | 34932500 | 65552384 | |
| push | C++ idiomatic variant=0 | MATCH | 48173250 | 263864320 | |
| push | C++ expert variant=1 | MATCH | 38855917 | 133660672 | |
| push | C++ idiomatic variant=2 | MATCH | 43535500 | 134234112 | |
| push | Rust push | MATCH | 35181083 | 131792896 | |
| push | With | MATCH | 70851542 | 136888320 | |
| push | Goose push | MATCH | 36010625 | 131563520 | |
| strlist | C++ idiomatic variant=0 | MATCH | 81229708 | 125009920 | |
| strlist | C++ expert variant=1 | MATCH | 71809041 | 101679104 | |
| strlist | C++ expert variant=2 | MATCH | 70167584 | 68878336 | |
| strlist | Rust strlist_owned | MATCH | 115309458 | 116293632 | |
| strlist | Rust strlist_borrowed | MATCH | 74599375 | 60948480 | |
| strlist | With | MATCH | 245985875 | 263487488 | |
| strlist | Goose strlist | MATCH | 77030042 | 57573376 | |
| records | C++ idiomatic variant=0 | MATCH | 191007958 | 163594240 | |
| records | C++ idiomatic variant=1 | MATCH | 161557917 | 329449472 | |
| records | C++ expert variant=2 | MATCH | 115017959 | 198295552 | |
| records | Rust records | MATCH | 121889334 | 147931136 | |
| records | With | MATCH | 180328458 | 161742848 | |
| records | Goose records_var | MATCH | 84141833 | 38535168 | |
| records | Goose records_fixed | MATCH | 87672625 | 85540864 | |
| tree | C++ idiomatic variant=0 | MATCH | 62338292 | 68878336 | |
| tree | C++ idiomatic variant=1 | MATCH | 58994792 | 68894720 | |
| tree | C++ expert variant=2 | MATCH | 27481000 | 26673152 | |
| tree | Rust tree_box | MATCH | 57101542 | 69074944 | |
| tree | Rust tree_arena | MATCH | 27018833 | 26820608 | |
| tree | With | MATCH | 30028792 | 26771456 | |
| tree | Goose tree | MATCH | 23098875 | 26705920 | |
| interp | C++ idiomatic variant=0 | MATCH | 9649292 | 8323072 | |
| interp | C++ expert variant=1 | MATCH | 6805917 | 11419648 | |
| interp | C++ expert variant=2 | MATCH | 6535583 | 11419648 | |
| interp | Rust interp_box | MATCH | 10978125 | 11173888 | |
| interp | Rust interp_arena | MATCH | 6495833 | 6897664 | |
| interp | With | MATCH | 6881291 | 7897088 | |
| interp | Goose interp | MATCH | 5474875 | 3522560 | |
| graph | C++ idiomatic variant=0 | MATCH | 183088625 | 46514176 | |
| graph | C++ expert variant=1 | MATCH | 75038542 | 57638912 | |
| graph | C++ expert variant=2 | MATCH | 406945125 | 41549824 | |
| graph | Rust graph_nested | MATCH | 139599209 | 46743552 | |
| graph | Rust graph_csr | MATCH | 76190500 | 57835520 | |
| graph | Rust graph_arena | MATCH | 348866291 | 41762816 | |
| graph | With | MATCH | 98391791 | 57802752 | |
| graph | Goose graph | MATCH | 324381584 | 41582592 | |
| graph | Goose graph_csr | MATCH | 68383875 | 57638912 | |
| words | C++ idiomatic variant=0 | MATCH | 257663375 | 212221952 | |
| words | C++ idiomatic variant=1 | MATCH | 264552375 | 213925888 | |
| words | C++ expert variant=2 | MATCH | 196132875 | 248643584 | |
| words | Rust words_hashmap | MATCH | 241748584 | 152829952 | |
| words | Rust words_open | MATCH | 214863584 | 178864128 | |
| words | With | MATCH | 914180041 | 486621184 | |
| words | Goose words | MATCH | 189506333 | 139968512 | |
| words | Goose words_dictionary | MATCH | 208458833 | 120045568 | |
| particles | C++ expert variant=0 | MATCH | 135549459 | 25493504 | |
| particles | C++ idiomatic variant=2 | MATCH | 145458375 | 25477120 | |
| particles | C++ expert variant=1 | MATCH | 196929625 | 25657344 | |
| particles | Rust particles | MATCH | 141979917 | 25657344 | |
| particles | Rust particles_scalar | MATCH | 121878167 | 25657344 | |
| particles | With | MATCH | 134688416 | 26771456 | |
| particles | Goose particles | MATCH | 143588209 | 25542656 | |
| particles | Goose particles_scalar | MATCH | 136438958 | 25526272 | |
| sexp | C++ idiomatic variant=0 | MATCH | 535683834 | 590741504 | |
| sexp | C++ expert variant=1 | MATCH | 371752584 | 436846592 | |
| sexp | Rust sexp_box | MATCH | 516123792 | 340426752 | |
| sexp | Rust sexp_arena | MATCH | 340179459 | 234602496 | |
| sexp | With | MATCH | 730663750 | 429801472 | |
| sexp | Goose sexp | MATCH | 348536125 | 130351104 | |
| lru | C++ idiomatic variant=0 | MATCH | 901245250 | 92307456 | |
| lru | C++ expert variant=1 | MATCH | 133587042 | 51150848 | |
| lru | Rust lru_hashmap | MATCH | 231837375 | 71974912 | |
| lru | Rust lru_open | MATCH | 146623041 | 36683776 | |
| lru | With | MATCH | 1141895666 | 63471616 | |
| lru | Goose lru | MATCH | 138997375 | 34357248 | |
| scene | C++ idiomatic variant=0 | MATCH | 59267500 | 36667392 | |
| scene | C++ expert variant=1 | MATCH | 36752291 | 63602688 | |
| scene | Rust scene_box | MATCH | 51105084 | 37650432 | |
| scene | Rust scene_arena | MATCH | 31452458 | 34291712 | |
| scene | With | MATCH | 51793208 | 35176448 | |
| scene | Goose scene | MATCH | 34682792 | 31309824 | |
| calc | C++ idiomatic variant=0 | MATCH | 746625416 | 1556480 | |
| calc | C++ expert variant=1 | MATCH | 111771000 | 1474560 | |
| calc | Rust calc_box | MATCH | 216328958 | 1736704 | |
| calc | Rust calc_arena | MATCH | 98707416 | 1671168 | |
| calc | With | MATCH | 154814959 | 1523712 | |
| calc | Goose calc | MATCH | 110367417 | 1556480 | |
| bintrees | C++ idiomatic variant=0 | MATCH | 468657417 | 9912320 | |
| bintrees | C++ expert variant=1 | MATCH | 68380666 | 9961472 | |
| bintrees | Rust bintrees_box | MATCH | 452449167 | 10108928 | |
| bintrees | Rust bintrees_arena | MATCH | 59669166 | 8110080 | |
| bintrees | With | MATCH | 122805542 | 5799936 | |
| bintrees | Goose bintrees | MATCH | 70570083 | 7815168 | |
| respond | C++ idiomatic variant=0 | MATCH | 219252500 | 1769472 | |
| respond | C++ expert variant=1 | MATCH | 139647416 | 1474560 | |
| respond | Rust respond_dto | MATCH | 276276750 | 1818624 | |
| respond | Rust respond_stream | MATCH | 141214583 | 1687552 | |
| respond | With | MATCH | 351766417 | 1540096 | |
| respond | Goose respond | MATCH | 120394000 | 1556480 | |
| respond | Goose respond_stream | MATCH | 100946042 | 1540096 | |
| blur | C++ idiomatic variant=0 | MATCH | 91402208 | 17039360 | |
| blur | C++ expert variant=1 | MATCH | 14866125 | 9895936 | |
| blur | Rust blur_index | MATCH | 14881791 | 18038784 | |
| blur | Rust blur_windows | MATCH | 14273792 | 18022400 | |
| blur | With | MATCH | 189684375 | 10010624 | |
| blur | Goose blur | MATCH | 13786084 | 9928704 | |
| blur | Goose blur_rows | MATCH | 13689500 | 9928704 | |

Failures: 0. Pending Goose rows: 0. No ratios are reported; inspect representation notes before comparing timings.
