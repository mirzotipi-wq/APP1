/* Linux-only, process-local diagnostic. Only the exact canonical destination
 * in KF_COMMIT_TARGET is eligible; the Python owner supplies a private pipe.
 * No hooks apply unless every configuration field is valid. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <signal.h>
#include <stdarg.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <unistd.h>

enum mode { DISABLED, BEFORE_RENAME, AFTER_RENAME, RENAME_EIO };
static enum mode configured_mode;
static char configured_target[PATH_MAX];
static int witness_fd = -1;
static _Atomic unsigned long hits;
static int (*real_rename)(const char *, const char *);
static int (*real_renameat)(int, const char *, int, const char *);
static int (*real_renameat2)(int, const char *, int, const char *, unsigned int);

__attribute__((constructor)) static void configure(void) {
    int saved_errno = errno;
    real_rename = (int (*)(const char *, const char *))dlsym(RTLD_NEXT, "rename");
    real_renameat = (int (*)(int, const char *, int, const char *))dlsym(RTLD_NEXT, "renameat");
    real_renameat2 = (int (*)(int, const char *, int, const char *, unsigned int))dlsym(RTLD_NEXT, "renameat2");
    const char *target = getenv("KF_COMMIT_TARGET");
    const char *mode_name = getenv("KF_COMMIT_MODE");
    const char *fd_text = getenv("KF_COMMIT_WITNESS_FD");
    enum mode selected = DISABLED;
    if (mode_name && strcmp(mode_name, "before-rename") == 0) selected = BEFORE_RENAME;
    if (mode_name && strcmp(mode_name, "after-rename") == 0) selected = AFTER_RENAME;
    if (mode_name && strcmp(mode_name, "rename-eio") == 0) selected = RENAME_EIO;
    if (!target || target[0] != '/' || !fd_text || !*fd_text || selected == DISABLED) goto done;
    if (strlen(target) >= sizeof(configured_target)) goto done;
    char canonical[PATH_MAX];
    if (!realpath(target, canonical) || strcmp(canonical, target) != 0) goto done;
    struct stat target_info;
    if (lstat(target, &target_info) != 0 || !S_ISREG(target_info.st_mode)) goto done;
    char *end = NULL;
    errno = 0;
    long parsed_fd = strtol(fd_text, &end, 10);
    if (errno || !end || *end || parsed_fd < 3 || parsed_fd > INT_MAX) goto done;
    struct stat pipe_info;
    if (fstat((int)parsed_fd, &pipe_info) != 0 || !S_ISFIFO(pipe_info.st_mode)) goto done;
    strcpy(configured_target, target);
    witness_fd = (int)parsed_fd;
    configured_mode = selected;
done:
    errno = saved_errno;
}

static int matches_target(int directory_fd, const char *path) {
    if (configured_mode == DISABLED || !path) return 0;
    char joined[PATH_MAX];
    char canonical[PATH_MAX];
    const char *candidate = path;
    if (path[0] != '/' && directory_fd != AT_FDCWD) {
        int length = snprintf(joined, sizeof(joined), "/proc/self/fd/%d/%s", directory_fd, path);
        if (length < 0 || (size_t)length >= sizeof(joined)) return 0;
        candidate = joined;
    }
    /* rename replaces the final directory entry; it does not follow a final
     * symlink. Resolving such an alias would intercept a different entry. */
    struct stat entry_info;
    if (lstat(candidate, &entry_info) != 0 || S_ISLNK(entry_info.st_mode)) return 0;
    return realpath(candidate, canonical) && strcmp(canonical, configured_target) == 0;
}

/* Each event is one bounded pipe write, never an unbounded log/file write. */
struct message { char data[4096]; size_t used; };

static void append(struct message *message, const char *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    int count = vsnprintf(message->data + message->used,
                          sizeof(message->data) - message->used, format, arguments);
    va_end(arguments);
    if (count < 0 || (size_t)count >= sizeof(message->data) - message->used) _exit(125);
    message->used += (size_t)count;
}

static void append_json_string(struct message *message, const char *value) {
    append(message, "\"");
    for (const unsigned char *cursor = (const unsigned char *)value; *cursor; ++cursor) {
        if (*cursor == '"' || *cursor == '\\') append(message, "\\%c", *cursor);
        else if (*cursor < 0x20) append(message, "\\u%04x", *cursor);
        else append(message, "%c", *cursor);
    }
    append(message, "\"");
}

