//! skip: non-executable spec sketch for Section 11.3 — Object Safety (formerly 25.83); contains pseudo-code for unimplemented feature work
// Spec test: Section 11.3 — Object Safety (formerly 25.83)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: trait with &Self methods is object-safe
trait Drawable:
    fn draw(self: &Self)
fn render(d: &dyn Drawable): d.draw()

// FAIL: trait with by-value self is not object-safe (without Box)
trait Consumable:
    fn consume(self: Self)
fn bad(c: &dyn Consumable): ...   // ERROR: Consumable is not object-safe

// PASS: by-value self through Box
fn good(c: Box[dyn Consumable]): c.consume()  // OK via generated shim
