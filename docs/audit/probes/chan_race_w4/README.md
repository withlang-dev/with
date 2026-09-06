# CHAN-001 reproducer
# main.w: 1 producer fiber sends 0..19999, 1 consumer fiber sums.
# Expected sum: 199990000.
# with.toml.w4 (fiber_worker_count=4): 167327233, 165637018, 178204976 (3 runs, all wrong).
# with.toml.w1 (fiber_worker_count=1): 199990000, 199990000 (exact).
# Copy one with.toml.w{N} to with.toml, `with build -O1 -o chantest main.w`, run.
