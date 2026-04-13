static inline int issue114_if_assign(unsigned long patlen) {
  int zero_terminated = 0;
  int adjusted = (int)patlen;
  if ((zero_terminated = (patlen == 42)))
    adjusted = 7;
  return zero_terminated * 10 + adjusted;
}

static inline int issue114_compare_assign(int x) {
  int seen = 0;
  if ((seen = x) == 3)
    return seen + 10;
  return seen;
}

static inline int issue114_logical_assign(int x) {
  int seen = 0;
  if (((seen = x) != 0) && x > 2)
    return seen + 20;
  return seen;
}

static inline int issue114_while_assign(int start) {
  int n = start;
  int total = 0;
  while ((n = n - 1) != 0)
    total += n;
  return total;
}

static inline int issue114_for_assign(int start) {
  int n;
  int total = 0;
  for (n = start; (n = n - 1) != 0; )
    total += n;
  return total;
}

static inline int issue114_do_assign(int start) {
  int n = start;
  int total = 0;
  do {
    total += n;
  } while ((n = n - 1) != 0);
  return total;
}
