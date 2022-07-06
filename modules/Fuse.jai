
#import "Linux";
#import "POSIX";

stat :: stat_t;


flock :: struct {
    l_type:      s16; // Type of lock; F_RDLCK, F_WRLCK, F_UNLCK. 
    l_whence:    s16; // Flag for starting offset. 
    l_start:   off_t; // Relative offset in bytes. 
    l_len:     off_t; // Size; if 0 then until EOF. 
    l_pid:     pid_t; // Process ID of the process holding the lock; returned with F_GETLK. 
}


FUSE_USE_VERSION :: 29;

FUSE_OPT_KEY_OPT :: -1;

FUSE_OPT_KEY_NONOPT :: -2;

FUSE_OPT_KEY_KEEP :: -3;

FUSE_OPT_KEY_DISCARD :: -4;

FUSE_MAJOR_VERSION :: 3;

FUSE_MINOR_VERSION :: 11;

FUSE_CAP_ASYNC_READ :: 1 << 0;

FUSE_CAP_POSIX_LOCKS :: 1 << 1;

FUSE_CAP_ATOMIC_O_TRUNC :: 1 << 3;

FUSE_CAP_EXPORT_SUPPORT :: 1 << 4;

FUSE_CAP_DONT_MASK :: 1 << 6;

FUSE_CAP_SPLICE_WRITE :: 1 << 7;

FUSE_CAP_SPLICE_MOVE :: 1 << 8;

FUSE_CAP_SPLICE_READ :: 1 << 9;

FUSE_CAP_FLOCK_LOCKS :: 1 << 10;

FUSE_CAP_IOCTL_DIR :: 1 << 11;

FUSE_CAP_AUTO_INVAL_DATA :: 1 << 12;

FUSE_CAP_READDIRPLUS :: 1 << 13;

FUSE_CAP_READDIRPLUS_AUTO :: 1 << 14;

FUSE_CAP_ASYNC_DIO :: 1 << 15;

FUSE_CAP_WRITEBACK_CACHE :: 1 << 16;

FUSE_CAP_NO_OPEN_SUPPORT :: 1 << 17;

FUSE_CAP_PARALLEL_DIROPS :: 1 << 18;

FUSE_CAP_POSIX_ACL :: 1 << 19;

FUSE_CAP_HANDLE_KILLPRIV :: 1 << 20;

FUSE_CAP_CACHE_SYMLINKS :: 1 << 23;

FUSE_CAP_NO_OPENDIR_SUPPORT :: 1 << 24;

FUSE_CAP_EXPLICIT_INVAL_DATA :: 1 << 25;

FUSE_IOCTL_MAX_IOV :: 256;

FUSE_ROOT_ID :: 1;

FUSE_SET_ATTR_MODE :: 1 << 0;
FUSE_SET_ATTR_UID :: 1 << 1;
FUSE_SET_ATTR_GID :: 1 << 2;
FUSE_SET_ATTR_SIZE :: 1 << 3;
FUSE_SET_ATTR_ATIME :: 1 << 4;
FUSE_SET_ATTR_MTIME :: 1 << 5;
FUSE_SET_ATTR_ATIME_NOW :: 1 << 7;
FUSE_SET_ATTR_MTIME_NOW :: 1 << 8;
FUSE_SET_ATTR_CTIME :: 1 << 10;

FUSE_KERNEL_VERSION :: 7;

FUSE_KERNEL_MINOR_VERSION :: 31;

FATTR_MODE :: 1 << 0;
FATTR_UID :: 1 << 1;
FATTR_GID :: 1 << 2;
FATTR_SIZE :: 1 << 3;
FATTR_ATIME :: 1 << 4;
FATTR_MTIME :: 1 << 5;
FATTR_FH :: 1 << 6;
FATTR_ATIME_NOW :: 1 << 7;
FATTR_MTIME_NOW :: 1 << 8;
FATTR_LOCKOWNER :: 1 << 9;
FATTR_CTIME :: 1 << 10;

FOPEN_DIRECT_IO :: 1 << 0;
FOPEN_KEEP_CACHE :: 1 << 1;
FOPEN_NONSEEKABLE :: 1 << 2;
FOPEN_CACHE_DIR :: 1 << 3;
FOPEN_STREAM :: 1 << 4;
FOPEN_NOFLUSH :: 1 << 5;

FUSE_ASYNC_READ :: 1 << 0;
FUSE_POSIX_LOCKS :: 1 << 1;
FUSE_FILE_OPS :: 1 << 2;
FUSE_ATOMIC_O_TRUNC :: 1 << 3;
FUSE_EXPORT_SUPPORT :: 1 << 4;
FUSE_BIG_WRITES :: 1 << 5;
FUSE_DONT_MASK :: 1 << 6;
FUSE_SPLICE_WRITE :: 1 << 7;
FUSE_SPLICE_MOVE :: 1 << 8;
FUSE_SPLICE_READ :: 1 << 9;
FUSE_FLOCK_LOCKS :: 1 << 10;
FUSE_HAS_IOCTL_DIR :: 1 << 11;
FUSE_AUTO_INVAL_DATA :: 1 << 12;
FUSE_DO_READDIRPLUS :: 1 << 13;
FUSE_READDIRPLUS_AUTO :: 1 << 14;
FUSE_ASYNC_DIO :: 1 << 15;
FUSE_WRITEBACK_CACHE :: 1 << 16;
FUSE_NO_OPEN_SUPPORT :: 1 << 17;
FUSE_PARALLEL_DIROPS :: 1 << 18;
FUSE_HANDLE_KILLPRIV :: 1 << 19;
FUSE_POSIX_ACL :: 1 << 20;
FUSE_ABORT_ERROR :: 1 << 21;
FUSE_MAX_PAGES :: 1 << 22;
FUSE_CACHE_SYMLINKS :: 1 << 23;
FUSE_NO_OPENDIR_SUPPORT :: 1 << 24;
FUSE_EXPLICIT_INVAL_DATA :: 1 << 25;
FUSE_MAP_ALIGNMENT :: 1 << 26;
FUSE_SUBMOUNTS :: 1 << 27;
FUSE_HANDLE_KILLPRIV_V2 :: 1 << 28;
FUSE_SETXATTR_EXT :: 1 << 29;
FUSE_INIT_EXT :: 1 << 30;
FUSE_INIT_RESERVED :: 1 << 31;

FUSE_SECURITY_CTX :: 1 << 32;
FUSE_HAS_INODE_DAX :: 1 << 33;

CUSE_UNRESTRICTED_IOCTL :: 1 << 0;

FUSE_RELEASE_FLUSH :: 1 << 0;
FUSE_RELEASE_FLOCK_UNLOCK :: 1 << 1;

FUSE_GETATTR_FH :: 1 << 0;

FUSE_LK_FLOCK :: 1 << 0;

FUSE_WRITE_CACHE :: 1 << 0;
FUSE_WRITE_LOCKOWNER :: 1 << 1;
FUSE_WRITE_KILL_PRIV :: 1 << 2;

FUSE_READ_LOCKOWNER :: 1 << 1;

FUSE_IOCTL_COMPAT :: 1 << 0;
FUSE_IOCTL_UNRESTRICTED :: 1 << 1;
FUSE_IOCTL_RETRY :: 1 << 2;
FUSE_IOCTL_32BIT :: 1 << 3;
FUSE_IOCTL_DIR :: 1 << 4;
FUSE_IOCTL_COMPAT_X32 :: 1 << 5;

FUSE_POLL_SCHEDULE_NOTIFY :: 1 << 0;

FUSE_FSYNC_FDATASYNC :: 1 << 0;

FUSE_MIN_READ_BUFFER :: 8192;

FUSE_COMPAT_ENTRY_OUT_SIZE :: 120;

FUSE_COMPAT_ATTR_OUT_SIZE :: 96;

FUSE_COMPAT_MKNOD_IN_SIZE :: 8;

FUSE_COMPAT_WRITE_IN_SIZE :: 24;

FUSE_COMPAT_STATFS_SIZE :: 48;

FUSE_COMPAT_INIT_OUT_SIZE :: 8;
FUSE_COMPAT_22_INIT_OUT_SIZE :: 24;

CUSE_INIT_INFO_MAX :: 4096;

/**
* Option description
*
* This structure describes a single option, and action associated
* with it, in case it matches.
*
* More than one such match may occur, in which case the action for
* each match is executed.
*
* There are three possible actions in case of a match:
*
* i) An integer (int or unsigned) variable determined by 'offset' is
*    set to 'value'
*
* ii) The processing function is called, with 'value' as the key
*
* iii) An integer (any) or string (char *) variable determined by
*    'offset' is set to the value of an option parameter
*
* 'offset' should normally be either set to
*
*  - 'offsetof(struct foo, member)'  actions i) and iii)
*
*  - -1               action ii)
*
* The 'offsetof()' macro is defined in the <stddef.h> header.
*
* The template determines which options match, and also have an
* effect on the action.  Normally the action is either i) or ii), but
* if a format is present in the template, then action iii) is
* performed.
*
* The types of templates are:
*
* 1) "-x", "-foo", "--foo", "--foo-bar", etc.   These match only
*   themselves.  Invalid values are "--" and anything beginning
*   with "-o"
*
* 2) "foo", "foo-bar", etc.  These match "-ofoo", "-ofoo-bar" or
*    the relevant option in a comma separated option list
*
* 3) "bar=", "--foo=", etc.  These are variations of 1) and 2)
*    which have a parameter
*
* 4) "bar=%s", "--foo=%lu", etc.  Same matching as above but perform
*    action iii).
*
* 5) "-x ", etc.  Matches either "-xparam" or "-x param" as
*    two separate arguments
*
* 6) "-x %s", etc.  Combination of 4) and 5)
*
* If the format is "%s", memory is allocated for the string unlike with
* scanf().  The previous value (if non-NULL) stored at the this location is
* freed.
*/
fuse_opt :: struct {
    /** Matching template and optional parameter formatting */
    templ:  *u8;

    /**
    * Offset of variable within 'data' parameter of fuse_opt_parse()
    * or -1
    */
    offset: u64;

    /**
    * Value to set the variable to, or to be passed as 'key' to the
    * processing function.   Ignored if template has a format
    */
    value:  s32;
}

/**
* Argument list
*/
fuse_args :: struct {
    /** Argument count */
    argc:      s32;

    /** Argument vector.  NULL terminated */
    argv:      **u8;

    /** Is 'argv' allocated? */
    allocated: s32;
}

/**
* Processing function
*
* This function is called if
*    - option did not match any 'struct fuse_opt'
*    - argument is a non-option
*    - option did match and offset was set to -1
*
* The 'arg' parameter will always contain the whole argument or
* option including the parameter if exists.  A two-argument option
* ("-x foo") is always converted to single argument option of the
* form "-xfoo" before this function is called.
*
* Options of the form '-ofoo' are passed to this function without the
* '-o' prefix.
*
* The return value of this function determines whether this argument
* is to be inserted into the output argument vector, or discarded.
*
* @param data is the user data passed to the fuse_opt_parse() function
* @param arg is the whole argument or option
* @param key determines why the processing function was called
* @param outargs the current output argument list
* @return -1 on error, 0 if arg is to be discarded, 1 if arg should be kept
*/
fuse_opt_proc_t :: #type (a0: *void, a1: *u8, a2: s32, a3: *fuse_args) -> s32 #c_call;

/**
* Log severity level
*
* These levels correspond to syslog(2) log levels since they are widely used.
*/
fuse_log_level :: enum u32 {
    EMERG   :: 0;
    ALERT   :: 1;
    CRIT    :: 2;
    ERR     :: 3;
    WARNING :: 4;
    NOTICE  :: 5;
    INFO    :: 6;
    DEBUG   :: 7;

    FUSE_LOG_EMERG   :: EMERG;
    FUSE_LOG_ALERT   :: ALERT;
    FUSE_LOG_CRIT    :: CRIT;
    FUSE_LOG_ERR     :: ERR;
    FUSE_LOG_WARNING :: WARNING;
    FUSE_LOG_NOTICE  :: NOTICE;
    FUSE_LOG_INFO    :: INFO;
    FUSE_LOG_DEBUG   :: DEBUG;
}

