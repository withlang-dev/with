pub error ImportedErr =
    Bad(msg: str)
    Missing(path: str, line: i32)
    Empty

pub enum ImportedToken { Int(i32) | Text(str) | End }

pub type ImportedHolder {
    err: ImportedErr,
    tok: ImportedToken,
}

pub type ImportedNest {
    holder: ImportedHolder,
}

pub fn imported_bad(msg: str) -> ImportedErr:
    ImportedErr.Bad(msg)

pub fn imported_missing(path: str, line: i32) -> ImportedErr:
    ImportedErr.Missing(path, line)

pub fn imported_empty() -> ImportedErr:
    ImportedErr.Empty

pub fn imported_int(n: i32) -> ImportedToken:
    ImportedToken.Int(n)

pub fn imported_text(label: str) -> ImportedToken:
    ImportedToken.Text(label)

pub fn imported_holder(msg: str, n: i32) -> ImportedHolder:
    ImportedHolder { err: imported_bad(msg), tok: imported_int(n) }

pub fn imported_nest(msg: str, n: i32) -> ImportedNest:
    ImportedNest { holder: imported_holder(msg, n) }

pub fn imported_if_err(ok: bool) -> ImportedErr:
    if ok then ImportedErr.Empty else ImportedErr.Bad("imported-if")

pub fn imported_match_tok(ok: bool) -> ImportedToken:
    match ok
        true => ImportedToken.Text("match-yes")
        false => ImportedToken.End
