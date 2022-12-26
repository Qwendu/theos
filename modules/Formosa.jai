 
// This is the formosa system API, kind of like #include "windows.h"

#scope_export

Syscall_Numbers :: enum {
    NONE                    :: 0x00;
    MAP_MEMORY              :: 0x01;
    UNMAP_MEMORY            :: 0x02;
    WRITE_STRING            :: 0x03;
    READ_FILE               :: 0x04;
    WRITE_FILE              :: 0x05;
    CREATE_FILE             :: 0x06;
    STAT_FILE               :: 0x07;
    GET_MESSAGE             :: 0x08;
    CREATE_WINDOW           :: 0x09;
    CLOSE_WINDOW            :: 0x0a;
    REPAINT                 :: 0x0b;
    GET_THEME               :: 0x0c;
    SET_THEME               :: 0x0d;
    INPUT                   :: 0x0e;
    OUTPUT                  :: 0x0f;
    READ_STRING             :: 0x10;
    LIST_DIRECTORY          :: 0x11;
    GET_TIME                :: 0x12;
    GET_SYSTEM_PARAMETERS   :: 0x13;
    WAIT_FOR_MESSAGE        :: 0x14;
    GET_DEVICE_LIST         :: 0x15;
    GET_SPACE_NEEDED_FOR_DEVICE_LIST :: 0x16;
    YIELD                   :: 0x17;
    EXIT                    :: 0x18;
    GET_WINDOW_BUFFER       :: 0x19;
    GET_MOUSE_POSITION      :: 0x20;
    GET_WINDOW_SIZE         :: 0x21;
    SLEEP                   :: 0x22;
}

femtosleep :: (fs: u64) {
    time: Apollo;
    time.low = fs;
    sleep(time);
}

sleep :: (time: Apollo) #no_context {
    using Syscall_Numbers;

    low := time.low;
    high := time.high;

    #asm {
        mov rbx: gpr === b, high;
        mov rcx: gpr === c, low;
        mov rax: gpr === a, SLEEP;

        int 0x80;
    }
}

System_Params :: struct {
    x_resolution: int;
    y_resolution: int;

    physical_memory: int;
    used_physical_memory: int;
}

get_system_parameters :: (params: *System_Params) {
    using Syscall_Numbers;

    #asm {
        mov rbx: gpr === b, params;
        mov rax: gpr === a, GET_SYSTEM_PARAMETERS;

        int 0x80;
    }
}

formosa_get_time :: () -> Apollo #no_context {
    using Syscall_Numbers;

    time: Apollo;
    target := *time;
    #asm {
        mov rbx: gpr === b, target;
        mov rax: gpr === a, GET_TIME;

        int 0x80;
    }
    return time;
}

output :: (value: Any) {
    using Syscall_Numbers;

    value_pointer := value.value_pointer;
    type := value.type;

    #asm {
        mov rbx: gpr === b, value_pointer;
        mov rcx: gpr === c, type;
        mov rax: gpr === a, OUTPUT;

        int 0x80;
    }
}

input :: () -> Any {
    using Syscall_Numbers;

    result: Any;
    target := *result;

    #asm {
        mov rbx: gpr === b, target;
        mov rax: gpr === a, INPUT;

        int 0x80;
    }

    return result;
}

yield :: () {
    using Syscall_Numbers;

    #asm {
        mov rax: gpr === a, YIELD;
        int 0x80;
    }
}

exit :: () {
    using Syscall_Numbers;

    #asm {
        mov rax: gpr === a, EXIT;
        int 0x80;
    }
}

get_theme :: () -> Theme {
    using Syscall_Numbers;

    theme: Theme;
    target := *theme;
    #asm {
        mov rbx: gpr === b, target;
        mov rax: gpr === a, GET_THEME;

        int 0x80;
    }
    return theme;
}

set_theme :: (theme: Theme) {
    using Syscall_Numbers;

    source := *theme;
    #asm {
        mov rbx: gpr === b, source;
        mov rax: gpr === a, SET_THEME;

        int 0x80;
    }
}

