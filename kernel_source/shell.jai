
handle_keyboard_events :: () {
    while true {
        event, success := read_event_buffer(*input_key_buffer);
        key_code := event.key;
        if !success break;

        if key_code == .FLAG || shell.flag_held {
            write_event_buffer(*the_first_task.parent_process.input, event);
            continue;
        }

        write_event_buffer(*shell.foreground_task.parent_process.input, event);
        if shell.foreground_task.state == .WAITING_FOR_MESSAGE {
            shell.foreground_task.state = .AWAKE;
        }
    }
}

last_x, last_y: int;

handle_mouse_events :: () {
    while true {
        press := read_event_buffer(*mouse.buffer);

        if last_x != mouse.position_x || last_y != mouse.position_y {
            last_x = mouse.position_x;
            last_y = mouse.position_y;
        }

        else if press == .NONE break;

        if press == .NONE press = .MOVE_ONLY;

        event: Mouse_Event;
        event.event = press;
        event.pixel_position_x = mouse.position_x;
        event.pixel_position_y = mouse.position_y;

        if shell.flag_held {
            write_event_buffer(*the_first_task.parent_process.mouse_events, event);
            continue;
        }

        hit := get_window_at(event.pixel_position_x, event.pixel_position_y);

        if hit != INVALID_WINDOW_HANDLE {
            window := *windows[hit];
            event.maybe_window = hit;
            event.pixel_position_in_window_x = event.pixel_position_x - window.blitter.draw.x;
            event.pixel_position_in_window_y = event.pixel_position_y - window.blitter.draw.y;
        }

        write_event_buffer(*shell.foreground_task.parent_process.mouse_events, event);
        if shell.foreground_task.state == .WAITING_FOR_MESSAGE {
            shell.foreground_task.state = .AWAKE;
        }
    }
}

Shell :: struct {
    text: Text_Viewer;
    command_text: Text_Viewer;
    command_buffer: [128] u8;
    command_buffer_size: int;
    background: Solid_Color;

    shift_held: bool;
    ctrl_held: bool;
    flag_held: bool;
    lmb_held: bool;

    dragging := INVALID_WINDOW_HANDLE;
    window_drag_offset_x: int;
    window_drag_offset_y: int;

    command_index: int;

    history: [..] string;
    history_index: int;

    foreground_task: *Task_Info;
}

shell: Shell;
init_shell :: (font: Pnm) {
    graphics.initialized = true;
    shell.background.color = theme.background;
    shell.background.draw.width = graphics.screen.width;
    shell.background.draw.height = graphics.screen.height;
    add_screen_draw_list_entry(*shell.background, 0, 0, "background");

    shell.foreground_task = *the_first_task;

    shell.text         = create_text_viewer(font, buffer_size = 0x10_0000);
    shell.command_text = create_text_viewer(font);

    add_screen_draw_list_entry(*shell.text, 50, 50, "shell output");
    shell.text.draw.width = 1200;
    shell.text.draw.height = graphics.screen.height - 110;

    add_screen_draw_list_entry(*shell.command_text, 50, graphics.screen.height - 50, "command");
    shell.command_text.draw.width = 900;
    shell.command_text.draw.height = 30;

    write_to_text_viewer(*shell.command_text, "> ");

    old_history := read_file("system/history");
    if !old_history.count {
        create_file("system/history");
    } else for split(cast(string) old_history, "\n") {
        array_add(*shell.history, it);
    }
    shell.history_index = shell.history.count;
}

update_shell :: () {
    shell_handle_keypress();
    shell_handle_mouse();
    shell_update_command_lists();

    if shell.foreground_task == *the_first_task || shell.command_text.point {
        time := get_system_time();
        ct := formosa_apollo_to_calendar(time);
        if xx (ct.millisecond > 500) == shell.command_text.point {
            shell.command_text.point = !shell.command_text.point;
            shell.command_text.draw.dirty = true;
            paint_screen();
        }
    }
}

