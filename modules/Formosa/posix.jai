
#scope_module

#program_export
crt_memset :: (target: *u8, value: s32, count: u64) -> *void #c_call {
    #asm {
        cld;

        count  === c;
        target === di;
        value  === a;
        rep_stos.b target, value, count;
    }

    return target;
}

#program_export
crt_memcpy :: (dst: *void, src: *void, count: u64) -> *void #c_call {
    #asm {
        cld;

        src   === si;
        dst   === di;
        count === c;
        rep_movs.b dst, src, count;
    }

    return dst;
}

#program_export
crt_memcmp :: (a: *u8, b: *u8, count: u64) -> s32 #c_call {
    for 0..(cast(s64) count)-1 {
        if a[it] != b[it] {
            return a[it] - b[it];
        }
    }
    return 0;
}

#program_export
crt_chdir :: (path: *u8) -> s32 #c_call {
    return 0;
}

#import "Hash_Table";
allocation_sizes: Table(*void, u64);

#program_export
crt_malloc :: (size: u64) -> *void #c_call {
    address := map_memory(cast,trunc(s64) size);
    push_context make_context() { table_add(*allocation_sizes, address, size); }
    return address;
}

#program_export
crt_calloc :: (nmemb: u64, size: u64) -> *void #c_call {
    address := map_memory(cast,trunc(s64) (size * nmemb));
    push_context make_context() { table_add(*allocation_sizes, address, size); }
    return address;
}

#program_export
crt_free :: (ptr: *void) #c_call {
    push_context make_context() { table_remove(*allocation_sizes, ptr); }
    return;
}

#program_export
crt_realloc :: (ptr: *void, size: u64) -> *void #c_call {
    if !ptr return map_memory(xx size);

    push_context make_context() {
        old_size, success := table_find(*allocation_sizes, ptr);
        if !success #asm { cli; hlt; }
        new_buffer := map_memory(xx size);
        memcpy(new_buffer, ptr, xx old_size);
        return new_buffer;
    }
}

#program_export
crt_strcmp :: (s1: *u8, s2: *u8) -> s32 #c_call {
    n: int;
    while s1[n] && (s1[n] == s2[n])  n += 1;
    return cast(s32) s1[n] - cast(s32) s2[n];
}

#program_export
crt_strlen :: (s: *u8) -> u64 #c_call {
    n: u64;
    while s[n]  n += 1;
    return n;
}

#program_export
crt_strstr :: (haystack: *u8, needle: *u8) -> *u8 #c_call {
    n: u64;
    while << haystack {
        if crt_strcmp(haystack, needle) == 0  return haystack;
        haystack += 1;
    }
    return null;
}

#program_export
crt_memmove :: (dest: *u8, src: *u8, n: u64) -> *void #c_call {
    if !dest || !src return dest;

    if src < dest && src + n > dest {
        for < xx n-1..0  dest[it] = src[it];
    } else {
        for 0..xx n-1  dest[it] = src[it];
    }

    return dest;
}

#program_export
crt_getenv :: (name: *u8) -> *u8 #c_call {
    variable_name: string;
    variable_name.data = name;
    while name[variable_name.count] != 0 variable_name.count += 1;

    // The sophisticated way in which environment variables work in this operating system
    if variable_name == "FREETYPE_PROPERTIES" {
        return "freetype\0".data;
    } else {
        write_string("Environment variable accessed: ");
        write_string(variable_name);
        write_string("\n");
    }

    return "\0".data;
}

FILE :: struct {
    path: string;
    cursor: int;
}

#program_export
crt_fopen :: (pathname: *u8, mode: *u8) -> *FILE #c_call {
    file := cast(*FILE) map_memory(size_of(FILE));
    file.path.count = xx crt_strlen(pathname);
    file.path.data = map_memory(file.path.count);
    memcpy(file.path.data, pathname, file.path.count);

    file.cursor = 0;

    return file;
}

#program_export
crt_fread :: (ptr: *void, size: u64, nmemb: u64, stream: *FILE) -> u64 #c_call {
    push_context make_context() {
        bytes := nmemb * size;
        data, result := read_file(stream.path);
        if result != .success return 0;

        memcpy(ptr, data.data + stream.cursor, xx bytes);
        unmap_memory(data.count, data.data);
        stream.cursor += xx bytes;
        return bytes;
    }
}

