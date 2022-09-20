
/*

Long list of things that need to be filled out because it is getting out of control
 - Recursive expressions
 - More immediate sizes and for any value, choose the required immediate size based on the size of the immediate
 - The rest of the operand types in general
 - The rest of the instructions
 - Recursive expressions rather than just one level deep
 - Unary minus and other operators
 - Handle errors
 - Handle escape characters in strings
 - Reference declarations that are later in the file (Keep looping until everything is resolved)

*/

#import "Theos";
#import "Basic";
#import "Hash_Table";
#import "String";

#import "Jason";
#import "Formosa_Executable_Format";

Json_Format :: struct {
    instructions: [] struct {
        mnemonic: string;
        summary: string;

        forms: [] struct {
            operands: [] struct {
                type: string;
                extended_size: int;
                input: bool;
                output: bool;
            };

            encodings: [] struct {
                prefix: struct {
                    mandatory: bool;
                    byte: string;
                }

                REX: struct {
                    mandatory: bool;
                    W, R, B, X: string;
                };

                opcode: struct {
                    byte: string;
                    addend: string;
                };

                ModRM: struct {
                    mode, rm, reg: string;
                };

                immediate: struct {
                    size: int;
                    value: string;
                }

                code_offset: struct {
                    size: int;
                    value: string;
                }
            };
        };
    };
}

File_Header :: struct {
    number_of_instructions: int;

    instruction_stride: s16;
    form_stride: s16;
    operand_stride: s16;

    instruction_header_offset: int; // Offset of the instruction header array from the beginning of the file
    instruction_form_offset: int; // Offset of the instruction form array from the beginning of the file
    instruction_operand_offset: int; // Offset of the instruction operand array from the beginning of the file
}

Instruction_Header :: struct {
    mnemonic: [8] u8;
    // Make this a relative pointer array
    forms_offset: int; // Number of bytes from the file header's instruction_form_offset at which to find the forms of this instruction
    number_of_forms: int;
}

Instruction_Form :: struct {
    number_of_operands: int;

    rex_required: bool;
    Rex_Field :: enum u8 {
        ignored; set; unset; op_0; op_1; op_2;
    }
    rex_w, rex_r, rex_x, rex_b: Rex_Field;
#place rex_w;
    rex: [4] Rex_Field;

    use_modrm: bool;
    mod_rm: struct {
        mode: s8; // -1 is 0b11, anything else is an operand index
        rm: u8; // Operand index
        reg: u8;
        reg_is_operand_index: bool; // `reg` points to an operand that is a register. Otherwise, `reg` is a literal to add into the reg field of ModRM
    };

    prefix_mandatory: bool;
    prefix: u8;

    opcode: u8;
    addend: s8; // -1 means no addend

    // The immediate byte
    immediate_size: u8;
    immediate_value: u8;

    relative_size: u8;
    relative_value: u8;

    // Make this a relative pointer array, although those are weird because it's much more common for things to be offset from the start of the file, or from the beginning of a particular region
    operands_offset: int; // Number of bytes from the file header's instruction_operand_offset at which to find the operands for this form
}

Instruction_Operand :: struct {
    type: Operand_Type;
    input: bool;
    output: bool;
}

eat_pound :: (value: string) -> string #expand {
    assert(value.count >= 2);
    assert(value[0] == #char "#");

    result: string;
    result.count = value.count - 1;
    result.data = value.data + 1;
    return result;
}

