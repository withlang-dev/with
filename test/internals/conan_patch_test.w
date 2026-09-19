//! expect-stdout: ok
use compiler.ConanPatch
use std.fs

fn read_text(path: &str) -> str: read_file(path) ?? ""

fn write_text(path: &str, text: &str) -> i32: write_file(path, text)

fn main:
    let root = "out/tmp/conan_patch_test"
    assert(mkdir_p(root ++ "/src") == 0)
    assert(write_text(root ++ "/src/a.c", "one\ntwo\nthree\nfour\nfive\nsix\nseven\n") == 0)
    assert(write_text(root ++ "/CMakeLists.txt", "project(x)\r\nadd_library(x a.c)\r\n") == 0)
    // Two hunks; the second's stated line is off by the first's growth and by
    // two more, so it has to be located. A CRLF file. A new file.
    let patch = "diff --git a/src/a.c b/src/a.c\n--- a/src/a.c\n+++ b/src/a.c\n@@ -1,3 +1,4 @@\n one\n-two\n+TWO\n+two and a half\n three\n@@ -9,2 +10,2 @@\n six\n-seven\n+SEVEN\n--- a/CMakeLists.txt\t2024-01-01\n+++ b/CMakeLists.txt\t2024-01-02\n@@ -1,2 +1,3 @@\n project(x)\n+option(X_TESTS \"\" OFF)\n add_library(x a.c)\n--- /dev/null\n+++ b/src/new.h\n@@ -0,0 +1,2 @@\n+#pragma once\n+int x(void);\n"
    assert(conan_apply_patch(patch, root, read_text, write_text) == "")
    assert(read_text(root ++ "/src/a.c") == "one\nTWO\ntwo and a half\nthree\nfour\nfive\nsix\nSEVEN\n")
    assert(read_text(root ++ "/CMakeLists.txt") == "project(x)\noption(X_TESTS \"\" OFF)\nadd_library(x a.c)\n")
    assert(read_text(root ++ "/src/new.h") == "#pragma once\nint x(void);\n")
    // Context that is not there is an error naming the file and the hunk.
    let stale = "--- a/src/a.c\n+++ b/src/a.c\n@@ -1,2 +1,2 @@\n one\n-two\n+2\n"
    assert(conan_apply_patch(stale, root, read_text, write_text) == "hunk 1 of the patch does not apply to src/a.c")
    assert(conan_apply_patch("--- a/nope.c\n+++ b/nope.c\n@@ -1 +1 @@\n-x\n+y\n", root, read_text, write_text) == "patch targets nope.c, which is not in the source")
    print("ok")
