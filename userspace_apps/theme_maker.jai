
#import "Theos";

main :: () {
    new_theme := get_theme();
    array := cast(*u32) *new_theme;

    ti := type_info(Theme);

    for 0..5 {
        write_string("Choose color for ");
        write_string(ti.members[it].name);
        write_string("\n");

        new_color := read_string("Type a hex color");
        while !is_valid_hex_color(new_color) {
            write_string("This color is not valid. It should be 6 or 8 lowercase hex digits.\n");
            new_color = read_string("Type a hex color");
        }

        array[it] = parse_hex(new_color);
        set_theme(new_theme);
    }

    shadows := read_string("Enable text shadow? (y/n)");
    if shadows.count && shadows[0] == #char "y" {
        new_theme.shadow = 1;
    } else {
        new_theme.shadow = 0;
    }
    set_theme(new_theme);

    save := read_string("Would you like to save this theme? (y/n)");
    if save.count && save[0] == #char "y" {
        name := read_string("Enter a name for the new theme");
        create_file(name);

        content: [] u8;
        content.count = size_of(Theme);
        content.data = xx *new_theme;
        write_file(name, content);
    }
}

is_valid_hex_color :: (text: string) -> bool {
    if text.count != 6 && text.count != 8 return false;

    for cast([] u8) text {
        if     (it < #char "0" || it > #char "9")
            && (it < #char "a" || it > #char "f") return false;
    }

    return true;
}

parse_hex :: (text: string) -> u32 {
    result: u32;

    for cast([] u8) text {
        result *= 0x10;
        if (it >= #char "0" && it <= #char "9") result += it - #char "0";
        if (it >= #char "a" && it <= #char "f") result += it - #char "a" + 0xa;
    }

    return result;
}
