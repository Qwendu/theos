
#import "Formosa";
#import "Formosa_Utilities";

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

    window_handle := create_window(image.width, image.height);
    window: *u32 = get_window_buffer(window_handle);
    defer close_window(window_handle);

    blit(image, window);

    repaint();
    while true {
        message := wait_for_message();
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
