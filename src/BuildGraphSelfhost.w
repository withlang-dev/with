// BuildGraphSelfhost -- bulky selfhost build.w fixture tests used by the
// repository build graph. Kept out of main.w so the CLI entry point remains a
// dispatcher instead of a fixture warehouse.

use BuildGraphSelfhostHarness
extern fn with_fs_chmod(path: str, mode: i32) -> i32
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_remove_dir(path: str) -> i32
extern fn with_fs_remove_file(path: str) -> i32
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_getenv_str(name: str) -> str
extern fn with_str_contains(s: str, needle: str) -> i32
extern fn with_eprint(s: str) -> void

fn bgs_migrate_error(target_name: str, message: str) -> void:
    with_eprint("error: cli selfhost migrator test target '" ++ target_name ++ "' " ++ message)

fn bgs_migrate_assert_contains(text: str, needle: str, target_name: str, label: str) -> i32:
    if with_str_contains(text, needle) != 0:
        return 0
    bgs_migrate_error(target_name, "missing expected output for " ++ label ++ ": " ++ needle)
    1

fn bgs_migrate_assert_not_contains(text: str, needle: str, target_name: str, label: str) -> i32:
    if with_str_contains(text, needle) == 0:
        return 0
    bgs_migrate_error(target_name, "found forbidden output for " ++ label ++ ": " ++ needle)
    1

fn bgs_migrate_file_contains(path: str, needle: str, target_name: str, label: str) -> i32:
    if with_fs_file_exists(path) == 0:
        bgs_migrate_error(target_name, "missing file for " ++ label ++ ": " ++ path)
        return 1
    bgs_migrate_assert_contains(with_fs_read_file(path), needle, target_name, label)

fn bgs_migrate_file_forbids(path: str, needle: str, target_name: str, label: str) -> i32:
    if with_fs_file_exists(path) == 0:
        bgs_migrate_error(target_name, "missing file for " ++ label ++ ": " ++ path)
        return 1
    bgs_migrate_assert_not_contains(with_fs_read_file(path), needle, target_name, label)

fn bgs_index_of(text: str, needle: str) -> i32:
    if needle.len() == 0:
        return 0
    if needle.len() > text.len():
        return -1
    let max_start = (text.len() - needle.len()) as i32
    for i in 0..(max_start + 1):
        var matched = true
        for j in 0..needle.len() as i32:
            if text.byte_at((i + j) as i64) != needle.byte_at(j as i64):
                matched = false
                break
        if matched:
            return i
    -1

fn bgs_count_occurrences(text: str, needle: str) -> i32:
    if needle.len() == 0:
        return 0
    var count = 0
    var offset = 0
    while offset < text.len() as i32:
        let found = bgs_index_of(text.slice(offset as i64, text.len()), needle)
        if found < 0:
            break
        count = count + 1
        offset = offset + found + needle.len() as i32
    count

fn bgs_migrate_expect_success(root: str, target_name: str, compiler_path: str, case_dir: str, label: str, argv_tail: str) -> BuildSelfhostRunResult:
    let result = bgs_run_cli_capture_cwd(root, target_name, compiler_path, label, argv_tail, 180000, case_dir)
    if result.rc != 0:
        bgs_migrate_error(target_name, "case '" ++ label ++ f"' failed with exit code {result.rc}")
    result

fn bgs_check_migrate_libc_ctype(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "libc_ctype.c")
    let out_w = bgs_resolve_join(case_dir, "libc_ctype.w")
    let c_text = "#include <ctype.h>\n\nint classify(int c) {\n  return isalpha(c) + isdigit(c) + isalnum(c) + isspace(c) +\n    isupper(c) + islower(c) + isxdigit(c) + isprint(c) +\n    isgraph(c) + ispunct(c) + iscntrl(c) + tolower(c) + toupper(c);\n}\n"
    var rc = bgs_write_fixture(src, c_text, target_name, "libc ctype source")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "--prefer-brace")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-libc-ctype", argv)
    if result.rc != 0: return result.rc
    let out_text = with_fs_read_file(out_w)
    let required: Vec[str] = Vec.new()
    required.push("extern fn isalpha(c: i32) -> i32")
    required.push("extern fn tolower(c: i32) -> i32")
    required.push("isalpha(__param_c)")
    required.push("isalnum(__param_c)")
    required.push("isgraph(__param_c)")
    required.push("tolower(__param_c)")
    for i in 0..required.len() as i32:
        rc = bgs_migrate_assert_contains(out_text, required.get(i as i64), target_name, "libc_ctype_calls")
        if rc != 0: return rc
    let forbidden: Vec[str] = Vec.new()
    forbidden.push("is_alpha(__param_c)")
    forbidden.push("is_alnum(__param_c)")
    forbidden.push("to_lower(__param_c)")
    for i in 0..forbidden.len() as i32:
        rc = bgs_migrate_assert_not_contains(out_text, forbidden.get(i as i64), target_name, "libc_ctype_calls")
        if rc != 0: return rc
    let check = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-libc-ctype", bgs_argv_append(bgs_argv_append("", "check"), out_w))
    if check.rc != 0: return check.rc
    0

fn bgs_check_migrate_macro_unsigned_minus(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "macro_initializer_unsigned_minus.c")
    let out_w = bgs_resolve_join(case_dir, "macro_initializer_unsigned_minus.w")
    let c_text = "typedef unsigned long size_t;\n\n#define MY_SIZE_MAX ((size_t)-1)\n#define COPY_ONE(dst_, src_, length_) do { size_t chkmc_length = length_; if (chkmc_length > 0) { (dst_)[0] = (src_)[0]; } } while (0)\n\nint too_large(size_t current, size_t need) {\n  return current > (MY_SIZE_MAX - need) / 2;\n}\n\nint repeat_too_large(size_t replen, size_t need, int count) {\n  return count > 0 && replen > (MY_SIZE_MAX - need) / count;\n}\n\nint copy_after_goto(char *dst, const char *src, int flag) {\n  if (flag) goto copy;\n  return 0;\ncopy:\n  COPY_ONE(dst, src, 3);\n  return (int)dst[0];\n}\n"
    var rc = bgs_write_fixture(src, c_text, target_name, "macro unsigned source")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "--prefer-brace")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-macro-unsigned-minus", argv)
    if result.rc != 0: return result.rc
    let out_text = with_fs_read_file(out_w)
    if with_str_contains(out_text, "(-1 as ") == 0 and with_str_contains(out_text, "(0 as ") == 0:
        bgs_migrate_error(target_name, "macro_initializer_unsigned_minus missing typed unsigned -1")
        return 1
    rc = bgs_migrate_assert_not_contains(out_text, "((0 -% 1)", target_name, "macro_initializer_unsigned_minus")
    if rc != 0: return rc
    rc = bgs_migrate_assert_contains(out_text, "/ (__param_count as ", target_name, "macro_initializer_unsigned_minus")
    if rc != 0: return rc
    rc = bgs_migrate_assert_contains(out_text, "__local_chkmc_length", target_name, "macro_initializer_unsigned_minus")
    if rc != 0: return rc
    rc = bgs_migrate_assert_contains(out_text, "= 3)", target_name, "macro_initializer_unsigned_minus")
    if rc != 0: return rc
    let check = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-macro-unsigned-minus", bgs_argv_append(bgs_argv_append("", "check"), out_w))
    if check.rc != 0: return check.rc
    0

