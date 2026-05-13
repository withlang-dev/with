// std.build — typed build graph construction API.
//
// The compiler driver is responsible for executing build.w in tool mode and
// turning this graph into concrete compiler/linker actions.

pub enum BuildKind: i32:
    Executable = 0
    Library = 1
    Test = 2
    Object = 3
    Archive = 4
    GeneratedSource = 5
    GeneratedBinary = 6
    Command = 7
    Install = 8
    Group = 9
    BinaryCompare = 10
    FixpointCompare = 11
    CompileCObject = 12
    CompileAsmObject = 13
    CompileLlvmIrObject = 14
    CreateStaticArchive = 15
    GenerateResponseFile = 16
    EmbedObjectFiles = 17
    CopyRuntimeTree = 18
    RunCorpusTest = 19
    PromoteTreeIfVerified = 20
    EmbeddedRuntimeExtractTest = 21
    SelfhostNoopLocalRegression = 22
    CliSelfhostSmokeTest = 23
    GenerateCompilerEntrypoints = 24
    WithCompilerBuild = 25
    Pcre2RunTest = 26
    Pcre2GeneratedCheck = 27
    Pcre2GeneratedPromote = 28
    Pcre2Build = 29
    CliSelfhostOneLinerTest = 30
    CliSelfhostObjectSymbolTest = 31

pub enum BuildTarget: i32:
    native = 0
    linux_x86_64 = 1
    linux_aarch64 = 2
    darwin_x86_64 = 3
    darwin_aarch64 = 4
    windows_x86_64 = 5

pub enum OptimizeMode: i32:
    debug = 0
    release = 1

pub type Package {
    name: str,
    version: str,
}

pub type Target {
    kind: BuildKind,
    name: str,
    entry: str,
    output: str,
    target_kind: BuildTarget,
    optimize_mode: OptimizeMode,
    system_libs: Vec[str],
    include_paths: Vec[str],
    defines: Vec[str],
    inputs: Vec[str],
    deps: Vec[str],
    args: Vec[str],
}

pub type GeneratedSource {
    path: str,
    contents: str,
}

pub type Build {
    package: Package,
    default_target: str,
    targets: Vec[Target],
    generated_sources: Vec[GeneratedSource],
}

fn build_graph_escape(value: str) -> str:
    var out = ""
    for i in 0..value.len() as i32:
        let ch = value.byte_at(i as i64)
        if ch == 92:
            out = out ++ "\\\\"
        else if ch == 9:
            out = out ++ "\\t"
        else if ch == 10:
            out = out ++ "\\n"
        else if ch == 13:
            out = out ++ "\\r"
        else:
            out = out ++ value.slice(i as i64, (i + 1) as i64)
    out

pub fn new_build(package: Package) -> Build:
    Build {
        package,
        default_target: "",
        targets: Vec.new(),
        generated_sources: Vec.new(),
    }

pub fn Build.default(mut self: Build, target_name: str) -> Build:
    self.default_target = target_name
    self

pub fn target_new(kind: BuildKind, name: str, entry: str) -> Target:
    Target {
        kind,
        name,
        entry,
        output: "",
        target_kind: BuildTarget.native,
        optimize_mode: OptimizeMode.debug,
        system_libs: Vec.new(),
        include_paths: Vec.new(),
        defines: Vec.new(),
        inputs: Vec.new(),
        deps: Vec.new(),
        args: Vec.new(),
    }

pub fn Build.add_target(mut self: Build, target: Target) -> Build:
    self.targets.push(target)
    self

pub fn Build.generated_source(mut self: Build, path: str, contents: str) -> Build:
    self.generated_sources.push(GeneratedSource { path, contents })
    self

pub fn Build.executable(self: Build, name: str, entry: str) -> Build:
    let target = target_new(.Executable, name, entry)
    self.add_target(target)

pub fn Build.library(self: Build, name: str, entry: str) -> Build:
    let target = target_new(.Library, name, entry)
    self.add_target(target)

pub fn Build.test(self: Build, name: str, entry: str) -> Build:
    let target = target_new(.Test, name, entry)
    self.add_target(target)

pub fn Build.object(self: Build, name: str, entry: str) -> Build:
    let target = target_new(.Object, name, entry)
    self.add_target(target)

pub fn Build.archive(self: Build, name: str, entry: str) -> Build:
    let target = target_new(.Archive, name, entry)
    self.add_target(target)

pub fn Build.command(self: Build, name: str, runner: str) -> Build:
    let target = target_new(.Command, name, runner)
    self.add_target(target)

pub fn Build.install(self: Build, name: str, source: str, dest: str) -> Build:
    let target = target_new(.Install, name, source).output(dest)
    self.add_target(target)

