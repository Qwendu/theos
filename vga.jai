
#if USE_VGA {
    vga_columns :: 80;
    vga_rows    :: 25;

    indent: int;
    margin: int = 2;
    ceiling: int = 5;

    text_cursor: int = 2;
    vga_screen :: cast(*u8) (0xb8000 + KERNEL_BASE);

    get_attribute :: () -> u8 #c_call {
        if !USE_VGA return 0;
        return cast(u8) theme.primary.vga | (theme.background.vga << 4);
    }

    vertical_divide :: () {
        if !USE_VGA return;
        furthest: int;

        for y: 0..vga_rows - 1 {
            for x: 0..vga_columns - 1 {
                cell := y * vga_columns + x;
                if vga_screen[cell * 2] != 0 && vga_screen[cell * 2] != #char " " {
                    if x > furthest furthest = x;
                }
            }
        }

        for 0..vga_rows-1 {
            cell := it * vga_columns + furthest + 3;
            vga_screen[cell * 2] = 0xba;
        }

        indent = furthest + 4;
        text_cursor = margin;
    }

    print :: (text: string, foreground: Color = .{ vga = 255}) #c_call {
        if !USE_VGA return;
        fg := ifx foreground.vga == 255 then theme.primary.vga else xx foreground.vga;

        indent = 0;
        margin = 0;

        for cast([] u8) text {
            if it == 10 {
                distance := text_cursor % vga_columns;
                text_cursor += vga_columns - distance;
                text_cursor += margin;
                continue;
            }

            if it == 13 continue;

            i := text_cursor + indent;
            if (i+1) % vga_columns == 0 {
                text_cursor += indent + margin + margin;
            }

            vga_screen[i * 2]     = it;

            text_cursor += 1;
        }
    }

    print :: (number: int, color: Color = .{ vga = 255}) #c_call {
        if !USE_VGA return;
        c := color;
        if c.vga == 255 c.vga = theme.foreground.vga;

        negative: bool;
        buffer: [30] u8 = ---;

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
                print(result, color);
                return;
            }
        }
    }

    print_hex :: (number: $T, color: Color = .{ vga = 1}, decorate := true) #c_call {
        if !USE_VGA return;
        #assert type_info(T).type == .INTEGER;
        size := #run type_info(T).runtime_size;

        if decorate print("0x");

        table := "0123456789abcdef";
        for 0..size * 2 - 1 {
            index := number >> (it * 4);
            index &= 0xf;

            cur := (text_cursor + indent + size * 2 - it - 1) * 2;
            vga_screen[cur] = table[index];
            vga_screen[cur + 1] = 0x0f;
        }
        text_cursor += size * 2;
    }

    debug :: (variable: string) #expand {
        print(variable);
        print(": ");

        value :=
        #insert variable
        ;
        print_hex(cast(u64) value); //`
        // else print(number);
        print("\n");
    }

    clear_screen :: () {
        for 0..vga_columns * vga_rows - 1 {
            vga_screen[it * 2]     = 0;
            vga_screen[it * 2 + 1] = get_attribute();
        }
        text_cursor = indent;
    }

    theme: Theme;
    Theme :: struct {
        background : Color = .{ vga = .BLACK };
        foreground : Color = .{ vga = .WHITE };
        primary    : Color = .{ vga = .CYAN };
        secondary  : Color = .{ vga = .CYAN };
        highlight  : Color = .{ vga = .LIGHT_CYAN };
        accent     : Color = .{ vga = .RED };
        shadow: float;

    #place background;
        as_array: [6] Color;
    }

    Vga_Register :: enum u16 {
        ATTRIBUTE_ADDRESS :: 0x3c0;
        DATA_READ         :: 0x3c1;
        DAC_PALETTE_MASK  :: 0x3c6;
        DAC_STATE         :: 0x3c7;
        DAC_ADDRESS_READ  :: 0x3c7;
        DAC_ADDRESS_WRITE :: 0x3c8;
        DAC_DATA          :: 0x3c9;
        CRT_CONTROL_INDEX :: 0x3d4;
        CRT_CONTROL_DATA  :: 0x3d5;
        INPUT_STATUS      :: 0x3da;
    }

    vga_hide_cursor :: () {
        if !USE_VGA return;
        using Vga_Register;

        port_write(xx CRT_CONTROL_INDEX, 0x0a);
        port_write(xx CRT_CONTROL_DATA,  0x20);
    }

    vga_set_palette_entry :: (index: u8, red: u8, green: u8, blue: u8) {
        if !USE_VGA return;
        using Vga_Register;

        port_write(xx DAC_PALETTE_MASK, 0xff);
        port_write(xx DAC_ADDRESS_WRITE, index);
        port_write(xx DAC_DATA, red);
        port_write(xx DAC_DATA, green);
        port_write(xx DAC_DATA, blue);
    }

    vga_attribute :: (register_name: u8, bit: u8, set: bool = true) {
        if !USE_VGA return;
        using Vga_Register;

        PAS : u8 :    1 << 5;
        mask: u8 = xx 1 << bit;

        port_read(xx INPUT_STATUS);
        address := port_read(xx ATTRIBUTE_ADDRESS);
        port_write(xx ATTRIBUTE_ADDRESS, register_name | PAS);

        data := port_read(xx DATA_READ);
        if set data |=  mask;
        else   data &= ~mask;

        port_write(xx ATTRIBUTE_ADDRESS, data);
        port_write(xx ATTRIBUTE_ADDRESS, address);
    }

    Color :: struct {
        using vga: enum {
            BLACK         :: 0x00;
            BLUE          :: 0x01;
            GREEN         :: 0x02;
            CYAN          :: 0x03;
            RED           :: 0x04;
            MAGENTA       :: 0x05;
            BROWN         :: 0x06;
            WHITE         :: 0x07;
            GRAY          :: 0x08;
            LIGHT_BLUE    :: 0x09;
            LIGHT_GREEN   :: 0x0a;
            LIGHT_CYAN    :: 0x0b;
            LIGHT_RED     :: 0x0c;
            LIGHT_MAGENTA :: 0x0d;
            YELLOW        :: 0x0e;
            BRIGHT_WHITE  :: 0x0f;
        }
        as_u32: u32;
        r, g, b, a: u8;
    }
}
