
acpi_parse_definition_block :: (bytecode: [] u8) {
    HexMode();
    LongForm();
    context.print_style.default_format_struct.draw_type_name = true;

    parser_context.start_address = bytecode.data;
    parser_context.bytecode_stream = bytecode;

    while parser_context.bytecode_stream.count > 0 {
        term_obj := parse_term_object();

        using term_obj.value;

        if term_obj.type == {
            case Op_Region;     printf("%\n", op_region);
            case Field;         printf("%\n", field);
            case Method;        printf("%\n", method);
            case Name;          printf("%\n", name);
            case Index_Field;   printf("%\n", index_field);
            case Scope;         printf("%\n", scope);
            case Package;       printf("%\n", package);
            case Device;        printf("%\n", device);
            case; assert(false);
        }
    }
}

dump :: () {
    HexMode();
    context.print_style.default_format_int.minimum_digits = 2;

    printf("Starting dump at byte 0x% (0x% left)\n", parser_context.bytecode_stream.data - parser_context.start_address, parser_context.bytecode_stream.count);

    for 0..99 {
        printf("0x% ", parser_context.bytecode_stream[it]);
        if !((it+1) % 10) printf("\n");
    }
    printf("\n");
}

#scope_file

parser_context: struct {
    start_address: *u8;
    bytecode_stream: [] u8;
}

peek :: () -> u8 {
    using parser_context;
    assert(bytecode_stream.count > 0);
    return bytecode_stream[0];
}

consume :: ($ type: Type) -> type {
    using parser_context;

    size := size_of(type);

    assert(bytecode_stream.count > size);

    result := << cast(*type) bytecode_stream.data;

    bytecode_stream.count -= size;
    bytecode_stream.data += size;

    return result;
}

consume_string :: (count: int = 4) -> string {
    result: string;
    result.data = parser_context.bytecode_stream.data;
    result.count = count;

    parser_context.bytecode_stream.data += count;
    parser_context.bytecode_stream.count -= count;

    return result;
}

parse_package_length :: () -> int, bytes_used: int {
    lead_byte := consume(u8);

    count := lead_byte >> 6;

    if count == 0 return lead_byte & 0x3f, 1;

    value: int = lead_byte & 0xf;
    value |= (cast(int) consume(u8)) << 4;

    if count > 1  value |= (cast(int) consume(u8)) << 12;
    if count > 2  value |= (cast(int) consume(u8)) << 20;

    return value, count+1;
}

Term_Object :: struct {
    type: Type;

    value: union {
        op_region: Op_Region;
        field: Field;
        method: Method;
        name: Name;
        index_field: Index_Field;
        scope: Scope;
        package: Package;
        device: Device;
    }
}

parse_term_object :: () -> Term_Object {
    ExtOpPrefix :: 0x5b;
    result: Term_Object;

    opcode := consume(u8);

    if opcode == ExtOpPrefix {
        opcode = consume(u8);

        if opcode == {
          case 0x80;
            result.type = Op_Region;
            result.value.op_region = parse_op_region();
          case 0x81;
            result.type = Field;
            result.value.field = parse_field();
          case 0x82;
            result.type = Device;
            result.value.device = parse_device();
          case 0x86;
            result.type = Index_Field;
            result.value.index_field = parse_index_field();
          case;
            dump();
            assert(false, tprint("Prefixed opcode not supported: 0x5b 0x%", opcode));
        }
    }

    else if opcode == {
      case 0x8;
        result.type = Name;
        result.value.name = parse_name();
      case 0x10;
        result.type = Scope;
        result.value.scope = parse_scope();
      case 0x12;
        result.type = Package;
        result.value.package = parse_package();
      case 0x14;
        result.type = Method;
        result.value.method = parse_method();
      case;
        dump();
        assert(false, tprint("Term object not supported: 0x%", opcode));
    }

    return result;
}

Device :: struct {
    name: Name_String;
    term_list: [] Term_Object;
}

