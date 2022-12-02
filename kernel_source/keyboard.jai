
// scan_table         :: "\0#1234567890-=\0\tqwertyuiop[]\0\0asdfghjkl;'`\0\\zxcvbnm,./\0*\0 ";
// scan_table_shifted :: "\0#!@#$%^&*()_+\0\0QWERTYUIOP{}\0\0ASDFGHJKL:\"~\0|ZXCVBNM<>?\0*\0 ";

Event_Buffer :: struct (T: Type) {
    size :: 32;
    buffer: [size] T;
    read_index: int;
    write_index: int;
}

read_event_buffer :: (event_buffer: *Event_Buffer($T)) -> T, bool {
    using event_buffer;

    default: T;
    if read_index == write_index return default, false;

    event := buffer[read_index];

    read_index += 1;
    read_index %= size;

    return event, true;
}

write_event_buffer :: (event_buffer: *Event_Buffer($T), event: T) #no_context {
    using event_buffer;

    buffer[write_index] = event;

    write_index += 1;
    write_index %= size;
}

input_key_buffer: Event_Buffer(Keyboard_Event);
pending_0xe0: bool;


#program_export
ps2_interrupt :: () #c_call {
    defer pic_end_of_interrupt(.PS2_KEYBOARD);

    key: u16 = port_read(Ps2_Port.DATA);


    if key == 0xe0 {
        pending_0xe0 = true;
        return;
    }

    if pending_0xe0 {
        key += 0xe0;
        pending_0xe0 = false;
    }

    event: Keyboard_Event;

    if key >= 0x80 && key <= 0xe0 {
        event.key = get_key_code(xx (key - 0x80));
        event.type = .RELEASED;
    } else {
        event.key = get_key_code(xx key);
        event.type = .PRESSED;
    }

    write_event_buffer(*input_key_buffer, event);
}

mouse_wait :: ($ is_signal: bool) #no_context {
    tick := 10000;

    for 1..tick {
        #if is_signal if !(port_read(Ps2_Port.STATUS) & 2) return;
        else          if   port_read(Ps2_Port.STATUS) & 1  return;
    }
}

mouse: struct {
    step: int;
    bytes: [4] u8;
    button_1: bool;
    button_2: bool;

    position_x: int;
    position_y: int;

    buffer: Event_Buffer(Mouse_Event_Type);
}

Ps2_Port :: enum {
    DATA :: 0x60;
    COMMAND :: 0x64;
    STATUS  :: 0x64;
}

PS2_ACK :: 0xfa;

Ps2_Mouse_Cmd :: enum {
    RESET :: 0xff;
    RESEND :: 0xfe;
    SET_DEFAULTS :: 0xf6;
    DISABLE_DATA_REPORTING :: 0xf5;
    ENABLE_DATA_REPORTING :: 0xf4;
    SET_SAMPLE_RATE :: 0xf3;
    GET_DEVICE_ID :: 0xf2;
}

Ps2_Controller_Cmd :: enum {
    READ_CONFIG_BYTE :: 0x20;
    WRITE_CONFIG_BYTE :: 0x60;
    ENABLE_SECOND_PS2_PORT :: 0xa8;
    WRITE_MOUSE_COMMAND :: 0xd4;

}

Mouse_Packet :: enum_flags {
    LEFT_BTN;
    RIGHT_BTN;
    MIDDLE_BTN;
    ONE;
    X_SIGN;
    Y_SIGN;
    X_OVERFLOW;
    Y_OVERFLOW;
}

