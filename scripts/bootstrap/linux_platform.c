#define _GNU_SOURCE
#include "with_runtime.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/random.h>
#include <sys/stat.h>
#include <sys/sysinfo.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>

static int rt_errno(void) { return errno == 0 ? EIO : errno; }

static char *rt_cstr(const uint8_t *p) {
    return (char *)p;
}

static with_str rt_owned_str(const char *s) {
    size_t len = strlen(s);
    char *out = (char *)malloc(len == 0 ? 1 : len);
    if (len != 0 && out != NULL) memcpy(out, s, len);
    return (with_str){ .ptr = (uint8_t *)out, .len = (int64_t)len };
}

int64_t rt_write(int32_t fd, const uint8_t *buf, uint64_t len) {
    ssize_t r;
    do { r = write(fd, buf, (size_t)len); } while (r < 0 && errno == EINTR);
    return r < 0 ? -(int64_t)rt_errno() : (int64_t)r;
}

int64_t rt_read(int32_t fd, uint8_t *buf, uint64_t len) {
    ssize_t r;
    do { r = read(fd, buf, (size_t)len); } while (r < 0 && errno == EINTR);
    return r < 0 ? -(int64_t)rt_errno() : (int64_t)r;
}

int32_t rt_open(const uint8_t *path, int32_t flags, int32_t mode) {
    int native = flags & 3;
    if ((flags & 0x200) != 0) native |= O_CREAT;
    if ((flags & 0x400) != 0) native |= O_TRUNC;
    if ((flags & 0x800) != 0) native |= O_APPEND;
    int r;
    do { r = open(rt_cstr(path), native, (mode_t)mode); } while (r < 0 && errno == EINTR);
    return r < 0 ? -rt_errno() : r;
}

int32_t rt_close(int32_t fd) {
    int r;
    do { r = close(fd); } while (r < 0 && errno == EINTR);
    return r < 0 ? -rt_errno() : 0;
}

int64_t rt_seek(int32_t fd, int64_t offset, int32_t whence) {
    off_t r = lseek(fd, (off_t)offset, whence);
    return r < 0 ? -(int64_t)rt_errno() : (int64_t)r;
}

uint8_t *rt_mmap(uint64_t size) {
    void *p = mmap(NULL, (size_t)size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    return p == MAP_FAILED ? NULL : (uint8_t *)p;
}

void rt_munmap(uint8_t *ptr, uint64_t size) {
    if (ptr != NULL && size != 0) munmap(ptr, (size_t)size);
}

void rt_exit(int32_t code) { _exit(code); }

int64_t rt_clock_ns(void) {
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) return 0;
    return (int64_t)ts.tv_sec * 1000000000LL + (int64_t)ts.tv_nsec;
}

const uint8_t *rt_getenv(const uint8_t *name) {
    return (const uint8_t *)getenv(rt_cstr(name));
}

static int saved_argc = 0;
static const char **saved_argv = NULL;

void rt_store_args(int32_t argc, const uint8_t *const *argv) {
    saved_argc = argc;
    saved_argv = (const char **)argv;
    (void)saved_argc;
    (void)saved_argv;
}

int32_t rt_nanosleep(int64_t ns) {
    struct timespec req;
    req.tv_sec = ns / 1000000000LL;
    req.tv_nsec = ns % 1000000000LL;
    while (nanosleep(&req, &req) != 0) {
        if (errno != EINTR) return -rt_errno();
    }
    return 0;
}

int32_t rt_getpid(void) { return (int32_t)getpid(); }
int32_t rt_raise(int32_t sig) { return raise(sig) == 0 ? 0 : -rt_errno(); }
int32_t rt_kill(int32_t pid, int32_t sig) { return kill((pid_t)pid, sig) == 0 ? 0 : -rt_errno(); }

int32_t rt_sysinfo(uint8_t *out) {
    struct sysinfo info;
    if (sysinfo(&info) != 0) return -rt_errno();
    memcpy(out, &info, sizeof(info));
    return 0;
}

with_str rt_sysinfo_os(void) {
    return (with_str){ .ptr = (uint8_t *)"Linux", .len = 5 };
}

with_str rt_sysinfo_arch(void) {
    return (with_str){ .ptr = (uint8_t *)"x86_64", .len = 6 };
}

