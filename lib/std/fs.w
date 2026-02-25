// std.fs — Filesystem utility functions
//
// Provides file and directory operations wrapping C stdlib functions.

use c_import("#include <stdio.h>\n#include <stdlib.h>\n#include <unistd.h>")

// Check if a file exists at the given path
pub fn file_exists(path: str) -> bool =
    access(path, 0) == 0

// Remove a file
pub fn remove_file(path: str) -> i32 =
    remove(path)

// Rename/move a file
pub fn rename_file(old_path: str, new_path: str) -> i32 =
    rename(old_path, new_path)
