// 3

entry_point :: #string END

#program_export
_formosa_start :: () #no_context {
    user_context: Context;
    user_context.allocator.proc = allocate_memory;
    user_context.logger = my_log;
    user_context.assertion_failed = assertion_failed;

    push_context user_context {
    }
}

my_log :: (message: string, data: *void, info: Log_Info) {
    Formosa :: #import "Formosa";
    Formosa.write_string(message);
}

allocate_memory :: (mode: Allocator_Mode, size: s64, old_size: s64, old_buffer: *void, user_data: *void) -> *void {
    Formosa :: #import "Formosa";
    if mode == .FREE {
        Formosa.unmap_memory(old_size, xx old_buffer);
        return null;
    }

    if mode == .RESIZE && old_size {
        if size < old_size || size < 4096 {
            return old_buffer;
        }

        new := Formosa.map_memory(size);
        memcpy(new, old_buffer, old_size);
        return new;
    }

    return Formosa.map_memory(size);
}

assertion_failed :: (location: Source_Code_Location, message: string) {
    Formosa :: #import "Formosa";
    #import "Formosa_Utilities";

    Formosa.write_string("\nAssertion failure!\n  -> ");
    Formosa.write_string(location.fully_pathed_filename);
    Formosa.write_string(":");
    write_int(location.line_number);

    if message.count {
        Formosa.write_string("\n     ");
        Formosa.write_string(message);
    }
    Formosa.write_string("\n\n");
    Formosa.repaint();

    while true {
        #asm { hlt; }
    }
}

END;

