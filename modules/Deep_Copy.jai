
//
// @Incomplete: I am not sure what the policy should be here when we get an Any?
// For now, we don't copy it.
//

//
// @Incomplete: Probably we need to handle pointers into the middle
// of already-allocated blocks. The yucky situation happens when we
// hit a pointer into the middle of said block first (or many pointers
// into the middle, like a bunch of strings) and then realize later
// they are part of a big shared block. This seems complex enough
// that maybe it should be a more-general-case, slower routine.
// I dunno man. That said the simplicity of Just Handling It is
// appealing, so if it's not much slower, maybe we just do it here.
//
// As an interim approach, we could handle such cases with explicit
// markup by the user, but this is error-prone and annoying...
//
//             -jblow, 31 October 2017
//

#scope_file

#import "Hash_Table";
#import "Hash";

#scope_export

helper_count := 0;
time_total: float64;

DC_DEBUG :: false;

#if DC_DEBUG {
    indent := 0;
}


Deep_Copy :: (value: *void, info: *Type_Info, follow_struct_pointers := true, preallocated_root: *void = null, pointer_map: *Pointer_Map = null, loc := #caller_location) -> *void {
    if !value  return null;

    result := preallocated_root;
    if !result  result = alloc(info.runtime_size);
    memcpy(result, value, info.runtime_size);

    local_pointer_map: Pointer_Map;
    defer uninit(*local_pointer_map.table);

    if !pointer_map  pointer_map = *local_pointer_map;
    
    old_count := helper_count;

    Copy_Helper(result, info, pointer_map, follow_struct_pointers);
    
    return result;
}

Pointer_Map :: struct {
    table: Table(*void, *void);
}


#scope_file

#import "Basic";

/*
Pointer_Pair :: struct {
    old: *void;
    new: *void;
}
*/

could_need_allocation :: (info: *Type_Info) -> bool {
    //
    // @Speed: This only looks at the top-level item.
    // We could, if it's a struct, recurse to see if it is a Vector3 or
    // something, which may need copying.
    // Alternatively, if we think this is a universal-enough need,
    // we could put a flag for this in the Type_Infos for Struct and Array.
    //                      -jblow, 31 October 2017
    //
    
    if info.type == {
        case Type_Info_Tag.STRING;  return true;
        case Type_Info_Tag.ARRAY;   return true;
        case Type_Info_Tag.POINTER; return true;
        case Type_Info_Tag.STRUCT;  return true;
        case;                       return false;
    }
}

