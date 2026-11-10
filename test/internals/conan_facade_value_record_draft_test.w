//! expect-stdout: ok
// D198 (§16.2b.5): a draft states `reads`, `fills` or `updates param N`
// only from a proof over the library's source: the record is complete in
// an installed header and has no identity, and the body touches only the
// one record and keeps no pointer to it or into it.
//   area          const Size *, read            -> reads
//   area_via      passes it to a package function that reads -> reads
//   default_size  Size *, written, never read   -> fills
//   grow          Size *, read and written      -> updates
//   total         const Size *items, indexed    -> raw (an array, not one record)
//   width_of      takes `&s->w`                 -> raw (a pointer into the record)
//   keep          stores the pointer            -> raw, and Kept has identity:
//   kept_area     const Kept *, only read       -> raw all the same
//   span_first    const Span *, a record holding a pointer -> raw: the
//                 callee follows `s->items`, and whoever builds the record
//                 chooses where that points
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_value_record_draft_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    var header = "typedef struct { int w; int h; } Size;\ntypedef struct { int n; } Kept;\ntypedef struct { const int *items; int n; } Span;\n"
    header = header ++ "int area(const Size *s);\nint area_via(const Size *s);\nvoid default_size(Size *out);\nvoid grow(Size *s, int by);\n"
    header = header ++ "int total(const Size *items, int count);\nint width_of(Size *s);\nvoid keep(const Kept *k);\nint kept_area(const Kept *k);\nint span_first(const Span *s);\n"
    assert(write_file(dep ++ "/include/shapes.h", header) == 0)
    assert(write_file(src ++ "/shapes.h", header) == 0)
    var unit = "#include \"shapes.h\"\n"
    unit = unit ++ "int area(const Size *s) { return s->w * s->h; }\n"
    unit = unit ++ "static int twice_area(const Size *s) { return 2 * s->w * s->h; }\nint area_via(const Size *s) { return twice_area(s); }\n"
    unit = unit ++ "void default_size(Size *out) { out->w = 3; out->h = 4; }\n"
    unit = unit ++ "void grow(Size *s, int by) { s->w += by; s->h = s->h + by; }\n"
    unit = unit ++ "int total(const Size *items, int count) { int t = 0; for (int i = 0; i < count; i++) t += items[i].w; return t; }\n"
    unit = unit ++ "static int read_int(const int *p) { return *p; }\nint width_of(Size *s) { return read_int(&s->w); }\n"
    unit = unit ++ "static const Kept *kept;\nvoid keep(const Kept *k) { kept = k; }\nint kept_area(const Kept *k) { return k->n; }\nint span_first(const Span *s) { return s->n > 0 ? s->items[0] : 0; }\n"
    assert(write_file(src ++ "/shapes.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c shapes.c\",\n  \"file\": \"shapes.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"shapes\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("shapes", "1.0", dep, src, build)
    let facade = read_file(dep ++ "/facade.w") ?? ""
    let report = read_file(dep ++ "/facade-report.txt") ?? ""
    let stated = [
        "    fn area\n        reads param 0",
        "    fn area_via\n        reads param 0",
        "    fn default_size\n        fills param 0",
        "    fn grow\n        updates param 0",
    ]
    var wrong = 0
    for item in stated:
        if not facade.contains(item):
            wrong = wrong + 1
            print("not stated: " ++ item)
    for name in ["total", "width_of", "keep", "kept_area", "span_first"]:
        if facade.contains("    fn " ++ name ++ "\n"):
            wrong = wrong + 1
            print("stated, and must stay raw: " ++ name)
    // The report says which words were stated, and why a record pointer is
    // no value record.
    for said in ["  area: value records: reads param 0 (proof:", "  kept_area: raw: parameter of unmodeled pointer type *const Kept; param 0 is no value record: some function of the package produces, destroys or retains a pointer to Kept", "  total: raw: parameter of unmodeled pointer type *const Size; param 0 is no value record: the body indexes it", "  span_first: raw: parameter of unmodeled pointer type *const Span; param 0 is no value record: Span is not a flat record complete in a header the package installs"]:
        if not report.contains(said):
            wrong = wrong + 1
            print("not reported: " ++ said)
    if wrong > 0:
        print(facade)
        print(report)
    assert(wrong == 0)
    print("ok")
