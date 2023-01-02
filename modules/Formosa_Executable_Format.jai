
#import "Machine_X64";

FORMOSA_EXE_MAGIC :: #run << cast(*u64) "FORMOSA\0".data;

Formosa_Exe_Header :: struct {
    magic: u64 = FORMOSA_EXE_MAGIC;
    type: Formosa_Exe_Type;

    // header_size: int; // The size of everything that isn't specific to the executable subtype
    // entry_points: []~s64 Exe_Entry_Point;

    input_parameter_count: int;
    type_table_offset: int;
    type_table_virtual_address: *Type_Info;
    type_table_size: int;

    // required_cpu_privilege_level: int;

    required_cpu_features: []~s16 x86_Feature_Flag;
    recommended_cpu_features: []~s16 x86_Feature_Flag;

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

Minimal_Exe_Header :: struct {
    data_section_in_the_file: []~s64 u8;
    code_section_in_the_file: []~s64 u8;
    zero_section_size: int;

    data_section_virtual_address: *void;
    code_section_virtual_address: *void;
    zero_section_virtual_address: *void;
}

Exe_Entry_Point :: struct {
    name: string~s64;
    virtual_address: *void;
}
