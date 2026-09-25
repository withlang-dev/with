// Binary trees: allocation-heavy recursive tree build and check, depth 18.
// Timed region: everything. Checksum: sum of all node counts.
// Uses the C allocator so the comparison is malloc against malloc.
const std = @import("std");
// Printing goes through libc so the file compiles on every Zig std I/O revision.
const c = @cImport(@cInclude("stdio.h"));

// std.time.Timer was removed in Zig 0.16; read the monotonic clock directly.
fn nowNs() u64 {
    var ts: std.c.timespec = undefined;
    if (std.c.clock_gettime(.MONOTONIC, &ts) != 0) @panic("clock_gettime failed");
    return @as(u64, @intCast(ts.sec)) * std.time.ns_per_s + @as(u64, @intCast(ts.nsec));
}

const MIN_DEPTH: u5 = 4;
const MAX_DEPTH: u5 = 18;

const Node = struct { left: ?*Node, right: ?*Node };

fn bottomUp(allocator: std.mem.Allocator, depth: u32) !*Node {
    const node = try allocator.create(Node);
    if (depth == 0) {
        node.* = .{ .left = null, .right = null };
    } else {
        node.* = .{ .left = try bottomUp(allocator, depth - 1), .right = try bottomUp(allocator, depth - 1) };
    }
    return node;
}

fn check(node: *const Node) i64 {
    const left: i64 = if (node.left) |child| check(child) else 0;
    const right: i64 = if (node.right) |child| check(child) else 0;
    return 1 + left + right;
}

fn release(allocator: std.mem.Allocator, node: *Node) void {
    if (node.left) |child| release(allocator, child);
    if (node.right) |child| release(allocator, child);
    allocator.destroy(node);
}

pub fn main() !void {
    const allocator = std.heap.c_allocator;
    const started = nowNs();
    var total: i64 = 0;
    const stretch = try bottomUp(allocator, MAX_DEPTH + 1);
    total += check(stretch);
    release(allocator, stretch);
    const long_lived = try bottomUp(allocator, MAX_DEPTH);
    var depth: u32 = MIN_DEPTH;
    while (depth <= MAX_DEPTH) : (depth += 2) {
        const iterations = @as(u32, 1) << @intCast(MAX_DEPTH - depth + MIN_DEPTH);
        for (0..iterations) |_| {
            const tree = try bottomUp(allocator, depth);
            total += check(tree);
            release(allocator, tree);
        }
    }
    total += check(long_lived);
    release(allocator, long_lived);
    const elapsed_ms = @as(f64, @floatFromInt(nowNs() - started)) / 1_000_000.0;
    _ = c.printf("max_depth %d\n", @as(c_int, MAX_DEPTH));
    _ = c.printf("elapsed_ms %.3f\n", elapsed_ms);
    _ = c.printf("checksum %lld\n", total);
}
