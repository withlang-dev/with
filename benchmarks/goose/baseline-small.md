# Goose benchmark port: small

Recorded 2026-10-08. 16 workloads; 3 measured runs after two warmups. Whole-process best wall time and worst measured peak RSS, including input generation and destruction. With -O1; C++/Goose C -O2; Rust -O with one codegen unit. Raw times include process startup. MATCH means complete stdout equals the first successful C++/Rust reference, not equivalent storage semantics.

This run precedes removal of redundant literal-shift casts from the ports. A subsequent full smoke run checks the resulting sources against the same comparison implementations; these times have not been relabeled as measurements of a later compiler or of D111.


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
| sum | C++ idiomatic variant=0 | MATCH | 3802125 | 9748480 | |
| sum | C++ expert variant=1 | MATCH | 3521500 | 5505024 | |
| sum | Rust sum | MATCH | 3698500 | 5668864 | |
| sum | With | MATCH | 13459000 | 5799936 | |
| sum | Goose sum | MATCH | 3665875 | 5554176 | |
| push | C++ idiomatic variant=0 | MATCH | 4950375 | 17989632 | |
| push | C++ expert variant=1 | MATCH | 4049167 | 9797632 | |
| push | C++ idiomatic variant=2 | MATCH | 3946542 | 9830400 | |
| push | Rust push | MATCH | 3741542 | 9912320 | |
| push | With | MATCH | 5714792 | 10092544 | |
| push | Goose push | MATCH | 3573417 | 9682944 | |
| strlist | C++ idiomatic variant=0 | MATCH | 9293833 | 15220736 | |
| strlist | C++ expert variant=1 | MATCH | 8778709 | 11517952 | |
| strlist | C++ expert variant=2 | MATCH | 8232250 | 7782400 | |
| strlist | Rust strlist_owned | MATCH | 13313041 | 15237120 | |
| strlist | Rust strlist_borrowed | MATCH | 8770166 | 9650176 | |
| strlist | With | MATCH | 26267750 | 27656192 | |
| strlist | Goose strlist | MATCH | 8948333 | 7176192 | |
| records | C++ idiomatic variant=0 | MATCH | 26004291 | 21839872 | |
| records | C++ idiomatic variant=1 | MATCH | 21698792 | 42582016 | |
| records | C++ expert variant=2 | MATCH | 15503666 | 26165248 | |
| records | Rust records | MATCH | 16636333 | 21905408 | |
| records | With | MATCH | 23703166 | 21577728 | |
| records | Goose records_var | MATCH | 11568208 | 6176768 | |
| records | Goose records_fixed | MATCH | 12003458 | 12042240 | |
| tree | C++ idiomatic variant=0 | MATCH | 5326500 | 5685248 | |
| tree | C++ idiomatic variant=1 | MATCH | 5086375 | 5685248 | |
| tree | C++ expert variant=2 | MATCH | 3313083 | 3047424 | |
| tree | Rust tree_box | MATCH | 4922375 | 5865472 | |
| tree | Rust tree_arena | MATCH | 2935792 | 3227648 | |
| tree | With | MATCH | 3205875 | 3178496 | |
| tree | Goose tree | MATCH | 2858709 | 3096576 | |
| interp | C++ idiomatic variant=0 | MATCH | 2531000 | 2359296 | |
| interp | C++ expert variant=1 | MATCH | 2156583 | 2752512 | |
| interp | C++ expert variant=2 | MATCH | 2310792 | 2752512 | |
| interp | Rust interp_box | MATCH | 2818208 | 2899968 | |
| interp | Rust interp_arena | MATCH | 2230125 | 2179072 | |
| interp | With | MATCH | 2237041 | 2408448 | |
| interp | Goose interp | MATCH | 2046584 | 1785856 | |
| graph | C++ idiomatic variant=0 | MATCH | 27737167 | 10567680 | |
| graph | C++ expert variant=1 | MATCH | 12739208 | 12812288 | |
| graph | C++ expert variant=2 | MATCH | 33234208 | 9535488 | |
| graph | Rust graph_nested | MATCH | 21291959 | 10797056 | |
| graph | Rust graph_csr | MATCH | 13070458 | 13025280 | |
| graph | Rust graph_arena | MATCH | 32328958 | 9732096 | |
| graph | With | MATCH | 17351375 | 13074432 | |
| graph | Goose graph | MATCH | 28989625 | 9584640 | |
| graph | Goose graph_csr | MATCH | 11943334 | 12828672 | |
| words | C++ idiomatic variant=0 | MATCH | 30280500 | 29032448 | |
| words | C++ idiomatic variant=1 | MATCH | 33976750 | 30244864 | |
| words | C++ expert variant=2 | MATCH | 22585458 | 33456128 | |
| words | Rust words_hashmap | MATCH | 27122042 | 21299200 | |
| words | Rust words_open | MATCH | 23893500 | 25870336 | |
| words | With | MATCH | 104360500 | 62144512 | |
| words | Goose words | MATCH | 22365416 | 18874368 | |
| words | Goose words_dictionary | MATCH | 25753458 | 16351232 | |
| particles | C++ expert variant=0 | MATCH | 14606333 | 3899392 | |
| particles | C++ idiomatic variant=2 | MATCH | 15614042 | 3899392 | |
| particles | C++ expert variant=1 | MATCH | 18828875 | 3948544 | |
| particles | Rust particles | MATCH | 15738916 | 4079616 | |
| particles | Rust particles_scalar | MATCH | 13473542 | 4079616 | |
| particles | With | MATCH | 15111959 | 4767744 | |
| particles | Goose particles | MATCH | 15747416 | 3948544 | |
| particles | Goose particles_scalar | MATCH | 15261875 | 3948544 | |
| sexp | C++ idiomatic variant=0 | MATCH | 113358000 | 122109952 | |
| sexp | C++ expert variant=1 | MATCH | 77363041 | 101384192 | |
| sexp | Rust sexp_box | MATCH | 109349166 | 71335936 | |
| sexp | Rust sexp_arena | MATCH | 71034209 | 50184192 | |
| sexp | With | MATCH | 153033458 | 100106240 | |
| sexp | Goose sexp | MATCH | 73903958 | 27361280 | |
| lru | C++ idiomatic variant=0 | MATCH | 111784833 | 24264704 | |
| lru | C++ expert variant=1 | MATCH | 31292458 | 13975552 | |
| lru | Rust lru_hashmap | MATCH | 42963875 | 18972672 | |
| lru | Rust lru_open | MATCH | 32779000 | 12107776 | |
| lru | With | MATCH | 170328459 | 17170432 | |
| lru | Goose lru | MATCH | 32041459 | 9781248 | |
| scene | C++ idiomatic variant=0 | MATCH | 10120542 | 7143424 | |
| scene | C++ expert variant=1 | MATCH | 7228000 | 14352384 | |
| scene | Rust scene_box | MATCH | 9036458 | 7438336 | |
| scene | Rust scene_arena | MATCH | 6482917 | 8650752 | |
| scene | With | MATCH | 8469334 | 10010624 | |
| scene | Goose scene | MATCH | 6635458 | 6307840 | |
| calc | C++ idiomatic variant=0 | MATCH | 188591792 | 1540096 | |
| calc | C++ expert variant=1 | MATCH | 28726292 | 1474560 | |
| calc | Rust calc_box | MATCH | 55183000 | 1736704 | |
| calc | Rust calc_arena | MATCH | 25917750 | 1687552 | |
| calc | With | MATCH | 39004208 | 1540096 | |
| calc | Goose calc | MATCH | 28632750 | 1556480 | |
| bintrees | C++ idiomatic variant=0 | MATCH | 99569834 | 3604480 | |
| bintrees | C++ expert variant=1 | MATCH | 15804459 | 3637248 | |
| bintrees | Rust bintrees_box | MATCH | 99532000 | 3784704 | |
| bintrees | Rust bintrees_arena | MATCH | 13476417 | 3358720 | |
| bintrees | With | MATCH | 28197834 | 2670592 | |
| bintrees | Goose bintrees | MATCH | 16112042 | 3096576 | |
| respond | C++ idiomatic variant=0 | MATCH | 56472667 | 1753088 | |
| respond | C++ expert variant=1 | MATCH | 36070500 | 1474560 | |
| respond | Rust respond_dto | MATCH | 71665708 | 1818624 | |
| respond | Rust respond_stream | MATCH | 36376042 | 1687552 | |
| respond | With | MATCH | 93248583 | 1540096 | |
| respond | Goose respond | MATCH | 32214541 | 1556480 | |
| respond | Goose respond_stream | MATCH | 26248708 | 1523712 | |
| blur | C++ idiomatic variant=0 | MATCH | 23382167 | 4390912 | |
| blur | C++ expert variant=1 | MATCH | 4790667 | 3571712 | |
| blur | Rust blur_index | MATCH | 4847375 | 5390336 | |
| blur | Rust blur_windows | MATCH | 4766291 | 5373952 | |
| blur | With | MATCH | 31606125 | 3735552 | |
| blur | Goose blur | MATCH | 4419375 | 3620864 | |
| blur | Goose blur_rows | MATCH | 4487292 | 3637248 | |

Failures: 0. Pending Goose rows: 0. No ratios are reported; inspect representation notes before comparing timings.
