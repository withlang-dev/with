typedef struct { unsigned type; int key; } KeyEv;
typedef struct { unsigned type; int x; } MoveEv;
typedef union { unsigned type; KeyEv key; MoveEv motion; float f; } Ev;
#define EV_KEY 1
#define EV_MOVE 2
#define EV_A 10
#define EV_B 12
static inline _Bool ev_poll(Ev* out) { return 0; }
static inline int ev_poll_int(Ev* out) { return 0; }
static inline _Bool ev_peek(const Ev* out) { return 0; }
typedef struct { int tag; unsigned char* data; int size; } Msg;
static inline _Bool msg_next(Msg* out) { return 0; }
static inline void msg_free(void) {}
static inline void msg_release(int a, int b) {}