Filesystem_Result :: enum s64 {
    success :: 0;
    item_doesnt_exist :: 1;
    item_already_exists :: 2;
    invalid_name :: 3;
    item_is_wrong_kind :: 4;
}

read_file :: (name: string) -> [] u8, Filesystem_Result {
    using Syscall_Numbers;

    p_name := *name;

    data: [] u8;
    target := *data;
    result: Filesystem_Result;
    #asm {
        mov rbx: gpr === d, target;
        mov rcx: gpr === c, p_name;
        mov rax: gpr === a, READ_FILE;

        int 0x80;
        mov result, rax;
    }
    return data, /* result */ .success;
}

write_file :: (name: string, data: [] u8) -> Filesystem_Result {
    using Syscall_Numbers;
    result: Filesystem_Result;

    _data := *data;
    _name := *name;
    #asm {
        mov rbx: gpr === b, _data;
        mov rcx: gpr === c, _name;
        mov rax: gpr === a, WRITE_FILE;

        int 0x80;
        mov result, rax;
    }
    return /* result */ .success;
}

create_file :: (name: string) -> Filesystem_Result {
    using Syscall_Numbers;
    result: Filesystem_Result;

    _name := *name;
    #asm {
        mov rbx: gpr === b, _name;
        mov rax: gpr === a, CREATE_FILE;

        int 0x80;
        mov result, rax;
    }
    return /* result */ .success;
}

list_directory :: (name: string) -> [] File_Status, Filesystem_Result {
    using Syscall_Numbers;
    result: Filesystem_Result;

    info: [] File_Status;
    _name := *name;
    _info := *info;

    #asm {
        mov rbx: gpr === b, _name;
        mov rcx: gpr === c, _info;
        mov rax: gpr === a, LIST_DIRECTORY;

        int 0x80;
    }

    return info, /* result */ .success;
}


Window_Handle :: s64;
INVALID_WINDOW_HANDLE : Window_Handle : -1;

create_window :: (width: int, height: int) -> Window_Handle {
    using Syscall_Numbers;

    result: Window_Handle;
    target := *result;
    #asm {
        mov rbx: gpr === di, width;
        mov rcx: gpr === c, height;
        mov rdx: gpr === d, target;
        mov rax: gpr === a, CREATE_WINDOW;

        int 0x80;
    }
    return result;
}

close_window :: (window: Window_Handle) {
    using Syscall_Numbers;

    #asm {
        mov rbx: gpr === b, window;
        mov rax: gpr === a, CLOSE_WINDOW;

        int 0x80;
    }
}

get_window_buffer :: (window: Window_Handle) -> *u32 {
    using Syscall_Numbers;

    result: *u32;
    target := *result;
    #asm {
        mov rcx: gpr === c, target;
        mov rbx: gpr === b, window;
        mov rax: gpr === a, GET_WINDOW_BUFFER;

        int 0x80;
    }
    return result;
}

repaint :: () {
    using Syscall_Numbers;

    #asm {
        mov rax: gpr === a, REPAINT;
        int 0x80;
    }
}

write_string :: (text: string) #no_context {
    using Syscall_Numbers;

    count := text.count;
    data := text.data;
    #asm {
        mov rbx: gpr === b, data;
        mov rcx: gpr === c, count;
        mov rax: gpr === a, WRITE_STRING;

        int 0x80;
    }
}

read_string :: (prompt: string) -> string {
    using Syscall_Numbers;

    result: string;
    result_count := *result.count;
    result_data := *result.data;

    prompt_count := prompt.count;
    prompt_data := prompt.data;

    #asm {
        mov rbx: gpr === b, prompt_data;
        mov rcx: gpr === c, prompt_count;
        mov rax: gpr === a, READ_STRING;

        int 0x80;

        mov [result_count], rcx;
        mov [result_data],  rbx;
    }

    return result;
}