compile_time_generate_instruction_table :: () {
    #import "File";
    json_code := read_entire_file("files/code/x86_64.json");
    success, table := json_parse_string(json_code, Json_Format);

    write :: (thing: $T) #expand {
        thingc := thing;
        append(*builder, cast(*u8) *thingc, size_of(T));
    }

    current_form_offset: int;
    current_operand_offset: int;

    builder: String_Builder;

    // Parse the instruction encoding information from the JSON layout into our binary representation

    instruction_header_offset := size_of(File_Header);
    // Write all of the instruction headers (1 for each mnemonic)
    for table.instructions {
        if it.mnemonic.count >= 8 continue;

        header: Instruction_Header;
        memcpy(header.mnemonic.data, it.mnemonic.data, it.mnemonic.count);

        header.number_of_forms = xx it.forms.count;
        header.forms_offset = current_form_offset;
        current_form_offset += size_of(Instruction_Form) * header.number_of_forms;

        write(header);
    }

    instruction_form_offset := builder_string_length(*builder) + size_of(File_Header);

    // Write each of the instruction forms for each of the mnemonics
    for inst: table.instructions {
        if inst.mnemonic.count >= 8 continue;
        for inst.forms {
            form: Instruction_Form;
            assert(it.encodings.count > 0);
            enc := it.encodings[0];

            form.rex_required = enc.REX.W.count || enc.REX.R.count || enc.REX.X.count || enc.REX.B.count;
            if form.rex_required {
                // Parse rex
                json_rex := *enc.REX.W;
                for 0..3 {
                    if json_rex[it].count == 0 {
                        form.rex[it] = .ignored;
                    } else if json_rex[it][0] == #char "#" {
                        reference := eat_pound(json_rex[it]);
                        form.rex[it] = Instruction_Form.Rex_Field.op_0 + xx string_to_int(reference);
                    } else {
                        set := string_to_int(json_rex[it]) > 0;
                        form.rex[it] = ifx set then Instruction_Form.Rex_Field.set else .unset;
                    }
                }
            }

            form.use_modrm = enc.ModRM.mode.count && enc.ModRM.rm.count && enc.ModRM.reg.count;
            if form.use_modrm {
                // Parse modrm
                if enc.ModRM.mode == "11" form.mod_rm.mode = -1;
                else {
                    reference := eat_pound(enc.ModRM.mode);
                    form.mod_rm.mode = cast(s8) string_to_int(reference);
                }

                reference := eat_pound(enc.ModRM.rm);
                form.mod_rm.rm = cast(u8) string_to_int(reference);

                reg := enc.ModRM.reg;
                if reg[0] == #char "#" {
                    reg = eat_pound(reg);
                    form.mod_rm.reg_is_operand_index = true;
                }
                form.mod_rm.reg = cast(u8) string_to_int(reg);
            }

            form.prefix_mandatory = enc.prefix.mandatory;
            form.prefix = cast(u8) string_to_int(enc.prefix.byte, 16);
            form.opcode = cast(u8) string_to_int(enc.opcode.byte, 16);

            if enc.opcode.addend.count {
                reference := eat_pound(enc.opcode.addend);
                form.addend = cast(s8) string_to_int(reference);
            }
            else form.addend = -1;

            if enc.immediate.value.count {
                form.immediate_size = cast(u8) enc.immediate.size;
                form.immediate_value = cast(u8) string_to_int(eat_pound(enc.immediate.value));
            }

            if enc.code_offset.value.count {
                form.relative_size = cast(u8) enc.code_offset.size;
                form.relative_value = cast(u8) string_to_int(eat_pound(enc.code_offset.value));
            }

            form.number_of_operands = it.operands.count;
            form.operands_offset = current_operand_offset;
            current_operand_offset += size_of(Instruction_Operand) * form.number_of_operands;

            write(form);
        }
    }

    instruction_operand_offset := builder_string_length(*builder) + size_of(File_Header);
    for inst: table.instructions for inst.forms for it.operands {
        if inst.mnemonic.count >= 8 continue;

        operand: Instruction_Operand;
        op_type: Operand_Type;

        operand.type = .invalid_or_unsupported_vector;
        ti := type_info(Operand_Type);
        op := it;
        for ti.names {
            name := it;
            if name[0] == #char "_" {
                name.data += 1;
                name.count -= 1;
            }

            if name == op.type {
                operand.type = cast(Operand_Type) ti.values[it_index];
                break;
            }
        }

        operand.input = it.input;
        operand.output = it.output;

        write(operand);
    }

    header_builder: String_Builder;
    file_header: File_Header;

    file_header.number_of_instructions = table.instructions.count;
    file_header.instruction_stride = size_of(Instruction_Header);
    file_header.form_stride = size_of(Instruction_Form);
    file_header.operand_stride = size_of(Instruction_Operand);

    file_header.instruction_header_offset = instruction_header_offset;
    file_header.instruction_form_offset = instruction_form_offset;
    file_header.instruction_operand_offset = instruction_operand_offset;

    append_by_pointer(*header_builder, *file_header);
    append(*header_builder, builder_to_string(*builder));

    write_entire_file("files/code/x64_enc", builder_to_string(*header_builder));
}

