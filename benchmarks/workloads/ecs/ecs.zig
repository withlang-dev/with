// ECS update: structure-of-arrays storage, bitmask queries, 1M entities.
// Timed region: 1000 ticks of movement, damage, and cleanup systems.
const std = @import("std");
// Printing goes through libc so the file compiles on every Zig std I/O revision.
const c = @cImport(@cInclude("stdio.h"));

// std.time.Timer was removed in Zig 0.16; read the monotonic clock directly.
fn nowNs() u64 {
    var ts: std.c.timespec = undefined;
    if (std.c.clock_gettime(.MONOTONIC, &ts) != 0) @panic("clock_gettime failed");
    return @as(u64, @intCast(ts.sec)) * std.time.ns_per_s + @as(u64, @intCast(ts.nsec));
}

const ENTITIES: usize = 1_000_000;
const TICKS: usize = 1000;
const HAS_POS: u8 = 1;
const HAS_VEL: u8 = 2;
const HAS_HP: u8 = 4;
const HAS_DMG: u8 = 8;

const Position = struct { x: f32 = 0, y: f32 = 0 };
const Velocity = struct { x: f32 = 0, y: f32 = 0 };
const Health = struct { hp: f32 = 0 };
const Damage = struct { dps: f32 = 0 };

const World = struct {
    mask: []u8,
    pos: []Position,
    vel: []Velocity,
    hp: []Health,
    dmg: []Damage,
    count: usize,

    fn init(allocator: std.mem.Allocator) !World {
        const w = World{
            .mask = try allocator.alloc(u8, ENTITIES),
            .pos = try allocator.alloc(Position, ENTITIES),
            .vel = try allocator.alloc(Velocity, ENTITIES),
            .hp = try allocator.alloc(Health, ENTITIES),
            .dmg = try allocator.alloc(Damage, ENTITIES),
            .count = 0,
        };
        @memset(w.mask, 0);
        return w;
    }

    fn create(self: *World) usize {
        const id = self.count;
        self.count += 1;
        return id;
    }

    fn systemMovement(self: *World, dt: f32) void {
        const need = HAS_POS | HAS_VEL;
        for (0..self.count) |i| {
            if (self.mask[i] & need == need) {
                self.pos[i].x += self.vel[i].x * dt;
                self.pos[i].y += self.vel[i].y * dt;
            }
        }
    }

    fn systemDamage(self: *World, dt: f32) void {
        const need = HAS_HP | HAS_DMG;
        for (0..self.count) |i| {
            if (self.mask[i] & need == need) self.hp[i].hp -= self.dmg[i].dps * dt;
        }
    }

    fn systemCleanup(self: *World) void {
        for (0..self.count) |i| {
            if (self.mask[i] & HAS_HP != 0 and self.hp[i].hp <= 0.0) self.mask[i] = 0;
        }
    }

    fn countAlive(self: *const World) usize {
        var n: usize = 0;
        for (0..self.count) |i| {
            if (self.mask[i] != 0) n += 1;
        }
        return n;
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var w = try World.init(allocator);
    // 70% move, 50% have health, 30% take damage.
    for (0..ENTITIES) |ii| {
        const id = w.create();
        const i: u32 = @intCast(ii);
        const fi: f32 = @floatFromInt(i);
        if (i % 10 < 7) {
            w.mask[id] |= HAS_POS;
            w.pos[id] = .{ .x = fi * 0.1, .y = fi * 0.2 };
            w.mask[id] |= HAS_VEL;
            w.vel[id] = .{ .x = @as(f32, @floatFromInt(i % 100)) * 0.01, .y = @as(f32, @floatFromInt((i + 50) % 100)) * 0.01 };
        }
        if (i % 10 < 5) {
            w.mask[id] |= HAS_HP;
            w.hp[id] = .{ .hp = 100.0 };
        }
        if (i % 10 < 3) {
            w.mask[id] |= HAS_DMG;
            w.dmg[id] = .{ .dps = 0.5 + @as(f32, @floatFromInt(i % 10)) * 0.1 };
        }
    }
    const alive_before = w.countAlive();

    const started = nowNs();
    const dt: f32 = 1.0 / 60.0;
    for (0..TICKS) |_| {
        w.systemMovement(dt);
        w.systemDamage(dt);
        w.systemCleanup();
    }
    const elapsed_ms = @as(f64, @floatFromInt(nowNs() - started)) / 1_000_000.0;

    var sum: f64 = 0.0;
    for (0..w.count) |i| {
        if (w.mask[i] & HAS_POS != 0) sum += @as(f64, w.pos[i].x);
    }
    _ = c.printf("entities %zu alive_before %zu alive_after %zu\n", w.count, alive_before, w.countAlive());
    _ = c.printf("elapsed_ms %.3f\n", elapsed_ms);
    _ = c.printf("checksum %.2f\n", sum);
}
