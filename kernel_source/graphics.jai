
Graphics :: struct {
    using screen: Surface;
    vesa_framebuffer: *u32;

    draw_list: *Draw_List_Entry;
    initialized: bool;
}

graphics: Graphics;

Rect :: struct {
    x, y, width, height: int;
}

overlap :: (a: Rect, b: Rect) -> bool {
    x_overlap := (a.x < b.x && a.width > (a.x - b.x))
              || (b.x < a.x && b.width > (b.x - a.x));

    y_overlap := (a.y < b.y && a.height > (a.y - b.y))
              || (b.y < a.y && b.height > (b.y - a.y));
    return x_overlap && y_overlap;
}

union_ :: (a: Rect, b: Rect) -> Rect {
    result: Rect = a;
    if !a.width || !a.height return b;
    if !b.width || !b.height return a;

    if b.x < a.x {
        result.x = b.x;
        result.width += a.x - b.x;
    }

    if b.y < a.y {
        result.y = b.y;
        result.height += a.y - b.y;
    }

    if result.width  + result.x < b.width  + b.x  result.width  = b.width  + b.x - result.x;
    if result.height + result.y < b.height + b.y  result.height = b.height + b.y - result.y;

    return result;
}

intersection :: (a: Rect, b: Rect) -> Rect {
    if !overlap(a, b) return .{};

    result: Rect;
    result.x = max(a.x, b.x);
    result.y = max(a.y, b.y);
    x2 := min(a.x + a.width,  b.x + b.width);
    y2 := min(a.y + a.height, b.y + b.height);

    result.width  = x2 - result.x;
    result.height = y2 - result.y;
    return result;
}

Surface :: struct {
    buffer: *u32;
    width: int;
    height: int;
    stride: int;
}

create_surface :: (width: int, height: int) -> Surface {
    surface: Surface;
    surface.width = width;
    surface.stride = width;
    surface.height = height;
    surface.buffer = map_memory(width * height * size_of(u32));
    return surface;
}

destroy_surface :: (surface: *Surface) {
    unmap_memory(surface.width * surface.height * size_of(u32), xx surface.buffer);
    surface.buffer = null;
}

Draw_List_Entry :: struct {
    type: enum {
        UNINITIALIZED;
        TEXT_VIEWER;
        SOLID_COLOR;
        BLITTER;
    }

    using target_rect: Rect;

    user_id: string;
    dirty: bool;
    transparency: bool;

    _dirty_subregion: Rect;

    next: *Draw_List_Entry;
    prev: *Draw_List_Entry;
}

add_screen_draw_list_entry :: (entry: *Draw_List_Entry, x: int, y: int, user_id := "noname") {
    entry.x = x;
    entry.y = y;
    entry.dirty = true;
    entry.user_id = user_id;

    if graphics.draw_list {
        last_entry := graphics.draw_list;

        while last_entry.next {
            last_entry = last_entry.next;
        }

        entry.prev = last_entry;
        last_entry.next = entry;
    } else {
        graphics.draw_list = entry;
    }
}