update_syntax_highlighting :: () {
    command: string;
    command.data = shell.command_text.buffer + 2;
    command.count = shell.command_text.used - 2;

    tokens := tokenize_command(command);
    shell.command_text.attr_count = 0;

    for token: tokens {
        text := *shell.command_text;

        HighlightToken :: (color: Color) #expand {
            attribute: Attribute;
            attribute.start_position = token.start + 2;
            attribute.color = color;
            text.attr_buffer[text.attr_count] = attribute;
            text.attr_count += 1;

            attribute.start_position = token.end + 2;
            attribute.color = theme.foreground;
            text.attr_buffer[text.attr_count] = attribute;
            text.attr_count += 1;
        }

        if token.type == .STRING {
            HighlightToken(theme.accent);
        }

        if token.type == .INT {
            HighlightToken(theme.primary);
        }
    }
}

get_window_at :: (x: int, y: int) -> Window_Handle {
    hit := INVALID_WINDOW_HANDLE;
    for *windows {
        if (x > it.blitter.draw.x) && (x < it.blitter.draw.x + it.blitter.draw.width) && (y > it.blitter.draw.y) && (y < it.blitter.draw.y + it.blitter.draw.height) {
            if hit == INVALID_WINDOW_HANDLE {
                hit = it_index;
            } else {
                entry := *windows[hit].blitter.draw;
                while entry {
                    if entry == *it.blitter.draw {
                        hit = it_index;
                        break;
                    }
                    entry = entry.next;
                }
            }
        }
    }
    return hit;
}

shell_handle_mouse :: () {
    while true {
        event := read_event_buffer(*the_first_task.parent_process.mouse_events);
        if event.event == .NONE break;

        if event.event == .BUTTON_1_PRESSED {
            shell.lmb_held = true;

            x := mouse.position_x;
            y := mouse.position_y;
            hit := get_window_at(x, y);

            move_to_front(hit);
            shell.dragging = hit;

            if hit != INVALID_WINDOW_HANDLE {
                w := *windows[hit];
                if w.exists {
                    shell.foreground_task = w.owner;
                    shell.window_drag_offset_x = x - w.blitter.draw.x;
                    shell.window_drag_offset_y = y - w.blitter.draw.y;
                }
            } else {
                shell.foreground_task = *the_first_task;
            }
        }

        if event.event == .BUTTON_1_RELEASED {
            shell.lmb_held = false;
            shell.dragging = INVALID_WINDOW_HANDLE;
        }
    }

    if shell.lmb_held && shell.dragging != INVALID_WINDOW_HANDLE {
        w := *windows[shell.dragging];
        if !w.exists return;

        x := mouse.position_x;
        y := mouse.position_y;
        w.blitter.draw.x = x - shell.window_drag_offset_x;
        w.blitter.draw.y = y - shell.window_drag_offset_y;
        w.shadow.draw.x = x - shell.window_drag_offset_x;
        w.shadow.draw.y = y - shell.window_drag_offset_y;

        paint_screen();
    }
}

