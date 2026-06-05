#include "with_runtime.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

static int rt_errno(void) {
    DWORD e = GetLastError();
    return e == 0 ? ERROR_INVALID_FUNCTION : (int)e;
}

static char *rt_cstr(const uint8_t *p) { return (char *)p; }

static with_str rt_owned_str(const char *s) {
    size_t len = strlen(s);
    char *out = (char *)malloc(len == 0 ? 1 : len);
    if (len != 0 && out != NULL) memcpy(out, s, len);
    return (with_str){ .ptr = (uint8_t *)out, .len = (int64_t)len };
}

static int fd_to_handle(int32_t fd, HANDLE *out) {
    if (fd == 0) *out = GetStdHandle(STD_INPUT_HANDLE);
    else if (fd == 1) *out = GetStdHandle(STD_OUTPUT_HANDLE);
    else if (fd == 2) *out = GetStdHandle(STD_ERROR_HANDLE);
    else *out = (HANDLE)(intptr_t)fd;
    return *out == NULL || *out == INVALID_HANDLE_VALUE ? -1 : 0;
}

static int32_t handle_to_fd(HANDLE h) {
    intptr_t v = (intptr_t)h;
    return (int32_t)v;
}

int64_t rt_write(int32_t fd, const uint8_t *buf, uint64_t len) {
    HANDLE h;
    if (fd_to_handle(fd, &h) != 0) return -(int64_t)ERROR_INVALID_HANDLE;
    DWORD written = 0;
    if (!WriteFile(h, buf, (DWORD)len, &written, NULL)) return -(int64_t)rt_errno();
    return (int64_t)written;
}

int64_t rt_read(int32_t fd, uint8_t *buf, uint64_t len) {
    HANDLE h;
    if (fd_to_handle(fd, &h) != 0) return -(int64_t)ERROR_INVALID_HANDLE;
    DWORD got = 0;
    if (!ReadFile(h, buf, (DWORD)len, &got, NULL)) return -(int64_t)rt_errno();
    return (int64_t)got;
}

int32_t rt_open(const uint8_t *path, int32_t flags, int32_t mode) {
    (void)mode;
    DWORD access = GENERIC_READ;
    if ((flags & 3) == 1) access = GENERIC_WRITE;
    else if ((flags & 3) == 2) access = GENERIC_READ | GENERIC_WRITE;
    DWORD creation = OPEN_EXISTING;
    if ((flags & 0x200) != 0 && (flags & 0x400) != 0) creation = CREATE_ALWAYS;
    else if ((flags & 0x200) != 0) creation = OPEN_ALWAYS;
    else if ((flags & 0x400) != 0) creation = TRUNCATE_EXISTING;
    HANDLE h = CreateFileA(rt_cstr(path), access, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                           NULL, creation, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE) return -rt_errno();
    if ((flags & 0x800) != 0) SetFilePointer(h, 0, NULL, FILE_END);
    return handle_to_fd(h);
}

int32_t rt_close(int32_t fd) {
    if (fd >= 0 && fd <= 2) return 0;
    HANDLE h = (HANDLE)(intptr_t)fd;
    return CloseHandle(h) ? 0 : -rt_errno();
}

int64_t rt_seek(int32_t fd, int64_t offset, int32_t whence) {
    HANDLE h;
    if (fd_to_handle(fd, &h) != 0) return -(int64_t)ERROR_INVALID_HANDLE;
    DWORD method = FILE_BEGIN;
    if (whence == 1) method = FILE_CURRENT;
    else if (whence == 2) method = FILE_END;
    LARGE_INTEGER in;
    LARGE_INTEGER out;
    in.QuadPart = offset;
    if (!SetFilePointerEx(h, in, &out, method)) return -(int64_t)rt_errno();
    return out.QuadPart;
}