/**
* Log message handler function.
*
* This function must be thread-safe.  It may be called from any libfuse
* function, including fuse_parse_cmdline() and other functions invoked before
* a FUSE filesystem is created.
*
* Install a custom log message handler function using fuse_set_log_func().
*
* @param level log severity level
* @param fmt sprintf-style format string including newline
* @param ap format string arguments
*/
fuse_log_func_t :: #type (a0: fuse_log_level, a1: *u8, a2: va_list) -> void #c_call;

/**
* Information about an open file.
*
* File Handles are created by the open, opendir, and create methods and closed
* by the release and releasedir methods.  Multiple file handles may be
* concurrently open for the same file.  Generally, a client will create one
* file handle per file descriptor, though in some cases multiple file
* descriptors can share a single file handle.
*/
fuse_file_info :: struct {
    /** Open flags.  Available in open() and release() */
    flags:         s32;

    /** In case of a write operation indicates if this was caused
    by a delayed write from the page cache. If so, then the
    context's pid, uid, and gid fields will not be valid, and
    the *fh* value may not match the *fh* value that would
    have been sent with the corresponding individual write
    requests if write caching had been disabled. */
    writepage:     u32;

    /** Can be filled in by open, to use direct I/O on this file. */
    #place writepage; /*bitfield 1*/     direct_io:     u32;

    /** Can be filled in by open. It signals the kernel that any
    currently cached file data (ie., data that the filesystem
    provided the last time the file was open) need not be
    invalidated. Has no effect when set in other contexts (in
    particular it does nothing when set by opendir()). */
    #place writepage; /*bitfield 2*/     keep_cache:    u32;

    /** Indicates a flush operation.  Set in flush operation, also
    maybe set in highlevel lock operation and lowlevel release
    operation. */
    #place writepage; /*bitfield 3*/     flush:         u32;

    /** Can be filled in by open, to indicate that the file is not
    seekable. */
    #place writepage; /*bitfield 4*/     nonseekable:   u32;

    /* Indicates that flock locks for this file should be
    released.  If set, lock_owner shall contain a valid value.
    May only be set in ->release(). */
    #place writepage; /*bitfield 5*/     flock_release: u32;

    /** Can be filled in by opendir. It signals the kernel to
    enable caching of entries returned by readdir().  Has no
    effect when set in other contexts (in particular it does
    nothing when set by open()). */
    #place writepage; /*bitfield 6*/     cache_readdir: u32;

    /** Can be filled in by open, to indicate that flush is not needed
    on close. */
    #place writepage; /*bitfield 7*/     noflush:       u32;

    /** Padding.  Reserved for future use*/
    #place writepage; /*bitfield 8*/     padding:       u32;
    padding2:      u32;

    /** File handle id.  May be filled in by filesystem in create,
    * open, and opendir().  Available in most other file operations on the
    * same file handle. */
    fh:            u64;

    /** Lock owner id.  Available in locking operations and flush */
    lock_owner:    u64;

    /** Requested poll events.  Available in ->poll.  Only set on kernels
    which support it.  If unsupported, this field is set to zero. */
    poll_events:   u32;
}

/**
* Configuration parameters passed to fuse_session_loop_mt() and
* fuse_loop_mt().
*/
fuse_loop_config :: struct {
    /**
    * whether to use separate device fds for each thread
    * (may increase performance)
    */
    clone_fd:         s32;

    /**
    * The maximum number of available worker threads before they
    * start to get deleted when they become idle. If not
    * specified, the default is 10.
    *
    * Adjusting this has performance implications; a very small number
    * of threads in the pool will cause a lot of thread creation and
    * deletion overhead and performance may suffer. When set to 0, a new
    * thread will be created to service every operation.
    */
    max_idle_threads: u32;
}

/**
* Connection information, passed to the ->init() method
*
* Some of the elements are read-write, these can be changed to
* indicate the value requested by the filesystem.  The requested
* value must usually be smaller than the indicated value.
*/
fuse_conn_info :: struct {
    /**
    * Major version of the protocol (read-only)
    */
    proto_major:          u32;

    /**
    * Minor version of the protocol (read-only)
    */
    proto_minor:          u32;

    /**
    * Maximum size of the write buffer
    */
    max_write:            u32;

    /**
    * Maximum size of read requests. A value of zero indicates no
    * limit. However, even if the filesystem does not specify a
    * limit, the maximum size of read requests will still be
    * limited by the kernel.
    *
    * NOTE: For the time being, the maximum size of read requests
    * must be set both here *and* passed to fuse_session_new()
    * using the ``-o max_read=<n>`` mount option. At some point
    * in the future, specifying the mount option will no longer
    * be necessary.
    */
    max_read:             u32;

    /**
    * Maximum readahead
    */
    max_readahead:        u32;

    /**
    * Capability flags that the kernel supports (read-only)
    */
    capable:              u32;

    /**
    * Capability flags that the filesystem wants to enable.
    *
    * libfuse attempts to initialize this field with
    * reasonable default values before calling the init() handler.
    */
    want:                 u32;

    /**
    * Maximum number of pending "background" requests. A
    * background request is any type of request for which the
    * total number is not limited by other means. As of kernel
    * 4.8, only two types of requests fall into this category:
    *
    *   1. Read-ahead requests
    *   2. Asynchronous direct I/O requests
    *
    * Read-ahead requests are generated (if max_readahead is
    * non-zero) by the kernel to preemptively fill its caches
    * when it anticipates that userspace will soon read more
    * data.
    *
    * Asynchronous direct I/O requests are generated if
    * FUSE_CAP_ASYNC_DIO is enabled and userspace submits a large
    * direct I/O request. In this case the kernel will internally
    * split it up into multiple smaller requests and submit them
    * to the filesystem concurrently.
    *
    * Note that the following requests are *not* background
    * requests: writeback requests (limited by the kernel's
    * flusher algorithm), regular (i.e., synchronous and
    * buffered) userspace read/write requests (limited to one per
    * thread), asynchronous read requests (Linux's io_submit(2)
    * call actually blocks, so these are also limited to one per
    * thread).
    */
    max_background:       u32;

    /**
    * Kernel congestion threshold parameter. If the number of pending
    * background requests exceeds this number, the FUSE kernel module will
    * mark the filesystem as "congested". This instructs the kernel to
    * expect that queued requests will take some time to complete, and to
    * adjust its algorithms accordingly (e.g. by putting a waiting thread
    * to sleep instead of using a busy-loop).
    */
    congestion_threshold: u32;

    /**
    * When FUSE_CAP_WRITEBACK_CACHE is enabled, the kernel is responsible
    * for updating mtime and ctime when write requests are received. The
    * updated values are passed to the filesystem with setattr() requests.
    * However, if the filesystem does not support the full resolution of
    * the kernel timestamps (nanoseconds), the mtime and ctime values used
    * by kernel and filesystem will differ (and result in an apparent
    * change of times after a cache flush).
    *
    * To prevent this problem, this variable can be used to inform the
    * kernel about the timestamp granularity supported by the file-system.
    * The value should be power of 10.  The default is 1, i.e. full
    * nano-second resolution. Filesystems supporting only second resolution
    * should set this to 1000000000.
    */
    time_gran:            u32;

    /**
    * For future use.
    */
    reserved:             [22] u32;
}

/**
* Session
*
* This provides hooks for processing requests, and exiting
*/
fuse_session :: struct {}
fuse_pollhandle :: struct {}
fuse_conn_info_opts :: struct {}

/**
* Buffer flags
*/
fuse_buf_flags :: enum u32 {
    IS_FD    :: 2;

    FD_SEEK  :: 4;

    FD_RETRY :: 8;

    FUSE_BUF_IS_FD    :: IS_FD;

    FUSE_BUF_FD_SEEK  :: FD_SEEK;

    FUSE_BUF_FD_RETRY :: FD_RETRY;
}

/**
* Buffer copy flags
*/
fuse_buf_copy_flags :: enum u32 {
    NO_SPLICE       :: 2;

    FORCE_SPLICE    :: 4;

    SPLICE_MOVE     :: 8;

    SPLICE_NONBLOCK :: 16;

    FUSE_BUF_NO_SPLICE       :: NO_SPLICE;

    FUSE_BUF_FORCE_SPLICE    :: FORCE_SPLICE;

    FUSE_BUF_SPLICE_MOVE     :: SPLICE_MOVE;

    FUSE_BUF_SPLICE_NONBLOCK :: SPLICE_NONBLOCK;
}

/**
* Single data buffer
*
* Generic data buffer for I/O, extended attributes, etc...  Data may
* be supplied as a memory pointer or as a file descriptor
*/
fuse_buf :: struct {
    /**
    * Size of data in bytes
    */
    size:  size_t;

    /**
    * Buffer flags
    */
    flags: fuse_buf_flags;

    /**
    * Memory pointer
    *
    * Used unless FUSE_BUF_IS_FD flag is set.
    */
    mem:   *void;

    /**
    * File descriptor
    *
    * Used if FUSE_BUF_IS_FD flag is set.
    */
    fd:    s32;

    /**
    * File position
    *
    * Used if FUSE_BUF_FD_SEEK flag is set.
    */
    pos:   off_t;
}

/**
* Data buffer vector
*
* An array of data buffers, each containing a memory pointer or a
* file descriptor.
*
* Allocate dynamically to add more than one buffer.
*/
fuse_bufvec :: struct {
    /**
    * Number of buffers in the array
    */
    count: size_t;

    /**
    * Index of current buffer within the array
    */
    idx:   size_t;

    /**
    * Current offset within the current buffer
    */
    off:   size_t;

    /**
    * Array of buffers
    */
    buf:   [1] fuse_buf;
}

_fuse_off_t_must_be_64bit_dummy_struct :: struct {
    _fuse_off_t_must_be_64bit: u32;
}

/** Inode number type */
fuse_ino_t :: u64;

fuse_req :: struct {}
/** Request pointer type */
fuse_req_t :: *fuse_req;

/** Directory entry parameters supplied to fuse_reply_entry() */
fuse_entry_param :: struct {
    /** Unique inode number
    *
    * In lookup, zero means negative entry (from version 2.5)
    * Returning ENOENT also means negative entry, but by setting zero
    * ino the kernel may cache negative entries for entry_timeout
    * seconds.
    */
    ino:           fuse_ino_t;

    /** Generation number for this entry.
    *
    * If the file system will be exported over NFS, the
    * ino/generation pairs need to be unique over the file
    * system's lifetime (rather than just the mount time). So if
    * the file system reuses an inode after it has been deleted,
    * it must assign a new, previously unused generation number
    * to the inode at the same time.
    *
    */
    generation:    u64;

    /** Inode attributes.
    *
    * Even if attr_timeout == 0, attr must be correct. For example,
    * for open(), FUSE uses attr.st_size from lookup() to determine
    * how many bytes to request. If this value is not correct,
    * incorrect data will be returned.
    */
    attr:          stat;

    /** Validity timeout (in seconds) for inode attributes. If
    attributes only change as a result of requests that come
    through the kernel, this should be set to a very large
    value. */
    attr_timeout:  float64;

    /** Validity timeout (in seconds) for the name. If directory
    entries are changed/deleted only as a result of requests
    that come through the kernel, this should be set to a very
    large value. */
    entry_timeout: float64;
}

/**
* Additional context associated with requests.
*
* Note that the reported client uid, gid and pid may be zero in some
* situations. For example, if the FUSE file system is running in a
* PID or user namespace but then accessed from outside the namespace,
* there is no valid uid/pid/gid that could be reported.
*/
fuse_ctx :: struct {
    /** User ID of the calling process */
    uid:   uid_t;

    /** Group ID of the calling process */
    gid:   gid_t;

    /** Thread ID of the calling process */
    pid:   pid_t;

    /** Umask of the calling process */
    umask: mode_t;
}

