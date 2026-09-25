// Grow: push-built vectors inside a struct, 800 rounds of 100k rows each.
// Timed region: everything. Checksum: wrapping fold over the rows.
const std = @import("std");
const c = @cImport(@cInclude("stdio.h"));

const ROUNDS: i64 = 800;
const ROWS: i64 = 100_000;

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

const Table = struct {
    xs: std.ArrayList(i64) = .empty,
    ys: std.ArrayList(i64) = .empty,
    ids: std.ArrayList(i64) = .empty,

    fn pushRow(self: *Table, allocator: std.mem.Allocator, r: u64, id: i64) !void {
        try self.xs.append(allocator, @intCast(r % 1000));
        try self.ys.append(allocator, @intCast((r >> 10) % 1000));
        try self.ids.append(allocator, id);
    }

    fn fold(self: *const Table) i64 {
        var total: i64 = 0;
        for (self.ids.items, 0..) |id, i| total +%= self.xs.items[i] * 3 + self.ys.items[i] * 7 + id;
        return total;
    }

    fn deinit(self: *Table, allocator: std.mem.Allocator) void {
        self.xs.deinit(allocator);
        self.ys.deinit(allocator);
        self.ids.deinit(allocator);
    }
};

pub fn main() !void {
    const allocator = std.heap.c_allocator;
    const started = nowNs();
    var rng: u64 = 2463534242;
    var checksum: i64 = 0;
    var round: i64 = 0;
    while (round < ROUNDS) : (round += 1) {
        var table = Table{};
        defer table.deinit(allocator);
        var i: i64 = 0;
        while (i < ROWS) : (i += 1) {
            rng = next(rng);
            try table.pushRow(allocator, rng, round * ROWS + i);
        }
        checksum +%= table.fold();
    }
    const elapsed_ms = @as(f64, @floatFromInt(nowNs() - started)) / 1_000_000.0;
    _ = c.printf("rounds %lld rows %lld\n", ROUNDS, ROWS);
    _ = c.printf("elapsed_ms %.3f\n", elapsed_ms);
    _ = c.printf("checksum %lld\n", checksum);
}
