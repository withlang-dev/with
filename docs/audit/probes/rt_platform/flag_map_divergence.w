// Probe: linux __open (rt/linux_x86_64.w:151-162) vs rt_open (:184-199) flag mapping.
// Snapshot 450733e5. Pure-logic mirror — no libc calls. Run via seed:
//   out/bootstrap/bin/with-stage1 run .audit/probes/rt_platform/flag_map_divergence.w

fn legacy_open_map(flags: i32) -> i32:
    var native = flags & 3
    if (flags & 0x0008) != 0: native = native | 0x400
    if (flags & 0x0200) != 0: native = native | 0x40
    if (flags & 0x0400) != 0: native = native | 0x200
    if (flags & 0x0800) != 0: native = native | 0x80
    native

fn rt_open_map(flags: i32) -> i32:
    var native = flags & 3
    if (flags & 0x200) != 0: native = native | 0x40
    if (flags & 0x400) != 0: native = native | 0x200
    if (flags & 0x800) != 0: native = native | 0x400
    native

// Canonical O_CREAT|O_WRONLY path agrees on both.
print(f"canon WRONLY|CREAT legacy={legacy_open_map(1 | 0x200)} rt_open={rt_open_map(1 | 0x200)}")
assert(legacy_open_map(1 | 0x200) == rt_open_map(1 | 0x200))
// 0x8 (Darwin O_APPEND residue): legacy maps to Linux O_APPEND, rt_open drops it.
print(f"flags=0x8 legacy={legacy_open_map(0x8)} rt_open={rt_open_map(0x8)}")
assert(legacy_open_map(0x8) == 0x400)
assert(rt_open_map(0x8) == 0)
// Canonical O_APPEND (0x800): legacy yields O_EXCL (0x80), rt_open yields O_APPEND (0x400).
print(f"flags=APPEND legacy={legacy_open_map(1 | 0x800)} rt_open={rt_open_map(1 | 0x800)}")
assert(legacy_open_map(1 | 0x800) == (1 | 0x80))
assert(rt_open_map(1 | 0x800) == (1 | 0x400))
print("divergence confirmed: __open disagrees with rt_open on 0x8 and 0x800")