fuse_forget_data :: struct {
    ino:     fuse_ino_t;
    nlookup: u64;
}

/**
* Low level filesystem operations
*
* Most of the methods (with the exception of init and destroy)
* receive a request handle (fuse_req_t) as their first argument.
* This handle must be passed to one of the specified reply functions.
*
* This may be done inside the method invocation, or after the call
* has returned.  The request handle is valid until one of the reply
* functions is called.
*
* Other pointer arguments (name, fuse_file_info, etc) are not valid
* after the call has returned, so if they are needed later, their
* contents have to be copied.
*
* In general, all methods are expected to perform any necessary
* permission checking. However, a filesystem may delegate this task
* to the kernel by passing the `default_permissions` mount option to
* `fuse_session_new()`. In this case, methods will only be called if
* the kernel's permission check has succeeded.
*
* The filesystem sometimes needs to handle a return value of -ENOENT
* from the reply function, which means, that the request was
* interrupted, and the reply discarded.  For example if
* fuse_reply_open() return -ENOENT means, that the release method for
* this file will not be called.
*/
fuse_lowlevel_ops :: struct {
    /**
    * Initialize filesystem
    *
    * This function is called when libfuse establishes
    * communication with the FUSE kernel module. The file system
    * should use this module to inspect and/or modify the
    * connection parameters provided in the `conn` structure.
    *
    * Note that some parameters may be overwritten by options
    * passed to fuse_session_new() which take precedence over the
    * values set in this handler.
    *
    * There's no reply to this function
    *
    * @param userdata the user data passed to fuse_session_new()
    */
    init:            #type (a0: *void, a1: *fuse_conn_info) -> void #c_call;

    /**
    * Clean up filesystem.
    *
    * Called on filesystem exit. When this method is called, the
    * connection to the kernel may be gone already, so that eg. calls
    * to fuse_lowlevel_notify_* will fail.
    *
    * There's no reply to this function
    *
    * @param userdata the user data passed to fuse_session_new()
    */
    destroy:         #type (a0: *void) -> void #c_call;

    /**
    * Look up a directory entry by name and get its attributes.
    *
    * Valid replies:
    *   fuse_reply_entry
    *   fuse_reply_err
    *
    * @param req request handle
    * @param parent inode number of the parent directory
    * @param name the name to look up
    */
    lookup:          #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *u8) -> void #c_call;

    /**
    * Forget about an inode
    *
    * This function is called when the kernel removes an inode
    * from its internal caches.
    *
    * The inode's lookup count increases by one for every call to
    * fuse_reply_entry and fuse_reply_create. The nlookup parameter
    * indicates by how much the lookup count should be decreased.
    *
    * Inodes with a non-zero lookup count may receive request from
    * the kernel even after calls to unlink, rmdir or (when
    * overwriting an existing file) rename. Filesystems must handle
    * such requests properly and it is recommended to defer removal
    * of the inode until the lookup count reaches zero. Calls to
    * unlink, rmdir or rename will be followed closely by forget
    * unless the file or directory is open, in which case the
    * kernel issues forget only after the release or releasedir
    * calls.
    *
    * Note that if a file system will be exported over NFS the
    * inodes lifetime must extend even beyond forget. See the
    * generation field in struct fuse_entry_param above.
    *
    * On unmount the lookup count for all inodes implicitly drops
    * to zero. It is not guaranteed that the file system will
    * receive corresponding forget messages for the affected
    * inodes.
    *
    * Valid replies:
    *   fuse_reply_none
    *
    * @param req request handle
    * @param ino the inode number
    * @param nlookup the number of lookups to forget
    */
    forget:          #type (a0: fuse_req_t, a1: fuse_ino_t, a2: u64) -> void #c_call;

    /**
    * Get file attributes.
    *
    * If writeback caching is enabled, the kernel may have a
    * better idea of a file's length than the FUSE file system
    * (eg if there has been a write that extended the file size,
    * but that has not yet been passed to the filesystem.n
    *
    * In this case, the st_size value provided by the file system
    * will be ignored.
    *
    * Valid replies:
    *   fuse_reply_attr
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param fi for future use, currently always NULL
    */
    getattr:         #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *fuse_file_info) -> void #c_call;

    /**
    * Set file attributes
    *
    * In the 'attr' argument only members indicated by the 'to_set'
    * bitmask contain valid values.  Other members contain undefined
    * values.
    *
    * Unless FUSE_CAP_HANDLE_KILLPRIV is disabled, this method is
    * expected to reset the setuid and setgid bits if the file
    * size or owner is being changed.
    *
    * If the setattr was invoked from the ftruncate() system call
    * under Linux kernel versions 2.6.15 or later, the fi->fh will
    * contain the value set by the open method or will be undefined
    * if the open method didn't set any value.  Otherwise (not
    * ftruncate call, or kernel version earlier than 2.6.15) the fi
    * parameter will be NULL.
    *
    * Valid replies:
    *   fuse_reply_attr
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param attr the attributes
    * @param to_set bit mask of attributes which should be set
    * @param fi file information, or NULL
    */
    setattr:         #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *stat, a3: s32, a4: *fuse_file_info) -> void #c_call;

    /**
    * Read symbolic link
    *
    * Valid replies:
    *   fuse_reply_readlink
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    */
    readlink:        #type (a0: fuse_req_t, a1: fuse_ino_t) -> void #c_call;

    /**
    * Create file node
    *
    * Create a regular file, character device, block device, fifo or
    * socket node.
    *
    * Valid replies:
    *   fuse_reply_entry
    *   fuse_reply_err
    *
    * @param req request handle
    * @param parent inode number of the parent directory
    * @param name to create
    * @param mode file type and mode with which to create the new file
    * @param rdev the device number (only valid if created file is a device)
    */
    mknod:           #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *u8, a3: mode_t, a4: dev_t) -> void #c_call;

    /**
    * Create a directory
    *
    * Valid replies:
    *   fuse_reply_entry
    *   fuse_reply_err
    *
    * @param req request handle
    * @param parent inode number of the parent directory
    * @param name to create
    * @param mode with which to create the new file
    */
    mkdir:           #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *u8, a3: mode_t) -> void #c_call;

    /**
    * Remove a file
    *
    * If the file's inode's lookup count is non-zero, the file
    * system is expected to postpone any removal of the inode
    * until the lookup count reaches zero (see description of the
    * forget function).
    *
    * Valid replies:
    *   fuse_reply_err
    *
    * @param req request handle
    * @param parent inode number of the parent directory
    * @param name to remove
    */
    unlink:          #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *u8) -> void #c_call;

    /**
    * Remove a directory
    *
    * If the directory's inode's lookup count is non-zero, the
    * file system is expected to postpone any removal of the
    * inode until the lookup count reaches zero (see description
    * of the forget function).
    *
    * Valid replies:
    *   fuse_reply_err
    *
    * @param req request handle
    * @param parent inode number of the parent directory
    * @param name to remove
    */
    rmdir:           #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *u8) -> void #c_call;

    /**
    * Create a symbolic link
    *
    * Valid replies:
    *   fuse_reply_entry
    *   fuse_reply_err
    *
    * @param req request handle
    * @param link the contents of the symbolic link
    * @param parent inode number of the parent directory
    * @param name to create
    */
    symlink:         #type (a0: fuse_req_t, a1: *u8, a2: fuse_ino_t, a3: *u8) -> void #c_call;

    /** Rename a file
    *
    * If the target exists it should be atomically replaced. If
    * the target's inode's lookup count is non-zero, the file
    * system is expected to postpone any removal of the inode
    * until the lookup count reaches zero (see description of the
    * forget function).
    *
    * If this request is answered with an error code of ENOSYS, this is
    * treated as a permanent failure with error code EINVAL, i.e. all
    * future bmap requests will fail with EINVAL without being
    * send to the filesystem process.
    *
    * *flags* may be `RENAME_EXCHANGE` or `RENAME_NOREPLACE`. If
    * RENAME_NOREPLACE is specified, the filesystem must not
    * overwrite *newname* if it exists and return an error
    * instead. If `RENAME_EXCHANGE` is specified, the filesystem
    * must atomically exchange the two files, i.e. both must
    * exist and neither may be deleted.
    *
    * Valid replies:
    *   fuse_reply_err
    *
    * @param req request handle
    * @param parent inode number of the old parent directory
    * @param name old name
    * @param newparent inode number of the new parent directory
    * @param newname new name
    */
    rename:          #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *u8, a3: fuse_ino_t, a4: *u8, a5: u32) -> void #c_call;

    /**
    * Create a hard link
    *
    * Valid replies:
    *   fuse_reply_entry
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the old inode number
    * @param newparent inode number of the new parent directory
    * @param newname new name to create
    */
    link:            #type (a0: fuse_req_t, a1: fuse_ino_t, a2: fuse_ino_t, a3: *u8) -> void #c_call;

    /**
    * Open a file
    *
    * Open flags are available in fi->flags. The following rules
    * apply.
    *
    *  - Creation (O_CREAT, O_EXCL, O_NOCTTY) flags will be
    *    filtered out / handled by the kernel.
    *
    *  - Access modes (O_RDONLY, O_WRONLY, O_RDWR) should be used
    *    by the filesystem to check if the operation is
    *    permitted.  If the ``-o default_permissions`` mount
    *    option is given, this check is already done by the
    *    kernel before calling open() and may thus be omitted by
    *    the filesystem.
    *
    *  - When writeback caching is enabled, the kernel may send
    *    read requests even for files opened with O_WRONLY. The
    *    filesystem should be prepared to handle this.
    *
    *  - When writeback caching is disabled, the filesystem is
    *    expected to properly handle the O_APPEND flag and ensure
    *    that each write is appending to the end of the file.
    * 
    *  - When writeback caching is enabled, the kernel will
    *    handle O_APPEND. However, unless all changes to the file
    *    come through the kernel this will not work reliably. The
    *    filesystem should thus either ignore the O_APPEND flag
    *    (and let the kernel handle it), or return an error
    *    (indicating that reliably O_APPEND is not available).
    *
    * Filesystem may store an arbitrary file handle (pointer,
    * index, etc) in fi->fh, and use this in other all other file
    * operations (read, write, flush, release, fsync).
    *
    * Filesystem may also implement stateless file I/O and not store
    * anything in fi->fh.
    *
    * There are also some flags (direct_io, keep_cache) which the
    * filesystem may set in fi, to change the way the file is opened.
    * See fuse_file_info structure in <fuse_common.h> for more details.
    *
    * If this request is answered with an error code of ENOSYS
    * and FUSE_CAP_NO_OPEN_SUPPORT is set in
    * `fuse_conn_info.capable`, this is treated as success and
    * future calls to open and release will also succeed without being
    * sent to the filesystem process.
    *
    * Valid replies:
    *   fuse_reply_open
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param fi file information
    */
    open:            #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *fuse_file_info) -> void #c_call;

    /**
    * Read data
    *
    * Read should send exactly the number of bytes requested except
    * on EOF or error, otherwise the rest of the data will be
    * substituted with zeroes.  An exception to this is when the file
    * has been opened in 'direct_io' mode, in which case the return
    * value of the read system call will reflect the return value of
    * this operation.
    *
    * fi->fh will contain the value set by the open method, or will
    * be undefined if the open method didn't set any value.
    *
    * Valid replies:
    *   fuse_reply_buf
    *   fuse_reply_iov
    *   fuse_reply_data
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param size number of bytes to read
    * @param off offset to read from
    * @param fi file information
    */
    read:            #type (a0: fuse_req_t, a1: fuse_ino_t, a2: size_t, a3: off_t, a4: *fuse_file_info) -> void #c_call;

    /**
    * Write data
    *
    * Write should return exactly the number of bytes requested
    * except on error.  An exception to this is when the file has
    * been opened in 'direct_io' mode, in which case the return value
    * of the write system call will reflect the return value of this
    * operation.
    *
    * Unless FUSE_CAP_HANDLE_KILLPRIV is disabled, this method is
    * expected to reset the setuid and setgid bits.
    *
    * fi->fh will contain the value set by the open method, or will
    * be undefined if the open method didn't set any value.
    *
    * Valid replies:
    *   fuse_reply_write
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param buf data to write
    * @param size number of bytes to write
    * @param off offset to write to
    * @param fi file information
    */
    write:           #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *u8, a3: size_t, a4: off_t, a5: *fuse_file_info) -> void #c_call;

    /**
    * Flush method
    *
    * This is called on each close() of the opened file.
    *
    * Since file descriptors can be duplicated (dup, dup2, fork), for
    * one open call there may be many flush calls.
    *
    * Filesystems shouldn't assume that flush will always be called
    * after some writes, or that if will be called at all.
    *
    * fi->fh will contain the value set by the open method, or will
    * be undefined if the open method didn't set any value.
    *
    * NOTE: the name of the method is misleading, since (unlike
    * fsync) the filesystem is not forced to flush pending writes.
    * One reason to flush data is if the filesystem wants to return
    * write errors during close.  However, such use is non-portable
    * because POSIX does not require [close] to wait for delayed I/O to
    * complete.
    *
    * If the filesystem supports file locking operations (setlk,
    * getlk) it should remove all locks belonging to 'fi->owner'.
    *
    * If this request is answered with an error code of ENOSYS,
    * this is treated as success and future calls to flush() will
    * succeed automatically without being send to the filesystem
    * process.
    *
    * Valid replies:
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param fi file information
    *
    * [close]: http://pubs.opengroup.org/onlinepubs/9699919799/functions/close.html
    */
    flush:           #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *fuse_file_info) -> void #c_call;

    /**
    * Release an open file
    *
    * Release is called when there are no more references to an open
    * file: all file descriptors are closed and all memory mappings
    * are unmapped.
    *
    * For every open call there will be exactly one release call (unless
    * the filesystem is force-unmounted).
    *
    * The filesystem may reply with an error, but error values are
    * not returned to close() or munmap() which triggered the
    * release.
    *
    * fi->fh will contain the value set by the open method, or will
    * be undefined if the open method didn't set any value.
    * fi->flags will contain the same flags as for open.
    *
    * Valid replies:
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param fi file information
    */
    release:         #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *fuse_file_info) -> void #c_call;

    /**
    * Synchronize file contents
    *
    * If the datasync parameter is non-zero, then only the user data
    * should be flushed, not the meta data.
    *
    * If this request is answered with an error code of ENOSYS,
    * this is treated as success and future calls to fsync() will
    * succeed automatically without being send to the filesystem
    * process.
    *
    * Valid replies:
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param datasync flag indicating if only data should be flushed
    * @param fi file information
    */
    fsync:           #type (a0: fuse_req_t, a1: fuse_ino_t, a2: s32, a3: *fuse_file_info) -> void #c_call;

    /**
    * Open a directory
    *
    * Filesystem may store an arbitrary file handle (pointer, index,
    * etc) in fi->fh, and use this in other all other directory
    * stream operations (readdir, releasedir, fsyncdir).
    *
    * If this request is answered with an error code of ENOSYS and
    * FUSE_CAP_NO_OPENDIR_SUPPORT is set in `fuse_conn_info.capable`,
    * this is treated as success and future calls to opendir and
    * releasedir will also succeed without being sent to the filesystem
    * process. In addition, the kernel will cache readdir results
    * as if opendir returned FOPEN_KEEP_CACHE | FOPEN_CACHE_DIR.
    *
    * Valid replies:
    *   fuse_reply_open
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param fi file information
    */
    opendir:         #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *fuse_file_info) -> void #c_call;

    /**
    * Read directory
    *
    * Send a buffer filled using fuse_add_direntry(), with size not
    * exceeding the requested size.  Send an empty buffer on end of
    * stream.
    *
    * fi->fh will contain the value set by the opendir method, or
    * will be undefined if the opendir method didn't set any value.
    *
    * Returning a directory entry from readdir() does not affect
    * its lookup count.
    *
    * If off_t is non-zero, then it will correspond to one of the off_t
    * values that was previously returned by readdir() for the same
    * directory handle. In this case, readdir() should skip over entries
    * coming before the position defined by the off_t value. If entries
    * are added or removed while the directory handle is open, the filesystem
    * may still include the entries that have been removed, and may not
    * report the entries that have been created. However, addition or
    * removal of entries must never cause readdir() to skip over unrelated
    * entries or to report them more than once. This means
    * that off_t can not be a simple index that enumerates the entries
    * that have been returned but must contain sufficient information to
    * uniquely determine the next directory entry to return even when the
    * set of entries is changing.
    *
    * The function does not have to report the '.' and '..'
    * entries, but is allowed to do so. Note that, if readdir does
    * not return '.' or '..', they will not be implicitly returned,
    * and this behavior is observable by the caller.
    *
    * Valid replies:
    *   fuse_reply_buf
    *   fuse_reply_data
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param size maximum number of bytes to send
    * @param off offset to continue reading the directory stream
    * @param fi file information
    */
    readdir:         #type (a0: fuse_req_t, a1: fuse_ino_t, a2: size_t, a3: off_t, a4: *fuse_file_info) -> void #c_call;

    /**
    * Release an open directory
    *
    * For every opendir call there will be exactly one releasedir
    * call (unless the filesystem is force-unmounted).
    *
    * fi->fh will contain the value set by the opendir method, or
    * will be undefined if the opendir method didn't set any value.
    *
    * Valid replies:
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param fi file information
    */
    releasedir:      #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *fuse_file_info) -> void #c_call;

    /**
    * Synchronize directory contents
    *
    * If the datasync parameter is non-zero, then only the directory
    * contents should be flushed, not the meta data.
    *
    * fi->fh will contain the value set by the opendir method, or
    * will be undefined if the opendir method didn't set any value.
    *
    * If this request is answered with an error code of ENOSYS,
    * this is treated as success and future calls to fsyncdir() will
    * succeed automatically without being send to the filesystem
    * process.
    *
    * Valid replies:
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param datasync flag indicating if only data should be flushed
    * @param fi file information
    */
    fsyncdir:        #type (a0: fuse_req_t, a1: fuse_ino_t, a2: s32, a3: *fuse_file_info) -> void #c_call;

    /**
    * Get file system statistics
    *
    * Valid replies:
    *   fuse_reply_statfs
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number, zero means "undefined"
    */
    statfs:          #type (a0: fuse_req_t, a1: fuse_ino_t) -> void #c_call;

    /**
    * Set an extended attribute
    *
    * If this request is answered with an error code of ENOSYS, this is
    * treated as a permanent failure with error code EOPNOTSUPP, i.e. all
    * future setxattr() requests will fail with EOPNOTSUPP without being
    * send to the filesystem process.
    *
    * Valid replies:
    *   fuse_reply_err
    */
    setxattr:        #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *u8, a3: *u8, a4: size_t, a5: s32) -> void #c_call;

    /**
    * Get an extended attribute
    *
    * If size is zero, the size of the value should be sent with
    * fuse_reply_xattr.
    *
    * If the size is non-zero, and the value fits in the buffer, the
    * value should be sent with fuse_reply_buf.
    *
    * If the size is too small for the value, the ERANGE error should
    * be sent.
    *
    * If this request is answered with an error code of ENOSYS, this is
    * treated as a permanent failure with error code EOPNOTSUPP, i.e. all
    * future getxattr() requests will fail with EOPNOTSUPP without being
    * send to the filesystem process.
    *
    * Valid replies:
    *   fuse_reply_buf
    *   fuse_reply_data
    *   fuse_reply_xattr
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param name of the extended attribute
    * @param size maximum size of the value to send
    */
    getxattr:        #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *u8, a3: size_t) -> void #c_call;

    /**
    * List extended attribute names
    *
    * If size is zero, the total size of the attribute list should be
    * sent with fuse_reply_xattr.
    *
    * If the size is non-zero, and the null character separated
    * attribute list fits in the buffer, the list should be sent with
    * fuse_reply_buf.
    *
    * If the size is too small for the list, the ERANGE error should
    * be sent.
    *
    * If this request is answered with an error code of ENOSYS, this is
    * treated as a permanent failure with error code EOPNOTSUPP, i.e. all
    * future listxattr() requests will fail with EOPNOTSUPP without being
    * send to the filesystem process.
    *
    * Valid replies:
    *   fuse_reply_buf
    *   fuse_reply_data
    *   fuse_reply_xattr
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param size maximum size of the list to send
    */
    listxattr:       #type (a0: fuse_req_t, a1: fuse_ino_t, a2: size_t) -> void #c_call;

    /**
    * Remove an extended attribute
    *
    * If this request is answered with an error code of ENOSYS, this is
    * treated as a permanent failure with error code EOPNOTSUPP, i.e. all
    * future removexattr() requests will fail with EOPNOTSUPP without being
    * send to the filesystem process.
    *
    * Valid replies:
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param name of the extended attribute
    */
    removexattr:     #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *u8) -> void #c_call;

    /**
    * Check file access permissions
    *
    * This will be called for the access() and chdir() system
    * calls.  If the 'default_permissions' mount option is given,
    * this method is not called.
    *
    * This method is not called under Linux kernel versions 2.4.x
    *
    * If this request is answered with an error code of ENOSYS, this is
    * treated as a permanent success, i.e. this and all future access()
    * requests will succeed without being send to the filesystem process.
    *
    * Valid replies:
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param mask requested access mode
    */
    access:          #type (a0: fuse_req_t, a1: fuse_ino_t, a2: s32) -> void #c_call;

    /**
    * Create and open a file
    *
    * If the file does not exist, first create it with the specified
    * mode, and then open it.
    *
    * See the description of the open handler for more
    * information.
    *
    * If this method is not implemented or under Linux kernel
    * versions earlier than 2.6.15, the mknod() and open() methods
    * will be called instead.
    *
    * If this request is answered with an error code of ENOSYS, the handler
    * is treated as not implemented (i.e., for this and future requests the
    * mknod() and open() handlers will be called instead).
    *
    * Valid replies:
    *   fuse_reply_create
    *   fuse_reply_err
    *
    * @param req request handle
    * @param parent inode number of the parent directory
    * @param name to create
    * @param mode file type and mode with which to create the new file
    * @param fi file information
    */
    create:          #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *u8, a3: mode_t, a4: *fuse_file_info) -> void #c_call;

    /**
    * Test for a POSIX file lock
    *
    * Valid replies:
    *   fuse_reply_lock
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param fi file information
    * @param lock the region/type to test
    */
    getlk:           #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *fuse_file_info, a3: *flock) -> void #c_call;

    /**
    * Acquire, modify or release a POSIX file lock
    *
    * For POSIX threads (NPTL) there's a 1-1 relation between pid and
    * owner, but otherwise this is not always the case.  For checking
    * lock ownership, 'fi->owner' must be used.  The l_pid field in
    * 'struct flock' should only be used to fill in this field in
    * getlk().
    *
    * Note: if the locking methods are not implemented, the kernel
    * will still allow file locking to work locally.  Hence these are
    * only interesting for network filesystems and similar.
    *
    * Valid replies:
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param fi file information
    * @param lock the region/type to set
    * @param sleep locking operation may sleep
    */
    setlk:           #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *fuse_file_info, a3: *flock, a4: s32) -> void #c_call;

    /**
    * Map block index within file to block index within device
    *
    * Note: This makes sense only for block device backed filesystems
    * mounted with the 'blkdev' option
    *
    * If this request is answered with an error code of ENOSYS, this is
    * treated as a permanent failure, i.e. all future bmap() requests will
    * fail with the same error code without being send to the filesystem
    * process.
    *
    * Valid replies:
    *   fuse_reply_bmap
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param blocksize unit of block index
    * @param idx block index within file
    */
    bmap:            #type (a0: fuse_req_t, a1: fuse_ino_t, a2: size_t, a3: u64) -> void #c_call;

    ioctl:           #type (a0: fuse_req_t, a1: fuse_ino_t, a2: s32, a3: *void, a4: *fuse_file_info, a5: u32, a6: *void, a7: size_t, a8: size_t) -> void #c_call;

    /**
    * Poll for IO readiness
    *
    * Note: If ph is non-NULL, the client should notify
    * when IO readiness events occur by calling
    * fuse_lowlevel_notify_poll() with the specified ph.
    *
    * Regardless of the number of times poll with a non-NULL ph
    * is received, single notification is enough to clear all.
    * Notifying more times incurs overhead but doesn't harm
    * correctness.
    *
    * The callee is responsible for destroying ph with
    * fuse_pollhandle_destroy() when no longer in use.
    *
    * If this request is answered with an error code of ENOSYS, this is
    * treated as success (with a kernel-defined default poll-mask) and
    * future calls to pull() will succeed the same way without being send
    * to the filesystem process.
    *
    * Valid replies:
    *   fuse_reply_poll
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param fi file information
    * @param ph poll handle to be used for notification
    */
    poll:            #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *fuse_file_info, a3: *fuse_pollhandle) -> void #c_call;

    /**
    * Write data made available in a buffer
    *
    * This is a more generic version of the ->write() method.  If
    * FUSE_CAP_SPLICE_READ is set in fuse_conn_info.want and the
    * kernel supports splicing from the fuse device, then the
    * data will be made available in pipe for supporting zero
    * copy data transfer.
    *
    * buf->count is guaranteed to be one (and thus buf->idx is
    * always zero). The write_buf handler must ensure that
    * bufv->off is correctly updated (reflecting the number of
    * bytes read from bufv->buf[0]).
    *
    * Unless FUSE_CAP_HANDLE_KILLPRIV is disabled, this method is
    * expected to reset the setuid and setgid bits.
    *
    * Valid replies:
    *   fuse_reply_write
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param bufv buffer containing the data
    * @param off offset to write to
    * @param fi file information
    */
    write_buf:       #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *fuse_bufvec, a3: off_t, a4: *fuse_file_info) -> void #c_call;

    /**
    * Callback function for the retrieve request
    *
    * Valid replies:
    *   fuse_reply_none
    *
    * @param req request handle
    * @param cookie user data supplied to fuse_lowlevel_notify_retrieve()
    * @param ino the inode number supplied to fuse_lowlevel_notify_retrieve()
    * @param offset the offset supplied to fuse_lowlevel_notify_retrieve()
    * @param bufv the buffer containing the returned data
    */
    retrieve_reply:  #type (a0: fuse_req_t, a1: *void, a2: fuse_ino_t, a3: off_t, a4: *fuse_bufvec) -> void #c_call;

    /**
    * Forget about multiple inodes
    *
    * See description of the forget function for more
    * information.
    *
    * Valid replies:
    *   fuse_reply_none
    *
    * @param req request handle
    */
    forget_multi:    #type (a0: fuse_req_t, a1: size_t, a2: *fuse_forget_data) -> void #c_call;

    /**
    * Acquire, modify or release a BSD file lock
    *
    * Note: if the locking methods are not implemented, the kernel
    * will still allow file locking to work locally.  Hence these are
    * only interesting for network filesystems and similar.
    *
    * Valid replies:
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param fi file information
    * @param op the locking operation, see flock(2)
    */
    _flock:           #type (a0: fuse_req_t, a1: fuse_ino_t, a2: *fuse_file_info, a3: s32) -> void #c_call;

    /**
    * Allocate requested space. If this function returns success then
    * subsequent writes to the specified range shall not fail due to the lack
    * of free space on the file system storage media.
    *
    * If this request is answered with an error code of ENOSYS, this is
    * treated as a permanent failure with error code EOPNOTSUPP, i.e. all
    * future fallocate() requests will fail with EOPNOTSUPP without being
    * send to the filesystem process.
    *
    * Valid replies:
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param offset starting point for allocated region
    * @param length size of allocated region
    * @param mode determines the operation to be performed on the given range,
    *             see fallocate(2)
    */
    fallocate:       #type (a0: fuse_req_t, a1: fuse_ino_t, a2: s32, a3: off_t, a4: off_t, a5: *fuse_file_info) -> void #c_call;

    /**
    * Read directory with attributes
    *
    * Send a buffer filled using fuse_add_direntry_plus(), with size not
    * exceeding the requested size.  Send an empty buffer on end of
    * stream.
    *
    * fi->fh will contain the value set by the opendir method, or
    * will be undefined if the opendir method didn't set any value.
    *
    * In contrast to readdir() (which does not affect the lookup counts),
    * the lookup count of every entry returned by readdirplus(), except "."
    * and "..", is incremented by one.
    *
    * Valid replies:
    *   fuse_reply_buf
    *   fuse_reply_data
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param size maximum number of bytes to send
    * @param off offset to continue reading the directory stream
    * @param fi file information
    */
    readdirplus:     #type (a0: fuse_req_t, a1: fuse_ino_t, a2: size_t, a3: off_t, a4: *fuse_file_info) -> void #c_call;

    /**
    * Copy a range of data from one file to another
    *
    * Performs an optimized copy between two file descriptors without the
    * additional cost of transferring data through the FUSE kernel module
    * to user space (glibc) and then back into the FUSE filesystem again.
    *
    * In case this method is not implemented, glibc falls back to reading
    * data from the source and writing to the destination. Effectively
    * doing an inefficient copy of the data.
    *
    * If this request is answered with an error code of ENOSYS, this is
    * treated as a permanent failure with error code EOPNOTSUPP, i.e. all
    * future copy_file_range() requests will fail with EOPNOTSUPP without
    * being send to the filesystem process.
    *
    * Valid replies:
    *   fuse_reply_write
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino_in the inode number or the source file
    * @param off_in starting point from were the data should be read
    * @param fi_in file information of the source file
    * @param ino_out the inode number or the destination file
    * @param off_out starting point where the data should be written
    * @param fi_out file information of the destination file
    * @param len maximum size of the data to copy
    * @param flags passed along with the copy_file_range() syscall
    */
    copy_file_range: #type (a0: fuse_req_t, a1: fuse_ino_t, a2: off_t, a3: *fuse_file_info, a4: fuse_ino_t, a5: off_t, a6: *fuse_file_info, a7: size_t, a8: s32) -> void #c_call;

    /**
    * Find next data or hole after the specified offset
    *
    * If this request is answered with an error code of ENOSYS, this is
    * treated as a permanent failure, i.e. all future lseek() requests will
    * fail with the same error code without being send to the filesystem
    * process.
    *
    * Valid replies:
    *   fuse_reply_lseek
    *   fuse_reply_err
    *
    * @param req request handle
    * @param ino the inode number
    * @param off offset to start search from
    * @param whence either SEEK_DATA or SEEK_HOLE
    * @param fi file information
    */
    lseek:           #type (a0: fuse_req_t, a1: fuse_ino_t, a2: off_t, a3: s32, a4: *fuse_file_info) -> void #c_call;
}

