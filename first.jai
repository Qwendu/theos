
#import,file "modules/Nasm.jai";
#import,file "modules/Elf.jai";
#import,file "modules/Formosa_Filesystem.jai";
#import,file "modules/Linker_Script.jai";

#load "config.jai";
#load "build_app.jai";

exceptions: [] struct {
    message: string;
    slot: int;
    has_error_code: bool;
} = .[
    .{ "Debug exception",                  0x01, false },
    .{ "Non-maskable interrupt exception", 0x02, false },
    .{ "Breakpoint exception",             0x03, false },
    .{ "Overflow exception",               0x04, false },
    .{ "Bound range exceeded exception",   0x05, false },
    .{ "Device not available exception",   0x07, false },
    .{ "Double Fault",                     0x08, true  },
    .{ "Invalid TSS",                      0x0a, true  },
    .{ "Segment not present",              0x0b, true  },
    .{ "Stack segment fault",              0x0c, true  },
//  .{ "Page fault",                       0x0e, true  },
    .{ "Floating point exception",         0x10, false },
    .{ "Alignment check fault",            0x11, true  },
    .{ "Machine check fault",              0x12, false },
    .{ "SIMD Float exception fault",       0x13, false },
    .{ "Virtualization exception fault",   0x14, false },
    .{ "Control protection exception",     0x15, true  },
    .{ "Security exception fault",         0x1e, true  },
];

interrupt_handlers: [] struct {
    handler: string;
    slot: int;
} = .[
    .{ "zero_division", 0x00 },
    .{ "invalid_opcode_exception", 0x06 },
    .{ "gp_exception", 0x0d },
    .{ "pit_interrupt",  0x20 },
    .{ "ps2_interrupt",  0x21 },
    .{ "cmos_interrupt", 0x28 },
    .{ "ps2_mouse"    ,  0x2c },
    .{ "ata_interrupt",  0x2e },
    .{ "syscall_interrupt", 0x80 },
    .{ "page_fault_handler", 0x0e },
];

#if OS == .LINUX {
    #import "POSIX";
}

