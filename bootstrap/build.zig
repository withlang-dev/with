const std = @import("std");

/// LLVM static libraries (from: llvm-config --libs core analysis native).
/// Using inline for so the names stay comptime for string concatenation.
const llvm_lib_flags = [_][]const u8{
    // Generated from: llvm-config --link-static --libs core analysis native
    //                 asmprinter asmparser codegen target ipo instrumentation
    //                 vectorize linker irreader bitwriter bitreader passes
    //                 irprinter mc mcparser object support demangle
    "-lLLVMPasses",
    "-lLLVMIRPrinter",
    "-lLLVMHipStdPar",
    "-lLLVMCoroutines",
    "-lLLVMipo",
    "-lLLVMInstrumentation",
    "-lLLVMLinker",
    "-lLLVMFrontendOpenMP",
    "-lLLVMFrontendAtomic",
    "-lLLVMFrontendOffloading",
    "-lLLVMAArch64Disassembler",
    "-lLLVMMCDisassembler",
    "-lLLVMAArch64AsmParser",
    "-lLLVMAArch64CodeGen",
    "-lLLVMVectorize",
    "-lLLVMSandboxIR",
    "-lLLVMGlobalISel",
    "-lLLVMSelectionDAG",
    "-lLLVMCFGuard",
    "-lLLVMAsmPrinter",
    "-lLLVMCodeGen",
    "-lLLVMTarget",
    "-lLLVMScalarOpts",
    "-lLLVMInstCombine",
    "-lLLVMAggressiveInstCombine",
    "-lLLVMObjCARCOpts",
    "-lLLVMTransformUtils",
    "-lLLVMCGData",
    "-lLLVMBitWriter",
    "-lLLVMAArch64Desc",
    "-lLLVMCodeGenTypes",
    "-lLLVMAArch64Utils",
    "-lLLVMAArch64Info",
    "-lLLVMAnalysis",
    "-lLLVMProfileData",
    "-lLLVMSymbolize",
    "-lLLVMDebugInfoBTF",
    "-lLLVMDebugInfoPDB",
    "-lLLVMDebugInfoMSF",
    "-lLLVMDebugInfoCodeView",
    "-lLLVMDebugInfoDWARF",
    "-lLLVMObject",
    "-lLLVMTextAPI",
    "-lLLVMMCParser",
    "-lLLVMIRReader",
    "-lLLVMAsmParser",
    "-lLLVMMC",
    "-lLLVMBitReader",
    "-lLLVMCore",
    "-lLLVMRemarks",
    "-lLLVMBitstreamReader",
    "-lLLVMBinaryFormat",
    "-lLLVMTargetParser",
    "-lLLVMSupport",
    "-lLLVMDemangle",
};