static void witness(const char *api, const char *source, const char *destination,
                    int source_fd, int destination_fd, const char *state,
                    int real_called, int real_result, int returned_errno) {
    struct message message = { .used = 0 };
    const char *name = configured_mode == BEFORE_RENAME ? "before-rename" :
                       configured_mode == AFTER_RENAME ? "after-rename" : "rename-eio";
    unsigned long hit = atomic_fetch_add_explicit(&hits, 1, memory_order_relaxed) + 1;
    append(&message, "{\"schemaVersion\":1,\"pid\":%ld,\"hit\":%lu,\"targetMatched\":true,\"api\":",
           (long)getpid(), hit);
    append_json_string(&message, api);
    append(&message, ",\"mode\":"); append_json_string(&message, name);
    append(&message, ",\"hookState\":"); append_json_string(&message, state);
    append(&message, ",\"targetPath\":"); append_json_string(&message, configured_target);
    append(&message, ",\"sourceArgument\":"); append_json_string(&message, source);
    append(&message, ",\"destinationArgument\":"); append_json_string(&message, destination);
    append(&message, ",\"sourceDirFD\":%d,\"destinationDirFD\":%d,\"realRenameCalled\":%s,\"realReturnCode\":",
           source_fd, destination_fd, real_called ? "true" : "false");
    if (real_called) append(&message, "%d", real_result); else append(&message, "null");
    append(&message, ",\"returnedErrno\":%d}\n", returned_errno);
    long pipe_bound = fpathconf(witness_fd, _PC_PIPE_BUF);
    if (pipe_bound < 0 || message.used > (size_t)pipe_bound) _exit(125);
    ssize_t written;
    do { written = write(witness_fd, message.data, message.used); } while (written < 0 && errno == EINTR);
    if (written < 0 || (size_t)written != message.used) _exit(125);
}

static void stop_at_hook(void) {
    /* SIGSTOP cannot be handled or ignored. The owner witnesses WSTOPPED before
     * killing the private process group. An unexpected resume cannot commit. */
    raise(SIGSTOP);
    _exit(126);
}

static int before_call(const char *api, const char *source, const char *destination,
                       int source_fd, int destination_fd) {
    if (configured_mode == BEFORE_RENAME) {
        witness(api, source, destination, source_fd, destination_fd, "before-call", 0, 0, 0);
        stop_at_hook();
    }
    if (configured_mode == RENAME_EIO) {
        witness(api, source, destination, source_fd, destination_fd, "rejected", 0, 0, EIO);
        errno = EIO;
        return 1;
    }
    return 0;
}

static int after_call(const char *api, const char *source, const char *destination,
                      int source_fd, int destination_fd, int result, int saved_errno) {
    witness(api, source, destination, source_fd, destination_fd,
            result == 0 ? "after-success" : "after-error", 1, result, result == 0 ? 0 : saved_errno);
    if (result == 0) stop_at_hook();
    errno = saved_errno;
    return result;
}

int rename(const char *source, const char *destination) {
    int saved_errno = errno;
    int targeted = matches_target(AT_FDCWD, destination);
    errno = saved_errno;
    if (targeted && before_call("rename", source, destination, AT_FDCWD, AT_FDCWD)) return -1;
    int result = real_rename ? real_rename(source, destination) :
                              (int)syscall(SYS_renameat, AT_FDCWD, source, AT_FDCWD, destination);
    saved_errno = errno;
    return targeted ? after_call("rename", source, destination, AT_FDCWD, AT_FDCWD, result, saved_errno) : result;
}

int renameat(int source_fd, const char *source, int destination_fd, const char *destination) {
    int saved_errno = errno;
    int targeted = matches_target(destination_fd, destination);
    errno = saved_errno;
    if (targeted && before_call("renameat", source, destination, source_fd, destination_fd)) return -1;
    int result = real_renameat ? real_renameat(source_fd, source, destination_fd, destination) :
                                (int)syscall(SYS_renameat, source_fd, source, destination_fd, destination);
    saved_errno = errno;
    return targeted ? after_call("renameat", source, destination, source_fd, destination_fd, result, saved_errno) : result;
}

int renameat2(int source_fd, const char *source, int destination_fd, const char *destination, unsigned int flags) {
    int saved_errno = errno;
    int targeted = matches_target(destination_fd, destination);
    errno = saved_errno;
    if (targeted && before_call("renameat2", source, destination, source_fd, destination_fd)) return -1;
    int result = real_renameat2 ? real_renameat2(source_fd, source, destination_fd, destination, flags) :
                                 (int)syscall(SYS_renameat2, source_fd, source, destination_fd, destination, flags);
    saved_errno = errno;
    return targeted ? after_call("renameat2", source, destination, source_fd, destination_fd, result, saved_errno) : result;
}
