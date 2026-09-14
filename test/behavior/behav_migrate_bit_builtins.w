//! expect-stdout: ok

use pre_d_build_runner

// The bit builtins lower structurally to With's integer methods on the
// builtin's unsigned width: __builtin_clz(x) is (x as u32).clz(), the
// ll forms are u64, bswapN is swap_bytes on the N-bit unsigned (TommyDS's
// tommy_ilog2 / tommy_ctz family, Phase 2).
fn main:
    let case_dir = p7_prepare_case("migrate_bit_builtins", "migrate_bit_builtins_test")
    p7_write(case_dir, "input.c", "int ilog2_u32(unsigned x) { return __builtin_clz(x) ^ 31; }\nint ilog2_u64(unsigned long long x) { return __builtin_clzll(x) ^ 63; }\nint ctz_u32(unsigned x) { return __builtin_ctz(x); }\nint ctz_u64(unsigned long long x) { return __builtin_ctzll(x); }\nint pop_u32(unsigned x) { return __builtin_popcount(x); }\nunsigned short bs16(unsigned short x) { return __builtin_bswap16(x); }\nunsigned bs32(unsigned x) { return __builtin_bswap32(x); }\nunsigned long long bs64(unsigned long long x) { return __builtin_bswap64(x); }\n")
    p7_write(case_dir, "lib/.keep", "")
    let migrated = p7_run(case_dir, "bit_builtins_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/bits.w\0")
    p7_assert_success(migrated, "migrate the bit builtins as integer methods")
    p7_write(case_dir, "src/main.w", "use bits\nfn main:\n    assert(ilog2_u32(1 as u32) == 0 and ilog2_u32(0x80000000 as u32) == 31 and ilog2_u32(1000 as u32) == 9)\n    assert(ilog2_u64(1 as u64) == 0 and ilog2_u64(0x8000000000000000 as u64) == 63)\n    assert(ctz_u32(8 as u32) == 3 and ctz_u64(0x100000000 as u64) == 32)\n    assert(pop_u32(0xF0F0 as u32) == 8)\n    assert(bs16(0x1234 as u16) == 0x3412 as u16)\n    assert(bs32(0x11223344 as u32) == 0x44332211 as u32)\n    assert(bs64(0x0102030405060708 as u64) == 0x0807060504030201 as u64)\n    print(\"bits ok\")\n")
    let executed = p7_run(case_dir, "bit_builtins_run", "run\0src/main.w\0")
    p7_assert_success(executed, "run the lowered builtins")
    assert(executed.stdout.contains("bits ok"))
    print("ok")