parse_device :: () -> Device {
    start_offset := parser_context.bytecode_stream.data;

    package_length := parse_package_length();

    result: Device;
    result.name = parse_name_string();

    end_offset := parser_context.bytecode_stream.data;

    device_body_size_bytes := package_length - (end_offset - start_offset);
    result.term_list = parse_term_list(device_body_size_bytes);

    return result;
}

Scope :: struct {
    name: Name_String;
    term_list: [] Term_Object;
}

parse_scope :: () -> Scope {
    start_offset := parser_context.bytecode_stream.data;

    package_length := parse_package_length();

    result: Scope;
    result.name = parse_name_string();

    end_offset := parser_context.bytecode_stream.data;

    scope_body_size_bytes := package_length - (end_offset - start_offset);
    result.term_list = parse_term_list(scope_body_size_bytes);

    return result;
}

Package :: struct {
    num_elements: int;
}

parse_package :: () -> Package {

    start_offset := parser_context.bytecode_stream.data;
    package_length, bytes_used := parse_package_length();

    result: Package;
    result.num_elements = cast(int) consume(u8);

    end_offset := parser_context.bytecode_stream.data;
    method_body_size_bytes := package_length - (end_offset - start_offset);

    // Skip package contents for now
    parser_context.bytecode_stream.data += method_body_size_bytes;
    parser_context.bytecode_stream.count -= method_body_size_bytes;

    return result;
}

parse_buffer :: () -> [] u8 {
    parse_package_length();

    buffer_size := parse_term_arg();
    assert(buffer_size.type == .integer);
    result := consume_string(buffer_size._int);
    return xx result;
}

Index_Field :: struct {
    name_a: Name_String;
    name_b: Name_String;
    flags: u8;
    elements: [..] Field_Element;
}

parse_index_field :: () -> Index_Field {
    result: Index_Field;

    start := parser_context.bytecode_stream.data;
    length := parse_package_length();

    result.name_a = parse_name_string();
    result.name_b = parse_name_string();
    result.flags = consume(u8);

    while true {
        array_add(*result.elements, parse_field_element());
        if parser_context.bytecode_stream.data >= start + length break;
    }

    return result;
}

parse_term_list :: (term_list_size_bytes: int) -> [] Term_Object {
    start := parser_context.bytecode_stream.data;
    result: [..] Term_Object;

    while true {
        if parser_context.bytecode_stream.data >= start + term_list_size_bytes {
            break;
        }

        object := parse_term_object();
        array_add(*result, object);
    }

    return result;
}

Term_Arg :: struct {
    type: enum {
        none;
        byte;
        integer;
        _string;
        buffer;
        package;
        object_reference;
        data_ref_object;
        computational_data;
    }

    _int: int;
    _string: string;
    buffer: [] u8;
}

parse_term_arg :: () -> Term_Arg, bool {
    BytePrefix :: 0x0a;
    WordPrefix :: 0x0b;
    DWordPrefix :: 0x0c;
    StringPrefix :: 0x0d;

    result: Term_Arg;

    prefix := consume(u8);

    if prefix == {
      case BytePrefix;
        result.type = .integer;
        result._int = consume(u8);

      case WordPrefix;
        result.type = .integer;
        result._int = consume(u16);

      case DWordPrefix;
        result.type = .integer;
        result._int = consume(u32);

      case StringPrefix;
        result.type = ._string;
        result._string.data = parser_context.bytecode_stream.data;
        while consume(u8) result._string.count += 1;

      case 0x00; #through;
      case 0x01; #through;
      case 0xff;
        result.type = .integer;
        result._int = prefix;

      case 0x11;
        result.type = .buffer;
        result.buffer = parse_buffer();

      case 0x12;
        result.type = .package;
        parse_package();

      case;
        assert(false, tprint("Term arg prefix not supported 0x%", prefix));
    }

    return result, result.type != .none;
}

Name_String :: struct {
    name_path: string;
    prefix_count: int;
    flags: enum_flags {
        root;
        dual;
        multi;
    }
}

