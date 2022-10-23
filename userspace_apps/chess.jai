
#import "Theos";
#import "Theos_Utilities";

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
    write_string("This program will fail. (redzone in the c library)\n");
    repaint();
    nn := read_file("chess_res/nn-04cf2b4ed1da.nnue");
    defer unmap_memory(nn.count, nn.data);
    nnue_init(nn);

    initialize_chess_game_memory(*chess);
    init_between_bitboards();
    init_magic_bitboards();

    clear_hash_table();

    in := input();
    if in.value_pointer {
        write_string("Loading fen...\n");
        if in.type.type == .STRING {
            chess_fen(*chess, tprint("%", in));
        } else write_string("It is the wrong type!\n");
    } else {
        chess_startpos(*chess);
    }

    pieces_pnm := read_file("chess_res/chess_pieces.ppm");
    pieces = parse_pnm(pieces_pnm);
    window = create_window(window_size, window_size);
    defer close_window(window);

    theme = get_theme();

    move_start_square = -1;
    last_move_square = -1;
    draw_board();
    repaint();

    defer write_fen();

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

write_fen :: () {
    piece_table :: " KQRBNPkqrbnp";

    space: [128] u8;
    cursor: int;

    empty_count: int;
    for < chess.pieces {
        index := 63 - it_index;
        if index && index % 8 == 0 {
            if empty_count {
                space[cursor] = cast(u8) (#char "0" + empty_count);
                empty_count = 0;
                cursor += 1;
            }

            space[cursor] = #char "/";
            cursor += 1;
        }

        if it == .NONE {
            empty_count += 1;
            continue;
        } else if empty_count {
            space[cursor] = cast(u8) (#char "0" + empty_count);
            empty_count = 0;
            cursor += 1;
        }

        space[cursor] = piece_table[cast(int) it];
        cursor += 1;
    }

    space[cursor] = #char " ";
    cursor += 1;
    space[cursor] = cast(u8) ifx white_to_move #char "w" else #char "b";
    cursor += 1;
    space[cursor] = #char " ";
    cursor += 1;
    space[cursor] = #char "-";
    cursor += 1;
    space[cursor] = #char " ";
    cursor += 1;
    space[cursor] = #char "-";
    cursor += 1;
    space[cursor] = #char " ";
    cursor += 1;
    space[cursor] = #char "0";
    cursor += 1;
    space[cursor] = #char " ";
    cursor += 1;
    space[cursor] = #char "0";

    time := theos_get_time();
    apollo: Apollo_Time;
    apollo.low = time.low;
    apollo.high = time.high;
    ct := theos_apollo_to_calendar(apollo);
    filename := tprint("chess_res/games/%1%2%3", ct.hour, ct.minute, ct.second);

    // Fix this dumbass API
    create_file(filename);

    content: string;
    content.data = space.data;
    content.count = cursor;
    write_file(filename, xx content);
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

    if !check && moves_arr.count == 0 {
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



theos_apollo_to_calendar :: (apollo: Apollo_Time) -> Calendar_Time {

    APOLLO_TIME_FOR_JAN_1_1970 :: Apollo_Time.{low=0xdbd87f0edb7c8000, high=0x300};
    milliseconds := to_milliseconds(apollo - APOLLO_TIME_FOR_JAN_1_1970);

    seconds      := milliseconds / 1000;
    minutes      := seconds      / 60;
    hours        := minutes      / 60;
    total_days   := hours        / 24;

    milliseconds -= seconds      * 1000;
    seconds      -= minutes      * 60;
    minutes      -= hours        * 60;
    hours        -= total_days   * 24;

    years := total_days / 365;
    leap_year_count := leap_years_before(years + 2);

    years = (total_days - leap_year_count * 366) / 365;
    years += leap_year_count;

    days := total_days - (years - leap_year_count) * 365;
    days -= leap_year_count * 366;

    years += 1970;
    is_leap_year := (years % 4 == 0) && (!(years % 100 == 0) || (years % 400 == 0));
    if is_leap_year && days < 59 days += 1;

    ct: Calendar_Time;

    days_in_month := int.[
        31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
    ];

    month: int;
    for days_in_month {
        month += 1;

        if days >= it {
            days -= it;
        } else {
            month = xx it_index;
            break;
        }
    }

    ct.year = xx years;
    // is_leap_year := (ct.year % 4 == 0) && (!(ct.year % 100 == 0) || (ct.year % 400 == 0));
    // if is_leap_year && month < 2 month_day += 1;

    ct.day_of_week_starting_at_0 = xx ((4 + total_days) % 7);

    ct.month_starting_at_0 = xx month;
    ct.day_of_month_starting_at_0 = xx days;

    ct.hour = xx hours;
    ct.minute = xx minutes;
    ct.second = xx seconds;
    ct.millisecond = xx milliseconds;
    return ct;
}

leap_years_before :: (year: s64) -> s64 {
    floor_div :: (dividend: int, $ divisor: int) -> int {
        offset := cast(int) (dividend <= 0 && dividend % divisor);
        return dividend / divisor - offset;
    }

    result := floor_div(year, 4) - floor_div(year, 100) + floor_div(year, 400);
    return result;
}