#run {
    write_string("\n=== Formosa Build Begin ===\n");

    set_build_options_dc(.{do_output = false});
    user_args, compiler_args := get_build_options().compile_time_command_line;

    make_vdi: bool;
    vbox: bool;
    userspace: bool;
    no_kernel: bool;
    setup_vm: bool;

    for user_args {
        if it == {
          case "assemble";
            assemble();
            return;

          case "vdi";   make_vdi  = true;
          case "run_vm";  vbox      = true;
          case "user";  userspace = true;
          case "no_kernel";  no_kernel = true;
          case "setup_vm";  setup_vm = true;
          case "help";
            print("\nSee readme.md.\n\n");
            return;
          case;
            print("Error: did not understand command line argument \"%\".\nSee https://github.com/dlandahl/theos/readme.md", it);
            return;
        }
    }

    if vbox {
        write_string("\n=== Doing Virtualbox Stuff ===\n");
        shell("VBoxManage controlvm formosa poweroff");
        shell("VBoxManage storageattach formosa --storagectl AHCI --port 0 --medium none --device 0");
        shell("VBoxManage closemedium disk_images/formosa.vdi");
        shell("VBoxManage storageattach formosa --storagectl AHCI --port 0 --medium disk_images/formosa.vdi --device 0 --type hdd");
        shell("VBoxManage startvm formosa");
        return;
    }

    if setup_vm {
        write_string("\n=== Creating VM ===\n");
        shell("VBoxManage storageattach formosa --storagectl AHCI --port 0 --medium none --device 0");
        shell("VBoxManage closemedium disk_images/formosa.vdi");
        shell("VBoxManage unregistervm --delete formosa");
        shell("VBoxManage createvm --name formosa --register");
        shell("VBoxManage storagectl formosa --name AHCI --add sata --controller IntelAhci");
        shell("VBoxManage modifyvm formosa --hpet on");
        shell("VBoxManage modifyvm formosa --memory 2048");
        shell("VBoxManage modifyvm formosa --vram 128");
        shell("VBoxManage setextradata global GUI/MaxGuestResolution any");
        shell("VBoxManage setextradata formosa \"CustomVideoMode1\" \"2560x1440x32\"", dont_quote = true);
        shell("VBoxManage setextradata formosa \"CustomVideoMode2\" \"1920x1080x32\"", dont_quote = true);
        shell("VBoxManage setextradata formosa GUI/DefaultCloseAction PowerOff");

        return;
    }

    #if OS != .LINUX {
        write_string("This build program must be executed on linux, or within WSL.\n");
        return;
    }

    version_info: Version_Info;
    compiler_get_version_info(*version_info);
    if memcmp(*version_info, *Version_Info.{0, 1, 44}, size_of(Version_Info)) != 0 {
        using version_info;
        print("This is the wrong version of the compiler! You need 0.1.044, but have %.%.0%\n", major, minor, micro);
        print("However there's a good chance it works anyway, so continuing.\n");
    }

    make_directory_if_it_does_not_exist(".build");

    #if OS == .LINUX if false {
        write_string("\n=== Applying Module Patches ===\n");

        success, exit_code, stdout, stderr := shell("which jai-linux", print_output = false);
        if !stdout.count {
            write_string("Could not find jai-linux executable using \"which\".\n");
            return;
        }

        path := parse_path(stdout, reduce = false);
        modules_path := tprint("%1%2", path_to_string(path, max_words = path.words.count - 2), "modules");

        module_names := string.["Basic", "Window_Type.jai"];

        for module_names {
            shell("cp -R %/% modules", modules_path, it);

            popen(to_c_string(tprint("patch -d. -p0 <modules/PATCHES/%.patch", it)), "r");
            // shell("patch -d module_diff_patches/ -p0 <module_diff_patches/%.patch", it);
        }
    }

    if !no_kernel {
        write_string("\n=== Assembling Interrupt Routines ===\n");
        {
            builder: String_Builder;
            append(*builder, IRQ_PREAMBLE);
            for interrupt_handlers {
                print_to_builder(*builder, "extern %\n", it.handler);
                print_to_builder(*builder, "global %_wrapper\n", it.handler);
                print_to_builder(*builder, "align 0x8\n%_wrapper:\n", it.handler);
                print_to_builder(*builder, "\tcli\n\tpush_all\n\tmov rdi, rsp\n\tcall %\n\tpop_all\n\tiretq\n\n", it.handler);
            }

            write_entire_file(".build/interrupt.asm", builder_to_string(*builder));

            noptions: Nasm_Options;
            noptions.outfile = ".build/interrupt.so";
            noptions.format = .ELF64;
            noptions.input_file_name = ".build/interrupt.asm";
            noptions.warnings |= .ALL;

            result, stdout, stderr := run_nasm(noptions);

            write_string(stdout);

            if result.exit_code {
                write_string("\nAssembly error:\n");
                write_string(stderr);
                return;
            } else {
                write_string("Assembly success!\n");
            }
        }

        BOOTLOADER_SECTOR_COUNT :: 5;
        assert(BOOTLOADER_SECTOR_COUNT * 0x200 + 0x7c00 < BOOT_DATA_AREA, "There is not enough space for the bootloader to go before the boot data area.");
        BOOT_DATA_AREA          :: 0x9000;
        BOOT_DATA_SIZE          :: 0x1000;

        PAGE_TABLE_ADDRESS      :: BOOT_DATA_AREA + BOOT_DATA_SIZE;
        PAGE_TABLE_SIZE         :: 0x6000;

        KERNEL_LOAD_BUFFER :: PAGE_TABLE_ADDRESS + PAGE_TABLE_SIZE;

        write_string("\n=== Compiling Kernel ===\n");
        {
            w := compiler_create_workspace("Formosa Kernel");
            options := get_build_options(w);
            options.output_executable_name = "kernel_elf";
            options.output_path = ".build/";
            options.output_type = .EXECUTABLE;
            options.entry_point_name = "kernel_entry";

            #if !ENABLE_IST options.disable_redzone = true;
            options.stack_trace = true;

            options.array_bounds_check = .OFF;
            options.cast\_bounds_check = .OFF;
            options.math\_bounds_check = .OFF;
            options.null_pointer_check = .OFF;
            options.enable_bytecode_inliner = false;
            options.dead_code_elimination = .MODULES_ONLY;

            options.backend = .LLVM;

            base :: 0xffffffff80100000;
            script: Linker_Script;
            script.entry_point_name = "kernel_entry";
            script.sections = .[
                    .{ base, "text", -1 },
                    .{ base, "rodata", -1 },
                    .{ base, "data", -1 },
                    .{ base, "bss", -1 },
            ];
            set_linker_script(*options, w, script);

            // Don't know if these do anything
            // options.llvm_options.target_system_triple = "x86_64-unknown-none-elf";
            // options.os_target = .NONE;

            new_path: [..] string;
            array_add(*new_path, "modules/");
            array_add(*new_path, ..options.import_path);
            options.import_path = new_path;

            set_build_options(options, w);

            compiler_begin_intercept(w);
            add_build_file("kernel_source/kernel.jai", w);

            {
                isr_code: String_Builder;
                for exceptions {
                    append(*isr_code, tprint(ISR_DECLARATION, formatInt(it.slot, base=16), it.message));
                    append(*isr_code, "\n");
                }
                for interrupt_handlers {
                    format := "%_wrapper :: () #c_call #foreign Interrupts;\n";
                    insert := tprint(format, it.handler);
                    append(*isr_code, insert);
                }

                append(*isr_code, "register_generated_isrs :: () {\n");
                for exceptions {
                    append(*isr_code, tprint("    idt_add_handler(xx isr_slot_0x%, 0x%1);\n", formatInt(it.slot, base=16)));
                }
                for interrupt_handlers {
                    append(*isr_code, tprint("    idt_add_handler(xx %_wrapper, 0x%);\n", it.handler, formatInt(it.slot, base=16)));
                }
                append(*isr_code, "}\n");

                add_build_string(builder_to_string(*isr_code), w);
            }

            add_build_string(tprint("BOOT_DATA_AREA    :: %;", BOOT_DATA_AREA), w);
            add_build_string(tprint("BOOT_DATA_SIZE    :: %;", BOOT_DATA_SIZE), w);
            add_build_string(tprint("COMPILER_VERSION  :: \"%\";", compiler_get_version_info(null)), w);

            for all_messages {
                if it.kind == .ERROR {
                    write_string("Kernel Compilation Failure!\n");
                    return;
                }
            }
            compiler_end_intercept(w);

            objdump_command := "objdump -x .build/kernel_elf -d -M intel --source";
            success, error_code, stdout, stderr := shell(objdump_command, print_output = false);
            if !success || error_code != 0 {
                write_string("objdump failed to run! (continuing)\n");
            }
            else write_entire_file(".build/kernel_elf.objdump.txt", stdout);
        }

        write_string("\n=== Reading ELF ===\n");
        {
            header_printer := context;
            header_printer.print_style.default_format_int.base = 16;
            header_printer.print_style.default_format_struct.use_newlines_if_long_form = true;

            push_context header_printer {
                patches := Plt_Patch.[
                        .{source = "crt_memset", target = "memset"},
                        .{source = "crt_memcpy", target = "memcpy"},
                        .{source = "crt_memcmp", target = "memcmp"},
                ];

                elf := read_entire_file(".build/kernel_elf");
                elf_header := cast(*Elf64_Ehdr) elf.data;

                patch_procedure_linkage_table(cast([] u8) elf, patches);

                generated_asm: String_Builder;
                append(*generated_asm, "\n");
                append(*generated_asm, tprint("kernel_entry_point    equ 0x%\n", elf_header.e_entry));
                append(*generated_asm, tprint("kernel_load_buffer    equ 0x%\n", KERNEL_LOAD_BUFFER));
                append(*generated_asm, tprint("page_table_address    equ 0x%\n", PAGE_TABLE_ADDRESS));
                append(*generated_asm, tprint("page_table_size       equ 0x%\n", PAGE_TABLE_SIZE));
                append(*generated_asm, tprint("bootloader_sectors    equ 0x%\n", BOOTLOADER_SECTOR_COUNT));
                append(*generated_asm, tprint("boot_data_area        equ 0x%\n", BOOT_DATA_AREA));
                append(*generated_asm, tprint("boot_data_size        equ 0x%\n", BOOT_DATA_SIZE));

                append(*generated_asm, tprint("\n%%define ENABLE_VESA %\n", cast(int) ENABLE_VESA));
                append(*generated_asm, tprint("vesa_width  equ 0x%\n", VESA_WIDTH));
                append(*generated_asm, tprint("vesa_height equ 0x%\n", VESA_HEIGHT));
                append(*generated_asm, tprint("vesa_depth  equ 0x%\n", VESA_DEPTH));

                append(*generated_asm, "\nkernel_section_table:\n");
                kernel_binary: String_Builder;

                kernel_offset := 0x500_000;
                section_count: int;
                for 0..elf_header.e_phnum - 1 {
                    base := elf.data + elf_header.e_phoff;
                    base += it       * elf_header.e_phentsize;
                    header := cast(*Elf64_Phdr) base;

                    if header.p_type != PT_LOAD  continue;
                    section_count += 1;

                    append(*generated_asm, tprint("  .section_%:\n", section_count));
                    append(*generated_asm, tprint("    dq 0x%\t\t; Target address\n", header.p_vaddr));
                    append(*generated_asm, tprint("    dq 0x%\t\t; Source address\n", kernel_offset));
                    append(*generated_asm, tprint("    dq 0x%\t\t; Bytes to zero clear\n",  header.p_memsz));
                    append(*generated_asm, tprint("    dq 0x%\t\t; Bytes to copy\n",        header.p_filesz));

                    assert(header.p_vaddr + max(header.p_filesz, header.p_memsz) < 0xffff_ffff_8030_0000);
                    append(*kernel_binary, elf.data + header.p_offset, xx header.p_filesz);
                    kernel_offset += xx header.p_filesz;
                }

                kernel_size := builder_string_length(*kernel_binary);
                write_entire_file(".build/kernel.bin", builder_to_string(*kernel_binary));

                append(*generated_asm, tprint("  .count: dq 0x%\n\n", section_count));

                kernel_sectors := kernel_size / 512 + 1;
                kernel_sectors += 0x10 - (kernel_sectors % 0x10);

                append(*generated_asm, tprint("kernel_sectors equ 0x%\n", kernel_sectors));

                write_entire_file(".build/generated.asm", builder_to_string(*generated_asm));
            }
        }

        write_string("\n=== Assembling Boot Loader ===\n");
        {
            if !assemble() return;
        }
    }

    if userspace {
        write_string("\n=== Building Userspace Apps ===\n");
        {
            make_directory_if_it_does_not_exist(".build/userspace");
            files := file_list("userspace");

            hashes: [] u32;
            new_hashes: [..] u32;
            hash_cache, success := read_entire_file(".build/userspace_app_hashes");

            system_library_code := read_entire_file("modules/Formosa.jai");
            library_hash := sdbm_hash(system_library_code.data, system_library_code.count);

            build_program_code := read_entire_file("build_app.jai");
            build_program_hash := sdbm_hash(build_program_code.data, build_program_code.count);

            if success {
                hashes.data = xx hash_cache.data;
                hashes.count = hash_cache.count / 4;
            }

            for filename: files {
                if !ends_with(filename, ".jai") continue;
                name := basename(filename);

                source_code, success := read_entire_file(filename);
                defer free(source_code);
                assert(success);

                hash := sdbm_hash(source_code.data, source_code.count) ^ library_hash ^ build_program_hash;
                array_add(*new_hashes, hash);

                for hashes if it == hash {
                    continue filename;
                }
                context.logger = (message: string, *void, Log_Info) {};
                build_formosa_app(name);
            }
            write_entire_file(".build/userspace_app_hashes", new_hashes.data, new_hashes.count * 4);
        }
    }

    write_string("\n=== Creating Floppy Image ===\n");
    {
        DISK_SIZE :: 0x16_8000 * 32;
        disk_image := cast(*u8) alloc(DISK_SIZE);
        cursor: int;

        boot_loader := file_open(".build/boot_loader.bin");
        file_read(boot_loader, disk_image + cursor, file_length(boot_loader));
        cursor += file_length(boot_loader);

        kernel := file_open(".build/kernel.bin");
        file_read(kernel, disk_image + cursor, file_length(kernel));
        cursor += file_length(kernel);
        print("Kernel size, bytes: %\n", file_length(kernel));

        Fs_Data :: struct {
            disk_image: *void;
            current_time: Apollo_Time;
        }

        fs_data: Fs_Data;
        fs_user_data = *fs_data;
        fs_data.disk_image = disk_image;

        write_block = (block_index: int, block: *Disk_Block, user: *void) {
            offset := block_index * FS_BLOCKSIZE + FS_BASE_ADDRESS;
            memcpy((cast(*Fs_Data) user).disk_image + offset, block, FS_BLOCKSIZE);
        };

        read_block = (block_index: int, block: *Disk_Block, user: *void) {
            offset := block_index * FS_BLOCKSIZE + FS_BASE_ADDRESS;
            memcpy(block, (cast(*Fs_Data) user).disk_image + offset, FS_BLOCKSIZE);
        };

        get_time = (user: *void) -> Apollo_Time {
            apollo := (cast(*Fs_Data) user).current_time;
            return apollo;
        };

        fs_name, success := os_get_username();
        if !success fs_name = "main drive";
        format_filesystem(fs_name);

        visit_files("files", true, fs_user_data, (info: *File_Visit_Info, user_data: *void) {
            name := info.full_name;
            name.data += "files/".count;
            name.count -= "files/".count;

            (cast(*Fs_Data) user_data).current_time = info.modification_time;

            if info.is_directory create_entry(name, directory = true);
            else {
                create_file(name);
                content := read_entire_file(info.full_name);
                write_file(name, cast([] u8) content);
            }
        }, visit_directories = true);

        flush_filesystem();

        make_directory_if_it_does_not_exist("disk_images");

        write_entire_file("disk_images/formosa.img", disk_image, DISK_SIZE);
    }

    if make_vdi {
        write_string("\n=== Creating Virtual Hard Disk ===\n");
        file_delete("disk_images/formosa.vdi");
        shell("VBoxManage convertfromraw --format VDI disk_images/formosa.img disk_images/formosa.vdi");
    }
}