shell_handle_keypress :: (is_reading_string: bool = false) -> command: string = "" {
    event, success := read_event_buffer(*the_first_task.parent_process.input);
    key_code := event.key;
    if key_code == .UNKNOWN return;
    if !success return;

    need_repaint: bool;
    while true {
        key := cast(u16) key_code;

        if event.type == .RELEASED {
            if key_code == .SHIFT || key_code == .RIGHT_SHIFT {
                shell.shift_held = false;
            }

            else if key_code == .CTRL {
                shell.ctrl_held = false;
            }

            else if key_code == .FLAG {
                shell.flag_held = false;
            }
        }

        else if key_code == .FLAG {
            shell.flag_held = true;
        }

        // else if key_code == (Key_Code.FLAG + 0x80) {
        //     shell.flag_held = false;
        // }

        else if key_code == .SHIFT || key_code == .RIGHT_SHIFT {
            shell.shift_held = true;
        }

        else if key_code == .CTRL {
            shell.ctrl_held = true;
        }

        else if key_code == .ENTER {
            command: string;
            command.data = shell.command_text.buffer + 2;
            command.count = shell.command_text.used - 2;
            need_repaint = true;
            if is_reading_string {
                clear_text_viewer(*shell.command_text);
                update_syntax_highlighting();

                return command;
            }

            shell.command_text.buffer[shell.command_text.used] = 0;

            printf("[%]", shell.command_index, color = theme.secondary);
            printf(" %\n\n", command, color = theme.primary);

            shell.command_index += 1;

            if shell_handle_text_command(command) {
                clear_text_viewer(*shell.command_text);
                write_to_text_viewer(*shell.command_text, "> ");
                update_syntax_highlighting();

                if command != shell.history[shell.history.count - 1] {
                    array_add(*shell.history, copy_string(command));
                }

                history := cast(string) read_file("system/history");
                history = tprint("%\n%", history, command);
                write_file("system/history", cast([] u8) history);
            }
            shell.history_index = shell.history.count;
        }

        else if !shell.ctrl_held && key_code == .ARROW_UP {
            if !shell.history.count return;

            shell.history_index -= 1;
            if shell.history_index < 0 shell.history_index = 0;

            clear_text_viewer(*shell.command_text);
            write_to_text_viewer(*shell.command_text, "> ");
            write_to_text_viewer(*shell.command_text, shell.history[shell.history_index]);
            update_syntax_highlighting();
            need_repaint = true;

            if shell.text.scroll_position != 0 {
                shell.text.scroll_position = 0;
                shell.text.draw.dirty = true;
                shell.command_text.draw.dirty = true;
            }
        }

        else if !shell.ctrl_held && key_code == .ARROW_DOWN {
            shell.history_index += 1;

            if shell.history_index >= shell.history.count {
                shell.history_index = shell.history.count;
                clear_text_viewer(*shell.command_text);
                write_to_text_viewer(*shell.command_text, "> ");
                update_syntax_highlighting();
            } else {
                clear_text_viewer(*shell.command_text);
                write_to_text_viewer(*shell.command_text, "> ");
                write_to_text_viewer(*shell.command_text, shell.history[shell.history_index]);
                update_syntax_highlighting();
            }
            need_repaint = true;

            if shell.text.scroll_position != 0 {
                shell.text.scroll_position = 0;
                shell.text.draw.dirty = true;
                shell.command_text.draw.dirty = true;
            }
        }

        else if key_code == .BACKSPACE {
            if !is_reading_string if shell.command_text.used > 2 {
                need_repaint = true;
                if shell.ctrl_held {
                    command: string;
                    command.data = shell.command_text.buffer + 2;
                    command.count = shell.command_text.used - 2;

                    tokens := tokenize_command(command);
                    if tokens.count {
                        shell.command_text.used = tokens[tokens.count - 2].start + 2;
                        shell.command_text.draw.dirty = true;
                    }
                } else {
                    text_viewer_backspace(*shell.command_text);
                }
                update_syntax_highlighting();
            }
        }

        else if shell.flag_held && key_code == .TAB {
            shell.foreground_task = shell.foreground_task.next;
            for *windows {
                if it.exists && it.owner == shell.foreground_task {
                    move_to_front(it_index);
                    need_repaint = true;
                }
            }
        }

        else if key_code == .TAB {
            // calendar := cmos_get_calendar_time();
            // printf("The CMOS time is %.\n", calendar_to_string(calendar));
            // 
            // calendar = formosa_apollo_to_calendar(system_time);
            // printf("The SYSTEM time is %.\n", calendar_to_string(calendar));
            // return "";

            if !is_reading_string {
                do_autocomplete_inefficiently_using_copypasta_code();
                update_syntax_highlighting();
                need_repaint = true;
            }
        }

        else if key_code == xx #char "C" && shell.ctrl_held {
            clear_text_viewer(*shell.command_text);
            write_to_text_viewer(*shell.command_text, "> ");
            update_syntax_highlighting();
            shell.history_index = shell.history.count;
            need_repaint = true;
        }

        else if key_code == .ARROW_UP {
            shell.text.scroll_position -= 5;
            min := -text_viewer_get_rows(*shell.text) + text_viewer_how_many_rows_fit_on_these_pixels(*shell.text, shell.text.draw.height);
            if shell.text.scroll_position < min {
                shell.text.scroll_position = min;
            }
            shell.text.draw.dirty = true;
            shell.command_text.draw.dirty = true;
            need_repaint = true;
        }

        else if key_code == .ARROW_DOWN {
            shell.text.scroll_position += 5;
            if shell.text.scroll_position > 0 {
                shell.text.scroll_position = 0;
            }
            shell.text.draw.dirty = true;
            shell.command_text.draw.dirty = true;
            need_repaint = true;
        }

        else if key_code == .ESCAPE {};

        else {
            // if key >= scan_table.count key = 0;
            char: [1] u8;
            // if shell.shift_held {
            //     char.data = *scan_table_shifted[key];
            // } else {
            //     char.data = *scan_table[key];
            // }
            char[0] = key_code_to_ascii(key_code, shell.shift_held);
            need_repaint = true;

            if char[0] != 0 {
                if shell.text.scroll_position != 0 {
                    shell.text.scroll_position = 0;
                    shell.text.draw.dirty = true;
                    shell.command_text.draw.dirty = true;
                }

                write_to_text_viewer(*shell.command_text, xx char);
                update_syntax_highlighting();
            }
        }

        event, success = read_event_buffer(*the_first_task.parent_process.input);
        if !success break;
        key_code = event.key;
    }

    if need_repaint paint_screen();
    return;
}

