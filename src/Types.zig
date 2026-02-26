//! Phase-0 `types` facade.
//!
//! The implementation currently lives in `Sema.zig`; this facade provides
//! a stable module boundary that matches the phase plan terminology.

const std = @import("std");
const Sema = @import("Sema.zig");

pub const TypeId = Sema.TypeId;
pub const Type = Sema.Type;
pub const IntType = Sema.IntType;
pub const FloatType = Sema.FloatType;
pub const StructType = Sema.StructType;
pub const EnumType = Sema.EnumType;
pub const PtrType = Sema.PtrType;
pub const RefType = Sema.RefType;
pub const error_type = Sema.error_type;

pub const Context = Sema;

test "types facade exports core type symbols" {
    try std.testing.expect(@hasDecl(@This(), "TypeId"));
    try std.testing.expect(@hasDecl(@This(), "Type"));
    try std.testing.expect(@hasDecl(@This(), "error_type"));
}

