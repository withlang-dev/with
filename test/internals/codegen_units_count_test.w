//! expect-stdout: ok

// Compiler partitions must remain small even on hosts with few CPU cores.
// Memory controls worker concurrency independently of partition count.

use compiler.CodegenUnitsPolicy

fn gib(n: i64): n * 1024 * 1024 * 1024

fn main:
    assert(codegen_units_count_for(0) == 1)
    assert(codegen_units_count_for(1999) == 1)
    assert(codegen_units_count_for(2000) == 16)
    assert(codegen_units_count_for(7553) == 16)
    assert(codegen_units_count_for(50000) == 16)

    // --- emit window: budget = mem − 5 GiB frontend reserve, per-unit = IR/K ---
    // Cost chosen so estimated total IR = 8 GiB, independent of the
    // calibration constant's exact value.
    let c8 = gib(8) / codegen_units_bytes_per_stmt()

    // Single unit: always width 1.
    assert(codegen_units_emit_width_for(1, c8, gib(64)) == 1)
    // Small hosts reserve space for a unit's peak, not just its average.
    assert(codegen_units_emit_width_for(16, c8, gib(8)) == 1)
    assert(codegen_units_emit_width_for(8, c8, gib(8)) == 1)
    assert(codegen_units_emit_width_for(16, 409756, gib(7)) == 1)
    assert(codegen_units_emit_width_for(16, c8, gib(9)) == 8)
    // 6 GiB host: 1 GiB budget → single unit at a time.
    assert(codegen_units_emit_width_for(8, c8, gib(6)) == 1)
    // At or under the frontend reserve: never more than one.
    assert(codegen_units_emit_width_for(16, c8, gib(5)) == 1)
    assert(codegen_units_emit_width_for(16, c8, gib(2)) == 1)
    // Big host: every unit concurrent (today's behavior preserved).
    assert(codegen_units_emit_width_for(16, c8, gib(64)) == 16)
    assert(codegen_units_emit_width_for(16, c8, gib(128)) == 16)
    // Tiny module: cost rounds to nothing → no throttling.
    assert(codegen_units_emit_width_for(16, 0, gib(64)) == 16)

    // Compiler-scale canary: plan_cost measured 2026-07-18 (289004 stmts,
    // ~10.4 GiB est IR). An 8 GB host serializes the units;
    // a 16 GB host keeps all 16 in flight.
    assert(codegen_units_emit_width_for(16, 289004, gib(8)) == 1)
    assert(codegen_units_emit_width_for(16, 289004, gib(16)) == 16)

    print("ok")