assemble :: () -> bool {
    options: Nasm_Options;
    options.outfile = ".build/boot_loader.bin";
    options.format = .BIN;
    options.input_file_name = "boot.asm";
    options.warnings |= .ALL;

    array_add(*options.include, ".build/");
    result, stdout, stderr := run_nasm(options);

    if result.type == .FAILED_TO_LAUNCH {
        write_string("nasm failed to run!\n");
        return false;
    }

    write_string(stdout);

    if result.exit_code {
        write_string("\nAssembly error:\n");
        write_string(stderr);
        return false;
    } else {
        write_string("Assembly success!\n");
    }

    {
        od_command := "od -t x1z -A x -v .build/boot_loader.bin";
        success, error_code, stdout, stderr := shell(od_command, print_output = false);
        if !success || error_code != 0 {
            write_string("od failed to run! (continuing) \n");
        }
        else write_entire_file(".build/boot_loader.hex.txt", stdout);
    }

    return true;
}


shell :: (format: string, args: .. Any, print_output := true, dont_quote := false) -> bool, int, string, string {
    command := tprint(format, .. args);
    print("|shell| \"%\"\n", command);
    result, stdout, stderr := run_command(.. split(command, " "), capture_and_return_output = true, arg_quoting = ifx dont_quote then .NEVER_QUOTE else Process_Argument_Quoting.QUOTE_IF_NEEDED);

    if print_output {
        print_color("%", stdout, color = FOREGROUND_INTENSITY);
        print_color("%", stderr, color = FOREGROUND_INTENSITY);
    }

    return !result.exit_code, result.exit_code, stdout, stderr;
}