do_autocomplete_inefficiently_using_copypasta_code :: () {
    command: string;
    command.data = shell.command_text.buffer + 2;
    command.count = shell.command_text.used - 2;

    parse_success, steps, tokens := parse_command(command);
    // defer unmap_memory(parse_args.count * size_of(type_of(<< parse_args.data)), xx parse_args.data);
    defer unmap_memory(tokens.count * size_of(type_of(<< tokens.data)), xx tokens.data);

    parse_args := steps[steps.count - 1].parameters;
    name := steps[steps.count - 1].name;

    if !parse_success return;

    exe := read_file(tprint("programs/%", name));
    defer unmap_memory(exe.count, xx exe.data);
    if !exe.count && parse_args.count == 0 {
        entries := list_directory("programs");

        for entries {
            if begins_with_nocase(it.name, name) {
                shell.command_text.used = tokens[tokens.count - 2].start + 2;
                write_to_text_viewer(*shell.command_text, it.name);
                write_to_text_viewer(*shell.command_text, " ");
                update_syntax_highlighting();
                break;
            }
        }
        return;
    }

    if !parse_args.count return;
    if !exe.count return;

    header := cast(*Formosa_Exe_Header) exe.data;

    map_memory(header.type_table_size, cast(u64) header.type_table_virtual_address);
    defer unmap_memory(header.type_table_size, cast(u64) header.type_table_virtual_address);

    type_table: [] *Type_Info;
    type_table.count = header.input_parameter_count;
    type_table.data = xx header.type_table_virtual_address;

    table_size := header.elf_offset - size_of(Formosa_Exe_Header);

    memcpy(type_table.data, exe.data + header.type_table_offset, table_size);

    index := parse_args.count - 1;
    if index >= type_table.count return;

    last_arg := *parse_args[index];
    if last_arg.type == .IDENT {
        if type_table[index].type == .ENUM {
            tie := cast(*Type_Info_Enum) type_table[index];
            for tie.names {
                if begins_with_nocase(it, last_arg._string) {
                    shell.command_text.used = last_arg.token_or_null.start + 2;
                    write_to_text_viewer(*shell.command_text, it);
                    write_to_text_viewer(*shell.command_text, ", ");
                    update_syntax_highlighting();
                    return;
                }
            }
        }
        return;
    }

    if last_arg.type == .STRING {
//        assert(false);
//        for 0..filesystem_cache.master.root.directory_entry_count - 1 {
//            dir_entry := *filesystem_cache.root.entries[it];
//
//            other_name: string;
//            other_name.data = dir_entry.name.data;
//            other_name.count = c_style_strlen(dir_entry.name.data);
//
//            if begins_with_nocase(other_name, last_arg._string) {
//                shell.command_text.used = last_arg.token_or_null.start + 2;
//                write_to_text_viewer(*shell.command_text, "\"");
//                write_to_text_viewer(*shell.command_text, other_name);
//                write_to_text_viewer(*shell.command_text, "\"");
//                update_syntax_highlighting();
//                break;
//            }
//        }
        return;
    }

    if last_arg.type == .STRING && !last_arg.token_or_null.string_is_terminated {
        write_to_text_viewer(*shell.command_text, "\"");
    }

    if tokens.count > 1 {
        if tokens[tokens.count - 2].type == .COMMA  return;
    }

    write_to_text_viewer(*shell.command_text, ", ");
}

