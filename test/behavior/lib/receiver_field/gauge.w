// §9.5 / §18.1 / §18.2 fixture (#1930): a type whose fields share their names
// with this module's own declarations, a prelude function and an intrinsic.
// Nothing is uncallable: each shadowed name is reached by its qualified form.

use std.math

let scale: i32 = 3

pub fn limit -> i32: 10

pub type Meter {
    v: i32,
}

pub fn Meter.make(v: i32) -> Meter: Meter { v }

pub enum Mode { | Idle | Busy }

pub type Gauge {
    limit: i32,
    scale: i32,
    sin: f64,
    print: bool,
    // A field named like a declaration is never an error by itself: only an
    // ambiguous bare use is.
    len: i32,
    Meter: i32,
    Idle: i32,
    math: i32,
}

impl Gauge:
    // field and this module's function
    pub fn headroom -> i32: self.limit + gauge.limit()
    // field and this module's global
    pub fn scaled -> i32: self.scale * gauge.scale
    // field and an intrinsic
    pub fn wave(x: f64) -> f64: builtins.sin(x) + self.sin
    // field and a prelude function
    pub fn show:
        if self.print: builtins.print(f"show {self.len}")
    // field and a type, a variant, an import namespace
    pub fn others -> i32:
        let m = gauge.Meter.make(self.Meter)
        let idle = if Mode.Idle == Mode.Idle: self.Idle else: 0
        m.v + idle + self.math + (std.math.PI as i32)

// A local shadowing this module's function: the self-name still reaches it.
pub fn local_shadow -> i32:
    let limit: i32 = 1
    limit + gauge.limit()