fn bgs_check_migrate_tentative_global_owner(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "tentative_global_owner.c")
    let out_w = bgs_resolve_join(case_dir, "tentative_global_owner.w")
    var rc = bgs_write_fixture(src, "typedef struct ctx { int x; } ctx;\nctx g;\nint issue127_read(void) { return g.x; }\n", target_name, "tentative global owner")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-tentative-global-owner", argv)
    if result.rc != 0: return result.rc
    rc = bgs_migrate_file_contains(out_w, "var g: ctx", target_name, "tentative_global_owner")
    if rc != 0: return rc
    rc = bgs_migrate_file_forbids(out_w, "extern var g: ctx", target_name, "tentative_global_owner")
    if rc != 0: return rc
    let check = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-tentative-global-owner", bgs_argv_append(bgs_argv_append("", "check"), out_w))
    if check.rc != 0: return check.rc
    0

fn bgs_check_migrate_cross_file_tentative_global_owner(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let generated_dir = bgs_resolve_join(case_dir, "generated")
    var rc = bgs_write_fixture(bgs_resolve_join(case_dir, "a.c"), "int issue127_counter;\nint issue127_get(void) { return issue127_counter; }\n", target_name, "cross tentative a")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "b.c"), "int issue127_counter;\nint issue127_bump(void) {\n  issue127_counter = issue127_counter + 1;\n  return issue127_counter;\n}\n", target_name, "cross tentative b")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, case_dir)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, generated_dir)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-cross-file-tentative", argv)
    if result.rc != 0: return result.rc
    let a_w = bgs_resolve_join(generated_dir, "a.w")
    let b_w = bgs_resolve_join(generated_dir, "b.w")
    rc = bgs_migrate_file_contains(a_w, "var issue127_counter: c_int", target_name, "cross_file_tentative_global_owner")
    if rc != 0: return rc
    rc = bgs_migrate_file_contains(b_w, "extern var issue127_counter: c_int", target_name, "cross_file_tentative_global_owner")
    if rc != 0: return rc
    let check_a = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-cross-file-tentative-a", bgs_argv_append(bgs_argv_append("", "check"), a_w))
    if check_a.rc != 0: return check_a.rc
    let check_b = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-cross-file-tentative-b", bgs_argv_append(bgs_argv_append("", "check"), b_w))
    if check_b.rc != 0: return check_b.rc
    0

fn bgs_check_migrate_noop_pointer_casts(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "noop_pointer_cast_exprs.c")
    let out_w = bgs_resolve_join(case_dir, "noop_pointer_cast_exprs.w")
    let c_text = "typedef struct ctx { int x; } ctx;\nctx g;\n\nctx *ret_ctx(void) { return (ctx *)(&g); }\n\nint f(ctx *ccontext) {\n  ctx *local = (ctx *)(&g);\n  ccontext = (ctx *)(&g);\n  return local->x + ccontext->x;\n}\n\nstatic void callback(void *p) { (void)p; }\n\ntypedef void (*callback_fn)(void *);\n\ncallback_fn ret_callback(void) { return &callback; }\n"
    var rc = bgs_write_fixture(src, c_text, target_name, "noop pointer casts")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-noop-pointer-casts", argv)
    if result.rc != 0: return result.rc
    let out_text = with_fs_read_file(out_w)
    let required: Vec[str] = Vec.new()
    required.push("fn ret_ctx() -> *mut ctx:")
    required.push("return ((&raw mut g as *mut ctx))")
    required.push("var __local_local: *mut ctx = ((&raw mut g as *mut ctx))")
    required.push("(&raw mut g as *mut ctx)")
    required.push("return callback")
    for i in 0..required.len() as i32:
        rc = bgs_migrate_assert_contains(out_text, required.get(i as i64), target_name, "noop_pointer_cast_exprs")
        if rc != 0: return rc
    let forbidden: Vec[str] = Vec.new()
    forbidden.push("extern fn ret_ctx()")
    forbidden.push("as *mut ctx)) as *mut ctx")
    forbidden.push("&raw const callback")
    for i in 0..forbidden.len() as i32:
        rc = bgs_migrate_assert_not_contains(out_text, forbidden.get(i as i64), target_name, "noop_pointer_cast_exprs")
        if rc != 0: return rc
    let check = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-noop-pointer-casts", bgs_argv_append(bgs_argv_append("", "check"), out_w))
    if check.rc != 0: return check.rc
    0

fn bgs_check_migrate_raw_pointer_index(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "raw_pointer_index_unsafe.c")
    let out_w = bgs_resolve_join(case_dir, "raw_pointer_index_unsafe.w")
    var rc = bgs_write_fixture(src, "int issue146_ptr_ops(int *p, int *q) {\n  int *r = p + 1;\n  int d = (int)(q - p);\n  r[0] = r[0] + d;\n  return p[1];\n}\n", target_name, "raw pointer index")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-raw-pointer-index", argv)
    if result.rc != 0: return result.rc
    let out_text = with_fs_read_file(out_w)
    rc = bgs_migrate_assert_contains(out_text, "__param_p +", target_name, "raw_pointer_index_unsafe")
    if rc != 0: return rc
    rc = bgs_migrate_assert_contains(out_text, "(unsafe: __local_r[0])", target_name, "raw_pointer_index_unsafe")
    if rc != 0: return rc
    rc = bgs_migrate_assert_contains(out_text, "(unsafe: __param_p[1])", target_name, "raw_pointer_index_unsafe")
    if rc != 0: return rc
    let check = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-raw-pointer-index", bgs_argv_append(bgs_argv_append("", "check"), out_w))
    if check.rc != 0: return check.rc
    0

fn bgs_check_migrate_prefer_brace_ws(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "prefer_brace_ws.c")
    let out_w = bgs_resolve_join(case_dir, "prefer_brace_ws.w")
    let c_text = "int prefer_brace_ws(int *p) {\n  while (*p != 0) {\n    if (*p < 3) {\n      p++;\n      continue;\n    }\n    p++;\n  }\n  return 0;\n}\n"
    var rc = bgs_write_fixture(src, c_text, target_name, "prefer brace source")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "--prefer-brace")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-prefer-brace-ws", argv)
    if result.rc != 0: return result.rc
    let out_text = with_fs_read_file(out_w)
    rc = bgs_assert_not_matches(out_text, "(?m)[\\t ]$", target_name, "prefer_brace_ws trailing whitespace")
    if rc != 0: return rc
    rc = bgs_assert_matches(out_text, "(?m)^[\\t ]*while\\b[^\\n]*\\{[\\t ]*$", target_name, "prefer_brace_ws while brace")
    if rc != 0: return rc
    rc = bgs_assert_matches(out_text, "(?m)^[\\t ]*if\\b[^\\n]*\\{[\\t ]*$", target_name, "prefer_brace_ws if brace")
    if rc != 0: return rc
    rc = bgs_assert_not_matches(out_text, "(?m)^[\\t ]*(if|while)\\b[^\\n]*:[\\t ]*$", target_name, "prefer_brace_ws colon style")
    if rc != 0: return rc
    let check = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-prefer-brace-ws", bgs_argv_append(bgs_argv_append("", "check"), out_w))
    if check.rc != 0: return check.rc
    0

