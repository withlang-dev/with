use std.fs

fn main -> i32:
    // roundtrip
    let wrc = write_file("/tmp/with_audit_fs_probe.txt", "hello-fs")
    print("write rc=" ++ wrc.to_string())
    let back = read_file("/tmp/with_audit_fs_probe.txt")
    print("read back=[" ++ back ++ "]")
    // missing file
    let miss = read_file("/tmp/with_audit_fs_NOPE_missing.txt")
    print("missing read len=" ++ miss.len().to_string() ++ " eq_empty=" ++ (miss == "").to_string())
    print("exists real=" ++ file_exists("/tmp/with_audit_fs_probe.txt").to_string())
    print("exists missing=" ++ file_exists("/tmp/with_audit_fs_NOPE_missing.txt").to_string())
    // write to bad path
    let badw = write_file("/tmp/with_audit_NOPE_dir_xyz/file.txt", "x")
    print("bad write rc=" ++ badw.to_string())
    // list missing dir
    let lst = list_files_text("/tmp/with_audit_NOPE_dir_xyz")
    print("list missing len=" ++ lst.len().to_string())
    // mkdir_p + remove_tree roundtrip
    let mk = mkdir_p("/tmp/with_audit_fs_tree/a/b")
    print("mkdir_p rc=" ++ mk.to_string())
    let w2 = write_file("/tmp/with_audit_fs_tree/a/b/f.txt", "data")
    print("nested write rc=" ++ w2.to_string())
    let lst2 = list_files_text("/tmp/with_audit_fs_tree")
    print("list tree len=" ++ lst2.len().to_string())
    print("list tree=[" ++ lst2 ++ "]")
    let rm = remove_tree("/tmp/with_audit_fs_tree")
    print("remove_tree rc=" ++ rm.to_string())
    let rm_missing = remove_file("/tmp/with_audit_fs_NOPE_missing.txt")
    print("remove missing rc=" ++ rm_missing.to_string())
    let rmdir_missing = remove_dir("/tmp/with_audit_NOPE_dir_xyz")
    print("remove_dir missing rc=" ++ rmdir_missing.to_string())
    let rn_missing = rename_file("/tmp/with_audit_fs_NOPE_missing.txt", "/tmp/with_audit_fs_probe2.txt")
    print("rename missing rc=" ++ rn_missing.to_string())
    let cp_missing = copy_tree("/tmp/with_audit_fs_NOPE_missing.txt", "/tmp/with_audit_fs_copy.txt")
    print("copy missing rc=" ++ cp_missing.to_string())
    let cp = copy_tree("/tmp/with_audit_fs_probe.txt", "/tmp/with_audit_fs_copy.txt")
    print("copy real rc=" ++ cp.to_string())
    print("copy exists=" ++ file_exists("/tmp/with_audit_fs_copy.txt").to_string())
    let rn = rename_file("/tmp/with_audit_fs_copy.txt", "/tmp/with_audit_fs_moved.txt")
    print("rename real rc=" ++ rn.to_string())
    let cl = remove_file("/tmp/with_audit_fs_probe.txt")
    let cl2 = remove_file("/tmp/with_audit_fs_moved.txt")
    print("cleanup rc=" ++ cl.to_string() ++ "," ++ cl2.to_string())
    0
