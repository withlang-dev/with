// Reading a Conan Center recipe as DATA, to build a package from source when
// Conan Center has no binary for the platform. Nothing here is about any one
// package, and nothing in a recipe is executed: conandata.yml names the
// tarball, its digest and the patches; conanfile.py's `requires`,
// `default_options` and `tc.variables[...]` lines are read for what they say.

pub type ConanSource { url: str, sha256: str }

fn cr_unquote(text: &str) -> str:
    let t = text.trim()
    if t.len() >= 2 and (t[0] == '"' or t[0] == '\'') and t[t.len() - 1] == t[0]: return t.slice(1, t.len() - 1).to_owned()
    t.to_owned()

fn cr_is_version_key(line: &str, version: &str) -> bool:
    line == "\"" ++ version ++ "\":" or line == version ++ ":" or line == "'" ++ version ++ "':"

// The lines of `section:`'s block for `version`, trimmed. conandata.yml is
// regular enough to read by line: a version block ends at the next line that
// is itself a key with nothing after the colon, other than `url:`.
fn cr_version_block(data: &str, section: &str, version: &str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
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
    var url = ""
    var sha256 = ""
    var in_url_list = false
    for line in cr_version_block(data, "sources", version):
        if line.starts_with("url:"):
            let rest = line.slice(4, line.len()).trim()
            in_url_list = rest.len() == 0
            if rest.len() > 0: url = cr_unquote(rest)
        else if line.starts_with("sha256:"):
            sha256 = cr_unquote(line.slice(7, line.len()))
            in_url_list = false
        else if in_url_list and line.starts_with("-"):
            // Mirrors: the first is the canonical one.
            if url.len() == 0: url = cr_unquote(line.slice(1, line.len()))
        else: in_url_list = false
    ConanSource { url, sha256 }

// Paths of the version's patch files, relative to the recipe folder, in order.
pub fn conan_data_patches(data: &str, version: &str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    for line in cr_version_block(data, "patches", version):
        let at = line.find("patch_file:")
        if at >= 0: out.push(cr_unquote(line.slice(at + 11, line.len())))
    out

// `default_options = { "shared": False, "fPIC": True, ... }` -> the literal for `name`, or "".
fn cr_default_option(recipe: &str, name: &str) -> str:
    let start = recipe.find("default_options")
    if start < 0: return ""
    let rest = recipe.slice(start, recipe.len())
    let end = rest.find("}")
    if end < 0: return ""
    // Comments go first: one may hold a comma or a colon.
    var block = ""
    for raw in rest.slice(0, end).split("\n"):
        let hash = raw.find("#")
        block = block ++ raw.slice(0, if hash >= 0: hash else: raw.len()) ++ "\n"
    for entry in block.split(","):
        let pair = entry.split(":")
        if pair.len() >= 2 and cr_unquote(pair.get(0).split("{").get(pair.get(0).split("{").len() - 1)) == name:
            return pair.get(1).trim().to_owned()
    ""

fn cr_version_component(version: &str, index: i32) -> str:
    let parts = version.split(".")
    if index < parts.len() as i32: parts.get(index).to_owned() else: "0"


// ── Recipe expressions ───────────────────────────────────────────────
// A recipe decides requirements and CMake variables with Python expressions
// over its options and the platform: `self.options.with_ssl == "openssl"`,
// `self.settings.os != "Windows"`, `not self.options.shared`, `"A" if c else
// "B"`. With every option at its declared default and the host as the
// platform, that subset has a value without running anything. What falls
// outside it evaluates to Unknown, and the caller reports it.

let CRV_UNKNOWN = 0
let CRV_BOOL = 1
let CRV_TEXT = 2          // strings and numbers: both are text to CMake
let CRV_LIST = 3
let CRV_NONE = 4

pub type CrValue { kind: i32, truth: bool, text: str, items: Vec[str] }

fn CrValue.unknown(): CrValue { kind: CRV_UNKNOWN, truth: false, text: "", items: Vec.new() }
fn CrValue.of_bool(b: bool): CrValue { kind: CRV_BOOL, truth: b, text: "", items: Vec.new() }
fn CrValue.of_text(s: &str): CrValue { kind: CRV_TEXT, truth: s.len() > 0, text: s.to_owned(), items: Vec.new() }
fn CrValue.none(): CrValue { kind: CRV_NONE, truth: false, text: "", items: Vec.new() }

// What the recipe is evaluated against.
pub type CrEnv { recipe: str, version: str, source_dir: str, os: str, arch: str }

fn cr_tokens(expr: &str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    var i = 0
    let n = expr.len() as i32
    while i < n:
        let c = expr[i]
        if c == ' ' or c == '\t':
            i = i + 1
        else if c == '"' or c == '\'':
            var j = i + 1
            while j < n and expr[j] != c:
                if expr[j] == '\\': j = j + 1
                j = j + 1
            // A string token keeps its opening quote as a marker.
            out.push("\"" ++ expr.slice(i + 1, if j < n: j else: n))
            i = j + 1
        else if (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '_' or c == '.':
            var j = i
            while j < n and ((expr[j] >= 'a' and expr[j] <= 'z') or (expr[j] >= 'A' and expr[j] <= 'Z') or (expr[j] >= '0' and expr[j] <= '9') or expr[j] == '_' or expr[j] == '.'): j = j + 1
            out.push(expr.slice(i, j).to_owned())
            i = j
        else if i + 1 < n and (expr.slice(i, i + 2) == "==" or expr.slice(i, i + 2) == "!="):
            out.push(expr.slice(i, i + 2).to_owned())
            i = i + 2
        else:
            out.push(expr.slice(i, i + 1).to_owned())
            i = i + 1
    out

type CrParser { tokens: Vec[str], at: i32 }

impl CrParser:
    fn peek() -> str: if self.at < self.tokens.len() as i32: self.tokens[self.at].clone() else: ""

    mut fn take() -> str:
        let t = self.peek()
        self.at = self.at + 1
        t

    mut fn accept(token: &str) -> bool:
        if self.peek() != token: return false
        self.at = self.at + 1
        true

    // Skips a balanced `( ... )` whose opening paren was just taken.
    mut fn skip_call():
        var depth = 1
        while depth > 0 and self.at < self.tokens.len() as i32:
            let t = self.take()
            if t == "(": depth = depth + 1
            if t == ")": depth = depth - 1

    mut fn expression(env: &CrEnv) -> CrValue:
        let value = self.or_expr(env)
        // Python's conditional expression: `value if condition else other`.
        if not self.accept("if"): return value
        let condition = self.or_expr(env)
        if not self.accept("else"): return CrValue.unknown()
        let other = self.expression(env)
        if condition.kind == CRV_UNKNOWN: return CrValue.unknown()
        if condition.truth: value else: other

    mut fn or_expr(env: &CrEnv) -> CrValue:
        var left = self.and_expr(env)
        while self.accept("or"):
            let right = self.and_expr(env)
            // `a or b` is a when a is truthy, so a known-true side decides.
            if left.kind != CRV_UNKNOWN and left.truth: continue
            left = if left.kind == CRV_UNKNOWN and not (right.kind != CRV_UNKNOWN and right.truth): CrValue.unknown() else: right
        left

    mut fn and_expr(env: &CrEnv) -> CrValue:
        var left = self.not_expr(env)
        while self.accept("and"):
            let right = self.not_expr(env)
            if left.kind != CRV_UNKNOWN and not left.truth: continue
            left = if left.kind == CRV_UNKNOWN and not (right.kind != CRV_UNKNOWN and not right.truth): CrValue.unknown() else: right
        left

    mut fn not_expr(env: &CrEnv) -> CrValue:
        if not self.accept("not"): return self.comparison(env)
        let value = self.not_expr(env)
        if value.kind == CRV_UNKNOWN: CrValue.unknown() else: CrValue.of_bool(not value.truth)

    mut fn comparison(env: &CrEnv) -> CrValue:
        let left = self.postfix(env)
        let op = self.peek()
        var negate = false
        if op == "not" and self.at + 1 < self.tokens.len() as i32 and self.tokens[self.at + 1] == "in":
            self.at = self.at + 2
            negate = true
        else if op == "in": self.at = self.at + 1
        else if op == "==" or op == "!=":
            self.at = self.at + 1
            let right = self.postfix(env)
            if left.kind == CRV_UNKNOWN or right.kind == CRV_UNKNOWN: return CrValue.unknown()
            let same = left.kind == right.kind and left.text == right.text and (left.kind != CRV_BOOL or left.truth == right.truth)
            return CrValue.of_bool(same == (op == "=="))
        else: return left
        let right = self.postfix(env)
        if left.kind != CRV_TEXT or right.kind != CRV_LIST: return CrValue.unknown()
        var found = false
        for item in right.items:
            if item == left.text: found = true
        CrValue.of_bool(found != negate)

    // An atom and the `.replace("a", "b")` calls that may follow it.
    mut fn postfix(env: &CrEnv) -> CrValue:
        var value = self.atom(env)
        while self.peek() == ".replace" and self.at + 1 < self.tokens.len() as i32 and self.tokens[self.at + 1] == "(":
            self.at = self.at + 2
            let from = self.take()
            let comma = self.take()
            let to = self.take()
            let close = self.take()
            if value.kind != CRV_TEXT or not from.starts_with("\"") or not to.starts_with("\"") or comma != "," or close != ")": return CrValue.unknown()
            value = CrValue.of_text(value.text.replace(from.slice(1, from.len()), to.slice(1, to.len())))
        value

    mut fn atom(env: &CrEnv) -> CrValue:
        let t = self.take()
        if t.len() == 0: return CrValue.unknown()
        if t.starts_with("\""): return CrValue { kind: CRV_TEXT, truth: t.len() > 1, text: t.slice(1, t.len()).to_owned(), items: Vec.new() }
        if t == "True": return CrValue.of_bool(true)
        if t == "False": return CrValue.of_bool(false)
        if t == "None": return CrValue.none()
        if t == "(" or t == "[":
            let close = if t == "(": ")" else: "]"
            let first = self.expression(env)
            if self.accept(close): return first
            // A tuple or list of literals, as the right side of `in`.
            var list = CrValue { kind: CRV_LIST, truth: true, text: "", items: Vec.new() }
            if first.kind == CRV_TEXT: list.items.push(first.text.clone())
            while self.accept(","):
                if self.peek() == close: break
                let item = self.expression(env)
                if item.kind != CRV_TEXT: list.kind = CRV_UNKNOWN
                list.items.push(item.text.clone())
            if not self.accept(close): return CrValue.unknown()
            return list
        if t[0] >= '0' and t[0] <= '9': return CrValue.of_text(t)
        if t == "str" or t == "bool":
            if not self.accept("("): return CrValue.unknown()
            let inner = self.expression(env)
            if not self.accept(")") or inner.kind == CRV_UNKNOWN: return CrValue.unknown()
            if t == "bool": return CrValue.of_bool(inner.truth)
            if inner.kind == CRV_BOOL: return CrValue.of_text(if inner.truth: "True" else: "False")
            return inner
        if t == "is_apple_os":
            if self.accept("("): self.skip_call()
            return CrValue.of_bool(env.os == "Macos")
        if t == "Version":
            // Version(self.version).major
            if self.accept("("): self.skip_call()
            let part = self.take()
            let index = if part == ".major": 0 else: if part == ".minor": 1 else: if part == ".patch": 2 else: -1
            return if index < 0: CrValue.unknown() else: CrValue.of_text(cr_version_component(env.version, index))
        if t == "self.version": return CrValue.of_text(env.version)
        if t == "self.settings.os": return CrValue.of_text(env.os)
        if t == "self.settings.arch": return CrValue.of_text(env.arch)
        if t == "self.settings.build_type": return CrValue.of_text("Release")
        if t.starts_with("self.source_folder"):
            if self.accept("("): self.skip_call()
            return CrValue.of_text(env.source_dir)
        if t == "self.options.get_safe":
            if not self.accept("("): return CrValue.unknown()
            let name = self.take()
            var fallback = CrValue.none()
            if self.accept(","): fallback = self.expression(env)
            if not self.accept(")") or not name.starts_with("\""): return CrValue.unknown()
            let found = cr_option_value(env.recipe, name.slice(1, name.len()))
            return if found.kind == CRV_UNKNOWN: fallback else: found
        if t.starts_with("self.options."): return cr_option_value(env.recipe, t.slice(13, t.len()))
        CrValue.unknown()

// An option's declared default. `shared` is decided here: a static library.
fn cr_option_value(recipe: &str, name: &str) -> CrValue:
    if name == "shared": return CrValue.of_bool(false)
    let literal = cr_default_option(recipe, name)
    if literal.len() == 0: return CrValue.unknown()
    var parser = CrParser { tokens: cr_tokens(literal), at: 0 }
    let env = CrEnv { recipe: "", version: "", source_dir: "", os: "", arch: "" }
    parser.atom(&env)

pub fn conan_recipe_eval(expr: &str, env: &CrEnv) -> CrValue:
    var parser = CrParser { tokens: cr_tokens(expr), at: 0 }
    let value = parser.expression(env)
    // Trailing tokens mean the expression was not understood as a whole.
    if parser.at < parser.tokens.len() as i32: CrValue.unknown() else: value

// The value as CMake spells it, or "" with `known` false.
pub fn conan_recipe_cmake_value(value: &CrValue) -> str:
    if value.kind == CRV_BOOL: return if value.truth: "ON" else: "OFF"
    if value.kind == CRV_TEXT: return value.text.clone()
    ""


// A recipe line with the verdict of the `if` / `elif` / `else` around it: 1 when
// every enclosing condition holds for the default options on this platform, 0
// when one does not, -1 when one cannot be evaluated (`why` names it).
type CrGuardedLine { text: str, verdict: i32, why: str }

fn cr_indent(raw: &str) -> i32:
    var n = 0
    while n < raw.len() as i32 and (raw[n] == ' ' or raw[n] == '\t'): n = n + 1
    n

fn cr_guarded_lines(env: &CrEnv) -> Vec[CrGuardedLine]:
    let out: Vec[CrGuardedLine] = Vec.new()
    var indents: Vec[i32] = Vec.new()
    var kinds: Vec[i32] = Vec.new()
    var texts: Vec[str] = Vec.new()
    // The if/elif chain last closed at an indent: 1 once a branch was taken,
    // -1 once one could not be decided, 0 while every branch was false.
    var chain_indent = -1
    var chain_state = 0
    for raw in env.recipe.split("\n"):
        let line = raw.trim()
        if line.len() == 0 or line.starts_with("#"): continue
        let indent = cr_indent(raw)
        while indents.len() > 0 and indents[indents.len() - 1] >= indent:
            let closed_indent: i32 = indents.pop().unwrap()
            let closed_kind: i32 = kinds.pop().unwrap()
            let _t = texts.pop()
            if closed_indent == indent and (line.starts_with("elif ") or line == "else:"):
                let prior = if chain_indent == indent: chain_state else: 0
                chain_state = if prior == 1 or closed_kind == 1: 1 else: if prior == -1 or closed_kind == -1: -1 else: 0
                chain_indent = indent
        if line.starts_with("if ") and line.ends_with(":"):
            if chain_indent == indent: chain_indent = -1
            let cond = line.slice(3, line.len() - 1)
            let value = conan_recipe_eval(cond, env)
            indents.push(indent)
            kinds.push(if value.kind == CRV_UNKNOWN: -1 else: if value.truth: 1 else: 0)
            texts.push(cond.to_owned())
        else if (line.starts_with("elif ") and line.ends_with(":")) or line == "else:":
            // Taken only if no branch before it was.
            let prior = if chain_indent == indent: chain_state else: -1
            var kind = if line == "else:": 1 else: -1
            if line != "else:":
                let value = conan_recipe_eval(line.slice(5, line.len() - 1), env)
                kind = if value.kind == CRV_UNKNOWN: -1 else: if value.truth: 1 else: 0
            indents.push(indent)
            kinds.push(if prior == 1: 0 else: if prior == -1 and kind != 0: -1 else: kind)
            texts.push(line.to_owned())
        var verdict = 1
        var why = ""
        for i in 0..kinds.len() as i32:
            if kinds[i] == 0: verdict = 0
            if kinds[i] < 0 and why.len() == 0: why = texts[i].clone()
        if verdict == 1 and why.len() > 0: verdict = -1
        out.push(CrGuardedLine { text: line.to_owned(), verdict, why })
    out

pub type ConanCMakeVariables {
    // `-DNAME=value` for every assignment that applies and whose value is known.
    defines: Vec[str],
    // `NAME = <expression>` for the rest, to report if the build then fails.
    unknown: Vec[str],
}

// `tc.variables["NAME"] = <expr>` and `tc.cache_variables["NAME"] = <expr>`,
// under the conditions that hold. A later assignment to a name replaces an
// earlier one, as it would when the recipe runs.
pub fn conan_recipe_cmake_variables(env: &CrEnv) -> ConanCMakeVariables:
    let names: Vec[str] = Vec.new()
    let values: Vec[str] = Vec.new()
    let unknown: Vec[str] = Vec.new()
    for guarded in cr_guarded_lines(env):
        let line = guarded.text.clone()
        let at = line.find("variables[")
        if at < 0 or guarded.verdict == 0: continue
        let rest = line.slice(at + 10, line.len())
        let close = rest.find("]")
        let eq = rest.find("=")
        if close < 0 or eq < close or rest.slice(eq, rest.len()).starts_with("=="): continue
        let name = cr_unquote(rest.slice(0, close))
        let expr = rest.slice(eq + 1, rest.len()).trim().to_owned()
        if guarded.verdict < 0:
            unknown.push(name ++ " = " ++ expr ++ "  (if " ++ guarded.why ++ ")")
            continue
        let value = conan_recipe_eval(expr, env)
        if value.kind == CRV_NONE: continue
        if value.kind != CRV_BOOL and value.kind != CRV_TEXT:
            unknown.push(name ++ " = " ++ expr)
            continue
        var slot = -1
        for i in 0..names.len() as i32:
            if names[i] == name: slot = i
        if slot >= 0: values[slot] = conan_recipe_cmake_value(&value)
        else:
            names.push(name)
            values.push(conan_recipe_cmake_value(&value))
    let defines: Vec[str] = Vec.new()
    for i in 0..names.len() as i32: defines.push("-D" ++ names[i] ++ "=" ++ values[i])
    ConanCMakeVariables { defines, unknown }

pub type ConanRequires {
    // "zlib/[>=1.2.11 <2]": requirements whose enclosing conditions all hold.
    refs: Vec[str],
    // A requirement under a condition that could not be evaluated, with it.
    undecided: Vec[str],
}

pub fn conan_recipe_requires(env: &CrEnv) -> ConanRequires:
    let refs: Vec[str] = Vec.new()
    let undecided: Vec[str] = Vec.new()
    for guarded in cr_guarded_lines(env):
        let at = guarded.text.find("self.requires(")
        if at < 0 or guarded.verdict == 0: continue
        var arg = guarded.text.slice(at + 14, guarded.text.len()).trim().to_owned()
        // `f"openssl/[>=3 <4]"`: an f-string with nothing to format.
        if arg.starts_with("f\"") or arg.starts_with("f'"): arg = arg.slice(1, arg.len()).to_owned()
        if arg.len() < 2 or (arg[0] != '"' and arg[0] != '\'') or arg.contains("{"): continue
        let close = arg.slice(1, arg.len()).find(arg.slice(0, 1))
        if close <= 0: continue
        let reference = arg.slice(1, close + 1).to_owned()
        if guarded.verdict < 0: undecided.push(reference ++ "  (if " ++ guarded.why ++ ")")
        else: refs.push(reference)
    ConanRequires { refs, undecided }
