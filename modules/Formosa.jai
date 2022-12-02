 
// This is the formosa system API, kind of like #include "windows.h"

#scope_export

Syscall_Numbers :: enum {
    NONE             :: 0x00;
    MAP_MEMORY       :: 0x01;
    UNMAP_MEMORY     :: 0x02;
    WRITE_STRING     :: 0x03;
    READ_FILE        :: 0x04;
    WRITE_FILE       :: 0x05;
    CREATE_FILE      :: 0x06;
    STAT_FILE        :: 0x07;
    GET_MESSAGE      :: 0x08;
    CREATE_WINDOW    :: 0x09;
    CLOSE_WINDOW     :: 0x0a;
    REPAINT          :: 0x0b;
    GET_THEME        :: 0x0c;
    SET_THEME        :: 0x0d;
    INPUT            :: 0x0e;
    OUTPUT           :: 0x0f;
    READ_STRING      :: 0x10;
    LIST_DIRECTORY   :: 0x11;
    GET_TIME         :: 0x12;
    GET_SYSTEM_PARAMETERS :: 0x13;
    WAIT_FOR_MESSAGE :: 0x14;
    GET_DEVICE_LIST  :: 0x15;
    GET_SPACE_NEEDED_FOR_DEVICE_LIST :: 0x16;
    YIELD :: 0x17;
    GET_WINDOW_BUFFER :: 0x19;
    GET_MOUSE_POSITION :: 0x20;
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

formosa_get_time :: () -> Apollo {
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

list_directory :: (name: string) -> [] Directory_Entry_Info {
    using Syscall_Numbers;

    result: [] Directory_Entry_Info;
    _name := *name;
    _result := *result;

    #asm {
        mov rbx: gpr === b, _name;
        mov rcx: gpr === c, _result;
        mov rax: gpr === a, LIST_DIRECTORY;

        int 0x80;
    }

    return result;
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

write_string :: (text: string) {
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

map_memory :: (size: int) -> *void {
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

get_mouse_position :: (in_window := INVALID_WINDOW_HANDLE) -> int, int {
    using Syscall_Numbers;

    x, y: int;
    px, py := *x, *y;
    w := in_window;

    #asm {
        mov rdi: gpr === di, px;
        mov rcx: gpr === c, py;
        mov rdx: gpr === d, w;
        mov rax: gpr === a, GET_MOUSE_POSITION;

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

Directory_Entry_Info :: struct {
    name: string;

    created: Apollo; @Formosa.apollo
    modified: Apollo; @Formosa.apollo
    type: enum int { dir; file; }
    size: int; @Formosa.base16
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
