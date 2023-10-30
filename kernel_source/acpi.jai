
acpi_parse_definition_block :: (bytecode: [] u8) {
    HexMode();
    LongForm();
    context.print_style.default_format_struct.draw_type_name = true;

    parser_context.bytecode_stream = bytecode;

    for 1..20 {
        term_obj := parse_term_object();

        if term_obj.type == {
            case Op_Region; printf("%\n", term_obj.value.op_region);
            case Field; printf("%\n", term_obj.value.field);
            case Method; printf("%\n", term_obj.value.method);
            case; assert(false);
        }
    }
}

dump :: () {
    HexMode();
    context.print_style.default_format_int.minimum_digits = 2;

    for 0..99 {
        printf("0x% ", parser_context.bytecode_stream[it]);
        if !((it+1) % 10) printf("\n");
    }
    printf("\n");
}

#scope_file

parser_context: struct {
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
    consume(u32);
    return result;
}

parse_package_length :: () -> int, bytes_used: int {
    lead_byte := consume(u8);

    count := lead_byte >> 6;

    if count == 0 return lead_byte & 0x3f, 1;

    value: int = lead_byte & 0xf;
    value |= consume(u8) << 4;

    if count > 1  value |= consume(u8) << 12;
    if count > 2  value |= consume(u8) << 20;

    return value, count+1;
}

Term_Object :: struct {
    type: Type;

    value: union {
        op_region: Op_Region;
        field: Field;
        method: Method;
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
          case;
            dump();
            assert(false, tprint("Prefixed opcode not supported: 0x5b 0x%", opcode));
        }
    } else if opcode == {
      case 0x14;
        result.type = Method;
        result.value.method = parse_method();
      case 0x8;
        result.type = Method;
        result.value.method = parse_method();
      case;
        dump();
        assert(false, tprint("Term object not supported: 0x%", opcode));
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
    // _string: string;
    // buffer: *u8;
}

parse_term_arg :: () -> Term_Arg {
    BytePrefix :: 0x0a;
    WordPrefix :: 0x0b;
    DWordPrefix :: 0x0c;

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

      case;
        assert(false, tprint("Term arg prefix not supported 0x%", prefix));
    }

    return result;
}

Name_String :: struct {
    name_path: string;
    prefix_count: int;
}

parse_name_string :: () -> Name_String {
    DualNamePrefix :: 0x2e;
    MultiNamePrefix :: 0x2f;

    result: Name_String;

    char := peek();
    while char == #char "^" {
        consume(u8);
        result.prefix_count += 1;
        char = peek();
    }

    if char == {
      case DualNamePrefix;
        assert(false, tprint("Dual name path not supported"));
      case MultiNamePrefix;
        assert(false, tprint("Multi name path not supported"));
      case 0x0;
        // Leave result.name_path empty
        assert(false);
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
    printf("Skipping, bytes used: %\n", bytes_used);

    // result.term_list = parse_term_list(method_body_size_bytes);
    parser_context.bytecode_stream.data += method_body_size_bytes;
    parser_context.bytecode_stream.count -= method_body_size_bytes;

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