/**
* Callback function for an interrupt
*
* @param req interrupted request
* @param data user data
*/
fuse_interrupt_func_t :: #type (a0: fuse_req_t, a1: *void) -> void #c_call;

/* ----------------------------------------------------------- *
* Filesystem setup & teardown                                 *
* ----------------------------------------------------------- */
fuse_cmdline_opts :: struct {
    singlethread:      s32;
    foreground:        s32;
    debug:             s32;
    nodefault_subtype: s32;
    mountpoint:        *u8;
    show_version:      s32;
    show_help:         s32;
    clone_fd:          s32;
    max_idle_threads:  u32;
}

cuse_info :: struct {
    dev_major:     u32;
    dev_minor:     u32;
    dev_info_argc: u32;
    dev_info_argv: **u8;
    flags:         u32;
}

/*
* Most ops behave almost identically to the matching fuse_lowlevel
* ops except that they don't take @ino.
*
* init_done : called after initialization is complete
* read/write    : always direct IO, simultaneous operations allowed
* ioctl : might be in unrestricted mode depending on ci->flags
*/
cuse_lowlevel_ops :: struct {
    init:      #type (a0: *void, a1: *fuse_conn_info) -> void #c_call;
    init_done: #type (a0: *void) -> void #c_call;
    destroy:   #type (a0: *void) -> void #c_call;
    open:      #type (a0: fuse_req_t, a1: *fuse_file_info) -> void #c_call;
    read:      #type (a0: fuse_req_t, a1: size_t, a2: off_t, a3: *fuse_file_info) -> void #c_call;

    write:     #type (a0: fuse_req_t, a1: *u8, a2: size_t, a3: off_t, a4: *fuse_file_info) -> void #c_call;

    flush:     #type (a0: fuse_req_t, a1: *fuse_file_info) -> void #c_call;
    release:   #type (a0: fuse_req_t, a1: *fuse_file_info) -> void #c_call;
    fsync:     #type (a0: fuse_req_t, a1: s32, a2: *fuse_file_info) -> void #c_call;
    ioctl:     #type (a0: fuse_req_t, a1: s32, a2: *void, a3: *fuse_file_info, a4: u32, a5: *void, a6: size_t, a7: size_t) -> void #c_call;

    poll:      #type (a0: fuse_req_t, a1: *fuse_file_info, a2: *fuse_pollhandle) -> void #c_call;
}

