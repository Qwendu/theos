
#scope_module

#import "Basic";
#import "Bit_Array";
#import "String";

Constants :: struct {
    info_node_size :: size_of(Info_Node);
    block_size :: FS_BLOCKSIZE;
    info_nodes_per_block :: Constants.block_size / info_node_size;
    directory_entry_size :: size_of(Directory_Entry);
    directory_entries_per_block :: Constants.block_size / directory_entry_size;
}

Extent :: struct {
    block_index: int;
    block_count: int;
}

Info_Node :: struct {
    file_size: int;

    flags: enum_flags u8 {
        DIRECTORY;
        SYSTEM;
        READ_ONLY;
    }
    extents: [4] Extent;

    modified: Apollo_Time;
    created: Apollo_Time;

#place file_size;
    directory_entry_count: int;
}

Directory_Entry :: struct {
    name: [32] u8;

    loc: Info_Node_Loc;

#place name;
    name_extent: Extent;
}

Master_Block :: struct {
    using content: struct {
        root: Info_Node;

        info_node_count: int;

        magic: u64;
        version: int;
        clock_generation: int;
    }
    padding: [Constants.block_size - size_of(type_of(content))] u8;
}

#assert size_of(Master_Block) == Constants.block_size;

scratch_space: [Constants.block_size] u8 #align Constants.block_size;

fs_bit_array: Bit_Array;

// "bytes_required" is the total number of bytes required of this extent and the other extents, not an additional number of bytes, so include the existing file size if appending
maybe_create_or_grow_extent :: (extent: *Extent, bytes_required: int) -> space_created: int {
    blocks_required := (bytes_required + Constants.block_size - 1) / Constants.block_size;

    // Exit if the extent is already big enough
    if blocks_required <= extent.block_count return 0;

    // Create a new extent that's large enough if it doesn't exist
    if extent.block_count == 0 && blocks_required > 0 {
        contiguous_bits_found: int;
        bit: int;

        while true {
            // Find the first long enough run of free disk blocks
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

                return blocks_required * Constants.block_size;
            }
            bit += 1;
        }
    } else {
        // There is an extent, try to grow it as much as needed or possible
        block_index := extent.block_index + extent.block_count;
        new_blocks_required := blocks_required - extent.block_count;

        for 0..new_blocks_required - 1 {
            if fs_bit_array[block_index + it] {
                // If there are not enough free blocks after the end of the extent

                extent.block_count += it;
                return it * Constants.block_size;
            }
            set_bit(*fs_bit_array, block_index + it);
        }

        extent.block_count += new_blocks_required;
        return new_blocks_required * Constants.block_size;
    }

    return 0;
}

write_data_to_extent :: (extent: Extent, data: *u8, count: int) -> remaining: int {
    blocks_required := (count + Constants.block_size - 1) / Constants.block_size;
    blocks_to_write := min(blocks_required, extent.block_count);

    for 0..blocks_to_write - 1 {
        data_pointer := data + it * Constants.block_size;

        location := FS_BASE_ADDRESS + (extent.block_index + it) * Constants.block_size;

        remaining := count - it * Constants.block_size;
        if remaining < Constants.block_size {
            memset(scratch_space.data, 0, Constants.block_size);
            memcpy(scratch_space.data, data_pointer, remaining);
        } else {
            memcpy(scratch_space.data, data_pointer, Constants.block_size);
        }
        write_block(extent.block_index + it, xx scratch_space.data, fs_user_data);
    }

    return count - blocks_to_write * Constants.block_size;
}

read_data_from_extent :: (extent: Extent, data: *u8, count: int) -> read: int {
    blocks_required := (count + Constants.block_size - 1) / Constants.block_size;
    blocks_to_read := min(blocks_required, extent.block_count);

    if read_extent {
        read_extent(extent.block_index, blocks_to_read, data, fs_user_data);
        return min(count, blocks_to_read * Constants.block_size);
    }

    for 0..blocks_to_read - 1 {
        data_pointer := data + it * Constants.block_size;
        location := FS_BASE_ADDRESS + (extent.block_index + it) * Constants.block_size;
        
        read_block(extent.block_index + it, xx scratch_space.data, fs_user_data);
        remaining := count - it * Constants.block_size;
        
        if remaining < Constants.block_size {
            memcpy(data_pointer, scratch_space.data, remaining);
        } else {
            memcpy(data_pointer, scratch_space.data, Constants.block_size);
        }
    }

    return min(count, blocks_to_read * Constants.block_size);
}

