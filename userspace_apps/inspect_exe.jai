
#import "Basic";

#import "Formosa";
#import "Formosa_Utilities";
#import "Formosa_Executable_Format";

main :: (file_name: string) {
    file := read_file(file_name);
    builder: String_Builder;

    attr: [..] Rich_Text.Attribute;
    array_reserve(*attr, 300);

    theme := get_theme();

    defer {
        rich: Rich_Text;
        rich.text = builder_to_string(*builder);
        rich.attributes = attr;

        output(rich);
    }

    if file.count < size_of(Formosa_Exe_Header) {
        add_text("File is not an executable, too small to contain the header\n");
        return;
    }

    header := cast(*Formosa_Exe_Header) file.data;

    if header.magic != FORMOSA_EXE_MAGIC {
        add_text("The magic number is not correct - not a valid executable\n");
        return;
    }

    if header.type == .ELF {
        add_text("This executable contains a fun fun elf file\n");
        return;
    }

    if header.type != .MINIMAL {
        add_text("This is an executable, but I do not understand the sub format (not minimal or elf)\n");
    }

    if file.count < size_of(Formosa_Exe_Header) + size_of(Minimal_Exe_Header) {
        add_text("Invalid - file is too small to contain both the executable header and the sub format header\n");
    }

    minimal := cast(*Minimal_Exe_Header) header.minimal_header;
    add_text("This is indeed a ");
    rainbow := u32.[
            0xd040d0,
            0x4040d0,
            0x40d040,
            0xd0d040,
            0xd0a040,
            0xd04040,
    ];
    for cast([] u8) "Formosa Exe \"Minimal\" file\n\n" {
        s: string;
        s.data = *it;
        s.count = 1;
        add_text("%", s, color = rainbow[it_index % rainbow.count]);
    }

    context.print_style.default_format_struct.use_long_form_if_more_than_this_many_members = 2;
    context.print_style.default_format_struct.use_newlines_if_long_form = true;
    // add_text("The header is: %\n", << minimal);

    context.print_style.default_format_int.base = 16;
    context.print_style.default_format_int.minimum_digits = 2;
    add_text("Here is the code:\n  ");
    for minimal.code_section_in_the_file {
        if it_index && it_index % 8 == 0 add_text("\n  ");
        add_text("\\x");
        add_text("% ", it, color = theme.highlight);
    }

    add_text("\n\nHere is the data:\n  ");
    add_text("00", color = theme.secondary);
    add_text(": ");
    text: string = "........";

    for minimal.data_section_in_the_file {
        if it_index && it_index % 8 == 0 {
            add_text("| ");
            add_text(text, color = theme.accent);
            add_text("\n  %", it_index, color = theme.secondary);
            add_text(": ");
        }

        add_text("% ", it, color = theme.highlight);
        if it >= 32 && it <= 126 {
            text[it_index % 8] = it;
        } else {
            text[it_index % 8] = #char ".";
        }
    }

    text.count = minimal.data_section_in_the_file.count % 8;
    for 0..7 - (minimal.data_section_in_the_file.count % 8) add_text("   ");
    add_text("| ");
    add_text(text, color = theme.accent);
    add_text("\n\n");

    add_text :: (format: string, args: .. Any, color: u32 = xx,no_check -1) #expand {
        _color := color;
        if _color == xx,no_check -1  _color = theme.foreground;

        a: Rich_Text.Attribute;
        a.start_position = builder_string_length(*builder);
        a.color = _color;

        array_add(*attr, a);
        print_to_builder(*builder, format, .. args);
    }
}