Plt_Patch :: struct {
    source: string;
    target: string;
    virtual_address: int;
    plt_index: int = -1;
}

patch_procedure_linkage_table :: (elf_file: [] u8, patches: [] Plt_Patch) {
    elf := elf_file;
    elf_header := cast(*Elf64_Ehdr) elf.data;

    get_section_header :: (index: int) -> *Elf64_Shdr #expand {
        base := elf.data + elf_header.e_shoff;
        base += index    * elf_header.e_shentsize;
        header := cast(*Elf64_Shdr) base;
        return header;
    }

    for 0..elf_header.e_shnum - 1 {
        header := get_section_header(it);
        if header.sh_type != SHT_SYMTAB continue;

        string_table_section_header := get_section_header(header.sh_link);
        table := elf.data + string_table_section_header.sh_offset;

        entry_count := header.sh_size / header.sh_entsize;
        assert(header.sh_size % header.sh_entsize == 0);

        for * patch: patches {
            for 0..entry_count - 1 {
                base := elf.data + header.sh_offset;
                base += it * header.sh_entsize;
                symbol := cast(*Elf64_Sym) base;

                name := to_string(table + symbol.st_name);
                if starts_with(name, patch.source) {
                    patch.virtual_address = xx symbol.st_value;
                    print("Found patch target % at virtual address %.\n", name, symbol.st_value);
                    break;
                }
            }
        }
    }

    for 0..elf_header.e_shnum - 1 {
        header := get_section_header(it);
        if header.sh_type != SHT_RELA continue;

        {
            section_name_table_header := get_section_header(elf_header.e_shstrndx);
            name := to_string(elf.data + section_name_table_header.sh_offset + header.sh_name);
            if name != ".rela.plt" continue;
        }

        symbol_table_section_header := get_section_header(header.sh_link);
        string_table_section_header := get_section_header(symbol_table_section_header.sh_link);

        symbol_table := elf.data + symbol_table_section_header.sh_offset;
        string_table := elf.data + string_table_section_header.sh_offset;

        entry_count := header.sh_size / header.sh_entsize;

        for * patch: patches {
            for 0..entry_count - 1 {
                base := elf.data + header.sh_offset;
                base += it * header.sh_entsize;
                rela := cast(*Elf64_Rela) base;

                index := (rela.r_info >> 32);
                symbol := cast(*Elf64_Sym) (symbol_table + index * symbol_table_section_header.sh_entsize);
                name := to_string(string_table + symbol.st_name);

                if name == patch.target {
                    patch.plt_index = xx it;
                    print("Found plt entry for patch \"%\" at index %.\n", name, it);
                    break;
                }
            }
        }
    }

    for 0..elf_header.e_shnum - 1 {
        header := get_section_header(it);
        if header.sh_type != SHT_PROGBITS continue;

        section_name_table_header := get_section_header(elf_header.e_shstrndx);
        name := to_string(elf.data + section_name_table_header.sh_offset + header.sh_name);
        if name != ".plt" continue;

        PLT_ENTRY_SIZE :: 16;

        for patch: patches {
            plt_offset := PLT_ENTRY_SIZE * (patch.plt_index + 1);
            patch_target           := plt_offset + xx header.sh_offset;
            source_virtual_address := plt_offset + xx header.sh_addr + 5;

            jump := patch.virtual_address - source_virtual_address;

            if patch.plt_index == -1 {
                continue;
            }

            if patch.virtual_address == 0 {
                print("Could not find target address for patch \"%\", but the PLT entry exists. This is probably a build failure, but we'll continue.\n", patch.source);
                continue;
            }

            elf.data[patch_target] = 0xe9;
            << (cast(*s32) (elf.data + patch_target + 1)) = xx jump;
        }
        break;
    }
}

