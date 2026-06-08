#include "with_runtime.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static char *with_str_to_cstr(with_str s) {
    char *out = (char *)malloc((size_t)s.len + 1);
    if (out == NULL) return NULL;
    if (s.len > 0) memcpy(out, s.ptr, (size_t)s.len);
    out[s.len] = 0;
    return out;
}

static int build_command_line(with_str args, char *out, size_t cap) {
    size_t pos = 0;
    size_t i = 0;
    while (i < (size_t)args.len) {
        const char *arg = (const char *)args.ptr + i;
        size_t n = strlen(arg);
        if (pos != 0) out[pos++] = ' ';
        out[pos++] = '"';
        size_t slash_count = 0;
        for (size_t j = 0; j < n; j++) {
            char ch = arg[j];
            if (ch == '\\') {
                slash_count++;
                continue;
            }
            if (ch == '"') {
                while (slash_count > 0) {
                    if (pos + 2 >= cap) return -1;
                    out[pos++] = '\\';
                    out[pos++] = '\\';
                    slash_count--;
                }
                if (pos + 2 >= cap) return -1;
                out[pos++] = '\\';
                out[pos++] = '"';
                continue;
            }
            while (slash_count > 0) {
                if (pos + 1 >= cap) return -1;
                out[pos++] = '\\';
                slash_count--;
            }
            if (pos + 1 >= cap) return -1;
            out[pos++] = ch;
        }
        while (slash_count > 0) {
            if (pos + 2 >= cap) return -1;
            out[pos++] = '\\';
            out[pos++] = '\\';
            slash_count--;
        }
        if (pos + 1 >= cap) return -1;
        out[pos++] = '"';
        i += n + 1;
    }
    out[pos] = 0;
    return 0;
}

static HANDLE open_redirect(with_str path, int write_mode) {
    char *p = with_str_to_cstr(path);
    if (p == NULL) return INVALID_HANDLE_VALUE;
    SECURITY_ATTRIBUTES sa;
    memset(&sa, 0, sizeof(sa));
    sa.nLength = sizeof(sa);
    sa.bInheritHandle = TRUE;
    HANDLE h = CreateFileA(p, write_mode ? GENERIC_WRITE : GENERIC_READ,
                           FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                           &sa, write_mode ? CREATE_ALWAYS : OPEN_EXISTING,
                           FILE_ATTRIBUTE_NORMAL, NULL);
    free(p);
    return h;
}

static int wait_process(HANDLE process, int32_t timeout_ms) {
    DWORD timeout = timeout_ms > 0 ? (DWORD)timeout_ms : INFINITE;
    DWORD wr = WaitForSingleObject(process, timeout);
    if (wr == WAIT_TIMEOUT) {
        TerminateProcess(process, 124);
        WaitForSingleObject(process, INFINITE);
        CloseHandle(process);
        return 124;
    }
    DWORD code = 1;
    GetExitCodeProcess(process, &code);
    CloseHandle(process);
    return (int)code;
}

