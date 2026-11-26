typedef struct { unsigned type; int key; } KeyEv;
typedef struct { unsigned type; int x; } MoveEv;
typedef union { unsigned type; KeyEv key; MoveEv motion; } Ev;
#define EV_KEY 1
#define EV_MOVE 2
#define EV_WIN_A 10
#define EV_WIN_B 12
static int ev_n = 0;
static inline _Bool ev_poll(Ev* out) { ev_n++; if (ev_n == 1) { out->key.type = EV_KEY; out->key.key = 65; return 1; } if (ev_n == 2) { out->motion.type = EV_MOVE; out->motion.x = 7; return 1; } if (ev_n == 3) { out->type = 11; return 1; } if (ev_n == 4) { out->type = 99; return 1; } return 0; }
