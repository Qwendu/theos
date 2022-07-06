

#scope_module

#import "Bit_Array";
#import "Basic";

Extent :: struct {
    block_index: int;
    block_count: int;
}

Directory_Entry :: struct {
    name: [32] u8;
    file_size: int;
    flags: enum_flags u8 {
        LONG_NAME;
        DIRECTORY;
        SYSTEM;
    }
    extents: [4] Extent;

    modified: Apollo_Time;
    created: Apollo_Time;

#place name;
    name_extent: Extent;

#place file_size;
    directory_entry_count: int;
}

// #assert(size_of(Directory_Entry) == 144);

Master_Block :: struct {
    using info: struct {
        root: Directory_Entry;

        magic: u64;
        version: int;
    }
    padding: [FS_BLOCKSIZE - size_of(type_of(info))] u8;
}

Bitmap_Block :: struct {
    ENTRY_COUNT :: FS_BLOCKSIZE / size_of(s64);
    entries: [ENTRY_COUNT] s64;
}

Directory_Block :: struct {
    ENTRY_COUNT :: FS_BLOCKSIZE / size_of(Directory_Entry);
    entries: [ENTRY_COUNT] Directory_Entry;
}

scratch_space: [FS_BLOCKSIZE] u8 #align FS_BLOCKSIZE;

fs_bit_array: Bit_Array;

maybe_create_or_grow_extent :: (extent: *Extent, bytes_required: int) -> space_created: int {
    blocks_required := (bytes_required + FS_BLOCKSIZE - 1) / FS_BLOCKSIZE;

    defer write_block(1, xx *bitmap, fs_user_data);

    if extent.block_count == 0 && blocks_required > 0 {
        contiguous_bits_found: int;
        bit: int;

        while true {
            if !fs_bit_array[bit] {
                contiguous_bits_found += 1;
            } else {
                contiguous_bits_found = 0;
            }

            if contiguous_bits_found == blocks_required {
                for bit - contiguous_bits_found..bit {
                    set_bit(*fs_bit_array, it);
                }
                extent.block_index = bit - contiguous_bits_found + 1;
                extent.block_count = blocks_required;

                return blocks_required * FS_BLOCKSIZE;
            }
            bit += 1;
        }
    }

    block_index := extent.block_index + extent.block_count;
    blocks_required -= extent.block_count;

    for 0..blocks_required - 1 {
        if fs_bit_array[block_index + it] {
            extent.block_count += it;
            return it * FS_BLOCKSIZE;
        }
        set_bit(*fs_bit_array, block_index + it);
    }

    if blocks_required > 0 {
        extent.block_count += blocks_required;
        return blocks_required * FS_BLOCKSIZE;
    }

    return 0;
}

write_data_to_extent :: (extent: Extent, data: *u8, count: int) -> remaining: int {
    blocks_required := (count + FS_BLOCKSIZE - 1) / FS_BLOCKSIZE;
    blocks_to_write := min(blocks_required, extent.block_count);

    for 0..blocks_to_write - 1 {
        data_pointer := data + it * FS_BLOCKSIZE;

        location := FS_BASE_ADDRESS + (extent.block_index + it) * FS_BLOCKSIZE;

        remaining := count - it * FS_BLOCKSIZE;
        if remaining < FS_BLOCKSIZE {
            memset(scratch_space.data, 0, FS_BLOCKSIZE);
            memcpy(scratch_space.data, data_pointer, remaining);
        } else {
            memcpy(scratch_space.data, data_pointer, FS_BLOCKSIZE);
        }
        write_block(extent.block_index + it, xx scratch_space.data, fs_user_data);
    }

    return count - blocks_to_write * FS_BLOCKSIZE;
}

