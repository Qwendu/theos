
#import "Formosa";
#import "String";
#import "Basic";

main :: (file_name: string) {
    file := read_file(join("themes/", file_name));

    if !file.count {
        file = read_file(file_name);
    }

    if !file.count {
        write_string("Can't set theme: this file was not found or is empty: \"");
        write_string(file_name);
        write_string("\"\n");
        return;
    }

    new_theme: Theme;
    number: string;
    number.count = 8;
    number.data = file.data;

    for *new_theme.array {
        << it = cast(u32) string_to_int(number, base = 16);
        // number.count += 7;
        number.data += 9;
    }

    number.count = 4;
    offset := cast(int) number.data - cast(int) file.data;
    if file.count >= (offset + number.count) {
        if number == "true" {
            new_theme.shadow = 1.0;
        }
    }

    set_theme(new_theme);
}
