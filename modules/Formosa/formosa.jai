
// This is the formosa system API, kind of like #include "windows.h"

femtosleep :: (fs: u64) {
    time: Apollo;
    time.low = fs;
    sleep(time);
}

sleep :: (time: Apollo) #no_context {

    low := time.low;
    high := time.high;

    syscall_number := Syscall_Numbers.SLEEP;

    #asm SYSCALL_SYSRET {
        high === b;
        low === 9;
        syscall_number === a;

        syscall rcx:, r11:, low, syscall_number, r8: gpr === 8, high ;
    }
}

System_Params :: struct {
    x_resolution: int;
    y_resolution: int;

    physical_memory: int;
    used_physical_memory: int;
}

get_system_parameters :: (params: *System_Params) {

    syscall_number := Syscall_Numbers.GET_SYSTEM_PARAMETERS;
    #asm SYSCALL_SYSRET {
        params === b;
        syscall_number === a;

        syscall rcx:, r11:, params, syscall_number, r8: gpr === 8 ;
    }
}

create_thread :: (entry_point: (*void)) -> u64 {
handle: u64;
    p_handle := *handle;

    syscall_number := Syscall_Numbers.CREATE_THREAD;

    #asm SYSCALL_SYSRET {
        entry_point === b;
        p_handle === 9;
        syscall_number === a;

        syscall rcx:, r11:, entry_point, p_handle, syscall_number, r8: gpr === 8 ;
    }

    return handle;
}

join_thread :: (thread_handle: u64) {

    syscall_number := Syscall_Numbers.JOIN_THREAD;

    #asm SYSCALL_SYSRET {
        thread_handle === b;
        syscall_number === a;

        syscall rcx:, r11:, thread_handle, syscall_number, r8: gpr === 8 ;
    }
}

formosa_get_time :: () -> Apollo #no_context {

    syscall_number := Syscall_Numbers.GET_TIME;
    
    time: Apollo;
    target := *time;
    #asm SYSCALL_SYSRET {
        target === b;
        syscall_number === a;

        syscall rcx:, r11:, target, syscall_number, r8: gpr === 8 ;
    }
    return time;
}

output :: (value: Any) {

    value_pointer := value.value_pointer;
    type := value.type;

    syscall_number := Syscall_Numbers.OUTPUT;
    
    #asm SYSCALL_SYSRET {
        value_pointer === b;
        type === 9;
        syscall_number === a;

        syscall rcx:, r11:, value_pointer, type, syscall_number, r8: gpr === 8 ;
    }
}

input :: () -> Any {

    result: Any;
    target := *result;

    syscall_number := Syscall_Numbers.INPUT;
    
    #asm SYSCALL_SYSRET {
        target === b;
        syscall_number === a;

        syscall rcx:, r11:, target, syscall_number, r8: gpr === 8 ;
    }

    return result;
}

yield :: () {

    syscall_number := Syscall_Numbers.YIELD;
    
    #asm SYSCALL_SYSRET {
        syscall_number === a;

        syscall rcx:, r11:, syscall_number, r8: gpr === 8 ;
    }
}

exit :: () {

    syscall_number := Syscall_Numbers.EXIT;
    
    #asm SYSCALL_SYSRET {
        syscall_number === a;

        syscall rcx:, r11:, syscall_number, r8: gpr === 8 ;
    }
}

get_theme :: () -> Theme {

    syscall_number := Syscall_Numbers.GET_THEME;
    
    theme: Theme;
    target := *theme;
    #asm SYSCALL_SYSRET {
        target === b;
        syscall_number === a;


        syscall rcx:, r11:, target, syscall_number, r8: gpr === 8;
    }
    return theme;
}

set_theme :: (theme: Theme) {

    syscall_number := Syscall_Numbers.SET_THEME;
    
    source := *theme;
    #asm SYSCALL_SYSRET {
        source === b;
        syscall_number === a;

        syscall rcx:, r11:, source, syscall_number, r8: gpr === 8;
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

    p_name := *name;

    syscall_number := Syscall_Numbers.READ_FILE;
    
    data: [] u8;
    target := *data;
    // result: Filesystem_Result;
    #asm SYSCALL_SYSRET {
        syscall_number === a;
        target === d;
        p_name === 9;

        syscall rcx:, r11:, syscall_number, r8: gpr === 8, target, p_name;
        // mov result, rax;
    }

    return data, /* result */ .success;
}

write_file :: (name: string, data: [] u8) -> Filesystem_Result {
result: Filesystem_Result;

    syscall_number := Syscall_Numbers.WRITE_FILE;
    
    _data := *data;
    _name := *name;
    #asm SYSCALL_SYSRET {
        _data === b;
        _name === 9;
        syscall_number === a;

        syscall rcx:, r11:, _data, _name, syscall_number, r8: gpr === 8;
        // mov result, rax;
    }
    return /* result */ .success;
}

create_file :: (name: string) -> Filesystem_Result {
    result: Filesystem_Result;

    syscall_number := Syscall_Numbers.CREATE_FILE;
    
    _name := *name;
    #asm SYSCALL_SYSRET {
        _name === b;
        syscall_number === a;

        syscall rcx:, r11:, _name, syscall_number, r8: gpr === 8;
        // mov result, rax;
    }
    return /* result */ .success;
}

