
#import "Formosa";
#import "Formosa_Utilities";

#import "Basic";
#import "Machine_X64";
Compiler :: #import "Compiler";

main :: () {
    builder: String_Builder;

    attr: [..] Rich_Text.Attribute;
    array_reserve(*attr, 300);

    theme := get_theme();

    // add_text("\n%\n\n", TITLE, color = theme.primary);
    add_text("Formosa v0.0.0", color = theme.highlight);
    add_text(" - Hello, sailor\n\n");

    time := formosa_get_time();
    calendar := formosa_apollo_to_calendar(<< cast(*Apollo_Time) *time);
    add_text("The time is %.\n", calendar_to_string(calendar));

    add_text("There are % files in the root directory.\n\n", list_directory("").count);

    cpu := get_cpu_info();

    ti := type_info(x86_Feature_Flag);
    add_text("Supported CPU features: -------------------------------------------");
    flags_on_this_line: int;
    for 0..ti.names.count-1 {
        if check_feature(cpu.feature_leaves, xx ti.values[it]) {
            name := ti.names[it];
            if name.count >= 8 continue;

            if (flags_on_this_line % 7) == 0 add_text("\n");

            add_text("| ");
            add_text(name, color = theme.highlight);
            for 1..8 - name.count  add_text(" ");
            flags_on_this_line += 1;
        }
    }
    add_text("\n-------------------------------------------------------------------\n");

    add_text("Compiled using ", color = theme.primary);
    add_text("Jai %", #run Compiler.compiler_get_version_info(null), color = theme.accent);
    add_text(".\n");
    // print_stack_trace();

    rich: Rich_Text;
    rich.text = builder_to_string(*builder);
    rich.attributes = attr;

    output(rich);

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