parse_name_string :: () -> Name_String {
    DualNamePrefix :: 0x2e;
    MultiNamePrefix :: 0x2f;

    result: Name_String;

    char := peek();
    if char == #char "\\" {
        consume(u8);
        result.flags |= .root;
    } else while char == #char "^" {
        consume(u8);
        result.prefix_count += 1;
        char = peek();
    }

    if char == {
      case DualNamePrefix;
        consume(u8);
        result.name_path = consume_string(8);
        result.flags |= .dual;
      case MultiNamePrefix;
        consume(u8);
        seg_count := consume(u8);
        result.name_path = consume_string(seg_count * 4);
        result.flags |= .multi;
      case 0x0;
        consume(u8);
        // Leave result.name_path empty
      case;
        result.name_path = consume_string(4);
    }

    return result;
}

Op_Region :: struct {
    name: Name_String;
    address_space: Address_Space;
    offset: Term_Arg;
    length: Term_Arg;

    Address_Space :: enum u8 {
        SystemMemory     :: 0x00;
        SystemIO         :: 0x01;
        PCI_Config       :: 0x02;
        EmbeddedControl  :: 0x03;
        SMBus            :: 0x04;
        System_CMOS      :: 0x05;
        PciBarTarget     :: 0x06;
        IPMI             :: 0x07;
        GeneralPurposeIO :: 0x08;
        GenericSerialBus :: 0x09;
        PCC              :: 0x0a;
    }
}

parse_op_region :: () -> Op_Region {
    result: Op_Region;
    result.name = parse_name_string();

    result.address_space = consume(Op_Region.Address_Space);
    result.offset = parse_term_arg();
    result.length = parse_term_arg();
    return result;
}

Method :: struct {
    name: Name_String;
    flags: u8;
    term_list: [] Term_Object;
}

parse_method :: () -> Method {
    start_offset := parser_context.bytecode_stream.data;

    package_length, bytes_used := parse_package_length();
    
    result: Method;
    result.name = parse_name_string();
    result.flags = consume(u8);

    end_offset := parser_context.bytecode_stream.data;

    // Skip method bodies for now
    method_body_size_bytes := package_length - (end_offset - start_offset);
    // printf("Skipping, bytes used: %\n", bytes_used);

    // result.term_list = parse_term_list(method_body_size_bytes);
    parser_context.bytecode_stream.data += method_body_size_bytes;
    parser_context.bytecode_stream.count -= method_body_size_bytes;

    return result;
}

Name :: struct {
    name: Name_String;
    value: Term_Arg;
}

parse_name :: () -> Name {
    result: Name;
    result.name = parse_name_string();
    result.value = parse_term_arg();
    return result;
}

Field :: struct {
    name: Name_String;
    flags: u8;
    elements: [..] Field_Element;
}

parse_field :: () -> Field {
    result: Field;

    start := parser_context.bytecode_stream.data;
    length := parse_package_length();

    result.name = parse_name_string();
    result.flags = consume(u8);

    while true {
        array_add(*result.elements, parse_field_element());
        if parser_context.bytecode_stream.data >= start + length break;
    }

    return result;
}

Field_Element :: struct {
    name: string;
    length: int;
}

parse_field_element :: () -> Field_Element {
    ReservedFieldPrefix       :: 0x0;
    AccessFieldPrefix         :: 0x1;
    ConnectFieldPrefix        :: 0x2;
    ExtendedAccessFieldPrefix :: 0x3;

    result: Field_Element;

    prefix := peek();

    if prefix == {
      case ReservedFieldPrefix;
        consume(u8);
        result.length = parse_package_length();

      case AccessFieldPrefix; #through;
      case ConnectFieldPrefix; #through;
      case ExtendedAccessFieldPrefix;
        assert(false, tprint("Field type not supported: %", prefix));

      case;
        result.name = consume_string(4);
        result.length = parse_package_length();
    }

    return result;
}
