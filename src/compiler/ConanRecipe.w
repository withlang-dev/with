// Reading a Conan Center recipe's conandata.yml as DATA, to build a package
// from source: it names the tarball, its digest and the patches, which is
// what a source build fetches. Nothing here is about any one package. What
// the recipe decides in Python (its requirements, options, CMake variables
// and link interface) is evaluated by compiler.RecipeInterp.

// `urls` are the archive's mirrors in the recipe's order; the first is the
// canonical one, the rest are tried when it does not answer.
pub type ConanSource { urls: List[str], sha256: str }

fn cr_unquote(text: &str) -> str:
    let t = text.trim()
    if t.len() >= 2 and (t[0] == '"' or t[0] == '\'') and t[t.len() - 1] == t[0]: return t.slice(1, t.len() - 1).to_owned()
    t.to_owned()

fn cr_is_version_key(line: &str, version: &str) -> bool:
    line == "\"" ++ version ++ "\":" or line == version ++ ":" or line == "'" ++ version ++ "':"

// The lines of `section:`'s block for `version`, trimmed. conandata.yml is
// regular enough to read by line: a version block ends at the next line that
// is itself a key with nothing after the colon, other than `url:`.
fn cr_version_block(data: &str, section: &str, version: &str) -> List[str]:
    let out: List[str] = List.new()
    var in_section = false
    var in_version = false
    for raw in data.split("\n"):
        let line = raw.trim()
        if line.len() == 0 or line.starts_with("#"): continue
        let top_level = raw[0] != ' ' and raw[0] != '\t' and raw[0] != '-'
        if top_level:
            in_section = line == section ++ ":"
            in_version = false
        else if in_section and cr_is_version_key(line, version): in_version = true
        else if in_version and line.ends_with(":") and line != "url:" and not line.starts_with("-"): in_version = false
        else if in_version: out.push(line.to_owned())
    out

pub fn conan_data_source(data: &str, version: &str) -> ConanSource:
    let urls: List[str] = List.new()
    var sha256 = ""
    var in_url_list = false
    for line in cr_version_block(data, "sources", version):
        if line.starts_with("url:"):
            let rest = line.slice(4, line.len()).trim().to_owned()
            in_url_list = rest.len() == 0
            if rest.len() > 0: urls.push(cr_unquote(rest))
        else if line.starts_with("sha256:"):
            sha256 = cr_unquote(line.slice(7, line.len()))
            in_url_list = false
        else if in_url_list and line.starts_with("-"): urls.push(cr_unquote(line.slice(1, line.len())))
        else: in_url_list = false
    ConanSource { urls, sha256 }

// The archive a build uses: the recipe's mirrors in order, the first that
// downloads and has the recipe's digest. `path` is "" when none did, and
// `tried` says what happened to each.
pub type ConanArchivePick { path: str, tried: str }

pub fn conan_pick_archive(source: &ConanSource, dir: &str, download: fn(&str, &str) -> i32, digest_of: fn(&str) -> str) -> ConanArchivePick:
    var tried = ""
    for url in source.urls:
        var slash = -1
        for i in 0..url.len() as i32:
            if url[i] == '/': slash = i
        let name = url.slice(slash + 1, url.len())
        let candidate = dir ++ "/" ++ name
        if download(url, &candidate) != 0:
            tried = tried ++ "\n  " ++ url ++ ": did not download"
            continue
        let digest = digest_of(&candidate)
        if digest != source.sha256:
            tried = tried ++ "\n  " ++ url ++ ": sha256 " ++ digest ++ ", the recipe expects " ++ source.sha256
            continue
        return ConanArchivePick { path: candidate, tried: tried.clone() }
    ConanArchivePick { path: "", tried }

// A patch entry can say where in the tree it applies (`base_path`) or how many
// path components to drop (`strip`). ConanPatch applies at the source root
// with one component dropped; anything else would land in the wrong place
// without a word, so it is named. "" when the version's patches need neither.
pub fn conan_data_patch_problem(data: &str, version: &str) -> str:
    for line in cr_version_block(data, "patches", version):
        let entry = if line.starts_with("-"): line.slice(1, line.len()).trim() else: line.trim()
        if entry.starts_with("base_path:") or entry.starts_with("strip:"): return "its patches use `" ++ entry ++ "`, which this build does not apply yet"
    ""

// Paths of the version's patch files, relative to the recipe folder, in order.
pub fn conan_data_patches(data: &str, version: &str) -> List[str]:
    let out: List[str] = List.new()
    for line in cr_version_block(data, "patches", version):
        let at = line.find("patch_file:")
        if at >= 0: out.push(cr_unquote(line.slice(at + 11, line.len())))
    out