#run compile_time_generate_instruction_table();

Operand_Type :: enum u16 {
    invalid_or_unsupported_vector; _1; _3; al; ax; eax; rax; cl; xmm0; rel8; rel32; imm4; imm8; imm16; imm32; imm64; r8; r16; r32; r64; mm; m; m8; m16; m32; m64;
}

Register_Name :: enum {
    rax; rcx; rdx; rbx; rsp; rbp; rsi; rdi; r8;  r9;  r10;  r11;  r12;  r13;  r14;  r15;
    eax; ecx; edx; ebx; esp; ebp; esi; edi; r8d; r9d; r10d; r11d; r12d; r13d; r14d; r15d;
    ax;  cx;  dx;  bx;  sp;  bp;  si;  di;  r8w; r9w; r10w; r11w; r12w; r13w; r14w; r15w;
    al;  cl;  dl;  bl;  spl; bpl; sil; dil; r8b; r9b; r10b; r11b; r12b; r13b; r14b; r15b;
    ah;  ch;  dh;  bh;
}

Typed_Value :: struct {
    type: Type;
    _string: string;
    _int: int;
    register: Register_Name;
}

Parser :: struct {
    tokens: [] Token;
    i: int;
    statements: [..] *Ast_Node;
}

Symbol_Table_Entry :: struct {
    value: Typed_Value;
    runtime_data_offset: int; // -1 is a constant value that cannot be found in the data section at run time, but be used for constant expression evaluation while generating code
}

Symbol_Table :: Table(string, Symbol_Table_Entry);

encodings_blob: [] u8;

register_encoding_number :: (name: Register_Name) -> u8 {
    // An arbitrary way in which x64 instruction encodings refer to registers using 4-bit numbers. The values in "Register_Name" are ordered such that this is just a modulo
    return cast(u8) (cast(int) name % 16);
}

data_section_virtual_base :: 0x0200_0000;
code_section_virtual_base :: 0x1200_0000;

code: [..] u8;