/** Handle for a FUSE filesystem */
fuse :: struct {}

/**
* Readdir flags, passed to ->readdir()
*/
fuse_readdir_flags :: enum u32 {
    FUSE_READDIR_PLUS :: 1;
}

/**
* Readdir flags, passed to fuse_fill_dir_t callback.
*/
fuse_fill_dir_flags :: enum u32 {
    FUSE_FILL_DIR_PLUS :: 2;
}

/** Function to add an entry in a readdir() operation
*
* The *off* parameter can be any non-zero value that enables the
* filesystem to identify the current point in the directory
* stream. It does not need to be the actual physical position. A
* value of zero is reserved to indicate that seeking in directories
* is not supported.
* 
* @param buf the buffer passed to the readdir() operation
* @param name the file name of the directory entry
* @param stbuf file attributes, can be NULL
* @param off offset of the next entry or zero
* @param flags fill flags
* @return 1 if buffer is full, zero otherwise
*/
fuse_fill_dir_t :: #type (a0: *void, a1: *u8, a2: *stat, a3: off_t, a4: fuse_fill_dir_flags) -> s32 #c_call;

/**
* Configuration of the high-level API
*
* This structure is initialized from the arguments passed to
* fuse_new(), and then passed to the file system's init() handler
* which should ensure that the configuration is compatible with the
* file system implementation.
*/
fuse_config :: struct {
    /**
    * If `set_gid` is non-zero, the st_gid attribute of each file
    * is overwritten with the value of `gid`.
    */
    set_gid:             s32;
    gid:                 u32;

    /**
    * If `set_uid` is non-zero, the st_uid attribute of each file
    * is overwritten with the value of `uid`.
    */
    set_uid:             s32;
    uid:                 u32;

    /**
    * If `set_mode` is non-zero, the any permissions bits set in
    * `umask` are unset in the st_mode attribute of each file.
    */
    set_mode:            s32;
    umask:               u32;

    /**
    * The timeout in seconds for which name lookups will be
    * cached.
    */
    entry_timeout:       float64;

    /**
    * The timeout in seconds for which a negative lookup will be
    * cached. This means, that if file did not exist (lookup
    * returned ENOENT), the lookup will only be redone after the
    * timeout, and the file/directory will be assumed to not
    * exist until then. A value of zero means that negative
    * lookups are not cached.
    */
    negative_timeout:    float64;

    /**
    * The timeout in seconds for which file/directory attributes
    * (as returned by e.g. the `getattr` handler) are cached.
    */
    attr_timeout:        float64;

    /**
    * Allow requests to be interrupted
    */
    intr:                s32;

    /**
    * Specify which signal number to send to the filesystem when
    * a request is interrupted.  The default is hardcoded to
    * USR1.
    */
    intr_signal:         s32;

    /**
    * Normally, FUSE assigns inodes to paths only for as long as
    * the kernel is aware of them. With this option inodes are
    * instead remembered for at least this many seconds.  This
    * will require more memory, but may be necessary when using
    * applications that make use of inode numbers.
    *
    * A number of -1 means that inodes will be remembered for the
    * entire life-time of the file-system process.
    */
    remember:            s32;

    /**
    * The default behavior is that if an open file is deleted,
    * the file is renamed to a hidden file (.fuse_hiddenXXX), and
    * only removed when the file is finally released.  This
    * relieves the filesystem implementation of having to deal
    * with this problem. This option disables the hiding
    * behavior, and files are removed immediately in an unlink
    * operation (or in a rename operation which overwrites an
    * existing file).
    *
    * It is recommended that you not use the hard_remove
    * option. When hard_remove is set, the following libc
    * functions fail on unlinked files (returning errno of
    * ENOENT): read(2), write(2), fsync(2), close(2), f*xattr(2),
    * ftruncate(2), fstat(2), fchmod(2), fchown(2)
    */
    hard_remove:         s32;

    /**
    * Honor the st_ino field in the functions getattr() and
    * fill_dir(). This value is used to fill in the st_ino field
    * in the stat(2), lstat(2), fstat(2) functions and the d_ino
    * field in the readdir(2) function. The filesystem does not
    * have to guarantee uniqueness, however some applications
    * rely on this value being unique for the whole filesystem.
    *
    * Note that this does *not* affect the inode that libfuse 
    * and the kernel use internally (also called the "nodeid").
    */
    use_ino:             s32;

    /**
    * If use_ino option is not given, still try to fill in the
    * d_ino field in readdir(2). If the name was previously
    * looked up, and is still in the cache, the inode number
    * found there will be used.  Otherwise it will be set to -1.
    * If use_ino option is given, this option is ignored.
    */
    readdir_ino:         s32;

    /**
    * This option disables the use of page cache (file content cache)
    * in the kernel for this filesystem. This has several affects:
    *
    * 1. Each read(2) or write(2) system call will initiate one
    *    or more read or write operations, data will not be
    *    cached in the kernel.
    *
    * 2. The return value of the read() and write() system calls
    *    will correspond to the return values of the read and
    *    write operations. This is useful for example if the
    *    file size is not known in advance (before reading it).
    *
    * Internally, enabling this option causes fuse to set the
    * `direct_io` field of `struct fuse_file_info` - overwriting
    * any value that was put there by the file system.
    */
    direct_io:           s32;

    /**
    * This option disables flushing the cache of the file
    * contents on every open(2).  This should only be enabled on
    * filesystems where the file data is never changed
    * externally (not through the mounted FUSE filesystem).  Thus
    * it is not suitable for network filesystems and other
    * intermediate filesystems.
    *
    * NOTE: if this option is not specified (and neither
    * direct_io) data is still cached after the open(2), so a
    * read(2) system call will not always initiate a read
    * operation.
    *
    * Internally, enabling this option causes fuse to set the
    * `keep_cache` field of `struct fuse_file_info` - overwriting
    * any value that was put there by the file system.
    */
    kernel_cache:        s32;

    /**
    * This option is an alternative to `kernel_cache`. Instead of
    * unconditionally keeping cached data, the cached data is
    * invalidated on open(2) if if the modification time or the
    * size of the file has changed since it was last opened.
    */
    auto_cache:          s32;

    /**
    * By default, fuse waits for all pending writes to complete
    * and calls the FLUSH operation on close(2) of every fuse fd.
    * With this option, wait and FLUSH are not done for read-only
    * fuse fd, similar to the behavior of NFS/SMB clients.
    */
    no_rofd_flush:       s32;

    /**
    * The timeout in seconds for which file attributes are cached
    * for the purpose of checking if auto_cache should flush the
    * file data on open.
    */
    ac_attr_timeout_set: s32;
    ac_attr_timeout:     float64;

    /**
    * If this option is given the file-system handlers for the
    * following operations will not receive path information:
    * read, write, flush, release, fallocate, fsync, readdir,
    * releasedir, fsyncdir, lock, ioctl and poll.
    *
    * For the truncate, getattr, chmod, chown and utimens
    * operations the path will be provided only if the struct
    * fuse_file_info argument is NULL.
    */
    nullpath_ok:         s32;

    /**
    * The remaining options are used by libfuse internally and
    * should not be touched.
    */
    show_help:           s32;
    modules:             *u8;
    debug:               s32;
}

