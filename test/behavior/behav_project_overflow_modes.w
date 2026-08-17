//! expect-stdout: ok

use pre_d_build_runner

fn main:
    let wrap_dir = p7_prepare_case("overflow_wrap_mode", "p7overflowwrap")
    p7_write(wrap_dir, "with.toml", "[package]\nname = \"p7overflowwrap\"\nversion = \"0.1.0\"\n\n[build]\noverflow = \"wrap\"\n")
    p7_write(wrap_dir, "src/main.w", "const X: u8 = 255 + 1u8\n\nfn main:\n    let zero: u8 = 0\n    assert(X == zero)\n")
    p7_assert_success(p7_run(wrap_dir, "overflow-wrap-mode", p7_build_args()), "overflow wrap mode")

    let sat_dir = p7_prepare_case("overflow_saturate_mode", "p7overflowsaturate")
    p7_write(sat_dir, "with.toml", "[package]\nname = \"p7overflowsaturate\"\nversion = \"0.1.0\"\n\n[build]\noverflow = \"saturate\"\n")
    p7_write(sat_dir, "src/main.w", "const X: u8 = 250 + 20u8\n\nfn main:\n    let max_u8: u8 = 255\n    assert(X == max_u8)\n")
    p7_assert_success(p7_run(sat_dir, "overflow-saturate-mode", p7_build_args()), "overflow saturate mode")

    print("ok")