main :: (source_file: string, output_name: string) {
    source_code := cast(string) read_file(source_file);

    tokens := tokenize(source_code);
    statements := parse(tokens);

    encodings_blob = read_file("code/x64_enc");
    defer unmap_memory(encodings_blob.count, encodings_blob.data);
    enc_header := cast(*File_Header) encodings_blob.data;
    assert(enc_header.instruction_stride == size_of(Instruction_Header));
    assert(enc_header.form_stride        == size_of(Instruction_Form));
    assert(enc_header.operand_stride     == size_of(Instruction_Operand));

    symbol_table: Symbol_Table;
    init(*symbol_table, 64);

    runtime_data_offset_cursor: int;

    info := type_info(Register_Name);
    for info.names {
        register: Symbol_Table_Entry;
        register.value.type = Register_Name;
        register.value.register = cast(Register_Name) info.values[it_index];
        register.runtime_data_offset = -1;

        table_add(*symbol_table, it, register);
    }

    for statements {
        if it.kind == .declaration {
            decl := cast(*Ast_Declaration) it;

            entry: Symbol_Table_Entry;
            entry.value = evaluate_expression(decl.value_expression, *symbol_table);
            if decl.constant {
                entry.runtime_data_offset = -1;
            } else {
                entry.runtime_data_offset = runtime_data_offset_cursor;
                if entry.value.type == string {
                    entry.value._int = runtime_data_offset_cursor;
                }
                runtime_data_offset_cursor += get_typed_value_runtime_size(entry.value);
            }

            table_add(*symbol_table, decl.name, entry);
        } else {
            assert(it.kind == .instruction);
            ast_inst := cast(*Ast_Instruction) it;

            // Find a matching instruction mnemonic
            for it: 0..enc_header.number_of_instructions - 1 {
                inst := cast(*Instruction_Header) (encodings_blob.data + it * enc_header.instruction_stride + enc_header.instruction_header_offset);
                if c_style_strlen(inst.mnemonic.data) != ast_inst.mnemonic.count continue;

                if ast_inst.mnemonic != to_string(inst.mnemonic.data) continue;

                // If we have a matching mnemonic, find a matching form
                forms: [] Instruction_Form;
                forms.data = cast(*Instruction_Form) (encodings_blob.data + inst.forms_offset + enc_header.instruction_form_offset);
                forms.count = inst.number_of_forms;

                for *instruction_form: forms {
                    if instruction_form.number_of_operands != ast_inst.operands.count  continue;

                    form_operands: [] Instruction_Operand;
                    form_operands.data = cast(*Instruction_Operand) (encodings_blob.data + instruction_form.operands_offset + enc_header.instruction_operand_offset);
                    form_operands.count = instruction_form.number_of_operands;

                    node_operands: [..] Typed_Value;
                    for ast_inst.operands {
                        array_add(*node_operands, evaluate_expression(it, *symbol_table));
                    }

                    for 0..instruction_form.number_of_operands - 1 {
                        if !types_match(node_operands[it], form_operands[it].type) continue instruction_form;
                    }

                    emit_instruction(*code, instruction_form, node_operands);
                    break it;
                }
            }
        }
    }

    runtime_data := alloc(runtime_data_offset_cursor);
    for entry, key: symbol_table {
        if entry.runtime_data_offset != -1 {
            source_pointer: *void;
            target_pointer := runtime_data + entry.runtime_data_offset;
            size := get_typed_value_runtime_size(entry.value);

            if entry.value.type == {
                case int; source_pointer = *entry.value._int;
                case string; source_pointer = entry.value._string.data;
            }

            memcpy(target_pointer, source_pointer, size);
        }
    }

    file_size := size_of(Formosa_Exe_Header) + size_of(Minimal_Exe_Header) + code.count + runtime_data_offset_cursor;
    file := alloc(file_size);

    cursor: int;
    cursor += size_of(Formosa_Exe_Header);

    header := cast(*Formosa_Exe_Header) file;
    header.magic = FORMOSA_EXE_MAGIC;
    header.type = .MINIMAL;
    header.minimal_header = cast(*Minimal_Exe_Header) (file + cursor);
    min := cast(*Minimal_Exe_Header) header.minimal_header;

    cursor += size_of(Minimal_Exe_Header);

    min.data_section_in_the_file.count = runtime_data_offset_cursor;
    min.data_section_in_the_file.data = file + cursor;
    memcpy(file + cursor, runtime_data, runtime_data_offset_cursor);

    cursor += runtime_data_offset_cursor;

    min.code_section_in_the_file.count = code.count;
    min.code_section_in_the_file.data = file + cursor;
    memcpy(file + cursor, code.data, code.count);

    min.data_section_virtual_address = xx data_section_virtual_base;
    min.code_section_virtual_address = xx code_section_virtual_base;

    content: [] u8;
    content.count = file_size;
    content.data = file;

    create_file(output_name);
    write_file(output_name, content);
}

types_match :: (value: Typed_Value, operand: Operand_Type) -> bool {
    if value.type == int {
        if value._int == 0x80 && operand == .imm8  return true;
        if operand == .imm64 return true;
        if cast(u64) value._int < 0x1_0000_0000 && operand == .imm32 return true;
        // if value._int < 256 && operand == .rel8 return true; // Tricky
        if operand == .rel8 return true;
    }

    if value.type == Register_Name {
        r := value.register;
        if r >= .rax && r <= .r15  && operand == .r64 return true;
        if r >= .eax && r <= .r15d && operand == .r32 return true;
        if r >= .ax  && r <= .r15w && operand == .r16 return true;
        if r >= .al  && r <= .bh   && operand == .r8  return true;
    }

    return false;
}

