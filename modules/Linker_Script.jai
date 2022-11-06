
#scope_export

Linker_Script :: struct {
    Section :: struct {
        // If consecutive sections are at the same base address, we put them after each other in the same order
        address: u64;
        name: string;
        vm_alignment: int = -1;
    }
    sections: [] Section;
    entry_point_name: string;
}

set_linker_script :: (options: *Build_Options, w: Workspace, script: Linker_Script) {
    make_directory_if_it_does_not_exist(".build");

    code: String_Builder;
    if script.entry_point_name.count {
        print_to_builder(*code, "ENTRY(%)\n\n", script.entry_point_name);
    }

    print_to_builder(*code, "SECTIONS {\n");

    last_address: u64 = xx,no_check -1;
    for script.sections {
        if it.address != last_address {
            print_to_builder(*code, "    . = 0x%;\n", formatInt(it.address, base = 16));
            last_address = it.address;
        }
        print_to_builder(*code, "    .%\t: { * (.%)", it.name, it.name);
        if it.vm_alignment != -1 print_to_builder(*code, " ALIGN(%)", it.vm_alignment);
        print_to_builder(*code, "; }\n");
    }

    print_to_builder(*code, "}\n");

    name := tprint(".build/.link_w%.ld", w);
    write_entire_file(name, builder_to_string(*code));

    free_buffers(*code);

    arguments: [..] string;
    array_add(*arguments, .. options.additional_linker_arguments);
    array_add(*arguments, "-T", name);
    options.additional_linker_arguments = arguments;
}

#scope_module

#import "Compiler";
#import "File";
#import "Basic";
