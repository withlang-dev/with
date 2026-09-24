use std.build

// The C in vendor/ is compiled by the compiler that compiles the With: there
// is no Makefile and no C toolchain to install.
comptime with BuildCtx as ctx:
pub fn build -> Build:
    var out = ctx.new_build().compile_c_object("tally-object", "vendor/tally.c", "out/lib/tally.o")
    out = out.add_target(target_new(.CreateStaticArchive, "tally", "").output("out/lib/libtally.a").input("out/lib/tally.o").dep("tally-object"))
    out = out.add_target(target_new(.Executable, "c-interop", "src/main.w").include_path("vendor").link_system_lib("tally").dep("tally"))
    out = out.test("test", "test/*.w")
    out.default("c-interop")
