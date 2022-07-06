
#import "Theos";

main :: (file_name: string) {
    image_file := read_file(file_name);
    if !image_file.count {
        write_string("File not found: ");
        write_string(file_name);
        write_string(".\n");
        return;
    }

    extension: string;
    if file_name.count > 4 {
        extension.count = 4;
        extension.data = file_name.data + file_name.count - 4;
    }

    if extension != ".ppm" {
        response := read_string("This may not be a compatible image file (ppm). Read anyway? (y/n)");
        if response != "y" return;
    }

    image := parse_pnm(image_file);

    window: *u32 = create_window(image.width, image.height);
    defer close_window(window);

    blit(image, window);

    repaint();
    while true {
        message := get_message();
        if message.kind == .KEYBOARD {
            if message.keyboard_scan_code == .ESC {
                break;
            }
        }
    }
}

blit :: (image: Pnm, surface: *u32) {
    // assert(image.type == .PIXMAP);
    size := image.width * image.height;

    cursor: int;
    for y: 0..image.height-1 for x: 0..image.width-1 {
        r := cast(u32) image.data[cursor];
        g := cast(u32) image.data[cursor + 1];
        b := cast(u32) image.data[cursor + 2];
        surface[x + y * image.width] = (r << 16) | (g << 8) | b;
        cursor += 3;
    }
}

Pnm :: struct {
    width: int;
    height: int;

    type: enum {
        UNINITIALIZED :: 0;
        ASCII_BITMAP;
        ASCII_GRAYMAP;
        ASCII_PIXMAP;
        BITMAP;
        GRAYMAP;
        PIXMAP;
    }

    data: *u8;
}

parse_pnm :: (file: [] u8) -> Pnm {
    buffer := file.data;
    // assert(buffer[0] == #char "P");

    pnm: Pnm;
    pnm.type = xx (buffer[1] - #char "0");
    // assert(pnm.type == .GRAYMAP || pnm.type == .PIXMAP);

    is_whitespace :: (char: u8) -> bool {
        return char == 0x20
            || char == 0x09
            || char == 0x0a
            || char == 0x0b
            || char == 0x0c
            || char == 0x0d
            || char == #char "#";
    }

    ConsumeWhitespaceAndComments :: () #expand {
        while is_whitespace(buffer[`cursor]) {
            if buffer[`cursor] == #char "#" {
                while buffer[`cursor] != 0xa `cursor += 1;
            }
            cursor += 1;
        }
    }

    ParseInt :: () -> int #expand {
        digit := buffer[`cursor]; //`
        result: int;

        while !is_whitespace(digit) {
            // assert(digit >= #char "0" && digit <= #char "9");
            result *= 10;
            result += digit - #char "0";
            `cursor += 1;
            digit = buffer[`cursor];
        }
        return result;
    }

    cursor := 2;
    ConsumeWhitespaceAndComments();
    pnm.width = ParseInt();

    ConsumeWhitespaceAndComments();
    pnm.height = ParseInt();

    ConsumeWhitespaceAndComments();
    max_value := ParseInt();
    // assert(max_value == 255);

    ConsumeWhitespaceAndComments();
    pnm.data = buffer + cursor;

    return pnm;
}