int64_t rt_thread_spawn(uint8_t *start_routine, uint8_t *arg) {
    pthread_t thread;
    if (pthread_create(&thread, NULL, (void *(*)(void *))start_routine, arg) != 0) return 0;
    return (int64_t)(uintptr_t)thread;
}

int32_t rt_thread_join(int64_t handle) {
    return pthread_join((pthread_t)(uintptr_t)handle, NULL) == 0 ? 0 : -rt_errno();
}

int32_t rt_mkdir(const uint8_t *path, int32_t mode) { return mkdir(rt_cstr(path), (mode_t)mode) == 0 ? 0 : -rt_errno(); }
int32_t rt_unlink(const uint8_t *path) { return unlink(rt_cstr(path)) == 0 ? 0 : -rt_errno(); }
int32_t rt_rmdir(const uint8_t *path) { return rmdir(rt_cstr(path)) == 0 ? 0 : -rt_errno(); }
int32_t rt_rename(const uint8_t *old_path, const uint8_t *new_path) { return rename(rt_cstr(old_path), rt_cstr(new_path)) == 0 ? 0 : -rt_errno(); }
int32_t rt_symlink(const uint8_t *target, const uint8_t *link_path) { return symlink(rt_cstr(target), rt_cstr(link_path)) == 0 ? 0 : -rt_errno(); }
int32_t rt_access(const uint8_t *path, int32_t mode) { return access(rt_cstr(path), mode) == 0 ? 0 : -rt_errno(); }
int32_t rt_chmod(const uint8_t *path, int32_t mode) { return chmod(rt_cstr(path), (mode_t)mode) == 0 ? 0 : -rt_errno(); }

int32_t rt_stat(const uint8_t *path, uint8_t *out) {
    struct stat st;
    if (stat(rt_cstr(path), &st) != 0) return -rt_errno();
    int64_t *fields = (int64_t *)out;
    fields[0] = (int64_t)st.st_size;
    fields[1] = S_ISDIR(st.st_mode) ? 1 : 0;
    fields[2] = S_ISREG(st.st_mode) ? 1 : 0;
    fields[3] = (int64_t)st.st_mtim.tv_sec * 1000000000LL + (int64_t)st.st_mtim.tv_nsec;
    return 0;
}

static int rt_remove_tree_cstr(const char *path) {
    struct stat st;
    if (lstat(path, &st) != 0) return -rt_errno();
    if (!S_ISDIR(st.st_mode)) return unlink(path) == 0 ? 0 : -rt_errno();
    DIR *dir = opendir(path);
    if (dir == NULL) return -rt_errno();
    struct dirent *ent;
    while ((ent = readdir(dir)) != NULL) {
        if (strcmp(ent->d_name, ".") == 0 || strcmp(ent->d_name, "..") == 0) continue;
        size_t n = strlen(path) + 1 + strlen(ent->d_name) + 1;
        char *child = (char *)malloc(n);
        if (child == NULL) { closedir(dir); return -ENOMEM; }
        snprintf(child, n, "%s/%s", path, ent->d_name);
        int rc = rt_remove_tree_cstr(child);
        free(child);
        if (rc != 0) { closedir(dir); return rc; }
    }
    closedir(dir);
    return rmdir(path) == 0 ? 0 : -rt_errno();
}

int32_t rt_remove_tree(const uint8_t *path) { return rt_remove_tree_cstr(rt_cstr(path)); }

int32_t rt_copy_tree(const uint8_t *src, const uint8_t *dst) {
    (void)src;
    (void)dst;
    return -ENOSYS;
}

static int rt_list_append(char **buf, size_t *len, size_t *cap, const char *path) {
    size_t path_len = strlen(path);
    if (*len + path_len + 1 > *cap) {
        while (*len + path_len + 1 > *cap) *cap *= 2;
        char *next = (char *)realloc(*buf, *cap);
        if (next == NULL) return -ENOMEM;
        *buf = next;
    }
    memcpy(*buf + *len, path, path_len);
    *len += path_len;
    (*buf)[(*len)++] = '\n';
    return 0;
}

