//! Phase-0 project scaffold validation utilities.

const std = @import("std");

pub const ModuleSpec = struct {
    logical_name: []const u8,
    file_path: []const u8,
};

pub const required_logical_modules = [_][]const u8{
    "ast",
    "types",
    "parse",
    "check",
    "mir",
    "codegen",
    "driver",
    "diag",
};

pub const canonical_modules = [_]ModuleSpec{
    .{ .logical_name = "ast", .file_path = "src/Ast.zig" },
    .{ .logical_name = "types", .file_path = "src/Types.zig" },
    .{ .logical_name = "parse", .file_path = "src/Parse.zig" },
    .{ .logical_name = "check", .file_path = "src/Check.zig" },
    .{ .logical_name = "mir", .file_path = "src/Mir.zig" },
    .{ .logical_name = "codegen", .file_path = "src/Codegen.zig" },
    .{ .logical_name = "driver", .file_path = "src/Driver.zig" },
    .{ .logical_name = "diag", .file_path = "src/Diag.zig" },
};

pub const ValidateError = error{
    MissingRequiredModule,
    DuplicateRequiredModule,
    MissingFile,
};

pub fn validateProjectScaffold(specs: []const ModuleSpec) ValidateError!void {
    for (required_logical_modules) |required_name| {
        var count: usize = 0;
        for (specs) |spec| {
            if (std.mem.eql(u8, spec.logical_name, required_name)) {
                count += 1;
            }
        }
        if (count == 0) return error.MissingRequiredModule;
        if (count > 1) return error.DuplicateRequiredModule;
    }

    for (specs) |spec| {
        std.fs.cwd().access(spec.file_path, .{}) catch {
            return error.MissingFile;
        };
    }
}

test "canonical phase0 scaffold validates" {
    try validateProjectScaffold(canonical_modules[0..]);
}

test "scaffold validation rejects missing required module" {
    const missing_mir = [_]ModuleSpec{
        canonical_modules[0],
        canonical_modules[1],
        canonical_modules[2],
        canonical_modules[3],
        canonical_modules[5],
        canonical_modules[6],
        canonical_modules[7],
    };

    try std.testing.expectError(
        error.MissingRequiredModule,
        validateProjectScaffold(missing_mir[0..]),
    );
}

test "scaffold validation rejects duplicate logical module" {
    var specs = canonical_modules;
    specs[7] = .{ .logical_name = "ast", .file_path = "src/Ast.zig" };

    try std.testing.expectError(
        error.DuplicateRequiredModule,
        validateProjectScaffold(specs[0..]),
    );
}

test "scaffold validation rejects missing module file" {
    var specs = canonical_modules;
    specs[4] = .{ .logical_name = "mir", .file_path = "src/__missing_mir__.zig" };

    try std.testing.expectError(
        error.MissingFile,
        validateProjectScaffold(specs[0..]),
    );
}

