
#import "Basic";
#import "Formosa";
#import "Machine_X64";

main :: () {
    message: string;
    in := input();
    if !in.value_pointer {
        write_string("There is no input :(\n");
        return;
    }

    if in.type.type == .STRUCT {
        if (cast(*Type_Info_Struct) in.type).name == "Rich_Text" {
            message = (cast(*Rich_Text) in.value_pointer).text;
        } else message = tprint("%\n", in);
    } else message = tprint("%\n", in);

    rich_text: Rich_Text;
    rich_text.text = message;

    attr: [..] Rich_Text.Attribute;
    array_reserve(*attr, message.count);

    for cast([] u8) message {
        new := array_add(*attr);
        new.start_position = it_index;
        new.color = xx rdtsc();
    }

    rich_text.attributes = attr;

    output(rich_text);
}
