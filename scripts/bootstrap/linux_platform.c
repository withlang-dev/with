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
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/sysinfo.h>
#include <sys/time.h>
#include <sys/wait.h>
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

/* --- platform surface added after the original shim (mirrors
 * rt/linux_x86_64.w): stdio handles, lstat mode, readlink, wall clock,
 * rlimits, and the rt_compat_* process-exec boundary that
 * rt/compat_runtime.w declares as externs. --- */

/* runtime/sys/resource.h (shipped stub, first on the include path) no-ops
 * rlimits and only defines RLIMIT_STACK; keep these fallbacks so the same
 * code also builds against a real <sys/resource.h>. */
#ifndef RLIMIT_AS
#define RLIMIT_AS RLIMIT_STACK
#endif
#ifndef RLIM_INFINITY
#define RLIM_INFINITY (~0ULL)
#endif

void *rt_libc_stdin(void) { return stdin; }
void *rt_libc_stdout(void) { return stdout; }
void *rt_libc_stderr(void) { return stderr; }

int64_t rt_wall_clock_sec(void) {
    struct timespec ts;
    if (clock_gettime(CLOCK_REALTIME, &ts) != 0) return 0;
    return (int64_t)ts.tv_sec;
}

int32_t rt_file_mode(const uint8_t *path) {
    struct stat st;
    if (lstat(rt_cstr(path), &st) != 0) return -rt_errno();
    return (int32_t)st.st_mode;
}

with_str rt_readlink(const uint8_t *path) {
    char buf[4096];
    ssize_t n = readlink(rt_cstr(path), buf, sizeof(buf) - 1);
    if (n < 0) return rt_owned_str("");
    buf[n] = 0;
    return rt_owned_str(buf);
}

int32_t rt_set_process_memory_limit_bytes(int64_t limit) {
    if (limit <= 0) return 0;
    struct rlimit lim;
    if (getrlimit(RLIMIT_AS, &lim) != 0) return -1;
    uint64_t want = (uint64_t)limit;
    if (lim.rlim_max != RLIM_INFINITY && want > lim.rlim_max) want = lim.rlim_max;
    if (lim.rlim_cur != RLIM_INFINITY && lim.rlim_cur <= want) return 0;
    lim.rlim_cur = want;
    return setrlimit(RLIMIT_AS, &lim);
}

static char *rt_compat_str_to_cbuf(with_str s) {
    char *out = (char *)malloc((size_t)s.len + 1);
    if (out == NULL) return NULL;
    if (s.len > 0) memcpy(out, s.ptr, (size_t)s.len);
    out[s.len] = 0;
    return out;
}

static volatile sig_atomic_t rt_compat_interrupt_flag = 0;
static volatile int rt_compat_active_child_pgid = 0;

static void rt_compat_interrupt_handler(int signo) {
    rt_compat_interrupt_flag = 1;
    if (rt_compat_active_child_pgid > 0)
        kill(-rt_compat_active_child_pgid, signo);
    _exit(128 + signo);
}

int32_t rt_compat_setenv_str(with_str name, with_str value) {
    char *name_buf = rt_compat_str_to_cbuf(name);
    char *value_buf = rt_compat_str_to_cbuf(value);
    int rc = -1;
    if (name_buf != NULL && value_buf != NULL)
        rc = setenv(name_buf, value_buf, 1);
    free(name_buf);
    free(value_buf);
    return rc;
}

void rt_compat_install_interrupt_handlers(void) {
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = rt_compat_interrupt_handler;
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGHUP, &sa, NULL);
}

void rt_compat_raise_stack_limit(void) {
    struct rlimit lim;
    if (getrlimit(RLIMIT_STACK, &lim) != 0) return;
    uint64_t want = 8u * 1024 * 1024;
    if (lim.rlim_max != RLIM_INFINITY && want > lim.rlim_max) want = lim.rlim_max;
    if (want > lim.rlim_cur) {
        lim.rlim_cur = want;
        setrlimit(RLIMIT_STACK, &lim);
    }
}

int32_t rt_compat_interrupt_requested(void) { return rt_compat_interrupt_flag != 0; }

