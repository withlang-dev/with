// Spec test: Section 4.4 / 18.2 - Enum Constructor Imports.

enum ImportedColor { Red | Green | Blue }
use ImportedColor.{Red, Green, Blue}

fn imported_color_name(c: ImportedColor) -> str:
    match c:
        Red => "red"
        Green => "green"
        Blue => "blue"

fn test_enum_constructors_are_importable:
    let c = Red
    assert(imported_color_name(c) == "red")
    let g = Green
    assert(imported_color_name(g) == "green")
    let b = Blue
    assert(imported_color_name(b) == "blue")

enum ImportedToken { Number(i32) | Text(str) }
use ImportedToken.{Number, Text}

fn test_imported_payload_constructors:
    let n = Number(42)
    match n:
        Number(value) => assert(value == 42)
        Text(_) => assert(false)
    let t = Text("ok")
    match t:
        Text(value) => assert(value == "ok")
        Number(_) => assert(false)

fn test_option_result_constructors_are_in_prelude:
    let x: Option[i32] = Some(5)
    match x:
        Some(value) => assert(value == 5)
        None => assert(false)
    let y: Result[i32, str] = Ok(5)
    match y:
        Ok(value) => assert(value == 5)
        Err(_) => assert(false)