evaluate_expression :: (expr: *Ast_Node, symbol_table: *Symbol_Table) -> Typed_Value {
    if expr.kind == .literal {
        lit := cast(*Ast_Literal) expr;
        return lit.value;
    }

    if expr.kind == .ident {
        ident := cast(*Ast_Ident) expr;
        value, success := table_find(symbol_table, ident.name);
        assert(success);
        return value.value;
    }

    if expr.kind == .binary_operator {
        binop := cast(*Ast_Binary_Operator) expr;
        assert(binop.operator_type == .dot || binop.operator_type == .minus, "Only dot and minus operators are implemented");

        if binop.operator_type == .dot {
            lhs := evaluate_expression(binop.left, symbol_table);
            field_name := (cast(*Ast_Ident) binop.right).name;
            return get_field_of_typed_value(lhs, field_name);
        }

        if binop.operator_type == .minus {
            lhs := evaluate_expression(binop.left, symbol_table);
            rhs := evaluate_expression(binop.right, symbol_table);
            assert(lhs.type == int && rhs.type == int, "Minus only allowed on two integers");

            result: Typed_Value;
            result.type = int;
            result._int = lhs._int - rhs._int;
            write_string(tprint("Result of subtraction was %\n", result._int));
            return result;
        }
    }

    if expr.kind == .directive {
        directive := cast(*Ast_Directive) expr;
        if directive.name == "code_offset" {
            result: Typed_Value;
            result.type = int;
            result._int = code.count + code_section_virtual_base;
            return result;
        }
        else assert(false, "Did not recognize directive");
    }

    assert(false);
    return .{};
}

get_field_of_typed_value :: (value: Typed_Value, field_name: string) -> Typed_Value {
    result: Typed_Value;
    if value.type == string {
        if field_name == "count" {
            result.type = int;
            result._int = value._string.count;
        } else if field_name == "data" {
            result.type = int;
            result._int = value._int + data_section_virtual_base;
        }
    }

    return result;
}

get_typed_value_runtime_size :: (value: Typed_Value) -> int {
    if value.type == int return 8;
    if value.type == string return value._string.count;
    assert(false, tprint("Could not determine runtime size of value %", value));
    return 0;
}

emit_instruction :: (code: *[..] u8, form: Instruction_Form, operands: [] Typed_Value) {
    if form.prefix {
        array_add(code, form.prefix);
    }

    if form.rex_required {
        rex: u8 = 0b0100_0000;
        for form.rex {
            if it == .set rex |= cast(u8) (0b1000 >> it_index);
            else if it >= .op_0 {
                // This rex bit is a reference to an operand
                op_index := cast(int) (it - .op_0);
                op := operands[op_index];

                if op.type == Register_Name {
                    // The referenced operand is a register - the bit is the high bit of the register's encoding number
                    high := register_encoding_number(op.register) & 0b1000;
                    if high > 0 {
                        rex |= cast(u8) (0b1000 >> it_index);
                    }
                } else {
                    assert(false, "REX references memory operand, not yet implemented");
                }
            }
        }

        array_add(code, rex);
    }

    opcode := form.opcode;
    if form.addend != -1 {
        op := operands[form.addend];
        assert(op.type == Register_Name);
        opcode |= register_encoding_number(op.register) & 0b111;
    }
    array_add(code, opcode);

    if form.use_modrm {
        modrm: u8;
        if form.mod_rm.mode == -1 {
            modrm |= 0b1100_0000;
        } else {
            assert(false, "ModR/M.mode references memory operand, not yet implemented");
        }

        if form.mod_rm.reg_is_operand_index {
            op := operands[form.mod_rm.reg];
            if op.type == Register_Name {
                // The referenced operand is a register - ModR/M.reg is the low bits of the register's encoding number
                rm := register_encoding_number(op.register);
                modrm |= rm & 0b111;
            } else {
                assert(false, "ModR/M.reg references memory operand, not yet implemented");
            }
        } else {
            // Otherwise ModR/M.reg is just a literal value
            modrm |= cast(u8) (form.mod_rm.reg << 3);
        }

        op := operands[form.mod_rm.rm];
        if op.type == Register_Name {
            rm := register_encoding_number(op.register);
            modrm |= rm & 0b111;
        } else {
            assert(false, "ModR/M.rm references memory operand, not yet implemented");
        }

        array_add(code, modrm);
    }

    if form.immediate_size {
        op := operands[form.immediate_value];
        assert(op.type == int);

        imm: [] u8;
        imm.data = cast(*u8) *op._int;
        imm.count = form.immediate_size;
        for imm array_add(code, it);
    }

    if form.relative_size {
        op := operands[form.relative_value];
        assert(op.type == int);

        jump := op._int - (code.count + code_section_virtual_base + form.relative_size);

        imm: [] u8;
        imm.data = cast(*u8) *jump;
        imm.count = form.relative_size;
        for imm array_add(code, it);
    }
}



