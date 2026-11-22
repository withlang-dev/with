// D39 emitter refusal fixture: a type with a drop method cannot cross the
// bundle boundary (a .wi carries no Drop impl and nobody drops bundle
// storage); --emit-bundle-interface must fail naming `Res`.
pub type Res { n: i32 }
impl Drop for Res:
    move fn drop():
        let _ = self.n
pub fn make(n: i32) -> Res: Res { n }
