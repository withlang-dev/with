// std.fs — Filesystem utility functions
//
// Provides file and directory operations via the runtime interface.
// No c_import — all operations go through with_fs_* runtime functions
// which are backed by rt_* platform calls.

extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_fs_remove_file(path: str) -> i32
extern fn with_fs_rename_file(old_path: str, new_path: str) -> i32
extern fn with_fs_create_dir(path: str) -> i32
extern fn with_fs_remove_dir(path: str) -> i32
extern fn with_fs_remove_tree(path: str) -> i32
extern fn with_fs_copy_tree(src: str, dst: str) -> i32
extern fn with_fs_symlink(target: str, link_path: str) -> i32
extern fn with_fs_list_files(path: str) -> str
extern fn with_fs_mkdir_p(path: str) -> i32

/// Check if a file exists at the given path.
pub fn file_exists(path: str) -> bool:
    with_fs_file_exists(path) != 0

/// Remove a file. Returns 0 on success.
pub fn remove_file(path: str) -> i32:
    with_fs_remove_file(path)

/// Rename or move a file. Returns 0 on success.
pub fn rename_file(old_path: str, new_path: str) -> i32:
    with_fs_rename_file(old_path, new_path)

/// Create a directory (mode 0755). Returns 0 on success.
pub fn create_dir(path: str) -> i32:
    with_fs_create_dir(path)

/// Remove an empty directory. Returns 0 on success.
pub fn remove_dir(path: str) -> i32:
    with_fs_remove_dir(path)

/// Remove a file or directory tree recursively. Returns 0 on success.
pub fn remove_tree(path: str) -> i32:
    with_fs_remove_tree(path)

/// Copy a file or directory tree recursively. Returns 0 on success.
pub fn copy_tree(src: str, dst: str) -> i32:
    with_fs_copy_tree(src, dst)

/// Create a symbolic link. Returns 0 on success.
pub fn symlink(target: str, link_path: str) -> i32:
    with_fs_symlink(target, link_path)

/// List files recursively under a path as newline-separated paths.
pub fn list_files_text(path: str) -> str:
    with_fs_list_files(path)

/// Write a string to a file, replacing its contents. Returns 0 on success.
pub fn write_file(path: str, data: str) -> i32:
    with_fs_write_file(path, data)

/// Read an entire file as a string. Returns "" on failure.
pub fn read_file(path: str) -> str:
    with_fs_read_file(path)

/// Create directories recursively (like mkdir -p). Returns 0 on success.
pub fn mkdir_p(path: str) -> i32:
    with_fs_mkdir_p(path)