uint8_t *rt_mmap(uint64_t size) {
    return (uint8_t *)VirtualAlloc(NULL, (SIZE_T)size, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
}

void rt_munmap(uint8_t *ptr, uint64_t size) {
    (void)size;
    if (ptr != NULL) VirtualFree(ptr, 0, MEM_RELEASE);
}

void rt_exit(int32_t code) { ExitProcess((UINT)code); }

int64_t rt_clock_ns(void) {
    static LARGE_INTEGER freq;
    if (freq.QuadPart == 0) QueryPerformanceFrequency(&freq);
    LARGE_INTEGER now;
    QueryPerformanceCounter(&now);
    return (int64_t)((now.QuadPart * 1000000000LL) / freq.QuadPart);
}

const uint8_t *rt_getenv(const uint8_t *name) { return (const uint8_t *)getenv(rt_cstr(name)); }

static int saved_argc = 0;
static const char **saved_argv = NULL;

void rt_store_args(int32_t argc, const uint8_t *const *argv) {
    saved_argc = argc;
    saved_argv = (const char **)argv;
}

with_str rt_args(void) {
    size_t len = 0;
    for (int i = 0; i < saved_argc; i++) len += strlen(saved_argv[i]) + 1;
    char *out = (char *)malloc(len == 0 ? 1 : len);
    if (out == NULL) return rt_owned_str("");
    size_t off = 0;
    for (int i = 0; i < saved_argc; i++) {
        size_t n = strlen(saved_argv[i]);
        memcpy(out + off, saved_argv[i], n);
        off += n;
        out[off++] = 0;
    }
    return (with_str){ .ptr = (uint8_t *)out, .len = (int64_t)off };
}

int32_t rt_nanosleep(int64_t ns) {
    Sleep((DWORD)((ns + 999999LL) / 1000000LL));
    return 0;
}

int32_t rt_getpid(void) { return (int32_t)GetCurrentProcessId(); }
int32_t rt_raise(int32_t sig) { (void)sig; return 0; }
int32_t rt_kill(int32_t pid, int32_t sig) {
    (void)sig;
    HANDLE h = OpenProcess(PROCESS_TERMINATE, FALSE, (DWORD)pid);
    if (h == NULL) return -rt_errno();
    int ok = TerminateProcess(h, 1);
    CloseHandle(h);
    return ok ? 0 : -rt_errno();
}

int32_t rt_sysinfo(uint8_t *out) {
    memset(out, 0, 64);
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    *(uint32_t *)(out + 8) = si.dwPageSize;
    *(uint32_t *)(out + 36) = si.dwNumberOfProcessors;
    MEMORYSTATUSEX mem;
    memset(&mem, 0, sizeof(mem));
    mem.dwLength = sizeof(mem);
    if (GlobalMemoryStatusEx(&mem)) *(uint64_t *)(out + 8) = mem.ullTotalPhys;
    return 0;
}

with_str rt_sysinfo_os(void) { return (with_str){ .ptr = (uint8_t *)"Windows", .len = 7 }; }
with_str rt_sysinfo_arch(void) { return (with_str){ .ptr = (uint8_t *)"x86_64", .len = 6 }; }

static DWORD WINAPI thread_thunk(LPVOID arg) {
    void **pair = (void **)arg;
    void *(*fn)(void *) = (void *(*)(void *))pair[0];
    void *ctx = pair[1];
    free(pair);
    fn(ctx);
    return 0;
}

int64_t rt_thread_spawn(uint8_t *start_routine, uint8_t *arg) {
    void **pair = (void **)malloc(sizeof(void *) * 2);
    if (pair == NULL) return 0;
    pair[0] = start_routine;
    pair[1] = arg;
    HANDLE h = CreateThread(NULL, 0, thread_thunk, pair, 0, NULL);
    if (h == NULL) { free(pair); return 0; }
    return (int64_t)(intptr_t)h;
}

int32_t rt_thread_join(int64_t handle) {
    HANDLE h = (HANDLE)(intptr_t)handle;
    WaitForSingleObject(h, INFINITE);
    CloseHandle(h);
    return 0;
}

int32_t rt_mkdir(const uint8_t *path, int32_t mode) {
    (void)mode;
    return CreateDirectoryA(rt_cstr(path), NULL) || GetLastError() == ERROR_ALREADY_EXISTS ? 0 : -rt_errno();
}

int32_t rt_unlink(const uint8_t *path) { return DeleteFileA(rt_cstr(path)) ? 0 : -rt_errno(); }
int32_t rt_rmdir(const uint8_t *path) { return RemoveDirectoryA(rt_cstr(path)) ? 0 : -rt_errno(); }
int32_t rt_rename(const uint8_t *old_path, const uint8_t *new_path) {
    return MoveFileExA(rt_cstr(old_path), rt_cstr(new_path), MOVEFILE_REPLACE_EXISTING) ? 0 : -rt_errno();
}
int32_t rt_symlink(const uint8_t *target, const uint8_t *link_path) {
    DWORD attrs = GetFileAttributesA(rt_cstr(target));
    DWORD flags = SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE;
    if (attrs != INVALID_FILE_ATTRIBUTES && (attrs & FILE_ATTRIBUTE_DIRECTORY)) flags |= SYMBOLIC_LINK_FLAG_DIRECTORY;
    return CreateSymbolicLinkA(rt_cstr(link_path), rt_cstr(target), flags) ? 0 : -rt_errno();
}
int32_t rt_access(const uint8_t *path, int32_t mode) {
    (void)mode;
    return GetFileAttributesA(rt_cstr(path)) == INVALID_FILE_ATTRIBUTES ? -rt_errno() : 0;
}
int32_t rt_chmod(const uint8_t *path, int32_t mode) {
    DWORD attrs = GetFileAttributesA(rt_cstr(path));
    if (attrs == INVALID_FILE_ATTRIBUTES) return -rt_errno();
    if ((mode & 0222) != 0) attrs &= ~FILE_ATTRIBUTE_READONLY;
    else attrs |= FILE_ATTRIBUTE_READONLY;
    return SetFileAttributesA(rt_cstr(path), attrs) ? 0 : -rt_errno();
}

int32_t rt_stat(const uint8_t *path, uint8_t *out) {
    WIN32_FILE_ATTRIBUTE_DATA data;
    if (!GetFileAttributesExA(rt_cstr(path), GetFileExInfoStandard, &data)) return -rt_errno();
    int64_t *fields = (int64_t *)out;
    uint64_t size = ((uint64_t)data.nFileSizeHigh << 32) | data.nFileSizeLow;
    uint64_t ticks = ((uint64_t)data.ftLastWriteTime.dwHighDateTime << 32) | data.ftLastWriteTime.dwLowDateTime;
    fields[0] = (int64_t)size;
    fields[1] = (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) ? 1 : 0;
    fields[2] = (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) ? 0 : 1;
    fields[3] = (int64_t)((ticks - 116444736000000000ULL) * 100ULL);
    return 0;
}

static int remove_tree_cstr(const char *path) {
    DWORD attrs = GetFileAttributesA(path);
    if (attrs == INVALID_FILE_ATTRIBUTES) return -rt_errno();
    if ((attrs & FILE_ATTRIBUTE_DIRECTORY) == 0) return DeleteFileA(path) ? 0 : -rt_errno();
    char pattern[MAX_PATH * 4];
    snprintf(pattern, sizeof(pattern), "%s\\*", path);
    WIN32_FIND_DATAA data;
    HANDLE h = FindFirstFileA(pattern, &data);
    if (h != INVALID_HANDLE_VALUE) {
        do {
            if (strcmp(data.cFileName, ".") == 0 || strcmp(data.cFileName, "..") == 0) continue;
            char child[MAX_PATH * 4];
            snprintf(child, sizeof(child), "%s\\%s", path, data.cFileName);
            int rc = remove_tree_cstr(child);
            if (rc != 0) { FindClose(h); return rc; }
        } while (FindNextFileA(h, &data));
        FindClose(h);
    }
    return RemoveDirectoryA(path) ? 0 : -rt_errno();
}

int32_t rt_remove_tree(const uint8_t *path) { return remove_tree_cstr(rt_cstr(path)); }
int32_t rt_copy_tree(const uint8_t *src, const uint8_t *dst) { (void)src; (void)dst; return -ERROR_NOT_SUPPORTED; }

static int list_append(char **buf, size_t *len, size_t *cap, const char *path) {
    size_t n = strlen(path);
    if (*len + n + 1 > *cap) {
        while (*len + n + 1 > *cap) *cap *= 2;
        char *next = (char *)realloc(*buf, *cap);
        if (next == NULL) return -ERROR_OUTOFMEMORY;
        *buf = next;
    }
    memcpy(*buf + *len, path, n);
    *len += n;
    (*buf)[(*len)++] = '\n';
    return 0;
}

static int list_walk(const char *path, char **buf, size_t *len, size_t *cap) {
    DWORD attrs = GetFileAttributesA(path);
    if (attrs == INVALID_FILE_ATTRIBUTES) return -rt_errno();
    if ((attrs & FILE_ATTRIBUTE_DIRECTORY) == 0) return list_append(buf, len, cap, path);
    char pattern[MAX_PATH * 4];
    snprintf(pattern, sizeof(pattern), "%s\\*", path);
    WIN32_FIND_DATAA data;
    HANDLE h = FindFirstFileA(pattern, &data);
    if (h == INVALID_HANDLE_VALUE) return 0;
    do {
        if (strcmp(data.cFileName, ".") == 0 || strcmp(data.cFileName, "..") == 0) continue;
        char child[MAX_PATH * 4];
        snprintf(child, sizeof(child), "%s\\%s", path, data.cFileName);
        int rc = list_walk(child, buf, len, cap);
        if (rc != 0) { FindClose(h); return rc; }
    } while (FindNextFileA(h, &data));
    FindClose(h);
    return 0;
}

with_str rt_list_files(const uint8_t *path) {
    size_t cap = 256;
    size_t len = 0;
    char *buf = (char *)malloc(cap);
    if (buf == NULL) return rt_owned_str("");
    int rc = list_walk(rt_cstr(path), &buf, &len, &cap);
    if (rc != 0) { free(buf); return rt_owned_str(""); }
    return (with_str){ .ptr = (uint8_t *)buf, .len = (int64_t)len };
}

void rt_fill_random(uint8_t *buf, uint64_t len) {
    HMODULE advapi = LoadLibraryA("advapi32.dll");
    BOOLEAN (APIENTRY *rtl_gen_random)(PVOID, ULONG) = NULL;
    if (advapi != NULL) rtl_gen_random = (BOOLEAN (APIENTRY *)(PVOID, ULONG))GetProcAddress(advapi, "SystemFunction036");
    if (rtl_gen_random != NULL && rtl_gen_random(buf, (ULONG)len)) return;
    for (uint64_t i = 0; i < len; i++) buf[i] = (uint8_t)(rand() & 0xff);
}

int __open(const uint8_t *path, int flags, int mode) { return rt_open(path, flags, mode); }
int unlink(const char *path) { return DeleteFileA(path) ? 0 : -1; }

int mkstemp(char *template_path) {
    char dir[MAX_PATH];
    DWORD n = GetTempPathA((DWORD)sizeof(dir), dir);
    if (n == 0 || n >= sizeof(dir)) return -1;
    char name[MAX_PATH];
    if (GetTempFileNameA(dir, "with", 0, name) == 0) return -1;
    strcpy(template_path, name);
    HANDLE h = CreateFileA(name, GENERIC_READ | GENERIC_WRITE,
                           FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                           NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE) return -1;
    return handle_to_fd(h);
}

char *realpath(const char *path, char *resolved_path) {
    DWORD n = GetFullPathNameA(path, MAX_PATH * 4, resolved_path, NULL);
    return n == 0 ? NULL : resolved_path;
}

int *__error(void) {
    static int e;
    e = rt_errno();
    return &e;
}

void *rt_libc_stdin(void) { return stdin; }
void *rt_libc_stdout(void) { return stdout; }
void *rt_libc_stderr(void) { return stderr; }

int gethostname(char *name, int namelen) {
    DWORD n = (DWORD)namelen;
    return GetComputerNameA(name, &n) ? 0 : -1;
}

int64_t pthread_self(void) {
    return (int64_t)GetCurrentThreadId();
}