fn defaultLlvmPrefix() []const u8 {
    const candidates = [_]struct {
        prefix: []const u8,
        dylib: []const u8,
    }{
        .{
            .prefix = "/opt/homebrew/opt/llvm",
            .dylib = "/opt/homebrew/opt/llvm/lib/libLLVM.dylib",
        },
        .{
            .prefix = "/usr/local/opt/llvm",
            .dylib = "/usr/local/opt/llvm/lib/libLLVM.dylib",
        },
        .{
            .prefix = "/usr/local/llvm",
            .dylib = "/usr/local/llvm/lib/libLLVM.dylib",
        },
    };
    for (candidates) |prefix| {
        if (std.fs.accessAbsolute(prefix.dylib, .{})) |_| {
            return prefix.prefix;
        } else |_| {}
    }
    return "/usr/local/llvm";
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const llvm_prefix = b.graph.env_map.get("LLVM_PREFIX") orelse defaultLlvmPrefix();
    const llvm_include = b.pathJoin(&.{ llvm_prefix, "include" });
    const llvm_lib = b.pathJoin(&.{ llvm_prefix, "lib" });
    const clangxx = b.pathJoin(&.{ llvm_prefix, "bin", "clang++" });
    const sdk_path = "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk";

    // --- Compile Zig source to object file ---
    const obj = b.addObject(.{
        .name = "with",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    obj.root_module.addSystemIncludePath(.{ .cwd_relative = llvm_include });
    obj.linkLibC();

    // --- Link with LLVM's clang (archives contain LTO bitcode) ---
    const link_cmd = b.addSystemCommand(&.{clangxx});
    link_cmd.addArtifactArg(obj);
    link_cmd.addArgs(&.{
        b.fmt("-L{s}", .{llvm_lib}),
        "-isysroot",
        sdk_path,
    });
    link_cmd.addArgs(&llvm_lib_flags);
    link_cmd.addArgs(&.{
        b.fmt("-Wl,-rpath,{s}", .{llvm_lib}),
        "-L/opt/homebrew/lib",
        "-lclang",
        "-lc++",
        "-lc++abi",
        "-lz",
        "-lzstd",
        "-lxml2",
    });
    link_cmd.addArgs(&.{"-o"});
    const output = link_cmd.addOutputFileArg("with");

    // --- Build fiber runtime ---
    const fiber_c = b.addSystemCommand(&.{
        "cc",
        "-isysroot",
        sdk_path,
        "-c",
    });
    fiber_c.addFileArg(b.path("../runtime/fiber.c"));
    fiber_c.addArg("-o");
    const fiber_c_out = fiber_c.addOutputFileArg("fiber.o");

    const fiber_asm = b.addSystemCommand(&.{
        "cc",
        "-isysroot",
        sdk_path,
        "-c",
    });
    fiber_asm.addFileArg(b.path("../runtime/fiber_asm_aarch64.s"));
    fiber_asm.addArg("-o");
    const fiber_asm_out = fiber_asm.addOutputFileArg("fiber_asm.o");

    // Compile runtime helpers.
    const helpers_c = b.addSystemCommand(&.{
        "cc",
        "-isysroot",
        sdk_path,
        "-c",
    });
    helpers_c.addFileArg(b.path("../runtime/helpers.c"));
    helpers_c.addArg("-o");
    const helpers_c_out = helpers_c.addOutputFileArg("helpers.o");

    // Compile LLVM bridge object.
    const bridge_c = b.addSystemCommand(&.{
        "cc",
        "-isysroot",
        sdk_path,
        b.fmt("-I{s}", .{llvm_include}),
        "-c",
    });
    bridge_c.addFileArg(b.path("../runtime/llvm_bridge.c"));
    bridge_c.addArg("-o");
    const bridge_c_out = bridge_c.addOutputFileArg("llvm_bridge.o");

    // Link the LLVM bridge as a thin dynamic wrapper around libLLVM.dylib.
    // Using the static archive set here produces a very large dylib and can
    // leave libc++ as an unresolved @rpath dependency at launch time, which
    // causes detached selfhost stages to stall in dyld before main().
    const bridge_link = b.addSystemCommand(&.{"cc"});
    bridge_link.addFileArg(bridge_c_out);
    bridge_link.addArgs(&.{
        "-dynamiclib",
        b.fmt("-L{s}", .{llvm_lib}),
        "-isysroot",
        sdk_path,
        "-Wl,-install_name,@executable_path/runtime/libwith_llvm_bridge.dylib",
        b.fmt("-Wl,-rpath,{s}", .{llvm_lib}),
        "-lLLVM",
    });
    bridge_link.addArgs(&.{"-o"});
    const bridge_dylib_out = bridge_link.addOutputFileArg("libwith_llvm_bridge.dylib");

    // --- Install ---
    const install = b.addInstallBinFile(output, "with");
    b.getInstallStep().dependOn(&install.step);

    // Install runtime objects alongside the compiler.
    const install_fiber_c = b.addInstallBinFile(fiber_c_out, "runtime/fiber.o");
    const install_fiber_asm = b.addInstallBinFile(fiber_asm_out, "runtime/fiber_asm.o");
    const install_helpers = b.addInstallBinFile(helpers_c_out, "runtime/helpers.o");
    const install_bridge_obj = b.addInstallBinFile(bridge_c_out, "runtime/llvm_bridge.o");
    const install_bridge_dylib = b.addInstallBinFile(bridge_dylib_out, "runtime/libwith_llvm_bridge.dylib");
    b.getInstallStep().dependOn(&install_fiber_c.step);
    b.getInstallStep().dependOn(&install_fiber_asm.step);
    b.getInstallStep().dependOn(&install_helpers.step);
    b.getInstallStep().dependOn(&install_bridge_obj.step);
    b.getInstallStep().dependOn(&install_bridge_dylib.step);

    // --- Run step (`zig build run -- <args>`) ---
    const run_step = b.step("run", "Run the With compiler");
    const run_installed = b.addSystemCommand(&.{"./zig-out/bin/with"});
    if (b.args) |args| {
        run_installed.addArgs(args);
    }
    run_installed.step.dependOn(&install.step);
    run_step.dependOn(&run_installed.step);

    // --- Unit tests ---
    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    unit_tests.root_module.addSystemIncludePath(.{ .cwd_relative = llvm_include });
    unit_tests.linkLibC();
    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
