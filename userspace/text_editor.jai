
#import "Formosa";
#import "Formosa_Utilities";
#import "Basic";

main :: (filename: string) {
    file: string;
    if filename.count {
        file = cast(string) read_file(filename);
    }

    if !file.count {
        data := input();
        if data.value_pointer {
            context.print_style.default_format_struct.use_long_form_if_more_than_this_many_members = 0;
            context.print_style.default_format_struct.use_newlines_if_long_form = true;
            file = tprint("%\n", data);
        }
    }

    params: System_Params;
    get_system_parameters(*params);

    width = params.x_resolution - 400;
    height = params.y_resolution - 400;
    window_handle := create_window(width, height);
    window = get_window_buffer(window_handle);
    defer close_window(window_handle);

    memset(window, 0x20, width * height * 4);
    memset(window, 0xff, width * 4);
    memset(window + width * (height - 1), 0xff, width * 4);
    for 1..height - 2 {
        window[it * width] = 0xffffff;
        window[it * width + width - 1] = 0xffffff;
    }

    font_file := read_file("system/font.pgm");
    font = parse_pnm(font_file);
    buffer = map_memory(0x8000);
    old_buffer = map_memory(0x8000);

    char_count := 95;

    char_width  = font.width / char_count;
    char_height = font.height;

    memcpy(buffer, file.data, file.count);
    used = file.count;
    spacing = 3;

    render_text();
    repaint();

    repaint_needed: bool;
    all: bool;
    shifted: bool;
    control: bool;

    while true {
        message := get_message();

        if message.kind == .KEYBOARD {
            code := message.keyboard.key;

            if message.keyboard.type == .RELEASED {
                if code == .SHIFT || code == .RIGHT_SHIFT {
                    shifted = false;
                }

                if code == .CTRL {
                    control = false;
                }
            }

            else if code == .ESCAPE {
                return;
            }

            else if code == .SHIFT || code == .RIGHT_SHIFT {
                shifted = true;
            }

            else if code == .CTRL {
                control = true;
            }

            else if code == .ARROW_LEFT {
                if cursor_pos > 0 cursor_pos -= 1;
                repaint_needed = true;
            }

            else if code == .ARROW_RIGHT {
                if cursor_pos < used cursor_pos += 1;
                repaint_needed = true;
            }

            else if code == .ENTER {
                for < used .. cursor_pos {
                    buffer[it] = buffer[it - 1];
                }

                buffer[cursor_pos] = #char "\n";
                used += 1;
                cursor_pos += 1;
                repaint_needed = true;
                all = true;
            }

            else if code == .DELETE {
                if cursor_pos == used continue;
                for cursor_pos..used - 1 {
                    buffer[it] = buffer[it + 1];
                }

                if used > 0 used -= 1;
                repaint_needed = true;
                all = true;
            }

            else if code == .BACKSPACE {
                if cursor_pos == 0 continue;
                for cursor_pos - 1..used - 1 {
                    buffer[it] = buffer[it + 1];
                }

                if used > 0 used -= 1;
                if cursor_pos > 0 cursor_pos -= 1;
                repaint_needed = true;
                all = true;
            }

            else if !control {
                char := key_code_to_ascii(code, shifted);
                if char == 0 continue;

                for < used..cursor_pos {
                    buffer[it] = buffer[it - 1];
                }

                buffer[cursor_pos] = char;
                used += 1;
                cursor_pos += 1;
                repaint_needed = true;
            } else {
                if code == #char "S" && filename.count {
                    contents: [] u8;
                    contents.data = buffer;
                    contents.count = used;
                    create_file(filename);
                    write_file(filename, contents);
                    write_string("Saving file!\n");
                }
            }
        }

        if message.kind == .NONE && repaint_needed {
            render_text(all);
            repaint();
            repaint_needed = false;
            all = false;

            memcpy(old_buffer, buffer, used);
            old_cursor_pos = cursor_pos;
        }
    }

    close_window(window_handle);
    repaint();
}

window: *u32;

width: int;
height: int;
font: Pnm;

char_width: int;
char_height: int;
spacing: int;

buffer: *u8;
old_buffer: *u8;
used: int;
cursor_pos: int;
old_cursor_pos: int;

render_text :: (all: bool = false) {
    cursor_y: int;
    cursor_x: int;

    if all {
        memset(window, 0x20, width * height * 4);
        memset(window, 0xff, width * 4);
        memset(window + width * (height - 1), 0xff, width * 4);
        for 1..height - 2 {
            window[it * width] = 0xffffff;
            window[it * width + width - 1] = 0xffffff;
        }
    }

    for 0..used - 1 {
        char := buffer[it];

        if char == 0 write_string("Null character, fix it\n");
        if char == #char "\r" continue;

        if char == #char "\n" {
            line := cursor_y * (char_height + spacing) * width + 10 * width;
            column := cursor_x * char_width + 10;

            cursor_y += 1;
            cursor_x = 0;

            for y: 0..char_height - 1 for x: 0..char_width - 1 {
                pixel := line + column + x + y * width;
                window[pixel] = xx ifx cursor_pos == it 0xffffffff else 0xff202020;
            }

            if (cursor_y + 1) * (char_height + spacing) > height {
                break;
            }
            continue;
        }

        if (cursor_x + 1) * char_width >= width {
            cursor_x += 1;
            continue;
        }
        source_top_left := char_width * (char - 0x20);

        if all || buffer[it] != old_buffer[it] || it == cursor_pos || it == old_cursor_pos {

            line := cursor_y * (char_height + spacing) * width + 10 * width;
            column := cursor_x * char_width + 10;

            for y: 0..char_height - 1 for x: 0..char_width - 1 {
                pixel := line + column + x + y * width;
                index := source_top_left + x + y * font.width;

                if cursor_pos == it {
                    color: Color = .{ as_u32 = 0x202020 };
                    color.a = cast(u8) font.data[index];
                    window[pixel] = blend(.{ as_u32 = 0xffffffff }, color).as_u32;
                } else {
                    color: Color = .{ as_u32 = 0xffffff };
                    color.a = cast(u8) font.data[index];
                    window[pixel] = blend(.{ as_u32 = 0xff202020 }, color).as_u32;
                }
            }
        }

        cursor_x += 1;
        // if (cursor_x + 2) * char_width >= width {
        //     cursor_x = 0;
        //     cursor_y += 1;
        //     if (cursor_y + 1) * (char_height + spacing) >= height {
        //         break;
        //     }
        // }
    }

    if cursor_pos == used || old_cursor_pos == used {
        line := cursor_y * (char_height + spacing) * width + 10 * width;
        column := cursor_x * char_width + 10;

        for y: 0..char_height - 1 for x: 0..char_width - 1 {
            pixel := line + column + x + y * width;
            window[pixel] = xx ifx cursor_pos == used 0xffffffff else 0xff202020;
        }
    }
}

blend :: (target: Color, source: Color) -> Color #expand {
    t := cast(float) source.a / 255;
    result: Color;
    result.r = cast(u8) (cast(float) target.r * (1 - t) + cast(float) source.r * t);
    result.g = cast(u8) (cast(float) target.g * (1 - t) + cast(float) source.g * t);
    result.b = cast(u8) (cast(float) target.b * (1 - t) + cast(float) source.b * t);

    return result;
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