Copy_Helper :: (data: *void, _info: *Type_Info, pointer_map: *Pointer_Map, follow_struct_pointers: bool, debug_name := "") {
    info := _info;

    // The problem is that info will be the type info of struct "Type_Info", but we want the type info of struct "Type_Info_Struct", or whatever the type tag on the value (which is a Type_Info) is. So just reassign by doing info = cast(*Type_Info) Type_Info_Whatever.
    if info.type == .STRUCT {
        tis := cast(*Type_Info_Struct) info;
        if tis.name == "Type_Info" {
            type_info_that_is_the_thing_we_are_copying := cast(*Type_Info) data;
            if type_info_that_is_the_thing_we_are_copying.type == {
                case .STRUCT;    info = type_info(Type_Info_Struct);
                case .INTEGER;   info = type_info(Type_Info_Integer);
                case .FLOAT;     info = type_info(Type_Info_Float);
                case .STRING;    info = type_info(Type_Info_String);
                case .POINTER;   info = type_info(Type_Info_Pointer);
                case .PROCEDURE; info = type_info(Type_Info_Procedure);
                case .ARRAY;     info = type_info(Type_Info_Array);
                case .ENUM;      info = type_info(Type_Info_Enum);
                case .VARIANT;   info = type_info(Type_Info_Variant);
            }
        }
    }

    // A large brain is required
    if info.type == .POINTER {
        tip := cast(*Type_Info_Pointer) info;
        if tip.pointer_to.type == .STRUCT {
            tis := cast(*Type_Info_Struct) tip.pointer_to;
            if tis.name == "Type_Info" {
                type_info_that_is_the_thing_we_are_copying := cast(**Type_Info) data;
                if (<< type_info_that_is_the_thing_we_are_copying).type == {
                    case .STRUCT;    info = type_info(*Type_Info_Struct);
                    case .INTEGER;   info = type_info(*Type_Info_Integer);
                    case .FLOAT;     info = type_info(*Type_Info_Float);
                    case .STRING;    info = type_info(*Type_Info_String);
                    case .POINTER;   info = type_info(*Type_Info_Pointer);
                    case .PROCEDURE; info = type_info(*Type_Info_Procedure);
                    case .ARRAY;     info = type_info(*Type_Info_Array);
                    case .ENUM;      info = type_info(*Type_Info_Enum);
                    case .VARIANT;   info = type_info(*Type_Info_Variant);
                }
            }
        }
    }

    helper_count += 1;
    if info.type == {
        case .STRING;
            s := cast(*string) data;
            if !s.data  return;  // Already copied!

            mapped := find(pointer_map, s.data);
            if mapped  return;  // Already copied!

            t := copy_string(<< s);
            add(pointer_map, s.data, t.data);

            << s = t;
        case .ARRAY;
            info_array := cast(*Type_Info_Array) info;
            // if !could_need_allocation(info_array.element_type) return;  // Early out so we don't iterate forever on dumb stuff.

            element_size := info_array.element_type.runtime_size;
            assert(element_size != -1);  // @Robustness @Incomplete: Right now, at compile time, this might fail.

            stride := get_array_stride(element_size);
            if info_array.array_count != -1 {
                // Fixed array.
                element_pointer := data;
                for 0..info_array.array_count-1 {
                    Copy_Helper(element_pointer, info_array.element_type, pointer_map, follow_struct_pointers);
                    element_pointer += stride;
                }
            } else {
                // Dynamic array of one kind or another.
                assert(info_array.relative_pointer_size == 0);  // @Incomplete: Relative pointer arrays not yet handled.

                count := << cast(*s64) data;

                array_dest: **void = data + 8;
                allocated_dest: *s64;
                if info_array.array_type == .RESIZABLE {
                    allocated_dest = data + 16;
                }

                array_data := << cast(**void) array_dest;
                if array_data == null  return;  // Already copied!

                mapped := find(pointer_map, array_data);
                if mapped {
                    << array_dest = mapped;
                } else {
                    bytes := stride * count;
                    new_array_data := alloc(bytes);
                    << array_dest = new_array_data;
                    if allocated_dest { << allocated_dest = count; }
                    
                    add(pointer_map, array_data, new_array_data);

                    memcpy(new_array_data, array_data, bytes);
                    element_pointer := new_array_data;
                    for 0..count-1 {
                        Copy_Helper(element_pointer, info_array.element_type, pointer_map, follow_struct_pointers);
                        element_pointer += stride;
                    }
                }
            }
        case .POINTER;
            info_pointer := cast(*Type_Info_Pointer) info;
            assert(info_pointer.relative_pointer_size == 0);  // @Incomplete: Relative pointers not yet handled.

            dest := cast(**void) data;
            old_value_pointer := << dest;
            if old_value_pointer == null  return;  // Already copied.

            mapped := find(pointer_map, old_value_pointer);
            if mapped {
                << dest = mapped;
            } else {
                element_size := info_pointer.pointer_to.runtime_size;
                assert(element_size != -1);  // @Robustness @Incomplete: Right now, at compile time, this might fail.

                new_value_pointer := alloc(element_size);
                memcpy(new_value_pointer, old_value_pointer, element_size);
                add(pointer_map, old_value_pointer, new_value_pointer);

                << dest = new_value_pointer;

                to_type := info_pointer.pointer_to.type;
                if follow_struct_pointers || (to_type != .STRUCT) {
                    Copy_Helper(new_value_pointer, info_pointer.pointer_to, pointer_map, follow_struct_pointers);
                }
            }
        case .STRUCT;
            info_struct := cast(*Type_Info_Struct) info;

            for member: info_struct.members {
                if member.flags & .CONSTANT  continue;
                if !could_need_allocation(member.type) continue;

                if member.notes {
                    for note: member.notes  if note == "NoDeepCopy" continue member;
                }

                offset := member.offset_in_bytes;
                assert(offset != -1);

                if offset == 0 && member.name == "info" continue; // This means it might be the type info that we're already in. Check this more narrowly

                Copy_Helper(data + offset, member.type, pointer_map, follow_struct_pointers, debug_name=member.name);
            }
    }
}

get_array_stride :: (size: s64) -> s64 {
    // We assume 8-byte alignment for now.

    return (size + 7) & ~7;
}


find :: (map: *Pointer_Map, old: *void) -> *void {
    value, found := table_find(map.table, old);
    if !found return null;
    return value;
}

add :: (map: *Pointer_Map, old: *void, new: *void) {
    // Assumes you already searched and did not find this pointer.
    table_add(*map.table, old, new);
}