execute_draw_list :: (list: *Draw_List_Entry, surface: Surface, debug_surface_extents := false) {
    entry := list;
    if !entry return;

//    {
//        {
//            if shell.text.draw.dirty  shell.command_text.draw.dirty = true;
//        }
//    }
//
//    dirty: Rect;
//    while true {
//        if entry.dirty {
//            dirty = union_(entry.target_rect, dirty);
//        }
//
//        entry = .{};
//        if !entry.next break;
//        entry = entry.next;
//    }
//
//    while entry {
//        if !entry.transparency && (dirty.width && dirty.height) {
//            this := entry.target_rect;
//
//            if (this.x <= dirty.x && this.width >= (dirty.width + (dirty.x - this.x))) {
//                if (this.y <= dirty.y) && (this.height >= (dirty.y - this.y)) {
//                    depth := this.height - (dirty.y - this.y);
//                    entry.x = dirty.x;
//                    entry.y = dirty.y;
//                    entry.width = dirty.width;
//                    entry.height = depth;
//
//                    dirty.y += depth;
//                    dirty.height -= depth;
//                    entry.dirty = false;
//                    if dirty.height < 0 dirty = .{};
//                } else if this.y <= (dirty.y + dirty.height) && (this.height >= (dirty.y + dirty.height) - this.y) {
//                    depth := dirty.y + dirty.height - this.y;
//                    entry.x = dirty.x;
//                    entry.y = this.y;
//                    entry.width = dirty.width;
//                    entry.height = depth;
//
//                    dirty.height -= depth;
//                    entry.dirty = false;
//                    if dirty.height < 0 dirty = .{};
//                }
//            } else if entry.dirty {
//                entry = entry.target_rect;
//            }
//        }
//        entry = entry.prev;
//    }

    entry = list;
    while entry {
        // if !entry.dirty && !(entry.width && entry.height) {
        //     entry = entry.next;
        //     continue;
        // }
        if entry.type == {
          case .SOLID_COLOR;
            solid := cast(*Solid_Color) entry;
            render_solid_color(solid, surface);

          case .TEXT_VIEWER;
            text_viewer := cast(*Text_Viewer) entry;
            render_text_viewer(text_viewer, surface);

          case .BLITTER;
            blit := cast(*Blitter) entry;
            render_blitter(blit, surface /*, area */);
        }

        if debug_surface_extents {
            size := surface.height * surface.stride;
            for 0..entry.width {
                index := it + entry.y * surface.stride + entry.x;
                if index < size surface.buffer[index] = theme.foreground.as_u32;
                index += (entry.height - 1) * surface.stride;
                if index < size  surface.buffer[index] = theme.foreground.as_u32;
            }

            for 0..entry.height {
                index := (it + entry.y) * surface.stride + entry.x;
                if index < size surface.buffer[index] = theme.foreground.as_u32;
                index += entry.width-1;
                if index < size surface.buffer[index] = theme.foreground.as_u32;
            }
        }

        entry.dirty = false;
        entry = entry.next;
    }
}

init_graphics :: (boot_data: Boot_Data) {
    g := *graphics;

    g.screen = create_surface(VESA_WIDTH, VESA_HEIGHT);
    screen_size := g.screen.width * g.screen.height * size_of(u32);

    flags := Page_Flags.READ_WRITE | .PRESENT | .PAGE_SIZE;
    g.vesa_framebuffer = map_memory(screen_size, physical_address = boot_data.vesa_framebuffer, flags);

    cursor_file := read_file("system/cursor.ppm");
    cursor_graphic = parse_pnm(cursor_file);
}

paint_screen :: () {
    if !graphics.initialized return;
    g := *graphics;

    execute_draw_list(g.draw_list, g.screen);

    screen_size := g.screen.width * g.screen.height * size_of(u32);
    memcpy(g.vesa_framebuffer, g.screen.buffer, xx screen_size);
    move_mouse(mouse.position_x, mouse.position_y, true);
}

old_mouse_x: int;
old_mouse_y: int;

cursor_graphic: Pnm;
last_mouse_move: Basic.Apollo_Time;

get_the_fucking_time :: get_system_time;