pub fn Build.group(self: Build, name: str) -> Build:
    let target = target_new(.Group, name, "")
    self.add_target(target)

pub fn Build.binary_compare(self: Build, name: str, left: str, right: str) -> Build:
    var target = target_new(.BinaryCompare, name, left)
    target = target.arg(right)
    self.add_target(target)

pub fn Build.fixpoint_compare(self: Build, name: str, left: str, right: str) -> Build:
    var target = target_new(.FixpointCompare, name, left)
    target = target.arg(right)
    self.add_target(target)

pub fn Build.compile_c_object(self: Build, name: str, source: str, output: str) -> Build:
    let target = target_new(.CompileCObject, name, source).output(output)
    self.add_target(target)

pub fn Build.compile_asm_object(self: Build, name: str, source: str, output: str) -> Build:
    let target = target_new(.CompileAsmObject, name, source).output(output)
    self.add_target(target)

pub fn Build.compile_llvm_ir_object(self: Build, name: str, source: str, output: str) -> Build:
    let target = target_new(.CompileLlvmIrObject, name, source).output(output)
    self.add_target(target)

pub fn Build.create_static_archive(self: Build, name: str, output: str) -> Build:
    let target = target_new(.CreateStaticArchive, name, "").output(output)
    self.add_target(target)

pub fn Build.generate_response_file(self: Build, name: str, output: str) -> Build:
    let target = target_new(.GenerateResponseFile, name, "").output(output)
    self.add_target(target)

pub fn Build.embed_object_files(self: Build, name: str, output: str) -> Build:
    let target = target_new(.EmbedObjectFiles, name, "").output(output)
    self.add_target(target)

pub fn Build.copy_runtime_tree(self: Build, name: str, source_dir: str, output_dir: str) -> Build:
    let target = target_new(.CopyRuntimeTree, name, source_dir).output(output_dir)
    self.add_target(target)

pub fn Build.run_corpus_test(self: Build, name: str, runner: str) -> Build:
    let target = target_new(.RunCorpusTest, name, runner)
    self.add_target(target)

pub fn Build.promote_tree_if_verified(self: Build, name: str, source_dir: str, output_dir: str) -> Build:
    let target = target_new(.PromoteTreeIfVerified, name, source_dir).output(output_dir)
    self.add_target(target)

pub fn Build.embedded_runtime_extract_test(self: Build, name: str, compiler: str) -> Build:
    let target = target_new(.EmbeddedRuntimeExtractTest, name, compiler)
    self.add_target(target)

pub fn Build.selfhost_noop_local_regression(self: Build, name: str, compiler: str) -> Build:
    let target = target_new(.SelfhostNoopLocalRegression, name, compiler)
    self.add_target(target)

pub fn Build.cli_selfhost_smoke_test(self: Build, name: str, compiler: str) -> Build:
    let target = target_new(.CliSelfhostSmokeTest, name, compiler)
    self.add_target(target)

pub fn Build.cli_selfhost_one_liner_test(self: Build, name: str, compiler: str) -> Build:
    let target = target_new(.CliSelfhostOneLinerTest, name, compiler)
    self.add_target(target)

pub fn Build.cli_selfhost_object_symbol_test(self: Build, name: str, compiler: str) -> Build:
    let target = target_new(.CliSelfhostObjectSymbolTest, name, compiler)
    self.add_target(target)

pub fn Build.generate_compiler_entrypoints(self: Build, name: str, stamp: str) -> Build:
    let target = target_new(.GenerateCompilerEntrypoints, name, "").output(stamp)
    self.add_target(target)

pub fn Build.with_compiler_build(self: Build, name: str, compiler: str, source: str, output: str) -> Build:
    var target = target_new(.WithCompilerBuild, name, compiler).output(output)
    target = target.input(source)
    self.add_target(target)

pub fn Build.pcre2_run_test(self: Build, name: str, pcre2test: str, ref_dir: str) -> Build:
    var target = target_new(.Pcre2RunTest, name, pcre2test)
    target = target.input(ref_dir ++ "/RunTest")
    target = target.arg(ref_dir)
    self.add_target(target)

pub fn Build.pcre2_generated_check(self: Build, name: str, compiler: str, generated_dir: str) -> Build:
    var target = target_new(.Pcre2GeneratedCheck, name, compiler)
    target = target.input(generated_dir)
    self.add_target(target)

pub fn Build.pcre2_generated_promote(self: Build, name: str, compiler: str, generated_dir: str, dest_dir: str) -> Build:
    var target = target_new(.Pcre2GeneratedPromote, name, compiler).output(dest_dir)
    target = target.input(generated_dir)
    self.add_target(target)

