//! expect-stdout: ok
// #3123 (§16.2b.15, D121): a producer that allocates through a callee's out
// parameter (`open(&data); return data;`) and a destroyer that frees through
// a pointer to its pointer (`close(&data)`), as libcurl's curl_easy_init and
// curl_easy_cleanup do. Both read as "local data is stored or its address
// taken". The callee's body decides: a slot it fills only with an allocation
// nothing else keeps is a fresh allocation in the caller, and a slot whose
// content it frees is a destruction of what the caller's local stands for.
// Anything less stays raw: a callee that also keeps the pointer, one that
// also returns it, a closer that frees nothing, a slot filled from a
// parameter.
use compiler.ConanClient
use std.fs
use std.process

fn line_of(report: &str, name: &str) -> str:
    for line in report.split("\n"):
        if line.starts_with("  " ++ name ++ ":"): return line.to_owned()
    ""

fn main:
    let root = "out/tmp/conan_facade_slot_producer_destroyer_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    var header = "struct good; struct kept; struct twice; struct lazy; struct lent;\n"
    header = header ++ "struct good *good_init(void);\nvoid good_cleanup(struct good *g);\n"
    // A prototype c_import does not import (a name starting with `_`) is
    // no facade item, proven or not.
    header = header ++ "struct good *__good_init_internal(void);\n"
    header = header ++ "struct kept *kept_init(void);\nvoid kept_cleanup(struct kept *k);\n"
    header = header ++ "struct twice *twice_init(void);\nvoid twice_cleanup(struct twice *t);\n"
    header = header ++ "struct lazy *lazy_init(void);\nvoid lazy_cleanup(struct lazy *l);\n"
    header = header ++ "struct lent *lent_init(struct lent *from);\nvoid lent_cleanup(struct lent *l);\n"
    assert(write_file(dep ++ "/include/slots.h", header) == 0)
    assert(write_file(src ++ "/slots.h", header) == 0)
    var unit = "#include <stdlib.h>\n#include \"slots.h\"\n"
    unit = unit ++ "struct good { int n; }; struct kept { int n; }; struct twice { int n; }; struct lazy { int n; }; struct lent { struct lent *next; };\n"
    // The shape that is proven.
    unit = unit ++ "static int good_open(struct good **out) { struct good *data = calloc(1, sizeof *data); if(!data) return 1; *out = data; return 0; }\n"
    unit = unit ++ "static void good_close(struct good **datap) { struct good *data; if(!datap || !*datap) return; data = *datap; *datap = NULL; free(data); }\n"
    unit = unit ++ "struct good *good_init(void) { struct good *data; if(good_open(&data)) return NULL; return data; }\n"
    unit = unit ++ "void good_cleanup(struct good *g) { struct good *data = g; if(data) good_close(&data); }\n"
    unit = unit ++ "struct good *__good_init_internal(void) { return calloc(1, sizeof(struct good)); }\n"
    // The callee keeps the pointer in a global as well.
    unit = unit ++ "static struct kept *last_kept;\n"
    unit = unit ++ "static int kept_open(struct kept **out) { struct kept *data = calloc(1, sizeof *data); if(!data) return 1; last_kept = data; *out = data; return 0; }\n"
    unit = unit ++ "struct kept *kept_init(void) { struct kept *data; if(kept_open(&data)) return NULL; return data; }\n"
    unit = unit ++ "void kept_cleanup(struct kept *k) { free(k); }\n"
    // The callee hands the same allocation out twice: by the slot and by its return.
    unit = unit ++ "static struct twice *twice_open(struct twice **out) { struct twice *data = calloc(1, sizeof *data); *out = data; return data; }\n"
    unit = unit ++ "struct twice *twice_init(void) { struct twice *a; return twice_open(&a); }\n"
    unit = unit ++ "void twice_cleanup(struct twice *t) { free(t); }\n"
    // The closer clears the slot and frees nothing.
    unit = unit ++ "static void lazy_close(struct lazy **datap) { *datap = NULL; }\n"
    unit = unit ++ "struct lazy *lazy_init(void) { return calloc(1, sizeof(struct lazy)); }\n"
    unit = unit ++ "void lazy_cleanup(struct lazy *l) { struct lazy *data = l; lazy_close(&data); }\n"
    // The slot is filled from a parameter: a borrow, not an allocation.
    unit = unit ++ "static void lent_pick(struct lent **out, struct lent *from) { *out = from->next; }\n"
    unit = unit ++ "struct lent *lent_init(struct lent *from) { struct lent *data; lent_pick(&data, from); return data; }\n"
    unit = unit ++ "void lent_cleanup(struct lent *l) { free(l); }\n"
    assert(write_file(src ++ "/slots.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c slots.c\",\n  \"file\": \"slots.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"slots\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("slots", "1.0", dep, src, build)
    let report = read_file(dep ++ "/facade-report.txt") ?? ""
    let facade = read_file(dep ++ "/facade.w") ?? ""
    let good = line_of(report, "good_init").contains("owned producer of Good") and line_of(report, "good_cleanup").contains("destroyer, param 0") and facade.contains("resource Good wraps *mut good\n        from good_init") and facade.contains("        drop good_cleanup")
    let kept = line_of(report, "kept_init").contains("raw:") and not facade.contains("from kept_init")
    let twice = line_of(report, "twice_init").contains("raw:") and not facade.contains("from twice_init")
    let lazy = line_of(report, "lazy_cleanup").contains("raw:") and line_of(report, "lazy_cleanup").contains("not proven to free what it holds") and not facade.contains("drop lazy_cleanup")
    let lent = not line_of(report, "lent_init").contains("owned producer") and not facade.contains("from lent_init")
    let internal = not facade.contains("__good_init_internal")
    let ok = good and kept and twice and lazy and lent and internal
    if not ok:
        print(f"good={good} kept={kept} twice={twice} lazy={lazy} lent={lent}")
        print(report)
        print(facade)
    assert(ok)
    print("ok")
