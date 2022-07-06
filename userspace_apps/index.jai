
#import "Theos";

main :: (index: int) {
    input_data := input();

    if !input_data.value_pointer return;
    if input_data.type.type != .ARRAY  return;

    info_array := cast(*Type_Info_Array) input_data.type;
    array_stride := info_array.element_type.runtime_size;

    array := cast(*[] void) input_data.value_pointer;
    if index >= array.count return;

    any: Any;
    any.value_pointer = array.data + index * array_stride;
    any.type = info_array.element_type;
    output(any);
}
