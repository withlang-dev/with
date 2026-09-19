//! expect-stdout: ok
use compiler.CPort

fn main:
    let text = "# zlib\n[port]\nname = \"zlib\"\nversion = \"1.3.2\"\n\n[source]\nurl = \"https://example.invalid/zlib-1.3.2.tar.gz\"   # tarball\nsha256 = \"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef\"\n\n[build]\nsources = [\n    \"*.c\",\n    \"contrib/minizip/*.c\",\n]\nexclude = [\"gzlib.c\"]\ninclude = [\".\"]\npublic_include = [\".\"]\ndefines = [\"HAVE_UNISTD_H\"]\nlib = \"z\"\n\n[build.linux]\ndefines = [\"_GNU_SOURCE\"]\n\n[build.windows]\ndefines = [\"_CRT_SECURE_NO_WARNINGS\"]\n\n[link]\nsystem_libs = [\"m\"]\n"
    let linux = cport_parse(text, "Linux")
    assert(linux.problem == "")
    assert(linux.name == "zlib" and linux.version == "1.3.2" and linux.lib == "z")
    assert(linux.source_url == "https://example.invalid/zlib-1.3.2.tar.gz")
    assert(linux.sources.len() == 2 and linux.exclude.len() == 1)
    // The target's section appends; another target's does not apply.
    assert(linux.defines.len() == 2 and linux.defines[1] == "_GNU_SOURCE")
    assert(cport_parse(text, "Macos").defines.len() == 1)
    assert(cport_parse(text, "Windows").defines[1] == "_CRT_SECURE_NO_WARNINGS")
    assert(linux.system_libs.len() == 1)

    let files: Vec[str] = Vec.new()
    files.push("adler32.c")
    files.push("gzlib.c")
    files.push("zlib.h")
    files.push("contrib/minizip/zip.c")
    files.push("contrib/minizip/sub/deep.c")
    files.push("test/example.c")
    let picked = cport_select_sources(&linux, &files)
    assert(picked.len() == 2)
    assert(picked[0] == "adler32.c" and picked[1] == "contrib/minizip/zip.c")

    // A port that cannot be trusted says why, once.
    assert(cport_parse(text.replace("lib = \"z\"\n", ""), "Linux").problem == "missing [build] lib")
    assert(cport_parse(text.replace("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef", "abc"), "Linux").problem == "[source] sha256 must be 64 hex digits")
    assert(cport_parse(text.replace("exclude =", "exclud ="), "Linux").problem == "unknown key `exclud` in [build]")
    assert(cport_parse(text.replace("[build.windows]\ndefines", "[build.windows]\ndefnies"), "Linux").problem == "unknown key `defnies` in [build.windows]")
    print("ok")