read_data_from_extent :: (extent: Extent, data: *u8, count: int) -> read: int {
    blocks_required := (count + FS_BLOCKSIZE - 1) / FS_BLOCKSIZE;
    blocks_to_read := min(blocks_required, extent.block_count);

    if read_extent {
        read_extent(extent.block_index, blocks_to_read, data, fs_user_data);
        return min(count, blocks_to_read * FS_BLOCKSIZE);
    }

    for 0..blocks_to_read - 1 {
        data_pointer := data + it * FS_BLOCKSIZE;
        location := FS_BASE_ADDRESS + (extent.block_index + it) * FS_BLOCKSIZE;
        
        read_block(extent.block_index + it, xx scratch_space.data, fs_user_data);
        remaining := count - it * FS_BLOCKSIZE;
        
        if remaining < FS_BLOCKSIZE {
            memcpy(data_pointer, scratch_space.data, remaining);
        } else {
            memcpy(data_pointer, scratch_space.data, FS_BLOCKSIZE);
        }
    }

    return min(count, blocks_to_read * FS_BLOCKSIZE);
}

using filesystem_cache;

#scope_export

Entry_Loc :: struct {
    directory_block: int;
    directory_index: int;
}

parse_path :: (path_string: string) -> [..] string {
    path: [..] string;

    if path_string.count {
        length: int = 1;
        for cast([] u8) path_string {
            if it == #char "/" {
                new: string;
                new.data = path_string.data + it_index - length + 1;
                new.count = length - 1;
                array_add(*path, new);
                length = 0;
            }
            length += 1;
        }

        new: string;
        new.data = path_string.data + path_string.count - length + 1;
        new.count = length - 1;
        array_add(*path, new);
    }

    return path;
}

find_entry :: (path: [] string) -> Entry_Loc, bool {
    loc: Entry_Loc = .{
        directory_block = 0,
        directory_index = 0,
    };

    block_storage := alloc(FS_BLOCKSIZE);
    current_entry_storage := alloc(FS_BLOCKSIZE);

    defer free(block_storage);
    defer free(current_entry_storage);

    for step: path {
        assert(step.count < 32);

        read_block(loc.directory_block, current_entry_storage, fs_user_data);
        current_entry := cast(*Directory_Entry) current_entry_storage + loc.directory_index;

        if it_index != path.count - 1 {
            if ~current_entry.flags & .DIRECTORY return loc, false;
        }

        assert(current_entry.extents[0].block_count > 0);

        block_index := current_entry.extents[0].block_index;
        read_block(block_index, block_storage, fs_user_data);

        entries := cast(*Directory_Entry) block_storage;
        for 0..current_entry.directory_entry_count - 1 {
            entry := entries[it];

            if step.count == c_style_strlen(entry.name.data) {
                if !memcmp(step.data, entry.name.data, step.count) {
                    loc.directory_block = block_index;
                    loc.directory_index = it;
                    continue step;
                }
            }
        }

        return loc, false;
    }

    return loc, true;
}

create_entry :: (path_string: string, directory: bool) -> bool {
    for *filesystem_cache.array {
        write_block(it_index, xx it, fs_user_data);
    }

    path := parse_path(path_string);
    assert(path.count > 0);

    name := path[path.count - 1];
    path.count -= 1;

    entry_loc, success := find_entry(path);
    if !success return false;

    block := cast(*Directory_Entry) alloc(FS_BLOCKSIZE);
    defer free(block);

    now := get_time(fs_user_data);
    dir_block_index, new_entry_index: int;
    {
        read\      _block(entry_loc.directory_block, xx block, fs_user_data);
        defer write_block(entry_loc.directory_block, xx block, fs_user_data);

        entry := block + entry_loc.directory_index;
        dir_block_index = entry.extents[0].block_index;
        new_entry_index = entry.directory_entry_count;

        entry.directory_entry_count += 1;
        entry.modified = now;
    }

    {
        read\      _block(dir_block_index, xx block, fs_user_data);
        defer write_block(dir_block_index, xx block, fs_user_data);

        new_entry := block + new_entry_index;
        << new_entry = .{};

        if directory {
            new_entry.flags |= .DIRECTORY;
            maybe_create_or_grow_extent(*new_entry.extents[0], FS_BLOCKSIZE);
        }

        assert(name.count < 32);
        memcpy(new_entry.name.data, name.data, name.count);
        new_entry.created = now;
        new_entry.modified = now;
    }

    for *filesystem_cache.array {
        read_block(it_index, xx it, fs_user_data);
    }

    return true;
}



