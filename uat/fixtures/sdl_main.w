use facades.sdl
use c_import("SDL3/SDL.h")

fn sdl_error(): SDL_GetError().map(it.to_str_lossy()) ?? "unknown SDL error"

fn main:
    if not SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_GAMEPAD):
        print(f"sdl UAT failed: SDL_Init: {sdl_error()}")
        return 1
    defer: SDL_Quit()

    let Some(window) = Window.open("with sdl uat", 640, 480, 0) else:
        print(f"sdl UAT failed: no window: {sdl_error()}")
        return 1
    let Some(renderer) = window.renderer() else:
        print(f"sdl UAT failed: no renderer: {sdl_error()}")
        return 1

    var bars: List[SDL_FRect] = List.new()
    for i in 0..8: bars.push(SDL_FRect { x: 40.0 + 70.0 * (i as f32), y: 200.0, w: 50.0, h: 80.0 })

    var drawn = 0
    for frame in 0..10:
        renderer.color(14, 16, 26, 255)
        renderer.clear()
        renderer.color(240, 200, 40, 255)
        if renderer.fill(bars) and renderer.present(): drawn += 1

    if drawn < 10:
        print(f"sdl UAT failed: drew {drawn} of 10 frames: {sdl_error()}")
        return 1
    let name = renderer.name().map(it.to_str_lossy()) ?? "unnamed"
    print(f"sdl UAT passed: {drawn} frames on the {name} renderer")
