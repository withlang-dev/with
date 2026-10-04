// An SDL facade a game writes for itself: the window and its renderer are
// owned resources that SDL's own destroy calls release, the renderer before
// the window it draws into.
use c_import("SDL3/SDL.h")

c facade sdl:
    resource Window wraps *mut SDL_Window
        from SDL_CreateWindow
        drop SDL_DestroyWindow
    resource Renderer wraps *mut SDL_Renderer
        from SDL_CreateRenderer
        drop SDL_DestroyRenderer
        borrows param 0
    fn SDL_CreateWindow
        of Window
        rename open
    fn SDL_CreateRenderer
        of Window
        rename renderer
        param name fixed null
        lend
    fn SDL_SetRenderDrawColor
        of Renderer
        rename color
        lend
    fn SDL_RenderClear
        of Renderer
        rename clear
        lend
    fn SDL_RenderFillRects
        of Renderer
        rename fill
        lend
        buffer param rects len param count elements
    fn SDL_RenderPresent
        of Renderer
        rename present
        lend
    fn SDL_GetRendererName
        of Renderer
        rename name
        returns borrow CStr from param 0
    domain errors thread
    fn SDL_GetError
        returns borrow CStr from domain errors