map_memory :: (size: int) -> *void #no_context {
    using Syscall_Numbers;

    buffer: *void;
    target := *buffer;
    #asm {
        mov rbx: gpr === b, target;
        mov rcx: gpr === c, size;
        mov rax: gpr === a, MAP_MEMORY;

        int 0x80;
    }
    return buffer;
}

unmap_memory :: (size_bytes: int, buffer: *void) {
    using Syscall_Numbers;

    #asm {
        mov rbx: gpr === b, size_bytes;
        mov rcx: gpr === c, buffer;
        mov rax: gpr === a, UNMAP_MEMORY;

        int 0x80;
    }
}

get_message :: () -> Message {
    using Syscall_Numbers;

    message: Message;
    target := *message;
    #asm {
        mov rbx: gpr === b, target;
        mov rax: gpr === a, GET_MESSAGE;

        int 0x80;
    }
    return message;
}

wait_for_message :: () -> Message {
    using Syscall_Numbers;

    message: Message;
    target := *message;
    #asm {
        mov rbx: gpr === b, target;
        mov rax: gpr === a, WAIT_FOR_MESSAGE;

        int 0x80;
    }
    return message;
}

// get_device_list :: (space: *void) -> [] Hardware_Device {
//     using Syscall_Numbers;
// 
//     count: int;
//     _count := *count;
//     #asm {
//         mov rcx: gpr === c, _count;
//         mov rbx: gpr === b, space;
//         mov rax: gpr === a, GET_DEVICE_LIST;
// 
//         int 0x80;
//     }
// 
//     result: [] Hardware_Device;
//     result.count = count;
//     result.data = cast(*Hardware_Device) space;
//     return result;
// }
// 
// get_space_needed_for_device_list :: () -> int {
//     using Syscall_Numbers;
// 
//     result: int;
//     _result := *result;
//     #asm {
//         mov rbx: gpr === b, _result;
//         mov rax: gpr === a, GET_SPACE_NEEDED_FOR_DEVICE_LIST;
// 
//         int 0x80;
//     }
// 
//     return result;
// }

get_mouse_position :: (window := INVALID_WINDOW_HANDLE) -> int, int {
    using Syscall_Numbers;

    x, y: int;
    px, py := *x, *y;
    w := window;

    #asm {
        mov rdi: gpr === di, px;
        mov rcx: gpr === c, py;
        mov rdx: gpr === d, w;
        mov rax: gpr === a, GET_MOUSE_POSITION;

        int 0x80;
    }

    return x, y;
}

get_window_size :: (window: Window_Handle) -> int, int {
    using Syscall_Numbers;

    x, y: int;
    px, py := *x, *y;
    w := window;

    #asm {
        mov rdi: gpr === di, px;
        mov rcx: gpr === c, py;
        mov rdx: gpr === d, w;
        mov rax: gpr === a, GET_WINDOW_SIZE;

        int 0x80;
    }

    return x, y;
}

Message :: struct {
    kind: Message_Kind;
    using data: union {
        keyboard: Keyboard_Event;
        mouse: Mouse_Event;
    };
}

Message_Kind :: enum {
    NONE;
    EXIT;
    KEYBOARD;
    MOUSE;
    THEME_CHANGED;
}

Mouse_Event :: struct {
    event: Mouse_Event_Type;

    maybe_window: Window_Handle;
    pixel_position_x: int;
    pixel_position_y: int;

    pixel_position_in_window_x: int;
    pixel_position_in_window_y: int;
}

Keyboard_Event :: struct {
    key: Key_Code;
    type: enum u8 { PRESSED; RELEASED; };
}

Mouse_Event_Type :: enum {
    NONE;
    MOVE_ONLY;
    BUTTON_1_PRESSED;
    BUTTON_1_RELEASED;
    BUTTON_2_PRESSED;
    BUTTON_2_RELEASED;
}

Theme :: struct {
    background:  u32; @hex
    foreground:  u32; @hex
    primary:     u32; @hex
    secondary:   u32; @hex
    highlight:   u32; @hex
    accent:      u32; @hex

    shadow: float;

#place background;
    array: [6] u32;
}

