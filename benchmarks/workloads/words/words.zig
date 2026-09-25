// Words: string building, hashing, and map lookup over 30M generated words.
// Timed region: everything. Checksum: order-independent FNV mix of the counts
// folded with an FNV of a 1000-line report built from lookups.
const std = @import("std");
const c = @cImport(@cInclude("stdio.h"));

const WORDS: usize = 30_000_000;
const VOCAB: u64 = 60_000;
const HOT: u64 = 600;

fn nowNs() u64 {
    var ts: std.c.timespec = undefined;
    if (std.c.clock_gettime(.MONOTONIC, &ts) != 0) @panic("clock_gettime failed");
    return @as(u64, @intCast(ts.sec)) * std.time.ns_per_s + @as(u64, @intCast(ts.nsec));
}

fn next(state: u64) u64 {
    var x = state;
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    return x;
}

fn spell(id: u64, out: []u8) []u8 {
    var v = id + 676;
    var n: usize = 0;
    while (v > 0) : (v /= 26) {
        out[n] = @intCast('a' + v % 26);
        n += 1;
    }
    return out[0..n];
}

fn fnv(s: []const u8) u64 {
    var h: u64 = 14695981039346656037;
    for (s) |b| h = (h ^ b) *% 1099511628211;
    return h;
}

pub fn main() !void {
    const allocator = std.heap.c_allocator;
    const started = nowNs();
    var rng: u64 = 88172645463325252;
    var counts = std.StringHashMap(i32).init(allocator);
    defer counts.deinit();
    var buf: [32]u8 = undefined;
    for (0..WORDS) |_| {
        rng = next(rng);
        const id = if (rng % 10 < 3) (rng >> 8) % HOT else (rng >> 8) % VOCAB;
        const word = spell(id, &buf);
        if (counts.getPtr(word)) |slot| {
            slot.* += 1;
        } else {
            try counts.put(try allocator.dupe(u8, word), 1);
        }
    }
    var mix: u64 = 0;
    var it = counts.iterator();
    while (it.next()) |entry| mix +%= @as(u64, @intCast(entry.value_ptr.*)) *% fnv(entry.key_ptr.*);
    var report: std.ArrayList(u8) = .empty;
    defer report.deinit(allocator);
    for (0..1000) |id| {
        const word = spell(@intCast(id), &buf);
        const count = counts.get(word) orelse 0;
        try report.appendSlice(allocator, word);
        try report.append(allocator, ':');
        var digits: [16]u8 = undefined;
        const text = try std.fmt.bufPrint(&digits, "{d}", .{count});
        try report.appendSlice(allocator, text);
        try report.append(allocator, '\n');
    }
    const checksum = mix ^ fnv(report.items);
    const elapsed_ms = @as(f64, @floatFromInt(nowNs() - started)) / 1_000_000.0;
    _ = c.printf("distinct %zu report_bytes %zu\n", counts.count(), report.items.len);
    _ = c.printf("elapsed_ms %.3f\n", elapsed_ms);
    _ = c.printf("checksum %llu\n", checksum);
    var key_it = counts.keyIterator();
    while (key_it.next()) |key| allocator.free(key.*);
}
