use std.build
use std.string

pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build()
    out = out.copy_file("copy-directory", "left", "out/copied-directory")
    out = out.binary_compare("compare-directories", "left", "right")

    var timeout_command = target_new(.Command, "timeout-command", "/usr/bin/sleep")
    timeout_command = timeout_command.arg("0.2")
    timeout_command = timeout_command.timeout(1)
    out = out.add_target(timeout_command)

    var cwd_command = target_new(.Command, "cwd-command", "/bin/pwd")
    cwd_command = cwd_command.working_dir("left")
    out = out.add_target(cwd_command)

    var env_command = target_new(.Command, "env-command", "/usr/bin/env")
    env_command = env_command.with_env("WITH_AUDIT_SENTINEL", "present")
    out = out.add_target(env_command)

    var missing_extra = target_new(.Command, "missing-extra", "/usr/bin/true")
    missing_extra = missing_extra.extra_output("out/never-created")
    out = out.add_target(missing_extra)

    var install_home = target_new(.Install, "install-home", "left/left.txt")
    install_home = install_home.output("$HOME/audit-installed")
    install_home = install_home.arg("0644")
    out = out.add_target(install_home)

    var nul_arg = StringBuilder.new()
    nul_arg.push_str("before")
    nul_arg.push_byte(0 as u8)
    nul_arg.push_str("after")
    var response_nul = target_new(.GenerateResponseFile, "response-nul", "")
    response_nul = response_nul.output("out/nul.rsp")
    response_nul = response_nul.arg(nul_arg.to_str())
    out = out.add_target(response_nul)

    var assemble_unknown = target_new(.CompileAsmObject, "assemble-unknown", "probe.s")
    assemble_unknown = assemble_unknown.output("out/assemble-unknown.o")
    assemble_unknown = assemble_unknown.arg("unsupported-option")
    out = out.add_target(assemble_unknown)

    var assemble_empty_triple = target_new(.CompileAsmObject, "assemble-empty-triple", "probe.s")
    assemble_empty_triple = assemble_empty_triple.output("out/assemble-empty-triple.o")
    assemble_empty_triple = assemble_empty_triple.arg("triple=")
    out = out.add_target(assemble_empty_triple)

    var copy_bad_mode = target_new(.CopyFile, "copy-bad-mode", "left/left.txt")
    copy_bad_mode = copy_bad_mode.output("out/bad-mode.txt")
    copy_bad_mode = copy_bad_mode.arg("10000")
    out = out.add_target(copy_bad_mode)

    var embedded_fallback = target_new(.EmbedObjectFiles, "embedded-fallback", "linux_x86_64")
    embedded_fallback = embedded_fallback.output("out/embedded-fallback.s")
    embedded_fallback = embedded_fallback.input("left/left.txt")
    embedded_fallback = embedded_fallback.arg("custom_blob")
    out = out.add_target(embedded_fallback)

    let verified = target_new(.Group, "verified", "")
    out = out.add_target(verified)
    var promote_partial = target_new(.PromoteTreeIfVerified, "promote-partial", "promote-src")
    promote_partial = promote_partial.output("promote-dst")
    promote_partial = promote_partial.input("first.txt")
     promote_partial = promote_partial.input("missing.txt")
     promote_partial = promote_partial.dep("verified")
     out = out.add_target(promote_partial)

     var copy_partial = target_new(.CopyTree, "copy-partial", "copy-src")
     copy_partial = copy_partial.output("copy-dst")
     copy_partial = copy_partial.input("first.txt")
     copy_partial = copy_partial.input("missing.txt")
     out = out.add_target(copy_partial)

     var archive_destructive = target_new(.CreateStaticArchive, "archive-destructive", "")
     archive_destructive = archive_destructive.output("out/archive-before.a")
     archive_destructive = archive_destructive.input("left")
     out = out.add_target(archive_destructive)
     out.default("compare-directories")