command_lists: [..][..] Command_Step;

shell_update_command_lists :: () {
    for list: command_lists {
        for step: list {
            if step.task == null continue list;
            if step.task.state != .RETIRED continue list; 

            if (it_index + 1) < list.count {
                next_step := *list[it_index + 1];
                if next_step.task == null {
                    new_task := shell_load_program(next_step);
                    if !new_task break;

                    new_task.parent_process.input_data = step.task.parent_process.output_data;
                    new_task.state = .AWAKE;
                    next_step.task = new_task;
                    continue list;
                }
            }
        }

        last_task := list[list.count - 1].task;
        if last_task {
            print_ipc_data(last_task.parent_process.output_data);
            paint_screen();

            if shell.text.buffer[shell.text.used - 1] == #char "\n" && shell.text.buffer[shell.text.used - 2] != #char "\n" {
                print("\n");
            }
        }

        remove list;
    }
}

shell_load_program :: (step: Command_Step) -> *Task_Info {
    exe := read_file(tprint("programs/%", step.name));
    defer unmap_memory(exe.count, xx exe.data);

    if !exe.count {
        printf("Command not found: \"%\"!\n\n", step.name);
        return null;
    }

    header := cast(*Formosa_Exe_Header) exe.data;

    use_type_table := header.type_table_size && (header.type == .ELF);

    if use_type_table map_memory(header.type_table_size, cast(u64) header.type_table_virtual_address);
    defer if use_type_table unmap_memory(header.type_table_size, cast(u64) header.type_table_virtual_address);

    if !step.parameters.count {
        task := load_program(exe);
        task.parent_process.name = copy_string(step.name);
        return task;
    }

    args := NewArray(32, Any);

    type_table: [] *Type_Info;
    type_table.count = header.input_parameter_count;
    type_table.data = xx header.type_table_virtual_address;

    table_size := header.elf_offset - size_of(Formosa_Exe_Header);
    memcpy(type_table.data, exe.data + header.type_table_offset, table_size);

    for * step.parameters {
        if it.type == .IDENT {
            if it_index < type_table.count && type_table[it_index].type == .ENUM {

                the_enum := cast(*Type_Info_Enum) type_table[it_index];
                found: bool;

                to_lower_in_place(it._string);
                for name: the_enum.names {
                    if to_lower_copy(name) == it._string {
                        it._int = the_enum.values[it_index];
                        found = true;
                        break;
                    }
                }

                args[it_index].value_pointer = *it.value;
                args[it_index].type = type_table[it_index];
            } else {
                args[it_index] = it.value._string;
            }

        }

        else if it.type == .STRING args[it_index] = it.value._string;
        else if it.type == .INT    args[it_index] = it.value._int;

        else assert(false);
    }

    the_args: [] Any;
    the_args.count = step.parameters.count;
    the_args.data = args.data;

    task := load_program(exe, .. the_args);
    task.parent_process.name = copy_string(step.name);

    return task;
}