Apollo :: struct {
    low:  u64;
    high: s64;
}

File_Information :: struct {
    size_bytes: int;

    creation_date: Apollo;
    modification_date: Apollo;
}

File_Status :: struct {
    name: string;

    type: enum int { folder; file; }
    size: int; @Formosa.cond(type=file) @Formosa.bytes
    entries: int; @Formosa.cond(type=folder) @Formosa.unit(entries)

    created: Apollo; @Formosa.apollo
    modified: Apollo; @Formosa.apollo
}

Rich_Text :: struct {
    text: string;
    attributes: [] Attribute;

    Attribute :: struct {
        start_position: int;
        color: u32;
    }
}

GAMEPAD_BUTTON_COUNT :: 32;

Key_Code :: enum u32 {
    UNKNOWN     :: 0;

    BACKSPACE   :: 8;
    TAB         :: 9;
    LINEFEED    :: 10;
    ENTER       :: 13;
    ESCAPE      :: 27;
    SPACEBAR    :: 32;
    
    DELETE      :: 127;

    ARROW_UP    :: 128;
    ARROW_DOWN  :: 129;
    ARROW_LEFT  :: 130;
    ARROW_RIGHT :: 131;

    PAGE_UP     :: 132;
    PAGE_DOWN   :: 133;

    HOME        :: 134;
    END         :: 135;

    INSERT      :: 136;

    PAUSE       :: 137;
    SCROLL_LOCK :: 138;
    
    ALT;
    CTRL;
    SHIFT;
    
    F1;         
    F2;
    F3;
    F4;
    F5;
    F6;
    F7;
    F8;
    F9;
    F10;
    F11;
    F12;
    F13;
    F14;
    F15;
    F16;
    F17;
    F18;
    F19;
    F20;
    F21;
    F22;
    F23;
    F24;

    PRINT_SCREEN;

    MOUSE_BUTTON_LEFT;
    MOUSE_BUTTON_MIDDLE;
    MOUSE_BUTTON_RIGHT;

    MOUSE_WHEEL_UP;
    MOUSE_WHEEL_DOWN;

    GAMEPAD_0_BEGIN;
    GAMEPAD_0_END :: GAMEPAD_0_BEGIN + xx GAMEPAD_BUTTON_COUNT;
    GAMEPAD_1_BEGIN;
    GAMEPAD_1_END :: GAMEPAD_1_BEGIN + xx GAMEPAD_BUTTON_COUNT;
    GAMEPAD_2_BEGIN;
    GAMEPAD_2_END :: GAMEPAD_2_BEGIN + xx GAMEPAD_BUTTON_COUNT;
    GAMEPAD_3_BEGIN;
    GAMEPAD_3_END :: GAMEPAD_3_BEGIN + xx GAMEPAD_BUTTON_COUNT;

    RIGHT_ALT;
    RIGHT_CTRL;
    RIGHT_SHIFT;

    FLAG;
    RIGHT_FLAG;

    NUMLOCK;

    KEYPAD_7;
    KEYPAD_8;
    KEYPAD_9;
    KEYPAD_4;
    KEYPAD_5;
    KEYPAD_6;
    KEYPAD_1;
    KEYPAD_2;
    KEYPAD_3;
    KEYPAD_0;

    KEYPAD_MINUS;
    KEYPAD_PLUS;
    KEYPAD_PERIOD;
    KEYPAD_ENTER;

    MUTE;
    CALCULATOR;
    PLAY;
    STOP;
    WWW;
    PREVIOUS_TRACK;
    NEXT_TRACK;

    KEY_CODE_COUNT;
}

key_code_to_ascii :: (key: Key_Code, shift: bool = false) -> u8 {
    if key < 31 || key > 126 return 0;

    if key >= #char "A" && key <= #char "Z" {
        if shift return xx key;
        else return xx key + cast(u8) (#char "a" - #char "A");
    }

    if !shift return xx key;
    if key >= #char "#" && key <= #char "=" {
        return "~\0\0\0@\0\0\0\0<_>?)!\"£$%^&*(\0:\0+"[key - #char "#"];
    }

    if key == #char "[" return #char "{";
    if key == #char "\\" return #char "|";
    if key == #char "]" return #char "}";
    // if key == #char "`" return #char "¬";

    return 0;
}