static int32_t rt_compat_wait_child(int pid, int32_t timeout_ms) {
    int status = -1;
    struct timespec start;
    clock_gettime(CLOCK_MONOTONIC, &start);
    for (;;) {
        pid_t waited = waitpid(pid, &status, timeout_ms > 0 ? WNOHANG : 0);
        if (waited == pid) {
            int termsig = status & 0x7f;
            if (termsig == 0) return (status >> 8) & 0xff;
            if (termsig != 0x7f) return 128 + termsig;
            return status;
        }
        if (waited < 0) {
            if (errno == EINTR) continue;
            return -1;
        }
        if (timeout_ms > 0) {
            struct timespec now;
            clock_gettime(CLOCK_MONOTONIC, &now);
            int64_t elapsed_ms = (int64_t)(now.tv_sec - start.tv_sec) * 1000 +
                                 (now.tv_nsec - start.tv_nsec) / 1000000;
            if (elapsed_ms >= timeout_ms) {
                kill(-pid, SIGTERM);
                usleep(10000);
                if (waitpid(pid, &status, WNOHANG) != pid) {
                    kill(-pid, SIGKILL);
                    waitpid(pid, &status, 0);
                }
                return 124; /* capture timeout rc, matches rt/linux_x86_64.w */
            }
            usleep(10000);
        }
    }
}

