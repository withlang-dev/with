#ifndef WITH_BOOTSTRAP_UNISTD_H
#define WITH_BOOTSTRAP_UNISTD_H

#include <stdint.h>
#include <stddef.h>

typedef long ssize_t;

#ifndef STDIN_FILENO
#define STDIN_FILENO 0
#endif
#ifndef STDOUT_FILENO
#define STDOUT_FILENO 1
#endif
#ifndef STDERR_FILENO
#define STDERR_FILENO 2
#endif

int close(int fd);
int64_t read(int fd, void *buf, uint64_t len);
int64_t write(int fd, const void *buf, uint64_t len);
int64_t lseek(int fd, int64_t offset, int whence);
int access(const char *path, int mode);
int rmdir(const char *path);
int unlink(const char *path);
int getpid(void);
int mkstemp(char *template_path);
char *realpath(const char *path, char *resolved_path);
int gethostname(void *name, uint64_t len);

#endif
