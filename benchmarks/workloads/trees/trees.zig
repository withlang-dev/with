// Binary trees: allocation-heavy recursive tree build and check, depth 18.
// Timed region: everything. Checksum: sum of all node counts.
// Uses the C allocator so the comparison is malloc against malloc.
const std = @import("std");

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
    const left: i64 = if (node.left) |c| check(c) else 0;
    const right: i64 = if (node.right) |c| check(c) else 0;
    return 1 + left + right;
}

fn release(allocator: std.mem.Allocator, node: *Node) void {
    if (node.left) |c| release(allocator, c);
    if (node.right) |c| release(allocator, c);
    allocator.destroy(node);
}

pub fn main() !void {
    const allocator = std.heap.c_allocator;
    var timer = try std.time.Timer.start();
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
    const elapsed_ms = @as(f64, @floatFromInt(timer.read())) / 1_000_000.0;
    var out = std.fs.File.stdout().writer(&.{});
    try out.interface.print("max_depth {d}\n", .{MAX_DEPTH});
    try out.interface.print("elapsed_ms {d:.3}\n", .{elapsed_ms});
    try out.interface.print("checksum {d}\n", .{total});
    try out.interface.flush();
}
