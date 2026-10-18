use c_import("raylib.h")

fn main:
    SetTraceLogLevel(LOG_WARNING)
    InitWindow(600, 600, "with — spiral")
    defer: CloseWindow()
    SetTargetFPS(60)

    let background = Color { r: 14, g: 16, b: 26, a: 255 }

    while not WindowShouldClose():
        BeginDrawing()
        defer: EndDrawing()
        ClearBackground(background)

        // raylib draws in f32; the clock is the one f64, narrowed once.
        let t = GetTime() as f32
        let mouse = GetMousePosition()

        for i in 0..140:
            let p = i as f32 / 140.0
            let angle = p * 4 * PI + t * 0.8
            let radius = 40 + p * 220 + sin(t * 1.4 + p * 6) * 30
            let color = ColorFromHSV(p * 360 + t * 50, 0.85, 1)
            DrawCircleV(Vector2 {
                mouse.x + cos(angle) * radius,
                mouse.y + sin(angle) * radius
            }, 3 + p * 4, color)

        DrawText("move the mouse", 20, 20, 20, LIGHTGRAY)
        DrawFPS(20, 560)