/**
* The file system operations:
*
* Most of these should work very similarly to the well known UNIX
* file system operations.  A major exception is that instead of
* returning an error in 'errno', the operation should return the
* negated error value (-errno) directly.
*
* All methods are optional, but some are essential for a useful
* filesystem (e.g. getattr).  Open, flush, release, fsync, opendir,
* releasedir, fsyncdir, access, create, truncate, lock, init and
* destroy are special purpose methods, without which a full featured
* filesystem can still be implemented.
*
* In general, all methods are expected to perform any necessary
* permission checking. However, a filesystem may delegate this task
* to the kernel by passing the `default_permissions` mount option to
* `fuse_new()`. In this case, methods will only be called if
* the kernel's permission check has succeeded.
*
* Almost all operations take a path which can be of any length.
*/
fuse_operations :: struct {
    /** Get file attributes.
    *
    * Similar to stat().  The 'st_dev' and 'st_blksize' fields are
    * ignored. The 'st_ino' field is ignored except if the 'use_ino'
    * mount option is given. In that case it is passed to userspace,
    * but libfuse and the kernel will still assign a different
    * inode for internal use (called the "nodeid").
    *
    * `fi` will always be NULL if the file is not currently open, but
    * may also be NULL if the file is open.
    */
    getattr:         #type (a0: *u8, a1: *stat, a2: *fuse_file_info) -> s32 #c_call;

    /** Read the target of a symbolic link
    *
    * The buffer should be filled with a null terminated string.  The
    * buffer size argument includes the space for the terminating
    * null character.   If the linkname is too long to fit in the
    * buffer, it should be truncated.   The return value should be 0
    * for success.
    */
    readlink:        #type (a0: *u8, a1: *u8, a2: size_t) -> s32 #c_call;

    /** Create a file node
    *
    * This is called for creation of all non-directory, non-symlink
    * nodes.  If the filesystem defines a create() method, then for
    * regular files that will be called instead.
    */
    mknod:           #type (a0: *u8, a1: mode_t, a2: dev_t) -> s32 #c_call;

    /** Create a directory
    *
    * Note that the mode argument may not have the type specification
    * bits set, i.e. S_ISDIR(mode) can be false.  To obtain the
    * correct directory type bits use  mode|S_IFDIR
    * */
    mkdir:           #type (a0: *u8, a1: mode_t) -> s32 #c_call;

    /** Remove a file */
    unlink:          #type (a0: *u8) -> s32 #c_call;

    /** Remove a directory */
    rmdir:           #type (a0: *u8) -> s32 #c_call;

    /** Create a symbolic link */
    symlink:         #type (a0: *u8, a1: *u8) -> s32 #c_call;

    /** Rename a file
    *
    * *flags* may be `RENAME_EXCHANGE` or `RENAME_NOREPLACE`. If
    * RENAME_NOREPLACE is specified, the filesystem must not
    * overwrite *newname* if it exists and return an error
    * instead. If `RENAME_EXCHANGE` is specified, the filesystem
    * must atomically exchange the two files, i.e. both must
    * exist and neither may be deleted.
    */
    rename:          #type (a0: *u8, a1: *u8, a2: u32) -> s32 #c_call;

    /** Create a hard link to a file */
    link:            #type (a0: *u8, a1: *u8) -> s32 #c_call;

    /** Change the permission bits of a file
    *
    * `fi` will always be NULL if the file is not currently open, but
    * may also be NULL if the file is open.
    */
    chmod:           #type (a0: *u8, a1: mode_t, a2: *fuse_file_info) -> s32 #c_call;

    /** Change the owner and group of a file
    *
    * `fi` will always be NULL if the file is not currently open, but
    * may also be NULL if the file is open.
    *
    * Unless FUSE_CAP_HANDLE_KILLPRIV is disabled, this method is
    * expected to reset the setuid and setgid bits.
    */
    chown:           #type (a0: *u8, a1: uid_t, a2: gid_t, a3: *fuse_file_info) -> s32 #c_call;

    /** Change the size of a file
    *
    * `fi` will always be NULL if the file is not currently open, but
    * may also be NULL if the file is open.
    *
    * Unless FUSE_CAP_HANDLE_KILLPRIV is disabled, this method is
    * expected to reset the setuid and setgid bits.
    */
    truncate:        #type (a0: *u8, a1: off_t, a2: *fuse_file_info) -> s32 #c_call;

    /** Open a file
    *
    * Open flags are available in fi->flags. The following rules
    * apply.
    *
    *  - Creation (O_CREAT, O_EXCL, O_NOCTTY) flags will be
    *    filtered out / handled by the kernel.
    *
    *  - Access modes (O_RDONLY, O_WRONLY, O_RDWR, O_EXEC, O_SEARCH)
    *    should be used by the filesystem to check if the operation is
    *    permitted.  If the ``-o default_permissions`` mount option is
    *    given, this check is already done by the kernel before calling
    *    open() and may thus be omitted by the filesystem.
    *
    *  - When writeback caching is enabled, the kernel may send
    *    read requests even for files opened with O_WRONLY. The
    *    filesystem should be prepared to handle this.
    *
    *  - When writeback caching is disabled, the filesystem is
    *    expected to properly handle the O_APPEND flag and ensure
    *    that each write is appending to the end of the file.
    *
    *  - When writeback caching is enabled, the kernel will
    *    handle O_APPEND. However, unless all changes to the file
    *    come through the kernel this will not work reliably. The
    *    filesystem should thus either ignore the O_APPEND flag
    *    (and let the kernel handle it), or return an error
    *    (indicating that reliably O_APPEND is not available).
    *
    * Filesystem may store an arbitrary file handle (pointer,
    * index, etc) in fi->fh, and use this in other all other file
    * operations (read, write, flush, release, fsync).
    *
    * Filesystem may also implement stateless file I/O and not store
    * anything in fi->fh.
    *
    * There are also some flags (direct_io, keep_cache) which the
    * filesystem may set in fi, to change the way the file is opened.
    * See fuse_file_info structure in <fuse_common.h> for more details.
    *
    * If this request is answered with an error code of ENOSYS
    * and FUSE_CAP_NO_OPEN_SUPPORT is set in
    * `fuse_conn_info.capable`, this is treated as success and
    * future calls to open will also succeed without being send
    * to the filesystem process.
    *
    */
    open:            #type (a0: *u8, a1: *fuse_file_info) -> s32 #c_call;

    /** Read data from an open file
    *
    * Read should return exactly the number of bytes requested except
    * on EOF or error, otherwise the rest of the data will be
    * substituted with zeroes.   An exception to this is when the
    * 'direct_io' mount option is specified, in which case the return
    * value of the read system call will reflect the return value of
    * this operation.
    */
    read:            #type (a0: *u8, a1: *u8, a2: size_t, a3: off_t, a4: *fuse_file_info) -> s32 #c_call;

    /** Write data to an open file
    *
    * Write should return exactly the number of bytes requested
    * except on error.   An exception to this is when the 'direct_io'
    * mount option is specified (see read operation).
    *
    * Unless FUSE_CAP_HANDLE_KILLPRIV is disabled, this method is
    * expected to reset the setuid and setgid bits.
    */
    write:           #type (a0: *u8, a1: *u8, a2: size_t, a3: off_t, a4: *fuse_file_info) -> s32 #c_call;

    /** Get file system statistics
    *
    * The 'f_favail', 'f_fsid' and 'f_flag' fields are ignored
    */
    statfs:          #type (a0: *u8, a1: *statvfs) -> s32 #c_call;

    /** Possibly flush cached data
    *
    * BIG NOTE: This is not equivalent to fsync().  It's not a
    * request to sync dirty data.
    *
    * Flush is called on each close() of a file descriptor, as opposed to
    * release which is called on the close of the last file descriptor for
    * a file.  Under Linux, errors returned by flush() will be passed to 
    * userspace as errors from close(), so flush() is a good place to write
    * back any cached dirty data. However, many applications ignore errors 
    * on close(), and on non-Linux systems, close() may succeed even if flush()
    * returns an error. For these reasons, filesystems should not assume
    * that errors returned by flush will ever be noticed or even
    * delivered.
    *
    * NOTE: The flush() method may be called more than once for each
    * open().  This happens if more than one file descriptor refers to an
    * open file handle, e.g. due to dup(), dup2() or fork() calls.  It is
    * not possible to determine if a flush is final, so each flush should
    * be treated equally.  Multiple write-flush sequences are relatively
    * rare, so this shouldn't be a problem.
    *
    * Filesystems shouldn't assume that flush will be called at any
    * particular point.  It may be called more times than expected, or not
    * at all.
    *
    * [close]: http://pubs.opengroup.org/onlinepubs/9699919799/functions/close.html
    */
    flush:           #type (a0: *u8, a1: *fuse_file_info) -> s32 #c_call;

    /** Release an open file
    *
    * Release is called when there are no more references to an open
    * file: all file descriptors are closed and all memory mappings
    * are unmapped.
    *
    * For every open() call there will be exactly one release() call
    * with the same flags and file handle.  It is possible to
    * have a file opened more than once, in which case only the last
    * release will mean, that no more reads/writes will happen on the
    * file.  The return value of release is ignored.
    */
    release:         #type (a0: *u8, a1: *fuse_file_info) -> s32 #c_call;

    /** Synchronize file contents
    *
    * If the datasync parameter is non-zero, then only the user data
    * should be flushed, not the meta data.
    */
    fsync:           #type (a0: *u8, a1: s32, a2: *fuse_file_info) -> s32 #c_call;

    /** Set extended attributes */
    setxattr:        #type (a0: *u8, a1: *u8, a2: *u8, a3: size_t, a4: s32) -> s32 #c_call;

    /** Get extended attributes */
    getxattr:        #type (a0: *u8, a1: *u8, a2: *u8, a3: size_t) -> s32 #c_call;

    /** List extended attributes */
    listxattr:       #type (a0: *u8, a1: *u8, a2: size_t) -> s32 #c_call;

    /** Remove extended attributes */
    removexattr:     #type (a0: *u8, a1: *u8) -> s32 #c_call;

    /** Open directory
    *
    * Unless the 'default_permissions' mount option is given,
    * this method should check if opendir is permitted for this
    * directory. Optionally opendir may also return an arbitrary
    * filehandle in the fuse_file_info structure, which will be
    * passed to readdir, releasedir and fsyncdir.
    */
    opendir:         #type (a0: *u8, a1: *fuse_file_info) -> s32 #c_call;

    /** Read directory
    *
    * The filesystem may choose between two modes of operation:
    *
    * 1) The readdir implementation ignores the offset parameter, and
    * passes zero to the filler function's offset.  The filler
    * function will not return '1' (unless an error happens), so the
    * whole directory is read in a single readdir operation.
    *
    * 2) The readdir implementation keeps track of the offsets of the
    * directory entries.  It uses the offset parameter and always
    * passes non-zero offset to the filler function.  When the buffer
    * is full (or an error happens) the filler function will return
    * '1'.
    *
    * When FUSE_READDIR_PLUS is not set, only some parameters of the
    * fill function (the fuse_fill_dir_t parameter) are actually used:
    * The file type (which is part of stat::st_mode) is used. And if
    * fuse_config::use_ino is set, the inode (stat::st_ino) is also
    * used. The other fields are ignored when FUSE_READDIR_PLUS is not
    * set.
    */
    readdir:         #type (a0: *u8, a1: *void, a2: fuse_fill_dir_t, a3: off_t, a4: *fuse_file_info, a5: fuse_readdir_flags) -> s32 #c_call;

    /** Release directory
    *
    * If the directory has been removed after the call to opendir, the
    * path parameter will be NULL.
    */
    releasedir:      #type (a0: *u8, a1: *fuse_file_info) -> s32 #c_call;

    /** Synchronize directory contents
    *
    * If the directory has been removed after the call to opendir, the
    * path parameter will be NULL.
    *
    * If the datasync parameter is non-zero, then only the user data
    * should be flushed, not the meta data
    */
    fsyncdir:        #type (a0: *u8, a1: s32, a2: *fuse_file_info) -> s32 #c_call;

    /**
    * Initialize filesystem
    *
    * The return value will passed in the `private_data` field of
    * `struct fuse_context` to all file operations, and as a
    * parameter to the destroy() method. It overrides the initial
    * value provided to fuse_main() / fuse_new().
    */
    init:            #type (a0: *fuse_conn_info, a1: *fuse_config) -> *void #c_call;

    /**
    * Clean up filesystem
    *
    * Called on filesystem exit.
    */
    destroy:         #type (a0: *void) -> void #c_call;

    /**
    * Check file access permissions
    *
    * This will be called for the access() system call.  If the
    * 'default_permissions' mount option is given, this method is not
    * called.
    *
    * This method is not called under Linux kernel versions 2.4.x
    */
    access:          #type (a0: *u8, a1: s32) -> s32 #c_call;

    /**
    * Create and open a file
    *
    * If the file does not exist, first create it with the specified
    * mode, and then open it.
    *
    * If this method is not implemented or under Linux kernel
    * versions earlier than 2.6.15, the mknod() and open() methods
    * will be called instead.
    */
    create:          #type (a0: *u8, a1: mode_t, a2: *fuse_file_info) -> s32 #c_call;

    /**
    * Perform POSIX file locking operation
    *
    * The cmd argument will be either F_GETLK, F_SETLK or F_SETLKW.
    *
    * For the meaning of fields in 'struct flock' see the man page
    * for fcntl(2).  The l_whence field will always be set to
    * SEEK_SET.
    *
    * For checking lock ownership, the 'fuse_file_info->owner'
    * argument must be used.
    *
    * For F_GETLK operation, the library will first check currently
    * held locks, and if a conflicting lock is found it will return
    * information without calling this method.   This ensures, that
    * for local locks the l_pid field is correctly filled in.   The
    * results may not be accurate in case of race conditions and in
    * the presence of hard links, but it's unlikely that an
    * application would rely on accurate GETLK results in these
    * cases.  If a conflicting lock is not found, this method will be
    * called, and the filesystem may fill out l_pid by a meaningful
    * value, or it may leave this field zero.
    *
    * For F_SETLK and F_SETLKW the l_pid field will be set to the pid
    * of the process performing the locking operation.
    *
    * Note: if this method is not implemented, the kernel will still
    * allow file locking to work locally.  Hence it is only
    * interesting for network filesystems and similar.
    */
    lock:            #type (a0: *u8, a1: *fuse_file_info, a2: s32, a3: *flock) -> s32 #c_call;

    /**
    * Change the access and modification times of a file with
    * nanosecond resolution
    *
    * This supersedes the old utime() interface.  New applications
    * should use this.
    *
    * `fi` will always be NULL if the file is not currently open, but
    * may also be NULL if the file is open.
    *
    * See the utimensat(2) man page for details.
    */
    utimens:         #type (a0: *u8, a1: *[2] timespec, a2: *fuse_file_info) -> s32 #c_call;

    /**
    * Map block index within file to block index within device
    *
    * Note: This makes sense only for block device backed filesystems
    * mounted with the 'blkdev' option
    */
    bmap:            #type (a0: *u8, a1: size_t, a2: *u64) -> s32 #c_call;

    ioctl:           #type (a0: *u8, a1: s32, a2: *void, a3: *fuse_file_info, a4: u32, a5: *void) -> s32 #c_call;

    /**
    * Poll for IO readiness events
    *
    * Note: If ph is non-NULL, the client should notify
    * when IO readiness events occur by calling
    * fuse_notify_poll() with the specified ph.
    *
    * Regardless of the number of times poll with a non-NULL ph
    * is received, single notification is enough to clear all.
    * Notifying more times incurs overhead but doesn't harm
    * correctness.
    *
    * The callee is responsible for destroying ph with
    * fuse_pollhandle_destroy() when no longer in use.
    */
    poll:            #type (a0: *u8, a1: *fuse_file_info, a2: *fuse_pollhandle, a3: *u32) -> s32 #c_call;

    /** Write contents of buffer to an open file
    *
    * Similar to the write() method, but data is supplied in a
    * generic buffer.  Use fuse_buf_copy() to transfer data to
    * the destination.
    *
    * Unless FUSE_CAP_HANDLE_KILLPRIV is disabled, this method is
    * expected to reset the setuid and setgid bits.
    */
    write_buf:       #type (a0: *u8, a1: *fuse_bufvec, a2: off_t, a3: *fuse_file_info) -> s32 #c_call;

    /** Store data from an open file in a buffer
    *
    * Similar to the read() method, but data is stored and
    * returned in a generic buffer.
    *
    * No actual copying of data has to take place, the source
    * file descriptor may simply be stored in the buffer for
    * later data transfer.
    *
    * The buffer must be allocated dynamically and stored at the
    * location pointed to by bufp.  If the buffer contains memory
    * regions, they too must be allocated using malloc().  The
    * allocated memory will be freed by the caller.
    */
    read_buf:        #type (a0: *u8, a1: **fuse_bufvec, a2: size_t, a3: off_t, a4: *fuse_file_info) -> s32 #c_call;

    /**
    * Perform BSD file locking operation
    *
    * The op argument will be either LOCK_SH, LOCK_EX or LOCK_UN
    *
    * Nonblocking requests will be indicated by ORing LOCK_NB to
    * the above operations
    *
    * For more information see the flock(2) manual page.
    *
    * Additionally fi->owner will be set to a value unique to
    * this open file.  This same value will be supplied to
    * ->release() when the file is released.
    *
    * Note: if this method is not implemented, the kernel will still
    * allow file locking to work locally.  Hence it is only
    * interesting for network filesystems and similar.
    */
    _flock:           #type (a0: *u8, a1: *fuse_file_info, a2: s32) -> s32 #c_call;

    /**
    * Allocates space for an open file
    *
    * This function ensures that required space is allocated for specified
    * file.  If this function returns success then any subsequent write
    * request to specified range is guaranteed not to fail because of lack
    * of space on the file system media.
    */
    fallocate:       #type (a0: *u8, a1: s32, a2: off_t, a3: off_t, a4: *fuse_file_info) -> s32 #c_call;

    /**
    * Copy a range of data from one file to another
    *
    * Performs an optimized copy between two file descriptors without the
    * additional cost of transferring data through the FUSE kernel module
    * to user space (glibc) and then back into the FUSE filesystem again.
    *
    * In case this method is not implemented, applications are expected to
    * fall back to a regular file copy.   (Some glibc versions did this
    * emulation automatically, but the emulation has been removed from all
    * glibc release branches.)
    */
    copy_file_range: #type (a0: *u8, a1: *fuse_file_info, a2: off_t, a3: *u8, a4: *fuse_file_info, a5: off_t, a6: size_t, a7: s32) -> ssize_t #c_call;

    /**
    * Find next data or hole after the specified offset
    */
    lseek:           #type (a0: *u8, a1: off_t, a2: s32, a3: *fuse_file_info) -> off_t #c_call;
}

