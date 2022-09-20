
FORMOSA_EXE_MAGIC :: #run << cast(*u64) "FORMOSA\0".data;

Formosa_Exe_Header :: struct {
    magic: u64 = FORMOSA_EXE_MAGIC;
    type: Formosa_Exe_Type;

    // Fix this nonsense
    input_parameter_count: int;
    type_table_offset: int;
    type_table_virtual_address: u64;

    union {
        elf_offset: int;
        minimal_header: *~s64 Minimal_Exe_Header;
    }
}

Formosa_Exe_Type :: enum {
    NONE :: 0;
    MINIMAL :: 1;
    STANDARD :: 2;
    ELF :: 0;
}

MINIMAL_EXE_MAGIC :: #run << cast(*u64) "MINIMAL\0".data;

Minimal_Exe_Header :: struct {
    data_section_in_the_file: []~s64 u8;
    code_section_in_the_file: []~s64 u8;
    zero_section_size: int;

    data_section_virtual_address: *void;
    code_section_virtual_address: *void;
    zero_section_virtual_address: *void;
}