using Basic :: #import "Basic";
#import "Compiler";
#import "Process";
#import "File";
#import "File_Utilities";
#import "String";
#import "System";
#import "Hash";
#import "Print_Color";


ISR_DECLARATION :: #string ISR
isr_slot_0x% :: (stack_data: *Interrupt_Data) #c_call {
    stack_data = xx (cast(*u8) stack_data + 8);
    c: Context;
    push_context c {
        print("\n\n   An exception has occurred:  ", theme.primary);
        print("%\n", theme.accent);

        print("\n   Interrupt frame:\n");
        print("   RIP:    "); print_hex(stack_data.ip);    print("\n");
        print("   CS:     "); print_hex(stack_data.cs);    print("\n");
        print("   FLAGS:  "); print_hex(stack_data.flags); print("\n");
        print("   SP:     "); print_hex(stack_data.sp);    print("\n");
        print("   SS:     "); print_hex(stack_data.ss);    print("\n");

        #if ENABLE_VESA paint_screen();
    }

    while true #asm { hlt; }
}
ISR;

IRQ_PREAMBLE :: #string END

section .text

[bits 64]

%macro push_all 0
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
%endmacro

%macro pop_all 0
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
%endmacro


global task_switch

; **current_task is in rax
; *new_task is in rbx

align 0x8
task_switch:
    cli
    ; push_all

    mov rcx, [rax]

    mov [rcx], rsp ; Store current stack on current (old) task

    mov [rax], rbx ; Set the current task to the new task

    mov rsp, [rbx] ; Restore the stack pointer from the current (new) task
    mov rdx, [rbx + 8]
    mov cr3, rdx ; Restore the page table from the current (new) task
    ; pop_all

    iretq

END;








// This is a dummy data type that invokes the for_expansion below.
all_messages: struct {};

for_expansion :: (messages: *type_of(all_messages), body: Code, flags: For_Flags) #expand {
    #assert(flags == 0);  // No options are supported.
    // This for_expansion quits on the first COMPLETE, so it's not suitable
    // if you launch multiple workspaces. It's just a starter loop to help
    // with simple metaprogram stuff.

    `it_index := -1;
    while 1 {
        `it := compiler_wait_for_message();
        it_index += 1;
        if it.kind == .COMPLETE break;
        #insert body;
    }
}

//os_run_command :: (args: .. string, working_directory := "", capture_and_return_output := false, print_captured_output := false, timeout_ms := 0) -> (successfully_launched: bool, exit_code: u32 = 0, output_string := "", error_string := "", timeout_reached := false) {
