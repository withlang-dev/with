//! expect-stdout: ok
use compiler.ConanRecipe
use compiler.RecipeInterp

// conandata.yml is read as data, and what the recipe decides in Python is
// evaluated (compiler.RecipeInterp); nothing is about any
// one package. The shapes are the ones Conan Center's recipes use.
// A dead first mirror, a second that serves the wrong bytes, a third that is right.
fn fake_download(url: &str, path: &str) -> i32: if url.contains("dead"): 1 else: 0

fn fake_digest(path: &str) -> str: if path.contains("good"): "ab5a" else: "ffff"

fn main:
    let data = "sources:\n  \"1.0.8\":\n    url:\n    - \"https://a.invalid/x-1.0.8.tar.gz\"\n    - \"https://mirror.invalid/x-1.0.8.tar.gz\"\n    sha256: \"ab5a\"\n  \"1.0.6\":\n    url: \"https://a.invalid/x-1.0.6.tar.gz\"\n    sha256: \"a284\"\npatches:\n  \"1.0.6\":\n    - patch_file: \"patches/0001-fix.patch\"\n      patch_type: \"portability\"\n    - patch_file: \"patches/0002-more.patch\"\n"
    let newest = conan_data_source(data, "1.0.8")
    // Every mirror, in the recipe's order: the second is tried when the first is down.
    assert(newest.urls.len() == 2 and newest.sha256 == "ab5a")
    assert(newest.urls[0] == "https://a.invalid/x-1.0.8.tar.gz" and newest.urls[1] == "https://mirror.invalid/x-1.0.8.tar.gz")
    let older = conan_data_source(data, "1.0.6")
    assert(older.urls.len() == 1 and older.urls[0] == "https://a.invalid/x-1.0.6.tar.gz")
    assert(conan_data_source(data, "9.9").urls.len() == 0)
    let mirrors = ConanSource { urls: ["https://dead.invalid/x-dead.tgz", "https://stale.invalid/x-stale.tgz", "https://ok.invalid/x-good.tgz"], sha256: "ab5a" }
    let picked = conan_pick_archive(&mirrors, "/w", fake_download, fake_digest)
    assert(picked.path == "/w/x-good.tgz")
    assert(picked.tried.contains("dead.invalid/x-dead.tgz: did not download") and picked.tried.contains("x-stale.tgz: sha256 ffff, the recipe expects ab5a"))
    let none = ConanSource { urls: ["https://dead.invalid/x-dead.tgz"], sha256: "ab5a" }
    assert(conan_pick_archive(&none, "/w", fake_download, fake_digest).path == "")
    // A patch that names where it applies is refused, not applied somewhere else.
    assert(conan_data_patch_problem(data, "1.0.6") == "")
    let placed = data.replace("      patch_type: \"portability\"\n", "      base_path: \"source_subfolder\"\n")
    assert(conan_data_patch_problem(placed, "1.0.6") == "its patches use `base_path: \"source_subfolder\"`, which this build does not apply yet")
    assert(conan_data_patch_problem(placed, "1.0.8") == "")
    assert(conan_data_patches(data, "1.0.8").len() == 0)
    let patches = conan_data_patches(data, "1.0.6")
    assert(patches.len() == 2 and patches[1] == "patches/0002-more.patch")

    let recipe = "class X(ConanFile):\n    default_options = {\n        \"shared\": False,\n        \"fPIC\": True,\n        \"with_ssl\": \"openssl\",\n        \"max_size\": None,          # a comment, with: punctuation\n        \"tools\": True,\n        \"level\": 3,\n    }\n\n    def requirements(self):\n        if self.options.with_ssl == \"openssl\":\n            self.requires(f\"openssl/[>=3 <4]\")\n        elif self.options.with_ssl == \"wolfssl\":\n            self.requires(\"wolfssl/5.6\")\n        else:\n            self.requires(\"never/1.0\")\n        if self.settings.os == \"Linux\" and self.options.tools:\n            self.requires(\"linuxonly/1.0\")\n        if self.options.with_ssl in (\"mbedtls\", \"libressl\"):\n            self.requires(\"other/1.0\")\n        if some_function(self):\n            self.requires(\"undecided/1.0\")\n        self.requires(\"zlib/[>=1.2.11 <2]\")\n\n    def generate(self):\n        tc = CMakeToolchain(self)\n        tc.variables[\"X_SRC_DIR\"] = self.source_folder.replace(\"\\\\\", \"/\")\n        tc.variables[\"X_MAJOR\"] = Version(self.version).major\n        tc.variables[\"X_VERSION\"] = self.version\n        tc.variables[\"X_TOOLS\"] = self.options.tools\n        tc.variables[\"X_STATIC\"] = not self.options.shared\n        tc.variables[\"X_LEVEL\"] = self.options.level\n        tc.variables[\"X_TLS\"] = self.options.with_ssl == \"openssl\"\n        tc.variables[\"X_UNIX\"] = self.settings.os != \"Windows\"\n        tc.variables[\"X_PIC\"] = self.options.get_safe(\"fPIC\", True)\n        tc.variables[\"X_GL\"] = \"OFF\" if not self.options.with_ssl else str(self.options.with_ssl).replace(\"-\", \" \")\n        if self.settings.os == \"Android\":\n            tc.variables[\"X_PLATFORM\"] = \"Android\"\n        elif self.settings.os == \"Windows\":\n            tc.variables[\"X_PLATFORM\"] = \"Win\"\n        else:\n            tc.variables[\"X_PLATFORM\"] = \"Desktop\"\n        tc.variables[\"X_LEVEL\"] = 4\n        tc.cache_variables[\"X_EMPTY\"] = \"\"\n        tc.variables[\"X_MAX\"] = self.options.max_size\n        tc.variables[\"X_WHO\"] = compute(self)\n        if tc.variables[\"X_TOOLS\"] == \"x\":\n            pass\n"
    let linux = RecipeEnv { os: "Linux", arch: "armv8", compiler: "clang", compiler_version: "", build_type: "Release", version: "4.5.6", package_folder: "", source_folder: "/src", options: List.new(), options_known: false }
    let vars = recipe_cmake_variables(recipe, &linux)
    assert(vars.ok)
    let expected = ["X_SRC_DIR=/src", "X_MAJOR=4", "X_VERSION=4.5.6", "X_TOOLS=ON", "X_STATIC=ON", "X_LEVEL=4", "X_TLS=ON", "X_UNIX=ON", "X_PIC=ON", "X_GL=openssl", "X_PLATFORM=Desktop", "X_EMPTY="]
    assert(vars.names.len() == expected.len())
    for i in 0..expected.len(): assert(vars.names[i] ++ "=" ++ vars.values[i] == expected[i])
    // None means "leave it to the project"; a call cannot be known: it is named.
    assert(vars.unknown.len() == 1 and vars.unknown[0] == "X_WHO")

    let reqs = recipe_requirements(recipe, &linux)
    assert(reqs.ok)
    assert(reqs.requires.len() == 3)
    assert(reqs.requires[0] == "openssl/[>=3 <4]" and reqs.requires[1] == "linuxonly/1.0" and reqs.requires[2] == "zlib/[>=1.2.11 <2]")
    // `if some_function(self)` cannot be decided: it is reported, and what it guards is not required.
    assert(reqs.notes.len() == 1 and reqs.notes[0].contains("could not be decided"))
    let windows = RecipeEnv { os: "Windows", arch: "x86_64", compiler: "clang", compiler_version: "", build_type: "Release", version: "4.5.6", package_folder: "", source_folder: "/src", options: List.new(), options_known: false }
    let win_vars = recipe_cmake_variables(recipe, &windows)
    assert(recipe_requirements(recipe, &windows).requires.len() == 2)
    assert(win_vars.names[7] == "X_UNIX" and win_vars.values[7] == "OFF")
    // An assignment under a condition that does not hold is not made (raylib's
    // recipe sets PLATFORM=Android under `if self.settings.os == "Android"`),
    // and a later assignment replaces an earlier one.
    assert(win_vars.names[10] == "X_PLATFORM" and win_vars.values[10] == "Win")
    print("ok")
