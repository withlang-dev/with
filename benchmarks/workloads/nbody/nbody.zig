// N-body: five-body gravitational integration in f64, 50M steps.
// Timed region: the integration loop. Checksum: final system energy.
const std = @import("std");
// Printing goes through libc so the file compiles on every Zig std I/O revision.
const c = @cImport(@cInclude("stdio.h"));

// std.time.Timer was removed in Zig 0.16; read the monotonic clock directly.
fn nowNs() u64 {
    var ts: std.c.timespec = undefined;
    if (std.c.clock_gettime(.MONOTONIC, &ts) != 0) @panic("clock_gettime failed");
    return @as(u64, @intCast(ts.sec)) * std.time.ns_per_s + @as(u64, @intCast(ts.nsec));
}

const STEPS: usize = 50_000_000;
const PI: f64 = 3.141592653589793;
const SOLAR_MASS: f64 = 4.0 * PI * PI;
const DAYS_PER_YEAR: f64 = 365.24;

const Body = struct { x: f64, y: f64, z: f64, vx: f64, vy: f64, vz: f64, mass: f64 };

var bodies = [_]Body{
    .{ .x = 0, .y = 0, .z = 0, .vx = 0, .vy = 0, .vz = 0, .mass = SOLAR_MASS },
    .{
        .x = 4.84143144246472090e+00, .y = -1.16032004402742839e+00, .z = -1.03622044471123109e-01,
        .vx = 1.66007664274403694e-03 * DAYS_PER_YEAR, .vy = 7.69901118419740425e-03 * DAYS_PER_YEAR,
        .vz = -6.90460016972063023e-05 * DAYS_PER_YEAR, .mass = 9.54791938424326609e-04 * SOLAR_MASS,
    },
    .{
        .x = 8.34336671824457987e+00, .y = 4.12479856412430479e+00, .z = -4.03523417114321381e-01,
        .vx = -2.76742510726862411e-03 * DAYS_PER_YEAR, .vy = 4.99852801234917238e-03 * DAYS_PER_YEAR,
        .vz = 2.30417297573763929e-05 * DAYS_PER_YEAR, .mass = 2.85885980666130812e-04 * SOLAR_MASS,
    },
    .{
        .x = 1.28943695621391310e+01, .y = -1.51111514016986312e+01, .z = -2.23307578892655734e-01,
        .vx = 2.96460137564761618e-03 * DAYS_PER_YEAR, .vy = 2.37847173959480950e-03 * DAYS_PER_YEAR,
        .vz = -2.96589568540237556e-05 * DAYS_PER_YEAR, .mass = 4.36624404335156298e-05 * SOLAR_MASS,
    },
    .{
        .x = 1.53796971148509165e+01, .y = -2.59193146099879641e+01, .z = 1.79258772950371181e-01,
        .vx = 2.68067772490389322e-03 * DAYS_PER_YEAR, .vy = 1.62824170038242295e-03 * DAYS_PER_YEAR,
        .vz = -9.51592254519715870e-05 * DAYS_PER_YEAR, .mass = 5.15138902046611451e-05 * SOLAR_MASS,
    },
};

fn offsetMomentum() void {
    var px: f64 = 0;
    var py: f64 = 0;
    var pz: f64 = 0;
    for (bodies) |b| {
        px += b.vx * b.mass;
        py += b.vy * b.mass;
        pz += b.vz * b.mass;
    }
    bodies[0].vx = -px / SOLAR_MASS;
    bodies[0].vy = -py / SOLAR_MASS;
    bodies[0].vz = -pz / SOLAR_MASS;
}

fn energy() f64 {
    var e: f64 = 0;
    for (bodies, 0..) |b, i| {
        e += 0.5 * b.mass * (b.vx * b.vx + b.vy * b.vy + b.vz * b.vz);
        for (bodies[i + 1 ..]) |o| {
            const dx = b.x - o.x;
            const dy = b.y - o.y;
            const dz = b.z - o.z;
            e -= b.mass * o.mass / @sqrt(dx * dx + dy * dy + dz * dz);
        }
    }
    return e;
}

fn advance(dt: f64) void {
    const n = bodies.len;
    for (0..n) |i| {
        for (i + 1..n) |j| {
            const dx = bodies[i].x - bodies[j].x;
            const dy = bodies[i].y - bodies[j].y;
            const dz = bodies[i].z - bodies[j].z;
            const distance2 = dx * dx + dy * dy + dz * dz;
            const mag = dt / (distance2 * @sqrt(distance2));
            const mi = bodies[i].mass * mag;
            const mj = bodies[j].mass * mag;
            bodies[i].vx -= dx * mj;
            bodies[i].vy -= dy * mj;
            bodies[i].vz -= dz * mj;
            bodies[j].vx += dx * mi;
            bodies[j].vy += dy * mi;
            bodies[j].vz += dz * mi;
        }
    }
    for (&bodies) |*b| {
        b.x += dt * b.vx;
        b.y += dt * b.vy;
        b.z += dt * b.vz;
    }
}

pub fn main() !void {
    offsetMomentum();
    const before = energy();
    const started = nowNs();
    for (0..STEPS) |_| advance(0.01);
    const elapsed_ms = @as(f64, @floatFromInt(nowNs() - started)) / 1_000_000.0;
    _ = c.printf("energy_before %.9f\n", before);
    _ = c.printf("elapsed_ms %.3f\n", elapsed_ms);
    _ = c.printf("checksum %.9f\n", energy());
}