fn bgs_check_migrate_typed_cast_macros(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    let src = bgs_resolve_join(case_dir, "typed_cast_macros.c")
    let out_w = bgs_resolve_join(case_dir, "typed_cast_macros.w")
    let c_text = "typedef unsigned long usize;\n#define ZERO_TERM ((usize)-1)\n\nint f(usize patlen) {\n  int zero_terminated = 0;\n  if ((zero_terminated = (patlen == ZERO_TERM)))\n    patlen = 7;\n  return zero_terminated + (int)patlen;\n}\n"
    var rc = bgs_write_fixture(src, c_text, target_name, "typed cast macros")
    if rc != 0: return rc
    var argv = ""
    argv = bgs_argv_append(argv, "migrate")
    argv = bgs_argv_append(argv, src)
    argv = bgs_argv_append(argv, "--no-c-export")
    argv = bgs_argv_append(argv, "-o")
    argv = bgs_argv_append(argv, out_w)
    let result = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "migrate-typed-cast-macros", argv)
    if result.rc != 0: return result.rc
    let out_text = with_fs_read_file(out_w)
    rc = bgs_migrate_assert_contains(out_text, "let ZERO_TERM: c_ulong = (-1 as c_ulong)", target_name, "typed_cast_macros")
    if rc != 0: return rc
    rc = bgs_migrate_assert_contains(out_text, "patlen == ((-1 as c_ulong))", target_name, "typed_cast_macros")
    if rc != 0: return rc
    let check = bgs_migrate_expect_success(root, target_name, compiler_path, case_dir, "check-typed-cast-macros", bgs_argv_append(bgs_argv_append("", "check"), out_w))
    if check.rc != 0: return check.rc
    0

pub fn run_cli_selfhost_migrate_core_test(root: str, target_name: str, compiler_path: str) -> i32:
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let base_dir = bgs_resolve_join(bgs_resolve_join(bgs_resolve_join(root, "out/test-graph"), target_name), stamp)
    var rc = bgs_check_migrate_libc_ctype(root, target_name, compiler_path, bgs_resolve_join(base_dir, "libc_ctype"))
    if rc != 0: return rc
    rc = bgs_check_migrate_macro_unsigned_minus(root, target_name, compiler_path, bgs_resolve_join(base_dir, "macro_unsigned_minus"))
    if rc != 0: return rc
    rc = bgs_check_migrate_tentative_global_owner(root, target_name, compiler_path, bgs_resolve_join(base_dir, "tentative_global_owner"))
    if rc != 0: return rc
    rc = bgs_check_migrate_cross_file_tentative_global_owner(root, target_name, compiler_path, bgs_resolve_join(base_dir, "cross_file_tentative_global_owner"))
    if rc != 0: return rc
    rc = bgs_check_migrate_noop_pointer_casts(root, target_name, compiler_path, bgs_resolve_join(base_dir, "noop_pointer_casts"))
    if rc != 0: return rc
    rc = bgs_check_migrate_raw_pointer_index(root, target_name, compiler_path, bgs_resolve_join(base_dir, "raw_pointer_index"))
    if rc != 0: return rc
    rc = bgs_check_migrate_prefer_brace_ws(root, target_name, compiler_path, bgs_resolve_join(base_dir, "prefer_brace_ws"))
    if rc != 0: return rc
    bgs_check_migrate_typed_cast_macros(root, target_name, compiler_path, bgs_resolve_join(base_dir, "typed_cast_macros"))

fn bgs_tool_from_env(env_name: str, fallback: str) -> str:
    let value = with_getenv_str(env_name)
    if value.len() > 0:
        return value
    fallback

fn bgs_nm_smoke(root: str, target_name: str, obj_path: str, label: str) -> i32:
    let capture_dir = bgs_resolve_join(bgs_resolve_join(root, "out/test-graph"), target_name)
    let _mkdir = with_fs_mkdir_p(capture_dir)
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let stdout_path = bgs_resolve_join(capture_dir, label ++ "." ++ stamp ++ ".nm.stdout")
    let stderr_path = bgs_resolve_join(capture_dir, label ++ "." ++ stamp ++ ".nm.stderr")
    var argv = ""
    argv = bgs_argv_append(argv, bgs_tool_from_env("NM", "nm"))
    argv = bgs_argv_append(argv, obj_path)
    let rc = with_exec_argv_capture(argv, stdout_path, stderr_path, 120000)
    if rc != 0:
        with_eprint("error: nm failed for " ++ label)
        return if rc == 0: 1 else: rc
    let _remove_stdout = with_fs_remove_file(stdout_path)
    let _remove_stderr = with_fs_remove_file(stderr_path)
    0

fn bgs_check_build_w_not_ignored(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    var rc = bgs_write_project_manifest(case_dir, "buildwdemo", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "src/main.w"), "fn main:\n    print(\"default main\")\n", target_name, "default main")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "src/custom.w"), "use c_import(\"answer.h\")\n\nfn main:\n    assert(ANSWER == 42)\n    print(\"custom build\")\n", target_name, "custom main")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "extra_include/answer.h"), "#ifndef WITH_BUILD_FEATURE\n#error \"missing build.w target define\"\n#endif\nenum { ANSWER = WITH_BUILD_VALUE };\n", target_name, "answer.h")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    var target = target_new(.Executable, \"custom-build\", \"src/custom.w\")\n    target = target.include_path(\"extra_include\")\n    target = target.define(\"WITH_BUILD_FEATURE\")\n    target = target.define(\"WITH_BUILD_VALUE=42\")\n    target = target.link_system_lib(\"m\")\n    var out = ctx.new_build()\n    out.add_target(target)\n", target_name, "build.w")
    if rc != 0: return rc
    let result = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-not-ignored", bgs_argv_append("", "build"))
    if result.rc != 0: return result.rc
    let custom_bin = bgs_resolve_join(case_dir, "out/bin/custom-build")
    if with_fs_file_exists(custom_bin) == 0:
        with_eprint("error: build_w_not_ignored missing custom-build output")
        return 1
    if with_fs_file_exists(bgs_resolve_join(case_dir, "out/bin/buildwdemo")) != 0:
        with_eprint("error: build_w_not_ignored unexpectedly produced default package output")
        return 1
    let run_result = bgs_run_binary_capture(root, target_name, "build-w-not-ignored-run", custom_bin, 120000)
    if run_result.rc != 0: return run_result.rc
    rc = bgs_assert_contains(run_result.stdout, "custom build", target_name, "build_w_not_ignored")
    if rc != 0: return rc
    let explicit = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-explicit-source", bgs_argv_append(bgs_argv_append("", "build"), bgs_resolve_join(case_dir, "src/main.w")))
    if explicit.rc != 0: return explicit.rc
    0

