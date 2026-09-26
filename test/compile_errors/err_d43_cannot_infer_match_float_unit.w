//! expect-check-fail: cannot infer return type: match arms have types f64 and Unit; add `-> f64` or `-> Unit`

// D43 / #1711: a float arm and a Unit arm do not unify. arithmetic_result_type
// answered `f64` for a float against any type, so the join inferred `f64`
// and MIR stored the Unit arm into it ("invalid MIR before codegen").
// behav_unit_tail_match_statement.w is the `-> Unit` spelling the remedy names.

pub enum K { | A | B }
impl Copy for K
pub type G { frozen: f64 = 0.0, health: i32 = 3 }
extend G:
    fn f(mut self: Self, k: K):
        match k:
            .A => { self.frozen = 5.0 }
            .B => {
                self.health += 1
                if self.health > 3: self.health = 3
            }
fn main:
    var g = G {}
    g.f(.A)
