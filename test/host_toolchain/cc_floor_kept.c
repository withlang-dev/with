/* #3603: names an archive built against a newer glibc reaches without
   asking (its headers turn fstat and strtol into these) still link. */
char fstat(void);
char __isoc23_strtol(void);
int main(int argc, char **argv) { return argc > 99 ? fstat() + __isoc23_strtol() : 0; }
