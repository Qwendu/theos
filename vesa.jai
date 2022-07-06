
clear_screen :: () {
    clear_text_viewer(*shell.text);
}

theme: Theme;
Theme :: struct {
    background:  Color = .{ as_u32 = 0xff603038 };
    foreground:  Color = .{ as_u32 = 0xfff8f8f8 };
    primary:     Color = .{ as_u32 = 0xfaebbcbc };
    secondary:   Color = .{ as_u32 = 0xffe4a424 };
    highlight:   Color = .{ as_u32 = 0xffebbcbc };
    accent:      Color = .{ as_u32 = 0xff81c44b };

    shadow: float = 1.0;

#place background;
    as_array: [6] Color = ---;
}

Color :: union {
    as_u32: u32;
    struct {
        b: u8;
        g: u8;
        r: u8;
        a: u8;
    }
}
#assert(size_of(Color) == size_of(u32));

print :: (text: string) {
    print(text, theme.foreground);
}

print :: (text: string, color: Color) {
    if !graphics.initialized return;
    write_to_text_viewer(*shell.text, text, color);
}

print :: (number: int) {
    print(number, theme.foreground);
}

print :: (number: int, color: Color) {
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

print_hex :: (number: $T, decorate := true) {
    print_hex(number, theme.foreground, decorate);
}

print_hex :: (number: $T, color: Color, decorate := true) {
#assert type_info(T).type == .INTEGER;
    size :: size_of(T);

    if decorate print("0x", color);

    result: [size*2] u8;

    table := "0123456789abcdef";
    for 0..size * 2 {
        index := number >> (it * 4);
        index &= 0xf;

        result[size*2 - it - 1] = table[index];
    }
    print(cast(string) result, color);
}