fn bgs_check_build_w_test_targets(root: str, target_name: str, compiler_path: str, base_dir: str) -> i32:
    let single_dir = bgs_resolve_join(base_dir, "single")
    var rc = bgs_write_project_manifest(single_dir, "buildwtest", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(single_dir, "src/build_test.w"), "use c_import(\"answer.h\")\n\n@[test]\nfn build_w_test_target_uses_settings:\n    assert(ANSWER == 42)\n", target_name, "test source")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(single_dir, "extra_include/answer.h"), "#ifndef WITH_BUILD_FEATURE\n#error \"missing build.w test target define\"\n#endif\nenum { ANSWER = WITH_BUILD_VALUE };\n", target_name, "test header")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(single_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    var target = target_new(.Test, \"configured-test\", \"src/build_test.w\")\n    target = target.include_path(\"extra_include\")\n    target = target.define(\"WITH_BUILD_FEATURE\")\n    target = target.define(\"WITH_BUILD_VALUE=42\")\n    var out = ctx.new_build()\n    out.add_target(target)\n", target_name, "test build.w")
    if rc != 0: return rc
    let single_result = bgs_build_expect_success(root, target_name, compiler_path, single_dir, "build-w-test-target", bgs_argv_append("", "build"))
    if single_result.rc != 0: return single_result.rc
    rc = bgs_assert_contains(single_result.stdout, "ok: 1 test passed", target_name, "build_w_test_target")
    if rc != 0: return rc

    let glob_dir = bgs_resolve_join(base_dir, "glob")
    rc = bgs_write_project_manifest(glob_dir, "buildwtestglob", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(glob_dir, "tests/first.w"), "use c_import(\"answer.h\")\n\n@[test]\nfn first_build_w_glob_test_uses_settings:\n    assert(ANSWER == 42)\n", target_name, "glob first")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(glob_dir, "tests/second.w"), "@[test]\nfn second_build_w_glob_test_runs:\n    assert(2 + 2 == 4)\n", target_name, "glob second")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(glob_dir, "extra_include/answer.h"), "#ifndef WITH_BUILD_FEATURE\n#error \"missing build.w test glob target define\"\n#endif\nenum { ANSWER = WITH_BUILD_VALUE };\n", target_name, "glob header")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(glob_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    var target = target_new(.Test, \"glob-tests\", \"tests/*.w\")\n    target = target.include_path(\"extra_include\")\n    target = target.define(\"WITH_BUILD_FEATURE\")\n    target = target.define(\"WITH_BUILD_VALUE=42\")\n    var out = ctx.new_build()\n    out.add_target(target)\n", target_name, "glob build.w")
    if rc != 0: return rc
    let glob_result = bgs_build_expect_success(root, target_name, compiler_path, glob_dir, "build-w-test-target-glob", bgs_argv_append("", "build"))
    if glob_result.rc != 0: return glob_result.rc
    bgs_assert_contains(glob_result.stdout, "ok: 2 files passed in build.w test target glob-tests", target_name, "build_w_test_target_glob")

fn bgs_check_build_w_library_and_targets(root: str, target_name: str, compiler_path: str, base_dir: str) -> i32:
    let lib_dir = bgs_resolve_join(base_dir, "library")
    var rc = bgs_write_project_manifest(lib_dir, "buildwlib", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(lib_dir, "src/lib.w"), "use c_import(\"answer.h\")\n\npub fn answer_from_header -> i32:\n    ANSWER\n", target_name, "library source")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(lib_dir, "extra_include/answer.h"), "#ifndef WITH_BUILD_FEATURE\n#error \"missing build.w library target define\"\n#endif\nenum { ANSWER = WITH_BUILD_VALUE };\n", target_name, "library header")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(lib_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    var target = target_new(.Library, \"configured\", \"src/lib.w\")\n    target = target.include_path(\"extra_include\")\n    target = target.define(\"WITH_BUILD_FEATURE\")\n    target = target.define(\"WITH_BUILD_VALUE=42\")\n    var out = ctx.new_build()\n    out.add_target(target)\n", target_name, "library build.w")
    if rc != 0: return rc
    let lib_result = bgs_build_expect_success(root, target_name, compiler_path, lib_dir, "build-w-library-target", bgs_argv_append("", "build"))
    if lib_result.rc != 0: return lib_result.rc
    let archive = bgs_resolve_join(lib_dir, "out/lib/libconfigured.a")
    if with_fs_file_exists(archive) == 0:
        with_eprint("error: build_w_library_target missing archive: " ++ archive)
        return 1
    rc = bgs_nm_smoke(root, target_name, archive, "build-w-library-nm")
    if rc != 0: return rc

    let host_dir = bgs_resolve_join(base_dir, "host")
    rc = bgs_write_project_manifest(host_dir, "buildwhosttarget", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(host_dir, "src/main.w"), "fn main:\n    print(\"explicit host target\")\n", target_name, "host source")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(host_dir, "build.w"), "use std.build\nuse std.sysinfo\n\npub fn build(ctx: BuildCtx) -> Build:\n    var host = BuildTarget.native\n    if os() == \"Macos\":\n        if arch() == \"armv8\" or arch() == \"aarch64\":\n            host = BuildTarget.darwin_aarch64\n        else if arch() == \"x86_64\":\n            host = BuildTarget.darwin_x86_64\n    else if os() == \"Linux\":\n        if arch() == \"armv8\" or arch() == \"aarch64\":\n            host = BuildTarget.linux_aarch64\n        else if arch() == \"x86_64\":\n            host = BuildTarget.linux_x86_64\n    else if os() == \"Windows\":\n        if arch() == \"x86_64\":\n            host = BuildTarget.windows_x86_64\n    var target = target_new(.Executable, \"host-target\", \"src/main.w\")\n    target = target.target(host)\n    var out = ctx.new_build()\n    out.add_target(target)\n", target_name, "host build.w")
    if rc != 0: return rc
    let host_result = bgs_build_expect_success(root, target_name, compiler_path, host_dir, "build-w-explicit-host-target", bgs_argv_append("", "build"))
    if host_result.rc != 0: return host_result.rc
    let host_bin = bgs_resolve_join(host_dir, "out/bin/host-target")
    if with_fs_file_exists(host_bin) == 0:
        with_eprint("error: build_w_explicit_host_target missing binary: " ++ host_bin)
        return 1
    let host_run = bgs_run_binary_capture(root, target_name, "build-w-explicit-host-run", host_bin, 120000)
    if host_run.rc != 0: return host_run.rc
    rc = bgs_assert_contains(host_run.stdout, "explicit host target", target_name, "build_w_explicit_host_target")
    if rc != 0: return rc

    let non_native_dir = bgs_resolve_join(base_dir, "non_native")
    rc = bgs_write_project_manifest(non_native_dir, "buildwnonnative", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(non_native_dir, "src/main.w"), "fn main:\n    print(\"wrong target\")\n", target_name, "non-native source")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(non_native_dir, "build.w"), "use std.build\nuse std.sysinfo\n\npub fn build(ctx: BuildCtx) -> Build:\n    var non_native = BuildTarget.linux_x86_64\n    if os() == \"Linux\" and arch() == \"x86_64\":\n        non_native = BuildTarget.darwin_aarch64\n    var target = target_new(.Executable, \"wrong-target\", \"src/main.w\")\n    target = target.target(non_native)\n    var out = ctx.new_build()\n    out.add_target(target)\n", target_name, "non-native build.w")
    if rc != 0: return rc
    let non_native_result = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "build-w-non-native-target", bgs_argv_append("", "build"), 120000, non_native_dir)
    if non_native_result.rc == 0:
        with_eprint("error: build_w_non_native_target unexpectedly succeeded")
        return 1
    bgs_assert_contains(non_native_result.stderr, "build.w cross-target platform", target_name, "build_w_non_native_target")