move_mouse :: (new_x: int, new_y: int, always := false) {
    if !do_mouse return;

    g := *graphics;
    cursor_size := 32;

    while new_x + cursor_size > g.screen.width new_x -= g.screen.width;
    while new_y + cursor_size > g.screen.height new_y -= g.screen.height;

    while new_x < 0 new_x += g.screen.width;
    while new_y < 0 new_y += g.screen.height;

    using Basic;
    fade := get_the_fucking_time() - last_mouse_move;
    fade -= seconds_to_apollo(1);

    if fade < seconds_to_apollo(0) fade = seconds_to_apollo(0);
    if fade > seconds_to_apollo(1) fade = seconds_to_apollo(1);

    if new_x != old_mouse_x || new_y != old_mouse_y {
        last_mouse_move = get_the_fucking_time();
    } else {
        if !always return;
    }

    // Clear the old location
    start := old_mouse_x + g.screen.width * old_mouse_y;

    for 0..cursor_size - 1 {
        memcpy(g.vesa_framebuffer + start, g.screen.buffer + start, cursor_size * size_of(u32));
        start += g.screen.width;
        if start + cursor_size * size_of(u32) > g.screen.height * g.screen.width {
            break;
        }
    }

    fade_s := cast(float) to_milliseconds(fade) / 1000;
    // Paint the new location
    start = new_x + g.screen.width * new_y;

    cursor: int;
    for y: 0..cursor_size-1 {
        if new_y + y >= g.screen.height break;
        for x: 0..cursor_size-1 {
            if new_x + x >= g.screen.width continue;
            alpha   := cast(float) cursor_graphic.data[cursor] / 255;
            border  := cast(float) cursor_graphic.data[cursor + 1] / 255 + alpha;

            index := (x) + (y) * g.screen.width;
            index += new_x;
            index += new_y * g.screen.width;

            // color : u32 = xx ifx black then theme.background else theme.accent;
            g.vesa_framebuffer[index] = blend(theme.accent.as_u32, g.vesa_framebuffer[index], min(alpha, 1));
            g.vesa_framebuffer[index] = blend(theme.foreground.as_u32, g.vesa_framebuffer[index], min(border, 1));

            cursor += 3;
        }
        cursor = y * cursor_size * 3;
    }

    old_mouse_x = new_x;
    old_mouse_y = new_y;

    blend :: (target: u32, source: u32, t: float) -> u32 #expand {
        result: u32;
        c :: (color: u32, offset: u32) -> u32 #expand {
            return (color >> offset) & 0xff;
        }

        result  = (cast(u32) (cast(float) c(target, 16) * (1 - t) + cast(float) c(source, 16) * t)) << 16;
        result |= (cast(u32) (cast(float) c(target,  8) * (1 - t) + cast(float) c(source,  8) * t)) << 8;
        result |= (cast(u32) (cast(float) c(target,  0) * (1 - t) + cast(float) c(source,  0) * t));

        return result;
    }
}


Blitter :: struct {
    #as draw: Draw_List_Entry;
    draw.type = .BLITTER;
    source_surface: Surface;
}

render_blitter :: (blit: *Blitter, surface: Surface) {
    count := blit.draw.height;

    highest_y := blit.draw.y + blit.draw.height;
    if highest_y > VESA_HEIGHT  count -= highest_y - VESA_HEIGHT;

    start := 0;
    if blit.draw.y < 0 start = -blit.draw.y;

    for start..count - 1 {
        target := surface.buffer + blit.draw.x;
        target += blit.draw.y * surface.stride;
        target += it * surface.stride;

        source := blit.source_surface.buffer;
        source += it * blit.source_surface.stride;

        count := blit.source_surface.width;

        highest_x := blit.draw.x + blit.draw.width;
        if highest_x > VESA_WIDTH  count -= highest_x - VESA_WIDTH;

        start := 0;
        if blit.draw.x < 0 start = -blit.draw.x;
        for start..count-1 {
            target[it] = source[it];
        }
    }
}



Solid_Color :: struct {
    #as draw: Draw_List_Entry;
    draw.transparency = false;
    draw.type = .SOLID_COLOR;
    color: Color;
}

render_solid_color :: (solid: *Solid_Color, surface: Surface) {
    count := solid.draw.height;

    highest_y := solid.draw.y + solid.draw.height;
    if highest_y > VESA_HEIGHT  count -= highest_y - VESA_HEIGHT;

    start := 0;
    if solid.draw.y < 0 start = -solid.draw.y;

    for start..count - 1 {
        target := surface.buffer + solid.draw.x;
        target += solid.draw.y * surface.stride;
        target += it * surface.stride;

        count := solid.draw.width;

        highest_x := solid.draw.x + solid.draw.width;
        if highest_x > VESA_WIDTH  count -= highest_x - VESA_WIDTH;

        start := 0;
        if solid.draw.x < 0 start = -solid.draw.x;
        for start..count-1 {
            target[it] = solid.color.as_u32;
        }
    }
}



Text_Viewer :: struct {
    #as draw: Draw_List_Entry;
    draw.type = .TEXT_VIEWER;
    draw.transparency = true;

    buffer: *u8;
    size: int;
    used: int;

    font: Pnm;
    char_width: int;
    char_height: int;

    attr_count: int;
    attr_buffer: *Attribute;

    spacing: int;
    point: bool;

    scroll_position: int;
}