/** Extra context that may be needed by some filesystems
*
* The uid, gid and pid fields are not filled in case of a writepage
* operation.
*/
fuse_context :: struct {
    /** Pointer to the fuse object */
    fuse:         *fuse;

    /** User ID of the calling process */
    uid:          uid_t;

    /** Group ID of the calling process */
    gid:          gid_t;

    /** Process ID of the calling thread */
    pid:          pid_t;

    /** Private filesystem data */
    private_data: *void;

    /** Umask of the calling process */
    umask:        mode_t;
}

/**
* Fuse filesystem object
*
* This is opaque object represents a filesystem layer
*/
fuse_fs :: struct {}

/**
* Factory for creating filesystem objects
*
* The function may use and remove options from 'args' that belong
* to this module.
*
* For now the 'fs' vector always contains exactly one filesystem.
* This is the filesystem which will be below the newly created
* filesystem in the stack.
*
* @param args the command line arguments
* @param fs NULL terminated filesystem object vector
* @return the new filesystem object
*/
fuse_module_factory_t :: #type (a0: *fuse_args, a1: **fuse_fs) -> *fuse_fs #c_call;

/* Make sure all structures are padded to 64bit boundary, so 32bit
userspace works under 64bit kernels */
fuse_attr :: struct {
    ino:       u64;
    size:      u64;
    blocks:    u64;
    atime:     u64;
    mtime:     u64;
    ctime:     u64;
    atimensec: u32;
    mtimensec: u32;
    ctimensec: u32;
    mode:      u32;
    nlink:     u32;
    uid:       u32;
    gid:       u32;
    rdev:      u32;
    blksize:   u32;
    padding:   u32;
}