Disk_Block :: [FS_BLOCKSIZE] u8;

filesystem_cache: struct {
    master: Master_Block;
    bitmap: Bitmap_Block;
    root:   Directory_Block;

#place master;
    array: [3] Disk_Block;
} #align FS_BLOCKSIZE;

FS_BASE_ADDRESS :: 0x100_000;
FS_BLOCKSIZE :: 4096;

fs_user_data: *void;

read_extent: (block_index: int, block_count: int, buffer: *void, user: *void);
read_block: (block_index: int, block: *Disk_Block, user: *void);
write_block: (block_index: int, block: *Disk_Block, user: *void);
get_time: (user: *void) -> Apollo_Time;

create_file :: (name: string) {
    create_entry(name, false);
}

write_file :: (path: string, data: [] u8) {
    for *filesystem_cache.array {
        write_block(it_index, xx it, fs_user_data);
    }

    loc, success := find_entry(parse_path(path));
    assert(success);

    block := alloc(FS_BLOCKSIZE);
    read_block(loc.directory_block, block, fs_user_data);

    dir_entry := cast(*Directory_Entry) block + loc.directory_index;
    if dir_entry.flags & .DIRECTORY return;

    remaining := data.count;
    for *dir_entry.extents {
        maybe_create_or_grow_extent(it, remaining);

        data_pointer := data.data + (data.count - remaining);
        remaining = write_data_to_extent(<< it, data_pointer, remaining);

        if remaining <= 0 break;
    }

    dir_entry.modified = get_time(fs_user_data);
    dir_entry.file_size = data.count;

    write_block(loc.directory_block, block, fs_user_data);
    for *filesystem_cache.array {
        read_block(it_index, xx it, fs_user_data);
    }
    free(block);
}

read_file :: (path: string) -> [] u8 {
    for *filesystem_cache.array {
        write_block(it_index, xx it, fs_user_data);
    }

    loc, success := find_entry(parse_path(path));
    if !success return .[];

    block := alloc(FS_BLOCKSIZE);
    read_block(loc.directory_block, block, fs_user_data);

    dir_entry := cast(*Directory_Entry) block + loc.directory_index;
    if dir_entry.flags & .DIRECTORY return .[];

    data := alloc(dir_entry.file_size);
    remaining := dir_entry.file_size;

    cursor: int;
    for dir_entry.extents {
        read := read_data_from_extent(it, data + cursor, remaining);
        cursor += read;
        remaining -= read;

        if remaining == 0 break;
        assert(remaining > 0);
    }

    result: [] u8;
    result.data = data;
    result.count = dir_entry.file_size;

    free(block);
    for *filesystem_cache.array {
        read_block(it_index, xx it, fs_user_data);
    }
    return result;
}

Directory_Entry_Info :: struct {
    name: string;
    created: Apollo_Time;
    modified: Apollo_Time;
    type: enum { DIR; FILE; }
    file_size_or_entry_count_if_directory: int;
}

list_directory :: (path: string) -> [] Directory_Entry_Info {
    for *filesystem_cache.array {
        write_block(it_index, xx it, fs_user_data);
    }

    block := cast(*Directory_Entry) alloc(FS_BLOCKSIZE);
    defer free(block);

    entry_loc, success := find_entry(parse_path(path));
    assert(success);

    read_block(entry_loc.directory_block, xx block, fs_user_data);

    entry := block + entry_loc.directory_index;
    if !entry.extents[0].block_count return .[];

    directory := cast(*Directory_Entry) alloc(FS_BLOCKSIZE);
    defer free(directory);
    read_block(entry.extents[0].block_index, xx directory, fs_user_data);

    result: [..] Directory_Entry_Info;
    for 0..entry.directory_entry_count - 1 {
        sub_entry := directory + it;

        info := array_add(*result);
        info.name.count = c_style_strlen(sub_entry.name.data);
        info.name.data = sub_entry.name.data;
        info.name = copy_string(info.name);

        info.modified = sub_entry.modified;
        info.created = sub_entry.created;

        info.file_size_or_entry_count_if_directory = sub_entry.file_size;
        if sub_entry.flags & .DIRECTORY  info.type = .DIR;
        else info.type = .FILE;
    }

    return result;
}

