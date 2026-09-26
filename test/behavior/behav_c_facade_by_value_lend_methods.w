//! expect-stdout: 1 2 50 1
//! expect-stdout: ok

// D51 §16.2b.3 / #1669: a by-value token (raylib's `Sound`, `Texture2D`)
// is a resource like a pointer handle, and an fn item that states `of` it
// is its method: `lend` passes the token, and an operation taking the
// token's address is a `mut fn` that C writes through. Its type alone never
// makes an operation its method (`int` would be every integer), so the
// explicit `of` is what assigns it. Before the fix the facade rendered no
// method for a by-value token and accepted the `of` silently: every call
// of a renamed method was "unknown method 'play' for type 'Clip'".
// Each C token counts its own calls through the slot it names; the counts
// are read back after the resource is gone.

use c_import("void *calloc(unsigned long count, unsigned long size);
typedef struct { int* state; float volume; } Snd;
static inline Snd snd_load(const char* path) { Snd s; s.state = (int*)calloc(4, sizeof(int)); s.volume = 1.0f; return s; }
static inline void snd_unload(Snd s) { s.state[0]++; }
static inline void snd_play(Snd s) { s.state[1]++; }
static inline void snd_set_volume(Snd s, float v) { s.state[2] = (int)(v * 100.0f); }
static inline int snd_valid(Snd s) { return s.state != 0; }
static inline void snd_retune(Snd* s) { s->volume = 0.25f; s->state[3]++; }
static inline float snd_volume(const Snd* s) { return s->volume; }
static inline int snd_count(Snd s, int i) { return s.state[i]; }
")

c facade sounds:
    resource Clip wraps Snd
        from snd_load
        drop snd_unload
    fn snd_load
        of Clip
        rename load
    fn snd_play
        of Clip
        rename play
        lend
    fn snd_set_volume
        of Clip
        rename volume
        lend
    fn snd_valid
        of Clip
        rename valid
        lend
    fn snd_retune
        of Clip
        rename retune
        lend
    fn snd_volume
        of Clip
        rename level
        lend

fn main:
    var clip = Clip.load("x")
    clip.volume(0.5)
    if clip.valid() != 0: clip.play()
    clip.play()
    clip.retune()
    assert(clip.level() == 0.25)
    let tok = clip.repr
    drop(clip)
    print(f"{snd_count(tok, 0)} {snd_count(tok, 1)} {snd_count(tok, 2)} {snd_count(tok, 3)}")
    print("ok")