build_formosa_app :: (name: string) {
/*    set_build_options_dc(.{do_output = false});

    user_args, compiler_args := get_build_options().compile_time_command_line;
    if !user_args.count assert(false);
    name := user_args[0];
*/

    program_parameters: [..] *Code_Declaration;
    print("\n=== Compiling User Application \"%\" ===\n", name);
    {
        w := compiler_create_workspace("Formosa User Application");
        options := get_build_options(w);
        options.output_executable_name = name;
        options.intermediate_path = ".build/";
        options.output_path = ".build/userspace_apps/";
        options.output_type = .EXECUTABLE;
        options.entry_point_name = "_formosa_start";

        #if !ENABLE_IST options.disable_redzone = true;

        options.stack_trace = false;
        options.array_bounds_check = .OFF;
        options.cast\_bounds_check = .OFF;
        options.math\_bounds_check = .OFF;
        options.null_pointer_check = .OFF;
        options.dead_code_elimination = .NONE;

        options.text_output_flags = 0;

        new_path: [..] string;
        array_add(*new_path, "modules/");
        array_add(*new_path, ..options.import_path);
        options.import_path = new_path;

        options.additional_linker_arguments = .["-e", "_formosa_start"];

        set_build_options(options, w);

        compiler_begin_intercept(w);
        add_build_file(tprint("userspace_apps/%.jai", name), w);

        while true {
            message := compiler_wait_for_message();

            if message.kind == .COMPLETE {
                complete := cast(*Message_Complete) message;
                if complete.error_code == .COMPILATION_FAILED return;
                break;
            }

            if message.kind == .TYPECHECKED {
                typechecked := cast(*Message_Typechecked) message;

                for typechecked.procedure_headers {
                    expr := it.expression;
                    if expr.name == "main" {
                        for expr.arguments {
                            array_add(*program_parameters, it);
                        }

                        add_build_string(entry_point, w);
                    }
                }

                for typechecked.procedure_bodies {
                    body := it.expression;
                    if body.header.name == "_formosa_start" for body.block.statements {
                        if body.body_flags & .ALREADY_MODIFIED break;

                        if it.kind == .PUSH_CONTEXT {
                            pc := cast(*Code_Push_Context) it;

                            new_statements: [..] *Code_Node;

                            ident_main := New(Code_Ident);
                            ident_main.name = "main";

                            call := New(Code_Procedure_Call);
                            call.kind = .PROCEDURE_CALL;
                            call.procedure_expression = ident_main;

                            array := NewArray(program_parameters.count, *Code_Node);

                            current_offset: int;
                            for * array {
                                value := PROGRAM_PARAMETER_BASE_ADDRESS + current_offset;
                                lit := make_integer_literal(value);

                                inst := New(Code_Type_Instantiation);
                                inst.kind = .TYPE_INSTANTIATION;
                                inst.pointer_to = program_parameters[it_index].type_inst;

                                _cast := New(Code_Cast);
                                _cast.kind = .CAST;
                                _cast.target_type = inst;
                                _cast.expression = lit;

                                deref := New(Code_Unary_Operator);
                                deref.kind = .UNARY_OPERATOR;
                                deref.operator_type = xx Operator_Type.POINTER_DEREFERENCE;
                                deref.subexpression = _cast;

                                current_offset += program_parameters[it_index].type_inst.result.runtime_size;

                                << it = deref;
                            }

                            call.arguments_sorted = array;
                            call.arguments_unsorted = NewArray(program_parameters.count, Code_Argument);
                            for *call.arguments_unsorted {
                                it.expression = array[it_index];
                            }

                            array_add(*new_statements, call);

                            for pc.block.statements   array_add(*new_statements, it);
                            pc.block.statements = new_statements;

                            compiler_modify_procedure(w, body);
                        }
                    }
                }
            }
        }
        compiler_end_intercept(w);
    }

    elf, success := read_entire_file(tprint(".build/userspace_apps/%", name));
    assert(success);

    objdump_command := tprint("objdump -x .build/userspace_apps/% -d -M intel --source", name);
    yes, error_code, stdout, stderr := shell(objdump_command, print_output = false);
    if !yes || error_code != 0 {
        write_string("objdump failed to run! (continuing)\n");
    }
    else write_entire_file(tprint(".build/%_elf.objdump.txt", name), stdout);

    write_string("\n=== Patching ELF ===\n");
    {
        patches := Plt_Patch.[
                .{source = "crt_memset", target = "memset"},
                .{source = "crt_memcpy", target = "memcpy"},
                .{source = "crt_memcmp", target = "memcmp"},
        ];

        patch_procedure_linkage_table(cast([] u8) elf, patches);
    }

    write_string("\n=== Writing executable ===\n");
    {
        header: Formosa_Exe_Header;
        header.input_parameter_count = program_parameters.count;
        header.type_table_offset = size_of(Formosa_Exe_Header);
        header.type_table_virtual_address = cast(*Type_Info) 0xc_0000;
        header.type_table_size = 0x4000;

        type_info_pointer_table := NewArray(header.input_parameter_count, u64);
        type_table: String_Builder;

        offset: u64;
        for program_parameters {
            ti := it.type_inst.result;

            GetVirtualAddress :: () -> u64 #expand {
                return cast(u64) header.type_table_virtual_address + offset + 8 * cast(u64) type_info_pointer_table.count;
            }

            type_info_pointer_table[it_index] = xx GetVirtualAddress();

            if ti.type == {
              case .INTEGER;
                tii := cast(*Type_Info_Integer) ti;
                offset += size_of(Type_Info_Integer);
                append_by_pointer(*type_table, tii);

              case .STRING;
                tis := cast(*Type_Info_String) ti;
                offset += size_of(Type_Info_String);
                append_by_pointer(*type_table, tis);

              case .ENUM;
                original := cast(*Type_Info_Enum) ti;
                tie := << original;
                original.names = array_copy(original.names);
                offset += size_of(Type_Info_Enum);

                tie.internal_type = xx GetVirtualAddress();
                offset += size_of(Type_Info_Integer);

                tie.values.data = xx GetVirtualAddress();
                offset += xx (tie.values.count * size_of(s64));

                for * tie.names {
                    it.data = xx GetVirtualAddress();
                    offset += xx it.count;
                }
                old_names_data := tie.names.data;

                tie.names.data = xx GetVirtualAddress();
                offset += xx (tie.names.count * size_of(string));

                append_by_pointer(*type_table, *tie);
                append_by_pointer(*type_table, original.internal_type);
                append(*type_table, cast(*u8) original.values.data, original.values.count * size_of(s64));
                for * original.names {
                    append(*type_table, << it);
                }
                append(*type_table, cast(*u8) old_names_data, original.names.count * size_of(string));

              case;
                assert(false, "You can only have integers, strings, and enums as command-line parameters at the moment");
            }

            // align := 8 - (offset % 8);
            // for 1..align  append(*type_table, 0);
            // offset += align;
        }

        header.elf_offset = size_of(Formosa_Exe_Header);
        header.elf_offset += type_info_pointer_table.count * 8;
        header.elf_offset += builder_string_length(*type_table);
        header.elf_offset += 8 - (header.elf_offset % 8);

        file := file_open(tprint("files/%", name), true);
        file_write(*file, *header, size_of(Formosa_Exe_Header));
        file_write(*file, type_info_pointer_table.data, type_info_pointer_table.count * 8);
        file_write(*file, *type_table);

        align := 8 - (file_length(file) % 8);
        file_write(*file, "\0\0\0\0\0\0\0\0".data, align);

        file_write(*file, cast(string) elf);
        file_close(*file);
    }
}

#import "Compiler";
#import "File";
#import "Basic";
#import "String";

#import "Formosa_Executable_Format";
