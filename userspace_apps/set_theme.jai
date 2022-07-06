
#import "Theos";
#import "String";

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

    if file.count < size_of(Theme) {
        write_string("Can't set theme: this file is too small to contain a theme: \"");
        write_string(file_name);
        write_string("\"\n");
        return;
    }

    theme := << cast(*Theme) file.data;
    set_theme(theme);
}
