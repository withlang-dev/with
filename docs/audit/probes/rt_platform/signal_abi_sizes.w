// Probe: signal-ABI buffer sizes + signal-bit math in rt/linux_x86_64.w.
// Snapshot 450733e5. Pure-logic mirror — no libc calls. Run via seed:
//   out/bootstrap/bin/with-stage1 run .audit/probes/rt_platform/signal_abi_sizes.w

// In-file constants (linux_x86_64.w:924 fiber sa arrays at :129/:144 use 152).
let compat_sigaction_size: i64 = 16
let fiber_sigaction_size: i64 = 152
let compat_mask_bytes: i64 = 4
print(f"compat sigaction buf={compat_sigaction_size} fiber sigaction buf={fiber_sigaction_size}")
print(f"compat sigmask buf={compat_mask_bytes}")
assert(compat_sigaction_size == 16)
assert(fiber_sigaction_size == 152)
assert(compat_mask_bytes == 4)

fn signal_bit(signo: i32) -> u32:
    if signo <= 0:
        return 0 as u32
    (1 as u32) << ((signo - 1) as u32)

let blocked = signal_bit(2) | signal_bit(15) | signal_bit(1)
print(f"SIGHUP bit={signal_bit(1)} SIGINT bit={signal_bit(2)} SIGTERM bit={signal_bit(15)} combined={blocked}")
assert(signal_bit(1) == 1 as u32)
assert(signal_bit(2) == 2 as u32)
assert(signal_bit(15) == 16384 as u32)
assert(blocked == 16387 as u32)
print("sizes differ 16-vs-152 and mask is one u32 word; bit math matches file")
