//! skip: non-executable spec sketch for Section 4.9 — Implicit Ok Wrapping (formerly 25.27b); contains pseudo-code for unimplemented feature work
// Spec test: Section 4.9 — Implicit Ok Wrapping (formerly 25.27b)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: value auto-wrapped in Ok
fn get_number -> Result[i32, str]:
    42                       // auto-wrapped to Ok(42)

// PASS: Result[Unit, E] with no trailing expression
fn do_stuff -> Result[Unit, IoError]:
    let f = fs.open("test.txt")?
    f.write_all(b"hello")?
    // implicit Ok(())

// PASS: explicit Ok still works
fn explicit -> Result[i32, str]:
    Ok(42)

// PASS: explicit Err still works
fn fail -> Result[i32, str]:
    Err("nope")

// PASS: ? still propagates errors
fn chain -> Result[User, DbError]:
    let row = db.query("SELECT ...", id)?
    User.from_row(row)       // auto-wrapped in Ok(...)