#program_export
crt_fclose :: (stream: *FILE) -> s32 #c_call {
    push_context make_context() {
        unmap_memory(stream.path.count, stream.path.data);
        unmap_memory(size_of(FILE), stream);
    }
    return 0;
}

SEEK_SET :: 0;
SEEK_CUR :: 1;
SEEK_END :: 2;

#program_export
crt_fseek :: (stream: *FILE, offset: s64, whence: s32) -> s32 #c_call {
    if whence == SEEK_SET  stream.cursor = offset;
    if whence == SEEK_CUR  stream.cursor += offset;
    if whence == SEEK_END  write_string("Fseek end\n");
    return 0;
}

#program_export
crt_clock_gettime :: (clockid_t: s32, out_ts: *void) -> s32 #c_call {
    Sadness :: #import "Basic";
    POSIX :: #import "POSIX";

    push_context make_context() {
        time := formosa_get_time();
        ts, success := Sadness.to_timespec(<< cast(*Sadness.Apollo_Time) *time);
        if !success  return -1;
        << cast(*POSIX.timespec) out_ts = ts;
    }

    return 0;
}

#program_export
crt_fmod :: (x: float64, y: float64) -> float64 #c_call {
    return x - cast(float64) cast(int) (x / y) * y;
}

#program_export
crt_fmodf :: (x: float, y: float) -> float #c_call {
    return x - cast(float) cast(int) (x / y) * y;
}

#program_export
crt_pthread_mutex_init :: (mutex: *void, attr: *void) -> s32 #c_call {
    return 0;
}

#program_export
crt_pthread_mutexattr_init :: (attr: *void) -> s32 #c_call {
    return 0;
}

#program_export
crt_pthread_mutexattr_settype :: (attr: *void, type: s32) -> s32 #c_call {
    return 0;
}

#program_export
crt_pthread_mutex_unlock :: (mutex: *void) -> s32 #c_call {
    return 0;
}

#program_export
crt_pthread_mutex_lock :: (mutex: *void) -> s32 #c_call {
    return 0;
}

#program_export
crt_setjmp :: (env: *void) -> s32 #c_call {
    return 0;
}

#program_export
crt_write :: (fd: s32, buffer: *u8, count: u64) -> u64 #c_call {
    message: string;
    message.count = cast(int) count;
    message.data = buffer;

    if fd == 0 || fd == 1 {
        write_string(message);
    } else {
        write_string("Hm.\n\n");
    }

    return count;
}

    timespec :: struct {
        tv_sec:  s64;
        tv_nsec: s64;
    }

#program_export
crt_nanosleep :: (ts: *timespec, _rem: *timespec) -> s32 #c_call {

    rem := cast(*timespec) _rem;
    operator + :: (a: Apollo, b: Apollo) -> Apollo #no_context {
        c: Apollo = ---;
        p := *c; // We would like to not have to do this, but #asm doesn't let us put c yet.

        #asm {
            mov a_low:,  [*a + 0];
            mov a_high:, [*a + 8];

            mov b_low:,  [*b + 0];
            mov b_high:, [*b + 8];

            mov [p + 0], a_low;
            mov [p + 8], a_high;

            add [p + 0], b_low;
            adc [p + 8], b_high;
        }

        return c;
    }

    ConvertToApollo :: (m: s64, FACTOR: s64) -> Apollo #expand {
        result: Apollo = ---;
        p := *result; // We would like to not have to do this, but #asm doesn't let us put 'result' yet.

        #asm {
            result_high: gpr === d;
            result_low:  gpr === a;

            mov result_low, FACTOR;
            imul result_high, result_low, m;

            mov [p + 0], result_low;
            mov [p + 8], result_high;
        }

        `return result; // `;

    }

    timespec_to_apollo :: (ts: timespec) -> Apollo #no_context {
        a_seconds     := ConvertToApollo(ts.tv_sec,  1_000_000_000_000_000);
        a_nanoseconds := ConvertToApollo(ts.tv_nsec, 1_000_000);

        apollo := a_seconds + a_nanoseconds + Apollo.{low=0xdbd87f0edb7c8000, high=0x300};
        return apollo;
    }

    apollo := timespec_to_apollo(<< ts);
    sleep(apollo);

    if rem then << rem = .{};
    return 0;
}

#program_export
crt_mmap :: (addr: *void, length: u64, prot: s32, flags: s32, fd: s32, offset: u64) -> *void #c_call {
    return map_memory(xx length);
}
