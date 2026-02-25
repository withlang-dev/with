// std.fs — Filesystem utility functions
//
// Provides file and directory operations wrapping C stdlib functions.

use c_import("#include <stdio.h>\n#include <stdlib.h>\n#include <unistd.h>")

extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_fs_read_file(path: str) -> str

// Check if a file exists at the given path
pub fn file_exists(path: str) -> bool =
    access(path, 0) == 0

// Remove a file
pub fn remove_file(path: str) -> i32 =
    remove(path)

// Rename/move a file
pub fn rename_file(old_path: str, new_path: str) -> i32 =
    rename(old_path, new_path)

// Write full text to a file (returns 0 on success)
pub fn write_file(path: str, data: str) -> i32 =
    with_fs_write_file(path, data)

// Read full file text (returns "" on failure)
pub fn read_file(path: str) -> str =
    with_fs_read_file(path)
