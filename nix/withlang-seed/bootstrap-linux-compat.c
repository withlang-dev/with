#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#include "bootstrap_types.h"

static volatile sig_atomic_t interrupt_flag;
static volatile sig_atomic_t active_child_pgid;

int32_t rt_compat_exec_argv_capture_cwd(with_str args, with_str stdout_path,
	with_str stderr_path, int32_t timeout_ms, with_str cwd);

static char *copy_str(with_str s)
{
	char *out;

	if (s.len < 0 || s.len > INT64_MAX - 1)
		return NULL;
	out = malloc((size_t)s.len + 1);
	if (out == NULL)
		return NULL;
	if (s.len > 0)
		memcpy(out, s.ptr, (size_t)s.len);
	out[s.len] = 0;
	return out;
}

struct argv_data {
	char *blob;
	char **argv;
	int argc;
};

static void argv_data_free(struct argv_data *a)
{
	free(a->argv);
	free(a->blob);
	a->argv = NULL;
	a->blob = NULL;
	a->argc = 0;
}

static int argv_data_init(struct argv_data *a, const char *blob, int64_t len)
{
	int count = 0;
	int argi = 0;
	int64_t start = 0;

	a->blob = NULL;
	a->argv = NULL;
	a->argc = 0;
	if (blob == NULL || len <= 0 || len > INT32_MAX)
		return -1;
	for (int64_t i = 0; i < len; i++) {
		if (blob[i] == 0)
			count++;
	}
	if (blob[len - 1] != 0)
		count++;
	if (count <= 0 || count >= 256)
		return -1;
	a->blob = malloc((size_t)len + 1);
	a->argv = calloc((size_t)count + 1, sizeof(*a->argv));
	if (a->blob == NULL || a->argv == NULL) {
		argv_data_free(a);
		return -1;
	}
	memcpy(a->blob, blob, (size_t)len);
	a->blob[len] = 0;
	for (int64_t i = 0; i < len; i++) {
		if (a->blob[i] != 0)
			continue;
		a->argv[argi++] = a->blob + start;
		start = i + 1;
	}
	if (start < len)
		a->argv[argi++] = a->blob + start;
	a->argv[argi] = NULL;
	a->argc = argi;
	return argi > 0 ? 0 : -1;
}

static int redirect_to_path(const char *path, int fd)
{
	int out_fd;

	if (path == NULL)
		return 0;
	out_fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
	if (out_fd < 0)
		return -1;
	if (dup2(out_fd, fd) < 0) {
		close(out_fd);
		return -1;
	}
	close(out_fd);
	return 0;
}

static int redirect_from_path(const char *path, int fd)
{
	int in_fd;

	if (path == NULL)
		return 0;
	in_fd = open(path, O_RDONLY);
	if (in_fd < 0)
		return -1;
	if (dup2(in_fd, fd) < 0) {
		close(in_fd);
		return -1;
	}
	close(in_fd);
	return 0;
}

static int status_to_rc(int status)
{
	if (WIFEXITED(status))
		return WEXITSTATUS(status);
	if (WIFSIGNALED(status))
		return 128 + WTERMSIG(status);
	return status;
}

static int wait_child(pid_t pid, int timeout_ms)
{
	struct timespec sleep_time = { .tv_sec = 0, .tv_nsec = 10000000 };
	struct timespec start;
	int status = 0;

	if (timeout_ms <= 0) {
		for (;;) {
			pid_t r = waitpid(pid, &status, 0);
			if (r == pid)
				return status_to_rc(status);
			if (r < 0 && errno == EINTR)
				continue;
			return -1;
		}
	}
	clock_gettime(CLOCK_MONOTONIC, &start);
	for (;;) {
		pid_t r = waitpid(pid, &status, WNOHANG);
		if (r == pid)
			return status_to_rc(status);
		if (r < 0 && errno == EINTR)
			continue;
		if (r < 0)
			return -1;

		struct timespec now;
		clock_gettime(CLOCK_MONOTONIC, &now);
		int64_t elapsed_ms = (int64_t)(now.tv_sec - start.tv_sec) * 1000 +
			(int64_t)(now.tv_nsec - start.tv_nsec) / 1000000;
		if (elapsed_ms >= timeout_ms) {
			kill(-pid, SIGTERM);
			nanosleep(&sleep_time, NULL);
			if (waitpid(pid, &status, WNOHANG) != pid) {
				kill(-pid, SIGKILL);
				waitpid(pid, &status, 0);
			}
			return 124;
		}
		nanosleep(&sleep_time, NULL);
	}
}

static int run_argv_blob(const char *blob, int64_t len, const char *stdout_path,
	const char *stderr_path, const char *stdin_path, const char *cwd,
	int timeout_ms, int wait_for_child)
{
	struct argv_data args;
	pid_t pid;
	int rc;

	if (interrupt_flag)
		return -1;
	if (argv_data_init(&args, blob, len) != 0)
		return -1;
	pid = fork();
	if (pid == 0) {
		signal(SIGINT, SIG_DFL);
		signal(SIGTERM, SIG_DFL);
		signal(SIGHUP, SIG_DFL);
		signal(SIGQUIT, SIG_DFL);
		setpgid(0, 0);
		if (redirect_from_path(stdin_path, 0) != 0)
			_exit(127);
		if (redirect_to_path(stdout_path, 1) != 0)
			_exit(127);
		if (redirect_to_path(stderr_path, 2) != 0)
			_exit(127);
		if (cwd != NULL && cwd[0] != 0 && chdir(cwd) != 0)
			_exit(127);
		execvp(args.argv[0], args.argv);
		_exit(127);
	}
	if (pid < 0) {
		argv_data_free(&args);
		return -1;
	}
	setpgid(pid, pid);
	argv_data_free(&args);
	if (!wait_for_child)
		return (int)pid;
	active_child_pgid = pid;
	rc = wait_child(pid, timeout_ms);
	active_child_pgid = 0;
	return rc;
}