fn bgs_check_build_w_generated_source(root: str, target_name: str, compiler_path: str, base_dir: str) -> i32:
    let gen_dir = bgs_resolve_join(base_dir, "generated")
    var rc = bgs_write_project_manifest(gen_dir, "buildwgenerated", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(gen_dir, "templates/generated_main.w"), "fn main:\n    print(\"generated source\")\n", target_name, "generated template")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(gen_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    let fs = ctx.fs()\n    let emitter = ctx.source_emitter()\n    let source = emitter.generated_source(\"out/gen/generated_main.w\", fs.read_text(\"templates/generated_main.w\"))\n    var generated = ctx.new_build()\n    generated = generated.add_generated_source(source)\n    generated.executable(\"generated-app\", \"out/gen/generated_main.w\")\n", target_name, "generated build.w")
    if rc != 0: return rc
    let gen_result = bgs_build_expect_success(root, target_name, compiler_path, gen_dir, "build-w-generated-source", bgs_argv_append("", "build"))
    if gen_result.rc != 0: return gen_result.rc
    let generated_source = bgs_resolve_join(gen_dir, "out/gen/generated_main.w")
    let generated_bin = bgs_resolve_join(gen_dir, "out/bin/generated-app")
    if with_fs_file_exists(generated_source) == 0 or with_fs_file_exists(generated_bin) == 0:
        with_eprint("error: build_w_generated_source missing generated source or binary")
        return 1
    let run_result = bgs_run_binary_capture(root, target_name, "build-w-generated-source-run", generated_bin, 120000)
    if run_result.rc != 0: return run_result.rc
    rc = bgs_assert_contains(run_result.stdout, "generated source", target_name, "build_w_generated_source")
    if rc != 0: return rc

    let invalid_dir = bgs_resolve_join(base_dir, "invalid_generated")
    rc = bgs_write_project_manifest(invalid_dir, "buildwinvalidgenerated", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(invalid_dir, "src/main.w"), "fn main:\n    print(\"should not build\")\n", target_name, "invalid generated source")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(invalid_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    var generated = ctx.new_build()\n    generated = generated.generated_source(\"../outside.w\", \"fn main: print(\\\"bad\\\")\\n\")\n    generated.executable(\"invalid-generated\", \"src/main.w\")\n", target_name, "invalid generated build.w")
    if rc != 0: return rc
    let invalid_result = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "build-w-invalid-generated-source", bgs_argv_append("", "build"), 120000, invalid_dir)
    if invalid_result.rc == 0:
        with_eprint("error: build_w_invalid_generated_source unexpectedly succeeded")
        return 1
    rc = bgs_assert_contains(invalid_result.stderr, "invalid build.w generated source path", target_name, "build_w_invalid_generated_source")
    if rc != 0: return rc

    let toolfs_ok_dir = bgs_resolve_join(base_dir, "toolfs_ok")
    rc = bgs_write_project_manifest(toolfs_ok_dir, "buildwtoolfsok", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(toolfs_ok_dir, "src/main.w"), "fn main:\n    print(\"toolfs ok\")\n", target_name, "toolfs ok source")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(toolfs_ok_dir, "fixtures/tree/a.txt"), "tree", target_name, "toolfs ok tree fixture")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(toolfs_ok_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    let fs = ctx.fs()\n    assert(fs.mkdir_all(\"out/toolfs\") == 0)\n    assert(fs.write_text(\"out/toolfs/value.txt\", \"inside\") == 0)\n    assert(fs.read_text(\"out/toolfs/value.txt\") == \"inside\")\n    let files = fs.list_files(\"fixtures/tree\")\n    assert(files.len() == 1)\n    assert(files.get(0) == \"fixtures/tree/a.txt\")\n    assert(fs.copy_tree(\"fixtures/tree\", \"out/toolfs/tree-copy\") == 0)\n    assert(fs.read_text(\"out/toolfs/tree-copy/a.txt\") == \"tree\")\n    assert(fs.symlink(\"fixtures/tree/a.txt\", \"out/toolfs/link-a.txt\") == 0)\n    assert(fs.read_text(\"out/toolfs/link-a.txt\") == \"tree\")\n    assert(fs.remove_tree(\"out/toolfs/tree-copy\") == 0)\n    assert(not fs.exists(\"out/toolfs/tree-copy/a.txt\"))\n    ctx.new_build().executable(\"toolfs-ok\", \"src/main.w\")\n", target_name, "toolfs ok build.w")
    if rc != 0: return rc
    let toolfs_ok = bgs_build_expect_success(root, target_name, compiler_path, toolfs_ok_dir, "build-w-toolfs-ok", bgs_argv_append("", "build"))
    if toolfs_ok.rc != 0: return toolfs_ok.rc
    if with_fs_file_exists(bgs_resolve_join(toolfs_ok_dir, "out/toolfs/value.txt")) == 0:
        with_eprint("error: build_w_toolfs_ok missing sandboxed ToolFs output")
        return 1

    let toolfs_escape_dir = bgs_resolve_join(base_dir, "toolfs_escape")
    rc = bgs_write_project_manifest(toolfs_escape_dir, "buildwtoolfsescape", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(toolfs_escape_dir, "src/main.w"), "fn main:\n    print(\"should not build\")\n", target_name, "toolfs escape source")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(toolfs_escape_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    let _ = ctx.fs().read_text(\"../outside.txt\")\n    ctx.new_build().executable(\"toolfs-escape\", \"src/main.w\")\n", target_name, "toolfs escape build.w")
    if rc != 0: return rc
    let toolfs_escape = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "build-w-toolfs-escape", bgs_argv_append("", "build"), 120000, toolfs_escape_dir)
    if toolfs_escape.rc == 0:
        with_eprint("error: build_w_toolfs_escape unexpectedly succeeded")
        return 1
    rc = bgs_assert_contains(toolfs_escape.stderr, "ToolFs path escapes project root", target_name, "build_w_toolfs_escape")
    if rc != 0: return rc

    let toolfs_tree_escape_dir = bgs_resolve_join(base_dir, "toolfs_tree_escape")
    rc = bgs_write_project_manifest(toolfs_tree_escape_dir, "buildwtoolfstreeescape", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(toolfs_tree_escape_dir, "src/main.w"), "fn main:\n    print(\"should not build\")\n", target_name, "toolfs tree escape source")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(toolfs_tree_escape_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    let _ = ctx.fs().copy_tree(\"../outside\", \"out/bad\")\n    ctx.new_build().executable(\"toolfs-tree-escape\", \"src/main.w\")\n", target_name, "toolfs tree escape build.w")
    if rc != 0: return rc
    let toolfs_tree_escape = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "build-w-toolfs-tree-escape", bgs_argv_append("", "build"), 120000, toolfs_tree_escape_dir)
    if toolfs_tree_escape.rc == 0:
        with_eprint("error: build_w_toolfs_tree_escape unexpectedly succeeded")
        return 1
    bgs_assert_contains(toolfs_tree_escape.stderr, "ToolFs path escapes project root", target_name, "build_w_toolfs_tree_escape")

fn bgs_graph_build_file() -> str:
    "use std.build\n\n" ++
    "pub fn build(ctx: BuildCtx) -> Build:\n" ++
    "    var out = ctx.new_build().executable(\"one\", \"src/one.w\")\n" ++
    "    out = out.executable(\"two\", \"src/two.w\")\n" ++
    "    out = out.object(\"one-o\", \"src/one.w\")\n" ++
    "    out = out.archive(\"one-a\", \"src/one.w\")\n" ++
    "    out = out.generated_source(\"out/tmp/a.txt\", \"same\")\n" ++
    "    out = out.generated_source(\"out/tmp/b.txt\", \"same\")\n" ++
    "    out = out.binary_compare(\"bytes-same\", \"out/tmp/a.txt\", \"out/tmp/b.txt\")\n" ++
    "    out = out.fixpoint_compare(\"fix-same\", \"out/tmp/a.txt\", \"out/tmp/b.txt\")\n" ++
    "    var rsp = target_new(.GenerateResponseFile, \"rsp\", \"\").output(\"out/tmp/args.rsp\")\n" ++
    "    rsp = rsp.arg(\"-L/some path\")\n" ++
    "    rsp = rsp.arg(\"plain\")\n" ++
    "    out = out.add_target(rsp)\n" ++
    "    out = out.compile_c_object(\"helper-o\", \"runtime/helper.c\", \"out/lib/helper.o\")\n" ++
    "    var archive = target_new(.CreateStaticArchive, \"helper-a\", \"\").output(\"out/lib/libhelper.a\")\n" ++
    "    archive = archive.input(\"out/lib/helper.o\")\n" ++
    "    out = out.add_target(archive)\n" ++
    "    var embedded = target_new(.EmbedObjectFiles, \"embed-helper\", \"\").output(\"out/lib/embedded_helper.s\")\n" ++
    "    embedded = embedded.input(\"out/lib/helper.o\")\n" ++
    "    embedded = embedded.arg(\"helper_o\")\n" ++
    "    out = out.add_target(embedded)\n" ++
    "    out = out.compile_asm_object(\"embedded-helper-o\", \"out/lib/embedded_helper.s\", \"out/lib/embedded_helper.o\")\n" ++
    "    out = out.copy_file(\"helper-copy\", \"runtime/helper.c\", \"out/copied/helper.c\")\n" ++
    "    var copy_target = target_new(.CopyTree, \"runtime-copy\", \"runtime\").output(\"out/runtime\")\n" ++
    "    copy_target = copy_target.input(\"helper.c\")\n" ++
    "    out = out.add_target(copy_target)\n" ++
    "    var promote = target_new(.PromoteTreeIfVerified, \"promote-runtime\", \"out/runtime\").output(\"promoted-runtime\")\n" ++
    "    promote = promote.input(\"helper.c\")\n" ++
    "    promote = promote.dep(\"runtime-copy\")\n" ++
    "    out = out.add_target(promote)\n" ++
    "    var corpus = target_new(.RunCorpusTest, \"corpus\", \"out/bin/two\")\n" ++
    "    corpus = corpus.dep(\"two\")\n" ++
    "    out = out.add_target(corpus)\n" ++
    "    var command = target_new(.Command, \"run-two\", \"out/bin/two\")\n" ++
    "    command = command.dep(\"two\")\n" ++
    "    out = out.add_target(command)\n" ++
    "    var install = target_new(.Install, \"install-two\", \"out/bin/two\").output(\"out/install/two\")\n" ++
    "    install = install.dep(\"two\")\n" ++
    "    install = install.arg(\"0755\")\n" ++
    "    out = out.add_target(install)\n" ++
    "    var aggregate = target_new(.Group, \"toolchain\", \"\")\n" ++
    "    aggregate = aggregate.dep(\"bytes-same\")\n" ++
    "    aggregate = aggregate.dep(\"fix-same\")\n" ++
    "    aggregate = aggregate.dep(\"rsp\")\n" ++
    "    aggregate = aggregate.dep(\"one-o\")\n" ++
    "    aggregate = aggregate.dep(\"one-a\")\n" ++
    "    aggregate = aggregate.dep(\"helper-a\")\n" ++
    "    aggregate = aggregate.dep(\"embedded-helper-o\")\n" ++
    "    aggregate = aggregate.dep(\"helper-copy\")\n" ++
    "    aggregate = aggregate.dep(\"promote-runtime\")\n" ++
    "    aggregate = aggregate.dep(\"corpus\")\n" ++
    "    aggregate = aggregate.dep(\"run-two\")\n" ++
    "    aggregate = aggregate.dep(\"install-two\")\n" ++
    "    out = out.add_target(aggregate)\n" ++
    "    out.default(\"toolchain\")\n"

fn bgs_require_case_file(case_dir: str, rel_path: str, target_name: str, label: str) -> i32:
    let path = bgs_resolve_join(case_dir, rel_path)
    if with_fs_file_exists(path) != 0:
        return 0
    with_eprint("error: " ++ target_name ++ " " ++ label ++ " missing expected output: " ++ rel_path)
    1

fn bgs_forbid_case_file(case_dir: str, rel_path: str, target_name: str, label: str) -> i32:
    let path = bgs_resolve_join(case_dir, rel_path)
    if with_fs_file_exists(path) == 0:
        return 0
    with_eprint("error: " ++ target_name ++ " " ++ label ++ " produced unexpected output: " ++ rel_path)
    1

fn bgs_check_build_w_graph_v2(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    var rc = bgs_write_project_manifest(case_dir, "buildwgraphv2", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "src/one.w"), "fn main:\n    print(\"one\")\n", target_name, "graph one")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "src/two.w"), "fn main:\n    print(\"two\")\n", target_name, "graph two")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "runtime/helper.c"), "int helper(void) {\n  return 42;\n}\n", target_name, "graph helper")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "build.w"), bgs_graph_build_file(), target_name, "graph build.w")
    if rc != 0: return rc
    let graph_result = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-graph-v2", bgs_argv_append(bgs_argv_append("", "build"), "--graph"))
    if graph_result.rc != 0: return graph_result.rc
    rc = bgs_assert_contains(graph_result.stdout, "WITH_BUILD_GRAPH\t2", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "default_target\ttoolchain", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "target\t3\tone-o\tsrc/one.w\t0\t0\t", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "target\t4\tone-a\tsrc/one.w\t0\t0\t", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "target\t12\thelper-o\truntime/helper.c\t0\t0\tout/lib/helper.o", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "target\t15\thelper-a\t\t0\t0\tout/lib/libhelper.a", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "target\t17\tembed-helper\t\t0\t0\tout/lib/embedded_helper.s", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "target\t10\tbytes-same\tout/tmp/a.txt\t0\t0\t", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "target\t16\trsp\t\t0\t0\tout/tmp/args.rsp", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "target\t7\trun-two\tout/bin/two\t0\t0\t", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "target\t8\tinstall-two\tout/bin/two\t0\t0\tout/install/two", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_assert_contains(graph_result.stdout, "target\t22\thelper-copy\truntime/helper.c\t0\t0\tout/copied/helper.c", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    let selected = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-graph-selected", bgs_argv_append(bgs_argv_append(bgs_argv_append("", "build"), ":two"), "--graph"))
    if selected.rc != 0: return selected.rc
    rc = bgs_assert_not_contains(selected.stdout, "target\t12\thelper-o", target_name, "build_w_graph_selected")
    if rc != 0: return rc
    let deps = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-graph-deps", bgs_argv_append(bgs_argv_append(bgs_argv_append("", "build"), ":toolchain"), "--graph"))
    if deps.rc != 0: return deps.rc
    rc = bgs_assert_contains(deps.stdout, "target\t12\thelper-o", target_name, "build_w_graph_deps")
    if rc != 0: return rc
    rc = bgs_assert_contains(deps.stdout, "target\t9\ttoolchain\t\t0\t0\t", target_name, "build_w_graph_deps")
    if rc != 0: return rc
    rc = bgs_assert_not_contains(deps.stdout, "target\t0\tone\t", target_name, "build_w_graph_deps")
    if rc != 0: return rc
    let full = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-full-graph", bgs_argv_append("", "build"))
    if full.rc != 0: return full.rc
    rc = bgs_require_case_file(case_dir, "out/obj/one-o.o", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "out/lib/libone-a.a", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "out/lib/helper.o", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "out/lib/libhelper.a", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "out/lib/embedded_helper.s", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "out/lib/embedded_helper.o", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "out/copied/helper.c", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "out/runtime/helper.c", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "promoted-runtime/helper.c", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "out/corpus/corpus/stdout.txt", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "out/command/run-two/stdout.txt", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "out/install/two", target_name, "build_w_graph_v2")
    if rc != 0: return rc
    rc = bgs_expect_file_contains(bgs_resolve_join(case_dir, "out/corpus/corpus/stdout.txt"), "two", target_name, "build_w_graph_corpus")
    if rc != 0: return rc
    rc = bgs_expect_file_contains(bgs_resolve_join(case_dir, "out/command/run-two/stdout.txt"), "two", target_name, "build_w_graph_command")
    if rc != 0: return rc
    rc = bgs_expect_file_contains(bgs_resolve_join(case_dir, "out/lib/embedded_helper.s"), "with_embedded_helper_o_start", target_name, "build_w_graph_embed")
    if rc != 0: return rc
    let _remove_out1 = with_fs_remove_dir(bgs_resolve_join(case_dir, "out"))
    let group = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-group-deps", bgs_argv_append(bgs_argv_append("", "build"), ":toolchain"))
    if group.rc != 0: return group.rc
    rc = bgs_require_case_file(case_dir, "out/bin/two", target_name, "build_w_graph_group")
    if rc != 0: return rc
    rc = bgs_forbid_case_file(case_dir, "out/bin/one", target_name, "build_w_graph_group")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "out/obj/one-o.o", target_name, "build_w_graph_group")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "out/lib/libone-a.a", target_name, "build_w_graph_group")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "out/lib/libhelper.a", target_name, "build_w_graph_group")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "out/copied/helper.c", target_name, "build_w_graph_group")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "out/corpus/corpus/stdout.txt", target_name, "build_w_graph_group")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "out/command/run-two/stdout.txt", target_name, "build_w_graph_group")
    if rc != 0: return rc
    rc = bgs_require_case_file(case_dir, "out/install/two", target_name, "build_w_graph_group")
    if rc != 0: return rc
    let _remove_out2 = with_fs_remove_dir(bgs_resolve_join(case_dir, "out"))
    let bytes = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-binary-compare", bgs_argv_append(bgs_argv_append("", "build"), ":bytes-same"))
    if bytes.rc != 0: return bytes.rc
    let fix = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-fixpoint-compare", bgs_argv_append(bgs_argv_append("", "build"), ":fix-same"))
    if fix.rc != 0: return fix.rc
    let rsp = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-response-file", bgs_argv_append(bgs_argv_append("", "build"), ":rsp"))
    if rsp.rc != 0: return rsp.rc
    let rsp_text = bgs_trim_trailing_line_endings(with_fs_read_file(bgs_resolve_join(case_dir, "out/tmp/args.rsp")))
    if rsp_text != "\"-L/some path\"\n\"plain\"":
        with_eprint("error: build_w_graph_v2 response file contents mismatch: " ++ rsp_text)
        return 1
    let _remove_out3 = with_fs_remove_dir(bgs_resolve_join(case_dir, "out"))
    let two = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-target-select", bgs_argv_append(bgs_argv_append("", "build"), ":two"))
    if two.rc != 0: return two.rc
    if with_fs_file_exists(bgs_resolve_join(case_dir, "out/bin/two")) == 0 or with_fs_file_exists(bgs_resolve_join(case_dir, "out/bin/one")) != 0:
        with_eprint("error: build_w_graph_v2 target selection outputs were wrong")
        return 1
    0

