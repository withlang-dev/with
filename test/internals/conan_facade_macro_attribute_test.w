//! expect-stdout: ok
// A function whose attribute comes from a macro defined under `#if` (curl's
// `CURL_TEMP_PRINTF(1, 2)`): the report names the attribute alone. The
// declaration's extent ends inside the macro's definition, and its tokens
// ran on through the `#else`/`#define` lines after it:
// `[attributes: format(printf,fmt,arg)))#endif#else#defineTEMP_PRINTF…]`.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_macro_attribute_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    var header = "#ifndef TEMP_PRINTF\n#if defined(__GNUC__) || defined(__clang__)\n#define TEMP_PRINTF(fmt, arg) \\\n  __attribute__((format(printf, fmt, arg)))\n#else\n#define TEMP_PRINTF(fmt, arg)\n#endif\n#endif\n"
    header = header ++ "int log_line(const char *format, ...)\n  TEMP_PRINTF(1, 2);\nint plain(int x) __attribute__((const));\n"
    assert(write_file(dep ++ "/include/logs.h", header) == 0)
    assert(write_file(src ++ "/logs.h", header) == 0)
    let unit = "#include \"logs.h\"\nint log_line(const char *format, ...) { return format[0]; }\nint plain(int x) { return x + 1; }\n"
    assert(write_file(src ++ "/logs.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c logs.c\",\n  \"file\": \"logs.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"logs\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("logs", "1.0", dep, src, build)
    let report = read_file(dep ++ "/facade-report.txt") ?? ""
    var log_line = ""
    var plain_line = ""
    for line in report.split("\n"):
        if line.starts_with("  log_line:"): log_line = line.to_owned()
        if line.starts_with("  plain:"): plain_line = line.to_owned()
    let ok = log_line.contains("[attributes: format(printf,fmt,arg)]") and not report.contains("#") and plain_line.contains("[attributes: const]")
    if not ok: print(report)
    assert(ok)
    print("ok")