/* args blob: argv strings separated by NUL bytes, length-delimited. */
static int32_t rt_compat_run_argv(const char *blob, int64_t len,
                                  const char *stdout_path, const char *stderr_path,
                                  const char *stdin_path, const char *cwd,
                                  int32_t timeout_ms, int wait_child) {
    int argc = 0;
    for (int64_t off = 0; off < len;) {
        argc++;
        while (off < len && blob[off] != 0) off++;
        off++;
    }
    if (argc <= 0 || argc >= 256) return -1;
    sigset_t blocked, prev;
    sigemptyset(&blocked);
    sigaddset(&blocked, SIGINT);
    sigaddset(&blocked, SIGTERM);
    sigaddset(&blocked, SIGHUP);
    int mask_rc = sigprocmask(SIG_BLOCK, &blocked, &prev);
    pid_t pid = fork();
    if (pid == 0) {
        if (mask_rc == 0) sigprocmask(SIG_SETMASK, &prev, NULL);
        setpgid(0, 0);
        signal(SIGINT, SIG_DFL);
        signal(SIGTERM, SIG_DFL);
        signal(SIGHUP, SIG_DFL);
        signal(SIGQUIT, SIG_DFL);
        if (stdin_path != NULL) {
            int fd = open(stdin_path, O_RDONLY);
            if (fd < 0 || dup2(fd, 0) < 0) _exit(127);
            close(fd);
        }
        if (stdout_path != NULL) {
            int fd = open(stdout_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
            if (fd < 0 || dup2(fd, 1) < 0) _exit(127);
            close(fd);
        }
        if (stderr_path != NULL) {
            int fd = open(stderr_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
            if (fd < 0 || dup2(fd, 2) < 0) _exit(127);
            close(fd);
        }
        if (cwd != NULL) {
            if (chdir(cwd) != 0) _exit(127);
            setenv("PWD", cwd, 1);
        }
        const char *argv[256];
        int argi = 0;
        for (int64_t off = 0; off < len && argi < 255;) {
            argv[argi++] = blob + off;
            while (off < len && blob[off] != 0) off++;
            off++;
        }
        argv[argi] = NULL;
        execvp(argv[0], (char *const *)argv);
        _exit(127);
    }
    if (pid < 0) {
        if (mask_rc == 0) sigprocmask(SIG_SETMASK, &prev, NULL);
        return -1;
    }
    setpgid(pid, pid);
    if (mask_rc == 0) sigprocmask(SIG_SETMASK, &prev, NULL);
    if (!wait_child) return pid;
    rt_compat_active_child_pgid = pid;
    int32_t rc = rt_compat_wait_child(pid, timeout_ms);
    rt_compat_active_child_pgid = 0;
    return rc;
}

static int32_t rt_compat_exec_common(with_str args, const with_str *stdout_path,
                                     const with_str *stderr_path, const with_str *stdin_path,
                                     const with_str *cwd, int32_t timeout_ms, int wait_child) {
    if (rt_compat_interrupt_flag) return -1;
    char *arg_buf = rt_compat_str_to_cbuf(args);
    char *out_buf = stdout_path != NULL ? rt_compat_str_to_cbuf(*stdout_path) : NULL;
    char *err_buf = stderr_path != NULL ? rt_compat_str_to_cbuf(*stderr_path) : NULL;
    char *in_buf = stdin_path != NULL ? rt_compat_str_to_cbuf(*stdin_path) : NULL;
    char *cwd_buf = (cwd != NULL && cwd->len > 0) ? rt_compat_str_to_cbuf(*cwd) : NULL;
    int32_t rc = -1;
    if (arg_buf != NULL &&
        (stdout_path == NULL || out_buf != NULL) &&
        (stderr_path == NULL || err_buf != NULL) &&
        (stdin_path == NULL || in_buf != NULL))
        rc = rt_compat_run_argv(arg_buf, args.len, out_buf, err_buf, in_buf, cwd_buf,
                                timeout_ms, wait_child);
    free(arg_buf);
    free(out_buf);
    free(err_buf);
    free(in_buf);
    free(cwd_buf);
    return rc;
}

int32_t rt_compat_exec_binary(with_str path) {
    return rt_compat_exec_common(path, NULL, NULL, NULL, NULL, 0, 1);
}

int32_t rt_compat_exec_argv(with_str args) {
    return rt_compat_exec_common(args, NULL, NULL, NULL, NULL, 0, 1);
}

int32_t rt_compat_exec_argv_cwd(with_str args, with_str cwd) {
    return rt_compat_exec_common(args, NULL, NULL, NULL, &cwd, 0, 1);
}

int32_t rt_compat_exec_argv_capture(with_str args, with_str stdout_path, with_str stderr_path, int32_t timeout_ms) {
    return rt_compat_exec_common(args, &stdout_path, &stderr_path, NULL, NULL, timeout_ms, 1);
}

int32_t rt_compat_exec_argv_capture_input(with_str args, with_str stdout_path, with_str stderr_path, int32_t timeout_ms, with_str stdin_path) {
    return rt_compat_exec_common(args, &stdout_path, &stderr_path, &stdin_path, NULL, timeout_ms, 1);
}

int32_t rt_compat_exec_argv_capture_cwd(with_str args, with_str stdout_path, with_str stderr_path, int32_t timeout_ms, with_str cwd) {
    return rt_compat_exec_common(args, &stdout_path, &stderr_path, NULL, &cwd, timeout_ms, 1);
}

int32_t rt_compat_exec_argv_capture_spawn(with_str args, with_str stdout_path, with_str stderr_path) {
    return rt_compat_exec_common(args, &stdout_path, &stderr_path, NULL, NULL, 0, 0);
}

int32_t rt_compat_exec_wait(int32_t pid, int32_t timeout_ms) {
    if (pid <= 0) return -1;
    rt_compat_active_child_pgid = pid;
    int32_t rc = rt_compat_wait_child(pid, timeout_ms);
    rt_compat_active_child_pgid = 0;
    return rc;
}

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
WITH_EMPTY_EMBEDDED_OBJECT(fiber_stubs_o);
WITH_EMPTY_EMBEDDED_OBJECT(channel_runtime_o);
WITH_EMPTY_EMBEDDED_OBJECT(fiber_runtime_o);
WITH_EMPTY_EMBEDDED_OBJECT(fiber_o);
WITH_EMPTY_EMBEDDED_OBJECT(fiber_asm_o);
WITH_EMPTY_EMBEDDED_OBJECT(rt_core_o);
WITH_EMPTY_EMBEDDED_OBJECT(rt_darwin_aarch64_o);
WITH_EMPTY_EMBEDDED_OBJECT(rt_linux_x86_64_o);
WITH_EMPTY_EMBEDDED_OBJECT(rt_windows_x86_64_o);
