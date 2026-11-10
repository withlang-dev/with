// raylib 6.0 (conan-center-index recipes/raylib). An Image and a Wave are
// passed by value and hold their buffers, so the functions that take one are
// pointer functions (§16.2b.5); the library's source says who allocates each
// buffer and who frees it. The proof engine follows pointers, not records
// passed by value.
//
// Stated here: what was read line by line in raylib 6.0's source and holds
// for every argument a program can pass. Not stated: Sound, Music,
// AudioStream (they read the audio device InitAudioDevice sets up), Font,
// Shader, Mesh, Model, Material (they call into the GL context InitWindow
// sets up), LoadSoundAlias (its buffer is the source sound's), and
// generators such as GenImageColor (a large width*height writes through a
// failed allocation).
c facade raylib:
    resource ImageData wraps Image
        from LoadImageFromScreen    // raylib.h 6.0: "Image LoadImageFromScreen(void); // Load image from screen buffer and (screenshot)"; rtextures.c 584-595, LoadImageFromScreen: image.data = rlReadScreenPixels(width, height), a buffer the caller owns
        from LoadImage    // raylib.h 6.0: "Image LoadImage(const char *fileName); // Load image from file into CPU memory (RAM)"; rtextures.c 263-300, LoadImage: the file is read into a buffer the image owns, a zeroed Image when it cannot be read
        drop UnloadImage    // raylib.h 6.0: "void UnloadImage(Image image); // Unload image from CPU memory (RAM)"; rtextures.c 612-615, UnloadImage: RL_FREE(image.data), a no-op on the zeroed Image
    fn GetImageColor
        of ImageData    // raylib.h 6.0: "Color GetImageColor(Image image, int x, int y); // Get image pixel color at (x, y) position"; rtextures.c 3192-3196, GetImageColor: reads image.data only when 0 <= x < width and 0 <= y < height, returns a Color by value, stores nothing
    fn IsImageValid
        of ImageData    // rtextures.c 598-609, IsImageValid: compares the record's fields, follows no pointer
    fn ExportImage
        of ImageData    // rtextures.c 619-623, ExportImage: returns at once when width or height is 0 or data is NULL (its "Security check"), then reads image.data to write the file; stores nothing
    resource WaveData wraps Wave
        from LoadWave    // raylib.h 6.0: "Wave LoadWave(const char *fileName); // Load wave data from file"; raudio.c 789-803, LoadWave: the samples are decoded into a buffer the wave owns, a zeroed Wave when the file cannot be read
        drop UnloadWave    // raylib.h 6.0: "void UnloadWave(Wave wave); // Unload wave data"; raudio.c 1030-1034, UnloadWave: RL_FREE(wave.data), a no-op on the zeroed Wave
    fn IsWaveValid
        of WaveData    // raudio.c 916-927, IsWaveValid: compares the record's fields, follows no pointer