Ast_Node :: struct {
    kind: Kind;

    Kind :: enum {
        instruction;
        declaration;
        literal;
        ident;
        binary_operator;
        directive;
    }
}

Ast_Instruction :: struct {
    using node: *Ast_Node;
    kind = .instruction;

    mnemonic: string;       // In `mov a, 10` this is "mov"
    operands: [] *Ast_Node; // In `mov a, 10` this is [a, 10]
}

Ast_Declaration :: struct {
    using node: *Ast_Node;
    kind = .declaration;

    name: string;
    constant: bool;
    value_expression: *Ast_Node;
}

Ast_Literal :: struct {
    using node: *Ast_Node;
    kind = .literal;

    value: Typed_Value;
}

Ast_Ident :: struct {
    using node: *Ast_Node;
    kind = .ident;

    name: string;
    declaration: *Ast_Declaration; // Not yet implemented
}

Ast_Binary_Operator :: struct {
    using node: *Ast_Node;
    kind = .binary_operator;

    left: *Ast_Node;
    right: *Ast_Node;
    operator_type: enum {
        dot;
        minus;
    }
}

Ast_Directive :: struct {
    using node: *Ast_Node;
    kind = .directive;

    name: string;
}

create_node :: ($Node: Type) -> *Node {
    new := New(Node);
    return cast(*Node) new;
}



parse :: (input: [] Token) -> [] *Ast_Node {
    state: Parser;
    state.tokens = input;
    state.i = -1;
    array_reset(*state.statements);

    while true {
        parse_statement(*state);
        if consume(*state, .eot) break;
    }

    return state.statements;
}

parse_statement :: (using p: *Parser) {
    assert(consume(p, .ident));
    id := current(p);

    if peek(p).kind == .doublecolon || peek(p).kind == .colonequals {
        array_add(*statements, parse_declaration(p));
    } else {
        array_add(*statements, parse_instruction(p));
    }

    assert(consume(p, .semicolon));
}

parse_declaration :: (using p: *Parser) -> *Ast_Node {
    new := create_node(Ast_Declaration);
    new.name = current(p)._string;

    if consume(p, .doublecolon) new.constant = true;
    else assert(consume(p, .colonequals));

    new.value_expression = parse_expression(p);
    return cast(*Ast_Node) new;
}

parse_expression :: (using p: *Parser) -> *Ast_Node {
    value := parse_factor(p);
    if consume(p, .dot) {
        other_value := parse_factor(p);
        op := create_node(Ast_Binary_Operator);
        op.left = value;
        op.right = other_value;
        op.operator_type = .dot;

        return cast(*Ast_Node) op;
    }

    if consume(p, .minus) {
        other_value := parse_factor(p);
        op := create_node(Ast_Binary_Operator);
        op.left = value;
        op.right = other_value;
        op.operator_type = .minus;

        return cast(*Ast_Node) op;
    }

    return value;
}

parse_factor :: (using p: *Parser) -> *Ast_Node {
    if consume(p, .integer) {
        lit := create_node(Ast_Literal);
        lit.value._int = current(p)._int;
        lit.value.type = int;
        return cast(*Ast_Node) lit;
    }

    if consume(p, .string) {
        lit := create_node(Ast_Literal);
        lit.value._string = current(p)._string;
        lit.value.type = string;
        return cast(*Ast_Node) lit;
    }

    if consume(p, .ident) {
        ident := create_node(Ast_Ident);
        ident.name = current(p)._string;
        return cast(*Ast_Node) ident;
    }

    if consume(p, .pound_sign) {
        assert(consume(p, .ident));
        directive := create_node(Ast_Directive);
        directive.name = current(p)._string;
        return cast(*Ast_Node) directive;
    }

    assert(false);
    return null;
}