get_root :: () -> *Directory_Entry {
    return *filesystem_cache.master.root;
}

flush_filesystem :: () {
    for *filesystem_cache.array {
        write_block(it_index, xx it, fs_user_data);
    }
}

MAGIC :: #run -> u64 {
    result: u64;
    for cast([] u8) "Theos FS"  result |= (cast(u64) it) << (it_index * 8);
    return result;
}

format_filesystem :: (name: string) -> bool {
    for *filesystem_cache.array {
        read_block(it_index, xx it, fs_user_data);
        memset(it, 0, FS_BLOCKSIZE);
    }

    master.magic = MAGIC;
    master.version = 1;
    if name.count > 64 return false;
    memcpy(master.root.name.data, name.data, name.count);
    master.root.flags = .DIRECTORY;

    fs_bit_array.slots.data = xx *filesystem_cache.bitmap;
    fs_bit_array.slots.count = FS_BLOCKSIZE / size_of(s64);
    fs_bit_array.count = FS_BLOCKSIZE * 8;

    for 0..2 {
        set_bit(*fs_bit_array, it);
    }
    master.root.extents[0].block_index = 2;
    master.root.extents[0].block_count = 1;

    for *filesystem_cache.array {
        write_block(it_index, xx it, fs_user_data);
    }
    return true;
}

initialize_filesystem :: () -> bool {
    for *filesystem_cache.array {
        read_block(it_index, xx it, fs_user_data);
    }

    fs_bit_array.slots.data = xx *filesystem_cache.bitmap;
    fs_bit_array.slots.count = FS_BLOCKSIZE / size_of(s64);
    fs_bit_array.count = FS_BLOCKSIZE * 8;

    if filesystem_cache.master.version != 1 return false;
    if filesystem_cache.master.magic != MAGIC return false;

    return true;
}





































#scope_module
    
String :: union {
    bytes: [32] u8;
    extent: Extent;
}

File_Type :: struct {
    name: String;
    vendor: String;
    extension: [8] u8;

    flags: Flags;
    Flags :: enum_flags u8 {
        ASCII;
        UTF_8;
        BINARY;
        EXECUTABLE;
        LONG_NAME;
        LONG_VENDOR;
    }
}

File_Type_Template :: struct {
    name: string;
    vendor: string;
    extension: string;
    flags: File_Type.Flags;
}

built_in_filetypes :: File_Type_Template.[
    File_Type_Template.{
        name = "Portable Pixmap",
        vendor = "Netpbm Project",
        extension = "ppm",
        flags = .BINARY,
    },

    File_Type_Template.{
        name = "Portable Graymap",
        vendor = "Netpbm Project",
        extension = "pgm",
        flags = .BINARY,
    },

    File_Type_Template.{
        name = "Plain Text",
        vendor = "",
        extension = "txt",
        flags = .UTF_8,
    },

    File_Type_Template.{
        name = "Efficiently Updateable Neural Network",
        vendor = "Yu Nasu",
        extension = "nnue",
        flags = .BINARY,
    },

    File_Type_Template.{
        name = "Theos Theme",
        vendor = "Theos",
        extension = "theome",
        flags = .BINARY,
    },

    File_Type_Template.{
        name = "Theos Executable",
        vendor = "Theos",
        extension = "thexec",
        flags = .BINARY,
    },
];

