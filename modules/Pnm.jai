
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
