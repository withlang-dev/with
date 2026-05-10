// std.build — typed build graph construction API.
//
// The compiler driver is responsible for executing build.w in tool mode and
// turning this graph into concrete compiler/linker actions.

pub enum BuildKind: i32:
    Executable = 0
    Library = 1
    Test = 2

pub enum BuildTarget: i32:
    native = 0

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
    target_kind: BuildTarget,
    optimize_mode: OptimizeMode,
    system_libs: Vec[str],
    include_paths: Vec[str],
    defines: Vec[str],
}

pub type Build {
    package: Package,
    targets: Vec[Target],
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
        targets: Vec.new(),
    }

pub fn target_new(kind: BuildKind, name: str, entry: str) -> Target:
    Target {
        kind,
        name,
        entry,
        target_kind: BuildTarget.native,
        optimize_mode: OptimizeMode.debug,
        system_libs: Vec.new(),
        include_paths: Vec.new(),
        defines: Vec.new(),
    }

pub fn Build.add_target(mut self: Build, target: Target) -> Build:
    self.targets.push(target)
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

pub fn Target.target(self: Target, target: BuildTarget) -> Target:
    Target {
        kind: self.kind,
        name: self.name,
        entry: self.entry,
        target_kind: target,
        optimize_mode: self.optimize_mode,
        system_libs: self.system_libs,
        include_paths: self.include_paths,
        defines: self.defines,
    }

pub fn Target.optimize(self: Target, mode: OptimizeMode) -> Target:
    Target {
        kind: self.kind,
        name: self.name,
        entry: self.entry,
        target_kind: self.target_kind,
        optimize_mode: mode,
        system_libs: self.system_libs,
        include_paths: self.include_paths,
        defines: self.defines,
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

pub fn Build.emit_graph(self: Build) -> str:
    var out = "WITH_BUILD_GRAPH\t1\n"
    out = out ++ "package\t" ++ build_graph_escape(self.package.name) ++ "\t" ++ build_graph_escape(self.package.version) ++ "\n"
    for ti in 0..self.targets.len() as i32:
        let target = self.targets.get(ti as i64)
        out = out ++ "target\t"
        out = out ++ f"{target.kind as i32}\t"
        out = out ++ build_graph_escape(target.name) ++ "\t"
        out = out ++ build_graph_escape(target.entry) ++ "\t"
        out = out ++ f"{target.target_kind as i32}\t"
        out = out ++ f"{target.optimize_mode as i32}\n"
        for li in 0..target.system_libs.len() as i32:
            out = out ++ "system_lib\t" ++ f"{ti}\t" ++ build_graph_escape(target.system_libs.get(li as i64)) ++ "\n"
        for ii in 0..target.include_paths.len() as i32:
            out = out ++ "include_path\t" ++ f"{ti}\t" ++ build_graph_escape(target.include_paths.get(ii as i64)) ++ "\n"
        for di in 0..target.defines.len() as i32:
            out = out ++ "define\t" ++ f"{ti}\t" ++ build_graph_escape(target.defines.get(di as i64)) ++ "\n"
    out
