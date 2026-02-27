// main — Entry point for the With self-hosted compiler.
//
// CLI commands:
//   with build <file.w> [-o output]  — compile to executable via C backend
//   with run <file.w>                — compile + execute
//   with check <file.w>              — lex + parse + sema only
//   with version                     — print version

use Driver
use CEmit

extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn exit(code: i32) -> void

fn version() -> str:
    "with 0.1.0-dev (self-hosted)"

fn print_usage() -> void:
    println("Usage: with <command> [options]")
    println("")
    println("Commands:")
    println("  build <file.w>  Compile to executable")
    println("  run <file.w>    Compile and run")
    println("  check <file.w>  Type-check only")
    println("  version         Print version")
    println("")
    println("Options:")
    println("  -o <output>     Output path (default: .with/build/main)")

fn main:
    let argc = with_arg_count()
    if argc < 2:
        print_usage()
        exit(1)
    let cmd = with_arg_at(1)
    if cmd == "build":
        cmd_build()
        return
    if cmd == "run":
        cmd_run()
        return
    if cmd == "check":
        cmd_check()
        return
    if cmd == "version":
        println(version())
        return
    println("error: unknown command '" ++ cmd ++ "'")
    print_usage()
    exit(1)

fn cmd_build() -> void:
    let argc = with_arg_count()
    if argc < 3:
        println("error: 'build' requires a source file")
        exit(1)
    let source_path = with_arg_at(2)
    var output_path = ".with/build/main"
    // Check for -o flag
    if argc >= 5:
        let flag = with_arg_at(3)
        if flag == "-o":
            output_path = with_arg_at(4)

    var d = Driver.new(MODE_BUILD(), source_path)
    let result = Driver.compile_to_c(d, output_path)
    if result != CR_OK():
        Driver.report_errors(d)
        exit(1)

fn cmd_run() -> void:
    let argc = with_arg_count()
    if argc < 3:
        println("error: 'run' requires a source file")
        exit(1)
    let source_path = with_arg_at(2)
    var d = Driver.new(MODE_RUN(), source_path)
    let result = Driver.compile_and_run(d)
    if result != CR_OK():
        Driver.report_errors(d)
        exit(1)

fn cmd_check() -> void:
    let argc = with_arg_count()
    if argc < 3:
        println("error: 'check' requires a source file")
        exit(1)
    let source_path = with_arg_at(2)
    var d = Driver.new(MODE_CHECK(), source_path)
    let result = Driver.run_pipeline(d)
    if result != CR_OK():
        Driver.report_errors(d)
        exit(1)
    println("ok")
