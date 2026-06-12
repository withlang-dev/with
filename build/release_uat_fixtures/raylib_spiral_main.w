use c_import("raylib.h")

extern fn sin(x: f64) -> f64
extern fn cos(x: f64) -> f64

fn draw_spiral(cx: f64, cy: f64, t: f64):
    for i in 0..180:
        let p = (i as f64) / 180.0
        let angle = p * 18.8495559215 + t * 0.8
        let radius = 28.0 + p * 250.0 + sin(t * 1.4 + p * 6.0) * 18.0
        let x = cx + cos(angle) * radius
        let y = cy + sin(angle) * radius
        let hue = (p * 360.0 + t * 50.0) as f32
        let col = ColorFromHSV(hue, 0.86 as f32, 1.0 as f32)
        DrawCircle(x as i32, y as i32, (4.0 + p * 4.0) as f32, col)

fn is_spiral_sample(c: Color) -> bool:
    let r = c.r as i32
    let g = c.g as i32
    let b = c.b as i32
    (r > 70 or g > 70 or b > 70) and (r + g + b > 170)

fn main:
    InitWindow(900, 600, "with raylib spiral uat")
    SetTargetFPS(60)

    let bg = Color { r: 14, g: 16, b: 26, a: 255 }
    let cx = 450.0
    let cy = 300.0
    let t = 1.25

    var frame = 0
    while frame < 10:
        BeginDrawing()
        ClearBackground(bg)
        draw_spiral(cx, cy, t)
        DrawText("with raylib spiral uat", 20, 20, 20, LIGHTGRAY)
        EndDrawing()
        frame = frame + 1

    let image = LoadImageFromScreen()
    var colored = 0
    var samples = 0

    var y = 40
    while y < 560:
        var x = 40
        while x < 860:
            let dx = (x as f64) - cx
            let dy = (y as f64) - cy
            let dist2 = dx * dx + dy * dy
            if dist2 > 900.0 and dist2 < 90000.0:
                samples = samples + 1
                if is_spiral_sample(GetImageColor(image, x, y)):
                    colored = colored + 1
            x = x + 6
        y = y + 6

    UnloadImage(image)
    CloseWindow()

    if samples < 4000:
        print(f"raylib spiral UAT failed: only sampled {samples} pixels")
        return 1
    if colored < 120:
        print(f"raylib spiral UAT failed: only found {colored} bright spiral samples")
        return 1

    print(f"raylib spiral UAT passed: {colored}/{samples} bright spiral samples")
    0
