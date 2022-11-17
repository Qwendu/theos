
#import "Formosa";
#import "Formosa_Utilities";
#import "Basic";

main :: (left: string, right: string) {
    input_data := input();
    if !input_data.value_pointer {
        write_string("No valid input :(\n");
        return;
    }

    struct_offset: int = -1;
    array_stride: int;

    field_type_info: *Type_Info;

    if input_data.type.type == .ARRAY {
        info_array := cast(*Type_Info_Array) input_data.type;
        if info_array.element_type.type == .STRUCT {
            info_struct := cast(*Type_Info_Struct) info_array.element_type;

            array_stride = info_struct.runtime_size;
            for info_struct.members {
                if it.name == left {
                    field_type_info = it.type;
                    struct_offset = it.offset_in_bytes;
                    break;
                }
            }
            if struct_offset == -1 return;

        } else {
            write_string("No valid input :(\n");
            return;
        }
    } else {
        write_string("No valid input :(\n");
        return;
    }

    array := cast(*[] void) input_data.value_pointer;

    result: [] void;
    result_data := map_memory(array.count * array_stride);
    result.data = result_data;

    for 0..array.count - 1 {
        element := array.data + it * array_stride;
        field := element + struct_offset;

        any: Any;
        any.type = field_type_info;
        any.value_pointer = field;
        value := tprint("%", any);

        if value == right {
            memcpy(result.data + result.count * array_stride, element, array_stride);
            result.count += 1;
        }
    }

    any: Any = result;
    any.type = input_data.type;
    output(any);
}

/* functions I need:

get_field
for array

*/