fuse_kstatfs :: struct {
    blocks:  u64;
    bfree:   u64;
    bavail:  u64;
    files:   u64;
    ffree:   u64;
    bsize:   u32;
    namelen: u32;
    frsize:  u32;
    padding: u32;
    spare:   [6] u32;
}

fuse_file_lock :: struct {
    start: u64;
    end:   u64;
    type:  u32;
    pid:   u32; /* tgid */
}

fuse_opcode :: enum u32 {
    FUSE_LOOKUP          :: 1;
    FUSE_FORGET          :: 2;
    FUSE_GETATTR         :: 3;
    FUSE_SETATTR         :: 4;
    FUSE_READLINK        :: 5;
    FUSE_SYMLINK         :: 6;
    FUSE_MKNOD           :: 8;
    FUSE_MKDIR           :: 9;
    FUSE_UNLINK          :: 10;
    FUSE_RMDIR           :: 11;
    FUSE_RENAME          :: 12;
    FUSE_LINK            :: 13;
    FUSE_OPEN            :: 14;
    FUSE_READ            :: 15;
    FUSE_WRITE           :: 16;
    FUSE_STATFS          :: 17;
    FUSE_RELEASE         :: 18;
    FUSE_FSYNC           :: 20;
    FUSE_SETXATTR        :: 21;
    FUSE_GETXATTR        :: 22;
    FUSE_LISTXATTR       :: 23;
    FUSE_REMOVEXATTR     :: 24;
    FUSE_FLUSH           :: 25;
    FUSE_INIT            :: 26;
    FUSE_OPENDIR         :: 27;
    FUSE_READDIR         :: 28;
    FUSE_RELEASEDIR      :: 29;
    FUSE_FSYNCDIR        :: 30;
    FUSE_GETLK           :: 31;
    FUSE_SETLK           :: 32;
    FUSE_SETLKW          :: 33;
    FUSE_ACCESS          :: 34;
    FUSE_CREATE          :: 35;
    FUSE_INTERRUPT       :: 36;
    FUSE_BMAP            :: 37;
    FUSE_DESTROY         :: 38;
    FUSE_IOCTL           :: 39;
    FUSE_POLL            :: 40;
    FUSE_NOTIFY_REPLY    :: 41;
    FUSE_BATCH_FORGET    :: 42;
    FUSE_FALLOCATE       :: 43;
    FUSE_READDIRPLUS     :: 44;
    FUSE_RENAME2         :: 45;
    FUSE_LSEEK           :: 46;
    FUSE_COPY_FILE_RANGE :: 47;

    CUSE_INIT            :: 4096;
}

fuse_notify_code :: enum u32 {
    POLL        :: 1;
    INVAL_INODE :: 2;
    INVAL_ENTRY :: 3;
    STORE       :: 4;
    RETRIEVE    :: 5;
    DELETE      :: 6;
    CODE_MAX    :: 7;

    FUSE_NOTIFY_POLL        :: POLL;
    FUSE_NOTIFY_INVAL_INODE :: INVAL_INODE;
    FUSE_NOTIFY_INVAL_ENTRY :: INVAL_ENTRY;
    FUSE_NOTIFY_STORE       :: STORE;
    FUSE_NOTIFY_RETRIEVE    :: RETRIEVE;
    FUSE_NOTIFY_DELETE      :: DELETE;
    FUSE_NOTIFY_CODE_MAX    :: CODE_MAX;
}

fuse_entry_out :: struct {
    nodeid:           u64; /* Inode ID */
    /* Inode generation: nodeid:gen must
    be unique for the fs's lifetime */
    generation:       u64;

    entry_valid:      u64; /* Cache timeout for the name */
    attr_valid:       u64; /* Cache timeout for the attributes */
    entry_valid_nsec: u32;
    attr_valid_nsec:  u32;
    attr:             fuse_attr;
}

fuse_forget_in :: struct {
    nlookup: u64;
}

fuse_forget_one :: struct {
    nodeid:  u64;
    nlookup: u64;
}

fuse_batch_forget_in :: struct {
    count: u32;
    dummy: u32;
}

fuse_getattr_in :: struct {
    getattr_flags: u32;
    dummy:         u32;
    fh:            u64;
}

fuse_attr_out :: struct {
    attr_valid:      u64; /* Cache timeout for the attributes */
    attr_valid_nsec: u32;
    dummy:           u32;
    attr:            fuse_attr;
}

fuse_mknod_in :: struct {
    mode:    u32;
    rdev:    u32;
    umask:   u32;
    padding: u32;
}

fuse_mkdir_in :: struct {
    mode:  u32;
    umask: u32;
}

fuse_rename_in :: struct {
    newdir: u64;
}

fuse_rename2_in :: struct {
    newdir:  u64;
    flags:   u32;
    padding: u32;
}

fuse_link_in :: struct {
    oldnodeid: u64;
}

fuse_setattr_in :: struct {
    valid:      u32;
    padding:    u32;
    fh:         u64;
    size:       u64;
    lock_owner: u64;
    atime:      u64;
    mtime:      u64;
    ctime:      u64;
    atimensec:  u32;
    mtimensec:  u32;
    ctimensec:  u32;
    mode:       u32;
    unused4:    u32;
    uid:        u32;
    gid:        u32;
    unused5:    u32;
}

fuse_open_in :: struct {
    flags:  u32;
    unused: u32;
}

fuse_create_in :: struct {
    flags:   u32;
    mode:    u32;
    umask:   u32;
    padding: u32;
}

fuse_open_out :: struct {
    fh:         u64;
    open_flags: u32;
    padding:    u32;
}

fuse_release_in :: struct {
    fh:            u64;
    flags:         u32;
    release_flags: u32;
    lock_owner:    u64;
}

fuse_flush_in :: struct {
    fh:         u64;
    unused:     u32;
    padding:    u32;
    lock_owner: u64;
}

fuse_read_in :: struct {
    fh:         u64;
    offset:     u64;
    size:       u32;
    read_flags: u32;
    lock_owner: u64;
    flags:      u32;
    padding:    u32;
}

fuse_write_in :: struct {
    fh:          u64;
    offset:      u64;
    size:        u32;
    write_flags: u32;
    lock_owner:  u64;
    flags:       u32;
    padding:     u32;
}

fuse_write_out :: struct {
    size:    u32;
    padding: u32;
}

fuse_statfs_out :: struct {
    st: fuse_kstatfs;
}

fuse_fsync_in :: struct {
    fh:          u64;
    fsync_flags: u32;
    padding:     u32;
}

fuse_setxattr_in :: struct {
    size:  u32;
    flags: u32;
}

fuse_getxattr_in :: struct {
    size:    u32;
    padding: u32;
}

fuse_getxattr_out :: struct {
    size:    u32;
    padding: u32;
}

fuse_lk_in :: struct {
    fh:       u64;
    owner:    u64;
    lk:       fuse_file_lock;
    lk_flags: u32;
    padding:  u32;
}

fuse_lk_out :: struct {
    lk: fuse_file_lock;
}

fuse_access_in :: struct {
    mask:    u32;
    padding: u32;
}

fuse_init_in :: struct {
    major:         u32;
    minor:         u32;
    max_readahead: u32;
    flags:         u32;
    flags2:        u32;
    unused:        [11] u32;
}

fuse_init_out :: struct {
    major:                u32;
    minor:                u32;
    max_readahead:        u32;
    flags:                u32;
    max_background:       u16;
    congestion_threshold: u16;
    max_write:            u32;
    time_gran:            u32;
    max_pages:            u16;
    map_alignment:        u16;
    flags2:               u32;
    unused:               [7] u32;
}

cuse_init_in :: struct {
    major:  u32;
    minor:  u32;
    unused: u32;
    flags:  u32;
}

cuse_init_out :: struct {
    major:     u32;
    minor:     u32;
    unused:    u32;
    flags:     u32;
    max_read:  u32;
    max_write: u32;
    dev_major: u32; /* chardev major */
    dev_minor: u32; /* chardev minor */
    spare:     [10] u32;
}

fuse_interrupt_in :: struct {
    unique: u64;
}

fuse_bmap_in :: struct {
    block:     u64;
    blocksize: u32;
    padding:   u32;
}

fuse_bmap_out :: struct {
    block: u64;
}

fuse_ioctl_in :: struct {
    fh:       u64;
    flags:    u32;
    cmd:      u32;
    arg:      u64;
    in_size:  u32;
    out_size: u32;
}

fuse_ioctl_iovec :: struct {
    base: u64;
    len:  u64;
}

fuse_ioctl_out :: struct {
    result:   s32;
    flags:    u32;
    in_iovs:  u32;
    out_iovs: u32;
}

fuse_poll_in :: struct {
    fh:     u64;
    kh:     u64;
    flags:  u32;
    events: u32;
}

fuse_poll_out :: struct {
    revents: u32;
    padding: u32;
}

fuse_notify_poll_wakeup_out :: struct {
    kh: u64;
}

fuse_fallocate_in :: struct {
    fh:      u64;
    offset:  u64;
    length:  u64;
    mode:    u32;
    padding: u32;
}

fuse_in_header :: struct {
    len:     u32;
    opcode:  u32;
    unique:  u64;
    nodeid:  u64;
    uid:     u32;
    gid:     u32;
    pid:     u32;
    padding: u32;
}

fuse_out_header :: struct {
    len:    u32;
    error:  s32;
    unique: u64;
}

fuse_dirent :: struct {
    ino:     u64;
    off:     u64;
    namelen: u32;
    type:    u32;
    name:    *u8;
}

fuse_direntplus :: struct {
    entry_out: fuse_entry_out;
    dirent:    fuse_dirent;
}

fuse_notify_inval_inode_out :: struct {
    ino: u64;
    off: s64;
    len: s64;
}

fuse_notify_inval_entry_out :: struct {
    parent:  u64;
    namelen: u32;
    padding: u32;
}

fuse_notify_delete_out :: struct {
    parent:  u64;
    child:   u64;
    namelen: u32;
    padding: u32;
}

fuse_notify_store_out :: struct {
    nodeid:  u64;
    offset:  u64;
    size:    u32;
    padding: u32;
}

fuse_notify_retrieve_out :: struct {
    notify_unique: u64;
    nodeid:        u64;
    offset:        u64;
    size:          u32;
    padding:       u32;
}

/* Matches the size of fuse_write_in */
fuse_notify_retrieve_in :: struct {
    dummy1: u64;
    offset: u64;
    size:   u32;
    dummy2: u32;
    dummy3: u64;
    dummy4: u64;
}

fuse_lseek_in :: struct {
    fh:      u64;
    offset:  u64;
    whence:  u32;
    padding: u32;
}

fuse_lseek_out :: struct {
    offset: u64;
}

fuse_copy_file_range_in :: struct {
    fh_in:      u64;
    off_in:     u64;
    nodeid_out: u64;
    fh_out:     u64;
    off_out:    u64;
    len:        u64;
    flags:      u64;
}

#scope_file

