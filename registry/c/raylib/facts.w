// raylib 6.0 (conan-center-index recipes/raylib). An Image is passed by value
// and holds its pixel buffer, so the functions that take one are pointer
// functions (§16.2b.5); the header says who allocates the buffer and who
// frees it. The proof engine follows pointers, not records passed by value.
c facade raylib:
    resource ImageData wraps Image
        from LoadImageFromScreen    // raylib.h 6.0: "Image LoadImageFromScreen(void); // Load image from screen buffer and (screenshot)"; rtextures.c, LoadImageFromScreen: image.data = rlReadScreenPixels(width, height), a buffer the caller owns
        drop UnloadImage    // raylib.h 6.0: "void UnloadImage(Image image); // Unload image from CPU memory (RAM)"; rtextures.c, UnloadImage: RL_FREE(image.data)
    fn GetImageColor
        of ImageData    // raylib.h 6.0: "Color GetImageColor(Image image, int x, int y); // Get image pixel color at (x, y) position"; rtextures.c, GetImageColor: reads image.data and returns a Color by value, storing nothing
