//! expect-stdout: ok

use compiler.RecipeInterp

// A recipe's `package_info` is evaluated, not matched: this one is written
// the way Conan Center's are (SDL, pulseaudio, openssl, libffi, glfw), with
// the Python they use — options built by dict unpacking and a comprehension
// over a module-level list, class-body statements that edit the defaults, a
// helper property and a helper method of the recipe's own, `str.format`, an
// f-string over `Version`, a `for` over tuples, lists that grow by `append`,
// `extend` and `+=`, and a list written over several lines with a comment in
// it. One method is not valid Python at all; it costs only itself.

fn demo_recipe() -> str:
    "from conan import ConanFile\n" ++
    "from conan.tools.apple import is_apple_os\n" ++
    "from conan.tools.microsoft import is_msvc\n" ++
    "from conan.tools.scm import Version\n" ++
    "import os\n" ++
    "\n" ++
    "_subsystems = [\n" ++
    "    (\"audio\", [\"CoreAudio\", \"AudioToolbox\"]),\n" ++
    "    (\"video\", [\"Cocoa\"]),\n" ++
    "]\n" ++
    "\n" ++
    "class DemoConan(ConanFile):\n" ++
    "    name = \"demo\"\n" ++
    "    settings = \"os\", \"arch\", \"compiler\", \"build_type\"\n" ++
    "    options = {\n" ++
    "        **{\"shared\": [True, False], \"fPIC\": [True, False]},\n" ++
    "        **{subsystem: [True, False] for subsystem, _ in _subsystems},\n" ++
    "        \"with_ssl\": [False, \"openssl\", \"schannel\"],\n" ++
    "    }\n" ++
    "    default_options = {key: True for key in options.keys()}\n" ++
    "    default_options[\"shared\"] = False\n" ++
    "    default_options[\"with_ssl\"] = \"openssl\"\n" ++
    "\n" ++
    "    @property\n" ++
    "    def _is_mingw(self):\n" ++
    "        return self.settings.os == \"Windows\" and self.settings.compiler == \"gcc\"\n" ++
    "\n" ++
    "    def config_options(self):\n" ++
    "        if self.settings.os == \"Windows\":\n" ++
    "            del self.options.fPIC\n" ++
    "\n" ++
    "    def broken(self):\n" ++
    "        x = 1 if self.options.shared\n" ++
    "        return x\n" ++
    "\n" ++
    "    def _lib_name(self, base):\n" ++
    "        return \"{}{}\".format(\"lib\" if is_msvc(self) else \"\", base)\n" ++
    "\n" ++
    "    def package_info(self):\n" ++
    "        name = self._lib_name(\"demo\")\n" ++
    "        if self.settings.os == \"Windows\" and not self.options.shared:\n" ++
    "            name += \"-static\"\n" ++
    "        self.cpp_info.components[\"core\"].libs = [name]\n" ++
    "        self.cpp_info.components[\"core\"].libdirs.append(os.path.join(\"lib\", \"demo\"))\n" ++
    "        self.cpp_info.components[\"core\"].requires = [\"headers\", \"zlib::zlib\"]\n" ++
    "        self.cpp_info.components[\"headers\"].libdirs = []\n" ++
    "        if self.settings.os in (\"Linux\", \"FreeBSD\"):\n" ++
    "            self.cpp_info.components[\"core\"].system_libs.extend([\"m\", \"pthread\"])\n" ++
    "            if self.settings.os == \"Linux\":\n" ++
    "                self.cpp_info.components[\"core\"].system_libs += [\"rt\"]\n" ++
    "        elif self.settings.os == \"Windows\":\n" ++
    "            self.cpp_info.components[\"core\"].system_libs = [\n" ++
    "                \"kernel32\", \"user32\",  # the usual\n" ++
    "                \"imm32\",\n" ++
    "            ]\n" ++
    "            if self._is_mingw:\n" ++
    "                self.cpp_info.components[\"core\"].system_libs.append(\"mingw32\")\n" ++
    "        if is_apple_os(self) and not self.options.shared:\n" ++
    "            for subsystem, frameworks in _subsystems:\n" ++
    "                if self.options.get_safe(subsystem):\n" ++
    "                    self.cpp_info.components[\"core\"].frameworks.extend(frameworks)\n" ++
    "            self.cpp_info.components[\"core\"].exelinkflags.append(\"-Wl,-weak_framework,CoreHaptics\")\n" ++
    "        if self.options.with_ssl == \"openssl\":\n" ++
    "            self.cpp_info.components[\"core\"].requires.append(\"openssl::ssl\")\n" ++
    "        elif self.options.with_ssl == \"schannel\":\n" ++
    "            self.cpp_info.components[\"core\"].system_libs.extend([\"crypt32\", \"secur32\"])\n" ++
    "        if Version(self.version) >= \"2.0\":\n" ++
    "            self.cpp_info.components[\"extra\"].libs = [f\"demo-extra-{Version(self.version).major}\"]\n" ++
    "            self.cpp_info.components[\"extra\"].requires = [\"core\"]\n" ++
    "        if self.options.fPIC:\n" ++
    "            self.cpp_info.components[\"core\"].defines.append(\"DEMO_PIC\")\n" ++
    "        if self.dependencies[\"zlib\"].options.shared:\n" ++
    "            self.cpp_info.components[\"core\"].defines.append(\"ZLIB_DLL\")\n" ++
    ""

