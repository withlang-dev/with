use compiler.ConanClient

let no_body = "def build(self):\n    pass\n"
let r1 = conan_extract_recipe_link_metadata(no_body, "Linux")
print("nobody-libs=" ++ f"{r1.libs.len()}")
print("nobody-args=" ++ f"{r1.lib_paths.len()}")

let nested = "def package_info(self):\n    self.cpp_info.system_libs = [\"m\"]\n    if self.settings.os == \"Linux\":\n        if self.settings.arch == \"x86_64\":\n            self.cpp_info.system_libs.append(\"dl\")\n        else:\n            self.cpp_info.system_libs.append(\"other-arch\")\n"
let r2 = conan_extract_recipe_link_metadata(nested, "Linux")
print("nested-n=" ++ f"{r2.libs.len()}")
for i in 0..r2.libs.len() as i32:
    print("nested-lib=" ++ r2.libs.get(i as i64))

let cond_expr = "def package_info(self):\n    self.cpp_info.system_libs = [\"m\"] if self.options.shared else [\"c\"]\n"
let r3 = conan_extract_recipe_link_metadata(cond_expr, "Linux")
print("condexpr-n=" ++ f"{r3.libs.len()}")
for i in 0..r3.libs.len() as i32:
    print("condexpr-lib=" ++ r3.libs.get(i as i64))