create_text_viewer :: (font: Pnm, buffer_size: int = 0x4000) -> Text_Viewer {
    assert(font.type == .GRAYMAP);

    text: Text_Viewer;
    text.buffer = map_memory(buffer_size);
    text.size = buffer_size;
    text.font = font;

    char_count := 95;
    assert(font.width % 95 == 0);

    text.char_width  = font.width / char_count;
    text.char_height = font.height;

    text.attr_buffer = map_memory(0x8_0000);
    text.spacing = 3;

    return text;
}

set_text_color :: (text: *Text_Viewer, color: Color) {
    if text.attr_count {
        last_attr := text.attr_buffer[text.attr_count - 1];
        if last_attr.color.as_u32 == color.as_u32 return;
    }
    attribute: Attribute;
    attribute.start_position = text.used;
    attribute.color = color;
    text.attr_buffer[text.attr_count] = attribute;
    text.attr_count += 1;
}

write_to_text_viewer :: (text: *Text_Viewer, message: string) {
    if !text return;

    assert(text.used + message.count < text.size, "Text buffer overflow");
    memcpy(text.buffer + text.used, message.data, xx message.count);
    text.used += message.count;
    text.draw.dirty = true;
    // shell.background.draw.dirty = true;
}

write_to_text_viewer :: (text: *Text_Viewer, message: string, color: Color) {
    if !text return;

    assert(text.used + message.count < text.size, "Text buffer overflow");
    memcpy(text.buffer + text.used, message.data, xx message.count);
    set_text_color(text, color);
    text.used += message.count;
    text.draw.dirty = true;
    // shell.background.draw.dirty = true;
}

clear_text_viewer :: (text: *Text_Viewer) {
    text.used = 0;
    text.attr_count = 0;
    text.draw.dirty = true;
}

text_viewer_backspace :: (text: *Text_Viewer) {
    if text.used == 0 return;
    text.used -= 1;
    text.buffer[text.used] = 0;

    count := text.attr_count;
    for 0..count - 1 {
        if text.attr_buffer[it].start_position >= text.used {
            text.attr_count -= 1;
        }
    }
    text.draw.dirty = true;
}

text_viewer_get_rows :: (text: Text_Viewer) -> int {
    rows: int;
    for 0..text.used-1 {
        if text.buffer[it] == #char "\n" {
            rows += 1;
        }
    }
    return rows;
}

// Todo: Doesn't respect line wrapping
text_viewer_how_many_rows_fit_on_these_pixels :: (text: Text_Viewer, pixels: int) -> int {
    return pixels / (text.char_height + text.spacing);
}