fn bgs_check_removed_build_kind_diagnostic(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    var rc = bgs_write_project_manifest(case_dir, "removedkind", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "src/main.w"), "fn main:\n    print(\"unused\")\n", target_name, "removed kind source")
    if rc != 0: return rc
    let build_text =
        "use std.build\n\n" ++
        "fn removed_kind() -> BuildKind: 5 as BuildKind\n\n" ++
        "pub fn build(ctx: BuildCtx) -> Build:\n" ++
        "    var out = ctx.new_build()\n" ++
        "    out = out.add_target(target_new(removed_kind(), \"old-generated-source\", \"\"))\n" ++
        "    out.default(\"old-generated-source\")\n"
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "build.w"), build_text, target_name, "removed kind build.w")
    if rc != 0: return rc
    let result = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "build-w-removed-kind", bgs_argv_append("", "build"), 120000, case_dir)
    if result.rc == 0:
        with_eprint("error: build_w_removed_kind unexpectedly succeeded")
        return 1
    rc = bgs_assert_contains(result.stderr, "removed_generated_source", target_name, "build_w_removed_kind")
    if rc != 0: return rc
    bgs_assert_contains(result.stderr, "regenerate your build graph", target_name, "build_w_removed_kind")

fn bgs_check_build_w_action_target(root: str, target_name: str, compiler_path: str, case_dir: str) -> i32:
    var rc = bgs_write_project_manifest(case_dir, "buildwaction", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "src/main.w"), "fn main:\n    print(\"unused\")\n", target_name, "action source")
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "src/input.txt"), "input", target_name, "action input")
    if rc != 0: return rc
    let build_text =
        "use std.build\n\n" ++
        "fn generate(ctx: ActionCtx) -> i32:\n" ++
        "    assert(ctx.target_name() == \"generate\")\n" ++
        "    assert(ctx.project_info().package_name() == \"buildwaction\")\n" ++
        "    assert(ctx.inputs().get(0) == \"src/input.txt\")\n" ++
        "    assert(ctx.args().get(0) == \"hello\")\n" ++
        "    assert(ctx.fs().read_text(ctx.inputs().get(0)) == \"input\")\n" ++
        "    assert(ctx.fs().mkdir_all(\"out/action\") == 0)\n" ++
        "    assert(ctx.fs().write_text(ctx.output(), \"action:\" ++ ctx.args().get(0)) == 0)\n" ++
        "    assert(ctx.fs().write_text(ctx.outputs().get(1), \"extra:\" ++ ctx.args().get(0)) == 0)\n" ++
        "    0\n\n" ++
        "pub fn build(ctx: BuildCtx) -> Build:\n" ++
        "    var out = ctx.new_build()\n" ++
        "    var generate_target = target_new(.Action, \"generate\", \"\").output(\"out/action/value.txt\")\n" ++
        "    generate_target = generate_target.extra_output(\"out/action/extra.txt\")\n" ++
        "    generate_target = generate_target.input(\"src/input.txt\")\n" ++
        "    generate_target = generate_target.arg(\"hello\")\n" ++
        "    generate_target.action = generate\n" ++
        "    out = out.add_target(generate_target)\n" ++
        "    var all = target_new(.Group, \"all\", \"\")\n" ++
        "    all = all.dep(\"generate\")\n" ++
        "    out = out.add_target(all)\n" ++
        "    out.default(\"all\")\n"
    rc = bgs_write_fixture(bgs_resolve_join(case_dir, "build.w"), build_text, target_name, "action build.w")
    if rc != 0: return rc
    let result = bgs_build_expect_success(root, target_name, compiler_path, case_dir, "build-w-action-target", bgs_argv_append("", "build"))
    if result.rc != 0: return result.rc
    rc = bgs_expect_file_contains(bgs_resolve_join(case_dir, "out/action/value.txt"), "action:hello", target_name, "build_w_action_target")
    if rc != 0: return rc
    bgs_expect_file_contains(bgs_resolve_join(case_dir, "out/action/extra.txt"), "extra:hello", target_name, "build_w_action_extra_output")

