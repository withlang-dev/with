// ECS update: structure-of-arrays storage, bitmask queries, 1M entities.
// Timed region: 1000 ticks of movement, damage, and cleanup systems.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define ENTITIES 1000000
#define TICKS 1000
#define HAS_POS 1
#define HAS_VEL 2
#define HAS_HP 4
#define HAS_DMG 8

typedef struct { float x, y; } Position;
typedef struct { float x, y; } Velocity;
typedef struct { float hp; } Health;
typedef struct { float dps; } Damage;

typedef struct {
    uint8_t *mask;
    Position *pos;
    Velocity *vel;
    Health *hp;
    Damage *dmg;
    int count;
} World;

static double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1000000.0;
}

static World world_new(void) {
    World w;
    w.mask = calloc(ENTITIES, sizeof(uint8_t));
    w.pos = calloc(ENTITIES, sizeof(Position));
    w.vel = calloc(ENTITIES, sizeof(Velocity));
    w.hp = calloc(ENTITIES, sizeof(Health));
    w.dmg = calloc(ENTITIES, sizeof(Damage));
    w.count = 0;
    return w;
}

static void system_movement(World *w, float dt) {
    const uint8_t need = HAS_POS | HAS_VEL;
    for (int i = 0; i < w->count; i++) {
        if ((w->mask[i] & need) == need) {
            w->pos[i].x += w->vel[i].x * dt;
            w->pos[i].y += w->vel[i].y * dt;
        }
    }
}

static void system_damage(World *w, float dt) {
    const uint8_t need = HAS_HP | HAS_DMG;
    for (int i = 0; i < w->count; i++) {
        if ((w->mask[i] & need) == need) w->hp[i].hp -= w->dmg[i].dps * dt;
    }
}

static void system_cleanup(World *w) {
    for (int i = 0; i < w->count; i++) {
        if ((w->mask[i] & HAS_HP) != 0 && w->hp[i].hp <= 0.0f) w->mask[i] = 0;
    }
}

static int count_alive(const World *w) {
    int n = 0;
    for (int i = 0; i < w->count; i++) if (w->mask[i] != 0) n++;
    return n;
}

int main(void) {
    World w = world_new();
    // 70% move, 50% have health, 30% take damage.
    for (uint32_t i = 0; i < ENTITIES; i++) {
        int id = w.count++;
        float fi = (float)i;
        if (i % 10 < 7) {
            w.mask[id] |= HAS_POS; w.pos[id] = (Position){ fi * 0.1f, fi * 0.2f };
            w.mask[id] |= HAS_VEL; w.vel[id] = (Velocity){ ((float)(i % 100)) * 0.01f, ((float)((i + 50) % 100)) * 0.01f };
        }
        if (i % 10 < 5) { w.mask[id] |= HAS_HP; w.hp[id] = (Health){ 100.0f }; }
        if (i % 10 < 3) { w.mask[id] |= HAS_DMG; w.dmg[id] = (Damage){ 0.5f + ((float)(i % 10)) * 0.1f }; }
    }
    int alive_before = count_alive(&w);

    double start = now_ms();
    float dt = 1.0f / 60.0f;
    for (int t = 0; t < TICKS; t++) {
        system_movement(&w, dt);
        system_damage(&w, dt);
        system_cleanup(&w);
    }
    double elapsed_ms = now_ms() - start;

    double sum = 0.0;
    for (int i = 0; i < w.count; i++) if (w.mask[i] & HAS_POS) sum += (double)w.pos[i].x;
    printf("entities %d alive_before %d alive_after %d\n", w.count, alive_before, count_alive(&w));
    printf("elapsed_ms %.3f\n", elapsed_ms);
    printf("checksum %.2f\n", sum);
    free(w.mask); free(w.pos); free(w.vel); free(w.hp); free(w.dmg);
    return 0;
}
