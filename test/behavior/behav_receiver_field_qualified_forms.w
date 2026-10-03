//! expect-stdout: 14
//! expect-stdout: 6
//! expect-stdout: 1.5
//! expect-stdout: show 9
//! expect-stdout: 15
//! expect-stdout: 11

// §9.5 / §18.1 / §18.2 (#1930): "nothing is uncallable" — every name a
// receiver field shadows by its bare name stays reachable by its qualified
// form: `self.field`, `<selfname>.decl`, `builtins.name`, `Type.Variant`, the
// full module path. See lib/receiver_field/gauge.w.

use receiver_field.gauge

fn main:
    let g = Gauge { limit: 4, scale: 2, sin: 0.5, print: true, len: 9, Meter: 7, Idle: 4, math: 1 }
    print(f"{g.headroom()}")
    print(f"{g.scaled()}")
    print(f"{g.wave(0.0) + 1.0}")
    g.show()
    print(f"{g.others()}")
    print(f"{local_shadow()}")