fn bgs_check_build_w_action_failures(root: str, target_name: str, compiler_path: str, base_dir: str) -> i32:
    let missing_dir = bgs_resolve_join(base_dir, "missing_input")
    var rc = bgs_write_project_manifest(missing_dir, "actionmissing", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(missing_dir, "src/main.w"), "fn main:\n    print(\"unused\")\n", target_name, "action missing source")
    if rc != 0: return rc
    let missing_build =
        "use std.build\n\n" ++
        "fn generate(ctx: ActionCtx) -> i32:\n" ++
        "    assert(ctx.fs().write_text(ctx.output(), \"should not run\") == 0)\n" ++
        "    0\n\n" ++
        "pub fn build(ctx: BuildCtx) -> Build:\n" ++
        "    var out = ctx.new_build()\n" ++
        "    var target = target_new(.Action, \"generate\", \"\").output(\"out/action/value.txt\")\n" ++
        "    target = target.input(\"src/missing.txt\")\n" ++
        "    target.action = generate\n" ++
        "    out = out.add_target(target)\n" ++
        "    out.default(\"generate\")\n"
    rc = bgs_write_fixture(bgs_resolve_join(missing_dir, "build.w"), missing_build, target_name, "action missing build.w")
    if rc != 0: return rc
    let missing = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "build-w-action-missing-input", bgs_argv_append("", "build"), 120000, missing_dir)
    if missing.rc == 0:
        with_eprint("error: build_w_action_missing_input unexpectedly succeeded")
        return 1
    rc = bgs_assert_contains(missing.stderr, "missing declared input", target_name, "build_w_action_missing_input")
    if rc != 0: return rc

    let failure_dir = bgs_resolve_join(base_dir, "failure")
    rc = bgs_write_project_manifest(failure_dir, "actionfailure", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(failure_dir, "src/main.w"), "fn main:\n    print(\"unused\")\n", target_name, "action failure source")
    if rc != 0: return rc
    let failure_build =
        "use std.build\n\n" ++
        "fn fail_action(ctx: ActionCtx) -> i32:\n" ++
        "    7\n\n" ++
        "pub fn build(ctx: BuildCtx) -> Build:\n" ++
        "    var out = ctx.new_build()\n" ++
        "    var target = target_new(.Action, \"fail\", \"\").output(\"out/action/value.txt\")\n" ++
        "    target.action = fail_action\n" ++
        "    out = out.add_target(target)\n" ++
        "    out.default(\"fail\")\n"
    rc = bgs_write_fixture(bgs_resolve_join(failure_dir, "build.w"), failure_build, target_name, "action failure build.w")
    if rc != 0: return rc
    let failure = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "build-w-action-failure", bgs_argv_append("", "build"), 120000, failure_dir)
    if failure.rc == 0:
        with_eprint("error: build_w_action_failure unexpectedly succeeded")
        return 1
    rc = bgs_assert_contains(failure.stderr, "failed with exit code 7", target_name, "build_w_action_failure")
    if rc != 0: return rc

    let undeclared_dir = bgs_resolve_join(base_dir, "undeclared_output")
    rc = bgs_write_project_manifest(undeclared_dir, "actionundeclared", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(undeclared_dir, "src/main.w"), "fn main:\n    print(\"unused\")\n", target_name, "action undeclared source")
    if rc != 0: return rc
    let undeclared_build =
        "use std.build\n\n" ++
        "fn bad_write(ctx: ActionCtx) -> i32:\n" ++
        "    assert(ctx.fs().write_text(\"out/action/other.txt\", \"bad\") == 0)\n" ++
        "    0\n\n" ++
        "pub fn build(ctx: BuildCtx) -> Build:\n" ++
        "    var out = ctx.new_build()\n" ++
        "    var target = target_new(.Action, \"bad-write\", \"\").output(\"out/action/value.txt\")\n" ++
        "    target.action = bad_write\n" ++
        "    out = out.add_target(target)\n" ++
        "    out.default(\"bad-write\")\n"
    rc = bgs_write_fixture(bgs_resolve_join(undeclared_dir, "build.w"), undeclared_build, target_name, "action undeclared build.w")
    if rc != 0: return rc
    let undeclared = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "build-w-action-undeclared-output", bgs_argv_append("", "build"), 120000, undeclared_dir)
    if undeclared.rc == 0:
        with_eprint("error: build_w_action_undeclared_output unexpectedly succeeded")
        return 1
    rc = bgs_assert_contains(undeclared.stderr, "not a declared action output", target_name, "build_w_action_undeclared_output")
    if rc != 0: return rc

    let escape_dir = bgs_resolve_join(base_dir, "escape_output")
    rc = bgs_write_project_manifest(escape_dir, "actionescape", target_name)
    if rc != 0: return rc
    rc = bgs_write_fixture(bgs_resolve_join(escape_dir, "src/main.w"), "fn main:\n    print(\"unused\")\n", target_name, "action escape source")
    if rc != 0: return rc
    let escape_build =
        "use std.build\n\n" ++
        "fn bad_escape(ctx: ActionCtx) -> i32:\n" ++
        "    assert(ctx.fs().write_text(\"../outside.txt\", \"bad\") == 0)\n" ++
        "    0\n\n" ++
        "pub fn build(ctx: BuildCtx) -> Build:\n" ++
        "    var out = ctx.new_build()\n" ++
        "    var target = target_new(.Action, \"bad-escape\", \"\").output(\"out/action/value.txt\")\n" ++
        "    target.action = bad_escape\n" ++
        "    out = out.add_target(target)\n" ++
        "    out.default(\"bad-escape\")\n"
    rc = bgs_write_fixture(bgs_resolve_join(escape_dir, "build.w"), escape_build, target_name, "action escape build.w")
    if rc != 0: return rc
    let escape = bgs_run_cli_capture_cwd(root, target_name, compiler_path, "build-w-action-escape-output", bgs_argv_append("", "build"), 120000, escape_dir)
    if escape.rc == 0:
        with_eprint("error: build_w_action_escape_output unexpectedly succeeded")
        return 1
    rc = bgs_assert_contains(escape.stderr, "ToolFs path escapes project root", target_name, "build_w_action_escape_output")
    if rc != 0: return rc

    0

