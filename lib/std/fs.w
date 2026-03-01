// std.fs — Filesystem utility functions
//
// Provides file and directory operations wrapping C stdlib functions.

use c_import("stdio.h")
use c_import("stdlib.h")
use c_import("unistd.h")
use c_import("sys/stat.h")

extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_fs_read_file(path: str) -> str

// Check if a file exists at the given path
pub fn file_exists(path: str) -> bool:
    access(path, 0) == 0

// Remove a file
pub fn remove_file(path: str) -> i32:
    remove(path)

// Rename/move a file
pub fn rename_file(old_path: str, new_path: str) -> i32:
    rename(old_path, new_path)

// Create a directory (mode 0755). Returns 0 on success.
pub fn create_dir(path: str) -> i32:
    let mode_i = 493
    let mode = mode_i as u16
    mkdir(path, mode)

// Remove an empty directory. Returns 0 on success.
pub fn remove_dir(path: str) -> i32:
    rmdir(path)

// Write full text to a file (returns 0 on success)
pub fn write_file(path: str, data: str) -> i32:
    with_fs_write_file(path, data)

// Read full file text (returns "" on failure)
pub fn read_file(path: str) -> str:
    with_fs_read_file(path)
