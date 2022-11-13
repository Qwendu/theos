
// scan_table         :: "\0#1234567890-=\0\tqwertyuiop[]\0\0asdfghjkl;'`\0\\zxcvbnm,./\0*\0 ";
// scan_table_shifted :: "\0#!@#$%^&*()_+\0\0QWERTYUIOP{}\0\0ASDFGHJKL:\"~\0|ZXCVBNM<>?\0*\0 ";

Event_Buffer :: struct (T: Type) {
    size :: 32;
    buffer: [size] T;
    read_index: int;
    write_index: int;
}

read_event_buffer :: (event_buffer: *Event_Buffer($T)) -> T {
    using event_buffer;

    default: T;
    if read_index == write_index return default;

    event := buffer[read_index];

    read_index += 1;
    read_index %= size;

    return event;
}

write_event_buffer :: (event_buffer: *Event_Buffer($T), event: T) #no_context {
    using event_buffer;

    buffer[write_index] = event;

    write_index += 1;
    write_index %= size;
}

input_key_buffer: Event_Buffer(Keyboard_Scan_Code);
sitting_on_0xe0: bool;


#program_export
ps2_interrupt :: () #c_call {
    defer pic_end_of_interrupt(.PS2_KEYBOARD);

    key: u16 = port_read(Ps2_Port.DATA);

    if key == 0xe0 {
        sitting_on_0xe0 = true;
        return;
    }

    if sitting_on_0xe0 {
        key += 0xe0;
        sitting_on_0xe0 = false;
    }
    write_event_buffer(*input_key_buffer, cast(Keyboard_Scan_Code) key);
}

mouse_wait :: ($ is_signal: bool) #no_context {
    tick := 10000;

    for 1..tick {
        #if is_signal if !(port_read(Ps2_Port.STATUS) & 2) return;
        else          if   port_read(Ps2_Port.STATUS) & 1  return;
    }
}

Mouse_Event :: enum {
    NONE;
    BUTTON_1_PRESSED;
    BUTTON_1_RELEASED;
    BUTTON_2_PRESSED;
    BUTTON_2_RELEASED;
}

mouse: struct {
    step: int;
    bytes: [4] u8;
    button_1: bool;
    button_2: bool;

    position_x: int;
    position_y: int;

    buffer: Event_Buffer(Mouse_Event);
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
        write_event_buffer(*mouse.buffer, cast(Mouse_Event) !button_1 + .BUTTON_1_PRESSED);
        mouse.button_1 = button_1;
    }

    if button_2 != mouse.button_2 {
        write_event_buffer(*mouse.buffer, cast(Mouse_Event) !button_2 + .BUTTON_2_PRESSED);
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

    mouse.position_x %= VESA_WIDTH;
    mouse.position_y %= VESA_HEIGHT;
    if mouse.position_x < 0 mouse.position_x += VESA_WIDTH;
    if mouse.position_y < 0 mouse.position_y += VESA_HEIGHT;
}

do_mouse :: true;

enable_ps2 :: () {
    pic_enable_irq(.PS2_KEYBOARD);

    layout := read_file(KEYBOARD_LAYOUT);

    mouse.position_x = 800;
    mouse.position_y = 800;

    count: int;
    for layout if it == #char "\n" {
        count = it_index;
        break;
    }

    scan_table.count = count;
    scan_table.data = layout.data;

    scan_table_shifted.count = count;
    scan_table_shifted.data = layout.data + count + 1;

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
    assert(port_read(Ps2_Port.DATA) == PS2_ACK);

    pic_enable_irq(.PS2_MOUSE);

    mouse_wait(true);
    port_write(Ps2_Port.COMMAND, Ps2_Controller_Cmd.WRITE_MOUSE_COMMAND);

    mouse_wait(true);
    port_write(Ps2_Port.DATA, Ps2_Mouse_Cmd.ENABLE_DATA_REPORTING);

    mouse_wait(false);
    assert(port_read(Ps2_Port.DATA) == PS2_ACK);

    input_key_buffer.read_index = input_key_buffer.write_index;
}

scan_table: string;
scan_table_shifted: string;

// Why are we using scan code set 1? Is that just what some things happen to default to?
Keyboard_Scan_Code :: enum u16 {
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