list_directory :: (name: string) -> [] File_Status, Filesystem_Result {
    result: Filesystem_Result;

    info: [] File_Status;
    _name := *name;
    _info := *info;

    syscall_number := Syscall_Numbers.LIST_DIRECTORY;
    
    #asm SYSCALL_SYSRET {
        _name === b;
        _info === 9;
        syscall_number === a;

        syscall rcx:, r11:, _name, _info, syscall_number, r8: gpr === 8;
    }

    return info, /* result */ .success;
}


Window_Handle :: s64;
INVALID_WINDOW_HANDLE : Window_Handle : -1;

create_window :: (width: int, height: int) -> Window_Handle {

    syscall_number := Syscall_Numbers.CREATE_WINDOW;
    
    result: Window_Handle;
    target := *result;
    #asm SYSCALL_SYSRET {
        width === di;
        height === 9;
        target === d;
        syscall_number === a;

        syscall rcx:, r11:, width, height, target, syscall_number, r8: gpr === 8;
    }
    return result;
}

close_window :: (window: Window_Handle) {

    syscall_number := Syscall_Numbers.CLOSE_WINDOW;
    
    #asm SYSCALL_SYSRET {
        window === b;
        syscall_number === a;

        syscall rcx:, r11:, window, syscall_number, r8: gpr === 8;
    }
}

get_window_buffer :: (window: Window_Handle) -> *u32 {

    syscall_number := Syscall_Numbers.GET_WINDOW_BUFFER;
    
    result: *u32;
    target := *result;
    #asm SYSCALL_SYSRET {
        target === 9;
        window === b;
        syscall_number === a;

        syscall rcx:, r11:, target, window, syscall_number, r8: gpr === 8;
    }
    return result;
}

repaint :: () {

    syscall_number := Syscall_Numbers.REPAINT;
    
    #asm SYSCALL_SYSRET {
        syscall_number === a;

        syscall rcx:, r11:, syscall_number, r8: gpr === 8 ;
    }
}

write_string :: (text: string) #no_context {

    syscall_number := Syscall_Numbers.WRITE_STRING;
    
    count := text.count;
    data := text.data;

    #asm SYSCALL_SYSRET {
        data === b;
        count === 9;
        syscall_number === a;

        syscall rcx:, r11:, data, count, syscall_number, r8: gpr === 8;
    }
}

read_string :: (prompt: string) -> string {

    result: string;
    result_count := *result.count;
    result_data := *result.data;

    prompt_count := prompt.count;
    prompt_data := prompt.data;

    syscall_number := Syscall_Numbers.READ_STRING;
    
    #asm SYSCALL_SYSRET {
        prompt_data === b;
        prompt_count === 9;
        syscall_number === a;

        syscall rcx:, r11:, prompt_data, prompt_count, syscall_number, r8: gpr === 8;

        // mov [result_count], rcx;
        // mov [result_data],  rbx;
    }

    return result;
}

map_memory :: (size: int) -> *void #no_context {

    syscall_number := Syscall_Numbers.MAP_MEMORY;
    
    buffer: *void;
    target := *buffer;

    #asm SYSCALL_SYSRET {
        target === b;
        size === 9;
        syscall_number === a;

        syscall rcx:, r11:, target, size, syscall_number, r8: gpr === 8;
    }

    return buffer;
}

unmap_memory :: (size_bytes: int, buffer: *void) {

    syscall_number := Syscall_Numbers.UNMAP_MEMORY;
    
    #asm SYSCALL_SYSRET {
        size_bytes === b;
        buffer === 9;
        syscall_number === a;

        syscall rcx:, r11:, size_bytes, buffer, syscall_number, r8: gpr === 8;
    }
}

get_message :: () -> Message {

    message: Message;
    target := *message;

    syscall_number := Syscall_Numbers.GET_MESSAGE;
    
    #asm SYSCALL_SYSRET {
        target === b;
        syscall_number === a;

        syscall rcx:, r11:, target, syscall_number, r8: gpr === 8;
    }
    return message;
}

wait_for_message :: () -> Message {

    syscall_number := Syscall_Numbers.WAIT_FOR_MESSAGE;
    
    message: Message;
    target := *message;
    #asm SYSCALL_SYSRET {
        target === b;
        syscall_number === a;

        syscall rcx:, r11:, target, syscall_number, r8: gpr === 8;
    }
    return message;
}

get_mouse_position :: (window := INVALID_WINDOW_HANDLE) -> int, int {

    x, y: int;
    px, py := *x, *y;
    w := window;

    syscall_number := Syscall_Numbers.GET_MOUSE_POSITION;
    
    #asm SYSCALL_SYSRET {
        px === di;
        py === 9;
        w === d;
        syscall_number === a;

        syscall rcx:, r11:, px, py, w, syscall_number, r8: gpr === 8;
    }

    return x, y;
}

get_window_size :: (window: Window_Handle) -> int, int {

    x, y: int;
    px, py := *x, *y;
    w := window;

    syscall_number := Syscall_Numbers.GET_WINDOW_SIZE;
    
    #asm SYSCALL_SYSRET {
        px === di;
        py === 9;
        w === d;
        syscall_number === a;

        syscall rcx:, r11:, px, py, w, syscall_number, r8: gpr === 8;
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
    write_string("\n");
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
