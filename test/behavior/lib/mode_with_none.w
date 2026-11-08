// #3088: an enum in another module whose variant is spelled like the
// prelude's `None`. Importing the module must not make a bare `None` in
// the importer mean `Mode.None`.
pub enum Mode:
    None
    Loud

pub fn mode_name(m: Mode) -> str:
    match m:
        .None => "quiet"
        .Loud => "loud"
