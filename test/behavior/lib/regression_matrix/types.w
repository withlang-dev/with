pub type ImportedEntry {
    name: str,
    rank: i32,
}

pub type ImportedBindings {
    entries: Vec[ImportedEntry],
}

pub error ImportedErr = ImportedBad

pub fn imported_direct(seed: i32) -> ImportedEntry:
    ImportedEntry { name: "imported-helper", rank: seed }

pub fn imported_if(ok: bool) -> ImportedEntry:
    if ok: ImportedEntry { name: "imported-if", rank: 20 } else ImportedEntry { name: "imported-else", rank: 21 }

pub fn imported_match(ok: bool) -> ImportedEntry:
    match ok:
        true => ImportedEntry { name: "imported-match-yes", rank: 30 }
        false => ImportedEntry { name: "imported-match-no", rank: 31 }

pub fn imported_option(ok: bool) -> Option[ImportedEntry]:
    if ok: Some(ImportedEntry { name: "imported-some", rank: 40 }) else None

pub fn imported_result(ok: bool) -> Result[ImportedEntry, ImportedErr]:
    if ok: Ok(ImportedEntry { name: "imported-ok", rank: 50 }) else Err(.ImportedBad)