#program_export
ps2_mouse :: () #c_call {
    defer pic_end_of_interrupt(.PS2_MOUSE);
    if !do_mouse return;

    for 0..1000 {
        status := port_read(Ps2_Port.STATUS);
        if status & 0x20 break;
    }

    new_byte := port_read(Ps2_Port.DATA);

    port_write(0x61, port_read(0x61));
    mouse.bytes[mouse.step] = new_byte;

    if !(mouse.bytes[0] & 0x8) {
        mouse.step = 0;
        return;
    }

    mouse.step += 1;
    if mouse.step != 3 return;

    mouse.step = 0;

    button_1 := (mouse.bytes[0] & 1) > 0;
    button_2 := (mouse.bytes[0] & 2) > 0;

    if button_1 != mouse.button_1 {
        write_event_buffer(*mouse.buffer, cast(Mouse_Event_Type) !button_1 + .BUTTON_1_PRESSED);
        mouse.button_1 = button_1;
    }

    if button_2 != mouse.button_2 {
        write_event_buffer(*mouse.buffer, cast(Mouse_Event_Type) !button_2 + .BUTTON_2_PRESSED);
        mouse.button_2 = button_2;
    }

    x_sign := (mouse.bytes[0] & 0x10) > 0;
    y_sign := (mouse.bytes[0] & 0x20) > 0;

    delta_x := cast(int) mouse.bytes[1];
    delta_y := cast(int) mouse.bytes[2];

    if x_sign delta_x |= 0xffffffff_ffffff00;
    if y_sign delta_y |= 0xffffffff_ffffff00;

    mouse.position_x += delta_x;
    mouse.position_y -= delta_y;

    if mouse.position_x >= VESA_WIDTH  mouse.position_x = VESA_WIDTH - 1;
    if mouse.position_y >= VESA_HEIGHT mouse.position_y = VESA_HEIGHT - 1;
    if mouse.position_x < 0 mouse.position_x = 0;
    if mouse.position_y < 0 mouse.position_y = 0;
}

do_mouse :: true;

enable_ps2 :: () {
    pic_enable_irq(.PS2_KEYBOARD);

    layout := read_file(KEYBOARD_LAYOUT);

    mouse.position_x = 0;
    mouse.position_y = 0;

    count: int;
    for layout if it == #char "\n" {
        count = it_index;
        break;
    }

    #if !do_mouse return;

    mouse_wait(true);
    port_write(Ps2_Port.COMMAND, Ps2_Controller_Cmd.ENABLE_SECOND_PS2_PORT);

    mouse_wait(true);
    port_write(Ps2_Port.COMMAND, Ps2_Controller_Cmd.READ_CONFIG_BYTE);

    mouse_wait(false);
    status := port_read(Ps2_Port.DATA);
    status |= 0x2;
    // status &= ~cast(u8) 0x20;
    // print_hex(status);

    mouse_wait(true);
    port_write(Ps2_Port.COMMAND, Ps2_Controller_Cmd.WRITE_CONFIG_BYTE);

    mouse_wait(true);
    port_write(Ps2_Port.DATA, status);

    mouse_wait(true);
    port_write(Ps2_Port.COMMAND, Ps2_Controller_Cmd.WRITE_MOUSE_COMMAND);

    mouse_wait(true);
    port_write(Ps2_Port.DATA, Ps2_Mouse_Cmd.SET_DEFAULTS);

    mouse_wait(false);
    // assert(port_read(Ps2_Port.DATA) == PS2_ACK);

    pic_enable_irq(.PS2_MOUSE);

    mouse_wait(true);
    port_write(Ps2_Port.COMMAND, Ps2_Controller_Cmd.WRITE_MOUSE_COMMAND);

    mouse_wait(true);
    port_write(Ps2_Port.DATA, Ps2_Mouse_Cmd.ENABLE_DATA_REPORTING);

    mouse_wait(false);
    // assert(port_read(Ps2_Port.DATA) == PS2_ACK);

    input_key_buffer.read_index = input_key_buffer.write_index;
}

