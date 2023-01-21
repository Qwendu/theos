
#import "Basic";
#import "Compiler";
#import "Process";
#import "File";
#import "File_Utilities";
#import "String";
#import "System";
#import "Hash";

#import,file "modules/Nasm.jai";
#import,file "modules/Elf.jai";
#import,file "modules/Formosa_Filesystem.jai"(Fs_Data);
#import,file "modules/Linker_Script.jai";

#load "config.jai";
#load "build_app.jai";

Fs_Data :: struct {
    disk_image: *void;
    current_time: Apollo_Time;
}

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
    .{ "hpet_interrupt",  0x20 },
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

    run_vm: bool;
    userspace: bool = true;
    all_userspace: bool;
    no_kernel: bool;
    setup_vm: bool;
    always: bool;

    compile_specific_app: string;

    for user_args {
        if starts_with(it, "app=") {
            compile_specific_app = split(it, cast(u8) #char "=")[1];
        }

        else if it == {
          case "assemble";
            assemble();
            return;
          case "run_vm";     run_vm = true;
          case "no_user";    userspace = false;
          case "user_all";   all_userspace = true;
          case "no_kernel";  no_kernel = true;
          case "setup_vm";   setup_vm = true;
          case "help";
            print("\nSee readme.md.\n\n");
            return;
          case;
            print("Error: did not understand command line argument \"%\". See readme.md\n", it);
            if it == "user" write_string("(The \"user\" command line argument is now the default, and has been removed.\n");
            write_string("(exiting.)\n");
            return;
        }
    }

    version_info: Version_Info;
    compiler_get_version_info(*version_info);
    if memcmp(*version_info, *Version_Info.{0, 1, 53}, size_of(Version_Info)) != 0 {
        using version_info;
        print("\e[31;1mThis is the wrong version of the compiler! You need 0.1.053, but have %.%.%\e[0m\n", major, minor, formatInt(micro, minimum_digits = 3));
        print("However there's a chance it works anyway, so continuing\n");
    }

    is_wsl := false;
    #if OS == .LINUX {
        success, output := shell("uname --kernel-release", print_output = false);
        is_wsl = contains_nocase(output, "microsoft");
    }

    if setup_vm {
        if run_vm || !userspace || no_kernel || all_userspace || compile_specific_app.count {
            write_string("Flags other than \"setup_vm\" are being ignored. You should compile, setup, and run using separate invocations of this program.\n");
        }

        if is_wsl {
            write_string("\nIt appears you are within WSL. Please attempt to setup the VM in the Windows host instead, since it will need to open a window.\n");
            return;
        }

        write_string("\n=== Creating VM ===\n");

        vbox_installed := shell("VBoxManage --version", print_output = false);
        if !vbox_installed {
            write_string("It appears that VirtualBox is not installed on your computer. You must install it, or boot the OS in a different way.\n");
            write_string("(exiting.)\n");
            return;
        }

        exists, vminfo := shell("VBoxManage showvminfo \"formosa\" --machinereadable", dont_quote = true, print_output = false);
        disk_inserted: bool;

        if exists {
            if !vminfo_field_contains(vminfo, "VMState", "poweroff") {
                write_string("\nThe VirtualBox VM is currently running. Please shut it down and try again.\n");
                return;
            }

            if !vminfo_field_contains(vminfo, "\"AHCI-0-0\"", "none") {
                shell("VBoxManage storageattach formosa --storagectl AHCI --port 0 --medium none --device 0");
            }

            if file_exists("disk_images/formosa.vdi") {
                shell("VBoxManage closemedium disk_images/formosa.vdi");
                file_delete("disk_images/formosa.vdi");
            }

            shell("VBoxManage unregistervm --delete formosa");
        }

        shell("VBoxManage createvm --name formosa --register");
        shell("VBoxManage storagectl formosa --name AHCI --add sata --controller IntelAhci");
        shell("VBoxManage modifyvm formosa --hpet on");
        shell("VBoxManage modifyvm formosa --memory 4096");
        shell("VBoxManage modifyvm formosa --vram 128");
        shell("VBoxManage modifyvm formosa --bioslogofadein off");
        shell("VBoxManage modifyvm formosa --bioslogofadeout off");
        shell("VBoxManage modifyvm formosa --bioslogodisplaytime 0");
        shell("VBoxManage modifyvm formosa --biosbootmenu disabled");
        shell("VBoxManage modifyvm formosa --audiocontroller ac97");
        shell("VBoxManage modifyvm formosa --audioout on");
        shell("VBoxManage setextradata formosa \"CustomVideoMode1\" \"2560x1440x32\"", dont_quote = true);
        shell("VBoxManage setextradata formosa \"CustomVideoMode2\" \"1920x1080x32\"", dont_quote = true);
        shell("VBoxManage setextradata formosa \"CustomVideoMode3\" \"1440x900x32\"", dont_quote = true);
        shell("VBoxManage setextradata formosa GUI/MaxGuestResolution any");
        shell("VBoxManage setextradata formosa GUI/DefaultCloseAction PowerOff");
        return;
    }

    if run_vm {
        if !userspace || no_kernel || all_userspace || compile_specific_app.count {
            write_string("Flags other than \"run_vm\" are being ignored. You should compile and run using separate invocations of this program.\n");
        }

        if is_wsl {
            write_string("\nIt appears you are within WSL. Please attempt to run the VM in the Windows host instead, since it will need to open a window.\n");
            return;
        }

        write_string("\n=== Running VirtualBox ===\n");

        vbox_installed := shell("VBoxManage --version", print_output = false);
        if !vbox_installed {
            write_string("It appears that VirtualBox is not installed on your computer. You must install it, or boot the OS in a different way.\n");
            write_string("(exiting.)\n");
            return;
        }

        exists, vminfo := shell("VBoxManage showvminfo \"formosa\" --machinereadable", dont_quote = true, print_output = false);
        if !exists {
            write_string("\nThe VM could not be started because it wasn't found. You may choose to run    jai first.jai - setup_vm\n(exiting.)\n");
            return;
        }

        was_running := shell("VBoxManage controlvm formosa poweroff", print_output = false);

        if was_running {
            write_string("\nThe VM was already running, turning off.\n");
            write_string("(exiting.)\n");
            return;
        }

        if !vminfo_field_contains(vminfo, "\"AHCI-0-0\"", "none") {
            shell("VBoxManage storageattach formosa --storagectl AHCI --port 0 --medium none --device 0");
            shell("VBoxManage closemedium disk_images/formosa.vdi");
        }

        make_directory_if_it_does_not_exist("disk_images");
        disks := file_list("disk_images");
        vdi := array_find(disks, "disk_images/formosa.vdi");
        img := array_find(disks, "disk_images/formosa.img");

        if !img && !vdi {
            write_string("There is no disk image! You must compile before you run. See readme.md (exiting.)\n");
            return;
        }

        if !vdi {
            write_string("\nNo VirtualBox disk (VDI) found, generating from \"disk_images/formosa.img\".\n\n");
            shell("VBoxManage convertfromraw --format VDI disk_images/formosa.img disk_images/formosa.vdi");
        } else {
            vdi_modtime := file_modtime_and_size("disk_images/formosa.vdi");
            img_modtime := file_modtime_and_size("disk_images/formosa.img");

            if img_modtime > vdi_modtime {
                write_string("\nThe raw disk image is more recent than the VirtualBox disk image. Reformatting.\n\n");
                file_delete("disk_images/formosa.vdi");
                shell("VBoxManage convertfromraw --format VDI disk_images/formosa.img disk_images/formosa.vdi");
            }
        }

        shell("VBoxManage storageattach formosa --storagectl AHCI --port 0 --medium disk_images/formosa.vdi --device 0 --type hdd");
        shell("VBoxManage startvm formosa -E VBOX_GUI_DBG_ENABLED=true");
        return;
    }

    #if OS != .LINUX {
        write_string("\e[31;1mWhen compiling, this build program must be executed on Linux, or within WSL.\e[0m\n");
        if file_exists("disk_images/formosa.img") {
            write_string("\nIf you have VirtualBox installed, and would like to boot the already-compiled operating system in a VM, try\n    jai first.jai - setup_vm\n    jai first.jai - run_vm\n");
        }
        return;
    }

    if !no_kernel {
        nasm_success := shell("nasm -v", print_output = false);

        if !nasm_success {
            write_string("\nIt looks like Nasm is not installed on your Linux system.\n");
            write_string("Nasm is required in order to assemble the bootloader.\n");

            os_name := read_entire_file("/etc/os-release");
            if contains_nocase(os_name, "ubuntu") {
                write_string("Since you are on Ubuntu, we will try to install the program. You may be prompted for root user credentials.\n\n");

                result := shell("sudo apt install nasm", capture = true);

                if !result || !shell("nasm -v", print_output = false) {
                    write_string("\n\nIt appears that this has failed!\nPlease manually install the Nasm program. (exiting.)\n");
                    return;
                }

                write_string("It appears that this was successful. Continuing.\n");
            } else {
                write_string("Since you do not appear to be on Ubuntu, please manually install the Nasm program. (exiting.)\n");
                return;
            }
        }
    }

    make_directory_if_it_does_not_exist(".build");

    #if OS == .LINUX if false {
        write_string("\n=== Applying Module Patches ===\n");

        success, stdout, stderr := shell("which jai-linux", print_output = false);
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

            try_to_write_file(".build/interrupt.asm", builder_to_string(*builder));

            shell("nasm .build/interrupt.asm -o .build/interrupt.so -f elf64 -wall");
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

            // set_optimization_level(*options, 3, 0);

            options.disable_redzone = true;
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

            // options.llvm_options.target_system_triple = "x86_64-unknown-none-elf";
            // options.os_target = .NONE;

            new_path: [..] string;
            array_add(*new_path, "modules/");
            array_add(*new_path, ..options.import_path);
            options.import_path = new_path;

            set_build_options(options, w);

            compiler_begin_intercept(w);
            add_build_file("kernel_source/kernel.jai", w);

            context.print_style.default_format_int.minimum_digits = 2;
            for 1..100 {
                add_build_string(tprint(DEFAULT_PLT_ENTRY_CODE, it - 1), w);
            }
            context.print_style.default_format_int.minimum_digits = 1;

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

            linker_fail: bool;
            for all_messages {
                if it.kind == .ERROR {
                    write_string("\nKernel Compilation Failure! (exiting.)\n");
                    return;
                }

                if it.kind == .PHASE {
                    phase := cast(*Message_Phase) it;
                    if phase.phase == .POST_WRITE_EXECUTABLE && phase.linker_exit_code != 0 {
                        write_string("It appears there were linker errors. Cannot continue.\n");
                        linker_fail = true;
                    }
                }
            }

            compiler_end_intercept(w);
            if linker_fail return;

            objdump_command := "objdump -x .build/kernel_elf -d -M intel --source";
            success, stdout, stderr := shell(objdump_command, print_output = false);
            if !success {
                write_string("objdump failed to run! (continuing)\n");
            } else {
                write_entire_file(".build/kernel_elf.objdump.txt", stdout);
            }
        }

        write_string("\n=== Patching ELF ===\n");
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

                default := "plt_entry_%_must_be_patched";

                patch_procedure_linkage_table(cast([] u8) elf, patches, default);

                context.print_style.default_format_int.base = 16;

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
                try_to_write_file(".build/kernel.bin", builder_to_string(*kernel_binary));

                append(*generated_asm, tprint("  .count: dq 0x%\n\n", section_count));

                kernel_sectors := kernel_size / 512 + 1;
                kernel_sectors += 0x10 - (kernel_sectors % 0x10);

                append(*generated_asm, tprint("kernel_sectors equ 0x%\n", kernel_sectors));

                try_to_write_file(".build/generated.asm", builder_to_string(*generated_asm));
            }
        }

        write_string("\n=== Assembling Boot Loader ===\n");
        {
            if !assemble() return;
        }
    }

    if userspace || all_userspace || compile_specific_app.count {
        write_string("\n=== Building Userspace ===\n");
        {
            make_directory_if_it_does_not_exist(".build/userspace");
            files := file_list("userspace");

            hashes: [] u32;
            new_hashes: [..] u32;

            hash_cache: string;
            success: bool;
            if file_exists(".build/userspace_app_hashes") {
                hash_cache, success = read_entire_file(".build/userspace_app_hashes");
            }

            // system_library_code := read_entire_file("modules/Formosa.jai");
            // library_hash := sdbm_hash(system_library_code.data, system_library_code.count);

            build_program_code := read_entire_file("build_app.jai");
            build_program_hash := sdbm_hash(build_program_code.data, build_program_code.count);

            if success {
                hashes.data = xx hash_cache.data;
                hashes.count = hash_cache.count / 4;
            }

            recompiled: int;
            successful: int;
            total: int;
            for filename: files {
                if !ends_with(filename, ".jai") continue;
                total += 1;
                name := basename(filename);

                source_code, success := read_entire_file(filename);
                defer free(source_code);
                assert(success);

                hash := sdbm_hash(source_code.data, source_code.count) ^ build_program_hash;
                array_add(*new_hashes, hash);

                if !all_userspace {
                    if compile_specific_app.count {
                        if name != compile_specific_app {
                            continue filename;
                        }
                    } else for hashes if it == hash {
                        continue filename;
                    }
                }

                context.logger = (message: string, *void, Log_Info) {};
                successful += cast(int) build_formosa_app(name);
                recompiled += 1;
            }

            cache_file: string;
            cache_file.data = cast(*u8) new_hashes.data;
            cache_file.count = new_hashes.count * 4;
            try_to_write_file(".build/userspace_app_hashes", cache_file);

            if recompiled == 0 {
                write_string("\n(no userspace applications needed to be recompiled.)\n");
            } else {
                print("Recompiled % userspace application%, with % compilation failure% and % already up to date.\n", recompiled, ifx recompiled == 1 then "" else "s", recompiled - successful, ifx recompiled-successful == 1 then "" else "s", total - recompiled);
            }
        }
    }

    write_string("\n=== Creating Disk Image ===\n");
    {
        if !file_exists(".build/boot_loader.bin") || !file_exists(".build/kernel.bin") {
            write_string("Trying to create a bootable disk image, but the OS binaries have not been found.\n");
            if no_kernel {
                write_string("Did you erroneously run this build program with \" - no_kernel\"?\n");
            } else {
                write_string("Was there a failure earlier in the build process?\n");
            }
            write_string("(exiting.)\n\n");
            return;
        }

        DISK_SIZE :: 0x800_0000;

        disk_image := cast(*u8) alloc(DISK_SIZE);
        cursor: int;

        boot_loader := file_open(".build/boot_loader.bin");
        file_read(boot_loader, disk_image + cursor, file_length(boot_loader));
        cursor += file_length(boot_loader);

        kernel := file_open(".build/kernel.bin");
        file_read(kernel, disk_image + cursor, file_length(kernel));
        cursor += file_length(kernel);
        print("Kernel size: % kb\n", file_length(kernel) / 1024);

        fs_data: Fs_Data;
        fs_user_data = *fs_data;
        fs_data.disk_image = disk_image;

        write_block = (block_index: int, block: *Disk_Block, user: *Fs_Data) {
            offset := block_index * FS_BLOCKSIZE + FS_BASE_ADDRESS;
            memcpy(user.disk_image + offset, block, FS_BLOCKSIZE);
        };

        read_block = (block_index: int, block: *Disk_Block, user: *Fs_Data) {
            offset := block_index * FS_BLOCKSIZE + FS_BASE_ADDRESS;
            memcpy(block, user.disk_image + offset, FS_BLOCKSIZE);
        };

        get_timestamp = (user: *Fs_Data) -> Apollo_Time {
            apollo := user.current_time;
            return apollo;
        };

        format_filesystem();

        visit_files("filesystem", true, fs_user_data, (info: *File_Visit_Info, user_data: *Fs_Data) {
            name := info.full_name;
            name.data += "filesystem/".count;
            name.count -= "filesystem/".count;

            (cast(*Fs_Data) user_data).current_time = info.modification_time;

            if info.is_directory {
                create_item(name, directory = true);
            } else {
                create_file(name);
                content := read_entire_file(info.full_name);
                write_file(name, cast([] u8) content);
            }
        }, visit_directories = true);

        flush_filesystem();
        make_directory_if_it_does_not_exist("disk_images");

        disk: string;
        disk.data = disk_image;
        disk.count = DISK_SIZE;
        try_to_write_file("disk_images/formosa.img", disk);
    }

    write_string("\nIf all went well, this program has written a bootable disk image into \"disk_images/formosa.img\".\n");
    if file_list("filesystem/programs").count == 0 {
        write_string("\nHowever, there is no userspace! The OS will not do much. Consider running\n    jai-linux first.jai - user_all\n\n");
    }
}

