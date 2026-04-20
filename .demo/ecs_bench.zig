// ecs_bench.zig — ECS benchmark: SoA storage, bitset queries, 1M entities
// No external packages. Idiomatic Zig.

const std = @import("std");
const print = std.debug.print;

const MAX_ENTITIES: usize = 1_048_576;

const Position = struct { x: f32 = 0, y: f32 = 0 };
const Velocity = struct { x: f32 = 0, y: f32 = 0 };
const Health = struct { hp: f32 = 0 };
const Damage = struct { dps: f32 = 0 };

const HAS_POS: u8 = 1;
const HAS_VEL: u8 = 2;
const HAS_HP: u8 = 4;
const HAS_DMG: u8 = 8;

fn nowNs() u64 {
    if (@hasDecl(std.time, "nanoTimestamp")) {
        return @intCast(std.time.nanoTimestamp());
    }

    var ts: std.c.timespec = undefined;
    if (std.c.clock_gettime(.MONOTONIC, &ts) != 0) {
        @panic("clock_gettime failed");
    }
    return @as(u64, @intCast(ts.sec)) * std.time.ns_per_s + @as(u64, @intCast(ts.nsec));
}

const World = struct {
    mask: []u8,
    pos: []Position,
    vel: []Velocity,
    hp: []Health,
    dmg: []Damage,
    count: usize,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) !World {
        return World{
            .mask = try allocator.alloc(u8, MAX_ENTITIES),
            .pos = try allocator.alloc(Position, MAX_ENTITIES),
            .vel = try allocator.alloc(Velocity, MAX_ENTITIES),
            .hp = try allocator.alloc(Health, MAX_ENTITIES),
            .dmg = try allocator.alloc(Damage, MAX_ENTITIES),
            .count = 0,
            .allocator = allocator,
        };
    }

    fn deinit(self: *World) void {
        self.allocator.free(self.mask);
        self.allocator.free(self.pos);
        self.allocator.free(self.vel);
        self.allocator.free(self.hp);
        self.allocator.free(self.dmg);
    }

    fn spawn(self: *World) usize {
        const id = self.count;
        self.mask[id] = 0;
        self.count += 1;
        return id;
    }

    fn addPos(self: *World, id: usize, p: Position) void {
        self.mask[id] |= HAS_POS;
        self.pos[id] = p;
    }

    fn addVel(self: *World, id: usize, v: Velocity) void {
        self.mask[id] |= HAS_VEL;
        self.vel[id] = v;
    }

    fn addHealth(self: *World, id: usize, h: Health) void {
        self.mask[id] |= HAS_HP;
        self.hp[id] = h;
    }

    fn addDamage(self: *World, id: usize, d: Damage) void {
        self.mask[id] |= HAS_DMG;
        self.dmg[id] = d;
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
            if (self.mask[i] & need == need) {
                self.hp[i].hp -= self.dmg[i].dps * dt;
            }
        }
    }

    fn systemCleanup(self: *World) void {
        for (0..self.count) |i| {
            if (self.mask[i] & HAS_HP != 0 and self.hp[i].hp <= 0.0) {
                self.mask[i] = 0;
            }
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

    var world = try World.init(allocator);
    defer world.deinit();

    for (0..1_000_000) |ii| {
        const id = world.spawn();
        const i: u32 = @intCast(ii);
        const fi: f32 = @floatFromInt(i);

        if (i % 10 < 7) {
            world.addPos(id, .{ .x = fi * 0.1, .y = fi * 0.2 });
            world.addVel(id, .{ .x = @mod(fi, 100.0) * 0.01, .y = @mod(fi + 50.0, 100.0) * 0.01 });
        }
        if (i % 10 < 5) {
            world.addHealth(id, .{ .hp = 100.0 });
        }
        if (i % 10 < 3) {
            world.addDamage(id, .{ .dps = 0.5 + @mod(fi, 10.0) * 0.1 });
        }
    }

    print("Entities: {d}\n", .{world.count});
    print("Alive: {d}\n", .{world.countAlive()});

    const start = nowNs();

    const dt: f32 = 1.0 / 60.0;
    for (0..1000) |_| {
        world.systemMovement(dt);
        world.systemDamage(dt);
        world.systemCleanup();
    }

    const elapsed = nowNs() - start;
    const secs = @as(f64, @floatFromInt(elapsed)) / 1_000_000_000.0;
    print("1000 ticks: {d:.3}s\n", .{secs});
    print("Alive after: {d}\n", .{world.countAlive()});

    var sum: f64 = 0.0;
    for (0..world.count) |i| {
        if (world.mask[i] & HAS_POS != 0) {
            sum += @as(f64, world.pos[i].x);
        }
    }
    print("Checksum: {d:.2}\n", .{sum});
}