Ps2_Scan_Code :: enum u16 {
    NONE;
    ESC;
    NUM1;
    NUM2;
    NUM3;
    NUM4;
    NUM5;
    NUM6;
    NUM7;
    NUM8;
    NUM9;
    NUM0;
    DASH;
    EQUAL;
    BACKSPACE;
    TAB;
    Q;
    W;
    E;
    R;
    T;
    Y;
    U;
    I;
    O;
    P;
    OPEN_BRACKET;
    CLOSED_BRACKET;
    ENTER;
    CTRL;
    A;
    S;
    D;
    F;
    G;
    H;
    J;
    K;
    L;
    SEMICOLON;
    APOSTROPHE;
    BACKTICK;
    LSHIFT;
    BACKSLASH;
    Z;
    X;
    C;
    V;
    B;
    N;
    M;
    COMMA;
    PERIOD;
    FORWARDSLASH;
    RSHIFT;
    ASTERISK;
    ALT;
    SPACE;
    CAPSLOCK;
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
    NUMLOCK;
    SCROLLLOCK;
    KEYPAD7;
    KEYPAD8;
    KEYPAD9;
    KEYPAD_MINUS;
    KEYPAD4;
    KEYPAD5;
    KEYPAD6;
    KEYPAD_PLUS;
    KEYPAD1;
    KEYPAD2;
    KEYPAD3;
    KEYPAD0;
    KEYPAD_PERIOD;

    ISO_BACKSLASH :: 0x56;
    F11 :: 0x57;
    F12;

    E0_PREFIX_OFFSET :: 0xe0;
    MM_PREV_TRACK   :: E0_PREFIX_OFFSET + 0x10;
    MM_NEXT_TRACK   :: E0_PREFIX_OFFSET + 0x19;
    KEYPAD_ENTER    :: E0_PREFIX_OFFSET + 0x1c;
    RCONTROL;
    MM_MUTE         :: E0_PREFIX_OFFSET + 0x20;
    MM_CALC;
    MM_PLAY;
    MM_STOP;
    MM_VOL_DOWN     :: E0_PREFIX_OFFSET + 0x2e;
    MM_VOL_UP       :: E0_PREFIX_OFFSET + 0x30;
    MM_WWW_HOME     :: E0_PREFIX_OFFSET + 0x32;
    MM_FORWARDSLASH :: E0_PREFIX_OFFSET + 0x35;
    MM_ALTGR        :: E0_PREFIX_OFFSET + 0x38;
    HOME            :: E0_PREFIX_OFFSET + 0x47;
    CURSOR_UP;
    PAGE_UP;
    CURSOR_LEFT     :: E0_PREFIX_OFFSET + 0x4b;
    CURSOR_RIGHT    :: E0_PREFIX_OFFSET + 0x4d;
    CURSOR_END      :: E0_PREFIX_OFFSET + 0x4f;
    CURSOR_DOWN;
    PAGE_DOWN;
    INSERT;
    DELETE;
    FLAG            :: E0_PREFIX_OFFSET + 0x5b;
    RIGHT_FLAG      :: E0_PREFIX_OFFSET + 0x5c;
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

GAMEPAD_BUTTON_COUNT :: 32;

Key_Code :: enum u32 {
    UNKNOWN :: 0;

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

ps2_to_ascii :: "\0\01234567890-=\0\tQWERTYUIOP[]\0\0ASDFGHJKL;'`\0#ZXCVBNM,./\0\0\0 ";
//                \01234567890-=  qwertyuiop[]  asdfghjkl;'` #zxcvbnm,./ *   function k  789-456+1230.  \ey
//                \0!"£$%^&*()_+  QWERTYUIOP{}  ASDFGHJKL:@| ~ZXCVBNM<>? *   FUNCTION K  789-456+1230.  |EY

get_key_code :: (key: Ps2_Scan_Code) -> Key_Code #no_context {
    // if current_task && current_task.the_context push_context current_task.the_context { printf("%\n", key); }
    if xx key < ps2_to_ascii.count {
        char := ps2_to_ascii[key];

        if char != 0  return xx char;
    }

    using Key_Code;

    if key == .HOME         return HOME;
    if key == .CURSOR_END   return END;
    if key == .SCROLLLOCK   return SCROLL_LOCK;
    if key == .PAGE_UP      return PAGE_UP;
    if key == .PAGE_DOWN    return PAGE_DOWN;
    if key == .CURSOR_LEFT  return ARROW_LEFT;
    if key == .CURSOR_RIGHT return ARROW_RIGHT;
    if key == .CURSOR_UP    return ARROW_UP;
    if key == .CURSOR_DOWN  return ARROW_DOWN;
    if key == .ALT          return ALT;
    if key == .LSHIFT       return SHIFT;
    if key == .CTRL         return CTRL;
    if key == .MM_ALTGR     return RIGHT_ALT;
    if key == .RSHIFT       return RIGHT_SHIFT;
    if key == .RCONTROL     return RIGHT_CTRL;
    if key == .BACKSPACE    return BACKSPACE;
    if key == .DELETE       return DELETE;
    if key == .INSERT       return INSERT;
    if key == .ESC          return ESCAPE;
    if key == .ENTER        return ENTER;
    if key == .TAB          return TAB;

    if (key >= .F1) && (key <= .F10) {
        delta := key - .F1;
        return xx(F1 + xx delta);
    }

    if key == .ISO_BACKSLASH return #char "\\";
    if key == .F11 return F11;
    if key == .F12 return F12;

    /*
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
    */

    return UNKNOWN;
}