try_to_write_file :: (name: string, data: string) {
    success := write_entire_file(name, cast(string) data);
    if !success {
        print("Failed to write file \"%\".\n(exiting.)\n", name);
        exit(1);
    }
}

assemble :: () -> bool {
    shell("nasm boot.asm -o .build/boot_loader.bin -I .build/ -f bin -wall");

    {
        od_command := "od -t x1z -A x -v .build/boot_loader.bin";
        success, stdout, stderr := shell(od_command, print_output = false);
        if !success {
            write_string("od failed to run! (continuing) \n");
        } else {
            write_entire_file(".build/boot_loader.hex.txt", stdout);
        }
    }

    return true;
}

shell :: (format: string, args: .. Any, print_output := true, dont_quote := false, capture := true, silent := false) -> bool, string, string {
    command := tprint(format, .. args);
    if !silent print("|shell| \e[36;1m\"%\"\e[0m\n", command);

    result, stdout, stderr := run_command(.. split(command, " "), capture_and_return_output = capture, arg_quoting = ifx dont_quote then .NEVER_QUOTE else Process_Argument_Quoting.QUOTE_IF_NEEDED);

    if !silent if print_output && (stdout.count || stderr.count) {
        print("\e[33;1m%", stdout);
        print("%\e[0m", stderr);
    }

    return !result.exit_code, stdout, stderr;
}

