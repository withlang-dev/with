// Binary trees: allocation-heavy recursive tree build and check, depth 18.
// Timed region: everything. Checksum: sum of all node counts.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define MIN_DEPTH 4
#define MAX_DEPTH 18

typedef struct Node { struct Node *left, *right; } Node;

static double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1000000.0;
}

static Node *bottom_up(int depth) {
    Node *node = malloc(sizeof(Node));
    if (depth == 0) {
        node->left = NULL;
        node->right = NULL;
    } else {
        node->left = bottom_up(depth - 1);
        node->right = bottom_up(depth - 1);
    }
    return node;
}

static int64_t check(const Node *node) {
    int64_t left = node->left ? check(node->left) : 0;
    int64_t right = node->right ? check(node->right) : 0;
    return 1 + left + right;
}

static void release(Node *node) {
    if (!node) return;
    release(node->left);
    release(node->right);
    free(node);
}

int main(void) {
    double start = now_ms();
    int64_t total = 0;
    Node *stretch = bottom_up(MAX_DEPTH + 1);
    total += check(stretch);
    release(stretch);
    Node *long_lived = bottom_up(MAX_DEPTH);
    for (int depth = MIN_DEPTH; depth <= MAX_DEPTH; depth += 2) {
        int iterations = 1 << (MAX_DEPTH - depth + MIN_DEPTH);
        for (int i = 0; i < iterations; i++) {
            Node *tree = bottom_up(depth);
            total += check(tree);
            release(tree);
        }
    }
    total += check(long_lived);
    release(long_lived);
    double elapsed_ms = now_ms() - start;
    printf("max_depth %d\n", MAX_DEPTH);
    printf("elapsed_ms %.3f\n", elapsed_ms);
    printf("checksum %lld\n", (long long)total);
    return 0;
}