shell_handle_text_command :: (command_string: string) -> bool {
    if !command_string.count return false;

    parse_success, steps, tokens := parse_command(command_string);
    if !parse_success || !steps.count return false;

    list := array_add(*command_lists);
    for steps {
        entry := array_add(list);
        entry.name = copy_string(it.name);

        entry.parameters.data = map_memory(size_of(Shell_Typed_Value) * it.parameters.count);
        entry.parameters.count = it.parameters.count;

        for it.parameters {
            entry.parameters[it_index] = it;
            if it.type == .IDENT || it.type == .STRING {
                entry.parameters[it_index]._string = copy_string(it._string);
            }
        }
    }

    // if shell.text.buffer[shell.text.used - 1] == #char "\n" && shell.text.buffer[shell.text.used - 2] != #char "\n" {
    //     print("\n");
    // }

    task := shell_load_program((<< list)[0]);
    if task == null return false;
    task.state = .AWAKE;
    (<< list)[0].task = task;

    return true;
}

Shell_Typed_Value :: struct {
    type: Type;
    using value: Value;

    token_or_null: *Token;
    Type :: enum {
        NONE;
        IDENT;
        STRING;
        INT;
    }

    Value :: union {
        _string: string;
        _int: int;
    }
}

Command_Step :: struct {
    name: string;
    parameters: [] Shell_Typed_Value;
    task: *Task_Info;
}

parse_command :: (command: string) -> bool, [] Command_Step, tokens: [] Token {

    generate_parse_error :: (format: string, args: .. Any) #expand {
        print("Command parse error:\n");
        printf(format, .. args);

        t := tokens[index];

        print("   Here is the problem: > ");
        first_part: string;
        first_part.data = command.data;
        first_part.count = t.start;

        error_part: string;
        error_part.data = command.data + t.start;
        error_part.count = t.end - t.start;

        last_part: string;
        last_part.data = command.data + t.end;
        last_part.count = command.count - t.end + 1;

        print(first_part);
        print(error_part, Color.{ as_u32 = 0xff0000 });
        print(last_part);
        print("\n\n");
    }

    tokens := tokenize_command(command);
    index: int;
    steps: [..] Command_Step;

    while true {
        tok := tokens[index];
        if tok.type == .EOT return true, steps, tokens;

        step := array_add(*steps);

        if tok.type != .IDENT {
            generate_parse_error("Type the name of a command to run.\n");
            return false, steps, tokens;
        }

        step.name = tok._string;

        index += 1;
        tok = tokens[index];
        if tok.type == .EOT return true, steps, tokens;

        parameters: [..] Shell_Typed_Value;
        defer step.parameters = parameters;

        while true {
            if tok.type == .VERTICAL_BAR {
                index += 1;
                break;
            }

            element := Basic.array_add(*parameters);
            element.token_or_null = *tokens[index];
            if tok.type == .INT {
                element.type = .INT;
                element._int =  tok._int;
            }

            else if tok.type == .STRING {
                element.type = .STRING;
                element._string = tok._string;
            }

            else if tok.type == .IDENT {
                element.type = .IDENT;
                element._string = tok._string;
            }

            else {
                generate_parse_error("Expected a parameter, but got token type %\n", tok.type);
                return false, steps, tokens;
            }

            index += 1;
            tok = tokens[index];
            if tok.type == .COMMA {
                index += 1;
                tok = tokens[index];
                if tok.type == .EOT return true, steps, tokens;
                continue;
            }

            if tok.type == .EOT return true, steps, tokens;

            if tok.type != .VERTICAL_BAR {
                generate_parse_error("Expected a comma or vertical bar, but got token type %\n", tok.type);
                return false, steps, tokens;
            }
        }
    }

    return true, steps, tokens;
}



EOT : u8 : 0x4;

