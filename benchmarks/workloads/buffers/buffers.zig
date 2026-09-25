// Buffers: chunked-I/O shaped churn of 8 to 64 KiB blocks, 32 live at once.
// Timed region: everything. Checksum: wrapping sum of the words written.
const std = @import("std");
const c = @cImport(@cInclude("stdio.h"));

const ITERATIONS: usize = 2_000_000;
const RING: usize = 32;

fn nowNs() u64 {
    var ts: std.c.timespec = undefined;
    if (std.c.clock_gettime(.MONOTONIC, &ts) != 0) @panic("clock_gettime failed");
    return @as(u64, @intCast(ts.sec)) * std.time.ns_per_s + @as(u64, @intCast(ts.nsec));
}

pub fn main() !void {
    const allocator = std.heap.c_allocator;
    const started = nowNs();
    var ring: [RING]?[]u64 = .{null} ** RING;
    var checksum: u64 = 0;
    for (0..ITERATIONS) |i| {
        const words = 1024 * (1 + (i % 8));
        const block = try allocator.alloc(u64, words);
        for (0..words / 64) |j| {
            const value = @as(u64, @intCast(i)) *% 2654435761 +% @as(u64, @intCast(j));
            block[j] = value;
            checksum +%= value;
        }
        if (ring[i % RING]) |old| allocator.free(old);
        ring[i % RING] = block;
    }
    for (ring) |slot| if (slot) |old| allocator.free(old);
    const elapsed_ms = @as(f64, @floatFromInt(nowNs() - started)) / 1_000_000.0;
    _ = c.printf("iterations %zu ring %zu\n", ITERATIONS, RING);
    _ = c.printf("elapsed_ms %.3f\n", elapsed_ms);
    _ = c.printf("checksum %llu\n", checksum);
}
