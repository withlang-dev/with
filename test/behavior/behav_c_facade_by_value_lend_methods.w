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
/* The counters are this snippet's own static state; a Snd holds its gain and no address (D198, spec 16.2b.5). */
static int snd_state_[4];
typedef struct { int loaded; float gain; } Snd;
static inline Snd snd_load(const char* path) { Snd s; s.loaded = 1; s.gain = 1.0f; snd_state_[0] = 0; snd_state_[1] = 0; snd_state_[2] = 0; snd_state_[3] = 0; return s; }
static inline void snd_unload(Snd s) { snd_state_[0]++; }
static inline void snd_play(Snd s) { snd_state_[1]++; }
static inline void snd_set_volume(Snd s, float v) { snd_state_[2] = (int)(v * 100.0f); }
static inline int snd_valid(Snd s) { return s.loaded != 0; }
static inline void snd_retune(Snd* s) { s->gain = 0.25f; snd_state_[3]++; }
static inline float snd_volume(const Snd* s) { return s->gain; }
static inline int snd_count(Snd s, int i) { return snd_state_[i]; }
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
    let tok = unsafe { clip.repr }
    drop(clip)
    print(f"{snd_count(tok, 0)} {snd_count(tok, 1)} {snd_count(tok, 2)} {snd_count(tok, 3)}")
    print("ok")
