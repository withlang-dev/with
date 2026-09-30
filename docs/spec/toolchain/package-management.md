# 18.8 Package Management

With has two dependency sources managed through the same CLI and
`with.toml`:

- **With packages** — `with get json`, `with get http`
- **C packages** — `with get c.glib`, `with get c.sqlite3`

The `c.` prefix routes through Conan Center (conan.io/center).
With packages come from the With package registry (future). Both
produce entries in `with.toml`:

```toml
[project]
name = "myapp"
version = "0.1.0"

[deps]
c.glib = "2.78"
c.sqlite3 = "3.45"
```

**`with get c.X`** resolves the package from Conan Center, downloads
headers, prebuilt libraries, and transitive deps into
`.with/deps/c/<name>/<version>/`, and updates `with.toml`. Each
package includes a `metadata.json` with include paths, library
paths, library names, and transitive dependencies.

When Conan Center has no binary this toolchain can link for the
platform, `with get c.X` builds the package from source. The recipe
Conan Center publishes is read as data and never executed: it names
the source archive, its digest and patches, the requirements, and the
CMake variables. The package's own CMake build runs with `with cc` as
the C compiler, and the result installs into
`.with/deps/c/<name>/<version>/` exactly as a binary package does. The
lock records the source archive's digest. A CMake build needs nothing
installed: the compiler carries the `cmake` and `ninja` it runs (D81). A
package that does not build with CMake names the tool its build system
needs and stops; installing that tool is the programmer's step, since the
package is the application's dependency.

**Build integration.** When `with build` encounters
`use c_import("<glib.h>")`, the compiler reads `with.toml`, finds
all `c.*` deps, reads their `metadata.json`, and constructs include
and link paths automatically. The user never writes `-I` or `-l`
flags. `c_import` headers are found by searching each dep's include
paths, and the matching package's libraries are linked automatically.

**Explicit override.** If auto-resolution picks the wrong library:

```
use c_import("<glib.h>", link: "glib-2.0", "gio-2.0")
```

**Manual C deps** work without Conan by specifying paths directly:

```toml
[deps.c.custom_lib]
include = "/opt/custom/include"
lib = "/opt/custom/lib"
link = ["custom"]
```

**CLI commands:**

| Command | Action |
|---------|--------|
| `with init` | Create new project with `with.toml`, `src/main.w`, `test/`, and `uat/hello.uat` (§18.5d) |
| `with get c.X` | Add C dependency via Conan |
| `with get c.X@2.78` | Pin specific version |
| `with get --force-reinstall c.X@2.78` | Delete and recreate the local installed C package |
| `with get --from-source c.X` | Build the C package from source even when a binary exists |
| `with remove c.X` | Remove dependency |
| `with update` | Update all deps to latest compatible |
| `with get` (no args) | Restore deps from lock file |

**Build variables for a source build.** `WITH_GET_CMAKE_<PACKAGE>` (the
package name uppercased, `-` as `_`) carries CMake cache variables into that
package's source build: `NAME=VALUE` entries separated by `;`, applied after
the recipe's own so they win. A Conan Center binary cannot honor a build
variable, so a set variable builds the package from source, as
`--from-source` does. It is a host provision, like `LIBGL_ALWAYS_SOFTWARE`:
a GPU-less macOS host draws raylib through its software rasterizer with
`WITH_GET_CMAKE_RAYLIB="PLATFORM=RGFW;OPENGL_VERSION=Software;USE_EXTERNAL_GLFW=OFF"`. An entry
that is not `NAME=VALUE` is an error, never ignored.

**Directory structure:**

```
.with/
├── deps/c/<name>/<version>/   # headers + libraries
├── cache/c_import/            # c_import translation cache
└── lock.json                  # exact version pins
```

`.with/` is gitignored. `with.toml` and `lock.json` are committed.

A facade or a convention profile is a versioned package. When a C package
publishes a facade that declares compatibility with the resolved package
version, `with get` installs and applies it automatically; package-owned
metadata needs no opt-in ceremony. A facade a package ships is trusted
exactly as the package's own code is: it is pinned by the same lock and
digest, and every fact it contributes carries the provenance
`facade:<package>@<version>`, which the contract view reports. A locally
generated draft facade is never trusted automatically. The toolchain
publishes no facade beyond the C standard library's.

---
