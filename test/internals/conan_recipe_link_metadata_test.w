//! expect-stdout: ok

use compiler.ConanClient

// Real-world shape (libcurl): components, os-membership lists, elif
// chains, is_apple_os, append/extend, and option-guarded lines that the
// reader must skip rather than guess.
fn recipe_fixture() -> str:
    "class LibcurlConan:\n" ++
    "    def package_info(self):\n" ++
    "        self.cpp_info.set_property(\"pkg_config_name\", \"libcurl\")\n" ++
    "        self.cpp_info.components[\"curl\"].resdirs = [\"res\"]\n" ++
    "        if is_msvc(self):\n" ++
    "            self.cpp_info.components[\"curl\"].libs = [\"libcurl_imp\"] if self.options.shared else [\"libcurl\"]\n" ++
    "        else:\n" ++
    "            self.cpp_info.components[\"curl\"].libs = [\"curl\"]\n" ++
    "        if self.settings.os in [\"Linux\", \"FreeBSD\"]:\n" ++
    "            self.cpp_info.components[\"curl\"].system_libs = [\"rt\", \"pthread\"]\n" ++
    "        elif self.settings.os == \"Windows\":\n" ++
    "            self.cpp_info.components[\"curl\"].system_libs = [\"ws2_32\", \"bcrypt\", \"iphlpapi\"]\n" ++
    "            if self.options.with_ldap:\n" ++
    "                self.cpp_info.components[\"curl\"].system_libs.append(\"wldap32\")\n" ++
    "        elif is_apple_os(self):\n" ++
    "            self.cpp_info.components[\"curl\"].frameworks.append(\"CoreFoundation\")\n" ++
    "            self.cpp_info.components[\"curl\"].frameworks.append(\"CoreServices\")\n" ++
    "            self.cpp_info.components[\"curl\"].frameworks.extend([\"SystemConfiguration\"])\n" ++
    "            if self.options.get_safe(\"with_apple_sectrust\"):\n" ++
    "                self.cpp_info.components[\"curl\"].frameworks.append(\"Security\")\n" ++
    "\n" ++
    "    def package_id(self):\n" ++
    "        self.cpp_info.components[\"curl\"].system_libs = [\"never_seen\"]\n"

fn vec_has(values: &Vec[str], value: str) -> bool:
    for i in 0..values.len() as i32:
        if values.get(i as i64) == value:
            return true
    false

fn main:
    let mac = conan_extract_recipe_link_metadata(recipe_fixture(), "Macos")
    assert(mac.libs.len() == 0)
    assert(mac.lib_paths.len() == 6)
    assert(mac.lib_paths.get(0) == "-framework")
    assert(vec_has(&mac.lib_paths, "CoreFoundation"))
    assert(vec_has(&mac.lib_paths, "CoreServices"))
    assert(vec_has(&mac.lib_paths, "SystemConfiguration"))
    // Option-guarded Security must be skipped, never guessed.
    assert(not vec_has(&mac.lib_paths, "Security"))

    let linux = conan_extract_recipe_link_metadata(recipe_fixture(), "Linux")
    assert(vec_has(&linux.libs, "rt"))
    assert(vec_has(&linux.libs, "pthread"))
    assert(linux.lib_paths.len() == 0)

    let windows = conan_extract_recipe_link_metadata(recipe_fixture(), "Windows")
    assert(vec_has(&windows.libs, "ws2_32"))
    assert(vec_has(&windows.libs, "bcrypt"))
    assert(vec_has(&windows.libs, "iphlpapi"))
    // Option-guarded wldap32 must be skipped.
    assert(not vec_has(&windows.libs, "wldap32"))
    // Declarations outside package_info are ignored.
    assert(not vec_has(&windows.libs, "never_seen"))

    print("ok")