Token :: struct {
    type: Type;
    using value: Value;

    start: int;
    end: int;

    string_is_terminated: bool;

    Type :: enum {
        NONE; IDENT; STRING; INT; COMMA; VERTICAL_BAR; POUND_SIGN; EOT; ERROR;
    }

    Value :: union {
        _string: string;
        _int: int;
    }
}

tokenize_command :: (command: string) -> [..] Token {
    cursor: int;
    result: [..] Token;

    current :: () -> u8 #expand {
        if cursor >= command.count  return EOT;
        return command[cursor];
    }

    start: int;
    Emit :: (type: Token.Type, _string := "", _int := 0) -> *Token #expand {
        token := Basic.array_add(*result);
        token.type = type;

        if _int    != 0  token._int = _int;
        if _string != "" token._string = _string;

        token.start = start;
        token.end = cursor + 1;
        return token;
    }

    is_char :: (char: u8) -> bool {
        if char >= #char "a" && char <= #char "z"  return true;
        if char >= #char "A" && char <= #char "Z"  return true;
        if char == #char "_"  return true;
        return false;
    }

    is_num :: (char: u8) -> bool {
        if char >= #char "0" && char <= #char "9"  return true;
        return false;
    }

    while true {
        defer cursor += 1;
        while current() == #char " " || current() == #char "\r" cursor += 1;

        start = cursor;
        if current() == {
          case #char ",";
            Emit(.COMMA);

          case #char "|";
            Emit(.VERTICAL_BAR);

          case #char "#";
            Emit(.EOT);
            return result;

          case 0; #through;
          case EOT;
            Emit(.EOT);
            return result;

          case #char "\"";
            cursor += 1;
            text: string;
            text.data = command.data + cursor;

            while current() != #char "\"" && current() != EOT {
                text.count += 1;
                cursor += 1;
            }

            tok := Emit(.STRING, _string = text);
            tok.string_is_terminated = true;

            if current() != #char "\"" {
                cursor -= 1;
                tok.end -= 1;
                tok.string_is_terminated = false;
            }

          case;
            if is_num(current()) {
                num: int;
                while is_num(current()) {
                    num *= 10;
                    num += current() - #char "0";
                    cursor += 1;
                }
                cursor -= 1;
                Emit(.INT, _int = num);
            }

            else if is_char(current()) {
                ident: string;
                ident.data = command.data + cursor;
                while is_char(current()) || is_num(current()) {
                    ident.count += 1;
                    cursor += 1;
                }
                cursor -= 1;
                Emit(.IDENT, _string = ident);
            }

            else Emit(.ERROR);
        }
    }

    return result;
}

represent_apollo_delta :: (time: Basic.Apollo_Time) -> string {
    s, success := Basic.to_seconds(time);
    assert(success);
    if s < 60  return Basic.tprint("% second%", s, ifx s == 1 then "" else "s");

    m := s / 60;
    if m < 60  return Basic.tprint("% minute%", m, ifx m == 1 then "" else "s");

    h := m / 60;
    if h < 24  return Basic.tprint("% hour%", h, ifx h == 1 then "" else "s");
    
    d := h / 24;
    if d < 30  return Basic.tprint("% day%", d, ifx d == 1 then "" else "s");
    
    m = d / 30;
    if m < 12  return Basic.tprint("% month%", m, ifx m == 1 then "" else "s");

    y := m / 12;
    return Basic.tprint("% year%", y, ifx y == 1 then "" else "s");
}

