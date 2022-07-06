
#import "Theos";
#load "chess_engine/movegen.jai";
#load "chess_engine/search.jai";
#load "chess_engine/eval.jai";

window: *u32;
window_size :: 45 * 8;
field_size :: window_size / 8;
piece_size :: 45;
pieces: Pnm;

theme: Theme;

stdin_stop_signal :: () -> bool {
    return false;
}

last_move_square: int;
selected_square: int;
move_start_square: int;

chess: ChessGame;
fifty: int;

cvt_square :: (square: int) -> int {
    x := square % 8;
    y := (63 - square) / 8;
    return x + y * 8;
}

Player_Kind :: enum {
    CPU;
    HUMAN;
}

main :: (white_pieces: Player_Kind, black_pieces: Player_Kind, depth: int) {
    write_string("Loading neural network...\n");
    repaint();
    nn := read_file("nn-04cf2b4ed1da.nnue");
    defer unmap_memory(nn.count, nn.data);
    nnue_init(nn);

    initialize_chess_game_memory(*chess);
    init_between_bitboards();
    init_magic_bitboards();

    chess_startpos(*chess);
    clear_hash_table();
    chess_startpos(*chess);

    pieces_pnm := read_file("chess_pieces.ppm");
    pieces = parse_pnm(pieces_pnm.data);
    window = create_window(window_size, window_size);
    defer close_window(window);

    theme = get_theme();

    move_start_square = -1;
    last_move_square = -1;
    draw_board();
    repaint();

    while true {
        white_to_move = true;
        if white_pieces == .CPU {
            if !computer_move(depth) return;
        } else {
            if !human_move() return;
        }

        if check_win_condition() return;

        white_to_move = false;
        if black_pieces == .CPU {
            if !computer_move(depth) return;
        } else {
            if !human_move() return;
        }

        if check_win_condition() return;
    }
}

white_to_move: bool;

check_win_condition :: () -> bool {
    moves_arr: [..] Move16;
    generate_moves(*chess, *moves_arr);

    check := in_check(*chess.chess);
    if check && moves_arr.count == 0 {
        write_string("Checkmate!\n");
        return true;
    }

    if !check && !moves_arr.count {
        write_string("Stalemate!\n");
        return true;
    }

    return false;
}

// Todo fix castle redrawing

clamp :: (value: int, min: int, max: int) -> int {
    if value > max return max;
    if value < min return min;
    return value;
}

computer_move :: (depth: int) -> bool {
    move := search(*chess, clamp(depth, 1, 10), fifty);
    make_move(*chess, move);

    message := get_message();
    while message.kind != .NONE {
        if message.kind == .KEYBOARD {
            if message.keyboard_scan_code == .ESC {
                return false;
            }
        }
        message = get_message();
    }

    type, from, to := decode_move16(move);

    if type & .King_Castle {
        draw_square(63 - 0);
        draw_square(63 - 3);
    }
    if type & .Queen_Castle {
        draw_square(63 - 3);
        draw_square(63 - 7);
    }

    old := last_move_square;
    last_move_square = cvt_square(to);
    draw_square(old);
    draw_square(last_move_square);
    draw_square(cvt_square(from));
    repaint();

    return true;
}

human_move :: () -> bool {
    moves_arr: [..] Move16;
    generate_moves(*chess, *moves_arr);

    while true {
        message := get_message();
        if message.kind == .KEYBOARD {
            if message.keyboard_scan_code == .ESC {
                return false;
            }

            old_square := selected_square;
            if message.keyboard_scan_code == {
                case .CURSOR_UP;    if selected_square >= 8 selected_square -= 8;
                case .CURSOR_LEFT;  if selected_square > 0  selected_square -= 1;
                case .CURSOR_RIGHT; if selected_square < 63 selected_square += 1;
                case .CURSOR_DOWN;  if selected_square <= (63 - 8) selected_square += 8;
            }
            draw_square(selected_square);
            draw_square(old_square);
            repaint();

            if message.keyboard_scan_code == .ENTER {
                from := cvt_square(selected_square);

                is_valid_start_square := !white_to_move && (chess.pieces[from] > .W_PAWN);
                is_valid_start_square ||= white_to_move && (chess.pieces[from] < .B_KING) && (chess.pieces[from] > .NONE);

                if is_valid_start_square {
                    old := move_start_square;
                    move_start_square = selected_square;
                    draw_square(move_start_square);
                    draw_square(old);
                    draw_square(cvt_square(from));
                    repaint();
                } else {
                    to   := cvt_square(selected_square);
                    from := cvt_square(move_start_square);
                    move := to_move16(from, to, 0);

                    move_start_square = -1;
                    for moves_arr {
                        flags, legal_from, legal_to := decode_move16(it);
                        if legal_from == from && legal_to == to {
                            make_move(*chess, it);

                            draw_square(cvt_square(from));
                            draw_square(selected_square);

                            if flags & .King_Castle {
                                draw_square(7);
                                draw_square(5);
                            }
                            if flags & .Queen_Castle {
                                draw_square(0);
                                draw_square(3);
                            }
                            repaint();
                            return true;
                        }
                    }
                    draw_square(cvt_square(from));
                    repaint();
                }
            }
        }
    }
}