make_context :: () -> Context #no_context {
    user_context: Context;
    user_context.allocator.proc = allocate_memory;
    user_context.logger = my_log;
    user_context.assertion_failed = assertion_failed;

    return user_context;
}



#scope_file



my_log :: (message: string, data: *void, info: Log_Info) {
    write_string(message);
}

allocate_memory :: (mode: Allocator_Mode, size: s64, old_size: s64, old_buffer: *void, user_data: *void) -> *void {
    if mode == .FREE {
        unmap_memory(old_size, xx old_buffer);
        return null;
    }

    if mode == .RESIZE && old_size {
        if size < old_size || size < 4096 {
            return old_buffer;
        }

        new := map_memory(size);
        memcpy(new, old_buffer, old_size);
        return new;
    }

    return map_memory(size);
}

assertion_failed :: (location: Source_Code_Location, message: string) {

    write_int :: (number: int) {
        negative: bool;
        buffer: [] u8;
        buffer.count = 30;
        buffer.data = map_memory(30);

        _number := number;
        if number < 0 _number *= -1;

        for 0..buffer.count - 1 {
            rem := _number % 10;
            buffer[29 - it] =  #char "0" + cast(u8) rem;
            _number /= 10;

            if _number == 0 {
                result: string = ---;
                result.data = buffer.data + 29 - it;
                result.count = it + 1;
                write_string(result);
                return;
            }
        }
    }

    write_string("\nAssertion failure!\n  -> ");
    write_string(location.fully_pathed_filename);
    write_string(":");
    write_int(location.line_number);

    if message.count {
        write_string("\n     ");
        write_string(message);
    }
    write_string("\n\n");
    repaint();

    write_string("\nStack trace:\n");
    node := context.stack_trace;
    while node {
        if node.info != null {
            write_string("In file \"");
            write_string(node.info.location.fully_pathed_filename);
            write_string("\" -> in proc \"");
            write_string(node.info.name);
            write_string("\" on line ");
            write_int(node.line_number);
            write_string("\n");
        }

        repaint();
        node = node.next;
    }
    repaint();
    exit();
}

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

#program_export
crt_malloc :: (size: u64) -> *void #c_call {
    return map_memory(xx size);
}

#program_export
crt_free :: (ptr: *void) #c_call {
    return;
}

#program_export
crt_realloc :: (ptr: *void, size: u64) -> *void #c_call {
    new_buffer := map_memory(xx size);
    memcpy(new_buffer, ptr, xx size);
    return new_buffer;
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
    if variable_name == "FREETYPE_PROPERTIES"  return "freetype\0".data;
    else {
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
//    Sadness :: #import "Basic";
//    #import "POSIX";
//
//    push_context make_context() {
//        time := formosa_get_time();
//        ts, success := Sadness.to_timespec(<< cast(*Sadness.Apollo_Time) *time);
//        if !success  return -1;
//        << cast(*timespec) out_ts = ts;
//    }

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
crt_write :: (fd: s32, buffer: *u8, count: u64) -> u64 #c_call {
    message: string;
    message.count = cast(int) count;
    message.data = buffer;

    if fd == 0 || fd == 1 {
        write_string(message);
    }

    return count;
}

timespec :: struct {
    tv_sec:  s64;
    tv_nsec: s64;
}

#program_export
nanosleep :: (ts: *timespec, rem: *timespec) -> s32 #c_call {
    operator + :: (a: Apollo, b: Apollo) -> Apollo #no_context {
        c: Apollo = ---;
        p := *c; // We would like to not have to do this, but #asm doesn't let us put c yet.

        #asm {
            mov a_low:,  [a + 0];
            mov a_high:, [a + 8];

            mov b_low:,  [b + 0];
            mov b_high:, [b + 8];

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