Plt_Patch :: struct {
    source: string;
    target: string;
    virtual_address: int;
    plt_index: int = -1;
}

patch_procedure_linkage_table :: (elf_file: [] u8, patches: [] Plt_Patch, default_target: string = "", silent := false) {
    elf := elf_file;
    elf_header := cast(*Elf64_Ehdr) elf.data;

    get_section_header :: (index: int) -> *Elf64_Shdr #expand {
        base := elf.data + elf_header.e_shoff;
        base += index    * elf_header.e_shentsize;
        header := cast(*Elf64_Shdr) base;
        return header;
    }

    default_addresses: [100] u64;
    default_names: [100] string;
    context.print_style.default_format_int.base = 16;
    for *default_names {
        (<< it) = tprint(default_target, it_index - 1);
    }
    context.print_style.default_format_int.base = 10;

    for 0..elf_header.e_shnum - 1 {
        header := get_section_header(it);
        if header.sh_type != SHT_SYMTAB continue;

        string_table_section_header := get_section_header(header.sh_link);
        table := elf.data + string_table_section_header.sh_offset;

        entry_count := header.sh_size / header.sh_entsize;
        assert(header.sh_size % header.sh_entsize == 0);

        for 0..entry_count - 1 {
            base := elf.data + header.sh_offset;
            base += it * header.sh_entsize;
            symbol := cast(*Elf64_Sym) base;

            name := to_string(table + symbol.st_name);

            for 0..100-1 {
                if starts_with(name, default_names[it]) {
                    default_addresses[it] = xx symbol.st_value;
                    break;
                }
            }

            for * patch: patches {
                if patch.virtual_address != 0  continue;

                if starts_with(name, patch.source) {
                    patch.virtual_address = xx symbol.st_value;
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

        for 0..entry_count - 1 {
            base := elf.data + header.sh_offset;
            base += it * header.sh_entsize;
            rela := cast(*Elf64_Rela) base;

            index := (rela.r_info >> 32);
            symbol := cast(*Elf64_Sym) (symbol_table + index * symbol_table_section_header.sh_entsize);
            name := to_string(string_table + symbol.st_name);

            for * patch: patches {
                if name == patch.target {
                    patch.plt_index = xx it;
                    break;
                }
            }
        }
    }

    successful_patches: [..] string;
    for 0..elf_header.e_shnum - 1 {
        header := get_section_header(it);
        if header.sh_type != SHT_PROGBITS continue;

        section_name_table_header := get_section_header(elf_header.e_shstrndx);
        name := to_string(elf.data + section_name_table_header.sh_offset + header.sh_name);
        if name != ".plt" continue;

        PLT_ENTRY_SIZE :: 16;

        // assert(header.sh_entsize == PLT_ENTRY_SIZE);
        plt_entry_count := header.sh_size / PLT_ENTRY_SIZE;
        if !silent print("PLT entry count: %\n", plt_entry_count);

        for 1..plt_entry_count-1 {
            plt_offset := PLT_ENTRY_SIZE * it;
            patch_target           := plt_offset + xx header.sh_offset;
            source_virtual_address := plt_offset + xx header.sh_addr + 5;

            jump := xx default_addresses[it] - source_virtual_address;

            elf.data[patch_target] = 0xe9;
            << (cast(*s32) (elf.data + patch_target + 1)) = xx jump;
        }

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

            array_add(*successful_patches, patch.target);

            elf.data[patch_target] = 0xe9;
            << (cast(*s32) (elf.data + patch_target + 1)) = xx jump;
        }

        break;
    }

    if !silent print("Successful patches: %\n", successful_patches);
    // for successful_patches
}

vminfo_field_contains :: (vminfo: string, field: string, value: string) -> bool {
    lines := split(vminfo, cast(u8) #char "\n");
    for lines {
        f := split(it, cast(u8) #char "=");
        if contains(f[0], field) {
            return contains(f[1], value);
        }
    }

    return false;
}


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
    push_all

    mov rcx, [rax]
    mov r8, [rcx + 16]
    fxsave64 [r8] ; Store FPU and SIMD state in the old task's xsave_area
    mov [rcx], rsp ; Store current stack on current (old) task

    mov [rax], rbx ; Set the current task to the new task
    mov r8, [rbx + 16]
    fxrstor64 [r8] ; Load FPU and SIMD state from the new task's xsave_area

    mov rsp, [rbx] ; Restore the stack pointer from the current (new) task
    mov rdx, [rbx + 8]
    mov cr3, rdx ; Restore the page table from the current (new) task
    pop_all

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

DEFAULT_PLT_ENTRY_CODE :: #string END
#program_export
plt_entry_%1_must_be_patched :: () #c_call {
    write_string("PLT 0x%1! ");
}
END;