draw_board :: () {
    for 0..63 draw_square(it);
}

draw_square :: (square: int) {
    if square == -1 return;
    color: u32;
    sq_x := square % 8;
    sq_y := square / 8;

    if square == last_move_square {
        color = theme.accent;
    } else if sq_x % 2 == sq_y % 2 {
        color = theme.foreground;
    } else {
        color = theme.primary;
    }

    for y: sq_y * field_size..(sq_y + 1) * field_size - 1 for x: sq_x * field_size..(sq_x + 1) * field_size - 1 {
        index := x + y * window_size;
        window[index] = color;

        highlight_size := 10;
        HighlightSquare :: (the_square: int) #expand {
            if `square == the_square { //`
                if (`x % field_size) > (field_size - highlight_size) || (`x % field_size < highlight_size) {
                    window[index] = theme.accent;
                } else if (`y % field_size) > (field_size - highlight_size) || (`y % field_size < highlight_size) {
                    window[index] = theme.accent;
                }
            }
        }
        HighlightSquare(move_start_square);
        HighlightSquare(selected_square);
    }

    for chess.pieces {
        if cvt_square(it_index) == square {
            draw_piece(it, it_index % 8, (63 - it_index) / 8);
        }
    }
}

draw_piece :: (piece: Piece, x_field: int, y_field: int) {
    if piece == .NONE return;
    black: bool = xx piece > Piece.W_PAWN;

    start := piece;
    if black start -= 6;
    cursor: int = (xx start - 1) * piece_size * 3;

    for y: 0..pieces.height-1 {
        for x: 0..pieces.width / 6-1 {
            alpha   := cast(float) pieces.data[cursor] / 255;
            border  := cast(float) pieces.data[cursor + 1] / 255 + alpha;

            index := (x) + (y) * window_size;
            index += x_field * field_size;
            index += y_field * window_size * field_size;

            color : u32 = xx ifx black then theme.background else theme.accent;
            window[index] = blend(color, window[index], alpha);
            window[index] = blend(0x0, window[index], border);

            cursor += 3;
        }
        cursor += piece_size * 15;
    }
}

blend :: (target: u32, source: u32, t: float) -> u32 #expand {
    result: u32;
    c :: (color: u32, offset: u32) -> u32 #expand {
        return (color >> offset) & 0xff;
    }

    result  = (cast(u32) (cast(float) c(target, 16) * (1 - t) + cast(float) c(source, 16) * t)) << 16;
    result |= (cast(u32) (cast(float) c(target,  8) * (1 - t) + cast(float) c(source,  8) * t)) << 8;
    result |= (cast(u32) (cast(float) c(target,  0) * (1 - t) + cast(float) c(source,  0) * t));

    return result;
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
        }
    }
}



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

parse_pnm :: (buffer: *u8) -> Pnm {

    pnm: Pnm;
    pnm.type = xx (buffer[1] - #char "0");

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
            if buffer[`cursor] == #char "#" {
                while buffer[`cursor] != 0xa `cursor += 1;
            }
            cursor += 1;
        }
    }

    ParseInt :: () -> int #expand {
        digit := buffer[`cursor]; //`
        result: int;

        while !is_whitespace(digit) {
            result *= 10;
            result += digit - #char "0";
            `cursor += 1;
            digit = buffer[`cursor];
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

    ConsumeWhitespaceAndComments();
    pnm.data = buffer + cursor;

    return pnm;
}

