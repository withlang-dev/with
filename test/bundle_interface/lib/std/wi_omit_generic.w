// D39 Level 0 emitter fixture: a generic function cannot cross a bundle
// boundary, so it stays corpus-internal — the interface omits `id`, names
// it in a note line, and the build warns; `plain` is exported as usual.
pub fn id[T](x: T) -> T: x
pub fn plain(x: i32) -> i32: x