render_text_viewer :: (text: *Text_Viewer, surface: Surface, scroll_from_bottom := true) {
    cursor_y: int;
    cursor_x: int;

    color := theme.foreground;
    attr_cursor: int;
    start: int;

    scroll_p := text.scroll_position;

    if scroll_from_bottom == true {
        rows := text_viewer_get_rows(text);
        max_rows := text_viewer_how_many_rows_fit_on_these_pixels(text, text.draw.height);

        if rows > max_rows {
            scroll_p = rows - max_rows;
            scroll_p += text.scroll_position;
        } else scroll_p = 0;
    }

    if scroll_p >= 0 {
        rows: int;
        for 0..text.used - 1 {
            if rows == scroll_p break;
            if text.buffer[it] == #char "\n" {
                rows += 1;
            }
            start += 1;
        }
    } else cursor_y -= scroll_p;

    if text.point {
        shell.command_text.buffer[shell.command_text.used] = #char "_";
        shell.command_text.used += 1;
    }

    for start..text.used - 1 {
        if text.attr_count > attr_cursor {
            attr := text.attr_buffer[attr_cursor];
            while attr.start_position <= it && text.attr_count > attr_cursor {
                color = attr.color;
                attr_cursor += 1;
                attr = text.attr_buffer[attr_cursor];
            }
        }

        char := text.buffer[it];

        if char == 0 continue;
        if char == #char "\r" continue;
        if char == #char "\n" {
            cursor_y += 1;
            cursor_x = 0;
            if (cursor_y + 1) * (text.char_height + text.spacing) > text.draw.height {
                break;
            }
            continue;
        }

        if (cursor_x + 1) * text.char_width >= text.draw.width {
            cursor_x += 1;
            continue;
        }

        source_top_left := text.char_width * (char - 0x20);
        for y: 0..text.char_height - 1 for x: 0..text.char_width - 1 {
            line := cursor_y * (text.char_height + text.spacing) * surface.stride + text.draw.y * surface.stride;
            column := cursor_x * text.char_width + text.draw.x;

            pixel := line + column + x + y * surface.stride;

            old := << cast(*Color) (surface.buffer + pixel);

            index := source_top_left + x + y * text.font.width;
            color.a = cast(u8) text.font.data[index];

            surface.buffer[pixel] = blend(old, color).as_u32;

            if theme.shadow > 0 {
                shadow_offset := 2 + 2 * surface.stride;
                shadow_color := Color.{ as_u32 = 0x00181818 };
                shadow_color.a = color.a;

                if color.a != 0 surface.buffer[pixel + shadow_offset] = blend(old, shadow_color).as_u32;
            }
        }

        cursor_x += 1;
        // if (cursor_x + 1) * text.char_width >= text.draw.width {
        //     cursor_x = 0;
        //     cursor_y += 1;
        //     if (cursor_y + 1) * (text.char_height + text.spacing) >= text.draw.height {
        //         break;
        //     }
        // }
    }

    if text.point {
        shell.command_text.used -= 1;
        shell.command_text.buffer[shell.command_text.used] = 0;
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



Attribute :: struct {
    start_position: int;
    color: Color;
}

USE_VGA :: !ENABLE_VESA;

#if ENABLE_VESA {
    #load "vesa.jai";
} else {
    #load "vga.jai";
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
    assert(buffer[0] == #char "P");

    pnm: Pnm;
    pnm.type = xx (buffer[1] - #char "0");
    assert(pnm.type == .GRAYMAP || pnm.type == .PIXMAP);

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
            assert(digit >= #char "0" && digit <= #char "9");
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
    assert(max_value == 255);

    ConsumeWhitespaceAndComments();
    pnm.data = buffer + cursor;

    return pnm;
}

printf :: (format: string, args: .. Any) {
    printf(format, ..args, color = theme.foreground);
}

printf :: (format: string, args: .. Any, color: Color) {
    result := Basic.tprint(format, .. args);
    print(result, color);
}




TITLE :: #string END
   /##     /##                                                  
  | ##    | ##                                                  
 /######  | #######   /######   /######   /#######              
|_  ##_/  | ##__  ## /##__  ## /##__  ## /##_____/              
  | ##    | ##  \ ##| ########| ##  \ ##|  ######               
  | ## /##| ##  | ##| ##_____/| ##  | ## \____  ##              
  |  ####/| ##  | ##|  #######|  ######/ /#######/              
   \___/  |__/  |__/ \_______/ \______/ |_______/               
END;


welcome_screen :: () {
    printf("\n%\n\n", TITLE, color = theme.primary);
    print("Hello, sailor.\n");

    calendar := cmos_get_calendar_time();
    printf("The time is %.\n", Basic.calendar_to_string(calendar));

    printf("There are % files in the root directory. Why am I telling you this?\n\n", filesystem_cache.master.root.directory_entry_count);

    ti := type_info(x86_Feature_Flag);
    print("Supported CPU features: -------------------------------------------", theme.foreground);
    flags_on_this_line: int;
    for 0..ti.names.count-1 {
        if check_feature(cpu.feature_leaves, xx ti.values[it]) {
            name := ti.names[it];
            if name.count >= 8 continue;

            if (flags_on_this_line % 7) == 0 print("\n");

            print("| ", theme.foreground);
            print(name, theme.highlight);
            for 1..8 - name.count  print(" ");
            flags_on_this_line += 1;
        }
    }
    print("\n-------------------------------------------------------------------\n", theme.foreground);

    print("Compiled using ", theme.primary);
    printf("Jai %", COMPILER_VERSION, color = theme.accent);
    print(".\n\n");
    print_stack_trace();
}