pub fn run_cli_selfhost_build_w_test(root: str, target_name: str, compiler_path: str) -> i32:
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let base_dir = bgs_resolve_join(bgs_resolve_join(bgs_resolve_join(root, "out/test-graph"), target_name), stamp)
    var rc = bgs_check_build_w_not_ignored(root, target_name, compiler_path, bgs_resolve_join(base_dir, "not_ignored"))
    if rc != 0: return rc
    rc = bgs_check_build_w_test_targets(root, target_name, compiler_path, base_dir)
    if rc != 0: return rc
    rc = bgs_check_build_w_library_and_targets(root, target_name, compiler_path, base_dir)
    if rc != 0: return rc
    rc = bgs_check_build_w_generated_source(root, target_name, compiler_path, base_dir)
    if rc != 0: return rc
    rc = bgs_check_build_w_graph_v2(root, target_name, compiler_path, bgs_resolve_join(base_dir, "graph_v2"))
    if rc != 0: return rc
    rc = bgs_check_removed_build_kind_diagnostic(root, target_name, compiler_path, bgs_resolve_join(base_dir, "removed_kind"))
    if rc != 0: return rc
    rc = bgs_check_build_w_action_target(root, target_name, compiler_path, bgs_resolve_join(base_dir, "action"))
    if rc != 0: return rc
    bgs_check_build_w_action_failures(root, target_name, compiler_path, bgs_resolve_join(base_dir, "action_failures"))
