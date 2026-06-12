//! expect-check-fail: may originate from

type Rule6ManyBox { n: i32 }

fn choose_many(p00: &Rule6ManyBox, p01: &Rule6ManyBox, p02: &Rule6ManyBox, p03: &Rule6ManyBox, p04: &Rule6ManyBox, p05: &Rule6ManyBox, p06: &Rule6ManyBox, p07: &Rule6ManyBox, p08: &Rule6ManyBox, p09: &Rule6ManyBox, p10: &Rule6ManyBox, p11: &Rule6ManyBox, p12: &Rule6ManyBox, p13: &Rule6ManyBox, p14: &Rule6ManyBox, p15: &Rule6ManyBox, p16: &Rule6ManyBox, p17: &Rule6ManyBox, p18: &Rule6ManyBox, p19: &Rule6ManyBox, p20: &Rule6ManyBox, p21: &Rule6ManyBox, p22: &Rule6ManyBox, p23: &Rule6ManyBox, p24: &Rule6ManyBox, p25: &Rule6ManyBox, p26: &Rule6ManyBox, p27: &Rule6ManyBox, p28: &Rule6ManyBox, p29: &Rule6ManyBox, p30: &Rule6ManyBox, p31: &Rule6ManyBox, p32: &Rule6ManyBox) -> &Rule6ManyBox:
    p32

fn main:
    let outer = Rule6ManyBox { n: 1 }
    var view = choose_many(&outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer)
    with Rule6ManyBox { n: 2 } as inner:
        view = choose_many(&outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &outer, &inner)
    assert(view.n == 2)