static void interrupt_handler(int signo)
{
	interrupt_flag = 1;
	if (active_child_pgid > 0)
		kill(-active_child_pgid, signo);
	_exit(128 + signo);
}

void *rt_libc_stdin(void) { return stdin; }
void *rt_libc_stdout(void) { return stdout; }
void *rt_libc_stderr(void) { return stderr; }

int32_t rt_compat_setenv_str(with_str name, with_str value)
{
	char *name_buf = copy_str(name);
	char *value_buf = copy_str(value);
	int rc = -1;

	if (name_buf != NULL && value_buf != NULL)
		rc = setenv(name_buf, value_buf, 1);
	free(name_buf);
	free(value_buf);
	return rc;
}

void rt_compat_install_interrupt_handlers(void)
{
	struct sigaction sa;

	memset(&sa, 0, sizeof(sa));
	sa.sa_handler = interrupt_handler;
	sigemptyset(&sa.sa_mask);
	sigaction(SIGINT, &sa, NULL);
	sigaction(SIGTERM, &sa, NULL);
	sigaction(SIGHUP, &sa, NULL);
}

void rt_compat_raise_stack_limit(void)
{
	struct rlimit lim;
	rlim_t want = 8 * 1024 * 1024;

	if (getrlimit(RLIMIT_STACK, &lim) != 0)
		return;
	if (lim.rlim_max != RLIM_INFINITY && want > lim.rlim_max)
		want = lim.rlim_max;
	if (want > lim.rlim_cur) {
		lim.rlim_cur = want;
		setrlimit(RLIMIT_STACK, &lim);
	}
}

int32_t rt_compat_interrupt_requested(void)
{
	return interrupt_flag ? 1 : 0;
}

int32_t rt_compat_exec_binary(with_str path)
{
	char *buf = copy_str(path);
	int rc;

	if (buf == NULL)
		return -1;
	rc = run_argv_blob(buf, path.len, NULL, NULL, NULL, NULL, 0, 1);
	free(buf);
	return rc;
}

int32_t rt_compat_exec_argv(with_str args)
{
	return run_argv_blob(args.ptr, args.len, NULL, NULL, NULL, NULL, 0, 1);
}

int32_t rt_compat_exec_argv_cwd(with_str args, with_str cwd)
{
	char *cwd_buf = copy_str(cwd);
	int rc;

	if (cwd_buf == NULL)
		return -1;
	rc = run_argv_blob(args.ptr, args.len, NULL, NULL, NULL, cwd_buf, 0, 1);
	free(cwd_buf);
	return rc;
}

int32_t rt_compat_exec_argv_capture(with_str args, with_str stdout_path,
	with_str stderr_path, int32_t timeout_ms)
{
	with_str empty = { .ptr = "", .len = 0 };
	return rt_compat_exec_argv_capture_cwd(args, stdout_path, stderr_path,
		timeout_ms, empty);
}

int32_t rt_compat_exec_argv_capture_input(with_str args, with_str stdout_path,
	with_str stderr_path, int32_t timeout_ms, with_str stdin_path)
{
	char *out_buf = copy_str(stdout_path);
	char *err_buf = copy_str(stderr_path);
	char *in_buf = copy_str(stdin_path);
	int rc = -1;

	if (out_buf != NULL && err_buf != NULL && in_buf != NULL)
		rc = run_argv_blob(args.ptr, args.len, out_buf, err_buf, in_buf, NULL,
			timeout_ms, 1);
	free(out_buf);
	free(err_buf);
	free(in_buf);
	return rc;
}

int32_t rt_compat_exec_argv_capture_cwd(with_str args, with_str stdout_path,
	with_str stderr_path, int32_t timeout_ms, with_str cwd)
{
	char *out_buf = copy_str(stdout_path);
	char *err_buf = copy_str(stderr_path);
	char *cwd_buf = cwd.len > 0 ? copy_str(cwd) : NULL;
	int rc = -1;

	if (out_buf != NULL && err_buf != NULL && (cwd.len == 0 || cwd_buf != NULL))
		rc = run_argv_blob(args.ptr, args.len, out_buf, err_buf, NULL, cwd_buf,
			timeout_ms, 1);
	free(out_buf);
	free(err_buf);
	free(cwd_buf);
	return rc;
}

int32_t rt_compat_exec_argv_capture_spawn(with_str args, with_str stdout_path,
	with_str stderr_path)
{
	char *out_buf = copy_str(stdout_path);
	char *err_buf = copy_str(stderr_path);
	int rc = -1;

	if (out_buf != NULL && err_buf != NULL)
		rc = run_argv_blob(args.ptr, args.len, out_buf, err_buf, NULL, NULL, 0, 0);
	free(out_buf);
	free(err_buf);
	return rc;
}

int32_t rt_compat_exec_wait(int32_t pid, int32_t timeout_ms)
{
	int rc;

	if (pid <= 0)
		return -1;
	active_child_pgid = pid;
	rc = wait_child((pid_t)pid, timeout_ms);
	active_child_pgid = 0;
	return rc;
}