pub fn Build.pcre2_build(self: Build, name: str, compiler: str, migrated_dir: str, output_dir: str) -> Build:
    var target = target_new(.Pcre2Build, name, compiler).output(output_dir)
    target = target.input(migrated_dir)
    self.add_target(target)

pub fn Target.target(self: Target, target: BuildTarget) -> Target:
    Target {
        kind: self.kind,
        name: self.name,
        entry: self.entry,
        output: self.output,
        target_kind: target,
        optimize_mode: self.optimize_mode,
        system_libs: self.system_libs,
        include_paths: self.include_paths,
        defines: self.defines,
        inputs: self.inputs,
        deps: self.deps,
        args: self.args,
    }

pub fn Target.optimize(self: Target, mode: OptimizeMode) -> Target:
    Target {
        kind: self.kind,
        name: self.name,
        entry: self.entry,
        output: self.output,
        target_kind: self.target_kind,
        optimize_mode: mode,
        system_libs: self.system_libs,
        include_paths: self.include_paths,
        defines: self.defines,
        inputs: self.inputs,
        deps: self.deps,
        args: self.args,
    }

pub fn Target.link_system_lib(mut self: Target, lib: str) -> Target:
    self.system_libs.push(lib)
    self

pub fn Target.include_path(mut self: Target, path: str) -> Target:
    self.include_paths.push(path)
    self

pub fn Target.define(mut self: Target, define: str) -> Target:
    self.defines.push(define)
    self

pub fn Target.output(self: Target, output: str) -> Target:
    Target {
        kind: self.kind,
        name: self.name,
        entry: self.entry,
        output,
        target_kind: self.target_kind,
        optimize_mode: self.optimize_mode,
        system_libs: self.system_libs,
        include_paths: self.include_paths,
        defines: self.defines,
        inputs: self.inputs,
        deps: self.deps,
        args: self.args,
    }

pub fn Target.input(mut self: Target, input: str) -> Target:
    self.inputs.push(input)
    self

pub fn Target.dep(mut self: Target, dep: str) -> Target:
    self.deps.push(dep)
    self

pub fn Target.arg(mut self: Target, arg: str) -> Target:
    self.args.push(arg)
    self

pub fn Target.compiler(mut self: Target, compiler: str) -> Target:
    self.args.push("compiler=" ++ compiler)
    self

pub fn Build.emit_graph(self: Build) -> str:
    var out = "WITH_BUILD_GRAPH\t2\n"
    out = out ++ "package\t" ++ build_graph_escape(self.package.name) ++ "\t" ++ build_graph_escape(self.package.version) ++ "\n"
    if self.default_target.len() > 0:
        out = out ++ "default_target\t" ++ build_graph_escape(self.default_target) ++ "\n"
    for gi in 0..self.generated_sources.len() as i32:
        let generated = self.generated_sources.get(gi as i64)
        out = out ++ "generated_source\t" ++ build_graph_escape(generated.path) ++ "\t" ++ build_graph_escape(generated.contents) ++ "\n"
    for ti in 0..self.targets.len() as i32:
        let target = self.targets.get(ti as i64)
        out = out ++ "target\t"
        out = out ++ f"{target.kind as i32}\t"
        out = out ++ build_graph_escape(target.name) ++ "\t"
        out = out ++ build_graph_escape(target.entry) ++ "\t"
        out = out ++ f"{target.target_kind as i32}\t"
        out = out ++ f"{target.optimize_mode as i32}\t"
        out = out ++ build_graph_escape(target.output) ++ "\n"
        for li in 0..target.system_libs.len() as i32:
            out = out ++ "system_lib\t" ++ f"{ti}\t" ++ build_graph_escape(target.system_libs.get(li as i64)) ++ "\n"
        for ii in 0..target.include_paths.len() as i32:
            out = out ++ "include_path\t" ++ f"{ti}\t" ++ build_graph_escape(target.include_paths.get(ii as i64)) ++ "\n"
        for di in 0..target.defines.len() as i32:
            out = out ++ "define\t" ++ f"{ti}\t" ++ build_graph_escape(target.defines.get(di as i64)) ++ "\n"
        for ini in 0..target.inputs.len() as i32:
            out = out ++ "input\t" ++ f"{ti}\t" ++ build_graph_escape(target.inputs.get(ini as i64)) ++ "\n"
        for depi in 0..target.deps.len() as i32:
            out = out ++ "dep\t" ++ f"{ti}\t" ++ build_graph_escape(target.deps.get(depi as i64)) ++ "\n"
        for ai in 0..target.args.len() as i32:
            out = out ++ "arg\t" ++ f"{ti}\t" ++ build_graph_escape(target.args.get(ai as i64)) ++ "\n"
    out
