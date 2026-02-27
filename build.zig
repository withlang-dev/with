const std = @import("std");

/// LLVM static libraries (from: llvm-config --libs core analysis native).
/// Using inline for so the names stay comptime for string concatenation.
const llvm_lib_flags = [_][]const u8{
    "-lLLVMAArch64Disassembler",
    "-lLLVMMCDisassembler",
    "-lLLVMAArch64AsmParser",
    "-lLLVMAArch64CodeGen",
    "-lLLVMPasses",
    "-lLLVMIRPrinter",
    "-lLLVMHipStdPar",
    "-lLLVMCoroutines",
    "-lLLVMipo",
    "-lLLVMInstrumentation",
    "-lLLVMVectorize",
    "-lLLVMSandboxIR",
    "-lLLVMLinker",
    "-lLLVMFrontendOpenMP",
    "-lLLVMFrontendDirective",
    "-lLLVMFrontendAtomic",
    "-lLLVMFrontendOffloading",
    "-lLLVMObjectYAML",
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
    "-lLLVMDebugInfoGSYM",
    "-lLLVMDebugInfoDWARF",
    "-lLLVMObject",
    "-lLLVMTextAPI",
    "-lLLVMMCParser",
    "-lLLVMIRReader",
    "-lLLVMAsmParser",
    "-lLLVMMC",
    "-lLLVMDebugInfoDWARFLowLevel",
    "-lLLVMBitReader",
    "-lLLVMFrontendHLSL",
    "-lLLVMCore",
    "-lLLVMRemarks",
    "-lLLVMBitstreamReader",
    "-lLLVMBinaryFormat",
    "-lLLVMTargetParser",
    "-lLLVMSupport",
    "-lLLVMDemangle",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const llvm_prefix = b.graph.env_map.get("LLVM_PREFIX") orelse "/usr/local/llvm";
    const llvm_include = b.pathJoin(&.{ llvm_prefix, "include" });
    const llvm_lib = b.pathJoin(&.{ llvm_prefix, "lib" });
    const clangxx = b.pathJoin(&.{ llvm_prefix, "bin", "clang++" });

    // --- Compile Zig source to object file ---
    const obj = b.addObject(.{
        .name = "with",
        .root_module = b.createModule(.{
            .root_source_file = b.path("bootstrap/main.zig"),
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
        "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk",
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
        "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk",
        "-c",
    });
    fiber_c.addFileArg(b.path("runtime/fiber.c"));
    fiber_c.addArg("-o");
    const fiber_c_out = fiber_c.addOutputFileArg("fiber.o");

    const fiber_asm = b.addSystemCommand(&.{
        "cc",
        "-isysroot",
        "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk",
        "-c",
    });
    fiber_asm.addFileArg(b.path("runtime/fiber_asm_aarch64.s"));
    fiber_asm.addArg("-o");
    const fiber_asm_out = fiber_asm.addOutputFileArg("fiber_asm.o");

    // Compile runtime helpers.
    const helpers_c = b.addSystemCommand(&.{
        "cc",
        "-isysroot",
        "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk",
        "-c",
    });
    helpers_c.addFileArg(b.path("runtime/helpers.c"));
    helpers_c.addArg("-o");
    const helpers_c_out = helpers_c.addOutputFileArg("helpers.o");

    // --- Install ---
    const install = b.addInstallBinFile(output, "with");
    b.getInstallStep().dependOn(&install.step);

    // Install runtime objects alongside the compiler.
    const install_fiber_c = b.addInstallBinFile(fiber_c_out, "runtime/fiber.o");
    const install_fiber_asm = b.addInstallBinFile(fiber_asm_out, "runtime/fiber_asm.o");
    const install_helpers = b.addInstallBinFile(helpers_c_out, "runtime/helpers.o");
    b.getInstallStep().dependOn(&install_fiber_c.step);
    b.getInstallStep().dependOn(&install_fiber_asm.step);
    b.getInstallStep().dependOn(&install_helpers.step);

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
            .root_source_file = b.path("bootstrap/main.zig"),
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