parse_instruction :: (using p: *Parser) -> *Ast_Node {
    new := create_node(Ast_Instruction);
    new.mnemonic = to_upper_copy(current(p)._string);

    if peek(p).kind == .semicolon {
        return cast(*Ast_Node) new; // Allow instructions with no operands
    }

    operands: [..] *Ast_Node;
    array_add(*operands, parse_expression(p));

    while consume(p, .comma) {
        array_add(*operands, parse_expression(p));
    }

    new.operands = operands;
    return cast(*Ast_Node) new;
}


consume :: (using p: *Parser, kind: Token_Kind) -> bool {
    new := tokens[i + 1];
    if new.kind == kind {
        i += 1;
        return true;
    }
    return false;
}

peek :: (using p: *Parser) -> Token #expand {
    if i >= tokens.count - 1 return tokens[tokens.count - 1];
    return tokens[i + 1];
}

current :: (using p: *Parser) -> Token { return tokens[i]; }



Token_Kind :: enum {
    none;
    ident;
    string;
    integer;
    doublecolon;
    colonequals;
    dot;
    minus;
    comma;
    semicolon;
    pound_sign;
    error;
    eot;
}

Token :: struct {
    kind: Token_Kind;

    _string: string;
    _int: int;

    line, c0, c1: int;
}

EOT : u8 : 0x4;

tokenize :: (source: string) -> [] Token {
    cursor: int;
    result: [..] Token;

    current :: () -> u8 #expand {
        if cursor >= source.count  return EOT;
        return source[cursor];
    }

    last_line_start: int;
    start: int;
    line: int;

    Emit :: (kind: Token_Kind, _string := "", _int := 0) -> *Token #expand {
        token := array_add(*result);
        token.kind = kind;

        if _int    != 0  token._int = _int;
        if _string != "" token._string = _string;

        token.line = line;
        token.c0 = start - last_line_start;
        token.c1 = cursor - last_line_start + 1;
        return token;
    }

    is_char :: (char: u8) -> bool {
        if char >= #char "a" && char <= #char "z"  return true;
        if char >= #char "A" && char <= #char "Z"  return true;
        if char == #char "_"  return true;
        return false;
    }

    is_num :: (char: u8) -> bool {
        if char >= #char "0" && char <= #char "9"  return true;
        return false;
    }

    while true {
        defer cursor += 1;
        while current() == #char " " || current() == #char "\r" || current() == #char "\n" {
            cursor += 1;
            if current() == #char "\n"  {
                last_line_start = cursor;
                line += 1;
            }
        }

        start = cursor;
        if current() == {
          case #char ","; Emit(.comma);
          case #char "."; Emit(.dot);
          case #char "-"; Emit(.minus);
          case #char ";"; Emit(.semicolon);
          case #char "#"; Emit(.pound_sign);

          case #char ":";
            cursor += 1;
            if      current() == #char ":"  Emit(.doublecolon);
            else if current() == #char "="  Emit(.colonequals);
            else Emit(.error);

          case 0; #through;
          case EOT;
            Emit(.eot);
            return result;

          case #char "\"";
            cursor += 1;
            text: string;
            text.data = source.data + cursor;

            while current() != #char "\"" && current() != EOT {
                text.count += 1;
                cursor += 1;
            }

            if current() == #char "\""
                then Emit(.string, _string = text);
                else Emit(.error);

          case;
            if is_num(current()) {
                base: int = 10;

                if current() == #char "0" {
                    cursor += 1;
                    if current() == {
                      case #char "x";
                        base = 16;
                        cursor += 1;
                      case #char "b";
                        base = 2;
                        cursor += 1;
                      case;
                        cursor -= 1;
                    }
                }

                len: int;
                while is_num(current()) || is_char(current()) {
                    cursor += 1;
                    len += 1;
                }
                cursor -= 1;

                num_str: string;
                num_str.data = source.data + cursor - len + 1;
                num_str.count = len;
                num := string_to_int(num_str, base = base);

                Emit(.integer, _int = num);
            }

            else if is_char(current()) {
                ident: string;
                ident.data = source.data + cursor;
                while is_char(current()) || is_num(current()) {
                    ident.count += 1;
                    cursor += 1;
                }
                cursor -= 1;
                Emit(.ident, _string = ident);
            }

            else Emit(.error);
        }
    }

    return result;
}
