//! expect-stdout: ok
use compiler.ConanRecipe

// A recipe is read as data: nothing here runs Python, and nothing is about any
// one package. The shapes are the ones Conan Center's recipes use.
fn main:
    let data = "sources:\n  \"1.0.8\":\n    url:\n    - \"https://a.invalid/x-1.0.8.tar.gz\"\n    - \"https://mirror.invalid/x-1.0.8.tar.gz\"\n    sha256: \"ab5a\"\n  \"1.0.6\":\n    url: \"https://a.invalid/x-1.0.6.tar.gz\"\n    sha256: \"a284\"\npatches:\n  \"1.0.6\":\n    - patch_file: \"patches/0001-fix.patch\"\n      patch_type: \"portability\"\n    - patch_file: \"patches/0002-more.patch\"\n"
    let newest = conan_data_source(data, "1.0.8")
    assert(newest.url == "https://a.invalid/x-1.0.8.tar.gz" and newest.sha256 == "ab5a")
    assert(conan_data_source(data, "1.0.6").url == "https://a.invalid/x-1.0.6.tar.gz")
    assert(conan_data_source(data, "9.9").url == "")
    assert(conan_data_patches(data, "1.0.8").len() == 0)
    let patches = conan_data_patches(data, "1.0.6")
    assert(patches.len() == 2 and patches[1] == "patches/0002-more.patch")

    let recipe = "class X(ConanFile):\n    default_options = {\n        \"shared\": False,\n        \"fPIC\": True,\n        \"with_ssl\": \"openssl\",\n        \"max_size\": None,          # a comment, with: punctuation\n        \"tools\": True,\n        \"level\": 3,\n    }\n\n    def requirements(self):\n        if self.options.with_ssl == \"openssl\":\n            self.requires(f\"openssl/[>=3 <4]\")\n        elif self.options.with_ssl == \"wolfssl\":\n            self.requires(\"wolfssl/5.6\")\n        else:\n            self.requires(\"never/1.0\")\n        if self.settings.os == \"Linux\" and self.options.tools:\n            self.requires(\"linuxonly/1.0\")\n        if self.options.with_ssl in (\"mbedtls\", \"libressl\"):\n            self.requires(\"other/1.0\")\n        if some_function(self):\n            self.requires(\"undecided/1.0\")\n        self.requires(\"zlib/[>=1.2.11 <2]\")\n\n    def generate(self):\n        tc = CMakeToolchain(self)\n        tc.variables[\"X_SRC_DIR\"] = self.source_folder.replace(\"\\\\\", \"/\")\n        tc.variables[\"X_MAJOR\"] = Version(self.version).major\n        tc.variables[\"X_VERSION\"] = self.version\n        tc.variables[\"X_TOOLS\"] = self.options.tools\n        tc.variables[\"X_STATIC\"] = not self.options.shared\n        tc.variables[\"X_LEVEL\"] = self.options.level\n        tc.variables[\"X_TLS\"] = self.options.with_ssl == \"openssl\"\n        tc.variables[\"X_UNIX\"] = self.settings.os != \"Windows\"\n        tc.variables[\"X_PIC\"] = self.options.get_safe(\"fPIC\", True)\n        tc.variables[\"X_GL\"] = \"OFF\" if not self.options.with_ssl else str(self.options.with_ssl).replace(\"-\", \" \")\n        if self.settings.os == \"Android\":\n            tc.variables[\"X_PLATFORM\"] = \"Android\"\n        elif self.settings.os == \"Windows\":\n            tc.variables[\"X_PLATFORM\"] = \"Win\"\n        else:\n            tc.variables[\"X_PLATFORM\"] = \"Desktop\"\n        tc.variables[\"X_LEVEL\"] = 4\n        tc.cache_variables[\"X_EMPTY\"] = \"\"\n        tc.variables[\"X_MAX\"] = self.options.max_size\n        tc.variables[\"X_WHO\"] = compute(self)\n        if tc.variables[\"X_TOOLS\"] == \"x\":\n            pass\n"
    let linux = CrEnv { recipe: recipe.to_owned(), version: "4.5.6", source_dir: "/src", os: "Linux", arch: "armv8" }
    let vars = conan_recipe_cmake_variables(&linux)
    let expected = ["-DX_SRC_DIR=/src", "-DX_MAJOR=4", "-DX_VERSION=4.5.6", "-DX_TOOLS=ON", "-DX_STATIC=ON", "-DX_LEVEL=4", "-DX_TLS=ON", "-DX_UNIX=ON", "-DX_PIC=ON", "-DX_GL=openssl", "-DX_PLATFORM=Desktop", "-DX_EMPTY="]
    assert(vars.defines.len() == expected.len())
    for i in 0..expected.len(): assert(vars.defines[i] == expected[i])
    // None means "leave it to the project"; a call cannot be known: it is named.
    assert(vars.unknown.len() == 1 and vars.unknown[0] == "X_WHO = compute(self)")

    let reqs = conan_recipe_requires(&linux)
    assert(reqs.refs.len() == 3)
    assert(reqs.refs[0] == "openssl/[>=3 <4]" and reqs.refs[1] == "linuxonly/1.0" and reqs.refs[2] == "zlib/[>=1.2.11 <2]")
    assert(reqs.undecided.len() == 1 and reqs.undecided[0].starts_with("undecided/1.0"))
    let windows = CrEnv { recipe: recipe.to_owned(), version: "4.5.6", source_dir: "/src", os: "Windows", arch: "x86_64" }
    assert(conan_recipe_requires(&windows).refs.len() == 2)
    assert(conan_recipe_cmake_variables(&windows).defines[7] == "-DX_UNIX=OFF")
    // An assignment under a condition that does not hold is not made (raylib's
    // recipe sets PLATFORM=Android under `if self.settings.os == "Android"`),
    // and a later assignment replaces an earlier one.
    assert(conan_recipe_cmake_variables(&windows).defines[10] == "-DX_PLATFORM=Win")
    print("ok")