static int spawn_argv(with_str args, with_str stdout_path, with_str stderr_path, with_str stdin_path, with_str cwd, int wait, int32_t timeout_ms) {
    char cmd[32768];
    if (build_command_line(args, cmd, sizeof(cmd)) != 0) return -1;

    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    memset(&si, 0, sizeof(si));
    memset(&pi, 0, sizeof(pi));
    si.cb = sizeof(si);
    BOOL inherit = FALSE;

    HANDLE stdin_h = GetStdHandle(STD_INPUT_HANDLE);
    HANDLE stdout_h = GetStdHandle(STD_OUTPUT_HANDLE);
    HANDLE stderr_h = GetStdHandle(STD_ERROR_HANDLE);
    if (stdin_path.len > 0) { stdin_h = open_redirect(stdin_path, 0); inherit = TRUE; }
    if (stdout_path.len > 0) { stdout_h = open_redirect(stdout_path, 1); inherit = TRUE; }
    if (stderr_path.len > 0) { stderr_h = open_redirect(stderr_path, 1); inherit = TRUE; }
    if (inherit) {
        si.dwFlags |= STARTF_USESTDHANDLES;
        si.hStdInput = stdin_h;
        si.hStdOutput = stdout_h;
        si.hStdError = stderr_h;
    }

    char *cwd_c = cwd.len > 0 ? with_str_to_cstr(cwd) : NULL;
    BOOL ok = CreateProcessA(NULL, cmd, NULL, NULL, inherit, 0, NULL, cwd_c, &si, &pi);
    if (cwd_c != NULL) free(cwd_c);
    if (stdin_path.len > 0 && stdin_h != INVALID_HANDLE_VALUE) CloseHandle(stdin_h);
    if (stdout_path.len > 0 && stdout_h != INVALID_HANDLE_VALUE) CloseHandle(stdout_h);
    if (stderr_path.len > 0 && stderr_h != INVALID_HANDLE_VALUE) CloseHandle(stderr_h);
    if (!ok) return -(int)GetLastError();
    CloseHandle(pi.hThread);
    if (wait) return wait_process(pi.hProcess, timeout_ms);
    return (int)pi.dwProcessId;
}

int32_t with_setenv_str(with_str name, with_str value) {
    char *n = with_str_to_cstr(name);
    char *v = with_str_to_cstr(value);
    if (n == NULL || v == NULL) { free(n); free(v); return -1; }
    int rc = _putenv_s(n, v);
    free(n);
    free(v);
    return rc == 0 ? 0 : -1;
}

void with_install_interrupt_handlers(void) {}
void with_raise_stack_limit(void) {}
int32_t with_interrupt_requested(void) { return 0; }

int32_t with_exec_binary(with_str path) {
    char *p = with_str_to_cstr(path);
    if (p == NULL) return -1;
    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    memset(&si, 0, sizeof(si));
    memset(&pi, 0, sizeof(pi));
    si.cb = sizeof(si);
    BOOL ok = CreateProcessA(NULL, p, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi);
    free(p);
    if (!ok) return -(int)GetLastError();
    CloseHandle(pi.hThread);
    return wait_process(pi.hProcess, 0);
}

int32_t with_exec_argv(with_str args) {
    with_str empty = {0};
    return spawn_argv(args, empty, empty, empty, empty, 1, 0);
}

int32_t with_exec_argv_cwd(with_str args, with_str cwd) {
    with_str empty = {0};
    return spawn_argv(args, empty, empty, empty, cwd, 1, 0);
}

int32_t with_exec_argv_capture(with_str args, with_str stdout_path, with_str stderr_path, int32_t timeout_ms) {
    with_str empty = {0};
    return spawn_argv(args, stdout_path, stderr_path, empty, empty, 1, timeout_ms);
}

int32_t with_exec_argv_capture_input(with_str args, with_str stdout_path, with_str stderr_path, int32_t timeout_ms, with_str stdin_path) {
    with_str empty = {0};
    return spawn_argv(args, stdout_path, stderr_path, stdin_path, empty, 1, timeout_ms);
}

int32_t with_exec_argv_capture_cwd(with_str args, with_str stdout_path, with_str stderr_path, int32_t timeout_ms, with_str cwd) {
    with_str empty = {0};
    return spawn_argv(args, stdout_path, stderr_path, empty, cwd, 1, timeout_ms);
}

int32_t with_exec_argv_capture_spawn(with_str args, with_str stdout_path, with_str stderr_path) {
    with_str empty = {0};
    return spawn_argv(args, stdout_path, stderr_path, empty, empty, 0, 0);
}

int32_t with_exec_wait(int32_t pid, int32_t timeout_ms) {
    HANDLE h = OpenProcess(SYNCHRONIZE | PROCESS_QUERY_LIMITED_INFORMATION | PROCESS_TERMINATE, FALSE, (DWORD)pid);
    if (h == NULL) return -(int)GetLastError();
    return wait_process(h, timeout_ms);
}
