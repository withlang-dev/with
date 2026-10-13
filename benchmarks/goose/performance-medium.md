| workload | With ms | fastest safe Rust ms | Rust row | With / Rust | verdict |
|---|---:|---:|---|---:|---|
| sum | 190.766 | 36.440 | Rust sum | 5.235 | BUG |
| push | 70.852 | 35.181 | Rust push | 2.014 | BUG |
| strlist | 245.986 | 74.599 | Rust strlist_borrowed | 3.297 | BUG |
| records | 180.328 | 121.889 | Rust records | 1.479 | BUG |
| tree | 30.029 | 27.019 | Rust tree_arena | 1.111 | BUG |
| interp | 6.881 | 6.496 | Rust interp_arena | 1.059 | BUG |
| graph | 98.392 | 76.191 | Rust graph_csr | 1.291 | BUG |
| words | 914.180 | 214.864 | Rust words_open | 4.255 | BUG |
| particles | 134.688 | 121.878 | Rust particles_scalar | 1.105 | BUG |
| sexp | 730.664 | 340.179 | Rust sexp_arena | 2.148 | BUG |
| lru | 1141.896 | 146.623 | Rust lru_open | 7.788 | BUG |
| scene | 51.793 | 31.452 | Rust scene_arena | 1.647 | BUG |
| calc | 154.815 | 98.707 | Rust calc_arena | 1.568 | BUG |
| bintrees | 122.806 | 59.669 | Rust bintrees_arena | 2.058 | BUG |
| respond | 351.766 | 141.215 | Rust respond_stream | 2.491 | BUG |
| blur | 189.684 | 14.274 | Rust blur_windows | 13.289 | BUG |

Performance bugs: 16. This comparison includes process startup and representation differences; it identifies losses, not their causes.