print_ipc_data :: (value: Any) {
    if value.value_pointer == null return;
    if value.type == null return;

    if value.type.type == .ARRAY {
        array := cast(*[] void) value.value_pointer;
        tia := cast(*Type_Info_Array) value.type;

        if !array.count return;

        if tia.element_type.type == .STRUCT {
            widths := Basic.NewArray(array.count, int);
            tis := cast(*Type_Info_Struct) tia.element_type;

            // Calculate widths:
            for tis.members {
                if it.name.count > widths[it_index]  widths[it_index] = it.name.count;
            }

            for index: 0..array.count - 1 {
                for tis.members {
                    thing: Any;
                    thing.value_pointer = array.data + it.offset_in_bytes + index * tia.element_type.runtime_size;
                    thing.type = it.type;

                    length: int;
                    apollo: bool;

                    context.print_style.default_format_int.base = 10;
                    for it.notes {
                        if it == "Formosa.apollo" {
                            time: *Basic.Apollo_Time = xx thing.value_pointer;
                            length = represent_apollo_delta(Basic.operator-(get_system_time(), << time)).count;
                            apollo = true;
                        }

                        if it == "Formosa.base16" {
                            context.print_style.default_format_int.base = 16;
                        }
                    }

                    if !apollo length = Basic.tprint("%", thing).count;
                    if length > widths[it_index]  widths[it_index] = length;
                    context.print_style.default_format_int.base = 10;
                }
            }

            number_of_dashes: int = 5;
            print("| # ");
            if array.count >= 10 {
                print(" ");
                number_of_dashes += 1;
            }

            for tis.members {
                printf("| % ", it.name);
                for 0..widths[it_index] - it.name.count - 1  print(" ");
                number_of_dashes += widths[it_index] + 3;
            }
            print("|\n");
            for 0..number_of_dashes-1 print("-");
            print("\n");

            for index: 0..array.count - 1 {
                print("|");
                printf(" % ", index, color = theme.highlight);
                if array.count >= 10 && index < 10 print(" ");
                for tis.members {
                    thing: Any;
                    thing.value_pointer = array.data + it.offset_in_bytes + index * tia.element_type.runtime_size;
                    thing.type = it.type;

                    print("| ");

                    apollo: bool;
                    to_print: string;
                    context.print_style.default_format_int.base = 10;
                    for it.notes {
                        if it == "Formosa.base16" {
                            context.print_style.default_format_int.base = 16;
                        }

                        if it == "Formosa.apollo" {
                            time: *Basic.Apollo_Time = xx thing.value_pointer;
                            to_print = represent_apollo_delta(Basic.operator-(get_system_time(), << time));
                            apollo = true;
                        }
                    }

                    if !apollo to_print = Basic.tprint("%", thing);
                    print(to_print);

                    for 0..widths[it_index] - to_print.count print(" ");
                    context.print_style.default_format_int.base = 10;
                }
                print("|\n");
            }
        }

        else {
            array := cast(*[] void) value.value_pointer;
            if tia.array_count != -1 {
                fixed := cast(*[3] string) value.value_pointer;
                array.data = fixed.data;
                array.count = tia.array_count;
            }

            element: Any;
            element.type = tia.element_type;

            for 0..array.count - 1 {
                element.value_pointer = array.data + it * tia.element_type.runtime_size;
                printf("| % ", element);
            }
            print("|\n");
        }
    }

    else if value.type.type == .STRUCT {
        new := context;
        new.print_style.default_format_struct.use_long_form_if_more_than_this_many_members = 0;
        new.print_style.default_format_struct.use_newlines_if_long_form = true;

        push_context new {
            tis := cast(*Type_Info_Struct) value.type;
            if tis.name == "Rich_Text" {
                rich := cast(*Rich_Text) value.value_pointer;

                for * rich.attributes {
                    it.start_position += shell.text.used;
                }

                dest := shell.text.attr_buffer + shell.text.attr_count;
                memcpy(dest, rich.attributes.data, rich.attributes.count * size_of(Rich_Text.Attribute));

                shell.text.attr_count += rich.attributes.count;
                write_to_text_viewer(*shell.text, rich.text);
                
            } else {
                printf("%\n", value);
            }
        }
    }

    else {
        printf("%\n", value);
    }

    Rich_Text :: struct {
        text: string;
        attributes: [] Attribute;

        Attribute :: struct {
            start_position: int;
            color: Color;
        }
    }

    print("\n");
}