fn env(os: &str, compiler: &str, version: &str, options: List[str], known: bool): RecipeEnv { os: os.to_owned(), arch: "x86_64", compiler: compiler.to_owned(), compiler_version: "13", build_type: "Release", version: version.to_owned(), package_folder: "", source_folder: "", options, options_known: known }

fn options(lines: &str) -> List[str]:
    var out: List[str] = List.new()
    for line in lines.split(" "): out.push(line.to_owned())
    out

fn component(info: &RecipePackageInfo, name: &str) -> i32:
    for i in 0..info.components.len() as i32:
        if info.components[i].name == name: return i
    -1

fn main:
    // A Linux binary, read against the options its conaninfo states.
    let linux = recipe_package_info(demo_recipe(), &env("Linux", "gcc", "2.1", options("shared=False fPIC=True audio=True video=False with_ssl=openssl"), true))
    assert(linux.ok)
    assert(linux.components.len() == 3)
    let core = &linux.components[component(&linux, "core")]
    assert(core.libs.join(",") == "demo")
    assert(core.libdirs.join(",") == "lib,lib/demo")
    assert(core.system_libs.join(",") == "m,pthread,rt")
    assert(core.requires.join(",") == "headers,zlib::zlib,openssl::ssl")
    assert(core.defines.join(",") == "DEMO_PIC")
    assert(core.frameworks.len() == 0)
    assert(linux.components[component(&linux, "headers")].libdirs.len() == 0)
    let extra = &linux.components[component(&linux, "extra")]
    assert(extra.libs.join(",") == "demo-extra-2")
    assert(extra.requires.join(",") == "core")
    // `self.dependencies[...]` is not modeled: that `if` is reported, not guessed.
    assert(linux.notes.len() == 1)
    assert(linux.notes[0].contains("could not be decided"))

    // macOS: the frameworks follow the binary's options, one subsystem off.
    let mac = recipe_package_info(demo_recipe(), &env("Macos", "apple-clang", "1.9", options("shared=False fPIC=True audio=True video=False with_ssl=schannel"), true))
    assert(mac.ok)
    assert(mac.components.len() == 2)
    let mac_core = &mac.components[component(&mac, "core")]
    assert(mac_core.frameworks.join(",") == "CoreAudio,AudioToolbox")
    assert(mac_core.exelinkflags.join(",") == "-Wl,-weak_framework,CoreHaptics")
    assert(mac_core.system_libs.join(",") == "crypt32,secur32")
    assert(mac_core.requires.join(",") == "headers,zlib::zlib")

    // A shared binary states no frameworks.
    let shared = recipe_package_info(demo_recipe(), &env("Macos", "apple-clang", "1.9", options("shared=True fPIC=True audio=True video=True with_ssl=False"), true))
    assert(shared.components[component(&shared, "core")].frameworks.len() == 0)

    // A package built here takes the recipe's defaults, after its own
    // config_options: no fPIC on Windows, so the `if` that reads it is reported.
    let windows = recipe_package_info(demo_recipe(), &env("Windows", "clang", "2.0", List.new(), false))
    assert(windows.ok)
    let win_core = &windows.components[component(&windows, "core")]
    assert(win_core.libs.join(",") == "demo-static")
    assert(win_core.system_libs.join(",") == "kernel32,user32,imm32")
    assert(win_core.requires.join(",") == "headers,zlib::zlib,openssl::ssl")
    assert(win_core.defines.len() == 0)
    var fpic_noted = false
    for n in windows.notes:
        if n.contains("option 'fPIC'"): fpic_noted = true
    assert(fpic_noted)

    // The recipe's own property decides: gcc on Windows is MinGW.
    let mingw = recipe_package_info(demo_recipe(), &env("Windows", "gcc", "2.0", List.new(), false))
    assert(mingw.components[component(&mingw, "core")].system_libs.join(",") == "kernel32,user32,imm32,mingw32")

    // msvc names the library its own way.
    let msvc = recipe_package_info(demo_recipe(), &env("Windows", "msvc", "2.0", options("shared=False audio=True video=True with_ssl=False"), true))
    assert(msvc.components[component(&msvc, "core")].libs.join(",") == "libdemo-static")

    let built = recipe_built_options(demo_recipe(), &env("Windows", "clang", "2.0", List.new(), false)).join(" ")
    assert(built.contains("shared=False"))
    assert(built.contains("audio=True"))
    assert(built.contains("with_ssl=openssl"))
    assert(not built.contains("fPIC"))

    // No package_info, or no recipe at all, is an error and not an empty answer.
    assert(not recipe_package_info("class A(ConanFile):\n    name = \"a\"\n", &env("Linux", "gcc", "1", List.new(), false)).ok)
    assert(not recipe_package_info("x = 1\n", &env("Linux", "gcc", "1", List.new(), false)).ok)
    print("ok")
