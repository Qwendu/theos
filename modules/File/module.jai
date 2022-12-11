
File :: struct {
    path: string;
    cursor: int;
}

file_open :: (name: string, for_writing := false, keep_existing_content := false, log_errors := false) -> File, bool {
    result := Formosa.create_file(name);
    if (result != .success) && (result != .item_already_exists) {
        if log_errors log_error("Could not open file: \"%\", error: %", name, result);
        return .{}, false;
    }

    if !keep_existing_content  Formosa.write_file(name, .[]);

    file: File;
    file.path = name;

    return file, true;
}

file_write :: inline (file: *File, data: string) -> bool {
    return file_write(file, data.data, data.count);
}

file_write :: (file: *File, builder: *String_Builder, do_reset := true) -> bool {
    defer if do_reset reset(builder);
    
    buffer := get_base_buffer(builder);
    while buffer {
        success := file_write(file, get_buffer_data(buffer), buffer.count);
        if !success return false;

        buffer = buffer.next;
    }

    return true;
}

write_entire_file :: inline (name: string, data: string) -> bool {
    return Formosa.write_file(name, cast([] u8) data) == .success;
}

write_entire_file :: (name: string, data: *void, count: int) -> bool {
    content: [] u8;
    content.data = xx data;
    content.count = count;

    return Formosa.write_file(name, content) == .success;
}

write_entire_file :: (name: string, builder: *String_Builder, do_reset := true) -> bool {
    success := write_entire_file(name, builder_to_string(builder));
    if do_reset reset(builder);
    return success;
}

read_entire_file :: (name: string, zero_terminated := false, log_errors := true) -> string, bool {
    data, result := Formosa.read_file(name);
    return xx data, result == .success;
}

make_directory_if_it_does_not_exist :: (name: string, recursive := false) -> bool {
    return false;
}


file_close :: (file: *File) {
    file.path = "";
    file.cursor = 0;
}

file_move :: (name_old: string, name_new: string) -> bool {
    return false;
}

file_delete :: (filename: string) -> bool {
    return false;
}

file_link :: (link : string, filepath : string) -> bool {
    return false;
}

is_valid :: (file: File) -> bool {
    return true;
}

file_read :: (f: File, vdata: *void, bytes_to_read: s64) -> (success: bool, bytes_read: s64) {
    file, result := Formosa.read_file(f.path);
    defer Formosa.unmap_memory(file.count, file.data);

    if result != .success  return false, 0;
    to_copy := ifx bytes_to_read < (file.count - f.cursor)  bytes_to_read else (file.count - f.cursor);

    memcpy(vdata, file.data + f.cursor, to_copy);
    return true, to_copy;
}

file_length :: (file: File) -> s64, bool {
    data, result := Formosa.read_file(file.path);
    Formosa.unmap_memory(data.count, data.data);
    return data.count, result == .success;
}

file_current_position :: (f: File) -> s64, bool {
    return f.cursor, true;
}

file_set_position :: (f: *File, pos: s64) -> bool {
    f.cursor = pos;
    return true;
}

read_entire_file :: (f: File, zero_terminated := false) -> string, bool {
    assert(!zero_terminated);
    file, result := Formosa.read_file(f.path);

    return xx file, result == .success;
}

file_write :: (file: *File, data: *void, length: s64) -> bool {
    f, result := Formosa.read_file(file.path);
    if result != .success return false;

    content: [] u8;
    content.count = f.count;
    if file.cursor + length > content.count  content.count = file.cursor + length;

    content.data = Formosa.map_memory(content.count);
    defer Formosa.unmap_memory(content.count, content.data);

    memcpy(content.data, f.data, f.count);
    memcpy(content.data + file.cursor, data, length);

    Formosa.write_file(file.path, content);
    return true;
}


delete_directory :: (dirname: string) -> bool {
    return false;
}

file_seek :: (file: *File, pos: s64, type: Seek_Type) -> (success: bool) {
    if type == .START   file.cursor = pos;
    else if type == .CURRENT file.cursor += pos;
    else if type == .END {
        length := file_length(file);
        file.cursor = length - pos;
    }

    return true;
}

file_tell :: (file: File) -> (success: bool, position: s64) {
    return true, file.cursor;
}

#scope_module

Seek_Type :: enum {
    START     :: 0;
    CURRENT   :: 1;
    END       :: 2;
}

#import "Basic";
#import "String";

Formosa :: #import "Formosa";
