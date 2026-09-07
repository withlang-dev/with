use compiler.ConanClient

let recipe = "def package_info(self):\n    self.cpp_info.system_libs = [\"m\", \"pthread\"]\n    if self.settings.os == \"Linux\":\n        self.cpp_info.system_libs.append(\"dl\")\n    elif self.settings.os == \"Windows\":\n        self.cpp_info.system_libs.append(\"winmm\")\n    else:\n        self.cpp_info.system_libs.append(\"other\")\n"

let linux = conan_extract_recipe_link_metadata(recipe, "Linux")
print("linux-n=" ++ f"{linux.libs.len()}")
for i in 0..linux.libs.len() as i32:
    print("linux-lib=" ++ linux.libs.get(i as i64))

let windows = conan_extract_recipe_link_metadata(recipe, "Windows")
print("windows-n=" ++ f"{windows.libs.len()}")
for i in 0..windows.libs.len() as i32:
    print("windows-lib=" ++ windows.libs.get(i as i64))

let macos = conan_extract_recipe_link_metadata(recipe, "Macos")
print("macos-n=" ++ f"{macos.libs.len()}")
for i in 0..macos.libs.len() as i32:
    print("macos-lib=" ++ macos.libs.get(i as i64))

let fw_recipe = "def package_info(self):\n    if self.settings.os == \"Macos\":\n        self.cpp_info.frameworks.append(\"Cocoa\")\n"
let fw = conan_extract_recipe_link_metadata(fw_recipe, "Macos")
print("fw-args-n=" ++ f"{fw.lib_paths.len()}")
for i in 0..fw.lib_paths.len() as i32:
    print("fw-arg=" ++ fw.lib_paths.get(i as i64))
print("fw-libs-n=" ++ f"{fw.libs.len()}")

let unknown_recipe = "def package_info(self):\n    self.cpp_info.system_libs = [\"m\"]\n    if self.options.shared:\n        self.cpp_info.system_libs.append(\"dl\")\n"
let unk = conan_extract_recipe_link_metadata(unknown_recipe, "Linux")
print("unknown-n=" ++ f"{unk.libs.len()}")
for i in 0..unk.libs.len() as i32:
    print("unknown-lib=" ++ unk.libs.get(i as i64))

print("sys-opengl=" ++ f"{conan_write_known_system_package("opengl", "system", "/tmp/conan_audit_root")}")
print("sys-xorg=" ++ f"{conan_write_known_system_package("xorg", "system", "/tmp/conan_audit_root")}")
print("sys-neg-version=" ++ f"{conan_write_known_system_package("opengl", "1.0", "/tmp/conan_audit_root")}")
print("sys-neg-name=" ++ f"{conan_write_known_system_package("zlib", "system", "/tmp/conan_audit_root")}")