using filesystem_cache;

#scope_export

Info_Node_Loc :: struct {
    block: int;
    index: int;
}

parse_path :: (_path_string: string) -> [..] string {
    path_string := _path_string;
    path: [..] string;

    if starts_with(path_string, "./") {
        path_string.count -= 2;
        path_string.data += 2;
    }

    if path_string.count {
        length: int = 1;
        for cast([] u8) path_string {
            assert(it != #char "\\", "Nah");

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

find_info_node :: (path: [] string) -> Info_Node_Loc, bool {
    loc: Info_Node_Loc = .{ // Start by pointing to the info node of the root directory
        block = 0,
        index = 0,
    };

    block_storage := alloc(Constants.block_size);
    current_info_node_block := alloc(Constants.block_size);

    defer free(block_storage);
    defer free(current_info_node_block);

    for step: path {
        assert(step.count < 32, tprint("File name too long: % > 32, in the future arbitrary length filenames will be supported", step));
        // Read the directory blocks of the current info node and iterate them to find the next directory info node
        read_block(loc.block, current_info_node_block, fs_user_data);
        current_info_node := cast(*Info_Node) current_info_node_block + loc.index;

        // If we are not at the end of the path and the current info node is not for a directory, fail
        if it_index != path.count - 1 {
            if ~current_info_node.flags & .DIRECTORY {
                return loc, false;
            }
        }

        dir_block_count := current_info_node.extents[0].block_count;
        assert(dir_block_count > current_info_node.directory_entry_count / Constants.directory_entries_per_block);

        directories_left := current_info_node.directory_entry_count;

        // Read the directory blocks of the current info node
        for 0..dir_block_count-1 {
            block_index := current_info_node.extents[0].block_index + it;
            read_block(block_index, block_storage, fs_user_data);

            entries := cast(*Directory_Entry) block_storage;
            for 0..min(Constants.directory_entries_per_block, directories_left) - 1 {
                entry := entries[it];

                if step.count == c_style_strlen(entry.name.data) {
                    if memcmp(step.data, entry.name.data, step.count) == 0 {
                        loc = entry.loc;
                        continue step;
                    }
                }
            }

            directories_left -= Constants.directory_entries_per_block;
        }

        // We did not find the item in this folder
        return loc, false;
    }

    return loc, true;
}

create_item :: (path_string: string, directory: bool) -> Filesystem_Result {
    defer flush_filesystem();

    path := parse_path(path_string);
    if path.count == 0 {
        return .invalid_name;
    }

    {
        existing_loc, existing_success := find_info_node(path);
        if existing_success return .item_already_exists;
    }

    name := path[path.count - 1];
    path.count -= 1;

    parent_info_loc, success := find_info_node(path);
    if !success return .item_doesnt_exist;

    block := cast(*Info_Node) alloc(Constants.block_size);
    defer free(block);

    now := get_timestamp(fs_user_data);
    dir_block_index, new_entry_index: int;
    {
        read_block(parent_info_loc.block, xx block, fs_user_data);

        parent_info_node := block + parent_info_loc.index;

        if !(parent_info_node.flags & .DIRECTORY) {
            return .item_is_wrong_kind;
        }

        bytes_required := parent_info_node.directory_entry_count * Constants.directory_entry_size;
        maybe_create_or_grow_extent(*parent_info_node.extents[0], bytes_required);

        extra_blocks_required := parent_info_node.directory_entry_count / Constants.directory_entries_per_block;

        assert(parent_info_node.extents[0].block_count > extra_blocks_required, "Could not grow directory %, must allocate a new extent, not implemented. Entry count is % block count is %", path, parent_info_node.directory_entry_count, parent_info_node.extents[0].block_count);

        dir_block_index = parent_info_node.extents[0].block_index + extra_blocks_required;
        new_entry_index = parent_info_node.directory_entry_count % Constants.directory_entries_per_block;

        parent_info_node.directory_entry_count += 1;
        parent_info_node.modified = now;

        write_block(parent_info_loc.block, xx block, fs_user_data);
    }

    {
        read_block(dir_block_index, xx block, fs_user_data);

        new_entry := cast(*Directory_Entry) block + new_entry_index;
        << new_entry = .{};

        assert(name.count < 32, tprint("File name too long: % > 32, in the future arbitrary length filenames will be supported", name));
        memcpy(new_entry.name.data, name.data, name.count);

        new_node_block := cast(*Info_Node) alloc(Constants.block_size);
        new_node_loc := allocate_info_node();

        read_block(new_node_loc.block, xx new_node_block, fs_user_data);
        new_node := new_node_block + new_node_loc.index;

        new_node.created = now;
        new_node.modified = now;

        new_entry.loc = new_node_loc;

        new_node.extents[0] = .{};

        if directory {
            new_node.flags |= .DIRECTORY;
            maybe_create_or_grow_extent(*new_node.extents[0], Constants.block_size * 4);
        }

        write_block(dir_block_index, xx block, fs_user_data);
        write_block(new_node_loc.block, xx new_node_block, fs_user_data);

        free(new_node_block);
    }

    return .success;
}

allocate_info_node :: () -> Info_Node_Loc {
    master_block: *Master_Block = alloc(Constants.block_size);
    defer free(master_block);

    read_block(0, xx master_block, fs_user_data);
    defer write_block(0, xx master_block, fs_user_data);

    defer read_block(0, xx *filesystem_cache.master, fs_user_data);

    count := master_block.info_node_count;
    loc: Info_Node_Loc;
    loc.block = 4 + count / Constants.info_nodes_per_block;
    assert(loc.block <= 11, "Not enough room for info nodes");
    loc.index = count % Constants.info_nodes_per_block;

    master_block.info_node_count += 1;

    return loc;
}

Disk_Block :: [Constants.block_size] u8;

filesystem_cache: struct {
    master: Master_Block;
    bitmap: Disk_Block;
    root:   Disk_Block;

#place master;
    array: [3] Disk_Block;
} #align Constants.block_size;

FS_BASE_ADDRESS :: 0x200_000;
FS_BLOCKSIZE :: 4096;

fs_user_data: *User_Datatype;

#module_parameters (User_Datatype := void);

read_extent: (block_index: int, block_count: int, buffer: *void, user: *User_Datatype);
read_block: (block_index: int, block: *Disk_Block, user: *User_Datatype);
write_block: (block_index: int, block: *Disk_Block, user: *User_Datatype);
get_timestamp: (user: *User_Datatype) -> Apollo_Time;

Filesystem_Result :: enum s64 {
    success :: 0;
    item_doesnt_exist :: 1;
    item_already_exists :: 2;
    invalid_name :: 3;
    item_is_wrong_kind :: 4;
}

create_file :: (name: string) -> Filesystem_Result {
    return create_item(name, false);
}

write_file :: (path: string, data: [] u8) -> Filesystem_Result {
    defer flush_filesystem();

    loc, success := find_info_node(parse_path(path));
    if !success return .item_doesnt_exist;

    block := alloc(FS_BLOCKSIZE);
    read_block(loc.block, block, fs_user_data);

    parent_info_node := cast(*Info_Node) block + loc.index;
    if parent_info_node.flags & .DIRECTORY return .item_is_wrong_kind;

    remaining := data.count;
    for *parent_info_node.extents {
        maybe_create_or_grow_extent(it, remaining);

        data_pointer := data.data + (data.count - remaining);
        remaining = write_data_to_extent(<< it, data_pointer, remaining);

        if remaining <= 0 break;
    }

    parent_info_node.modified = get_timestamp(fs_user_data);
    parent_info_node.file_size = data.count;

    write_block(loc.block, block, fs_user_data);
    free(block);

    return .success;
}

read_file :: (path: string) -> [] u8, Filesystem_Result {
    defer flush_filesystem();

    loc, success := find_info_node(parse_path(path));
    if !success return .[], .item_doesnt_exist;

    block := alloc(FS_BLOCKSIZE);
    read_block(loc.block, block, fs_user_data);

    info_node := cast(*Info_Node) block + loc.index;
    if info_node.flags & .DIRECTORY return .[], .item_is_wrong_kind;

    data := alloc(info_node.file_size);
    remaining := info_node.file_size;

    cursor: int;
    for info_node.extents {
        read := read_data_from_extent(it, data + cursor, remaining);
        cursor += read;
        remaining -= read;

        if remaining == 0 break;
        assert(remaining > 0);
    }

    result: [] u8;
    result.data = data;
    result.count = info_node.file_size;

    free(block);
    return result, .success;
}

File_Status :: struct {
    name: string;
    type: enum { DIR; FILE; }
    file_size: int;
    directory_entry_count: int;
    created: Apollo_Time;
    modified: Apollo_Time;
}

list_directory :: (path: string) -> [] File_Status, Filesystem_Result {
    defer flush_filesystem();

    block := cast(*Info_Node) alloc(FS_BLOCKSIZE);
    defer free(block);

    loc, success := find_info_node(parse_path(path));
    if !success return .[], .item_doesnt_exist;

    read_block(loc.block, xx block, fs_user_data);

    info_node := block + loc.index;
    if !(info_node.flags & .DIRECTORY)  return .[], .item_is_wrong_kind;
    if !info_node.extents[0].block_count return .[], .success;

    directory_block := cast(*Directory_Entry) alloc(FS_BLOCKSIZE);
    defer free(directory_block);

    current_file_block := cast(*Info_Node) alloc(FS_BLOCKSIZE);
    defer free(current_file_block);

    directories_left := info_node.directory_entry_count;
    result: [..] File_Status;

    for 0..info_node.extents[0].block_count - 1 {
        read_block(info_node.extents[0].block_index + it, xx directory_block, fs_user_data);

        for 0..min(Constants.directory_entries_per_block, directories_left) - 1 {
            entry := directory_block + it;
            name: string;
            name.count = c_style_strlen(entry.name.data);
            name.data = entry.name.data;

            read_block(entry.loc.block, xx current_file_block, fs_user_data);
            node := current_file_block + entry.loc.index;

            status := array_add(*result);
            status.name = copy_string(name);
            status.modified = node.modified;
            status.created = node.created;

            if node.flags & .DIRECTORY {
                status.type = .DIR;
                status.directory_entry_count = node.directory_entry_count;
            } else {
                status.type = .FILE;
                status.file_size = node.file_size;
            }
        }

        directories_left -= Constants.directory_entries_per_block;
    }

    return result, .success;
}

get_root :: () -> *Info_Node {
    return *filesystem_cache.master.root;
}

flush_filesystem :: () {
//    write_block(0, xx *filesystem_cache.master, fs_user_data);
    write_block(1, xx *filesystem_cache.bitmap, fs_user_data);
}

MAGIC :: #run -> u64 {
    result: u64;
    for cast([] u8) "Formosa FS"  result |= (cast(u64) it) << (it_index * 8);
    return result;
}

format_filesystem :: () -> bool {
    for *filesystem_cache.array {
        memset(it, 0, FS_BLOCKSIZE);
    }

    master.magic = MAGIC;
    master.version = 1;
    master.root.flags = .DIRECTORY;

    fs_bit_array.slots.data = xx *filesystem_cache.bitmap;
    fs_bit_array.slots.count = FS_BLOCKSIZE / size_of(s64);
    fs_bit_array.count = FS_BLOCKSIZE * 8;

    // Blocks:
    // | Master | Bitmap | Root directory entries | More root | Inodes | Inodes | Inodes | Inodes | Inodes | Inodes | Inodes | Inodes | ... Rest of the filesystem ...

    for 0..11 {
        set_bit(*fs_bit_array, it);
    }
    master.root.extents[0].block_index = 2;
    master.root.extents[0].block_count = 2;

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
    mime: String;
    extension: [8] u8;

    flags: Flags;
    Flags :: enum_flags u8 {
        ASCII;
        UTF_8;
        BINARY;
        EXECUTABLE;
        LONG_NAME;
        LONG_VENDOR;
        LONG_MIME;
    }
}

File_Type_Template :: struct {
    name: string;
    vendor: string;
    mime: string;
    extension: string;
    flags: File_Type.Flags;
}

built_in_filetypes :: File_Type_Template.[
    File_Type_Template.{
        name = "Portable Pixmap",
        vendor = "Netpbm Project",
        mime = "image/x-portable-pixmap",
        extension = "ppm",
        flags = .BINARY,
    },

    File_Type_Template.{
        name = "Portable Graymap",
        vendor = "Netpbm Project",
        mime = "image/x-portable-graymap",
        extension = "pgm",
        flags = .BINARY,
    },

    File_Type_Template.{
        name = "Plain Text",
        vendor = "",
        mime = "text/plain",
        extension = "txt",
        flags = .UTF_8,
    },

    File_Type_Template.{
        name = "Efficiently Updateable Neural Network",
        vendor = "Yu Nasu",
        mime = "x-nnue",
        extension = "nnue",
        flags = .BINARY,
    },

    File_Type_Template.{
        name = "Formosa Theme",
        vendor = "Formosa",
        extension = "theome",
        flags = .BINARY,
    },

    File_Type_Template.{
        name = "Formosa Executable",
        vendor = "Formosa",
        extension = "thexec",
        flags = .BINARY,
    },
];
