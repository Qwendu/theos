
#scope_module
#import "Formosa";

#scope_export

Pnm :: struct {
    width: int;
    height: int;

    type: enum {
        UNINITIALIZED :: 0;
        ASCII_BITMAP;
        ASCII_GRAYMAP;
        ASCII_PIXMAP;
        BITMAP;
        GRAYMAP;
        PIXMAP;
    }

    data: *u8;
}

parse_pnm :: (file: [] u8) -> Pnm {
    buffer := file.data;
    // assert(buffer[0] == #char "P");

    pnm: Pnm;
    pnm.type = xx (buffer[1] - #char "0");
    // assert(pnm.type == .GRAYMAP || pnm.type == .PIXMAP);

    is_whitespace :: (char: u8) -> bool {
        return char == 0x20
            || char == 0x09
            || char == 0x0a
            || char == 0x0b
            || char == 0x0c
            || char == 0x0d
            || char == #char "#";
    }

    ConsumeWhitespaceAndComments :: () #expand {
        while is_whitespace(buffer[`cursor]) {
            if buffer[`cursor /*`*/] == #char "#" {
                while buffer[`cursor /*`*/] != 0xa `cursor += 1; /*`*/
            }
            cursor += 1;
        }
    }

    ParseInt :: () -> int #expand {
        digit := buffer[`cursor /*`*/];
        result: int;

        while !is_whitespace(digit) {
            // assert(digit >= #char "0" && digit <= #char "9");
            result *= 10;
            result += digit - #char "0";
            `cursor += 1; /*`*/
            digit = buffer[`cursor /*`*/];
        }
        return result;
    }

    cursor := 2;
    ConsumeWhitespaceAndComments();
    pnm.width = ParseInt();

    ConsumeWhitespaceAndComments();
    pnm.height = ParseInt();

    ConsumeWhitespaceAndComments();
    max_value := ParseInt();
    // assert(max_value == 255);

    ConsumeWhitespaceAndComments();
    pnm.data = buffer + cursor;

    return pnm;
}

scan_table         :: "\0#1234567890-=\0\tqwertyuiop[]\0\0asdfghjkl;'`\0\\zxcvbnm,./\0*\0 ";
scan_table_shifted :: "\0#!@#$%^&*()_+\0\0QWERTYUIOP{}\0\0ASDFGHJKL:\"~\0|ZXCVBNM<>?\0*\0 ";

write_int :: (number: int) {
    negative: bool;
    buffer: [] u8;
    buffer.count = 30;
    buffer.data = map_memory(30);

    _number := number;
    if number < 0 _number *= -1;

    for 0..buffer.count - 1 {
        rem := _number % 10;
        buffer[29 - it] =  #char "0" + cast(u8) rem;
        _number /= 10;

        if _number == 0 {
            result: string = ---;
            result.data = buffer.data + 29 - it;
            result.count = it + 1;
            write_string(result);
            return;
        }
    }
}

write_hex :: (number: u16) {
    result: [4] u8;

    table := "0123456789abcdef";
    for 0..3 {
        index := number >> (it * 4);
        index &= 0xf;

        result[4 - it - 1] = table[index];
    }
    write_string(xx result);
}