static int rt_list_walk(const char *path, char **buf, size_t *len, size_t *cap) {
    struct stat st;
    if (lstat(path, &st) != 0) return -rt_errno();
    if (!S_ISDIR(st.st_mode)) return rt_list_append(buf, len, cap, path);
    DIR *dir = opendir(path);
    if (dir == NULL) return -rt_errno();
    struct dirent *ent;
    while ((ent = readdir(dir)) != NULL) {
        if (strcmp(ent->d_name, ".") == 0 || strcmp(ent->d_name, "..") == 0) continue;
        size_t base_len = strlen(path);
        size_t name_len = strlen(ent->d_name);
        char *child = (char *)malloc(base_len + 1 + name_len + 1);
        if (child == NULL) { closedir(dir); return -ENOMEM; }
        memcpy(child, path, base_len);
        child[base_len] = '/';
        memcpy(child + base_len + 1, ent->d_name, name_len + 1);
        int rc = rt_list_walk(child, buf, len, cap);
        free(child);
        if (rc != 0) { closedir(dir); return rc; }
    }
    closedir(dir);
    return 0;
}

with_str rt_list_files(const uint8_t *path) {
    size_t cap = 256;
    size_t len = 0;
    char *buf = (char *)malloc(cap);
    if (buf == NULL) return rt_owned_str("");
    int rc = rt_list_walk(rt_cstr(path), &buf, &len, &cap);
    if (rc != 0) {
        free(buf);
        return rt_owned_str("");
    }
    return (with_str){ .ptr = (uint8_t *)buf, .len = (int64_t)len };
}

void arc4random_buf(void *buf, size_t len) {
    uint8_t *p = (uint8_t *)buf;
    size_t off = 0;
    while (off < len) {
        ssize_t n = getrandom(p + off, len - off, 0);
        if (n > 0) { off += (size_t)n; continue; }
        if (errno == EINTR) continue;
        break;
    }
    if (off < len) {
        int fd = open("/dev/urandom", O_RDONLY);
        if (fd >= 0) {
            while (off < len) {
                ssize_t n = read(fd, p + off, len - off);
                if (n > 0) off += (size_t)n;
                else if (errno != EINTR) break;
            }
            close(fd);
        }
    }
}

void rt_fill_random(uint8_t *buf, uint64_t len) {
    arc4random_buf(buf, (size_t)len);
}

int *__error(void) { return __errno_location(); }

int __open(const uint8_t *path, int flags, int mode) {
    int native = flags & 3;
    if (flags & 0x0008) native |= O_APPEND;
    if (flags & 0x0200) native |= O_CREAT;
    if (flags & 0x0400) native |= O_TRUNC;
    if (flags & 0x0800) native |= O_EXCL;
    return open((const char *)path, native, (mode_t)mode);
}

#define WITH_EMPTY_EMBEDDED_OBJECT(name) \
    __asm__(".section .rodata\n" \
            ".globl with_embedded_" #name "_start\n" \
            "with_embedded_" #name "_start:\n" \
            ".globl with_embedded_" #name "_end\n" \
            "with_embedded_" #name "_end:\n" \
            ".previous\n")

WITH_EMPTY_EMBEDDED_OBJECT(cimport_stubs_o);
WITH_EMPTY_EMBEDDED_OBJECT(compat_runtime_o);
WITH_EMPTY_EMBEDDED_OBJECT(panic_runtime_o);
WITH_EMPTY_EMBEDDED_OBJECT(regex_runtime_o);
WITH_EMPTY_EMBEDDED_OBJECT(fiber_stubs_o);
WITH_EMPTY_EMBEDDED_OBJECT(channel_runtime_o);
WITH_EMPTY_EMBEDDED_OBJECT(fiber_runtime_o);
WITH_EMPTY_EMBEDDED_OBJECT(fiber_o);
WITH_EMPTY_EMBEDDED_OBJECT(fiber_asm_o);
WITH_EMPTY_EMBEDDED_OBJECT(rt_core_o);
WITH_EMPTY_EMBEDDED_OBJECT(rt_darwin_aarch64_o);
WITH_EMPTY_EMBEDDED_OBJECT(rt_linux_x86_64_o);
WITH_EMPTY_EMBEDDED_OBJECT(rt_windows_x86_64_o);
